/* 
   NSFont.h

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

#ifndef _GNUstep_H_NSFont
#define _GNUstep_H_NSFont

#include <AppKit/stdappkit.h>
#include <Foundation/NSCoder.h>

@interface NSFont : NSObject <NSCoding>

{
  // Attributes
  NSString *family_name;
  NSString *font_name;
  float point_size;
  NSFontTraitMask font_traits;

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
- (void)setFamilyName:(NSString *)familyName;
- (NSString *)fontName;
- (BOOL)isBaseFont;
- (const float *)matrix;
- (float)pointSize;
- (void)setPointSize:(float)value;
- (NSFont *)printerFont;
- (NSFont *)screenFont;
- (float)widthOfString:(NSString *)string;
- (float *)widths;
- (NSFontTraitMask)traits;
- (void)setTraits:(NSFontTraitMask)traits;

//
// Manipulating Glyphs
//
- (NSSize)advancementForGlyph:(NSGlyph)aGlyph;
- (NSRect)boundingRectForGlyph:(NSGlyph)aGlyph;
- (BOOL)glyphIsEncoded:(NSGlyph)aGlyph;
- (NSPoint)positionOfGlyph:(NSGlyph)curGlyph
	   precededByGlyph:(NSGlyph)prevGlyph
isNominal:(BOOL *)nominal;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSFont
