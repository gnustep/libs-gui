/** <title>CGGradient</title>
 
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
#import <Foundation/NSArray.h>
#include "CoreGraphics/CGGradient.h"
#include "CoreGraphics/CGColor.h"
 
@interface CGGradient : NSObject
{
@public
  CGColorSpaceRef cs;
  CGFloat *components;
  CGFloat *locations;
  size_t count;
}

@end

@implementation CGGradient

- (id) initWithComponents: (const CGFloat[])comps
                locations: (const CGFloat[])locs
                    count: (size_t) cnt
               colorspace: (CGColorSpaceRef)cspace
{
  self = [super init];
  
  size_t numcomps = cnt * (CGColorSpaceGetNumberOfComponents(cspace) + 1);
  
  components = malloc(numcomps * sizeof(CGFloat));
  memcpy(components, comps, numcomps * sizeof(CGFloat));
  locations = malloc(cnt * sizeof(CGFloat));
  memcpy(locations, locs, cnt * sizeof(CGFloat));
  count = cnt;
  cs = CGColorSpaceRetain(cspace);
  
  return self; 
}
- (void) dealloc
{
  free(components);
  free(locations);
  CGColorSpaceRelease(cs);
  [super dealloc];
}
- (id) copyWithZone: (NSZone*)zone
{
  return [self retain];    
}

@end

/* Private */

CGColorSpaceRef OPGradientGetColorSpace(CGGradientRef g)
{
  return g->cs;
}
const CGFloat *OPGradientGetComponents(CGGradientRef g)
{
  return g->components;
}
const CGFloat *OPGradientGetLocations(CGGradientRef g)
{
  return g->locations; 
}
size_t OPGradientGetCount(CGGradientRef g)
{
  return g->count;
}


/* Public */


CGGradientRef CGGradientCreateWithColorComponents(
  CGColorSpaceRef cs,
  const CGFloat components[],
  const CGFloat locations[],
  size_t count)
{
  return [[CGGradient alloc] initWithComponents: components locations: locations count: count colorspace: cs];
}

CGGradientRef CGGradientCreateWithColors(
  CGColorSpaceRef cs,
  CFArrayRef colors,
  const CGFloat locations[])
{
  size_t count = [colors count];
  size_t cs_numcomps = CGColorSpaceGetNumberOfComponents(cs) + 1;
  CGFloat components[count * cs_numcomps];
  for (int i=0; i<count; i++)
  {
    CGColorRef clr = [colors objectAtIndex: i];
    memcpy(&components[i*cs_numcomps], CGColorGetComponents(clr), cs_numcomps * sizeof(CGFloat));
  }
  return CGGradientCreateWithColorComponents(cs, components, locations, count);
}

CFTypeID CGGradientGetTypeID()
{
  return (CFTypeID)[CGGradient class];
}

CGGradientRef CGGradientRetain(CGGradientRef grad)
{
  return [grad retain];
}

void CGGradientRelease(CGGradientRef grad)
{
  [grad release];
}
