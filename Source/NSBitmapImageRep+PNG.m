/*
   NSBitmapImageRep+PNG.m

   Methods for loading .png images.

   Copyright (C) 2003 Free Software Foundation, Inc.
   
   Written by: Alexander Malmberg <alexander@malmberg.org>
   Date: 2003-12-07
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   */

#include "config.h"
#include "NSBitmapImageRep+PNG.h"

#if HAVE_LIBPNG

#include <png.h>

#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include "AppKit/NSGraphics.h"


@implementation NSBitmapImageRep (PNG)

+ (BOOL) _bitmapIsPNG: (NSData *)imageData
{
  if (![imageData length])
    return NO;

  if (!png_sig_cmp((png_bytep)[imageData bytes], 0, [imageData length]))
    return YES;
  return NO;
}

typedef struct
{
  NSData *data;
  unsigned int offset;
} reader_struct_t;

static void reader_func(png_structp png_struct, png_bytep data,
			png_size_t length)
{
  reader_struct_t *r = png_get_io_ptr(png_struct);

  if (r->offset + length > [r->data length])
    {
      png_error(png_struct, "end of buffer");
      return;
    }
  memcpy(data, [r->data bytes] + r->offset, length);
  r->offset += length;
}

- (id) _initBitmapFromPNG: (NSData *)imageData
{
  png_structp png_struct;
  png_infop png_info, png_end_info;

  int width,height;
  unsigned char *buf;
  int bytes_per_row;
  int type,channels,depth;

  BOOL alpha;
  int bpp;
  NSString *colorspace;

  reader_struct_t reader;


  if (!(self = [super init]))
    return nil;

  png_struct = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png_struct)
    {
      RELEASE(self);
      return nil;
    }

  png_info = png_create_info_struct(png_struct);
  if (!png_info)
    {
      png_destroy_read_struct(&png_struct, NULL, NULL);
      RELEASE(self);
      return nil;
    }

  png_end_info = png_create_info_struct(png_struct);
  if (!png_end_info)
    {
      png_destroy_read_struct(&png_struct, &png_info, NULL);
      RELEASE(self);
      return nil;
    }

  if (setjmp(png_jmpbuf(png_struct)))
    {
      png_destroy_read_struct(&png_struct, &png_info, &png_end_info);
      RELEASE(self);
      return nil;
    }

  reader.data = imageData;
  reader.offset = 0;
  png_set_read_fn(png_struct, &reader, reader_func);

  png_read_info(png_struct, png_info);

  width = png_get_image_width(png_struct, png_info);
  height = png_get_image_height(png_struct, png_info);
  bytes_per_row = png_get_rowbytes(png_struct, png_info);
  type = png_get_color_type(png_struct, png_info);
  channels = png_get_channels(png_struct, png_info);
  depth = png_get_bit_depth(png_struct, png_info);

  switch (type)
    {
      case PNG_COLOR_TYPE_GRAY:
	colorspace = NSCalibratedWhiteColorSpace;
	alpha = NO;
	NSAssert(channels == 1, @"unexpected channel/color_type combination");
	bpp = depth;
	break;

      case PNG_COLOR_TYPE_GRAY_ALPHA:
	colorspace = NSCalibratedWhiteColorSpace;
	alpha = YES;
	NSAssert(channels == 2, @"unexpected channel/color_type combination");
	bpp = depth * 2;
	break;

      case PNG_COLOR_TYPE_PALETTE:
	png_set_palette_to_rgb(png_struct);
	channels = 3;
	depth = 8;

	alpha = NO;
	if (png_get_valid(png_struct, png_info, PNG_INFO_tRNS))
	  {
	    alpha = YES;
	    channels++;
	    png_set_tRNS_to_alpha(png_struct);
	  }

	bpp = channels * 8;
	bytes_per_row = channels * width;
	colorspace = NSCalibratedRGBColorSpace;
	break;

      case PNG_COLOR_TYPE_RGB:
	colorspace = NSCalibratedRGBColorSpace;
	alpha = NO;
	bpp = channels * depth; /* channels might be 4 if there's a filler */
	channels = 3;
	break;

      case PNG_COLOR_TYPE_RGB_ALPHA:
	colorspace = NSCalibratedRGBColorSpace;
	alpha = YES;
	NSAssert(channels == 4, @"unexpected channel/color_type combination");
	bpp = 4 * depth;
	break;

      default:
	NSLog(@"NSBitmapImageRep+PNG: unknown color type %i", type);
	RELEASE(self);
	return nil;
    }

  buf = NSZoneMalloc([self zone], bytes_per_row * height);

  {
    unsigned char *row_pointers[height];
    int i;
    for (i=0;i<height;i++)
      row_pointers[i]=buf+i*bytes_per_row;
    png_read_image(png_struct, row_pointers);
  }

  [self initWithBitmapDataPlanes: &buf
		      pixelsWide: width
		      pixelsHigh: height
		   bitsPerSample: depth
		 samplesPerPixel: channels
			hasAlpha: alpha
			isPlanar: NO
		  colorSpaceName: colorspace
		     bytesPerRow: bytes_per_row
		    bitsPerPixel: bpp];

  _imageData = [[NSData alloc]
    initWithBytesNoCopy: buf
		 length: bytes_per_row * height];

  png_destroy_read_struct(&png_struct, &png_info, &png_end_info);

  return self;
}

@end

#else /* !HAVE_LIBPNG */

@implementation NSBitmapImageRep (PNG)
+ (BOOL) _bitmapIsPNG: (NSData *)imageData
{
  return NO;
}
- (id) _initBitmapFromPNG: (NSData *)imageData
{
  RELEASE(self);
  return nil;
}
@end

#endif /* !HAVE_LIBPNG */

