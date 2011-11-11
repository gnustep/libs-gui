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

#ifndef OPAL_CGGeometry_h
#define OPAL_CGGeometry_h

#include <CoreGraphics/CGBase.h>

/* Data Types */

typedef struct CGPoint
{
  CGFloat x;
  CGFloat y;
} CGPoint;

typedef struct CGSize
{
  CGFloat width;
  CGFloat height;
} CGSize;

typedef struct CGRect
{
  CGPoint origin;
  CGSize size;
} CGRect;

/* Constants */

typedef enum CGRectEdge
{
  CGRectMinXEdge = 0,
  CGRectMinYEdge = 1,
  CGRectMaxXEdge = 2,
  CGRectMaxYEdge = 3
} CGRectEdge;

/** Point at 0,0 */
extern const CGPoint CGPointZero;

/** Zero size */
extern const CGSize CGSizeZero;

/** Zero-size rectangle at 0,0 */
extern const CGRect CGRectZero;

/** An invalid rectangle */
extern const CGRect CGRectNull;

/** A rectangle with infinite extent */
extern const CGRect CGRectInfinite;

/* Functions */

/* All but the most complex functions are declared static inline in this
 * header file so that they are maximally efficient.  In order to provide
 * true functions (for code modules that don't have this header) this
 * header is included in CGGeometry.c where the functions are no longer
 * declared inline.
 */
#ifdef IN_CGGEOMETRY_C
#define	OP_GEOM_SCOPE	extern
#define OP_GEOM_ATTR	
#else
#define	OP_GEOM_SCOPE	static inline
#define OP_GEOM_ATTR	__attribute__((unused))
#endif

/* Creating and modifying Geometric Forms */

/** Returns a CGPoint having x-coordinate x and y-coordinate y. */
OP_GEOM_SCOPE CGPoint CGPointMake(CGFloat x, CGFloat y) OP_GEOM_ATTR;

/** Returns a CGSize having width width and height height. */
OP_GEOM_SCOPE CGSize CGSizeMake(CGFloat width, CGFloat height) OP_GEOM_ATTR;

/** Returns a CGRect having point of origin (x, y) and size (width, height). */
OP_GEOM_SCOPE CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) OP_GEOM_ATTR;

/** Returns an equivalent rect which has positive width and heght. */
OP_GEOM_SCOPE CGRect CGRectStandardize(CGRect rect) OP_GEOM_ATTR;

/** Returns the rectangle obtained by translating rect
 * horizontally by dx and vertically by dy. */
OP_GEOM_SCOPE CGRect CGRectOffset(CGRect rect, CGFloat dx, CGFloat dy) OP_GEOM_ATTR;

/** Returns the rectangle obtained by moving each of rect's
 * horizontal sides inward by dy and each of rect's vertical
 * sides inward by dx with the center point preserved. A larger
 * rectangle can be created by using negative values. */
OP_GEOM_SCOPE CGRect CGRectInset(CGRect rect, CGFloat dx, CGFloat dy) OP_GEOM_ATTR;

/** Returns a rectangle obtained by expanding rect minimally
 * so that all four of its defining components are integers. */
CGRect CGRectIntegral(CGRect rect);

/** Returns the smallest rectangle which contains both r1 and r2
 * (modulo a set of measure zero).  If either of r1 or r2
 * is an empty rectangle, then the other rectangle is returned.
 * If both are empty, then the empty rectangle is returned. */
CGRect CGRectUnion(CGRect r1, CGRect r2);

/** Returns the largest rectangle which lies in both r1 and r2.
 * If r1 and r2 have empty intersection (or, rather, intersection
 * of measure zero, since this includes having their intersection
 * be only a point or a line), then the empty rectangle is returned. */
CGRect CGRectIntersection(CGRect r1, CGRect r2);

/** Divides rect into two rectangles (namely slice and remainder) by
 * "cutting" rect---parallel to, and a distance amount from the given edge
 * of rect. You may pass 0 in as either of slice or remainder to avoid
 * obtaining either of the created rectangles. */
void CGRectDivide(CGRect rect, CGRect *slice, CGRect *remainder,
                  CGFloat amount, CGRectEdge edge);

/* Accessing Geometric Attributes */

/** Returns the least x-coordinate value still inside rect. */
OP_GEOM_SCOPE CGFloat CGRectGetMinX(CGRect rect) OP_GEOM_ATTR;

