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
#include <Foundation/NSString.h>
#include <AppKit/AppKitDefines.h>

@class NSDictionary;

typedef unsigned int NSGlyph;

enum {
  NSControlGlyph = 0x00ffffff,
  NSNullGlyph = 0x0
};


typedef enum _NSGlyphRelation {
  NSGlyphBelow,
  NSGlyphAbove,
} NSGlyphRelation;

typedef enum _NSMultibyteGlyphPacking {
  NSOneByteGlyphPacking,
  NSJapaneseEUCGlyphPacking, 
  NSAsciiWithDoubleByteEUCGlyphPacking,
  NSTwoByteGlyphPacking, 
  NSFourByteGlyphPacking
} NSMultibyteGlyphPacking;

APPKIT_EXPORT const float*NSFontIdentityMatrix;

@interface NSFont : NSObject <NSCoding, NSCopying>
{
  NSString *fontName;
  float matrix[6];
  BOOL matrixExplicitlySet;

  id fontInfo;
}

//
// Creating a Font Object
//
+ (NSFont*) boldSystemFontOfSize: (float)fontSize;
+ (NSFont*) fontWithName: (NSString*)aFontName 
		  matrix: (const float*)fontMatrix;
+ (NSFont*) fontWithName: (NSString*)aFontName
		    size: (float)fontSize;
+ (NSFont*) systemFontOfSize: (float)fontSize;
+ (NSFont*) userFixedPitchFontOfSize: (float)fontSize;
+ (NSFont*) userFontOfSize: (float)fontSize;

+ (NSFont*) titleBarFontOfSize: (float)fontSize;
+ (NSFont*) menuFontOfSize: (float)fontSize;
+ (NSFont*) messageFontOfSize: (float)fontSize;
+ (NSFont*) paletteFontOfSize: (float)fontSize;
+ (NSFont*) toolTipsFontOfSize: (float)fontSize;
+ (NSFont*) controlContentFontOfSize: (float)fontSize;
+ (NSFont*) labelFontOfSize: (float)fontSize;

//
// Font Sizes
//
+ (float) labelFontSize;
+ (float) smallSystemFontSize;
+ (float) systemFontSize;

//
// Preferred Fonts
//
+ (NSArray*) preferredFontNames;
+ (void) setPreferredFontNames: (NSArray*)fontNames;

//
// Setting the Font
//
+ (void) setUserFixedPitchFont: (NSFont*)aFont;
+ (void) setUserFont: (NSFont*)aFont;
+ (void) useFont: (NSString*)aFontName;
- (void) set;

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
- (const float*) matrix;
- (float) pointSize;
- (NSFont*) printerFont;
- (NSFont*) screenFont;
- (float) ascender;
- (float) descender;
- (float) capHeight;
- (float) italicAngle;
- (NSSize) maximumAdvancement;
- (NSSize) minimumAdvancement;
- (float) underlinePosition;
- (float) underlineThickness;
- (float) xHeight;
- (float) widthOfString: (NSString*)string;
- (float) defaultLineHeightForFont;

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

- (NSStringEncoding) mostCompatibleStringEncoding;

@end

#ifndef	STRICT_OPENSTEP
@class GSFontInfo;

@interface NSFont (GNUstep)
- (GSFontInfo*) fontInfo;
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

#endif // _GNUstep_H_NSFont
