/* 
   NSColor.m

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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSColor.h>
#include <AppKit/NSColorList.h>
#include <AppKit/NSColorPrivate.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSView.h>
#include <AppKit/NSGraphics.h>

@implementation NSColor

// Class variables
static BOOL gnustep_gui_ignores_alpha = YES;
static NSColorList	*systemColors = nil;

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColor class])
    {
      // Set the version number
      [self setVersion:2];

      // ignore alpha by default
      gnustep_gui_ignores_alpha = YES;

      // Set up default system colors
      systemColors = [[NSColorList alloc] initWithName: @"System"];
      [self defaultSystemColors];

      // ensure user defaults are loaded, then use them and watch for changes.
      [NSUserDefaults standardUserDefaults];
      [self defaultsDidChange: nil];
//     [NSNotificationCenter addObserver: self
//			       selector: @selector(defaultsDidChange:)
//				   name: NSUserDefaultsDidChangeNotification
//				 object: nil];
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
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSCalibratedRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_HSB_ACTIVE];
  [c setHue: hue];
  [c setSaturation: saturation];
  [c setBrightness: brightness];
  [c setAlpha: alpha];
  [c setValidComponents: GNUSTEP_GUI_HSB_ACTIVE];

  return c;
}

+ (NSColor *)colorWithCalibratedRed:(float)red
			      green:(float)green
			       blue:(float)blue
			      alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSCalibratedRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_RGB_ACTIVE];
  [c setRed: red];
  [c setGreen: green];
  [c setBlue: blue];
  [c setAlpha: alpha];
  [c setValidComponents: GNUSTEP_GUI_RGB_ACTIVE];

  return c;
}

+ (NSColor *)colorWithCalibratedWhite:(float)white
				alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSCalibratedWhiteColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_WHITE_ACTIVE];
  [c setWhite: white];
  [c setAlpha: alpha];
  [c setValidComponents: GNUSTEP_GUI_WHITE_ACTIVE];

  return c;
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
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceCMYKColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_CMYK_ACTIVE];
  [c setCyan: cyan];
  [c setMagenta: magenta];
  [c setYellow: yellow];
  [c setBlack: black];
  [c setAlpha: alpha];
  [c setValidComponents: GNUSTEP_GUI_CMYK_ACTIVE];

  return c;
}

+ (NSColor *)colorWithDeviceHue:(float)hue
		     saturation:(float)saturation
		     brightness:(float)brightness
			  alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_HSB_ACTIVE];
  [c setHue: hue];
  [c setSaturation: saturation];
  [c setBrightness: brightness];
  [c setAlpha: alpha];
  [c setValidComponents: GNUSTEP_GUI_HSB_ACTIVE];

  return c;
}

+ (NSColor *)colorWithDeviceRed:(float)red
			  green:(float)green
			   blue:(float)blue
			  alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_RGB_ACTIVE];
  [c setRed: red];
  [c setGreen: green];
  [c setBlue: blue];
  [c setAlpha: alpha];
  [c setValidComponents: GNUSTEP_GUI_RGB_ACTIVE];

  return c;
}

+ (NSColor *)colorWithDeviceWhite:(float)white
			    alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceWhiteColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_WHITE_ACTIVE];
  [c setWhite: white];
  [c setAlpha: alpha];
  [c setValidComponents: GNUSTEP_GUI_WHITE_ACTIVE];

  return c;
}

//
// Creating an NSColor With Preset Components
//
+ (NSColor *)blackColor
{
  return [self colorWithCalibratedWhite: NSBlack alpha: 1.0];
}

+ (NSColor *)blueColor
{
  return [self colorWithCalibratedRed:0
	       green:0
	       blue:1.0
	       alpha:1.0];
}

+ (NSColor *)brownColor
{
  return [self colorWithCalibratedRed:0.6
	       green:0.4
	       blue:0.2
	       alpha:1.0];
}

+ (NSColor *)clearColor
{
  NSColor *c;
  c = [self colorWithCalibratedRed:0
	    green:1.0
	    blue:1.0
	    alpha:1.0];
  [c setClear:YES];
  return c;
}

+ (NSColor *)cyanColor
{
  return [self colorWithCalibratedRed:0
	       green:1.0
	       blue:1.0
	       alpha:1.0];
}

+ (NSColor *)darkGrayColor
{
  return [self colorWithCalibratedWhite: NSDarkGray alpha: 1.0];
}

+ (NSColor *)grayColor
{
  return [self colorWithCalibratedWhite: NSGray alpha: 1.0];
}

+ (NSColor *)greenColor
{
  return [self colorWithCalibratedRed:0
	       green:1.0
	       blue:0
	       alpha:1.0];
}

+ (NSColor *)lightGrayColor
{
  return [self colorWithCalibratedWhite: NSLightGray alpha: 1];
}

+ (NSColor *)magentaColor
{
  return [self colorWithCalibratedRed:1.0
	       green:0
	       blue:1.0
	       alpha:1.0];
}

+ (NSColor *)orangeColor;
{
  return [self colorWithCalibratedRed:1.0
	       green:0.5
	       blue:0
	       alpha:1.0];
}

+ (NSColor *)purpleColor;
{
  return [self colorWithCalibratedRed:0.5
	       green:0
	       blue:0.5
	       alpha:1.0];
}

+ (NSColor *)redColor;
{
  return [self colorWithCalibratedRed:1.0
	       green:0
	       blue:0
	       alpha:1.0];
}

+ (NSColor *)whiteColor;
{
  return [self colorWithCalibratedWhite: NSWhite alpha: 1.0];
}

+ (NSColor *)yellowColor
{
  return [self colorWithCalibratedRed:1.0
	       green:1.0
	       blue:0
	       alpha:1.0];
}

//
// Ignoring Alpha Components
//
+ (BOOL)ignoresAlpha
{
  return gnustep_gui_ignores_alpha;
}

+ (void)setIgnoresAlpha:(BOOL)flag
{
  gnustep_gui_ignores_alpha = flag;
}

//
// Copying and Pasting
//
+ (NSColor *)colorFromPasteboard:(NSPasteboard *)pasteBoard
{
  NSData	*d = [pasteBoard dataForType: NSColorPboardType];

  if (d)
    return [NSUnarchiver unarchiveObjectWithData: d];
  return nil;
}

//
// System colors stuff.
//
+ (NSColor*) controlBackgroundColor
{
  return [systemColors colorWithKey: @"controlBackgroundColor"];
}

+ (NSColor*) controlColor
{
  return [systemColors colorWithKey: @"controlColor"];
}

+ (NSColor*) controlHighlightColor
{
  return [systemColors colorWithKey: @"controlHighlightColor"];
}

+ (NSColor*) controlLightHighlightColor
{
  return [systemColors colorWithKey: @"controlLightHighlightColor"];
}

+ (NSColor*) controlShadowColor
{
  return [systemColors colorWithKey: @"controlShadowColor"];
}

+ (NSColor*) controlDarkShadowColor
{
  return [systemColors colorWithKey: @"controlDarkShadowColor"];
}

+ (NSColor*) controlTextColor
{
  return [systemColors colorWithKey: @"controlTextColor"];
}

+ (NSColor*) disabledControlTextColor
{
  return [systemColors colorWithKey: @"disabledControlTextColor"];
}

+ (NSColor*) gridColor
{
  return [systemColors colorWithKey: @"gridColor"];
}

+ (NSColor*) highlightColor
{
  return [systemColors colorWithKey: @"highlightColor"];
}

+ (NSColor*) knobColor
{
  return [systemColors colorWithKey: @"knobColor"];
}

+ (NSColor*) scrollBarColor
{
  return [systemColors colorWithKey: @"scrollBarColor"];
}

+ (NSColor*) selectedControlColor
{
  return [systemColors colorWithKey: @"selectedControlColor"];
}

+ (NSColor*) selectedControlTextColor
{
  return [systemColors colorWithKey: @"selectedControlTextColor"];
}

+ (NSColor*) selectedMenuItemColor
{
  return [systemColors colorWithKey: @"selectedMenuItemColor"];
}

+ (NSColor*) selectedMenuItemTextColor
{
  return [systemColors colorWithKey: @"selectedMenuItemTextColor"];
}

+ (NSColor*) selectedTextBackgroundColor
{
  return [systemColors colorWithKey: @"selectedTextBackgroundColor"];
}

+ (NSColor*) selectedTextColor
{
//  return [systemColors colorWithKey: @"selectedTextColor"];		// FIX ME
	return [self colorWithCalibratedRed:.12 green:.12 blue:0 alpha:1.0];
}

+ (NSColor*) selectedKnobColor
{
  return [systemColors colorWithKey: @"selectedKnobColor"];
}

+ (NSColor*) shadowColor
{
  return [systemColors colorWithKey: @"shadowColor"];
}

+ (NSColor*) textBackgroundColor
{
  return [systemColors colorWithKey: @"textBackgroundColor"];
}

+ (NSColor*) textColor
{
  return [systemColors colorWithKey: @"textColor"];
}

+ (NSColor*) windowFrameColor
{
  return [systemColors colorWithKey: @"windowFrameColor"];
}

+ (NSColor*) windowFrameTextColor
{
  return [systemColors colorWithKey: @"windowFrameTextColor"];
}

////////////////////////////////////////////////////////////
//
// Instance methods
//
- init
{
  [super init];

  colorspace_name = @"";
  catalog_name = @"";
  color_name = @"";
  return self;
}

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone(self, aZone))
    {
      return [self retain];
    }
  else
    {
      NSColor	*aCopy = NSCopyObject(self, 0, aZone);

      aCopy->colorspace_name = [colorspace_name copyWithZone: aZone];
      aCopy->catalog_name = [catalog_name copyWithZone: aZone];
      aCopy->color_name = [color_name copyWithZone: aZone];
      return aCopy;
    }
}

- (NSString*) description
{
  NSMutableString	*desc;

  NSAssert(colorspace_name != nil, NSInternalInconsistencyException);

  /*
   *	For a simple RGB color without alpha, we use a shorthand description
   *	consisting of the three componets values in a quoted string.
   */
  if ([colorspace_name isEqualToString: NSCalibratedRGBColorSpace] &&
	alpha_component == 0)
    return [NSString stringWithFormat: @"\"%f %f %f\"",
	RGB_component.red, RGB_component.green, RGB_component.blue];
 
  /*
   *	For more complex color values - we encode information in a dictionary
   *	format with meaningful keys.
   */
  desc = [NSMutableString stringWithCapacity: 128];
  [desc appendFormat: @"{ ColorSpace = \"%@\";", colorspace_name];

  if ([colorspace_name isEqual: NSCalibratedWhiteColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", white_component];
    }
  if ([colorspace_name isEqual: NSCalibratedBlackColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", white_component];
    }
  if ([colorspace_name isEqual: NSCalibratedRGBColorSpace])
    {
      if (active_component == GNUSTEP_GUI_HSB_ACTIVE)
	{
	  [desc appendFormat: @" H = \"%f\";", HSB_component.hue];
	  [desc appendFormat: @" S = \"%f\";", HSB_component.saturation];
	  [desc appendFormat: @" B = \"%f\";", HSB_component.brightness];
	}
      else
	{
	  [desc appendFormat: @" R = \"%f\";", RGB_component.red];
	  [desc appendFormat: @" G = \"%f\";", RGB_component.green];
	  [desc appendFormat: @" B = \"%f\";", RGB_component.blue];
	}
    }
  if ([colorspace_name isEqual: NSDeviceWhiteColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", white_component];
    }
  if ([colorspace_name isEqual: NSDeviceBlackColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", white_component];
    }
  if ([colorspace_name isEqual: NSDeviceRGBColorSpace])
    {
      if (active_component == GNUSTEP_GUI_HSB_ACTIVE)
	{
	  [desc appendFormat: @" H = \"%f\";", HSB_component.hue];
	  [desc appendFormat: @" S = \"%f\";", HSB_component.saturation];
	  [desc appendFormat: @" B = \"%f\";", HSB_component.brightness];
	}
      else
	{
	  [desc appendFormat: @" R = \"%f\";", RGB_component.red];
	  [desc appendFormat: @" G = \"%f\";", RGB_component.green];
	  [desc appendFormat: @" B = \"%f\";", RGB_component.blue];
	}
    }
  if ([colorspace_name isEqual: NSDeviceCMYKColorSpace])
    {
      [desc appendFormat: @" C = \"%f\";", CMYK_component.cyan];
      [desc appendFormat: @" M = \"%f\";", CMYK_component.magenta];
      [desc appendFormat: @" Y = \"%f\";", CMYK_component.yellow];
      [desc appendFormat: @" K = \"%f\";", CMYK_component.black];
    }
  if ([colorspace_name isEqual: NSNamedColorSpace])
    {
      [desc appendFormat: @" Catalog = \"%@\";", catalog_name];
      [desc appendFormat: @" Color = \"%@\";", color_name];
    }

  [desc appendFormat: @" Alpha = \"%f\"; }", alpha_component];
  return desc;
}

//
// Retrieving a Set of Components
//
- (void)getCyan:(float *)cyan
	magenta:(float *)magenta
	 yellow:(float *)yellow
	  black:(float *)black
	  alpha:(float *)alpha
{
  if ((valid_components & GNUSTEP_GUI_CMYK_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not a CMYK color then you get bogus values
  if (cyan)
    *cyan = CMYK_component.cyan;
  if (magenta)
    *magenta = CMYK_component.magenta;
  if (yellow)
    *yellow = CMYK_component.yellow;
  if (black)
    *black = CMYK_component.black;
  if (alpha)
    *alpha = alpha_component;
}

- (void)getHue:(float *)hue
    saturation:(float *)saturation
    brightness:(float *)brightness
	 alpha:(float *)alpha
{
  if ((valid_components & GNUSTEP_GUI_HSB_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not an HSB color then you get bogus values
  if (hue)
    *hue = HSB_component.hue;
  if (saturation)
    *saturation = HSB_component.saturation;
  if (brightness)
    *brightness = HSB_component.brightness;
  if (alpha)
    *alpha = alpha_component;
}

- (void)getRed:(float *)red
	 green:(float *)green
	  blue:(float *)blue
	 alpha:(float *)alpha
{
  if ((valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not an RGB color then you get bogus values
  if (red)
    *red = RGB_component.red;
  if (green)
    *green = RGB_component.green;
  if (blue)
    *blue = RGB_component.blue;
  if (alpha)
    *alpha = alpha_component;
}

- (void)getWhite:(float *)white
	   alpha:(float *)alpha
{
  if ((valid_components & GNUSTEP_GUI_WHITE_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not a grayscale color then you get bogus values
  if (white)
    *white = white_component;
  if (alpha)
    *alpha = alpha_component;
}

//
// Retrieving Individual Components
//
- (float)alphaComponent
{
  return alpha_component;
}

- (float)blackComponent
{
  return CMYK_component.black;
}

- (float)blueComponent
{
  return RGB_component.blue;
}

- (float)brightnessComponent
{
  return HSB_component.brightness;
}

- (NSString *)catalogNameComponent
{
  return catalog_name;
}

- (NSString *)colorNameComponent
{
  return color_name;
}

- (float)cyanComponent
{
  return CMYK_component.cyan;
}

- (float)greenComponent
{
  return RGB_component.green;
}

- (float)hueComponent
{
  return HSB_component.hue;
}

- (NSString *)localizedCatalogNameComponent
{
  // +++ how do we localize?
  return catalog_name;
}

- (NSString *)localizedColorNameComponent
{
  // +++ how do we localize?
  return color_name;
}

- (float)magentaComponent
{
  return CMYK_component.magenta;
}

- (float)redComponent
{
  return RGB_component.red;
}

- (float)saturationComponent
{
  return HSB_component.saturation;
}

- (float)whiteComponent
{
  return white_component;
}

- (float)yellowComponent
{
  return CMYK_component.yellow;
}

//
// Converting to Another Color Space
//
- (NSString *)colorSpaceName
{
  return colorspace_name;
}

- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace
{
  if (colorSpace == nil)
    {
      colorSpace = NSCalibratedRGBColorSpace;
    }
  if ([colorSpace isEqualToString: colorspace_name])
    {
      return self;
    }

  [self supportMaxColorSpaces];

  if ([colorSpace isEqualToString: NSCalibratedRGBColorSpace])
    {
      if (valid_components & GNUSTEP_GUI_RGB_ACTIVE)
	{
	  NSColor	*aCopy = [self copy];
	  if (aCopy)
	    {
	      aCopy->active_component = GNUSTEP_GUI_RGB_ACTIVE;
	      [aCopy setColorSpaceName: NSCalibratedRGBColorSpace];
	    }
	  return aCopy;
	}
    }

  if ([colorSpace isEqualToString: NSCalibratedWhiteColorSpace])
    {
      if (valid_components & GNUSTEP_GUI_WHITE_ACTIVE)
	{
	  NSColor	*aCopy = [self copy];
	  if (aCopy)
	    {
	      aCopy->active_component = GNUSTEP_GUI_WHITE_ACTIVE;
	      [aCopy setColorSpaceName: NSCalibratedWhiteColorSpace];
	    }
	  return aCopy;
	}
    }

  if ([colorSpace isEqualToString: NSCalibratedBlackColorSpace])
    {
      if (valid_components & GNUSTEP_GUI_WHITE_ACTIVE)
	{
	  NSColor	*aCopy = [self copy];
	  if (aCopy)
	    {
	      aCopy->active_component = GNUSTEP_GUI_WHITE_ACTIVE;
	      [aCopy setColorSpaceName: NSCalibratedBlackColorSpace];
	    }
	  return aCopy;
	}
    }

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
  NSColor	*myColor = self;
  NSColor	*other = aColor;
  float		mr, mg, mb, or, og, ob, red, green, blue;

  if ((valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
    {
      [self supportMaxColorSpaces];
      if ((valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  myColor = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	}
    }
  if ((aColor->valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
    {
      [aColor supportMaxColorSpaces];
      if ((aColor->valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  other = [aColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	}
    }

  if (myColor == nil || other == nil)
    {
      return nil;
    }
  [myColor getRed: &mr green: &mg blue: &mb alpha: 0];
  [other getRed: &or green: &og blue: &ob alpha: 0];
  red = fraction * mr + (1 - fraction) * or;
  green = fraction * mg + (1 - fraction) * og;
  blue = fraction * mb + (1 - fraction) * ob;
  return [NSColor colorWithCalibratedRed: red
				   green: green
				    blue: blue
				   alpha: 0];
}

- (NSColor *)colorWithAlphaComponent:(float)alpha
{
  [self setAlpha: alpha];
  return self;
}

- (NSColor*) highlightWithLevel: (float)level
{
  return [self blendedColorWithFraction: level
			        ofColor: [NSColor highlightColor]];
}

- (NSColor*) shadowWithLevel: (float)level
{
  return [self blendedColorWithFraction: level
			        ofColor: [NSColor shadowColor]];
}

//
// Copying and Pasting
//
- (void)writeToPasteboard:(NSPasteboard *)pasteBoard
{
  NSData	*d = [NSArchiver archivedDataWithRootObject: self];

  if (d)
    [pasteBoard setData: d forType: NSColorPboardType];
}

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
  [colorspace_name release];
  [catalog_name release];
  [color_name release];
  [super dealloc];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  // Version 1
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.red];
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.green];
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.blue];
  [aCoder encodeValueOfObjCType: "f" at: &alpha_component];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_clear];

  // Version 2
  [aCoder encodeObject: colorspace_name];
  [aCoder encodeObject: catalog_name];
  [aCoder encodeObject: color_name];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.cyan];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.magenta];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.yellow];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.black];
  [aCoder encodeValueOfObjCType: "f" at: &HSB_component.hue];
  [aCoder encodeValueOfObjCType: "f" at: &HSB_component.saturation];
  [aCoder encodeValueOfObjCType: "f" at: &HSB_component.brightness];
  [aCoder encodeValueOfObjCType: "f" at: &white_component];
  [aCoder encodeValueOfObjCType: @encode(int) at: &active_component];
  [aCoder encodeValueOfObjCType: @encode(int) at: &valid_components];
}

- initWithCoder:aDecoder
{
  NSString *s;

  // Version 1
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.red];
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.green];
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.blue];
  [aDecoder decodeValueOfObjCType: "f" at: &alpha_component];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_clear];

  // Get our class name
  s = NSStringFromClass(isa);

  // Version 2
  // +++ Coding cannot return class version yet
  //  if ([aDecoder versionForClassName: s] > 1)
    {
      colorspace_name = [aDecoder decodeObject];
      catalog_name = [aDecoder decodeObject];
      color_name = [aDecoder decodeObject];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.cyan];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.magenta];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.yellow];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.black];
      [aDecoder decodeValueOfObjCType: "f" at: &HSB_component.hue];
      [aDecoder decodeValueOfObjCType: "f" at: &HSB_component.saturation];
      [aDecoder decodeValueOfObjCType: "f" at: &HSB_component.brightness];
      [aDecoder decodeValueOfObjCType: "f" at: &white_component];
      [aDecoder decodeValueOfObjCType: "i" at: &active_component];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &active_component];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &valid_components];
    }

  return self;
}

