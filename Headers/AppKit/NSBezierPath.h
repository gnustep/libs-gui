/*
   The NSBezierPath class

   Copyright (C) 1999, 2005 Free Software Foundation, Inc.

   Author:  Enrico Sersale
   Date: Dec 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

/**
 * <title>NSBezierPath</title>
 * <abstract>Vector graphics path construction and drawing</abstract>
 *
 * NSBezierPath provides a comprehensive interface for creating, manipulating,
 * and rendering vector graphics paths using cubic Bézier curves. The class
 * supports path construction through moveTo/lineTo/curveTo operations, common
 * geometric shapes (rectangles, ovals, arcs), and text glyph outlines.
 *
 * Key features include:
 * - Path construction with moveTo, lineTo, curveToPoint operations
 * - Geometric shape creation (rectangles, ovals, arcs, rounded rectangles)
 * - Stroke and fill rendering with customizable line styles
 * - Hit testing and point containment with winding rules
 * - Path transformation and combination operations
 * - Text glyph path generation for custom text rendering
 * - Performance optimizations through path caching
 *
 * The class provides both immediate drawing methods (fillRect:, strokeRect:)
 * for simple operations and instance-based path building for complex shapes.
 * Line appearance is controlled through cap styles, join styles, dash patterns,
 * and stroke width settings. Fill behavior follows either non-zero or even-odd
 * winding rules for determining interior points.
 *
 * NSBezierPath integrates with the graphics context system for coordinate
 * transformations and clipping operations, making it suitable for both
 * simple drawing tasks and sophisticated vector graphics applications.
 */

#ifndef BEZIERPATH_H
#define BEZIERPATH_H
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>
#import <AppKit/NSFont.h>

@class NSAffineTransform;
@class NSImage;

typedef enum {
  NSButtLineCapStyle = 0,
  NSRoundLineCapStyle = 1,
  NSSquareLineCapStyle = 2,
  #if OS_API_VERSION(MAC_OS_X_VERSION_10_14, GS_API_LATEST)
  NSLineCapStyleButt = 0,
  NSLineCapStyleRound = 1,
  NSLineCapStyleSquare = 2
  #endif
} NSLineCapStyle;

typedef enum {
  NSMiterLineJoinStyle = 0,
  NSRoundLineJoinStyle = 1,
  NSBevelLineJoinStyle = 2,
  #if OS_API_VERSION(MAC_OS_X_VERSION_10_14, GS_API_LATEST)
  NSLineJoinStyleMiter = 0,
  NSLineJoinStyleRound = 1,
  NSLineJoinStyleBevel = 2
  #endif
} NSLineJoinStyle;

/** A winding rule defines which points are considered inside and which
    points are considered outside a path.
    <deflist>
      <term>NSNonZeroWindingRule</term>
      <desc>Deprecated. Use NSWindingRuleNonZero instead.</desc>
      <term>NSEvenOddWindingRule</term>
      <desc>Deprecated. Use NSWindingRuleEvenOdd instead.</desc>
      <term>NSWindingRuleNonZero</term>
      <desc>A point is inside the path iff the winding count at the point
      is non-zero.</desc>
      <term>NSWindingRuleEvenOdd</term>
      <desc>A point is inside the path iff the winding count at the point
      is odd.</desc>
    </deflist>
    */
typedef enum {
  NSNonZeroWindingRule = 0,
  NSEvenOddWindingRule = 1,
  #if OS_API_VERSION(MAC_OS_X_VERSION_10_14, GS_API_LATEST)
  NSWindingRuleNonZero = 0,
  NSWindingRuleEvenOdd = 1
  #endif
} NSWindingRule;

typedef enum {
  NSMoveToBezierPathElement = 0,
  NSLineToBezierPathElement = 1,
  NSCurveToBezierPathElement = 2,
  NSClosePathBezierPathElement = 3,
  #if OS_API_VERSION(MAC_OS_X_VERSION_10_14, GS_API_LATEST)
  NSBezierPathElementMoveTo = 0,
  NSBezierPathElementLineTo = 1,
  NSBezierPathElementCurveTo = 2,
  NSBezierPathElementClosePath = 3
  #endif
} NSBezierPathElement;

