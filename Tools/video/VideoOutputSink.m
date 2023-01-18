/*
   VideoOutputSink.m

   Sink video data to libavcodec.

   Copyright (C) 2022 Free Software Foundation, Inc.

   Written by:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: Mar 2022
   
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GNUstepGUI/GSVideoSink.h>

// Portions of this code have been taken from an example in avcodec by Fabrice Bellard

/*
 * Copyright (c) 2001 Fabrice Bellard
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>

// #define INBUF_SIZE 4096

@interface VideoOutputSink : NSObject <GSVideoSink>
{
  NSMovieView *_movieView;
  CGFloat _volume;
}
@end

@implementation VideoOutputSink

+ (BOOL) canInitWithData: (NSData *)data
{
  return YES; // for now just say yes...
}

/**
 * Opens the device for output, called by [NSMovie-play].
 */
- (BOOL) open
{
  return YES;
}

/** Closes the device, called by [NSMovie-stop].
 */
- (void) close
{
}

/** 
 * Plays the data in bytes
 */
- (BOOL) playBytes: (void *)bytes length: (NSUInteger)length
{
  return YES;
}

/** Called by [NSMovieView -setVolume:], and corresponds to it.  Parameter volume
 *  is between the values 0.0 and 1.0.
 */
- (void) setVolume: (float)volume
{
  _volume = volume;
}

/** Called by [NSMovieView -volume].
 */
- (CGFloat) volume
{
  return _volume;
}

/**
 * Sets the view to output to.
 */
- (void) setMovieView: (NSMovieView *)view
{
  ASSIGN(_movieView, view);
}

/**
 * The movie view
 */
- (NSMovieView *) movieView
{
  return _movieView;
}

- (void) drawFrame: (AVFrame *)frame toView: (NSView *)view
{
  int bitsPerPixel = 24;
  int bytesPerRow = frame->linesize[0];
  NSSize size = NSMakeSize(frame->width, frame->height);
  NSBitmapImageRep *imageRep =
    [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: &frame->data[0]
					    pixelsWide: frame->width
					    pixelsHigh: frame->height
					 bitsPerSample: 8
				       samplesPerPixel: 3
					      hasAlpha: NO
					      isPlanar: NO
					colorSpaceName: NSCalibratedRGBColorSpace
					   bytesPerRow: bytesPerRow
					  bitsPerPixel: bitsPerPixel];

  // Create an NSImage from the bitmap image rep
  NSImage *image = [[NSImage alloc] initWithSize: size];
  [image addRepresentation: imageRep];

  // Draw the image to the view
  [image drawInRect: view.bounds
	   fromRect: NSZeroRect
	  operation: NSCompositeCopy
	   fraction: 1.0];
}

- (void) play
{
  NSView *view = _movieView;
  NSURL *movieURL = [[_movieView movie] URL];
  
  // Initialize ffmpeg
  av_register_all();
  avcodec_register_all();
  avformat_network_init();
  
  // Open the movie file using ffmpeg
  AVFormatContext *formatContext = avformat_alloc_context();
  if (avformat_open_input(&formatContext, [movieURL UTF8String], NULL, NULL) != 0)
    {
      NSLog(@"Error opening movie file");
      return;
    }
  
  // Retrieve stream information
  if (avformat_find_stream_info(formatContext, NULL) < 0)
    {
      NSLog(@"Error retrieving stream information");
      return;
    }
  
  // Find the video stream
  int videoStream = -1;
  for (int i = 0; i < formatContext->nb_streams; i++)
    {
      if (formatContext->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
	{
	  videoStream = i;
	  break;
	}
    }
  
  if (videoStream == -1)
    {
      NSLog(@"Error finding video stream");
      return;
    }
  
  // Get the codec context for the video stream
  AVCodecContext *codecContext = formatContext->streams[videoStream]->codec;
  
  // Find the decoder for the video stream
  AVCodec *codec = avcodec_find_decoder(codecContext->codec_id);
  if (codec == NULL)
    {
      NSLog(@"Error finding decoder");
      return;
    }
  
  // Open the codec
  if (avcodec_open2(codecContext, codec, NULL) < 0)
    {
      NSLog(@"Error opening codec");
      return;
    }
  
  // Allocate a frame to hold the decoded video
  AVFrame *frame = av_frame_alloc();
  
  // Create a packet
  AVPacket packet;
  av_init_packet(&packet);
  
  // Read frames from the movie file
  while (av_read_frame(formatContext, &packet) >= 0)
    {
      if (packet.stream_index == videoStream)
	{
	  // Decode the video frame
	  int frameFinished = 0;
	  avcodec_decode_video2(codecContext, frame, &frameFinished, &packet);
	  
	  if (frameFinished)
	    {
	      // Draw the frame to the NSView
	      [self drawFrame:frame toView:view];
	    }
	}
      
      // Free the packet
      av_free_packet(&packet);
    }
  
  // Free the frame
  av_free(frame);
  
  // Close the codec
  avcodec_close(codecContext);
  
  // Close the movie file
  avformat_close_input(&formatContext);
}

@end

