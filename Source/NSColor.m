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
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSView.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/PSOperators.h>

// What component should we take values from
// Bitmask - more than one component set may be valid.
#define GNUSTEP_GUI_RGB_ACTIVE 1
#define GNUSTEP_GUI_CMYK_ACTIVE 2
#define GNUSTEP_GUI_HSB_ACTIVE 4
#define GNUSTEP_GUI_WHITE_ACTIVE 8

@interface NSColor (GNUstepPrivate)

+ (NSColor*) colorFromString: (NSString*)string;
+ (void) defaultsDidChange: (NSNotification*)notification;

- (void) supportMaxColorSpaces;

// RGB component values
- (NSColor*) initWithCalibratedRed: (float)red
			     green: (float)green
			      blue: (float)blue
			     alpha: (float)alpha;
- (NSColor*) initWithDeviceRed: (float)red
			 green: (float)green
			  blue: (float)blue
			 alpha: (float)alpha;

// CMYK component values
- (NSColor*) initWithDeviceCyan: (float)cyan
			magenta: (float)magenta
			 yellow: (float)yellow
			  black: (float)black
			  alpha: (float)alpha;

// HSB component values
- (NSColor*) initWithCalibratedHue: (float)hue
			saturation: (float)saturation
			brightness: (float)brightness
			     alpha: (float)alpha;
- (NSColor*) initWithDeviceHue: (float)hue
		    saturation: (float)saturation
		    brightness: (float)brightness
			 alpha: (float)alpha;

// Grayscale
- (NSColor*) initWithCalibratedWhite: (float)white
			       alpha: (float)alpha;
- (NSColor*) initWithDeviceWhite: (float)white
			   alpha: (float)alpha;

- (NSColor*) initWithCatalogName: (NSString *)listName
		       colorName: (NSString *)colorName;

@end

// Class variables
static BOOL gnustep_gui_ignores_alpha = YES;
static NSColorList		*systemColors = nil;
static NSMutableDictionary	*colorStrings = nil;
static SEL cwkSel;
static NSColor*	(*cwkImp)(NSColorList*, SEL, NSString*);

NSColor* systemColorWithName(NSString *name)
{
  NSString *rep;
  NSColor *color = (*cwkImp)(systemColors, cwkSel, name);

  if (color != nil)
    return color;
    
  rep = [colorStrings objectForKey: name];
  if (rep == nil)
    {
      NSLog(@"Request for unknown system color - '%@'\n", name);
      return nil;
    }
  color = [NSColor colorFromString: rep];
  if (color == nil)
    {
      NSLog(@"System color '%@' has bad string rep - '%@'\n", name, rep);
      return nil;
    }
  [systemColors setColor: color forKey: name];
  return color;
}

@implementation NSColor

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSColor class])
    {
      NSString	*white;
      NSString	*lightGray;
      NSString	*gray;
      NSString	*darkGray;
      NSString	*black;

      // Set the version number
      [self setVersion: 2];

      // ignore alpha by default
      gnustep_gui_ignores_alpha = YES;

      // Set up a dictionary containing the names of all the system colors
      // as keys and with colors in string format as values.
      white = [NSString stringWithFormat: @"%f %f %f",
		NSWhite, NSWhite, NSWhite];
      lightGray = [NSString stringWithFormat: @"%f %f %f",
		NSLightGray, NSLightGray, NSLightGray];
      gray = [NSString stringWithFormat: @"%f %f %f",
		NSGray, NSGray, NSGray];
      darkGray = [NSString stringWithFormat: @"%f %f %f",
		NSDarkGray, NSDarkGray, NSDarkGray];
      black = [NSString stringWithFormat: @"%f %f %f",
		NSBlack, NSBlack, NSBlack];

      colorStrings = [[NSMutableDictionary alloc]
		initWithObjectsAndKeys: 
	lightGray, @"controlBackgroundColor", 
	lightGray, @"controlColor",
	lightGray, @"controlHighlightColor",
	white, @"controlLightHighlightColor",
	darkGray, @"controlShadowColor",
	black, @"controlDarkShadowColor",
	black, @"controlTextColor",
	darkGray, @"disabledControlTextColor",
	gray, @"gridColor",
	lightGray, @"headerColor",
	black, @"headerTextColor",
	white, @"highlightColor",
	black, @"keyboardFocusIndicatorColor",
	lightGray, @"knobColor",
	gray, @"scrollBarColor",
	white, @"selectedControlColor",
	black, @"selectedControlTextColor",
	lightGray, @"selectedKnobColor",
	white, @"selectedMenuItemColor",
	black, @"selectedMenuItemTextColor",
	lightGray, @"selectedTextBackgroundColor",
	black, @"selectedTextColor",
	black, @"shadowColor",
	white, @"textBackgroundColor",
	black, @"textColor",
	lightGray, @"windowBackgroundColor", 
	black, @"windowFrameColor",
	white, @"windowFrameTextColor",
	//gray, @"windowFrameColor",
	//black, @"windowFrameTextColor",
	nil];

      // Set up default system colors
      systemColors = [[NSColorList alloc] initWithName: @"System"];
      cwkSel = @selector(colorWithKey:);
      cwkImp = (NSColor*(*)(NSColorList*, SEL, NSString*))
	  [systemColors methodForSelector: cwkSel];

      // ensure user defaults are loaded, then use them and watch for changes.
      [NSUserDefaults standardUserDefaults];
      [self defaultsDidChange: nil];
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	   selector: @selector(defaultsDidChange:)
	       name: NSUserDefaultsDidChangeNotification
	     object: nil];
    }
}

