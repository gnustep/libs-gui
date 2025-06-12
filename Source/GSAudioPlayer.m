/** <title>GSAudioPlayer</title>

   <abstract>Encapsulate a movie</abstract>

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
      _audioPackets = nil;
      _audioThread = nil;
      _running = NO;
      _volume = 1.0;
      _started = NO;
      _paused = NO;
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

- (void) setPaused: (BOOL)f;
{
  _paused = f;
}

- (BOOL) isPaused
{
  return _paused;
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

- (void) prepareAudioWithFormatContext: (AVFormatContext *)formatCtx
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

  _aoDev = ao_open_live(driver, &_aoFmt, NULL);
  _timeBase = formatCtx->streams[audioStreamIndex]->time_base;
  _audioClock = av_gettime();
  _audioPackets = [[NSMutableArray alloc] init];
  _running = YES;
}

- (void)audioThreadEntry
{
  while (_running)
    {
      // Stop reading packets while paused...
      if (_paused == YES)
	{
	  usleep(10000); // 10ms pause
	  continue; // start the loop again...
	}

      // create pool...
      CREATE_AUTORELEASE_POOL(pool);
      {
	NSDictionary *dict = nil;
	
	@synchronized (_audioPackets)
	  {
	    if ([_audioPackets count] > 0)
	      {
		dict = [[_audioPackets objectAtIndex:0] retain];
		[_audioPackets removeObjectAtIndex:0];
	      }
	  }
	
	if (!_started && dict)
	  {
	    _audioClock = av_gettime();
	    _started = YES;
	  }
	
	if (dict)
	  {
	    AVPacket packet = AVPacketFromNSDictionary(dict);
	    int64_t packetTime = av_rescale_q(packet.pts, _timeBase, (AVRational){1, 1000000});
	    int64_t now = av_gettime() - _audioClock;
	    int64_t delay = packetTime - now;

	    if (delay > 0)
	      {
		usleep((useconds_t)delay); //  + 50000);
	      }
	    
	    [self decodeAudioPacket:&packet];
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

- (void)decodeAudioPacket: (AVPacket *)packet
{
  if (!_audioCodecCtx || !_swrCtx || !_aoDev)
    {
      return;
    }

  if (avcodec_send_packet(_audioCodecCtx, packet) < 0)
    {
      return;
    }

  if (packet->flags & AV_PKT_FLAG_CORRUPT)
    {
      NSLog(@"Skipping corrupt audio packet");
      return;
    }

  while (avcodec_receive_frame(_audioCodecCtx, _audioFrame) == 0)
    {
      int outSamples = _audioFrame->nb_samples;
      int outBytes = av_samples_get_buffer_size(NULL, 2, outSamples, AV_SAMPLE_FMT_S16, 1);
      uint8_t *outBuf = (uint8_t *) malloc(outBytes);
      uint8_t *outPtrs[] = { outBuf };

      swr_convert(_swrCtx, outPtrs, outSamples,
		  (const uint8_t **) _audioFrame->data,
		  outSamples);

      // Apply volume
      int16_t *samples = (int16_t *)outBuf;
      int i = 0;
      for (i = 0; i < outBytes / 2; ++i)
	{
	  if ([self isMuted])
	    {
	      samples[i] = 0.0;
	    }
	  else
	    {
	      samples[i] = samples[i] * _volume;
	    }
	}

      ao_play(_aoDev, (char *) outBuf, outBytes);
      free(outBuf);
    }
}

- (void) submitPacket: (AVPacket *)packet
{
  NSDictionary *dict = NSDictionaryFromAVPacket(packet);

  if (_paused)
    {
      NSLog(@"Submitted audio packet...");
    }

  @synchronized (_audioPackets)
    {
      [_audioPackets addObject: dict];
    }
}

- (void) startAudio
{
  _running = YES;
  NSLog(@"[GSAudioPlayer] Starting audio thread | Timestamp: %ld", av_gettime());
  _audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(audioThreadEntry) object:nil];
  [_audioThread start];
}

- (void) stopAudio
{
  _running = NO;
  [_audioThread cancel];

  while ([_audioThread isFinished] == NO)
    {
      usleep(1000);
    }

  DESTROY(_audioThread);
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

@end
