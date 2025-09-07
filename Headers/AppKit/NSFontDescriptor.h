/*
   NSFontDescriptor.h

   Describes font characteristics and attributes for font matching

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: 2006

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


#ifndef _GNUstep_H_NSFontDescriptor
#define _GNUstep_H_NSFontDescriptor
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)

@class NSArray;
@class NSCoder;
@class NSDictionary;
@class NSSet;
@class NSString;
@class NSAffineTransform;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Type for font symbolic traits.
 * Symbolic traits are a bitmask that describes various characteristics
 * of a font's design, such as whether it's bold, italic, condensed, or
 * has other stylistic properties.
 */
typedef uint32_t NSFontSymbolicTraits;

/**
 * Font family classification system.
 * These values categorize fonts by their design characteristics and
 * historical typographic classifications, helping to group fonts with
 * similar visual styles and intended uses.
 */
typedef enum _NSFontFamilyClass
{
  /** Font family classification is unknown or unspecified */
  NSFontUnknownClass = 0 << 28,
  /** Old style serif fonts with angled stress and bracketed serifs */
  NSFontOldStyleSerifsClass = 1U << 28,
  /** Transitional serif fonts blending old style and modern characteristics */
  NSFontTransitionalSerifsClass = 2U << 28,
  /** Modern serif fonts with vertical stress and thin, unbracketed serifs */
  NSFontModernSerifsClass = 3U << 28,
  /** Clarendon serif fonts with thick, bracketed serifs */
  NSFontClarendonSerifsClass = 4U << 28,
  /** Slab serif fonts with thick, unbracketed serifs */
  NSFontSlabSerifsClass = 5U << 28,
  /** Freeform serif fonts with creative or unusual serif designs */
  NSFontFreeformSerifsClass = 7U << 28,
  /** Sans serif fonts without serifs */
  NSFontSansSerifClass = 8U << 28,
  /** Ornamental fonts with decorative characteristics */
  NSFontOrnamentalsClass = 9U << 28,
  /** Script fonts that resemble handwriting or calligraphy */
  NSFontScriptsClass = 10U << 28,
  /** Symbolic fonts containing symbols, icons, or special characters */
  NSFontSymbolicClass = 12U << 28
} NSFontFamilyClass;

/**
 * Mask for extracting font family class information.
 * This mask isolates the family class bits from other font classification data.
 */
enum _NSFontFamilyClassMask {
    NSFontFamilyClassMask = 0xF0000000
};

/**
 * Font trait flags for describing font characteristics.
 * These flags can be combined to describe multiple aspects of a font's
 * design and intended usage patterns.
 */
enum _NSFontTrait
{
  /** Font has italic or oblique styling */
  NSFontItalicTrait = 0x0001,
  /** Font has bold or heavy weight */
  NSFontBoldTrait = 0x0002,
  /** Font has expanded or extended width */
  NSFontExpandedTrait = 0x0020,
  /** Font has condensed or compressed width */
  NSFontCondensedTrait = 0x0040,
  /** Font has monospace (fixed-width) character spacing */
  NSFontMonoSpaceTrait = 0x0400,
  /** Font is designed for vertical text layout */
  NSFontVerticalTrait = 0x0800,
  /** Font is optimized for user interface rendering */
  NSFontUIOptimizedTrait = 0x1000
};

#endif

/**
 * Font attribute key for the font family name.
 * The value is an NSString containing the font family name such as
 * "Helvetica" or "Times". This is the primary identifier for grouping
 * related fonts with different weights and styles.
 */
APPKIT_EXPORT NSString *NSFontFamilyAttribute;

/**
 * Font attribute key for the font face name.
 * The value is an NSString containing the specific font face name
 * such as "Bold", "Italic", or "Regular". This distinguishes between
 * different variants within the same font family.
 */
APPKIT_EXPORT NSString *NSFontNameAttribute;

/**
 * Font attribute key for the font face variant.
 * The value is an NSString specifying the style variant of the font
 * within its family, providing additional granularity beyond the name.
 */
APPKIT_EXPORT NSString *NSFontFaceAttribute;

/**
 * Font attribute key for the font point size.
 * The value is an NSNumber containing the font size in points.
 * This determines the visual size of the font when rendered.
 */
