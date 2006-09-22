/** <title>NSColor</title>

   <abstract>The colorful color class</abstract>

   Copyright (C) 1996, 1998, 2001, 2002 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: 2001, 2002

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "config.h"
#include <Foundation/NSString.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSScanner.h>

#include "AppKit/NSColor.h"
#include "AppKit/NSColorList.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSView.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/PSOperators.h"
#include "GNUstepGUI/GSTheme.h"

static Class	NSColorClass;

/* This interface must be provided in NSColorList to let us manage
 * system colors.
 */
@interface NSColorList (GNUstepPrivate)
+ (void) _setDefaultSystemColorList: (NSColorList*)aList;
+ (void) _setThemeSystemColorList: (NSColorList*)aList;
@end


@interface GSNamedColor : NSColor
{
  NSString *_catalog_name;
  NSString *_color_name;
  NSString *_cached_name_space;
  NSColor *_cached_color;
}

- (NSColor*) initWithCatalogName: (NSString *)listName
		       colorName: (NSString *)colorName;
- (void) recache;

@end

@interface GSWhiteColor : NSColor
{
  float _white_component;
  float _alpha_component;
}

@end

@interface GSDeviceWhiteColor : GSWhiteColor

- (NSColor*) initWithDeviceWhite: (float)white
			   alpha: (float)alpha;

@end

@interface GSCalibratedWhiteColor : GSWhiteColor

- (NSColor*) initWithCalibratedWhite: (float)white
			       alpha: (float)alpha;

@end

@interface GSDeviceCMYKColor : NSColor
{
  float _cyan_component;
  float _magenta_component;
  float _yellow_component;
  float _black_component;
  float _alpha_component;
}

- (NSColor*) initWithDeviceCyan: (float)cyan
			magenta: (float)magenta
			 yellow: (float)yellow
			  black: (float)black
			  alpha: (float)alpha;

@end

@interface GSRGBColor : NSColor
{
  float _red_component;
  float _green_component;
  float _blue_component;
  float _hue_component;
  float _saturation_component;
  float _brightness_component;
  float _alpha_component;
}

@end

@interface GSDeviceRGBColor : GSRGBColor

- (NSColor*) initWithDeviceRed: (float)red
			 green: (float)green
			  blue: (float)blue
			 alpha: (float)alpha;
- (NSColor*) initWithDeviceHue: (float)hue
		    saturation: (float)saturation
		    brightness: (float)brightness
			 alpha: (float)alpha;

@end

@interface GSCalibratedRGBColor : GSRGBColor

- (NSColor*) initWithCalibratedRed: (float)red
			     green: (float)green
			      blue: (float)blue
			     alpha: (float)alpha;
- (NSColor*) initWithCalibratedHue: (float)hue
			saturation: (float)saturation
			brightness: (float)brightness
			     alpha: (float)alpha;
@end

// FIXME: This is not described in the specification
@interface GSPatternColor : NSColor
{
  NSImage *_pattern;
}

- (NSColor*) initWithPatternImage: (NSImage*) pattern;

@end

@interface NSColor (GNUstepPrivate)

+ (NSColor*) colorFromString: (NSString*)string;
+ (void) defaultsDidChange: (NSNotification*)notification;
+ (void) themeDidActivate: (NSNotification*)notification;

@end

// Class variables
static BOOL gnustep_gui_ignores_alpha = YES;
static NSColorList		*systemColors = nil;
static NSColorList		*defaultSystemColors = nil;
static NSMutableDictionary	*colorStrings = nil;
static NSMutableDictionary	*systemDict = nil;

static
void initSystemColors(void)
{
  NSString *white;
  NSString *lightGray;
  NSString *gray;
  NSString *darkGray;
  NSString *black;
  
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
		     black, @"alternateSelectedControlColor",
		     white, @"alternateSelectedControlTextColor",
		     white, @"rowBackgroundColor",
		     lightGray, @"alternateRowBackgroundColor",
		     lightGray, @"secondarySelectedControlColor",
		     //gray, @"windowFrameColor",
		     //black, @"windowFrameTextColor",
		     nil];
  
  systemColors = [NSColorList colorListNamed: @"System"];
  defaultSystemColors = [[NSColorList alloc] initWithName: @"System"];
  [NSColorList _setDefaultSystemColorList: defaultSystemColors];
  if (systemColors == nil)
    {
      ASSIGN(systemColors, defaultSystemColors);
    }

    {
      NSEnumerator *enumerator;
      NSString *key;
      BOOL changed = NO;

      // Set up default system colors

      enumerator = [colorStrings keyEnumerator];
  
      while ((key = (NSString *)[enumerator nextObject])) 
	{
	  NSColor *color;

	  if ((color = [systemColors colorWithKey: key]) == nil)
	    {
	      NSString	*aColorString;

	      aColorString = [colorStrings objectForKey: key];
	      color = [NSColorClass colorFromString: aColorString];

	      NSCAssert1(color, @"couldn't get default system color %@", key);
	      [systemColors setColor: color forKey: key];
	      changed = YES;
	    }
	  if (defaultSystemColors != systemColors)
	    {
	      [defaultSystemColors setColor: color forKey: key];
	    }
	}
    }

  systemDict = [NSMutableDictionary new];
}

static NSColor*
systemColorWithName(NSString *name)
{
  NSColor* col = [systemDict objectForKey: name];

  if (col == nil)
    {
      col = [NSColor colorWithCatalogName: @"System"
		     colorName: name];
      [systemDict setObject: col forKey: name];
    }

  return col;
}

/**
 *<p>TODO NSColor description</p>
 *
 */
@implementation NSColor

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSColor class])
    {
      NSColorClass = self;

      // Set the version number
      [self setVersion: 3];

      // ignore alpha by default
      gnustep_gui_ignores_alpha = YES;

      // Load or define the system colour list
      initSystemColors();

      // ensure user defaults are loaded, then use them and watch for changes.
      [self defaultsDidChange: nil];
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(defaultsDidChange:)
	name: NSUserDefaultsDidChangeNotification
	object: nil];
      // watch for themes which may provide new system color lists
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(themeDidActivate:)
	name: GSThemeDidActivateNotification
	object: nil];
    }
}

/**<p>Creates and returns a new NSColor in a NSCalibratedRGBColorSpace space 
   name, with hue, saturation, brightness and alpha as specified. Valid values
   are the range 0.0 to 1.0. Out of range values will be clipped.</p>
*/
+ (NSColor*) colorWithCalibratedHue: (float)hue
			 saturation: (float)saturation
			 brightness: (float)brightness
			      alpha: (float)alpha
{
  id color;

  color = [GSCalibratedRGBColor allocWithZone: NSDefaultMallocZone()];
  color = [color initWithCalibratedHue: hue
		 saturation: saturation
		 brightness: brightness
		 alpha: alpha];

  return AUTORELEASE(color);
}


/**<p>Creates and returns a new NSColor in a NSCalibratedRGBColorSpace space 
   name, with red, green, blue and alpha as specified. Valid values
   are the range 0.0 to 1.0. Out of range values will be clipped.</p>
*/
+ (NSColor*) colorWithCalibratedRed: (float)red
			      green: (float)green
			       blue: (float)blue
			      alpha: (float)alpha
{
  id color;

  color = [GSCalibratedRGBColor allocWithZone: NSDefaultMallocZone()];
  color = [color initWithCalibratedRed: red
		 green: green
		 blue: blue
		 alpha: alpha];
  return AUTORELEASE(color);
}


/**<p>Creates and returns a new NSColor in a NSCalibratedWhiteColorSpace space 
   name, with red, green, blue and alpha as specified. Valid values
   are the range 0.0 to 1.0. Out of range values will be clipped.</p>
*/
+ (NSColor*) colorWithCalibratedWhite: (float)white
				alpha: (float)alpha
{
  id color;

  color = [GSCalibratedWhiteColor allocWithZone: NSDefaultMallocZone()] ;
  color = [color initWithCalibratedWhite: white
		 alpha: alpha];

  return AUTORELEASE(color);
}

