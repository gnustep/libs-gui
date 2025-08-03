/** <title>GSMovieView</title>

    <abstract>Encapsulate a movie with audio clock-driven synchronization</abstract>

    This implementation uses the audio clock as the master timing reference.
    Video frames are synchronized to the audio clock to ensure proper
    audio-video synchronization. When no audio is present, the system
    falls back to system time-based synchronization.

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

@interface NSMovieView (AVCodec)
@end

@implementation NSMovieView (AVCodec)

// Make sure we have all of the video and audio components, to build this...
+ (id) allocWithZone: (NSZone *)zone
{
  if (self == [NSMovieView class])
    {
      return [GSMovieView allocWithZone: zone];
    }
  return [super allocWithZone: zone];
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
      _videoCodecCtx = NULL;
      _formatCtx = NULL;
      _swsCtx = NULL;
      _stream = NULL;
      _lastPts = 0;
      _videoStartTime = 0;
      _videoFallbackTime = 0;
      _fps = 0.0;

      // Flags...
      _flags.playing = NO;
      _started = NO;
      _manualStop = NO;
      _resetTiming = NO;
    }
  return self;
}

- (void)dealloc
{
  // Stop all playback and clean up
  [self stop: nil];
  [self _stopFeed];

  // Cancel and clean up threads if they still exist
  if (_feedThread)
    {
      [_feedThread cancel];
      DESTROY(_feedThread);
    }

  if (_videoThread)
    {
      [_videoThread cancel];
      DESTROY(_videoThread);
    }

  // Clean up AV structures
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

  // Close format context
  if (_formatCtx)
    {
      avformat_close_input(&_formatCtx);
    }

  // Destroy objects
  DESTROY(_videoPackets);
  DESTROY(_audioPlayer);
  DESTROY(_currentFrame);

  [super dealloc];
}

// Private methods...
- (void) _startFeed
{
  @synchronized(self)
    {
      if (_feedThread != nil)
	{
	  NSLog(@"[GSMovieView] Feed thread already exists");
	  return;
	}

      [self setRate: 1.0 / 30.0];
      [self setVolume: 1.0];

      _feedThread = [[NSThread alloc] initWithTarget:self selector:@selector(feed) object:nil];
      [_feedThread start];

      NSLog(@"[GSMovieView] Feed thread started | Timestamp: %ld", av_gettime());
    }
}

- (void) _stopFeed
{
  @synchronized(self)
    {
      if (_feedThread != nil)
	{
	  [_feedThread cancel];

	  // Wait for feed thread to finish with timeout
	  int timeout = 500; // 0.5 second timeout
	  while (![_feedThread isFinished] && timeout > 0)
	    {
	      usleep(1000); // 1ms
	      timeout--;
	    }

	  // Don't destroy the thread reference immediately - let start method handle it
	  // This allows us to check if the thread finished and needs restarting
	  NSLog(@"[GSMovieView] Feed thread stopped | Timestamp: %ld", av_gettime());
	}
    }
}

// Overridden methods from the superclass...
- (BOOL) isPlaying
{
  @synchronized(self)
    {
      // More robust check: ensure we have both the flag and active threads
      return _flags.playing && (_videoThread != nil || _feedThread != nil);
    }
}

- (IBAction) start: (id)sender
{
  @synchronized(self)
    {
      if (_flags.playing)
	{
	  NSLog(@"[GSMovieView] Already running, ignoring start request | Timestamp: %ld", av_gettime());
	  return;
	}

      if (!_formatCtx || !_stream)
	{
	  NSLog(@"[GSMovieView] Cannot start - no media loaded | Timestamp: %ld", av_gettime());
	  return;
	}

      NSLog(@"[GSMovieView] Starting video playback | Timestamp: %ld, lastPts = %ld, manualStop = %d",
	    av_gettime(), _lastPts, _manualStop);

      _started = NO; // Reset for synchronization

      // For manual resume, seek to the preserved position
      if (_manualStop)
	{
	  NSLog(@"[GSMovieView] Resuming from manual stop at PTS: %ld | Timestamp: %ld",
		_lastPts, av_gettime());

	  // Clear existing video packets to start fresh
	  @synchronized (_videoPackets)
	    {
	      [_videoPackets removeAllObjects];
	    }

	  // Seek to the current position to ensure proper resume
	  if (_lastPts != 0)
	    {
	      int64_t currentTimestamp = av_rescale_q(_lastPts, _timeBase, (AVRational){1, 1000000});
	      NSLog(@"[GSMovieView] Seeking to resume position: %ld us (PTS: %ld) | Timestamp: %ld",
		    currentTimestamp, _lastPts, av_gettime());

	      if (av_seek_frame(_formatCtx, _videoStreamIndex, _lastPts, AVSEEK_FLAG_BACKWARD) >= 0)
		{
		  // Reset codec state after seek
		  if (_videoCodecCtx)
		    {
		      avcodec_flush_buffers(_videoCodecCtx);
		    }

		  // Ask audio player to seek to the same position
		  if (_audioPlayer)
		    {
		      [_audioPlayer seekToTime: currentTimestamp];
		    }

		  NSLog(@"[GSMovieView] Seek to resume position successful | Timestamp: %ld", av_gettime());
		}
	      else
		{
		  NSLog(@"[GSMovieView] Failed to seek to resume position, falling back to current stream position | Timestamp: %ld", av_gettime());
		}
	    }
	  else
	    {
	      NSLog(@"[GSMovieView] No valid PTS for resume, starting from current stream position | Timestamp: %ld", av_gettime());
	    }

	  // Clear the manual stop flag since we're resuming
	  _manualStop = NO;
	  // Flag to reset timing on next video frame
	  _resetTiming = YES;
	}
      else
	{
	  NSLog(@"[GSMovieView] Starting playback from current stream position | Timestamp: %ld", av_gettime());
	  // Clear existing video packets to start fresh
	  @synchronized (_videoPackets)
	    {
	      [_videoPackets removeAllObjects];
	    }
	}

      // Set playing flag before starting threads so they don't exit immediately
      _flags.playing = YES;

      // Start feed thread if not already started or if it finished
      if (_feedThread == nil || [_feedThread isFinished])
	{
	  NSLog(@"[GSMovieView] Starting new feed thread | Timestamp: %ld", av_gettime());
	  [self setRate: 1.0 / 30.0];
	  [self setVolume: 1.0];

	  // Clean up old thread reference if it finished
	  if (_feedThread && [_feedThread isFinished])
	    {
	      DESTROY(_feedThread);
	    }

	  _feedThread = [[NSThread alloc] initWithTarget:self
						selector:@selector(feed)
						  object:nil];
	  [_feedThread start];
	  NSLog(@"[GSMovieView] Feed thread started successfully | Timestamp: %ld", av_gettime());
	}
      else
	{
	  NSLog(@"[GSMovieView] Feed thread already running | Timestamp: %ld", av_gettime());
	}

      // Start video processing thread
      if (_videoThread == nil || [_videoThread isFinished])
	{
	  NSLog(@"[GSMovieView] Starting new video thread | Timestamp: %ld", av_gettime());
	  // Clean up old thread reference if it finished
	  if (_videoThread && [_videoThread isFinished])
	    {
	      DESTROY(_videoThread);
	    }

	  _videoThread = [[NSThread alloc] initWithTarget:self
						 selector:@selector(videoThreadEntry)
						   object:nil];
	  [_videoThread start];
	  NSLog(@"[GSMovieView] Video thread started successfully | Timestamp: %ld", av_gettime());
	}
      else
	{
	  NSLog(@"[GSMovieView] Video thread already running | Timestamp: %ld", av_gettime());
	}

      // Start audio playback
      if (_audioPlayer && _audioStreamIndex >= 0)
	{
	  NSLog(@"[GSMovieView] Starting audio playback | Timestamp: %ld", av_gettime());
	  [_audioPlayer startAudio];
	}
      else
	{
	  NSLog(@"[GSMovieView] No audio to start (audioPlayer: %p, audioStreamIndex: %d) | Timestamp: %ld",
		_audioPlayer, _audioStreamIndex, av_gettime());
	}

      NSLog(@"[GSMovieView] Video playback started successfully | Timestamp: %ld", av_gettime());
    }
}

- (IBAction) stop: (id)sender
{
  @synchronized(self)
    {
      if (!_flags.playing)
	{
	  NSLog(@"[GSMovieView] Already stopped, ignoring stop request | Timestamp: %ld", av_gettime());
	  return;
	}

      NSLog(@"[GSMovieView] Stopping video playback | Timestamp: %ld, lastPts = %ld",
	    av_gettime(), _lastPts);

      _flags.playing = NO;
      _manualStop = YES; // Mark this as a manual stop

      // Stop audio playback first
      if (_audioPlayer)
	{
	  [_audioPlayer stopAudio];
	}

      // Cancel and wait for video thread
      if (_videoThread)
	{
	  [_videoThread cancel];

	  // Wait for video thread to finish with timeout
	  int timeout = 1000; // 1 second timeout
	  while (![_videoThread isFinished] && timeout > 0)
	    {
	      usleep(1000); // 1ms
	      timeout--;
	    }

	  if (timeout <= 0)
	    {
	      NSLog(@"[GSMovieView] Warning: Video thread did not finish within timeout");
	    }

	  DESTROY(_videoThread);
	}

      // Cancel feed thread but don't destroy it (might be reused)
      if (_feedThread)
	{
	  [_feedThread cancel];
	}

      // Clear video packet queue
      @synchronized (_videoPackets)
	{
	  [_videoPackets removeAllObjects];
	}

      NSLog(@"[GSMovieView] Video playback stopped successfully | Timestamp: %ld", av_gettime());
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

/*
  - (void) setLoopMode: (NSQTMovieLoopMode)mode
  {
  [super setLoopMode: mode];
  }
*/

