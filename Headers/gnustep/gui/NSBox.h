/* 
   NSBox.h

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

#ifndef _GNUstep_H_NSBox
#define _GNUstep_H_NSBox

#include <AppKit/NSView.h>

@class NSString;
@class NSFont;

typedef enum _NSTitlePosition {
  NSNoTitle,
  NSAboveTop,
  NSAtTop,
  NSBelowTop,
  NSAboveBottom,
  NSAtBottom,
  NSBelowBottom
} NSTitlePosition;

@interface NSBox : NSView <NSCoding>
{
  // Attributes
  id cell;
  id content_view;
  NSSize offsets;
  NSRect border_rect;
  NSRect title_rect;
  NSBorderType border_type;
  NSTitlePosition title_position;
}

//
// Getting and Modifying the Border and Title 
//
- (NSRect)borderRect;
- (NSBorderType)borderType;
- (void)setBorderType:(NSBorderType)aType;
- (void)setTitle:(NSString *)aString;
- (void)setTitleFont:(NSFont *)fontObj;
- (void)setTitlePosition:(NSTitlePosition)aPosition;
- (NSString *)title;
- (id)titleCell;
- (NSFont *)titleFont;
- (NSTitlePosition)titlePosition;
- (NSRect)titleRect;

//
// Setting and Placing the Content View 
//
- (id)contentView;
- (NSSize)contentViewMargins;
- (void)setContentView:(NSView *)aView;
- (void)setContentViewMargins:(NSSize)offsetSize;

//
// Resizing the Box 
//
- (void)setFrameFromContentFrame:(NSRect)contentFrame;
- (void)sizeToFit;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSBox

