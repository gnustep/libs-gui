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

#include <AppKit/stdappkit.h>
#include <AppKit/NSActionCell.h>
#include <DPSClient/DPSOperators.h>
#include <AppKit/NSColor.h>
#include <Foundation/NSCoder.h>

@interface NSTextFieldCell : NSActionCell <NSCoding>

{
  // Attributes
  NSColor *background_color;
  NSColor *text_color;
  BOOL draw_background;
  BOOL pending_select;

  // Reserved for back-end use
  void *be_tfc_reserved;
}

//
// Modifying Graphic Attributes 
//
- (NSColor *)backgroundColor;
- (BOOL)drawsBackground;
- (void)setBackgroundColor:(NSColor *)aColor;
- (void)setDrawsBackground:(BOOL)flag;
- (void)setTextColor:(NSColor *)aColor;
- (id)setUpFieldEditorAttributes:(id)textObject;
- (NSColor *)textColor;

//
// Edit text
//
- (void)selectText:(id)sender;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSTextFieldCell
