/* 
   NSScroller.m

   The scroller class

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

#include <gnustep/gui/NSScroller.h>
#include <gnustep/gui/NSWindow.h>
#include <gnustep/base/NSCoder.h>

@implementation NSScroller

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSScroller class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Laying out the NSScroller 
//
+ (float)scrollerWidth
{
  return 0;
}

//
// Instance methods
//
- init
{
  return [self initWithFrame:NSZeroRect];
}

- initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];
  if (frame.size.width > frame.size.height)
    is_horizontal = YES;
  else
    is_horizontal = NO;
  target = nil;
  action = NULL;
  return self;
}
//
// Laying out the NSScroller 
//
- (NSScrollArrowPosition)arrowsPosition
{
  return 0;
}

- (void)checkSpaceForParts
{}

- (NSRect)rectForPart:(NSScrollerPart)partCode
{
  return NSZeroRect;
}

- (void)setArrowsPosition:(NSScrollArrowPosition)where
{}

- (NSUsableScrollerParts)usableParts
{
  return 0;
}

//
// Setting the NSScroller's Values
//
- (float)knobProportion
{
  return 0;
}

- (void)setFloatValue:(float)aFloat
       knobProportion:(float)ratio
{}

//
// Displaying 
//
- (void)drawRect:(NSRect)rect
{
}

- (void)drawArrow:(NSScrollerArrow)whichButton
	highlight:(BOOL)flag
{}

- (void)drawKnob
{}

- (void)drawParts
{}

- (void)highlight:(BOOL)flag
{}

//
// Handling Events 
//
- (NSScrollerPart)hitPart
{
  return 0;
}

- (NSScrollerPart)testPart:(NSPoint)thePoint
{
  return 0;
}

- (void)trackKnob:(NSEvent *)theEvent
{}

- (void)trackScrollButtons:(NSEvent *)theEvent
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_horizontal];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &action];
  [aCoder encodeObjectReference: target withName: @"Target"];
  [aCoder encodeValuesOfObjCTypes: "ff", &percent, &cur_value];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_horizontal];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &action];
  [aDecoder decodeObjectAt: &target withName: NULL];
  [aDecoder decodeValuesOfObjCTypes: "ff", &percent, &cur_value];

  return self;
}

@end

