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
  return [self initTextCell:@"Field:"];
}

- initTextCell: (NSString *)aString
{
  self = [super initTextCell:@""];
  [self setBezeled:YES];
  [self setAlignment:NSLeftTextAlignment];
  titleWidth = -1;
  titleCell = [[NSCell alloc] initTextCell:aString];
  [titleCell setBordered:NO];
  [titleCell setBezeled:NO];
  [titleCell setAlignment:NSRightTextAlignment];
  return self;
}

- (void)dealloc
{
  [titleCell release];
  [super dealloc];
}

- (BOOL)isOpaque
{
  return [super isOpaque] && [titleCell isOpaque];
}

- (void)setTitle:(NSString*)aString
{
  [titleCell setStringValue:aString];
}

- (void)setTitleAlignment:(NSTextAlignment)mode
{
  [titleCell setAlignment:mode];
}

- (void)setTitleFont:(NSFont*)fontObject
{
  [titleCell setFont:fontObject];
}

- (void)setTitleWidth:(float)width
{
  titleWidth = width;
}

- (NSString*)title
{
  return [titleCell stringValue];
}

- (NSTextAlignment)titleAlignment
{
  return [titleCell alignment];
}

- (NSFont*)titleFont
{
  return [titleCell font];
}

- (float)titleWidth
{
  if (titleWidth < 0)
    return [[titleCell font] widthOfString:[self title]];
  else
    return titleWidth;
}

- (float)titleWidth:(NSSize)size
{
  // TODO
  return 0;
}

- (NSSize)cellSize
{
  NSSize returnedSize;
  NSSize titleSize = [titleCell cellSize];
  NSSize textSize = [super cellSize];
  
  textSize.width = [cell_font widthOfString: @"minimum"];
  textSize.height = [cell_font pointSize] + (2 * yDist) 
    + 2 * ([NSCell sizeForBorderType: NSBezelBorder].height); 
 
  returnedSize.width = titleSize.width + 4 + textSize.width;
  if (titleSize.height > textSize.height)
    returnedSize.height = titleSize.height;
  else
    returnedSize.height = textSize.height; 
  
  return returnedSize;
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSRect titleFrame;
  NSRect textFrame;

  NSDivideRect(cellFrame, &titleFrame, &textFrame,
               [self titleWidth] + 4, NSMinXEdge);
  titleFrame.size.width -= 4; 

  [titleCell drawWithFrame: titleFrame inView: controlView];
  [super drawWithFrame: textFrame inView: controlView];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end

