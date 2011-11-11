/** <title>CGFunction</title>
 
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
#include "CoreGraphics/CGFunction.h"

@interface CGFunction : NSObject
{
@public
}

@end

@implementation CGFunction

@end


CGFunctionRef CGFunctionCreate(
  void *info,
  size_t domainDimension,
  const CGFloat *domain,
  size_t rangeDimension,
  const CGFloat *range,
  const CGFunctionCallbacks *callbacks)
{
  CGFunctionRef func = [[CGFunction alloc] init];
  
  //FIXME
  
  return func;
}

CGFunctionRef CGFunctionRetain(CGFunctionRef function)
{
  return [function retain];
}

void CGFunctionRelease(CGFunctionRef function)
{
  [function release];
}
