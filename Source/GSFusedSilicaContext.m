/** <title>GSFusedSilicaContext</title>

   <abstract>Extention to NSGraphicsContext for necessary methods</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Oct 2002
   
   This file is part of the GNUStep

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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

#include "GSFusedSilicaContext.h"
#include "GNUstepGUI/GSFontInfo.h"
#include "AppKit/NSGraphics.h"
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>

#define NUMBER(num) \
  [NSNumber numberWithInt: num]
#define FLOAT_ARRAY(ptr, count) \
  [NSData dataWithBytes: ptr length: count*sizeof(float)]

@implementation NSGraphicsContext (FusedSilica)

/* Colorspaces */
+ (CGColorSpaceRef) CGColorSpaceCreateDeviceGray
{
  NSMutableDictionary *space;
  space = [NSDictionary dictionaryWithObject: NSDeviceWhiteColorSpace
			forKey: GSColorSpaceName];
  [space setObject: NUMBER(1) forKey: GSColorSpaceComponents];
  return space;
}

+ (CGColorSpaceRef) CGColorSpaceCreateDeviceRGB
{
  NSMutableDictionary *space;
  space = [NSDictionary dictionaryWithObject: NSDeviceRGBColorSpace
			forKey: GSColorSpaceName];
  [space setObject: NUMBER(3) forKey: GSColorSpaceComponents];
  return space;
}

+ (CGColorSpaceRef) CGColorSpaceCreateDeviceCMYK
{
  NSMutableDictionary *space;
  space = [NSDictionary dictionaryWithObject: NSDeviceCMYKColorSpace
			forKey: GSColorSpaceName];
  [space setObject: NUMBER(4) forKey: GSColorSpaceComponents];
  return space;
}

+ (CGColorSpaceRef) CGColorSpaceCreateCalibratedGray: (const float *)whitePoint
						    : (const float *)blackPoint
						    : (float)gamma
{
  NSMutableDictionary *space;
  space = [NSDictionary dictionaryWithObject: NSCalibratedWhiteColorSpace
			forKey: GSColorSpaceName];
  [space setObject: FLOAT_ARRAY(whitePoint, 3) forKey: GSColorSpaceWhitePoint];
  [space setObject: FLOAT_ARRAY(blackPoint, 3) forKey: GSColorSpaceBlackPoint];
  [space setObject: NUMBER(1) forKey: GSColorSpaceComponents];
  return space;
}

+ (CGColorSpaceRef) CGColorSpaceCreateCalibratedRGB: (const float *)whitePoint
						   : (const float *)blackPoint
						   : (const float *)gamma
						   : (const float *)matrix
{
  NSMutableDictionary *space;
  space = [NSDictionary dictionaryWithObject: NSCalibratedRGBColorSpace
			forKey: GSColorSpaceName];
  [space setObject: FLOAT_ARRAY(whitePoint, 3) forKey: GSColorSpaceWhitePoint];
  [space setObject: FLOAT_ARRAY(blackPoint, 3) forKey: GSColorSpaceBlackPoint];
  [space setObject: FLOAT_ARRAY(gamma, 3) forKey: GSColorSpaceGamma];
  [space setObject: FLOAT_ARRAY(matrix, 9) forKey: GSColorSpaceMatrix];
  [space setObject: NUMBER(3) forKey: GSColorSpaceComponents];
  return space;
}

+ (CGColorSpaceRef) CGColorSpaceCreateLab: (const float *)whitePoint
					 : (const float *)blackPoint
					 : (const float *) range
{
  NSMutableDictionary *space;
  space = [NSDictionary dictionaryWithObject: @"NSLabColorSpace"
			forKey: GSColorSpaceName];
  [space setObject: FLOAT_ARRAY(whitePoint, 3) forKey: GSColorSpaceWhitePoint];
  [space setObject: FLOAT_ARRAY(blackPoint, 3) forKey: GSColorSpaceBlackPoint];
  [space setObject: FLOAT_ARRAY(range, 4) forKey: GSColorSpaceRange];
  [space setObject: NUMBER(3) forKey: GSColorSpaceComponents];
  return space;
}

+ (CGColorSpaceRef) CGColorSpaceCreateICCBased: (size_t) nComponents
					      : (const float *)range
					      : (CGDataProviderRef)profile
					      : (CGColorSpaceRef)alternateSpace
{
  //FIXME
  return nil;
}

+ (CGColorSpaceRef) CGColorSpaceCreateIndexed: (CGColorSpaceRef)baseSpace
					     : (size_t)lastIndex
					     : (const unsigned short int *)colorTable
{
  //FIXME
  return nil;
}

+ (size_t) CGColorSpaceGetNumberOfComponents: (CGColorSpaceRef)cs
{
  return [[(NSDictionary *)cs objectForKey: GSColorSpaceComponents] intValue];
}

+ (CGColorSpaceRef) CGColorSpaceRetain: (CGColorSpaceRef)cs
{
  return [(NSDictionary *)cs retain];
}

+ (void) CGColorSpaceRelease: (CGColorSpaceRef)cs
{
  [(NSDictionary *)cs release];
}


/* Fonts */

+ (CGFontRef) CGFontReferenceFromFont: (NSFont *)font
{
  return [font fontInfo];
}

+ (CGFontRef) CGFontRetain: (CGFontRef) font
{
  return [(GSFontInfo *)font retain];
}

+ (void) CGFontRelease: (CGFontRef) font
{
  [(GSFontInfo *)font release];
}

@end

