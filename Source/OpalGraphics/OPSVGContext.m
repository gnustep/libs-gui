/** <title>OPSVGContext</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: June, 2010

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

#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSDictionary.h>

#include "CoreGraphics/OPSVGContext.h"
#include "CoreGraphics/CGDataConsumer.h"
#include "CGContext-private.h"
#include "CGDataConsumer-private.h"

#include <cairo.h>
#include <cairo-svg.h>

/* Constants */

const CFStringRef kOPSVGContextSVGVersion = @"kOPSVGContextSVGVersion";

/* Functions */

void OPSVGContextBeginPage(CGContextRef ctx, CFDictionaryRef pageInfo)
{
  // FIXME: Not sure what this should do. Nothing?
}

void OPSVGContextClose(CGContextRef ctx)
{
  cairo_status_t cret;
  cairo_surface_finish(cairo_get_target(ctx->ct));
  
  cret = cairo_status(ctx->ct);
  if (cret) {
    NSLog(@"OPSVGContextClose status: %s",
           cairo_status_to_string(cret));
    return;
  }
}

cairo_status_t opal_OPSVGContextWriteFunction(
  void *closure,
  const unsigned char *data,
  unsigned int length)
{
  OPDataConsumerPutBytes((CGDataConsumerRef)closure, data, length);
  return CAIRO_STATUS_SUCCESS;
}

static void opal_setProperties(cairo_surface_t *surf, CFDictionaryRef auxiliaryInfo)
{
  if ([[auxiliaryInfo valueForKey: kOPSVGContextSVGVersion] isEqual: @"1.1"])
  {
    cairo_svg_surface_restrict_to_version(surf, CAIRO_SVG_VERSION_1_1);
  }
  else if ([[auxiliaryInfo valueForKey: kOPSVGContextSVGVersion] isEqual: @"1.2"])
  {
    cairo_svg_surface_restrict_to_version(surf, CAIRO_SVG_VERSION_1_2);
  }
}


static cairo_user_data_key_t OpalDataConsumerKey;

static void opal_SurfaceDestoryFunc(void *data)
{
  CGDataConsumerRelease((CGDataConsumerRef)data);
}


CGContextRef OPSVGContextCreate(
  CGDataConsumerRef consumer,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo)
{
  CGRect box;
  if (mediaBox == NULL) {
    box = CGRectMake(0, 0, 8.5 * 72, 11 * 72);
  } else {
    box = *mediaBox;
  }
  
  //FIXME: We ignore the origin of mediaBox.. is that correct?
  
  cairo_surface_t *surf = cairo_svg_surface_create_for_stream(
    opal_OPSVGContextWriteFunction,
    CGDataConsumerRetain(consumer),
    box.size.width,
    box.size.height);
  
  cairo_surface_set_user_data(surf, &OpalDataConsumerKey, consumer, opal_SurfaceDestoryFunc);
    
  opal_setProperties(surf, auxiliaryInfo);

  CGContextRef ctx = opal_new_CGContext(surf, box.size);
  return ctx;
}

CGContextRef OPSVGContextCreateWithURL(
  CFURLRef url,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo)
{
  CGDataConsumerRef dc = CGDataConsumerCreateWithURL(url);
  CGContextRef ctx = OPSVGContextCreate(dc, mediaBox, auxiliaryInfo);
  CGDataConsumerRelease(dc);
  return ctx;
}

void OPSVGContextEndPage(CGContextRef ctx)
{
  cairo_status_t cret;
  cairo_show_page(ctx->ct);
  
  cret = cairo_status(ctx->ct);
  if (cret) {
    NSLog(@"OPSVGContextEndPage status: %s",
          cairo_status_to_string(cret));
    return;
  }
}

