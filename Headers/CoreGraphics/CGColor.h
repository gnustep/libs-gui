/** <title>CGColor</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_CGColor_h
#define OPAL_CGColor_h

/* Data Types */

#ifdef __OBJC__
@class CGColor;
typedef CGColor* CGColorRef;
#else
typedef struct CGColor* CGColorRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGPattern.h>

/* Constants */

const extern CFStringRef kCGColorWhite;
const extern CFStringRef kCGColorBlack;
const extern CFStringRef kCGColorClear;

/* Functions */

CGColorRef CGColorCreate(CGColorSpaceRef colorspace, const CGFloat components[]);

CGColorRef CGColorCreateCopy(CGColorRef clr);

CGColorRef CGColorCreateCopyWithAlpha(CGColorRef clr, CGFloat alpha);

CGColorRef CGColorCreateGenericCMYK(
  CGFloat cyan,
  CGFloat magenta,
  CGFloat yellow,
  CGFloat black,
  CGFloat alpha
);

CGColorRef CGColorCreateGenericGray(CGFloat gray, CGFloat alpha);

CGColorRef CGColorCreateGenericRGB(
  CGFloat red,
  CGFloat green,
  CGFloat blue,
  CGFloat alpha
);

CGColorRef CGColorCreateWithPattern(
  CGColorSpaceRef colorspace,
  CGPatternRef pattern,
  const CGFloat components[]
);

bool CGColorEqualToColor(CGColorRef color1, CGColorRef color2);

CGFloat CGColorGetAlpha(CGColorRef clr);

CGColorSpaceRef CGColorGetColorSpace(CGColorRef clr);

const CGFloat *CGColorGetComponents(CGColorRef clr);

CGColorRef CGColorGetConstantColor(CFStringRef name);

size_t CGColorGetNumberOfComponents(CGColorRef clr);

CGPatternRef CGColorGetPattern(CGColorRef clr);

CFTypeID CGColorGetTypeID();

void CGColorRelease(CGColorRef clr);

CGColorRef CGColorRetain(CGColorRef clr);

#endif /* OPAL_CGColor_h */
