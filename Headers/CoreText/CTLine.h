/** <title>CTLine</title>

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

#ifndef OPAL_CTLine_h
#define OPAL_CTLine_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGFont.h>
#include <CoreGraphics/CGGeometry.h>
#include <CoreText/CTRun.h>
/* Data Types */

#ifdef __OBJC__
@class CTLine;
typedef CTLine* CTLineRef;
#else
typedef struct CTLine* CTLineRef;
#endif

/* Constants */

typedef enum {
  kCTLineTruncationStart = 0,
  kCTLineTruncationEnd = 1,
  kCTLineTruncationMiddle = 2
} CTLineTruncationType;

/* Functions */

CFTypeID CTLineGetTypeID();

CTLineRef CTLineCreateWithAttributedString(CFAttributedStringRef string);

CTLineRef CTLineCreateTruncatedLine(
  CTLineRef line,
  double width,
  CTLineTruncationType truncationType,
  CTLineRef truncationToken
);

CTLineRef CTLineCreateJustifiedLine(
  CTLineRef line,
  CGFloat justificationFactor,
  double justificationWidth
);

CFIndex CTLineGetGlyphCount(CTLineRef line);

CFArrayRef CTLineGetGlyphRuns(CTLineRef line);

CFRange CTLineGetStringRange(CTLineRef line);

double CTLineGetPenOffsetForFlush(
  CTLineRef line,
  CGFloat flushFactor,
  double flushWidth
);

void CTLineDraw(CTLineRef line, CGContextRef ctx);

CGRect CTLineGetImageBounds(
  CTLineRef line,
  CGContextRef ctx
);

double CTLineGetTypographicBounds(
  CTLineRef line,
  CGFloat* ascent,
  CGFloat* descent,
  CGFloat* leading
);

double CTLineGetTrailingWhitespaceWidth(CTLineRef line);

CFIndex CTLineGetStringIndexForPosition(
  CTLineRef line,
  CGPoint position
);

CGFloat CTLineGetOffsetForStringIndex(
  CTLineRef line,
  CFIndex charIndex,
  CGFloat* secondaryOffset
);

#endif
