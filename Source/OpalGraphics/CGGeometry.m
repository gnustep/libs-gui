/** <title>CGGeometry</title>

   <abstract>C Interface to graphics drawing library
             - geometry routines</abstract>

   Copyright (C) 1995,2002 Free Software Foundation, Inc.
   Author: Adam Fedor <fedor@gnu.org>
   Author: BALATON Zoltan <balaton@eik.bme.hu>

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

/* Define IN_CGGEOMETRY_C so that the header can provide non-inline
 * versions of the function implementations for us.
 */
#define IN_CGGEOMETRY_C
#include "CoreGraphics/CGGeometry.h"
#undef IN_CGGEOMETRY_C
#define _ISOC99_SOURCE
#include <math.h>

/* Constants */
const CGPoint CGPointZero = {0,0};

const CGSize CGSizeZero = {0,0};

const CGRect CGRectZero = {{0,0},{0,0}};

const CGRect CGRectNull = {{NAN,NAN},{NAN,NAN}};

const CGRect CGRectInfinite = {{INFINITY,INFINITY},{INFINITY,INFINITY}};

/* Functions */

int CGRectIsNull(CGRect rect)
{
  return (isnan(rect.origin.x) || isnan(rect.origin.y) ||
          isnan(rect.size.width) || isnan(rect.size.height)) ? 1 : 0;
}

int CGRectIsInfinite(CGRect rect)
{
  return (isinf(rect.origin.x) || isinf(rect.origin.y) ||
          isinf(rect.size.width) || isinf(rect.size.height)) ? 1 : 0;
}

CGRect CGRectIntegral(CGRect rect)
{
  rect = CGRectStandardize(rect);
  /* The order of the following is relevant: we change values we already used */
  rect.size.width = ceil(rect.origin.x + rect.size.width);
  rect.size.height = ceil(rect.origin.y + rect.size.height);
  rect.origin.x = floor(rect.origin.x);
  rect.origin.y = floor(rect.origin.y);
  rect.size.width -= rect.origin.x;
  rect.size.height -= rect.origin.y;
  return rect;
}

CGRect CGRectIntersection(CGRect r1, CGRect r2)
{
  CGRect rect;

  /* If both of them are empty we can return r2 as an empty rect,
     so this covers all cases: */
  if (CGRectIsEmpty(r1))
    return r2;
  else if (CGRectIsEmpty(r2))
    return r1;

  r1 = CGRectStandardize(r1);
  r2 = CGRectStandardize(r2);

  if (r1.origin.x + r1.size.width <= r2.origin.x ||
      r2.origin.x + r2.size.width <= r1.origin.x ||
      r1.origin.y + r1.size.height <= r2.origin.y ||
      r2.origin.y + r2.size.height <= r1.origin.y) 
    return CGRectNull;

  rect.origin.x = (r1.origin.x > r2.origin.x ? r1.origin.x : r2.origin.x);
  rect.origin.y = (r1.origin.y > r2.origin.y ? r1.origin.y : r2.origin.y);

  if (r1.origin.x + r1.size.width < r2.origin.x + r2.size.width)
    rect.size.width = r1.origin.x + r1.size.width - rect.origin.x;
  else
    rect.size.width = r2.origin.x + r2.size.width - rect.origin.x;

  if (r1.origin.y + r1.size.height < r2.origin.y + r2.size.height)
    rect.size.height = r1.origin.y + r1.size.height - rect.origin.y;
  else
    rect.size.height = r2.origin.y + r2.size.height - rect.origin.y;

  return rect;
}

void CGRectDivide(CGRect rect, CGRect *slice, CGRect *remainder,
                  CGFloat amount, CGRectEdge edge)
{
  static CGRect srect;
  static CGRect rrect;

  if (!slice)
    slice = &srect;
  if (!remainder)
    remainder = &rrect;
  if (amount < 0)
    amount = 0;

  rect = CGRectStandardize(rect);
  *slice = rect;
  *remainder = rect;
  switch (edge) {
    case CGRectMinXEdge:
      remainder->origin.x += amount;
      if (amount < rect.size.width) {
        slice->size.width = amount;
        remainder->size.width -= amount;
      } else {
        remainder->size.width = 0;
      }
      break;
    case CGRectMinYEdge:
      remainder->origin.y += amount;
      if (amount < rect.size.height) {
        slice->size.height = amount;
        remainder->size.height -= amount;
      } else {
        remainder->size.height = 0;
      }
      break;
    case CGRectMaxXEdge:
      if (amount < rect.size.width) {
        slice->origin.x += rect.size.width - amount;
        slice->size.width = amount;
        remainder->size.width -= amount;
      } else {
        remainder->size.width = 0;
      }        
      break;
    case CGRectMaxYEdge:
      if (amount < rect.size.height) {
        slice->origin.y += rect.size.height - amount;
        slice->size.height = amount;
        remainder->size.height -= amount;
      } else {
        remainder->size.height = 0;
      }        
      break;
    default:
      break;
  }
}

CGRect CGRectUnion(CGRect r1, CGRect r2)
{
  CGRect rect;

  /* If both of them are empty we can return r2 as an empty rect,
     so this covers all cases: */
  if (CGRectIsEmpty(r1))
    return r2;
  else if (CGRectIsEmpty(r2))
    return r1;

  r1 = CGRectStandardize(r1);
  r2 = CGRectStandardize(r2);
  rect.origin.x = MIN(r1.origin.x, r2.origin.x);
  rect.origin.y = MIN(r1.origin.y, r2.origin.y);
  rect.size.width = MAX(r1.origin.x + r1.size.width, r2.origin.x + r2.size.width);
  rect.size.height = MAX(r1.origin.y + r1.size.height, r2.origin.y + r2.size.height);
  return rect;
}

CFDictionaryRef CGPointCreateDictionaryRepresentation(CGPoint point)
{
  // FIXME: implement
  return nil;
}  

bool CGPointMakeWithDictionaryRepresentation(CFDictionaryRef dict, CGPoint *point)
{
  // FIXME: implement
  return false;
}

CFDictionaryRef CGSizeCreateDictionaryRepresentation(CGSize size)
{
  // FIXME: implement
  return nil;
}

bool CGSizeMakeWithDictionaryRepresentation(CFDictionaryRef dict, CGSize *size)
{
  // FIXME: implement
  return false;
}

CFDictionaryRef CGRectCreateDictionaryRepresentation(CGRect rect)
{
  // FIXME: implement
  return nil;
}

bool CGRectMakeWithDictionaryRepresentation(CFDictionaryRef dict, CGRect *rect)
{
  // FIXME: implement
  return false;
}