/* 
   NSBezierPath.m

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

#include <gnustep/gui/config.h>
#include <AppKit/AppKit.h>
#include <math.h>

#ifndef PI
#define PI 3.1415926535897932384626433
#endif

typedef struct {
	NSPoint p1;
	NSPoint p2;
} Line;

typedef struct {
	NSPoint p;
	double t;
} pointOnCurve;

typedef enum { 
	INTERIOR, 
	EXTERIOR,
	VERTEX,
	ONBORDER
} pointPosition;

pointPosition inPath(NSBezierPath *aPath, NSPoint p);
BOOL onPathBorder(NSBezierPath *aPath, NSPoint p);
int ccw(NSPoint p0, NSPoint p1, NSPoint p2);
BOOL intersect(Line line1, Line line2);
BOOL intersectRect(NSRect rect, Line line);
void subdiv(int degree, float coeff[], float t, float bleft[], float bright[]);
NSPoint rotatePoint(NSPoint p, NSPoint centre, float angle);

@interface PathElement : NSObject
{
	NSPoint p[3];
	NSBezierPathElementType type;
}

+ (PathElement *)pathElement;
- (void)setType:(NSBezierPathElementType)t;
- (void)setPointAtIndex:(int)index toPoint:(NSPoint)aPoint;
- (NSBezierPathElementType)type;
- (NSPoint *)points;

@end

@implementation PathElement

+ (PathElement *)pathElement
{
  	return AUTORELEASE([[self alloc] init]);
}

- (void)setType:(NSBezierPathElementType)t
{
	type = t;
}

- (void)setPointAtIndex:(int)index toPoint:(NSPoint)aPoint
{
	p[index].x = aPoint.x;
	p[index].y = aPoint.y;
}

- (NSBezierPathElementType)type
{
	return type;
}

- (NSPoint *)points
{
	return p;
}

@end

@interface NSBezierPath (PrivateMethods)

- (void)setCurrentPoint:(NSPoint)aPoint;
- (BOOL)isPathElement:(PathElement *)elm1 onPathElement:(PathElement *)elm2;
- (NSMutableArray *)pathElements;
- (PathElement *)moveToElement;
- (PathElement *)lastElement;
- (int)indexOfElement:(PathElement *)element;
- (PathElement *)elementPrecedingElement:(PathElement *)element;
- (void)calculateDraftPolygon;
- (NSPoint *)draftPolygon;
- (int)pcount;
- (NSBezierPath *)pathWithOvalInRect:(NSRect)aRect;
- (void)movePathToPoint:(NSPoint)p;
- (void)rotateByAngle:(float)angle center:(NSPoint)center;
- (pointOnCurve)pointOnPathSegmentOfElement:(PathElement *)elm
									  nearestToPoint:(NSPoint)p;
- (PathElement *)pathElementSubdividingPathAtPoint:(NSPoint)p 
											 pathSegmentOwner:(PathElement *)owner;

@end


@implementation NSBezierPath

+ (NSBezierPath *)bezierPath
{
  	return AUTORELEASE([[self alloc] init]);
}

+ (NSBezierPath *)bezierPathWithRect:(NSRect)aRect
{
	NSBezierPath *path;
	NSPoint p;
	
	path = [NSBezierPath bezierPath];
	[path moveToPoint: aRect.origin];
	p.x = aRect.origin.x + aRect.size.width;
	p.y = aRect.origin.y;
	[path lineToPoint: p];
	p.x = aRect.origin.x + aRect.size.width;
	p.y = aRect.origin.y + aRect.size.height;
	[path lineToPoint: p];
	p.x = aRect.origin.x;
	p.y = aRect.origin.y + aRect.size.height;
	[path lineToPoint: p];
	[path closePath];
	
	return path;
}

- (id)init
{
	self = [super init];
	if(self) {
		pathElements = [[NSMutableArray alloc] initWithCapacity: 1];
		subPaths = [[NSMutableArray alloc] initWithCapacity: 1];
		windingRule = NSWindingRuleNonZero;
	}
	return self;
}

- (void)dealloc
{
	[pathElements release];
	[subPaths release];
	[super dealloc];
}

//
// Contructing paths 
//
- (void)moveToPoint:(NSPoint)aPoint
{
	PathElement *elm = [PathElement pathElement];
	[elm setType: NSBezierPathElementMoveTo];
	[elm setPointAtIndex: 0 toPoint: aPoint];
	[pathElements addObject: elm];
	[self setCurrentPoint: aPoint];
	[self calculateDraftPolygon];
}

- (void)lineToPoint:(NSPoint)aPoint
{
	PathElement *elm = [PathElement pathElement];
	[elm setType: NSBezierPathElementLineTo];
	[elm setPointAtIndex: 0 toPoint: aPoint];
	[pathElements addObject: elm];
	[self setCurrentPoint: aPoint];
	[self calculateDraftPolygon];
}

- (void)curveToPoint:(NSPoint)aPoint 
		 controlPoint1:(NSPoint)controlPoint1
		 controlPoint2:(NSPoint)controlPoint2
{
	PathElement *elm = [PathElement pathElement];
	[elm setType: NSBezierPathElementCurveTo];
	[elm setPointAtIndex: 0 toPoint: controlPoint1];
	[elm setPointAtIndex: 1 toPoint: controlPoint2];
	[elm setPointAtIndex: 2 toPoint: aPoint];
	[pathElements addObject: elm];
	[self setCurrentPoint: aPoint];
	[self calculateDraftPolygon];
}

- (void)closePath
{
	PathElement *elm, *elm1, *elm2;
	NSPoint p;

	elm1 = [self moveToElement];
	elm2 = [self lastElement];
	if(![self isPathElement: elm2 onPathElement: elm1]) {
		p = [elm1 points][0];
		[self lineToPoint: p];
	}
	elm = [PathElement pathElement];
	[elm setType: NSBezierPathElementClose];
	[pathElements addObject: elm];
}

- (void)reset
{
	[pathElements removeAllObjects];
	[subPaths removeAllObjects];
}

- (void)relativeMoveToPoint:(NSPoint)aPoint
{
	NSBezierPath *path;
	NSPoint p;

	p.x = currentPoint.x + aPoint.x;
	p.y = currentPoint.y + aPoint.y;
	path = [NSBezierPath bezierPath];
	[path moveToPoint: p];
	[subPaths addObject: path];	
	[self setCurrentPoint: p];	
}

- (void)relativeLineToPoint:(NSPoint)aPoint
{
	NSPoint p;

  	if(![pathElements count]) {
    	[NSException raise: NSGenericException
				format: @"attempt to append illegal path component"];
		return;
	}
	
	p.x = currentPoint.x + aPoint.x;
	p.y = currentPoint.y + aPoint.y;
	[self lineToPoint: p];
}

- (void)relativeCurveToPoint:(NSPoint)aPoint
					controlPoint1:(NSPoint)controlPoint1
					controlPoint2:(NSPoint)controlPoint2
{
	NSPoint p, cp1, cp2;

  	if(![pathElements count]) {
    	[NSException raise: NSGenericException
				format: @"attempt to append illegal path component"];
		return;
	}

	p.x = currentPoint.x + aPoint.x;
	p.y = currentPoint.y + aPoint.y;
	cp1.x = currentPoint.x + controlPoint1.x;
	cp1.y = currentPoint.y + controlPoint1.y;
	cp2.x = currentPoint.x + controlPoint2.x;
	cp2.y = currentPoint.y + controlPoint2.y;
	[self curveToPoint: p controlPoint1: cp1 controlPoint2: cp2];
}

//
// Appending paths and some common shapes 
//
- (void)appendBezierPath:(NSBezierPath *)aPath
{
	NSArray *pathelems;
	PathElement *last, *elm;
	NSBezierPathElementType t1, t2;
	NSPoint p, *p1, *p2;
	int i;
	
	if(![pathElements count]) {
		[subPaths addObject: aPath];
		return;
	}
	
	last = [self lastElement];
	t1 = [last type];
	elm = [aPath lastElement];
	t2 = [elm type];

	if(t1 == NSBezierPathElementClose || t2 == NSBezierPathElementClose) {
		[subPaths addObject: aPath];
		return;
	}
	
	p1 = [last points];
	if(t1 == NSBezierPathElementCurveTo) 
		p = NSMakePoint(p1[2].x, p1[2].y);
	else
		p = NSMakePoint(p1[0].x, p1[0].y);
	
	elm = [aPath moveToElement];
	p2 = [elm points];
	
	if((p.x != p2[0].x) || (p.y != p2[0].y)) {
		[subPaths addObject: aPath];
		return;
	}
	
	pathelems = [aPath pathElements];
	for(i = 1; i < [pathelems count]; i++) {
		elm = [pathelems objectAtIndex: i];
		t2 = [elm type];
		p2 = [elm points];
		if(t2 == NSBezierPathElementCurveTo)
			[self curveToPoint: p2[2] controlPoint1: p2[0] controlPoint2: p2[1]];
		else 
			[self lineToPoint: p2[0]];
	}
}

- (void)appendBezierPathWithPoints:(NSPoint *)points count:(int)count
{
	int i, c;
	
	if([[self lastElement] type] == NSBezierPathElementClose)
		return;
		
	if(![pathElements count]) {
		[self moveToPoint: points[0]];
		c = 1;
	} else {
		c = 0;
	}
	for(i = c; i < count; i++) 
		[self lineToPoint: points[i]];
}

- (void)appendBezierPathWithOvalInRect:(NSRect)aRect
{
	NSBezierPath *path = [self pathWithOvalInRect: aRect];
	[subPaths addObject: path];
}

- (void)appendBezierPathWithArcWithCenter:(NSPoint)center 
											  radius:(float)radius 
										 startAngle:(float)startAngle
											endAngle:(float)endAngle
{
	NSRect r;
	NSBezierPath *path, *npath;
	NSMutableArray *pelements;
	PathElement *elm;
	float tmpangle, diffangle, strtangrd, endangrd;
	NSPoint p, *pts;
	int index;

	if(startAngle < 0)
		startAngle = 360 + startAngle;

	if(endAngle < 0)
		endAngle = 360 + endAngle;

  	if(endAngle < startAngle) {
		tmpangle = endAngle;
		endAngle = startAngle;
		startAngle = tmpangle;
	}
	
	strtangrd = PI * startAngle / 180;
	endangrd = PI * endAngle / 180;

	r = NSMakeRect(center.x - radius, center.y - radius, radius * 2, radius * 2);
	path = [self pathWithOvalInRect: r];
	[path rotateByAngle: -90 center: center];
	[path rotateByAngle: startAngle center: center];
	
	npath = [NSBezierPath bezierPath];
	elm = [path moveToElement];
	p = [elm points][0];
	[npath moveToPoint: p];

	pelements = [path pathElements];	
	diffangle = endAngle - startAngle;
	index = 1;
	while(diffangle >= 90) {
		elm = [pelements objectAtIndex: index];
		pts = [elm points];
		[npath curveToPoint: pts[2] controlPoint1: pts[0] controlPoint2: pts[1]];
		diffangle -= 90;
		index++;
	}
	if(diffangle == 0) {
		[self appendBezierPath: npath];
		return;
	}
	
	p = NSMakePoint(center.x + radius * cos(endangrd), 
											center.y + radius * sin(endangrd));
	elm = [path pathElementSubdividingPathAtPoint: p 
							pathSegmentOwner: [pelements objectAtIndex: index]];
	pts = [elm points];
	[npath curveToPoint: pts[2] controlPoint1: pts[0] controlPoint2: pts[1]];
	[self appendBezierPath: npath];
}

- (void)appendBezierPathWithGlyph:(NSGlyph)aGlyph inFont:(NSFont *)fontObj
{



}

- (void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
									  count:(int)count
									 inFont:(NSFont *)fontObj
{

}

- (void)appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs
{

}

//
// Setting attributes 
//
- (void)setWindingRule:(NSWindingRule)aWindingRule
{
	windingRule = aWindingRule;
}

- (NSWindingRule)windingRule
{
	return windingRule;
}

+ (void)setLineCapStyle:(int)style
{
	[[NSGraphicsContext currentContext] DPSsetlinecap: style];
}

+ (void)setLineJoinStyle:(int)style
{
	[[NSGraphicsContext currentContext] DPSsetlinejoin: style];
}

+ (void)setLineWidth:(float)width
{
	[[NSGraphicsContext currentContext] DPSsetlinewidth: width];
}

+ (void)setMiterLimit:(float)limit
{
	[[NSGraphicsContext currentContext] DPSsetmiterlimit: limit];
}

+ (void)setFlatness:(float)flatness
{
	[[NSGraphicsContext currentContext] DPSsetflat: flatness];
}

+ (void)setHalftonePhase:(float)x : (float)y
{
	[[NSGraphicsContext currentContext] DPSsethalftonephase: x : y];
}

//
// Drawing paths
// 
- (void)stroke
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint *pts;
	int i;
	
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		switch(t) {
			case NSBezierPathElementMoveTo:
				PSmoveto(pts[0].x, pts[0].y);
				break;
			case NSBezierPathElementLineTo:
				PSlineto(pts[0].x, pts[0].y);
				break;
			case NSBezierPathElementCurveTo:
				PScurveto(pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
				break;
			default:
				break;
		}
	}
	PSstroke();
	
	for(i = 0; i < [subPaths count]; i++) 
		[[subPaths objectAtIndex: i] stroke];
}

- (void)fill
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint *pts;
	int i;
	
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		switch(t) {
			case NSBezierPathElementMoveTo:
				PSmoveto(pts[0].x, pts[0].y);
				break;
			case NSBezierPathElementLineTo:
				PSlineto(pts[0].x, pts[0].y);
				break;
			case NSBezierPathElementCurveTo:
				PScurveto(pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
				break;
			default:
				break;
		}
	}
	if(windingRule == NSWindingRuleNonZero)
		PSfill();
	else
		PSeofill();
		
	for(i = 0; i < [subPaths count]; i++) 
		[[subPaths objectAtIndex: i] fill];
}

+ (void)fillRect:(NSRect)aRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect: aRect];
	[path fill];
}

+ (void)strokeRect:(NSRect)aRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect: aRect];
	[path stroke];
}

+ (void)strokeLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint: point1];
	[path lineToPoint: point2];
	[path stroke];
}

+ (void)drawPackedGlyphs:(const char *)packedGlyphs atPoint:(NSPoint)aPoint
{

}

//
// Clipping paths 
// 
- (void)addClip
{

}

- (void)setClip
{

}

+ (void)clipRect:(NSRect)aRect
{

}

//
// Hit detection  
// 
- (BOOL)isHitByPoint:(NSPoint)aPoint
{
	if(inPath(self, aPoint) == INTERIOR)
		return YES;

	return NO;
}

- (BOOL)isHitByRect:(NSRect)aRect
{
	NSPoint p;

	p.x = aRect.origin.x;
	p.y = aRect.origin.y;
	if([self isHitByPoint: p])
		return YES;	
	p.x = aRect.origin.x + aRect.size.width;
	p.y = aRect.origin.y;
	if([self isHitByPoint: p])
		return YES;
	p.x = aRect.origin.x + aRect.size.width;
	p.y = aRect.origin.y + aRect.size.height;
	if([self isHitByPoint: p])
		return YES;	
	p.x = aRect.origin.x;
	p.y = aRect.origin.y + aRect.size.height;
	if([self isHitByPoint: p])
		return YES;		
				
	return NO;
}

- (BOOL)isHitByPath:(NSBezierPath *)aBezierPath
{
	NSPoint p, *pts;
	int i;
	
	pts = [aBezierPath draftPolygon];
	for(i = 0; i < [aBezierPath pcount]; i++) {
		p.x = pts[i].x;
		p.y = pts[i].y;
		if([self isHitByPoint: p])
			return YES;			
	}
		
	return NO;
}

- (BOOL)isStrokeHitByPoint:(NSPoint)aPoint
{
	return onPathBorder(self, aPoint);
}

- (BOOL)isStrokeHitByRect:(NSRect)aRect
{
	Line line;
	int i;

	for(i = 1; i < pcount; i++) {
		line.p1.x = draftPolygon[i-1].x;
		line.p1.y = draftPolygon[i-1].y;
		line.p2.x = draftPolygon[i].x;
		line.p2.y = draftPolygon[i].y;
		if(intersectRect(aRect, line))
			return YES;
	}

	return NO;
}

- (BOOL)isStrokeHitByPath:(NSBezierPath *)aBezierPath
{
	return [self isHitByPath: aBezierPath];
}

//
// Querying paths
// 
- (NSRect)bounds
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint *pts, *pp;
	float maxx, minx, maxy, miny;
	int i, count = 0;
	
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
			pp[count].x = pts[0].x;
			pp[count].y = pts[0].y;
			count++;
		} else if(t == NSBezierPathElementCurveTo) {
			pp[count].x = pts[2].x;
			pp[count].y = pts[2].y;
			count++;
		}
	}

	maxx = minx = pp[0].x;
	maxy = miny = pp[0].x;
	for(i = 0; i < count; i++) {
		if(pp[i].x > maxx)
			maxx = pp[i].x;
		if(pp[i].x < minx)
			minx = pp[i].x;
		if(pp[i].y > maxy)
			maxy = pp[i].y;
		if(pp[i].y < minx)
			minx = pp[i].y;
	}

	return NSMakeRect(minx, miny, maxx - minx, maxy - miny);
}

- (NSRect)controlPointBounds
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint *pts, *pp;
	float maxx, minx, maxy, miny;
	int i, count = 0;
	
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
			pp[count].x = pts[0].x;
			pp[count].y = pts[0].y;
			count++;
		} else if(t == NSBezierPathElementCurveTo) {
			pp[count].x = pts[0].x;
			pp[count].y = pts[0].y;
			count++;
			pp[count].x = pts[1].x;
			pp[count].y = pts[1].y;
			count++;
			pp[count].x = pts[2].x;
			pp[count].y = pts[2].y;
			count++;
		}
	}

	maxx = minx = pp[0].x;
	maxy = miny = pp[0].x;
	for(i = 0; i < count; i++) {
		if(pp[i].x > maxx)
			maxx = pp[i].x;
		if(pp[i].x < minx)
			minx = pp[i].x;
		if(pp[i].y > maxy)
			maxy = pp[i].y;
		if(pp[i].y < minx)
			minx = pp[i].y;
	}

	return NSMakeRect(minx, miny, maxx - minx, maxy - miny);
}

- (NSPoint)currentPoint
{
	return currentPoint;
}

//
// Accessing elements of a path 
// 
- (int)elementCount
{
	return [pathElements count];
}

- (NSBezierPathElementType)elementTypeAtIndex:(int)index
{
	return [(PathElement *)[pathElements objectAtIndex: index] type];
}

- (NSBezierPathElementType)elementTypeAtIndex:(int)index
									  associatedPoints:(NSPoint *)points
{
	PathElement *elm = [pathElements objectAtIndex: index];
	points = [elm points];
	return [elm type];
}

- (void)removeLastElement
{
	[pathElements removeObjectAtIndex: [pathElements count]-1];
}

- (int)pointCount
{
	NSBezierPathElementType t;
	int i, count = 0;

	for(i = 0; i < [pathElements count]; i++) {
		t = [(PathElement *)[pathElements objectAtIndex: i] type];
		if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo)
			count++;
		else if(t == NSBezierPathElementCurveTo)
			count += 3;
	}
	
	return count;
}

- (NSPoint)pointAtIndex:(int)index
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint p, *pts;
	int i, j, count = 0;
	
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		
		if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
			count++;
			if(count == index) {
				p.x = pts[0].x;
				p.y = pts[0].y;
				break;
			}
		} else if(t == NSBezierPathElementCurveTo) {
			for(j = 0; j <= 3; j++) {
				count++;
				if(count == index) {
					p.x = pts[j].x;
					p.y = pts[j].y;
					break;
				}		
			}
		}
	}

	return p;
}

- (void)setPointAtIndex:(int)index toPoint:(NSPoint)aPoint
{
	PathElement *elm;
	int eindex, fpointind, localind;
	
	eindex = [self pathElementIndexForPointIndex: index];
	elm = [pathElements objectAtIndex: eindex];
	fpointind = [self pointIndexForPathElementIndex: eindex];
	localind = index - fpointind;
	[elm setPointAtIndex: localind toPoint: aPoint];
	[self calculateDraftPolygon];
}

- (int)pointIndexForPathElementIndex:(int)index
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint *pts;
	int i, j, pindex = -1;

	for(i = 0; i <= index; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];

		if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
			pindex++;
		} else if(t == NSBezierPathElementCurveTo) {
			if(i < index) 
				for(j = 0; j <= 3; j++)
					pindex++;
			else 
				pindex++;
		}
	}

	return pindex;
}

- (int)pathElementIndexForPointIndex:(int)index
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint *pts;
	int pindex = 0, j, elemindex = 0;

	while(elemindex < [pathElements count]) {
		elm = [pathElements objectAtIndex: elemindex];
		pts = [elm points];
		t = [elm type];
		
		if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
			pindex++;
			elemindex++;
			if(pindex == index)
				break;
		} else if(t == NSBezierPathElementCurveTo) {
			elemindex++;
			for(j = 0; j <= 3; j++) {
				pindex++;
				if(pindex == index)
					break;
			}
		}
	}

	return elemindex;
}

//
// Caching paths 
// 
- (BOOL)cachesBezierPath
{
	return cachesBezierPath;
}

- (void)setCachesBezierPath:(BOOL)flag
{
	cachesBezierPath = flag;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:(NSCoder*)aCoder
{
	[super encodeWithCoder: aCoder];
}

- (id)initWithCoder:(NSCoder*)aCoder
{
	[super initWithCoder: aCoder];
	return self;
}

//
// NSCopying Protocol
//
- (id)copyWithZone:(NSZone*)zone
{
  	return self;
}

@end


@implementation NSBezierPath (PrivateMethods)

- (void)setCurrentPoint:(NSPoint)aPoint
{
	currentPoint.x = aPoint.x;
	currentPoint.y = aPoint.y;
}

- (BOOL)isPathElement:(PathElement *)elm1 onPathElement:(PathElement *)elm2
{
	NSPoint p1, p2;
	NSBezierPathElementType t;

	t = [elm1 type];
	if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
		p1.x = [elm1 points][0].x;
		p1.y = [elm1 points][0].y;
	} else if(t == NSBezierPathElementCurveTo) {
		p1.x = [elm1 points][2].x;
		p1.y = [elm1 points][2].y;
	} else {
		return NO;
	}

	t = [elm2 type];
	if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
		p2.x = [elm2 points][0].x;
		p2.y = [elm2 points][0].y;
	} else if(t == NSBezierPathElementCurveTo) {
		p2.x = [elm2 points][2].x;
		p2.y = [elm2 points][2].y;
	} else {
		return NO;
	}
	
	if(p1.x == p2.x && p1.y == p2.y)
		return YES;
	
	return NO;
}

- (NSMutableArray *)pathElements
{
	return pathElements;
}

- (PathElement *)moveToElement
{
	return [pathElements objectAtIndex: 0];
}

- (PathElement *)lastElement
{
	return [pathElements objectAtIndex: [pathElements count] -1];
}

- (int)indexOfElement:(PathElement *)element
{
	PathElement *elm;
	int i;
	
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		if(elm == element)
			break;
	}
	
	return i;
}

- (PathElement *)elementPrecedingElement:(PathElement *)element
{
	PathElement *prevelm;
	int index;
	
	index = [self indexOfElement: element];
	if(index == 0)
		prevelm = [pathElements objectAtIndex: [pathElements count] -1];
	else
		prevelm = [pathElements objectAtIndex: index -1];
		
		
		// ATTENZIONE !!!!!
		// COSA FARE SE IL PATH E' APERTO ??????????????
		// ATTENZIONE !!!!!
		// E SE E' DI TYPO CLOSEPATH ???????????????
		
		
	return prevelm;
}

- (void)calculateDraftPolygon
{
	PathElement *elm;
	NSBezierPathElementType bpt;
	NSPoint p, *pts;
	double x, y, t, k = 0.025;
	int i;
				
	pcount = 0;
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		bpt = [elm type];
		pts = [elm points];
		
		if(bpt == NSBezierPathElementMoveTo || bpt == NSBezierPathElementLineTo) {
			draftPolygon[pcount].x = pts[0].x;
			draftPolygon[pcount].y = pts[0].y;
			pcount++;
		} else if(bpt == NSBezierPathElementCurveTo) {
			if(pcount) {
  				p.x = draftPolygon[pcount -1].x;
  				p.y = draftPolygon[pcount -1].y;
			} else {
  				p.x = pts[0].x;
  				p.y = pts[0].y;
			}
  			for(t = k; t <= 1+k; t += k) {
      		x = (p.x+t*(-p.x*3+t*(3*p.x-p.x*t)))
        			+t*(3*pts[0].x+t*(-6*pts[0].x+pts[0].x*3*t))
					+t*t*(pts[1].x*3-pts[1].x*3*t)+pts[2].x*t*t*t;
      		y = (p.y+t*(-p.y*3+t*(3*p.y-p.y*t)))
        			+t*(3*pts[0].y+t*(-6*pts[0].y+pts[0].y*3*t))
					+t*t*(pts[1].y*3-pts[1].y*3*t)+pts[2].y*t*t*t;

				draftPolygon[pcount].x = x;
				draftPolygon[pcount].y = y;
				pcount++;
			}
		}
	}
}

- (NSPoint *)draftPolygon
{
	return draftPolygon;
}

- (int)pcount
{
	return pcount;
}

- (NSBezierPath *)pathWithOvalInRect:(NSRect)aRect
{
	NSBezierPath *path;
	NSPoint p, p1, p2;
	double originx = aRect.origin.x;
	double originy = aRect.origin.y;
	double width = aRect.size.width;
	double height = aRect.size.height;
	double hdiff = width / 2 * 0.5522847498;
	double vdiff = height / 2 * 0.5522847498;
	
	path = [NSBezierPath bezierPath];
	p = NSMakePoint(originx + width / 2, originy + height);
	[path moveToPoint: p];

	p = NSMakePoint(originx, originy + height / 2);
	p1 = NSMakePoint(originx + width / 2 - hdiff, originy + height);
	p2 = NSMakePoint(originx, originy + height / 2 + vdiff);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];
	
	p = NSMakePoint(originx + width / 2, originy);
	p1 = NSMakePoint(originx, originy + height / 2 - vdiff);
	p2 = NSMakePoint(originx + width / 2 - hdiff, originy);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];	
	
	p = NSMakePoint(originx + width, originy + height / 2);
	p1 = NSMakePoint(originx + width / 2 + hdiff, originy);
	p2 = NSMakePoint(originx + width, originy + height / 2 - vdiff);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];	
	
	p = NSMakePoint(originx + width / 2, originy + height);
	p1 = NSMakePoint(originx + width, originy + height / 2 + vdiff);
	p2 = NSMakePoint(originx + width / 2 + hdiff, originy + height);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];	
	
	return path;
}

- (void)movePathToPoint:(NSPoint)p
{




}

- (void)rotateByAngle:(float)angle center:(NSPoint)center
{
	PathElement *elm;
	NSBezierPathElementType t;
	NSPoint p, *pts;
	int i;

	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		if(t == NSBezierPathElementCurveTo) {
			p = rotatePoint(pts[0], center, angle);
			[elm setPointAtIndex: 0 toPoint: p];
			p = rotatePoint(pts[1], center, angle);
			[elm setPointAtIndex: 1 toPoint: p];
			p = rotatePoint(pts[2], center, angle);
			[elm setPointAtIndex: 2 toPoint: p];
		} else if(t == NSBezierPathElementMoveTo || t == NSBezierPathElementLineTo) {
			p = rotatePoint(pts[0], center, angle);
			[elm setPointAtIndex: 0 toPoint: p];
		}	
	}
}

- (pointOnCurve)pointOnPathSegmentOfElement:(PathElement *)elm
									  nearestToPoint:(NSPoint)p
{
	pointOnCurve pc;
	PathElement *prevelm;
	NSPoint *pp1, *pp2, cpp[4];
	double x, y, d, dmin = 10000, t, k = 0.001;
	
	prevelm = [self elementPrecedingElement: elm];
	if([prevelm type] == NSBezierPathElementClose)
		prevelm = [self elementPrecedingElement: prevelm];
	
	pp1 = [prevelm points];
	pp2 = [elm points];

	if([prevelm type] == NSBezierPathElementCurveTo) {
		cpp[0].x = pp1[2].x;
		cpp[0].y = pp1[2].y;
	} else {
		cpp[0].x = pp1[0].x;
		cpp[0].y = pp1[0].y;
	}
	
	if([elm type] == NSBezierPathElementCurveTo) {
		cpp[1].x = pp2[0].x;
		cpp[1].y = pp2[0].y;
		cpp[2].x = pp2[1].x;
		cpp[2].y = pp2[1].y;
		cpp[3].x = pp2[2].x;
		cpp[3].y = pp2[2].y;
	} else {
		cpp[1].x = cpp[0].x;
		cpp[1].y = cpp[0].y;
		cpp[2].x = pp2[0].x;
		cpp[2].y = pp2[0].y;
		cpp[3].x = pp2[0].x;
		cpp[3].y = pp2[0].y;
	}

 	for(t = k; t <= 1+k; t += k) {
		x = (cpp[0].x+t*(-cpp[0].x*3+t*(3*cpp[0].x-cpp[0].x*t)))
        	 +t*(3*cpp[1].x+t*(-6*cpp[1].x+cpp[1].x*3*t))
			 +t*t*(cpp[2].x*3-cpp[2].x*3*t)+cpp[3].x*t*t*t;
		y = (cpp[0].y+t*(-cpp[0].y*3+t*(3*cpp[0].y-cpp[0].y*t)))
        	 +t*(3*cpp[1].y+t*(-6*cpp[1].y+cpp[1].y*3*t))
			 +t*t*(cpp[2].y*3-cpp[2].y*3*t)+cpp[3].y*t*t*t;

		d = pow(pow(x - p.x, 2) + pow(y - p.y, 2), 0.5);
		if(d < dmin) {
			dmin = d;
			pc.p = NSMakePoint(x, y);
			pc.t = t - k;
		}
	}	
	
	return pc;
}

- (PathElement *)pathElementSubdividingPathAtPoint:(NSPoint)p 
											 pathSegmentOwner:(PathElement *)owner
{
	PathElement *prevelm, *elm;
	NSPoint *ownerpts, *prevpts;
	pointOnCurve pc;
	float coeffx[4], coeffy[4], bleftx[4], blefty[4], brightx[4], brighty[4];
	
	prevelm = [self elementPrecedingElement: owner];
	if([prevelm type] == NSBezierPathElementClose)
		prevelm = [self elementPrecedingElement: prevelm];
	prevpts = [prevelm points];
	ownerpts = [owner points];	
	pc = [self pointOnPathSegmentOfElement: owner nearestToPoint: p];
	
	if([prevelm type] == NSBezierPathElementCurveTo) {
		coeffx[0] = prevpts[2].x;
		coeffy[0] = prevpts[2].y;
	} else {
		coeffx[0] = prevpts[0].x;
		coeffy[0] = prevpts[0].y;
	}	
	if([owner type] == NSBezierPathElementCurveTo) {
		coeffx[1] = ownerpts[0].x;
		coeffy[1] = ownerpts[0].y;
		coeffx[2] = ownerpts[1].x;
		coeffy[2] = ownerpts[1].y;
		coeffx[3] = ownerpts[2].x;
		coeffy[3] = ownerpts[2].y;
	} else {
		coeffx[1] = ownerpts[0].x;
		coeffy[1] = ownerpts[0].y;
		coeffx[2] = ownerpts[0].x;
		coeffy[2] = ownerpts[0].y;
		coeffx[3] = ownerpts[0].x;
		coeffy[3] = ownerpts[0].y;
	}
	
	subdiv(3, coeffx, pc.t, bleftx, brightx);
	subdiv(3, coeffy, pc.t, blefty, brighty);
		
	elm = [PathElement pathElement];
	[elm setType: NSBezierPathElementCurveTo];
	[elm setPointAtIndex: 0 toPoint: NSMakePoint(bleftx[2], blefty[2])];
	[elm setPointAtIndex: 1 toPoint: NSMakePoint(bleftx[1], blefty[1])];
	[elm setPointAtIndex: 2 toPoint: p];

	[owner setType: NSBezierPathElementCurveTo];
	[owner setPointAtIndex: 0 toPoint: NSMakePoint(brightx[1], brighty[1])];
	[owner setPointAtIndex: 1 toPoint: NSMakePoint(brightx[2], brighty[2])];

	return elm;
}

@end

//
// Functions
//
pointPosition inPath(NSBezierPath *aPath, NSPoint p)
{
	NSPoint *pts;
	int xs[PMAX], ys[PMAX];
	double x;
	int i, i1, pcount;
	int Rcross = 0;
  	int Lcross = 0;	
	
	pts = [aPath draftPolygon];
	pcount = [aPath pcount];	
	for(i = 0; i < pcount; i++) {
		xs[i] = (int)pts[i].x - p.x;
		ys[i] = (int)pts[i].y - p.y;
	}

  	for(i = 0; i < pcount; i++) {
		if(xs[i] == 0 && ys[i] == 0) 
			return VERTEX;
					
    	i1 = (i + pcount - 1) % pcount;
    	if((ys[i] > 0) != (ys[i1] > 0)) {
     		x = (xs[i] * (double)ys[i1] - xs[i1] * (double)ys[i])
															/ (double)(ys[i1] - ys[i]);
      	if(x > 0) 
				Rcross++;
		}
		if((ys[i] < 0 ) != (ys[i1] < 0)) { 
			x = (xs[i] * ys[i1] - xs[i1] * ys[i])
          												/ (double)(ys[i1] - ys[i]);
      	if(x < 0) 
				Lcross++;		
		}
	}

	if((Rcross % 2) != (Lcross % 2))
    	return ONBORDER;
  	if((Rcross % 2) == 1)
    	return INTERIOR;
  	else	
		return EXTERIOR;
}

BOOL onPathBorder(NSBezierPath *aPath, NSPoint p)
{
	if(inPath(aPath, p) == ONBORDER)
		return YES;
	
	return NO;
}

int ccw(NSPoint p0, NSPoint p1, NSPoint p2)
{
	int dx1, dx2, dy1, dy2;
        
	dx1 = p1.x - p0.x; 
	dy1 = p1.y - p0.y;
	dx2 = p2.x - p0.x; 
	dy2 = p2.y - p0.y;
        
	if(dx1*dy2 > dy1*dx2)
		return +1;
	if(dx1*dy2 < dy1*dx2)
		return -1;
	if((dx1*dx2 < 0) || (dy1*dy2 < 0))
		return -1;
	if((dx1*dx1 + dy1*dy1) < (dx2*dx2 + dy2*dy2))
		return +1;
	
	return 0;
}

BOOL intersect(Line line1, Line line2)
{
	return ((ccw(line1.p1, line1.p2, line2.p1)
                        * ccw(line1.p1, line1.p2, line2.p2)) <= 0)
          && ((ccw(line2.p1, line2.p2, line1.p1)
                        * ccw(line2.p1, line2.p2, line1.p2)) <= 0);
}

BOOL intersectRect(NSRect rect, Line line)
{
	Line line1, line2, line3, line4;
	NSPoint topLeft, bottomRight;
	double tmp;

	line1.p1.x = rect.origin.x;
	line1.p1.y = rect.origin.y + rect.size.height;
	line1.p2.x = rect.origin.x + rect.size.width;
	line1.p2.y = rect.origin.y + rect.size.height;
	
	line2.p1.x = line1.p2.x;
	line2.p1.y = line1.p2.y;
	line2.p2.x = line2.p1.x;
	line2.p2.y = rect.origin.y;

	line3.p1.x = line2.p2.x;
   line3.p1.y = line2.p2.y;     
	line3.p2.x = rect.origin.x;
	line3.p2.y = rect.origin.y;
        
   line4.p1.x = line3.p2.x;
	line4.p1.y = line3.p2.y;
	line4.p2.x = line1.p1.x;
	line4.p2.y = line1.p1.y;
	        
	if(intersect(line1, line) || intersect(line2, line)
     					|| intersect(line3, line) || intersect(line4, line))
		return YES;
        
	topLeft.x = rect.origin.x;
	topLeft.y = rect.origin.y + rect.size.height;
	bottomRight.x = rect.origin.x + rect.size.width;
	bottomRight.y = rect.origin.y;
	
	if(bottomRight.x < topLeft.x) {
		tmp = bottomRight.x;
		bottomRight.x = topLeft.x;
		topLeft.x = tmp;
	}
	if(bottomRight.y < topLeft.y) {
		tmp = bottomRight.y;
		bottomRight.y = topLeft.y;
		topLeft.y = tmp;
	}
        
	return (line.p1.x >= topLeft.x && line.p1.x <= bottomRight.x
             && line.p1.y >= topLeft.y && line.p1.y <= bottomRight.y);
}

void subdiv(int degree, float coeff[], float t, float bleft[], float bright[])
{
	int r, i;
	float t1;

	t1 = 1.0 - t;

	// use Casteljeau to find the right Bezier polygon
	for (i = 0; i <= degree; i++)
		bright[i] = coeff[i];
 
	for (r = 1; r <= degree; r++)
    	for (i = 0; i <= degree - r; i++)
      	bright[i] = t1 * bright[i] + t * bright[i + 1];

	// to find the left Bezier polygon (inverse order)
	t = 1.0 - t;
	t1 = 1.0 - t;

	for (i = 0; i <= degree; i++)
		bleft[degree - i] = coeff[i];

	for (r = 1; r <= degree; r++)
    	for (i = 0; i <= degree - r; i++)
			bleft[i] = t1 * bleft[i] + t * bleft[i + 1];
}

NSPoint rotatePoint(NSPoint p, NSPoint centre, float angle)
{
	NSPoint rp;
	float rdangle = PI * angle / 180;
	float dx, dy;

	dx = p.x - centre.x;
	dy = p.y - centre.y;

	rp.x = (dx * cos(rdangle)) - (dy * sin(rdangle)) + centre.x;
	rp.y = (dx * sin(rdangle)) + (dy * cos(rdangle)) + centre.y;

	return rp;
}






