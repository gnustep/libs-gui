/*
   NSColor.h

   The colorful color class

   Copyright (C) 1996, 1998 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
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

#ifndef _GNUstep_H_NSColor
#define _GNUstep_H_NSColor
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSCoder.h>
#import <Foundation/NSObject.h>
#import <AppKit/AppKitDefines.h>

@class NSString;
@class NSDictionary;
@class NSPasteboard;
@class NSImage;
@class NSColorSpace;

enum _NSControlTint {
    NSDefaultControlTint,
    NSBlueControlTint,
    NSGraphiteControlTint = 6,
    NSClearControlTint
};
typedef NSUInteger NSControlTint;

enum _NSControlSize {
    NSRegularControlSize,
    NSSmallControlSize,
    NSMiniControlSize
};
typedef NSUInteger NSControlSize;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_14, GS_API_LATEST)
enum _NSColorType {
    NSColorTypeComponentBased,
    NSColorTypePattern,
    NSColorTypeCatalog
};
typedef NSInteger NSColorType;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_14, GS_API_LATEST)
enum _NSColorSystemEffect {
    NSColorSystemEffectNone,
    NSColorSystemEffectPressed,
    NSColorSystemEffectDeepPressed,
    NSColorSystemEffectDisabled,
    NSColorSystemEffectRollover
};
typedef NSInteger NSColorSystemEffect;
#endif

/**
 * NSColor provides a powerful and flexible system for representing and
 * manipulating colors across different color spaces and devices. As an abstract
 * superclass of a class cluster, NSColor supports multiple color models including
 * RGB, HSB, CMYK, grayscale, and catalog-based colors.
 *
 * Key features include:
 * * Multiple color space support (calibrated, device-dependent, generic)
 * * Component-based color creation with precise control
 * * Comprehensive set of predefined system and standard colors
 * * Color space conversion and device-specific adaptation
 * * Pattern-based colors using images
 * * System appearance integration with dynamic colors
 * * Pasteboard integration for color copying and pasting
 * * Advanced color manipulation (blending, highlighting, shadowing)
 * * Support for alpha transparency and composition
 *
 * NSColor automatically handles color space conversions and provides optimized
 * representations for different rendering contexts. The class integrates seamlessly
 * with the graphics system and supports both programmatic color creation and
 * system-provided appearance colors that adapt to user preferences.
 *
 * Color spaces NSDeviceBlackColorSpace and NSCalibratedBlackColorSpace are
 * treated as synonyms for their white counterparts for compatibility.
 */
APPKIT_EXPORT_CLASS
@interface NSColor : NSObject <NSCoding, NSCopying>
{
}

//
// Creating an NSColor from Component Values
//

/**
 * Creates a color in the calibrated HSB color space.
 * hue: The hue component (0.0 to 1.0)
 * saturation: The saturation component (0.0 to 1.0)
 * brightness: The brightness component (0.0 to 1.0)
 * alpha: The alpha transparency component (0.0 to 1.0)
 * Returns: A new NSColor instance in calibrated HSB color space
 */
+ (NSColor *)colorWithCalibratedHue:(CGFloat)hue
			 saturation:(CGFloat)saturation
			 brightness:(CGFloat)brightness
			      alpha:(CGFloat)alpha;

/**
 * Creates a color in the calibrated RGB color space.
 * red: The red component (0.0 to 1.0)
 * green: The green component (0.0 to 1.0)
 * blue: The blue component (0.0 to 1.0)
 * alpha: The alpha transparency component (0.0 to 1.0)
 * Returns: A new NSColor instance in calibrated RGB color space
 */
+ (NSColor *)colorWithCalibratedRed:(CGFloat)red
			      green:(CGFloat)green
			       blue:(CGFloat)blue
			      alpha:(CGFloat)alpha;

/**
 * Creates a grayscale color in the calibrated white color space.
 * white: The grayscale value (0.0 for black to 1.0 for white)
 * alpha: The alpha transparency component (0.0 to 1.0)
 * Returns: A new NSColor instance in calibrated white color space
 */
+ (NSColor *)colorWithCalibratedWhite:(CGFloat)white
				alpha:(CGFloat)alpha;

/**
 * Creates a color from a color catalog.
 * listName: The name of the color catalog
 * colorName: The name of the color within the catalog
 * Returns: A new NSColor instance from the specified catalog, or nil if not found
 */
+ (NSColor *)colorWithCatalogName:(NSString *)listName
			colorName:(NSString *)colorName;
