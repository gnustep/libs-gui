/** <title>CTGlyphInfo</title>

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

#ifndef OPAL_CTGlyphInfo_h
#define OPAL_CTGlyphInfo_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGFont.h>
#include <CoreText/CTFont.h>

/* Data Types */

#ifdef __OBJC__
@class CTGlyphInfo;
typedef CTGlyphInfo* CTGlyphInfoRef;
#else
typedef struct CTGlyphInfo* CTGlyphInfoRef;
#endif

/* Constants */

typedef enum {
  kCTIdentityMappingCharacterCollection = 0,
  kCTAdobeCNS1CharacterCollection = 1,
  kCTAdobeGB1CharacterCollection = 2,
  kCTAdobeJapan1CharacterCollection = 3,
  kCTAdobeJapan2CharacterCollection = 4,
  kCTAdobeKorea1CharacterCollection = 5
} CTCharacterCollection;

/* Functions */

CFTypeID CTGlyphInfoGetTypeID();

CTGlyphInfoRef CTGlyphInfoCreateWithGlyphName(
  CFStringRef glyphName,
  CTFontRef font,
  CFStringRef baseString
);

CTGlyphInfoRef CTGlyphInfoCreateWithGlyph(
  CGGlyph glyph,
  CTFontRef font,
  CFStringRef baseString
);

CTGlyphInfoRef CTGlyphInfoCreateWithCharacterIdentifier(
  CGFontIndex cid,
  CTCharacterCollection collection,
  CFStringRef baseString
);

CFStringRef CTGlyphInfoGetGlyphName(CTGlyphInfoRef glyphInfo);

CGFontIndex CTGlyphInfoGetCharacterIdentifier(CTGlyphInfoRef glyphInfo);

CTCharacterCollection CTGlyphInfoGetCharacterCollection(CTGlyphInfoRef glyphInfo);

#endif
