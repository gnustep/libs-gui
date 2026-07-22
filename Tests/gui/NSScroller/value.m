/* Coverage for the NSScroller value model: the orientation-dependent arrow
   position, the default hit part and control size, setting the value and
   knob proportion together, the clamping of the value and the knob
   proportion into [0,1], and the arrow-position and control-size accessors.
   The scroller uses the theme and font backend, so the set is skipped when
   the backend is unavailable.
*/
#include "Testing.h"

#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSScroller.h>

static BOOL
eq(CGFloat a, CGFloat b)
{
  return fabs((double)(a - b)) < 0.0001;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSScroller value")

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

  /* Orientation follows the frame; the arrows sit at the end of the axis. */
  {
    NSScroller *v = AUTORELEASE([[NSScroller alloc]
      initWithFrame: NSMakeRect(0, 0, 15, 200)]);
    NSScroller *h = AUTORELEASE([[NSScroller alloc]
      initWithFrame: NSMakeRect(0, 0, 200, 15)]);

    PASS([v arrowsPosition] == NSScrollerArrowsMaxEnd,
      "a vertical scroller keeps its arrows at the max end");
    PASS([h arrowsPosition] == NSScrollerArrowsMinEnd,
      "a horizontal scroller keeps its arrows at the min end");
    PASS([v hitPart] == NSScrollerNoPart, "a new scroller has no hit part");
    PASS([v controlSize] == NSRegularControlSize, "the default control size is regular");
  }

  /* Value and knob proportion. */
  {
    NSScroller *s = AUTORELEASE([[NSScroller alloc]
      initWithFrame: NSMakeRect(0, 0, 15, 200)]);

    [s setFloatValue: 0.5 knobProportion: 0.25];
    PASS(eq([s floatValue], 0.5) && eq([s knobProportion], 0.25),
      "setFloatValue:knobProportion: sets both the value and the proportion");

    /* The value clamps to at most 1. */
    [s setFloatValue: 2.0 knobProportion: 0.25];
    PASS(eq([s floatValue], 1.0), "a value above 1 clamps to 1");

    /* The knob proportion clamps into [0,1]. */
    [s setKnobProportion: 1.5];
    PASS(eq([s knobProportion], 1.0), "a knob proportion above 1 clamps to 1");
    [s setKnobProportion: -0.5];
    PASS(eq([s knobProportion], 0.0), "a knob proportion below 0 clamps to 0");
    [s setKnobProportion: 0.4];
    PASS(eq([s knobProportion], 0.4), "a knob proportion within range is kept");
  }

  /* Accessors round-trip. */
  {
    NSScroller *s = AUTORELEASE([[NSScroller alloc]
      initWithFrame: NSMakeRect(0, 0, 15, 200)]);

    [s setArrowsPosition: NSScrollerArrowsNone];
    PASS([s arrowsPosition] == NSScrollerArrowsNone, "setArrowsPosition: round trips");
    [s setControlSize: NSSmallControlSize];
    PASS([s controlSize] == NSSmallControlSize, "setControlSize: round trips");
  }

  END_SET("NSScroller value")

  DESTROY(arp);
  return 0;
}