- (void) setMovie: (NSMovie *)movie
{
  @synchronized(self)
    {
      // Stop current playback
      [self stop: nil];

      // Clean up existing format context
      if (_formatCtx)
	{
	  avformat_close_input(&_formatCtx);
	  _formatCtx = NULL;
	}

      // Reset stream indices
      _videoStreamIndex = -1;
      _audioStreamIndex = -1;
      _stream = NULL;

      // Clear codec context
      if (_videoCodecCtx)
	{
	  avcodec_free_context(&_videoCodecCtx);
	  _videoCodecCtx = NULL;
	}

      // Clear scaling context
      if (_swsCtx)
	{
	  sws_freeContext(_swsCtx);
	  _swsCtx = NULL;
	}

      // Clear video frame
      if (_videoFrame)
	{
	  av_frame_free(&_videoFrame);
	  _videoFrame = NULL;
	}

      // Set the new movie
      [super setMovie: movie];

      // Setup the new movie if provided
      if (movie != nil)
	{
	  [self setup];
	}

      NSLog(@"[GSMovieView] Movie changed | Timestamp: %ld", av_gettime());
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

  // Go to the first frame (poster frame)
  if ([self seekToFrame: 0])
    {
      [self displayCurrentFrame];
      NSLog(@"[GSMovieView] gotoPosterFrame successful | Timestamp: %ld", av_gettime());
    }
  else
    {
      NSLog(@"[GSMovieView] gotoPosterFrame failed | Timestamp: %ld", av_gettime());
    }
}

- (IBAction)gotoBeginning: (id)sender
{
  [self stop: sender];

  // Go to timestamp 0 (beginning of movie)
  if ([self seekToTime: 0])
    {
      [self displayCurrentFrame];
      NSLog(@"[GSMovieView] gotoBeginning successful | Timestamp: %ld", av_gettime());
    }
  else
    {
      NSLog(@"[GSMovieView] gotoBeginning failed | Timestamp: %ld", av_gettime());
    }
}

- (IBAction)gotoEnd: (id)sender
{
  [self stop: sender];

  // Go to the end of the movie
  int64_t duration = [self getDuration];
  if (duration > 0)
    {
      if ([self seekToTime: duration - 1000000]) // 1 second before end
	{
	  [self displayCurrentFrame];
	  NSLog(@"[GSMovieView] gotoEnd successful | Timestamp: %ld", av_gettime());
	}
      else
	{
	  NSLog(@"[GSMovieView] gotoEnd failed | Timestamp: %ld", av_gettime());
	}
    }
  else
    {
      NSLog(@"[GSMovieView] gotoEnd failed - no duration available | Timestamp: %ld", av_gettime());
    }
}

- (IBAction) stepForward: (id)sender
{
  BOOL wasPlaying = [self isPlaying];
  [self stop: sender];

  if (_fps > 0.0)
    {
      // Calculate frame duration in microseconds
      int64_t frameDuration = (int64_t)(1000000.0 / _fps);
      int64_t currentTime = [self getCurrentTimestamp];
      int64_t nextFrameTime = currentTime + frameDuration;

      // Don't seek beyond the duration
      int64_t duration = [self getDuration];
      if (duration > 0 && nextFrameTime >= duration)
	{
	  nextFrameTime = duration - 1000; // Just before the end
	}

      if ([self seekToTime: nextFrameTime])
	{
	  [self displayCurrentFrame];
	  NSLog(@"[GSMovieView] stepForward successful to time %ld | Timestamp: %ld",
		nextFrameTime, av_gettime());

	  // If it was playing before, resume playback after a short delay
	  if (wasPlaying)
	    {
	      [self performSelector: @selector(start:)
			 withObject: sender
			 afterDelay: 0.1];
	    }
	}
      else
	{
	  NSLog(@"[GSMovieView] stepForward failed | Timestamp: %ld", av_gettime());
	}
    }
  else
    {
      NSLog(@"[GSMovieView] stepForward failed - no frame rate available (fps: %f) | Timestamp: %ld",
	    _fps, av_gettime());
    }
}

- (IBAction) stepBack: (id)sender
{
  BOOL wasPlaying = [self isPlaying];
  [self stop: sender];

  if (_fps > 0.0)
    {
      // Calculate frame duration in microseconds
      int64_t frameDuration = (int64_t)(1000000.0 / _fps);
      int64_t currentTime = [self getCurrentTimestamp];
      int64_t prevFrameTime = currentTime - frameDuration;

      // Don't go before the beginning
      if (prevFrameTime < 0)
	{
	  prevFrameTime = 0;
	}

      if ([self seekToTime: prevFrameTime])
	{
	  [self displayCurrentFrame];
	  NSLog(@"[GSMovieView] stepBack successful to time %ld | Timestamp: %ld",
		prevFrameTime, av_gettime());

	  // If it was playing before, resume playback after a short delay
	  if (wasPlaying)
	    {
	      [self performSelector: @selector(start:)
			 withObject: sender
			 afterDelay: 0.1];
	    }
	}
      else
	{
	  NSLog(@"[GSMovieView] stepBack failed | Timestamp: %ld", av_gettime());
	}
    }
  else
    {
      NSLog(@"[GSMovieView] stepBack failed - no frame rate available (fps: %f) | Timestamp: %ld",
	    _fps, av_gettime());
    }
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

	  NSDebugLog(@"[Info] Opening file: %s | Timestamp: %ld", path, av_gettime());
	  avformat_network_init();
	  if (avformat_open_input(&_formatCtx, path, NULL, NULL) != 0)
	    {
	      NSDebugLog(@"[Error] Could not open file: %s | Timestamp: %ld", path, av_gettime());
	      return NO;
	    }

	  if (avformat_find_stream_info(_formatCtx, NULL) < 0)
	    {
	      NSDebugLog(@"[Error] Could not find stream info. | Timestamp: %ld", av_gettime());
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
  NSLog(@"[GSMovieView] Feed loop started | Timestamp: %ld", av_gettime());

  if (_formatCtx != NULL)
    {
      AVPacket packet;
      int64_t i = 0;

      while (av_read_frame(_formatCtx, &packet) >= 0)
	{
	  // Check if we should stop feeding - exit if cancelled OR if not playing
	  if ([[NSThread currentThread] isCancelled] || !_flags.playing)
	    {
	      NSLog(@"[GSMovieView] Feed loop stopping - playing: %d, cancelled: %d | Timestamp: %ld",
		    _flags.playing, [[NSThread currentThread] isCancelled], av_gettime());
	      av_packet_unref(&packet);
	      break;
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

      // When we reach EOF, we can seek back to beginning if looping is desired
      // For now, just log that we've reached the end
      // Mark this as not a manual stop since we reached EOF naturally
      _manualStop = NO;
      NSLog(@"[GSMovieView] Reached end of stream, frames read: %ld | Timestamp: %ld", i, av_gettime());
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
      // DON'T close the format context here - keep it open for restart capability
      // [self close];
      NSDebugLog(@"[GSMovieView] Feed thread finished, format context remains open for restart | Timestamp: %ld", av_gettime());
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
  _flags.playing = NO;
  _started = NO;
}

- (void) setPlaying: (BOOL)f
{
  _flags.playing = f;
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
  NSLog(@"[GSMovieView] Video thread started | Timestamp: %ld", av_gettime());

  while (_flags.playing)
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

	// If the dict is present and audio is started, we can sync to audio clock.
	// If audio is not available, we fall back to system time
	if (!_started && dict)
	  {
	    _started = YES;
	  }

	// If dict is not nil, decode it and get the frame...
	if (dict)
	  {
	    AVPacket packet = AVPacketFromNSDictionary(dict);

	    // Calculate video timing based on audio clock
	    int64_t packetTime = av_rescale_q(packet.pts,
					      _timeBase,
					      (AVRational){1, 1000000});
	    int64_t referenceTime;
	    int64_t delay;

	    // Use audio clock as master if audio is available and started
	    if (_audioPlayer && [_audioPlayer isAudioStarted])
	      {
		referenceTime = [_audioPlayer currentPlaybackTime];
		delay = packetTime - referenceTime;

		// Sanity check - if delay is extremely large, audio clock might be wrong
		if (delay > 5000000 || delay < -5000000) // More than 5 seconds off
		  {
		    NSDebugLog(@"[GSMovieView] Audio clock seems incorrect (delay: %ld us), falling back to system time\r", delay);
		    // Fall back to system timing
		    if (_videoFallbackTime == 0 || _resetTiming)
		      {
			_videoFallbackTime = av_gettime();
		      }
		    referenceTime = av_gettime() - _videoFallbackTime;
		    delay = packetTime - referenceTime;
		  }

		// Debug: Log audio synchronization details
		if (packet.pts % 30 == 0) // Log every 30th frame to avoid spam
		  {
		    NSDebugLog(@"[GSMovieView] Audio sync - PTS: %ld, AudioTime: %ld, Delay: %ld us\r",
			  packetTime, referenceTime, delay);
		  }
	      }
	    else
	      {
		// Fall back to system time if no audio
		if (_videoStartTime == 0 || _resetTiming)
		  {
		    _videoStartTime = av_gettime();
		  }
		referenceTime = av_gettime() - _videoStartTime;
		delay = packetTime - referenceTime;

		// Debug: Log system time synchronization
		if (packet.pts % 30 == 0) // Log every 30th frame to avoid spam
		  {
		    NSDebugLog(@"[GSMovieView] System sync - PTS: %ld, SysTime: %ld, Delay: %ld us\n",
			  packetTime, referenceTime, delay);
		  }
	      }

	    // Clear the reset timing flag after first use
	    if (_resetTiming)
	      {
		_resetTiming = NO;
		NSLog(@"[GSMovieView] Reset video timing for resume");
	      }

	    if (_statusField != nil)
	      {
		// Show the information...
		NSString *syncSource = (_audioPlayer && [_audioPlayer isAudioStarted]) ? @"Audio Clock" : @"System Time";
		_statusString = [NSString stringWithFormat: @"Rendering video frame PTS: %ld | Delay: %ld us | Sync: %@ | %@",
					  packet.pts, delay, syncSource, _flags.playing ? @"Running" : @"Stopped"];
		[_statusField setStringValue: _statusString];
	      }

	    // Show status on the command line...
	    NSString *syncSource = (_audioPlayer && [_audioPlayer isAudioStarted]) ? @"Audio Clock" : @"System Time";
	    NSDebugLog(@"[GSMovieView] Rendering video frame PTS: %ld | Delay: %ld us | Sync: %s\r",
		    packet.pts, delay, [syncSource UTF8String]);

	    // More tolerant timing thresholds to ensure video displays
	    // Be extra lenient during startup (first 100 frames)
	    static int frameCount = 0;
	    frameCount++;

	    int64_t delayThreshold = (frameCount < 100) ? 100000 : 50000; // 100ms during startup, then 50ms
	    int64_t dropThreshold = (frameCount < 100) ? 500000 : 200000; // 500ms during startup, then 200ms

	    if (delay > delayThreshold)
	      {
		// Only delay if we're significantly ahead
		usleep((useconds_t)delay);
		NSDebugLog(@"[GSMovieView] Delaying frame by %ld us (frame #%d)\r", delay, frameCount);
	      }
	    else if (delay < -dropThreshold)
	      {
		NSDebugLog(@"[GSMovieView] Dropping frame - %ld us behind (threshold: %ld us, frame #%d)\r",
		      -delay, dropThreshold, frameCount);
		RELEASE(dict);
		continue; // Skip this frame to catch up
	      }
	    else
	      {
		// Normal case - display the frame without delay
		if (packet.pts % 60 == 0) // Log every 60th frame
		  {
		    NSDebugLog(@"[GSMovieView] Displaying frame normally - delay: %ld us (frame #%d)\r", delay, frameCount);
		  }
	      }

	    // Decode the packet, display it and play the sound...
	    [self decodePacket: &packet];
	    RELEASE(dict);
	  }
	else
	  {
	    // No packets available, sleep briefly to avoid busy waiting
	    usleep(1000); // 1ms
	  }
      }
      RELEASE(pool);
    }

  NSLog(@"[GSMovieView] Video thread finished | Timestamp: %ld", av_gettime());
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
      NSDebugLog(@"Skipping corrupt video packet");
      return;
    }

  // Record last pts...
  _lastPts = packet->pts;

  while (avcodec_receive_frame(_videoCodecCtx, _videoFrame) == 0)
    {
      [self renderFrame: _videoFrame];
    }
}

// Seeking methods
- (BOOL) seekToTime: (int64_t)timestamp
{
  if (!_formatCtx || !_stream)
    {
      return NO;
    }

  BOOL wasPlaying = [self isPlaying];

  // Stop playback first
  if (wasPlaying)
    {
      [self stop: nil];
    }

  // Convert timestamp to stream timebase
  int64_t seekTarget = av_rescale_q(timestamp, (AVRational){1, 1000000}, _timeBase);

  // Seek in the format context
  int result = av_seek_frame(_formatCtx, _videoStreamIndex, seekTarget, AVSEEK_FLAG_BACKWARD);

  if (result >= 0)
    {
      // Clear existing video packets
      @synchronized (_videoPackets)
	{
	  [_videoPackets removeAllObjects];
	}

      // Reset codec state
      if (_videoCodecCtx)
	{
	  avcodec_flush_buffers(_videoCodecCtx);
	}

      // Ask audio player to seek as well
      if (_audioPlayer)
	{
	  [_audioPlayer seekToTime: timestamp];
	}

      // Reset internal state
      _started = NO;

      // Update _lastPts to reflect the seek position
      // Convert back from stream timebase to get actual PTS
      _lastPts = seekTarget;

      NSDebugLog(@"[GSMovieView] Seek to timestamp %ld successful\r", timestamp);
      return YES;
    }

  NSLog(@"[GSMovieView] Seek to timestamp %ld failed", timestamp);
  return NO;
}

- (BOOL) seekToFrame: (int64_t)frameNumber
{
  if (!_formatCtx || !_stream || _fps <= 0.0)
    {
      return NO;
    }

  // Calculate timestamp from frame number
  int64_t timestamp = (int64_t)((double)frameNumber / _fps * 1000000.0);

  return [self seekToTime: timestamp];
}

- (int64_t) getCurrentTimestamp
{
  if (_lastPts != AV_NOPTS_VALUE)
    {
      return av_rescale_q(_lastPts, _timeBase, (AVRational){1, 1000000});
    }
  return 0;
}

- (int64_t) getDuration
{
  if (_formatCtx && _formatCtx->duration != AV_NOPTS_VALUE)
    {
      return _formatCtx->duration;
    }
  else if (_stream && _stream->duration != AV_NOPTS_VALUE)
    {
      return av_rescale_q(_stream->duration, _timeBase, (AVRational){1, 1000000});
    }
  return 0;
}

- (void) displayCurrentFrame
{
  if (!_formatCtx)
    {
      return;
    }

  // Read and decode a single frame to display
  AVPacket packet;
  while (av_read_frame(_formatCtx, &packet) >= 0)
    {
      if (packet.stream_index == _videoStreamIndex)
	{
	  [self decodePacket: &packet];
	  av_packet_unref(&packet);
	  break; // Only process one video frame
	}
      av_packet_unref(&packet);
    }
}

// Playback status
- (NSString *) playbackStatus
{
  int64_t currentTime = [self getCurrentTimestamp];
  int64_t duration = [self getDuration];
  double currentSeconds = (double)currentTime / 1000000.0;
  double totalSeconds = (double)duration / 1000000.0;

  return [NSString stringWithFormat: @"Time: %.2f/%.2f sec | FPS: %.2f | Playing: %@",
		   currentSeconds, totalSeconds, _fps, [self isPlaying] ? @"YES" : @"NO"];
}

// Status field management
- (void) setStatusField: (NSTextField *)field
{
  ASSIGN(_statusField, field);
}

- (NSTextField *) statusField
{
  return _statusField;
}

// Synchronization monitoring
- (BOOL) isUsingSynchronizedAudio
{
  return (_audioPlayer && [_audioPlayer isAudioStarted]);
}

- (NSString *) synchronizationStatus
{
  if ([self isUsingSynchronizedAudio])
    {
      int64_t audioTime = [_audioPlayer currentPlaybackTime];
      return [NSString stringWithFormat: @"Audio Clock Sync: %ld us", audioTime];
    }
  else
    {
      return @"System Time Sync (No Audio)";
    }
}

// Emergency cleanup (use with caution)
- (void) forceStop
{
  NSLog(@"[GSMovieView] Force stop initiated | Timestamp: %ld", av_gettime());

  _flags.playing = NO;

  // Force stop audio
  if (_audioPlayer)
    {
      [_audioPlayer stopAudio];
    }

  // Force destroy threads without waiting
  if (_videoThread)
    {
      [_videoThread cancel];
      DESTROY(_videoThread);
    }

  if (_feedThread)
    {
      [_feedThread cancel];
      DESTROY(_feedThread);
    }

  // Clear packet queue
  @synchronized (_videoPackets)
    {
      [_videoPackets removeAllObjects];
    }

  NSLog(@"[GSMovieView] Force stop completed | Timestamp: %ld", av_gettime());
}

@end
