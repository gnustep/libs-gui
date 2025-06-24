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

#import "GSMovieView.h"
#import "GSAudioPlayer.h"
#import "GSAVUtils.h"

static NSNotificationCenter *nc = nil;

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
      // Objects...
      _audioPlayer = [[GSAudioPlayer alloc] init];
      _feedTimer = nil;
      _currentFrame = nil;
      
      // AV...
      _videoClock = 0;
      _videoCodecCtx = NULL;
      _formatCtx = NULL;
      _swsCtx = NULL;
      _stream = NULL;
      _lastPts = 0;
      _fps = 0.0;

      // Flags...
      _running = NO; // is the thread running?
      
      // Get notifications and shut down the thread if app is closing.
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

  // Cancel thread, dealloc av structs...
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
  DESTROY(_audioPlayer);
  DESTROY(_currentFrame);
  
  // Unsubscribe to NSNotification
  [nc removeObserver: self];

  [super dealloc];
}

// New methods...
- (CGFloat) frameRateForStream
{
  if (_stream->avg_frame_rate.num > 0 && _stream->avg_frame_rate.den > 0)
    return av_q2d(_stream->avg_frame_rate);
  else
    return (1.0 / av_q2d(_stream->time_base));
}

// Notification responses...
- (void) handleNotification: (NSNotification *)notification
{
  NSLog(@"[GSMovieView] Shutting down, final pts %ld", _lastPts);
  [_feedTimer invalidate];
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
      NSTimeInterval fr = (double)(1/[self frameRateForStream]);

      NSLog(@"[GSMovieView] Starting video | Timestamp: %ld, lastPts = %ld, fr = %f",
	    av_gettime(), _lastPts, fr); 
      [self setRate: 1.0];
      [self setVolume: 1.0];
      
      _running = YES;
      _feedTimer = [NSTimer scheduledTimerWithTimeInterval: fr
						    target: self
						  selector: @selector(decodeAndDisplayNextFrame)
						  userInfo: nil
						   repeats: YES];			   
    }
}

- (IBAction) stop: (id)sender
{
  if (_running == YES)
    {
      _running = NO;
      [_feedTimer invalidate];
      NSLog(@"[GSMovieView] Stopping video | Timestamp: %ld, lastPts = %ld",
	    	av_gettime(), _lastPts);
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
      [self start: nil];
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
  //
}

- (IBAction) stepForward: (id)sender
{

}

- (IBAction) stepBack: (id)sender
{
  [self stop: sender];
  // [self _startAtPts: _savedPts - 1000];
}

// Video playback methods...
- (void) updateImage: (NSImage *)image
{
  ASSIGN(_currentFrame, image);
  [self setNeedsDisplay: YES];
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
	      NSLog(@"[GSMovieView - Info] No video stream found. | Timestamp: %ld", av_gettime());
	    }
	  else
	    {
	      [self prepareWithFormatContext: _formatCtx
				 streamIndex: _videoStreamIndex];
	    }

	  // Audio stream...
	  if (_audioStreamIndex == -1) // if we do have an audio stream, initialize it... otherwise log it
	    {
	      NSLog(@"[GSMovieView - Info] No audio stream found. | Timestamp: %ld", av_gettime());
	    }
	  else
	    {
	      [_audioPlayer prepareWithFormatContext: _formatCtx
					 streamIndex: _audioStreamIndex];
	    }

	  // Video and Audio stream not present...
	  if (_videoStreamIndex == -1 && _audioStreamIndex == -1)
	    {
	      NSLog(@"[GSMovieView - Error] No video or audio stream detected, exiting");
	      avformat_close_input(&_formatCtx);
	      return NO;
	    }
	}
    }

  return YES;
}

- (void) decodeAndDisplayNextFrame
{
  AVPacket packet;
  uint8_t *rgbData[1];
  int rgbLineSize[1];
  int width = _videoCodecCtx->width;
  int height = _videoCodecCtx->height;

  // av_init_packet(&packet);
  packet.data = NULL;
  packet.size = 0;

  rgbLineSize[0] = width * 3;
  rgbData[0] = (uint8_t *)malloc(height * rgbLineSize[0]);
  
  while (av_read_frame(_formatCtx, &packet) >= 0)
    {
      if (!_running)
	{
	  break;
	}
      
      if (packet.stream_index == _videoStreamIndex)
	{
	  avcodec_send_packet(_videoCodecCtx, &packet);
	  if (avcodec_receive_frame(_videoCodecCtx, _videoFrame) == 0)
	    {
	      sws_scale(_swsCtx,
			(const uint8_t * const *)_videoFrame->data,
			_videoFrame->linesize,
			0,
			height,
			rgbData,
			rgbLineSize);

	      NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
					initWithBitmapDataPlanes: &rgbData[0]
						      pixelsWide: _videoCodecCtx->width
						      pixelsHigh: _videoCodecCtx->height
						   bitsPerSample: 8
						 samplesPerPixel: 3
							hasAlpha: NO
							isPlanar: NO
						  colorSpaceName: NSCalibratedRGBColorSpace
						     bytesPerRow: rgbLineSize[0]
						    bitsPerPixel: 24];

	      NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(_videoCodecCtx->width, _videoCodecCtx->height)];
	      [image addRepresentation:rep];

	      [self performSelectorOnMainThread: @selector(updateImage:)
				     withObject: image
				  waitUntilDone: NO];
	      break;
	    }
	}
      else if (packet.stream_index == _audioStreamIndex)
	{
	  NSLog(@"Audio packet...");
	}

      av_packet_unref(&packet);
  }
}

- (void) loop
{
  if (_formatCtx != NULL)
    {
      AVPacket packet;
      
      while (av_read_frame(_formatCtx, &packet) >= 0)
	{
	  if (packet.stream_index == _videoStreamIndex)
	    {
	      [self decodePacket: &packet];
	      break;
	    }
	  if (packet.stream_index == _audioStreamIndex)
	    {
	      [_audioPlayer decodePacket: &packet];
	      break;
	    }
	}
      
      av_packet_unref(&packet);
    }
}

- (void) close
{
  if (_formatCtx != NULL)
    {
      avformat_close_input(&_formatCtx);
    }
}

- (void)prepareWithFormatContext: (AVFormatContext *)formatCtx streamIndex: (int)videoStreamIndex
{
  AVCodecParameters *videoPar = NULL;
  const AVCodec *videoCodec = NULL;

  _stream = formatCtx->streams[videoStreamIndex];
  _fps = [self frameRateForStream]; 
  videoPar = _stream->codecpar;
  videoCodec = avcodec_find_decoder(videoPar->codec_id);

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
			   NULL,
			   NULL,
			   NULL);

  _timeBase = formatCtx->streams[videoStreamIndex]->time_base;
  _videoClock = av_gettime();
  _running = NO;
}

- (void) setPlaying: (BOOL)f
{
  _running = f;
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

  // Log pts...
  fprintf(stderr, "[GSMovieView] Rendering video frame PTS: %ld\r",
	  packet->pts);
  if (_statusField != nil)
    {
      // Show the information...
      _statusString = [NSString stringWithFormat: @"Rendering video frame PTS: %ld | %@",
				packet->pts, _running ? @"Running" : @"Stopped"];
      [_statusField setStringValue: _statusString];
    }
  
  // Record last pts...
  _lastPts = packet->pts;
  while (avcodec_receive_frame(_videoCodecCtx, _videoFrame) == 0)
    {
      [self renderFrame: _videoFrame];
    }
}

@end