//
// Creating an NSColor from Component Values
//
+ (NSColor*) colorWithCalibratedHue: (float)hue
			 saturation: (float)saturation
			 brightness: (float)brightness
			      alpha: (float)alpha
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithCalibratedHue: hue
						   saturation: saturation
						   brightness: brightness
						   alpha: alpha];

  return AUTORELEASE(c);
}

+ (NSColor*) colorWithCalibratedRed: (float)red
			      green: (float)green
			       blue: (float)blue
			      alpha: (float)alpha
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithCalibratedRed: red
						   green: green
						   blue: blue
						   alpha: alpha];
  return AUTORELEASE(c);
}

+ (NSColor*) colorWithCalibratedWhite: (float)white
				alpha: (float)alpha
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithCalibratedWhite: white
						   alpha: alpha];

  return AUTORELEASE(c);
}

+ (NSColor*) colorWithCatalogName: (NSString *)listName
			colorName: (NSString *)colorName
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithCatalogName: listName
						   colorName: colorName];

  return AUTORELEASE(c);
}

+ (NSColor*) colorWithDeviceCyan: (float)cyan
			 magenta: (float)magenta
			  yellow: (float)yellow
			   black: (float)black
			   alpha: (float)alpha
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithDeviceCyan: cyan
						   magenta: magenta
						   yellow: yellow
						   black: black
						   alpha: alpha];

  return AUTORELEASE(c);
}

+ (NSColor*) colorWithDeviceHue: (float)hue
		     saturation: (float)saturation
		     brightness: (float)brightness
			  alpha: (float)alpha
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithDeviceHue: hue
						   saturation: saturation
						   brightness: brightness
						   alpha: alpha];

  return AUTORELEASE(c);
}

+ (NSColor*) colorWithDeviceRed: (float)red
			  green: (float)green
			   blue: (float)blue
			  alpha: (float)alpha
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithDeviceRed: red
						   green: green
						   blue: blue
						   alpha: alpha];

  return AUTORELEASE(c);
}

+ (NSColor*) colorWithDeviceWhite: (float)white
			    alpha: (float)alpha
{
  NSColor *c;

  c = [[self allocWithZone: NSDefaultMallocZone()] initWithDeviceWhite: white
						   alpha: alpha];

  return AUTORELEASE(c);
}

+ (NSColor *)colorForControlTint:(NSControlTint)controlTint
{
  // TODO
  return nil;
}

+ (NSColor*) colorWithPatternImage:(NSImage*)image
{
  // TODO
  return nil;
}

//
// Creating an NSColor With Preset Components
//
+ (NSColor*) blackColor
{
  return [self colorWithCalibratedWhite: NSBlack alpha: 1.0];
}

+ (NSColor*) blueColor
{
  return [self colorWithCalibratedRed: 0.0
			        green: 0.0
				 blue: 1.0
			        alpha: 1.0];
}

+ (NSColor*) brownColor
{
  return [self colorWithCalibratedRed: 0.6
			        green: 0.4
				 blue: 0.2
			        alpha: 1.0];
}

+ (NSColor*) clearColor
{
  return [self colorWithCalibratedWhite: 0.0 alpha: 0.0];
}

+ (NSColor*) cyanColor
{
  return [self colorWithCalibratedRed: 0.0
			        green: 1.0
				 blue: 1.0
			        alpha: 1.0];
}

+ (NSColor*) darkGrayColor
{
  return [self colorWithCalibratedWhite: NSDarkGray alpha: 1.0];
}

+ (NSColor*) grayColor
{
  return [self colorWithCalibratedWhite: NSGray alpha: 1.0];
}

+ (NSColor*) greenColor
{
  return [self colorWithCalibratedRed: 0.0
			        green: 1.0
				 blue: 0.0
			        alpha: 1.0];
}

+ (NSColor*) lightGrayColor
{
  return [self colorWithCalibratedWhite: NSLightGray alpha: 1];
}

+ (NSColor*) magentaColor
{
  return [self colorWithCalibratedRed: 1.0
			        green: 0.0
				 blue: 1.0
			        alpha: 1.0];
}

+ (NSColor*) orangeColor;
{
  return [self colorWithCalibratedRed: 1.0
			        green: 0.5
				 blue: 0.0
			        alpha: 1.0];
}

+ (NSColor*) purpleColor;
{
  return [self colorWithCalibratedRed: 0.5
			        green: 0.0
				 blue: 0.5
			        alpha: 1.0];
}

+ (NSColor*) redColor;
{
  return [self colorWithCalibratedRed: 1.0
			        green: 0.0
				 blue: 0.0
			        alpha: 1.0];
}

+ (NSColor*) whiteColor;
{
  return [self colorWithCalibratedWhite: NSWhite alpha: 1.0];
}

+ (NSColor*) yellowColor
{
  return [self colorWithCalibratedRed: 1.0
			        green: 1.0
				 blue: 0.0
			        alpha: 1.0];
}

//
// Ignoring Alpha Components
//
+ (BOOL) ignoresAlpha
{
  return gnustep_gui_ignores_alpha;
}

+ (void) setIgnoresAlpha: (BOOL)flag
{
  gnustep_gui_ignores_alpha = flag;
}

//
// Copying and Pasting
//
+ (NSColor*) colorFromPasteboard: (NSPasteboard *)pasteBoard
{
  NSData	*d = [pasteBoard dataForType: NSColorPboardType];

  // FIXME: This should better use the description format
  if (d)
    return [NSUnarchiver unarchiveObjectWithData: d];
  return nil;
}

//
// System colors stuff.
//
+ (NSColor*) controlBackgroundColor
{
  return systemColorWithName(@"controlBackgroundColor");
}

+ (NSColor*) controlColor
{
  return systemColorWithName(@"controlColor");
}

+ (NSColor*) controlHighlightColor
{
  return systemColorWithName(@"controlHighlightColor");
}

+ (NSColor*) controlLightHighlightColor
{
  return systemColorWithName(@"controlLightHighlightColor");
}

+ (NSColor*) controlShadowColor
{
  return systemColorWithName(@"controlShadowColor");
}

+ (NSColor*) controlDarkShadowColor
{
  return systemColorWithName(@"controlDarkShadowColor");
}

+ (NSColor*) controlTextColor
{
  return systemColorWithName(@"controlTextColor");
}

+ (NSColor*) disabledControlTextColor
{
  return systemColorWithName(@"disabledControlTextColor");
}

+ (NSColor*) gridColor
{
  return systemColorWithName(@"gridColor");
}

+ (NSColor*) headerColor
{
  return systemColorWithName(@"headerColor");
}

+ (NSColor*) headerTextColor
{
  return systemColorWithName(@"headerTextColor");
}

+ (NSColor*) highlightColor
{
  return systemColorWithName(@"highlightColor");
}

+ (NSColor*) keyboardFocusIndicatorColor
{
  return systemColorWithName(@"keyboardFocusIndicatorColor");
}

+ (NSColor*) knobColor
{
  return systemColorWithName(@"knobColor");
}

+ (NSColor*) scrollBarColor
{
  return systemColorWithName(@"scrollBarColor");
}

+ (NSColor*) selectedControlColor
{
  return systemColorWithName(@"selectedControlColor");
}

+ (NSColor*) selectedControlTextColor
{
  return systemColorWithName(@"selectedControlTextColor");
}

+ (NSColor*) selectedKnobColor
{
  return systemColorWithName(@"selectedKnobColor");
}

+ (NSColor*) selectedMenuItemColor
{
  return systemColorWithName(@"selectedMenuItemColor");
}

+ (NSColor*) selectedMenuItemTextColor
{
  return systemColorWithName(@"selectedMenuItemTextColor");
}

+ (NSColor*) selectedTextBackgroundColor
{
  return systemColorWithName(@"selectedTextBackgroundColor");
}

+ (NSColor*) selectedTextColor
{
  return systemColorWithName(@"selectedTextColor");
}

+ (NSColor*) shadowColor
{
  return systemColorWithName(@"shadowColor");
}

+ (NSColor*) textBackgroundColor
{
  return systemColorWithName(@"textBackgroundColor");
}

+ (NSColor*) textColor
{
  return systemColorWithName(@"textColor");
}

+ (NSColor *)windowBackgroundColor
{
  return systemColorWithName(@"windowBackgroundColor");
}

+ (NSColor*) windowFrameColor
{
  return systemColorWithName(@"windowFrameColor");
}

+ (NSColor*) windowFrameTextColor
{
  return systemColorWithName(@"windowFrameTextColor");
}

////////////////////////////////////////////////////////////
//
// Instance methods
//

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone(self, aZone))
    {
      return RETAIN(self);
    }
  else
    {
      NSColor *aCopy = NSCopyObject(self, 0, aZone);

      aCopy->_colorspace_name = [_colorspace_name copyWithZone: aZone];
      aCopy->_catalog_name = [_catalog_name copyWithZone: aZone];
      aCopy->_color_name = [_color_name copyWithZone: aZone];
      return aCopy;
    }
}

