/** <title>CGPattern</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: June 2010
 
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

#import <Foundation/NSObject.h>
#include "CoreGraphics/CGPattern.h"

@interface CGPattern : NSObject
{
  void *info;
}
@end
@implementation CGPattern
@end


CGPatternRef CGPatternCreate(
  void *info,
  CGRect bounds,
  CGAffineTransform matrix,
  CGFloat xStep,
  CGFloat yStep,
  CGPatternTiling tiling,
  int isColored,
  const CGPatternCallbacks *callbacks)
{
  CGPatternRef pattern = nil;
  
  // FIXME

  return pattern;
}

CFTypeID CGPatternGetTypeID()
{
  return (CFTypeID)[CGPattern class];
}

CGPatternRef CGPatternRetain(CGPatternRef pattern)
{
  return [pattern retain];
}

void CGPatternRelease(CGPatternRef pattern)
{
  [pattern release];
}