/**
 * <p> TODO </p>
 */
+ (NSColor*) colorWithCatalogName: (NSString *)listName
			colorName: (NSString *)colorName
{
  id color;

  color = [GSNamedColor allocWithZone: NSDefaultMallocZone()] ;
  color = [color initWithCatalogName: listName
		 colorName: colorName];

  return AUTORELEASE(color);
}

/**<p>Creates and returns a new NSColor in a NSDeviceCMYKColorSpace space 
   name, with cyan, magenta, yellow, black and alpha as specified. Valid values
   are the range 0.0 to 1.0. Out of range values will be clipped.</p>
*/
+ (NSColor*) colorWithDeviceCyan: (float)cyan
			 magenta: (float)magenta
			  yellow: (float)yellow
			   black: (float)black
			   alpha: (float)alpha
{
  id color;

  color = [GSDeviceCMYKColor allocWithZone: NSDefaultMallocZone()];
  color = [color initWithDeviceCyan: cyan
		 magenta: magenta
		 yellow: yellow
		 black: black
		 alpha: alpha];

  return AUTORELEASE(color);
}


/**<p>Creates and returns a new NSColor in a NSDeviceCMYKColorSpace space 
   name, with hue, saturation, brightness and alpha as specified. Valid values
   are the range 0.0 to 1.0. Out of range values will be clipped.</p>
*/
+ (NSColor*) colorWithDeviceHue: (float)hue
		     saturation: (float)saturation
		     brightness: (float)brightness
			  alpha: (float)alpha
{
  id color;

  color = [GSDeviceRGBColor allocWithZone: NSDefaultMallocZone()];
  color = [color initWithDeviceHue: hue
		 saturation: saturation
		 brightness: brightness
		 alpha: alpha];

  return AUTORELEASE(color);
}

/**<p>Creates and returns a new NSColor in a NSDeviceCMYKColorSpace space 
   name, with red, green, blue and alpha as specified. Valid values
   are the range 0.0 to 1.0. Out of range values will be clipped.</p>
*/
+ (NSColor*) colorWithDeviceRed: (float)red
			  green: (float)green
			   blue: (float)blue
			  alpha: (float)alpha
{
  id color;

  color = [GSDeviceRGBColor allocWithZone: NSDefaultMallocZone()];
  color = [color initWithDeviceRed: red
		 green: green
		 blue: blue
		 alpha: alpha];

  return AUTORELEASE(color);
}

/**<p>Creates and returns a new NSColor in a  NSDeviceWhiteColorSpace space 
   name, with red, green, blue and alpha as specified. Valid values
   are the range 0.0 to 1.0. Out of range values will be clipped.</p>
*/
+ (NSColor*) colorWithDeviceWhite: (float)white
			    alpha: (float)alpha
{
  id color;

  color = [GSDeviceWhiteColor allocWithZone: NSDefaultMallocZone()];
  color = [color initWithDeviceWhite: white
		 alpha: alpha];

  return AUTORELEASE(color);
}

+ (NSColor*) colorForControlTint: (NSControlTint)controlTint
{
  // TODO
  return nil;
}

+ (NSColor*) colorWithPatternImage: (NSImage*)image
{
  id color;

  color = [GSPatternColor allocWithZone: NSDefaultMallocZone()];
  color = [color initWithPatternImage: image];

  return AUTORELEASE(color);
}


/**<p>Returns a NSColor in a NSCalibratedWhiteColorSpace space name.
  with white and alpha values set as NSBlack and 1.0 respectively.</p>
  <p>See Also : +colorWithCalibratedWhite:alpha:</p>
*/
+ (NSColor*) blackColor
{
  return [self colorWithCalibratedWhite: NSBlack alpha: 1.0];
}


/**<p>Returns an NSColor in a  NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 0.0, 0.0, 1.0 and 1.0
  respectively.</p><p>See Also : +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) blueColor
{
  return [self colorWithCalibratedRed: 0.0
			        green: 0.0
				 blue: 1.0
			        alpha: 1.0];
}

/**<p>Returns a NSColor in a NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 0.6, 0.4, 0.2 and 1.0
  respectively.</p><p>See Also: +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) brownColor
{
  return [self colorWithCalibratedRed: 0.6
			        green: 0.4
				 blue: 0.2
			        alpha: 1.0];
}

/**<p>Returns a NSColor in a NSCalibratedWhiteColorSpace space name.
  with white and alpha values set as 0.0 and 1.0 respectively.</p>
  <p>See Also : +colorWithCalibratedWhite:alpha:</p>
*/
+ (NSColor*) clearColor
{
  return [self colorWithCalibratedWhite: 0.0 alpha: 0.0];
}


/**<p>Returns a NSColor in a NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 0.0, 1.0, 1.0 and 1.0
  respectively.</p><p>See Also : +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) cyanColor
{
  return [self colorWithCalibratedRed: 0.0
			        green: 1.0
				 blue: 1.0
			        alpha: 1.0];
}

/**<p>Returns a NSColor in a NSCalibratedWhiteColorSpace space name.
  with white and alpha values set as NSDarkGray and 1.0 respectively. </p>
  <p>See Also : +colorWithCalibratedWhite:alpha:</p>
*/
+ (NSColor*) darkGrayColor
{
  return [self colorWithCalibratedWhite: NSDarkGray alpha: 1.0];
}

/**<p>Returns a NSColor in a NSCalibratedWhiteColorSpace space name.
  with white and alpha values set as NSGray and 1.0 respectively. </p>
  <p>See Also: +colorWithCalibratedWhite:alpha:</p>
*/
+ (NSColor*) grayColor
{
  return [self colorWithCalibratedWhite: NSGray alpha: 1.0];
}

/**<p>Returns a NSColor in a  NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 0.0, 1.0, 0.0 and 1.0
  respectively </p><p>See Also: +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) greenColor
{
  return [self colorWithCalibratedRed: 0.0
			        green: 1.0
				 blue: 0.0
			        alpha: 1.0];
}

/**<p>Returns a NSColor in a NSCalibratedWhiteColorSpace space name.
  with white and alpha values set as NSLightGray and 1.0 respectively </p>
  <p>See Also : +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) lightGrayColor
{
  return [self colorWithCalibratedWhite: NSLightGray alpha: 1];
}

/**<p>Returns a NSColor in a NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 1.0, 0.0, 1.0 and 1.0
  respectively.</p><p>See Also : +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) magentaColor
{
  return [self colorWithCalibratedRed: 1.0
			        green: 0.0
				 blue: 1.0
			        alpha: 1.0];
}


/**<p>Returns a NSColor in a NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 1.0, 0.5, 0.0 and 1.0
  respectively.</p><p>See Also: +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) orangeColor
{
  return [self colorWithCalibratedRed: 1.0
			        green: 0.5
				 blue: 0.0
			        alpha: 1.0];
}


/**<p>Returns a NSColor in a NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 0.5, 0.0, 0.5 and 1.0
  respectively.</p><p>See Also : +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) purpleColor
{
  return [self colorWithCalibratedRed: 0.5
			        green: 0.0
				 blue: 0.5
			        alpha: 1.0];
}


/**<p>Returns a NSColor in a NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 1.0, 0.0, 0.0 and 1.0
  respectively </p><p>See Also: +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) redColor
{
  return [self colorWithCalibratedRed: 1.0
			        green: 0.0
				 blue: 0.0
			        alpha: 1.0];
}

/**<p>Returns a NSColor in a NSCalibratedWhiteColorSpace space name.
  with white and alpha values set as NSWhite and 1.0 respectively. </p>
  <p>See Also : +colorWithCalibratedWhite:alpha:</p>
*/
+ (NSColor*) whiteColor
{
  return [self colorWithCalibratedWhite: NSWhite alpha: 1.0];
}


