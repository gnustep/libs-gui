/** <title>CTParagraphStyle</title>

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

#ifndef OPAL_CTParagraphStyle_h
#define OPAL_CTParagraphStyle_h

#include <CoreGraphics/CGBase.h>

/* Data Types */

#ifdef __OBJC__
@class CTParagraphStyle;
typedef CTParagraphStyle* CTParagraphStyleRef;
#else
typedef struct CTParagraphStyle* CTParagraphStyleRef;
#endif

/* Constants */

typedef enum {
  kCTLeftTextAlignment = 0,
  kCTRightTextAlignment = 1,
  kCTCenterTextAlignment = 2,
  kCTJustifiedTextAlignment = 3,
  kCTNaturalTextAlignment = 4
} CTTextAlignment;

typedef enum {
  kCTLineBreakByWordWrapping = 0,
  kCTLineBreakByCharWrapping = 1,
  kCTLineBreakByClipping = 2,
  kCTLineBreakByTruncatingHead = 3,
  kCTLineBreakByTruncatingTail = 4,
  kCTLineBreakByTruncatingMiddle = 5
} CTLineBreakMode;

typedef enum {
  kCTWritingDirectionNatural = -1,
  kCTWritingDirectionLeftToRight = 0,
  kCTWritingDirectionRightToLeft = 1
} CTWritingDirection;

typedef enum {
  kCTParagraphStyleSpecifierAlignment = 0,
  kCTParagraphStyleSpecifierFirstLineHeadIndent = 1,
  kCTParagraphStyleSpecifierHeadIndent = 2,
  kCTParagraphStyleSpecifierTailIndent = 3,
  kCTParagraphStyleSpecifierTabStops = 4,
  kCTParagraphStyleSpecifierDefaultTabInterval = 5,
  kCTParagraphStyleSpecifierLineBreakMode = 6,
  kCTParagraphStyleSpecifierLineHeightMultiple = 7,
  kCTParagraphStyleSpecifierMaximumLineHeight = 8,
  kCTParagraphStyleSpecifierMinimumLineHeight = 9,
  kCTParagraphStyleSpecifierLineSpacing = 10,
  kCTParagraphStyleSpecifierParagraphSpacing = 11,
  kCTParagraphStyleSpecifierParagraphSpacingBefore = 12,
  kCTParagraphStyleSpecifierBaseWritingDirection = 13,
  kCTParagraphStyleSpecifierCount = 14
} CTParagraphStyleSpecifier;


/* Data Types */

typedef struct CTParagraphStyleSetting {
  CTParagraphStyleSpecifier spec;
  size_t valueSize;
  const void *value;
} CTParagraphStyleSetting;


/* Functions */

CFTypeID CTParagraphStyleGetTypeID();

CTParagraphStyleRef CTParagraphStyleCreate(
  const CTParagraphStyleSetting* settings,
  CFIndex settingCount
);

CTParagraphStyleRef CTParagraphStyleCreateCopy(CTParagraphStyleRef paragraphStyle);

bool CTParagraphStyleGetValueForSpecifier(
  CTParagraphStyleRef paragraphStyle,
  CTParagraphStyleSpecifier spec,
  size_t valueBufferSize,
  void* valueBuffer
);

#endif
