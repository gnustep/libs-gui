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

#define PMAX 10000

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
void subdiv(int degree, float coeff[], float t, float bleft[], float bright[]);
NSPoint rotatePoint(NSPoint p, NSPoint centre, float angle);


@interface PathElement : NSObject
{
	NSPoint p[3];
	NSBezierPathElement type;
}

+ (PathElement *)pathElement;

- (void)setType:(NSBezierPathElement)t;

- (void)setPointAtIndex:(int)index toPoint:(NSPoint)aPoint;

- (NSBezierPathElement)type;

- (NSPoint *)points;

@end


@interface NSBezierPath (PrivateMethods)

- (void)setBounds:(NSRect)br;

- (void)setControlPointBounds:(NSRect)br;

@end


@interface GSBezierPath : NSBezierPath
{
	NSMutableArray *pathElements;
	NSMutableArray *subPaths;
	NSPoint draftPolygon[PMAX];
	int pcount;
	NSPoint currentPoint;
	BOOL cachesBezierPath;
	NSImage *cacheimg;
	BOOL isValid;
}

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

- (void)movePathToPoint:(NSPoint)p;

- (void)rotateByAngle:(float)angle center:(NSPoint)center;

- (pointOnCurve)pointOnPathSegmentOfElement:(PathElement *)elm
									  nearestToPoint:(NSPoint)p;
									  
- (PathElement *)pathElementSubdividingPathAtPoint:(NSPoint)p 
											 pathSegmentOwner:(PathElement *)owner;

@end


@implementation PathElement

+ (PathElement *)pathElement
{
	PathElement *element = [[self alloc] init];
	[element setPointAtIndex: 0 toPoint: NSMakePoint(0, 0)];
  	return AUTORELEASE(element);
}

- (void)setType:(NSBezierPathElement)t
{
	type = t;
}

- (void)setPointAtIndex:(int)index toPoint:(NSPoint)aPoint
{
	p[index].x = aPoint.x;
	p[index].y = aPoint.y;
}

- (NSBezierPathElement)type
{
	return type;
}

- (NSPoint *)points
{
	return p;
}

@end


static Class NSBezierPath_concrete_class = nil;

@implementation NSBezierPath

+ (void)initialize
{
	if(self == [NSBezierPath class])
      NSBezierPath_concrete_class = [GSBezierPath class];
}

+ (void)_setConcreteClass:(Class)c
{
  	NSBezierPath_concrete_class = c;
}

+ (Class)_concreteClass
{
	return NSBezierPath_concrete_class;
}

