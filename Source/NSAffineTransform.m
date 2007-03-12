/** <title>NSAffineTransform.m</title>

   <abstract>
   This class provides a way to perform affine transforms.  It provides 
   a matrix for transforming from one coordinate system to another.
   </abstract>
   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: August 1997
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: March 1999
   
   This file is part of the GNUstep GUI Library.

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
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
*/

#include "config.h"
#include <math.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>

#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/PSOperators.h"

typedef struct internal
{
  @defs(NSAffineTransform)
} *iptr;

/* Private definitions */
#define	matrix	(((iptr)self)->_matrix)
#define A matrix.m11
#define B matrix.m12
#define C matrix.m21
#define D matrix.m22
#define TX matrix.tX
#define TY matrix.tY

/* A Postscript matrix looks like this:

  /  a  b  0 \
  |  c  d  0 |
  \ tx ty  1 /

 */

static const float pi = 3.1415926535897932384626434;

/* Quick function to multiply two coordinate matrices. C = AB */
static inline NSAffineTransformStruct 
matrix_multiply (NSAffineTransformStruct MA, NSAffineTransformStruct MB)
{
  NSAffineTransformStruct MC;
  MC.m11 = MA.m11 * MB.m11 + MA.m12 * MB.m21;
  MC.m12 = MA.m11 * MB.m12 + MA.m12 * MB.m22;
  MC.m21 = MA.m21 * MB.m11 + MA.m22 * MB.m21;
  MC.m22 = MA.m21 * MB.m12 + MA.m22 * MB.m22;
  MC.tX  = MA.tX * MB.m11 + MA.tY * MB.m21 + MB.tX;
  MC.tY  = MA.tX * MB.m12 + MA.tY * MB.m22 + MB.tY;
  return MC;
}

static NSAffineTransformStruct identityTransform = {
   1.0, 0.0, 0.0, 1.0, 0.0, 0.0
};

@implementation NSAffineTransform (GUIAdditions)

/**
 * Concatenates the receiver's matrix with the one in the current graphics 
 * context.
 */
- (void) concat
{
  float m[6];
  m[0] = matrix.m11;
  m[1] = matrix.m12;
  m[2] = matrix.m21;
  m[3] = matrix.m22;
  m[4] = matrix.tX;
  m[5] = matrix.tY;
  PSconcat(m);
}


/**
 * Get the currently active graphics context's transformation 
 * matrix and set it into the receiver.
 */
- (void) set
{
  GSSetCTM(GSCurrentContext(), self);
}

/**
 * <p>Applies the receiver's transformation matrix to each point in 
 * the bezier path, then returns the result.  The original bezier 
 * path is not modified.
 * </p>
 */
- (NSBezierPath*) transformBezierPath: (NSBezierPath*)aPath
{
  NSBezierPath *path = [aPath copy];

  [path transformUsingAffineTransform: self];
  return AUTORELEASE(path);
}

@end /* NSAffineTransform (GUIAdditions) */

@implementation NSAffineTransform (GNUstep)

- (void) scaleTo: (float)sx : (float)sy
{
  /* If it's rotated.  */
  if (B != 0  ||  C != 0)
    {
      float angle = [self rotationAngle];

      A = sx; B = 0;
      C = 0; D = sy;

      [self rotateByDegrees: angle];
    }
  else
    {
      A = sx; B = 0;
      C = 0; D = sy;
    }
  // FIXME
  _isIdentity = NO;
  _isFlipY = NO;
}

- (void) translateToPoint: (NSPoint)point
{
  float newTX, newTY;

  newTX = point.x * A + point.y * C + TX;
  newTY = point.x * B + point.y * D + TY;
  TX = newTX;
  TY = newTY;
}


- (void) makeIdentityMatrix
{
  matrix = identityTransform;
  // FIXME
  _isIdentity = YES;
  _isFlipY = NO;
}

- (void) setFrameOrigin: (NSPoint)point
{
  float dx = point.x - TX;
  float dy = point.y - TY;
  [self translateToPoint: NSMakePoint(dx, dy)];
}

- (void) setFrameRotation: (float)angle
{
  [self rotateByDegrees: angle - [self rotationAngle]];
}

- (float) rotationAngle
{
  float rotationAngle = atan2(-C, A);
  rotationAngle *= 180.0 / pi;
  if (rotationAngle < 0.0)
    rotationAngle += 360.0;

  return rotationAngle;
}

