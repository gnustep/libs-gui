/*
   NSTypesetter.m

   The text layout class

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


@implementation NSTypesetter

static NSTypesetter *_gs_system_typesetter = nil;
static NSLock *_gs_typesetter_lock;

+ (void) initialize
{
  if (self == [NSTypesetter class])
    {
      [self setVersion: 1];
      _gs_typesetter_lock = [NSLock new];
    }
}

+ (id) sharedSystemTypesetter
{
  if (_gs_system_typesetter == nil)
    {
      [_gs_typesetter_lock lock];

      if (_gs_system_typesetter == nil)
        _gs_system_typesetter = [NSSimpleHorizontalTypesetter sharedInstance];

      [_gs_typesetter_lock unlock];
    }

  return _gs_system_typesetter;
}

+ (NSSize) printingAdjustmentsInLayoutManager: (NSLayoutManager *)layoutManager
                 forNominallySpacedGlyphRange: (NSRange)glyphRange
                                 packedGlyphs: (const unsigned char *)glyphs
                                        count: (unsigned)packedGlyphCount
{
  return NSMakeSize(0, 0);
}

- (float) baselineOffsetInLayoutManager: (NSLayoutManager *)layoutManager
                             glyphIndex: (unsigned)glyphIndex
{
  return 0.0;
}

- (void) layoutGlyphsInLayoutManager: (NSLayoutManager *)layoutManager
                startingAtGlyphIndex: (unsigned)glyphIndex
            maxNumberOfLineFragments: (unsigned)maxFragments
                      nextGlyphIndex: (unsigned *)nextGlyph
{
  if (nextGlyph != NULL)
    *nextGlyph = glyphIndex;
}

@end
