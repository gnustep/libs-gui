/** <title>OPSVGContext</title>

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

#ifndef OPAL_OPSVGContext_h
#define OPAL_OPSVGContext_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGDataConsumer.h>

/* Constants */

/**
 * Can used as a key in the auxiliaryInfo dictionary with a value of @"1.2" or
 * @"1.1" to restrict to a particular SVG version.
 */
extern const CFStringRef kOPSVGContextSVGVersion;

/* Functions */

void OPSVGContextBeginPage(CGContextRef ctx, CFDictionaryRef pageInfo);

void OPSVGContextClose(CGContextRef ctx);

CGContextRef OPSVGContextCreate(
  CGDataConsumerRef consumer,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo
);

CGContextRef OPSVGContextCreateWithURL(
  CFURLRef url,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo
);

void OPSVGContextEndPage(CGContextRef ctx);

#endif /* OPAL_OPSVGContext_h */
