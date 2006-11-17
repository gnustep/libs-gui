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
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSButtonCell
#define _GNUstep_H_NSButtonCell
#import <GNUstepBase/GSVersionMacros.h>

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
  // These come from MacOSX
  NSMomentaryLight,
  NSMomentaryLightButton = NSMomentaryLight,
  NSMomentaryPushInButton = NSMomentaryPushButton
} NSButtonType;

typedef enum _NSBezelStyle {
  NSRoundedBezelStyle,
  NSRegularSquareBezelStyle,
  NSThickSquareBezelStyle,
  NSThickerSquareBezelStyle,
  // The next five no longer show up in the MacOSX documentation
  NSNeXTBezelStyle,
  NSPushButtonBezelStyle,
  NSSmallIconButtonBezelStyle,
  NSMediumIconButtonBezelStyle,
  NSLargeIconButtonBezelStyle,
  // But those two do
  NSShadowlessSquareBezelStyle,
  NSCircularBezelStyle
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
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
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
- (void)setKeyEquivalent:(NSString *)key;
- (void)setKeyEquivalentModifierMask:(unsigned int)mask;
- (void)setKeyEquivalentFont:(NSFont *)fontObj;
- (void)setKeyEquivalentFont:(NSString *)fontName 
			size:(float)fontSize;

//
// Modifying Graphic Attributes 
//
- (BOOL)isTransparent;
- (void)setTransparent:(BOOL)flag;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
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
- (void)setHighlightsBy:(int)mask;
- (void)setShowsStateBy:(int)mask;
- (void)setButtonType:(NSButtonType)buttonType;
- (int)showsStateBy;

//
// Sound
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)setSound:(NSSound *)aSound;
- (NSSound *)sound;
#endif

//
// Mouse
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)mouseEntered:(NSEvent *)event;
- (void)mouseExited:(NSEvent *)event;
#endif

@end

#endif // _GNUstep_H_NSButtonCell
