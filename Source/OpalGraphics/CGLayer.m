/** <title>CGLayer</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2009 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: Dec 2009
  
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
#include <math.h>
#include "CoreGraphics/CGLayer.h"
#include "CGContext-private.h"

@interface CGLayer : NSObject
{
@public
  CGContextRef ctxt;
  CGSize size;
}
@end

@implementation CGLayer

- (void) dealloc
{
  CGContextRelease(self->ctxt);
  [super dealloc];
}

@end


CGLayerRef CGLayerCreateWithContext(
  CGContextRef referenceCtxt,
  CGSize size,
  CFDictionaryRef auxInfo)
{
  CGLayer *layer = [[CGLayer alloc] init];
  if (!layer) return NULL;
  
  // size is in user-space units of referenceCtxt, so transform it to device
  // space.
  double w = size.width, h = size.height;
  cairo_user_to_device_distance(referenceCtxt->ct, &w, &h);
  
  cairo_surface_t *layerSurface = 
    cairo_surface_create_similar(cairo_get_target(referenceCtxt->ct),
                                 CAIRO_CONTENT_COLOR_ALPHA,
                                 ceil(fabs(w)),
                                 ceil(fabs(h)));
  layer->ctxt = opal_new_CGContext(layerSurface, CGSizeMake(ceil(fabs(w)), ceil(fabs(h))));
  layer->size = size;
  
  return layer;
}

CFTypeID CGLayerGetTypeID()
{
  return (CFTypeID)[CGLayer class];
}

CGLayerRef CGLayerRetain(CGLayerRef layer)
{
  return [layer retain];
}

void CGLayerRelease(CGLayerRef layer)
{
  [layer release];
}

CGSize CGLayerGetSize(CGLayerRef layer)
{
  return layer->size;
}

CGContextRef CGLayerGetContext(CGLayerRef layer)
{
  return layer->ctxt;
}

void CGContextDrawLayerInRect(
  CGContextRef destCtxt,
  CGRect rect,
  CGLayerRef layer)
{
  opal_draw_surface_in_rect(destCtxt, rect, cairo_get_target(layer->ctxt->ct),
    CGRectMake(0, 0, layer->size.width, layer->size.height));
}

void CGContextDrawLayerAtPoint(
  CGContextRef destCtxt,
  CGPoint point,
  CGLayerRef layer)
{
  CGContextDrawLayerInRect(destCtxt,
    CGRectMake(point.x, point.y, layer->size.width, layer->size.height),
    layer);
}

