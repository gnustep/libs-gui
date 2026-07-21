/* Coverage for NSBezierPath areas not exercised by basic.m / bounds.m /
 * windingCountAtPoint.m: the append helpers and elementAtIndex:associatedPoints:,
 * containsPoint:, transformUsingAffineTransform:, relative moves, the empty /
 * current-point state and the line attributes.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSBezierPath.h>
#include <AppKit/NSAffineTransform.h>
#include <AppKit/NSGraphics.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("appendBezierPathWithRect:")
    NSBezierPath	*p = [NSBezierPath bezierPath];
    NSPoint		pts[3];
    NSRect		b;

    [p appendBezierPathWithRect: NSMakeRect(1, 2, 10, 20)];
    PASS(5 == [p elementCount],
      "a rect appends a move, three lines and a close");
    PASS(NSMoveToBezierPathElement
      == [p elementAtIndex: 0 associatedPoints: pts]
      && EQ(pts[0].x, 1) && EQ(pts[0].y, 2),
      "the first element moves to the rect origin");
    PASS(NSLineToBezierPathElement == [p elementAtIndex: 1 associatedPoints: NULL],
      "the second element is a line");
    PASS(NSClosePathBezierPathElement
      == [p elementAtIndex: 4 associatedPoints: NULL],
      "the last element closes the path");

    b = [p bounds];
    PASS(EQ(b.origin.x, 1) && EQ(b.origin.y, 2)
      && EQ(b.size.width, 10) && EQ(b.size.height, 20),
      "the bounds match the appended rect");
  END_SET("appendBezierPathWithRect:")

  START_SET("appendBezierPathWithPoints:count:")
    NSBezierPath	*p = [NSBezierPath bezierPath];
    NSPoint		pts[3] = {{0, 0}, {5, 0}, {5, 5}};

    [p appendBezierPathWithPoints: pts count: 3];
    PASS(3 == [p elementCount],
      "three points on an empty path give three elements");
    PASS(NSMoveToBezierPathElement == [p elementAtIndex: 0 associatedPoints: NULL],
      "the first point becomes a move");
    PASS(NSLineToBezierPathElement == [p elementAtIndex: 1 associatedPoints: NULL],
      "later points become lines");
  END_SET("appendBezierPathWithPoints:count:")

  START_SET("elementAtIndex:associatedPoints: for a curve")
    NSBezierPath	*p = [NSBezierPath bezierPath];
    NSPoint		pts[3];

    [p moveToPoint: NSMakePoint(1, 1)];
    [p curveToPoint: NSMakePoint(4, 4)
       controlPoint1: NSMakePoint(2, 2)
       controlPoint2: NSMakePoint(3, 3)];
    PASS(NSCurveToBezierPathElement
      == [p elementAtIndex: 1 associatedPoints: pts],
      "a curve element is reported");
    PASS(EQ(pts[0].x, 2) && EQ(pts[1].x, 3) && EQ(pts[2].x, 4),
      "the curve yields control point 1, control point 2 then the endpoint");
  END_SET("elementAtIndex:associatedPoints: for a curve")

  START_SET("containsPoint:")
    NSBezierPath	*p = [NSBezierPath bezierPath];

    PASS(![p containsPoint: NSMakePoint(0, 0)],
      "an empty path contains no point");
    [p appendBezierPathWithRect: NSMakeRect(0, 0, 10, 10)];
    PASS([p containsPoint: NSMakePoint(5, 5)],
      "a point inside the rect is contained");
    PASS(![p containsPoint: NSMakePoint(20, 20)],
      "a point outside the bounds is not contained");
    PASS(![p containsPoint: NSMakePoint(-1, -1)],
      "a point below the origin is not contained");
  END_SET("containsPoint:")

  START_SET("transformUsingAffineTransform:")
    NSBezierPath	*p = [NSBezierPath bezierPath];
    NSAffineTransform	*t = [NSAffineTransform transform];
    NSRect		b;

    [p appendBezierPathWithRect: NSMakeRect(0, 0, 10, 10)];
    [t translateXBy: 5 yBy: 7];
    [p transformUsingAffineTransform: t];
    b = [p bounds];
    PASS(EQ(b.origin.x, 5) && EQ(b.origin.y, 7)
      && EQ(b.size.width, 10) && EQ(b.size.height, 10),
      "translating the path shifts its bounds");
  END_SET("transformUsingAffineTransform:")

  START_SET("relative moves and currentPoint")
    NSBezierPath	*p = [NSBezierPath bezierPath];
    NSPoint		cp;

    [p moveToPoint: NSMakePoint(10, 10)];
    [p relativeLineToPoint: NSMakePoint(5, 3)];
    cp = [p currentPoint];
    PASS(EQ(cp.x, 15) && EQ(cp.y, 13),
      "a relative line advances the current point by the delta");
    [p relativeMoveToPoint: NSMakePoint(2, 2)];
    cp = [p currentPoint];
    PASS(EQ(cp.x, 17) && EQ(cp.y, 15),
      "a relative move advances the current point by the delta");
  END_SET("relative moves and currentPoint")

  START_SET("isEmpty and currentPoint")
    NSBezierPath	*p = [NSBezierPath bezierPath];
    NSPoint		cp;

    PASS([p isEmpty], "a fresh path is empty");
    [p moveToPoint: NSMakePoint(3, 4)];
    PASS(![p isEmpty], "a path with an element is not empty");
    cp = [p currentPoint];
    PASS(EQ(cp.x, 3) && EQ(cp.y, 4), "the current point is the move target");
  END_SET("isEmpty and currentPoint")

  START_SET("line attributes")
    NSBezierPath	*p = [NSBezierPath bezierPath];

    [p setLineWidth: 3.5];
    PASS(EQ([p lineWidth], 3.5), "line width round-trips");
    [p setLineCapStyle: NSRoundLineCapStyle];
    PASS(NSRoundLineCapStyle == [p lineCapStyle], "line cap style round-trips");
    [p setLineJoinStyle: NSBevelLineJoinStyle];
    PASS(NSBevelLineJoinStyle == [p lineJoinStyle],
      "line join style round-trips");
    [p setMiterLimit: 7.0];
    PASS(EQ([p miterLimit], 7.0), "miter limit round-trips");
    [p setFlatness: 0.25];
    PASS(EQ([p flatness], 0.25), "flatness round-trips");
    [p setWindingRule: NSEvenOddWindingRule];
    PASS(NSEvenOddWindingRule == [p windingRule], "winding rule round-trips");
  END_SET("line attributes")

  START_SET("appendBezierPath:")
    NSBezierPath	*a = [NSBezierPath bezierPath];
    NSBezierPath	*b = [NSBezierPath bezierPath];

    [a appendBezierPathWithRect: NSMakeRect(0, 0, 4, 4)];
    [b moveToPoint: NSMakePoint(20, 20)];
    [b lineToPoint: NSMakePoint(30, 30)];
    [a appendBezierPath: b];
    PASS(7 == [a elementCount],
      "appending a path adds its elements to the receiver");
  END_SET("appendBezierPath:")

  DESTROY(arp);
  return 0;
}
