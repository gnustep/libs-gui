/* 
   NSBox.m

   Simple box view that can display a border and title

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

#include <Foundation/NSArray.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSTextFieldCell.h>

@implementation NSBox

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSBox class])
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
  [super initWithFrame:frameRect];

  cell = [[NSTextFieldCell alloc] initTextCell:@"Title"];
  offsets.width = 5;
  offsets.height = 5;
  border_rect = bounds;
  border_type = NSLineBorder;
  title_position = NSAtTop;
  title_rect = NSZeroRect;
  [self setContentView: [[NSView alloc] init]];

  return self;
}

- (void)dealloc
{
  if (cell) [cell release];
  if (content_view) [content_view release];
  [super dealloc];
}

//
// Getting and Modifying the Border and Title 
//
- (NSRect)borderRect
{
  return border_rect;
}

- (NSBorderType)borderType
{
  return border_type;
}

- (void)setBorderType:(NSBorderType)aType
{
  border_type = aType;
}

- (void)setTitle:(NSString *)aString
{
  [cell setStringValue:aString];
}

- (void)setTitleFont:(NSFont *)fontObj
{
  [cell setFont:fontObj];
}

- (void)setTitlePosition:(NSTitlePosition)aPosition
{
  title_position = aPosition;
}

- (NSString *)title
{
  return [cell stringValue];
}

- (id)titleCell
{
  return cell;
}

- (NSFont *)titleFont
{
  return [cell font];
}

- (NSTitlePosition)titlePosition
{
  return title_position;
}

- (NSRect)titleRect
{
  return title_rect;
}

//
// Setting and Placing the Content View 
//
- (id)contentView
{
  return content_view;
}

- (NSSize)contentViewMargins
{
  return offsets;
}

- (void)setContentView:(NSView *)aView
{
  NSRect r;

  if (content_view)
    {
      // Tell view that it is no longer in a window
      [content_view viewWillMoveToWindow:nil];
      [content_view release];
    }
  content_view = aView;
  [content_view retain];

  // We only have one view in our subview array
  [sub_views release];
  sub_views = [NSMutableArray array];
  if ([sub_views count] == 0)
    {
      [sub_views addObject:aView];
    }

  [content_view setSuperview:self];
  [content_view setNextResponder:self];
  [content_view viewWillMoveToWindow:window];
  r.origin.x = bounds.origin.x + offsets.width;
  r.origin.y = bounds.origin.y + offsets.height;
  r.size.width = bounds.size.width - (2 * offsets.width);
  r.size.height = bounds.size.height - (2 * offsets.height);
  [content_view setFrame:r];
}

- (void)setContentViewMargins:(NSSize)offsetSize
{
  offsets = offsetSize;
}

//
// Resizing the Box 
//
- (void)setFrameFromContentFrame:(NSRect)contentFrame
{
}

- (void)sizeToFit
{}

//
// Managing the NSView Hierarchy 
//
- (void)addSubview:(NSView *)aView
{
  // Subviews get added to our content view's list
  [content_view addSubview:aView];
}

//
// Displaying
//
- (void)drawRect:(NSRect)rect
{
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: cell];
  [aCoder encodeObject: content_view];
  [aCoder encodeSize: offsets];
  [aCoder encodeRect: border_rect];
  [aCoder encodeRect: title_rect];
  [aCoder encodeValueOfObjCType: @encode(NSBorderType) at: &border_type];
  [aCoder encodeValueOfObjCType: @encode(NSTitlePosition) at: &title_position];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  cell = [aDecoder decodeObject];
  content_view = [aDecoder decodeObject];
  offsets = [aDecoder decodeSize];
  border_rect = [aDecoder decodeRect];
  title_rect = [aDecoder decodeRect];
  [aDecoder decodeValueOfObjCType: @encode(NSBorderType) at: &border_type];
  [aDecoder decodeValueOfObjCType: @encode(NSTitlePosition) 
	    at: &title_position];

  return self;
}

@end
