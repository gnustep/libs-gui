/** <title>GSAudioPlayer</title>

   <abstract>Audio player with master clock functionality for GSMovieView</abstract>

   This audio player serves as the master clock for audio-video synchronization
   in GSMovieView. The audio clock is updated during playback and is used by
   the video thread to synchronize video frame presentation.

   Copyright <copy>(C) 2025 Free Software Foundation, Inc.</copy>

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: May 2025

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import "GSAudioPlayer.h"
#import "GSAVUtils.h"

#import <Foundation/NSRange.h>

@implementation GSAudioPlayer
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _audioCodecCtx = NULL;
      _audioFrame = NULL;
      _swrCtx = NULL;
      _audioClock = 0;
      _audioStartTime = 0;
      _audioBaseTime = 0;
      _totalSamplesPlayed = 0;
      _audioPackets = nil;
      _audioPacketCursor = 0;
      _audioThread = nil;
      _running = NO;
      _volume = 1.0;
      _started = NO;
      _loopMode = NSQTMovieNormalPlayback;
    }
  return self;
}

- (void)dealloc
{
  [self stopAudio];

  if (_audioFrame)
    {
      av_frame_free(&_audioFrame);
    }

  if (_audioCodecCtx)
    {
      avcodec_free_context(&_audioCodecCtx);
    }

  if (_swrCtx)
    {
      swr_free(&_swrCtx);
    }

  if (_aoDev)
    {
      ao_close(_aoDev);
    }

  RELEASE(_audioPackets);

  ao_shutdown();
  [super dealloc];
}

- (void) setPlaying: (BOOL)f
{
  _running = f;
}

- (BOOL) isPlaying
{
  return _running;
}

- (NSQTMovieLoopMode) loopMode
{
  return _loopMode;
}

- (void) setLoopMode: (NSQTMovieLoopMode)mode
{
  _loopMode = mode;
}

- (void) prepareWithFormatContext: (AVFormatContext *)formatCtx
		      streamIndex: (int)audioStreamIndex
{
  ao_initialize();
  int driver = ao_default_driver_id();
  int out_channels = 2;

  AVCodecParameters *audioPar = formatCtx->streams[audioStreamIndex]->codecpar;
  const AVCodec *audioCodec = avcodec_find_decoder(audioPar->codec_id);

  if (!audioCodec)
    {
      NSLog(@"Audio codec not found.");
      return;
    }

  _audioCodecCtx = avcodec_alloc_context3(audioCodec);
  avcodec_parameters_to_context(_audioCodecCtx, audioPar);

  if (avcodec_open2(_audioCodecCtx, audioCodec, NULL) < 0)
    {
      NSLog(@"Failed to open audio codec.");
      return;
    }

  _audioFrame = av_frame_alloc();
  swr_alloc_set_opts2(&_swrCtx,
		      &(AVChannelLayout){ .order = AV_CHANNEL_ORDER_NATIVE,
			  .nb_channels = out_channels,
			  .u.mask = AV_CH_LAYOUT_STEREO },
		      AV_SAMPLE_FMT_S16,
		      _audioCodecCtx->sample_rate,
		      &_audioCodecCtx->ch_layout,
		      _audioCodecCtx->sample_fmt,
		      _audioCodecCtx->sample_rate,
		      0, NULL);
  int r = swr_init(_swrCtx);
  if (r == 0)
    {
      NSLog(@"[GSAudioPlayer] WARNING: swr_init returned 0");
    }

  memset(&_aoFmt, 0, sizeof(ao_sample_format));
  _aoFmt.bits = 16;
  _aoFmt.channels = out_channels;
  _aoFmt.rate = _audioCodecCtx->sample_rate;
  _aoFmt.byte_format = AO_FMT_NATIVE;

  // Configure audio device options for better buffering.
  ao_option *options = NULL;
  ao_append_option(&options, "buffer_time", "100000");

  NSLog(@"[GSAudioPlayer] Initializing audio: %d Hz, %d channels",
        _audioCodecCtx->sample_rate, out_channels);

  _aoDev = ao_open_live(driver, &_aoFmt, options);
  if (_aoDev == NULL)
    {
      NSLog(@"[GSAudioPlayer] Failed to open audio device");
      ao_free_options(options);
      return;
    }
  
  ao_free_options(options);
  _timeBase = formatCtx->streams[audioStreamIndex]->time_base;
  _audioClock = 0;
  _audioBaseTime = 0;
  _audioPackets = [[NSMutableArray alloc] init];
  _audioPacketCursor = 0;
  _running = YES;
}

- (void)audioThreadEntry
{
  while (_running)
    {
      // create pool...
      CREATE_AUTORELEASE_POOL(pool);
      {
	NSDictionary *dict = nil;
	
	@synchronized (_audioPackets)
	  {
	    if (_audioPacketCursor < [_audioPackets count])
	      {
		dict = [[_audioPackets objectAtIndex: _audioPacketCursor] retain];
		_audioPacketCursor++;

		if (_audioPacketCursor > 256
		    && _audioPacketCursor * 2 > [_audioPackets count])
		  {
		    [_audioPackets removeObjectsInRange:
		      NSMakeRange(0, _audioPacketCursor)];
		    _audioPacketCursor = 0;
		  }
	      }
	  }
	
	if (!_started && dict)
	  {
	    int64_t packetPts = [[dict objectForKey: @"pts"] longLongValue];

	    _audioStartTime = av_gettime();
	    _audioBaseTime = (packetPts == AV_NOPTS_VALUE)
	      ? 0
	      : av_rescale_q(packetPts, _timeBase, (AVRational){1, 1000000});
	    _audioClock = _audioBaseTime;
	    _totalSamplesPlayed = 0;
	    _started = YES;
	    NSLog(@"[GSAudioPlayer] Audio playback started | Timestamp: %ld", _audioStartTime);
	  }
	
	if (dict)
	  {
	    AVPacket packet = AVPacketFromNSDictionary(dict);

	    int samplesDecoded = [self decodePacket:&packet];
	    _totalSamplesPlayed += samplesDecoded;
	    _audioClock = _audioBaseTime
	      + (_totalSamplesPlayed * 1000000LL / _audioCodecCtx->sample_rate);
	    
	    [dict release];
	  }
	else
	  {
	    usleep(1000);
	  }
      }
      RELEASE(pool);
    }
}

- (int)decodePacket: (AVPacket *)packet
{
  int totalSamples = 0;
  
  if (!_audioCodecCtx || !_swrCtx || !_aoDev)
    {
      return 0;
    }

  if (avcodec_send_packet(_audioCodecCtx, packet) < 0)
    {
      return 0;
    }

  if (packet->flags & AV_PKT_FLAG_CORRUPT)
    {
      NSLog(@"Skipping corrupt audio packet");
      return 0;
    }

  while (avcodec_receive_frame(_audioCodecCtx, _audioFrame) == 0)
    {
      int outSamples = _audioFrame->nb_samples;
      int outBytes = av_samples_get_buffer_size(NULL, 2, outSamples, AV_SAMPLE_FMT_S16, 1);
      uint8_t *outBuf = (uint8_t *) malloc(outBytes);
      uint8_t *outPtrs[] = { outBuf };

      int convertedSamples = swr_convert(_swrCtx, outPtrs, outSamples,
					 (const uint8_t **) _audioFrame->data,
					 outSamples);

      if (convertedSamples > 0)
        {
          // Apply volume
          int16_t *samples = (int16_t *)outBuf;
          int sampleCount = convertedSamples * 2; // stereo
          
          for (int i = 0; i < sampleCount; ++i)
            {
              if ([self isMuted])
                {
                  samples[i] = 0;
                }
              else
                {
                  samples[i] = (int16_t)(samples[i] * _volume);
                }
            }

          // Play the audio - this will block until the audio device is ready
          ao_play(_aoDev, (char *) outBuf, convertedSamples * 2 * sizeof(int16_t));
          totalSamples += convertedSamples;
        }
      
      free(outBuf);
    }
  
  return totalSamples;
}

- (void) submitPacket: (AVPacket *)packet
{
  NSDictionary *dict = NSDictionaryFromAVPacket(packet);
  @synchronized (_audioPackets)
    {
      [_audioPackets addObject: dict];
    }
}

- (void) startAudio
{
  if (_audioThread != nil && [_audioThread isFinished] == NO)
    {
      return;
    }

  if (_audioThread != nil)
    {
      DESTROY(_audioThread);
    }

  _running = YES;
  _started = NO; // Will be set to YES when first packet is processed
  NSLog(@"[GSAudioPlayer] Starting audio thread | Timestamp: %ld", av_gettime());
  _audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(audioThreadEntry) object:nil];
  [_audioThread start];
}

- (void) stopAudio
{
  _running = NO;
  _started = NO; // Reset synchronization state
  _audioStartTime = 0;
  _audioBaseTime = 0;
  _totalSamplesPlayed = 0;

  if (_audioThread == nil)
    {
      return;
    }

  [_audioThread cancel];

  while ([_audioThread isFinished] == NO)
    {
      usleep(1000);
    }

  DESTROY(_audioThread);
  NSLog(@"[GSAudioPlayer] Audio thread stopped | Timestamp: %ld", av_gettime());
}

- (void) setVolume: (float)volume
{
  if (volume < 0.0)
    {
      volume = 0.0;
    }

  if (volume > 1.0)
    {
      volume = 1.0;
    }

  _volume = volume;
}

- (float) volume
{
  return _volume;
}

- (void) setMuted: (BOOL)muted
{
  _muted = muted;
}

- (BOOL) isMuted
{
  return _muted;
}

// Seeking methods
- (BOOL) seekToTime: (int64_t)timestamp
{
  // Clear existing audio packets
  @synchronized (_audioPackets)
    {
      [_audioPackets removeAllObjects];
      _audioPacketCursor = 0;
    }
  
  // Reset codec state
  if (_audioCodecCtx)
    {
      avcodec_flush_buffers(_audioCodecCtx);
    }
  
  // Reset the audio clock and synchronization state
  // The clock will be properly initialized when the next packet is processed
  _audioClock = timestamp;
  _audioBaseTime = timestamp;
  _totalSamplesPlayed = 0;
  _started = NO; // Will be reset when first packet after seek is processed
  
  NSLog(@"[GSAudioPlayer] Audio seek to timestamp %ld", timestamp);
  return YES;
}

// Audio clock access for synchronization
- (int64_t) currentAudioClock
{
  return _audioClock;
}

- (BOOL) isAudioStarted
{
  return _started;
}

- (int64_t) currentPlaybackTime
{
  if (_started && _audioCodecCtx)
    {
      int64_t elapsed = av_gettime() - _audioStartTime;
      int64_t decoded = _totalSamplesPlayed * 1000000LL / _audioCodecCtx->sample_rate;

      if (elapsed < 0)
	{
	  elapsed = 0;
	}
      if (elapsed > decoded)
	{
	  elapsed = decoded;
	}

      return _audioBaseTime + elapsed;
    }
  return 0;
}

// Debug method to check buffer status
- (NSUInteger) audioPacketBufferCount
{
  @synchronized (_audioPackets)
    {
      return [_audioPackets count];
    }
}

@end
