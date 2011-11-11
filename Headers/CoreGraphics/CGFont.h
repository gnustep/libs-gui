/** <title>CGFont</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_CGFont_h
#define OPAL_CGFont_h

/* Data Types */

#ifdef __OBJC__
@class CGFont;
typedef CGFont* CGFontRef;
#else
typedef struct CGFont* CGFontRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGGeometry.h>
#include <CoreGraphics/CGDataProvider.h>

typedef unsigned short CGGlyph;

typedef unsigned short CGFontIndex;

/* Constants */

enum { 
   kCGFontIndexMax = ((1 << 16) - 2), 
   kCGFontIndexInvalid = ((1 << 16) - 1), 
   kCGGlyphMax = kCGFontIndexMax
};

typedef enum CGFontPostScriptFormat {
  kCGFontPostScriptFormatType1 = 1,
  kCGFontPostScriptFormatType3 = 3,
  kCGFontPostScriptFormatType42 = 42
} CGFontPostScriptFormat;

const extern CFStringRef kCGFontVariationAxisName;
const extern CFStringRef kCGFontVariationAxisMinValue;
const extern CFStringRef kCGFontVariationAxisMaxValue;
const extern CFStringRef kCGFontVariationAxisDefaultValue;

/* Functions */

bool CGFontCanCreatePostScriptSubset(
  CGFontRef font,
  CGFontPostScriptFormat format
);

CFStringRef CGFontCopyFullName(CGFontRef font);

CFStringRef CGFontCopyGlyphNameForGlyph(CGFontRef font, CGGlyph glyph);

CFStringRef CGFontCopyPostScriptName(CGFontRef font);

CFDataRef CGFontCopyTableForTag(CGFontRef font, uint32_t tag);

CFArrayRef CGFontCopyTableTags(CGFontRef font);

CFArrayRef CGFontCopyVariationAxes(CGFontRef font);

CFDictionaryRef CGFontCopyVariations(CGFontRef font);

CGFontRef CGFontCreateCopyWithVariations(
  CGFontRef font,
  CFDictionaryRef variations
);

CFDataRef CGFontCreatePostScriptEncoding(
  CGFontRef font,
  const CGGlyph encoding[256]
);

CFDataRef CGFontCreatePostScriptSubset(
  CGFontRef font,
  CFStringRef name,
  CGFontPostScriptFormat format,
  const CGGlyph glyphs[],
  size_t count,
  const CGGlyph encoding[256]
);

CGFontRef CGFontCreateWithDataProvider(CGDataProviderRef provider);

CGFontRef CGFontCreateWithFontName(CFStringRef name);

CGFontRef CGFontCreateWithPlatformFont(void *platformFontReference);

int CGFontGetAscent(CGFontRef font);

int CGFontGetCapHeight(CGFontRef font);

int CGFontGetDescent(CGFontRef font);

CGRect CGFontGetFontBBox(CGFontRef font);

bool CGFontGetGlyphAdvances(
  CGFontRef font,
  const CGGlyph glyphs[],
  size_t count,
  int advances[]
);

bool CGFontGetGlyphBBoxes(
  CGFontRef font,
  const CGGlyph glyphs[],
  size_t count,
  CGRect bboxes[]
);

CGGlyph CGFontGetGlyphWithGlyphName(CGFontRef font, CFStringRef glyphName);

CGFloat CGFontGetItalicAngle(CGFontRef font);

int CGFontGetLeading(CGFontRef font);

size_t CGFontGetNumberOfGlyphs(CGFontRef font);

CGFloat CGFontGetStemV(CGFontRef font);

int CGFontGetUnitsPerEm(CGFontRef font);

int CGFontGetXHeight(CGFontRef font);

CFTypeID CGFontGetTypeID();

CGFontRef CGFontRetain(CGFontRef font);

void CGFontRelease(CGFontRef font);

#endif /* OPAL_CGFont_h */
