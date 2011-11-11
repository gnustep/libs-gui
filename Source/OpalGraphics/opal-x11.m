/** <title>opal-x11</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006
   
   This file is part of GNUstep

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
   */

#ifndef __MINGW__

#include <stdlib.h>
#include <cairo-xlib.h>
#include "CoreGraphics/CGContext.h"
#include "CGContext-private.h"

/* Internal cairo API, declare it here to avoid dependencies of cairoint.h */
extern void _cairo_surface_set_device_scale(cairo_surface_t *surface,
                                            double sx, double sy);

/* Keys we use to attach additional data to Xlib surfaces */
static cairo_user_data_key_t XWindow;

CGContextRef opal_XWindowContextCreate(Display *d, Window w)
{
  CGContextRef ctx;
  XWindowAttributes wa;
  cairo_surface_t *target;
  int ret;

  ret = XGetWindowAttributes(d, w, &wa);
  if (!ret) {
    NSLog(@"XGetWindowAttributes returned %d", ret);
    return NULL;
  }

  target = cairo_xlib_surface_create(d, w, wa.visual, wa.width, wa.height);

  /* May not need this but left here for reference */
  ret = cairo_surface_set_user_data(target, &XWindow, (void *)w, NULL);
  if (ret) {
    NSLog(@"cairo_surface_set_user_data %s", cairo_status_to_string(CAIRO_STATUS_NO_MEMORY));
    cairo_surface_destroy(target);
    return NULL;
  }

  /* Flip coordinate system */
  //cairo_surface_set_device_offset(target, 0, wa.height);
  /* FIXME: The scale part of device transform does not work correctly in
   * cairo so for now we have to patch the CTM! This should really be fixed
   * in cairo and then the ScaleCTM call below and the hacks in GetCTM in
   * CGContext should be removed in favour of the following line: */
  /* _cairo_surface_set_device_scale(target, 1.0, -1.0); */
  
  // NOTE: It doesn't looks like cairo will support using both device_scale and 
  //       device_offset any time soon, so I moved the translation part of the
  //       flip to the transformation matrix, to be consistent.
  //       - Eric

  ctx = opal_new_CGContext(target, CGSizeMake(wa.width, wa.height));


  cairo_surface_destroy(target);

  return ctx;
}

void opal_XWindowContexSetSize(CGContextRef ctx, CGSize size)
{
  OPContextSetSize(ctx, size); // Updates CTM
  cairo_xlib_surface_set_size(cairo_get_target(ctx->ct), size.width, size.height);
}

void opal_surface_flush(cairo_surface_t *target)
{
  XFlush(cairo_xlib_surface_get_display(target));
}

#endif
