/* 
   NSTextFieldCell.h

   Cell class for the text field entry control

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

#ifndef _GNUstep_H_NSTextFieldCell
#define _GNUstep_H_NSTextFieldCell

#include <AppKit/NSActionCell.h>

@class NSColor;

@interface NSTextFieldCell : NSActionCell <NSCoding>
{
  // Attributes
  NSColor *_background_color;
  NSColor *_text_color;
  BOOL _draws_background;
  // The following is different from _draws_background 
  // if we are using a semi-transparent color.
  BOOL _isOpaque;
}

//
// Modifying Graphic Attributes 
//
- (void)setTextColor:(NSColor *)aColor;
- (NSColor *)textColor;

- (void)setDrawsBackground:(BOOL)flag;
- (BOOL)drawsBackground;

- (void)setBackgroundColor:(NSColor *)aColor;
- (NSColor *)backgroundColor;

- (id)setUpFieldEditorAttributes:(id)textObject;


//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSTextFieldCell
