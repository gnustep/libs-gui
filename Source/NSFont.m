/* 
   NSFont.m

   The font class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: February 1997
   A completely rewritten version of the original source by Scott Christley.
   
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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSSet.h>

#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/GSFontInfo.h>

@implementation NSFont

/* Class variables */

/* Register all the fonts used by the current print operation to be able to
   dump the %%DocumentFonts comment required by the Adobe Document Structuring
   Convention (see the red book). */
static NSMutableSet* fontsUsed = nil;

NSFont* getNSFont(NSString* key, NSString* defaultFontName,
		  float fontSize)
{
  NSString* fontName;

  fontName = [[NSUserDefaults standardUserDefaults] objectForKey:key];
  if (!fontName)
    fontName = defaultFontName;

  if (!fontSize) {
    fontSize = [[NSUserDefaults standardUserDefaults]
		    floatForKey:[NSString stringWithFormat:@"%@Size", key]];
    if (!fontSize)
      fontSize = 12;
  }

  return [NSFont fontWithName:fontName size:fontSize];
}

void setNSFont(NSString* key, NSFont* font)
{
  NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];

  [standardDefaults setObject:[font fontName] forKey:key];

  /* Don't care about errors */
  [standardDefaults synchronize];
}

//
// Class methods
//
+ (void)initialize
{
  static BOOL initialized = NO;

  if (!initialized) {
    initialized = YES;
    fontsUsed = [NSMutableSet new];
  }
}

/* Getting the preferred user fonts */

// This is deprecated in MacOSX
+ (NSFont*)boldSystemFontOfSize:(float)fontSize
{
  return getNSFont (@"NSBoldFont", @"Helvetica-Bold", fontSize);
}

// This is deprecated in MacOSX
+ (NSFont*)systemFontOfSize:(float)fontSize
{
  return getNSFont (@"NSFont", @"Helvetica", fontSize);
}

+ (NSFont*)userFixedPitchFontOfSize:(float)fontSize
{
  return getNSFont (@"NSUserFixedPitchFont", @"Courier", fontSize);
}

+ (NSFont*)userFontOfSize:(float)fontSize
{
  return getNSFont (@"NSUserFont", @"Helvetica", fontSize);
}

/* Setting the preferred user fonts */

+ (void)setUserFixedPitchFont:(NSFont*)font
{
  setNSFont (@"NSUserFixedPitchFont", font);
}

+ (void)setUserFont:(NSFont*)font
{
  setNSFont (@"NSUserFont", font);
}

/* Getting various fonts */

#ifndef STRICT_OPENSTEP
+ (NSFont *)controlContentFontOfSize:(float)fontSize
{
  return [NSFont fontWithName:@"Helvetica" size:fontSize];
}

+ (NSFont *)menuFontOfSize:(float)fontSize
{
  return [NSFont fontWithName:@"Helvetica" size:fontSize];
}

+ (NSFont *)titleBarFontOfSize:(float)fontSize
{
  return [self boldSystemFontOfSize:fontSize];
}

+ (NSFont *)messageFontOfSize:(float)fontSize
{
  return [self systemFontOfSize:fontSize];
}

+ (NSFont *)paletteFontOfSize:(float)fontSize
{
  // Not sure on this one.
  return [self boldSystemFontOfSize:fontSize];
}

+ (NSFont *)toolTipsFontOfSize:(float)fontSize
{
  // Not sure on this one.
  return [NSFont fontWithName:@"Helvetica" size:fontSize];
}
#endif

- initWithName:(NSString*)name matrix:(const float*)fontMatrix
{
  [fontsUsed addObject:name];
  fontName = RETAIN(name);
  memcpy(matrix, fontMatrix, sizeof(matrix));
  fontInfo = RETAIN([GSFontInfo fontInfoForFontName: name matrix: fontMatrix]);
  return self;
}

+ (NSFont*)fontWithName:(NSString*)name 
		 matrix:(const float*)fontMatrix
{
  return AUTORELEASE([[NSFont alloc] initWithName: name matrix: fontMatrix]);
}

