/* 
   NSFormCell.m

   The cell class for the NSForm control

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

#include <gnustep/gui/NSFormCell.h>

@implementation NSFormCell

//
// Initializing an NSFormCell 
//
- (id)initTextCell:(NSString *)aString
{
  return nil;
}

//
// Determining an NSFormCell's Size 
//
- (NSSize)cellSizeForBounds:(NSRect)aRect
{
  return NSZeroSize;
}

//
// Determining Graphic Attributes 
//
- (BOOL)isOpaque
{
  return NO;
}

//
// Modifying the Title 
//
- (void)setTitle:(NSString *)aString
{}

- (void)setTitleAlignment:(NSTextAlignment)mode
{}

- (void)setTitleFont:(NSFont *)fontObject
{}

- (void)setTitleWidth:(float)width
{}

- (NSString *)title
{
  return nil;
}

- (NSTextAlignment)titleAlignment
{
  return 0;
}

- (NSFont *)titleFont
{
  return nil;
}

- (float)titleWidth
{
  return 0;
}

- (float)titleWidth:(NSSize)aSize
{
  return 0;
}

//
// Displaying 
//
- (void)drawInteriorWithFrame:(NSRect)cellFrame
		       inView:(NSView *)controlView
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
