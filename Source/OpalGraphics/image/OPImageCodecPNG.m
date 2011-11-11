/*
   NSBitmapImageRep+PNG.m

   Methods for loading .png images.

   Copyright (C) 2010 Free Software Foundation, Inc.

   Written by:  Eric Wasylishen <ewasylishen@gmail.com>
   Date: July 2010   
   Written by: Alexander Malmberg <alexander@malmberg.org>
   Date: 2003-12-07
   
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

#ifdef HAVE_LIBPNG_PNG_H
#include <libpng/png.h>
#else
#include <png.h>
#endif

#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

#import "CGImageSource-private.h"
#import "CGImageDestination-private.h"
#import "CGDataProvider-private.h"
#import "CGDataConsumer-private.h"

#if defined(PNG_FLOATING_POINT_SUPPORT)
#  define PNG_FLOATING_POINT 1
#else
#  define PNG_FLOATING_POINT 0
#endif
#if defined(PNG_gAMA_SUPPORT)
#  define PNG_gAMA 1
#else
#  define PNG_gAMA 0
#endif

extern void DumpPixel(const void *data, NSString *msg);

static void opal_png_error_fn(png_structp png_ptr, png_const_charp error_msg)
{
  [NSException raise: @"PNGException" format: @"%s", error_msg];
}

static void opal_png_warning_fn(png_structp png_ptr, png_const_charp warning_msg)
{
  NSLog(@"PNG Warning: '%s'", warning_msg);   
}

static void opal_png_reader_func(png_structp png_struct, png_bytep data,
			png_size_t length)
{
  CGDataProviderRef dp = (CGDataProviderRef)png_get_io_ptr(png_struct);

  if (OPDataProviderGetBytes(dp, data, length) < length)
    {
      png_error(png_struct, "end of buffer");
      return;
    }
}

static void opal_png_writer_func(png_structp png_struct, png_bytep data,
			png_size_t length)
{
  CGDataConsumerRef dc = (CGDataConsumerRef)png_get_io_ptr(png_struct);
  OPDataConsumerPutBytes(dc, data, length);
}

static bool opal_has_png_header(CGDataProviderRef dp)
{
  OPDataProviderRewind(dp);
  unsigned char header[8];
  OPDataProviderGetBytes(dp, header, 8);
  return (0 == png_sig_cmp(header, 0, 8));
}





@interface CGImageSourcePNG : CGImageSource
{
  CGDataProviderRef dp;
}
@end

@implementation CGImageSourcePNG

+ (void)load
{
  [CGImageSource registerSourceClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.png"];
}

- (id)initWithProvider: (CGDataProviderRef)provider;
{
  self = [super init];
  dp = CGDataProviderRetain(provider);
  return self;
}

- (void)dealloc
{
  CGDataProviderRelease(dp);
  [super dealloc];
}

- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts
{
  return [NSDictionary dictionary];
}

- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts atIndex: (size_t)index
{
  return [NSDictionary dictionary];  
}

- (size_t)count
{
  return 1;
}

- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)opts
{
  CGImageRef img = NULL;
  png_structp png_struct;
  png_infop png_info, png_end_info;

  if (!(self = [super init]))
    return NULL;

  if (!opal_has_png_header(dp))
    return NULL;
    
  OPDataProviderRewind(dp);
  
  NS_DURING
  {
    png_struct = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, opal_png_error_fn, opal_png_warning_fn);
    if (!png_struct)
      {
        RELEASE(self);
        return NULL;
      }
  
    png_info = png_create_info_struct(png_struct);
    if (!png_info)
      {
        png_destroy_read_struct(&png_struct, NULL, NULL);
        RELEASE(self);
        return NULL;
      }
  
    png_end_info = png_create_info_struct(png_struct);
    if (!png_end_info)
      {
        png_destroy_read_struct(&png_struct, &png_info, NULL);
        RELEASE(self);
        return NULL;
      }

    png_set_read_fn(png_struct, dp, opal_png_reader_func);
  
    png_read_info(png_struct, png_info);
  
    int width = png_get_image_width(png_struct, png_info);
    int height = png_get_image_height(png_struct, png_info);
    int bytes_per_row = png_get_rowbytes(png_struct, png_info);
    int type = png_get_color_type(png_struct, png_info);
    int channels = png_get_channels(png_struct, png_info); // includes alpha
    int depth = png_get_bit_depth(png_struct, png_info);
  
    BOOL alpha = NO;
    CGColorSpaceRef cs = NULL;
    
    switch (type)
    {
      case PNG_COLOR_TYPE_GRAY_ALPHA:
        alpha = YES;
      case PNG_COLOR_TYPE_GRAY:
      	cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
      	break;
      
    	case PNG_COLOR_TYPE_RGB_ALPHA:	
    	  alpha = YES;
      case PNG_COLOR_TYPE_RGB:
      	cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        break;
                	
      case PNG_COLOR_TYPE_PALETTE:
      	png_set_palette_to_rgb(png_struct);
      	if (png_get_valid(png_struct, png_info, PNG_INFO_tRNS))
        {
          alpha = YES;
          png_set_tRNS_to_alpha(png_struct);
        }
        cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
      	break;

      default:
      	NSLog(@"NSBitmapImageRep+PNG: unknown color type %i", type);
      	RELEASE(self);
      	return NULL;
    }
  
    // FIXME: Handle colorspaces properly
    // FIXME: Handle color rendering intent
    // FIXME: Handle gamma
    // FIXME: Handle resolution

    // Create the CGImage
    
    NSMutableData *imgData = [[NSMutableData alloc] initWithLength: height * bytes_per_row];
    {
      unsigned char *row_pointers[height];
      unsigned char *buf = [imgData mutableBytes];
      for (int i = 0; i < height; i++)
      {
        row_pointers[i] = buf + (i * bytes_per_row);
      }
      png_read_image(png_struct, row_pointers);
    }    
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imgData);
    [imgData release];
    
    img = CGImageCreate(
      width,
      height,
      depth,
      channels * depth,
      bytes_per_row,
      cs,
      kCGBitmapByteOrderDefault | (alpha ? kCGImageAlphaLast : kCGImageAlphaNone),
      imgDataProvider,
      NULL,
      true,
      kCGRenderingIntentDefault);

		DumpPixel([imgData bytes], @"read from png: (expecting R G B A)");

    CGColorSpaceRelease(cs);
    CGDataProviderRelease(imgDataProvider);
  }
  NS_HANDLER
  {
    RELEASE(self);
    png_destroy_read_struct(&png_struct, &png_info, &png_end_info);
    NS_VALUERETURN(nil, CGImageRef);
  }
  NS_ENDHANDLER
  
  png_destroy_read_struct(&png_struct, &png_info, &png_end_info);
  
  return img;
}

- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)opts
{
  return nil;
}

- (CGImageSourceStatus)status
{
  return kCGImageStatusComplete;
}

- (CGImageSourceStatus)statusAtIndex: (size_t)index
{
  return kCGImageStatusComplete;
}

- (NSString*)type
{
  return @"public.png";
}

- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate
{
  ;
}

@end



@interface CGImageDestinationPNG : CGImageDestination
{
  CGDataConsumerRef dc;
  CFDictionaryRef props;
  CGImageRef img;
}
@end

@implementation CGImageDestinationPNG

+ (void)load
{
  [CGImageDestination registerDestinationClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.png"];
}
- (id) initWithDataConsumer: (CGDataConsumerRef)consumer
                       type: (CFStringRef)type
                      count: (size_t)count
                    options: (CFDictionaryRef)opts
{
  self = [super init];
  
  if ([type isEqualToString: @"public.png"] || count != 1)
  {
    [self release];
    return nil;
  }
  
  dc = [consumer retain];
  
  return self;
}

- (void)dealloc
{
  CGDataConsumerRelease(dc);
  [props release];
  CGImageRelease(img);
  [super dealloc];    
}

- (void) setProperties: (CFDictionaryRef)properties
{
  ASSIGN(props, properties);
}

- (void) addImage: (CGImageRef)image properties: (CFDictionaryRef)properties
{
  img = CGImageRetain(image);
  ASSIGN(props, properties);
}

- (bool) finalize
{
  png_structp png_struct;
  png_infop png_info;

  // make the PNG structures
  png_struct = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, opal_png_error_fn, opal_png_warning_fn);
  if (!png_struct)
  {
    return false;
  }

  png_info = png_create_info_struct(png_struct);
  if (!png_info)
  {
    png_destroy_write_struct(&png_struct, NULL);
    return false;
  }

  NS_DURING  
  {
    const bool interlace = false;
    const int width = CGImageGetWidth(img);
    const int height = CGImageGetHeight(img);
    const int bytes_per_row = CGImageGetBytesPerRow(img);    
    const int depth = CGImageGetBitsPerComponent(img);
  
    const int alphaInfo = CGImageGetAlphaInfo(img);
    const CGColorSpaceModel model = CGColorSpaceGetModel(CGImageGetColorSpace(img));
    
    int type;
    switch (model)
    {
      case kCGColorSpaceModelRGB:
        type = PNG_COLOR_TYPE_RGB; 
        break;
      case kCGColorSpaceModelMonochrome:
        type = PNG_COLOR_TYPE_GRAY;
        break;
      default:
        NSLog(@"Unsupported color model");
        return false;
    }
    
    switch (alphaInfo)
    {
      case kCGImageAlphaNone:
        break;
        
      case kCGImageAlphaPremultipliedFirst:
        //png_set_swap_alpha(png_struct);
        NSLog(@"Unsupported alpha type");
        return false;
        
      case kCGImageAlphaPremultipliedLast:
        // FIXME: must un-premultiply
        type |= PNG_COLOR_MASK_ALPHA;
        NSLog(@"Unsupported color model");
        return false;
        
      case kCGImageAlphaFirst:
        //png_set_swap_alpha(png_struct);
        NSLog(@"Unsupported alpha type");
        return false;
        
      case kCGImageAlphaLast:
        type |= PNG_COLOR_MASK_ALPHA;
        break;
        
      case kCGImageAlphaNoneSkipLast:
      case kCGImageAlphaNoneSkipFirst:
        // Will need to process
        NSLog(@"Unsupported alpha type");
        return false;
    }
          
    // init structures
    png_info_init_3(&png_info, png_sizeof(png_info));
    png_set_write_fn(png_struct, dc, opal_png_writer_func, NULL);
    png_set_IHDR(png_struct, png_info, width, height, depth,
     type, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE,
     PNG_FILTER_TYPE_BASE);
  
    png_write_info(png_struct, png_info);
    
    unsigned char *rowdata = malloc(bytes_per_row);
    CGDataProviderRef dp = CGImageGetDataProvider(img);
    const int times = interlace ? png_set_interlace_handling(png_struct) : 1;
    for (int i=0; i<times; i++)
    {
      OPDataProviderRewind(dp);
      for (int j=0; j<height; j++) 
      {
        OPDataProviderGetBytes(dp, rowdata, bytes_per_row);
        png_write_row(png_struct, rowdata);
      }
    }
    free(rowdata);
    
    png_write_end(png_struct, png_info);
  }
  NS_HANDLER
  {
    png_destroy_write_struct(&png_struct, &png_info);
    NS_VALUERETURN(false, bool);
  }
  NS_ENDHANDLER
              
  png_destroy_write_struct(&png_struct, &png_info);
  return true;
}

@end
