/* 
   NSSliderCell.h

   Cell class for slider control

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSSliderCell
#define _GNUstep_H_NSSliderCell

#include <AppKit/stdappkit.h>
#include <AppKit/NSActionCell.h>
#include <Foundation/NSCoder.h>

@interface NSSliderCell : NSActionCell <NSCoding>

{
  // Attributes
  double max_value;
  double min_value;
  double scale_factor;
  int scroll_size;
  int knob_thickness; 
  double page_value;
  BOOL is_vertical;

  // Reserved for back-end use
  void *be_sc_reserved;
}

//
// Determining Component Sizes 
//
- (NSSize)cellSizeForBounds:(NSRect)aRect;
- (NSRect)knobRectFlipped:(BOOL)flipped;

//
// Setting Value Limits 
//
- (double)maxValue;
- (double)minValue;
- (void)setMaxValue:(double)aDouble;
- (void)setMinValue:(double)aDouble;

//
// Modifying Graphic Attributes 
//
- (void)setVertical:(BOOL)value;
- (int)isVertical;
- (float)knobThickness;
- (void)setKnobThickness:(float)aFloat;
- (void)setTitle:(NSString *)aString;
- (void)setTitleCell:(NSCell *)aCell;
- (void)setTitleColor:(NSColor *)aColor;
- (void)setTitleFont:(NSFont *)fontObject;
- (NSString *)title;
- (id)titleCell;
- (NSFont *)titleFont;
- (NSColor *)titleColor;

//
// Displaying the NSSliderCell 
//
- (void)drawBarInside:(NSRect)aRect
	      flipped:(BOOL)flipped;
- (void)drawKnob;
- (void)drawKnob:(NSRect)knobRect;

//
// Modifying Behavior 
//
- (double)altIncrementValue;
- (void)setAltIncrementValue:(double)incValue;

//
// Tracking the Mouse 
//
+ (BOOL)prefersTrackingUntilMouseUp;
- (NSRect)trackRect;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSSliderCell
