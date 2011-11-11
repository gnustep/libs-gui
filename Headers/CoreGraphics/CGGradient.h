/** <title>CGGradient</title>

   <abstract>C Interface to graphics drawing library
             - geometry routines</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.
   Author: Eric Wasylishen <ewasylishen@gmail.com>

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

#ifndef OPAL_CGGradient_h
#define OPAL_CGGradient_h

/* Data Types */

#ifdef __OBJC__
@class CGGradient;
typedef CGGradient* CGGradientRef;
#else
typedef struct CGGradient* CGGradientRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGColorSpace.h>

/* Constants */

typedef enum {
  kCGGradientDrawsBeforeStartLocation = (1 << 0),
  kCGGradientDrawsAfterEndLocation = (1 << 1)
} CGGradientDrawingOptions;

/* Functions */

CGGradientRef CGGradientCreateWithColorComponents(
  CGColorSpaceRef cs,
  const CGFloat components[],
  const CGFloat locations[],
  size_t count
);

CGGradientRef CGGradientCreateWithColors(
  CGColorSpaceRef cs,
  CFArrayRef colors,
  const CGFloat locations[]
);

CFTypeID CGGradientGetTypeID();

CGGradientRef CGGradientRetain(CGGradientRef grad);

void CGGradientRelease(CGGradientRef grad);

#endif