- (NSString*) description
{
  NSMutableString	*desc;

  NSAssert(_colorspace_name != nil, NSInternalInconsistencyException);

  /*
   *	For a simple RGB color without alpha, we use a shorthand description
   *	consisting of the three componets values in a quoted string.
   */
  if ([_colorspace_name isEqualToString: NSCalibratedRGBColorSpace] &&
	_alpha_component == 1.0)
    return [NSString stringWithFormat: @"%f %f %f",
	_RGB_component.red, _RGB_component.green, _RGB_component.blue];
 
  /*
   *	For more complex color values - we encode information in a dictionary
   *	format with meaningful keys.
   */
  desc = [NSMutableString stringWithCapacity: 128];
  [desc appendFormat: @"{ ColorSpace = \"%@\";", _colorspace_name];

  if ([_colorspace_name isEqual: NSCalibratedWhiteColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", _white_component];
    }
  if ([_colorspace_name isEqual: NSCalibratedBlackColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", _white_component];
    }
  if ([_colorspace_name isEqual: NSCalibratedRGBColorSpace])
    {
      if (_active_component == GNUSTEP_GUI_HSB_ACTIVE)
	{
	  [desc appendFormat: @" H = \"%f\";", _HSB_component.hue];
	  [desc appendFormat: @" S = \"%f\";", _HSB_component.saturation];
	  [desc appendFormat: @" B = \"%f\";", _HSB_component.brightness];
	}
      else
	{
	  [desc appendFormat: @" R = \"%f\";", _RGB_component.red];
	  [desc appendFormat: @" G = \"%f\";", _RGB_component.green];
	  [desc appendFormat: @" B = \"%f\";", _RGB_component.blue];
	}
    }
  if ([_colorspace_name isEqual: NSDeviceWhiteColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", _white_component];
    }
  if ([_colorspace_name isEqual: NSDeviceBlackColorSpace])
    {
      [desc appendFormat: @" W = \"%f\";", _white_component];
    }
  if ([_colorspace_name isEqual: NSDeviceRGBColorSpace])
    {
      if (_active_component == GNUSTEP_GUI_HSB_ACTIVE)
	{
	  [desc appendFormat: @" H = \"%f\";", _HSB_component.hue];
	  [desc appendFormat: @" S = \"%f\";", _HSB_component.saturation];
	  [desc appendFormat: @" B = \"%f\";", _HSB_component.brightness];
	}
      else
	{
	  [desc appendFormat: @" R = \"%f\";", _RGB_component.red];
	  [desc appendFormat: @" G = \"%f\";", _RGB_component.green];
	  [desc appendFormat: @" B = \"%f\";", _RGB_component.blue];
	}
    }
  if ([_colorspace_name isEqual: NSDeviceCMYKColorSpace])
    {
      [desc appendFormat: @" C = \"%f\";", _CMYK_component.cyan];
      [desc appendFormat: @" M = \"%f\";", _CMYK_component.magenta];
      [desc appendFormat: @" Y = \"%f\";", _CMYK_component.yellow];
      [desc appendFormat: @" K = \"%f\";", _CMYK_component.black];
    }
  if ([_colorspace_name isEqual: NSNamedColorSpace])
    {
      [desc appendFormat: @" Catalog = \"%@\";", _catalog_name];
      [desc appendFormat: @" Color = \"%@\";", _color_name];
    }

  [desc appendFormat: @" Alpha = \"%f\"; }", _alpha_component];
  return desc;
}

//
// Retrieving a Set of Components
//
- (void) getCyan: (float*)cyan
	 magenta: (float*)magenta
	  yellow: (float*)yellow
	   black: (float*)black
	   alpha: (float*)alpha
{
  if ((_valid_components & GNUSTEP_GUI_CMYK_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not a CMYK color then you get bogus values
  if (cyan)
    *cyan = _CMYK_component.cyan;
  if (magenta)
    *magenta = _CMYK_component.magenta;
  if (yellow)
    *yellow = _CMYK_component.yellow;
  if (black)
    *black = _CMYK_component.black;
  if (alpha)
    *alpha = _alpha_component;
}

- (void) getHue: (float*)hue
     saturation: (float*)saturation
     brightness: (float*)brightness
	  alpha: (float*)alpha
{
  if ((_valid_components & GNUSTEP_GUI_HSB_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not an HSB color then you get bogus values
  if (hue)
    *hue = _HSB_component.hue;
  if (saturation)
    *saturation = _HSB_component.saturation;
  if (brightness)
    *brightness = _HSB_component.brightness;
  if (alpha)
    *alpha = _alpha_component;
}

- (void) getRed: (float*)red
	  green: (float*)green
	   blue: (float*)blue
	  alpha: (float*)alpha
{
  if ((_valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not an RGB color then you get bogus values
  if (red)
    *red = _RGB_component.red;
  if (green)
    *green = _RGB_component.green;
  if (blue)
    *blue = _RGB_component.blue;
  if (alpha)
    *alpha = _alpha_component;
}

- (void) getWhite: (float*)white
	    alpha: (float*)alpha
{
  if ((_valid_components & GNUSTEP_GUI_WHITE_ACTIVE) == 0)
    [self supportMaxColorSpaces];
  // Only set what is wanted
  // If not a grayscale color then you get bogus values
  if (white)
    *white = _white_component;
  if (alpha)
    *alpha = _alpha_component;
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    return YES;
  if ([other isKindOfClass: [NSColor class]] == NO)
    return NO;
  else
    {
      NSColor	*col = (NSColor*)other;

      if (col->_active_component != _active_component)
	return NO;
      if (col->_alpha_component != _alpha_component)
	return NO;
      switch (_active_component)
	{
	  case GNUSTEP_GUI_RGB_ACTIVE:
	    if (col->_RGB_component.red != _RGB_component.red
	      || col->_RGB_component.green != _RGB_component.green
	      || col->_RGB_component.blue != _RGB_component.blue)
	      return NO;
	    return YES;

	  case GNUSTEP_GUI_CMYK_ACTIVE:
	    if (col->_CMYK_component.cyan != _CMYK_component.cyan
	      || col->_CMYK_component.magenta != _CMYK_component.magenta
	      || col->_CMYK_component.yellow != _CMYK_component.yellow
	      || col->_CMYK_component.black != _CMYK_component.black)
	      return NO;
	    return YES;

	  case GNUSTEP_GUI_HSB_ACTIVE:
	    if (col->_HSB_component.hue != _HSB_component.hue
	      || col->_HSB_component.saturation != _HSB_component.saturation
	      || col->_HSB_component.brightness != _HSB_component.brightness)
	      return NO;
	    return YES;

	  case GNUSTEP_GUI_WHITE_ACTIVE:
	    if (col->_white_component != _white_component)
	      return NO;
	    return YES;
	}
      return NO;
    }
}

//
// Retrieving Individual Components
//
- (float) alphaComponent
{
  return _alpha_component;
}

- (float) blackComponent
{
  return _CMYK_component.black;
}

- (float) blueComponent
{
  return _RGB_component.blue;
}

- (float) brightnessComponent
{
  return _HSB_component.brightness;
}

- (NSString *) catalogNameComponent
{
  return _catalog_name;
}

- (NSString *) colorNameComponent
{
  return _color_name;
}

- (float) cyanComponent
{
  return _CMYK_component.cyan;
}

- (float) greenComponent
{
  return _RGB_component.green;
}

- (float) hueComponent
{
  return _HSB_component.hue;
}

- (NSString *) localizedCatalogNameComponent
{
  // +++ how do we localize?
  return _catalog_name;
}

- (NSString *) localizedColorNameComponent
{
  // +++ how do we localize?
  return _color_name;
}

- (float) magentaComponent
{
  return _CMYK_component.magenta;
}

- (float) redComponent
{
  return _RGB_component.red;
}

- (float) saturationComponent
{
  return _HSB_component.saturation;
}

- (float) whiteComponent
{
  return _white_component;
}

- (float) yellowComponent
{
  return _CMYK_component.yellow;
}

//
// Converting to Another Color Space
//
- (NSString *) colorSpaceName
{
  return _colorspace_name;
}

- (NSColor*) colorUsingColorSpaceName: (NSString *)colorSpace
{
  return [self colorUsingColorSpaceName: colorSpace
	       device: nil];
}

- (NSColor*) colorUsingColorSpaceName: (NSString *)colorSpace
			       device: (NSDictionary *)deviceDescription
{
  if (colorSpace == nil)
    {
      if (deviceDescription != nil)
	colorSpace = [deviceDescription objectForKey: NSDeviceColorSpaceName];
      if (colorSpace == nil)
        colorSpace = NSCalibratedRGBColorSpace;
    }
  if ([colorSpace isEqualToString: _colorspace_name])
    {
      return self;
    }

  [self supportMaxColorSpaces];

  if ([colorSpace isEqualToString: NSCalibratedRGBColorSpace])
    {
      if (_valid_components & GNUSTEP_GUI_RGB_ACTIVE)
	{
	  NSColor *aCopy = [self copy];
	  if (aCopy)
	    {
	      aCopy->_active_component = GNUSTEP_GUI_RGB_ACTIVE;
	      ASSIGN(aCopy->_colorspace_name, NSCalibratedRGBColorSpace);
	    }
	  return aCopy;
	}
    }

  if ([colorSpace isEqualToString: NSCalibratedWhiteColorSpace])
    {
      if (_valid_components & GNUSTEP_GUI_WHITE_ACTIVE)
	{
	  NSColor *aCopy = [self copy];
	  if (aCopy)
	    {
	      aCopy->_active_component = GNUSTEP_GUI_WHITE_ACTIVE;
	      ASSIGN(aCopy->_colorspace_name, NSCalibratedWhiteColorSpace);
	    }
	  return aCopy;
	}
    }

  if ([colorSpace isEqualToString: NSCalibratedBlackColorSpace])
    {
      if (_valid_components & GNUSTEP_GUI_WHITE_ACTIVE)
	{
	  NSColor *aCopy = [self copy];
	  if (aCopy)
	    {
	      aCopy->_active_component = GNUSTEP_GUI_WHITE_ACTIVE;
	      ASSIGN(aCopy->_colorspace_name, NSCalibratedBlackColorSpace);
	    }
	  return aCopy;
	}
    }

  return nil;
}

//
// Changing the Color
//
- (NSColor*) blendedColorWithFraction: (float)fraction
			      ofColor: (NSColor*)aColor
{
  NSColor *myColor = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  NSColor *other = [aColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  float mr, mg, mb, or, og, ob, red, green, blue;

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
				   alpha: 1.0];
}

- (NSColor*) colorWithAlphaComponent: (float)alpha
{
  NSColor *aCopy = NSCopyObject(self, 0, NSDefaultMallocZone());

  if (aCopy)
    {
      aCopy->_colorspace_name = [_colorspace_name copy];
      aCopy->_catalog_name = [_catalog_name copy];
      aCopy->_color_name = [_color_name copy];

      if (alpha < 0.0) alpha = 0.0;
      else if (alpha > 1.0) alpha = 1.0;
      aCopy->_alpha_component = alpha;
    }

  return aCopy;
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
- (void) writeToPasteboard: (NSPasteboard *)pasteBoard
{
  NSData *d = [NSArchiver archivedDataWithRootObject: self];

  if (d)
    [pasteBoard setData: d forType: NSColorPboardType];
}

//
// Drawing
//
- (void) drawSwatchInRect: (NSRect)rect
{
  [self set];
  NSRectFill(rect);
}

- (void) set
{
  switch (_active_component)
    {
      case GNUSTEP_GUI_RGB_ACTIVE:
	NSDebugLLog(@"NSColor", @"RGB %f %f %f\n", _RGB_component.red,
		   _RGB_component.green, _RGB_component.blue);
	PSsetrgbcolor(_RGB_component.red, _RGB_component.green, 
		      _RGB_component.blue);
	break;

      case GNUSTEP_GUI_CMYK_ACTIVE:
	NSDebugLLog(@"NSColor", @"CMYK %f %f %f %f\n", _CMYK_component.cyan, 
		   _CMYK_component.magenta,
		   _CMYK_component.yellow, _CMYK_component.black);
	PSsetcmykcolor(_CMYK_component.cyan, _CMYK_component.magenta,
		       _CMYK_component.yellow, _CMYK_component.black);
	break;

      case GNUSTEP_GUI_HSB_ACTIVE:
	NSDebugLLog(@"NSColor", @"HSB %f %f %f\n", _HSB_component.hue,
		   _HSB_component.saturation, _HSB_component.brightness);
	PSsethsbcolor(_HSB_component.hue, _HSB_component.saturation,
		      _HSB_component.brightness);
	break;

      case GNUSTEP_GUI_WHITE_ACTIVE:
	NSDebugLLog(@"NSColor", @"Gray %f\n", _white_component);
	PSsetgray(_white_component);
    }
  // Should we check the ignore flag here?
  PSsetalpha(_alpha_component);
}

//
// Destroying
//
- (void) dealloc
{
  RELEASE(_colorspace_name);
  TEST_RELEASE(_catalog_name);
  TEST_RELEASE(_color_name);
  [super dealloc];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // Hack to get old archives still working
  BOOL is_clear = (_alpha_component == 0.0);

  // Version 1
  [aCoder encodeValueOfObjCType: @encode(float) at: &_RGB_component.red];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_RGB_component.green];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_RGB_component.blue];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_alpha_component];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_clear];

  // Version 2
  [aCoder encodeObject: _colorspace_name];
  [aCoder encodeObject: _catalog_name];
  [aCoder encodeObject: _color_name];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_CMYK_component.cyan];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_CMYK_component.magenta];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_CMYK_component.yellow];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_CMYK_component.black];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_HSB_component.hue];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_HSB_component.saturation];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_HSB_component.brightness];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_white_component];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_active_component];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_valid_components];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  NSString *s;
  // Hack to get old archives still working
  BOOL is_clear;

  // Version 1
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_RGB_component.red];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_RGB_component.green];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_RGB_component.blue];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_alpha_component];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_clear];

  // Get our class name
  s = NSStringFromClass(isa);

  // Version 2
  // +++ Coding cannot return class version yet
  //  if ([aDecoder versionForClassName: s] > 1)
    {
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_colorspace_name];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_catalog_name];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_color_name];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_CMYK_component.cyan];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_CMYK_component.magenta];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_CMYK_component.yellow];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_CMYK_component.black];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_HSB_component.hue];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_HSB_component.saturation];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_HSB_component.brightness];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_white_component];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_active_component];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_valid_components];
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
  if ([str hasPrefix: @"{"])
    {
      NSDictionary	*dict;
      NSString		*space;
      float		alpha;

      dict = [str propertyList];
      if (dict == nil)
	return nil;
      if ((space = [dict objectForKey: @"ColorSpace"]) == nil)
	return nil;

      str = [dict objectForKey: @"Alpha"];
      if (str == nil || [str isEqualToString: @""])
	{
	  alpha = 1.0;
	}
      else
	{
	  alpha = [str floatValue];
	}

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
    }
  else if (str != nil)
    {
      const char	*ptr = [str cString];
      float		r, g, b;

      if (sscanf(ptr, "%f %f %f", &r, &g, &b) == 3)
	{
	  return [self colorWithCalibratedRed: r
					green: g
					 blue: b
					alpha: 1.0];
	}
    }
  return nil;
}

