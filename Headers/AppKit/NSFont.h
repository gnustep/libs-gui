/*
   NSFont.h

   The font class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996, 1997

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

#ifndef _GNUstep_H_NSFont
#define _GNUstep_H_NSFont
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
// For NSControlSize
#import <AppKit/NSColor.h>

@class NSAffineTransform;
@class NSCharacterSet;
@class NSDictionary;
@class NSFontDescriptor;
@class NSGraphicsContext;

typedef unsigned int NSGlyph;

/**
 * Special glyph constants for control and attachment handling.
 * These values represent special cases in text layout systems.
 */
enum {
  /** Represents control characters that don't have visible glyphs */
  NSControlGlyph = 0x00ffffff,
  /** GNUstep extension for text attachment glyphs */
  GSAttachmentGlyph = 0x00fffffe,
  /** Represents the absence of a glyph */
  NSNullGlyph = 0x0
};

/**
 * Defines the spatial relationship between glyphs in composite characters.
 * Used for positioning diacritical marks and other combining characters.
 */
typedef enum _NSGlyphRelation {
  /** The glyph should be positioned below the base glyph */
  NSGlyphBelow,
  /** The glyph should be positioned above the base glyph */
  NSGlyphAbove,
} NSGlyphRelation;

/**
 * Specifies how multibyte character encodings are packed into glyph arrays.
 * Different packing schemes optimize storage for various character sets.
 */
typedef enum _NSMultibyteGlyphPacking {
  /** Each glyph uses one byte (ASCII, Latin-1) */
  NSOneByteGlyphPacking,
  /** Japanese EUC encoding scheme */
  NSJapaneseEUCGlyphPacking,
  /** ASCII with double-byte EUC for non-ASCII characters */
  NSAsciiWithDoubleByteEUCGlyphPacking,
  /** Each glyph uses two bytes (Unicode BMP) */
  NSTwoByteGlyphPacking,
  /** Each glyph uses four bytes (full Unicode) */
  NSFourByteGlyphPacking
} NSMultibyteGlyphPacking;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Specifies different rendering modes for font display.
 * These modes control how fonts are rasterized and displayed on screen.
 */
typedef enum _NSFontRenderingMode
{
  /** Use the system default rendering mode based on font size and system settings */
  NSFontDefaultRenderingMode = 0,
  /** Force antialiased (smooth) rendering regardless of font size */
  NSFontAntialiasedRenderingMode,
  /** Use integer pixel advancements for precise character positioning */
  NSFontIntegerAdvancementsRenderingMode,
  /** Combine antialiasing with integer advancements for best quality and positioning */
  NSFontAntialiasedIntegerAdvancementsRenderingMode
} NSFontRenderingMode;
#endif

APPKIT_EXPORT const CGFloat NSFontIdentityMatrix[6];

/**
 * NSFont encapsulates all the information needed to render text with a specific
 * typeface, size, and style. It provides comprehensive font creation, measurement,
 * and glyph manipulation capabilities for text layout and rendering systems.
 *
 * The font system supports both screen and printer fonts, with automatic
 * conversion between them. Fonts can be created by name and size, or through
 * more advanced methods using font descriptors and transformation matrices.
 *
 * NSFont provides extensive metrics information including ascender, descender,
 * line height, character advancement, and glyph bounding rectangles. It also
 * supports advanced typography features like composite glyph positioning and
 * multi-byte character encoding schemes.
 *
 * The class integrates with the broader text system through glyph manipulation
 * methods that support complex text layout, international text rendering,
 * and precise typographic control needed for high-quality document formatting.
 */
APPKIT_EXPORT_CLASS
@interface NSFont : NSObject <NSCoding, NSCopying>
{
  NSString *fontName;
  CGFloat matrix[6];
  BOOL matrixExplicitlySet; // unused
  BOOL screenFont;

  id fontInfo;
  void *_fontRef;

  /*
  If this font was created with a specific "role", like user font, or
  message font, and not a specific postscript name, the role will be
  stored here.
  */
  int role;

  /*
  For printer fonts, this is a cache of the corresponding screen font.
  It is initialized to placeHolder, and is created for real on demand in
  -screenFont (and retained). For screen fonts, it's nil.
  */
  NSFont *cachedScreenFont;

  /*
  In the GNUstep implementation, fonts may encapsulate some rendering state
  relating to view flipped state, therefore we generate a separate font for
  this case.  We don't create it by default, unless -set is called in a
  flipped context.
  */
  NSFont *cachedFlippedFont;
}

//
// Creating a Font Object
//

