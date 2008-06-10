/*
   GSFontInfo

   Private class for handling font info

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Mar 2000
   
   This file is part of the GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <math.h>

#include "GNUstepGUI/GSFontInfo.h"
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSException.h>

static Class fontEnumeratorClass = Nil;
static Class fontInfoClass = Nil;

static GSFontEnumerator *sharedEnumerator = nil;

@implementation GSFontEnumerator

+ (void) setDefaultClass: (Class)defaultClass
{
  fontEnumeratorClass = defaultClass;
}

- (id) init
{
  [super init];
  [self enumerateFontsAndFamilies];

  return self;
}

- (void) dealloc
{
  RELEASE(allFontNames);
  RELEASE(allFontFamilies);
  [super dealloc];
}

+ (GSFontEnumerator*) sharedEnumerator
{
  NSAssert(fontEnumeratorClass,
    @"Called with fontEnumeratorClass unset."
    @" The shared NSApplication instance must be created before methods that"
    @" need the backend may be called.");
  if (!sharedEnumerator)
    sharedEnumerator = [[fontEnumeratorClass alloc] init];
  return sharedEnumerator;
}

- (void) enumerateFontsAndFamilies
{
  // This method has to set up the ivars allFontNames and allFontFamilies
  [self subclassResponsibility: _cmd];
}

- (NSArray*) availableFonts
{
  return allFontNames;
}

- (NSArray*) availableFontFamilies
{
  return [[allFontFamilies allKeys] sortedArrayUsingSelector:
    @selector(compare:)];
}

- (NSArray*) availableMembersOfFontFamily: (NSString*)family
{
  return [allFontFamilies objectForKey: family];
}


- (NSString *) defaultSystemFontName
{
  return @"Helvetica";
}

- (NSString *) defaultBoldSystemFontName
{
  return @"Helvetica-Bold";
}

- (NSString *) defaultFixedPitchFontName
{
  return @"Courier";
}

@end

@interface GSFontInfo (Backend)
-initWithFontName: (NSString *)fontName
	   matrix: (const float *)fmatrix
       screenFont: (BOOL)screenFont;
@end

@implementation GSFontInfo

+ (void) setDefaultClass: (Class)defaultClass
{
  fontInfoClass = defaultClass;
}

+ (GSFontInfo*) fontInfoForFontName: (NSString*)nfontName 
                             matrix: (const float *)fmatrix
			 screenFont: (BOOL)screenFont;
{
  NSAssert(fontInfoClass,
    @"Called with fontInfoClass unset."
    @" The shared NSApplication instance must be created before methods that"
    @" need the backend may be called.");
  return AUTORELEASE([[fontInfoClass alloc] initWithFontName: nfontName 
						      matrix: fmatrix
						  screenFont: screenFont]);
}

+ (int) weightForString: (NSString *)weightString
{
  static NSDictionary *dict = nil;
  NSNumber *num;
  
  if (dict == nil)
    {
      dict = [NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithInt: 1], @"ultralight",
	[NSNumber numberWithInt: 2], @"thin",
	[NSNumber numberWithInt: 3], @"light",
	[NSNumber numberWithInt: 3], @"extralight",
	[NSNumber numberWithInt: 4], @"book",
	[NSNumber numberWithInt: 5], @"regular",
	[NSNumber numberWithInt: 5], @"plain",
	[NSNumber numberWithInt: 5], @"display",
	[NSNumber numberWithInt: 5], @"roman",
	[NSNumber numberWithInt: 5], @"semilight",
	[NSNumber numberWithInt: 6], @"medium",
	[NSNumber numberWithInt: 7], @"demi",
	[NSNumber numberWithInt: 7], @"demibold",
	[NSNumber numberWithInt: 8], @"semi",
	[NSNumber numberWithInt: 8], @"semibold",
	[NSNumber numberWithInt: 9], @"bold",
	[NSNumber numberWithInt: 10], @"extra",
	[NSNumber numberWithInt: 10], @"extrabold",
	[NSNumber numberWithInt: 11], @"heavy",
	[NSNumber numberWithInt: 11], @"heavyface",
	[NSNumber numberWithInt: 12], @"ultrabold",
	[NSNumber numberWithInt: 12], @"black",
	[NSNumber numberWithInt: 13], @"ultra",
	[NSNumber numberWithInt: 13], @"ultrablack",
	[NSNumber numberWithInt: 13], @"fat",
	[NSNumber numberWithInt: 14], @"extrablack",
	[NSNumber numberWithInt: 14], @"obese",
	[NSNumber numberWithInt: 14], @"nord",
	nil];
      RETAIN(dict);
    }

  if ((weightString == nil) || 
      ((num = [dict objectForKey: weightString]) == nil))
    {
      return 5;
    } 
  else
    {
      return [num intValue];
    }
}

+ (NSString *) stringForWeight: (int)aWeight
{
  static NSArray *arr = nil;

  if (arr == nil)
    {
      arr = [NSArray arrayWithObjects: @"", @"ultralight",
	@"thin", @"light", @"book", @"regular",
	@"medium", @"demibold", @"semibold",
	@"bold", @"extrabold", @"heavy",
	@"black", @"ultrablack", @"extrablack", 
	nil];
      RETAIN(arr);
    }

  if ((aWeight < 1) || (aWeight > 14))
    return @"";
  else
    return [arr objectAtIndex: aWeight];
}

- init
{
  [super init];
  mostCompatibleStringEncoding = NSASCIIStringEncoding;

  return self;
}

- (void) dealloc
{
  RELEASE(coveredCharacterSet);
  RELEASE(fontDictionary);
  RELEASE(fontName);
  RELEASE(familyName);
  RELEASE(encodingScheme);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
  GSFontInfo *copy;
  if (NSShouldRetainWithZone(self, zone))
    copy = RETAIN(self);
  else
    {
      copy = (GSFontInfo*) NSCopyObject (self, 0, zone);
      copy->fontDictionary = [fontDictionary copyWithZone: zone];
      copy->fontName = [fontName copyWithZone: zone];
      copy->familyName = [familyName copyWithZone: zone];
      copy->encodingScheme = [encodingScheme copyWithZone: zone];
    }
  return copy;
}

/* We really want a mutable class for this, but this is quick and easy since
   it's not really a public class anyway */
