/* 
   NSFont.m

   The font class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSFont.h>
#include <gnustep/gui/NSFontManager.h>

NSFont *gnustep_gui_user_fixed_font;
NSFont *gnustep_gui_user_font;

// Global Strings
NSString *NSAFMAscender;
NSString *NSAFMCapHeight;
NSString *NSAFMCharacterSet;
NSString *NSAFMDescender;
NSString *NSAFMEncodingScheme;
NSString *NSAFMFamilyName;
NSString *NSAFMFontName;
NSString *NSAFMFormatVersion;
NSString *NSAFMFullName;
NSString *NSAFMItalicAngle;
NSString *NSAFMMappingScheme;
NSString *NSAFMNotice;
NSString *NSAFMUnderlinePosition;
NSString *NSAFMUnderlineThickness;
NSString *NSAFMVersion;
NSString *NSAFMWeight;
NSString *NSAFMXHeight;

@implementation NSFont

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSFont class])
    {
      NSLog(@"Initialize NSFont class\n");

      // Initial version
      [self setVersion:1];
    }
}

//
// Creating a Font Object
//
+ (NSFont *)boldSystemFontOfSize:(float)fontSize
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  NSFont *f;

  f = [fm fontWithFamily:@"Times New Roman" traits:NSBoldFontMask 
	  weight:0 size:fontSize];
  return f;
}

+ (NSFont *)fontWithName:(NSString *)fontName 
		  matrix:(const float *)fontMatrix
{
  return nil;
}

+ (NSFont *)fontWithName:(NSString *)fontName
		    size:(float)fontSize
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  NSFont *f;

  f = [fm fontWithFamily:fontName traits:0 weight:0 size:fontSize];
  return f;
}

+ (NSFont *)systemFontOfSize:(float)fontSize
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  NSFont *f;

  f = [fm fontWithFamily:@"Times New Roman" traits:0 weight:0 size:fontSize];
  return f;
}

+ (NSFont *)userFixedPitchFontOfSize:(float)fontSize
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  return [fm convertFont:gnustep_gui_user_fixed_font toSize:fontSize];
}

+ (NSFont *)userFontOfSize:(float)fontSize
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  return [fm convertFont:gnustep_gui_user_font toSize:fontSize];
}

//
// Setting the Font
//
+ (void)setUserFixedPitchFont:(NSFont *)aFont
{
  gnustep_gui_user_fixed_font = aFont;
}

+ (void)setUserFont:(NSFont *)aFont
{
  gnustep_gui_user_font = aFont;
}

+ (void)useFont:(NSString *)fontName
{}

//
// Instance methods
//
- (void)dealloc
{
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
- (NSDictionary *)afmDictionary
{
  return nil;
}

- (NSString *)afmFileContents
{
  return nil;
}

- (NSRect)boundingRectForFont
{
  return NSZeroRect;
}

- (NSString *)displayName
{
  return nil;
}

- (NSString *)familyName
{
  return family_name;
}

- (void)setFamilyName:(NSString *)familyName
{
  family_name = familyName;
}

- (NSString *)fontName
{
  return font_name;
}

- (BOOL)isBaseFont
{
  return NO;
}

- (const float *)matrix
{
  return NULL;
}

- (float)pointSize
{
  return point_size;
}

- (void)setPointSize:(float)value
{
  point_size = value;
}

- (NSFont *)printerFont
{
  return nil;
}

- (NSFont *)screenFont
{
  return nil;
}

- (float)widthOfString:(NSString *)string
{
  /* bogus estimate */
  if (string)
    return (8.0 * (float)[string length]);
  else
    return 0;
}

- (float *)widths
{
  return NULL;
}
- (NSFontTraitMask)traits
{
  return font_traits;
}

- (void)setTraits:(NSFontTraitMask)traits
{
  font_traits = traits;
}

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
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: family_name];
  [aCoder encodeObject: font_name];
  [aCoder encodeValueOfObjCType: "f" at: &point_size];
  [aCoder encodeValueOfObjCType: @encode(NSFontTraitMask) at: &font_traits];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  family_name = [aDecoder decodeObject];
  font_name = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: "f" at: &point_size];
  [aDecoder decodeValueOfObjCType: @encode(NSFontTraitMask) at: &font_traits];

  return self;
}

@end
