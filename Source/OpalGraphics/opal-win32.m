/** <title>opal-win32</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: 2010
   
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

#ifdef __MINGW__

#include <stdlib.h>
#include <cairo-win32.h>
#include "CoreGraphics/CGContext.h"
#include "CGContext-private.h"

CGContextRef opal_Win32ContextCreate(HDC hdc)
{
  CGContextRef ctx;
  cairo_surface_t *target;
  RECT r;

  target = cairo_win32_surface_create(hdc);

  GetClipBox(hdc, &r);

  ctx = opal_new_CGContext(target, CGSizeMake(r.right - r.left, r.bottom - r.top));

  cairo_surface_destroy(target);

  return ctx;
}

void opal_surface_flush(cairo_surface_t *target)
{
  cairo_surface_flush(target);
}

#endif