APPKIT_EXPORT_CLASS
@interface NSBezierPath : NSObject <NSCopying, NSCoding>
{
@private
  NSWindingRule _windingRule;
  NSLineCapStyle _lineCapStyle;
  NSLineJoinStyle _lineJoinStyle;
  CGFloat _lineWidth;
  CGFloat _flatness;
  CGFloat _miterLimit;
  NSInteger _dash_count;
  CGFloat _dash_phase;
  CGFloat *_dash_pattern;
  NSRect _bounds;
  NSRect _controlPointBounds;
  NSImage *_cacheImage;
#ifndef	_IN_NSBEZIERPATH_M
#define	GSIArray	void*
#endif
  GSIArray _pathElements;
#ifndef	_IN_NSBEZIERPATH_M
#undef	GSIArray
#endif
  BOOL _cachesBezierPath;
  BOOL _shouldRecalculateBounds;
  BOOL _flat;
}

//
// Creating common paths
//

/**
 * Creates and returns an empty bezier path.
 * Returns: A new autoreleased NSBezierPath instance with no path elements.
 */
+ (NSBezierPath *)bezierPath;

/**
 * Creates a rectangular bezier path.
 * aRect: The rectangle to create the path from
 * Returns: A new autoreleased NSBezierPath containing the rectangle
 */
+ (NSBezierPath *)bezierPathWithRect:(NSRect)aRect;

/**
 * Creates an oval bezier path inscribed in the given rectangle.
 * aRect: The rectangle in which to inscribe the oval
 * Returns: A new autoreleased NSBezierPath containing the oval
 */
+ (NSBezierPath *)bezierPathWithOvalInRect:(NSRect)aRect;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 * Creates a rounded rectangle bezier path.
 * aRect: The rectangle to create the rounded path from
 * xRadius: The horizontal radius for the rounded corners
 * yRadius: The vertical radius for the rounded corners
 * Returns: A new autoreleased NSBezierPath containing the rounded rectangle
 */
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)aRect
                                    xRadius:(CGFloat)xRadius
                                    yRadius:(CGFloat)yRadius;
#endif

//
// Immediate mode drawing of common paths
//

/**
 * Fills a rectangle using the default fill color.
 * aRect: The rectangle to fill
 */
+ (void)fillRect:(NSRect)aRect;

/** Using default stroke color and default drawing attributes, strokes
    a rectangle using the specified rect. */
+ (void)strokeRect:(NSRect)aRect;

/**
 * Sets the clipping region to the specified rectangle.
 * aRect: The rectangle to use as the clipping region
 */
+ (void)clipRect:(NSRect)aRect;

/** Using default stroke color and default drawing attributes, draws a line
    between the two points specified. */
+ (void)strokeLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2;

/**
 * Draws packed glyph data at the specified point.
 * packedGlyphs: The packed glyph data to draw
 * aPoint: The point at which to draw the glyphs
 */
+ (void)drawPackedGlyphs: (const char *)packedGlyphs atPoint: (NSPoint)aPoint;

//
// Default path rendering parameters
//

/**
 * Sets the default miter limit for new bezier paths.
 * limit: The miter limit value (must be >= 1.0)
 */
+ (void)setDefaultMiterLimit:(CGFloat)limit;

/**
 * Returns the default miter limit for new bezier paths.
 * Returns: The current default miter limit value
 */
+ (CGFloat)defaultMiterLimit;

/**
 * Sets the default flatness for new bezier paths.
 * flatness: The flatness value for curve approximation
 */
+ (void)setDefaultFlatness:(CGFloat)flatness;

/**
 * Returns the default flatness for new bezier paths.
 * Returns: The current default flatness value
 */
+ (CGFloat)defaultFlatness;

/**
 * Sets the default winding rule for new bezier paths.
 * windingRule: The winding rule to use for fill operations
 */
+ (void)setDefaultWindingRule:(NSWindingRule)windingRule;

/**
 * Returns the default winding rule for new bezier paths.
 * Returns: The current default winding rule
 */
+ (NSWindingRule)defaultWindingRule;

/**
 * Sets the default line cap style for new bezier paths.
 * lineCapStyle: The line cap style for path endpoints
 */
+ (void)setDefaultLineCapStyle:(NSLineCapStyle)lineCapStyle;

/**
 * Returns the default line cap style for new bezier paths.
 * Returns: The current default line cap style
 */
+ (NSLineCapStyle)defaultLineCapStyle;

/**
 * Sets the default line join style for new bezier paths.
 * lineJoinStyle: The line join style for path corners
 */
+ (void)setDefaultLineJoinStyle:(NSLineJoinStyle)lineJoinStyle;

/**
 * Returns the default line join style for new bezier paths.
 * Returns: The current default line join style
 */
+ (NSLineJoinStyle)defaultLineJoinStyle;

/**
 * Sets the default line width for new bezier paths.
 * lineWidth: The line width for stroked paths
 */
+ (void)setDefaultLineWidth:(CGFloat)lineWidth;

/**
 * Returns the default line width for new bezier paths.
 * Returns: The current default line width
 */
+ (CGFloat)defaultLineWidth;

//
// Path construction
//

/**
 * Moves the current path point to the specified location.
 * aPoint: The point to move to
 */
- (void)moveToPoint:(NSPoint)aPoint;

/**
 * Appends a straight line from the current point to the specified point.
 * aPoint: The endpoint of the line segment
 */
- (void)lineToPoint:(NSPoint)aPoint;

/**
 * Appends a cubic Bézier curve from the current point to the specified endpoint.
 * aPoint: The endpoint of the curve
 * controlPoint1: The first control point
 * controlPoint2: The second control point
 */
- (void)curveToPoint:(NSPoint)aPoint
       controlPoint1:(NSPoint)controlPoint1
       controlPoint2:(NSPoint)controlPoint2;

/**
 * Closes the current subpath by drawing a straight line to the starting point.
 */
- (void)closePath;

/**
 * Removes all path elements, creating an empty path.
 */
- (void)removeAllPoints;

//
// Relative path construction
//

/**
 * Moves the current path point by the specified offset.
 * aPoint: The relative offset to move by
 */
- (void)relativeMoveToPoint:(NSPoint)aPoint;

/**
 * Appends a straight line from the current point by the specified offset.
 * aPoint: The relative endpoint offset
 */
- (void)relativeLineToPoint:(NSPoint)aPoint;

/**
 * Appends a cubic Bézier curve using relative coordinates.
 * aPoint: The relative endpoint offset
 * controlPoint1: The first control point offset
 * controlPoint2: The second control point offset
 */
- (void)relativeCurveToPoint:(NSPoint)aPoint
	       controlPoint1:(NSPoint)controlPoint1
	       controlPoint2:(NSPoint)controlPoint2;

//
// Path rendering parameters
//

/**
 * Returns the line width for stroking the path.
 * Returns: The current line width
 */
- (CGFloat)lineWidth;

/**
 * Sets the line width for stroking the path.
 * lineWidth: The new line width
 */
- (void)setLineWidth:(CGFloat)lineWidth;

/**
 * Returns the line cap style for path endpoints.
 * Returns: The current line cap style
 */
- (NSLineCapStyle)lineCapStyle;

/**
 * Sets the line cap style for path endpoints.
 * lineCapStyle: The new line cap style
 */
- (void)setLineCapStyle:(NSLineCapStyle)lineCapStyle;

/**
 * Returns the line join style for path corners.
 * Returns: The current line join style
 */
- (NSLineJoinStyle)lineJoinStyle;

/**
 * Sets the line join style for path corners.
 * lineJoinStyle: The new line join style
 */
- (void)setLineJoinStyle:(NSLineJoinStyle)lineJoinStyle;

/**
 * Returns the winding rule used for fill operations.
 * Returns: The current winding rule
 */
- (NSWindingRule)windingRule;

/**
 * Sets the winding rule used for fill operations.
 * windingRule: The new winding rule
 */
- (void)setWindingRule:(NSWindingRule)windingRule;

/**
 * Sets the flatness value for curve approximation.
 * flatness: The flatness value (smaller values create smoother curves)
 */
- (void)setFlatness:(CGFloat)flatness;

/**
 * Returns the flatness value for curve approximation.
 * Returns: The current flatness value
 */
- (CGFloat)flatness;

/**
 * Sets the miter limit for line joins.
 * limit: The miter limit value (must be >= 1.0)
 */
- (void)setMiterLimit:(CGFloat)limit;

/**
 * Returns the miter limit for line joins.
 * Returns: The current miter limit value
 */
- (CGFloat)miterLimit;

/**
 * Gets the current dash pattern, count, and phase.
 * pattern: Array to fill with dash pattern values (may be NULL)
 * count: Pointer to store the number of dash elements
 * phase: Pointer to store the dash phase offset
 */
- (void)getLineDash:(CGFloat *)pattern count:(NSInteger *)count phase:(CGFloat *)phase;

/**
 * Sets the dash pattern for stroking the path.
 * pattern: Array of dash lengths (alternating stroke and gap lengths)
 * count: Number of elements in the pattern array
 * phase: Offset into the dash pattern at which to start
 */
- (void)setLineDash:(const CGFloat *)pattern count:(NSInteger)count phase:(CGFloat)phase;

//
// Path operations
//

/**
 * Strokes the path using the current stroke color and line attributes.
 */
- (void)stroke;

/**
 * Fills the path using the current fill color and winding rule.
 */
- (void)fill;

/**
 * Intersects the current clipping region with the area enclosed by the path.
 */
- (void)addClip;

/**
 * Sets the clipping region to the area enclosed by the path.
 */
- (void)setClip;

//
// Path modifications.
//

/**
 * Returns a flattened copy of the path with all curves converted to line segments.
 * Returns: A new NSBezierPath with curves approximated by straight lines
 */
- (NSBezierPath *)bezierPathByFlatteningPath;

/**
 * Returns a copy of the path with all subpaths reversed.
 * Returns: A new NSBezierPath with reversed element order
 */
- (NSBezierPath *)bezierPathByReversingPath;

//
// Applying transformations.
//

/**
 * Transforms all points in the path using the given affine transformation.
 * transform: The NSAffineTransform to apply to the path
 */
- (void)transformUsingAffineTransform:(NSAffineTransform *)transform;

//
// Path info
//

/**
 * Returns whether the path contains any elements.
 * Returns: YES if the path is empty, NO otherwise
 */
- (BOOL)isEmpty;

/**
 * Returns the current point in the path (the last point added).
 * Returns: The current path point
 */
- (NSPoint)currentPoint;

/**
 * Returns the smallest rectangle containing all control points.
 * Returns: The bounding rectangle of all control points
 */
- (NSRect)controlPointBounds;

/**
 * Returns the smallest rectangle containing the rendered path.
 * Returns: The bounding rectangle of the filled/stroked path
 */
- (NSRect)bounds;

//
// Elements
//

/**
 * Returns the number of path elements in the path.
 * Returns: The count of path elements (moveTo, lineTo, curveTo, closePath)
 */
- (NSInteger)elementCount;

/**
 * Returns the type of path element at the given index and its associated points.
 * index: The zero-based index of the element
 * points: Array to fill with associated points (may be NULL)
 * Returns: The type of path element at the specified index
 */
- (NSBezierPathElement)elementAtIndex:(NSInteger)index
		     associatedPoints:(NSPoint *)points;

/**
 * Returns the type of path element at the given index.
 * index: The zero-based index of the element
 * Returns: The type of path element at the specified index
 */
- (NSBezierPathElement)elementAtIndex:(NSInteger)index;

/**
 * Sets the associated points for the path element at the given index.
 * points: Array of points to associate with the element
 * index: The zero-based index of the element
 */
