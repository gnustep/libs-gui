/** <title>OPColorSpaceLCMS</title>

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

#include "CoreGraphics/CGColorSpace.h"

#import "OPColorSpaceLCMS.h"
#import "CGColorSpace-private.h"
#import "OPColorTransformLCMS.h"


@implementation OPColorSpaceLCMS

static OPColorSpaceLCMS *colorSpaceSRGB;
static OPColorSpaceLCMS *colorSpaceGenericRGBLinear;
static OPColorSpaceLCMS *colorSpaceGenericCMYK;
static OPColorSpaceLCMS *colorSpaceAdobeRGB1998;
static OPColorSpaceLCMS *colorSpaceGenericGrayGamma2_2;

/**
 * Returns a generic RGB color space
 */ 
+ (id<CGColorSpace>)colorSpaceGenericRGB
{
  return [self colorSpaceSRGB];
}
/**
 * Returns a generic RGB color space with a gamma of 1.0
 */ 
+ (id<CGColorSpace>)colorSpaceGenericRGBLinear
{
  if (nil == colorSpaceGenericRGBLinear)
  {
    // Use the sRGB white point and primaries with a gamma of 1.0
    CGFloat whiteCIExy[2] = {0.3127, 0.3290};
    CGFloat redCIExy[2] = {0.64, 0.33};
    CGFloat greenCIExy[2] = {0.30, 0.60};
    CGFloat blueCIExy[2] = {0.15, 0.06};
    colorSpaceGenericRGBLinear = [[OPColorSpaceLCMS alloc]
      initWithCalibratedRGBWithWhitePointCIExy: whiteCIExy
                                      redCIExy: redCIExy
                                    greenCIExy: greenCIExy
                                     blueCIExy: blueCIExy
                                         gamma: 1.0];
  }
  return colorSpaceGenericRGBLinear;
}
/**
 * Returns a CMYK colorspace following the FOGRA39L specification.
 */
+ (id<CGColorSpace>)colorSpaceGenericCMYK
{
  if (nil == colorSpaceGenericCMYK)
  {
    NSString *path = [[NSBundle bundleForClass: [self class]]
                        pathForResource: @"coated_FOGRA39L_argl"
                                 ofType: @"icc"];
    NSData *data = [NSData dataWithContentsOfFile: path];
    colorSpaceGenericCMYK = [[OPColorSpaceLCMS alloc] initWithICCProfile: data];
  }
  return colorSpaceGenericCMYK;
}
/**
 * Returns an Adobe RGB compatible color space
 */
+ (id<CGColorSpace>)colorSpaceAdobeRGB1998
{
  if (nil == colorSpaceAdobeRGB1998)
  {
    CGFloat whiteCIExy[2] = {0.3127, 0.3290};
    CGFloat redCIExy[2] = {0.6400, 0.3300};
    CGFloat greenCIExy[2] = {0.2100, 0.7100};
    CGFloat blueCIExy[2] = {0.1500, 0.0600};
    colorSpaceAdobeRGB1998 = [[OPColorSpaceLCMS alloc]
      initWithCalibratedRGBWithWhitePointCIExy: whiteCIExy
                                      redCIExy: redCIExy
                                    greenCIExy: greenCIExy
                                     blueCIExy: blueCIExy
                                         gamma: (563.0/256.0)];
  }
  return colorSpaceAdobeRGB1998;
}
/**
 * Returns an sRGB compatible color space
 */
+ (id<CGColorSpace>)colorSpaceSRGB
{
  if (nil == colorSpaceSRGB)
  {
    colorSpaceSRGB = [[OPColorSpaceLCMS alloc] initWithProfile: cmsCreate_sRGBProfile()];
  }
  return colorSpaceSRGB;
}
/**
 * Returns a grayscale color space with a D65 white point
 */
+ (id<CGColorSpace>)colorSpaceGenericGray
{
  return [self colorSpaceGenericGrayGamma2_2];
}
/**
 * Returns a grayscale color space with gamma 2.2 and a D65 white point
 */
+ (id<CGColorSpace>)colorSpaceGenericGrayGamma2_2
{
  if (nil == colorSpaceGenericGrayGamma2_2)
  {
    CGFloat whiteCIEXYZ[3] = {0.9504, 1.0000, 1.0888};
    CGFloat blackCIEXYZ[3] = {0, 0, 0};
    colorSpaceGenericGrayGamma2_2 = [[OPColorSpaceLCMS alloc] initWithCalibratedGrayWithWhitePoint: whiteCIEXYZ
                                                                                        blackPoint: blackCIEXYZ
                                                                                             gamma: 2.2];
  }
  return colorSpaceGenericGrayGamma2_2;
}

// Initializers

/**
 * Creates a color space with the given LCMS profile. Takes ownership of the profile
 * (releases it when done.)
 */
- (id)initWithProfile: (cmsHPROFILE)aProfile
{
  self = [super init];
  self->profile = aProfile;
  return self;
}

/**
 * Returns ICC profile data for color spaces created from ICC profiles, otherwise nil
 */
- (NSData*)ICCProfile
{
  return data;
}

- (NSString*)name
{
  return [NSString stringWithUTF8String: cmsTakeProductName(self->profile)];
}

static inline cmsCIExyY CIExyzToCIExyY(const CGFloat point[3])
{
  // LittleCMS docs say Y is always 1
  cmsCIExyY xyY = {point[0], point[1], 1.0}; 
  return xyY;
}

static inline cmsCIExyY CIEXYZToCIExyY(const CGFloat point[3])
{
  cmsCIEXYZ XYZ = {point[0], point[1], point[2]};
  cmsCIExyY xyY;
  cmsXYZ2xyY(&xyY, &XYZ);
  return xyY;
}

- (id)initWithCalibratedGrayWithWhitePoint: (const CGFloat*)whiteCIEXYZ
                                blackPoint: (const CGFloat*)blackCIEXYZ
                                     gamma: (CGFloat)gamma
{
  self = [super init];

  // NOTE: we ignore the black point; LCMS computes it on its own

  LPGAMMATABLE table = cmsBuildGamma(256, gamma);
  cmsCIExyY whiteCIExyY = CIEXYZToCIExyY(whiteCIEXYZ);
  self->profile = cmsCreateGrayProfile(&whiteCIExyY, table);
  cmsFreeGamma(table);

  return self;
}
- (id)initWithCalibratedRGBWithWhitePointCIExy: (const CGFloat*)white
                                      redCIExy: (const CGFloat*)red
                                    greenCIExy: (const CGFloat*)green
                                     blueCIExy: (const CGFloat*)blue
                                         gamma: (CGFloat)gamma
{
  self = [super init];

  LPGAMMATABLE tables[3] = {cmsBuildGamma(256, gamma),
                            cmsBuildGamma(256, gamma),
                            cmsBuildGamma(256, gamma)};
  cmsCIExyY whitePoint = {white[0], white[1], 1.0};
  cmsCIExyYTRIPLE primaries = {
    {red[0], red[1], 1.0},
    {green[0], green[1], 1.0},
    {blue[0], blue[1], 1.0}
  };

  self->profile = cmsCreateRGBProfile(&whitePoint, &primaries, tables);

  cmsFreeGamma(tables[0]);
  cmsFreeGamma(tables[1]);
  cmsFreeGamma(tables[2]);
  
  return self;
}
- (id)initWithCalibratedRGBWithWhitePoint: (const CGFloat*)whitePoint
                               blackPoint: (const CGFloat*)blackPoint
                                    gamma: (const CGFloat *)gamma
                                   matrix: (const CGFloat *)matrix
{
  self = [super init];

  // NOTE: we ignore the black point; LCMS computes it on its own

  LPGAMMATABLE tables[3] = {cmsBuildGamma(256, gamma[0]),
                            cmsBuildGamma(256, gamma[1]),
                            cmsBuildGamma(256, gamma[2])};

  // FIXME: I'm not 100% sure this is the correct interpretation of matrix

  // We can test it by checking the results in pdf manual vs doing a trasformation
  // with LCMS to XYZ.

  cmsCIExyYTRIPLE primaries;
  primaries.Red = CIEXYZToCIExyY(matrix);
  primaries.Green = CIEXYZToCIExyY(matrix+3);
  primaries.Blue = CIEXYZToCIExyY(matrix+6);

  cmsCIExyY whitePointCIExyY = CIEXYZToCIExyY(whitePoint);

  self->profile = cmsCreateRGBProfile(&whitePointCIExyY, &primaries, tables);

  cmsFreeGamma(tables[0]);
  cmsFreeGamma(tables[1]);
  cmsFreeGamma(tables[2]);
  
  return self;
}

- (id)initICCBasedWithComponents: (size_t)nComponents
                           range: (const CGFloat*)range
                         profile: (CGDataProviderRef)profile
                  alternateSpace: (CGColorSpaceRef)alternateSpace
{
  return nil;
}
- (CGColorSpaceRef) initLabWithWhitePoint: (const CGFloat*)whitePoint
                               blackPoint: (const CGFloat*)blackPoint
                                    range: (const CGFloat*)range
{
  return nil;
}
- (CGColorSpaceRef) initWithICCProfile: (CFDataRef)profileData
{
  self = [super init];
  self->data = [profileData retain];
	self->profile = cmsOpenProfileFromMem((LPVOID)[profileData bytes], [profileData length]);
  return self;
}

- (CGColorSpaceRef) initWithPlatformColorSpace: (void *)platformColorSpace
{
	[self release];
	return nil;
}

static CGColorSpaceModel CGColorSpaceModelForSignature(icColorSpaceSignature sig)
{
  switch (sig)
  {
    case icSigGrayData:
      return kCGColorSpaceModelMonochrome;
    case icSigRgbData:
      return kCGColorSpaceModelRGB;
    case icSigCmykData:
      return kCGColorSpaceModelCMYK;
    case icSigLabData:
      return kCGColorSpaceModelLab;
    default:
      return kCGColorSpaceModelUnknown;
  }
}

- (CGColorSpaceModel) model
{
	return CGColorSpaceModelForSignature(cmsGetColorSpace(profile));

}
- (size_t) numberOfComponents
{
  return _cmsChannelsOf(cmsGetColorSpace(profile));
}

- (id<OPColorTransform>) colorTransformTo: (id<CGColorSpace>)aColorSpace
                          sourceFormat: (OPImageFormat)aSourceFormat
                     destinationFormat: (OPImageFormat)aDestFormat
                       renderingIntent: (CGColorRenderingIntent)anIntent
                            pixelCount: (size_t)aPixelCount
{
  return [[OPColorTransformLCMS alloc]
       initWithSourceSpace: self
          destinationSpace: aColorSpace
              sourceFormat: aSourceFormat
         destinationFormat: aDestFormat
           renderingIntent: anIntent
                pixelCount: aPixelCount];
}

- (BOOL)isEqual: (id)other
{
  if ([other isKindOfClass: [OPColorSpaceLCMS class]])
  {
    // FIXME: Maybe there is a simple way to compare the profiles?
    return ((OPColorSpaceLCMS*)other)->profile == self->profile;
  }
  return NO;
}

@end


