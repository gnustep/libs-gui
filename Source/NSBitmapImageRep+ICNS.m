/*
   NSBitmapImageRep+ICNS.m

   Methods for loading .icns images.

   Copyright (C) 2008 Free Software Foundation, Inc.
   
   Written by: Gregory Casamento
   Date: 2008-08-12
   
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

#include "config.h"
#include "NSBitmapImageRep+ICNS.h"

#if HAVE_LIBICNS

#include <icns.h>

#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>
#include "AppKit/NSGraphics.h"

#define ICNS_HEADER "icns"

// Define the pixel
typedef struct pixel_t
{
  uint8_t r;
  uint8_t g;
  uint8_t b;
  uint8_t a;
} pixel_t;

@implementation NSBitmapImageRep (ICNS)

+ (BOOL) _bitmapIsICNS: (NSData *)imageData
{
  char header[5];

  /*
   * If the data is 0, return immediately.
   */
  if (![imageData length])
    {
      return NO;
    }

  /*
   * Check the beginning of the data for 
   * the string "icns".
   */
  [imageData getBytes: header length: 4];
  if(strncmp(header, ICNS_HEADER, 4) == 0)
    {
      return YES;
    }

  return NO;
}

- (id) _initBitmapFromICNS: (NSData *)imageData
{
  int                     error = 0;
  int                     size = [imageData length];
  icns_byte_t            *bytes = (icns_byte_t *)[imageData bytes];
  icns_family_t          *iconFamily = NULL;
  unsigned long           dataOffset = 0;
  icns_byte_t            *data = NULL;
  char                    typeStr[5] = {0,0,0,0,0};
  unsigned int            iconWidth = 0, iconHeight = 0;
  icns_image_t            iconImage;
  icns_element_t          iconElement;
  icns_icon_info_t        iconInfo;
  int                     sPP = 4;
  unsigned char          *rgbBuffer = NULL; /* image converted to rgb */
  unsigned int            rgbBufferPos = 0;
  unsigned int            rgbBufferSize = 0;
  int                     i = 0, j = 0;
  int                     imageChannels = 0;
  // int                     maskChannels = 0;
  // icns_image_t            mask;

  error = icns_import_family_data(size, bytes, &iconFamily);
  if(error != ICNS_STATUS_OK)
    {
      NSLog(@"Error reading ICNS data.");
      RELEASE(self);
      return nil;
    }

  // skip the header...
  dataOffset = sizeof(icns_type_t) + sizeof(icns_size_t);
  data = (icns_byte_t *)iconFamily;

  // read each icon...
  while(((dataOffset + 8) < iconFamily->resourceSize))
    {
      icns_element_t   element;
      icns_icon_info_t info;
      icns_size_t      dataSize = 0;
      unsigned int     w = 0, h = 0;
      
      memcpy(&element, (data+dataOffset),8);
      memcpy(&typeStr, &(element.elementType),4);

      dataSize = element.elementSize - 8;

      info = icns_get_image_info_for_type(element.elementType);

      h = info.iconHeight;
      w = info.iconWidth;
      
      if( w > iconWidth )
	{
	  iconWidth = w;
	  iconHeight = h;
	  iconInfo = info;
	  iconElement = element;
	}

      // next...
      dataOffset += element.elementSize;
    }

  // extract the image...
  memset ( &iconImage, 0, sizeof(icns_image_t) );
  error = icns_get_image32_with_mask_from_family(iconFamily,iconElement.elementType,&iconImage);
  if(error)
    {
      NSLog(@"Error while extracting image from ICNS data.");
      RELEASE(self);
      return nil;
    }

  // allocate the buffer...
  rgbBufferSize = iconHeight * (iconWidth * sizeof(unsigned char) * sPP);
  rgbBuffer = NSZoneMalloc([self zone],  rgbBufferSize); 
  if(rgbBuffer == NULL)
    {
      NSLog(@"Couldn't allocate memory for image data from ICNS.");
      RELEASE(self);
      return nil;
    }

  imageChannels = iconImage.imageChannels;
  rgbBufferPos = 0;
  for (i = 0; i < iconHeight; i++)
    {
      for(j = 0; j < iconWidth; j++)
	{
	  pixel_t	*src_rgb_pixel;
	  //pixel_t	*src_pha_pixel;
	  
	  src_rgb_pixel = (pixel_t *)&(iconImage.imageData[i*iconWidth*imageChannels+j*imageChannels]);
	  
	  rgbBuffer[rgbBufferPos++] = src_rgb_pixel->r;
	  rgbBuffer[rgbBufferPos++] = src_rgb_pixel->g;
	  rgbBuffer[rgbBufferPos++] = src_rgb_pixel->b;
	  
	  /*
	  if(mask != NULL) {
	    src_pha_pixel = (pixel_t *)&(mask.imageData[i*iconWidth*maskChannels+j*maskChannels]);
	    rgbBuffer[rgbBufferPos++] = src_pha_pixel->a;
	  } else {
	  */
	  rgbBuffer[rgbBufferPos++] = src_rgb_pixel->a;
       // }
	}
    }
  
  /* initialize self */
  [self initWithBitmapDataPlanes: &rgbBuffer
	pixelsWide: (float)iconWidth
	pixelsHigh: (float)iconHeight
	bitsPerSample: 8
	samplesPerPixel: sPP
	hasAlpha: YES
	isPlanar: NO
	colorSpaceName: NSCalibratedRGBColorSpace
	bytesPerRow: iconWidth * sPP
	bitsPerPixel: 8 * sPP];
  
  _imageData = [[NSData alloc] initWithBytesNoCopy: rgbBuffer
			       length: rgbBufferSize];

  return self;
}
@end

#else /* !HAVE_LIBICNS */

@implementation NSBitmapImageRep (ICNS)
+ (BOOL) _bitmapIsICNS: (NSData *)imageData
{
  return NO;
}

- (id) _initBitmapFromICNS: (NSData *)imageData
{
  RELEASE(self);
  return nil;
}
@end

#endif /* !HAVE_LIBICNS */