/**
 * Creates a color in the device CMYK color space.
 * cyan: The cyan component (0.0 to 1.0)
 * magenta: The magenta component (0.0 to 1.0)
 * yellow: The yellow component (0.0 to 1.0)
 * black: The black component (0.0 to 1.0)
 * alpha: The alpha transparency component (0.0 to 1.0)
 * Returns: A new NSColor instance in device CMYK color space
 */
+ (NSColor *)colorWithDeviceCyan:(CGFloat)cyan
			 magenta:(CGFloat)magenta
			  yellow:(CGFloat)yellow
			   black:(CGFloat)black
			   alpha:(CGFloat)alpha;

/**
 * Creates a color in the device HSB color space.
 * hue: The hue component (0.0 to 1.0)
 * saturation: The saturation component (0.0 to 1.0)
 * brightness: The brightness component (0.0 to 1.0)
 * alpha: The alpha transparency component (0.0 to 1.0)
 * Returns: A new NSColor instance in device HSB color space
 */
+ (NSColor *)colorWithDeviceHue:(CGFloat)hue
		     saturation:(CGFloat)saturation
		     brightness:(CGFloat)brightness
			  alpha:(CGFloat)alpha;

/**
 * Creates a color in the device RGB color space.
 * red: The red component (0.0 to 1.0)
 * green: The green component (0.0 to 1.0)
 * blue: The blue component (0.0 to 1.0)
 * alpha: The alpha transparency component (0.0 to 1.0)
 * Returns: A new NSColor instance in device RGB color space
 */
+ (NSColor *)colorWithDeviceRed:(CGFloat)red
			  green:(CGFloat)green
			   blue:(CGFloat)blue
			  alpha:(CGFloat)alpha;

/**
 * Creates a grayscale color in the device white color space.
 * white: The grayscale value (0.0 for black to 1.0 for white)
 * alpha: The alpha transparency component (0.0 to 1.0)
 * Returns: A new NSColor instance in device white color space
 */
+ (NSColor *)colorWithDeviceWhite:(CGFloat)white
			    alpha:(CGFloat)alpha;

//
// Creating an NSColor With Preset Components
//

/**
 * Returns a black color (0.0, 0.0, 0.0, 1.0 in RGB).
 * Returns: A black NSColor instance
 */
+ (NSColor *)blackColor;

/**
 * Returns a blue color (0.0, 0.0, 1.0, 1.0 in RGB).
 * Returns: A blue NSColor instance
 */
+ (NSColor *)blueColor;

/**
 * Returns a brown color (0.6, 0.4, 0.2, 1.0 in RGB).
 * Returns: A brown NSColor instance
 */
+ (NSColor *)brownColor;

/**
 * Returns a clear color (0.0, 0.0, 0.0, 0.0 in RGB).
 * Returns: A completely transparent NSColor instance
 */
+ (NSColor *)clearColor;

/**
 * Returns a cyan color (0.0, 1.0, 1.0, 1.0 in RGB).
 * Returns: A cyan NSColor instance
 */
+ (NSColor *)cyanColor;

/**
 * Returns a dark gray color (0.33, 0.33, 0.33, 1.0 in RGB).
 * Returns: A dark gray NSColor instance
 */
+ (NSColor *)darkGrayColor;

/**
 * Returns a medium gray color (0.5, 0.5, 0.5, 1.0 in RGB).
 * Returns: A gray NSColor instance
 */
+ (NSColor *)grayColor;

/**
 * Returns a green color (0.0, 1.0, 0.0, 1.0 in RGB).
 * Returns: A green NSColor instance
 */
+ (NSColor *)greenColor;

/**
 * Returns a light gray color (0.67, 0.67, 0.67, 1.0 in RGB).
 * Returns: A light gray NSColor instance
 */
+ (NSColor *)lightGrayColor;

/**
 * Returns a magenta color (1.0, 0.0, 1.0, 1.0 in RGB).
 * Returns: A magenta NSColor instance
 */
+ (NSColor *)magentaColor;

/**
 * Returns an orange color (1.0, 0.5, 0.0, 1.0 in RGB).
 * Returns: An orange NSColor instance
 */
+ (NSColor *)orangeColor;

/**
 * Returns a purple color (0.5, 0.0, 0.5, 1.0 in RGB).
 * Returns: A purple NSColor instance
 */
+ (NSColor *)purpleColor;

/**
 * Returns a red color (1.0, 0.0, 0.0, 1.0 in RGB).
 * Returns: A red NSColor instance
 */
+ (NSColor *)redColor;

/**
 * Returns a white color (1.0, 1.0, 1.0, 1.0 in RGB).
 * Returns: A white NSColor instance
 */
+ (NSColor *)whiteColor;

/**
 * Returns a yellow color (1.0, 1.0, 0.0, 1.0 in RGB).
 * Returns: A yellow NSColor instance
 */
+ (NSColor *)yellowColor;

//
// Ignoring Alpha Components
//

/**
 * Returns whether alpha components are ignored in color operations.
 * Returns: YES if alpha components are ignored, NO if they are used
 */
+ (BOOL)ignoresAlpha;

/**
 * Sets whether alpha components should be ignored in color operations.
 * flag: YES to ignore alpha components, NO to use them
 */
+ (void)setIgnoresAlpha:(BOOL)flag;

//
// Retrieving a Set of Components
//

/**
 * Gets the CMYK components of the color.
 * cyan: Pointer to store the cyan component (0.0 to 1.0)
 * magenta: Pointer to store the magenta component (0.0 to 1.0)
 * yellow: Pointer to store the yellow component (0.0 to 1.0)
 * black: Pointer to store the black component (0.0 to 1.0)
 * alpha: Pointer to store the alpha component (0.0 to 1.0)
 */
- (void)getCyan:(CGFloat *)cyan
	magenta:(CGFloat *)magenta
	 yellow:(CGFloat *)yellow
	  black:(CGFloat *)black
	  alpha:(CGFloat *)alpha;

/**
 * Gets the HSB components of the color.
 * hue: Pointer to store the hue component (0.0 to 1.0)
 * saturation: Pointer to store the saturation component (0.0 to 1.0)
 * brightness: Pointer to store the brightness component (0.0 to 1.0)
 * alpha: Pointer to store the alpha component (0.0 to 1.0)
 */
- (void)getHue:(CGFloat *)hue
    saturation:(CGFloat *)saturation
    brightness:(CGFloat *)brightness
	 alpha:(CGFloat *)alpha;

/**
 * Gets the RGB components of the color.
 * red: Pointer to store the red component (0.0 to 1.0)
 * green: Pointer to store the green component (0.0 to 1.0)
 * blue: Pointer to store the blue component (0.0 to 1.0)
 * alpha: Pointer to store the alpha component (0.0 to 1.0)
 */
- (void)getRed:(CGFloat *)red
	 green:(CGFloat *)green
	  blue:(CGFloat *)blue
	 alpha:(CGFloat *)alpha;

/**
 * Gets the grayscale components of the color.
 * white: Pointer to store the grayscale value (0.0 to 1.0)
 * alpha: Pointer to store the alpha component (0.0 to 1.0)
 */
- (void)getWhite:(CGFloat *)white
	   alpha:(CGFloat *)alpha;

//
// Retrieving Individual Components
//

/**
 * Returns the alpha (transparency) component of the color.
 * Returns: The alpha component (0.0 to 1.0)
 */
- (CGFloat)alphaComponent;

/**
 * Returns the black component of the color in CMYK color space.
 * Returns: The black component (0.0 to 1.0)
 */
- (CGFloat)blackComponent;

/**
 * Returns the blue component of the color in RGB color space.
 * Returns: The blue component (0.0 to 1.0)
 */
- (CGFloat)blueComponent;

/**
 * Returns the brightness component of the color in HSB color space.
 * Returns: The brightness component (0.0 to 1.0)
 */
- (CGFloat)brightnessComponent;

/**
 * Returns the catalog name component of a catalog-based color.
 * Returns: The name of the color catalog, or nil if not a catalog color
 */
- (NSString *)catalogNameComponent;

/**
 * Returns the color name component of a catalog-based color.
 * Returns: The name of the color within the catalog, or nil if not a catalog color
 */
- (NSString *)colorNameComponent;

/**
 * Returns the cyan component of the color in CMYK color space.
 * Returns: The cyan component (0.0 to 1.0)
 */
- (CGFloat)cyanComponent;

/**
 * Returns the green component of the color in RGB color space.
 * Returns: The green component (0.0 to 1.0)
 */
- (CGFloat)greenComponent;

/**
 * Returns the hue component of the color in HSB color space.
 * Returns: The hue component (0.0 to 1.0)
 */
- (CGFloat)hueComponent;

/**
 * Returns the localized catalog name component of a catalog-based color.
 * Returns: The localized name of the color catalog, or nil if not a catalog color
 */
- (NSString *)localizedCatalogNameComponent;

/**
 * Returns the localized color name component of a catalog-based color.
 * Returns: The localized name of the color within the catalog, or nil if not a catalog color
 */
- (NSString *)localizedColorNameComponent;

/**
 * Returns the magenta component of the color in CMYK color space.
 * Returns: The magenta component (0.0 to 1.0)
 */
- (CGFloat)magentaComponent;

/**
 * Returns the red component of the color in RGB color space.
 * Returns: The red component (0.0 to 1.0)
 */
- (CGFloat)redComponent;

/**
 * Returns the saturation component of the color in HSB color space.
 * Returns: The saturation component (0.0 to 1.0)
 */
- (CGFloat)saturationComponent;

/**
 * Returns the white component of the color in grayscale color space.
 * Returns: The white component (0.0 to 1.0)
 */
- (CGFloat)whiteComponent;

/**
 * Returns the yellow component of the color in CMYK color space.
 * Returns: The yellow component (0.0 to 1.0)
 */
- (CGFloat)yellowComponent;

//
// Converting to Another Color Space
//

/**
 * Returns the name of the color space used by this color.
 * Returns: The color space name string
 */
- (NSString *)colorSpaceName;

/**
 * Returns a version of the color converted to the specified color space.
 * colorSpace: The target color space name
 * Returns: A new NSColor in the specified color space, or nil if conversion fails
 */
- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace;

/**
 * Returns a version of the color converted to the specified color space and device.
 * colorSpace: The target color space name
 * deviceDescription: Dictionary describing the target device characteristics
 * Returns: A new NSColor in the specified color space for the device, or nil if conversion fails
 */
- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace
			       device:(NSDictionary *)deviceDescription;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
// + (NSColor *)colorWithCIColor:(CIColor *)color;

/**
 * Creates a color with the specified color space and component values.
 * space: The NSColorSpace to use
 * comp: Array of component values
 * number: Number of components in the array
 * Returns: A new NSColor instance in the specified color space
 */
+ (NSColor *)colorWithColorSpace:(NSColorSpace *)space
                      components:(const CGFloat *)comp
                           count:(NSInteger)number;

/**
 * Returns the color space of this color.
 * Returns: The NSColorSpace used by this color
 */
- (NSColorSpace *)colorSpace;

/**
 * Returns a version of the color converted to the specified color space.
 * space: The target NSColorSpace
 * Returns: A new NSColor in the specified color space, or nil if conversion fails
 */
- (NSColor *)colorUsingColorSpace:(NSColorSpace *)space;

/**
 * Gets all component values of the color.
 * components: Array to store the component values
 */
- (void)getComponents:(CGFloat *)components;

/**
 * Returns the number of color components in this color.
 * Returns: The number of components (excluding alpha)
 */
- (NSInteger)numberOfComponents;
#endif

//
// Changing the Color
//

/**
 * Returns a color that is a blend between this color and another color.
 * fraction: The fraction of the other color to blend (0.0 to 1.0)
 * aColor: The color to blend with
 * Returns: A new NSColor representing the blended color
 */
- (NSColor *)blendedColorWithFraction:(CGFloat)fraction
			      ofColor:(NSColor *)aColor;

/**
 * Returns a version of the color with a different alpha component.
 * alpha: The new alpha value (0.0 to 1.0)
 * Returns: A new NSColor with the specified alpha component
 */
- (NSColor *)colorWithAlphaComponent:(CGFloat)alpha;

//
// Copying and Pasting
//

/**
 * Creates a color from color data on the pasteboard.
 * pasteBoard: The pasteboard to read color data from
 * Returns: A new NSColor from the pasteboard data, or nil if no valid color data
 */
+ (NSColor *)colorFromPasteboard:(NSPasteboard *)pasteBoard;

/**
 * Writes color data to the specified pasteboard.
 * pasteBoard: The pasteboard to write the color data to
 */
- (void)writeToPasteboard:(NSPasteboard *)pasteBoard;

//
// Drawing
//

/**
 * Draws a color swatch in the specified rectangle.
 * rect: The rectangle to draw the color swatch in
 */
- (void)drawSwatchInRect:(NSRect)rect;

/**
 * Sets the color as both the fill and stroke color in the current graphics context.
 */
- (void)set;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Sets the color as the fill color in the current graphics context.
 */
- (void)setFill;

/**
 * Sets the color as the stroke color in the current graphics context.
 */
- (void)setStroke;
#endif

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
//
// Changing the color
//

