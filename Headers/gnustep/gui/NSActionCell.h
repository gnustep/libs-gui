/* 
   NSActionCell.h

   Abstract cell for target/action paradigm

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

#ifndef _GNUstep_H_NSActionCell
#define _GNUstep_H_NSActionCell

#include <AppKit/stdappkit.h>
#include <AppKit/NSCell.h>
#include <Foundation/NSCoder.h>

@interface NSActionCell : NSCell <NSCoding>

{
  // Attributes
  int tag;
  id target;
  SEL action;
}

//
// Configuring an NSActionCell 
//
- (void)setAlignment:(NSTextAlignment)mode;
- (void)setBezeled:(BOOL)flag;
- (void)setBordered:(BOOL)flag;
- (void)setEnabled:(BOOL)flag;
- (void)setFloatingPointFormat:(BOOL)autoRange
			  left:(unsigned int)leftDigits
right:(unsigned int)rightDigits;
- (void)setFont:(NSFont *)fontObject;
- (void)setImage:(NSImage *)image;

//
// Manipulating NSActionCell Values 
//
- (double)doubleValue;
- (float)floatValue;
- (int)intValue;
- (void)setStringValue:(NSString *)aString;
- (NSString *)stringValue;

//
// Displaying 
//
- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView;
- (NSView *)controlView;

//
// Target and Action 
//
- (SEL)action;
- (void)setAction:(SEL)aSelector;
- (void)setTarget:(id)anObject;
- (id)target;

//
// Assigning a Tag 
//
- (void)setTag:(int)anInt;
- (int)tag;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSActionCell
