/* 
   NSSlider.h

   The slider control class

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

#ifndef _GNUstep_H_NSSlider
#define _GNUstep_H_NSSlider

#include <AppKit/stdappkit.h>
#include <AppKit/NSControl.h>
#include <Foundation/NSCoder.h>

@interface NSSlider : NSControl <NSCoding>

{
  // Attributes
}

//
// Setting the Cell Class
//
+ (Class)cellClass;
+ (void)setCellClass:(Class)classId;

//
// Modifying an NSSlider's Appearance 
//
- (NSImage *)image;
- (int)isVertical;
- (float)knobThickness;
- (void)setImage:(NSImage *)backgroundImage;
- (void)setKnobThickness:(float)aFloat;
- (void)setTitle:(NSString *)aString;
- (void)setTitleCell:(NSCell *)aCell;
- (void)setTitleColor:(NSColor *)aColor;
- (void)setTitleFont:(NSFont *)fontObject;
- (NSString *)title;
- (id)titleCell;
- (NSColor *)titleColor;
- (NSFont *)titleFont;

//
// Setting and Getting Value Limits 
//
- (double)maxValue;
- (double)minValue;
- (void)setMaxValue:(double)aDouble;
- (void)setMinValue:(double)aDouble;

//
// Handling Events 
//
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSSlider

