/*
   NSBitmapImageRep+SVG.m

   Methods for loading .svg images.

   Copyright (C) 2008 Free Software Foundation, Inc.
   
   Written by: Gregory Casamento
   Date: 2016-11-26

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

#import "config.h"
#import "NSBitmapImageRep+SVG.h"
#import <Foundation/NSByteOrder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import "AppKit/NSGraphics.h"
#import "GSGuiPrivate.h"
#include <librsvg-2.0/librsvg/rsvg.h>

#define SVG_HEADER @"SVG"
#define XML_HEADER @"DOCTYPE"

@implementation NSBitmapImageRep (SVG)

+ (BOOL) _bitmapIsSVG: (NSData *)imageData
{
  NSString *string = nil; 
  
  /*
   * If the data is 0, return immediately.
   */
  if ([imageData length] < 8)
    {
      return NO;
    }

  /*
   * Check the beginning of the data for 
   * the string "svg" or "doctype".
   */
  string = [NSString stringWithUTF8String:[imageData bytes]];
  if([string containsString: SVG_HEADER] &&
     [string containsString: XML_HEADER])
    {
      return YES;
    }

  return NO;
}

+ (NSArray*) _imageRepsWithSVGData: (NSData *)imageData
{
  NSMutableArray *array = [NSMutableArray array];
  return array;
}

- (id) _initBitmapFromSVG: (NSData *)imageData
{
  return nil;
}

@end
