/* 
   AudioOutputSink.m

   Sink audio data to libavcodec.

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

#include <Foundation/Foundation.h>
#include <AppKit/NSMovie.h>
#include <AppKit/NSMovieView.h>

#include <GNUstepGUI/GSVideoSink.h>

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

#include <libavcodec/avcodec.h>

#define INBUF_SIZE 4096

@interface VideoOutputSink : NSObject <GSVideoSink>
{
  AVCodec *_codec;
  AVCodecParserContext *_parser;
  AVCodecContext *_context; // = NULL;
  AVPacket *_pkt;
  AVFrame *_frame;
  
  NSMovieView *_movieView;
}
@end

@implementation VideoOutputSink

- (void) display: (unsigned char *) buf
            wrap: (int) wrap
           xsize: (int) xsize
           ysize: (int) ysize
{
  /*
    FILE *f;
    int i;

    f = fopen(filename,"wb");
    fprintf(f, "P5\n%d %d\n%d\n", xsize, ysize, 255);
    for (i = 0; i < ysize; i++)
        fwrite(buf + i * wrap, 1, xsize, f);
    fclose(f);
  */
}



- (void) decode
{
  int ret;
  
  ret = avcodec_send_packet(_context, _pkt);
  if (ret < 0)
    {
      NSLog(@"Error sending a packet for decoding\n");
      return;
    }
  
  while (ret >= 0)
    {
      ret = avcodec_receive_frame(_context, _frame);
      if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
        {
          return;
        }
      else if (ret < 0)
        {
          NSLog(@"Error during decoding\n");
          return;
        }
      
      NSLog(@"saving frame %3d\n", _context->frame_number);
      fflush(stdout);
      
      /* the picture is allocated by the decoder. no need to
         free it */
      // snprintf(buf, sizeof(buf), "%d", _context->frame_number);
      [self display: _frame->data[0]
               wrap: _frame->linesize[0]
              xsize: _frame->width
              ysize: _frame->height];
      
      // pgm_save(frame->data[0], frame->linesize[0],
      //         frame->width, frame->height, buf);      
    }
}

- (void)dealloc
{
  [self close];
  _movieView = nil;
  _pkt = NULL;
  _context = NULL;
  _parser = NULL;
  _frame = NULL;
  
  [super dealloc];
}

- (id)init
{
  self = [super init];

  if (self != nil)
    {
      _movieView = nil;
      _pkt = NULL;
      _context = NULL;
      _parser = NULL;
      _frame = NULL;
    }
  
  return self;
}

- (void) setMovieView: (NSMovieView *)view
{
  _movieView = view; // weak, don't retain since the view is retained by its parent view.
}

- (NSMovieView *) movieView
{
  return _movieView;
}

- (BOOL)open
{
  _pkt = av_packet_alloc();
  if (!_pkt)
    {
      NSLog(@"Could not allocate packet");
      return NO;
    }

  _codec = avcodec_find_decoder(AV_CODEC_ID_MPEG4); // will set this based on file type.
  if (!_codec)
    {
      NSLog(@"Could not find decoder for type");
      return NO;
    }
  
  _parser = av_parser_init(_codec->id);
  if (!_parser)
    {
      NSLog(@"Could not init parser");
      return NO;
    }

  _context = avcodec_alloc_context3(_codec);
  if (!_context)
    {
      NSLog(@"Could not allocate video coder context");
      return NO;
    }
  
  /* open it */
  if (avcodec_open2(_context, _codec, NULL) < 0)
    {
      NSLog(@"Could not open codec\n");
      return NO;
    }

  _frame = av_frame_alloc();
  if (!_frame)
    {
      NSLog(@"Could not allocate video frame\n");
      return NO;
    }
  
  return YES;
}

- (void)close
{
  if (_parser != NULL)
    {
      av_parser_close(_parser);
    }
  
  if (_context != NULL)
    {
      avcodec_free_context(&_context);
    }
  
  if (_frame != NULL)
    {
      av_frame_free(&_frame);
    }

  if (_pkt != NULL)
    {
      av_packet_free(&_pkt);
    }
}

- (BOOL)playBytes: (void *)bytes length: (NSUInteger)length
{
  int ret = av_parser_parse2(_parser, _context, &_pkt->data, &_pkt->size,
                             bytes, length, AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);
  if (ret < 0)
    {
      NSLog(@"Error encountered while parsing data");
      return NO;
    }

  if (_pkt != NULL)
    {
      if (_pkt->size)
        {
          [self decode];
        }
    }
  else
    {
      return NO;
    }
  
  return YES;
}

- (void)setVolume: (float)volume
{
}

- (CGFloat)volume
{
  return 1.0;
}

@end