//
// Creating common paths
//
+ (id)bezierPath
{
	return [[[self _concreteClass] alloc] init];
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

+ (NSBezierPath *)bezierPathWithOvalInRect:(NSRect)rect
{
	NSBezierPath *path;
	NSPoint p, p1, p2;
	double originx = rect.origin.x;
	double originy = rect.origin.y;
	double width = rect.size.width;
	double height = rect.size.height;
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

//
// Immediate mode drawing of common paths
//
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

+ (void)clipRect:(NSRect)rect
{

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
// Default path rendering parameters
//
+ (void)setDefaultMiterLimit:(float)limit
{
	PSsetmiterlimit(limit);
}

+ (float)defaultMiterLimit
{
	float limit;
	PScurrentmiterlimit(&limit);
	return limit;
}

+ (void)setDefaultFlatness:(float)flatness
{
	PSsetflat(flatness);
}

+ (float)defaultFlatness
{
	float flatness;
	PScurrentflat(&flatness);
	return flatness;
}

+ (void)setDefaultWindingRule:(NSWindingRule)windingRule
{

}

+ (NSWindingRule)defaultWindingRule
{
	return NSNonZeroWindingRule;
}

+ (void)setDefaultLineCapStyle:(NSLineCapStyle)lineCapStyle
{
	PSsetlinecap(lineCapStyle);
}

+ (NSLineCapStyle)defaultLineCapStyle
{
	int lineCapStyle;
	PScurrentlinecap(&lineCapStyle);
	return lineCapStyle;
}

+ (void)setDefaultLineJoinStyle:(NSLineJoinStyle)lineJoinStyle
{
	PSsetlinejoin(lineJoinStyle);
}

+ (NSLineJoinStyle)defaultLineJoinStyle
{
	int lineJoinStyle;
	PScurrentlinejoin(&lineJoinStyle);
	return lineJoinStyle;
}

+ (void)setDefaultLineWidth:(float)lineWidth
{
	PSsetlinewidth(lineWidth);
}

+ (float)defaultLineWidth
{
	float lineWidth;
	PScurrentlinewidth(&lineWidth);
	return lineWidth;
}

//
// Path construction
//
- (void)moveToPoint:(NSPoint)aPoint
{
	[self subclassResponsibility:_cmd];
}

- (void)lineToPoint:(NSPoint)aPoint
{
	[self subclassResponsibility:_cmd];
}

- (void)curveToPoint:(NSPoint)aPoint 
		 controlPoint1:(NSPoint)controlPoint1
		 controlPoint2:(NSPoint)controlPoint2
{
	[self subclassResponsibility:_cmd];
}

- (void)closePath
{
	[self subclassResponsibility:_cmd];
}

- (void)removeAllPoints
{
	[self subclassResponsibility:_cmd];
}

//
// Relative path construction
//
- (void)relativeMoveToPoint:(NSPoint)aPoint
{
	[self subclassResponsibility:_cmd];
}

- (void)relativeLineToPoint:(NSPoint)aPoint
{
	[self subclassResponsibility:_cmd];
}

- (void)relativeCurveToPoint:(NSPoint)aPoint
					controlPoint1:(NSPoint)controlPoint1
					controlPoint2:(NSPoint)controlPoint2
{
	[self subclassResponsibility:_cmd];
}

//
// Path rendering parameters
//
- (float)lineWidth
{
	return _lineWidth;
}

- (void)setLineWidth:(float)lineWidth
{
	_lineWidth = lineWidth;
}

- (NSLineCapStyle)lineCapStyle
{
	return _lineCapStyle;
}

- (void)setLineCapStyle:(NSLineCapStyle)lineCapStyle
{
	_lineCapStyle = lineCapStyle;
}

- (NSLineJoinStyle)lineJoinStyle
{
	return _lineJoinStyle;
}

- (void)setLineJoinStyle:(NSLineJoinStyle)lineJoinStyle
{
	_lineJoinStyle = lineJoinStyle;
}

- (NSWindingRule)windingRule
{
	return _windingRule;
}

- (void)setWindingRule:(NSWindingRule)windingRule
{
	_windingRule = windingRule;
}

//
// Path operations
//
- (void)stroke
{
	[self subclassResponsibility:_cmd];
}

- (void)fill
{
	[self subclassResponsibility:_cmd];
}

- (void)addClip
{
	[self subclassResponsibility:_cmd];
}

- (void)setClip
{
	[self subclassResponsibility:_cmd];
}

//
// Path modifications.
//
- (NSBezierPath *)bezierPathByFlatteningPath
{
	return self;
}

- (NSBezierPath *)bezierPathByReversingPath
{
	return self;
}

//
// Applying transformations.
//
- (void)transformUsingAffineTransform:(NSAffineTransform *)transform
{

}

//
// Path info
//
- (BOOL)isEmpty
{
	[self subclassResponsibility:_cmd];
	return NO;
}

- (NSPoint)currentPoint
{
	[self subclassResponsibility:_cmd];
	return NSZeroPoint;
}

- (NSRect)controlPointBounds
{
	return _controlPointBounds;
}

- (NSRect)bounds
{
	return _bounds;
}

//
// Elements
//
- (int)elementCount
{
	[self subclassResponsibility:_cmd];
	return 0;
}

- (NSBezierPathElement)elementAtIndex:(int)index
		     				associatedPoints:(NSPoint *)points
{
	[self subclassResponsibility:_cmd];	
	return 0;
}

- (NSBezierPathElement)elementAtIndex:(int)index
{
	return [self elementAtIndex: index associatedPoints: NULL];	
}

- (void)setAssociatedPoints:(NSPoint *)points atIndex:(int)index
{
	[self subclassResponsibility:_cmd];	
}

//
// Appending common paths
//
- (void)appendBezierPath:(NSBezierPath *)aPath
{
	[self subclassResponsibility:_cmd];
}

- (void)appendBezierPathWithRect:(NSRect)rect
{
	[self subclassResponsibility:_cmd];
}

- (void)appendBezierPathWithPoints:(NSPoint *)points count:(int)count
{
	[self subclassResponsibility:_cmd];
}

- (void)appendBezierPathWithOvalInRect:(NSRect)aRect
{
	[self subclassResponsibility:_cmd];
}

- (void)appendBezierPathWithArcWithCenter:(NSPoint)center  
											  radius:(float)radius
			       					 startAngle:(float)startAngle
				 							endAngle:(float)endAngle
										  clockwise:(BOOL)clockwise
{
	[self subclassResponsibility:_cmd];
}

- (void)appendBezierPathWithArcWithCenter:(NSPoint)center  
											  radius:(float)radius
			       					 startAngle:(float)startAngle
				 							endAngle:(float)endAngle
{
	[self appendBezierPathWithArcWithCenter: center radius: radius
			       	startAngle: startAngle endAngle: endAngle clockwise: NO];
}

- (void)appendBezierPathWithArcFromPoint:(NSPoint)point1
				 							toPoint:(NSPoint)point2
				  							 radius:(float)radius
{
	[self subclassResponsibility:_cmd];
}

- (void)appendBezierPathWithGlyph:(NSGlyph)glyph inFont:(NSFont *)font
{

}

- (void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
									  count:(int)count
			    					 inFont:(NSFont *)font
{

}
				 
- (void)appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs
{

}

//
// Hit detection  
// 
- (BOOL)containsPoint:(NSPoint)point
{
	[self subclassResponsibility:_cmd];
	return NO;
}

//
// Caching paths 
// 
- (BOOL)cachesBezierPath
{
	[self subclassResponsibility:_cmd];
	return NO;
}

- (void)setCachesBezierPath:(BOOL)flag
{
	[self subclassResponsibility:_cmd];
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

- (void)setBounds:(NSRect)br
{
	_bounds = NSMakeRect(br.origin.x, br.origin.y, br.size.width, br.size.height);
}

- (void)setControlPointBounds:(NSRect)br
{
	_controlPointBounds = NSMakeRect(br.origin.x, br.origin.y, br.size.width, br.size.height);
}

@end


@implementation GSBezierPath

+ (id)bezierPath
{
  	return AUTORELEASE([[self alloc] init]);
}

- (id)init
{
	self = [super init];
	if(self) {
		pathElements = [[NSMutableArray alloc] initWithCapacity: 1];
		subPaths = [[NSMutableArray alloc] initWithCapacity: 1];
		[self setWindingRule: NSNonZeroWindingRule];
		[self setBounds: NSZeroRect];
		[self setControlPointBounds: NSZeroRect];
		cachesBezierPath = NO;
		cacheimg = nil;
		isValid = NO;
	}
	return self;
}

- (void)dealloc
{
	[pathElements release];
	[subPaths release];
	if(cacheimg)
		[cacheimg release];
	[super dealloc];
}

//
// Path construction
//
- (void)moveToPoint:(NSPoint)aPoint
{
	PathElement *elm = [PathElement pathElement];
	[elm setType: NSMoveToBezierPathElement];
	[elm setPointAtIndex: 0 toPoint: aPoint];
	[pathElements addObject: elm];
	[self setCurrentPoint: aPoint];
	[self calculateDraftPolygon];
}

- (void)lineToPoint:(NSPoint)aPoint
{
	PathElement *elm = [PathElement pathElement];
	[elm setType: NSLineToBezierPathElement];
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
	[elm setType: NSCurveToBezierPathElement];
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
	[elm setType: NSClosePathBezierPathElement];
	[pathElements addObject: elm];
}

- (void)removeAllPoints
{
	[pathElements removeAllObjects];
	[subPaths removeAllObjects];
	[self setBounds: NSZeroRect];
	[self setControlPointBounds: NSZeroRect];
	if(cacheimg != nil) {
		[cacheimg release];
		cacheimg = nil;	
		isValid = NO;
	}
}

//
// Relative path construction
//
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
// Path operations
//
- (void)stroke
{
	PathElement *elm;
	NSBezierPathElement t;
	NSPoint *pts, origin;
	float r, g, b, w;
	int i;
		
	if(cachesBezierPath) {
		origin = [self bounds].origin;
		if(!isValid) {
			if(cacheimg) 
				[cacheimg release];
			cacheimg = [[NSImage alloc] initWithSize: [self bounds].size];		
			[self movePathToPoint: NSMakePoint(0, 0)];
			
			PScurrentrgbcolor(&r, &g, &b);
			PScurrentlinewidth(&w);

			[cacheimg lockFocus];
			PSsetrgbcolor(r, g, b);
			PSsetlinewidth(w);
			for(i = 0; i < [pathElements count]; i++) {
				elm = [pathElements objectAtIndex: i];
				pts = [elm points];
				t = [elm type];
				switch(t) {
					case NSMoveToBezierPathElement:
						PSmoveto(pts[0].x, pts[0].y);
						break;
					case NSLineToBezierPathElement:
						PSlineto(pts[0].x, pts[0].y);
						break;
					case NSCurveToBezierPathElement:
						PScurveto(pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
						break;
					default:
						break;
				}
			}
			PSstroke();
			[cacheimg unlockFocus];
						
			[self movePathToPoint: origin];			
			isValid = YES;
		}
		[cacheimg compositeToPoint: origin operation: NSCompositeCopy];
	} else {
		for(i = 0; i < [pathElements count]; i++) {
			elm = [pathElements objectAtIndex: i];
			pts = [elm points];
			t = [elm type];
			switch(t) {
				case NSMoveToBezierPathElement:
					PSmoveto(pts[0].x, pts[0].y);
					break;
				case NSLineToBezierPathElement:
					PSlineto(pts[0].x, pts[0].y);
					break;
				case NSCurveToBezierPathElement:
					PScurveto(pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
					break;
				default:
					break;
			}
		}
		PSstroke();
	}
	
	for(i = 0; i < [subPaths count]; i++) 
		[[subPaths objectAtIndex: i] stroke];
}

- (void)fill
{
	PathElement *elm;
	NSBezierPathElement t;
	NSPoint *pts, origin;
	float r, g, b;	
	int i;

	if(cachesBezierPath) {
		origin = [self bounds].origin;
		if(!isValid) {
			if(cacheimg) 
				[cacheimg release];
			cacheimg = [[NSImage alloc] initWithSize: [self bounds].size];		
			[self movePathToPoint: NSMakePoint(0, 0)];
			PScurrentrgbcolor(&r, &g, &b);
			
			[cacheimg lockFocus];
			PSsetrgbcolor(r, g, b);
			for(i = 0; i < [pathElements count]; i++) {
				elm = [pathElements objectAtIndex: i];
				pts = [elm points];
				t = [elm type];
				switch(t) {
					case NSMoveToBezierPathElement:
						PSmoveto(pts[0].x, pts[0].y);
						break;
					case NSLineToBezierPathElement:
						PSlineto(pts[0].x, pts[0].y);
						break;
					case NSCurveToBezierPathElement:
						PScurveto(pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
						break;
					default:
						break;
				}
			}
			if([self windingRule] == NSNonZeroWindingRule)
				PSfill();
			else
				PSeofill();
			[cacheimg unlockFocus];
			
			[self movePathToPoint: origin];			
			isValid = YES;
		}
		[cacheimg compositeToPoint: origin operation: NSCompositeCopy];
	} else {
		for(i = 0; i < [pathElements count]; i++) {
			elm = [pathElements objectAtIndex: i];
			pts = [elm points];
			t = [elm type];
			switch(t) {
				case NSMoveToBezierPathElement:
					PSmoveto(pts[0].x, pts[0].y);
					break;
				case NSLineToBezierPathElement:
					PSlineto(pts[0].x, pts[0].y);
					break;
				case NSCurveToBezierPathElement:
					PScurveto(pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
					break;
				default:
					break;
			}
		}
		if([self windingRule] == NSNonZeroWindingRule)
			PSfill();
		else
			PSeofill();
	}
	
	for(i = 0; i < [subPaths count]; i++) 
		[[subPaths objectAtIndex: i] fill];
}

- (void)addClip
{

}

- (void)setClip
{

}

//
// Path info
//
- (BOOL)isEmpty
{
	if([pathElements count])
		return NO;
		
	return YES;
}

- (NSPoint)currentPoint
{
	return currentPoint;
}

//
// Elements
//
- (int)elementCount
{
	return [pathElements count];
}

- (NSBezierPathElement)elementAtIndex:(int)index
		     				associatedPoints:(NSPoint *)points
{
	PathElement *elm = [pathElements objectAtIndex: index];
	NSBezierPathElement type = [elm type];
	NSPoint *p = [elm points];
	
	if(points != NULL) {
		if(type == NSMoveToBezierPathElement || type == NSLineToBezierPathElement) {
			points[0].x = p[0].x;
			points[0].y = p[0].y;
		} else if(type == NSCurveToBezierPathElement) {
			points[0].x = p[0].x;
			points[0].y = p[0].y;
			points[1].x = p[1].x;
			points[1].y = p[1].y;
			points[2].x = p[2].x;
			points[2].y = p[2].y;
		}
	}
	
	return type;
}

- (void)setAssociatedPoints:(NSPoint *)points atIndex:(int)index
{
	PathElement *elm = [pathElements objectAtIndex: index];
	NSBezierPathElement type = [elm type];

	if(type == NSMoveToBezierPathElement
						|| type == NSLineToBezierPathElement
										|| type == NSClosePathBezierPathElement) {
		[elm setPointAtIndex: 0 toPoint: points[0]];
		return;
	}
	
	[elm setPointAtIndex: 0 toPoint: points[0]];
	[elm setPointAtIndex: 1 toPoint: points[1]];
	[elm setPointAtIndex: 2 toPoint: points[2]];
	
	[self calculateDraftPolygon];
}

//
// Appending common paths
//
- (void)appendBezierPath:(NSBezierPath *)aPath
{
	NSArray *pathelems;
	PathElement *last, *elm;
	NSBezierPathElement t1, t2;
	NSPoint p, *p1, *p2;
	int i;
	
	if(![pathElements count]) {
		[subPaths addObject: aPath];
		return;
	}
	
	last = [self lastElement];
	t1 = [last type];
	elm = [(GSBezierPath *)aPath lastElement];
	t2 = [elm type];

	if(t1 == NSClosePathBezierPathElement || t2 == NSClosePathBezierPathElement) {
		[subPaths addObject: aPath];
		return;
	}
	
	p1 = [last points];
	if(t1 == NSCurveToBezierPathElement) 
		p = NSMakePoint(p1[2].x, p1[2].y);
	else
		p = NSMakePoint(p1[0].x, p1[0].y);
	
	elm = [(GSBezierPath *)aPath moveToElement];
	p2 = [elm points];
	
	if((p.x != p2[0].x) || (p.y != p2[0].y)) {
		[subPaths addObject: aPath];
		return;
	}
	
	pathelems = [(GSBezierPath *)aPath pathElements];
	for(i = 1; i < [pathelems count]; i++) {
		elm = [pathelems objectAtIndex: i];
		t2 = [elm type];
		p2 = [elm points];
		if(t2 == NSCurveToBezierPathElement)
			[self curveToPoint: p2[2] controlPoint1: p2[0] controlPoint2: p2[1]];
		else 
			[self lineToPoint: p2[0]];
	}
}

- (void)appendBezierPathWithRect:(NSRect)rect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect: rect];
	[subPaths addObject: path];
}

- (void)appendBezierPathWithPoints:(NSPoint *)points count:(int)count
{
	int i, c;
	
	if([[self lastElement] type] == NSClosePathBezierPathElement)
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
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: aRect];
	[subPaths addObject: path];
}

- (void)appendBezierPathWithArcWithCenter:(NSPoint)center  
											  radius:(float)radius
			       					 startAngle:(float)startAngle
				 							endAngle:(float)endAngle
										  clockwise:(BOOL)clockwise
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
	path = [NSBezierPath bezierPathWithOvalInRect: r];
	[(GSBezierPath *)path rotateByAngle: -90 center: center];
	[(GSBezierPath *)path rotateByAngle: startAngle center: center];
	
	npath = [NSBezierPath bezierPath];
	elm = [(GSBezierPath *)path moveToElement];
	p = [elm points][0];
	[npath moveToPoint: p];

	pelements = [(GSBezierPath *)path pathElements];	
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
	elm = [(GSBezierPath *)path pathElementSubdividingPathAtPoint: p 
							pathSegmentOwner: [pelements objectAtIndex: index]];
	pts = [elm points];
	[npath curveToPoint: pts[2] controlPoint1: pts[0] controlPoint2: pts[1]];
	[self appendBezierPath: npath];
}

- (void)appendBezierPathWithArcFromPoint:(NSPoint)point1
				 							toPoint:(NSPoint)point2
				  							 radius:(float)radius
{
	[self subclassResponsibility:_cmd];
}

//
// Hit detection  
// 
- (BOOL)containsPoint:(NSPoint)point
{
	if(inPath(self, point) == INTERIOR)
		return YES;

	return NO;	
}

//
// Caching
// 
- (BOOL)cachesBezierPath
{
	return cachesBezierPath;
}

- (void)setCachesBezierPath:(BOOL)flag
{
	cachesBezierPath = flag;
	if(flag)
		[self calculateDraftPolygon];
}


//
// Private Methods 
// 
- (void)calculateDraftPolygon
{
	PathElement *elm;
	NSBezierPathElement bpt;
	NSPoint p, *pts;
	double x, y, t, k = 0.025;
	float maxx, minx, maxy, miny;
	float cpmaxx, cpminx, cpmaxy, cpminy;	
	int i;

	if(![pathElements count])
		return;
		
	pts = [[pathElements objectAtIndex: 0] points];
	maxx = minx = cpmaxx = cpminx = pts[0].x;
	maxy = miny = cpmaxy = cpminy = pts[0].y;
				
	pcount = 0;
	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		bpt = [elm type];
		pts = [elm points];
		
		if(bpt == NSMoveToBezierPathElement || bpt == NSLineToBezierPathElement) {
			draftPolygon[pcount].x = pts[0].x;
			draftPolygon[pcount].y = pts[0].y;
			
			if(pts[0].x > maxx) maxx = pts[0].x;
			if(pts[0].x < minx) minx = pts[0].x;
			if(pts[0].y > maxy) maxy = pts[0].y;
			if(pts[0].y < miny) miny = pts[0].y;

			if(pts[0].x > cpmaxx) cpmaxx = pts[0].x;
			if(pts[0].x < cpminx) cpminx = pts[0].x;
			if(pts[0].y > cpmaxy) cpmaxy = pts[0].y;
			if(pts[0].y < cpminy) cpminy = pts[0].y;
			
			pcount++;
		} else if(bpt == NSCurveToBezierPathElement) {
			if(pcount) {
  				p.x = draftPolygon[pcount -1].x;
  				p.y = draftPolygon[pcount -1].y;
			} else {
  				p.x = pts[0].x;
  				p.y = pts[0].y;
			}
			
			if(pts[2].x > maxx) maxx = pts[2].x;
			if(pts[2].x < minx) minx = pts[2].x;
			if(pts[2].y > maxy) maxy = pts[2].y;
			if(pts[2].y < miny) miny = pts[2].y;
			
			if(pts[0].x > cpmaxx) cpmaxx = pts[0].x;
			if(pts[0].x < cpminx) cpminx = pts[0].x;
			if(pts[0].y > cpmaxy) cpmaxy = pts[0].y;
			if(pts[0].y < cpminy) cpminy = pts[0].y;
			if(pts[1].x > cpmaxx) cpmaxx = pts[1].x;
			if(pts[1].x < cpminx) cpminx = pts[1].x;
			if(pts[1].y > cpmaxy) cpmaxy = pts[1].y;
			if(pts[1].y < cpminy) cpminy = pts[1].y;
			if(pts[2].x > cpmaxx) cpmaxx = pts[2].x;
			if(pts[2].x < cpminx) cpminx = pts[2].x;
			if(pts[2].y > cpmaxy) cpmaxy = pts[2].y;
			if(pts[2].y < cpminy) cpminy = pts[2].y;
				
  			for(t = k; t <= 1+k; t += k) {
      		x = (p.x+t*(-p.x*3+t*(3*p.x-p.x*t)))
        			+t*(3*pts[0].x+t*(-6*pts[0].x+pts[0].x*3*t))
					+t*t*(pts[1].x*3-pts[1].x*3*t)+pts[2].x*t*t*t;
      		y = (p.y+t*(-p.y*3+t*(3*p.y-p.y*t)))
        			+t*(3*pts[0].y+t*(-6*pts[0].y+pts[0].y*3*t))
					+t*t*(pts[1].y*3-pts[1].y*3*t)+pts[2].y*t*t*t;

				draftPolygon[pcount].x = x;
				draftPolygon[pcount].y = y;
				
				if(x > maxx) maxx = x;
				if(x < minx) minx = x;
				if(y > maxy) maxy = y;
				if(y < miny) miny = y;
				
				if(x > cpmaxx) cpmaxx = x;
				if(x < cpminx) cpminx = x;
				if(y > cpmaxy) cpmaxy = y;
				if(y < cpminy) cpminy = y;
				
				pcount++;
			}
		}
	}
	
	[self setBounds: NSMakeRect(minx, miny, maxx - minx, maxy - miny)];
	[self setControlPointBounds: NSMakeRect(cpminx, cpminy, cpmaxx - cpminx, cpmaxy - cpminy)];
	isValid = NO;
}

- (void)setCurrentPoint:(NSPoint)aPoint
{
	currentPoint.x = aPoint.x;
	currentPoint.y = aPoint.y;
}

- (BOOL)isPathElement:(PathElement *)elm1 onPathElement:(PathElement *)elm2
{
	NSPoint p1, p2;
	NSBezierPathElement t;

	t = [elm1 type];
	if(t == NSMoveToBezierPathElement || t == NSLineToBezierPathElement) {
		p1.x = [elm1 points][0].x;
		p1.y = [elm1 points][0].y;
	} else if(t == NSCurveToBezierPathElement) {
		p1.x = [elm1 points][2].x;
		p1.y = [elm1 points][2].y;
	} else {
		return NO;
	}

	t = [elm2 type];
	if(t == NSMoveToBezierPathElement || t == NSLineToBezierPathElement) {
		p2.x = [elm2 points][0].x;
		p2.y = [elm2 points][0].y;
	} else if(t == NSCurveToBezierPathElement) {
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
		
	return prevelm;
}

- (NSPoint *)draftPolygon
{
	return draftPolygon;
}

- (int)pcount
{
	return pcount;
}

- (void)movePathToPoint:(NSPoint)p
{
	PathElement *elm;
	NSBezierPathElement t;
	NSPoint pp, origin, *pts;
	float diffx, diffy;
	int i, j;

	origin = [self bounds].origin;
	diffx = origin.x - p.x;
	diffy = origin.y - p.y;

	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		if(t == NSCurveToBezierPathElement) {
			for(j = 0; j < 3; j++) {
				pp.x = pts[j].x - diffx;
				pp.y = pts[j].y - diffy;
				[elm setPointAtIndex: j toPoint: pp];
			}
		} else if(t == NSMoveToBezierPathElement 
							|| t == NSLineToBezierPathElement 
									|| t == NSClosePathBezierPathElement) {
			pp.x = pts[0].x - diffx;
			pp.y = pts[0].y - diffy;
			[elm setPointAtIndex: 0 toPoint: pp];
		}	
	}
	
	[self calculateDraftPolygon];
}

- (void)rotateByAngle:(float)angle center:(NSPoint)center
{
	PathElement *elm;
	NSBezierPathElement t;
	NSPoint p, *pts;
	int i;

	for(i = 0; i < [pathElements count]; i++) {
		elm = [pathElements objectAtIndex: i];
		pts = [elm points];
		t = [elm type];
		if(t == NSCurveToBezierPathElement) {
			p = rotatePoint(pts[0], center, angle);
			[elm setPointAtIndex: 0 toPoint: p];
			p = rotatePoint(pts[1], center, angle);
			[elm setPointAtIndex: 1 toPoint: p];
			p = rotatePoint(pts[2], center, angle);
			[elm setPointAtIndex: 2 toPoint: p];
		} else if(t == NSMoveToBezierPathElement 
							|| t == NSLineToBezierPathElement 
									|| t == NSClosePathBezierPathElement) {
			p = rotatePoint(pts[0], center, angle);
			[elm setPointAtIndex: 0 toPoint: p];
		}	
	}
	[self calculateDraftPolygon];
}

- (pointOnCurve)pointOnPathSegmentOfElement:(PathElement *)elm
									  nearestToPoint:(NSPoint)p
{
	pointOnCurve pc;
	PathElement *prevelm;
	NSPoint *pp1, *pp2, cpp[4];
	double x, y, d, dmin = 10000, t, k = 0.001;
	
	prevelm = [self elementPrecedingElement: elm];
	if([prevelm type] == NSClosePathBezierPathElement)
		prevelm = [self elementPrecedingElement: prevelm];
	
	pp1 = [prevelm points];
	pp2 = [elm points];

	if([prevelm type] == NSCurveToBezierPathElement) {
		cpp[0].x = pp1[2].x;
		cpp[0].y = pp1[2].y;
	} else {
		cpp[0].x = pp1[0].x;
		cpp[0].y = pp1[0].y;
	}
	
	if([elm type] == NSCurveToBezierPathElement) {
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
	if([prevelm type] == NSClosePathBezierPathElement)
		prevelm = [self elementPrecedingElement: prevelm];
	prevpts = [prevelm points];
	ownerpts = [owner points];	
	pc = [self pointOnPathSegmentOfElement: owner nearestToPoint: p];
	
	if([prevelm type] == NSCurveToBezierPathElement) {
		coeffx[0] = prevpts[2].x;
		coeffy[0] = prevpts[2].y;
	} else {
		coeffx[0] = prevpts[0].x;
		coeffy[0] = prevpts[0].y;
	}	
	if([owner type] == NSCurveToBezierPathElement) {
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
	[elm setType: NSCurveToBezierPathElement];
	[elm setPointAtIndex: 0 toPoint: NSMakePoint(bleftx[2], blefty[2])];
	[elm setPointAtIndex: 1 toPoint: NSMakePoint(bleftx[1], blefty[1])];
	[elm setPointAtIndex: 2 toPoint: p];

	[owner setType: NSCurveToBezierPathElement];
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
	
	pts = [(GSBezierPath *)aPath draftPolygon];
	pcount = [(GSBezierPath *)aPath pcount];	
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






