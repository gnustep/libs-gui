/** <title>CGPath</title>

 <abstract>C Interface to graphics drawing library</abstract>

 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: August 2010

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
#include "CoreGraphics/CGPath.h"



typedef struct
{
  CGPathElementType type;
  CGPoint points[3];
} OPPathElement;

@interface CGPath : NSObject
{
  NSUInteger _count;
  OPPathElement *_elementsArray;
}
- (id) initWithCGPath: (CGPathRef)path;
- (NSUInteger) count;
- (CGPathElementType) elementTypeAtIndex: (NSUInteger)index points: (CGPoint*)outPoints;
- (void) addElementWithType: (CGPathElementType)type points: (CGPoint[])points;
- (BOOL) isEqual:(id)otherObj;
- (BOOL) isRect: (CGRect*)outRect;

@end

@interface CGMutablePath : CGPath
{
  NSUInteger _capacity;
}

- (void) addElementWithType: (CGPathElementType)type points: (CGPoint[])points;

@end


/*
 * Functions and definitions for approximating arcs through bezier curves.
 */

#define OPPathArcDefaultTolerance 0.1

/**
 * Calculates the number of segments needed to approximate an arc with the given
 * <var>radius</var> after applying the affine transform from <var>m</var>.
 * FIXME: Uses fixed tolerance to compute the number of segments needed.
 */
NSUInteger
_OPPathRequiredArcSegments(CGFloat angle,
  CGFloat radius,
  const CGAffineTransform *m);

