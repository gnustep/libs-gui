/** <title>CGImage</title>

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

#ifndef OPAL_CGImage_h
#define OPAL_CGImage_h

/* Data Types */

#ifdef __OBJC__
@class CGImage;
typedef CGImage* CGImageRef;
#else
typedef struct CGImage* CGImageRef;
#endif


#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGGeometry.h>

/* Constants */

typedef enum CGImageAlphaInfo
{
  kCGImageAlphaNone = 0,
  kCGImageAlphaPremultipliedLast = 1,
  kCGImageAlphaPremultipliedFirst = 2,
  kCGImageAlphaLast = 3,
  kCGImageAlphaFirst = 4,
  kCGImageAlphaNoneSkipLast = 5,
  kCGImageAlphaNoneSkipFirst = 6,
  kCGImageAlphaOnly = 7
} CGImageAlphaInfo;

typedef enum CGBitmapInfo {
  kCGBitmapAlphaInfoMask = 0x1F,
  kCGBitmapFloatComponents = (1 << 8),
  kCGBitmapByteOrderMask = 0x7000,
  kCGBitmapByteOrderDefault = (0 << 12),
  kCGBitmapByteOrder16Little = (1 << 12),
  kCGBitmapByteOrder32Little = (2 << 12),
  kCGBitmapByteOrder16Big = (3 << 12),
  kCGBitmapByteOrder32Big = (4 << 12)
} CGBitmapInfo;

// FIXME: Verify this endianness check works
#if GS_WORDS_BIGENDIAN
#define kCGBitmapByteOrder16Host kCGBitmapByteOrder16Big
#define kCGBitmapByteOrder32Host kCGBitmapByteOrder32Big
#else
#define kCGBitmapByteOrder16Host kCGBitmapByteOrder16Little
#define kCGBitmapByteOrder32Host kCGBitmapByteOrder32Little
#endif

/* Drawing Images */

CGImageRef CGImageCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGColorSpaceRef colorspace,
  CGBitmapInfo bitmapInfo,
  CGDataProviderRef provider,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent
);

CGImageRef CGImageMaskCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGDataProviderRef provider,
  const CGFloat decode[],
  bool shouldInterpolate
);

CGImageRef CGImageCreateCopy(CGImageRef image);

CGImageRef CGImageCreateCopyWithColorSpace(
  CGImageRef image,
  CGColorSpaceRef colorspace
);

CGImageRef CGImageCreateWithImageInRect(
  CGImageRef image,
  CGRect rect
);

CGImageRef CGImageCreateWithJPEGDataProvider (
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent
);

CGImageRef CGImageCreateWithMask (
  CGImageRef image,
  CGImageRef mask
);

CGImageRef CGImageCreateWithMaskingColors (
  CGImageRef image,
  const CGFloat components[]
);

CGImageRef CGImageCreateWithPNGDataProvider (
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent
);

CFTypeID CGImageGetTypeID();

CGImageRef CGImageRetain(CGImageRef image);

void CGImageRelease(CGImageRef image);

bool CGImageIsMask(CGImageRef image);

size_t CGImageGetWidth(CGImageRef image);

size_t CGImageGetHeight(CGImageRef image);

size_t CGImageGetBitsPerComponent(CGImageRef image);

size_t CGImageGetBitsPerPixel(CGImageRef image);

size_t CGImageGetBytesPerRow(CGImageRef image);

CGColorSpaceRef CGImageGetColorSpace(CGImageRef image);

CGImageAlphaInfo CGImageGetAlphaInfo(CGImageRef image);

CGBitmapInfo CGImageGetBitmapInfo(CGImageRef image);

CGDataProviderRef CGImageGetDataProvider(CGImageRef image);

const CGFloat *CGImageGetDecode(CGImageRef image);

bool CGImageGetShouldInterpolate(CGImageRef image);

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef image);

#endif /* OPAL_CGImage_h */