/**
 * Returns a highlighted version of the color.
 * level: The highlight level (0.0 for no change, 1.0 for maximum highlight)
 * Returns: A new NSColor representing the highlighted color
 */
- (NSColor*) highlightWithLevel: (CGFloat)level;

/**
 * Returns a shadowed version of the color.
 * level: The shadow level (0.0 for no change, 1.0 for maximum shadow)
 * Returns: A new NSColor representing the shadowed color
 */
- (NSColor*) shadowWithLevel: (CGFloat)level;

/**
 * Creates a pattern color using the specified image.
 * image: The image to use as the pattern
 * Returns: A new NSColor that draws the image as a repeating pattern
 */
+ (NSColor*)colorWithPatternImage:(NSImage*)image;

/**
 * Returns the color appropriate for the specified control tint.
 * controlTint: The control tint (blue, graphite, etc.)
 * Returns: An NSColor matching the control tint preference
 */
+ (NSColor*)colorForControlTint:(NSControlTint)controlTint;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Returns the current control tint preference.
 * Returns: The NSControlTint value representing the user's preference
 */
+ (NSControlTint)currentControlTint;
#endif

//
// System colors stuff.
//
#if OS_API_VERSION(MAC_OS_X_VERSION_10_2, GS_API_LATEST)
/**
 * Returns the alternate selected control color for alternating row backgrounds.
 * Returns: An NSColor for alternate selection highlighting
 */
+ (NSColor*) alternateSelectedControlColor;

/**
 * Returns the text color for alternate selected controls.
 * Returns: An NSColor for text in alternate selected controls
 */
+ (NSColor*) alternateSelectedControlTextColor;
#endif

/**
 * Returns the background color for controls.
 * Returns: An NSColor for control backgrounds
 */
+ (NSColor*) controlBackgroundColor;

/**
 * Returns the standard control color.
 * Returns: An NSColor for standard control appearance
 */
+ (NSColor*) controlColor;

/**
 * Returns the highlight color for controls.
 * Returns: An NSColor for control highlighting
 */
+ (NSColor*) controlHighlightColor;

/**
 * Returns the light highlight color for controls.
 * Returns: An NSColor for light control highlighting
 */
+ (NSColor*) controlLightHighlightColor;

/**
 * Returns the shadow color for controls.
 * Returns: An NSColor for control shadows
 */
+ (NSColor*) controlShadowColor;

/**
 * Returns the dark shadow color for controls.
 * Returns: An NSColor for dark control shadows
 */
+ (NSColor*) controlDarkShadowColor;

/**
 * Returns the text color for controls.
 * Returns: An NSColor for control text
 */
+ (NSColor*) controlTextColor;

/**
 * Returns the text color for disabled controls.
 * Returns: An NSColor for disabled control text
 */
+ (NSColor*) disabledControlTextColor;

/**
 * Returns the color for grid lines.
 * Returns: An NSColor for drawing grid lines
 */
+ (NSColor*) gridColor;

/**
 * Returns the color for header backgrounds.
 * Returns: An NSColor for header backgrounds
 */
+ (NSColor*) headerColor;

/**
 * Returns the text color for headers.
 * Returns: An NSColor for header text
 */
+ (NSColor*) headerTextColor;

/**
 * Returns the general highlight color.
 * Returns: An NSColor for general highlighting
 */
+ (NSColor*) highlightColor;

/**
 * Returns the keyboard focus indicator color.
 * Returns: An NSColor for keyboard focus indicators
 */
+ (NSColor*) keyboardFocusIndicatorColor;

/**
 * Returns the color for control knobs.
 * Returns: An NSColor for control knobs (sliders, etc.)
 */
+ (NSColor*) knobColor;

/**
 * Returns the color for scroll bars.
 * Returns: An NSColor for scroll bar backgrounds
 */
+ (NSColor*) scrollBarColor;

/**
 * Returns the secondary selected control color.
 * Returns: An NSColor for secondary selection highlighting
 */
+ (NSColor*) secondarySelectedControlColor;

/**
 * Returns the selected control color.
 * Returns: An NSColor for selected control backgrounds
 */
+ (NSColor*) selectedControlColor;

/**
 * Returns the text color for selected controls.
 * Returns: An NSColor for text in selected controls
 */
+ (NSColor*) selectedControlTextColor;

/**
 * Returns the color for selected knobs.
 * Returns: An NSColor for selected control knobs
 */
+ (NSColor*) selectedKnobColor;

