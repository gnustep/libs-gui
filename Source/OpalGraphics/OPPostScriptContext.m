/** <title>OPPostScriptContext</title>

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

#include "CoreGraphics/OPPostScriptContext.h"
#include "CoreGraphics/CGDataConsumer.h"
#include "CGContext-private.h"
#include "CGDataConsumer-private.h"

#include <cairo.h>
#include <cairo-ps.h>

/* Constants */

const CFStringRef kOPPostScriptContextIsEPS = @"kOPPostScriptContextIsEPS";
const CFStringRef kOPPostScriptContextLanguageLevel = @"kOPPostScriptContextLanguageLevel";

/* Functions */

void OPPostScriptContextBeginPage(CGContextRef ctx, CFDictionaryRef pageInfo)
{
  // FIXME: Not sure what this should do. Nothing?
}

void OPPostScriptContextClose(CGContextRef ctx)
{
  cairo_status_t cret;
  cairo_surface_finish(cairo_get_target(ctx->ct));
  
  cret = cairo_status(ctx->ct);
  if (cret) {
    NSLog(@"OPPostScriptContextClose status: %s",
          cairo_status_to_string(cret));
    return;
  }
}

cairo_status_t opal_OPPostScriptContextWriteFunction(
  void *closure,
  const unsigned char *data,
  unsigned int length)
{
  OPDataConsumerPutBytes((CGDataConsumerRef)closure, data, length);
  return CAIRO_STATUS_SUCCESS;
}

static void  opal_setProperties(cairo_surface_t *surf, CFDictionaryRef auxiliaryInfo)
{
  if ([[auxiliaryInfo valueForKey: kOPPostScriptContextIsEPS] boolValue])
  {
    cairo_ps_surface_set_eps(surf, 1);
  }
  if ([[auxiliaryInfo valueForKey: kOPPostScriptContextLanguageLevel] intValue] == 2)
  {
     cairo_ps_surface_restrict_to_level(surf, CAIRO_PS_LEVEL_2);  
  }
  if ([[auxiliaryInfo valueForKey: kOPPostScriptContextLanguageLevel] intValue] == 3)
  {
    cairo_ps_surface_restrict_to_level(surf, CAIRO_PS_LEVEL_3);
  }
}

static cairo_user_data_key_t OpalDataConsumerKey;

static void opal_SurfaceDestoryFunc(void *data)
{
  CGDataConsumerRelease((CGDataConsumerRef)data);
}


CGContextRef OPPostScriptContextCreate(
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
  
  cairo_surface_t *surf = cairo_ps_surface_create_for_stream(
    opal_OPPostScriptContextWriteFunction,
    CGDataConsumerRetain(consumer),
    box.size.width,
    box.size.height);

  cairo_surface_set_user_data(surf, &OpalDataConsumerKey, consumer, opal_SurfaceDestoryFunc);

  opal_setProperties(surf, auxiliaryInfo);
 
  CGContextRef ctx = opal_new_CGContext(surf, box.size);
  return ctx;
}

CGContextRef OPPostScriptContextCreateWithURL(
  CFURLRef url,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo)
{
  CGDataConsumerRef dc = CGDataConsumerCreateWithURL(url);
  CGContextRef ctx = OPPostScriptContextCreate(dc, mediaBox, auxiliaryInfo);
  CGDataConsumerRelease(dc);
  return ctx;
}

void OPPostScriptContextEndPage(CGContextRef ctx)
{
  // Make sure it is not an EPS surface, which are single-page
  if (!cairo_ps_surface_get_eps(cairo_get_target(ctx->ct)))
  {
    cairo_status_t cret;
    cairo_show_page(ctx->ct);
  
    cret = cairo_status(ctx->ct);
    if (cret) {
      NSLog(@"OPPostScriptContextEndPage status: %s",
             cairo_status_to_string(cret));
      return;
    }
  }
}

