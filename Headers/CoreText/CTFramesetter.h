/** <title>CTFramesetter</title>

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

#ifndef OPAL_CTFramesetter_h
#define OPAL_CTFramesetter_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPath.h>
#include <CoreGraphics/CGGeometry.h>
#include <CoreText/CTFrame.h>
#include <CoreText/CTTypesetter.h>

/* Data Types */

#ifdef __OBJC__
@class CTFramesetter;
typedef CTFramesetter* CTFramesetterRef;
#else
typedef struct CTFramesetter* CTFramesetterRef;
#endif

/* Functions */

CFTypeID CTFramesetterGetTypeID();

CTFramesetterRef CTFramesetterCreateWithAttributedString(CFAttributedStringRef string);

CTFrameRef CTFramesetterCreateFrame(
  CTFramesetterRef framesetter,
  CFRange stringRange,
  CGPathRef path,
  CFDictionaryRef attributes
);

CTTypesetterRef CTFramesetterGetTypesetter(CTFramesetterRef framesetter);

CGSize CTFramesetterSuggestFrameSizeWithConstraints(
  CTFramesetterRef framesetter,
  CFRange stringRange,
  CFDictionaryRef attributes,
  CGSize constraints,
  CFRange* fitRange
);

#endif
