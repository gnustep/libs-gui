/* 
   NSBezierPath.m

   The NSBezierPath class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Enrico Sersale <enrico@imago.ro>
   Date: Dec 1999
   Modified:  Fred Kiefer <FredKiefer@gmx.de>
   Date: January 2001
   
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

// This magic number is 4 *(sqrt(2) -1)/3
#define KAPPA 0.5522847498
#define INVALIDATE_CACHE()   [self _invalidateCache]

static void flatten(NSPoint coeff[], float flatness, NSBezierPath *path);
static Class NSBezierPath_concrete_class = nil;

static NSWindingRule default_winding_rule = NSNonZeroWindingRule;
static float default_line_width = 1.0;
static float default_flatness = 1.0;
static NSLineJoinStyle default_line_join_style = NSMiterLineJoinStyle;
static NSLineCapStyle default_line_cap_style = NSButtLineCapStyle;
static float default_miter_limit = 10.0;

@interface NSBezierPath (PrivateMethods)

- (void)_invalidateCache;
- (void)_recalculateBounds;
- (void)_doPath;

@end

@class GSBezierPath;

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
+ (id) allocWithZone: (NSZone*)z
{
  if (self != NSBezierPath_concrete_class)
    {
      return [NSBezierPath_concrete_class alloc];
    }
  else
    {
      return NSAllocateObject (self, 0, z);
    }    
}

+ (id)bezierPath
{
  return [[NSBezierPath_concrete_class alloc] init];
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
  double hdiff = width / 2 * KAPPA;
  double vdiff = height / 2 * KAPPA;
  
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
  PSrectfill(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect),  NSHeight(aRect));
}

+ (void)strokeRect:(NSRect)aRect
{
  PSrectstroke(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect),  NSHeight(aRect));
}

+ (void)clipRect:(NSRect)aRect
{
  PSrectclip(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect),  NSHeight(aRect));
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
  NSBezierPath *path = [NSBezierPath bezierPath];
  
  [path moveToPoint: aPoint];
  [path appendBezierPathWithPackedGlyphs: packedGlyphs];
  [path stroke];  
}

//
// Default path rendering parameters
//
+ (void)setDefaultMiterLimit:(float)limit
{
  default_miter_limit = limit;
  // Do we need this?
  PSsetmiterlimit(limit);
}

+ (float)defaultMiterLimit
{
  return default_miter_limit;
}

+ (void)setDefaultFlatness:(float)flatness
{
  default_flatness = flatness;
  PSsetflat(flatness);
}

+ (float)defaultFlatness
{
  return default_flatness;
}

+ (void)setDefaultWindingRule:(NSWindingRule)windingRule
{
  default_winding_rule = windingRule;
}

+ (NSWindingRule)defaultWindingRule
{
  return default_winding_rule;
}

+ (void)setDefaultLineCapStyle:(NSLineCapStyle)lineCapStyle
{
  default_line_cap_style = lineCapStyle;
  PSsetlinecap(lineCapStyle);
}

+ (NSLineCapStyle)defaultLineCapStyle
{
  return default_line_cap_style;
}

+ (void)setDefaultLineJoinStyle:(NSLineJoinStyle)lineJoinStyle
{
  default_line_join_style = lineJoinStyle;
  PSsetlinejoin(lineJoinStyle);
}

+ (NSLineJoinStyle)defaultLineJoinStyle
{
  return default_line_join_style;
}

+ (void)setDefaultLineWidth:(float)lineWidth
{
  default_line_width = lineWidth;
  PSsetlinewidth(lineWidth);
}

+ (float)defaultLineWidth
{
  return default_line_width;
}

- (id) init
{
  [super init];

  // Those values come from the default.
  [self setLineWidth: default_line_width];
  [self setFlatness: default_flatness];
  [self setLineCapStyle: default_line_cap_style];
  [self setLineJoinStyle: default_line_join_style];
  [self setMiterLimit: default_miter_limit];
  [self setWindingRule: default_winding_rule];
  // Set by allocation
  //_bounds = NSZeroRect;
  //_controlPointBounds = NSZeroRect;
  //_cachesBezierPath = NO;
  //_cacheImage = nil;
  //_dash_count = 0;
  //_dash_phase = 0;
  //_dash_pattern = NULL; 

  return self;
}

- (void) dealloc
{
  if(_cacheImage != nil)
    RELEASE(_cacheImage);

  if (_dash_pattern != NULL)
    NSZoneFree([self zone], _dash_pattern);

  [super dealloc];
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
  NSPoint p = [self currentPoint];

  p.x = p.x + aPoint.x;
  p.y = p.y + aPoint.y;
  [self moveToPoint: p];
}

- (void)relativeLineToPoint:(NSPoint)aPoint
{
  NSPoint p = [self currentPoint];

  p.x = p.x + aPoint.x;
  p.y = p.y + aPoint.y;
  [self lineToPoint: p];
}

- (void)relativeCurveToPoint:(NSPoint)aPoint
	       controlPoint1:(NSPoint)controlPoint1
	       controlPoint2:(NSPoint)controlPoint2
{
  NSPoint p = [self currentPoint];

  aPoint.x = p.x + aPoint.x;
  aPoint.y = p.y + aPoint.y;
  controlPoint1.x = p.x + controlPoint1.x;
  controlPoint1.y = p.y + controlPoint1.y;
  controlPoint2.x = p.x + controlPoint2.x;
  controlPoint2.y = p.y + controlPoint2.y;
  [self curveToPoint: aPoint
	controlPoint1: controlPoint1
	controlPoint2: controlPoint2];
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

- (void)setFlatness:(float)flatness
{
  _flatness = flatness;
}

- (float)flatness
{
  return _flatness;
}

- (void)setMiterLimit:(float)limit
{
  _miterLimit = limit;
}

- (float)miterLimit
{
  return _miterLimit;
}

- (void)getLineDash:(float *)pattern count:(int *)count phase:(float *)phase
{
  // FIXME: How big is the pattern array? 
  // We assume that this value is in count!
  if (count != NULL)
    {
      if (*count < _dash_count)
        {
	  *count = _dash_count;
	  return;
	}
      *count = _dash_count;
    }

  if (phase != NULL)
    *phase = _dash_phase;

  memcpy(pattern, _dash_pattern, _dash_count * sizeof(float));
}

- (void)setLineDash:(const float *)pattern count:(int)count phase:(float)phase
{
  NSZone *myZone = [self zone];
  
  if ( _dash_pattern == NULL)
    _dash_pattern = NSZoneMalloc(myZone, count * sizeof(float));
  else
    NSZoneRealloc(myZone, _dash_pattern, count * sizeof(float));

  _dash_count = count;
  _dash_phase = phase;
  memcpy(_dash_pattern, pattern, _dash_count * sizeof(float));
}

//
// Path operations
//
- (void)stroke
{
  if(_cachesBezierPath) 
    {
      NSRect bounds = [self bounds];
      NSPoint origin = bounds.origin;

      // FIXME: I don't see how this should work with color changes
      if(_cacheImage == nil) 
        {
	  _cacheImage = [[NSImage alloc] initWithSize: bounds.size];		
	  [_cacheImage lockFocus];
	  PStranslate(-origin.x, -origin.y);
  	  [self _doPath];
	  PSstroke();
	  [_cacheImage unlockFocus];						
	}
      [_cacheImage compositeToPoint: origin operation: NSCompositeCopy];
    } 
  else 
    {
      [self _doPath];
      PSstroke();
    }
}

- (void)fill
{
  if(_cachesBezierPath) 
    {
      NSRect bounds = [self bounds];
      NSPoint origin = bounds.origin;

      // FIXME: I don't see how this should work with color changes
      if(_cacheImage == nil) 
        {
	  _cacheImage = [[NSImage alloc] initWithSize: bounds.size];		
	  [_cacheImage lockFocus];
	  PStranslate(-origin.x, -origin.y);
	  [self _doPath];
	  if([self windingRule] == NSNonZeroWindingRule)
	    PSfill();
	  else
	    PSeofill();
	  [_cacheImage unlockFocus];
	}
      [_cacheImage compositeToPoint: origin operation: NSCompositeCopy];
    } 
  else 
    {
      [self _doPath];
      if([self windingRule] == NSNonZeroWindingRule)
	PSfill();
      else
	PSeofill();
    }
}

- (void)addClip
{
  [self _doPath];
  if([self windingRule] == NSNonZeroWindingRule)
    PSclip();
  else
    PSeoclip();
}

- (void)setClip
{
  PSinitclip();
  [self _doPath];
  if([self windingRule] == NSNonZeroWindingRule)
    PSclip();
  else
    PSeoclip();
}

//
// Path modifications.
//
- (NSBezierPath *)bezierPathByFlatteningPath
{
  NSBezierPath *path = [isa bezierPath];
  NSBezierPathElement type;
  NSPoint pts[3];
  NSPoint coeff[4];
  NSPoint p, last_p;
  int i, count;
  BOOL first = YES;

  count = [self elementCount];
  for(i = 0; i < count; i++) 
    {
      type = [self elementAtIndex: i associatedPoints: pts];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	      [path moveToPoint: pts[0]];
	      last_p = p = pts[0];
	      first = NO;
	      break;
	  case NSLineToBezierPathElement:
	      [path lineToPoint: pts[0]];
	      p = pts[0];
	      if (first)
	        {
		  last_p = pts[0];
		  first = NO;
		}
	      break;
	  case NSCurveToBezierPathElement:
	      coeff[0] = p;
	      coeff[1] = pts[0];
	      coeff[2] = pts[1];
	      coeff[3] = pts[2];
      	      flatten(coeff, [self flatness], path);
	      p = pts[2];
	      if (first)
	        {
		  last_p = pts[2];
		  first = NO;
		}
	      break;
	  case NSClosePathBezierPathElement:
	      [path closePath];
	      p = last_p;
	      break;
	  default:
	      break;
	}
    }

  return path;
}

- (NSBezierPath *) bezierPathByReversingPath
{
  NSBezierPath *path = [isa bezierPath];
  NSBezierPathElement type, last_type;
  NSPoint pts[3];
  NSPoint p, cp1, cp2;
  int i, j, count;
  BOOL closed = NO;

  last_type = NSMoveToBezierPathElement;
  count = [self elementCount];
  for(i = count - 1; i >= 0; i--) 
    {
      type = [self elementAtIndex: i associatedPoints: pts];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	      p = pts[0];
	      break;
	  case NSLineToBezierPathElement:
	      p = pts[0];
	      break;
	  case NSCurveToBezierPathElement:
	      cp1 = pts[0];
	      cp2 = pts[1];
	      p = pts[2];      
	      break;
	  case NSClosePathBezierPathElement:
	      // find the first point of segment
	      for (j = i - 1; j >= 0; j--) 
	        {
		  type = [self elementAtIndex: i associatedPoints: pts];
		  if (type == NSMoveToBezierPathElement)
		    {
		      p = pts[0];
		      break;
		    }   
		}
	      // FIXME: What to do if we don't find a move element?
	      break;
	  default:
	      break;
	}

      switch(last_type) 
        {
	  case NSMoveToBezierPathElement:
	      if (closed)
	        {
		  [path closePath];
		  closed = NO;
		}
	      [path moveToPoint: p];
	      break;
	  case NSLineToBezierPathElement:
	      [path lineToPoint: p];
	      break;
	  case NSCurveToBezierPathElement:
	      [path curveToPoint: p 
		    controlPoint1: cp2 
		    controlPoint2: cp1];	      
	      break;
	  case NSClosePathBezierPathElement:
	      closed = YES;
	      break;
	  default:
	      break;
	}
      last_type = type;
    }

  if (closed)
    [path closePath];
  return self;
}

//
// Applying transformations.
//
- (void) transformUsingAffineTransform: (NSAffineTransform *)transform
{
  NSBezierPathElement type;
  NSPoint pts[3];
  int i, count;

  count = [self elementCount];
  for(i = 0; i < count; i++) 
    {
      type = [self elementAtIndex: i associatedPoints: pts];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	  case NSLineToBezierPathElement:
	      pts[0] = [transform transformPoint: pts[0]];
	      [self setAssociatedPoints: pts atIndex: i];
	      break;
	  case NSCurveToBezierPathElement:
	      pts[0] = [transform transformPoint: pts[0]];
	      pts[1] = [transform transformPoint: pts[1]];
	      pts[2] = [transform transformPoint: pts[2]];
	      [self setAssociatedPoints: pts atIndex: i];
	      break;
	  case NSClosePathBezierPathElement:
	      break;
	  default:
	      break;
	}
    }
  INVALIDATE_CACHE();
}


//
// Path info
//
- (BOOL) isEmpty
{
  return ([self elementCount] == 0);
}

- (NSPoint) currentPoint
{
  NSBezierPathElement type;
  NSPoint points[3];
  int i, count;

  count = [self elementCount];
  if (!count) 
    [NSException raise: NSGenericException
		 format: @"No current Point in NSBezierPath"];

  type = [self elementAtIndex: count - 1 associatedPoints: points];
  switch(type) 
    {
      case NSMoveToBezierPathElement:
      case NSLineToBezierPathElement:
	  return points[0];
	  break;
      case NSCurveToBezierPathElement:
	  return points[2];
	  break;
      case NSClosePathBezierPathElement:
	  // We have to find the last move element and take its point
	  for (i = count - 2; i >= 0; i--)
	    {
	      type = [self elementAtIndex: i associatedPoints: points];
	      if (type == NSMoveToBezierPathElement)
		return points[0];
	    }
	  break;
      default:
	  break;
    }

  return NSZeroPoint;
}

- (NSRect) controlPointBounds
{
  if (_shouldRecalculateBounds)
     [self _recalculateBounds];
  return _controlPointBounds;
}

- (NSRect) bounds
{
  if (_shouldRecalculateBounds)
     [self _recalculateBounds];
  return _bounds;
}

//
// Elements
//
- (int) elementCount
{
  [self subclassResponsibility:_cmd];
  return 0;
}

- (NSBezierPathElement) elementAtIndex: (int)index
		      associatedPoints: (NSPoint *)points
{
  [self subclassResponsibility:_cmd];	
  return 0;
}

- (NSBezierPathElement) elementAtIndex: (int)index
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
- (void) appendBezierPath: (NSBezierPath *)aPath
{
  NSBezierPathElement type;
  NSPoint points[3];
  int i, count;

  count = [aPath elementCount];
  
  for (i = 0; i < count; i++)
    {
      type = [aPath elementAtIndex: i associatedPoints: points];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	      [self moveToPoint: points[0]];
	      break;
	  case NSLineToBezierPathElement:
	      [self lineToPoint: points[0]];
	      break;
	  case NSCurveToBezierPathElement:
	      [self curveToPoint: points[0] 
		    controlPoint1: points[1]
		    controlPoint2: points[2]];
	      break;
	  case NSClosePathBezierPathElement:
	      [self closePath];
	      break;
	  default:
	      break;
	}
    }
}

- (void)appendBezierPathWithRect:(NSRect)rect
{
  [self appendBezierPath: [isa bezierPathWithRect: rect]];
}

- (void)appendBezierPathWithPoints:(NSPoint *)points count:(int)count
{
  int i;

  if (!count)
    return;

  if ([self isEmpty])
    {
	[self moveToPoint: points[0]];
    }
  else
    {
	[self lineToPoint: points[0]];
    }
  
  for (i = 1; i < count; i++)
    [self lineToPoint: points[i]];
}

- (void) appendBezierPathWithOvalInRect: (NSRect)aRect
{
  [self appendBezierPath: [isa bezierPathWithOvalInRect: aRect]];
}

/* startAngle and endAngle are in degrees, counterclockwise, from the
   x axis */
