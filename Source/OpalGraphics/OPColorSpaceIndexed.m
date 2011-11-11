/** <title>OPColorSpaceIndexed</title>

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

#import <Foundation/Foundation.h>

#import "OPColorSpaceIndexed.h"

@implementation OPColorSpaceIndexed

- (id)initWithBaseSpace: (CGColorSpaceRef)aBaseSpace
              lastIndex: (size_t)aLastIndex
             colorTable: (const unsigned char *)aColorTable
{
  self = [super init];
  ASSIGN(base, aBaseSpace);
  lastIndex = aLastIndex;

  table = malloc([self tableSize]);
  if (NULL == table)
  {
    [self release];
    return nil;
  }
  memmove(table, aColorTable, [self tableSize]);

  return self;
}
- (size_t) tableSize
{
  return (lastIndex + 1) * CGColorSpaceGetNumberOfComponents(base);
}
- (void) dealloc
{
  free(table);
  CGColorSpaceRelease(base);
  [super dealloc];    
}
- (NSData*)ICCProfile
{
	return [base ICCProfile]; // FIXME: ???
}
- (NSString*)name
{
	return [base name]; // FIXME: ???
}
- (CGColorSpaceRef) baseColorSpace
{
	return base;
}
- (size_t) numberOfComponents
{
  return [base numberOfComponents];
}
- (void) getColorTable: (uint8_t*)tableOut
{
  memmove(tableOut, self->table, [self tableSize]);
}
- (size_t) colorTableCount
{
  return self->lastIndex + 1;
}
- (CGColorSpaceModel) model
{
	return [base model];
}
- (BOOL) isEqual: (id)other
{
  if ([other isKindOfClass: [OPColorSpaceIndexed class]])
  {
    OPColorSpaceIndexed *otherIndexed = (OPColorSpaceIndexed*)other;
    return [self->base isEqual: otherIndexed->base]
      && self->lastIndex == otherIndexed->lastIndex
      && (0 == memcmp(otherIndexed->table, 
                      self->table,
                      [self tableSize]));
  }
  return NO;
}

- (id<OPColorTransform>) colorTransformTo: (id<CGColorSpace>)otherColor
                          sourceFormat: (OPImageFormat)sourceFormat
                     destinationFormat: (OPImageFormat)destFormat
{
	return [[[OPColorTransformIndexed alloc] init] autorelease];
}

@end

@implementation OPColorTransformIndexed

- (void) transformPixelData: (const unsigned char *)input
                     output: (unsigned char *)output
{
	// FIXME:
}

@end

