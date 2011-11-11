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

#import "CGColorSpace-private.h"

@interface OPColorSpaceLCMS : NSObject <CGColorSpace>
{
@public
	cmsHPROFILE profile;
  NSData *data;
}

/**
 * Returns a generic RGB color space
 */ 
+ (id<CGColorSpace>)colorSpaceGenericRGB;

/**
 * Returns a generic RGB color space with a gamma of 1.0
 */ 
+ (id<CGColorSpace>)colorSpaceGenericRGBLinear;

/**
 * Returns a CMYK colorspace following the FOGRA39L specification.
 */
+ (id<CGColorSpace>)colorSpaceGenericCMYK;

/**
 * Returns an Adobe RGB compatible color space
 */
+ (id<CGColorSpace>)colorSpaceAdobeRGB1998;

/**
 * Returns an sRGB compatible color space
 */
+ (id<CGColorSpace>)colorSpaceSRGB;

/**
 * Returns a grayscale color space with a D65 white point
 */
+ (id<CGColorSpace>)colorSpaceGenericGray;
/**
 * Returns a grayscale color space with gamma 2.2 and a D65 white point
 */
+ (id<CGColorSpace>)colorSpaceGenericGrayGamma2_2;

// Initializers

/**
 * Creates a color space with the given LCMS profile. Takes ownership of the profile
 * (releases it when done.)
 */
- (id)initWithProfile: (cmsHPROFILE)profile;

/**
 * Returns ICC profile data for color spaces created from ICC profiles, otherwise nil
 */
- (NSData*)ICCProfile;

- (NSString*)name;

- (id)initWithCalibratedGrayWithWhitePoint: (const CGFloat*)whiteCIEXYZ
                                blackPoint: (const CGFloat*)blackCIEXYZ
                                     gamma: (CGFloat)gamma;

- (id)initWithCalibratedRGBWithWhitePointCIExy: (const CGFloat*)white
                                      redCIExy: (const CGFloat*)red
                                    greenCIExy: (const CGFloat*)green
                                     blueCIExy: (const CGFloat*)blue
                                         gamma: (CGFloat)gamma;

- (id)initWithCalibratedRGBWithWhitePoint: (const CGFloat*)whitePoint
                               blackPoint: (const CGFloat*)blackPoint
                                    gamma: (const CGFloat *)gamma
                                   matrix: (const CGFloat *)matrix;

- (id)initICCBasedWithComponents: (size_t)nComponents
                           range: (const CGFloat*)range
                         profile: (CGDataProviderRef)profile
                  alternateSpace: (CGColorSpaceRef)alternateSpace;

- (CGColorSpaceRef) initLabWithWhitePoint: (const CGFloat*)whitePoint
                               blackPoint: (const CGFloat*)blackPoint
                                    range: (const CGFloat*)range;

- (CGColorSpaceRef) initWithICCProfile: (CFDataRef)profileData;

- (CGColorSpaceRef) initWithPlatformColorSpace: (void *)platformColorSpace;

- (CGColorSpaceModel) model;

- (size_t) numberOfComponents;

- (id<OPColorTransform>) colorTransformTo: (id<CGColorSpace>)aColorSpace
                             sourceFormat: (OPImageFormat)aSourceFormat
                        destinationFormat: (OPImageFormat)aDestFormat
                          renderingIntent: (CGColorRenderingIntent)anIntent
                               pixelCount: (size_t)aPixelCount;

@end


