/** <title>CGColorSpace</title>

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

#ifndef OPAL_CGColorSpace_h
#define OPAL_CGColorSpace_h

#import <Foundation/NSObject.h>

/* Data Types */

#ifdef __OBJC__
@protocol CGColorSpace;
typedef id <CGColorSpace, NSObject>CGColorSpaceRef;
#else
typedef struct CGColorSpace* CGColorSpaceRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGDataProvider.h>

typedef enum CGColorSpaceModel {
  kCGColorSpaceModelUnknown = -1,
  kCGColorSpaceModelMonochrome = 0,
  kCGColorSpaceModelRGB = 1,
  kCGColorSpaceModelCMYK = 2,
  kCGColorSpaceModelLab = 3,
  kCGColorSpaceModelDeviceN = 4,
  kCGColorSpaceModelIndexed = 5,
  kCGColorSpaceModelPattern = 6
} CGColorSpaceModel;


/* Constants */

typedef enum CGColorRenderingIntent {
  kCGRenderingIntentDefault = 0,
  kCGRenderingIntentAbsoluteColorimetric = 1,
  kCGRenderingIntentRelativeColorimetric = 2,
  kCGRenderingIntentPerceptual = 3,
  kCGRenderingIntentSaturation = 4
} CGColorRenderingIntent;

extern const CFStringRef kCGColorSpaceGenericGray;
extern const CFStringRef kCGColorSpaceGenericRGB;
extern const CFStringRef kCGColorSpaceGenericCMYK;
extern const CFStringRef kCGColorSpaceGenericRGBLinear;
extern const CFStringRef kCGColorSpaceAdobeRGB1998;
extern const CFStringRef kCGColorSpaceSRGB;
extern const CFStringRef kCGColorSpaceGenericGrayGamma2_2;

/* Functions */

CFDataRef CGColorSpaceCopyICCProfile(CGColorSpaceRef cs);

CFStringRef CGColorSpaceCopyName(CGColorSpaceRef cs);

CGColorSpaceRef CGColorSpaceCreateCalibratedGray(
  const CGFloat whitePoint[3],
  const CGFloat blackPoint[3],
  CGFloat gamma
);

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const CGFloat whitePoint[3],
  const CGFloat blackPoint[3],
  const CGFloat gamma[3],
  const CGFloat matrix[9]
);

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK();

CGColorSpaceRef CGColorSpaceCreateDeviceGray();

CGColorSpaceRef CGColorSpaceCreateDeviceRGB();

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const CGFloat *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace
);

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const unsigned char *colorTable
);

CGColorSpaceRef CGColorSpaceCreateLab(
  const CGFloat whitePoint[3],
  const CGFloat blackPoint[3],
  const CGFloat range[4]
);

CGColorSpaceRef CGColorSpaceCreatePattern(CGColorSpaceRef baseSpace);

CGColorSpaceRef CGColorSpaceCreateWithICCProfile(CFDataRef data);

CGColorSpaceRef CGColorSpaceCreateWithName(CFStringRef name);

CGColorSpaceRef CGColorSpaceCreateWithPlatformColorSpace(
  void *platformColorSpace
);

CGColorSpaceRef CGColorSpaceGetBaseColorSpace(CGColorSpaceRef cs);

void CGColorSpaceGetColorTable(CGColorSpaceRef cs, unsigned char *table);

size_t CGColorSpaceGetColorTableCount(CGColorSpaceRef cs);

CGColorSpaceModel CGColorSpaceGetModel(CGColorSpaceRef cs);

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs);

CFTypeID CGColorSpaceGetTypeID();

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs);

void CGColorSpaceRelease(CGColorSpaceRef cs);

#endif /* OPAL_CGColorSpace_h */
