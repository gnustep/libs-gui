/** <title>CGImage-conversion.h</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: July, 2010
   
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

#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGImage.h>

/**
 * To make the internals sane and fast, we only work with these four pixel components
 * internally. They are all native-endian.
 */
typedef enum OPComponentFormat
{
  kOPComponentFormat8bpc,
  kOPComponentFormat16bpc,
  kOPComponentFormat32bpc,
  kOPComponentFormatFloat32bpc
} OPComponentFormat;

typedef struct OPImageFormat
{
  OPComponentFormat compFormat;
  size_t colorComponents;
  bool hasAlpha;
  bool isAlphaPremultiplied;
  bool isAlphaLast;
} OPImageFormat;

size_t OPComponentNumberOfBytes(OPComponentFormat fmt);
size_t OPPixelTotalComponents(OPImageFormat fmt);
size_t OPPixelNumberOfBytes(OPImageFormat fmt);


void OPImageFormatLog(OPImageFormat fmt, NSString *msg);

void OPImageConvert(
  unsigned char *dstData,
  const unsigned char *srcData, 
  size_t width,
  size_t height,
  size_t dstBitsPerComponent,
  size_t srcBitsPerComponent,
  size_t dstBitsPerPixel,
  size_t srcBitsPerPixel,
  size_t dstBytesPerRow,
  size_t srcBytesPerRow,
  CGBitmapInfo dstBitmapInfo,
  CGBitmapInfo srcBitmapInfo,
  CGColorSpaceRef dstColorSpace, 
  CGColorSpaceRef srcColorSpace,
  CGColorRenderingIntent intent);
