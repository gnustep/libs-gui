/*
   GSHorizontalTypesetter.h

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2002

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_GSHorizontalTypesetter
#define _GNUstep_H_GSHorizontalTypesetter

#import <GNUstepGUI/GSTypesetter.h>

@class NSLock;
@class GSLayoutManager, NSTextContainer, NSTextStorage;
@class NSDictionary;
@class NSParagraphStyle, NSFont;

APPKIT_EXPORT_CLASS
@interface GSHorizontalTypesetter : GSTypesetter
{
  NSLock *lock;

  GSLayoutManager *currentLayoutManager;
  NSTextContainer *currentTextContainer;
  NSTextStorage *currentTextStorage;

  unsigned int currentGlyphIndex;
  NSPoint currentPoint;


  NSParagraphStyle *currentParagraphStyle;
  NSRange paragraphRange; /* characters */

  NSDictionary *currentAttributes;
  NSRange attributeRange; /* characters */
  struct
    {
      BOOL explicitKern;
      float kern;
      float baselineOffset;
      int superscript;
    } attributes;

  NSFont *currentFont;
  NSRange fontRange; /* glyphs */

  struct GSHorizontalTypesetterGlyphCacheStruct *glyphCache;
  /*
    cacheBase: index of first glyph in cache within the text container
    cacheSize: capacity of cache
    cacheLength: how much of the cache is filled
   */
  unsigned int cacheBase, cacheSize, cacheLength;
  BOOL atEnd;


  struct GSHorizontalTypesetterLineFragmentStruct *lineFragments;
  int lineFragmentCount, lineFragmentCapacity;
}

+(GSHorizontalTypesetter *) sharedInstance;

@end

#endif
