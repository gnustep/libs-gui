/*
   NSButton.h

   The button class

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

#ifndef _GNUstep_H_NSButton
#define _GNUstep_H_NSButton

#include <AppKit/stdappkit.h>
#include <AppKit/NSControl.h>
#include <DPSClient/DPSOperators.h>
#include <Foundation/NSCoder.h>

@interface NSButton : NSControl <NSCoding>

{
  // Attributes
}

//
// Initializing the NSButton Factory 
//
+ (Class)cellClass;
+ (void)setCellClass:(Class)classId;

//
// Setting the Button Type 
//
- (void)setType:(NSButtonType)aType;

//
// Setting the State 
//
- (void)setState:(int)value;
- (int)state;

//
// Setting the Repeat Interval 
//
- (void)getPeriodicDelay:(float *)delay
		interval:(float *)interval;
- (void)setPeriodicDelay:(float)delay
		interval:(float)interval;

//
// Setting the Titles 
//
- (NSString *)alternateTitle;
- (void)setAlternateTitle:(NSString *)aString;
- (void)setTitle:(NSString *)aString;
- (NSString *)title;

//
// Setting the Images 
//
- (NSImage *)alternateImage;
- (NSImage *)image;
- (NSCellImagePosition)imagePosition;
- (void)setAlternateImage:(NSImage *)anImage;
- (void)setImage:(NSImage *)anImage;
- (void)setImagePosition:(NSCellImagePosition)aPosition;

//
// Modifying Graphic Attributes 
//
- (BOOL)isBordered;
- (BOOL)isTransparent;
- (void)setBordered:(BOOL)flag;
- (void)setTransparent:(BOOL)flag;

//
// Displaying 
//
- (void)highlight:(BOOL)flag;

//
// Setting the Key Equivalent 
//
- (NSString *)keyEquivalent;
- (unsigned int)keyEquivalentModifierMask;
- (void)setKeyEquivalent:(NSString *)aKeyEquivalent;
- (void)setKeyEquivalentModifierMask:(unsigned int)mask;

//
// Handling Events and Action Messages 
//
- (void)performClick:(id)sender;
- (BOOL)performKeyEquivalent:(NSEvent *)anEvent;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSButton
