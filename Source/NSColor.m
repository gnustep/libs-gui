/* 
   NSColor.m

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSColor.h>
#include <gnustep/gui/NSView.h>

// Global strings
NSString *NSCalibratedWhiteColorSpace; 
NSString *NSCalibratedBlackColorSpace; 
NSString *NSCalibratedRGBColorSpace;
NSString *NSDeviceWhiteColorSpace;
NSString *NSDeviceBlackColorSpace;
NSString *NSDeviceRGBColorSpace;
NSString *NSDeviceCMYKColorSpace;
NSString *NSNamedColorSpace;
NSString *NSCustomColorSpace;

// Global gray values
const float NSBlack = 0;
const float NSDarkGray = .502;
const float NSWhite = 1;
const float NSLightGray = .753;

@implementation NSColor

////////////////////////////////////////////////////////////
//
// Internal methods
//
- (void)setRed:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  RGB_component.red = value;
}

- (void)setGreen:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  RGB_component.green = value;
}

- (void)setBlue:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  RGB_component.blue = value;
}

- (void)setClear:(BOOL)flag
{
  is_clear = flag;
}

////////////////////////////////////////////////////////////
//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColor class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSColor from Component Values
//
+ (NSColor *)colorWithCalibratedHue:(float)hue
			 saturation:(float)saturation
			 brightness:(float)brightness
			      alpha:(float)alpha
{
  return nil;
}

+ (NSColor *)colorWithCalibratedRed:(float)red
			      green:(float)green
			       blue:(float)blue
			      alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setRed:red];
  [c setGreen:green];
  [c setBlue:blue];
  [c setClear:NO];
  return c;
}

+ (NSColor *)colorWithCalibratedWhite:(float)white
				alpha:(float)alpha
{
  return nil;
}

+ (NSColor *)colorWithCatalogName:(NSString *)listName
			colorName:(NSString *)colorName
{
  return nil;
}

+ (NSColor *)colorWithDeviceCyan:(float)cyan
			 magenta:(float)magenta
			  yellow:(float)yellow
			   black:(float)black
			   alpha:(float)alpha
{
  return nil;
}

+ (NSColor *)colorWithDeviceHue:(float)hue
		     saturation:(float)saturation
		     brightness:(float)brightness
			  alpha:(float)alpha
{
  return nil;
}

+ (NSColor *)colorWithDeviceRed:(float)red
			  green:(float)green
			   blue:(float)blue
			  alpha:(float)alpha
{
  return self;
}

+ (NSColor *)colorWithDeviceWhite:(float)white
			    alpha:(float)alpha
{
  return nil;
}

//
// Creating an NSColor With Preset Components
//
+ (NSColor *)blackColor
{
  return [self colorWithCalibratedRed:0
	       green:0
	       blue:0
	       alpha:1];
}

+ (NSColor *)blueColor
{
  return [self colorWithCalibratedRed:0
	       green:0
	       blue:1.0
	       alpha:1];
}

+ (NSColor *)brownColor
{
  return [self colorWithCalibratedRed:0.6
	       green:0.4
	       blue:0.2
	       alpha:1];
}

+ (NSColor *)clearColor
{
  NSColor *c;
  c = [self colorWithCalibratedRed:0
	    green:1.0
	    blue:1.0
	    alpha:1];
  [c setClear:YES];
  return c;
}

+ (NSColor *)cyanColor
{
  return [self colorWithCalibratedRed:0
	       green:1.0
	       blue:1.0
	       alpha:1];
}

+ (NSColor *)darkGrayColor
{
  return [self colorWithCalibratedRed:0.502
	       green:0.502
	       blue:0.502
	       alpha:1];
}

+ (NSColor *)grayColor
{
  return [self colorWithCalibratedRed:0.753
	       green:0.753
	       blue:0.753
	       alpha:1];
}

+ (NSColor *)greenColor
{
  return [self colorWithCalibratedRed:0
	       green:1.0
	       blue:0
	       alpha:1];
}

+ (NSColor *)lightGrayColor
{
  return [self colorWithCalibratedRed:0.9
	       green:0.9
	       blue:0.9
	       alpha:1];
}

+ (NSColor *)magentaColor
{
  return [self colorWithCalibratedRed:1.0
	       green:0
	       blue:1.0
	       alpha:1];
}

+ (NSColor *)orangeColor;
{
  return [self colorWithCalibratedRed:1.0
	       green:0.5
	       blue:0
	       alpha:1];
}

+ (NSColor *)purpleColor;
{
  return [self colorWithCalibratedRed:0.5
	       green:0
	       blue:0.5
	       alpha:1];
}

+ (NSColor *)redColor;
{
  return [self colorWithCalibratedRed:1.0
	       green:0
	       blue:0
	       alpha:1];
}

+ (NSColor *)whiteColor;
{
  return [self colorWithCalibratedRed:1.0
	       green:1.0
	       blue:1.0
	       alpha:1];
}

+ (NSColor *)yellowColor
{
  return [self colorWithCalibratedRed:1.0
	       green:1.0
	       blue:0
	       alpha:1];
}

//
// Ignoring Alpha Components
//
+ (BOOL)ignoresAlpha
{
  return YES;
}

+ (void)setIgnoresAlpha:(BOOL)flag
{}

//
// Copying and Pasting
//
+ (NSColor *)colorFromPasteboard:(NSPasteboard *)pasteBoard
{
  return nil;
}

////////////////////////////////////////////////////////////
//
// Instance methods
//
//
// Retrieving a Set of Components
//
- (void)getCyan:(float *)cyan
	magenta:(float *)magenta
	 yellow:(float *)yellow
	black:(float *)black
	  alpha:(float *)alpha
{}

- (void)getHue:(float *)hue
    saturation:(float *)saturation
    brightness:(float *)brightness
	 alpha:(float *)alpha
{}

- (void)getRed:(float *)red
	 green:(float *)green
	  blue:(float *)blue
	 alpha:(float *)alpha
{}

- (void)getWhite:(float *)white
	   alpha:(float *)alpha
{}

//
// Retrieving Individual Components
//
- (float)alphaComponent
{
  return alpha_component;
}

- (float)blackComponent
{
  return 0;
}

- (float)blueComponent
{
  return RGB_component.blue;
}

- (float)brightnessComponent
{
  return 0;
}

- (NSString *)catalogNameComponent
{
  return nil;
}

- (NSString *)colorNameComponent
{
  return nil;
}

- (float)cyanComponent
{
  return 0;
}

- (float)greenComponent
{
  return RGB_component.green;
}

- (float)hueComponent
{
  return 0;
}

- (NSString *)localizedCatalogNameComponent
{
  return nil;
}

- (NSString *)localizedColorNameComponent
{
  return nil;
}

- (float)magentaComponent
{
  return 0;
}

- (float)redComponent
{
  return RGB_component.red;
}

- (float)saturationComponent
{
  return 0;
}

- (float)whiteComponent
{
  return 0;
}

- (float)yellowComponent
{
  return 0;
}

//
// Converting to Another Color Space
//
- (NSString *)colorSpaceName
{
  return nil;
}

- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace
{
  return nil;
}

- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace
			       device:(NSDictionary *)deviceDescription
{
  return nil;
}

//
// Changing the Color
//
- (NSColor *)blendedColorWithFraction:(float)fraction
			      ofColor:(NSColor *)aColor
{
  return nil;
}

- (NSColor *)colorWithAlphaComponent:(float)alpha
{
  return nil;
}

//
// Copying and Pasting
//
- (void)writeToPasteboard:(NSPasteboard *)pasteBoard
{}

//
// Drawing
//
- (void)drawSwatchInRect:(NSRect)rect
{}

- (void)set
{
}

//
// Destroying
//
- (void)dealloc
{
  [super dealloc];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.red];
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.green];
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.blue];
  [aCoder encodeValueOfObjCType: "f" at: &alpha_component];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_clear];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.red];
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.green];
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.blue];
  [aDecoder decodeValueOfObjCType: "f" at: &alpha_component];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_clear];

  return self;
}

@end
