/*
   NSSliderCell.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: September 1997
   
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

#ifndef _GNUstep_H_NSSliderCell
#define _GNUstep_H_NSSliderCell

#include <AppKit/NSActionCell.h>

@class NSString;
@class NSColor;
@class NSFont;
@class NSImage;

typedef enum _NSTickMarkPosition
{
    NSTickMarkBelow = 0,
    NSTickMarkAbove,
    NSTickMarkLeft = 0,
    NSTickMarkRight
} NSTickMarkPosition;

@interface NSSliderCell : NSActionCell <NSCoding>
{
  float		_minValue;
  float		_maxValue;
  float		_altIncrementValue;
  id		_titleCell;
  id		_knobCell;
  NSRect	_trackRect;
  BOOL		_isVertical;
  BOOL          _allowsTickMarkValuesOnly;
  int           _numberOfTickMarks;
  NSTickMarkPosition _tickMarkPosition;
}

/* Asking about the cell's behavior */
- (double) altIncrementValue;
+ (BOOL) prefersTrackingUntilMouseUp;
- (NSRect) trackRect;

/* Changing the cell's behavior */
- (void) setAltIncrementValue: (double)increment;

/* Displaying the cell */
- (NSRect) knobRectFlipped: (BOOL)flipped;
- (void) drawBarInside: (NSRect)rect flipped: (BOOL)flipped;
- (void) drawKnob;
- (void) drawKnob: (NSRect)knobRect;

/* Asking about the cell's appearance */
- (float) knobThickness;
- (int) isVertical;
- (NSString*) title;
- (id) titleCell;
- (NSColor*) titleColor;
- (NSFont*) titleFont;

/* Changing the cell's appearance */
- (void) setKnobThickness: (float)thickness;
- (void) setTitle: (NSString*)title;
- (void) setTitleCell: (NSCell*)aCell;
- (void) setTitleColor: (NSColor*)color;
- (void) setTitleFont: (NSFont*)font;

/* Asking about the value limits */
- (double) minValue;
- (double) maxValue;

/* Changing the value limits */
- (void) setMinValue: (double)aDouble;
- (void) setMaxValue: (double)aDouble;

#ifndef	STRICT_OPENSTEP
// ticks
- (BOOL) allowsTickMarkValuesOnly;
- (double) closestTickMarkValueToValue: (double)aValue;
- (int) indexOfTickMarkAtPoint: (NSPoint)point;
- (int) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex: (int)index;
- (void) setAllowsTickMarkValuesOnly: (BOOL)flag;
- (void) setNumberOfTickMarks: (int)numberOfTickMarks;
- (void) setTickMarkPosition: (NSTickMarkPosition)position;
- (NSTickMarkPosition) tickMarkPosition;
- (double) tickMarkValueAtIndex: (int)index;
#endif

@end

#endif /* _GNUstep_H_NSSliderCell */
