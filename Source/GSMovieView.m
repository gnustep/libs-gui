/** <title>GSMovieView</title>

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

#import "config.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSURL.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageRep.h"
#import "AppKit/NSMovie.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSSound.h"

#import "GSMovieView.h"

#include <libswresample/swresample.h>

static NSNotificationCenter *nc = nil;

static NSDictionary *NSDictionaryFromAVPacket(AVPacket *packet)
{
  NSData *data = [NSData dataWithBytes:packet->data length:packet->size];
  NSNumber *pts = [NSNumber numberWithLongLong:packet->pts];
  NSNumber *duration = [NSNumber numberWithInt:packet->duration];
  NSNumber *flags = [NSNumber numberWithInt:packet->flags];

  return [NSDictionary dictionaryWithObjectsAndKeys:
			 data, @"data",
		       pts, @"pts",
		       duration, @"duration",
		       flags, @"flags",
		       nil];
}

static AVPacket AVPacketFromNSDictionary(NSDictionary *dict)
{
  NSData *data = [dict objectForKey:@"data"];
  NSNumber *pts = [dict objectForKey:@"pts"];
  NSNumber *duration = [dict objectForKey:@"duration"];
  NSNumber *flags = [dict objectForKey:@"flags"];

  AVPacket *packet = av_packet_alloc();
  packet->data = (uint8_t *)[data bytes];
  packet->size = (int)[data length];
  packet->pts = [pts longLongValue];
  packet->duration = [duration intValue];
  packet->flags = [flags intValue];

  return *packet;
}

// Ignore the warning this will produce as it is intentional.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

// Category smash this method to get the proper types.
@interface NSMovie (AVCodec)
@end

@implementation NSMovie (AVCodec)

+ (NSArray*) movieUnfilteredFileTypes
{
  NSMutableSet *extensionsSet = [NSMutableSet set];
  void *opaque = NULL;
  const AVOutputFormat *ofmt = NULL;

  // Iterate over all muxers
  while ((ofmt = av_muxer_iterate(&opaque)))
    {
      if (ofmt->extensions)
	{
	  NSString *extString = [NSString stringWithUTF8String:ofmt->extensions];
	  NSArray *exts = [extString componentsSeparatedByString:@","];
	  [extensionsSet addObjectsFromArray: exts];
	}
    }

    // Convert to sorted array
    NSArray *sortedExtensions = [[extensionsSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    return sortedExtensions;
}

+ (NSArray*) movieUnfilteredPasteboardTypes
{
  NSMutableSet *result = [NSMutableSet set];
  const AVCodec *codec = NULL;
  void *i = 0;

  while ((codec = av_codec_iterate(&i)))
    {
      if (av_codec_is_decoder(codec) && codec->type == AVMEDIA_TYPE_VIDEO)
	{
	  [result addObject: [NSString stringWithUTF8String: codec->name]];
	}
    }

  // Convert to sorted array
  NSArray *sorted = [[result allObjects] sortedArrayUsingSelector:@selector(compare:)];
  return sorted;
}

@end

#pragma clang diagnostic pop

// Audio player for NSMovieView...
@interface GSAudioPlayer : NSObject
{
  AVCodecContext *_audioCodecCtx;
  AVFrame *_audioFrame;
  SwrContext *_swrCtx;
  ao_device *_aoDev;
  ao_sample_format _aoFmt;
  int64_t _audioClock;
  AVRational _timeBase;
  BOOL _running;
  float _volume; /* 0.0 to 1.0 */
  BOOL _started;
  unsigned int _loopMode:3;
  BOOL _muted;

  NSMutableArray *_audioPackets;
  NSThread *_audioThread;
}

- (void) prepareAudioWithFormatContext: (AVFormatContext *)formatCtx
			   streamIndex: (int)audioStreamIndex;
- (void) decodeAudioPacket: (AVPacket *)packet;
- (void) startAudio;
- (void) stopAudio;

- (float) volume;
- (void) setVolume: (float)volume;

- (NSQTMovieLoopMode) loopMode;
- (void) setLoopMode: (NSQTMovieLoopMode)mode;

- (BOOL) isMuted;
- (void) setMuted: (BOOL)muted;

