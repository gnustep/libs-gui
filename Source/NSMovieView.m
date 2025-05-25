/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

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

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSURL.h>

#import "AppKit/NSColor.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageRep.h"
#import "AppKit/NSMovie.h"
#import "AppKit/NSMovieView.h"
#import "AppKit/NSPasteboard.h"

#import "config.h"

@implementation NSMovieView

// private method to display frames...
- (void) _updateImage: (NSImage *)image
{
  _currentFrame = image;
  [self setNeedsDisplay:YES];
}

- (void) _prepareDecoder
{
#ifdef HAVE_AVCODEC  
  NSString *moviePath = [[_movie URL] path];

  _formatContext = avformat_alloc_context();
  if (avformat_open_input(&_formatContext, [moviePath UTF8String], NULL, NULL) != 0) return;
  if (avformat_find_stream_info(_formatContext, NULL) < 0) return;
  
  _videoStreamIndex = -1;
  for (int i = 0; i < _formatContext->nb_streams; i++)
    {
      if (_formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO)
	{
	  _videoStreamIndex = i;
	  break;
	}
    }
  
  if (_videoStreamIndex == -1) return;
  
  AVCodecParameters *codecPar = _formatContext->streams[_videoStreamIndex]->codecpar;
  const AVCodec *codec = avcodec_find_decoder(codecPar->codec_id);

  _codecContext = avcodec_alloc_context3(codec);
  avcodec_parameters_to_context(_codecContext, codecPar);
  if (avcodec_open2(_codecContext, codec, NULL) < 0) return;
  
  _avframe = av_frame_alloc();
  _avframeRGB = av_frame_alloc();
  
  int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, _codecContext->width, _codecContext->height, 1);
  _buffer = (uint8_t *)av_malloc(numBytes * sizeof(uint8_t));
  av_image_fill_arrays(_avframeRGB->data, _avframeRGB->linesize, _buffer, AV_PIX_FMT_RGB24,
		       _codecContext->width, _codecContext->height, 1);
  
  _swsCtx = sws_getContext(_codecContext->width, _codecContext->height, _codecContext->pix_fmt,
			   _codecContext->width, _codecContext->height, AV_PIX_FMT_RGB24,
			   SWS_BILINEAR, NULL, NULL, NULL);
#endif
}

- (void) _decodeAndDisplayNextFrame
{
#ifdef HAVE_AVCODEC  
  AVPacket packet;

  av_init_packet(&packet);
  packet.data = NULL;
  packet.size = 0;
  
  while (av_read_frame(_formatContext, &packet) >= 0)
    {
      if (!_playing) break;
      
      if (packet.stream_index == _videoStreamIndex)
	{
	  avcodec_send_packet(_codecContext, &packet);
	  if (avcodec_receive_frame(_codecContext, _avframe) == 0)
	    {
	      sws_scale(_swsCtx, (const uint8_t * const *)_avframe->data, _avframe->linesize, 0,
			_codecContext->height, _avframeRGB->data, _avframeRGB->linesize);
	      
	      NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
					initWithBitmapDataPlanes: _avframeRGB->data
						      pixelsWide: _codecContext->width
						      pixelsHigh: _codecContext->height
						   bitsPerSample: 8
						 samplesPerPixel: 3
							hasAlpha: NO
							isPlanar: NO
						  colorSpaceName: NSCalibratedRGBColorSpace
						     bytesPerRow: _avframeRGB->linesize[0]
						    bitsPerPixel: 24];
	      
	      NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(_codecContext->width, _codecContext->height)];
	      [image addRepresentation:rep];
	      
	      [self performSelectorOnMainThread: @selector(_updateImage:)
				     withObject: image
				  waitUntilDone: NO];
	      break;
	    }
	}
    av_packet_unref(&packet);
  }
#endif
}

- (void) drawRect: (NSRect)dirtyRect
{
  [super drawRect: dirtyRect];
  if (_currentFrame)
    {
      [_currentFrame drawInRect: [self bounds]];
    }
}

- (void) setMovie: (NSMovie*)movie
{
  ASSIGN(_movie, movie);
  [self _prepareDecoder];
}

- (NSMovie*) movie
{
  return _movie;
}

- (void) start: (id)sender
{
  _playing = YES;
  _rate = 1.0 / 30.0;
  _volume = 1.0;
  
  _decodeTimer =
    [NSTimer scheduledTimerWithTimeInterval: _rate
				     target: self
				   selector: @selector(decodeAndDisplayNextFrame)
				   userInfo: nil
				    repeats: YES];
}

- (void) stop: (id)sender
{
  _playing = NO;

  if (_decodeTimer)
    {
      [_decodeTimer invalidate];
      _decodeTimer = nil;
    }
  
#ifdef HAVE_AVCODEC    
  if (_avframe) av_frame_free(&_avframe);
  if (_avframeRGB) av_frame_free(&_avframeRGB);
  if (_buffer) av_free(_buffer);
  if (_codecContext) avcodec_free_context(&_codecContext);
  if (_formatContext) avformat_close_input(&_formatContext);
  if (_swsCtx) sws_freeContext(_swsCtx);
#endif  
}

- (BOOL) isPlaying
{
  return _playing;  
}

- (void) gotoPosterFrame: (id)sender
{
  //FIXME
}

- (void) gotoBeginning: (id)sender
{
  //FIXME
}

- (void) gotoEnd: (id)sender
{
  //FIXME
}

- (void) stepForward: (id)sender
{
  //FIXME
}

- (void) stepBack: (id)sender
{
  //FIXME
}

- (void) setRate: (float)rate
{
  _rate = rate;
}

- (float) rate
{
  return _rate;
}

- (void) setVolume: (float)volume
{
  _volume = volume;
}

- (float) volume
{
  return _volume;
}

- (void) setMuted: (BOOL)mute
{
  _flags.muted = mute;
}

- (BOOL) isMuted
{
  return _flags.muted;
}

- (void) setLoopMode: (NSQTMovieLoopMode)mode
{
  _flags.loopMode = mode;
}

- (NSQTMovieLoopMode) loopMode
{
  return _flags.loopMode;
}

- (void) setPlaysSelectionOnly: (BOOL)flag
{
  _flags.plays_selection_only = flag;
}

- (BOOL) playsSelectionOnly
{
  return _flags.plays_selection_only;
}

- (void) setPlaysEveryFrame: (BOOL)flag
{
  _flags.plays_every_frame = flag;
}

- (BOOL) playsEveryFrame
{
  return _flags.plays_every_frame;
}

- (void) showController: (BOOL)show adjustingSize: (BOOL)adjustSize
{
  //FIXME
  _flags.is_controller_visible = show; 
}

- (void*) movieController
{
  //FIXME
  return NULL;
}

- (BOOL) isControllerVisible
{
  return _flags.is_controller_visible;
}

- (NSRect) movieRect
{
  return [self bounds];
}

- (void) resizeWithMagnification: (float)magnification
{
  //FIXME
}
- (NSSize) sizeForMagnification: (float)magnification
{
  //FIXME
  return NSMakeSize(0, 0);
}

- (void) setEditable: (BOOL)editable
{
  _flags.editable = editable;
}

- (BOOL) isEditable
{
  return _flags.editable;
}

- (void) cut: (id)sender
{
  //FIXME
}

- (void) copy: (id)sender
{
  //FIXME
}

- (void) paste: (id)sender
{
  //FIXME
}

- (void) clear: (id)sender
{
  //FIXME
}

- (void) undo: (id)sender
{
  //FIXME
}

- (void) selectAll: (id)sender
{
  //FIXME
}

@end
