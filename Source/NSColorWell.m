/* 
   NSColorWell.m

   NSControl for selecting and display a single color value.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: May 1998
   
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
#include <AppKit/NSActionCell.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>


@implementation NSColorWell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorWell class])
    [self setVersion: 1];
}

// FIXME: This is a hack.  An NSColorWell shouldn't need an associated
// cell, but without one the setTarget: and setAction: methods get passed
// to an NSCell object by the superclass (NSControl).  NSCell raises an
// exception on these methods, but NSActionCell actually implements them.
+ (Class)cellClass
{
  return [NSActionCell class];
}

//
// Instance methods
//
- (id) initWithFrame: (NSRect)frameRect
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

/*
 * Drawing
 */
- (void) drawRect: (NSRect)rect
{
  NSRect aRect = bounds;
  
  if (NSIntersectsRect(aRect, rect) == NO)
    return;

  if (is_bordered)
    {
      /*
       * Draw outer frame.
       */
      NSDrawButton(aRect, rect);

      /*
       * Fill in control color.
       */
      aRect = NSInsetRect(aRect, 2.0, 2.0);
      [[NSColor controlColor] set];
      NSRectFill(NSIntersectionRect(aRect, rect));

      aRect = NSInsetRect(aRect, 5.0, 5.0);

      /*
       * OpenStep 4.2 behavior is to omit the inner border for
       * non-enabled NSColorWell objects.
       */
      if ([self isEnabled])
        {
          /*
           * Draw inner frame.
           */
          NSDrawGrayBezel(aRect, rect);
          aRect = NSInsetRect(aRect, 2.0, 2.0);
        }
    }
  else
    aRect = NSInsetRect(aRect, 9.0, 9.0);

  [self drawWellInside: NSIntersectionRect(aRect, rect)];
}

- (void) drawWellInside: (NSRect)insideRect
{
  if (NSIsEmptyRect(insideRect))
    return;
  [the_color drawSwatchInRect: insideRect];
}

- (BOOL) isOpaque
{
  return is_bordered;
}


//
// Activating 
//
- (void)activate: (BOOL)exclusive
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

- (void)setColor: (NSColor *)color
{
  ASSIGN(the_color, color);
  [self display];
}

- (void)takeColorFrom: (id)sender
{
  if ([sender respondsToSelector: @selector(color)])
    ASSIGN(the_color, [sender color]);
}

//
// Managing Borders 
//
- (BOOL)isBordered
{
  return is_bordered;
}

- (void)setBordered: (BOOL)bordered
{
  is_bordered = bordered;
  [self display];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: the_color];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_active];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_bordered];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &the_color];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_active];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_bordered];

  return self;
}

@end