/**
 * Returns the bold system font at the specified size.
 * The bold system font is used for emphasis in user interface elements
 * and provides consistent bold text appearance across the system.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default system size.
 * Returns a bold variant of the system font at the specified size.
 */
+ (NSFont*) boldSystemFontOfSize: (CGFloat)fontSize;

/**
 * Creates a font with the specified PostScript name and transformation matrix.
 * This method provides the most control over font creation, allowing custom
 * transformation matrices for scaling, rotation, and skewing effects.
 * The aFontName parameter should contain the PostScript name of the font
 * (e.g., "Helvetica-Bold"). The fontMatrix parameter should be a 6-element
 * transformation matrix [a b c d tx ty] for font transformation.
 * Returns a font object with the specified name and transformation, or nil
 * if the font cannot be created.
 */
+ (NSFont*) fontWithName: (NSString*)aFontName
		  matrix: (const CGFloat*)fontMatrix;

/**
 * Creates a font with the specified PostScript name and size.
 * This is the most commonly used font creation method for standard text rendering.
 * The aFontName parameter should contain the PostScript name of the font
 * (e.g., "Times-Roman", "Helvetica"). The fontSize parameter specifies
 * the desired font size in points.
 * Returns a font object with the specified name and size, or nil if the
 * font cannot be created.
 */
+ (NSFont*) fontWithName: (NSString*)aFontName
		    size: (CGFloat)fontSize;

/**
 * Returns the standard system font at the specified size.
 * The system font is the default font used for user interface text throughout
 * the system and provides optimal readability for interface elements.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default system size.
 * Returns the system font at the specified size.
 */
+ (NSFont*) systemFontOfSize: (CGFloat)fontSize;

/**
 * Returns the user's preferred fixed-pitch font at the specified size.
 * Fixed-pitch fonts are essential for code editing, terminal applications,
 * and any context where character alignment is important.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the user's preferred fixed-pitch font at the specified size.
 */
+ (NSFont*) userFixedPitchFontOfSize: (CGFloat)fontSize;

/**
 * Returns the user's preferred proportional font at the specified size.
 * This font reflects the user's personal preference for general text display
 * and reading, providing a personalized text experience.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the user's preferred proportional font at the specified size.
 */
+ (NSFont*) userFontOfSize: (CGFloat)fontSize;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the font used in window title bars.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard title bar font at the specified size.
 */
+ (NSFont*) titleBarFontOfSize: (CGFloat)fontSize;

/**
 * Returns the font used in menus.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard menu font at the specified size.
 */
+ (NSFont*) menuFontOfSize: (CGFloat)fontSize;

/**
 * Returns the font used for message text in alerts and dialogs.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard message font at the specified size.
 */
+ (NSFont*) messageFontOfSize: (CGFloat)fontSize;

/**
 * Returns the font used in palette windows and tool palettes.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard palette font at the specified size.
 */
+ (NSFont*) paletteFontOfSize: (CGFloat)fontSize;

/**
 * Returns the font used for tooltip text.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard tooltip font at the specified size.
 */
+ (NSFont*) toolTipsFontOfSize: (CGFloat)fontSize;

/**
 * Returns the font used for control content (button titles, text field content).
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard control content font at the specified size.
 */
+ (NSFont*) controlContentFontOfSize: (CGFloat)fontSize;

/**
 * Returns the font used for labels and non-editable text.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard label font at the specified size.
 */
+ (NSFont*) labelFontOfSize: (CGFloat)fontSize;

/**
 * Returns the font used in the menu bar.
 * The fontSize parameter specifies the desired font size in points.
 * Use 0.0 for the default size.
 * Returns the standard menu bar font at the specified size.
 */
+ (NSFont*) menuBarFontOfSize: (CGFloat)fontSize;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Creates a font using a font descriptor and size.
 * Font descriptors provide a more flexible way to specify font characteristics
 * including family, weight, traits, and other attributes.
 * The descriptor parameter specifies the desired font characteristics.
 * The size parameter sets the font size in points.
 * Returns a font matching the descriptor at the specified size.
 */
+ (NSFont*) fontWithDescriptor: (NSFontDescriptor*)descriptor size: (CGFloat)size;

/**
 * Creates a font using a font descriptor and transformation matrix.
 * This method combines descriptor-based font selection with custom transformations.
 * The descriptor parameter specifies the desired font characteristics.
 * The transform parameter specifies the transformation to apply to the font.
 * Returns a font matching the descriptor with the specified transformation applied.
 */
