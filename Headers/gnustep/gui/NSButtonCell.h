/* 
   NSButtonCell.h

   The cell class for NSButton

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

#ifndef _GNUstep_H_NSButtonCell
#define _GNUstep_H_NSButtonCell

#include <AppKit/NSActionCell.h>

@class NSFont;
@class NSSound;

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

typedef enum _NSBezelStyle {
  NSRoundedBezelStyle,
  NSRegularSquareBezelStyle,
  NSThickSquareBezelStyle,
  NSThickerSquareBezelStyle,
  NSNeXTBezelStyle,
  NSPushButtonBezelStyle,
  NSSmallIconButtonBezelStyle,
  NSMediumIconButtonBezelStyle,
  NSLargeIconButtonBezelStyle
} NSBezelStyle;

typedef enum _NSGradientType {
    NSGradientNone,
    NSGradientConcaveWeak,
    NSGradientConcaveStrong,
    NSGradientConvexWeak,
    NSGradientConvexStrong
} NSGradientType;


@interface NSButtonCell : NSActionCell
{
  // Attributes
  NSString *_altContents;
  NSImage *_altImage;
  NSString *_keyEquivalent;
  NSFont *_keyEquivalentFont;
  NSSound *_sound;
  unsigned int _keyEquivalentModifierMask;
  unsigned int _highlightsByMask;
  unsigned int _showAltStateMask;
  float _delayInterval;
  float _repeatInterval;
  NSBezelStyle _bezel_style;
  NSGradientType _gradient_type;
  BOOL _shows_border_only_while_mouse_inside;
  BOOL _mouse_inside;
  // Think of the following as a BOOL ivars
#define _buttoncell_is_transparent _cell.subclass_bool_one
#define _image_dims_when_disabled _cell.subclass_bool_two
}

//
// Setting the Titles 
//
- (NSString *)alternateTitle;
- (void)setAlternateTitle:(NSString *)aString;
- (void)setFont:(NSFont *)fontObject;
- (void)setTitle:(NSString *)aString;
- (NSString *)title;
#ifndef STRICT_OPENSTEP
- (NSAttributedString *)attributedAlternateTitle;
- (NSAttributedString *)attributedTitle;
- (void)setAttributedAlternateTitle:(NSAttributedString *)aString;
- (void)setAttributedTitle:(NSAttributedString *)aString;
- (void)setTitleWithMnemonic:(NSString *)aString;
- (NSString *)alternateMnemonic;
- (unsigned)alternateMnemonicLocation;
- (void)setAlternateMnemonicLocation:(unsigned)location;
- (void)setAlternateTitleWithMnemonic:(NSString *)aString;
#endif

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
#ifndef STRICT_OPENSTEP
- (NSBezelStyle)bezelStyle;
- (void)setBezelStyle:(NSBezelStyle)bezelStyle;
- (BOOL)showsBorderOnlyWhileMouseInside;
- (void)setShowsBorderOnlyWhileMouseInside:(BOOL)show;
- (NSGradientType)gradientType;
- (void)setGradientType:(NSGradientType)gradientType;
- (BOOL)imageDimsWhenDisabled;
- (void)setImageDimsWhenDisabled:(BOOL)flag;
#endif

//
// Modifying Graphic Attributes 
//
- (int)highlightsBy;
- (void)setHighlightsBy:(int)aType;
- (void)setShowsStateBy:(int)aType;
- (void)setButtonType:(NSButtonType)aType;
- (int)showsStateBy;

//
// Sound
//
#ifndef STRICT_OPENSTEP
- (void)setSound:(NSSound *)aSound;
- (NSSound *)sound;
#endif

//
// Mouse
//
#ifndef STRICT_OPENSTEP
- (void)mouseEntered:(NSEvent *)event;
- (void)mouseExited:(NSEvent *)event;
- (void)performClick:(id)sender;
#endif

@end

#endif // _GNUstep_H_NSButtonCell
