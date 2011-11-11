/** <title>CGPattern</title>

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

#ifndef OPAL_CGPattern_h
#define OPAL_CGPattern_h

/* Data Types */

#ifdef __OBJC__
@class CGPattern;
typedef CGPattern* CGPatternRef;
#else
typedef struct CGPattern* CGPatternRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGGeometry.h>
#include <CoreGraphics/CGAffineTransform.h>

/* Constants */

typedef enum CGPatternTiling
{
  kCGPatternTilingNoDistortion = 0,
  kCGPatternTilingConstantSpacingMinimalDistortion = 1,
  kCGPatternTilingConstantSpacing = 2
} CGPatternTiling;

/* Callbacks */

typedef void(*CGPatternDrawPatternCallback)(void *info, CGContextRef ctx);

typedef void(*CGPatternReleaseInfoCallback)(void *info);

typedef struct CGPatternCallbacks {
  unsigned int version;
  CGPatternDrawPatternCallback drawPattern;
  CGPatternReleaseInfoCallback releaseInfo;
} CGPatternCallbacks;

/* Functions */

CGPatternRef CGPatternCreate(
  void *info,
  CGRect bounds,
  CGAffineTransform matrix,
  CGFloat xStep,
  CGFloat yStep,
  CGPatternTiling tiling,
  int isColored,
  const CGPatternCallbacks *callbacks
);

CFTypeID CGPatternGetTypeID();

void CGPatternRelease(CGPatternRef pattern);

CGPatternRef CGPatternRetain(CGPatternRef pattern);

#endif /* OPAL_CGPattern_h */
