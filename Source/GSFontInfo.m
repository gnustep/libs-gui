/*
   GSFontInfo

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

#include <AppKit/GSFontInfo.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSValue.h>

static Class fontEnumeratorClass = Nil;
static Class fontInfoClass = Nil;

static GSFontEnumerator *sharedEnumerator = nil;

@interface NSFontManager (GNUstepBackend)
- (BOOL) _includeFont: (NSString*)fontName;
@end

@implementation GSFontEnumerator

+ (void) setDefaultClass: (Class)defaultClass
{
  fontEnumeratorClass = defaultClass;
}

- initWithFontManager: manager
{
  [super init];
  fontManager = manager;
  return self;
}

+ sharedEnumeratorWithFontManager: manager
{
  if (!sharedEnumerator)
    sharedEnumerator = [[fontEnumeratorClass alloc] 
			        initWithFontManager: manager];
  return sharedEnumerator;
}

- (NSArray*) allFonts
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (NSArray*) availableFonts
{
  int		i;
  NSArray	*fontsList;
  NSMutableArray *fontNames;

  fontsList = [self allFonts];
  fontNames = [NSMutableArray arrayWithCapacity: [fontsList count]];

  for (i = 0; i < [fontsList count]; i++)
    {
      GSFontInfo *font = (GSFontInfo*)[fontsList objectAtIndex: i];
      NSString	 *name = [font fontName];
      
      if ([fontManager _includeFont: name])
	[fontNames addObject: name];
    }

  return fontNames;
}

- (NSArray*) availableFontFamilies
{
  int		i;
  NSArray	*fontsList;
  NSMutableSet	*fontFamilies;

  fontsList = [self allFonts];
  fontFamilies = [NSMutableSet setWithCapacity: [fontsList count]];
  for (i = 0; i < [fontsList count]; i++)
    {
      GSFontInfo *font = (GSFontInfo*)[fontsList objectAtIndex: i];

      [fontFamilies addObject: [font familyName]];
    }

  return [fontFamilies allObjects];
}

- (NSArray*) availableMembersOfFontFamily: (NSString*)family
{
  int i, j;
  NSArray *fontFamilies = [self availableFontFamilies];
  NSMutableArray *fontNames = [NSMutableArray array];
  NSFontTraitMask traits;

  for (i = 0; i < [fontFamilies count]; i++)
    {
      NSArray *fontDefs = [self availableMembersOfFontFamily: 
				  [fontFamilies objectAtIndex: i]];
      
      for (j = 0; j < [fontDefs count]; j++)
	{
	  NSArray	*fontDef = [fontDefs objectAtIndex: j];

	  traits = [[fontDef objectAtIndex: 3] unsignedIntValue];
	  // Check if the font has exactly the given mask
	  //if (traits == fontTraitMask)
	    {
	      NSString *name = [fontDef objectAtIndex: 0];
	
	      if ([fontManager _includeFont: name])
		[fontNames addObject: name];
	    }
	}
    }

  return fontNames;
}

@end

@interface GSFontInfo (Backend)
-initWithFontName: (NSString *)fontName matrix: (const float *)fmatrix;
@end

@implementation GSFontInfo

+ (void) setDefaultClass: (Class)defaultClass
{
  fontInfoClass = defaultClass;
}

+ (GSFontInfo*) fontInfoForFontName: (NSString*)nfontName 
                             matrix: (const float *)fmatrix;
{
  return AUTORELEASE([[fontInfoClass alloc] initWithFontName: nfontName 
                                                     matrix: fmatrix]);
}

- init
{
  [super init];
  ASSIGN(fontDictionary, [NSMutableDictionary dictionaryWithCapacity:25]);
  weight = 0;
  traits = 0;
  mostCompatibleStringEncoding = NSASCIIStringEncoding;

  return self;
}

- (void) dealloc
{
  RELEASE(fontDictionary);
  RELEASE(fontName);
  RELEASE(familyName);
  RELEASE(encodingScheme);
  [super dealloc];
}

- copyWithZone: (NSZone *)zone
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
- mutableCopyWithZone: (NSZone *)zone
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
  return fontDictionary;
}

- (NSString *)afmFileContents
{
  return nil;
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

- (float)defaultLineHeightForFont
{
  // ascent plus descent plus some suitable linegap
  return [self ascender] + [self descender] + [self pointSize]/ 11.0;
}

- (NSSize) advancementForGlyph: (NSGlyph)aGlyph
{
  return NSMakeSize(0,0);
}

- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph
{
  return NSZeroRect;
}

- (BOOL) glyphIsEncoded: (NSGlyph)aGlyph;
{
  return NO;
}

- (NSMultibyteGlyphPacking)glyphPacking
{
  return NSOneByteGlyphPacking;
}

- (NSGlyph) glyphWithName: (NSString*)glyphName
{
  return 0;
}

- (NSPoint) positionOfGlyph: (NSGlyph)curGlyph
	    precededByGlyph: (NSGlyph)prevGlyph
		  isNominal: (BOOL*)nominal
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

  return NSMakePoint(advance.width, advance.height); 
}

- (NSPoint)positionOfGlyph:(NSGlyph)aGlyph 
              forCharacter:(unichar)aChar 
            struckOverRect:(NSRect)aRect
{
  return NSZeroPoint;
}

- (NSPoint)positionOfGlyph:(NSGlyph)aGlyph 
           struckOverGlyph:(NSGlyph)baseGlyph 
              metricsExist:(BOOL *)flag
{
  if (flag)
    *flag = NO;

  return NSZeroPoint;
}

- (NSPoint)positionOfGlyph:(NSGlyph)aGlyph 
            struckOverRect:(NSRect)aRect 
              metricsExist:(BOOL *)flag
{
  if (flag)
    *flag = NO;

  return NSZeroPoint;
}

- (NSPoint)positionOfGlyph:(NSGlyph)aGlyph 
              withRelation:(NSGlyphRelation)relation 
               toBaseGlyph:(NSGlyph)baseGlyph
          totalAdvancement:(NSSize *)offset 
              metricsExist:(BOOL *)flag
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
      point = NSMakePoint(baseRect.origin.x, NSMaxY(baseRect));
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

- (NSStringEncoding)mostCompatibleStringEncoding
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

@end