- (void) appendBezierPathWithArcWithCenter: (NSPoint)center  
				    radius: (float)radius
				startAngle: (float)startAngle
				  endAngle: (float)endAngle
				 clockwise: (BOOL)clockwise
{
  float startAngle_rad, endAngle_rad, diff;
  NSPoint p0, p1, p2, p3;

  /* We use the Postscript prescription for managing the angles and
     drawing the arc.  See the documentation for `arc' and `arcn' in
     the Postscript Reference. */

  if (clockwise)
    {
      /* This modification of the angles is the postscript
         prescription. */
      while (startAngle < endAngle)
        endAngle -= 360;

      /* This is used when we draw a clockwise quarter of
	 circumference.  By adding diff at the starting angle of the
	 quarter, we get the ending angle.  diff is negative because
	 we draw clockwise. */
      diff = - PI / 2;
    }
  else
    {
      /* This modification of the angles is the postscript
         prescription. */
      while (endAngle < startAngle)
        endAngle += 360;

      /* This is used when we draw a counterclockwise quarter of
	 circumference.  By adding diff at the starting angle of the
	 quarter, we get the ending angle.  diff is positive because
	 we draw counterclockwise. */
      diff = PI / 2;
    }

  /* Convert the angles to radians */
  startAngle_rad = PI * startAngle / 180;
  endAngle_rad = PI * endAngle / 180;

  /* Start point */
  p0 = NSMakePoint (center.x + radius * cos (startAngle_rad), 
		    center.y + radius * sin (startAngle_rad));
  if ([self elementCount] == 0)
    {
      [self moveToPoint: p0];
    }
  else
    {
      NSPoint ps = [self currentPoint];
      
      if (p0.x != ps.x  ||  p0.y != ps.y)
	{
	  [self lineToPoint: p0];
	}
    }
  
  while ((clockwise) ? (startAngle_rad > endAngle_rad) 
	 : (startAngle_rad < endAngle_rad))
    {
    /* Add a quarter circle */
    if ((clockwise) ? (startAngle_rad + diff >= endAngle_rad) 
	: (startAngle_rad + diff <= endAngle_rad))
      {
	float sin_start = sin (startAngle_rad);
	float cos_start = cos (startAngle_rad);
	float sign = (clockwise) ? -1.0 : 1.0;
	
	p1 = NSMakePoint (center.x 
                           + radius * (cos_start - KAPPA * sin_start * sign), 
			  center.y 
                           + radius * (sin_start + KAPPA * cos_start * sign));
	p2 = NSMakePoint (center.x 
                           + radius * (-sin_start * sign + KAPPA * cos_start),
			  center.y 
                           + radius * (cos_start * sign + KAPPA * sin_start));
	p3 = NSMakePoint (center.x + radius * (-sin_start * sign),
			  center.y + radius *   cos_start * sign);
	
	[self curveToPoint: p3  controlPoint1: p1  controlPoint2: p2];
	startAngle_rad += diff;
      }
    else
      {
	/* Add the missing bit
	 * We require that the arc be less than a semicircle.
	 * The arc may go either clockwise or counterclockwise.
	 * The approximation is a very simple one: a single curve
	 * whose middle two control points are a fraction F of the way
	 * to the intersection of the tangents, where
	 *      F = (4/3) / (1 + sqrt (1 + (d / r)^2))
	 * where r is the radius and d is the distance from either tangent
	 * point to the intersection of the tangents. This produces
	 * a curve whose center point, as well as its ends, lies on
	 * the desired arc.
	 */
	NSPoint ps = [self currentPoint];
	/* tangent is the tangent of half the angle */
	float tangent = tan ((endAngle_rad - startAngle_rad) / 2);
	/* trad is the distance from either tangent point to the
	   intersection of the tangents */
	float trad = radius * tangent;
	/* pt is the intersection of the tangents */
	NSPoint pt = NSMakePoint (ps.x - trad * sin (startAngle_rad),
				  ps.y + trad * cos (startAngle_rad));
	/* This is F - in this expression we need to compute 
	   (trad/radius)^2, which is simply tangent^2 */
	float f = (4.0 / 3.0) / (1.0 + sqrt (1.0 +  (tangent * tangent)));
	
	p1 = NSMakePoint (ps.x + (pt.x - ps.x) * f, ps.y + (pt.y - ps.y) * f);
	p3 = NSMakePoint(center.x + radius * cos (endAngle_rad),
			 center.y + radius * sin (endAngle_rad));
	p2 = NSMakePoint (p3.x + (pt.x - p3.x) * f, p3.y + (pt.y - p3.y) * f);
	[self curveToPoint: p3  controlPoint1: p1  controlPoint2: p2];
	break;
      }
  }
}