/*
 *	Go through all the names of system colors - for each color where
 *	there is a value in the defaults database, see if the current
 *	istring value of the color differs from the old one.
 *	Where there is a difference, update the color strings dictionary 
 *	and, where a color object exists, update the system colors list
 *	to contain the new color.
 *	Finally, issue a notification if appropriate.
 */
+ (void) defaultsDidChange: (NSNotification*)notification
{
  NSUserDefaults	*defs;
  NSEnumerator		*enumerator;
  NSString		*key;
  BOOL			didChange = NO;

  defs = [NSUserDefaults standardUserDefaults];

  enumerator = [colorStrings keyEnumerator];
  while ((key = [enumerator nextObject]) != nil)
    {
      NSString	*def = [defs stringForKey: key];

      if (def != nil)
	{
	  NSString	*old = [colorStrings objectForKey: key];

	  if ([def isEqualToString: old] == NO)
	    {
	      NSColor *color;

	      didChange = YES;
	      [colorStrings setObject: def forKey: key];
	      color = [systemColors colorWithKey: key];
	      if (color != nil)
		{
		  color = [NSColor colorFromString: def];
		  if (color == nil)
		    {
		      NSLog(@"System color '%@' has bad string rep - '%@'\n",
				key, def);
		    }
		  else
		    {
		      [systemColors setColor: color forKey: key];
		    }
		}
	    }
	}
    }
  if (didChange)
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: NSSystemColorsDidChangeNotification object: nil];
    }
}