@end

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
      NSLog(@"[GSMovieView] WARNING: swr_init returned 0");
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
      CREATE_AUTORELEASE_POOL(pool);
      {
	NSDictionary *dict = nil;

	@synchronized (_audioPackets)
	  {
	    if (!_started && [_audioPackets count] < 5)
	      {
		usleep(5000);
		continue;
	      }
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
	      usleep((useconds_t)delay);

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

- (void)submitPacket: (AVPacket *)packet
{
  NSDictionary *dict = NSDictionaryFromAVPacket(packet);
  @synchronized (_audioPackets)
    {
      [_audioPackets addObject: dict];
    }
}

- (void)startAudio
{
  NSLog(@"[GSMovieView] Starting audio thread | Timestamp: %ld", av_gettime());
  _audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(audioThreadEntry) object:nil];
  [_audioThread start];
}

- (void)stopAudio
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

// NSMovieView subclass that does all of the actual work of decoding...
@implementation GSMovieView

+ (void) initialize
{
  if (self == [GSMovieView class])
    {
      if (nc == nil)
	{
	  nc = [NSNotificationCenter defaultCenter];
	}
    }
}

- (instancetype) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      _currentFrame = nil;
      _videoThread = nil;
      _feedThread = nil;
      _audioPlayer = [[GSAudioPlayer alloc] init];
      _videoPackets = [[NSMutableArray alloc] init];
      _running = NO;
      _started = NO;
      _videoClock = 0;
      _videoCodecCtx = NULL;
      _formatCtx = NULL;
      _swsCtx = NULL;
      _lastPts = 0;
      // NSApplicationWillTerminateNotification
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSApplicationWillTerminateNotification
	       object: nil];
    }
  return self;
}

- (void)dealloc
{
  [self stop: nil];

  if (_feedThread)
    {
      [_feedThread cancel];
      DESTROY(_feedThread);
    }

  if (_videoFrame)
    {
      av_frame_free(&_videoFrame);
    }

  if (_videoCodecCtx)
    {
      avcodec_free_context(&_videoCodecCtx);
    }

  if (_swsCtx)
    {
      sws_freeContext(_swsCtx);
    }

  TEST_RELEASE(_currentFrame);
  DESTROY(_videoPackets);
  DESTROY(_audioPlayer);
  [nc removeObserver: self];

  [super dealloc];
}

// Notification responses...
- (void) handleNotification: (NSNotification *)notification
{
  NSLog(@"[GSMovieView] Shutting down, final pts %ld", _lastPts);
  
  [_feedThread cancel];
  [_videoThread cancel];
  [_audioPlayer stopAudio];
  [self stopVideo];
}

// Private methods...
- (void) _resetFeed: (int64_t)pts
{
  [self stop: nil];
  _savedPts = pts;
  // [self start: nil];
}

// Overridden methods from the superclass...
- (BOOL) isPlaying
{
  return _running;
}

- (IBAction) start: (id)sender
{
  if (_running == NO)
    {
      [self setRate: 1.0 / 30.0];
      [self setVolume: 1.0];

      _feedThread = [[NSThread alloc] initWithTarget:self selector:@selector(feedVideo) object:nil];
      [_feedThread start];
      [_audioPlayer startAudio];
    }
}

- (IBAction) stop: (id)sender
{
  if (_running)
    {
      [_feedThread cancel];
      [self stopVideo];
      [_audioPlayer stopAudio];
      
      DESTROY(_feedThread);    
    }
}

- (void) setMuted: (BOOL)muted
{
  [super setMuted: muted];
  [_audioPlayer setMuted: muted];
}

- (void) setVolume: (float)volume
{
  [super setVolume: volume];
  [_audioPlayer setVolume: volume];
}

- (void) setLoopMode: (NSQTMovieLoopMode)mode
{
  [super setLoopMode: mode];
}

- (NSRect) movieRect
{
  AVFormatContext* fmt_ctx = NULL;
  NSURL *url = [[self movie] URL];
  const char *name = [[url path] UTF8String];

  // I realize this is inefficient, but there is a race condition
  // which occurs when setting this from the existing stream.
  // The issue with using the ivars is that they are initialized on
  // a thread, so they may not be set when this is called.
  
  // Open video file
  avformat_open_input(&fmt_ctx, name, NULL, NULL);
  avformat_find_stream_info(fmt_ctx, NULL);

  // Find the first video stream
  int video_stream_index = -1;
  unsigned int i = 0;
  for (i = 0; i < fmt_ctx->nb_streams; i++)
    {
      if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO)
	{
	  video_stream_index = i;
	  break;
	}
    }

  // Retrieve codec parameters
  AVCodecParameters* codecpar =
    fmt_ctx->streams[video_stream_index]->codecpar;

  // These are your video dimensions:
  CGFloat width = (CGFloat)(codecpar->width);
  CGFloat height = (CGFloat)(codecpar->height);

  return NSMakeRect(0.0, 0.0, width, height);
}

