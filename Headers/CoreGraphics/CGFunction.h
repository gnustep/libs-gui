/** <title>CGFunction</title>

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

#ifndef OPAL_CGFunction_h
#define OPAL_CGFunction_h

/* Data Types */

#ifdef __OBJC__
@class CGFunction;
typedef CGFunction* CGFunctionRef;
#else
typedef struct CGFunction* CGFunctionRef;
#endif

#include <CoreGraphics/CGBase.h>

/* Callbacks */

typedef void (*CGFunctionEvaluateCallback)(
  void *info,
  const CGFloat *inData,
  CGFloat *outData
);

typedef void (*CGFunctionReleaseInfoCallback)(void *info);

typedef struct CGFunctionCallbacks {
  unsigned int version;
  CGFunctionEvaluateCallback evaluate;
  CGFunctionReleaseInfoCallback releaseInfo;
} CGFunctionCallbacks;

/* Functions */

CGFunctionRef CGFunctionCreate(
  void *info,
  size_t domainDimension,
  const CGFloat *domain,
  size_t rangeDimension,
  const CGFloat *range,
  const CGFunctionCallbacks *callbacks
);

CGFunctionRef CGFunctionRetain(CGFunctionRef function);

void CGFunctionRelease(CGFunctionRef function);

#endif /* OPAL_CGFunction_h */
