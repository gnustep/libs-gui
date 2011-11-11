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

@implementation NSFont

//
// Querying the Font
//
- (NSRect) boundingRectForFont
{
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
}
- (const CGFloat*) matrix
{
}
- (NSAffineTransform*) textTransform
{
}
- (CGFloat) pointSize
{
}
- (NSFont*) printerFont
{
}
- (NSFont*) screenFont
{
}
- (CGFloat) ascender
{
}
- (CGFloat) descender
{
}
- (CGFloat) capHeight
{
}
- (CGFloat) italicAngle
{
}
- (CGFloat) leading
{
}
- (NSSize) maximumAdvancement
{
}
- (CGFloat) underlinePosition
{
}
- (CGFloat) underlineThickness
{
}
- (CGFloat) xHeight
{
}
- (NSUInteger) numberOfGlyphs
{
}
- (NSCharacterSet*) coveredCharacterSet
{
}
- (NSFontDescriptor*) fontDescriptor
{
}
- (NSFontRenderingMode) renderingMode
{
}
- (NSFont*) screenFontWithRenderingMode: (NSFontRenderingMode)mode
{
}

//
// Manipulating Glyphs
//
- (NSSize) advancementForGlyph: (NSGlyph)aGlyph
{
}
- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph
{
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
}
- (NSStringEncoding) mostCompatibleStringEncoding
{
}

//
// CTFont private
//
+ (NSFont*) fontWithDescriptor: (NSFontDescriptor*)descriptor 
                       options: (CTFontOptions)options
{
}
+ (NSFont*) fontWithGraphicsFont: (CGFontRef)graphics
            additionalDescriptor: (NSFontDescriptor*)descriptor
{
}

- (NSArray*) supportedLanguages
{
}
- (CGFloat) unitsPerEm
{
}
- (NSString*) nameForKey: (NSString*)nameKey
{
}
- (NSString*) localizedNameForKey: (NSString*)nameKey
                         language: (NSString**)languageOut
{
}
- (bool) getGraphicsGlyphsForCharacters: (const unichar *)characters
                         graphicsGlyphs: (const CGGlyph *)glyphs
                                  count: (CFIndex)count
{
}
- (double) getAdvancesForGraphicsGlyphs: (const CGGlyph *)glyphs
                               advances: (CGSize*)advances
                            orientation: (CTFontOrientation)orientation
                                  count: (CFIndex)count
{
}
- (CGRect) getBoundingRectsForGraphicsGlyphs: (const CGGlyph *)glyphs
                                       rects: (CGRect*)rects
                                 orientation: (CTFontOrientation)orientation
                                       count: (CFIndex)count
{
}
- (void) getVerticalTranslationForGraphicsGlyphs: (const CGGlyph*)glyphs
                                     translation: (CGSize*)translation
                                           count: (CFIndex)count
{
}
- (CGPathRef) graphicsPathForGlyph: (CGGlyph)glyph
                         transform: (const CGAffineTransform *)xform
{
}
- (NSArray*) variationAxes
{
}
- (NSDictionary*) variation
{
}
- (CGFontRef) graphicsFontWithDescriptor: (NSFontDescriptor**)descriptorOut
{
}
- (NSArray*) avaliableTablesWithOptions: (CTFontTableOptions)options
{
}
- (NSData*) tableForTag: (CTFontTableTag)tag
            withOptions: (CTFontTableOptions)options
{
}

//
// CGFont private
//
- (NSString*) nameForGlyph: (CGGlyph)graphicsGlyph
{
}
+ (CTFontRef) fontWithData: (NSData*)fontData
                      size: (CGFloat)size
       		          matrix: (const CGFloat*)fontMatrix
      additionalDescriptor: (NSFontDescriptor*)descriptor
{
}

@end

