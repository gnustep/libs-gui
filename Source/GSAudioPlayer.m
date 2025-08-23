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

#define BUFFER_SIZE 2048

@implementation GSAudioPlayer
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      [self reset];
    }
  return self;
}

- (void)dealloc
{
  [self reset];
  [super dealloc];
}

- (void) reset
{
  [self stop];
  [self cleanupTimeStretching];

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

  if (_audioBuffer)
    {
      free(_audioBuffer);
      _audioBuffer = NULL;
      _audioBufferSize = 0;
    }

  if (_aoDev)
    {
      ao_close(_aoDev);
    }

  RELEASE(_audioPackets);

  ao_shutdown();

  // Reset all ivars...
  _audioPackets = [[NSMutableArray alloc] initWithCapacity: BUFFER_SIZE];
  _audioThread = nil;

  _audioCodecCtx = NULL;
  _audioFrame = NULL;
  _swrCtx = NULL;
  _audioClock = 0;
  _running = NO;
  _volume = 1.0;
  _playbackRate = 1.0;
  _started = NO;
  _loopMode = NSQTMovieNormalPlayback;

  // Initialize reusable audio buffer
  _audioBuffer = NULL;
  _audioBufferSize = 0;

  // Initialize time stretching components
  _stretchSwrCtx = NULL;
  _stretchedFrame = NULL;
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

  _formatCtx = formatCtx;
  _audioStreamIndex = audioStreamIndex;

  AVStream *audioStream = formatCtx->streams[_audioStreamIndex];
  AVCodecParameters *audioPar = audioStream->codecpar;
  const AVCodec *audioCodec = avcodec_find_decoder(audioPar->codec_id);

  _stream = audioStream;

  if (!audioCodec)
    {
      NSLog(@"Audio codec not found.");
      return;
    }

  if (_audioCodecCtx != NULL)
    {
      NSLog(@"Audio codec already initialized");
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

  // Configure audio device options for better buffering to reduce skipping
  ao_option *options = NULL;

  // Set buffer size to reduce skipping (in bytes)
  // Calculate buffer for about 100ms of audio
  int bufferSamples = _audioCodecCtx->sample_rate / 10; // 100ms
  int bufferSize = bufferSamples * out_channels * 2; // 16-bit stereo
  char bufferSizeStr[32];
  snprintf(bufferSizeStr, sizeof(bufferSizeStr), "%d", bufferSize);
  ao_append_option(&options, "buffer_time", "100000"); // 100ms in microseconds

  NSLog(@"[GSAudioPlayer] Initializing audio: %d Hz, %d channels, buffer size: %d bytes",
	_audioCodecCtx->sample_rate, out_channels, bufferSize);

  _aoDev = ao_open_live(driver, &_aoFmt, options);
  if (_aoDev == NULL)
    {
      NSLog(@"[GSAudioPlayer] Failed to open audio device");
      ao_free_options(options);
      return;
    }

  ao_free_options(options);
  _timeBase = formatCtx->streams[_audioStreamIndex]->time_base;
  _audioClock = av_gettime();

  // Initialize time stretching for sample rate changes
  if (![self initializeTimeStretching])
    {
      NSLog(@"[GSAudioPlayer] Warning: Failed to initialize time stretching");
    }
}

- (void)audioThreadEntry
{
  int64_t audioStartTime = 0;
  int64_t totalSamplesPlayed = 0;

  while (_running)
    {
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
	    audioStartTime = av_gettime();
	    totalSamplesPlayed = 0;
	    _started = YES;
	    NSLog(@"[GSAudioPlayer] Audio playback started | Timestamp: %ld", audioStartTime);
	  }

	if (dict)
	  {
	    AVPacket packet = AVPacketFromNSDictionary(dict);

	    // Calculate expected playback time based on samples played
	    int64_t expectedTime = audioStartTime + (totalSamplesPlayed * 1000000LL / _audioCodecCtx->sample_rate);
	    int64_t currentTime = av_gettime();

	    // Only delay if we're ahead of schedule by more than 5ms to reduce skipping
	    int64_t timingError = expectedTime - currentTime;
	    if (timingError > 5000) // 5ms threshold
	      {
		usleep((useconds_t)timingError);
	      }

	    // Update audio clock for video synchronization
	    // The audio clock represents the actual time of the audio currently being played
	    _audioClock = audioStartTime + (totalSamplesPlayed * 1000000LL / _audioCodecCtx->sample_rate);

	    // Debug logging for audio clock updates (reduced frequency)
	    if (totalSamplesPlayed % (_audioCodecCtx->sample_rate / 4) == 0) // Log 4 times per second
	      {
		NSLog(@"[GSAudioPlayer] Audio clock: %ld | PTS: %ld | Samples: %ld | Timing error: %ld us\n",
			_audioClock, packet.pts, totalSamplesPlayed, timingError);
	      }

	    // Decode and play the packet
	    int samplesDecoded = [self decodePacket:&packet];
	    totalSamplesPlayed += samplesDecoded;

	    [dict release];
	  }
	else
	  {
	    // No packets available - wait a bit longer to avoid busy waiting
	    usleep(5000); // 5ms
	  }
      }
      RELEASE(pool);
    }
}

