/*
   NSSimpleHorizontalTypesetter.m

   The text layout class for horizontal scripts

   Copyright (C) 2000 Free Software Foundation, Inc.

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

#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTypesetter.h>
#include <Foundation/NSLock.h>


@implementation NSSimpleHorizontalTypesetter

static NSSimpleHorizontalTypesetter *_gs_horiz_typesetter = nil;
static NSLock *_gs_horiz_typesetter_lock;

+ (void) initialize
{
  if (self == [NSSimpleHorizontalTypesetter class])
    {
      [self setVersion: 1];
      _gs_horiz_typesetter_lock = [NSLock new];
    }
}

+ (id) sharedInstance
{
  if (_gs_horiz_typesetter == nil)
    {
      [_gs_horiz_typesetter_lock lock];

      if (_gs_horiz_typesetter == nil)
        _gs_horiz_typesetter = RETAIN([NSSimpleHorizontalTypesetter new]);

      [_gs_horiz_typesetter_lock unlock];
    }

  return _gs_horiz_typesetter;
}

//
// Get information about the typesetter
//

- (NSTypesetterGlyphInfo *) baseOfTypesetterGlyphInfo
{
  return nil;
}

- (unsigned) capacityOfTypesetterGlyphInfo
{
  return 0;
}

- (NSTextContainer *) currentContainer
{
  return nil;
}

- (NSLayoutManager *) currentLayoutManager
{
  return nil;
}

- (NSParagraphStyle *) currentParagraphStyle
{
  return nil;
}

- (NSTextStorage *) currentTextStorage
{
  return nil;
}

- (unsigned) firstIndexOfCurrentLineFragment
{
  return 0;
}

- (unsigned) sizeOfTypesetterGlyphInfo
{
  return 0;
}

//
// Glyph layout
//

- (void) breakLineAtIndex: (unsigned)location
{
  return;
}

- (void) fullJustifyLineAtGlyphIndex: (unsigned)glyphIndex
{
  return;
}

- (unsigned) glyphIndexToBreakLineByHyphenatingWordAtIndex: (unsigned)charIndex
{
  return 0;
}

- (unsigned) glyphIndexToBreakLineByWrappingAtIndex: (unsigned)charIndex
{
  return 0;
}

- (void) insertGlyph: (NSGlyph)glyph
        atGlyphIndex: (unsigned)glyphIndex
      characterIndex: (unsigned)charIndex
{
  return;
}

- (NSLayoutStatus) layoutControlGlyphForLineFragment: (NSRect)fragRect
{
  return NSLayoutOutOfGlyphs;
}

- (NSLayoutStatus) layoutGlyphsInHorizontalLineFragment: (NSRect *)fragRect
                                               baseline: (float *)baseline
{
  *fragRect = NSZeroRect;
  *baseline = 0.0;

  return NSLayoutOutOfGlyphs;
}

- (void) layoutGlyphsInLayoutManager: (NSLayoutManager *)layoutManager
                startingAtGlyphIndex: (unsigned)glyphIndex
            maxNumberOfLineFragments: (unsigned)maxNumLines
                      nextGlyphIndex: (unsigned *)nextGlyph
{
  if (nextGlyph != NULL)
    *nextGlyph = glyphIndex;
}

- (void) layoutTab
{
  return;
}

- (void) typesetterLaidOneGlyph: (NSTypesetterGlyphInfo *)glyphInfo
{
  return;
}

- (void) updateCurGlyphOffset
{
  return;
}

- (void) willSetLineFragmentRect: (NSRect *)aRect
                   forGlyphRange: (NSRange)aRange
                        usedRect: (NSRect *)usedRect
{
  return;
}

//
// Caching
//

- (void) clearAttributesCache
{
  return;
}

- (void) clearGlyphCache
{
  return;
}

- (void) fillAttributesCache
{
  return;
}

- (unsigned) growGlyphCaches: (unsigned)newCapacity
               fillGlyphInfo: (BOOL)flag
{
  return 0;
}

@end
