/* 
   NSColor.h

   The colorful color class

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

#ifndef _GNUstep_H_NSColor
#define _GNUstep_H_NSColor

#include <Foundation/NSCoder.h>

@class NSString;
@class NSDictionary;

@class NSPasteboard;

// What component should we take values from
#define GNUSTEP_GUI_RGB_ACTIVE 1
#define GNUSTEP_GUI_CMYK_ACTIVE 2
#define GNUSTEP_GUI_HSB_ACTIVE 3
#define GNUSTEP_GUI_WHITE_ACTIVE 4

enum {
  NSGrayModeColorPanel,
  NSRGBModeColorPanel,
  NSCMYKModeColorPanel,
  NSHSBModeColorPanel,
  NSCustomPaletteModeColorPanel,
  NSColorListModeColorPanel,
  NSWheelModeColorPanel 
};

enum {
  NSColorPanelGrayModeMask,
  NSColorPanelRGBModeMask,
  NSColorPanelCMYKModeMask,
  NSColorPanelHSBModeMask,
  NSColorPanelCustomPaletteModeMask,
  NSColorPanelColorListModeMask,
  NSColorPanelWheelModeMask,
  NSColorPanelAllModesMask  
};

@interface NSColor : NSObject <NSCoding>
{
  // Attributes
  NSString *colorspace_name;
  NSString *catalog_name;
  NSString *color_name;

  struct _GNU_RGB_component
  {
    float red;
    float green;
    float blue;
  } RGB_component;

  struct _GNU_CMYK_component
  {
    float cyan;
    float magenta;
    float yellow;
    float black;
  } CMYK_component;

  struct _GNU_HSB_component
  {
    float hue;
    float saturation;
    float brightness;
  } HSB_component;

  float white_component;

  int active_component;
  float alpha_component;

  BOOL is_clear;

  // Reserved for back-end use
  void *be_color_reserved;
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

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

@interface NSCoder (NSCoderAdditions)

//
// Converting an Archived NXColor to an NSColor
//
- (NSColor *)decodeNXColor;

@end

#endif // _GNUstep_H_NSColor