- (id) mutableCopyWithZone: (NSZone *)zone
{
  GSFontInfo *copy;
  copy = (GSFontInfo*) NSCopyObject (self, 0, zone);
  copy->fontDictionary = [fontDictionary copyWithZone: zone];
  copy->fontName = [fontName copyWithZone: zone];
  copy->familyName = [familyName copyWithZone: zone];
  copy->encodingScheme = [encodingScheme copyWithZone: zone];
  return copy;
}

- (void) set
{
  [self subclassResponsibility: _cmd];
}

- (NSDictionary*) afmDictionary
{
  if (fontDictionary == nil)
    {
      NSString *weightString;

      fontDictionary = [[NSMutableDictionary alloc] initWithCapacity: 25];
      
      [fontDictionary setObject: fontName forKey: NSAFMFontName];
      if (familyName != nil)
        {
	  [fontDictionary setObject: familyName 
			  forKey: NSAFMFamilyName];
	}
      if (ascender != 0.0)
        {
	  [fontDictionary setObject: [NSNumber numberWithFloat: ascender] 
			  forKey: NSAFMAscender];
	}
      if (descender != 0.0)
        {
	  [fontDictionary setObject: [NSNumber numberWithFloat: descender]
			  forKey: NSAFMDescender];
	}
      if (xHeight != 0.0)
        {
	  [fontDictionary setObject: [NSNumber numberWithFloat: xHeight]
			  forKey: NSAFMXHeight];
	}
      if (capHeight != 0.0)
        {
	  [fontDictionary setObject: [NSNumber numberWithFloat: capHeight]
			  forKey: NSAFMCapHeight];
	}
      if (italicAngle != 0.0)
        {
	  [fontDictionary setObject: [NSNumber numberWithFloat: italicAngle]
			  forKey: NSAFMItalicAngle];
	}
      if (underlinePosition != 0.0)
        {
	  [fontDictionary setObject: [NSNumber numberWithFloat: underlinePosition]
			  forKey: NSAFMUnderlinePosition];
	}
      if (underlineThickness != 0.0)
        {
	  [fontDictionary setObject: [NSNumber numberWithFloat: underlineThickness]
			  forKey: NSAFMUnderlineThickness];
	}

      weightString = [GSFontInfo stringForWeight: weight];      
      if (weightString != nil)
        {
	  [fontDictionary setObject: weightString forKey: NSAFMWeight];
	}
      if (encodingScheme != nil)
        {
	  [fontDictionary setObject: encodingScheme
			  forKey: NSAFMEncodingScheme];
	}

    }
  return fontDictionary;
}

- (NSString *) afmFileContents
{
  return nil;
}

- (NSCharacterSet*) coveredCharacterSet
{
  return coveredCharacterSet;
}

- (NSString*) encodingScheme
{ 
  return encodingScheme; 
}

- (NSRect) boundingRectForFont
{
  return fontBBox;
}

- (NSString*) displayName
{
  return familyName;
}

- (NSString*) familyName
{
  return familyName;
}

- (const float*) matrix
{
  return matrix;
}

- (unsigned) numberOfGlyphs
{
  return numberOfGlyphs;
}

- (float) pointSize
{
  return matrix[0];
}

- (NSString*) fontName
{
  return fontName;
}

- (BOOL) isBaseFont
{ 
  return isBaseFont; 
}

- (BOOL) isFixedPitch
{ 
  return isFixedPitch; 
}

- (float) ascender
{ 
  return ascender; 
}

- (float) descender
{ 
  return descender; 
}

- (float) capHeight
{ 
  return capHeight; 
}

- (float) italicAngle
{ 
  return italicAngle; 
}

- (NSSize) maximumAdvancement
{ 
  return maximumAdvancement; 
}

- (NSSize) minimumAdvancement
{ 
  return minimumAdvancement; 
}

- (float) underlinePosition
{ 
  return underlinePosition; 
}

- (float) underlineThickness
{ 
  return underlineThickness; 
}

- (float) xHeight
{ 
  return xHeight; 
}

- (float) defaultLineHeightForFont
{
  /*
  In the absence of a more accurate line height from the font itself, we
  use ascender_height+descender_height (note that descender is negative
  below the baseline). This matches what other systems do, and it matches
  the font-provided line height in most cases. (Note that the ascender
  height usually includes a bit of space above the top of the actual
  glyphs, so we get some inter-line spacing anyway.)

  This calculation should match the baseline calculation in
  GSHorizontalTypesetter, or text will look odd.
  */
  return [self ascender] - [self descender];
}

- (NSSize) advancementForGlyph: (NSGlyph)aGlyph
{
  return NSMakeSize (0,0);
}

- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph
{
  return NSZeroRect;
}

- (BOOL) glyphIsEncoded: (NSGlyph)aGlyph;
{
  // FIXME: This is a hack for aGlyph == theChar fonts.
  if (coveredCharacterSet == nil)
    {
      [self coveredCharacterSet];
    }
  return [coveredCharacterSet characterIsMember: (unichar)aGlyph];
}

- (NSMultibyteGlyphPacking) glyphPacking
{
  return NSOneByteGlyphPacking;
}

- (NSGlyph) glyphWithName: (NSString*)glyphName
{
  return 0;
}

- (NSPoint) positionOfGlyph: (NSGlyph)curGlyph
	    precededByGlyph: (NSGlyph)prevGlyph
		  isNominal: (BOOL *)nominal
{
  NSSize advance;

  if (nominal)
    *nominal = YES;

  if (curGlyph == NSControlGlyph || prevGlyph == NSControlGlyph)
    return NSZeroPoint;

  if (curGlyph == NSNullGlyph)
    advance = [self advancementForGlyph: prevGlyph];
  else 
    // Should check kerning
    advance = [self advancementForGlyph: prevGlyph];

  return NSMakePoint (advance.width, advance.height); 
}

- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
	       forCharacter: (unichar)aChar 
	     struckOverRect: (NSRect)aRect
{
  return NSZeroPoint;
}

- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
	    struckOverGlyph: (NSGlyph)baseGlyph 
	       metricsExist: (BOOL *)flag
{
  if (flag)
    *flag = NO;

  return NSZeroPoint;
}

- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
	     struckOverRect: (NSRect)aRect 
	       metricsExist: (BOOL *)flag
{
  if (flag)
    *flag = NO;

  return NSZeroPoint;
}

- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph 
	       withRelation: (NSGlyphRelation)relation 
		toBaseGlyph: (NSGlyph)baseGlyph
	   totalAdvancement: (NSSize *)offset 
	       metricsExist: (BOOL *)flag
{
  NSRect baseRect = [self boundingRectForGlyph: baseGlyph];
  NSPoint point = NSZeroPoint;

  if (flag)
    *flag = NO;

  if (relation == NSGlyphBelow)
    {
      point = baseRect.origin;
    }
  else
    {
      point = NSMakePoint (baseRect.origin.x, NSMaxY (baseRect));
    }

  if (offset)
    {
       NSSize baseSize = [self advancementForGlyph: baseGlyph];
       NSSize aSize = [self advancementForGlyph: aGlyph];

       if (baseSize.width > aSize.width)
	 *offset = baseSize;
       else
	 *offset = aSize;
    }

  return point;
}

- (NSStringEncoding) mostCompatibleStringEncoding
{
  return mostCompatibleStringEncoding;
}

- (float) widthOfString: (NSString*)string
{
  return 0;
}

- (NSFontTraitMask) traits
{
  return traits;
}

- (int) weight
{
  return weight;
}

-(void) appendBezierPathWithGlyphs: (NSGlyph *)glyphs
			     count: (int)count
		      toBezierPath: (NSBezierPath *)path
{
  [self subclassResponsibility: _cmd];
}

- (NSGlyph) glyphForCharacter: (unichar)theChar
{
  // Hack to get most font backends working
  if ([self glyphIsEncoded: (NSGlyph)theChar])
    return (NSGlyph)theChar;
  else
    return NSNullGlyph;
}

@end
