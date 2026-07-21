#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

static BOOL
rects_almost_equal(NSRect r1, NSRect r2)
{
  if (fabs(r1.origin.x - r2.origin.x) > 0.001
      || fabs(r1.origin.y - r2.origin.y) > 0.001
      || fabs(r1.size.width - r2.size.width) > 0.001
      || fabs(r1.size.height - r2.size.height) > 0.001)
    {
      printf("expected frame (%g %g)+(%g %g), got (%g %g)+(%g %g)\n",
	     r2.origin.x, r2.origin.y, r2.size.width, r2.size.height,
	     r1.origin.x, r1.origin.y, r1.size.width, r1.size.height);
      return NO;
    }
  return YES;
}

@interface FlippedView : NSView
@end
@implementation FlippedView
- (BOOL) isFlipped
{
  return YES;
}
@end

/*
 * Drives a superview/subview pair through setFrameSize: and checks the
 * subview's resulting frame. superSize is the superview's fixed OTHER-axis
 * size (kept constant across the resize).
 */
static NSView *
autoresizeCase(Class superClass, NSRect subFrame,
	       NSUInteger mask, NSSize newSupSize)
{
  NSView *sup = AUTORELEASE([[superClass alloc]
			      initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  NSView *sub = AUTORELEASE([[NSView alloc] initWithFrame: subFrame]);

  [sup setAutoresizesSubviews: YES];
  [sub setAutoresizingMask: mask];
  [sup addSubview: sub];
  [sup setFrameSize: newSupSize];

  return sub;
}

/*
 * Same resize as the first minYMargin case, but the superview sits inside a
 * 2x-scaled parent in a window, so a window / device pixel is 0.5 apart in the
 * superview's coordinate space. AppKit floors the resized frame on the device
 * pixel grid, not on the superview's integer grid: the raw origin.y 16.6667
 * and far edge 50.0 become window rows 33 and 100, i.e. {10, 16.5}+{20, 33.5}
 * back in the superview's space. Needs a window, so it is guarded like the
 * backend cases above.
 */
static NSView *
scaledAutoresizeCase(void)
{
  NSWindow *win = AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 400, 400)
              styleMask: NSWindowStyleMaskBorderless
                backing: NSBackingStoreBuffered
                  defer: NO]);
  NSView *scaler = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 200)]);
  NSView *sup = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  NSView *sub = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(10, 10, 20, 20)]);

  [[win contentView] addSubview: scaler];
  [scaler scaleUnitSquareToSize: NSMakeSize(2.0, 2.0)];
  [scaler addSubview: sup];
  [sup setAutoresizesSubviews: YES];
  [sub setAutoresizingMask: NSViewHeightSizable | NSViewMinYMargin];
  [sup addSubview: sub];
  [sup setFrameSize: NSMakeSize(100, 120)];

  return sub;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSView *sub;

  START_SET("NSView autoresizeRounding")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
	SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  /*
   * All values below are AppKit values (checked against AppKit), from the
   * autoresize rounding-rule reference cases: sup (0,0,100,100), sub as
   * given, resized via a single setFrameSize:. AppKit floors the min edge
   * and the max edge of the resized subview frame independently per axis,
   * then derives size as the difference; it does not round to nearest.
   */

  /* --- heightSizable|minYMargin, dual-axis resize to (200,150) --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewHeightSizable | NSViewMinYMargin,
			NSMakeSize(200, 150));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 22, 30, 68)),
       "heightSizable|minYMargin floors both edges");

  /* --- heightSizable|maxYMargin, dual-axis resize to (200,150) --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewHeightSizable | NSViewMaxYMargin,
			NSMakeSize(200, 150));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 10, 30, 46)),
       "heightSizable|maxYMargin floors both edges");

  /* --- widthSizable|minXMargin, dual-axis resize to (200,150) --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewWidthSizable | NSViewMinXMargin,
			NSMakeSize(200, 150));
  PASS(rects_almost_equal([sub frame], NSMakeRect(35, 10, 105, 30)),
       "widthSizable|minXMargin floors both edges");

  /* --- widthSizable|maxXMargin, dual-axis resize to (200,150) --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewWidthSizable | NSViewMaxXMargin,
			NSMakeSize(200, 150));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 10, 63, 30)),
       "widthSizable|maxXMargin floors both edges");

  /* --- y, minYMargin, .5 tie landing on an odd floor value (100->154) --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewHeightSizable | NSViewMinYMargin,
			NSMakeSize(100, 154));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 23, 30, 71)),
       "heightSizable|minYMargin odd-floor tie floors down, not to even");

  /* --- x, minXMargin, .5 tie landing on an odd floor value (100->154) --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewWidthSizable | NSViewMinXMargin,
			NSMakeSize(154, 100));
  PASS(rects_almost_equal([sub frame], NSMakeRect(23, 10, 71, 30)),
       "widthSizable|minXMargin odd-floor tie floors down, not to even");

  /* --- y, maxYMargin, shrink (100->75): raw height 21.667, floors down --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewHeightSizable | NSViewMaxYMargin,
			NSMakeSize(100, 75));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 10, 30, 21)),
       "heightSizable|maxYMargin shrink floors size, not nearest");

  /* --- x, maxXMargin, shrink (100->75): raw width 21.667, floors down --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewWidthSizable | NSViewMaxXMargin,
			NSMakeSize(75, 100));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 10, 21, 30)),
       "widthSizable|maxXMargin shrink floors size, not nearest");

  /*
   * y, minYMargin, shrink (100->75): raw origin 3.75, raw (exact) max edge
   * 15. AppKit floors the origin DOWN to 3 (not up to 4, which any
   * round-half-up/nearest rule would give) and derives size as 15-3=12
   * (not floor(11.25)=11, which independently flooring the size would
   * give). This is the single clearest witness of the floor-both-edges
   * rule.
   */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewHeightSizable | NSViewMinYMargin,
			NSMakeSize(100, 75));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 3, 30, 12)),
       "heightSizable|minYMargin shrink floors origin down and derives size from exact far edge");

  /* --- x mirror of the above --- */
  sub = autoresizeCase([NSView class], NSMakeRect(10, 10, 30, 30),
			NSViewWidthSizable | NSViewMinXMargin,
			NSMakeSize(75, 100));
  PASS(rects_almost_equal([sub frame], NSMakeRect(3, 10, 12, 30)),
       "widthSizable|minXMargin shrink floors origin down and derives size from exact far edge");

  /*
   * Flipped superview control: identical to the first minYMargin tie case
   * above, but the superview is flipped. AppKit's answer is unchanged
   * ({10,22},{30,68}), i.e. AppKit does not swap minYMargin/maxYMargin
   * roles when the superview is flipped. Checked against AppKit.
   */
  sub = autoresizeCase([FlippedView class], NSMakeRect(10, 10, 30, 30),
			NSViewHeightSizable | NSViewMinYMargin,
			NSMakeSize(100, 150));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 22, 30, 68)),
       "heightSizable|minYMargin floors both edges with a flipped superview");

  /*
   * Scaled superview: the rounding is on the window / device pixel grid, not
   * on the superview's own integer grid. With a 2x-scaled parent the raw
   * origin.y 16.6667 and far edge 50.0 floor to window rows 33 and 100, i.e.
   * {10, 16.5}+{20, 33.5} back in the superview's space (a plain floor of the
   * superview-space edges would give {10, 16}+{20, 34}). Needs a window.
   */
  NS_DURING
    {
      sub = scaledAutoresizeCase();
      PASS(rects_almost_equal([sub frame], NSMakeRect(10, 16.5, 20, 33.5)),
           "heightSizable|minYMargin floors on the device pixel grid under a scaled superview");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available for the scaled-window case")
    }
  NS_ENDHANDLER

  END_SET("NSView autoresizeRounding")

  DESTROY(arp);
  return 0;
}