@end

//
// Private methods
//
@implementation NSColor (GNUstepPrivate)

+ (NSColor*) colorFromString: (NSString*)str
{
  id		plist = [str propertyList];
  NSDictionary	*dict;
  NSString	*space;
  float		alpha;

  if (plist == nil)
    return nil;

  if ([plist isKindOfClass: [NSString class]] == YES)
    {
      const char	*str = [(NSString*)plist cString];
      float	r, g, b;

      sscanf(str, "%f %f %f", &r, &g, &b);
      return [self colorWithCalibratedRed: r
				    green: g
				     blue: b
				    alpha: 0];
    }

  if ([plist isKindOfClass: [NSDictionary class]] == NO)
    return nil;

  dict = (NSDictionary*)plist;
  if ((space = [dict objectForKey: @"ColorSpace"]) == nil)
    return nil;

  alpha = [[dict objectForKey: @"Alpha"] floatValue];

  if ([space isEqual: NSCalibratedWhiteColorSpace])
    {
      float	white = [[dict objectForKey: @"W"] floatValue];

      return [self colorWithCalibratedWhite: white alpha: alpha];
    }
  if ([space isEqual: NSCalibratedBlackColorSpace])
    {
      float	white = [[dict objectForKey: @"W"] floatValue];

      return [self colorWithCalibratedWhite: white
				      alpha: alpha];
    }
  if ([space isEqual: NSCalibratedRGBColorSpace])
    {
      if ([dict objectForKey: @"H"] != nil)
	{
	  float	hue = [[dict objectForKey: @"H"] floatValue];
	  float	saturation = [[dict objectForKey: @"S"] floatValue];
	  float	brightness = [[dict objectForKey: @"B"] floatValue];

	  return [self colorWithCalibratedHue: hue
				   saturation: saturation
				   brightness: brightness
					alpha: alpha];
	}
      else
	{
	  float	red = [[dict objectForKey: @"R"] floatValue];
	  float	green = [[dict objectForKey: @"G"] floatValue];
	  float	blue = [[dict objectForKey: @"B"] floatValue];

	  return [self colorWithCalibratedRed: red
				        green: green
					 blue: blue
					alpha: alpha];
	}
    }
  if ([space isEqual: NSDeviceCMYKColorSpace])
    {
      float	cyan = [[dict objectForKey: @"C"] floatValue];
      float	magenta = [[dict objectForKey: @"M"] floatValue];
      float	yellow = [[dict objectForKey: @"Y"] floatValue];
      float	black = [[dict objectForKey: @"B"] floatValue];

      return [self colorWithDeviceCyan: cyan
			       magenta: magenta
				yellow: yellow
				 black: black
				 alpha: alpha];
    }
  if ([space isEqual: NSNamedColorSpace])
    {
      NSString	*cat = [dict objectForKey: @"Catalog"];
      NSString	*col = [dict objectForKey: @"Color"];

      return [self colorWithCatalogName: cat
			      colorName: col];
    }

  return nil;
}