- (int) decodePacket: (AVPacket *)packet
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
      AVFrame *frameToProcess = _audioFrame;

      // Apply time stretching if rate is not 1.0
      if (_playbackRate != 1.0f && _stretchSwrCtx)
	{
	  // Calculate new sample rate for time stretching
	  int stretchedSampleRate = (int)(_audioCodecCtx->sample_rate / _playbackRate);

	  // Convert to stretched sample rate
	  int maxOutSamples = swr_get_out_samples(_stretchSwrCtx, _audioFrame->nb_samples);

	  if (!_stretchedFrame)
	    {
	      _stretchedFrame = av_frame_alloc();
	      _stretchedFrame->format = AV_SAMPLE_FMT_S16;
	      _stretchedFrame->ch_layout = _audioFrame->ch_layout;
	      _stretchedFrame->sample_rate = stretchedSampleRate;
	    }

	  _stretchedFrame->nb_samples = maxOutSamples;
	  av_frame_get_buffer(_stretchedFrame, 0);

	  int convertedSamples = swr_convert(_stretchSwrCtx,
					   _stretchedFrame->data, maxOutSamples,
					   (const uint8_t **)_audioFrame->data, _audioFrame->nb_samples);

	  if (convertedSamples > 0)
	    {
	      _stretchedFrame->nb_samples = convertedSamples;
	      frameToProcess = _stretchedFrame;
	    }
	}

      int outSamples = frameToProcess->nb_samples;
      int outBytes = av_samples_get_buffer_size(NULL, 2, outSamples, AV_SAMPLE_FMT_S16, 1);

      // Ensure our reusable buffer is large enough
      if (_audioBufferSize < outBytes)
	{
	  if (_audioBuffer)
	    {
	      free(_audioBuffer);
	    }
	  _audioBuffer = (uint8_t *) malloc(outBytes);
	  _audioBufferSize = outBytes;
	  NSLog(@"[GSAudioPlayer] Allocated audio buffer: %d bytes", outBytes);
	}

      uint8_t *outPtrs[] = { _audioBuffer };

      int convertedSamples = swr_convert(_swrCtx, outPtrs, outSamples,
					 (const uint8_t **) frameToProcess->data,
					 outSamples);

      if (convertedSamples > 0)
	{
	  // Apply volume
	  int16_t *samples = (int16_t *)_audioBuffer;
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
	  ao_play(_aoDev, (char *) _audioBuffer, convertedSamples * 2 * sizeof(int16_t));
	  totalSamples += convertedSamples;
	}

      // Unref stretched frame if we used it
      if (frameToProcess == _stretchedFrame)
	{
	  av_frame_unref(_stretchedFrame);
	}
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

/*
- (void) startAudio
{
  _running = YES;
  _started = NO; // Will be set to YES when first packet is processed
  NSLog(@"[GSAudioPlayer] Starting audio thread | Timestamp: %ld", av_gettime());
  _audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(audioThreadEntry) object:nil];
  [_audioThread start];
}

- (void) stopAudio
{
  _running = NO;
  [_audioThread cancel];

  while ([_audioThread isFinished] == NO && _started)
    {
      usleep(1000);
    }

  _started = NO; // Reset synchronization state
  DESTROY(_audioThread);
  NSLog(@"[GSAudioPlayer] Audio thread stopped | Timestamp: %ld", av_gettime());
}
*/

- (void) setNeedsRestart: (BOOL)f
{
  _needsRestart = f;
}

- (void) start
{
  @synchronized(self)
    {
      if (_running)
	{
	  NSLog(@"[GSAudioPlayer] Already running, ignoring start request | Timestamp: %ld", av_gettime());
	  return;
	}

      if (!_formatCtx || !_stream)
	{
	  NSLog(@"[GSAudioPlayer] Cannot start - no media loaded | Timestamp: %ld", av_gettime());
	  return;
	}

      // NSLog(@"[GSAudioPlayer] Starting video playback | Timestamp: %ld, lastPts = %ld",
      //    av_gettime(), _lastPts);

      _running = YES;
      _started = NO; // Reset for synchronization

      if (_needsRestart)
	{
	  NSLog(@"[GSAudioPlayer] Restarting from EOF, seeking to beginning | Timestamp: %ld", av_gettime());
	  _needsRestart = NO;

	  // Clear existing video packets
	  @synchronized (_audioPackets)
	    {
	      [_audioPackets removeAllObjects];
	    }

	  // Seek back to the beginning
	  if (av_seek_frame(_formatCtx, _audioStreamIndex, 0, AVSEEK_FLAG_BACKWARD) >= 0)
	    {
	      // Reset codec state
	      if (_audioCodecCtx)
		{
		  avcodec_flush_buffers(_audioCodecCtx);
		}
	    }
	  else
	    {
	      NSLog(@"[GSAudioPlayer] Failed to seek back to beginning for restart | Timestamp: %ld", av_gettime());
	    }
	}

      // Start video processing thread
      if (_audioThread == nil || [_audioThread isFinished])
	{
	  // Clean up old thread reference if it finished
	  if (_audioThread && [_audioThread isFinished])
	    {
	      DESTROY(_audioThread);
	    }

	  _audioThread = [[NSThread alloc] initWithTarget:self
						 selector:@selector(audioThreadEntry)
						   object:nil];
	  [_audioThread start];
	}

      NSLog(@"[GSAudioPlayer] Video playback started successfully | Timestamp: %ld", av_gettime());
    }
}

