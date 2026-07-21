/* Coverage for the AppKit/GNUstep additions to NSAffineTransform:
 * rotationAngle, isRotated, boundingRectFor:result:, the delta transform,
 * concatenateWithMatrix:, setMatrix:/getMatrix: and the frame helpers.
 *
 * These are only exercised under the modern Objective-C runtime: the
 * traditional GNU runtime cannot handle the additions that take a C array
 * (setMatrix:/getMatrix:/concatenateWithMatrix: use const float[6]) and aborts
 * when one is sent, so they are skipped there.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSAffineTransform.h>

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

#if __OBJC2__
  START_SET("rotationAngle and isRotated")
    NSAffineTransform	*t = [NSAffineTransform transform];

    PASS(![t isRotated], "the identity is not rotated");
    PASS(EQ([t rotationAngle], 0.0), "the identity has rotation angle 0");

    [t rotateByDegrees: 90.0];
    PASS([t isRotated], "a rotated transform reports isRotated");
    PASS(EQ([t rotationAngle], 90.0), "rotationAngle reads a 90 degree rotation");

    t = [NSAffineTransform transform];
    [t rotateByDegrees: 30.0];
    PASS(EQ([t rotationAngle], 30.0), "rotationAngle reads a 30 degree rotation");

    t = [NSAffineTransform transform];
    [t scaleXBy: 2.0 yBy: 3.0];
    PASS(![t isRotated], "a pure scale is not rotated");
  END_SET("rotationAngle and isRotated")

  START_SET("setFrameRotation sets an absolute angle")
    NSAffineTransform	*t = [NSAffineTransform transform];

    [t rotateByDegrees: 20.0];
    [t setFrameRotation: 75.0];
    PASS(EQ([t rotationAngle], 75.0),
      "setFrameRotation: replaces the current rotation");
  END_SET("setFrameRotation sets an absolute angle")

  START_SET("setMatrix / getMatrix round-trip")
    NSAffineTransform	*t = [NSAffineTransform transform];
    float		m[6] = {2.0, 0.0, 0.0, 3.0, 5.0, 7.0};
    float		out[6];
    NSPoint		p;

    [t setMatrix: m];
    [t getMatrix: out];
    PASS(EQ(out[0], 2.0) && EQ(out[3], 3.0) && EQ(out[4], 5.0)
      && EQ(out[5], 7.0), "getMatrix returns what setMatrix stored");

    /* transformPoint uses (m11*x + m21*y + tX, m12*x + m22*y + tY). */
    p = [t transformPoint: NSMakePoint(1.0, 1.0)];
    PASS(EQ(p.x, 7.0) && EQ(p.y, 10.0),
      "the set matrix scales by (2,3) and translates by (5,7)");
  END_SET("setMatrix / getMatrix round-trip")

  START_SET("deltaPointInMatrixSpace ignores translation")
    NSAffineTransform	*t = [NSAffineTransform transform];
    NSPoint		d;

    [t scaleXBy: 2.0 yBy: 3.0];
    [t translateXBy: 100.0 yBy: 100.0];
    d = [t deltaPointInMatrixSpace: NSMakePoint(1.0, 1.0)];
    PASS(EQ(d.x, 2.0) && EQ(d.y, 3.0),
      "a delta point is scaled but not translated");
  END_SET("deltaPointInMatrixSpace ignores translation")

  START_SET("concatenateWithMatrix composes")
    NSAffineTransform	*t = [NSAffineTransform transform];
    float		scale[6] = {2.0, 0.0, 0.0, 2.0, 0.0, 0.0};
    NSPoint		p;

    [t concatenateWithMatrix: scale];
    p = [t transformPoint: NSMakePoint(3.0, 4.0)];
    PASS(EQ(p.x, 6.0) && EQ(p.y, 8.0),
      "concatenating a scale matrix scales transformed points");
  END_SET("concatenateWithMatrix composes")

  START_SET("boundingRectFor:result:")
    NSAffineTransform	*t = [NSAffineTransform transform];
    NSRect		r = NSMakeRect(1.0, 2.0, 10.0, 20.0);
    NSRect		out;

    /* Identity leaves the rect unchanged. */
    [t boundingRectFor: r result: &out];
    PASS(EQ(out.origin.x, 1.0) && EQ(out.origin.y, 2.0)
      && EQ(out.size.width, 10.0) && EQ(out.size.height, 20.0),
      "the identity bounding rect is the rect itself");

    /* Translation shifts the bounding rect. */
    t = [NSAffineTransform transform];
    [t translateXBy: 5.0 yBy: 3.0];
    [t boundingRectFor: r result: &out];
    PASS(EQ(out.origin.x, 6.0) && EQ(out.origin.y, 5.0)
      && EQ(out.size.width, 10.0) && EQ(out.size.height, 20.0),
      "translation shifts the bounding rect origin");

    /* A 90 degree rotation of a 10x20 rect at the origin gives a 20x10
     * bounding rect: (x,y) maps to (-y,x). */
    t = [NSAffineTransform transform];
    [t rotateByDegrees: 90.0];
    [t boundingRectFor: NSMakeRect(0.0, 0.0, 10.0, 20.0) result: &out];
    PASS(EQ(out.origin.x, -20.0) && EQ(out.origin.y, 0.0)
      && EQ(out.size.width, 20.0) && EQ(out.size.height, 10.0),
      "a 90 degree rotation swaps the bounding rect extents");
  END_SET("boundingRectFor:result:")

  START_SET("makeIdentityMatrix and takeMatrixFromTransform")
    NSAffineTransform	*t = [NSAffineTransform transform];
    NSAffineTransform	*u = [NSAffineTransform transform];
    NSPoint		p;

    [t scaleXBy: 4.0 yBy: 4.0];
    [t rotateByDegrees: 33.0];
    [t makeIdentityMatrix];
    p = [t transformPoint: NSMakePoint(9.0, 11.0)];
    PASS(EQ(p.x, 9.0) && EQ(p.y, 11.0),
      "makeIdentityMatrix resets to the identity");

    [u translateXBy: 8.0 yBy: 6.0];
    [t takeMatrixFromTransform: u];
    p = [t transformPoint: NSMakePoint(0.0, 0.0)];
    PASS(EQ(p.x, 8.0) && EQ(p.y, 6.0),
      "takeMatrixFromTransform: copies another transform");
  END_SET("makeIdentityMatrix and takeMatrixFromTransform")
#else
  START_SET("NSAffineTransform GNUstep additions")
    SKIP("the additions need the modern Objective-C runtime")
  END_SET("NSAffineTransform GNUstep additions")
#endif

  DESTROY(arp);
  return 0;
}