/**
 * Returns the background color for selected menu items.
 * Returns: An NSColor for selected menu item backgrounds
 */
+ (NSColor*) selectedMenuItemColor;

/**
 * Returns the text color for selected menu items.
 * Returns: An NSColor for text in selected menu items
 */
+ (NSColor*) selectedMenuItemTextColor;

/**
 * Returns the background color for selected text.
 * Returns: An NSColor for selected text backgrounds
 */
+ (NSColor*) selectedTextBackgroundColor;

/**
 * Returns the color for selected text.
 * Returns: An NSColor for selected text
 */
+ (NSColor*) selectedTextColor;

/**
 * Returns the general shadow color.
 * Returns: An NSColor for general shadows
 */
+ (NSColor*) shadowColor;

/**
 * Returns the background color for text areas.
 * Returns: An NSColor for text field backgrounds
 */
+ (NSColor*) textBackgroundColor;

/**
 * Returns the standard text color.
 * Returns: An NSColor for standard text
 */
+ (NSColor*) textColor;

/**
 * Returns the background color for windows.
 * Returns: An NSColor for window backgrounds
 */
+ (NSColor*) windowBackgroundColor;

/**
 * Returns the color for window frames.
 * Returns: An NSColor for window frame borders
 */
+ (NSColor*) windowFrameColor;

/**
 * Returns the text color for window frames.
 * Returns: An NSColor for text in window frames (titles, etc.)
 */
+ (NSColor*) windowFrameTextColor;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)
+ (NSColor*) labelColor;
+ (NSColor*) secondaryLabelColor;
+ (NSColor*) tertiaryLabelColor;
+ (NSColor*) quaternaryLabelColor;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
+ (NSArray*) controlAlternatingRowBackgroundColors;
#endif

// Pattern colour
- (NSImage*) patternImage;

// Tooltip colours
+ (NSColor*) toolTipColor;
+ (NSColor*) toolTipTextColor;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_7, GS_API_LATEST)
+ (NSColor *)colorWithSRGBRed:(CGFloat)red
                        green:(CGFloat)green
                         blue:(CGFloat)blue
                        alpha:(CGFloat)alpha;
+ (NSColor *)colorWithGenericGamma22White:(CGFloat)white
                                    alpha:(CGFloat)alpha;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_9, GS_API_LATEST)
+ (NSColor *)colorWithRed:(CGFloat)red
                    green:(CGFloat)green
                     blue:(CGFloat)blue
                    alpha:(CGFloat)alpha;
+ (NSColor *)colorWithHue:(CGFloat)hue
               saturation:(CGFloat)saturation
               brightness:(CGFloat)brightness
                    alpha:(CGFloat)alpha;
+ (NSColor *)colorWithWhite:(CGFloat)white
                      alpha:(CGFloat)alpha;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)
+ (NSColor *)systemBlueColor;
+ (NSColor *)systemBrownColor;
+ (NSColor *)systemGrayColor;
+ (NSColor *)systemGreenColor;
+ (NSColor *)systemOrangeColor;
+ (NSColor *)systemPinkColor;
+ (NSColor *)systemPurpleColor;
+ (NSColor *)systemRedColor;
+ (NSColor *)systemYellowColor;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)
+ (NSColor *)colorWithDisplayP3Red:(CGFloat)red
                             green:(CGFloat)green
                              blue:(CGFloat)blue
                             alpha:(CGFloat)alpha;
+ (NSColor *)colorWithColorSpace:(NSColorSpace *)space
                             hue:(CGFloat)hue
                      saturation:(CGFloat)saturation
                      brightness:(CGFloat)brightness
                           alpha:(CGFloat)alpha;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_13, GS_API_LATEST)
- (NSColor *)colorUsingType:(NSColorType)type;
- (NSColorType)type;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_14, GS_API_LATEST)
- (NSColor *)colorWithSystemEffect:(NSColorSystemEffect)systemEffect;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST)
+ (NSColor *)systemIndigoColor;
+ (NSColor *)systemTealColor;
#endif

#endif

@end

APPKIT_EXPORT NSString	*NSSystemColorsDidChangeNotification;

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
@interface NSCoder (NSCoderAdditions)

//
// Converting an Archived NXColor to an NSColor
//
- (NSColor *)decodeNXColor;

@end
#endif

typedef struct CGColor *CGColorRef;
@interface NSColor (GSQuartz)
#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
- (CGColorRef)CGColor;
#endif
@end

#endif // _GNUstep_H_NSColor
