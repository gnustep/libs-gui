/** <title>NSFont</title>

   <abstract>The font class</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: February 1997
   A completely rewritten version of the original source by Scott Christley.

   This file is part of the GNUstep GUI Library.

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

#import <Foundation/NSAffineTransform.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSValue.h>

#import "NSFont.h"

const CGFloat *NSFontIdentityMatrix;


@implementation NSFont

+ (void)load
{
  static CGFloat identity[6] = {1.0, 0.0, 1.0, 0.0, 0.0, 0.0};
  NSFontIdentityMatrix = identity;
}

//
// Querying the Font
//
- (NSRect) boundingRectForFont
{
  return NSMakeRect(0,0,0,0);
}
- (NSString*) displayName
{
  return [self nameForKey: kCTFontFullNameKey];
}
- (NSString*) familyName
{
  return [self nameForKey: kCTFontFamilyNameKey];
}
- (NSString*) fontName
{
  return [self nameForKey: kCTFontPostScriptNameKey];
}
- (BOOL) isFixedPitch
{
  return NO;
}
- (const CGFloat*) matrix
{
  return _matrix.PSMatrix;
}
- (NSAffineTransform*) textTransform
{
  // FIXME: Need to implement bridging between NSFontMatrixAttribute and kCTFontMatrixAttribute somewhere
  NSAffineTransform *transform = [NSAffineTransform transform];
  [transform setTransformStruct: _matrix.NSTransform];
  return transform;
}

- (CGFloat) pointSize
{
  return [[[self fontDescriptor] objectForKey: NSFontSizeAttribute] doubleValue];
}
- (NSFont*) printerFont
{
  return nil;
}
- (NSFont*) screenFont
{
  return nil;
}
- (CGFloat) ascender
{
  return 0;
}
- (CGFloat) descender
{
  return 0;
}
- (CGFloat) capHeight
{
  return 0;
}
- (CGFloat) italicAngle
{
  return 0;
}
- (CGFloat) leading
{
  return 0;
}
- (NSSize) maximumAdvancement
{
  return NSMakeSize(0,0);
}
- (CGFloat) underlinePosition
{
  return 0;
}
- (CGFloat) underlineThickness
{
  return 0;
}
- (CGFloat) xHeight
{
  return 0;
}
- (NSUInteger) numberOfGlyphs
{
  return 0;
}
- (NSCharacterSet*) coveredCharacterSet
{
  return [[self fontDescriptor] objectForKey: kCTFontCharacterSetAttribute];
}
- (NSFontDescriptor*) fontDescriptor
{
  return _descriptor;
}
- (NSFontRenderingMode) renderingMode
{
  return 0;
}
- (NSFont*) screenFontWithRenderingMode: (NSFontRenderingMode)mode
{
  return nil;
}

//
// Manipulating Glyphs
//
- (NSSize) advancementForGlyph: (NSGlyph)aGlyph
{
  return NSMakeSize(0,0);
}
- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph
{
  return NSMakeRect(0,0,0,0);
}
- (void) getAdvancements: (NSSizeArray)advancements
               forGlyphs: (const NSGlyph*)glyphs
                   count: (NSUInteger)count
{
}
- (void) getAdvancements: (NSSizeArray)advancements
         forPackedGlyphs: (const void*)packedGlyphs
                  length: (NSUInteger)count
{
}
- (void) getBoundingRects: (NSRectArray)advancements
                forGlyphs: (const NSGlyph*)glyphs
                    count: (NSUInteger)count
{
}
- (NSGlyph) glyphWithName: (NSString*)glyphName
{
  return 0;
}
- (NSStringEncoding) mostCompatibleStringEncoding
{
  return 0;
}

//
// CTFont private
//
+ (NSFont*) fontWithDescriptor: (NSFontDescriptor*)descriptor
                       options: (CTFontOptions)options
{
  // FIXME: placeholder code.
  return [[[NSFont alloc] _initWithDescriptor: descriptor
                                      options: options] autorelease];
}

+ (NSFont*) fontWithGraphicsFont: (CGFontRef)graphics
            additionalDescriptor: (NSFontDescriptor*)descriptor
{
	return nil;
}

- (id)_initWithDescriptor: (NSFontDescriptor*)aDescriptor
                  options: (CTFontOptions)options
{
  if (nil == (self = [super init]))
  {
    return nil;
  }
  ASSIGN(_descriptor, aDescriptor);
  NSAffineTransform *transform = [_descriptor objectForKey: NSFontMatrixAttribute];
  if (transform == nil)
  {
    _matrix.CGTransform = CGAffineTransformIdentity;
  }
  else
  {
    _matrix.NSTransform = [transform transformStruct];
  }
  return self;
}

- (CGFloat) unitsPerEm
{
	return 0;
}
- (NSString*) nameForKey: (NSString*)nameKey
{
	return nil;
}
- (NSString*) localizedNameForKey: (NSString*)nameKey
                         language: (NSString**)languageOut
{
	return nil;
}
- (bool) getGraphicsGlyphsForCharacters: (const unichar *)characters
                         graphicsGlyphs: (const CGGlyph *)glyphs
                                  count: (CFIndex)count
{
	return 0;
}
- (double) getAdvancesForGraphicsGlyphs: (const CGGlyph *)glyphs
                               advances: (CGSize*)advances
                            orientation: (CTFontOrientation)orientation
                                  count: (CFIndex)count
{
	return 0;
}
- (CGRect) getBoundingRectsForGraphicsGlyphs: (const CGGlyph *)glyphs
                                       rects: (CGRect*)rects
                                 orientation: (CTFontOrientation)orientation
                                       count: (CFIndex)count
{
	CGRect r = {{0,0},{0,0}};
	return r;
}
- (void) getVerticalTranslationForGraphicsGlyphs: (const CGGlyph*)glyphs
                                     translation: (CGSize*)translation
                                           count: (CFIndex)count
{
}
- (CGPathRef) graphicsPathForGlyph: (CGGlyph)glyph
                         transform: (const CGAffineTransform *)xform
{
	return nil;
}
- (NSArray*) variationAxes
{
	return nil;
}
- (NSDictionary*) variation
{
	return nil;
}
- (CGFontRef) graphicsFontWithDescriptor: (NSFontDescriptor**)descriptorOut
{
	return nil;
}
- (NSArray*) availableTablesWithOptions: (CTFontTableOptions)options
{
	return nil;
}
- (NSData*) tableForTag: (CTFontTableTag)tag
            withOptions: (CTFontTableOptions)options
{
	return nil;
}

//
// CGFont private
//
- (NSString*) nameForGlyph: (CGGlyph)graphicsGlyph
{
	return nil;
}
+ (CTFontRef) fontWithData: (NSData*)fontData
                      size: (CGFloat)size
       		          matrix: (const CGFloat*)fontMatrix
      additionalDescriptor: (NSFontDescriptor*)descriptor
{
	return nil;
}

@end

