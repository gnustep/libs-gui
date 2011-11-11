/** <title>CGBitmapContext</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2009 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: January 2010
  
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

#include "CoreGraphics/CGBitmapContext.h"
#include "CGContext-private.h" 

@interface CGBitmapContext : CGContext
{
@public
  CGColorSpaceRef cs;
  void *data;
  void *releaseInfo;
  CGBitmapContextReleaseDataCallback cb;
}
- (id) initWithSurface: (cairo_surface_t *)target
            colorspace: (CGColorSpaceRef)colorspace
                  data: (void*)d
           releaseInfo: (void*)i
       releaseCallback: (CGBitmapContextReleaseDataCallback)releaseCallback;     
@end

@implementation CGBitmapContext

- (id) initWithSurface: (cairo_surface_t *)target
            colorspace: (CGColorSpaceRef)colorspace
                  data: (void*)d
           releaseInfo: (void*)i
       releaseCallback: (CGBitmapContextReleaseDataCallback)releaseCallback;     
{
  CGSize size = CGSizeMake(cairo_image_surface_get_width(target),
                           cairo_image_surface_get_height(target));
  if (nil == (self = [super initWithSurface: target size: size]))
  {
    return nil;
  }
  cs = CGColorSpaceRetain(colorspace);
  data = d;
  releaseInfo = i;
  cb = releaseCallback;
  return self;
}

- (void) dealloc
{
  CGColorSpaceRelease(cs);
  if (cb)
  {
  	cb(releaseInfo, data);
  }
  [super dealloc];    
}

@end


CGContextRef CGBitmapContextCreate(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef cs,
  CGBitmapInfo info)
{
  return CGBitmapContextCreateWithData(data, width, height, bitsPerComponent,
    bytesPerRow, cs, info, NULL, NULL);
}

static void OPBitmapDataReleaseCallback(void *info, void *data)
{
  free(data);
}

CGContextRef CGBitmapContextCreateWithData(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef cs,
  CGBitmapInfo info,
  CGBitmapContextReleaseDataCallback callback,
  void *releaseInfo)
{
  cairo_format_t format;
  cairo_surface_t *surf;  

  if (0 != (info & kCGBitmapFloatComponents))
  {
  	NSLog(@"Float components not supported"); 
    return nil;
  }
  
  const int order = info & kCGBitmapByteOrderMask;
  if (!((NSHostByteOrder() == NS_LittleEndian) && (order == kCGBitmapByteOrder32Little))
    && !((NSHostByteOrder() == NS_BigEndian) && (order == kCGBitmapByteOrder32Big))
	&& !(order == kCGBitmapByteOrderDefault))
  {
  	NSLog(@"Bitmap context must be native-endiand");
    return nil;
  }

  const int alpha = info &  kCGBitmapAlphaInfoMask;
  const CGColorSpaceModel model = CGColorSpaceGetModel(cs);
  const size_t numComps = CGColorSpaceGetNumberOfComponents(cs);
  
  if (bitsPerComponent == 8
      && numComps == 3
      && model == kCGColorSpaceModelRGB
      && alpha == kCGImageAlphaPremultipliedFirst)
  {
  	format = CAIRO_FORMAT_ARGB32;
  }
  else if (bitsPerComponent == 8
      && numComps == 3
      && model == kCGColorSpaceModelRGB
      && alpha == kCGImageAlphaNoneSkipFirst)
  {
  	format = CAIRO_FORMAT_RGB24;
  }
  else if (bitsPerComponent == 8 && alpha == kCGImageAlphaOnly)
  {
  	format = CAIRO_FORMAT_A8;
  }
  else if (bitsPerComponent == 1 && alpha == kCGImageAlphaOnly)
  {
  	format = CAIRO_FORMAT_A1;
  }
  else
  {
  	NSLog(@"Unsupported bitmap format");
    return nil;
  }
  
  
  if (data == NULL)
  {
  	data = malloc(height * bytesPerRow); // FIXME: checks
  	callback = (CGBitmapContextReleaseDataCallback)OPBitmapDataReleaseCallback;
  }

  surf = cairo_image_surface_create_for_data(data, format, width, height, bytesPerRow);
  
  return [[CGBitmapContext alloc] initWithSurface: surf
                                       colorspace: cs
                                             data: data
                                      releaseInfo: releaseInfo
		                          releaseCallback: callback];
}


CGImageAlphaInfo CGBitmapContextGetAlphaInfo(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    switch (cairo_image_surface_get_format(cairo_get_target(ctx->ct)))
	{
	  case CAIRO_FORMAT_ARGB32:
	    return kCGImageAlphaPremultipliedFirst;
	  case CAIRO_FORMAT_RGB24:
	    return kCGImageAlphaNoneSkipFirst;
	  case CAIRO_FORMAT_A8:
	  case CAIRO_FORMAT_A1:
	    return kCGImageAlphaOnly;
	  default:
	    return kCGImageAlphaNone;
	}
  }
  return kCGImageAlphaNone;
}

CGBitmapInfo CGBitmapContextGetBitmapInfo(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_stride(cairo_get_target(ctx->ct));
  }
  return 0;
}

size_t CGBitmapContextGetBitsPerComponent(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    switch (cairo_image_surface_get_format(cairo_get_target(ctx->ct)))
	{
	  case CAIRO_FORMAT_ARGB32:
	  case CAIRO_FORMAT_RGB24:
	  case CAIRO_FORMAT_A8:
	    return 8;
	  case CAIRO_FORMAT_A1:
	    return 1;
	  default:
	    return 0;
	}
  }
  return 0;
}

size_t CGBitmapContextGetBitsPerPixel(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    switch (cairo_image_surface_get_format(cairo_get_target(ctx->ct)))
	{
	  case CAIRO_FORMAT_ARGB32:
	  case CAIRO_FORMAT_RGB24:
	    return 32;
	  case CAIRO_FORMAT_A8:
	    return 8;
	  case CAIRO_FORMAT_A1:
	    return 1;
	  default:
	    return 0;
	}
  }
  return 0;
}

size_t CGBitmapContextGetBytesPerRow(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_stride(cairo_get_target(ctx->ct));
  }
  return 0;
}

CGColorSpaceRef CGBitmapContextGetColorSpace(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
  	return ((CGBitmapContext*)ctx)->cs;
  }
  return nil;
}

void *CGBitmapContextGetData(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_data(cairo_get_target(ctx->ct));
  }
  return 0;
}

size_t CGBitmapContextGetHeight(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_height(cairo_get_target(ctx->ct));
  }
  return 0;
}

size_t CGBitmapContextGetWidth(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_width(cairo_get_target(ctx->ct));
  }
  return 0;
}

static void OpalReleaseContext(void *info, const void *data, size_t size)
{
  CGContextRelease(info);
}

CGImageRef CGBitmapContextCreateImage(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    CGDataProviderRef dp = CGDataProviderCreateWithData(
      CGContextRetain(ctx),
      CGBitmapContextGetData(ctx),
      CGBitmapContextGetBytesPerRow(ctx) * CGBitmapContextGetHeight(ctx),
      OpalReleaseContext
    );
    
    CGImageRef img = CGImageCreate(
      CGBitmapContextGetWidth(ctx), 
      CGBitmapContextGetHeight(ctx), 
      CGBitmapContextGetBitsPerComponent(ctx),
      CGBitmapContextGetBitsPerPixel(ctx),
      CGBitmapContextGetBytesPerRow(ctx),
      CGBitmapContextGetColorSpace(ctx),
      CGBitmapContextGetBitmapInfo(ctx),
      dp,
      NULL,
      true,
      kCGRenderingIntentDefault
    );
    
    CGDataProviderRelease(dp);
    return img;
  }
  return nil;
}
