/** <title>CTFont</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include <CoreText/CTFont.h>
#include <CoreText/CTFontDescriptor.h>
#import "NSFont.h"
#import "NSFontDescriptor.h"

/* Constants */

const CFStringRef kCTFontCopyrightNameKey = @"kCTFontCopyrightNameKey";
const CFStringRef kCTFontFamilyNameKey = @"kCTFontFamilyNameKey";
const CFStringRef kCTFontSubFamilyNameKey = @"kCTFontSubFamilyNameKey";
const CFStringRef kCTFontStyleNameKey = @"kCTFontStyleNameKey";
const CFStringRef kCTFontUniqueNameKey = @"kCTFontUniqueNameKey";
const CFStringRef kCTFontFullNameKey = @"kCTFontFullNameKey";
const CFStringRef kCTFontVersionNameKey = @"kCTFontVersionNameKey";
const CFStringRef kCTFontPostScriptNameKey = @"kCTFontPostScriptNameKey";
const CFStringRef kCTFontTrademarkNameKey = @"kCTFontTrademarkNameKey";
const CFStringRef kCTFontManufacturerNameKey = @"kCTFontManufacturerNameKey";
const CFStringRef kCTFontDesignerNameKey = @"kCTFontDesignerNameKey";
const CFStringRef kCTFontDescriptionNameKey = @"kCTFontDescriptionNameKey";
const CFStringRef kCTFontVendorURLNameKey = @"kCTFontVendorURLNameKey";
const CFStringRef kCTFontDesignerURLNameKey = @"kCTFontDesignerURLNameKey";
const CFStringRef kCTFontLicenseNameKey = @"kCTFontLicenseNameKey";
const CFStringRef kCTFontLicenseURLNameKey = @"kCTFontLicenseURLNameKey";
const CFStringRef kCTFontSampleTextNameKey = @"kCTFontSampleTextNameKey";
const CFStringRef kCTFontPostScriptCIDNameKey = @"kCTFontPostScriptCIDNameKey";

const CFStringRef kCTFontVariationAxisIdentifierKey = @"kCTFontVariationAxisIdentifierKey";
const CFStringRef kCTFontVariationAxisMinimumValueKey = @"kCTFontVariationAxisMinimumValueKey";
const CFStringRef kCTFontVariationAxisMaximumValueKey = @"kCTFontVariationAxisMaximumValueKey";
const CFStringRef kCTFontVariationAxisDefaultValueKey = @"kCTFontVariationAxisDefaultValueKey";
const CFStringRef kCTFontVariationAxisNameKey = @"kCTFontVariationAxisNameKey";

const CFStringRef kCTFontFeatureTypeIdentifierKey = @"kCTFontFeatureTypeIdentifierKey";
const CFStringRef kCTFontFeatureTypeNameKey = @"kCTFontFeatureTypeNameKey";
const CFStringRef kCTFontFeatureTypeExclusiveKey = @"kCTFontFeatureTypeExclusiveKey";
const CFStringRef kCTFontFeatureTypeSelectorsKey = @"kCTFontFeatureTypeSelectorsKey";
const CFStringRef kCTFontFeatureSelectorIdentifierKey = @"kCTFontFeatureSelectorIdentifierKey";
const CFStringRef kCTFontFeatureSelectorNameKey = @"kCTFontFeatureSelectorNameKey";
const CFStringRef kCTFontFeatureSelectorDefaultKey = @"kCTFontFeatureSelectorDefaultKey";
const CFStringRef kCTFontFeatureSelectorSettingKey = @"kCTFontFeatureSelectorSettingKey";

/* Classes */


/* Functions */

/* Creating */

CTFontRef CTFontCreateForString(
  CTFontRef base,
  CFStringRef str,
  CFRange range)
{
  NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:
    [str substringWithRange: range]];

  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
    set, kCTFontCharacterSetAttribute,
    nil];

  NSFontDescriptor *descriptor = [NSFontDescriptor fontDescriptorWithFontAttributes: attrs];

  return CTFontCreateCopyWithAttributes(base, CTFontGetSize(base), NULL, descriptor);
}

CTFontRef CTFontCreateWithFontDescriptor(
  CTFontDescriptorRef descriptor,
  CGFloat size,
  const CGAffineTransform *matrixPtr)
{
  return CTFontCreateWithFontDescriptorAndOptions(descriptor, size, matrixPtr, kCTFontOptionsDefault);
}

CTFontRef CTFontCreateWithFontDescriptorAndOptions(
  CTFontDescriptorRef descriptor,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontOptions opts)
{
  NSDictionary *addedAttributes;

  if (size == 0.0)
  {
    size = 12.0;
  }

  if (matrixPtr)
  {
    addedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithDouble: size], kCTFontSizeAttribute,
      [NSData dataWithBytes: matrixPtr length: sizeof(CGAffineTransform)], kCTFontMatrixAttribute,
      nil];
  }
  else
  {
    addedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithDouble: size], kCTFontSizeAttribute,
      nil];
  }

  return [[NSFont fontWithDescriptor: [descriptor fontDescriptorByAddingAttributes: addedAttributes]
                             options: opts] retain];
}

