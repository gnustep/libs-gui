/* 
   NSColorWell.m

   NSControl for selecting and display a single color value.

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

#include <gnustep/gui/config.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSColor.h>

@implementation NSColorWell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorWell class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//
- initWithFrame:(NSRect)frameRect
{
  [super initWithFrame: frameRect];

  is_bordered = YES;
  is_active = NO;
  the_color = [[NSColor blackColor] retain];

  return self;
}

- (void)dealloc
{
  [the_color release];
  [super dealloc];
}

//
// Drawing
//
- (void)drawRect:(NSRect)rect
{
  NSDebugLog(@"NSColorWell drawRect: %f %f %f %f\n", rect.origin.x, 
	     rect.origin.y,
	     rect.size.width, rect.size.height);

  // Draw border
  if (is_bordered)
    [self drawBorderRect: rect];

  // Draw the color inside
  [self drawWellInside: rect];
}

- (void)drawWellInside:(NSRect)insideRect
{
}

//
// Activating 
//
- (void)activate:(BOOL)exclusive
{
  is_active = YES;
}

- (void)deactivate
{
  is_active = NO;
}

- (BOOL)isActive
{
  return is_active;
}

//
// Managing Color 
//
- (NSColor *)color
{
  return the_color;
}

- (void)setColor:(NSColor *)color
{
  ASSIGN(the_color, color);
}

- (void)takeColorFrom:(id)sender
{
  if ([sender respondsToSelector:@selector(color)])
    ASSIGN(the_color, [sender color]);
}

//
// Managing Borders 
//
- (BOOL)isBordered
{
  return is_bordered;
}

- (void)setBordered:(BOOL)bordered
{
  is_bordered = bordered;
  [self display];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject: the_color];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_active];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_bordered];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];
  the_color = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_active];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_bordered];

  return self;
}

@end

//
// GNUstep backend methods
//
@implementation NSColorWell (GNUstepBackend)

- (void)drawBorderRect:(NSRect)aRect
{
}

@end