/**<p>Returns a NSColor in a NSCalibratedRGBColorSpace space name.
  with red, green, blue and alpha values set as 1.0, 0.0, 0.0 and 1.0
  respectively.</p><p>See Also : +colorWithCalibratedRed:green:blue:alpha:</p>
*/
+ (NSColor*) yellowColor
{
  return [self colorWithCalibratedRed: 1.0
			        green: 1.0
				 blue: 0.0
			        alpha: 1.0];
}


/** Returns whether TODO
 *<p>See Also: +setIgnoresAlpha:</p>
 */
+ (BOOL) ignoresAlpha
{
  return gnustep_gui_ignores_alpha;
}

/** TODO
 *<p>See Also: +ignoresAlpha</p>
 */
+ (void) setIgnoresAlpha: (BOOL)flag
{
  gnustep_gui_ignores_alpha = flag;
}

/**<p>Returns the NSColor on the NSPasteboard pasteBoard
   or nil if it does not exists.</p><p>See Also: -writeToPasteboard:</p>
 */
+ (NSColor*) colorFromPasteboard: (NSPasteboard *)pasteBoard
{
  NSData *colorData = [pasteBoard dataForType: NSColorPboardType];

  // FIXME: This should better use the description format
  if (colorData != nil)
    return [NSUnarchiver unarchiveObjectWithData: colorData];

  return nil;
}

//
// System colors stuff.
//
+ (NSColor*) alternateSelectedControlColor
{
  return systemColorWithName(@"alternateSelectedControlColor");
}

+ (NSColor*) alternateSelectedControlTextColor
{
  return systemColorWithName(@"alternateSelectedControlTextColor");
}

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

+ (NSColor*) secondarySelectedControlColor
{
  return systemColorWithName(@"secondarySelectedControlColor");
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

+ (NSArray*) controlAlternatingRowBackgroundColors
{
  return [NSArray arrayWithObjects: systemColorWithName(@"rowBackgroundColor"), 
		  systemColorWithName(@"alternateRowBackgroundColor"), nil];
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
      return NSCopyObject(self, 0, aZone);
    }
}

- (NSString*) description
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/**<p>Gets the cyan, magenta, yellow,black and alpha values from the NSColor.
 Raises a NSInternalInconsistencyException if the NSColor is not a CYMK color
 </p>
 */
- (void) getCyan: (float*)cyan
	 magenta: (float*)magenta
	  yellow: (float*)yellow
	   black: (float*)black
	   alpha: (float*)alpha
{
  [NSException raise: NSInternalInconsistencyException
    format: @"Called getCyan:magenta:yellow:black:alpha: on non-CMYK colour"];
}

/**<p>Gets the hue, saturation, brightness and alpha values from the NSColor.
 Raises a NSInternalInconsistencyException if the NSColor is not a RGB color
 </p>
 */
- (void) getHue: (float*)hue
     saturation: (float*)saturation
     brightness: (float*)brightness
	  alpha: (float*)alpha
{
  [NSException raise: NSInternalInconsistencyException
    format: @"Called getHue:saturation:brightness:alpha: on non-RGB colour"];
}

/**<p>Gets the red, green, blue and alpha values from the NSColor.
 Raises a NSInternalInconsistencyException if the NSColor is not a RGB color
 </p>
 */
-(void) getRed: (float*)red
	  green: (float*)green
	   blue: (float*)blue
	  alpha: (float*)alpha
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called getRed:green:blue:alpha: on non-RGB colour"];
}

/**<p>Gets the white alpha values from the NSColor.
 Raises a NSInternalInconsistencyException if the NSColor is not a 
 greyscale color</p>
 */
- (void) getWhite: (float*)white
	    alpha: (float*)alpha
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called getWhite:alpha: on non-grayscale colour"];
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    return YES;
  if ([other isKindOfClass: NSColorClass] == NO)
    return NO;
  else
    {
      [self subclassResponsibility: _cmd];
      return NO;
    }
}

/** <p>Returns the alpha component. </p>
 */
- (float) alphaComponent
{
  return 1.0;
}

/** <p>Returns the black component. Raises a NSInternalInconsistencyException
    if NSColor is not a CMYK color.</p>
 */
- (float) blackComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called blackComponent on non-CMYK colour"];
  return 0.0;
}

/** <p>Returns the blue component. Raises a NSInternalInconsistencyException
    if NSColor is not a RGB color.</p>
 */
- (float) blueComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called blueComponent on non-RGB colour"];
  return 0.0;
}

/** <p>Returns the brightness component. Raises a 
    NSInternalInconsistencyException if NSColor space is not a RGB color</p>
*/
- (float) brightnessComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called brightnessComponent on non-RGB colour"];
  return 0.0;
}

- (NSString *) catalogNameComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called catalogNameComponent on colour with name"];
  return nil;
}

- (NSString *) colorNameComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called colorNameComponent on colour with name"];
  return nil;
}

/** <p>Returns the cyan component. Raises a  NSInternalInconsistencyException 
    if NSColor is not a CYMK color</p>
*/
- (float) cyanComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called cyanComponent on non-CMYK colour"];
  return 0.0;
}

/** <p>Returns the green component. Raises a  NSInternalInconsistencyException 
    if NSColor is not a RGB color</p>
*/
- (float) greenComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called greenComponent on non-RGB colour"];
  return 0.0;
}

/** <p>Returns the hue component. Raises a  NSInternalInconsistencyException 
    if NSColor is not a RGB color</p>
*/
- (float) hueComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called hueComponent on non-RGB colour"];
  return 0.0;
}

- (NSString *) localizedCatalogNameComponent
{
  [NSException raise: NSInternalInconsistencyException
    format: @"Called localizedCatalogNameComponent on colour with name"];
  return nil;
}

- (NSString *) localizedColorNameComponent
{
  [NSException raise: NSInternalInconsistencyException
    format: @"Called localizedColorNameComponent on colour with name"];
  return nil;
}

/** <p>Returns the magenta component. Raises a  
    NSInternalInconsistencyException  if NSColor is not a CMYK color</p>
*/
- (float) magentaComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called magentaComponent on non-CMYK colour"];
  return 0.0;
}

/** <p>Returns the red component. Raises a NSInternalInconsistencyException  
    if NSColor is not a RGB color</p>
*/
- (float) redComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called redComponent on non-RGB colour"];
  return 0.0;
}

/** <p>Returns the saturation component. Raises a
    NSInternalInconsistencyException if NSColor is not a RGB color</p>
*/
- (float) saturationComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called saturationComponent on non-RGB colour"];
  return 0.0;
}

/** <p>Returns the white component. Raises a NSInternalInconsistencyException  
    if NSColor is not a grayscale color</p>
*/
- (float) whiteComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called whiteComponent on non-grayscale colour"];
  return 0.0;
}

- (NSImage*) patternImage
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called patternImage on non-pattern colour"];
  return nil;
}

/** <p>Returns the yellow component. Raises a NSInternalInconsistencyException
    if NSColor is not a RGB color</p>
*/
- (float) yellowComponent
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Called yellowComponent on non-CMYK colour"];
  return 0.0;
}

