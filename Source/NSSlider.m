/* 
   NSSlider.m

   The slider control class

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

#include <gnustep/gui/NSSlider.h>
#include <gnustep/gui/NSSliderCell.h>

//
// class variables
//
id MB_NSSLIDER_CLASS;

//
// NSSlider implementation
//
@implementation NSSlider

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSlider class])
    {
      // Initial version
      [self setVersion:1];

      // Set our cell class to NSSliderCell
      [self setCellClass:[NSSliderCell class]];
    }
}

//
// Setting the Cell Class
//
+ (Class)cellClass
{
  return MB_NSSLIDER_CLASS;
}

+ (void)setCellClass:(Class)classId
{
  MB_NSSLIDER_CLASS = classId;
}

//
// Instance methods
//

//
// Initialization
//
- initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];

  // set our cell
  [[self cell] release];
  [self setCell:[[MB_NSSLIDER_CLASS alloc] init]];
  if (frame.size.width > frame.size.height)
    [cell setVertical:NO];
  else
    [cell setVertical:YES];
  [cell setState:1];
  return self;
}

//
// Modifying an NSSlider's Appearance 
//
- (NSImage *)image
{
  return nil;
}

- (int)isVertical
{
  return [cell isVertical];
}

- (float)knobThickness
{
  return [cell knobThickness];
}

- (void)setImage:(NSImage *)backgroundImage
{}

- (void)setKnobThickness:(float)aFloat
{
  [cell setKnobThickness:aFloat];
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

- (NSColor *)titleColor
{
  return nil;
}

- (NSFont *)titleFont
{
  return nil;
}

//
// Setting and Getting Value Limits 
//
- (double)maxValue
{
  return [cell maxValue];
}

- (double)minValue
{
  return [cell minValue];
}

- (void)setMaxValue:(double)aDouble
{
  [cell setMaxValue:aDouble];
}

- (void)setMinValue:(double)aDouble
{
  [cell setMinValue:aDouble];
}

//
// Handling Events 
//
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return NO;
}

//
// Handling Events and Action Messages 
//
- (void)mouseDown:(NSEvent *)theEvent
{
}

//
// Displaying 
//
- (void)drawRect:(NSRect)rect
{
  [cell drawWithFrame:rect inView:self];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
