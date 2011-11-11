/** <title>CTTypesetter</title>

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

#ifndef OPAL_CTTypesetter_h
#define OPAL_CTTypesetter_h

#include <CoreGraphics/CGBase.h>
#include <CoreText/CTLine.h>

/* Data Types */

#ifdef __OBJC__
@class CTTypesetter;
typedef CTTypesetter* CTTypesetterRef;
#else
typedef struct CTTypesetter* CTTypesetterRef;
#endif

/* Constants */

extern const CFStringRef kCTTypesetterOptionDisableBidiProcessing;
extern const CFStringRef kCTTypesetterOptionForcedEmbeddingLevel;

/* Functions */

CTTypesetterRef CTTypesetterCreateWithAttributedString(CFAttributedStringRef string);

CTTypesetterRef CTTypesetterCreateWithAttributedStringAndOptions(
  CFAttributedStringRef string,
  CFDictionaryRef opts
);

CTLineRef CTTypesetterCreateLine(
  CTTypesetterRef typesetter,
  CFRange range
);

CFIndex CTTypesetterSuggestClusterBreak(
  CTTypesetterRef typesetter,
  CFIndex start,
  double width
);

CFIndex CTTypesetterSuggestLineBreak(
  CTTypesetterRef typesetter,
  CFIndex start,
  double width
);

CFTypeID CTTypesetterGetTypeID();

#endif
