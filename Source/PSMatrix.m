/*
   PSMatrix.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: August 1997
   
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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <gnustep/gui/config.h>
#include <math.h>

#include <Foundation/NSString.h>

#include <AppKit/config.h>
#include <AppKit/PSMatrix.h>

/* A Postscript matrix look like this:

  /  a  b  0 \
  |  c  d  0 |
  \ tx ty  1 /

 */

static const float pi = 3.1415926535897932384626433;

@implementation PSMatrix

+ matrixFrom: (const float[6])_matrix
{
  PSMatrix* m = [[self alloc] autorelease];

  memcpy (m->matrix, _matrix, sizeof (m->matrix));

  return m;
}

- init
{
  [self makeIdentityMatrix];
  rotationAngle = 0;
  return self;
}

- (id)copyWithZone:(NSZone*)zone
{
  PSMatrix* new = [isa alloc];

  memcpy (new->matrix, matrix, sizeof(matrix));
  new->rotationAngle = rotationAngle;
  return new;
}

- (void)scaleBy:(float)sx :(float)sy
{
  A *= sx; B *= sx;
  C *= sy; D *= sy;
}

- (void)scaleTo:(float)sx :(float)sy
{
  float angle = rotationAngle;

  A = sx; B = 0;
  C = 0; D = sy;
  if (rotationAngle) {
    [self rotateByAngle:angle];
    rotationAngle = angle;
  }
}
- (void)translateToPoint:(NSPoint)point
{
  float newTX, newTY;

  newTX = point.x * A + point.y * C + TX;
  newTY = point.x * B + point.y * D + TY;
  TX = newTX;
  TY = newTY;
}

- (void)rotateByAngle:(float)angle
{
  float newA, newB, newC, newD;
  float angleRad = pi * angle / 180;
  float sine = sin (angleRad);
  float cosine = cos (angleRad);

  newA = A * cosine + C * sine;   newB = B * cosine + D * sine;
  newC = -A * sine + C * cosine;  newD = -B * sine + D * cosine;

  A = newA; B = newB;
  C = newC; D = newD;

  rotationAngle += angle;
}

- (void)makeIdentityMatrix
{
   A = 1;  B = 0;
   C = 0;  D = 1;
  TX = 0; TY = 0;
  rotationAngle = 0;
}

- (void)setFrameOrigin:(NSPoint)point
{
  float dx = point.x - TX;
  float dy = point.y - TY;
  [self translateToPoint:NSMakePoint (dx, dy)];
}

- (void)setFrameRotation:(float)angle
{
  float newAngle = angle - rotationAngle;
  [self rotateByAngle:newAngle];
}

- (float)rotationAngle
{
  return rotationAngle;
}

- (void)concatenateWith:(PSMatrix*)other
{
  float newA, newB, newC, newD, newTX, newTY;

  newA = other->A * A + other->B * C;
  newB = other->A * B + other->B * D;
  newC = other->C * A + other->D * C;
  newD = other->C * B + other->D * D;
  newTX = other->TX * A + other->TY * C + TX;
  newTY = other->TX * B + other->TY * D + TY;

  A = newA; B = newB;
  C = newC; D = newD;
  TX = newTX; TY = newTY;

  rotationAngle += other->rotationAngle;
}

- (void)inverse
{
  float newA, newB, newC, newD, newTX, newTY;
  float det;

  det = A * D - B * C;
  if (!det) {
    NSLog (@"error: determinant of matrix is 0!");
    return;
  }

  newA = D / det;
  newB = -B / det;
  newC = -C / det;
  newD = A / det;
  newTX = (-D * TX + C * TY) / det;
  newTY = (B * TX - A * TY) / det;

  NSDebugLog (@"inverse of matrix ((%f, %f) (%f, %f) (%f, %f))\n"
	@"is ((%f, %f) (%f, %f) (%f, %f))",
	A, B, C, D, TX, TY,
	newA, newB, newC, newD, newTX, newTY);

  A = newA; B = newB;
  C = newC; D = newD;
  TX = newTX; TY = newTY;
}

- (BOOL)isRotated
{
  return rotationAngle != 0;
}

- (void)boundingRectFor:(NSRect)rect result:(NSRect*)new
{
  float angle = rotationAngle
		- ((int)(rotationAngle / 360)) * rotationAngle;
  float angleRad = pi * angle / 180;
  float angle90Rad = pi * (angle + 90) / 180;
  float cosWidth, cosHeight, sinWidth, sinHeight;
  /* Shortcuts of the usual rect values */
  float x = rect.origin.x;
  float y = rect.origin.y;
  float width = rect.size.width;
  float height = rect.size.height;

  if (rotationAngle == 0) {
    *new = NSZeroRect;
    return;
  }

  cosWidth = cos(angleRad);
  cosHeight = cos(angle90Rad);
  sinWidth = sin(angleRad);
  sinHeight = sin(angle90Rad);

  if (angle <= 90) {
    new->origin.x = x + height * cosHeight;
    new->origin.y = y;
    new->size.width = width * cosWidth - height * cosHeight;
    new->size.height = width * sinWidth + height * sinHeight;
  }
  else if (angle <= 180) {
    new->origin.x = x + width * cosWidth + height * cosHeight;
    new->origin.y = y + height * sinHeight;
    new->size.width = -width * cosWidth - height * cosHeight;
    new->size.height = width * sinWidth - height * sinHeight;
  }
  else if (angle <= 270) {
    new->origin.x = x + width * cosWidth;
    new->origin.y = y + width * sinWidth + height * sinHeight;
    new->size.width = -width * cosWidth + height * cosHeight;
    new->size.height = -width * sinWidth - height * sinHeight;
  }
  else {
    new->origin.x = x;
    new->origin.y = y;
    new->size.width = width * cosWidth + height * cosHeight;
    new->size.height = width * sinWidth + height * sinHeight;
  }
}

- (NSPoint)pointInMatrixSpace:(NSPoint)point
{
  NSPoint new;

  new.x = A * point.x + C * point.y + TX;
  new.y = B * point.x + D * point.y + TY;

  return new;
}

- (NSSize)sizeInMatrixSpace:(NSSize)size
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

- (NSRect)rectInMatrixSpace:(NSRect)rect
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

- (NSString*)description
{
  return [NSString stringWithFormat:@"PSMatrix ((%f, %f) (%f, %f) (%f, %f))",
				    A, B, C, D, TX, TY];
}

- (void) setMatrix: (const float[6])replace
{
 memcpy (matrix, replace, sizeof (matrix));
 rotationAngle = atan2(replace[2], replace[0]);
 rotationAngle *= 180.0 / M_PI;

}

- (void) getMatrix: (float[6])replace
{
 memcpy (replace, matrix, sizeof (matrix));
}

@end /* PSMatrix */