+ (NSFont*) fontWithDescriptor: (NSFontDescriptor*)descriptor
                 textTransform: (NSAffineTransform*)transform;

// This method was a mistake in the 10.4 documentation
/**
 * Creates a font using a font descriptor, size, and transformation matrix.
 * This method provides the most comprehensive font creation capabilities,
 * combining descriptor-based selection with size and transformation control.
 *
 * @param descriptor The font descriptor specifying the desired font characteristics.
 * @param size The font size in points.
 * @param transform The transformation to apply to the font.
 * @return A font matching the descriptor at the specified size with transformation applied.
 */
+ (NSFont*) fontWithDescriptor: (NSFontDescriptor*)descriptor
                          size: (CGFloat)size
                 textTransform: (NSAffineTransform*)transform;
#endif

//
// Font Sizes
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the standard font size for labels.
 * Returns the standard label font size in points.
 */
+ (CGFloat) labelFontSize;

/**
 * Returns the standard small system font size.
 * Returns the standard small system font size in points.
 */
+ (CGFloat) smallSystemFontSize;

/**
 * Returns the standard system font size.
 * Returns the standard system font size in points.
 */
+ (CGFloat) systemFontSize;

/**
 * Returns the appropriate system font size for the given control size.
 * This method provides the correct font size for different control sizes
 * (regular, small, mini) to maintain visual consistency.
 * The controlSize parameter specifies the control size (NSRegularControlSize,
 * NSSmallControlSize, NSMiniControlSize).
 * Returns the appropriate font size for the specified control size.
 */
+ (CGFloat) systemFontSizeForControlSize: (NSControlSize)controlSize;
#endif

//
// Preferred Fonts
//

/**
 * Returns the list of preferred font names.
 * The preferred fonts list determines the fallback order when a requested
 * font is not available on the system.
 * Returns an array of NSString objects containing preferred font names.
 */
+ (NSArray*) preferredFontNames;

/**
 * Sets the list of preferred font names.
 * This establishes the fallback order for font selection when requested
 * fonts are not available.
 * The fontNames parameter should contain an array of NSString objects
 * with preferred font names.
 */
+ (void) setPreferredFontNames: (NSArray*)fontNames;

//
// Setting the Font
//

/**
 * Sets the user's preferred fixed-pitch font.
 * This establishes the default fixed-pitch font that will be returned
 * by userFixedPitchFontOfSize: for subsequent requests.
 *
 * @param aFont The font to set as the user's preferred fixed-pitch font.
 */
+ (void) setUserFixedPitchFont: (NSFont*)aFont;

/**
 * Sets the user's preferred proportional font.
 * This establishes the default proportional font that will be returned
 * by userFontOfSize: for subsequent requests.
 *
 * @param aFont The font to set as the user's preferred proportional font.
 */
+ (void) setUserFont: (NSFont*)aFont;

/**
 * Sets the font for subsequent text drawing operations by name.
 * This is a legacy method that establishes a font for text operations
 * by PostScript name.
 *
 * @param aFontName The PostScript name of the font to use for text operations.
 */
+ (void) useFont: (NSString*)aFontName;

/**
 * Sets this font as the current font for text drawing in the current graphics context.
 * This method establishes the font for subsequent text rendering operations,
 * taking into account the coordinate system and rendering context.
 */
- (void) set;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Sets this font as the current font in the specified graphics context.
 * This method provides more control by allowing the font to be set in a
 * specific graphics context rather than the current one.
 *
 * @param context The graphics context in which to set this font.
 */
- (void) setInContext: (NSGraphicsContext*)context;

/**
 * Returns the text transformation matrix for this font.
 * The transformation matrix defines scaling, rotation, and skewing
 * applied to the font's glyphs during rendering.
 *
 * @return The NSAffineTransform representing the font's text transformation.
 */
- (NSAffineTransform*) textTransform;
#endif

//
// Querying the Font
//
- (NSDictionary*) afmDictionary;
- (NSString*) afmFileContents;
- (NSRect) boundingRectForFont;
- (NSString*) displayName;
- (NSString*) familyName;
- (NSString*) fontName;
- (NSString*) encodingScheme;
- (BOOL) isFixedPitch;
- (BOOL) isBaseFont;
- (const CGFloat*) matrix;
- (CGFloat) pointSize;
- (NSFont*) printerFont;
- (NSFont*) screenFont;
- (CGFloat) ascender;
- (CGFloat) descender;
- (CGFloat) capHeight;
- (CGFloat) italicAngle;
- (NSSize) maximumAdvancement;
- (NSSize) minimumAdvancement;
- (CGFloat) underlinePosition;
- (CGFloat) underlineThickness;
- (CGFloat) xHeight;
- (CGFloat) widthOfString: (NSString*)string;
- (CGFloat) defaultLineHeightForFont;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (CGFloat) leading;

