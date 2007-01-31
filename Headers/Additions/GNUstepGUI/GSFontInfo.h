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
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#ifndef __GSFontInfo_h_INCLUDE_
#define __GSFontInfo_h_INCLUDE_

#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>

@class NSMutableDictionary;
@class NSArray;
@class NSBezierPath;

@interface GSFontEnumerator : NSObject
{
  NSArray *allFontNames;
  NSMutableDictionary *allFontFamilies;
}

+ (void) setDefaultClass: (Class)defaultClass;
+ (GSFontEnumerator*) sharedEnumerator;
- (void) enumerateFontsAndFamilies;
- (NSArray*) availableFonts;
- (NSArray*) availableFontFamilies;
- (NSArray*) availableMembersOfFontFamily: (NSString*)family;

/* Note that these are only called once. NSFont will remember the returned
values. Backends may override these. */
- (NSString *) defaultSystemFontName;
- (NSString *) defaultBoldSystemFontName;
- (NSString *) defaultFixedPitchFontName;
@end

@interface GSFontInfo : NSObject <NSCopying, NSMutableCopying>
{
  NSMutableDictionary* fontDictionary;

  // metrics of the font
  NSString *fontName;
  NSString *familyName;
  float matrix[6];
  float italicAngle;
  float underlinePosition;
  float underlineThickness;
  float capHeight;
  float xHeight;
  float descender;
  float ascender;
  NSSize maximumAdvancement;
  NSSize minimumAdvancement;
  NSString *encodingScheme;
  NSStringEncoding mostCompatibleStringEncoding;
  NSRect fontBBox;
  BOOL isFixedPitch;
  BOOL isBaseFont;
  int weight;
  NSFontTraitMask traits;
  unsigned	numberOfGlyphs;
  NSCharacterSet	*coveredCharacterSet;
}

+ (GSFontInfo*) fontInfoForFontName: (NSString*)fontName 
                             matrix: (const float *)fmatrix
			 screenFont: (BOOL)screenFont;
+ (void) setDefaultClass: (Class)defaultClass;
+ (NSString *) stringForWeight: (int)weight;
+ (int) weightForString: (NSString *)weightString;

- (NSSize) advancementForGlyph: (NSGlyph)aGlyph;
- (NSDictionary *) afmDictionary;
- (NSString *) afmFileContents;
- (void) appendBezierPathWithGlyphs: (NSGlyph *)glyphs
			      count: (int)count
		       toBezierPath: (NSBezierPath *)path;
- (float) ascender;
- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph;
- (NSRect) boundingRectForFont;
- (float) capHeight;
- (NSCharacterSet*) coveredCharacterSet;
- (float) defaultLineHeightForFont;
- (float) descender;
- (NSString *) displayName;
- (NSString *) encodingScheme;
- (NSString *) familyName;
- (NSString *) fontName;
- (BOOL) glyphIsEncoded: (NSGlyph)aGlyph;
- (NSMultibyteGlyphPacking) glyphPacking;
- (NSGlyph) glyphWithName: (NSString*)glyphName;
- (BOOL) isFixedPitch;
- (BOOL) isBaseFont;
- (float) italicAngle;
- (const float*) matrix;
- (NSSize) maximumAdvancement;
- (NSSize) minimumAdvancement;
- (NSStringEncoding) mostCompatibleStringEncoding;
- (unsigned) numberOfGlyphs;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
               forCharacter: (unichar)aChar 
             struckOverRect: (NSRect)aRect;
- (NSPoint) positionOfGlyph: (NSGlyph)curGlyph
	    precededByGlyph: (NSGlyph)prevGlyph
		  isNominal: (BOOL*)nominal;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
	    struckOverGlyph: (NSGlyph)baseGlyph 
	       metricsExist: (BOOL *)flag;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
	     struckOverRect: (NSRect)aRect 
	       metricsExist: (BOOL *)flag;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
	       withRelation: (NSGlyphRelation)relation 
		toBaseGlyph: (NSGlyph)baseGlyph
	   totalAdvancement: (NSSize *)offset 
	       metricsExist: (BOOL *)flag;
- (NSFontTraitMask) traits;
- (float) underlinePosition;
- (float) underlineThickness;
- (int) weight;
- (float) widthOfString: (NSString*)string;
- (float) xHeight;

@end

#endif /* __GSFontInfo_h_INCLUDE_ */
