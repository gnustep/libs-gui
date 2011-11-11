/** <title>CGImage-conversion.m</title>

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


#include <lcms.h>
#import <Foundation/NSString.h>

#include "CoreGraphics/CGColorSpace.h"
#include "CoreGraphics/CGImage.h"

#import "CGColorSpace-private.h"

size_t OPComponentNumberOfBytes(OPComponentFormat fmt)
{
  switch (fmt)
  {
    case kOPComponentFormat8bpc:
      return 1;
    case kOPComponentFormat16bpc:
      return 2;
    case kOPComponentFormat32bpc:
      return 4;
    case kOPComponentFormatFloat32bpc:
      return 4;
  }
  return 0;
}

size_t OPPixelTotalComponents(OPImageFormat fmt)
{
  return fmt.colorComponents + (fmt.hasAlpha ? 1 : 0);
}
size_t OPPixelNumberOfBytes(OPImageFormat fmt)
{
  return OPComponentNumberOfBytes(fmt.compFormat) * OPPixelTotalComponents(fmt);
}

void OPImageFormatLog(OPImageFormat fmt, NSString *msg)
{
	NSString *compFormatString = nil;
	switch (fmt.compFormat)
	{
		case kOPComponentFormat8bpc:
			compFormatString = @"kOPComponentFormat8bpc";
			break;
	  case kOPComponentFormat16bpc:
			compFormatString = @"kOPComponentFormat16bpc";
			break;
  	case kOPComponentFormat32bpc:
			compFormatString = @"kOPComponentFormat32bpc";
			break;
  	case kOPComponentFormatFloat32bpc:
			compFormatString = @"kOPComponentFormatFloat32bpc";
			break;
	}
	NSLog(@"%@: <%@, color components=%d, alpha?=%d, premul?=%d, alpha last?=%d>", 
		msg, compFormatString, fmt.colorComponents, fmt.hasAlpha, fmt.isAlphaPremultiplied, fmt.isAlphaLast);
}

static inline uint64_t swap64(uint64_t val)
{
  char out[8];
  char *in = (char *)(&val);
  for (unsigned int i = 0; i<8; i++)
  {
    out[i] = in[7-i];
  }
  return *((uint64_t*)&out);
}

static inline void
_set_bit_value(unsigned char *base, size_t msb_off, size_t bit_width, 
               uint32_t val)
{
  if (msb_off % 32 == 0 && bit_width == 32)
  {
    ((uint32_t*)base)[msb_off / 32] = val;
  }
  else if (msb_off % 16 == 0 && bit_width == 16)
  {
    ((uint16_t*)base)[msb_off / 16] = val;
  }
  else if (msb_off % 8 == 0 && bit_width == 8)
  {
    ((uint8_t*)base)[msb_off / 8] = val;
  }
  else if (bit_width <= 32)
  {
    int byte1 = msb_off / 8;
    int shift = 64 - bit_width - (msb_off % 8);

    uint64_t value = val;
    value &= ((1 << bit_width) - 1);
    value <<= shift;
    value = swap64(value); // if little endian

    uint64_t mask = ((1 << bit_width) - 1);
    mask <<= shift;
    mask = ~mask;
    mask = swap64(mask);   // if little endian

    *((uint64_t*)(base + byte1)) &= mask;
    *((uint64_t*)(base + byte1)) |= value;
  }
  else
  {
    abort();
  }
}

static inline uint32_t
_get_bit_value(const unsigned char *base, size_t msb_off, size_t bit_width)
{
  if (msb_off % 32 == 0 && bit_width == 32)
  {
    return ((uint32_t*)base)[msb_off / 32];
  }
  else if (msb_off % 16 == 0 && bit_width == 16)
  {
    return ((uint16_t*)base)[msb_off / 16];
  }
  else if (msb_off % 8 == 0 && bit_width == 8)
  {
    return ((uint8_t*)base)[msb_off / 8];
  }
  else
  {
    int byte1 = msb_off / 8;
    int byte2 = ((msb_off + bit_width - 1) / 8);
    int shift = 64 - bit_width - (msb_off % 8);

    int bytes_needed = byte2 - byte1 + 1;
    char chars[8];

    switch (bytes_needed)
    {
      case 5: chars[4] = base[byte1+4];
      case 4: chars[3] = base[byte1+3];
      case 3: chars[2] = base[byte1+2];
      case 2: chars[1] = base[byte1+1];
      case 1: chars[0] = base[byte1+0];
        break;
      default:
        abort();
    }

    uint64_t value = *((uint64_t*)chars);
    value = swap64(value); // if little endian
    value >>= shift;
    value &= ((1<<bit_width)-1);
  
    return (uint32_t)value;
  }
}


/**
 * Rounds up a format to a standard size.
 */
static void OPRoundUp(size_t bitsPerComponentIn, size_t bitsPerPixelIn, size_t *bitsPerComponentOut, size_t *bitsPerPixelOut)
{
  if (bitsPerComponentIn < 8)
  {
    *bitsPerComponentOut = 8;
  }
  else if (bitsPerComponentIn < 16)
  {
    *bitsPerComponentOut = 16;
  }
  else if (bitsPerComponentIn < 32)
  {
    *bitsPerComponentOut = 32;
  }

  *bitsPerPixelOut = (bitsPerPixelIn / bitsPerComponentIn) * (*bitsPerComponentOut);
} 

static bool OPImageFormatForCGFormat(
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  CGBitmapInfo bitmapInfo,
  CGColorSpaceRef colorSpace,
  OPImageFormat *out)
{
  switch (bitsPerComponent)
  {
    case 8:
      out->compFormat = kOPComponentFormat8bpc;
			break;
    case 16:
      out->compFormat = kOPComponentFormat16bpc;
      break;
    case 32:
      if (bitmapInfo & kCGBitmapFloatComponents)
      {
        out->compFormat = kOPComponentFormat32bpc;
      }
      else
      {
        out->compFormat = kOPComponentFormatFloat32bpc;
      }
      break;
    default:
      return false;
  }
  
  size_t colorComponents = CGColorSpaceGetNumberOfComponents(colorSpace);
  size_t actualComponents = bitsPerPixel / bitsPerComponent;
  CGImageAlphaInfo alpha = bitmapInfo & kCGBitmapAlphaInfoMask;
  
  out->colorComponents = colorComponents;
  out->hasAlpha = (alpha != kCGImageAlphaNone && actualComponents > colorComponents);
  out->isAlphaPremultiplied = (alpha == kCGImageAlphaPremultipliedFirst ||
                               alpha == kCGImageAlphaPremultipliedLast);
  out->isAlphaLast = (alpha == kCGImageAlphaPremultipliedLast || 
                      alpha == kCGImageAlphaLast);
  return true;
}

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
  CGColorRenderingIntent intent)
{
  // For now, just support conversions that OPColorTransform can docs
  OPImageFormat srcFormat, dstFormat;

  if (!OPImageFormatForCGFormat(srcBitsPerComponent, srcBitsPerPixel, srcBitmapInfo, srcColorSpace, &srcFormat))
  {
    NSLog(@"Input format not supported");
  }
  if (!OPImageFormatForCGFormat(dstBitsPerComponent, dstBitsPerPixel, dstBitmapInfo, dstColorSpace, &dstFormat))
  {
    NSLog(@"Output format not supported");
  }
  
  OPImageFormatLog(srcFormat, @"OPImageConversion source");
  OPImageFormatLog(dstFormat, @"OPImageConversion dest");
  
  id<OPColorTransform> xform = [srcColorSpace colorTransformTo: dstColorSpace
                                               sourceFormat: srcFormat
                                          destinationFormat: dstFormat
                                            renderingIntent: intent
                                                 pixelCount: width];

  unsigned char *tempInput = malloc(srcBytesPerRow);
  
  for (size_t row=0; row<height; row++)
  {
  	const unsigned char *input = srcData + (row * srcBytesPerRow);
  	
    if (srcBitmapInfo & kCGBitmapByteOrder32Little)
		{
			for (size_t i=0; i<width; i++)
		  {
			  ((uint32_t*)tempInput)[i] = GSSwapI32(((uint32_t*)(srcData + (row * srcBytesPerRow)))[i]);
			}
			input = tempInput;
		}

    [xform transformPixelData: input
                       output: dstData + (row * dstBytesPerRow)];
    
    if (dstBitmapInfo & kCGBitmapByteOrder32Little)
		{
			for (uint32_t *pixel = (uint32_t*) (dstData + (row * dstBytesPerRow));
			     pixel < (uint32_t*) (dstData + (row * dstBytesPerRow) + dstBytesPerRow);
			     pixel++)
		  {
			  *pixel = GSSwapI32(*pixel);
			}
		}
  }
  
  free(tempInput);
}
