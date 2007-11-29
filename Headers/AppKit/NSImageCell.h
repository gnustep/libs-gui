/* 
   NSImageCell.h

   The cell class for NSImage

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@chem.wisc.edu>
   Date: 1999
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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

#ifndef _GNUstep_H_NSImageCell
#define _GNUstep_H_NSImageCell
#import <GNUstepBase/GSVersionMacros.h>

#include <AppKit/NSCell.h>

typedef enum {
    NSScaleProportionally = 0,   // Fit proportionally
    NSScaleToFit,                // Forced fit (distort if necessary)
    NSScaleNone                  // Don't scale (clip)
} NSImageScaling;

typedef enum {
    NSImageAlignCenter = 0,
    NSImageAlignTop,
    NSImageAlignTopLeft,
    NSImageAlignTopRight,
    NSImageAlignLeft,
    NSImageAlignBottom,
    NSImageAlignBottomLeft,
    NSImageAlignBottomRight,
    NSImageAlignRight
} NSImageAlignment;

typedef enum {
    NSImageFrameNone = 0,
    NSImageFramePhoto,
    NSImageFrameGrayBezel,
    NSImageFrameGroove,
    NSImageFrameButton
} NSImageFrameStyle;

@interface NSImageCell : NSCell
{
  // Attributes
  NSImageAlignment _imageAlignment;
  NSImageFrameStyle _frameStyle;
  NSImageScaling _imageScaling;
  NSSize _original_image_size;
}

//
// Aligning and scaling the image
//
- (NSImageAlignment) imageAlignment;
- (void) setImageAlignment: (NSImageAlignment)anAlignment;
- (NSImageScaling) imageScaling;
- (void) setImageScaling: (NSImageScaling)scaling;

//
// Choosing the frame
//
- (NSImageFrameStyle) imageFrameStyle;
- (void) setImageFrameStyle: (NSImageFrameStyle)aFrameStyle;

@end

#endif // _GNUstep_H_NSImageCell
