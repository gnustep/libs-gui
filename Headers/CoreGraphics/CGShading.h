/** <title>CGShading</title>

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

#ifndef OPAL_CGShading_h
#define OPAL_CGShading_h

/* Data Types */

#ifdef __OBJC__
@class CGShading;
typedef CGShading* CGShadingRef;
#else
typedef struct CGShading* CGShadingRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGFunction.h>
#include <CoreGraphics/CGGeometry.h>
#include <CoreGraphics/CGColorSpace.h>

/* Functions */

CGShadingRef CGShadingCreateAxial(
  CGColorSpaceRef colorspace,
  CGPoint start,
  CGPoint end,
  CGFunctionRef function,
  int extendStart,
  int extendEnd
);

CGShadingRef CGShadingCreateRadial(
  CGColorSpaceRef colorspace,
  CGPoint start,
  CGFloat startRadius,
  CGPoint end,
  CGFloat endRadius,
  CGFunctionRef function,
  int extendStart,
  int extendEnd
);

CFTypeID CGShadingGetTypeID();

CGShadingRef CGShadingRetain(CGShadingRef shading);

void CGShadingRelease(CGShadingRef shading);

#endif /* OPAL_CGShading_h */
