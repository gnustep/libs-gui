/* 
   NSColorWell.m

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSColorWell.h>

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

//
// Drawing
//
- (void)drawWellInside:(NSRect)insideRect
{}

//
// Activating 
//
- (void)activate:(BOOL)exclusive
{}

- (void)deactivate
{}

- (BOOL)isActive
{
  return NO;
}

//
// Managing Color 
//
- (NSColor *)color
{
  return nil;
}

- (void)setColor:(NSColor *)color
{}

- (void)takeColorFrom:(id)sender
{}

//
// Managing Borders 
//
- (BOOL)isBordered
{
  return NO;
}

- (void)setBordered:(BOOL)bordered
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
