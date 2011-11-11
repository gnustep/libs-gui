/** <title>CTFrame</title>

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

#ifndef OPAL_CTFrame_h
#define OPAL_CTFrame_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPath.h>
#include <CoreGraphics/CGGeometry.h>
#include <CoreText/CTLine.h>

/* Data Types */

#ifdef __OBJC__
@class CTFrame;
typedef CTFrame* CTFrameRef;
#else
typedef struct CTFrame* CTFrameRef;
#endif

/* Constants */

extern const CFStringRef kCTFrameProgressionAttributeName;

typedef enum {
  kCTFrameProgressionTopToBottom = 0,
  kCTFrameProgressionRightToLeft = 1
} CTFrameProgression;

/* Functions */

CFTypeID CTFrameGetTypeID();

CFRange CTFrameGetStringRange(CTFrameRef frame);

CFRange CTFrameGetVisibleStringRange(CTFrameRef frame);

CGPathRef CTFrameGetPath(CTFrameRef frame);

CFDictionaryRef CTFrameGetFrameAttributes(CTFrameRef frame);

CFArrayRef CTFrameGetLines(CTFrameRef frame);

void CTFrameGetLineOrigins(
  CTFrameRef frame,
  CFRange range,
  CGPoint origins[]
);

void CTFrameDraw(
  CTFrameRef frame,
  CGContextRef context
);

#endif
