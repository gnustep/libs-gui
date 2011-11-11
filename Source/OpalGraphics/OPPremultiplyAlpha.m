/** <title>OPColorTransformLCMS</title>

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

#import "OPPremultiplyAlpha.h"

#define _OPPremultiplyAlpha(format, compType, compMax, rowStart, comps, pixels, unPremultiply) \
  for (size_t pixel = 0; pixel<pixels; pixel++) \
  { \
		compType *pixelPtr = (compType *)(rowStart + ((sizeof(compType)*comps) * pixel)); \
    const size_t firstComp = (format.isAlphaLast ? 0 : 1); \
    const size_t lastComp = (format.isAlphaLast ? (comps - 2) : (comps - 1)); \
    const size_t alphaComp = (format.isAlphaLast ? (comps - 1) : 0); \
    const float alphaValue = pixelPtr[alphaComp] / (float)compMax; \
    for (size_t i = firstComp; i<=lastComp; i++) \
    { \
      pixelPtr[i] *= (unPremultiply ? (1.0/alphaValue) : alphaValue); \
    } \
  }
  
void OPPremultiplyAlpha(
  unsigned char *row,
  size_t pixels,
  OPImageFormat format,
  bool unPremultiply)
{
  if (!format.hasAlpha)
	{
		NSLog(@"Warning, unnecessary call to OPPremultiplyAlpha");
    return;
	}
  const size_t comps = (format.colorComponents + 1);

  switch (format.compFormat)
  {
    case kOPComponentFormat8bpc:
      _OPPremultiplyAlpha(format, uint8_t,  UINT8_MAX, row, comps, pixels, unPremultiply);
      break;
    case kOPComponentFormat16bpc:
      _OPPremultiplyAlpha(format, uint16_t, UINT16_MAX, row, comps, pixels, unPremultiply);
      break;
    case kOPComponentFormat32bpc:
      _OPPremultiplyAlpha(format, uint32_t, UINT32_MAX, row, comps, pixels, unPremultiply);
      break;
    case kOPComponentFormatFloat32bpc:
      _OPPremultiplyAlpha(format, float, 1.0f, row, comps, pixels, unPremultiply);
      break;
  }
}

