/* 
   NSCursor.m

   Description...

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

#include <gnustep/gui/NSCursor.h>

@implementation NSCursor

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSCursor class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Setting the Cursor
//
+ (void)hide
{}

+ (void)pop
{}

+ (void)setHiddenUntilMouseMoves:(BOOL)flag
{}

+ (void)unhide
{}

//
// Getting the Cursor
//
+ (NSCursor *)arrowCursor
{
  return nil;
}

+ (NSCursor *)currentCursor
{
  return nil;
}

+ (NSCursor *)IBeamCursor
{
  return nil;
}

//
// Instance methods
//

//
// Initializing a New NSCursor Object
//
- (id)initWithImage:(NSImage *)newImage
{
  return nil;
}

//
// Defining the Cursor
//
- (NSPoint)hotSpot
{
  return NSZeroPoint;
}

- (NSImage *)image
{
  return nil;
}

- (void)setHotSpot:(NSPoint)spot
{}

- (void)setImage:(NSImage *)newImage
{}

//
// Setting the Cursor
//
- (BOOL)isSetOnMouseEntered
{
  return NO;
}

- (BOOL)isSetOnMouseExited
{
  return NO;
}

- (void)mouseEntered:(NSEvent *)theEvent
{}

- (void)mouseExited:(NSEvent *)theEvent
{}

- (void)pop
{}

- (void)push
{}

- (void)set
{}

- (void)setOnMouseEntered:(BOOL)flag
{}

- (void)setOnMouseExited:(BOOL)flag
{}

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
