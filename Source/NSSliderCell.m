/* 
   NSSliderCell.m

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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/NSSliderCell.h>
#include <gnustep/gui/NSControl.h>
#include <gnustep/gui/NSApplication.h>
#include <gnustep/gui/NSEvent.h>
#include <gnustep/gui/NSWindow.h>

//
// NSSliderCell implementation
//
@implementation NSSliderCell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSliderCell class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//
//
// Initialization
//
- init
{
  [self initTextCell:@""];
  return self;
}

- initImageCell:(NSImage *)anImage
{
  return nil;
}

- initTextCell:(NSString *)aString
{
  [super initTextCell:aString];
  [self setEnabled:YES];
  knob_thickness = 6;
  page_value = 6;
  [self setDoubleValue:0];
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

//
// Determining Component Sizes 
//
- (NSSize)cellSizeForBounds:(NSRect)aRect
{
  return NSZeroSize;
}

- (NSRect)knobRectFlipped:(BOOL)flipped
{
  return NSZeroRect;
}

//
// Setting the NSCell's Value 
//
- (void)setDoubleValue:(double)aDouble
{
  double value = aDouble;

  if (aDouble < min_value) value = min_value;
  if (aDouble > max_value) value = max_value;
  [super setDoubleValue:value];
}

- (void)setFloatValue:(float)aFloat
{
  [self setDoubleValue:(double)aFloat];
}

- (void)setIntValue:(int)anInt
{
  [self setDoubleValue:(double)anInt];
}

- (void)setStringValue:(NSString *)aString
{
}

//
// Setting Value Limits 
//
- (double)maxValue
{
  return max_value;
}

- (double)minValue
{
  return min_value;
}

- (void)setMaxValue:(double)aDouble
{
  double val_range,value;

  // Swap values if new max is less than min
  if (aDouble < min_value)
    {
      max_value = min_value;
      min_value = aDouble;
    }
  else
    max_value = aDouble;

  val_range = max_value - min_value;
  if (val_range != 0)
    {
      scale_factor = scroll_size/val_range; 
      if (scale_factor != 0)
	page_value = knob_thickness * (1/scale_factor);
    }
}

- (void)setMinValue:(double)aDouble
{
  double val_range,value;

  // Swap values if new min is greater than max
  if (aDouble > max_value)
    {
      min_value = max_value;
      max_value = aDouble;
    }
  else
    min_value = aDouble;

  val_range = max_value - min_value;
  if (val_range != 0)
    {
      scale_factor = scroll_size/val_range; 
      if (scale_factor != 0)
	page_value = knob_thickness * (1/scale_factor);
    }
}

//
// Modifying Graphic Attributes 
//
- (void)setVertical:(BOOL)value
{
  is_vertical = value;
}

- (int)isVertical
{
  return is_vertical;
}

- (float)knobThickness
{
  return knob_thickness;
}

- (void)setKnobThickness:(float)aFloat
{
  int old_scroll = scroll_size;
  double val_range;

  // Recalculate the scroll size
  scroll_size = old_scroll + knob_thickness;
  knob_thickness = aFloat;
  scroll_size -= knob_thickness;

  val_range = max_value - min_value;
  if (val_range != 0)
    {
      scale_factor = scroll_size/val_range; 
      if (scale_factor != 0)
	page_value = knob_thickness * (1/scale_factor);
    }
}

- (void)setTitle:(NSString *)aString
{}

- (void)setTitleCell:(NSCell *)aCell
{}

- (void)setTitleColor:(NSColor *)aColor
{}

- (void)setTitleFont:(NSFont *)fontObject
{}

- (NSString *)title
{
  return nil;
}

- (id)titleCell
{
  return nil;
}

- (NSFont *)titleFont
{
  return nil;
}

- (NSColor *)titleColor
{
  return nil;
}

//
// Displaying the NSSliderCell 
//
- (void)drawBarInside:(NSRect)aRect
	      flipped:(BOOL)flipped
{}

- (void)drawKnob
{}

- (void)drawKnob:(NSRect)knobRect
{}

//
// Modifying Behavior 
//
- (double)altIncrementValue
{
  return page_value;
}

- (void)setAltIncrementValue:(double)incValue
{
  page_value = incValue;
}

//
// Tracking the Mouse 
//
+ (BOOL)prefersTrackingUntilMouseUp
{
  return NO;
}

- (NSRect)trackRect
{
  return NSZeroRect;
}

//
// Displaying
//
- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView
{
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeValueOfObjCType: "d" at: &max_value];
  [aCoder encodeValueOfObjCType: "d" at: &min_value];
  [aCoder encodeValueOfObjCType: "d" at: &scale_factor];
  [aCoder encodeValueOfObjCType: "i" at: &scroll_size];
  [aCoder encodeValueOfObjCType: "i" at: &knob_thickness];
  [aCoder encodeValueOfObjCType: "d" at: &page_value];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_vertical];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeValueOfObjCType: "d" at: &max_value];
  [aDecoder decodeValueOfObjCType: "d" at: &min_value];
  [aDecoder decodeValueOfObjCType: "d" at: &scale_factor];
  [aDecoder decodeValueOfObjCType: "i" at: &scroll_size];
  [aDecoder decodeValueOfObjCType: "i" at: &knob_thickness];
  [aDecoder decodeValueOfObjCType: "d" at: &page_value];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_vertical];

  return self;
}

@end

