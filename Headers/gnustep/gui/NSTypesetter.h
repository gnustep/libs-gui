/*
   NSTypesetter.h

   The text layout class(es)

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@home.com>
   Date: May 2000

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef GNUstep_H_NSTypesetter
#define GNUstep_H_NSTypesetter

#include <AppKit/NSFont.h>
#include <AppKit/NSLayoutManager.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSRange.h>

@class NSParagraphStyle, NSTextContainer, NSTextStorage;

// FIXME - when the use of this type becomes clear
typedef void NSTypesetterGlyphInfo;

typedef enum
{
  NSLayoutNotDone = 1,
  NSLayoutDone,
  NSLayoutCantFit,
  NSLayoutOutOfGlyphs
} NSLayoutStatus;


@interface NSTypesetter : NSObject
{
}

+ (NSSize) printingAdjustmentsInLayoutManager: (NSLayoutManager *)layoutManager
                 forNominallySpacedGlyphRange: (NSRange)glyphRange
                                 packedGlyphs: (const unsigned char *)glyphs
                                        count: (unsigned)packedGlyphCount;

+ (id) sharedSystemTypesetter;

- (float) baselineOffsetInLayoutManager: (NSLayoutManager *)layoutManager
                             glyphIndex: (unsigned)glyphIndex;

- (void) layoutGlyphsInLayoutManager: (NSLayoutManager *)layoutManager
                startingAtGlyphIndex: (unsigned)glyphIndex
            maxNumberOfLineFragments: (unsigned)maxFragments
                      nextGlyphIndex: (unsigned *)nextGlyph;

@end

//
// Basic horizontal (l-to-r or r-to-l) typesetter
//

@interface NSSimpleHorizontalTypesetter : NSTypesetter
{
}

//
// Get the shared horizontal typesetter
//
+ (id) sharedInstance;

//
// Get information about a typesetter
//
- (NSTypesetterGlyphInfo *) baseOfTypesetterGlyphInfo;
- (unsigned) capacityOfTypesetterGlyphInfo;
- (NSTextContainer *) currentContainer;
- (NSLayoutManager *) currentLayoutManager;
- (NSParagraphStyle *) currentParagraphStyle;
- (NSTextStorage *) currentTextStorage;
- (unsigned) firstIndexOfCurrentLineFragment;
- (unsigned) sizeOfTypesetterGlyphInfo;

//
// Glyph layout
//
- (void) breakLineAtIndex: (unsigned)location;
- (void) fullJustifyLineAtGlyphIndex: (unsigned)glyphIndex;
- (unsigned) glyphIndexToBreakLineByHyphenatingWordAtIndex: (unsigned)charIndex;
- (unsigned) glyphIndexToBreakLineByWrappingAtIndex: (unsigned)charIndex;
- (void) insertGlyph: (NSGlyph)glyph
        atGlyphIndex: (unsigned) glyphIndex
      characterIndex: (unsigned) charIndex;
- (NSLayoutStatus) layoutControlGlyphForLineFragment: (NSRect)lineFrag;
- (NSLayoutStatus) layoutGlyphsInHorizontalLineFragment: (NSRect *)fragRect
                                               baseline: (float *)baseline;
- (void) layoutGlyphsInLayoutManager: (NSLayoutManager *)layoutManager
                startingAtGlyphIndex: (unsigned)startGlyphIndex
            maxNumberOfLineFragments: (unsigned)maxNumLines
                      nextGlyphIndex: (unsigned *)nextGlyph;
- (void) layoutTab;
- (void) typesetterLaidOneGlyph: (NSTypesetterGlyphInfo *)glyphInfo;
- (void) updateCurGlyphOffset;
- (void) willSetLineFragmentRect: (NSRect *)aRect
                   forGlyphRange: (NSRange)aRange
                        usedRect: (NSRect *)usedRect;

//
// Caching
//
- (void) clearAttributesCache;
- (void) clearGlyphCache;
- (void) fillAttributesCache;
- (unsigned) growGlyphCaches: (unsigned)desiredCapacity
               fillGlyphInfo: (BOOL)flag;
@end

#endif /* GNUstep_H_NSTypesetter */
