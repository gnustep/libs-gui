/*
   GSFontInfo.h

   Private class for handling font info

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Mar 2000
   
   This file is part of the GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef __GSFontInfo_h_INCLUDE_
#define __GSFontInfo_h_INCLUDE_

#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>

@class NSMutableDictionary;
@class NSMutableSet;

@interface GSFontEnumerator : NSObject
{
  id fontManager;
  NSMutableSet *allFontNames;
  NSMutableDictionary *allFontFamilies;
  NSMutableDictionary* fontInfoDictionary;
}

+ (void) setDefaultClass: (Class)defaultClass;
+ sharedEnumeratorWithFontManager: manager;
- (NSArray*) allFonts;
- (NSArray*) availableFonts;
- (NSArray*) availableFontFamilies;
- (NSArray*) availableMembersOfFontFamily: (NSString*)family;
@end

@interface GSFontInfo : NSObject
{
  NSMutableDictionary* fontDictionary;

  // metrics of the font
  NSString *fontName;
  NSString *familyName;
  float matrix[6];
  float italicAngle;
  NSString *weight;
  float underlinePosition;
  float underlineThickness;
  float capHeight;
  float xHeight;
  float descender;
  float ascender;
  float widths[256];
  NSSize maximumAdvancement;
  NSSize minimumAdvancement;
  NSString *encodingScheme;
  NSRect fontBBox;
  BOOL isFixedPitch;
  BOOL isBaseFont;
}

+ (void) setDefaultClass: (Class)defaultClass;
+ (GSFontInfo*) fontInfoForFontName: (NSString*)fontName 
                             matrix: (const float *)fmatrix;

- (GSFontInfo*) newTransformedFontInfoForMatrix: (const float*)fmatrix;
- (void) transformUsingMatrix: (const float*)fmatrix;

- (NSDictionary *)afmDictionary;
- (NSString *)afmFileContents;
- (NSRect)boundingRectForFont;
- (NSString *)displayName;
- (NSString *)familyName;
- (NSString *)fontName;
- (NSString *)encodingScheme;
- (BOOL)isFixedPitch;
- (BOOL)isBaseFont;
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

- (NSSize) advancementForGlyph: (NSGlyph)aGlyph;
- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph;
- (BOOL) glyphIsEncoded: (NSGlyph)aGlyph;
- (NSGlyph) glyphWithName: (NSString*)glyphName;
- (NSPoint) positionOfGlyph: (NSGlyph)curGlyph
	    precededByGlyph: (NSGlyph)prevGlyph
		  isNominal: (BOOL*)nominal;
- (float) widthOfString: (NSString*)string;

- (NSFontTraitMask) traits;
- (int) weight;

@end

#endif /* __GSFontInfo_h_INCLUDE_ */
