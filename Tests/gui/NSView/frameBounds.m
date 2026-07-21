#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <math.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>

/* Values checked against AppKit unless noted otherwise on the block. */

static int
FBCheckFrameBounds(NSView *view, NSRect frame, NSRect bounds)
{
  NSRect r;

  r = [view frame];
  if (fabs(r.origin.x - frame.origin.x) > 0.001
    || fabs(r.origin.y - frame.origin.y) > 0.001
    || fabs(r.size.width - frame.size.width) > 0.001
    || fabs(r.size.height - frame.size.height) > 0.001)
    {
      printf("expected frame (%g %g)+(%g %g), got (%g %g)+(%g %g)\n",
        frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
        r.origin.x, r.origin.y, r.size.width, r.size.height);
      return 0;
    }

  r = [view bounds];
  if (fabs(r.origin.x - bounds.origin.x) > 0.001
    || fabs(r.origin.y - bounds.origin.y) > 0.001
    || fabs(r.size.width - bounds.size.width) > 0.001
    || fabs(r.size.height - bounds.size.height) > 0.001)
    {
      printf("expected bounds (%g %g)+(%g %g), got (%g %g)+(%g %g)\n",
        bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height,
        r.origin.x, r.origin.y, r.size.width, r.size.height);
      return 0;
    }

  return 1;
}

static int
FBCheckBoundsRotation(NSView *view, CGFloat rot)
{
  if (fabs([view boundsRotation] - rot) > 0.001)
    {
      printf("expected bounds rotation %g got %g\n", rot, [view boundsRotation]);
      return 0;
    }
  return 1;
}

