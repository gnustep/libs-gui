/*
   PSMatrix.h

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

#ifndef _GNUstep_H_PSMatrix
#define _GNUstep_H_PSMatrix

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

@interface PSMatrix : NSObject <NSCopying>
{
  float matrix[6];
  float rotationAngle;
}

+ matrixFrom:(float[6])matrix;
- (void)translateToPoint:(NSPoint)point;
- (void)rotateByAngle:(float)angle;
- (void)scaleBy:(float)sx :(float)sy;
- (void)scaleTo:(float)sx :(float)sy;
- (void)makeIdentityMatrix;
- (float)rotationAngle;
- (void)setFrameOrigin:(NSPoint)point;
- (void)setFrameRotation:(float)angle;
- (void)inverse;

- (BOOL)isRotated;

- (void)boundingRectFor:(NSRect)rect result:(NSRect*)result;

/* Returns anotherMatrix * self */
- (void)concatenateWith:(PSMatrix*)anotherMatrix;

- (NSPoint)pointInMatrixSpace:(NSPoint)point;
- (NSSize)sizeInMatrixSpace:(NSSize)size;
- (NSRect)rectInMatrixSpace:(NSRect)rect;

@end

@interface PSMatrix (BackendMethods)
- (void)set;
@end

/* Private definitions */
#define A matrix[0]
#define B matrix[1]
#define C matrix[2]
#define D matrix[3]
#define TX matrix[4]
#define TY matrix[5]

#endif /* _GNUstep_H_PSMatrix */
