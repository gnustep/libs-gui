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

#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSSet.h>

#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>

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

+ (NSFont*)boldSystemFontOfSize:(float)fontSize
{
  return getNSFont (@"NSBoldFont", @"Helvetica-Bold", fontSize);
}

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

/* The following method should be rewritten in the backend and it has to be
   called as part of the implementation. */
+ (NSFont*)fontWithName:(NSString*)name 
		 matrix:(const float*)fontMatrix
{
  [fontsUsed addObject:name];
  return nil;
}

+ (NSFont*)fontWithName:(NSString*)name
		   size:(float)fontSize
{
  float fontMatrix[6] = { fontSize, 0, 0, fontSize, 0, 0 };

  return [self fontWithName:name matrix:fontMatrix];
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
  [fontName release];
  [super dealloc];
}

//
// Setting the Font
//
- (void)set
{
}

//
// Querying the Font
//
- (float)pointSize			{ return matrix[3]; }
- (NSString*)fontName			{ return fontName; }
- (const float*)matrix			{ return matrix; }

/* The backends should rewrite the following methods to provide a more
   appropiate behavior than these. */

- (NSString *)encodingScheme		{ return nil; }
- (NSString*)familyName			{ return nil; }
- (NSRect)boundingRectForFont		{ return NSZeroRect; }
- (BOOL)isFixedPitch			{ return NO; }
- (BOOL)isBaseFont			{ return YES; }

/* Usually the display name of font is the font name. */
- (NSString*)displayName		{ return fontName; }

- (NSDictionary*)afmDictionary		{ return nil; }
- (NSString*)afmFileContents		{ return nil; }
- (NSFont*)printerFont			{ return self; }
- (NSFont*)screenFont			{ return self; }
- (float)ascender			{ return 0.0; }
- (float)descender			{ return 0.0; }
- (float)capHeight			{ return 0.0; }
- (float)italicAngle			{ return 0.0; }
- (NSSize)maximumAdvancement		{ return NSZeroSize; }
- (NSSize)minimumAdvancement		{ return NSZeroSize; }
- (float)underlinePosition		{ return 0.0; }
- (float)underlineThickness		{ return 0.0; }
- (float)xHeight			{ return 0.0; }

/* Computing font metrics attributes */
- (float)widthOfString:(NSString*)string
{
  return 0;
}

- (float*)widths
{
  return NULL;
}

/* The following methods have to implemented by backends */

//
// Manipulating Glyphs
//
- (NSSize)advancementForGlyph:(NSGlyph)aGlyph
{
  return NSZeroSize;
}

- (NSRect)boundingRectForGlyph:(NSGlyph)aGlyph
{
  return NSZeroRect;
}

- (BOOL)glyphIsEncoded:(NSGlyph)aGlyph
{
  return NO;
}

- (NSGlyph)glyphWithName:(NSString*)glyphName
{
  return -1;
}

- (NSPoint)positionOfGlyph:(NSGlyph)curGlyph
	   precededByGlyph:(NSGlyph)prevGlyph
		 isNominal:(BOOL *)nominal
{
  return NSZeroPoint;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [aCoder encodeObject:fontName];
  [aCoder encodeArrayOfObjCType:"f" count:6 at:matrix];
}

- initWithCoder:aDecoder
{
  fontName = [aDecoder decodeObject];
  [aDecoder decodeArrayOfObjCType:"f" count:6 at:matrix];

  return self;
}

@end /* NSFont */
