/** <title>CGColorSpace</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: July, 2010
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

#import <Foundation/NSString.h>

#include "CoreGraphics/CGColorSpace.h"

#import "CGColorSpace-private.h"
#import "OPColorSpaceIndexed.h"

const CFStringRef kCGColorSpaceGenericGray = @"kCGColorSpaceGenericGray";
const CFStringRef kCGColorSpaceGenericRGB = @"kCGColorSpaceGenericRGB";
const CFStringRef kCGColorSpaceGenericCMYK = @"kCGColorSpaceGenericCMYK";
const CFStringRef kCGColorSpaceGenericRGBLinear = @"kCGColorSpaceGenericRGBLinear";
const CFStringRef kCGColorSpaceAdobeRGB1998 = @"kCGColorSpaceAdobeRGB1998";
const CFStringRef kCGColorSpaceSRGB = @"kCGColorSpaceSRGB";
const CFStringRef kCGColorSpaceGenericGrayGamma2_2 = @"kCGColorSpaceGenericGrayGamma2_2";


/**
 * This is a fallback only used when building Opal without LittleCMS.
 * Note that it doesn't do any color management.
 */
#if 0
static void opal_todev_rgb(CGFloat *dest, const CGFloat comps[])
{
  dest[0] = comps[0];
  dest[1] = comps[1];
  dest[2] = comps[2];
  dest[3] = comps[3];
}

static void opal_todev_gray(CGFloat *dest, const CGFloat comps[])
{
  dest[0] = comps[0];
  dest[1] = comps[0];
  dest[2] = comps[0];
  dest[3] = comps[1];
}

static void opal_todev_cmyk(CGFloat *dest, const CGFloat comps[])
{
  // DeviceCMYK to DeviceRGB conversion from PostScript Language Reference
  // section 7.2.4
  dest[0] = 1 - MIN(1.0, comps[0] + comps[3]);
  dest[1] = 1 - MIN(1.0, comps[1] + comps[3]);
  dest[2] = 1 - MIN(1.0, comps[2] + comps[3]);
  dest[3] = comps[4];
}

#endif


Class OPColorSpaceClass()
{
  // FIXME:
  return NSClassFromString(@"OPColorSpaceLCMS");
}

CFDataRef CGColorSpaceCopyICCProfile(CGColorSpaceRef cs)
{
  return [cs ICCProfile];
}

CFStringRef CGColorSpaceCopyName(CGColorSpaceRef cs)
{
  return [cs name];
}

CGColorSpaceRef CGColorSpaceCreateCalibratedGray(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  CGFloat gamma)
{
  return [[OPColorSpaceClass() alloc]
             initWithCalibratedGrayWithWhitePoint: whitePoint
                                       blackPoint: blackPoint
                                            gamma: gamma];

}

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *gamma,
  const CGFloat *matrix)
{
  return [[OPColorSpaceClass() alloc] 
      initWithCalibratedRGBWithWhitePoint: whitePoint
                               blackPoint: blackPoint
                                    gamma: gamma
                                   matrix: matrix]; 
}

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK()
{
  return [[OPColorSpaceClass() colorSpaceGenericCMYK] retain];
}

CGColorSpaceRef CGColorSpaceCreateDeviceGray()
{
  return [[OPColorSpaceClass() colorSpaceGenericGray] retain];
}

CGColorSpaceRef CGColorSpaceCreateDeviceRGB()
{
  return [[OPColorSpaceClass() colorSpaceSRGB] retain];
}

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const CGFloat *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace)
{
  return [[OPColorSpaceClass() alloc] initICCBasedWithComponents: nComponents
                           range: range
                         profile: profile
                  alternateSpace: alternateSpace]; 
}

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const unsigned char *colorTable)
{
  return [[OPColorSpaceIndexed alloc] initWithBaseSpace: baseSpace
                                              lastIndex: lastIndex
                                             colorTable: colorTable];
}  

CGColorSpaceRef CGColorSpaceCreateLab(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *range)
{
  return [[OPColorSpaceClass() alloc] initLabWithWhitePoint: whitePoint
                                                            blackPoint: blackPoint
                                                                 range: range];
}

CGColorSpaceRef CGColorSpaceCreatePattern(CGColorSpaceRef baseSpace)
{
  // FIXME: implement
  return nil;
}

CGColorSpaceRef CGColorSpaceCreateWithICCProfile(CFDataRef data)
{
  return [[OPColorSpaceClass() alloc] initWithICCProfile: data];
}

CGColorSpaceRef CGColorSpaceCreateWithName(CFStringRef name)
{
  if ([name isEqualToString: kCGColorSpaceGenericGray])
  {
		return [[OPColorSpaceClass() colorSpaceGenericGray] retain];
  }
  else if ([name isEqualToString: kCGColorSpaceGenericRGB])
  {
    return [[OPColorSpaceClass() colorSpaceGenericRGB] retain];
  }
  else if ([name isEqualToString: kCGColorSpaceGenericCMYK])
  {
    return [[OPColorSpaceClass() colorSpaceGenericCMYK] retain];
  }
  else if ([name isEqualToString: kCGColorSpaceGenericRGBLinear])
  {
    return [[OPColorSpaceClass() colorSpaceGenericRGBLinear] retain];
  }
  else if ([name isEqualToString: kCGColorSpaceAdobeRGB1998])
  {
    return [[OPColorSpaceClass() colorSpaceAdobeRGB1998] retain];
  }
  else if ([name isEqualToString: kCGColorSpaceSRGB])
  {
    return [[OPColorSpaceClass() colorSpaceSRGB] retain];
  }
  else if ([name isEqualToString: kCGColorSpaceGenericGrayGamma2_2])
  {
    return [[OPColorSpaceClass() colorSpaceGenericGrayGamma2_2] retain];
  }
  return nil;
}

CGColorSpaceRef CGColorSpaceCreateWithPlatformColorSpace(
  void *platformColorSpace)
{
  return [[OPColorSpaceClass() alloc] initWithPlatformColorSpace: platformColorSpace];
}

CGColorSpaceRef CGColorSpaceGetBaseColorSpace(CGColorSpaceRef cs)
{
  // FIXME: fail silently on non-indexed space?
  return [(OPColorSpaceIndexed*)cs baseColorSpace];  
}

void CGColorSpaceGetColorTable(CGColorSpaceRef cs, unsigned char *table)
{
  // FIXME: fail silently on non-indexed space?
  [(OPColorSpaceIndexed*)cs getColorTable: table];
}

size_t CGColorSpaceGetColorTableCount(CGColorSpaceRef cs)
{
  // FIXME: fail silently on non-indexed space?
  return [(OPColorSpaceIndexed*)cs colorTableCount];
}

CGColorSpaceModel CGColorSpaceGetModel(CGColorSpaceRef cs)
{
  return [cs model];
}

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs)
{
  return [cs numberOfComponents];
}

CFTypeID CGColorSpaceGetTypeID()
{
  return (CFTypeID)OPColorSpaceClass(); 
}

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs)
{
  return [cs retain];
}

void CGColorSpaceRelease(CGColorSpaceRef cs)
{
  [cs release];
}