//
// Converting to Another Color Space
//
- (NSString *) colorSpaceName
{
  [self subclassResponsibility: _cmd];
  return nil;
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
        colorSpace = NSDeviceRGBColorSpace;
    }
  if ([colorSpace isEqualToString: [self colorSpaceName]])
    {
      return self;
    }

  if ([colorSpace isEqualToString: NSNamedColorSpace])
    {
      // FIXME: We cannot convert to named color space.
      return nil;
    }

  [self subclassResponsibility: _cmd];

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
  float mr, mg, mb, ma, or, og, ob, oa, red, green, blue, alpha;

  if (fraction <= 0.0)
    {
      return self;
    }

  if (fraction >= 1.0)
    {
      return aColor;
    }

  if (myColor == nil || other == nil)
    {
      return nil;
    }

  [myColor getRed: &mr green: &mg blue: &mb alpha: &ma];
  [other getRed: &or green: &og blue: &ob alpha: &oa];
  red = fraction * or + (1 - fraction) * mr;
  green = fraction * og + (1 - fraction) * mg;
  blue = fraction * ob + (1 - fraction) * mb;
  alpha = fraction * oa + (1 - fraction) * ma;
  return [NSColorClass colorWithCalibratedRed: red
					green: green
					 blue: blue
					alpha: alpha];
}

- (NSColor*) colorWithAlphaComponent: (float)alpha
{
  return self;
}

- (NSColor*) highlightWithLevel: (float)level
{
  return [self blendedColorWithFraction: level
			        ofColor: [NSColorClass highlightColor]];
}

- (NSColor*) shadowWithLevel: (float)level
{
  return [self blendedColorWithFraction: level
			        ofColor: [NSColorClass shadowColor]];
}

/**<p>Writes the NSColor into the NSPasteboard specified by pasteBoard</p>
 * <p>See Also: +colorFromPasteboard: </p>
 */
- (void) writeToPasteboard: (NSPasteboard *)pasteBoard
{
  // FIXME: We should better use the description
  NSData *colorData = [NSArchiver archivedDataWithRootObject: self];

  if (colorData != nil)
    [pasteBoard setData: colorData
		forType: NSColorPboardType];
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
  // This is here to keep old code working
  [[self colorUsingColorSpaceName: NSDeviceRGBColorSpace] set];
}

//
// NSCoding protocol
//
- (Class) classForCoder
{
  return NSColorClass;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [self subclassResponsibility: _cmd];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      int colorSpace = [aDecoder decodeIntForKey: @"NSColorSpace"];

      DESTROY(self);

      if ((colorSpace == 1) || (colorSpace == 2))
        {
	  unsigned length;
	  const uint8_t *data;
	  float red = 0.0;
	  float green = 0.0;
	  float blue = 0.0;
	  float alpha = 1.0;
	  NSString *str;
	  NSScanner *scanner;
	  
	  if ([aDecoder containsValueForKey: @"NSRGB"])
	    {
	      data = [aDecoder decodeBytesForKey: @"NSRGB"
			       returnedLength: &length]; 
	      str = [[NSString alloc] initWithCString: (const char*)data 
				      length: length];
	      scanner = [[NSScanner alloc] initWithString: str];
	      [scanner scanFloat: &red];
	      [scanner scanFloat: &green];
	      [scanner scanFloat: &blue];
	      RELEASE(scanner);
	      RELEASE(str);
	    }

	  if (colorSpace == 1)
	    {
	      self = RETAIN([NSColor colorWithCalibratedRed: red
				     green: green
				     blue: blue
				     alpha: alpha]);
	    }
	  else
	    {
	      self = RETAIN([NSColor colorWithDeviceRed: red
				     green: green
				     blue: blue
				     alpha: alpha]);
	    }
	}
      else if ((colorSpace == 3) || (colorSpace == 4))
        {
	  unsigned length;
	  const uint8_t *data;
	  float white = 0.0;
	  float alpha = 1.0;
	  NSString *str;
	  NSScanner *scanner;
	  
	  if ([aDecoder containsValueForKey: @"NSWhite"])
	    {
	      data = [aDecoder decodeBytesForKey: @"NSWhite"
			       returnedLength: &length]; 
	      str = [[NSString alloc] initWithCString: (const char*)data 
				      length: length];
	      scanner = [[NSScanner alloc] initWithString: str];
	      [scanner scanFloat: &white];
	      RELEASE(scanner);
	      RELEASE(str);
	    }
	  
	  if (colorSpace == 3)
	    {
	      self = RETAIN([NSColor colorWithCalibratedWhite: white
				     alpha: alpha]);
	    }
	  else
	    {
	      self = RETAIN([NSColor colorWithDeviceWhite: white
				     alpha: alpha]);
	    }
	}
      else if (colorSpace == 5)
        {
	  unsigned length;
	  const uint8_t *data;
	  float cyan = 0.0;
	  float yellow = 0.0;
	  float magenta = 0.0;
	  float black = 0.0;
	  float alpha = 1.0;
	  NSString *str;
	  NSScanner *scanner;
	  
	  if ([aDecoder containsValueForKey: @"NSCYMK"])
	    {
	      data = [aDecoder decodeBytesForKey: @"NSCYMK"
			       returnedLength: &length]; 
	      str = [[NSString alloc] initWithCString: (const char*)data 
				      length: length];
	      scanner = [[NSScanner alloc] initWithString: str];
	      [scanner scanFloat: &cyan];
	      [scanner scanFloat: &yellow];
	      [scanner scanFloat: &magenta];
	      [scanner scanFloat: &black];
	      RELEASE(scanner);
	      RELEASE(str);
	    }

	  self = RETAIN([NSColor colorWithDeviceCyan: cyan
				 magenta: magenta
				 yellow: yellow
				 black: black
				 alpha: alpha]);
	}
      else if (colorSpace == 6)
        {
	  NSString *catalog = [aDecoder decodeObjectForKey: @"NSCatalogName"];
	  NSString *name = [aDecoder decodeObjectForKey: @"NSColorName"];
	  //NSColor *color = [aDecoder decodeObjectForKey: @"NSColor"];
	  
	  self = RETAIN([NSColor colorWithCatalogName: catalog
				 colorName: name]);
	}
      else if (colorSpace == 10)
        {
	  NSImage *image = [aDecoder decodeObjectForKey: @"NSImage"];
	  
	  self = RETAIN([NSColor colorWithPatternImage: image]);
	}
      
      return self;
    }
  else if ([aDecoder versionForClassName: @"NSColor"] < 3)
    {
      float red;
      float green;
      float blue;
      float cyan;
      float magenta;
      float yellow;
      float black;
      float hue;
      float saturation;
      float brightness;
      float alpha;
      float white;

      int active_component;
      int valid_components;
      NSString *colorspace_name;
      NSString *catalog_name;
      NSString *color_name;
      BOOL is_clear;

      DESTROY(self);

      // Version 1
      [aDecoder decodeValueOfObjCType: @encode(float) at: &red];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &green];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &blue];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &alpha];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_clear];

      // Version 2
      [aDecoder decodeValueOfObjCType: @encode(id) at: &colorspace_name];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &catalog_name];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &color_name];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &cyan];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &magenta];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &yellow];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &black];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &hue];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &saturation];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &brightness];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &white];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &active_component];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &valid_components];

      if ([colorspace_name isEqualToString: @"NSDeviceCMYKColorSpace"])
	{
	  self = [NSColorClass colorWithDeviceCyan: cyan
					   magenta: magenta
					    yellow: yellow
					     black: black
					     alpha: alpha];
	}
      else if ([colorspace_name isEqualToString: @"NSDeviceWhiteColorSpace"])
	{
	  self = [NSColorClass colorWithDeviceWhite: white alpha: alpha];
	}
      else if ([colorspace_name isEqualToString:
	@"NSCalibratedWhiteColorSpace"])
	{
	  self = [NSColorClass colorWithCalibratedWhite:white alpha: alpha];
	}
      else if ([colorspace_name isEqualToString: @"NSDeviceRGBColorSpace"])
	{
	  self = [NSColorClass colorWithDeviceRed: red
					    green: green
					     blue: blue
					    alpha: alpha];
	}
      else if ([colorspace_name isEqualToString: @"NSCalibratedRGBColorSpace"])
	{
	  self = [NSColorClass colorWithCalibratedRed: red
						green: green
						 blue: blue
						alpha: alpha];
	}
      else if ([colorspace_name isEqualToString: @"NSNamedColorSpace"])
	{
	  self = [NSColorClass colorWithCatalogName: catalog_name
					  colorName: color_name];
	}

      return RETAIN(self);
    }
  else
    {
      NSString	*csName = [aDecoder decodeObject];

      RELEASE(self);
      if ([csName isEqualToString: @"NSDeviceCMYKColorSpace"])
	{
	  self = [GSDeviceCMYKColor alloc];
	}
      else if ([csName isEqualToString: @"NSDeviceRGBColorSpace"])
	{
	  self = [GSDeviceRGBColor alloc];
	}
      else if ([csName isEqualToString: @"NSDeviceWhiteColorSpace"])
	{
	  self = [GSDeviceWhiteColor alloc];
	}
      else if ([csName isEqualToString: @"NSCalibratedWhiteColorSpace"])
	{
	  self = [GSCalibratedWhiteColor alloc];
	}
      else if ([csName isEqualToString: @"NSCalibratedRGBColorSpace"])
	{
	  self = [GSCalibratedRGBColor alloc];
	}
      else if ([csName isEqualToString: @"NSNamedColorSpace"])
	{
	  self = [GSNamedColor alloc];
	}
      else
	{
	  NSLog(@"Unknown colorspace name in decoded color");
	  return nil;
	}
      return [self initWithCoder: aDecoder];
    }
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
      float		r, g, b;
      NSScanner *scanner = [[NSScanner alloc] initWithString: str];

      if ([scanner scanFloat: &r] &&
	  [scanner scanFloat: &g] &&
	  [scanner scanFloat: &b] &&
	  [scanner isAtEnd])
	{
	  RELEASE(scanner);
	  return [self colorWithCalibratedRed: r
					green: g
					 blue: b
					alpha: 1.0];
	}

      RELEASE(scanner);
    }

  return nil;
}

/*
 *	Go through all the names of system colors - for each color where
 *	there is a value in the defaults database, see if the current
 *	value of the color differs from the old one.
 *	Where there is a difference, update the color strings dictionary
 *	and update the system colors list to contain the new color.
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
      NSString	*def = [[defs objectForKey: key] description];

      if (def != nil)
	{
	  NSColor *old = [systemColors colorWithKey: key];
	  NSColor *color = [NSColor colorFromString: def];

	  if (color == nil)
	    {
	      NSLog(@"System color '%@' has bad string rep - '%@'\n",
		    key, def);
	    }
	  else if ([color isEqual: old] == NO)
	    {
	      didChange = YES;
	      [colorStrings setObject: def forKey: key];
	      [systemColors setColor: color forKey: key];
	      // Refresh the cache for this named colour
	      [[systemDict objectForKey: key] recache];
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
 * Handle activation of a new theme ... look for a 'System' color list
 * in the theme bundle and use it instead of the default system color
 * list if it is present.
 */
+ (void) themeDidActivate: (NSNotification*)notification
{
  NSDictionary	*userInfo = [notification userInfo];
  NSColorList	*list = [userInfo objectForKey: @"Colors"];

  if (list == nil)
    {
      list = defaultSystemColors;
    }
  NSAssert([[list name] isEqual: @"System"], NSInvalidArgumentException);
  [NSColorList _setThemeSystemColorList: list];

  /* We always update the system dictionary and send a notification, since
   * the theme may have gicen us a pre-existing color list, but have changed
   * one or more of the colors in it.
   */
  list = [NSColorList colorListNamed: @"System"];
  ASSIGN(systemColors, list);
  [systemDict removeAllObjects];
NSLog(@"Theme activation with control background %@", [self controlBackgroundColor]);
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSSystemColorsDidChangeNotification object: nil];
}

@end


// Named colours
@implementation GSNamedColor

- (NSColor*) initWithCatalogName: (NSString *)listName
		       colorName: (NSString *)colorName
{
  ASSIGN(_catalog_name, listName);
  ASSIGN(_color_name, colorName);

  return self;
}

- (void) dealloc
{
  RELEASE(_catalog_name);
  RELEASE(_color_name);
  RELEASE(_cached_name_space);
  RELEASE(_cached_color);
  [super dealloc];
}

- (NSString *) colorSpaceName
{
  return NSNamedColorSpace;
}

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone(self, aZone))
    {
      return RETAIN(self);
    }
  else
    {
      GSNamedColor *aCopy = (GSNamedColor*)NSCopyObject(self, 0, aZone);

      aCopy->_catalog_name = [_catalog_name copyWithZone: aZone];
      aCopy->_color_name = [_color_name copyWithZone: aZone];
      aCopy->_cached_name_space = nil;
      aCopy->_cached_color = nil;
	 return aCopy;
    }
}

- (NSString*) description
{
  NSMutableString *desc;

  /*
   *	We encode information in a dictionary
   *	format with meaningful keys.
   */
  desc = [NSMutableString stringWithCapacity: 128];
  [desc appendFormat: @"{ ColorSpace = \"%@\";", [self colorSpaceName]];
  [desc appendFormat: @" Catalog = \"%@\";", _catalog_name];
  [desc appendFormat: @" Color = \"%@\"; }", _color_name];

  return desc;
}

- (NSString *) catalogNameComponent
{
  return _catalog_name;
}

- (NSString *) colorNameComponent
{
  return _color_name;
}

- (NSString *) localizedCatalogNameComponent
{
  // FIXME: How do we localize?
  return NSLocalizedString(_catalog_name, @"colour list name");
}

- (NSString *) localizedColorNameComponent
{
  // FIXME: How do we localize?
  return NSLocalizedString(_color_name, @"colour name");
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    return YES;
  if ([other isKindOfClass: [self class]] == NO)
    return NO;
  else
    {
      GSNamedColor *col = (GSNamedColor*)other;

      if (![[col catalogNameComponent] isEqualToString: _catalog_name])
	return NO;
      if (![[col colorNameComponent] isEqualToString: _color_name])
	return NO;
      return YES;
    }
  return NO;
}

- (NSColor*) colorUsingColorSpaceName: (NSString *)colorSpace
			       device: (NSDictionary *)deviceDescription
{
  NSColorList *list;
  NSColor *real;

  if (colorSpace == nil)
    {
      if (deviceDescription != nil)
	colorSpace = [deviceDescription objectForKey: NSDeviceColorSpaceName];
      // FIXME: If the deviceDescription is nil, we should get it from the
      // current view or printer
      if (colorSpace == nil)
        colorSpace = NSCalibratedRGBColorSpace;
    }
  if ([colorSpace isEqualToString: [self colorSpaceName]])
    {
      return self;
    }


  // Is there a cache hit?
  // FIXME How would we detect that the cache has become invalid by a
  // change to the colour list?
  if ([colorSpace isEqualToString: _cached_name_space])
    {
      return _cached_color;
    }

  list = [NSColorList colorListNamed: _catalog_name];
  real = [list colorWithKey: _color_name];

  ASSIGN(_cached_color, [real colorUsingColorSpaceName: colorSpace
		       device: deviceDescription]);
  ASSIGN(_cached_name_space, colorSpace);

  return _cached_color;
}

- (void) recache
{
  DESTROY(_cached_name_space);
  DESTROY(_cached_color);
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeInt: 6 forKey: @"NSColorSpace"];
      [aCoder encodeObject: _catalog_name forKey: @"NSCatalogName"];
      [aCoder encodeObject: _color_name forKey: @"NSColorName"];
    }
  else 
    {
      [aCoder encodeObject: [self colorSpaceName]];
      [aCoder encodeObject: _catalog_name];
      [aCoder encodeObject: _color_name];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_catalog_name];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_color_name];

  return self;
}

@end

// Grayscale colours
@implementation GSWhiteColor

- (float) alphaComponent
{
  return _alpha_component;
}

- (float) whiteComponent
{
  return _white_component;
}

- (NSString*) description
{
  NSMutableString *desc;

  /*
   *	We encode information in a dictionary
   *	format with meaningful keys.
   */
  desc = [NSMutableString stringWithCapacity: 128];
  [desc appendFormat: @"{ ColorSpace = \"%@\";", [self colorSpaceName]];
  [desc appendFormat: @" W = \"%f\";", _white_component];
  [desc appendFormat: @" Alpha = \"%f\"; }", _alpha_component];

  return desc;
}

- (void) getWhite: (float*)white
	    alpha: (float*)alpha
{
  // Only set what is wanted
  if (white)
    *white = _white_component;
  if (alpha)
    *alpha = _alpha_component;
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    return YES;
  if ([other isKindOfClass: [self class]] == NO)
    return NO;
  else
    {
      GSWhiteColor *col = (GSWhiteColor*)other;

      if (col->_white_component != _white_component ||
	  col->_alpha_component != _alpha_component)
	  return NO;
      return YES;
    }
  return NO;
}

- (NSColor*) colorWithAlphaComponent: (float)alpha
{
  GSWhiteColor *aCopy;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;

  if (alpha == _alpha_component)
    return self;

  aCopy = (GSWhiteColor*)NSCopyObject(self, 0, NSDefaultMallocZone());

  if (aCopy)
    {
      aCopy->_alpha_component = alpha;
    }

  return AUTORELEASE(aCopy);
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
  if ([colorSpace isEqualToString: [self colorSpaceName]])
    {
      return self;
    }

  if ([colorSpace isEqualToString: NSNamedColorSpace])
    {
      // FIXME: We cannot convert to named color space.
      return nil;
    }

  if ([colorSpace isEqualToString: NSDeviceWhiteColorSpace]
    || [colorSpace isEqualToString: NSDeviceBlackColorSpace])
    {
      return [NSColor colorWithDeviceWhite: _white_component
				     alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSCalibratedWhiteColorSpace]
    || [colorSpace isEqualToString: NSCalibratedBlackColorSpace])
    {
      return [NSColor colorWithCalibratedWhite: _white_component
					 alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSCalibratedRGBColorSpace])
    {
      return [NSColor colorWithCalibratedRed: _white_component
				       green: _white_component
					blue: _white_component
				       alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSDeviceRGBColorSpace])
    {
      return [NSColor colorWithDeviceRed: _white_component
				   green: _white_component
				    blue: _white_component
				   alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSDeviceCMYKColorSpace])
    {
      return [NSColor colorWithDeviceCyan: 0.0
				  magenta: 0.0
				   yellow: 0.0
				    black: 1.0 - _white_component
				    alpha: _alpha_component];
    }

  return nil;
}

- (void) set
{
  // This should be in GSDeviceWhiteColor, but is here to keep old code working
  NSDebugLLog(@"NSColor", @"Gray %f\n", _white_component);
  PSsetgray(_white_component);
  // Should we check the ignore flag here?
  PSsetalpha(_alpha_component);
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      NSString *str;

      if ([[self colorSpaceName] isEqualToString: NSCalibratedWhiteColorSpace])
        {
	  [aCoder encodeInt: 3 forKey: @"NSColorSpace"];
	}
      else
        {
	  [aCoder encodeInt: 4 forKey: @"NSColorSpace"];
	}
      // FIXME: Missing handling of alpha value
      str = [[NSString alloc] initWithFormat: @"%f", _white_component];
      [aCoder encodeBytes: (const uint8_t*)[str cString] 
	      length: [str cStringLength] 
	      forKey: @"NSWhite"];
      RELEASE(str);
    }
  else 
    {
      [aCoder encodeObject: [self colorSpaceName]];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_white_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_alpha_component];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_white_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_alpha_component];

  return self;
}

@end

@implementation GSDeviceWhiteColor

- (NSString *) colorSpaceName
{
  return NSDeviceWhiteColorSpace;
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

  return self;
}

@end

@implementation GSCalibratedWhiteColor

- (NSString *) colorSpaceName
{
  return NSCalibratedWhiteColorSpace;
}

- (NSColor*) initWithCalibratedWhite: (float)white
			       alpha: (float)alpha
{
  if (white < 0.0) white = 0.0;
  else if (white > 1.0) white = 1.0;
  _white_component = white;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  return self;
}

@end

@implementation GSDeviceCMYKColor

- (NSColor*) initWithDeviceCyan: (float)cyan
			magenta: (float)magenta
			 yellow: (float)yellow
			  black: (float)black
			  alpha: (float)alpha
{
  if (cyan < 0.0) cyan = 0.0;
  else if (cyan > 1.0) cyan = 1.0;
  _cyan_component = cyan;

  if (magenta < 0.0) magenta = 0.0;
  else if (magenta > 1.0) magenta = 1.0;
  _magenta_component = magenta;

  if (yellow < 0.0) yellow = 0.0;
  else if (yellow > 1.0) yellow = 1.0;
  _yellow_component = yellow;

  if (black < 0.0) black = 0.0;
  else if (black > 1.0) black = 1.0;
  _black_component = black;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  return self;
}

- (NSString *) colorSpaceName
{
  return NSDeviceCMYKColorSpace;
}

- (float) alphaComponent
{
  return _alpha_component;
}

- (float) blackComponent
{
  return _black_component;
}

- (float) cyanComponent
{
  return _cyan_component;
}

- (float) magentaComponent
{
  return _magenta_component;
}

- (float) yellowComponent
{
  return _yellow_component;
}

- (NSString*) description
{
  NSMutableString *desc;

  /*
   *	We encode information in a dictionary
   *	format with meaningful keys.
   */
  desc = [NSMutableString stringWithCapacity: 128];
  [desc appendFormat: @"{ ColorSpace = \"%@\";", [self colorSpaceName]];
  [desc appendFormat: @" C = \"%f\";", _cyan_component];
  [desc appendFormat: @" M = \"%f\";", _magenta_component];
  [desc appendFormat: @" Y = \"%f\";", _yellow_component];
  [desc appendFormat: @" K = \"%f\";", _black_component];
  [desc appendFormat: @" Alpha = \"%f\"; }", _alpha_component];

  return desc;
}

- (void) getCyan: (float*)cyan
	 magenta: (float*)magenta
	  yellow: (float*)yellow
	   black: (float*)black
	   alpha: (float*)alpha
{
  // Only set what is wanted
  if (cyan)
    *cyan = _cyan_component;
  if (magenta)
    *magenta = _magenta_component;
  if (yellow)
    *yellow = _yellow_component;
  if (black)
    *black = _black_component;
  if (alpha)
    *alpha = _alpha_component;
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    return YES;
  if ([other isKindOfClass: [self class]] == NO)
    return NO;
  else
    {
      GSDeviceCMYKColor *col = (GSDeviceCMYKColor*)other;

      if (col->_cyan_component != _cyan_component
	|| col->_magenta_component != _magenta_component
	|| col->_yellow_component != _yellow_component
	|| col->_black_component != _black_component
	|| col->_alpha_component != _alpha_component)
	{
	  return NO;
	}
      return YES;
    }
  return NO;
}

- (NSColor*) colorWithAlphaComponent: (float)alpha
{
  GSDeviceCMYKColor *aCopy;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;

  if (alpha == _alpha_component)
    return self;

  aCopy = (GSDeviceCMYKColor*)NSCopyObject(self, 0, NSDefaultMallocZone());

  if (aCopy)
    {
      aCopy->_alpha_component = alpha;
    }

  return AUTORELEASE(aCopy);
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
  if ([colorSpace isEqualToString: [self colorSpaceName]])
    {
      return self;
    }

  if ([colorSpace isEqualToString: NSNamedColorSpace])
    {
      // FIXME: We cannot convert to named color space.
      return nil;
    }

  if ([colorSpace isEqualToString: NSCalibratedRGBColorSpace])
    {
      double c = _cyan_component;
      double m = _magenta_component;
      double y = _yellow_component;
      double white = 1 - _black_component;

      return [NSColor colorWithCalibratedRed: (c > white ? 0 : white - c)
		      green: (m > white ? 0 : white - m)
		      blue: (y > white ? 0 : white - y)
		      alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSDeviceRGBColorSpace])
    {
      double c = _cyan_component;
      double m = _magenta_component;
      double y = _yellow_component;
      double white = 1 - _black_component;

      return [NSColor colorWithDeviceRed: (c > white ? 0 : white - c)
		      green: (m > white ? 0 : white - m)
		      blue: (y > white ? 0 : white - y)
		      alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSCalibratedWhiteColorSpace]
    || [colorSpace isEqualToString: NSCalibratedBlackColorSpace])
    {
      return [NSColor colorWithCalibratedWhite: 1 - _black_component -
	(_cyan_component + _magenta_component + _yellow_component)/3
	alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSDeviceWhiteColorSpace]
    || [colorSpace isEqualToString: NSDeviceBlackColorSpace])
    {
      return [NSColor colorWithDeviceWhite: 1 - _black_component -
	(_cyan_component + _magenta_component + _yellow_component)/3
	alpha: _alpha_component];
    }

  return nil;
}

- (void) set
{
  NSDebugLLog(@"NSColor", @"CMYK %f %f %f %f\n",
	      _cyan_component, _magenta_component,
	      _yellow_component, _black_component);
  PSsetcmykcolor(_cyan_component, _magenta_component,
		 _yellow_component, _black_component);

  // Should we check the ignore flag here?
  PSsetalpha(_alpha_component);
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      NSString *str;

      // FIXME: Missing handling of alpha value
      [aCoder encodeInt: 5 forKey: @"NSColorSpace"];
      str = [[NSString alloc] initWithFormat: @"%f %f %f %f", _cyan_component, 
	_magenta_component, _yellow_component, _black_component];
      [aCoder encodeBytes: (const uint8_t*)[str cString] 
		   length: [str cStringLength] 
		   forKey: @"NSCYMK"];
      RELEASE(str);
    }
  else 
    {
      [aCoder encodeObject: [self colorSpaceName]];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_cyan_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_magenta_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_yellow_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_black_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_alpha_component];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_cyan_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_magenta_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_yellow_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_black_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_alpha_component];

  return self;
}

@end

// RGB/HSB colours
@implementation GSRGBColor

- (float) alphaComponent
{
  return _alpha_component;
}

- (float) redComponent
{
  return _red_component;
}

- (float) greenComponent
{
  return _green_component;
}

- (float) blueComponent
{
  return _blue_component;
}

- (float) hueComponent
{
  return _hue_component;
}

- (float) saturationComponent
{
  return _saturation_component;
}

- (float) brightnessComponent
{
  return _brightness_component;
}

- (void) getHue: (float*)hue
     saturation: (float*)saturation
     brightness: (float*)brightness
	  alpha: (float*)alpha
{
  // Only set what is wanted
  if (hue)
    *hue = _hue_component;
  if (saturation)
    *saturation = _saturation_component;
  if (brightness)
    *brightness = _brightness_component;
  if (alpha)
    *alpha = _alpha_component;
}

- (void) getRed: (float*)red
	  green: (float*)green
	   blue: (float*)blue
	  alpha: (float*)alpha
{
  // Only set what is wanted
  if (red)
    *red = _red_component;
  if (green)
    *green = _green_component;
  if (blue)
    *blue = _blue_component;
  if (alpha)
    *alpha = _alpha_component;
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    return YES;
  if ([other isKindOfClass: [self class]] == NO)
    return NO;
  else
    {
      GSRGBColor *col = (GSRGBColor*)other;

      if (col->_red_component != _red_component
	|| col->_green_component != _green_component
	|| col->_blue_component != _blue_component)
	{
	  return NO;
	}
      return YES;
    }

  return NO;
}

- (NSColor*) colorWithAlphaComponent: (float)alpha
{
  GSRGBColor *aCopy;

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;

  if (alpha == _alpha_component)
    return self;

  aCopy = (GSRGBColor*)NSCopyObject(self, 0, NSDefaultMallocZone());

  if (aCopy)
    {
      aCopy->_alpha_component = alpha;
    }

  return AUTORELEASE(aCopy);
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
  if ([colorSpace isEqualToString: [self colorSpaceName]])
    {
      return self;
    }

  if ([colorSpace isEqualToString: NSNamedColorSpace])
    {
      // FIXME: We cannot convert to named color space.
      return nil;
    }

  if ([colorSpace isEqualToString: NSCalibratedRGBColorSpace])
    {
      return [NSColor colorWithCalibratedRed: _red_component
		      green: _green_component
		      blue: _blue_component
		      alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSDeviceRGBColorSpace])
    {
      return [NSColor colorWithDeviceRed: _red_component
		      green: _green_component
		      blue: _blue_component
		      alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSCalibratedWhiteColorSpace]
    || [colorSpace isEqualToString: NSCalibratedBlackColorSpace])
    {
      return [NSColor colorWithCalibratedWhite:
	(_red_component + _green_component + _blue_component)/3
	alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSDeviceWhiteColorSpace]
    || [colorSpace isEqualToString: NSDeviceBlackColorSpace])
    {
      return [NSColor colorWithDeviceWhite:
	(_red_component + _green_component + _blue_component)/3
	alpha: _alpha_component];
    }

  if ([colorSpace isEqualToString: NSDeviceCMYKColorSpace])
    {
      return [NSColor colorWithDeviceCyan: 1 - _red_component
				  magenta: 1 - _green_component
				   yellow: 1 - _blue_component
				    black: 0.0
				    alpha: _alpha_component];
    }

  return nil;
}

- (NSString*) description
{
  NSMutableString *desc;

  /*
   *	For a simple RGB color without alpha, we use a shorthand description
   *	consisting of the three component values in a quoted string.
   */
  if (_alpha_component == 1.0)
    return [NSString stringWithFormat: @"%f %f %f",
	_red_component, _green_component, _blue_component];

  /*
   *	For more complex color values - we encode information in a dictionary
   *	format with meaningful keys.
   */
  desc = [NSMutableString stringWithCapacity: 128];
  [desc appendFormat: @"{ ColorSpace = \"%@\";", [self colorSpaceName]];
  [desc appendFormat: @" R = \"%f\";", _red_component];
  [desc appendFormat: @" G = \"%f\";", _green_component];
  [desc appendFormat: @" B = \"%f\";", _blue_component];
  [desc appendFormat: @" Alpha = \"%f\"; }", _alpha_component];
  return desc;
}

