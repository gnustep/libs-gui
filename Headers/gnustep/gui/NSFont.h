/* 
   NSFont.h

   The font class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996, 1997
   
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

#ifndef _GNUstep_H_NSFont
#define _GNUstep_H_NSFont

#include <Foundation/NSCoder.h>
#include <Foundation/NSGeometry.h>

@class NSString;
@class NSDictionary;

typedef unsigned int NSGlyph;

enum {
  NSControlGlyph = 0x00ffffff,
  NSNullGlyph = 0x0
};

extern const float *NSFontIdentityMatrix;

@interface NSFont : NSObject <NSCoding>
{
  // Font attributes
  NSString *fontName;
  float matrix[6];

  // Reserved for back-end use
  void *be_font_reserved;
}

//
// Creating a Font Object
//
+ (NSFont *)boldSystemFontOfSize:(float)fontSize;
+ (NSFont *)fontWithName:(NSString *)fontName 
		  matrix:(const float *)fontMatrix;
+ (NSFont *)fontWithName:(NSString *)fontName
		    size:(float)fontSize;
+ (NSFont *)systemFontOfSize:(float)fontSize;
+ (NSFont *)userFixedPitchFontOfSize:(float)fontSize;
+ (NSFont *)userFontOfSize:(float)fontSize;

//
// Setting the Font
//
+ (void)setUserFixedPitchFont:(NSFont *)aFont;
+ (void)setUserFont:(NSFont *)aFont;
+ (void)useFont:(NSString *)fontName;
- (void)set;

//
// Querying the Font
//
- (NSDictionary *)afmDictionary;
- (NSString *)afmFileContents;
- (NSRect)boundingRectForFont;
- (NSString *)displayName;
- (NSString *)familyName;
- (NSString *)fontName;
- (NSString *)encodingScheme;
- (BOOL)isFixedPitch;
- (BOOL)isBaseFont;
- (const float *)matrix;
- (float)pointSize;
- (NSFont *)printerFont;
- (NSFont *)screenFont;
- (float)ascender;
- (float)descender;
- (float)capHeight;
- (float)italicAngle;
- (NSSize)maximumAdvancement;
- (NSSize)minimumAdvancement;
- (float)underlinePosition;
- (float)underlineThickness;
- (float)xHeight;
- (float)widthOfString:(NSString *)string;
- (float *)widths;

//
// Manipulating Glyphs
//
- (NSSize)advancementForGlyph:(NSGlyph)aGlyph;
- (NSRect)boundingRectForGlyph:(NSGlyph)aGlyph;
- (BOOL)glyphIsEncoded:(NSGlyph)aGlyph;
- (NSGlyph)glyphWithName:(NSString*)glyphName;
- (NSPoint)positionOfGlyph:(NSGlyph)curGlyph
	   precededByGlyph:(NSGlyph)prevGlyph
		 isNominal:(BOOL *)nominal;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

extern NSString *NSAFMAscender;
extern NSString *NSAFMCapHeight;
extern NSString *NSAFMCharacterSet;
extern NSString *NSAFMDescender;
extern NSString *NSAFMEncodingScheme;
extern NSString *NSAFMFamilyName;
extern NSString *NSAFMFontName;
extern NSString *NSAFMFormatVersion;
extern NSString *NSAFMFullName;
extern NSString *NSAFMItalicAngle;
extern NSString *NSAFMMappingScheme;
extern NSString *NSAFMNotice;
extern NSString *NSAFMUnderlinePosition;
extern NSString *NSAFMUnderlineThickness;
extern NSString *NSAFMVersion;
extern NSString *NSAFMWeight;
extern NSString *NSAFMXHeight;

#endif // _GNUstep_H_NSFont