- (void)setAssociatedPoints:(NSPoint *)points atIndex:(NSInteger)index;

//
// Appending common paths
//

/**
 * Appends all elements from another bezier path to this path.
 * aPath: The bezier path whose elements to append
 */
- (void)appendBezierPath:(NSBezierPath *)aPath;

/**
 * Appends a rectangular path to this path.
 * aRect: The rectangle to append
 */
- (void)appendBezierPathWithRect:(NSRect)aRect;

/**
 * Appends a path connecting the given points with straight lines.
 * points: Array of points to connect
 * count: Number of points in the array
 */
- (void)appendBezierPathWithPoints:(NSPoint *)points count:(NSInteger)count;

/**
 * Appends an oval path inscribed in the given rectangle.
 * aRect: The rectangle in which to inscribe the oval
 */
- (void)appendBezierPathWithOvalInRect:(NSRect)aRect;

/**
 * Appends an arc to the path with specified parameters and direction.
 * center: The center point of the arc
 * radius: The radius of the arc
 * startAngle: The starting angle in degrees
 * endAngle: The ending angle in degrees
 * clockwise: YES for clockwise direction, NO for counterclockwise
 */
- (void)appendBezierPathWithArcWithCenter:(NSPoint)center
				   radius:(CGFloat)radius
			       startAngle:(CGFloat)startAngle
				 endAngle:(CGFloat)endAngle
				clockwise:(BOOL)clockwise;

/**
 * Appends an arc to the path (counterclockwise by default).
 * center: The center point of the arc
 * radius: The radius of the arc
 * startAngle: The starting angle in degrees
 * endAngle: The ending angle in degrees
 */
- (void)appendBezierPathWithArcWithCenter:(NSPoint)center
				   radius:(CGFloat)radius
			       startAngle:(CGFloat)startAngle
				 endAngle:(CGFloat)endAngle;

/**
 * Appends an arc that is tangent to two lines defined by three points.
 * point1: The first point defining the first line
 * point2: The second point (shared between both lines)
 * radius: The radius of the arc
 */
- (void)appendBezierPathWithArcFromPoint:(NSPoint)point1
				 toPoint:(NSPoint)point2
				  radius:(CGFloat)radius;

/**
 * Appends the outline of a single glyph to the path.
 * glyph: The glyph to append
 * font: The font containing the glyph
 */
- (void)appendBezierPathWithGlyph:(NSGlyph)glyph inFont:(NSFont *)font;

/**
 * Appends the outlines of multiple glyphs to the path.
 * glyphs: Array of glyphs to append
 * count: Number of glyphs in the array
 * font: The font containing the glyphs
 */
- (void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs
			     count:(NSInteger)count
			    inFont:(NSFont *)font;

/**
 * Appends glyph outlines from packed glyph data.
 * packedGlyphs: The packed glyph data
 */
- (void)appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 * Appends a rounded rectangle to the path.
 * aRect: The rectangle to append
 * xRadius: The horizontal radius for the rounded corners
 * yRadius: The vertical radius for the rounded corners
 */
- (void)appendBezierPathWithRoundedRect:(NSRect)aRect
                                xRadius:(CGFloat)xRadius
                                yRadius:(CGFloat)yRadius;
#endif

//
// Hit detection
//

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/** Returns the winding count, according to the PostScript definition,
    at the given point.  */
- (int) windingCountAtPoint: (NSPoint)point;
#endif

/** Returns YES iff the path contains, according to the current
    <ref type="type" id="NSWindingRule">winding rule</ref>, the given point.
    */
- (BOOL)containsPoint:(NSPoint)point;

//
// Caching
//

/**
 * Returns whether the path caches its bezier path data for performance.
 * Returns: YES if caching is enabled, NO otherwise
 */
- (BOOL)cachesBezierPath;

/**
 * Sets whether the path should cache its bezier path data for performance.
 * flag: YES to enable caching, NO to disable it
 */
- (void)setCachesBezierPath:(BOOL)flag;

@end

#endif // BEZIERPATH_H