- (void) stop
{
  @synchronized(self)
    {
      if (!_running)
	{
	  NSLog(@"[GSAudioPlayer] Already stopped, ignoring stop request | Timestamp: %ld", av_gettime());
	  return;
	}

      // NSLog(@"[GSAudioPlayer] Stopping audio playback | Timestamp: %ld, lastPts = %ld",
      //    av_gettime(), _lastPts);

      // _needsRestart = YES;
      _running = NO;

      // Cancel and wait for video thread
      if (_audioThread)
	{
	  [_audioThread cancel];

	  // Wait for video thread to finish with timeout
	  int timeout = 1000; // 1 second timeout
	  while (![_audioThread isFinished] && timeout > 0)
	    {
	      usleep(1000); // 1ms
	      timeout--;
	    }

	  if (timeout <= 0)
	    {
	      NSLog(@"[GSAudioPlayer] Warning: Audio thread did not finish within timeout");
	    }

	  DESTROY(_audioThread);
	}

      // Clear video packet queue
      @synchronized (_audioPackets)
	{
	  [_audioPackets removeAllObjects];
	}

      NSLog(@"[GSAudioPlayer] Audio playback stopped successfully | Timestamp: %ld", av_gettime());
    }
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

  // Muted...
  if (volume <= 0.0)
    {
      _muted = YES;
    }
  else if (volume > 0.0)
    {
      _muted = NO;
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
    }

  // Reset codec state
  if (_audioCodecCtx)
    {
      avcodec_flush_buffers(_audioCodecCtx);
    }

  // Reset the audio clock and synchronization state
  // The clock will be properly initialized when the next packet is processed
  _audioClock = timestamp;
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
  if (_started)
    {
      // Return the current audio clock time
      return _audioClock;
    }
  return 0;
}

// Time stretching support
- (float) playbackRate
{
  return _playbackRate;
}

- (void) setPlaybackRate: (float)rate
{
  if (rate < 0.5f) rate = 0.5f;
  if (rate > 2.0f) rate = 2.0f;

  if (_playbackRate != rate)
    {
      _playbackRate = rate;

      // Reinitialize time stretching if it's already set up
      if (_stretchSwrCtx)
	{
	  [self cleanupTimeStretching];
	  [self initializeTimeStretching];
	}

      NSLog(@"[GSAudioPlayer] Set playback rate to %.2f", rate);
    }
}

- (BOOL) initializeTimeStretching
{
  if (!_audioCodecCtx)
    {
      NSLog(@"[GSAudioPlayer] Cannot initialize time stretching - no audio codec context");
      return NO;
    }

  // Clean up existing context
  [self cleanupTimeStretching];

  if (_playbackRate == 1.0f)
    {
      // No stretching needed
      return YES;
    }

  // Calculate stretched sample rate
  int stretchedSampleRate = (int)(_audioCodecCtx->sample_rate / _playbackRate);

  // Create resampler for time stretching
  swr_alloc_set_opts2(&_stretchSwrCtx,
		      &_audioCodecCtx->ch_layout,
		      AV_SAMPLE_FMT_S16,
		      stretchedSampleRate,  // Output at different rate for time stretch
		      &_audioCodecCtx->ch_layout,
		      _audioCodecCtx->sample_fmt,
		      _audioCodecCtx->sample_rate,
		      0, NULL);

  int ret = swr_init(_stretchSwrCtx);
  if (ret < 0)
    {
      NSLog(@"[GSAudioPlayer] Failed to initialize time stretching resampler");
      [self cleanupTimeStretching];
      return NO;
    }

  NSLog(@"[GSAudioPlayer] Time stretching initialized with rate %.2f (sample rate: %d -> %d)",
	_playbackRate, _audioCodecCtx->sample_rate, stretchedSampleRate);
  return YES;
}

- (void) cleanupTimeStretching
{
  if (_stretchedFrame)
    {
      av_frame_free(&_stretchedFrame);
      _stretchedFrame = NULL;
    }

  if (_stretchSwrCtx)
    {
      swr_free(&_stretchSwrCtx);
      _stretchSwrCtx = NULL;
    }
}

@end