- (void) concatenateWith: (NSAffineTransform*)anotherMatrix
{
  [self prependTransform: anotherMatrix];
}

- (void) concatenateWithMatrix: (const float[6])anotherMatrix
{
  NSAffineTransformStruct amat;
  amat.m11 = anotherMatrix[0];
  amat.m12 = anotherMatrix[1];
  amat.m21 = anotherMatrix[2];
  amat.m22 = anotherMatrix[3];
  amat.tX  = anotherMatrix[4];
  amat.tY  = anotherMatrix[5];
  matrix = matrix_multiply(amat, matrix);
  // FIXME
  _isIdentity = NO;
  _isFlipY = NO;
}

- (void)inverse
{
  [self invert];
}

- (BOOL) isRotated
{
  if (B == 0  &&  C == 0)
    {
      return NO;
    }
  else
    {
      return YES;
    }
}

- (void) boundingRectFor: (NSRect)rect result: (NSRect*)newRect
{
  /* Shortcuts of the usual rect values */
  float x = rect.origin.x;
  float y = rect.origin.y;
  float width = rect.size.width;
  float height = rect.size.height;
  float xc[3];
  float yc[3];
  float min_x;
  float max_x;
  float min_y;
  float max_y;
  int i;

  max_x = A * x + C * y + TX;
  max_y = B * x + D * y + TY;
  xc[0] = max_x + A * width;
  yc[0] = max_y + B * width;
  xc[1] = max_x + C * height;
  yc[1] = max_y + D * height;
  xc[2] = max_x + A * width + C * height;
  yc[2] = max_y + B * width + D * height;
  
  min_x = max_x;
  min_y = max_y;
  
  for (i = 0; i < 3; i++) 
    {
      if (xc[i] < min_x)
	min_x = xc[i];
      if (xc[i] > max_x)
	max_x = xc[i];

      if (yc[i] < min_y)
	 min_y = yc[i];
      if (yc[i] > max_y)
	max_y = yc[i];
    }

  newRect->origin.x = min_x;
  newRect->origin.y = min_y;
  newRect->size.width = max_x -min_x;
  newRect->size.height = max_y -min_y;
}

- (NSPoint) pointInMatrixSpace: (NSPoint)point
{
  NSPoint new;

  new.x = A * point.x + C * point.y + TX;
  new.y = B * point.x + D * point.y + TY;

  return new;
}

- (NSPoint) deltaPointInMatrixSpace: (NSPoint)point
{
  NSPoint new;

  new.x = A * point.x + C * point.y;
  new.y = B * point.x + D * point.y;

  return new;
}

- (NSSize) sizeInMatrixSpace: (NSSize)size
{
  NSSize new;

  new.width = A * size.width + C * size.height;
  if (new.width < 0)
    new.width = - new.width;
  new.height = B * size.width + D * size.height;
  if (new.height < 0)
    new.height = - new.height;

  return new;
}

- (NSRect) rectInMatrixSpace: (NSRect)rect
{
  NSRect new;

  new.origin.x = A * rect.origin.x + C * rect.origin.y + TX;
  new.size.width = A * rect.size.width + C * rect.size.height;
  if (new.size.width < 0)
    {
      new.origin.x += new.size.width;
      new.size.width *= -1;
    }

  new.origin.y = B * rect.origin.x + D * rect.origin.y + TY;
  new.size.height = B * rect.size.width + D * rect.size.height;
  if (new.size.height < 0)
    {
      new.origin.y += new.size.height;
      new.size.height *= -1;
    }

  return new;
}

- (void) setMatrix: (const float[6])replace
{
  matrix.m11 = replace[0];
  matrix.m12 = replace[1];
  matrix.m21 = replace[2];
  matrix.m22 = replace[3];
  matrix.tX = replace[4];
  matrix.tY = replace[5];
  // FIXME
  _isIdentity = NO;
  _isFlipY = NO;
}

- (void) getMatrix: (float[6])replace
{
  replace[0] = matrix.m11;
  replace[1] = matrix.m12;
  replace[2] = matrix.m21;
  replace[3] = matrix.m22;
  replace[4] = matrix.tX;
  replace[5] = matrix.tY;
}

- (void) takeMatrixFromTransform: (NSAffineTransform *)aTransform
{
  matrix = [aTransform transformStruct];
  // FIXME
  _isIdentity = NO;
  _isFlipY = NO;
}


@end /* NSAffineTransform (GNUstep) */

