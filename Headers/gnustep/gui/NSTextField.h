/* 
   NSTextField.h

   Text field control class for text entry

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

#ifndef _GNUstep_H_NSTextField
#define _GNUstep_H_NSTextField

#include <AppKit/NSControl.h>

@class NSNotification;
@class NSColor;
@class NSText;
@class NSCursor;

@interface NSTextField : NSControl <NSCoding>
{
  // Attributes
  id _delegate;
  SEL _error_action;
  NSText *_text_object;
}

//
// Setting User Access to Text 
//
- (BOOL)isEditable;
- (BOOL)isSelectable;
- (void)setEditable:(BOOL)flag;
- (void)setSelectable:(BOOL)flag;

//
// Editing Text 
//
- (void)selectText:(id)sender;

//
// Setting Tab Key Behavior 
//
- (id)nextText;
- (id)previousText;
- (void)setNextText:(id)anObject;
- (void)setPreviousText:(id)anObject;

//
// Assigning a Delegate 
//
- (void)setDelegate:(id)anObject;
- (id)delegate;

//
// Modifying Graphic Attributes 
//
- (NSColor *)backgroundColor;
- (BOOL)drawsBackground;
- (BOOL)isBezeled;
- (BOOL)isBordered;
- (void)setBackgroundColor:(NSColor *)aColor;
- (void)setBezeled:(BOOL)flag;
- (void)setBordered:(BOOL)flag;
- (void)setDrawsBackground:(BOOL)flag;
- (void)setTextColor:(NSColor *)aColor;
- (NSColor *)textColor;

//
// Target and Action 
//
- (SEL)errorAction;
- (void)setErrorAction:(SEL)aSelector;

//
// Handling Events 
//
- (BOOL)acceptsFirstResponder;
- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidChange:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (BOOL)textShouldBeginEditing:(NSText *)textObject;
- (BOOL)textShouldEndEditing:(NSText *)textObject;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSTextField
