/** <title>NSFont</title>

   <abstract>The font class</abstract>

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

#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/GSFontInfo.h>

/* We cache all the 4 default fonts after we first get them.
   But when a default font is changed, the variable is set to YES 
   so all default fonts are forced to be recomputed. */
static BOOL systemCacheNeedsRecomputing = NO;
static BOOL boldSystemCacheNeedsRecomputing = NO;
static BOOL userCacheNeedsRecomputing = NO;
static BOOL userFixedCacheNeedsRecomputing = NO;

@interface NSFont (Private)
- (id) initWithName: (NSString*)name 
	     matrix: (const float*)fontMatrix;
@end

@implementation NSFont

/* Class variables*/

/* Fonts that are preferred by the application */
NSArray *_preferredFonts;

/* Class for fonts */
static Class	NSFontClass = 0;

/* Store all created fonts for reuse. 
   ATTENTION: This way a font will never get freed! */
static NSMutableDictionary* globalFontDictionary = nil;

static NSUserDefaults	*defaults = nil;

NSFont*
getNSFont(NSString* key, NSString* defaultFontName, float fontSize)
{
  NSString* fontName;

  fontName = [defaults objectForKey: key];
  if (fontName == nil)
    fontName = defaultFontName;

  if (fontSize == 0)
    {
      fontSize = [defaults floatForKey:
	[NSString stringWithFormat: @"%@Size", key]];
      if (fontSize == 0)
	fontSize = 12;
    }

  return [NSFontClass fontWithName: fontName size: fontSize];
}

void
setNSFont(NSString* key, NSFont* font)
{
  [defaults setObject: [font fontName] forKey: key];

  systemCacheNeedsRecomputing = YES;
  boldSystemCacheNeedsRecomputing = YES;
  userCacheNeedsRecomputing = YES;
  userFixedCacheNeedsRecomputing = YES;

  /* Don't care about errors*/
  [defaults synchronize];
}

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSFont class])
    {
      NSFontClass = self;
      globalFontDictionary = [NSMutableDictionary new];

      if (defaults == nil)
	{
	  defaults = RETAIN([NSUserDefaults standardUserDefaults]);
	}
    }
}

/* Getting the preferred user fonts.  */

// This is deprecated in MacOSX
+ (NSFont*) boldSystemFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSBoldFont", @"Helvetica-Bold", fontSize);
    }
  else
    {
      if ((font == nil) || (boldSystemCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSBoldFont", @"Helvetica-Bold", 0));
	  boldSystemCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

// This is deprecated in MacOSX
+ (NSFont*) systemFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSFont", @"Helvetica", fontSize);
    }
  else
    {
      if ((font == nil) || (systemCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSFont", @"Helvetica", 0));
	  systemCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) userFixedPitchFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSUserFixedPitchFont", @"Courier", fontSize);
    }
  else
    {
      if ((font == nil) || (userFixedCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSUserFixedPitchFont", @"Courier", 0));
	  userFixedCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) userFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSUserFont", @"Helvetica", fontSize);
    }
  else
    {
      if ((font == nil) || (userCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSUserFont", @"Helvetica", 0));
	  userCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSArray *)preferredFontNames
{
  return _preferredFonts;
}

/* Setting the preferred user fonts*/

+ (void) setUserFixedPitchFont: (NSFont*)font
{
  setNSFont (@"NSUserFixedPitchFont", font);
}

+ (void) setUserFont: (NSFont*)font
{
  setNSFont (@"NSUserFont", font);
}

+ (void)setPreferredFontNames:(NSArray *)fontNames
{
  ASSIGN(_preferredFonts, fontNames);
}

/* Getting various fonts*/

+ (NSFont*) controlContentFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSControlContentFont", @"Helvetica", fontSize);
    }
  else
    {
      if ((font == nil) || (userCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSControlContentFont", @"Helvetica", 0));
	  userCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) labelFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSLabelFont", @"Helvetica", fontSize);
    }
  else
    {
      if ((font == nil) || (userCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSLabelFont", @"Helvetica", 0));
	  userCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) menuFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSMenuFont", @"Helvetica", fontSize);
    }
  else
    {
      if ((font == nil) || (userCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSMenuFont", @"Helvetica", 0));
	  userCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) titleBarFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSTitleBarFont", @"Helvetica-Bold", fontSize);
    }
  else
    {
      if ((font == nil) || (boldSystemCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSTitleBarFont", @"Helvetica-Bold", 0));
	  boldSystemCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) messageFontOfSize: (float)fontSize
{
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSMessageFont", @"Helvetica", fontSize);
    }
  else
    {
      if ((font == nil) || (userCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSMessageFont", @"Helvetica", 0));
	  userCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) paletteFontOfSize: (float)fontSize
{
  // Not sure on this one.
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSPaletteFont", @"Helvetica-Bold", fontSize);
    }
  else
    {
      if ((font == nil) || (boldSystemCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSPaletteFont", @"Helvetica-Bold", 0));
	  boldSystemCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

+ (NSFont*) toolTipsFontOfSize: (float)fontSize
{
  // Not sure on this one.
  static NSFont *font = nil;

  if (fontSize != 0)
    {
      return getNSFont (@"NSToolTipsFont", @"Helvetica", fontSize);
    }
  else
    {
      if ((font == nil) || (userCacheNeedsRecomputing == YES))
	{
	  ASSIGN (font, getNSFont (@"NSToolTipsFont", @"Helvetica", 0));
	  userCacheNeedsRecomputing = NO;
	}
      return font;
    }
}

//
// Font Sizes
//
+ (float) labelFontSize
{
  /* FIXME - if the user has set a default, shouldn't this return that ? */ 
  return 12.0;
}

+ (float) smallSystemFontSize
{
  return 9.0;
}

+ (float) systemFontSize
{
  return 12.0;
}

+ (NSFont*) fontWithName: (NSString*)name 
		  matrix: (const float*)fontMatrix
{
  return AUTORELEASE([[NSFontClass alloc] initWithName: name
						matrix: fontMatrix]);
}

+ (NSFont*) fontWithName: (NSString*)name
		    size: (float)fontSize
{
  NSFont*font;
  float fontMatrix[6] = { 0, 0, 0, 0, 0, 0 };

  if (fontSize == 0)
    {
      fontSize = [defaults floatForKey: @"NSUserFontSize"];
      if (fontSize == 0)
	{
	  fontSize = 12;
	}
    }
  fontMatrix[0] = fontSize;
  fontMatrix[3] = fontSize;

  font = [self fontWithName: name matrix: fontMatrix];
  font->matrixExplicitlySet = NO;
  return font;
}

+ (void) useFont: (NSString*)name
{
  [GSCurrentContext() useFont: name];
}

//
// Instance methods
//
- (id) initWithName: (NSString*)name matrix: (const float*)fontMatrix
{
  NSFont *font;
  NSString *nameWithMatrix;

  nameWithMatrix = [NSString stringWithFormat:
                             @"%@ %.3f %.3f %.3f %.3f %.3f %.3f",
                             name,
                             fontMatrix[0], fontMatrix[1], fontMatrix[2], 
			     fontMatrix[3], fontMatrix[4], fontMatrix[5]];

  /* Check whether the font is cached */
  font = [globalFontDictionary objectForKey: nameWithMatrix];
  if(font != nil)
    {
      RELEASE(self);
      // retain to act like we were alloc'd
      return RETAIN(font);
    }
  /* Cache the font for later use */
  [globalFontDictionary setObject: self forKey: nameWithMatrix];

  fontName = [name copy];
  memcpy(matrix, fontMatrix, sizeof(matrix));
  fontInfo = RETAIN([GSFontInfo fontInfoForFontName: fontName
					     matrix: fontMatrix]);
  return self;
}

- (void) dealloc
{
  RELEASE(fontName);
  RELEASE(fontInfo);
  [super dealloc];
}

/* FIXME - appropriate description */
/*
- (NSString *) description
{
  return [self fontName];
}
*/

- (BOOL) isEqual: (id)anObject
{
  int i;
  const float*obj_matrix;
  if (anObject == self)
    return YES;
  if ([anObject isKindOfClass: self->isa] == NO)
    return NO;
  if ([[anObject fontName] isEqual: fontName] == NO)
    return NO;
  obj_matrix = [anObject matrix];
  for (i = 0; i < 6; i++)
    if (obj_matrix[i] != matrix[i])
      return NO;
  return YES;
}

- (unsigned) hash
{
  int i, sum;
  sum = 0;
  for (i = 0; i < 6; i++)
    sum += matrix[i]* ((i+1)* 17);
  return ([fontName hash] + sum);
}

//
// NSCopying Protocol
//
- (id) copyWithZone: (NSZone*)zone
{
  NSFont*new_font;
  if (NSShouldRetainWithZone(self, zone))
    new_font = RETAIN(self);
  else
    {
      new_font = (NSFont*)NSCopyObject(self, 0, zone);
      new_font->fontName = [fontName copyWithZone: zone];
      new_font->fontInfo = [fontInfo copyWithZone: zone];
    }
  return new_font;
}

//
// Setting the Font
//
- (void) set
{
  NSGraphicsContext *ctxt = GSCurrentContext();

  [ctxt GSSetFont: self];
  [ctxt useFont: fontName];
}

//
// Querying the Font
//
- (float) pointSize		{ return [fontInfo pointSize]; }
- (NSString*) fontName		{ return fontName; }
- (const float*) matrix		{ return matrix; }

- (NSString*) encodingScheme	{ return [fontInfo encodingScheme]; }
- (NSString*) familyName	{ return [fontInfo familyName]; }
- (NSRect) boundingRectForFont	{ return [fontInfo boundingRectForFont]; }
- (BOOL) isFixedPitch		{ return [fontInfo isFixedPitch]; }
- (BOOL) isBaseFont		{ return [fontInfo isBaseFont]; }

/* Usually the display name of font is the font name.*/
- (NSString*) displayName	{ return fontName; }

- (NSDictionary*) afmDictionary	{ return [fontInfo afmDictionary]; }
- (NSString*) afmFileContents	{ return [fontInfo afmFileContents]; }
- (NSFont*) printerFont		{ return self; }
- (NSFont*) screenFont		{ return self; }
- (float) ascender		{ return [fontInfo ascender]; }
- (float) descender		{ return [fontInfo descender]; }
- (float) capHeight		{ return [fontInfo capHeight]; }
- (float) italicAngle		{ return [fontInfo italicAngle]; }
- (NSSize) maximumAdvancement	{ return [fontInfo maximumAdvancement]; }
- (NSSize) minimumAdvancement	{ return [fontInfo minimumAdvancement]; }
- (float) underlinePosition	{ return [fontInfo underlinePosition]; }
- (float) underlineThickness	{ return [fontInfo underlineThickness]; }
- (float) xHeight		{ return [fontInfo xHeight]; }
- (float) defaultLineHeightForFont { return [fontInfo defaultLineHeightForFont]; }

/* Computing font metrics attributes*/
- (float) widthOfString: (NSString*)string
{
  return [fontInfo widthOfString: string];
}

/* The following methods have to be implemented by backends */

//
// Manipulating Glyphs
//
- (NSSize) advancementForGlyph: (NSGlyph)aGlyph
{
  return [fontInfo advancementForGlyph: aGlyph];
}

- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph
{
  return [fontInfo boundingRectForGlyph: aGlyph];
}

- (BOOL) glyphIsEncoded: (NSGlyph)aGlyph
{
  return [fontInfo glyphIsEncoded: aGlyph];
}

- (NSMultibyteGlyphPacking) glyphPacking
{
  return [fontInfo glyphPacking];
}

- (NSGlyph) glyphWithName: (NSString*)glyphName
{
  return [fontInfo glyphWithName: glyphName];
}

- (NSPoint) positionOfGlyph: (NSGlyph)curGlyph
	    precededByGlyph: (NSGlyph)prevGlyph
		  isNominal: (BOOL*)nominal
{
  return [fontInfo positionOfGlyph: curGlyph precededByGlyph: prevGlyph
                         isNominal: nominal];
}

- (NSPoint) positionOfGlyph:(NSGlyph)aGlyph 
	       forCharacter:(unichar)aChar 
	     struckOverRect:(NSRect)aRect
{
  return [fontInfo positionOfGlyph: aGlyph 
		   forCharacter: aChar 
		   struckOverRect: aRect];
}

- (NSPoint) positionOfGlyph:(NSGlyph)aGlyph 
	    struckOverGlyph:(NSGlyph)baseGlyph 
	       metricsExist:(BOOL *)flag
{
  return [fontInfo positionOfGlyph: aGlyph 
		   struckOverGlyph: baseGlyph 
		   metricsExist: flag];
}

- (NSPoint) positionOfGlyph:(NSGlyph)aGlyph 
	     struckOverRect:(NSRect)aRect 
	       metricsExist:(BOOL *)flag
{
  return [fontInfo positionOfGlyph: aGlyph 
		   struckOverRect: aRect 
		   metricsExist: flag];
}

- (NSPoint) positionOfGlyph:(NSGlyph)aGlyph 
	       withRelation:(NSGlyphRelation)relation 
		toBaseGlyph:(NSGlyph)baseGlyph
	   totalAdvancement:(NSSize *)offset 
	       metricsExist:(BOOL *)flag
{
  return [fontInfo positionOfGlyph: aGlyph 
		   withRelation: relation 
		   toBaseGlyph: baseGlyph
		   totalAdvancement: offset 
		   metricsExist: flag];
}

- (int) positionsForCompositeSequence: (NSGlyph *)glyphs 
		       numberOfGlyphs: (int)numGlyphs 
			   pointArray: (NSPoint *)points
{
  int i;
  NSGlyph base = glyphs[0];

  points[0] = NSZeroPoint;

  for (i = 1; i < numGlyphs; i++)
    {
      BOOL flag;
      // This only places the glyphs relative to the base glyph 
      // not to each other
      points[i] = [self positionOfGlyph: glyphs[i] 
			struckOverGlyph: base 
			metricsExist: &flag];
      if (!flag)
	return i - 1;
    }

  return i;
}

- (NSStringEncoding) mostCompatibleStringEncoding
{
  return [fontInfo mostCompatibleStringEncoding];
}

//
// NSCoding protocol
//
- (Class) classForCoder
{
  return NSFontClass;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: fontName];
  [aCoder encodeArrayOfObjCType: @encode(float)  count: 6  at: matrix];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  id	name;
  float	fontMatrix[6];

  name = [aDecoder decodeObject];
  [aDecoder decodeArrayOfObjCType: @encode(float)  count: 6  at: fontMatrix];
  return [self initWithName: name  matrix: fontMatrix];
}

@end /* NSFont */

@implementation NSFont (GNUstep)
//
// Private method for NSFontManager and backend
//
- (GSFontInfo*) fontInfo
{
  return fontInfo;
}

@end


int NSConvertGlyphsToPackedGlyphs(NSGlyph *glBuf, 
				  int count, 
				  NSMultibyteGlyphPacking packing, 
				  char *packedGlyphs)
{
// TODO
  return 0;
}
