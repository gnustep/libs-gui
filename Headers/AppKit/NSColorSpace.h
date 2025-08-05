/* 
   NSColorSpace.h

   The color space class

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  H. Nikolaus Schaller <hns@computer.org>
   Date: 2007
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSColorSpace
#define _GNUstep_H_NSColorSpace
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
#import <Foundation/NSObject.h>

@class NSData;
@class NSString;

/**
 * NSColorSpace represents and manages color space information used
 * in color conversions and rendering. It supports standard and device-specific
 * color spaces and enables loading color profiles via ICC data or
 * ColorSync profiles.
 *
 * The class provides factory methods to access common color spaces,
 * including generic and device RGB, CMYK, and grayscale spaces. It also
 * allows inspection of color space models and profile data.
 */
typedef enum _NSColorSpaceModel
{
  NSUnknownColorSpaceModel = -1,
  NSGrayColorSpaceModel,
  NSRGBColorSpaceModel,
  NSCMYKColorSpaceModel,
  NSLABColorSpaceModel,
  NSDeviceNColorSpaceModel,
  NSColorSpaceModelUnknown = NSUnknownColorSpaceModel,
  NSColorSpaceModelGray = NSGrayColorSpaceModel,
  NSColorSpaceModelRGB = NSRGBColorSpaceModel,
  NSColorSpaceModelCMYK = NSCMYKColorSpaceModel,
  NSColorSpaceModelLAB = NSLABColorSpaceModel,
  NSColorSpaceModelDeviceN = NSDeviceNColorSpaceModel
} NSColorSpaceModel;

APPKIT_EXPORT_CLASS
@interface NSColorSpace : NSObject <NSCoding>
{
  NSColorSpaceModel _colorSpaceModel;
  NSData *_iccData;
  void *_colorSyncProfile;
}

/**
 * Returns the device CMYK color space.
 */
+ (NSColorSpace *)deviceCMYKColorSpace;

/**
 * Returns the device grayscale color space.
 */
+ (NSColorSpace *)deviceGrayColorSpace;

/**
 * Returns the device RGB color space.
 */
+ (NSColorSpace *)deviceRGBColorSpace;

/**
 * Returns the generic CMYK color space.
 */
+ (NSColorSpace *)genericCMYKColorSpace;

/**
 * Returns the generic grayscale color space.
 */
+ (NSColorSpace *)genericGrayColorSpace;

/**
 * Returns the generic RGB color space.
 */
+ (NSColorSpace *)genericRGBColorSpace;

/**
 * Returns the color space model associated with this instance.
 */
- (NSColorSpaceModel)colorSpaceModel;

/**
 * Returns the ColorSync profile associated with this color space.
 */
- (void *)colorSyncProfile;

/**
 * Returns the ICC profile data associated with this color space.
 */
- (NSData *)ICCProfileData;

/**
 * Initializes the color space with a specified ColorSync profile.
 */
- (id)initWithColorSyncProfile:(void *)prof;

/**
 * Initializes the color space using ICC profile data.
 */
- (id)initWithICCProfileData:(NSData *)iccData;

/**
 * Returns a localized, human-readable name for this color space.
 */
- (NSString *)localizedName;

/**
 * Returns the number of color components in this color space.
 */
- (int)numberOfColorComponents;

@end

#endif // MAC_OS_X_VERSION_10_4
#endif // _GNUstep_H_NSColorSpace
