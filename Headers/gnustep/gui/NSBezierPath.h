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

#ifndef BEZIERPATH_H
#define BEZIERPATH_H

#include <Foundation/Foundation.h>
#include <AppKit/NSFont.h>

@class NSAffineTransform;
@class NSImage;

typedef enum {
  NSButtLineCapStyle = 0,
  NSRoundLineCapStyle = 1,
  NSSquareLineCapStyle = 2
} NSLineCapStyle;

typedef enum {
  NSMiterLineJoinStyle = 0,
  NSRoundLineJoinStyle = 1,
  NSBevelLineJoinStyle = 2
} NSLineJoinStyle;

typedef enum {
  NSNonZeroWindingRule,
  NSEvenOddWindingRule
} NSWindingRule;

typedef enum {
  NSMoveToBezierPathElement,
  NSLineToBezierPathElement,
  NSCurveToBezierPathElement,
  NSClosePathBezierPathElement
} NSBezierPathElement;

@interface NSBezierPath : NSObject <NSCopying, NSCoding>
{
@private
  NSWindingRule _windingRule;
  NSLineCapStyle _lineCapStyle;
  NSLineJoinStyle _lineJoinStyle;
  float _lineWidth;
  float _flatness;
  float _miterLimit;
  int _dash_count;
  float _dash_phase;
  float *_dash_pattern;
  BOOL _shouldRecalculateBounds;
  NSRect _bounds;
  NSRect _controlPointBounds;
  BOOL _cachesBezierPath;
  NSImage *_cacheImage;
}

//
// Creating common paths
//
+ (NSBezierPath *)bezierPath;
+ (NSBezierPath *)bezierPathWithRect:(NSRect)aRect;
+ (NSBezierPath *)bezierPathWithOvalInRect:(NSRect)aRect;

//
// Immediate mode drawing of common paths
//
+ (void)fillRect:(NSRect)aRect;
+ (void)strokeRect:(NSRect)aRect;
+ (void)clipRect:(NSRect)aRect;
+ (void)strokeLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2;
+ (void)drawPackedGlyphs: (const char *)packedGlyphs atPoint: (NSPoint)aPoint;

//
// Default path rendering parameters
//
+ (void)setDefaultMiterLimit:(float)limit;
+ (float)defaultMiterLimit;
+ (void)setDefaultFlatness:(float)flatness;
+ (float)defaultFlatness;
+ (void)setDefaultWindingRule:(NSWindingRule)windingRule;
+ (NSWindingRule)defaultWindingRule;
+ (void)setDefaultLineCapStyle:(NSLineCapStyle)lineCapStyle;
+ (NSLineCapStyle)defaultLineCapStyle;
+ (void)setDefaultLineJoinStyle:(NSLineJoinStyle)lineJoinStyle;
+ (NSLineJoinStyle)defaultLineJoinStyle;
+ (void)setDefaultLineWidth:(float)lineWidth;
+ (float)defaultLineWidth;

//
// Path construction
//
- (void)moveToPoint:(NSPoint)aPoint;
- (void)lineToPoint:(NSPoint)aPoint;
- (void)curveToPoint:(NSPoint)aPoint 
       controlPoint1:(NSPoint)controlPoint1
       controlPoint2:(NSPoint)controlPoint2;
- (void)closePath;
- (void)removeAllPoints;

//
// Relative path construction
//
- (void)relativeMoveToPoint:(NSPoint)aPoint;
- (void)relativeLineToPoint:(NSPoint)aPoint;
- (void)relativeCurveToPoint:(NSPoint)aPoint
	       controlPoint1:(NSPoint)controlPoint1
	       controlPoint2:(NSPoint)controlPoint2;

//
// Path rendering parameters
//
- (float)lineWidth;
- (void)setLineWidth:(float)lineWidth;
- (NSLineCapStyle)lineCapStyle;
- (void)setLineCapStyle:(NSLineCapStyle)lineCapStyle;
- (NSLineJoinStyle)lineJoinStyle;
- (void)setLineJoinStyle:(NSLineJoinStyle)lineJoinStyle;
- (NSWindingRule)windingRule;
- (void)setWindingRule:(NSWindingRule)windingRule;
- (void)setFlatness:(float)flatness;
- (float)flatness;
- (void)setMiterLimit:(float)limit;
- (float)miterLimit;
- (void)getLineDash:(float *)pattern count:(int *)count phase:(float *)phase;
- (void)setLineDash:(const float *)pattern count:(int)count phase:(float)phase;

//
// Path operations
//
- (void)stroke;
- (void)fill;
- (void)addClip;
- (void)setClip;

//
// Path modifications.
//
- (NSBezierPath *)bezierPathByFlatteningPath;
- (NSBezierPath *)bezierPathByReversingPath;

//
// Applying transformations.
//
- (void)transformUsingAffineTransform:(NSAffineTransform *)transform;

//
// Path info
//
- (BOOL)isEmpty;
- (NSPoint)currentPoint;
- (NSRect)controlPointBounds;
- (NSRect)bounds;

//
// Elements
//
- (int)elementCount;
- (NSBezierPathElement)elementAtIndex:(int)index
		     associatedPoints:(NSPoint *)points;
- (NSBezierPathElement)elementAtIndex:(int)index;
- (void)setAssociatedPoints:(NSPoint *)points atIndex:(int)index;

//
// Appending common paths
//
- (void)appendBezierPath:(NSBezierPath *)aPath;
- (void)appendBezierPathWithRect:(NSRect)aRect;
- (void)appendBezierPathWithPoints:(NSPoint *)points count:(int)count;
- (void)appendBezierPathWithOvalInRect:(NSRect)aRect;
- (void)appendBezierPathWithArcWithCenter:(NSPoint)center  
				   radius:(float)radius
			       startAngle:(float)startAngle
				 endAngle:(float)endAngle
				clockwise:(BOOL)clockwise;
- (void)appendBezierPathWithArcWithCenter:(NSPoint)center  
				   radius:(float)radius
			       startAngle:(float)startAngle
				 endAngle:(float)endAngle;
- (void)appendBezierPathWithArcFromPoint:(NSPoint)point1
				 toPoint:(NSPoint)point2
				  radius:(float)radius;
- (void)appendBezierPathWithGlyph:(NSGlyph)glyph inFont:(NSFont *)font;
- (void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
			     count:(int)count
			    inFont:(NSFont *)font;
- (void)appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs;

//
// Hit detection  
// 
- (BOOL)containsPoint:(NSPoint)point;

//
// Caching
// 
- (BOOL)cachesBezierPath;
- (void)setCachesBezierPath:(BOOL)flag;

@end

#endif // BEZIERPATH_H
