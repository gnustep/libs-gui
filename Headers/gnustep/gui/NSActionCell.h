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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSActionCell
#define _GNUstep_H_NSActionCell

#include <AppKit/NSCell.h>

@interface NSActionCell : NSCell <NSCopying, NSCoding>
{
  // Attributes
  int _tag;
  id _target;
  SEL _action;
  NSView *_control_view; 
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
- (void)setIntValue:(int)anInt;
- (void)setFloatValue:(float)aFloat;
- (void)setDoubleValue:(double)aDouble;
- (void)setStringValue:(NSString *)aString;

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