- (void) set
{
  /* This should only be in GSDeviceRGBColor,
   * but is here to keep old code working.
   */
  NSDebugLLog(@"NSColor", @"RGB %f %f %f\n", _red_component,
	      _green_component, _blue_component);
  PSsetrgbcolor(_red_component, _green_component,
		_blue_component);
  // Should we check the ignore flag here?
  PSsetalpha(_alpha_component);
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      NSString *str;

      if ([[self colorSpaceName] isEqualToString: NSCalibratedRGBColorSpace])
        {
	  [aCoder encodeInt: 1 forKey: @"NSColorSpace"];
	}
      else
        {
	  [aCoder encodeInt: 2 forKey: @"NSColorSpace"];
	}
      // FIXME: Missing handling of alpha value
      str = [[NSString alloc] initWithFormat: @"%f %f %f", _red_component, 
			      _green_component, _blue_component];
      [aCoder encodeBytes: (const uint8_t*)[str cString] 
	      length: [str cStringLength] 
	      forKey: @"NSRGB"];
      RELEASE(str);
    }
  else 
    {
      [aCoder encodeObject: [self colorSpaceName]];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_red_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_green_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_blue_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_hue_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_saturation_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_brightness_component];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_alpha_component];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_red_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_green_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_blue_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_hue_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_saturation_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_brightness_component];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_alpha_component];

  return self;
}

@end

@implementation GSDeviceRGBColor

- (NSString *) colorSpaceName
{
  return NSDeviceRGBColorSpace;
}

- (NSColor*) initWithDeviceRed: (float)red
			 green: (float)green
			  blue: (float)blue
			 alpha: (float)alpha
{
  if (red < 0.0) red = 0.0;
  else if (red > 1.0) red = 1.0;
  _red_component = red;

  if (green < 0.0) green = 0.0;
  else if (green > 1.0) green = 1.0;
  _green_component = green;

  if (blue < 0.0) blue = 0.0;
  else if (blue > 1.0) blue = 1.0;
  _blue_component = blue;

  {
    float r = _red_component;
    float g = _green_component;
    float b = _blue_component;

    if (r == g && r == b)
      {
	_hue_component = 0;
	_saturation_component = 0;
	_brightness_component = r;
      }
    else
      {
	double H;
	double V;
	double Temp;
	double diff;

	V = (r > g ? r : g);
	V = (b > V ? b : V);
	Temp = (r < g ? r : g);
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
	_hue_component = H/6;
	_saturation_component = diff/V;
	_brightness_component = V;
      }
  }

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  return self;
}

- (NSColor*) initWithDeviceHue: (float)hue
		    saturation: (float)saturation
		    brightness: (float)brightness
			 alpha: (float)alpha;
{
  if (hue < 0.0) hue = 0.0;
  else if (hue > 1.0) hue = 1.0;
  _hue_component = hue;

  if (saturation < 0.0) saturation = 0.0;
  else if (saturation > 1.0) saturation = 1.0;
  _saturation_component = saturation;

  if (brightness < 0.0) brightness = 0.0;
  else if (brightness > 1.0) brightness = 1.0;
  _brightness_component = brightness;

  {
    int	I = (int)(hue * 6);
    double V = brightness;
    double S = saturation;
    double F = (hue * 6) - I;
    double M = V * (1 - S);
    double N = V * (1 - S * F);
    double K = M - N + V;
    double R, G, B;

    switch (I)
      {
	default: R = V; G = K; B = M; break;
	  case 1: R = N; G = V; B = M; break;
	  case 2: R = M; G = V; B = K; break;
	  case 3: R = M; G = N; B = V; break;
	  case 4: R = K; G = M; B = V; break;
	  case 5: R = V; G = M; B = N; break;
      }
    _red_component = (float)R;
    _green_component = (float)G;
    _blue_component = (float)B;
  }

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  return self;
}

@end

@implementation GSCalibratedRGBColor

- (NSString *) colorSpaceName
{
  return NSCalibratedRGBColorSpace;
}

- (NSColor*) initWithCalibratedRed: (float)red
			     green: (float)green
			      blue: (float)blue
			     alpha: (float)alpha
{
  if (red < 0.0) red = 0.0;
  else if (red > 1.0) red = 1.0;
  _red_component = red;

  if (green < 0.0) green = 0.0;
  else if (green > 1.0) green = 1.0;
  _green_component = green;

  if (blue < 0.0) blue = 0.0;
  else if (blue > 1.0) blue = 1.0;
  _blue_component = blue;

  {
    float r = _red_component;
    float g = _green_component;
    float b = _blue_component;

    if (r == g && r == b)
      {
	_hue_component = 0;
	_saturation_component = 0;
	_brightness_component = r;
      }
    else
      {
	double H;
	double V;
	double Temp;
	double diff;

	V = (r > g ? r : g);
	V = (b > V ? b : V);
	Temp = (r < g ? r : g);
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
	_hue_component = H/6;
	_saturation_component = diff/V;
	_brightness_component = V;
      }
  }

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  return self;
}

- (NSColor*) initWithCalibratedHue: (float)hue
			saturation: (float)saturation
			brightness: (float)brightness
			     alpha: (float)alpha;
{
  if (hue < 0.0) hue = 0.0;
  else if (hue > 1.0) hue = 1.0;
  _hue_component = hue;

  if (saturation < 0.0) saturation = 0.0;
  else if (saturation > 1.0) saturation = 1.0;
  _saturation_component = saturation;

  if (brightness < 0.0) brightness = 0.0;
  else if (brightness > 1.0) brightness = 1.0;
  _brightness_component = brightness;

  {
    int	I = (int)(hue * 6);
    double V = brightness;
    double S = saturation;
    double F = (hue * 6) - I;
    double M = V * (1 - S);
    double N = V * (1 - S * F);
    double K = M - N + V;
    double R, G, B;

    switch (I)
      {
	default: R = V; G = K; B = M; break;
	  case 1: R = N; G = V; B = M; break;
	  case 2: R = M; G = V; B = K; break;
	  case 3: R = M; G = N; B = V; break;
	  case 4: R = K; G = M; B = V; break;
	  case 5: R = V; G = M; B = N; break;
      }
    _red_component = (float)R;
    _green_component = (float)G;
    _blue_component = (float)B;
  }

  if (alpha < 0.0) alpha = 0.0;
  else if (alpha > 1.0) alpha = 1.0;
  _alpha_component = alpha;

  return self;
}

@end

@implementation GSPatternColor

- (NSColor*) initWithPatternImage: (NSImage*) pattern;
{
  ASSIGN(_pattern, pattern);

  return self;
}

- (void) dealloc
{
  RELEASE(_pattern);
  [super dealloc];
}

- (NSString *) colorSpaceName
{
  return NSPatternColorSpace;
}

- (NSImage*) patternImage
{
  return _pattern;
}

- (NSString*) description
{
  NSMutableString *desc;

  /*
   *	We encode information in a dictionary
   *	format with meaningful keys.
   */
  desc = [NSMutableString stringWithCapacity: 128];
  [desc appendFormat: @"{ ColorSpace = \"%@\";", [self colorSpaceName]];
  [desc appendFormat: @" Pattern = \"%@\"; }", [_pattern description]];

  return desc;
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    return YES;
  if ([other isKindOfClass: [self class]] == NO)
    return NO;
  else
    {
      GSPatternColor *col = (GSPatternColor*)other;

      if ([col->_pattern isEqual: _pattern] == NO)
	return NO;
      return YES;
    }

  return NO;
}

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone(self, aZone))
    {
      return RETAIN(self);
    }
  else
    {
      GSPatternColor *aCopy = (GSPatternColor*)NSCopyObject(self, 0, aZone);

      aCopy->_pattern = [_pattern copyWithZone: aZone];
      return aCopy;
    }
}

- (void) set
{
  [GSCurrentContext() GSSetPatterColor: _pattern];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeInt: 10 forKey: @"NSColorSpace"];
      [aCoder encodeObject: _pattern forKey: @"NSImage"];
    }
  else 
    {
      [aCoder encodeObject: [self colorSpaceName]];
      [aCoder encodeObject: _pattern];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_pattern];

  return self;
}

@end

//
// Implementation of the NSCoder additions
//
@implementation NSCoder (NSCoderAdditions)

//
// Converting an archived NXColor to an NSColor
//
- (NSColor*) decodeNXColor
{
  // FIXME
  return nil;
}

@end
