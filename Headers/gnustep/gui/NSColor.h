/* 
   NSColor.h

   The colorful color class

   Copyright (C) 1996, 1998 Free Software Foundation, Inc.

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

#ifndef _GNUstep_H_NSColor
#define _GNUstep_H_NSColor

#include <Foundation/NSCoder.h>
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSDictionary;
@class NSPasteboard;
@class NSImage;

typedef enum _NSControlTint {
    NSDefaultControlTint,
    NSClearControlTint
} NSControlTint;

/*
 * NSColor is an abstract super class of the class cluster of the real colour classes.
 * For each colour space exists a specific subclass that implements the behaviour for 
 * this colour space.
 * The colour spaces NSDeviceBlackColorSpace and NSCalibratedBlackColorSpace
 * are no longer supported by this class. They were not in the old OpenStep 
 * specification, and are not used in the new Apple specification. The names are
 * used as synonyms to NSDeviceWhiteColorSpace and NSCalibratedWhiteColorSpace.
 */

@interface NSColor : NSObject <NSCoding, NSCopying>
{
}

//
// Creating an NSColor from Component Values
//
+ (NSColor *)colorWithCalibratedHue:(float)hue
			 saturation:(float)saturation
			 brightness:(float)brightness
			      alpha:(float)alpha;
+ (NSColor *)colorWithCalibratedRed:(float)red
			      green:(float)green
			       blue:(float)blue
			      alpha:(float)alpha;
+ (NSColor *)colorWithCalibratedWhite:(float)white
				alpha:(float)alpha;
+ (NSColor *)colorWithCatalogName:(NSString *)listName
			colorName:(NSString *)colorName;
+ (NSColor *)colorWithDeviceCyan:(float)cyan
			 magenta:(float)magenta
			  yellow:(float)yellow
			   black:(float)black
			   alpha:(float)alpha;
+ (NSColor *)colorWithDeviceHue:(float)hue
		     saturation:(float)saturation
		     brightness:(float)brightness
			  alpha:(float)alpha;
+ (NSColor *)colorWithDeviceRed:(float)red
			  green:(float)green
			   blue:(float)blue
			  alpha:(float)alpha;
+ (NSColor *)colorWithDeviceWhite:(float)white
			    alpha:(float)alpha;

//
// Creating an NSColor With Preset Components
//
+ (NSColor *)blackColor;
+ (NSColor *)blueColor;
+ (NSColor *)brownColor;
+ (NSColor *)clearColor;
+ (NSColor *)cyanColor;
+ (NSColor *)darkGrayColor;
+ (NSColor *)grayColor;
+ (NSColor *)greenColor;
+ (NSColor *)lightGrayColor;
+ (NSColor *)magentaColor;
+ (NSColor *)orangeColor;
+ (NSColor *)purpleColor;
+ (NSColor *)redColor;
+ (NSColor *)whiteColor;
+ (NSColor *)yellowColor;

//
// Ignoring Alpha Components
//
+ (BOOL)ignoresAlpha;
+ (void)setIgnoresAlpha:(BOOL)flag;

//
// Retrieving a Set of Components
//
- (void)getCyan:(float *)cyan
	magenta:(float *)magenta
	 yellow:(float *)yellow
	  black:(float *)black
	  alpha:(float *)alpha;	
- (void)getHue:(float *)hue
    saturation:(float *)saturation
    brightness:(float *)brightness
	 alpha:(float *)alpha;
- (void)getRed:(float *)red
	 green:(float *)green
	  blue:(float *)blue
	 alpha:(float *)alpha;
- (void)getWhite:(float *)white
	   alpha:(float *)alpha;

//
// Retrieving Individual Components
//
- (float)alphaComponent;
- (float)blackComponent;
- (float)blueComponent;
- (float)brightnessComponent;
- (NSString *)catalogNameComponent;
- (NSString *)colorNameComponent;
- (float)cyanComponent;
- (float)greenComponent;
- (float)hueComponent;
- (NSString *)localizedCatalogNameComponent;
- (NSString *)localizedColorNameComponent;
- (float)magentaComponent;
- (float)redComponent;
- (float)saturationComponent;
- (float)whiteComponent;
- (float)yellowComponent;

//
// Converting to Another Color Space
//
- (NSString *)colorSpaceName;
- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace;
- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace
			       device:(NSDictionary *)deviceDescription;

//
// Changing the Color
//
- (NSColor *)blendedColorWithFraction:(float)fraction
			      ofColor:(NSColor *)aColor;
- (NSColor *)colorWithAlphaComponent:(float)alpha;

//
// Copying and Pasting
//
+ (NSColor *)colorFromPasteboard:(NSPasteboard *)pasteBoard;
- (void)writeToPasteboard:(NSPasteboard *)pasteBoard;

//
// Drawing
//
- (void)drawSwatchInRect:(NSRect)rect;
- (void)set;

#ifndef	STRICT_OPENSTEP
//
// Changing the color
//
- (NSColor*) highlightWithLevel: (float)level;
- (NSColor*) shadowWithLevel: (float)level;

+ (NSColor*) colorWithPatternImage:(NSImage*)image;
+ (NSColor*) colorForControlTint:(NSControlTint)controlTint;

//
// System colors stuff.
//
+ (NSColor*) controlBackgroundColor;
+ (NSColor*) controlColor;
+ (NSColor*) controlHighlightColor;
+ (NSColor*) controlLightHighlightColor;
+ (NSColor*) controlShadowColor;
+ (NSColor*) controlDarkShadowColor;
+ (NSColor*) controlTextColor;
+ (NSColor*) disabledControlTextColor;
+ (NSColor*) gridColor;
+ (NSColor*) headerColor;
+ (NSColor*) headerTextColor;
+ (NSColor*) highlightColor;
+ (NSColor*) keyboardFocusIndicatorColor;
+ (NSColor*) knobColor;
+ (NSColor*) scrollBarColor;
+ (NSColor*) selectedControlColor;
+ (NSColor*) selectedControlTextColor;
+ (NSColor*) selectedKnobColor;
+ (NSColor*) selectedMenuItemColor;
+ (NSColor*) selectedMenuItemTextColor;
+ (NSColor*) selectedTextBackgroundColor;
+ (NSColor*) selectedTextColor;
+ (NSColor*) shadowColor;
+ (NSColor*) textBackgroundColor;
+ (NSColor*) textColor;
+ (NSColor*) windowBackgroundColor;
+ (NSColor*) windowFrameColor;
+ (NSColor*) windowFrameTextColor;

// Pattern colour
- (NSImage*) patternImage;
#endif

@end

APPKIT_EXPORT NSString	*NSSystemColorsDidChangeNotification;

#ifndef	STRICT_MACOS_X
@interface NSCoder (NSCoderAdditions)

//
// Converting an Archived NXColor to an NSColor
//
- (NSColor *)decodeNXColor;

@end
#endif

#endif // _GNUstep_H_NSColor