/*
 *	Conversion algorithms taken from ghostscript.
 */
- (void) supportMaxColorSpaces
{
  /*
   *	CMYK to RGB if required.
   */
  if (_valid_components & GNUSTEP_GUI_CMYK_ACTIVE)
    {
      if ((_valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  if (_CMYK_component.black == 0)
	    {
	      _RGB_component.red = 1 - _CMYK_component.cyan;
	      _RGB_component.green = 1 - _CMYK_component.magenta;
	      _RGB_component.blue = 1 - _CMYK_component.yellow;
	    }
	  else if (_CMYK_component.black == 1)
	    {
	      _RGB_component.red = 0;
	      _RGB_component.green = 0;
	      _RGB_component.blue = 0;
	    }
	  else
	    {
	      double	c = _CMYK_component.cyan;
	      double	m = _CMYK_component.magenta;
	      double	y = _CMYK_component.yellow;
	      double	white = 1 - _CMYK_component.black;

	      _RGB_component.red = (c > white ? 0 : white - c);
	      _RGB_component.green = (m > white ? 0 : white - m);
	      _RGB_component.blue = (y > white ? 0 : white - y);
	    }
	  _valid_components |= GNUSTEP_GUI_RGB_ACTIVE;
	}
    }

  /*
   *	HSB to RGB if required
   */
  if (_valid_components & GNUSTEP_GUI_HSB_ACTIVE)
    {
      if ((_valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  if (_HSB_component.saturation == 0)
	    {
	      _RGB_component.red = _HSB_component.brightness;
	      _RGB_component.green = _HSB_component.brightness;
	      _RGB_component.blue = _HSB_component.brightness;
	    }
	  else
	    {
	      double	h6 = _HSB_component.hue * 6;
	      double	V = _HSB_component.brightness;
	      double	S = _HSB_component.saturation;
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
	      _RGB_component.red = (float)R;
	      _RGB_component.green = (float)G;
	      _RGB_component.blue = (float)B;
	    }
	  _valid_components |= GNUSTEP_GUI_RGB_ACTIVE;
	}
    }

  /*
   *	White to RGB if required.
   */
  if (_valid_components & GNUSTEP_GUI_WHITE_ACTIVE)
    {
      if ((_valid_components & GNUSTEP_GUI_RGB_ACTIVE) == 0)
	{
	  _RGB_component.red = _white_component;
	  _RGB_component.green = _white_component;
	  _RGB_component.blue = _white_component;
	  _valid_components |= GNUSTEP_GUI_RGB_ACTIVE;
	}
    }

  if (_valid_components & GNUSTEP_GUI_RGB_ACTIVE)
    {
      /*
       *	RGB to HSB if required.
       */
      if ((_valid_components & GNUSTEP_GUI_HSB_ACTIVE) == 0)
	{
	  float	r = _RGB_component.red;
	  float	g = _RGB_component.green;
	  float	b = _RGB_component.blue;

	  if (r == g && r == b)
	    {
	      _HSB_component.hue = 0;
	      _HSB_component.saturation = 0;
	      _HSB_component.brightness = r;
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
	      _HSB_component.hue = H/6;
	      _HSB_component.saturation = diff/V;
	      _HSB_component.brightness = V;
	    }
	  _valid_components |= GNUSTEP_GUI_HSB_ACTIVE;
	}

      /*
       *	RGB to white if required.
       */
      if ((_valid_components & GNUSTEP_GUI_WHITE_ACTIVE) == 0)
	{
	  _white_component = (_RGB_component.red + _RGB_component.green + _RGB_component.blue)/3;
	  _valid_components |= GNUSTEP_GUI_WHITE_ACTIVE;
	}
    }
}

// RGB component values
- (NSColor*) initWithCalibratedRed: (float)red
			     green: (float)green
			      blue: (float)blue
			     alpha: (float)alpha
{
  if (red < 0.0) red = 0.0;
  else if (red > 1.0) red = 1.0;
  _RGB_component.red = red;

  if (green < 0.0) green = 0.0;
  else if (green > 1.0) green = 1.0;
  _RGB_component.green = green;

  if (blue < 0.0) blue = 0.0;
  else if (blue > 1.0) blue = 1.0;
  _RGB_component.blue = blue;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  ASSIGN(_colorspace_name, NSCalibratedRGBColorSpace);
  _active_component = GNUSTEP_GUI_RGB_ACTIVE;
  _valid_components = GNUSTEP_GUI_RGB_ACTIVE;

  return self;
}

- (NSColor*) initWithDeviceRed: (float)red
			 green: (float)green
			  blue: (float)blue
			 alpha: (float)alpha
{
  if (red < 0.0) red = 0.0;
  else if (red > 1.0) red = 1.0;
  _RGB_component.red = red;

  if (green < 0.0) green = 0.0;
  else if (green > 1.0) green = 1.0;
  _RGB_component.green = green;

  if (blue < 0.0) blue = 0.0;
  else if (blue > 1.0) blue = 1.0;
  _RGB_component.blue = blue;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  ASSIGN(_colorspace_name, NSDeviceRGBColorSpace);
  _active_component = GNUSTEP_GUI_RGB_ACTIVE;
  _valid_components = GNUSTEP_GUI_RGB_ACTIVE;

  return self;
}

// CMYK component values
- (NSColor*) initWithDeviceCyan: (float)cyan
			magenta: (float)magenta
			 yellow: (float)yellow
			  black: (float)black
			  alpha: (float)alpha
{
  if (cyan < 0.0) cyan = 0.0;
  else if (cyan > 1.0) cyan = 1.0;
  _CMYK_component.cyan = cyan;

  if (magenta < 0.0) magenta = 0.0;
  else if (magenta > 1.0) magenta = 1.0;
  _CMYK_component.magenta = magenta;

  if (yellow < 0.0) yellow = 0.0;
  else if (yellow > 1.0) yellow = 1.0;
  _CMYK_component.yellow = yellow;

  if (black < 0.0) black = 0.0;
  else if (black > 1.0) black = 1.0;
  _CMYK_component.black = black;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  ASSIGN(_colorspace_name, NSDeviceCMYKColorSpace);
  _active_component = GNUSTEP_GUI_CMYK_ACTIVE;
  _valid_components = GNUSTEP_GUI_CMYK_ACTIVE;

  return self;
}

// HSB component values
- (NSColor*) initWithCalibratedHue: (float)hue
			saturation: (float)saturation
			brightness: (float)brightness
			     alpha: (float)alpha;
{
  if (hue < 0.0) hue = 0.0;
  else if (hue > 1.0) hue = 1.0;
  _HSB_component.hue = hue;

  if (saturation < 0.0) saturation = 0.0;
  else if (saturation > 1.0) saturation = 1.0;
  _HSB_component.saturation = saturation;

  if (brightness < 0.0) brightness = 0.0;
  else if (brightness > 1.0) brightness = 1.0;
  _HSB_component.brightness = brightness;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  ASSIGN(_colorspace_name, NSCalibratedRGBColorSpace);
  _active_component = GNUSTEP_GUI_HSB_ACTIVE;
  _valid_components = GNUSTEP_GUI_HSB_ACTIVE;

  return self;
}

- (NSColor*) initWithDeviceHue: (float)hue
		    saturation: (float)saturation
		    brightness: (float)brightness
			 alpha: (float)alpha;
{
  if (hue < 0.0) hue = 0.0;
  else if (hue > 1.0) hue = 1.0;
  _HSB_component.hue = hue;

  if (saturation < 0.0) saturation = 0.0;
  else if (saturation > 1.0) saturation = 1.0;
  _HSB_component.saturation = saturation;

  if (brightness < 0.0) brightness = 0.0;
  else if (brightness > 1.0) brightness = 1.0;
  _HSB_component.brightness = brightness;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  ASSIGN(_colorspace_name, NSDeviceRGBColorSpace);
  _active_component = GNUSTEP_GUI_HSB_ACTIVE;
  _valid_components = GNUSTEP_GUI_HSB_ACTIVE;

  return self;
}

// Grayscale
- (NSColor*) initWithCalibratedWhite: (float)white
			       alpha: (float)alpha
{
  if (white < 0.0) white = 0.0;
  else if (white > 1.0) white = 1.0;
  _white_component = white;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  ASSIGN(_colorspace_name, NSCalibratedWhiteColorSpace);
  _active_component = GNUSTEP_GUI_WHITE_ACTIVE;
  _valid_components = GNUSTEP_GUI_WHITE_ACTIVE;

  return self;
}

- (NSColor*) initWithDeviceWhite: (float)white
			   alpha: (float)alpha
{
  if (white < 0.0) white = 0.0;
  else if (white > 1.0) white = 1.0;
  _white_component = white;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  ASSIGN(_colorspace_name, NSDeviceWhiteColorSpace);
  _active_component = GNUSTEP_GUI_WHITE_ACTIVE;
  _valid_components = GNUSTEP_GUI_WHITE_ACTIVE;

  return self;
}

- (NSColor*) initWithCatalogName: (NSString *)listName
		       colorName: (NSString *)colorName
{
  ASSIGN(_catalog_name, listName);
  ASSIGN(_color_name, colorName);

  ASSIGN(_colorspace_name, NSNamedColorSpace);
  _active_component = 0;
  _valid_components = 0;

  return self;
}

@end

//
// Implementation of the NSCoder additions
//
@implementation NSCoder (NSCoderAdditions)

//
// Converting an Archived NXColor to an NSColor
//
- (NSColor*) decodeNXColor
{
  return nil;
}

@end
