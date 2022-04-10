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

int video_main(NSMovieView *view);

@interface VideoOutputSink : NSObject <GSVideoSink>
{
  NSMovieView *_movieView;
}
@end

@implementation VideoOutputSink

- (void)dealloc
{
  _movieView = nil;
  
  [super dealloc];
}

- (id)initWithMovieView: (NSMovieView *)movieView
{
  self = [super init];

  if (self != nil)
    {
      [self setMovieView: movieView];  // weak
    }
  
  return self;
}

- (void)setVolume: (float)volume
{
}

- (CGFloat)volume
{
  return 1.0;
}

- (void) setMovieView: (NSMovieView *)view
{
  _movieView = view; // weak, don't retain since the view is retained by its parent view.
}

- (NSMovieView *) movieView
{
  return _movieView;
}

- (void) stop
{
}

- (void) play
{
  video_main(_movieView);
}

@end

