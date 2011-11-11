/** <title>CGAffineTransform</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

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

#ifndef OPAL_CGAffineTransform_h
#define OPAL_CGAffineTransform_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGGeometry.h>

/* Data Types */

typedef struct CGAffineTransform
{
  CGFloat a;
  CGFloat b;
  CGFloat c;
  CGFloat d;
  CGFloat tx;
  CGFloat ty;
} CGAffineTransform;

/* Constants */

extern const CGAffineTransform CGAffineTransformIdentity;

/* Functions */

/* All but the most complex functions are declared static inline in this
 * header file so that they are maximally efficient.  In order to provide
 * true functions (for code modules that don't have this header) this
 * header is included in CGAffineTransform.c where the functions are no longer
 * declared inline.
 */
#ifdef IN_CGAFFINETRANSFORM_C
#define	GS_AFTR_SCOPE	extern
#define GS_AFTR_ATTR	
#else
#define	GS_AFTR_SCOPE	static inline
#define GS_AFTR_ATTR	__attribute__((unused))
#endif

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformMake(
  CGFloat a,
  CGFloat b,
  CGFloat c,
  CGFloat d,
  CGFloat tx,
  CGFloat ty
) GS_AFTR_ATTR;

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformMakeTranslation(
  CGFloat tx,
  CGFloat ty
) GS_AFTR_ATTR;

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformMakeScale(
  CGFloat sx,
  CGFloat sy
) GS_AFTR_ATTR;

CGAffineTransform CGAffineTransformMakeRotation(CGFloat angle);

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformConcat(
  CGAffineTransform t1,
  CGAffineTransform t2
) GS_AFTR_ATTR;

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformTranslate(
  CGAffineTransform t,
  CGFloat tx,
  CGFloat ty
) GS_AFTR_ATTR;

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformScale(
  CGAffineTransform t,
  CGFloat sx,
  CGFloat sy
) GS_AFTR_ATTR;

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformRotate(
  CGAffineTransform t,
  CGFloat angle
) GS_AFTR_ATTR;

CGAffineTransform CGAffineTransformInvert(CGAffineTransform t);

GS_AFTR_SCOPE CGPoint CGPointApplyAffineTransform(
  CGPoint point,
  CGAffineTransform t
) GS_AFTR_ATTR;

GS_AFTR_SCOPE CGSize CGSizeApplyAffineTransform(
  CGSize size,
  CGAffineTransform t
) GS_AFTR_ATTR;

CGRect CGRectApplyAffineTransform(
  CGRect rect,
  CGAffineTransform t
);

/* Inlined functions */

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformMake(
  CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat tx, CGFloat ty)
{
  CGAffineTransform matrix;

  matrix.a = a;
  matrix.b = b;
  matrix.c = c;
  matrix.d = d;
  matrix.tx = tx;
  matrix.ty = ty;

  return matrix;
}

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformMakeTranslation(
  CGFloat tx, CGFloat ty)
{
  CGAffineTransform matrix;

  matrix = CGAffineTransformIdentity;
  matrix.tx = tx;
  matrix.ty = ty;

  return matrix;
}

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformMakeScale(CGFloat sx, CGFloat sy)
{
  CGAffineTransform matrix;

  matrix = CGAffineTransformIdentity;
  matrix.a = sx;
  matrix.d = sy;

  return matrix;
}

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformConcat(
  CGAffineTransform t1, CGAffineTransform t2)
{
  CGAffineTransform t;

  t.a = t1.a * t2.a + t1.b * t2.c;
  t.b = t1.a * t2.b + t1.b * t2.d;
  t.c = t1.c * t2.a + t1.d * t2.c;
  t.d = t1.c * t2.b + t1.d * t2.d;
  t.tx = t1.tx * t2.a + t1.ty * t2.c + t2.tx;
  t.ty = t1.tx * t2.b + t1.ty * t2.d + t2.ty;

  return t;
}

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformTranslate(
  CGAffineTransform t, CGFloat tx, CGFloat ty)
{
  t.tx += tx * t.a + ty * t.c;
  t.ty += tx * t.b + ty * t.d;

  return t;
}

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformScale(
  CGAffineTransform t, CGFloat sx, CGFloat sy)
{
  t.a *= sx;
  t.b *= sx;
  t.c *= sy;
  t.d *= sy;

  return t;
}

GS_AFTR_SCOPE CGAffineTransform CGAffineTransformRotate(
  CGAffineTransform t, CGFloat angle)
{
  return CGAffineTransformConcat(CGAffineTransformMakeRotation(angle), t);
}

GS_AFTR_SCOPE CGPoint CGPointApplyAffineTransform(
  CGPoint point, CGAffineTransform t)
{
  return CGPointMake(t.a * point.x + t.c * point.y + t.tx,
                     t.b * point.x + t.d * point.y + t.ty);
}

GS_AFTR_SCOPE CGSize CGSizeApplyAffineTransform(
  CGSize size, CGAffineTransform t)
{
  CGSize r;

  r = CGSizeMake(t.a * size.width + t.c * size.height,
                 t.b * size.width + t.d * size.height);
  if (r.width < 0) r.width = -r.width;
  if (r.height < 0) r.height = -r.height;

  return r;
}

#endif /* OPAL_CGAffineTransform_h */
