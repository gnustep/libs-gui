/** <title>NSMovieView</title>

   <abstract>Encapsulate a view for Quicktime movies</abstract>

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

#ifndef _GNUstep_H_GSMovieView
#define _GNUstep_H_GSMovieView

#import "config.h"

#import "AppKit/NSMovieView.h"

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>

@class NSImage;
@class NSTimer;

APPKIT_EXPORT_CLASS
@interface GSMovieView : NSMovieView
{
  NSImage *_currentFrame;
#ifdef HAVE_AVCODEC
  AVFormatContext *_formatContext;
  AVCodecContext *_codecContext;
  AVFrame *_avframe;
  AVFrame *_avframeRGB;
  struct SwsContext *_swsCtx;
#endif
  int _videoStreamIndex;
  uint8_t *_buffer;
  NSTimer *_decodeTimer;
}

- (void) updateImage: (NSImage *)image;
- (void) prepareDecoder;
- (void) decodeAndDisplayNextFrame;

@end

#endif /* _GNUstep_H_NSMovieView */
