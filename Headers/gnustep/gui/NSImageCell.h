/* 
   NSImageCell.h

   The cell class for NSImage

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@chem.wisc.edu>
   Date: 1999
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSImageCell
#define _GNUstep_H_NSImageCell

#include <AppKit/NSCell.h>
#include <AppKit/NSImageView.h>

/*
typedef enum _NSImageAlignment {
  NSImageAlignLeft,
  NSImageAlignRight,
  NSImageAlignCenter,
  NSImageAlignTop,
  NSImageAlignBottom,
  NSImageAlignTopLeft,
  NSImageAlignTopRight,
  NSImageAlignBottomLeft,
  NSImageAlignBottomRight
} NSImageAlignment;

typedef enum _NSImageFrameStyle {
  NSImageFrameNone,
  NSImageFramePhoto,
  NSImageFrameGrayBezel,
  NSImageFrameGroove,
  NSImageFrameButton
} NSImageFrameStyle;

typedef enum _NSImageScaling {
  NSScaleProportionally,
  NSScaleToFit,
  NSScaleNone
} NSImageScaling;
*/

@interface NSImageCell : NSCell <NSCopying, NSCoding>
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
