#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <math.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>

/* Values checked against AppKit. Rotated geometry produces irrational
   coordinates, so non-integer assertions below compare within a small
   tolerance rather than bit-exact. */

#define ROT_EPS 1e-6

static BOOL
RotPointsClose(NSPoint a, NSPoint b, CGFloat eps)
{
  return fabs(a.x - b.x) <= eps && fabs(a.y - b.y) <= eps;
}

static BOOL
RotRectsClose(NSRect a, NSRect b, CGFloat eps)
{
  return fabs(a.origin.x - b.origin.x) <= eps
    && fabs(a.origin.y - b.origin.y) <= eps
    && fabs(a.size.width - b.size.width) <= eps
    && fabs(a.size.height - b.size.height) <= eps;
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView rotation")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* setFrameRotation:/frameRotation */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameRotation: 30.0];
    PASS(fabs([v frameRotation] - 30.0) <= ROT_EPS,
      "setFrameRotation: sets the frame rotation");
    PASS(NSEqualRects([v frame], NSMakeRect(0, 0, 100, 100)),
      "setFrameRotation: leaves the frame rect unchanged");
  }

  /* setBoundsRotation:/boundsRotation and the resulting bounds bounding box */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setBoundsRotation: 30.0];
    PASS(fabs([v boundsRotation] - 30.0) <= ROT_EPS,
      "setBoundsRotation: sets the bounds rotation");
    PASS(RotRectsClose([v bounds],
      NSMakeRect(0, -50.0, 136.60254037844388, 136.60254037844388), ROT_EPS),
      "setBoundsRotation: rotates the bounds bounding box around the frame");
  }

  /* rotateByAngle: rotates the bounds, not the frame; frameRotation is
     unaffected by it */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v rotateByAngle: 15.0];
    PASS(fabs([v frameRotation] - 0.0) <= ROT_EPS,
      "rotateByAngle: leaves a fresh view's frame rotation at zero");
  }
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameRotation: 10.0];
    [v rotateByAngle: 15.0];
    PASS(fabs([v frameRotation] - 10.0) <= ROT_EPS,
      "rotateByAngle: leaves the frame rotation set by setFrameRotation: unchanged");
  }

  /* non-axis-aligned rotation and its effect on a converted point:
     windowless, display-independent */
  {
    NSView *outer = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)]);
    NSView *inner = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(50, 50, 100, 100)]);
    [outer addSubview: inner];
    [inner setFrameRotation: 45.0];

    NSPoint p = [inner convertPoint: NSMakePoint(10, 10) toView: outer];
    PASS(RotPointsClose(p, NSMakePoint(50, 64.142135623730951), ROT_EPS),
      "convertPoint:toView: through a 45 degree rotated subview");
  }

  /* setFrameRotation: does not normalize into [0, 360); it keeps the
     equivalent angle in (-180, 180], the same range atan2 returns */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameRotation: 90.0];
    PASS(fabs([v frameRotation] - 90.0) <= ROT_EPS,
      "setFrameRotation: 90 reads back as 90");
  }
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameRotation: 180.0];
    PASS(fabs([v frameRotation] - 180.0) <= ROT_EPS,
      "setFrameRotation: 180 reads back as 180");
  }
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameRotation: 405.0];
    PASS(fabs([v frameRotation] - 45.0) <= ROT_EPS,
      "setFrameRotation: 405 wraps to its 45 degree equivalent");
  }

  END_SET("NSView rotation")

  /* non-axis-aligned rotation and its effect on a converted rect: needs a
     window (windowless convertRect: hits the confirmed convertRect no-op
     divergence recorded in the values doc) */
  START_SET("NSView rotation (windowed)")
  NS_DURING
    {
      [NSApplication sharedApplication];
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *wOuter = [w contentView];
      NSView *wInner = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(50, 50, 100, 100)]);
      [wOuter addSubview: wInner];
      [wInner setFrameRotation: 45.0];

      NSRect r = [wInner convertRect: NSMakeRect(10, 10, 20, 20) toView: wOuter];
      PASS(RotRectsClose(r,
        NSMakeRect(35.857864376269077, 64.142135623730923,
          28.284271247461845, 28.284271247461845),
        ROT_EPS),
        "convertRect:toView: through a 45 degree rotated subview returns its rotated bounding box");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER
  END_SET("NSView rotation (windowed)")

  DESTROY(arp);
  return 0;
}