- (IBAction)gotoPosterFrame: (id)sender
{
  [self _resetFeed: _savedPts];
  NSLog(@"[GSMovieView] gotoPosterFrame called | Timestamp: %ld", av_gettime());
}

- (IBAction)gotoBeginning: (id)sender
{
  [self _resetFeed: _savedPts];
  NSLog(@"[GSMovieView] gotoBeginning called | Timestamp: %ld", av_gettime());
}

- (IBAction)gotoEnd: (id)sender
{
  NSLog(@"_videoStreamIndex = %d", _videoStreamIndex);
  AVStream *videoStream = _formatCtx->streams[_videoStreamIndex];
  int64_t duration = videoStream->duration;
  // AVRational timeBase = videoStream->time_base;

  [self stop: nil];
  
  // Seek near the end (some formats don't like seeking to exact end)
  int64_t seekTarget = duration - (AV_TIME_BASE / 10); // a bit before the end
  av_seek_frame(_formatCtx, _videoStreamIndex, seekTarget, AVSEEK_FLAG_BACKWARD);

  // Flush decoder
  avcodec_flush_buffers(_videoCodecCtx);

  // Read packets and decode
  AVPacket packet;
  while (av_read_frame(_formatCtx, &packet) >= 0)
    {
      if (packet.stream_index == _videoStreamIndex)
	{
	  if (avcodec_send_packet(_videoCodecCtx, &packet) == 0)
	    {
	      AVFrame *frame = av_frame_alloc();
	      if (avcodec_receive_frame(_videoCodecCtx, frame) == 0)
		{
		  // Convert & render this frame
		  [self renderFrame: frame];
		  av_frame_free(&frame);
		  break;
		}
	      av_frame_free(&frame);
	    }
	}
      av_packet_unref(&packet);
    }
}

- (IBAction) stepForward: (id)sender
{
}

- (IBAction) stepBack: (id)sender
{
}

// Video playback methods...
- (void) updateImage: (NSImage *)image
{
  ASSIGN(_currentFrame, image);
  [self setNeedsDisplay:YES];
}

- (void) drawRect: (NSRect)dirtyRect
{
  [super drawRect: dirtyRect];
  if (_currentFrame)
    {
      [_currentFrame drawInRect: [self bounds]];
    }
}

- (void) feedVideo
{
  NSMovie *movie = [self movie];

  if (movie != nil)
    {
      NSURL *url = [movie URL];

      if (url != nil)
	{
	  const char *path = [[url path] UTF8String];

	  NSLog(@"[Info] Opening file: %s | Timestamp: %ld", path, av_gettime());
	  avformat_network_init();
	  if (avformat_open_input(&_formatCtx, path, NULL, NULL) != 0)
	    {
	      NSLog(@"[Error] Could not open file: %s | Timestamp: %ld", path, av_gettime());
	      return;
	    }

	  if (avformat_find_stream_info(_formatCtx, NULL) < 0)
	    {
	      NSLog(@"[Error] Could not find stream info. | Timestamp: %ld", av_gettime());
	      avformat_close_input(&_formatCtx);
	      return;
	    }

	  _videoStreamIndex = -1;
	  for (unsigned int i = 0; i < _formatCtx->nb_streams; i++)
	    {
	      if (_formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO)
		{
		  _videoStreamIndex = i;
		  break;
		}
	    }

	  _audioStreamIndex = -1;
	  for (unsigned int i = 0; i < _formatCtx->nb_streams; i++)
	    {
	      if (_formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO)
		{
		  _audioStreamIndex = i;
		  break;
		}
	    }

	  // Video stream...
	  if (_videoStreamIndex == -1)
	    {
	      NSLog(@"[Info] No video stream found. | Timestamp: %ld", av_gettime());
	    }
	  else
	    {
	      [self prepareVideoWithFormatContext: _formatCtx
				      streamIndex: _videoStreamIndex];
	    }

	  // Audio stream...
	  if (_audioStreamIndex == -1) // if we do have an audio stream, initialize it... otherwise log it
	    {
	      NSLog(@"[Info] No audio stream found. | Timestamp: %ld", av_gettime());
	    }
	  else
	    {
	      [_audioPlayer prepareAudioWithFormatContext: _formatCtx
					      streamIndex: _audioStreamIndex];
	    }

	  // Video and Audio stream not present...
	  if (_videoStreamIndex == -1 && _audioStreamIndex == -1)
	    {
	      NSLog(@"[Error] No video or audio stream detected, exiting");
	      avformat_close_input(&_formatCtx);
	      return;
	    }

	  AVPacket packet;
	  int64_t i = 0;

	  while (av_read_frame(_formatCtx, &packet) >= 0)
	    {
	      if (packet.pts <= _savedPts)
		{
		  continue;
		}
	      
	      // After 1000 frames, start the thread...
	      if (i == 1000)
		{
		  [self startVideo];
		  [_audioPlayer startAudio];
		}
		  
	      if (packet.stream_index == _videoStreamIndex)
		{
		  [self submitVideoPacket: &packet];
		}

	      if (packet.stream_index == _audioStreamIndex)
		{
		  [_audioPlayer submitPacket: &packet];
		}

	      av_packet_unref(&packet);
	      i++;
	    }

	  // if we had a very short video... play it.
	  if (i < 1000)
	    {
	      NSLog(@"[GSMovieView] Starting short video... | Timestamp: %ld", av_gettime());
	      [self startVideo];
	      [_audioPlayer startAudio];
	    }
	}
	  
      avformat_close_input(&_formatCtx);
    }
}

- (void)prepareVideoWithFormatContext: (AVFormatContext *)formatCtx streamIndex: (int)videoStreamIndex
{
  AVCodecParameters *videoPar = formatCtx->streams[videoStreamIndex]->codecpar;
  const AVCodec *videoCodec = avcodec_find_decoder(videoPar->codec_id);

  if (!videoCodec)
    {
      NSLog(@"[Error] Unsupported video codec. | Timestamp: %ld", av_gettime());
      return;
    }

  _videoCodecCtx = avcodec_alloc_context3(videoCodec);
  avcodec_parameters_to_context(_videoCodecCtx, videoPar);
  if (avcodec_open2(_videoCodecCtx, videoCodec, NULL) < 0)
    {
      NSLog(@"[Error] Failed to open video codec. | Timestamp: %ld", av_gettime());
      return;
    }

  // Configure the codec...
  _videoCodecCtx->thread_count = 4;
  _videoCodecCtx->thread_type = FF_THREAD_FRAME;
  _videoFrame = av_frame_alloc();
  _swsCtx = sws_getContext(videoPar->width,
			   videoPar->height,
			   _videoCodecCtx->pix_fmt,
			   videoPar->width,
			   videoPar->height,
			   AV_PIX_FMT_RGB24,
			   SWS_BILINEAR,
			   NULL, NULL, NULL);

  _timeBase = formatCtx->streams[videoStreamIndex]->time_base;
  _videoPackets = [[NSMutableArray alloc] init];
  _videoClock = av_gettime();
  _running = NO;
  _started = NO;
}

- (void) startVideo
{
  NSLog(@"[GSMovieView] Starting video thread | Timestamp: %ld, lastPts = %ld", av_gettime(), _lastPts);
  if (!_running)
    {
      _running = YES;
      _videoThread = [[NSThread alloc] initWithTarget:self selector:@selector(videoThreadEntry) object:nil];
      [_videoThread start];
    }
}

- (void) stopVideo
{
  NSLog(@"[GSMovieView] Stopping video thread | Timestamp: %ld, lastPts = %ld", av_gettime(), _lastPts);
  if (_running)
    {
      _running = NO;

      [_videoThread cancel];
      while (![_videoThread isFinished])
	{
	  usleep(1000);
	}
      
      DESTROY(_videoThread);
      avformat_close_input(&_formatCtx);

      _savedPts = _lastPts;
      _lastPts = 0;
    }
}