+ (void) defaultSystemColors
{
  NSColor	*color;

  color = [self lightGrayColor];
  [systemColors setColor: color forKey: @"controlBackgroundColor"];

  color = [self lightGrayColor];
  [systemColors setColor: color forKey: @"controlColor"];

  color = [self lightGrayColor];
  [systemColors setColor: color forKey: @"controlHighlightColor"];

  color = [self whiteColor];
  [systemColors setColor: color forKey: @"controlLightHighlightColor"];

  color = [self darkGrayColor];
  [systemColors setColor: color forKey: @"controlShadowColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"controlDarkShadowColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"controlTextColor"];

  color = [self darkGrayColor];
  [systemColors setColor: color forKey: @"disabledControlTextColor"];

  color = [self grayColor];
  [systemColors setColor: color forKey: @"gridColor"];

  color = [self whiteColor];
  [systemColors setColor: color forKey: @"highlightColor"];

  color = [self lightGrayColor];
  [systemColors setColor: color forKey: @"knobColor"];

  color = [self lightGrayColor];
  [systemColors setColor: color forKey: @"scrollBarColor"];

  color = [self whiteColor];
  [systemColors setColor: color forKey: @"selectedControlColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"selectedControlTextColor"];

  color = [self whiteColor];
  [systemColors setColor: color forKey: @"selectedMenuItemColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"selectedMenuItemTextColor"];

  color = [self lightGrayColor];
  [systemColors setColor: color forKey: @"selectedTextBackgroundColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"selectedTextColor"];

  color = [self lightGrayColor];
  [systemColors setColor: color forKey: @"selectedKnobColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"shadowColor"];

  color = [self whiteColor];
  [systemColors setColor: color forKey: @"textBackgroundColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"textColor"];

  color = [self blackColor];
  [systemColors setColor: color forKey: @"windowFrameColor"];

  color = [self whiteColor];
  [systemColors setColor: color forKey: @"windowFrameTextColor"];
}

+ (void) defaultsDidChange: (NSNotification*)notification
{
  static NSString	*controlBackgroundColor = nil;
  static NSString	*controlColor = nil;
  static NSString	*controlHighlightColor = nil;
  static NSString	*controlLightHighlightColor = nil;
  static NSString	*controlShadowColor = nil;
  static NSString	*controlDarkShadowColor = nil;
  static NSString	*controlTextColor = nil;
  static NSString	*disabledControlTextColor = nil;
  static NSString	*gridColor = nil;
  static NSString	*highlightColor = nil;
  static NSString	*knobColor = nil;
  static NSString	*scrollBarColor = nil;
  static NSString	*selectedControlColor = nil;
  static NSString	*selectedControlTextColor = nil;
  static NSString	*selectedMenuItemColor = nil;
  static NSString	*selectedMenuItemTextColor = nil;
  static NSString	*selectedTextBackgroundColor = nil;
  static NSString	*selectedTextColor = nil;
  static NSString	*selectedKnobColor = nil;
  static NSString	*shadowColor = nil;
  static NSString	*textBackgroundColor = nil;
  static NSString	*textColor = nil;
  static NSString	*windowFrameColor = nil;
  static NSString	*windowFrameTextColor = nil;
  NSUserDefaults	*defs;
  NSString		*str;
  NSColor		*color;

  defs = [NSUserDefaults standardUserDefaults];

  str = [defs stringForKey: @"controlBackgroundColor"];
  if (str != nil && (controlBackgroundColor == nil || [controlBackgroundColor isEqualToString: str] == NO))
    {
      [controlBackgroundColor release];
      controlBackgroundColor = [str retain];
      color = [self colorFromString: controlBackgroundColor];
      [systemColors setColor: color forKey: @"controlBackgroundColor"];
    }

  str = [defs stringForKey: @"controlColor"];
  if (str != nil && (controlColor == nil || [controlColor isEqualToString: str] == NO))
    {
      [controlColor release];
      controlColor = [str retain];
      color = [self colorFromString: controlColor];
      [systemColors setColor: color forKey: @"controlColor"];
    }

  str = [defs stringForKey: @"controlHighlightColor"];
  if (str != nil && (controlHighlightColor == nil || [controlHighlightColor isEqualToString: str] == NO))
    {
      [controlHighlightColor release];
      controlHighlightColor = [str retain];
      color = [self colorFromString: controlHighlightColor];
      [systemColors setColor: color forKey: @"controlHighlightColor"];
    }

  str = [defs stringForKey: @"controlLightHighlightColor"];
  if (str != nil && (controlLightHighlightColor == nil || [controlLightHighlightColor isEqualToString: str] == NO))
    {
      [controlLightHighlightColor release];
      controlLightHighlightColor = [str retain];
      color = [self colorFromString: controlLightHighlightColor];
      [systemColors setColor: color forKey: @"controlLightHighlightColor"];
    }

  str = [defs stringForKey: @"controlShadowColor"];
  if (str != nil && (controlShadowColor == nil || [controlShadowColor isEqualToString: str] == NO))
    {
      [controlShadowColor release];
      controlShadowColor = [str retain];
      color = [self colorFromString: controlShadowColor];
      [systemColors setColor: color forKey: @"controlShadowColor"];
    }

  str = [defs stringForKey: @"controlDarkShadowColor"];
  if (str != nil && (controlDarkShadowColor == nil || [controlDarkShadowColor isEqualToString: str] == NO))
    {
      [controlDarkShadowColor release];
      controlDarkShadowColor = [str retain];
      color = [self colorFromString: controlDarkShadowColor];
      [systemColors setColor: color forKey: @"controlDarkShadowColor"];
    }

  str = [defs stringForKey: @"controlTextColor"];
  if (str != nil && (controlTextColor == nil || [controlTextColor isEqualToString: str] == NO))
    {
      [controlTextColor release];
      controlTextColor = [str retain];
      color = [self colorFromString: controlTextColor];
      [systemColors setColor: color forKey: @"controlTextColor"];
    }

  str = [defs stringForKey: @"disabledControlTextColor"];
  if (str != nil && (disabledControlTextColor == nil || [disabledControlTextColor isEqualToString: str] == NO))
    {
      [disabledControlTextColor release];
      disabledControlTextColor = [str retain];
      color = [self colorFromString: disabledControlTextColor];
      [systemColors setColor: color forKey: @"disabledControlTextColor"];
    }

  str = [defs stringForKey: @"gridColor"];
  if (str != nil && (gridColor == nil || [gridColor isEqualToString: str] == NO))
    {
      [gridColor release];
      gridColor = [str retain];
      color = [self colorFromString: gridColor];
      [systemColors setColor: color forKey: @"gridColor"];
    }

  str = [defs stringForKey: @"highlightColor"];
  if (str != nil && (highlightColor == nil || [highlightColor isEqualToString: str] == NO))
    {
      [highlightColor release];
      highlightColor = [str retain];
      color = [self colorFromString: highlightColor];
      [systemColors setColor: color forKey: @"highlightColor"];
    }

  str = [defs stringForKey: @"knobColor"];
  if (str != nil && (knobColor == nil || [knobColor isEqualToString: str] == NO))
    {
      [knobColor release];
      knobColor = [str retain];
      color = [self colorFromString: knobColor];
      [systemColors setColor: color forKey: @"knobColor"];
    }

  str = [defs stringForKey: @"scrollBarColor"];
  if (str != nil && (scrollBarColor == nil || [scrollBarColor isEqualToString: str] == NO))
    {
      [scrollBarColor release];
      scrollBarColor = [str retain];
      color = [self colorFromString: scrollBarColor];
      [systemColors setColor: color forKey: @"scrollBarColor"];
    }

  str = [defs stringForKey: @"selectedControlColor"];
  if (str != nil && (selectedControlColor == nil || [selectedControlColor isEqualToString: str] == NO))
    {
      [selectedControlColor release];
      selectedControlColor = [str retain];
      color = [self colorFromString: selectedControlColor];
      [systemColors setColor: color forKey: @"selectedControlColor"];
    }

  str = [defs stringForKey: @"selectedControlTextColor"];
  if (str != nil && (selectedControlTextColor == nil || [selectedControlTextColor isEqualToString: str] == NO))
    {
      [selectedControlTextColor release];
      selectedControlTextColor = [str retain];
      color = [self colorFromString: selectedControlTextColor];
      [systemColors setColor: color forKey: @"selectedControlTextColor"];
    }

  str = [defs stringForKey: @"selectedMenuItemColor"];
  if (str != nil && (selectedMenuItemColor == nil || [selectedMenuItemColor isEqualToString: str] == NO))
    {
      [selectedMenuItemColor release];
      selectedMenuItemColor = [str retain];
      color = [self colorFromString: selectedMenuItemColor];
      [systemColors setColor: color forKey: @"selectedMenuItemColor"];
    }

  str = [defs stringForKey: @"selectedMenuItemTextColor"];
  if (str != nil && (selectedMenuItemTextColor == nil || [selectedMenuItemTextColor isEqualToString: str] == NO))
    {
      [selectedMenuItemTextColor release];
      selectedMenuItemTextColor = [str retain];
      color = [self colorFromString: selectedMenuItemTextColor];
      [systemColors setColor: color forKey: @"selectedMenuItemTextColor"];
    }

  str = [defs stringForKey: @"selectedTextBackgroundColor"];
  if (str != nil && (selectedTextBackgroundColor == nil || [selectedTextBackgroundColor isEqualToString: str] == NO))
    {
      [selectedTextBackgroundColor release];
      selectedTextBackgroundColor = [str retain];
      color = [self colorFromString: selectedTextBackgroundColor];
      [systemColors setColor: color forKey: @"selectedTextBackgroundColor"];
    }

  str = [defs stringForKey: @"selectedTextColor"];
  if (str != nil && (selectedTextColor == nil || [selectedTextColor isEqualToString: str] == NO))
    {
      [selectedTextColor release];
      selectedTextColor = [str retain];
      color = [self colorFromString: selectedTextColor];
      [systemColors setColor: color forKey: @"selectedTextColor"];
    }

  str = [defs stringForKey: @"selectedKnobColor"];
  if (str != nil && (selectedKnobColor == nil || [selectedKnobColor isEqualToString: str] == NO))
    {
      [selectedKnobColor release];
      selectedKnobColor = [str retain];
      color = [self colorFromString: selectedKnobColor];
      [systemColors setColor: color forKey: @"selectedKnobColor"];
    }

  str = [defs stringForKey: @"shadowColor"];
  if (str != nil && (shadowColor == nil || [shadowColor isEqualToString: str] == NO))
    {
      [shadowColor release];
      shadowColor = [str retain];
      color = [self colorFromString: shadowColor];
      [systemColors setColor: color forKey: @"shadowColor"];
    }

  str = [defs stringForKey: @"textBackgroundColor"];
  if (str != nil && (textBackgroundColor == nil || [textBackgroundColor isEqualToString: str] == NO))
    {
      [textBackgroundColor release];
      textBackgroundColor = [str retain];
      color = [self colorFromString: textBackgroundColor];
      [systemColors setColor: color forKey: @"textBackgroundColor"];
    }

  str = [defs stringForKey: @"textColor"];
  if (str != nil && (textColor == nil || [textColor isEqualToString: str] == NO))
    {
      [textColor release];
      textColor = [str retain];
      color = [self colorFromString: textColor];
      [systemColors setColor: color forKey: @"textColor"];
    }

  str = [defs stringForKey: @"windowFrameColor"];
  if (str != nil && (windowFrameColor == nil || [windowFrameColor isEqualToString: str] == NO))
    {
      [windowFrameColor release];
      windowFrameColor = [str retain];
      color = [self colorFromString: windowFrameColor];
      [systemColors setColor: color forKey: @"windowFrameColor"];
    }

  str = [defs stringForKey: @"windowFrameTextColor"];
  if (str != nil && (windowFrameTextColor == nil || [windowFrameTextColor isEqualToString: str] == NO))
    {
      [windowFrameTextColor release];
      windowFrameTextColor = [str retain];
      color = [self colorFromString: windowFrameTextColor];
      [systemColors setColor: color forKey: @"windowFrameTextColor"];
    }
}

- (void)setColorSpaceName:(NSString *)str
{
  ASSIGN(colorspace_name, str);
}

/*
 *	Conversion algorithms taken from ghostscript.
 */
- (void) supportMaxColorSpaces
{
  /*
   *	CMYK to RGB if required.
   */
  if (valid_components & GNUSTEP_GUI_CMYK_ACTIVE)
    {
      if ((valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  if (CMYK_component.black == 0)
	    {
	      RGB_component.red = 1 - CMYK_component.cyan;
	      RGB_component.green = 1 - CMYK_component.magenta;
	      RGB_component.blue = 1 - CMYK_component.yellow;
	    }
	  else if (CMYK_component.black == 1)
	    {
	      RGB_component.red = 0;
	      RGB_component.green = 0;
	      RGB_component.blue = 0;
	    }
	  else
	    {
	      double	c = CMYK_component.cyan;
	      double	m = CMYK_component.magenta;
	      double	y = CMYK_component.yellow;
	      double	white = 1 - CMYK_component.black;

	      RGB_component.red = (c > white ? 0 : white - c);
	      RGB_component.green = (m > white ? 0 : white - m);
	      RGB_component.blue = (y > white ? 0 : white - y);
	    }
	  valid_components |= GNUSTEP_GUI_RGB_ACTIVE;
	}
    }

  /*
   *	HSB to RGB if required
   */
  if (valid_components & GNUSTEP_GUI_HSB_ACTIVE)
    {
      if ((valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  if (HSB_component.saturation == 0)
	    {
	      RGB_component.red = HSB_component.brightness;
	      RGB_component.green = HSB_component.brightness;
	      RGB_component.blue = HSB_component.brightness;
	    }
	  else
	    {
	      double	h6 = HSB_component.hue * 6;
	      double	V = HSB_component.brightness;
	      double	S = HSB_component.saturation;
	      int	I = (int)h6;
	      double	F = h6 - I;
	      double	M = V * (1 - S);
	      double	N = V * (1 - S * F);
	      double	K = M - N + V;
	      double	R, G, B;

	      switch (I)
		{
		  default: R = V; G = K; B = M; break;
		  case 1: R = N; G = V; B = M; break;
		  case 2: R = M; G = V; B = K; break;
		  case 3: R = M; G = N; B = V; break;
		  case 4: R = K; G = M; B = V; break;
		  case 5: R = V; G = M; B = N; break;
		}
	      RGB_component.red = (float)R;
	      RGB_component.green = (float)G;
	      RGB_component.blue = (float)B;
	    }
	  valid_components |= GNUSTEP_GUI_RGB_ACTIVE;
	}
    }

  /*
   *	White to RGB if required.
   */
  if (valid_components & GNUSTEP_GUI_WHITE_ACTIVE)
    {
      if ((valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  RGB_component.red = white_component;
	  RGB_component.green = white_component;
	  RGB_component.blue = white_component;
	  valid_components |= GNUSTEP_GUI_RGB_ACTIVE;
	}
    }

  if (valid_components & GNUSTEP_GUI_RGB_ACTIVE)
    {
      /*
       *	RGB to HSB if required.
       */
      if ((valid_components & GNUSTEP_GUI_HSB_ACTIVE) == 0)
	{
	  float	r = RGB_component.red;
	  float	g = RGB_component.green;
	  float	b = RGB_component.blue;

	  if (r == g && r == b)
	    {
	      HSB_component.hue = 0;
	      HSB_component.saturation = 0;
	      HSB_component.brightness = r;
	    }
	  else
	    {
	      double	H;
	      double	V;
	      double	Temp;
	      double	diff;

	      V = (r > g ? r : g);
	      V = (b > V ? b : V);
	      Temp = (r > g ? r : g);
	      Temp = (b < Temp ? b : Temp);
	      diff = V - Temp;
	      if (V == r)
		{
		  H = (g - b)/diff;
		}
	      else if (V == g)
		{
		  H = (b - r)/diff + 2;
		}
	      else
		{
		  H = (r - g)/diff + 4;
		}
	      if (H < 0)
		{
		  H += 6;
		}
	      HSB_component.hue = H/6;
	      HSB_component.saturation = diff/V;
	      HSB_component.brightness = V;
	    }
	  valid_components |= GNUSTEP_GUI_HSB_ACTIVE;
	}

      /*
       *	RGB to white if required.
       */
      if ((valid_components & GNUSTEP_GUI_WHITE_ACTIVE) == 0)
	{
	  white_component = (RGB_component.red + RGB_component.green + RGB_component.blue)/3;
	  valid_components |= GNUSTEP_GUI_WHITE_ACTIVE;
	}
    }
}

- (void)setCatalogName:(NSString *)str
{
  ASSIGN(catalog_name, str);
}

- (void)setColorName:(NSString *)str
{
  ASSIGN(color_name, str);
}

// RGB component values

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

// CMYK component values
- (void)setCyan:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.cyan = value;
}

- (void)setMagenta:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.magenta = value;
}

- (void)setYellow:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.yellow = value;
}

- (void)setBlack:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.black = value;
}

// HSB component values
- (void)setHue:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  HSB_component.hue = value;
}

- (void)setSaturation:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  HSB_component.saturation = value;
}

- (void)setBrightness:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  HSB_component.brightness = value;
}

// Grayscale
- (void)setWhite:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  white_component = value;
}

- (void)setAlpha:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  alpha_component = value;
}

- (void)setActiveComponent:(int)value
{
  active_component = value;
}

- (void)setClear:(BOOL)flag
{
  is_clear = flag;
}

- (void)setValidComponents:(int)value
{
  valid_components = value;
}

@end

//
// Implementation of the NSCoder additions
//
@implementation NSCoder (NSCoderAdditions)

//
// Converting an Archived NXColor to an NSColor
//
- (NSColor *)decodeNXColor
{
  return nil;
}

@end
