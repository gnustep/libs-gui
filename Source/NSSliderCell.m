/*
   NSSliderCell.m

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: September 1997
   Rewrite: Richard Frith-Macdonald <richard@brainstorm.co.uk>
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include "gnustep/gui/config.h"

#include <Foundation/NSString.h>

#include <AppKit/NSSliderCell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSTextFieldCell.h>


@implementation NSSliderCell

- (id) init
{
  [self initImageCell: nil];
  _altIncrementValue = -1;
  _isVertical = -1;
  _minValue = 0;
  _maxValue = 1;
  _cell.is_bordered = YES;
  _cell.is_bezeled = YES;

  _knobCell = [NSCell new];

  return self;
}

- (void) dealloc
{
  [_titleCell release];
  [_knobCell release];
  [super dealloc];
}

- (BOOL) isFlipped
{
  return YES;
}

- (void) drawBarInside: (NSRect)rect flipped: (BOOL)flipped
{
  [[NSColor scrollBarColor] set];					
  NSRectFill(rect);
}

- (NSRect) knobRectFlipped: (BOOL)flipped
{
  NSImage* image = [_knobCell image];
  NSSize size;
  NSPoint origin;
  float floatValue = [self floatValue];

  if (_isVertical && flipped)
    floatValue = _maxValue + _minValue - floatValue;

  floatValue = (floatValue - _minValue) / (_maxValue - _minValue);

  size = [image size];

  if (_isVertical)
    {
      origin.x = 0;
      origin.y = (_trackRect.size.height - size.height) * floatValue;
    }
  else
    {
      origin.x = (_trackRect.size.width - size.width) * floatValue;
      origin.y = 0;
    }

  return NSMakeRect (origin.x, origin.y, size.width, size.height); 
}

- (void) drawKnob
{
  [self drawKnob: [self knobRectFlipped: [[self controlView] isFlipped]]];
}

- (void) drawKnob: (NSRect)knobRect
{
  [_knobCell drawInteriorWithFrame: knobRect inView: [self controlView]];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  BOOL vertical = (cellFrame.size.height > cellFrame.size.width);
  NSImage* image;
  NSSize size;

  [controlView lockFocus];
  if (vertical != _isVertical) {
    if (vertical) {
      image = [NSImage imageNamed: @"common_SliderVert"];
      size = [image size];
      [_knobCell setImage: image];
      [image setSize: NSMakeSize (cellFrame.size.width, size.height)];
    }
    else {
      image = [NSImage imageNamed: @"common_SliderHoriz"];
      size = [image size];
      [_knobCell setImage: image];
      [image setSize: NSMakeSize (size.width, cellFrame.size.height)];
    }
  }
  _isVertical = vertical;

  _trackRect = cellFrame;

  if (_titleCell)
    [_titleCell drawInteriorWithFrame: cellFrame inView: controlView];

  [self drawBarInside: cellFrame flipped: [controlView isFlipped]];
  [self drawKnob];
  [controlView unlockFocus];
}

- (BOOL) isOpaque
{
  return YES;
}

- (float) knobThickness
{
  NSImage* image = [_knobCell image];
  NSSize size = [image size];

  return _isVertical ? size.height : size.width;
}

- (void) setKnobThickness: (float)thickness
{
  NSImage* image = [_knobCell image];
  NSSize size = [image size];

  if (_isVertical)
    size.height = thickness;
  else
    size.width = thickness;

  [image setSize: size];
}

- (void) setAltIncrementValue: (double)increment
{
  _altIncrementValue = increment;
}

- (void) setMinValue: (double)aDouble
{
  _minValue = aDouble;
}

- (void) setMaxValue: (double)aDouble
{
  _maxValue = aDouble;
}

- (id) titleCell
{
  return _titleCell;
}

- (NSColor*) titleColor
{
  return [_titleCell textColor];
}

- (NSFont*) titleFont
{
  return [_titleCell font];
}

- (void) setTitle: (NSString*)title
{
  [_titleCell setStringValue: title];
}

- (NSString*) title
{
  return [_titleCell stringValue];
}

- (void) setTitleCell: (NSCell*)aCell
{
  ASSIGN(_titleCell, aCell);
}

- (void) setTitleColor: (NSColor*)color
{
  [_titleCell setTextColor: color];
}

- (void) setTitleFont: (NSFont*)font
{
  [_titleCell setFont: font];
}

- (int) isVertical
{
  return _isVertical;
}

- (double) altIncrementValue
{
  return _altIncrementValue;
}

+ (BOOL) prefersTrackingUntilMouseUp
{
  return YES;
}

- (NSRect) trackRect
{
  return _trackRect;
}

- (double) minValue
{
  return _minValue;
}

- (double) maxValue
{
  return _maxValue;
}

- (float) floatValue
{
  float	aFloat = [super floatValue];
  if (aFloat < _minValue)
    return _minValue;
  else if (aFloat > _maxValue)
    return _maxValue;
  return aFloat;
}

- (id) initWithCoder: (NSCoder*)decoder
{
  self = [super initWithCoder: decoder];
  [decoder decodeValuesOfObjCTypes: "fffi",
    &_minValue, &_maxValue, &_altIncrementValue, &_isVertical];
  [decoder decodeValueOfObjCType: @encode(id) at: &_titleCell];
  [decoder decodeValueOfObjCType: @encode(id) at: &_knobCell];
  return self;
}

- (void) encodeWithCoder: (NSCoder*)coder
{
  [super encodeWithCoder: coder];
  [coder encodeValuesOfObjCTypes: "fffi",
    &_minValue, &_maxValue, &_altIncrementValue, &_isVertical];
  [coder encodeValueOfObjCType: @encode(id) at: &_titleCell];
  [coder encodeValueOfObjCType: @encode(id) at: &_knobCell];
}

@end
