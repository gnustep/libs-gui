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

#ifndef OPAL_CTFont_h
#define OPAL_CTFont_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGAffineTransform.h>
#include <CoreGraphics/CGPath.h>
#include <CoreGraphics/CGFont.h>
#include <CoreText/CTFontDescriptor.h>

/* Data Types */

#ifdef __OBJC__
@class NSFont;
typedef NSFont* CTFontRef;
#else
typedef struct NSFont* CTFontRef;
#endif

/* Constants */

/**
 * The following keys are used to retrieve different names for the font,
 * using CTFontCopyName or CTFontCopyLocalizedName.
 */
extern const CFStringRef kCTFontCopyrightNameKey;
extern const CFStringRef kCTFontFamilyNameKey;
extern const CFStringRef kCTFontSubFamilyNameKey;
extern const CFStringRef kCTFontStyleNameKey;
extern const CFStringRef kCTFontUniqueNameKey;
extern const CFStringRef kCTFontFullNameKey;
extern const CFStringRef kCTFontVersionNameKey;
extern const CFStringRef kCTFontPostScriptNameKey;
extern const CFStringRef kCTFontTrademarkNameKey;
extern const CFStringRef kCTFontManufacturerNameKey;
extern const CFStringRef kCTFontDesignerNameKey;
extern const CFStringRef kCTFontDescriptionNameKey;
extern const CFStringRef kCTFontVendorURLNameKey;
extern const CFStringRef kCTFontDesignerURLNameKey;
extern const CFStringRef kCTFontLicenseNameKey;
extern const CFStringRef kCTFontLicenseURLNameKey;
extern const CFStringRef kCTFontSampleTextNameKey;
extern const CFStringRef kCTFontPostScriptCIDNameKey;

/**
 * For use with CTFontCopyVariationAxes and CTFontCopyVariation
 */
extern const CFStringRef kCTFontVariationAxisIdentifierKey;
extern const CFStringRef kCTFontVariationAxisMinimumValueKey;
extern const CFStringRef kCTFontVariationAxisMaximumValueKey;
extern const CFStringRef kCTFontVariationAxisDefaultValueKey;
extern const CFStringRef kCTFontVariationAxisNameKey;

/**
 * For use with CTFontCopyFeatures and CTFontCopyFeatureSettings.
 *
 * These are used as keys in the feature dictionaries, which
 * are used to query the supported OpenType features of a font,
 * or request a feature for a range in an attributed string.
 */
extern const CFStringRef kCTFontFeatureTypeIdentifierKey;
extern const CFStringRef kCTFontFeatureTypeNameKey;
extern const CFStringRef kCTFontFeatureTypeExclusiveKey;
extern const CFStringRef kCTFontFeatureTypeSelectorsKey;
extern const CFStringRef kCTFontFeatureSelectorIdentifierKey;
extern const CFStringRef kCTFontFeatureSelectorNameKey;
extern const CFStringRef kCTFontFeatureSelectorDefaultKey;
extern const CFStringRef kCTFontFeatureSelectorSettingKey;

typedef enum {
  kCTFontOptionsDefault = 0,
  kCTFontOptionsPreventAutoActivation = 1 << 0,
  kCTFontOptionsPreferSystemFont = 1 << 2,
} CTFontOptions;

typedef enum {
  kCTFontTableOptionNoOptions = 0,
  kCTFontTableOptionExcludeSynthetic = 1 << 0
} CTFontTableOptions;

#if GS_WORDS_BIGENDIAN
#define OP_TABLETAG(a,b,c,d) ((((int)a) << 24) | (((int)b) << 16) | (((int)c) << 8) | ((int)d))
#else
#define OP_TABLETAG(a,b,c,d) ((((int)d) << 24) | (((int)c) << 16) | (((int)b) << 8) | ((int)a))
#endif

typedef enum {
  kCTFontTableBASE = OP_TABLETAG('B','A','S','E'),
  kCTFontTableCFF = OP_TABLETAG('C','F','F',' '),
  kCTFontTableDSIG = OP_TABLETAG('D','S','I','G'),
  kCTFontTableEBDT = OP_TABLETAG('E','B','D','T'),
  kCTFontTableEBLC = OP_TABLETAG('E','B','L','C'),
  kCTFontTableEBSC = OP_TABLETAG('E','B','S','C'),
  kCTFontTableGDEF = OP_TABLETAG('G','D','E','F'),
  kCTFontTableGPOS = OP_TABLETAG('G','P','O','S'),
  kCTFontTableGSUB = OP_TABLETAG('G','S','U','B'),
  kCTFontTableJSTF = OP_TABLETAG('J','S','T','F'),
  kCTFontTableLTSH = OP_TABLETAG('L','T','S','H'),
  kCTFontTableOS2 = OP_TABLETAG('O','S','/','2'),
  kCTFontTablePCLT = OP_TABLETAG('P','C','L','T'),
  kCTFontTableVDMX = OP_TABLETAG('V','D','M','X'),
  kCTFontTableVORG = OP_TABLETAG('V','O','R','G'),
  kCTFontTableZapf = OP_TABLETAG('Z','a','p','f'),
  kCTFontTableAcnt = OP_TABLETAG('a','c','n','t'),
  kCTFontTableAvar = OP_TABLETAG('a','v','a','r'),
  kCTFontTableBdat = OP_TABLETAG('b','d','a','t'),
  kCTFontTableBhed = OP_TABLETAG('b','h','e','d'),
  kCTFontTableBloc = OP_TABLETAG('b','l','o','c'),
  kCTFontTableBsln = OP_TABLETAG('b','s','l','n'),
  kCTFontTableCmap = OP_TABLETAG('c','m','a','p'),
  kCTFontTableCvar = OP_TABLETAG('c','v','a','r'),
  kCTFontTableCvt = OP_TABLETAG('c','v','t',' '),
  kCTFontTableFdsc = OP_TABLETAG('f','d','s','c'),
  kCTFontTableFeat = OP_TABLETAG('f','e','a','t'),
  kCTFontTableFmtx = OP_TABLETAG('f','m','t','x'),
  kCTFontTableFpgm = OP_TABLETAG('f','p','g','m'),
  kCTFontTableFvar = OP_TABLETAG('f','v','a','r'),
  kCTFontTableGasp = OP_TABLETAG('g','a','s','p'),
  kCTFontTableGlyf = OP_TABLETAG('g','l','y','f'),
  kCTFontTableGvar = OP_TABLETAG('g','v','a','r'),
  kCTFontTableHdmx = OP_TABLETAG('h','d','m','x'),
  kCTFontTableHead = OP_TABLETAG('h','e','a','d'),
  kCTFontTableHhea = OP_TABLETAG('h','h','e','a'),
  kCTFontTableHmtx = OP_TABLETAG('h','m','t','x'),
  kCTFontTableHsty = OP_TABLETAG('h','s','t','y'),
  kCTFontTableJust = OP_TABLETAG('j','u','s','t'),
  kCTFontTableKern = OP_TABLETAG('k','e','r','n'),
  kCTFontTableLcar = OP_TABLETAG('l','c','a','r'),
  kCTFontTableLoca = OP_TABLETAG('l','o','c','a'),
  kCTFontTableMaxp = OP_TABLETAG('m','a','x','p'),
  kCTFontTableMort = OP_TABLETAG('m','o','r','t'),
  kCTFontTableMorx = OP_TABLETAG('m','o','r','x'),
  kCTFontTableName = OP_TABLETAG('n','a','m','e'),
  kCTFontTableOpbd = OP_TABLETAG('o','p','b','d'),
  kCTFontTablePost = OP_TABLETAG('p','o','s','t'),
  kCTFontTablePrep = OP_TABLETAG('p','r','e','p'),
  kCTFontTableProp = OP_TABLETAG('p','r','o','p'),
  kCTFontTableTrak = OP_TABLETAG('t','r','a','k'),
  kCTFontTableVhea = OP_TABLETAG('v','h','e','a'),
  kCTFontTableVmtx = OP_TABLETAG('v','m','t','x')
} CTFontTableTag;

typedef enum {
  kCTFontNoFontType = -1,
  kCTFontUserFontType = 0,
  kCTFontUserFixedPitchFontType = 1,
  kCTFontSystemFontType = 2,
  kCTFontEmphasizedSystemFontType = 3,
  kCTFontSmallSystemFontType = 4,
  kCTFontSmallEmphasizedSystemFontType = 5,
  kCTFontMiniSystemFontType = 6,
  kCTFontMiniEmphasizedSystemFontType = 7,
  kCTFontViewsFontType = 8,
  kCTFontApplicationFontType = 9,
  kCTFontLabelFontType = 10,
  kCTFontMenuTitleFontType = 11,
  kCTFontMenuItemFontType = 12,
  kCTFontMenuItemMarkFontType = 13,
  kCTFontMenuItemCmdKeyFontType = 14,
  kCTFontWindowTitleFontType = 15,
  kCTFontPushButtonFontType = 16,
  kCTFontUtilityWindowTitleFontType = 17,
  kCTFontAlertHeaderFontType = 18,
  kCTFontSystemDetailFontType = 19,
  kCTFontEmphasizedSystemDetailFontType = 20,
  kCTFontToolbarFontType = 21,
  kCTFontSmallToolbarFontType = 22,
  kCTFontMessageFontType = 23,
  kCTFontPaletteFontType = 24,
  kCTFontToolTipFontType = 25,
  kCTFontControlContentFontType = 26
} CTFontUIFontType;

/* Functions */

/* Creating */

CTFontRef CTFontCreateForString(
  CTFontRef base,
  CFStringRef str,
  CFRange range
);

/**
 * Creates a font with the given matrix and size.
 * matrix
 */
CTFontRef CTFontCreateWithFontDescriptor(
  CTFontDescriptorRef attribs,
  CGFloat size,
  const CGAffineTransform *matrixPtr
);