+ (NSFont*)fontWithName:(NSString*)name
		   size:(float)fontSize
{
  NSFont *font;
  float fontMatrix[6] = { fontSize, 0, 0, fontSize, 0, 0 };

  font = [self fontWithName: name matrix: fontMatrix];
  font->matrixExplicitlySet = NO;
  return font;
}

+ (void)useFont:(NSString*)name
{
  [fontsUsed addObject:name];
}

//
// Instance methods
//
- (void)dealloc
{
  RELEASE(fontName);
  RELEASE(fontInfo);
  [super dealloc];
}

//
// NSCopying Protocol
//
- copyWithZone: (NSZone *)zone
{
  NSFont *new_font;
  if (NSShouldRetainWithZone(self, zone))
    new_font = RETAIN(self);
  else
    {
      new_font = (NSFont *)NSCopyObject(self, 0, zone);
      [new_font->fontName copyWithZone: zone];
      [new_font->fontInfo copyWithZone: zone];
    }
  return new_font;
}

//
// Setting the Font
//
- (void)set
{
  [fontInfo set];
}

//
// Querying the Font
//
- (float)pointSize		{ return [fontInfo pointSize]; }
- (NSString*)fontName		{ return fontName; }
- (const float*)matrix		{ return matrix; }

- (NSString *)encodingScheme	{ return [fontInfo encodingScheme]; }
- (NSString*)familyName		{ return [fontInfo familyName]; }
- (NSRect)boundingRectForFont	{ return [fontInfo boundingRectForFont]; }
- (BOOL)isFixedPitch		{ return [fontInfo isFixedPitch]; }
- (BOOL)isBaseFont		{ return [fontInfo isBaseFont]; }

/* Usually the display name of font is the font name. */
- (NSString*)displayName	{ return fontName; }

- (NSDictionary*)afmDictionary	{ return [fontInfo afmDictionary]; }
- (NSString*)afmFileContents	{ return [fontInfo afmFileContents]; }
- (NSFont*)printerFont		{ return self; }
- (NSFont*)screenFont		{ return self; }
- (float)ascender		{ return [fontInfo ascender]; }
- (float)descender		{ return [fontInfo descender]; }
- (float)capHeight		{ return [fontInfo capHeight]; }
- (float)italicAngle		{ return [fontInfo italicAngle]; }
- (NSSize)maximumAdvancement	{ return [fontInfo maximumAdvancement]; }
- (NSSize)minimumAdvancement	{ return [fontInfo minimumAdvancement]; }
- (float)underlinePosition	{ return [fontInfo underlinePosition]; }
- (float)underlineThickness	{ return [fontInfo underlineThickness]; }
- (float)xHeight		{ return [fontInfo xHeight]; }

/* Computing font metrics attributes */
- (float)widthOfString:(NSString*)string
{
  return [fontInfo widthOfString: string];
}

- (float*)widths
{
  return [fontInfo widths];
}

/* The following methods have to implemented by backends */

//
// Manipulating Glyphs
//
- (NSSize)advancementForGlyph:(NSGlyph)aGlyph
{
  return [fontInfo advancementForGlyph: aGlyph];
}

- (NSRect)boundingRectForGlyph:(NSGlyph)aGlyph
{
  return [fontInfo boundingRectForGlyph: aGlyph];
}

- (BOOL)glyphIsEncoded:(NSGlyph)aGlyph
{
  return [fontInfo glyphIsEncoded: aGlyph ];
}

- (NSGlyph)glyphWithName:(NSString*)glyphName
{
  return [fontInfo glyphWithName: glyphName ];
}

- (NSPoint)positionOfGlyph:(NSGlyph)curGlyph
	   precededByGlyph:(NSGlyph)prevGlyph
		 isNominal:(BOOL *)nominal
{
  return [fontInfo positionOfGlyph: curGlyph precededByGlyph: prevGlyph
                         isNominal: nominal];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: fontName];
  [aCoder encodeArrayOfObjCType: @encode(float) count: 6 at: matrix];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &fontName];
  [aDecoder decodeArrayOfObjCType: @encode(float) count: 6 at: matrix];
  return [[self class] fontWithName: fontName matrix: matrix];
}

@end /* NSFont */
