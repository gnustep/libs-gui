/** <title>NSStepperCell</title>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#include "config.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSColor.h"
#include "AppKit/DPSOperators.h"
#include "AppKit/PSOperators.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSStepperCell.h"
#include "AppKit/NSText.h"
#include "GNUstepGUI/GSDrawFunctions.h"

@implementation NSStepperCell
+ (void) initialize
{
  if (self == [NSStepperCell class])
    {
      [self setVersion: 1];
    }
}

//
// Initialization
//
- (id) init
{
  [self setIntValue: 0];
  [super setAlignment: NSRightTextAlignment];
  [super setWraps: NO];
  _autorepeat = YES;
  _valueWraps = YES;
  _maxValue = 59;
  _minValue = 0;
  _increment = 1;
  highlightUp = NO;
  highlightDown = NO;
  return self;
}

- (double) maxValue
{
  return _maxValue;
}

- (void) setMaxValue: (double)maxValue
{
  _maxValue = maxValue;
}

- (double) minValue
{
  return _minValue;
}

- (void) setMinValue: (double)minValue
{
  _minValue = minValue;
}

- (double) increment
{
  return _increment;
}

- (void) setIncrement: (double)increment
{
  _increment = increment;
}



- (BOOL)autorepeat
{
  return _autorepeat;
}

- (void)setAutorepeat: (BOOL)autorepeat
{
  _autorepeat = autorepeat;
}

- (BOOL)valueWraps
{
  return _valueWraps;
}

- (void)setValueWraps: (BOOL)valueWraps
{
  _valueWraps = valueWraps;
}

- (void) dealloc
{
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSStepperCell *c = [super copyWithZone: zone];

  return c;
}

static inline NSRect DrawLightButton(NSRect border, NSRect clip)
{
/*
  NSRect highlightRect = NSInsetRect(border, 1., 1.);
  [GSDrawFunctions drawButton: border : clip];
  return highlightRect;
*/
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge}; 
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge}; 
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, dark, white, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
}

 static inline void DrawUpButton(NSRect aRect)
{
  NSRect unHighlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor controlBackgroundColor] set];
  NSRectFill(unHighlightRect);
      
  PSsetgray(NSDarkGray);
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  PSsetgray(NSWhite);
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

static inline void HighlightUpButton(NSRect aRect)
{
  NSRect highlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor selectedControlColor] set];
  NSRectFill(highlightRect);
  
  PSsetgray(NSLightGray);
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  PSsetgray(NSLightGray);
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

static inline void DrawDownButton(NSRect aRect)
{
  NSRect unHighlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor controlBackgroundColor] set];
  NSRectFill(unHighlightRect);

  PSsetlinewidth(1.0);
  PSsetgray(NSDarkGray);
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  PSsetgray(NSWhite);
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

static inline void HighlightDownButton(NSRect aRect)
{
  NSRect highlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor selectedControlColor] set];
  NSRectFill(highlightRect);
  
  PSsetlinewidth(1.0);
  PSsetgray(NSLightGray);
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  PSsetgray(NSLightGray);
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame
			inView: (NSView*)controlView
{
  NSRect upRect;
  NSRect downRect;
  NSRect twoButtons;

  upRect = [self upButtonRectWithFrame: cellFrame];
  downRect = [self downButtonRectWithFrame: cellFrame];
  
  twoButtons = downRect;
  twoButtons.origin.y--;
  twoButtons.size.width++;
  twoButtons.size.height = 23;

  if (highlightUp)
    HighlightUpButton(upRect);
  else
    DrawUpButton(upRect);

  if (highlightDown)
    HighlightDownButton(downRect);
  else
    DrawDownButton(downRect);

  {
    NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge};
    float grays[] = {NSBlack, NSBlack}; 
    
    NSDrawTiledRects(twoButtons, NSZeroRect,
		     up_sides, grays, 2);
  }
}

- (void) highlight: (BOOL) highlight
	  upButton: (BOOL) upButton
	 withFrame: (NSRect) frame
	    inView: (NSView*) controlView
{
  if (upButton)
    {  
      highlightUp = highlight;
    }
  else
    {
      highlightDown = highlight;
    }

  [self drawWithFrame: frame inView: controlView];
}

- (NSRect) upButtonRectWithFrame: (NSRect) frame
{
  NSRect upRect;
  upRect.size.width = 15;
  upRect.size.height = 11;
  upRect.origin.x = NSMaxX(frame) - 16;
  upRect.origin.y = NSMinY(frame) + ((int) frame.size.height / 2) + 1;
  return upRect;
}

- (NSRect) downButtonRectWithFrame: (NSRect) frame
{
  NSRect downRect;
  downRect.size.width = 15;
  downRect.size.height = 11;
  downRect.origin.x = NSMaxX(frame) - 16;
  downRect.origin.y = NSMinY(frame) + 
    ((int) frame.size.height / 2) - 10;
  return downRect;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  int tmp1, tmp2;
  [super encodeWithCoder: aCoder];

  tmp1 = (int)_autorepeat;
  tmp2 = (int)_valueWraps;

  [aCoder encodeValueOfObjCType: @encode(double)
	  at: &_maxValue];
  [aCoder encodeValueOfObjCType: @encode(double)
	  at: &_minValue];
  [aCoder encodeValueOfObjCType: @encode(double)
	  at: &_increment];
  [aCoder encodeValueOfObjCType: @encode(int)
	  at: &tmp1];
  [aCoder encodeValueOfObjCType: @encode(int)
	  at: &tmp2];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  int tmp1, tmp2;
  [super initWithCoder: aDecoder];

  if([aDecoder allowsKeyedCoding])
    {
      _autorepeat = [aDecoder decodeBoolForKey: @"NSAutorepeat"];
      _valueWraps = [aDecoder decodeBoolForKey: @"NSValueWraps"];
      _increment = [aDecoder decodeIntForKey: @"NSIncrement"];
      _maxValue = [aDecoder decodeIntForKey: @"NSMaxValue"];
      if([aDecoder containsValueForKey: @"NSMinValue"])
	{
	  _minValue = [aDecoder decodeIntForKey: @"NSMinValue"];
	}
    }
  else
    {
      [aDecoder decodeValueOfObjCType: @encode(double)
		at: &_maxValue];
      [aDecoder decodeValueOfObjCType: @encode(double)
		at: &_minValue];
      [aDecoder decodeValueOfObjCType: @encode(double)
		at: &_increment];
      [aDecoder decodeValueOfObjCType: @encode(int)
		at: &tmp1];
      [aDecoder decodeValueOfObjCType: @encode(int)
		at: &tmp2];

      _autorepeat = (BOOL)tmp1;
      _valueWraps = (BOOL)tmp2;
    }

  return self;
}

@end
