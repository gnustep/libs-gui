/** <title>NSAffineTransform.m</title>

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <gnustep/gui/config.h>
#include <math.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>

#include <AppKit/config.h>
#include <AppKit/NSAffineTransform.h>
#include <AppKit/NSBezierPath.h>
#include <AppKit/PSOperators.h>

/* Private definitions */
#define A matrix.m11
#define B matrix.m12
#define C matrix.m21
#define D matrix.m22
#define TX matrix.tx
#define TY matrix.ty

/* A Postscript matrix look like this:

  /  a  b  0 \
  |  c  d  0 |
  \ tx ty  1 /

 */

static const float pi = 3.1415926535897932384626433;

@implementation NSAffineTransform

static NSAffineTransformStruct identityTransform = {
   1.0, 0.0, 0.0, 1.0, 0.0, 0.0
};

+ (NSAffineTransform*) transform
{
  NSAffineTransform	*t;

  t = (NSAffineTransform*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  t->matrix = identityTransform;
  t->rotationAngle = 0.0;
  return AUTORELEASE(t);
}

+ (id) new
{
  NSAffineTransform	*t;

  t = (NSAffineTransform*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  t->matrix = identityTransform;
  t->rotationAngle = 0.0;
  return t;
}

- (void) appendTransform: (NSAffineTransform*)aTransform
{
  float newA, newB, newC, newD, newTX, newTY;

  newA = aTransform->A * A + aTransform->B * C;
  newB = aTransform->A * B + aTransform->B * D;
  newC = aTransform->C * A + aTransform->D * C;
  newD = aTransform->C * B + aTransform->D * D;
  newTX = aTransform->TX * A + aTransform->TY * C + TX;
  newTY = aTransform->TX * B + aTransform->TY * D + TY;

  A = newA; B = newB;
  C = newC; D = newD;
  TX = newTX; TY = newTY;

  if (rotationAngle >= 0 && aTransform->rotationAngle >= 0)
    {
      rotationAngle += aTransform->rotationAngle;
      if (rotationAngle < 0)
	rotationAngle -= ((int)(rotationAngle/360)-1)*360;
      else if (rotationAngle >= 360)
	rotationAngle -= ((int)(rotationAngle/360))*360;
    }
  else
    rotationAngle = -1;
}

- (void) concat
{
  float m[6];
  m[0] = matrix.m11;
  m[1] = matrix.m12;
  m[2] = matrix.m21;
  m[3] = matrix.m22;
  m[4] = matrix.tx;
  m[5] = matrix.ty;
  PSconcat(m);
}

- (id) init
{
  matrix = identityTransform;
  rotationAngle = 0.0;
  return self;
}

- (id) initWithTransform: (NSAffineTransform*)aTransform
{
  matrix = aTransform->matrix;
  rotationAngle = aTransform->rotationAngle;
  return self;
}

- (void) invert
{
  float newA, newB, newC, newD, newTX, newTY;
  float det;

  det = A * D - B * C;
  if (det == 0)
    {
      NSLog (@"error: determinant of matrix is 0!");
      return;
    }

  newA = D / det;
  newB = -B / det;
  newC = -C / det;
  newD = A / det;
  newTX = (-D * TX + C * TY) / det;
  newTY = (B * TX - A * TY) / det;

  NSDebugLLog(@"NSAffineTransform",
	@"inverse of matrix ((%f, %f) (%f, %f) (%f, %f))\n"
	@"is ((%f, %f) (%f, %f) (%f, %f))",
	A, B, C, D, TX, TY,
	newA, newB, newC, newD, newTX, newTY);

  A = newA; B = newB;
  C = newC; D = newD;
  TX = newTX; TY = newTY;
}

- (void) prependTransform: (NSAffineTransform*)aTransform
{
  float newA, newB, newC, newD, newTX, newTY;

  newA = A * aTransform->A + B * aTransform->C;
  newB = A * aTransform->B + B * aTransform->D;
  newC = C * aTransform->A + D * aTransform->C;
  newD = C * aTransform->B + D * aTransform->D;
  newTX = TX * aTransform->A + TY * aTransform->C + aTransform->TX;
  newTY = TX * aTransform->B + TY * aTransform->D + aTransform->TY;

  A = newA; B = newB;
  C = newC; D = newD;
  TX = newTX; TY = newTY;

  if (rotationAngle >= 0 && aTransform->rotationAngle >= 0)
    {
      rotationAngle += aTransform->rotationAngle;
      if (rotationAngle < 0)
	rotationAngle -= ((int)(rotationAngle/360)-1)*360;
      else if (rotationAngle >= 360)
	rotationAngle -= ((int)(rotationAngle/360))*360;
    }
  else
    rotationAngle = -1;
}

- (void) rotateByDegrees: (float)angle
{
  float newA, newB, newC, newD;
  float angleRad = pi * angle / 180;
  float sine = sin (angleRad);
  float cosine = cos (angleRad);

  newA = A * cosine + C * sine;   newB = B * cosine + D * sine;
  newC = -A * sine + C * cosine;  newD = -B * sine + D * cosine;

  A = newA; B = newB;
  C = newC; D = newD;

  if (rotationAngle >= 0)
    {
      rotationAngle += angle;
      if (rotationAngle < 0)
	rotationAngle -= ((int)(rotationAngle/360)-1)*360;
      else if (rotationAngle >= 360)
	rotationAngle -= ((int)(rotationAngle/360))*360;
    }
  else
    rotationAngle = -1;
}

- (void) rotateByRadians: (float)angleRad
{
  float newA, newB, newC, newD;
  float angle = angleRad * 180 / pi;
  float sine = sin (angleRad);
  float cosine = cos (angleRad);

  newA = A * cosine + C * sine;   newB = B * cosine + D * sine;
  newC = -A * sine + C * cosine;  newD = -B * sine + D * cosine;

  A = newA; B = newB;
  C = newC; D = newD;

  if (rotationAngle >= 0)
    {
      rotationAngle += angle;
      if (rotationAngle < 0)
	rotationAngle -= ((int)(rotationAngle/360)-1)*360;
      else if (rotationAngle >= 360)
	rotationAngle -= ((int)(rotationAngle/360))*360;
    }
  else
    rotationAngle = -1;
}

- (void) scaleBy: (float)scale
{
  A *= scale; B *= scale;
  C *= scale; D *= scale;
}

- (void) scaleXBy: (float)scaleX yBy: (float)scaleY
{
  A *= scaleX; B *= scaleX;
  C *= scaleY; D *= scaleY;
}

- (void) set
{
  float m[6];
  m[0] = matrix.m11;
  m[1] = matrix.m12;
  m[2] = matrix.m21;
  m[3] = matrix.m22;
  m[4] = matrix.tx;
  m[5] = matrix.ty;
  GSSetCTM(GSCurrentContext(), self);
}

- (void) setTransformStruct: (NSAffineTransformStruct)val
{
  matrix = val;
  rotationAngle = -1;	// Needs recalculating
}

- (NSBezierPath*) transformBezierPath: (NSBezierPath*)aPath
{
  NSBezierPath *path = [aPath copy];

  [path transformUsingAffineTransform: self];
  return AUTORELEASE(path);
}

- (NSPoint) transformPoint: (NSPoint)aPoint
{
  NSPoint new;

  new.x = A * aPoint.x + C * aPoint.y + TX;
  new.y = B * aPoint.x + D * aPoint.y + TY;

  return new;
}

- (NSSize) transformSize: (NSSize)aSize
{
  NSSize new;

  new.width = A * aSize.width + C * aSize.height;
  if (new.width < 0)
    new.width = - new.width;
  new.height = B * aSize.width + D * aSize.height;
  if (new.height < 0)
    new.height = - new.height;

  return new;
}

- (NSAffineTransformStruct) transformStruct
{
  return matrix;
}

- (void) translateXBy: (float)tranX yBy: (float)tranY
{
  TX += tranX;
  TY += tranY;
}

- (id) copyWithZone: (NSZone*)zone
{
  return NSCopyObject(self, 0, zone);
}

- (BOOL) isEqual: (id)anObject
{
  if ([anObject class] == isa)
    {
      NSAffineTransform	*o = anObject;

      if (A == o->A && B == o->B && C == o->C
	&& D == o->D && TX == o->TX && TY == o->TY)
	return YES;
    }
  return NO;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  float replace[6];
    
  [aCoder decodeArrayOfObjCType: @encode(float)
	  count: 6
	  at: replace];
  [self setMatrix: replace];

  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  float replace[6];
    
  [self getMatrix: replace];
  [aCoder encodeArrayOfObjCType: @encode(float)
	  count: 6
	  at: replace];
}

@end /* NSAffineTransform */

@implementation NSAffineTransform (GNUstep)

+ matrixFrom: (const float[6])_matrix
{
  NSAffineTransform	*m = AUTORELEASE([self alloc]);

  [m setMatrix: _matrix];

  return m;
}

- (void) scaleBy: (float)sx :(float)sy
{
  A *= sx; B *= sx;
  C *= sy; D *= sy;
}

- (void) scaleTo: (float)sx : (float)sy
{
  float angle = rotationAngle < 0 ? [self rotationAngle] : rotationAngle;

  A = sx; B = 0;
  C = 0; D = sy;
  if (rotationAngle)
    {
      [self rotateByDegrees: angle];
      rotationAngle = angle;
    }
}

- (void) translateToPoint: (NSPoint)point
{
  float newTX, newTY;

  newTX = point.x * A + point.y * C + TX;
  newTY = point.x * B + point.y * D + TY;
  TX = newTX;
  TY = newTY;
}

- (void) rotateByAngle: (float)angle
{
  [self rotateByDegrees: angle];
}

- (void) makeIdentityMatrix
{
  matrix = identityTransform;
  rotationAngle = 0;
}

- (void) setFrameOrigin: (NSPoint)point
{
  float dx = point.x - TX;
  float dy = point.y - TY;
  [self translateToPoint: NSMakePoint(dx, dy)];
}

- (void) setFrameRotation: (float)angle
{
  float newAngle;

  if (rotationAngle < 0)
    [self rotationAngle];
  newAngle = angle - rotationAngle;
  [self rotateByAngle: newAngle];
}

- (float) rotationAngle
{
  if (rotationAngle < 0)
    {
      rotationAngle = atan2(matrix.m21, matrix.m11);
      rotationAngle *= 180.0 / pi;
    }
  return rotationAngle;
}

- (void) concatenateWith: (NSAffineTransform*)anotherMatrix
{
  [self appendTransform: anotherMatrix];
}

- (void) concatenateWithMatrix: (const float[6])anotherMatrix
{
  float newA, newB, newC, newD, newTX, newTY;

  newA = anotherMatrix[0] * A + anotherMatrix[1] * C;
  newB = anotherMatrix[0] * B + anotherMatrix[1] * D;
  newC = anotherMatrix[2] * A + anotherMatrix[3] * C;
  newD = anotherMatrix[2] * B + anotherMatrix[3] * D;
  newTX = anotherMatrix[4] * A + anotherMatrix[5] * C + TX;
  newTY = anotherMatrix[4] * B + anotherMatrix[5] * D + TY;

  A = newA; B = newB;
  C = newC; D = newD;
  TX = newTX; TY = newTY;

  rotationAngle = -1;
}

- (void)inverse
{
  [self invert];
}

- (BOOL) isRotated
{
  if (rotationAngle == 0)
    return NO;
  if (rotationAngle < 0 && [self rotationAngle] == 0)
    return NO;
  return YES;
}

- (void) boundingRectFor: (NSRect)rect result: (NSRect*)new
{
  float angle = (rotationAngle < 0) ? [self rotationAngle] : rotationAngle;
  float angleRad = pi * angle / 180;
  float angle90Rad = pi * (angle + 90) / 180;
  float cosWidth, cosHeight, sinWidth, sinHeight;
  /* Shortcuts of the usual rect values */
  float x = rect.origin.x;
  float y = rect.origin.y;
  float width = rect.size.width;
  float height = rect.size.height;

  if (rotationAngle == 0)
    {
      *new = rect;
      return;
    }

  cosWidth = cos(angleRad);
  cosHeight = cos(angle90Rad);
  sinWidth = sin(angleRad);
  sinHeight = sin(angle90Rad);

  if (angle <= 90)
    {
      new->origin.x = x + height * cosHeight;
      new->origin.y = y;
      new->size.width = width * cosWidth - height * cosHeight;
      new->size.height = width * sinWidth + height * sinHeight;
    }
  else if (angle <= 180)
    {
      new->origin.x = x + width * cosWidth + height * cosHeight;
      new->origin.y = y + height * sinHeight;
      new->size.width = -width * cosWidth - height * cosHeight;
      new->size.height = width * sinWidth - height * sinHeight;
    }
  else if (angle <= 270)
    {
      new->origin.x = x + width * cosWidth;
      new->origin.y = y + width * sinWidth + height * sinHeight;
      new->size.width = -width * cosWidth + height * cosHeight;
      new->size.height = -width * sinWidth - height * sinHeight;
    }
  else
    {
      new->origin.x = x;
      new->origin.y = y;
      new->size.width = width * cosWidth + height * cosHeight;
      new->size.height = width * sinWidth + height * sinHeight;
    }
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

- (NSString*) description
{
  return [NSString stringWithFormat:
		@"NSAffineTransform ((%f, %f) (%f, %f) (%f, %f))",
				    A, B, C, D, TX, TY];
}

- (void) setMatrix: (const float[6])replace
{
  matrix.m11 = replace[0];
  matrix.m12 = replace[1];
  matrix.m21 = replace[2];
  matrix.m22 = replace[3];
  matrix.tx = replace[4];
  matrix.ty = replace[5];
}

- (void) getMatrix: (float[6])replace
{
  replace[0] = matrix.m11;
  replace[1] = matrix.m12;
  replace[2] = matrix.m21;
  replace[3] = matrix.m22;
  replace[4] = matrix.tx;
  replace[5] = matrix.ty;
}

- (void) takeMatrixFromTransform: (NSAffineTransform *)aTransform
{
  matrix.m11 = aTransform->matrix.m11;
  matrix.m12 = aTransform->matrix.m12;
  matrix.m21 = aTransform->matrix.m21;
  matrix.m22 = aTransform->matrix.m22;
  matrix.tx = aTransform->matrix.tx;
  matrix.ty = aTransform->matrix.ty;
}


@end /* NSAffineTransform (GNUstep) */

