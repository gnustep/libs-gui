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
   * roles when the superview is flipped. GNUstep's pre-existing
   * flip-conditional margin swap (resizeWithOldSuperviewSize:, before the
   * edge-flooring this fix touches) does swap them, so this still diverges
   * after this fix; that is a separate, unrelated bug, not the
   * centerScanRect:/floor rounding issue this fix addresses. Marked
   * hopeful pending a follow-up fix to the margin swap.
   */
  testHopeful = YES;
  sub = autoresizeCase([FlippedView class], NSMakeRect(10, 10, 30, 30),
			NSViewHeightSizable | NSViewMinYMargin,
			NSMakeSize(100, 150));
  PASS(rects_almost_equal([sub frame], NSMakeRect(10, 22, 30, 68)),
       "heightSizable|minYMargin floors both edges with a flipped superview");
  testHopeful = NO;

  END_SET("NSView autoresizeRounding")

  DESTROY(arp);
  return 0;
}