APPKIT_EXPORT NSString *NSFontSizeAttribute;

/**
 * Font attribute key for the visible font name.
 * The value is an NSString containing the font name as it should
 * appear in user interface elements like font panels and menus.
 */
APPKIT_EXPORT NSString *NSFontVisibleNameAttribute;

/**
 * Font attribute key for font color information.
 * The value is an NSColor object specifying the default color
 * for text rendered with this font descriptor.
 */
APPKIT_EXPORT NSString *NSFontColorAttribute;

/**
 * Font attribute key for matrix transformations.
 * The value is an NSAffineTransform that defines geometric
 * transformations to apply to the font, such as skewing or scaling.
 */
APPKIT_EXPORT NSString *NSFontMatrixAttribute;

/**
 * Font attribute key for character variation settings.
 * The value is an NSNumber containing axis variation values
 * for variable fonts that support multiple design axes.
 */
APPKIT_EXPORT NSString *NSFontVariationAttribute;

/**
 * Font attribute key for character set coverage.
 * The value is an NSCharacterSet indicating which Unicode
 * characters are available in this font.
 */
APPKIT_EXPORT NSString *NSFontCharacterSetAttribute;

/**
 * Font attribute key for cascading font list.
 * The value is an NSArray of additional fonts to use when
 * the primary font doesn't contain needed characters.
 */
APPKIT_EXPORT NSString *NSFontCascadeListAttribute;

/**
 * Font attribute key for font symbolic traits.
 * The value is an NSNumber containing NSFontSymbolicTraits
 * flags that describe the font's design characteristics.
 */
APPKIT_EXPORT NSString *NSFontTraitsAttribute;

/**
 * Font attribute key for fixed advance glyph spacing.
 * The value is an NSNumber specifying a fixed advance width
 * to use for all glyphs, creating monospaced behavior.
 */
APPKIT_EXPORT NSString *NSFontFixedAdvanceAttribute;

/**
 * Dictionary key for font symbolic traits within the traits attribute.
 * The value is an NSNumber containing NSFontSymbolicTraits flags
 * that describe characteristics like bold, italic, condensed, etc.
 */
APPKIT_EXPORT NSString *NSFontSymbolicTrait;

/**
 * Dictionary key for font weight within the traits attribute.
 * The value is an NSNumber representing the weight of the font
 * on a scale where normal weight is typically 0.0.
 */
APPKIT_EXPORT NSString *NSFontWeightTrait;

/**
 * Dictionary key for font width within the traits attribute.
 * The value is an NSNumber representing the width of the font
 * where 0.0 is normal width, negative values are condensed,
 * and positive values are expanded.
 */
APPKIT_EXPORT NSString *NSFontWidthTrait;

/**
 * Dictionary key for font slant within the traits attribute.
 * The value is an NSNumber representing the slant angle
 * where 0.0 is upright and positive values indicate italic slant.
 */
APPKIT_EXPORT NSString *NSFontSlantTrait;

/**
 * Dictionary key for variation axis identifier.
 * The value is an NSString containing the four-character tag
 * that identifies the variation axis in variable fonts.
 */
APPKIT_EXPORT NSString *NSFontVariationAxisIdentifierKey;

/**
 * Dictionary key for variation axis minimum value.
 * The value is an NSNumber specifying the minimum allowed
 * value for this variation axis.
 */
APPKIT_EXPORT NSString *NSFontVariationAxisMinimumValueKey;

/**
 * Dictionary key for variation axis maximum value.
 * The value is an NSNumber specifying the maximum allowed
 * value for this variation axis.
 */
APPKIT_EXPORT NSString *NSFontVariationAxisMaximumValueKey;

/**
 * Dictionary key for variation axis default value.
 * The value is an NSNumber specifying the default value
 * for this variation axis when no specific value is set.
 */
APPKIT_EXPORT NSString *NSFontVariationAxisDefaultValueKey;

/**
 * Dictionary key for variation axis display name.
 * The value is an NSString containing the human-readable
 * name for this variation axis for display in user interfaces.
 */
APPKIT_EXPORT NSString *NSFontVariationAxisNameKey;

