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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSBox
#define _GNUstep_H_NSBox

#include <AppKit/stdappkit.h>
#include <AppKit/NSView.h>
#include <AppKit/NSFont.h>
#include <Foundation/NSCoder.h>

@interface NSBox : NSView <NSCoding>

{
@protected
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

