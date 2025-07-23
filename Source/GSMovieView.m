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

#import "GSMovieView.h"
#import "GSAudioPlayer.h"
#import "GSAVUtils.h"

#define BUFFER_SIZE 2048

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
    return [[extensionsSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
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
  return [[result allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

@end

#pragma clang diagnostic pop

// NSMovieView subclass that does all of the actual work of decoding...
@implementation GSMovieView

- (instancetype) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      // Objects...
      _currentFrame = nil;
      _videoThread = nil;
      _feedThread = nil;
      _audioPlayer = [[GSAudioPlayer alloc] init];
      _videoPackets = [[NSMutableArray alloc] init];

      // AV...
      _videoClock = 0;
      _videoCodecCtx = NULL;
      _formatCtx = NULL;
      _swsCtx = NULL;
      _stream = NULL;
      _lastPts = 0;
      _fps = 0.0;

      // Flags...
      _running = NO;
      _started = NO;
    }
  return self;
}

- (void)dealloc
{
  [self stop: nil];

  // Cancel thread, dealloc av structs...
  if (_feedThread)
    {
      [_feedThread cancel];
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

  // Destroy objects
  DESTROY(_feedThread);
  DESTROY(_videoPackets);
  DESTROY(_audioPlayer);
  DESTROY(_currentFrame);
  
  [super dealloc];
}

// Private methods...
- (void) _startFeed
{
  if (_running == NO)
    {
      [self setRate: 1.0 / 30.0];
      [self setVolume: 1.0];

      _feedThread = [[NSThread alloc] initWithTarget:self selector:@selector(feed) object:nil];
      [_feedThread start];
      [_audioPlayer startAudio];
    }
}

- (void) _stopFeed
{
  if (_running == YES)
    {
      [_feedThread cancel];
      [_audioPlayer stopAudio];
    }
}

// Overridden methods from the superclass...
- (BOOL) isPlaying
{
  return _running;
}

- (IBAction) start: (id)sender
{
  NSLog(@"[GSMovieView] Starting video thread | Timestamp: %ld, lastPts = %ld",
	av_gettime(), _lastPts);

  if (!_running)
    {
      _running = YES;
      _videoThread = [[NSThread alloc] initWithTarget:self
					     selector:@selector(videoThreadEntry)
					       object:nil];
      [_videoThread start];
      [_audioPlayer startAudio];
    }
}

- (IBAction) stop: (id)sender
{
  NSLog(@"[GSMovieView] Stopping video thread | Timestamp: %ld, lastPts = %ld",
	av_gettime(), _lastPts);

  if (_running)
    {
      _running = NO;

      [_videoThread cancel];
      [_audioPlayer stopAudio];
      while (![_videoThread isFinished])
	{
	  usleep(1000);
	}

      DESTROY(_videoThread);
      avformat_close_input(&_formatCtx);
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

- (void) setMovie: (NSMovie *)movie
{
  @synchronized(_movie)
    {
      [super setMovie: movie];
      [self setup];
      [self _startFeed];
    }
}

- (NSRect) movieRect
{
  NSRect result = NSZeroRect;
  
  if (_stream != NULL)
    {
      // Retrieve codec parameters
      AVCodecParameters* codecpar = _stream->codecpar;
      
      // These are your video dimensions:
      CGFloat width = (CGFloat)(codecpar->width);
      CGFloat height = (CGFloat)(codecpar->height);
        
      result = NSMakeRect(0.0, 0.0, width, height);
    }

  return result;
}

- (IBAction)gotoPosterFrame: (id)sender
{
  [self stop: sender];
  // [self _startAtPts: 0];
  NSLog(@"[GSMovieView] gotoPosterFrame called | Timestamp: %ld", av_gettime());
}

- (IBAction)gotoBeginning: (id)sender
{
  [self stop: sender];
  // [self _startAtPts: 0];
  NSLog(@"[GSMovieView] gotoBeginning called | Timestamp: %ld", av_gettime());
}

- (IBAction)gotoEnd: (id)sender
{
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

- (BOOL) setup
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
	      return NO;
	    }

	  if (avformat_find_stream_info(_formatCtx, NULL) < 0)
	    {
	      NSLog(@"[Error] Could not find stream info. | Timestamp: %ld", av_gettime());
	      avformat_close_input(&_formatCtx);
	      return NO;
	    }

	  _videoStreamIndex = -1;
	  for (unsigned int i = 0; i < _formatCtx->nb_streams; i++)
	    {
	      if (_formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO)
		{
		  _stream = _formatCtx->streams[i];
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
	      [self prepareWithFormatContext: _formatCtx
				 streamIndex: _videoStreamIndex];
	    }

	  // Audio stream...
	  if (_audioStreamIndex == -1) // if we do have an audio stream, initialize it... otherwise log it
	    {
	      NSLog(@"[Info] No audio stream found. | Timestamp: %ld", av_gettime());
	    }
	  else
	    {
	      [_audioPlayer prepareWithFormatContext: _formatCtx
					 streamIndex: _audioStreamIndex];
	    }

	  // Video and Audio stream not present...
	  if (_videoStreamIndex == -1 && _audioStreamIndex == -1)
	    {
	      NSLog(@"[Error] No video or audio stream detected, exiting");
	      avformat_close_input(&_formatCtx);
	      return NO;
	    }
	}
    }

  return YES;
}

- (void) loop
{
  if (_formatCtx != NULL)
    {
      AVPacket packet;
      int64_t i = 0;

      while (av_read_frame(_formatCtx, &packet) >= 0)
	{
	  // After BUFFER_SIZE frames, start the thread...
	  if (i == BUFFER_SIZE)
	    {
	      [self start: nil];
	    }

	  if (packet.stream_index == _videoStreamIndex)
	    {
	      [self submitPacket: &packet];
	    }

	  if (packet.stream_index == _audioStreamIndex)
	    {
	      [_audioPlayer submitPacket: &packet];
	    }

	  av_packet_unref(&packet);
	  i++;
	}

      // if we had a very short video... play it.
      if (i < BUFFER_SIZE)
	{
	  NSLog(@"[GSMovieView] Starting short video... | Timestamp: %ld", av_gettime());
	  [self start: nil];
	}
    }
}

- (void) close
{
  if (_formatCtx != NULL)
    {
      avformat_close_input(&_formatCtx);
    }
}

- (void) feed
{
  if (_stream != NULL)
    {
      [self loop];
      [self close];
    }
}

- (void)prepareWithFormatContext: (AVFormatContext *)formatCtx streamIndex: (int)videoStreamIndex
{
  AVStream *videoStream = formatCtx->streams[videoStreamIndex];
  AVCodecParameters *videoPar = videoStream->codecpar;
  const AVCodec *videoCodec = avcodec_find_decoder(videoPar->codec_id);
  AVRational fr = videoStream->avg_frame_rate;

  _stream = videoStream;
  _fps = av_q2d(fr); 
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

- (void) setPlaying: (BOOL)f
{
  _running = f;
}

- (void)submitPacket: (AVPacket *)packet
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
      // Create pool...
      CREATE_AUTORELEASE_POOL(pool);
      {
	NSDictionary *dict = nil;

	// Pop the video packet off _videoPackets, sync on
	// the array.
	@synchronized (_videoPackets)
	  {
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
	    [self decodePacket: &packet];
	    RELEASE(dict);
	  }
      }
      RELEASE(pool);
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

- (void) decodePacket: (AVPacket *)packet
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
