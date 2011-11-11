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

#define IN_CGAFFINETRANSFORM_C
#include "CoreGraphics/CGAffineTransform.h"
#undef IN_CGAFFINETRANSFORM_C

#import <Foundation/Foundation.h>
#include <math.h>

const CGAffineTransform CGAffineTransformIdentity = {1,0,0,1,0,0};

CGAffineTransform CGAffineTransformMakeRotation(CGFloat angle)
{
  CGAffineTransform matrix;
  CGFloat cosa = cos(angle);
  CGFloat sina = sin(angle);

  matrix.a = matrix.d = cosa;
  matrix.b = sina;
  matrix.c = -sina;
  matrix.tx = matrix.ty = 0;

  return matrix;
}

CGAffineTransform CGAffineTransformInvert(CGAffineTransform t)
{
  CGAffineTransform inv;
  CGFloat det;

  det = t.a * t.d - t.b *t.c;
  if (det == 0) {
    NSLog(@"Cannot invert matrix, determinant is 0");
    return t;
  }

  inv.a = t.d / det;
  inv.b = -t.b / det;
  inv.c = -t.c / det;
  inv.d = t.a / det;
  inv.tx = (t.c * t.ty - t.d * t.tx) / det;
  inv.ty = (t.b * t.tx - t.a * t.ty) / det;

  return inv;
}

/**
 * Returns the smallest rectangle which contains the four supplied points.
 */
static CGRect make_bounding_rect(CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4)
{
  CGFloat minX = MIN(p1.x, MIN(p2.x, MIN(p3.x, p4.x)));
  CGFloat minY = MIN(p1.y, MIN(p2.y, MIN(p3.y, p4.y)));
  CGFloat maxX = MAX(p1.x, MAX(p2.x, MAX(p3.x, p4.x)));
  CGFloat maxY = MAX(p1.y, MAX(p2.y, MAX(p3.y, p4.y)));
  
  return CGRectMake(minX, minY, (maxX - minX), (maxY - minY));
}

CGRect CGRectApplyAffineTransform(CGRect rect, CGAffineTransform t)
{

  CGPoint p1 = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
  CGPoint p2 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
  CGPoint p3 = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
  CGPoint p4 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
  
  p1 = CGPointApplyAffineTransform(p1, t);
  p2 = CGPointApplyAffineTransform(p2, t);
  p3 = CGPointApplyAffineTransform(p3, t);
  p4 = CGPointApplyAffineTransform(p4, t);
  
  return make_bounding_rect(p1, p2, p3, p4);
}
