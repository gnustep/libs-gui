/*
   NSButton.h

   The button class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
	    Ovidiu Predescu <ovidiu@net-community.com>
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

#ifndef _GNUstep_H_NSButton
#define _GNUstep_H_NSButton

#include <AppKit/NSControl.h>
#include <AppKit/NSButtonCell.h>

@class NSString;
@class NSEvent;

@interface NSButton : NSControl
{
  // Attributes
}

//
// Setting the Button Type 
//
- (void)setButtonType:(NSButtonType)aType;
#ifndef STRICT_OPENSTEP
- (void)setHighlightsBy:(int)aType;
- (void)setShowsStateBy:(int)aType;
#endif

//
// Setting the State 
//
- (void)setState:(int)value;
- (int)state;
- (BOOL)allowsMixedState;
- (void)setAllowsMixedState: (BOOL)flag;
- (void)setNextState;

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
#ifndef STRICT_OPENSTEP
- (NSAttributedString *)attributedAlternateTitle;
- (NSAttributedString *)attributedTitle;
- (void)setAttributedAlternateTitle:(NSAttributedString *)aString;
- (void)setAttributedTitle:(NSAttributedString *)aString;
- (void)setTitleWithMnemonic:(NSString *)aString;
#endif

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
#ifndef STRICT_OPENSTEP
- (NSBezelStyle)bezelStyle;
- (void)setBezelStyle:(NSBezelStyle)bezelStyle;
- (void)setShowsBorderOnlyWhileMouseInside:(BOOL)show;
- (BOOL)showsBorderOnlyWhileMouseInside;
#endif

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
- (BOOL)performKeyEquivalent:(NSEvent *)anEvent;

//
// Sound
//
#ifndef STRICT_OPENSTEP
- (void)setSound:(NSSound *)aSound;
- (NSSound *)sound;
#endif

@end

#endif // _GNUstep_H_NSButton