#endif

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (NSUInteger) numberOfGlyphs;
- (NSCharacterSet*) coveredCharacterSet;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (NSFontDescriptor*) fontDescriptor;
- (NSFontRenderingMode) renderingMode;
- (NSFont*) screenFontWithRenderingMode: (NSFontRenderingMode)mode;
#endif

//
// Manipulating Glyphs
//
- (NSSize) advancementForGlyph: (NSGlyph)aGlyph;
- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph;
- (BOOL) glyphIsEncoded: (NSGlyph)aGlyph;
- (NSMultibyteGlyphPacking) glyphPacking;
- (NSGlyph) glyphWithName: (NSString*)glyphName;
- (NSPoint) positionOfGlyph: (NSGlyph)curGlyph
	    precededByGlyph: (NSGlyph)prevGlyph
		  isNominal: (BOOL*)nominal;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
	       forCharacter: (unichar)aChar
	     struckOverRect: (NSRect)aRect;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
	    struckOverGlyph: (NSGlyph)baseGlyph
	metricsExist: (BOOL*)flag;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
             struckOverRect: (NSRect)aRect
               metricsExist: (BOOL*)flag;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
               withRelation: (NSGlyphRelation)relation
                toBaseGlyph: (NSGlyph)baseGlyph
           totalAdvancement: (NSSize*)offset
               metricsExist: (BOOL*)flag;
- (int) positionsForCompositeSequence: (NSGlyph*)glyphs
                       numberOfGlyphs: (int)numGlyphs
                           pointArray: (NSPoint*)points;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (void) getAdvancements: (NSSizeArray)advancements
               forGlyphs: (const NSGlyph*)glyphs
                   count: (NSUInteger)count;
- (void) getAdvancements: (NSSizeArray)advancements
         forPackedGlyphs: (const void*)glyphs
                   count: (NSUInteger)count;
- (void) getBoundingRects: (NSRectArray)bounds
                forGlyphs: (const NSGlyph*)glyphs
                    count: (NSUInteger)count;
#endif

- (NSStringEncoding) mostCompatibleStringEncoding;

@end

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
@class GSFontInfo;

@interface NSFont (GNUstep)
- (GSFontInfo*) fontInfo;
- (void *) fontRef;
@end

int NSConvertGlyphsToPackedGlyphs(NSGlyph*glBuf,
				  int count,
				  NSMultibyteGlyphPacking packing,
				  char*packedGlyphs);
#endif

APPKIT_EXPORT NSString *NSAFMAscender;
APPKIT_EXPORT NSString *NSAFMCapHeight;
APPKIT_EXPORT NSString *NSAFMCharacterSet;
APPKIT_EXPORT NSString *NSAFMDescender;
APPKIT_EXPORT NSString *NSAFMEncodingScheme;
APPKIT_EXPORT NSString *NSAFMFamilyName;
APPKIT_EXPORT NSString *NSAFMFontName;
APPKIT_EXPORT NSString *NSAFMFormatVersion;
APPKIT_EXPORT NSString *NSAFMFullName;
APPKIT_EXPORT NSString *NSAFMItalicAngle;
APPKIT_EXPORT NSString *NSAFMMappingScheme;
APPKIT_EXPORT NSString *NSAFMNotice;
APPKIT_EXPORT NSString *NSAFMUnderlinePosition;
APPKIT_EXPORT NSString *NSAFMUnderlineThickness;
APPKIT_EXPORT NSString *NSAFMVersion;
APPKIT_EXPORT NSString *NSAFMWeight;
APPKIT_EXPORT NSString *NSAFMXHeight;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
typedef CGFloat NSFontWeight;
APPKIT_EXPORT const CGFloat NSFontWeightUltraLight;
APPKIT_EXPORT const CGFloat NSFontWeightThin;
APPKIT_EXPORT const CGFloat NSFontWeightLight;
APPKIT_EXPORT const CGFloat NSFontWeightRegular;
APPKIT_EXPORT const CGFloat NSFontWeightMedium;
APPKIT_EXPORT const CGFloat NSFontWeightSemibold;
APPKIT_EXPORT const CGFloat NSFontWeightBold;
APPKIT_EXPORT const CGFloat NSFontWeightHeavy;
APPKIT_EXPORT const CGFloat NSFontWeightBlack;
#endif

#endif // _GNUstep_H_NSFont