CTFontRef CTFontCreateWithFontDescriptorAndOptions(
  CTFontDescriptorRef attribs,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontOptions opts
);

CTFontRef CTFontCreateWithGraphicsFont(
  CGFontRef cgFont,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontDescriptorRef attribs
);

CTFontRef CTFontCreateWithName(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrixPtr
);

CTFontRef CTFontCreateWithNameAndOptions(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontOptions opts
);

CTFontRef CTFontCreateWithPlatformFont(
  void *platformFont,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontDescriptorRef attribs
);

CTFontRef CTFontCreateWithQuickdrawInstance(
  void *name,
  int16_t identifier,
  uint8_t style,
  CGFloat size
);

CTFontRef CTFontCreateUIFontForLanguage(
  CTFontUIFontType type,
  CGFloat size,
  CFStringRef language
);

/* Copying & Conversion */

CTFontRef CTFontCreateCopyWithAttributes(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontDescriptorRef attribs
);

CTFontRef CTFontCreateCopyWithSymbolicTraits(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CTFontSymbolicTraits value,
  CTFontSymbolicTraits mask
);

CTFontRef CTFontCreateCopyWithFamily(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrixPtr,
  CFStringRef family
);

void *CTFontGetPlatformFont(
  CTFontRef font,
  CTFontDescriptorRef *attribs
);

CGFontRef CTFontCopyGraphicsFont(
  CTFontRef font,
  CTFontDescriptorRef *attribs
);

/* Glyphs */

CFIndex CTFontGetGlyphCount(CTFontRef font);

CGPathRef CTFontCreatePathForGlyph(
  CTFontRef font,
  CGGlyph glyph,
  const CGAffineTransform *transform
);

bool CTFontGetGlyphsForCharacters(
  CTFontRef font,
  const unichar characters[],
  CGGlyph glyphs[],
  CFIndex count
);

CGGlyph CTFontGetGlyphWithName(
  CTFontRef font,
  CFStringRef name
);

double CTFontGetAdvancesForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGSize advances[],
  CFIndex count
);

CGRect CTFontGetBoundingRectsForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGRect rects[],
  CFIndex count
);

void CTFontGetVerticalTranslationsForGlyphs(
  CTFontRef font,
  const CGGlyph glyphs[],
  CGSize translations[],
  CFIndex count
);

/* Metrics */

CGFloat CTFontGetAscent(CTFontRef font);

CGFloat CTFontGetDescent(CTFontRef font);

CGFloat CTFontGetCapHeight(CTFontRef font);

CGFloat CTFontGetSize(CTFontRef font);

CGFloat CTFontGetLeading(CTFontRef font);

unsigned CTFontGetUnitsPerEm(CTFontRef font);

CGRect CTFontGetBoundingBox(CTFontRef font);

CGFloat CTFontGetUnderlinePosition(CTFontRef font);

CGFloat CTFontGetUnderlineThickness(CTFontRef font);

CGFloat CTFontGetSlantAngle(CTFontRef font);

CGFloat CTFontGetXHeight(CTFontRef font);

/* Properties */

CGAffineTransform CTFontGetMatrix(CTFontRef font);

CTFontSymbolicTraits CTFontGetSymbolicTraits(CTFontRef font);

CFTypeRef CTFontCopyAttribute(
  CTFontRef font,
  CFStringRef attrib
);

CFArrayRef CTFontCopyAvailableTables(
  CTFontRef font,
  CTFontTableOptions opts
);

CFDictionaryRef CTFontCopyTraits(CTFontRef font);

CFArrayRef CTFontCopyFeatures(CTFontRef font);

CFArrayRef CTFontCopyFeatureSettings(CTFontRef font);

CTFontDescriptorRef CTFontCopyFontDescriptor(CTFontRef font);

CFDataRef CTFontCopyTable(
  CTFontRef font,
  CTFontTableTag table,
  CTFontTableOptions opts
);

CFArrayRef CTFontCopyVariationAxes(CTFontRef font);

CFDictionaryRef CTFontCopyVariation(CTFontRef font);

/* Encoding & Character Set */

/**
 * Note: Returns NSStringEncoding instead of CFStringEncoding
 */
NSStringEncoding CTFontGetStringEncoding(CTFontRef font);

CFCharacterSetRef CTFontCopyCharacterSet(CTFontRef font);

CFArrayRef CTFontCopySupportedLanguages(CTFontRef font);

/* Name */

CFStringRef CTFontCopyDisplayName(CTFontRef font);

CFStringRef CTFontCopyName(
  CTFontRef font,
  CFStringRef key
);

CFStringRef CTFontCopyLocalizedName(
  CTFontRef font,
  CFStringRef key,
  CFStringRef *language
);

CFStringRef CTFontCopyPostScriptName(CTFontRef font);

CFStringRef CTFontCopyFamilyName(CTFontRef font);

CFStringRef CTFontCopyFullName(CTFontRef font);

/* CFTypeID */

CFTypeID CTFontGetTypeID();

#endif