/** Returns the x-coordinate of rect's middle point. */
OP_GEOM_SCOPE CGFloat CGRectGetMidX(CGRect rect) OP_GEOM_ATTR;

/** Returns the greatest x-coordinate value still inside rect. */
OP_GEOM_SCOPE CGFloat CGRectGetMaxX(CGRect rect) OP_GEOM_ATTR;

/** Returns the least y-coordinate value still inside rect. */
OP_GEOM_SCOPE CGFloat CGRectGetMinY(CGRect rect) OP_GEOM_ATTR;

/** Returns the y-coordinate of rect's middle point. */
OP_GEOM_SCOPE CGFloat CGRectGetMidY(CGRect rect) OP_GEOM_ATTR;

/** Returns the greatest y-coordinate value still inside rect. */
OP_GEOM_SCOPE CGFloat CGRectGetMaxY(CGRect rect) OP_GEOM_ATTR;

/** Returns rect's width. */
OP_GEOM_SCOPE CGFloat CGRectGetWidth(CGRect rect) OP_GEOM_ATTR;

/** Returns rect's height. */
OP_GEOM_SCOPE CGFloat CGRectGetHeight(CGRect rect) OP_GEOM_ATTR;

/** Returns 1 iff the rect is invalid. */
int CGRectIsNull(CGRect rect);

/** Returns 1 iff the area of rect is zero (i.e., iff either
 * of rect's width or height is zero or is an invalid rectangle). */
OP_GEOM_SCOPE int CGRectIsEmpty(CGRect rect) OP_GEOM_ATTR;

/** Returns 1 iff the rect is infinite. */
int CGRectIsInfinite(CGRect rect);

/** Returns 1 iff rect1 and rect2 are intersecting. */
OP_GEOM_SCOPE int CGRectIntersectsRect(CGRect rect1, CGRect rect2) OP_GEOM_ATTR;

/** Returns 1 iff rect1 contains rect2. */
OP_GEOM_SCOPE int CGRectContainsRect(CGRect rect1, CGRect rect2) OP_GEOM_ATTR;

/** Returns 1 iff point is inside rect. */
OP_GEOM_SCOPE int CGRectContainsPoint(CGRect rect, CGPoint point) OP_GEOM_ATTR;

/** Returns 1 iff rect1's and rect2's origin and size are the same. */
OP_GEOM_SCOPE int CGRectEqualToRect(CGRect rect1, CGRect rect2) OP_GEOM_ATTR;

/** Returns 1 iff size1's and size2's width and height are the same. */
OP_GEOM_SCOPE int CGSizeEqualToSize(CGSize size1, CGSize size2) OP_GEOM_ATTR;

/** Returns 1 iff point1's and point2's x- and y-coordinates are the same. */
OP_GEOM_SCOPE int CGPointEqualToPoint(CGPoint point1, CGPoint point2) OP_GEOM_ATTR;

CFDictionaryRef CGPointCreateDictionaryRepresentation(CGPoint point);
  
bool CGPointMakeWithDictionaryRepresentation(CFDictionaryRef dict, CGPoint *point);

CFDictionaryRef CGSizeCreateDictionaryRepresentation(CGSize size);

bool CGSizeMakeWithDictionaryRepresentation(CFDictionaryRef dict, CGSize *size);

CFDictionaryRef CGRectCreateDictionaryRepresentation(CGRect rect);

bool CGRectMakeWithDictionaryRepresentation(CFDictionaryRef dict, CGRect *rect);

/* Inlined functions */

OP_GEOM_SCOPE CGFloat CGRectGetMinX(CGRect rect)
{
  if (rect.size.width < 0)
    return rect.origin.x + rect.size.width;
  else
    return rect.origin.x;
}

OP_GEOM_SCOPE CGFloat CGRectGetMidX(CGRect rect)
{
  return rect.origin.x + (rect.size.width / 2.0);
}

OP_GEOM_SCOPE CGFloat CGRectGetMaxX(CGRect rect)
{
  if (rect.size.width < 0)
    return rect.origin.x;
  else
    return rect.origin.x + rect.size.width;
}

OP_GEOM_SCOPE CGFloat CGRectGetMinY(CGRect rect)
{
  if (rect.size.height < 0)
    return rect.origin.y + rect.size.height;
  else
    return rect.origin.y;
}