static int
FBCheckMatrix(NSView *view, CGFloat *ts)
{
  NSView *superView = [view superview];
  CGFloat tsm[6];
  NSPoint res;

  res = [view convertPoint: NSMakePoint(0, 0) toView: superView];
  tsm[4] = res.x;
  tsm[5] = res.y;
  res = [view convertPoint: NSMakePoint(1, 0) toView: superView];
  tsm[0] = res.x - tsm[4];
  tsm[1] = res.y - tsm[5];
  res = [view convertPoint: NSMakePoint(0, 1) toView: superView];
  tsm[2] = res.x - tsm[4];
  tsm[3] = res.y - tsm[5];
  if (fabs(ts[0] - tsm[0]) > 0.001
    || fabs(ts[1] - tsm[1]) > 0.001
    || fabs(ts[2] - tsm[2]) > 0.001
    || fabs(ts[3] - tsm[3]) > 0.001
    || fabs(ts[4] - tsm[4]) > 0.001
    || fabs(ts[5] - tsm[5]) > 0.001)
    {
      printf("expected bounds matrix (%g %g %g %g %g %g) got (%g %g %g %g %g %g)\n",
        ts[0], ts[1], ts[2], ts[3], ts[4], ts[5],
        tsm[0], tsm[1], tsm[2], tsm[3], tsm[4], tsm[5]);
      return 0;
    }
  return 1;
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView frame and bounds")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* setFrame:/setFrameOrigin:/setFrameSize: and the resulting bounds */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrame: NSMakeRect(10, 20, 50, 60)];
    PASS(NSEqualRects([v frame], NSMakeRect(10, 20, 50, 60)),
      "setFrame: sets the frame");
    PASS(NSEqualRects([v bounds], NSMakeRect(0, 0, 50, 60)),
      "setFrame: resets the bounds origin and matches the new frame size");
  }
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameOrigin: NSMakePoint(15, 25)];
    PASS(NSEqualRects([v frame], NSMakeRect(15, 25, 100, 100)),
      "setFrameOrigin: moves the frame without changing its size");
    PASS(NSEqualRects([v bounds], NSMakeRect(0, 0, 100, 100)),
      "setFrameOrigin: leaves the bounds unchanged");
  }
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameSize: NSMakeSize(150, 80)];
    PASS(NSEqualRects([v frame], NSMakeRect(0, 0, 150, 80)),
      "setFrameSize: resizes the frame in place");
    PASS(NSEqualRects([v bounds], NSMakeRect(0, 0, 150, 80)),
      "setFrameSize: matches the bounds size to the new frame size");
  }

  /* setBounds:/setBoundsOrigin:/setBoundsSize: and the resulting frame */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setBounds: NSMakeRect(5, 5, 50, 50)];
    PASS(NSEqualRects([v bounds], NSMakeRect(5, 5, 50, 50)),
      "setBounds: sets the bounds");
    PASS(NSEqualRects([v frame], NSMakeRect(0, 0, 100, 100)),
      "setBounds: leaves the frame unchanged");
  }
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setBoundsOrigin: NSMakePoint(10, 10)];
    PASS(NSEqualRects([v bounds], NSMakeRect(10, 10, 100, 100)),
      "setBoundsOrigin: moves the bounds origin without changing its size");
    PASS(NSEqualRects([v frame], NSMakeRect(0, 0, 100, 100)),
      "setBoundsOrigin: leaves the frame unchanged");
  }
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setBoundsSize: NSMakeSize(50, 50)];
    PASS(NSEqualRects([v bounds], NSMakeRect(0, 0, 50, 50)),
      "setBoundsSize: resizes the bounds in place");
    PASS(NSEqualRects([v frame], NSMakeRect(0, 0, 100, 100)),
      "setBoundsSize: leaves the frame unchanged");
  }

  /* frame<->bounds scale mismatch: shrinking the bounds relative to the
     frame scales the view's coordinate system */
  {
    NSView *mid = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [mid setBounds: NSMakeRect(0, 0, 50, 50)];
    PASS(NSEqualRects([mid bounds], NSMakeRect(0, 0, 50, 50)),
      "setBounds: to half the frame size leaves the reported bounds at the set value");
  }

  /* centerScanRect: and backingAlignedRect:options: diverge from AppKit;
     see the Divergences table in the values doc. centerScanRect: is not
     covered here for that reason; backingAlignedRect:options: is not
     implemented by GNUstep NSView at all. */

  /* the zero-dimension rotated case */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameRotation: 45.0];
    [v setFrameSize: NSMakeSize(0, 100)];
    PASS(NSEqualRects([v frame], NSMakeRect(0, 0, 0, 100)),
      "setFrameSize: to zero width on a rotated view sets the frame exactly");
    PASS(NSEqualRects([v bounds], NSMakeRect(0, 0, 0, 100)),
      "setFrameSize: to zero width on a rotated view keeps the bounds matching");
  }

  /* Regression: collapsing a rotated view's frame to zero width and then
     expanding it again must not leave the bounds infinite or NaN (division
     by a zero frame dimension when the bounds rescale). */
  {
    NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
    [v setFrameRotation: 30.0];
    [v setFrameSize: NSMakeSize(0, 100)];
    [v setFrameSize: NSMakeSize(100, 100)];
    NSSize bounds = [v bounds].size;
    PASS(isfinite(bounds.width) && isfinite(bounds.height),
      "setFrameSize: keeps a rotated view's bounds finite across a zero width");
  }

  /* Sequence combining frame, bounds, rotation, translation and scale
     changes on a single view, checked against GNUstep's own transform math
     (frame/bounds are local view state, not AppKit-comparable in this
     combination). */
  {
    NSView *view1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(20, 20, 100, 100)]);
    int passed = 1;

    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(0, 0, 100, 100)) && passed;

    [view1 setFrameOrigin: NSMakePoint(10, 10)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(10, 10, 100, 100), NSMakeRect(0, 0, 100, 100)) && passed;

    [view1 setFrameSize: NSMakeSize(80, 80)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(10, 10, 80, 80), NSMakeRect(0, 0, 80, 80)) && passed;

    [view1 setFrameRotation: 45.0];
    passed = FBCheckFrameBounds(view1, NSMakeRect(10, 10, 80, 80), NSMakeRect(0, 0, 80, 80)) && passed;

    [view1 setBoundsRotation: -45.0];
    passed = FBCheckFrameBounds(view1, NSMakeRect(10, 10, 80, 80), NSMakeRect(-56.5685, 0, 113.137, 113.137)) && passed;

    [view1 setFrameSize: NSMakeSize(100, 100)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(10, 10, 100, 100), NSMakeRect(-70.7107, 0, 141.421, 141.421)) && passed;

    [view1 setFrameOrigin: NSMakePoint(20, 20)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(-70.7107, 0, 141.421, 141.421)) && passed;

    [view1 setBoundsOrigin: NSMakePoint(20, 20)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(-50.7107, 20, 141.421, 141.421)) && passed;

    [view1 setBoundsSize: NSMakeSize(100, 100)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(-50.7107, 20, 141.421, 141.421)) && passed;

    [view1 setBoundsSize: NSMakeSize(10, 10)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(-5.07107, 2, 14.1421, 14.1421)) && passed;

    [view1 setBoundsRotation: 0.0];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(2.82843, 0, 10, 10)) && passed;

    [view1 setBoundsSize: NSMakeSize(1, 1)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(0.282843, 0, 1, 1)) && passed;

    [view1 setBoundsRotation: -45.0];
    [view1 setBounds: NSMakeRect(10, 10, 100, 100)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(-60.7107, 10, 141.421, 141.421)) && passed;

    [view1 translateOriginToPoint: NSMakePoint(20, 20)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(-80.7107, -10, 141.421, 141.421)) && passed;

    [view1 scaleUnitSquareToSize: NSMakeSize(2, 3)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(-40.3553, -3.33333, 70.7107, 47.1405)) && passed;

    pass(passed, "NSView -frame and -bounds hold across a combined rotation/translation/scale sequence");
  }

  /* setBoundsRotation:/scaleUnitSquareToSize: interaction, checked against
     GNUstep's own transform math via the derived conversion matrix. */
  {
    NSView *container = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 300, 300)]);
    NSView *view1;
    CGFloat ts[6];
    int passed = 1;

    view1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(20, 20, 100, 100)]);
    [container addSubview: view1];

    [view1 setBounds: NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)) && passed;
    passed = FBCheckBoundsRotation(view1, 0) && passed;
    ts[0] = 4.70723; ts[1] = 0; ts[2] = 0; ts[3] = 1.64281; ts[4] = -123.409; ts[5] = -125.535;
    passed = FBCheckMatrix(view1, ts) && passed;

    [view1 setBoundsRotation: 30];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(70.6788, 50.866, 48.8336, 63.3383)) && passed;
    passed = FBCheckBoundsRotation(view1, 30) && passed;
    ts[0] = 4.07658; ts[1] = 0.821396; ts[2] = -2.35362; ts[3] = 1.42271; ts[4] = -123.409; ts[5] = -125.535;
    passed = FBCheckMatrix(view1, ts) && passed;

    [view1 setBounds: (NSRect){{30.4657, 88.5895}, {21.2439, 60.8716}}];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{30.4657, 77.9676}, {48.8336, 63.3383}}) && passed;
    passed = FBCheckBoundsRotation(view1, 30) && passed;
    ts[0] = 4.07658; ts[1] = 0.821396; ts[2] = -2.35361; ts[3] = 1.42271; ts[4] = 104.31; ts[5] = -131.062;
    passed = FBCheckMatrix(view1, ts) && passed;

    [view1 scaleUnitSquareToSize: (NSSize){0.720733, 0.747573}];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{42.2704, 104.294}, {67.7554, 84.7253}}) && passed;
    passed = FBCheckBoundsRotation(view1, 30) && passed;
    ts[0] = 2.93813; ts[1] = 0.59201; ts[2] = -1.7595; ts[3] = 1.06358; ts[4] = 104.31; ts[5] = -131.062;
    passed = FBCheckMatrix(view1, ts) && passed;

    [view1 setBoundsRotation: 30 - 1e-6];
    passed = (fabs([view1 boundsRotation] - 30.0 + 1e-6) <= 0.001) && passed;
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{39.9801, 104.211}, {66.2393, 85.2544}}) && passed;
    passed = FBCheckBoundsRotation(view1, 30 - 1e-6) && passed;
    ts[0] = 2.93813; ts[1] = 0.614059; ts[2] = -1.69633; ts[3] = 1.06358; ts[4] = 104.31; ts[5] = -131.062;
    passed = FBCheckMatrix(view1, ts) && passed;

    [view1 rotateByAngle: 1e-6];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{39.9801, 104.211}, {66.2393, 85.2544}}) && passed;
    passed = FBCheckBoundsRotation(view1, 30) && passed;

    view1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(20, 20, 100, 100)]);
    [container addSubview: view1];

    [view1 setBounds: NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)) && passed;
    [view1 scaleUnitSquareToSize: (NSSize){0.720733, 0.747573}];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{42.2704, 118.503}, {29.4754, 81.4256}}) && passed;
    passed = FBCheckBoundsRotation(view1, 0) && passed;
    [view1 setBoundsRotation: 30];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{95.8587, 66.7535}, {66.2393, 85.2544}}) && passed;
    passed = FBCheckBoundsRotation(view1, 30) && passed;

    view1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(20, 20, 100, 100)]);
    [container addSubview: view1];

    [view1 setBounds: NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)) && passed;
    [view1 setBoundsRotation: 30];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{70.6788, 50.866}, {48.8336, 63.3383}}) && passed;
    passed = FBCheckBoundsRotation(view1, 30) && passed;
    [view1 scaleUnitSquareToSize: (NSSize){0.720733, 0.747573}];
    passed = FBCheckFrameBounds(view1, NSMakeRect(20, 20, 100, 100), (NSRect){{98.0652, 68.0415}, {67.7554, 84.7252}}) && passed;
    passed = FBCheckBoundsRotation(view1, 30) && passed;

    testHopeful = YES;
    pass(passed, "NSView -scaleUnitSquareToSize interacts correctly with a rotated bounds");
    testHopeful = NO;
  }

  END_SET("NSView frame and bounds")

  /* frame<->bounds scale mismatch through convertRect:toView:, needs a
     window (windowless convertRect: is a separate confirmed divergence,
     see the values doc). */
  START_SET("NSView frame and bounds (windowed)")
  NS_DURING
    {
      [NSApplication sharedApplication];
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 300)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *outer = [w contentView];
      NSView *mid = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
      [outer addSubview: mid];
      [mid setBounds: NSMakeRect(0, 0, 50, 50)];

      NSView *inner = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(10, 10, 10, 10)]);
      [mid addSubview: inner];

      NSRect r = [inner convertRect: NSMakeRect(0, 0, 5, 5) toView: outer];
      PASS(NSEqualRects(r, NSMakeRect(20, 20, 10, 10)),
        "convertRect:toView: through a 2x frame/bounds scale mismatch");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER
  END_SET("NSView frame and bounds (windowed)")

  DESTROY(arp);
  return 0;
}