- (void)submitVideoPacket: (AVPacket *)packet
{
  NSDictionary *dict = NSDictionaryFromAVPacket(packet);
  @synchronized (_videoPackets)
    {
      [_videoPackets addObject: dict];
    }
}

- (void)videoThreadEntry
{
  while (_running)
    {
      CREATE_AUTORELEASE_POOL(pool);
	{
	  NSDictionary *dict = nil;

	  // Pop the video packet off _videoPackets, sync on
	  // the array.
	  @synchronized (_videoPackets)
	    {
	      if (!_started && [_videoPackets count] < 3)
		{
		  usleep(5000);
		  RELEASE(pool);
		  continue;
		}
	      if ([_videoPackets count] > 0)
		{
		  dict = RETAIN([_videoPackets objectAtIndex: 0]);
		  [_videoPackets removeObjectAtIndex: 0];
		}
	    }

	  // If the dict is present and the thread is started, get
	  // the clock.
	  if (!_started && dict)
	    {
	      _videoClock = av_gettime();
	      _started = YES;
	    }

	  // If dict is not nil, decode it and get the frame...
	  if (dict)
	    {
	      AVPacket packet = AVPacketFromNSDictionary(dict);

	      // If the current pts is at or after the saved,
	      // then alow it to be decoded and displayed...
	      if (packet.pts >= _savedPts)
		{
		  int64_t packetTime = av_rescale_q(packet.pts,
						    _timeBase,
						    (AVRational){1, 1000000});
		  int64_t now = av_gettime() - _videoClock;
		  int64_t delay = packetTime - now;

		  if (_statusField != nil)
		    {
		      // Show the information...
		      _statusString = [NSString stringWithFormat: @"Rendering video frame PTS: %ld | Delay: %ld us | %@",
						packet.pts, delay, _running ? @"Running" : @"Stopped"];
		      [_statusField setStringValue: _statusString];
		    }

		  // Show status on the command line...
		  fprintf(stderr, "[GSMovieView] Rendering video frame PTS: %ld | Delay: %ld us\r",
			  packet.pts, delay);
		  if (delay > 0)
		    {
		      usleep((useconds_t)delay);
		    }

		  // Decode the packet, display it and play the sound...
		  [self decodeVideoPacket: &packet];
		  RELEASE(dict);
		}
	      else
		{
		  usleep(1000);
		}
	    }
	  
	  RELEASE(pool);
	}
    }
}

- (void) renderFrame: (AVFrame *)videoFrame
{
  uint8_t *rgbData[1];
  int rgbLineSize[1];
  int width = _videoCodecCtx->width;
  int height = _videoCodecCtx->height;
  
  rgbLineSize[0] = width * 3;
  rgbData[0] = (uint8_t *)malloc(height * rgbLineSize[0]);
  
  sws_scale(_swsCtx,
	    (const uint8_t * const *)videoFrame->data,
	    videoFrame->linesize,
	    0,
	    height,
	    rgbData,
	    rgbLineSize);
  
  NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
				   initWithBitmapDataPlanes: &rgbData[0]
						 pixelsWide: width
						 pixelsHigh: height
					      bitsPerSample: 8
					    samplesPerPixel: 3
						   hasAlpha: NO
						   isPlanar: NO
					     colorSpaceName: NSCalibratedRGBColorSpace
						bytesPerRow: rgbLineSize[0]
					       bitsPerPixel: 24];
  
  NSImage *image = [[NSImage alloc] initWithSize: NSMakeSize(width, height)];
  [image addRepresentation: bitmap];
  [self performSelectorOnMainThread: @selector(updateImage:)
			 withObject: image
		      waitUntilDone: NO];
  
  RELEASE(image);
  RELEASE(bitmap);
  free(rgbData[0]);
}

- (void) decodeVideoPacket: (AVPacket *)packet
{
  if (!_videoCodecCtx || !_swsCtx)
    {
      return;
    }

  if (avcodec_send_packet(_videoCodecCtx, packet) < 0)
    {
      return;
    }
  
  if (packet->flags & AV_PKT_FLAG_CORRUPT)
    {
      NSLog(@"Skipping corrupt video packet");
      return;
    }
  
  // Record last pts...
  _lastPts = packet->pts;
  
  while (avcodec_receive_frame(_videoCodecCtx, _videoFrame) == 0)
    {
      [self renderFrame: _videoFrame];
    }
}

@end
