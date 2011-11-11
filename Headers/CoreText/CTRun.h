/** <title>CTRun</title>

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

#ifndef OPAL_CTRun_h
#define OPAL_CTRun_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGFont.h>
#include <CoreGraphics/CGAffineTransform.h>
#include <CoreGraphics/CGContext.h>

/* Data Types */

#ifdef __OBJC__
@class CTRun;
typedef CTRun* CTRunRef;
#else
typedef struct CTRun* CTRunRef;
#endif

/* Constants */

typedef enum {
  kCTRunStatusNoStatus = 0,
  kCTRunStatusRightToLeft = (1 << 0),
  kCTRunStatusNonMonotonic = (1 << 1),
  kCTRunStatusHasNonIdentityMatrix = (1 << 2)
} CTRunStatus;

/* Functions */
 
CFIndex CTRunGetGlyphCount(CTRunRef run);

CFDictionaryRef CTRunGetAttributes(CTRunRef run);

CTRunStatus CTRunGetStatus(CTRunRef run);

const CGGlyph* CTRunGetGlyphsPtr(CTRunRef run);

void CTRunGetGlyphs(
  CTRunRef run,
  CFRange range,
  CGGlyph buffer[]
);

const CGPoint* CTRunGetPositionsPtr(CTRunRef run);

void CTRunGetPositions(
  CTRunRef run,
  CFRange range,
  CGPoint buffer[]
);

const CGSize* CTRunGetAdvancesPtr(CTRunRef run);

void CTRunGetAdvances(
  CTRunRef run,
  CFRange range,
  CGSize buffer[]
);

const CFIndex *CTRunGetStringIndicesPtr(CTRunRef run);

void CTRunGetStringIndices(
  CTRunRef run,
  CFRange range,
  CFIndex buffer[]
);

CFRange CTRunGetStringRange(CTRunRef run);

double CTRunGetTypographicBounds(
  CTRunRef run,
  CFRange range,
  CGFloat *ascent,
  CGFloat *descent,
  CGFloat *leading
);

CGRect CTRunGetImageBounds(
  CTRunRef run,
  CGContextRef ctx,
  CFRange range
);

CGAffineTransform CTRunGetTextMatrix(CTRunRef run);

void CTRunDraw(
  CTRunRef run,
  CGContextRef ctx,
  CFRange range
);

CFTypeID CTRunGetTypeID();

#endif