CTFontRef CTFontCreateWithGraphicsFont(
  CGFontRef cgFont,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontDescriptorRef descriptor)
{
  NSDictionary *addedAttributes;

  if (size == 0.0)
  {
    size = 12.0;
  }

  if (matrixPtr)
  {
    addedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithDouble: size], kCTFontSizeAttribute,
      [NSData dataWithBytes: matrixPtr length: sizeof(CGAffineTransform)], kCTFontMatrixAttribute,
      nil];
  }
  else
  {
    addedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithDouble: size], kCTFontSizeAttribute,
      nil];
  }

  return [[NSFont fontWithGraphicsFont: cgFont
                  additionalDescriptor: [descriptor fontDescriptorByAddingAttributes: addedAttributes]] retain];
}

CTFontRef CTFontCreateWithName(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrixPtr)
{
  return CTFontCreateWithNameAndOptions(name, size, matrixPtr, kCTFontOptionsDefault);
}

CTFontRef CTFontCreateWithNameAndOptions(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontOptions opts)
{
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
    name, kCTFontNameAttribute,
    nil];

  NSFontDescriptor *descriptor = [NSFontDescriptor fontDescriptorWithFontAttributes: attrs];

  return CTFontCreateWithFontDescriptorAndOptions(descriptor, size, matrixPtr, opts);
}

CTFontRef CTFontCreateWithPlatformFont(
  void *platformFont,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontDescriptorRef descriptor)
{
  return nil;
}

CTFontRef CTFontCreateWithQuickdrawInstance(
  void *name,
  int16_t identifier,
  uint8_t style,
  CGFloat size)
{
  return nil;
}

CTFontRef CTFontCreateUIFontForLanguage(
  CTFontUIFontType type,
  CGFloat size,
  CFStringRef language)
{
  if ([[NSFont class] respondsToSelector:@selector(UIFontWithType:size:forLangage:)])
  {
    return [[NSFont UIFontWithType: type size: size forLanguage: language] retain];
  }
  else
  {
    NSLog(@"Warning, Opal delegate CTFontCreateUIFontForLanguage to GNUstep gui");
    
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
		  [NSArray arrayWithObject: language], kCTFontLanguagesAttribute,
		  nil];

		NSFontDescriptor *descriptor = [NSFontDescriptor fontDescriptorWithFontAttributes: attrs];

		return CTFontCreateWithFontDescriptor(descriptor, size, NULL);
  }
}

/* Copying & Conversion */

CTFontRef CTFontCreateCopyWithAttributes(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontDescriptorRef descriptor)
{
  return nil; //FIXME: set up a new descriptor...
}

CTFontRef CTFontCreateCopyWithSymbolicTraits(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontSymbolicTraits value,
  CTFontSymbolicTraits mask)
{
  return nil; //FIXME: set up a new descriptor...
}

CTFontRef CTFontCreateCopyWithFamily(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CFStringRef family)
{
  //FIXME: should return nil if the result doesn't have the desired family
  return CTFontCreateWithFontDescriptor([[font fontDescriptor] fontDescriptorWithFamily: family], size, matrixPtr);
}

void *CTFontGetPlatformFont(
  CTFontRef font,
  CTFontDescriptorRef *attribs)
{
  return NULL;
}

CGFontRef CTFontCopyGraphicsFont(
  CTFontRef font,
  CTFontDescriptorRef *descriptorOut)
{
  return [[font graphicsFontWithDescriptor: descriptorOut] retain];
}

/* Glyphs */

CFIndex CTFontGetGlyphCount(CTFontRef font)
{
  return [font numberOfGlyphs];
}

CGPathRef CTFontCreatePathForGlyph(
  CTFontRef font,
  CGGlyph glyph,
  const CGAffineTransform *transform)
{
  return [font graphicsPathForGlyph: glyph
                          transform: transform];
}

bool CTFontGetGlyphsForCharacters(
  CTFontRef font,
  const unichar characters[],
  CGGlyph glyphs[],
  CFIndex count)
{
  return [font getGraphicsGlyphsForCharacters: characters
                               graphicsGlyphs: glyphs
                                        count: count];
}

CGGlyph CTFontGetGlyphWithName(
  CTFontRef font,
  CFStringRef name)
{
  return [font glyphWithName: name];
}

double CTFontGetAdvancesForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGSize advances[],
  CFIndex count)
{
  return [font getAdvancesForGraphicsGlyphs: glyphs
                                   advances: advances
                                orientation: orientation
                                      count: count];
}

CGRect CTFontGetBoundingRectsForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGRect rects[],
  CFIndex count)
{
  return [font getBoundingRectsForGraphicsGlyphs: glyphs
                                           rects: rects
                                     orientation: orientation
                                           count: count];
}

void CTFontGetVerticalTranslationsForGlyphs(
  CTFontRef font,
  const CGGlyph glyphs[],
  CGSize translations[],
  CFIndex count)
{
  [font getVerticalTranslationForGraphicsGlyphs: glyphs
                                    translation: translations
                                          count: count];
}

/* Metrics */

CGFloat CTFontGetAscent(CTFontRef font)
{
  return [font ascender];
}

CGFloat CTFontGetDescent(CTFontRef font)
{
  return [font descender];
}

CGFloat CTFontGetCapHeight(CTFontRef font)
{
  return [font capHeight];
}

CGFloat CTFontGetSize(CTFontRef font)
{
  return [font pointSize];
}

CGFloat CTFontGetLeading(CTFontRef font)
{
  return [font leading];
}

unsigned CTFontGetUnitsPerEm(CTFontRef font)
{
  return [font unitsPerEm];
}

CGRect CTFontGetBoundingBox(CTFontRef font)
{
  NSRect r = [font boundingRectForFont];
  return CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height);
}

CGFloat CTFontGetUnderlinePosition(CTFontRef font)
{
  return [font underlinePosition];
}

CGFloat CTFontGetUnderlineThickness(CTFontRef font)
{
  return [font underlineThickness];
}

CGFloat CTFontGetSlantAngle(CTFontRef font)
{
  return [font italicAngle];
}

CGFloat CTFontGetXHeight(CTFontRef font)
{
  return [font xHeight];
}

/* Properties */

CGAffineTransform CTFontGetMatrix(CTFontRef font)
{
  const CGFloat *matrix = [font matrix];
  CGAffineTransform xform;
  xform.a = matrix[0];
  xform.b = matrix[1];
  xform.c = matrix[2];
  xform.d = matrix[3];
  xform.tx = matrix[4];
  xform.ty = matrix[5];
  return xform;
}

CTFontSymbolicTraits CTFontGetSymbolicTraits(CTFontRef font)
{
  NSDictionary *traits = CTFontCopyTraits(font);
  int symTraits = [[traits objectForKey: kCTFontSymbolicTrait] intValue];
  [traits release];

  return (CTFontSymbolicTraits)symTraits;
}

CFTypeRef CTFontCopyAttribute(
  CTFontRef font,
  CFStringRef attrib)
{
  return [[[font fontDescriptor] objectForKey: attrib] retain];
}

CFArrayRef CTFontCopyAvailableTables(
  CTFontRef font,
  CTFontTableOptions opts)
{
  return (CFArrayRef)[font availableTablesWithOptions: opts];
}

CFDictionaryRef CTFontCopyTraits(CTFontRef font)
{
  return (CFDictionaryRef)CTFontCopyAttribute(font, kCTFontTraitsAttribute);
}

CFArrayRef CTFontCopyFeatures(CTFontRef font)
{
  return (CFArrayRef)CTFontCopyAttribute(font, kCTFontFeaturesAttribute);
}

CFArrayRef CTFontCopyFeatureSettings(CTFontRef font)
{
  return (CFArrayRef)CTFontCopyAttribute(font, kCTFontFeatureSettingsAttribute);
}

CTFontDescriptorRef CTFontCopyFontDescriptor(CTFontRef font)
{
  return [font fontDescriptor];
}

CFDataRef CTFontCopyTable(
  CTFontRef font,
  CTFontTableTag table,
  CTFontTableOptions opts)
{
  return [[font tableForTag: table withOptions: opts] retain];
}

CFArrayRef CTFontCopyVariationAxes(CTFontRef font)
{
  return [[font variationAxes] retain];
}

CFDictionaryRef CTFontCopyVariation(CTFontRef font)
{
  return [[font variation] retain];
}

/* Encoding & Character Set */

NSStringEncoding CTFontGetStringEncoding(CTFontRef font)
{
  return [font mostCompatibleStringEncoding];
}

CFCharacterSetRef CTFontCopyCharacterSet(CTFontRef font)
{
  return [[font coveredCharacterSet] retain];
}

CFArrayRef CTFontCopySupportedLanguages(CTFontRef font)
{
  return [[[font fontDescriptor] objectForKey: kCTFontLanguagesAttribute] retain]; 
}

/* Name */

CFStringRef CTFontCopyDisplayName(CTFontRef font)
{
  return [[font displayName] retain];
}

CFStringRef CTFontCopyName(
  CTFontRef font,
  CFStringRef key)
{
  return [[font nameForKey: key] retain];
}

CFStringRef CTFontCopyLocalizedName(
  CTFontRef font,
  CFStringRef key,
  CFStringRef *language)
{
  return [[font localizedNameForKey: key
                           language: language] retain];
}

CFStringRef CTFontCopyPostScriptName(CTFontRef font)
{
  return [[font fontName] retain];
}

CFStringRef CTFontCopyFamilyName(CTFontRef font)
{
  return [[font familyName] retain];
}

CFStringRef CTFontCopyFullName(CTFontRef font)
{
  return CTFontCopyName(font, kCTFontFullNameKey);
}

/* CFTypeID */

CFTypeID CTFontGetTypeID()
{
  return (CFTypeID)[NSFont class];
}

