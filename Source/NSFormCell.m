/* 
   NSFormCell.m

   The cell class for the NSForm control

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   
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
#include <AppKit/NSFormCell.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextFieldCell.h>

@implementation NSFormCell

/* The title attributes are those inherited from the NSActionCell class. */

- init
{
  self = [super init];
  [self setBordered:NO];
  [self setBezeled:NO];
  titleWidth = -1;
  textCell = [NSTextFieldCell new];
  [textCell setBordered:YES];
  [textCell setBezeled:YES];
  return self;
}

- (void)dealloc
{
  [textCell release];
  [super dealloc];
}

- (BOOL)isOpaque
{
  return [super isOpaque] && [textCell isOpaque];
}

- (void)setTitle:(NSString*)aString
{
  [self setStringValue:aString];
}

- (void)setTitleAlignment:(NSTextAlignment)mode
{
  [self setAlignment:mode];
}

- (void)setTitleFont:(NSFont*)fontObject
{
  [self setFont:fontObject];
}

- (void)setTitleWidth:(float)width
{
  titleWidth = width;
}

- (NSString*)title
{
  return [self stringValue];
}

- (NSTextAlignment)titleAlignment
{
  return [self alignment];
}

- (NSFont*)titleFont
{
  return [self font];
}

- (float)titleWidth
{
  if (titleWidth < 0)
    return [[self font] widthOfString:[self title]];
  else
    return titleWidth;
}

- (float)titleWidth:(NSSize)size
{
  // TODO
  return 0;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame
  inView:(NSView*)controlView
{
  NSRect titleRect = cellFrame;
  NSRect textRect;

  titleRect.size.width = [self titleWidth] + 4;
  [super drawInteriorWithFrame:titleRect inView:controlView];

  textRect.origin.x = cellFrame.origin.x + titleRect.size.width;
  textRect.origin.y = cellFrame.origin.y;
  textRect.size.width = cellFrame.size.width - titleRect.size.width;
  textRect.size.height = cellFrame.size.height;
  [textCell drawInteriorWithFrame:textRect inView:controlView];
}

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