OP_GEOM_SCOPE CGFloat CGRectGetMidY(CGRect rect)
{
  return rect.origin.y + (rect.size.height / 2.0);
}

OP_GEOM_SCOPE CGFloat CGRectGetMaxY(CGRect rect)
{
  if (rect.size.height < 0)
    return rect.origin.y;
  else
    return rect.origin.y + rect.size.height;
}

OP_GEOM_SCOPE CGFloat CGRectGetWidth(CGRect rect)
{
  return rect.size.width;
}

OP_GEOM_SCOPE CGFloat CGRectGetHeight(CGRect rect)
{
  return rect.size.height;
}

OP_GEOM_SCOPE int CGRectIsEmpty(CGRect rect)
{
  if (CGRectIsNull(rect))
    return 1;
  return ((rect.size.width == 0) || (rect.size.height == 0)) ? 1 : 0;
}

OP_GEOM_SCOPE int CGRectIntersectsRect(CGRect rect1, CGRect rect2)
{
  return (CGRectIsNull(CGRectIntersection(rect1, rect2)) ? 0 : 1);
}

OP_GEOM_SCOPE int CGRectContainsRect(CGRect rect1, CGRect rect2)
{
  return CGRectEqualToRect(rect1, CGRectUnion(rect1, rect2));
}

OP_GEOM_SCOPE int CGRectContainsPoint(CGRect rect, CGPoint point)
{
  rect = CGRectStandardize(rect);
  return ((point.x >= rect.origin.x) &&
          (point.y >= rect.origin.y) &&
          (point.x <= rect.origin.x + rect.size.width) &&
          (point.y <= rect.origin.y + rect.size.height)) ? 1 : 0;
}

OP_GEOM_SCOPE int CGRectEqualToRect(CGRect rect1, CGRect rect2)
{
  /* FIXME: It is not clear from the docs if {{0,0},{1,1}} and {{1,1},{-1,-1}}
     are equal or not. (The text seem to imply that they aren't.) */
  return ((rect1.origin.x == rect2.origin.x) &&
          (rect1.origin.y == rect2.origin.y) &&
          (rect1.size.width == rect2.size.width) &&
          (rect1.size.height == rect2.size.height)) ? 1 : 0;
}

OP_GEOM_SCOPE int CGSizeEqualToSize(CGSize size1, CGSize size2)
{
  return ((size1.width == size2.width) &&
          (size1.height == size2.height)) ? 1 : 0;
}

OP_GEOM_SCOPE int CGPointEqualToPoint(CGPoint point1, CGPoint point2)
{
  return ((point1.x == point2.x) && (point1.y == point2.y)) ? 1 : 0;
}

OP_GEOM_SCOPE CGPoint CGPointMake(CGFloat x, CGFloat y)
{
  CGPoint point;

  point.x = x;
  point.y = y;
  return point;
}

OP_GEOM_SCOPE CGSize CGSizeMake(CGFloat width, CGFloat height)
{
  CGSize size;

  size.width = width;
  size.height = height;
  return size;
}

OP_GEOM_SCOPE CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height)
{
  CGRect rect;

  rect.origin.x = x;
  rect.origin.y = y;
  rect.size.width = width;
  rect.size.height = height;
  return rect;
}

OP_GEOM_SCOPE CGRect CGRectStandardize(CGRect rect)
{
  if (rect.size.width < 0) {
    rect.origin.x += rect.size.width;
    rect.size.width = -rect.size.width;
  }
  if (rect.size.height < 0) {
    rect.origin.y += rect.size.height;
    rect.size.height = -rect.size.height;
  }
  return rect;
}

OP_GEOM_SCOPE CGRect CGRectOffset(CGRect rect, CGFloat dx, CGFloat dy)
{
  rect.origin.x += dx;
  rect.origin.y += dy;
  return rect;
}

OP_GEOM_SCOPE CGRect CGRectInset(CGRect rect, CGFloat dx, CGFloat dy)
{
  rect = CGRectStandardize(rect);
  rect.origin.x += dx;
  rect.origin.y += dy;
  rect.size.width -= (2 * dx);
  rect.size.height -= (2 * dy);
  return rect;
}

#endif /* OPAL_CGGeometry_h */
