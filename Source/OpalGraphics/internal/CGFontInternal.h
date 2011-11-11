/** <title>CGFontInternal</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006
   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: January, 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#import <Foundation/NSObject.h>
#include "CoreGraphics/CGFont.h"

@interface CGFont : NSObject
{
@public
  CFStringRef fullName;
  CFStringRef postScriptName;
  int ascent;
  int capHeight;
  int descent;
  CGRect fontBBox;
  CGFloat italicAngle;
  int leading;
  size_t numberOfGlyphs;
  CGFloat stemV;
  int unitsPerEm;
  int xHeight;
}

- (bool) canCreatePostScriptSubset: (CGFontPostScriptFormat)format;

- (CFStringRef) copyGlyphNameForGlyph: (CGGlyph)glyph;

- (CFDataRef) copyTableForTag: (uint32_t)tag;

- (CFArrayRef) copyTableTags;

- (CFArrayRef) copyVariationAxes;

- (CFDictionaryRef) copyVariations;

- (CGFontRef) createCopyWithVariations: (CFDictionaryRef)variations;

- (CFDataRef) createPostScriptEncoding: (const CGGlyph[])encoding;

- (CFDataRef) createPostScriptSubset: (CFStringRef)name
                                    : (CGFontPostScriptFormat)format
                                    : (const CGGlyph[])glyphs
                                    : (size_t)count
                                    : (const CGGlyph[])encoding;

+ (CGFontRef) createWithDataProvider: (CGDataProviderRef)provider;

+ (CGFontRef) createWithFontName: (CFStringRef)name;

+ (CGFontRef) createWithPlatformFont: (void *)platformFontReference;



- (bool) getGlyphAdvances: (const CGGlyph[])glyphs
                         : (size_t)count
                         : (int[]) advances;

- (bool) getGlyphBBoxes: (const CGGlyph[])glyphs
                       : (size_t)count
                       : (CGRect[])bboxes;

- (CGGlyph) glyphWithGlyphName: (CFStringRef)glyphName;


@end
