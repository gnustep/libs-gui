/* 
   NSButtonCell.h

   The cell class for NSButton

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

#ifndef _GNUstep_H_NSButtonCell
#define _GNUstep_H_NSButtonCell

#include <AppKit/NSActionCell.h>

@class NSFont;

typedef enum _NSButtonType {
  NSMomentaryPushButton,
  NSPushOnPushOffButton,
  NSToggleButton,
  NSSwitchButton,
  NSRadioButton,
  NSMomentaryChangeButton,
  NSOnOffButton,
  NSMomentaryLight
} NSButtonType;

@interface NSButtonCell : NSActionCell <NSCopying, NSCoding>
{
  // Attributes
  NSString *altContents;
  NSImage *altImage;
  NSString* keyEquivalent;
  NSFont* keyEquivalentFont;
  unsigned int keyEquivalentModifierMask;
  BOOL transparent;
  unsigned int highlightsByMask;
  unsigned int showAltStateMask;
  float delayInterval;
  float repeatInterval;

  // Reserved for back-end use
  void *be_bc_reserved;
}

//
// Setting the Titles 
//
- (NSString *)alternateTitle;
- (void)setAlternateTitle:(NSString *)aString;
- (void)setFont:(NSFont *)fontObject;
- (void)setTitle:(NSString *)aString;
- (NSString *)title;

//
// Setting the Images 
//
- (NSImage *)alternateImage;
- (NSCellImagePosition)imagePosition;
- (void)setAlternateImage:(NSImage *)anImage;
- (void)setImagePosition:(NSCellImagePosition)aPosition;

//
// Setting the Repeat Interval 
//
- (void)getPeriodicDelay:(float *)delay
		interval:(float *)interval;
- (void)setPeriodicDelay:(float)delay
		interval:(float)interval;

//
// Setting the Key Equivalent 
//
- (NSString *)keyEquivalent;
- (NSFont *)keyEquivalentFont;
- (unsigned int)keyEquivalentModifierMask;
- (void)setKeyEquivalent:(NSString *)aKeyEquivalent;
- (void)setKeyEquivalentModifierMask:(unsigned int)mask;
- (void)setKeyEquivalentFont:(NSFont *)fontObj;
- (void)setKeyEquivalentFont:(NSString *)fontName 
			size:(float)fontSize;

//
// Modifying Graphic Attributes 
//
- (BOOL)isTransparent;
- (void)setTransparent:(BOOL)flag;

//
// Modifying Graphic Attributes 
//
- (int)highlightsBy;
- (void)setHighlightsBy:(int)aType;
- (void)setShowsStateBy:(int)aType;
- (void)setButtonType:(NSButtonType)aType;
- (int)showsStateBy;

//
// Simulating a Click 
//
- (void)performClick:(id)sender;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSButtonCell
