/* 
   NSButtonCell.h

   The cell class for NSButton

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
	    Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSButtonCell
#define _GNUstep_H_NSButtonCell
#import <GNUstepBase/GSVersionMacros.h>

#import <AppKit/NSActionCell.h>

@class NSFont;
@class NSSound;

/** Type of button in an NSButton or NSButtonCell.
 * <deflist>
 *  <term>NSMomentaryPushInButton</term>
 *   <desc><em>Default button type!</em>  Pushed in and lit when mouse is 
 *         down, pushed out and unlit when mouse is release.</desc>
 *  <term>NSPushOnPushOffButton</term>
 *   <desc>Used to show/store ON / OFF states.  In when ON, out when OFF.</desc>
 *  <term>NSToggleButton</term>
 *   <desc>Like NSPushOnPushOffButton but images is changed for ON and 
 *         OFF state.</desc>
 *  <term>NSSwitchButton</term>
 *   <desc>A borderless NSToggleButton</desc>
 *  <term>NSRadioButton</term>
 *   <desc>A type of NSSwitchButton similar to a Microsoft Windows radio 
 *         button.</desc>
 *  <term>NSMomentaryChangeButton</term>
 *   <desc>Image of button changes on mouse down and then changes back 
 *         once released.</desc>
 *  <term>NSOnOffButton</term>
 *   <desc>Simple ON / OFF button.  First click lights the button, 
 *         seconds click unlights it.</desc>
 *  <term>NSMomentaryLightButton</term>
 *   <desc>Like NSMomentaryPushInButton but button is not pushed 
 *         in on mouse down</desc>
 *
 *  <term>NSMomentaryLight</term>
 *   <desc>Same as NSMomentaryPushInButton. Has been depricated in Cocoa.</desc>
 *  <term>NSMomentaryPushButton</term>
 *   <desc>Same as NSMomentaryLightButton. Has been depricated in 
 *         Cocoa.</desc>
 * </deflist>
 */
typedef enum _NSButtonType {
  NSMomentaryLightButton,
  NSPushOnPushOffButton,
  NSToggleButton,
  NSSwitchButton,
  NSRadioButton,
  NSMomentaryChangeButton,
  NSOnOffButton,
  NSMomentaryPushInButton,
  // These are old names
  NSMomentaryLight = NSMomentaryPushInButton,
  NSMomentaryPushButton = NSMomentaryLightButton
} NSButtonType;

typedef enum _NSBezelStyle {
  NSRoundedBezelStyle = 1,
  NSRegularSquareBezelStyle,
  NSThickSquareBezelStyle,
  NSThickerSquareBezelStyle,
  NSDisclosureBezelStyle,
  NSShadowlessSquareBezelStyle,
  NSCircularBezelStyle,
  NSTexturedSquareBezelStyle,
  NSHelpButtonBezelStyle,
  NSSmallSquareBezelStyle,
  NSTexturedRoundedBezelStyle,
  NSRoundRectBezelStyle,
  NSRecessedBezelStyle,
  NSRoundedDisclosureBezelStyle,
  // The next five no longer show up in the MacOSX documentation
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

typedef struct _GSButtonCellFlags
{
#if GS_WORDS_BIGENDIAN == 1
  unsigned int isPushin:1;
  unsigned int changeContents:1;
  unsigned int changeBackground:1;
  unsigned int changeGray:1;
  
  unsigned int highlightByContents:1;
  unsigned int highlightByBackground:1;
  unsigned int highlightByGray:1;
  unsigned int drawing:1;
  
  unsigned int isBordered:1;
  unsigned int imageDoesOverlap:1;
  unsigned int isHorizontal:1;
  unsigned int isBottomOrLeft:1;
  
  unsigned int isImageAndText:1;
  unsigned int isImageSizeDiff:1;
  unsigned int hasKeyEquiv:1;
  unsigned int lastState:1;
  
  unsigned int isTransparent:1;
  unsigned int inset:2; // inset:2
  unsigned int doesNotDimImage:1; //doesn't dim:1
  
  unsigned int gradient:3; // gradient:3
  unsigned int useButtonImageSource:1;
  
  unsigned int unused2:8; // alt mnemonic loc.
#else
  unsigned int unused2:8; // alt mnemonic loc.
  unsigned int useButtonImageSource:1;
  unsigned int gradient:3; // gradient:3
  unsigned int doesNotDimImage:1; // doesn't dim:1
  unsigned int inset:2; // inset:2
  unsigned int isTransparent:1;
  unsigned int lastState:1;
  unsigned int hasKeyEquiv:1;
  unsigned int isImageSizeDiff:1;
  unsigned int isImageAndText:1;
  unsigned int isBottomOrLeft:1;
  unsigned int isHorizontal:1;
  unsigned int imageDoesOverlap:1;
  unsigned int isBordered:1;
  unsigned int drawing:1;
  unsigned int highlightByGray:1;
  unsigned int highlightByBackground:1;
  unsigned int highlightByContents:1;
  unsigned int changeGray:1;
  unsigned int changeBackground:1;
  unsigned int changeContents:1;
  unsigned int isPushin:1;
#endif
} GSButtonCellFlags;

typedef union _GSButtonCellFlagsUnion
{
  GSButtonCellFlags flags;
  uint32_t          value;
} GSButtonCellFlagsUnion;

typedef struct _GSButtonCellFlags2 {
#if GS_WORDS_BIGENDIAN == 1
  unsigned int	keyEquivalentModifierMask:24;
  unsigned int	imageScaling:2;
  unsigned int	bezelStyle2:1;
  unsigned int	mouseInside:1;
  unsigned int	showsBorderOnlyWhileMouseInside:1;
  unsigned int	bezelStyle:3;
#else
  unsigned int	bezelStyle:3;
  unsigned int	showsBorderOnlyWhileMouseInside:1;
  unsigned int	mouseInside:1;
  unsigned int	bezelStyle2:1;
  unsigned int	imageScaling:2;
  unsigned int	keyEquivalentModifierMask:24;
#endif
} GSButtonCellFlags2;

typedef union _GSButtonCellFlags2Union
{
  GSButtonCellFlags2 flags;
  uint32_t           value;
} GSButtonCellFlags2Union;

@interface NSCell (Private)
- (NSSize) _scaleImageWithSize: (NSSize)imageSize
                   toFitInSize: (NSSize)canvasSize
                   scalingType: (NSImageScaling)scalingType;
@end


@interface NSButtonCell : NSActionCell
{
  // Attributes
  NSString *_altContents;
  NSImage *_altImage;
  NSString *_keyEquivalent;
  NSFont *_keyEquivalentFont;
  NSSound *_sound;
  NSUInteger _keyEquivalentModifierMask;
  NSInteger _highlightsByMask;
  NSInteger _showAltStateMask;
  float _delayInterval;
  float _repeatInterval;
  NSBezelStyle _bezel_style;
  NSGradientType _gradient_type;
  NSColor *_backgroundColor;
  // Think of the following as a BOOL ivars
#define _buttoncell_is_transparent _cell.subclass_bool_one
#define _image_dims_when_disabled _cell.subclass_bool_two
#define _shows_border_only_while_mouse_inside _cell.subclass_bool_three
#define _mouse_inside _cell.subclass_bool_four
  NSImageScaling _imageScaling;
}

//
// Setting the Titles 
//
- (NSString *)alternateTitle;
- (void)setAlternateTitle: (NSString *)aString;
- (void)setFont: (NSFont *)fontObject;
- (void)setTitle: (NSString *)aString;
- (NSString *)title;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (NSAttributedString *)attributedAlternateTitle;
- (NSAttributedString *)attributedTitle;
- (void)setAttributedAlternateTitle: (NSAttributedString *)aString;
- (void)setAttributedTitle: (NSAttributedString *)aString;
- (void)setTitleWithMnemonic: (NSString *)aString;
- (NSString *)alternateMnemonic;
- (NSUInteger)alternateMnemonicLocation;
- (void)setAlternateMnemonicLocation: (NSUInteger)location;
- (void)setAlternateTitleWithMnemonic: (NSString *)aString;
#endif

//
// Setting the Images 
//
- (NSImage *)alternateImage;
- (NSCellImagePosition)imagePosition;
- (void)setAlternateImage: (NSImage *)anImage;
- (void)setImagePosition: (NSCellImagePosition)aPosition;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
- (NSImageScaling)imageScaling;
- (void)setImageScaling:(NSImageScaling)scaling;
#endif

//
// Setting the Repeat Interval 
//
- (void)getPeriodicDelay: (float *)delay
		interval: (float *)interval;
- (void)setPeriodicDelay: (float)delay
		interval: (float)interval;

//
// Setting the Key Equivalent 
//
- (NSString *)keyEquivalent;
- (NSFont *)keyEquivalentFont;
- (NSUInteger)keyEquivalentModifierMask;
- (void)setKeyEquivalent: (NSString *)key;
- (void)setKeyEquivalentModifierMask: (NSUInteger)mask;
- (void)setKeyEquivalentFont: (NSFont *)fontObj;
- (void)setKeyEquivalentFont: (NSString *)fontName 
			size: (float)fontSize;

//
// Modifying Graphic Attributes 
//
- (BOOL)isTransparent;
- (void)setTransparent: (BOOL)flag;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (NSBezelStyle)bezelStyle;
- (void)setBezelStyle: (NSBezelStyle)bezelStyle;
- (BOOL)showsBorderOnlyWhileMouseInside;
- (void)setShowsBorderOnlyWhileMouseInside: (BOOL)show;
- (NSGradientType)gradientType;
- (void)setGradientType: (NSGradientType)gradientType;
- (BOOL)imageDimsWhenDisabled;
- (void)setImageDimsWhenDisabled: (BOOL)flag;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (NSColor *) backgroundColor;
- (void) setBackgroundColor: (NSColor *)color;
- (void) drawBezelWithFrame: (NSRect)cellFrame inView: (NSView*)controlView;
- (void) drawImage: (NSImage*)imageToDisplay 
         withFrame: (NSRect)cellFrame 
            inView: (NSView *)controlView;
- (NSRect) drawTitle: (NSAttributedString*)titleToDisplay 
         withFrame: (NSRect)cellFrame 
            inView: (NSView *)controlView;
#endif

//
// Modifying Graphic Attributes 
//
- (NSInteger)highlightsBy;
- (void)setHighlightsBy: (NSInteger)mask;
- (void)setShowsStateBy: (NSInteger)mask;
- (void)setButtonType: (NSButtonType)buttonType;
- (NSInteger)showsStateBy;

//
// Sound
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)setSound: (NSSound *)aSound;
- (NSSound *)sound;
#endif

//
// Mouse
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)mouseEntered: (NSEvent *)event;
- (void)mouseExited: (NSEvent *)event;
#endif

@end

#endif // _GNUstep_H_NSButtonCell