/**
 * NSFontDescriptor provides a flexible way to describe fonts using
 * attribute dictionaries rather than specific font instances. This class
 * serves as an intermediate representation that can be used to create
 * fonts with specific characteristics or to find fonts that match
 * certain criteria.
 *
 * Font descriptors are particularly useful for:
 * - Font matching and substitution when exact fonts aren't available
 * - Describing fonts in a platform-independent way
 * - Creating variations of existing fonts with modified attributes
 * - Serializing font information for storage or transmission
 * - Implementing font panels and font selection interfaces
 *
 * The descriptor system uses attribute dictionaries where keys are
 * NSString constants (like NSFontFamilyAttribute) and values are
 * appropriate objects (NSString for names, NSNumber for sizes, etc.).
 * This provides flexibility while maintaining type safety.
 *
 * Font descriptors work closely with NSFont for font creation and with
 * NSFontCollection for organizing and managing groups of related fonts.
 * They also integrate with the font panel system for user font selection.
 */
APPKIT_EXPORT_CLASS
@interface NSFontDescriptor : NSObject <NSCoding, NSCopying>
{
  NSDictionary *_attributes;
}

/**
 * Creates a font descriptor from a dictionary of font attributes.
 * The attributes dictionary contains key-value pairs that describe
 * the desired font characteristics using standard font attribute keys
 * like NSFontFamilyAttribute, NSFontSizeAttribute, and NSFontTraitsAttribute.
 * Returns a new font descriptor that encapsulates these attributes,
 * or nil if the attributes dictionary is invalid.
 */
+ (id) fontDescriptorWithFontAttributes: (NSDictionary *)attributes;

/**
 * Creates a font descriptor with a specific font family name and point size.
 * The name parameter specifies the font family (such as "Helvetica" or "Times")
 * and the size parameter specifies the font size in points. This is a
 * convenience method for creating descriptors with the most commonly needed
 * attributes. Returns a new font descriptor with the specified family and size.
 */
+ (id) fontDescriptorWithName: (NSString *)name
                         size: (CGFloat)size;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Creates a font descriptor with a specific font name and transformation matrix.
 * The name parameter specifies the font family name and the matrix parameter
 * provides an affine transformation to apply to the font, allowing for effects
 * like scaling, rotation, or skewing. Returns a new font descriptor that
 * combines the font name with the geometric transformation.
 */
+ (id) fontDescriptorWithName: (NSString *)name
                       matrix: (NSAffineTransform *)matrix;
#endif

/**
 * Returns the complete attribute dictionary for this font descriptor.
 * The returned dictionary contains all the font attributes that define
 * this descriptor, using standard attribute keys like NSFontFamilyAttribute
 * and NSFontSizeAttribute. This provides access to all font characteristics
 * in a single collection for inspection or serialization.
 */
- (NSDictionary *) fontAttributes;

/**
 * Initializes a font descriptor with the specified font attributes dictionary.
 * The attributes dictionary should contain key-value pairs using standard
 * font attribute keys. This is the designated initializer for creating
 * font descriptors with custom attribute combinations. Returns an initialized
 * font descriptor or nil if the attributes are invalid.
 */
- (id) initWithFontAttributes: (NSDictionary *)attributes;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Creates a new font descriptor by adding attributes to this descriptor.
 * The attributes parameter contains additional font attributes to merge
 * with the existing attributes in this descriptor. If an attribute key
 * already exists, the new value replaces the old one. Returns a new
 * font descriptor with the combined attributes.
 */
- (NSFontDescriptor *) fontDescriptorByAddingAttributes:
  (NSDictionary *)attributes;

/**
 * Creates a new font descriptor with a specific font face name.
 * The face parameter specifies the font face (such as "Bold", "Italic",
 * or "Regular") to use with this descriptor's other attributes. This is
 * useful for creating variations of an existing font descriptor with
 * different weights or styles. Returns a new descriptor with the face attribute.
 */
- (NSFontDescriptor *) fontDescriptorWithFace: (NSString *)face;

/**
 * Creates a new font descriptor with a specific font family name.
 * The family parameter specifies the font family (such as "Helvetica"
 * or "Times") to use while preserving other attributes from this descriptor.
 * This allows changing the font family while maintaining size, traits,
 * and other characteristics. Returns a new descriptor with the family attribute.
 */
