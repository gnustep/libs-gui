/* 
   The NSBezierPath class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Enrico Sersale <enrico@imago.ro>
   Date: Dec 1999
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111 - 1307, USA.
*/

#ifndef NSBEZIERPATH_H
#define NSBEZIERPATH_H

#include <Foundation/NSArray.h>
#include <AppKit/NSFont.h>

#define PMAX 10000

typedef enum { 
	NSBezierPathElementMoveTo,
	NSBezierPathElementLineTo,
	NSBezierPathElementCurveTo,
	NSBezierPathElementClose
} NSBezierPathElementType;

typedef enum { 
	NSWindingRuleNonZero,
	NSWindingRuleEvenOdd
} NSWindingRule;

@interface NSBezierPath : NSObject
{
	NSMutableArray *pathElements;
	NSMutableArray *subPaths;
	NSPoint draftPolygon[PMAX];
	int pcount;
	NSPoint currentPoint;
	NSWindingRule windingRule;
	BOOL cachesBezierPath;
}

+ (NSBezierPath *)bezierPath;

+ (NSBezierPath *)bezierPathWithRect:(NSRect)aRect;

//
// Contructing paths 
//
- (void)moveToPoint:(NSPoint)aPoint;

- (void)lineToPoint:(NSPoint)aPoint;

- (void)curveToPoint:(NSPoint)aPoint 
		 controlPoint1:(NSPoint)controlPoint1
		 controlPoint2:(NSPoint)controlPoint2;
		 
- (void)closePath;

- (void)reset;

- (void)relativeMoveToPoint:(NSPoint)aPoint;

- (void)relativeLineToPoint:(NSPoint)aPoint;

- (void)relativeCurveToPoint:(NSPoint)aPoint
					controlPoint1:(NSPoint)controlPoint1
					controlPoint2:(NSPoint)controlPoint2;

//
// Appending paths and some common shapes 
//
- (void)appendBezierPath:(NSBezierPath *)aPath;

- (void)appendBezierPathWithPoints:(NSPoint *)points count:(int)count;

- (void)appendBezierPathWithOvalInRect:(NSRect)aRect;

- (void)appendBezierPathWithArcWithCenter:(NSPoint)center 
											  radius:(float)radius 
										 startAngle:(float)startAngle
											endAngle:(float)endAngle;
											
- (void)appendBezierPathWithGlyph:(NSGlyph)aGlyph inFont:(NSFont *)fontObj;

- (void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
									  count:(int)count
									 inFont:(NSFont *)fontObj;

- (void)appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs;

//
// Setting attributes 
//
- (void)setWindingRule:(NSWindingRule)aWindingRule;

- (NSWindingRule)windingRule;

+ (void)setLineCapStyle:(int)style;

+ (void)setLineJoinStyle:(int)style;

+ (void)setLineWidth:(float)width; 

+ (void)setMiterLimit:(float)limit;

+ (void)setFlatness:(float)flatness;

+ (void)setHalftonePhase:(float)x : (float)y;

//
// Drawing paths
// 
- (void)stroke;

- (void)fill;

+ (void)fillRect:(NSRect)aRect;

+ (void)strokeRect:(NSRect)aRect;

+ (void)strokeLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2;

+ (void)drawPackedGlyphs:(const char *)packedGlyphs atPoint:(NSPoint)aPoint;

//
// Clipping paths 
// 
- (void)addClip;

- (void)setClip;

+ (void)clipRect:(NSRect)aRect;

//
// Hit detection  
// 
- (BOOL)isHitByPoint:(NSPoint)aPoint;

- (BOOL)isHitByRect:(NSRect)aRect;

- (BOOL)isHitByPath:(NSBezierPath *)aBezierPath;

- (BOOL)isStrokeHitByPoint:(NSPoint)aPoint;

- (BOOL)isStrokeHitByRect:(NSRect)aRect;

- (BOOL)isStrokeHitByPath:(NSBezierPath *)aBezierPath;

//
// Querying paths
// 
- (NSRect)bounds;

- (NSRect)controlPointBounds;

- (NSPoint)currentPoint;

//
// Accessing elements of a path 
// 
- (int)elementCount;

- (NSBezierPathElementType)elementTypeAtIndex:(int)index;

- (NSBezierPathElementType)elementTypeAtIndex:(int)index
									  associatedPoints:(NSPoint *)points;

- (void)removeLastElement;

- (int)pointCount;

- (NSPoint)pointAtIndex:(int)index;

- (void)setPointAtIndex:(int)index toPoint:(NSPoint)aPoint;

- (int)pointIndexForPathElementIndex:(int)index;

- (int)pathElementIndexForPointIndex:(int)index;

//
// Caching paths 
// 
- (BOOL)cachesBezierPath;

- (void)setCachesBezierPath:(BOOL)flag;

@end

#endif // NSBEZIERPATH_H