- (void) appendBezierPathWithArcWithCenter: (NSPoint)center  
				    radius: (float)radius
				startAngle: (float)startAngle
				  endAngle: (float)endAngle
{
  [self appendBezierPathWithArcWithCenter: center  radius: radius
	startAngle: startAngle  endAngle: endAngle  clockwise: NO];
}

- (void) appendBezierPathWithArcFromPoint: (NSPoint)point1
				  toPoint: (NSPoint)point2
				   radius: (float)radius
{
  // TODO
}

- (void)appendBezierPathWithGlyph:(NSGlyph)glyph inFont:(NSFont *)font
{
  // TODO
}

- (void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
			     count:(int)count
			    inFont:(NSFont *)font
{
  // TODO
}
				 
- (void)appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs
{
  // TODO
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
//
// Caching
// 
- (BOOL)cachesBezierPath
{
  return _cachesBezierPath;
}

- (void)setCachesBezierPath:(BOOL)flag
{
  _cachesBezierPath = flag;

  if(!flag)
    INVALIDATE_CACHE();
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:(NSCoder *)aCoder
{
  NSBezierPathElement type;
  NSPoint pts[3];
  int i, count;
  float f;

  f = [self lineWidth];
  [aCoder encodeValueOfObjCType: @encode(float) at: &f];
  i = [self lineCapStyle];
  [aCoder encodeValueOfObjCType: @encode(int) at: &i];
  i = [self lineJoinStyle];
  [aCoder encodeValueOfObjCType: @encode(int) at: &i];
  i = [self windingRule];
  [aCoder encodeValueOfObjCType: @encode(int) at: &i];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_cachesBezierPath];

  count = [self elementCount];
  [aCoder encodeValueOfObjCType: @encode(int) at: &count];
  
  for(i = 0; i < count; i++) 
    {
      type = [self elementAtIndex: i associatedPoints: pts];
      [aCoder encodeValueOfObjCType: @encode(NSBezierPathElement) at: &type];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	  case NSLineToBezierPathElement:
	      [aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
	      break;
	  case NSCurveToBezierPathElement:
	      [aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
	      [aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[1]];
	      [aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[2]];
	      break;
	  case NSClosePathBezierPathElement:
	      break;
	  default:
	      break;
	}
    }
}

- (id)initWithCoder:(NSCoder *)aCoder
{
  NSBezierPathElement type;
  NSPoint pts[3];
  int i, count;
  float f;

  // We have to init the place to store the elements
  [self init];

  [aCoder decodeValueOfObjCType: @encode(float) at: &f];
  [self setLineWidth: f];
  [aCoder decodeValueOfObjCType: @encode(int) at: &i];
  [self setLineCapStyle: i];
  [aCoder decodeValueOfObjCType: @encode(int) at: &i];
  [self setLineJoinStyle: i];
  [aCoder decodeValueOfObjCType: @encode(int) at: &i];
  [self setWindingRule: i];
  [aCoder decodeValueOfObjCType: @encode(BOOL) at: &_cachesBezierPath];
  _cacheImage = nil;
  _shouldRecalculateBounds = YES;

  [aCoder decodeValueOfObjCType: @encode(int) at: &count];

  for(i = 0; i < count; i++) 
    {
      [aCoder decodeValueOfObjCType: @encode(NSBezierPathElement) at: &type];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	      [aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
	      [self moveToPoint: pts[0]];
	  case NSLineToBezierPathElement:
	      [aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
	      [self lineToPoint: pts[0]];
	      break;
	  case NSCurveToBezierPathElement:
	      [aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
	      [aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[1]];
	      [aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[2]];
	      [self curveToPoint: pts[0] controlPoint1: pts[1] controlPoint2: pts[2]];
	      break;
	  case NSClosePathBezierPathElement:
	      [self closePath];
	      break;
	  default:
	      break;
	}
    }

  return self;
}

//
// NSCopying Protocol
//
- (id)copyWithZone:(NSZone *)zone
{
  NSBezierPath *path = (NSBezierPath*)NSCopyObject (self, 0, zone);

  if(_cachesBezierPath && _cacheImage)
      path->_cacheImage = [_cacheImage copy];

  if (_dash_pattern != NULL)
    {
      float *pattern = NSZoneMalloc(zone, _dash_count * sizeof(float));

      memcpy(pattern, _dash_pattern, _dash_count * sizeof(float));
      _dash_pattern = pattern;
    }

  return path;
}

@end


@implementation NSBezierPath (PrivateMethods)

- (void) _invalidateCache
{
  _shouldRecalculateBounds = YES;
  DESTROY(_cacheImage);
}

- (void)_recalculateBounds
{
  NSBezierPathElement type;
  NSPoint p, last_p;
  NSPoint pts[3];
  // This will compute three intermediate points per curve
  double x, y, t, k = 0.25;
  float maxx, minx, maxy, miny;
  float cpmaxx, cpminx, cpmaxy, cpminy;	
  int i, count;
  BOOL first = YES;
  
  count = [self elementCount];
  if(!count)
    {
      _bounds = NSZeroRect;
      _controlPointBounds = NSZeroRect;
      return;
    }

  // Some big starting values
  maxx = maxy = cpmaxx = cpmaxy = -1E9;
  minx = miny = cpminx = cpminy = 1E9;

  for(i = 0; i < count; i++) 
    {
      type = [self elementAtIndex: i associatedPoints: pts];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	      last_p = pts[0];
	      // NO BREAK
	  case NSLineToBezierPathElement:
	      if (first)
	        {
		  maxx = minx = cpmaxx = cpminx = pts[0].x;
		  maxy = miny = cpmaxy = cpminy = pts[0].y;
		  last_p = pts[0];
		  first = NO;
		}
	      else
	      {
	        if(pts[0].x > maxx) maxx = pts[0].x;
		if(pts[0].x < minx) minx = pts[0].x;
		if(pts[0].y > maxy) maxy = pts[0].y;
		if(pts[0].y < miny) miny = pts[0].y;
		
		if(pts[0].x > cpmaxx) cpmaxx = pts[0].x;
		if(pts[0].x < cpminx) cpminx = pts[0].x;
		if(pts[0].y > cpmaxy) cpmaxy = pts[0].y;
		if(pts[0].y < cpminy) cpminy = pts[0].y;
	      }

	      p = pts[0];
	      break;

	  case NSCurveToBezierPathElement:
	      if (first)
	        {
		  maxx = minx = cpmaxx = cpminx = pts[0].x;
		  maxy = miny = cpmaxy = cpminy = pts[0].y;
		  p = last_p = pts[0];
		  first = NO;
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
	      
	      for(t = k; t <= 1+k; t += k) 
	        {
		  x = (p.x+t*(-p.x*3+t*(3*p.x-p.x*t)))+
		      t*(3*pts[0].x+t*(-6*pts[0].x+pts[0].x*3*t))+
		      t*t*(pts[1].x*3-pts[1].x*3*t)+pts[2].x*t*t*t;
		  y = (p.y+t*(-p.y*3+t*(3*p.y-p.y*t)))+
		      t*(3*pts[0].y+t*(-6*pts[0].y+pts[0].y*3*t))+
		      t*t*(pts[1].y*3-pts[1].y*3*t)+pts[2].y*t*t*t;
		  
		  if(x > cpmaxx) cpmaxx = x;
		  if(x < cpminx) cpminx = x;
		  if(y > cpmaxy) cpmaxy = y;
		  if(y < cpminy) cpminy = y;
		}

	      p = pts[2];
	      break;

	  case NSClosePathBezierPathElement:
	      // This does not add to the bounds, but changes the current point
	      p = last_p;
	      break;
	  default:
	      break;
	}
    }
  
  _bounds = NSMakeRect(minx, miny, maxx - minx, maxy - miny);
  _controlPointBounds = NSMakeRect(cpminx, cpminy, cpmaxx - cpminx, cpmaxy - cpminy);
  _shouldRecalculateBounds = NO;
}

- (void)_doPath
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSBezierPathElement type;
  NSPoint pts[3];
  int i, count;
  float pattern[10];
  float phase;

  DPSnewpath(ctxt);
  DPSsetlinewidth(ctxt, [self lineWidth]);
  DPSsetlinejoin(ctxt, [self lineJoinStyle]);
  DPSsetlinecap(ctxt, [self lineCapStyle]);
  DPSsetmiterlimit(ctxt, [self miterLimit]);
  DPSsetflat(ctxt, [self flatness]);

  [self getLineDash: pattern count: &count phase: &phase];
  if (count != 0 && count < 10)
    DPSsetdash(ctxt, pattern, count, phase);

  count = [self elementCount];
  for(i = 0; i < count; i++) 
    {
      type = [self elementAtIndex: i associatedPoints: pts];
      switch(type) 
        {
	  case NSMoveToBezierPathElement:
	      DPSmoveto(ctxt, pts[0].x, pts[0].y);
	      break;
	  case NSLineToBezierPathElement:
	      DPSlineto(ctxt, pts[0].x, pts[0].y);
	      break;
	  case NSCurveToBezierPathElement:
	      DPScurveto(ctxt, pts[0].x, pts[0].y, 
			 pts[1].x, pts[1].y, pts[2].x, pts[2].y);
	      break;
	  case NSClosePathBezierPathElement:
	      DPSclosepath(ctxt);
	      break;
	  default:
	      break;
	}
    }
}

@end


typedef struct _PathElement
{
  NSBezierPathElement type;
  NSPoint points[3];
} PathElement;

//#define GSUNION_TYPES GSUNION_OBJ
#define GSI_ARRAY_TYPES       0
#define GSI_ARRAY_EXTRA       PathElement

#define GSI_ARRAY_NO_RETAIN
#define GSI_ARRAY_NO_RELEASE

#ifdef GSIArray
#undef GSIArray
#endif
#include <base/GSIArray.h>

@interface GSBezierPath : NSBezierPath
{
  GSIArray pathElements;
  BOOL flat;
}

@end

@implementation GSBezierPath

- (id)init
{
  NSZone *zone;

  self = [super init];
  zone = GSObjCZone(self);
  pathElements = NSZoneMalloc(zone, sizeof(GSIArray_t));
  GSIArrayInitWithZoneAndCapacity(pathElements, zone, 8);
  flat = YES;

  return self;
}

- (void)dealloc
{
  GSIArrayEmpty(pathElements);
  NSZoneFree(GSObjCZone(self), pathElements);
  [super dealloc];
}

//
// Path construction
//
- (void)moveToPoint:(NSPoint)aPoint
{
  PathElement elem;
  
  elem.type = NSMoveToBezierPathElement;
  elem.points[0] = aPoint;
  GSIArrayAddItem(pathElements, (GSIArrayItem)elem);
  INVALIDATE_CACHE();
}

- (void)lineToPoint:(NSPoint)aPoint
{
  PathElement elem;
  
  elem.type = NSLineToBezierPathElement;
  elem.points[0] = aPoint;
  GSIArrayAddItem(pathElements, (GSIArrayItem)elem);
  INVALIDATE_CACHE();
}

- (void) curveToPoint: (NSPoint)aPoint 
	controlPoint1: (NSPoint)controlPoint1
	controlPoint2: (NSPoint)controlPoint2
{
  PathElement elem;
  
  elem.type = NSCurveToBezierPathElement;
  elem.points[0] = controlPoint1;
  elem.points[1] = controlPoint2;
  elem.points[2] = aPoint;
  GSIArrayAddItem(pathElements, (GSIArrayItem)elem);
  flat = NO;

  INVALIDATE_CACHE();
}

- (void)closePath
{
  PathElement elem;

  elem.type = NSClosePathBezierPathElement;
  GSIArrayAddItem(pathElements, (GSIArrayItem)elem);
  INVALIDATE_CACHE();
}

- (void)removeAllPoints
{
  GSIArrayRemoveAllItems(pathElements);
  INVALIDATE_CACHE();
}

//
// Elements
//
- (int)elementCount
{
  return GSIArrayCount(pathElements);
}

- (NSBezierPathElement)elementAtIndex:(int)index
		     associatedPoints:(NSPoint *)points
{
  PathElement elm = GSIArrayItemAtIndex(pathElements, index).ext;
  NSBezierPathElement type = elm.type;
	
  if (points != NULL) 
    {
      if(type == NSMoveToBezierPathElement || type == NSLineToBezierPathElement) 
        {
	  points[0] = elm.points[0];
	} 
      else if(type == NSCurveToBezierPathElement) 
        {
	  points[0] = elm.points[0];
	  points[1] = elm.points[1];
	  points[2] = elm.points[2];
	}
    }
  
  return type;
}

- (void)setAssociatedPoints:(NSPoint *)points atIndex:(int)index
{
  PathElement elm = GSIArrayItemAtIndex(pathElements, index).ext;
  NSBezierPathElement type = elm.type;
  
  switch(type) 
    {
      case NSMoveToBezierPathElement:
      case NSLineToBezierPathElement:
	  elm.points[0] = points[0];
	  break;
      case NSCurveToBezierPathElement:
	  elm.points[0] = points[0];
	  elm.points[1] = points[1];
	  elm.points[2] = points[2];
	  break;
      case NSClosePathBezierPathElement:
	  break;
      default:
	  break;
    }

  GSIArraySetItemAtIndex(pathElements, (GSIArrayItem)elm, index);
  INVALIDATE_CACHE();
}

//
// Path modifications.
//
- (NSBezierPath *)bezierPathByFlatteningPath
{
  if (flat)
    return self;

  return [super bezierPathByFlatteningPath];
}

//
// NSCopying Protocol
//
- (id)copyWithZone:(NSZone *)zone
{
  GSBezierPath *path = [super copyWithZone: zone];
	
  path->pathElements = GSIArrayCopyWithZone(pathElements, zone);

  return path;
}

//
// Hit detection  
// 
#define PMAX 10000

- (BOOL)containsPoint:(NSPoint)point
{
  NSPoint draftPolygon[PMAX];
  int pcount = 0;
  // Coordinates of the current point
  double cx, cy;
  // Coordinates of the last point
  double lx, ly;
  int i;
  int Rcross = 0;
  int Lcross = 0;	
  NSBezierPathElement bpt;
  NSPoint p, pts[3];
  double x, y, t, k = 0.25;
  int count = [self elementCount];

  if(!count)
    return NO;
		
  if (!NSPointInRect(point, [self bounds]))
    return NO;

  // FIXME: This does not handle multiple segments!
  for(i = 0; i < count; i++) 
    {
      bpt = [self elementAtIndex: i associatedPoints: pts];
      
      if(bpt == NSMoveToBezierPathElement || bpt == NSLineToBezierPathElement) 
        {
	  draftPolygon[pcount].x = pts[0].x;
	  draftPolygon[pcount].y = pts[0].y;
	  
	  pcount++;
	} 
      else if(bpt == NSCurveToBezierPathElement) 
        {
	  if(pcount) 
	    {
	      p.x = draftPolygon[pcount -1].x;
	      p.y = draftPolygon[pcount -1].y;
	    } 
	  else 
	    {
	      p.x = pts[0].x;
	      p.y = pts[0].y;
	    }
				
	  for(t = k; t <= 1+k; t += k) 
	    {
      	      x = (p.x+t*(-p.x*3+t*(3*p.x-p.x*t)))+
		  t*(3*pts[0].x+t*(-6*pts[0].x+pts[0].x*3*t))+
		  t*t*(pts[1].x*3-pts[1].x*3*t)+pts[2].x*t*t*t;
	      y = (p.y+t*(-p.y*3+t*(3*p.y-p.y*t)))+
		  t*(3*pts[0].y+t*(-6*pts[0].y+pts[0].y*3*t))+
		  t*t*(pts[1].y*3-pts[1].y*3*t)+pts[2].y*t*t*t;
	      
	      draftPolygon[pcount].x = x;
	      draftPolygon[pcount].y = y;
	      pcount++;
	    }
	}

      // Simple overflow check
      if (pcount == PMAX)
	return NO;
    }  

  lx = draftPolygon[pcount - 1].x - point.x;
  ly = draftPolygon[pcount - 1].y - point.y;
  for(i = 0; i < pcount; i++) 
    {
      cx = draftPolygon[i].x - point.x;
      cy = draftPolygon[i].y - point.y;
      if(cx == 0 && cy == 0) 
	// on a vertex
	return NO;
					
      if((cy > 0)  && !(ly > 0)) 
        {
	  if (((cx * ly - lx * cy) / (ly - cy)) > 0)
	    Rcross++;
	}
      if((cy < 0 ) && !(ly < 0)) 
        { 
	  if (((cx * ly - lx * cy) / (ly - cy)) < 0);
	    Lcross++;		
	}
      lx = cx;
      ly = cy;
    }

  if((Rcross % 2) != (Lcross % 2))
    // On the border
    return NO;
  if((Rcross % 2) == 1)
    return YES;
  else	
    return NO;
}

@end // GSBezierPath


static void flatten(NSPoint coeff[], float flatness, NSBezierPath *path)
{
  // Check if the Bezier path defined by the four points has the given flatness.
  // If not split it up in the middle and recurse. 
  // Otherwise add the end point to the path.
  BOOL flat = YES;

  // This criteria for flatness is based on code from Libart which has the 
  // following copyright:
/* Libart_LGPL - library of basic graphic primitives
 * Copyright (C) 1998 Raph Levien
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

  double x1_0, y1_0;
  double x3_2, y3_2;
  double x3_0, y3_0;
  double z3_0_dot;
  double z1_dot, z2_dot;
  double z1_perp, z2_perp;
  double max_perp_sq;

  x3_0 = coeff[3].x - coeff[0].x;
  y3_0 = coeff[3].y - coeff[0].y;
  x3_2 = coeff[3].x - coeff[2].x;
  y3_2 = coeff[3].y - coeff[2].y;
  x1_0 = coeff[1].x - coeff[0].x;
  y1_0 = coeff[1].y - coeff[0].y;
  z3_0_dot = x3_0 * x3_0 + y3_0 * y3_0;

  if (z3_0_dot < 0.001)
    flat = YES;
  else
    {
      max_perp_sq = flatness * flatness * z3_0_dot;

      z1_perp = y1_0 * x3_0 - x1_0 * y3_0;
      if (z1_perp * z1_perp > max_perp_sq)
	flat = NO;
      else
        {
	  z2_perp = y3_2 * x3_0 - x3_2 * y3_0;
	  if (z2_perp * z2_perp > max_perp_sq)
	      flat = NO;
	  else
	    {
	      z1_dot = x1_0 * x3_0 + y1_0 * y3_0;
	      if (z1_dot < 0 && z1_dot * z1_dot > max_perp_sq)
		flat = NO;
	      else
	        {
		  z2_dot = x3_2 * x3_0 + y3_2 * y3_0;
		  if (z2_dot < 0 && z2_dot * z2_dot > max_perp_sq)
		      flat = NO;
		  else
		    {
		      if ((z1_dot + z1_dot > z3_0_dot) ||
			  (z2_dot + z2_dot > z3_0_dot))
			flat = NO;
		    }
		}
	    }
	}
    }

  if (!flat)
    {
      NSPoint bleft[4], bright[4];
	
      bleft[0] = coeff[0];
      bleft[1].x = (coeff[0].x + coeff[1].x) / 2;
      bleft[1].y = (coeff[0].y + coeff[1].y) / 2;
      bleft[2].x = (coeff[0].x + 2*coeff[1].x + coeff[2].x) / 4;
      bleft[2].y = (coeff[0].y + 2*coeff[1].y + coeff[2].y) / 4;
      bleft[3].x = (coeff[0].x + 3*(coeff[1].x + coeff[2].x) + coeff[3].x) / 8;
      bleft[3].y = (coeff[0].y + 3*(coeff[1].y + coeff[2].y) + coeff[3].y) / 8;
      bright[0].x =  bleft[3].x;
      bright[0].y =  bleft[3].y;
      bright[1].x = (coeff[3].x + 2*coeff[2].x + coeff[1].x) / 4;
      bright[1].y = (coeff[3].y + 2*coeff[2].y + coeff[1].y) / 4;
      bright[2].x = (coeff[3].x + coeff[2].x) / 2;
      bright[2].y = (coeff[3].y + coeff[2].y) / 2;
      bright[3] = coeff[3];

      flatten(bleft, flatness, path);
      flatten(bright, flatness, path);
    }
  else
    {
      //[path lineToPoint: coeff[1]];
      //[path lineToPoint: coeff[2]];
      [path lineToPoint: coeff[3]];
    }
}