- (NSFontDescriptor *) fontDescriptorWithFamily: (NSString *)family;

/**
 * Creates a new font descriptor with a specific transformation matrix.
 * The matrix parameter provides an NSAffineTransform to apply to the font,
 * allowing for geometric transformations like scaling, rotation, or skewing.
 * Other attributes from this descriptor are preserved. Returns a new
 * descriptor with the matrix transformation applied.
 */
- (NSFontDescriptor *) fontDescriptorWithMatrix: (NSAffineTransform *)matrix;

/**
 * Creates a new font descriptor with a specific point size.
 * The size parameter specifies the font size in points while preserving
 * all other attributes from this descriptor. This is a convenient way
 * to resize a font while maintaining its family, traits, and other
 * characteristics. Returns a new descriptor with the specified size.
 */
- (NSFontDescriptor *) fontDescriptorWithSize: (CGFloat)size;

/**
 * Creates a new font descriptor with specific symbolic traits.
 * The traits parameter contains NSFontSymbolicTraits flags that describe
 * font characteristics like bold, italic, condensed, etc. Other attributes
 * from this descriptor are preserved while the symbolic traits are updated.
 * Returns a new descriptor with the specified traits.
 */
- (NSFontDescriptor *) fontDescriptorWithSymbolicTraits:
  (NSFontSymbolicTraits)traits;
/**
 * Finds font descriptors that match this descriptor's attributes.
 * The keys parameter is an NSSet containing attribute keys that must
 * be matched exactly in the search results. Other attributes may be
 * used for ranking but are not mandatory. Returns an NSArray of
 * NSFontDescriptor objects sorted by relevance, with the best matches first.
 * Returns an empty array if no matching fonts are found.
 */
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys;

/**
 * Returns the value for a specific font attribute key.
 * The attribute parameter should be one of the standard font attribute
 * constants like NSFontNameAttribute or NSFontSizeAttribute. Returns the
 * corresponding value object (NSString, NSNumber, etc.) or nil if the
 * attribute is not present in this descriptor. Provides direct access
 * to individual attributes without retrieving the entire dictionary.
 */
- (id) objectForKey: (NSString *)attribute;

/**
 * Returns the transformation matrix associated with this font descriptor.
 * Extracts the NSAffineTransform from the NSFontMatrixAttribute if present,
 * or returns the identity matrix if no transformation is specified.
 * This matrix defines geometric transformations like scaling, rotation,
 * or skewing that should be applied to the font.
 */
- (NSAffineTransform *) matrix;

/**
 * Returns the point size specified in this font descriptor.
 * Extracts the font size from the NSFontSizeAttribute if present,
 * or returns 0.0 if no size is specified. This provides convenient
 * access to the font size without needing to query the attributes
 * dictionary directly.
 */
- (CGFloat) pointSize;

/**
 * Returns the PostScript name for the font described by this descriptor.
 * The PostScript name is a unique identifier for the specific font face
 * that includes family, weight, and style information in a standardized
 * format. Returns the PostScript name as an NSString, or nil if the
 * descriptor doesn't specify a complete font definition.
 */
- (NSString *) postscriptName;

/**
 * Returns the symbolic traits associated with this font descriptor.
 * Extracts the NSFontSymbolicTraits flags from the font attributes,
 * providing information about font characteristics like bold, italic,
 * condensed, monospace, etc. Returns 0 if no symbolic traits are
 * specified in this descriptor.
 */
- (NSFontSymbolicTraits) symbolicTraits;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 * Finds the best matching font descriptor for this descriptor's attributes.
 * The keys parameter is an NSSet containing attribute keys that must be
 * matched exactly in the search result. Unlike matchingFontDescriptorsWithMandatoryKeys:
 * which returns an array of all matches, this method returns only the single
 * best matching font descriptor, or nil if no suitable match is found.
 * This is useful when you need a specific font rather than a list of options.
 */
- (NSFontDescriptor *) matchingFontDescriptorWithMandatoryKeys: (NSSet *)keys;
#endif

@end

#endif /* OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST) */

#endif /* _GNUstep_H_NSFontDescriptor */
