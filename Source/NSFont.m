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
#include <gnustep/gui/NSFontPrivate.h>

NSFont *gnustep_gui_user_fixed_font;
NSFont *gnustep_gui_user_font;
NSString *gnustep_gui_system_family = @"";

// Global Strings
NSString *NSAFMAscender = @"AFMAscender";
NSString *NSAFMCapHeight = @"AFMCapHeight";
NSString *NSAFMCharacterSet = @"AFMCharacterSet";
NSString *NSAFMDescender = @"AFMDescender";
NSString *NSAFMEncodingScheme = @"AFMEncodingScheme";
NSString *NSAFMFamilyName = @"AFMFamilyName";
NSString *NSAFMFontName = @"AFMFontName";
NSString *NSAFMFormatVersion = @"AFMFormatVersion";
NSString *NSAFMFullName = @"AFMFullName";
NSString *NSAFMItalicAngle = @"AFMItalicAngle";
NSString *NSAFMMappingScheme = @"AFMMappingScheme";
NSString *NSAFMNotice = @"AFMNotice";
NSString *NSAFMUnderlinePosition = @"AFMUnderlinePosition";
NSString *NSAFMUnderlineThickness = @"AFMUnderlineThickness";
NSString *NSAFMVersion = @"AFMVersion";
NSString *NSAFMWeight = @"AFMWeight";
NSString *NSAFMXHeight = @"AFMXHeight";

@implementation NSFont

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSFont class])
    {
      NSDebugLog(@"Initialize NSFont class\n");

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

  f = [fm fontWithFamily:gnustep_gui_system_family traits:NSBoldFontMask 
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

  // +++ We need to extract the family name from the font name
  f = [fm fontWithFamily:fontName traits:0 weight:400 size:fontSize];
  return f;
}

+ (NSFont *)systemFontOfSize:(float)fontSize
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  NSFont *f;

  f = [fm fontWithFamily:gnustep_gui_system_family traits:0 
	  weight:400 size:fontSize];
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
- init
{
  [super init];

  family_name = @"";
  font_name = @"";
  type_face = @"";

  return self;
}

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

- (NSFont *)printerFont
{
  return self;
}

- (NSFont *)screenFont
{
  return self;
}

- (float)widthOfString:(NSString *)string
{
  return 0;
}

- (float *)widths
{
  return NULL;
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

@implementation NSFont (GNUstepPrivate)

- (void)setFamilyName:(NSString *)familyName
{
  NSMutableString *s = [NSMutableString stringWithCString: ""];

  // New family name so new font name
  // Format is family name, dash, typeface
  family_name = familyName;
  [s appendString: family_name];

  if ([type_face compare: @""] != NSOrderedSame)
    {
      [s appendString: @"-"];
      [s appendString: type_face];
    }
  font_name = s;
}

- (void)setFontName:(NSString *)fontName
{
  font_name = fontName;
}

- (void)setPointSize:(float)value
{
  point_size = value;
}

- (NSFontTraitMask)traits
{
  return font_traits;
}

- (void)setTraits:(NSFontTraitMask)traits
{
  // Only if the traits have changed
  if (font_traits != traits)
    {
      // Figure out a new typeface
      NSMutableString *s = [NSMutableString stringWithCString: ""];

      // Bold
      if (traits & NSBoldFontMask)
	[s appendString: @"Bold"];

      // +++ How do we determine whether to use Italic or Oblique?
      if (traits & NSItalicFontMask)
	[s appendString: @"Italic"];

      [self setTypeface: s];
    }
  font_traits = traits;
}

- (int)weight
{
  return font_weight;
}

- (void)setWeight:(int)value
{
  NSFontTraitMask t = font_traits;

  font_weight = value;
  // Make the font bold or unbold based upon the weight
  if (font_weight <= 400)
    t = t ^ NSUnboldFontMask;
  else
    t = t ^ NSBoldFontMask;
  [self setTraits:t];
}

- (NSString *)typeface
{
  return type_face;
}

- (void)setTypeface:(NSString *)str
{
  NSMutableString *s = [NSMutableString stringWithCString: ""];

  // New typeface so new font name
  // Format is family name, dash, typeface
  type_face = str;
  [s appendString: family_name];

  if ([type_face compare: @""] != NSOrderedSame)
    {
      [s appendString: @"-"];
      [s appendString: type_face];
    }
  font_name = s;
}

@end
