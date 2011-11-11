/** <title>OPColorSpaceIndexed</title>

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

#include "CoreGraphics/CGColorSpace.h"
#import "CGColorSpace-private.h"

@interface OPColorSpaceIndexed : NSObject
{
@public
  CGColorSpaceRef base;
  size_t lastIndex;
  unsigned char *table;
}

- (id)initWithBaseSpace: (CGColorSpaceRef)aBaseSpace
              lastIndex: (size_t)aLastIndex
             colorTable: (const unsigned char *)aColorTable;
- (size_t) tableSize;
- (CGColorSpaceRef) baseColorSpace;
- (void) getColorTable: (uint8_t*)tableOut;
- (size_t) colorTableCount;

- (id<OPColorTransform>) colorTransformTo: (id<CGColorSpace>)otherColor
                             sourceFormat: (OPImageFormat)sourceFormat
                        destinationFormat: (OPImageFormat)destFormat;

@end

@interface OPColorTransformIndexed : NSObject <OPColorTransform>
{
  id<OPColorTransform> baseTransform;
}

- (void) transformPixelData: (const unsigned char *)input
                     output: (unsigned char *)output;

@end

