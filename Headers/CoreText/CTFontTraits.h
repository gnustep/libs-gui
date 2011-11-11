/** <title>CTFontTraits</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_CTFontTraits_h
#define OPAL_CTFontTraits_h

#include <CoreGraphics/CGBase.h>

/* Constants */

extern const CFStringRef kCTFontSymbolicTrait;
extern const CFStringRef kCTFontWeightTrait;
extern const CFStringRef kCTFontWidthTrait;
extern const CFStringRef kCTFontSlantTrait;

enum {
  kCTFontClassMaskShift = 28
};

typedef enum {
  kCTFontItalicTrait = (1 << 0),
  kCTFontBoldTrait = (1 << 1),
  kCTFontExpandedTrait = (1 << 5),
  kCTFontCondensedTrait = (1 << 6),
  kCTFontMonoSpaceTrait = (1 << 10),
  kCTFontVerticalTrait = (1 << 11),
  kCTFontUIOptimizedTrait = (1 << 12),
  kCTFontClassMaskTrait = (15 << 28)
} CTFontSymbolicTraits;

typedef enum {
  kCTFontUnknownClass = (0 << 28),
  kCTFontOldStyleSerifsClass = (1 << 28),
  kCTFontTransitionalSerifsClass = (2 << 28),
  kCTFontModernSerifsClass = (3 << 28),
  kCTFontClarendonSerifsClass = (4 << 28),
  kCTFontSlabSerifsClass = (5 << 28),
  kCTFontFreeformSerifsClass = (7 << 28),
  kCTFontSansSerifClass = (8 << 28),
  kCTFontOrnamentalsClass = (9 << 28),
  kCTFontScriptsClass = (10 << 28),
  kCTFontSymbolicClass = (12 << 28)
} CTFontStylisticClass;

#endif
