/* -[NSScroller setFloatValue:knobProportion:] clamps the value into [0,1] in
   both directions, matching OS X.  A value of -1 is a regression case: it
   collides with the internal redisplay marker, so it must still clamp to 0. */
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

  START_SET("NSScroller clamp float value")

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

  {
    NSScroller *s = AUTORELEASE([[NSScroller alloc]
      initWithFrame: NSMakeRect(0, 0, 15, 200)]);

    [s setFloatValue: -1.0 knobProportion: 0.25];
    PASS(eq([s floatValue], 0.0), "a value of -1 clamps to 0");
    [s setFloatValue: -0.5 knobProportion: 0.25];
    PASS(eq([s floatValue], 0.0), "a value below 0 clamps to 0");
    [s setFloatValue: 2.0 knobProportion: 0.25];
    PASS(eq([s floatValue], 1.0), "a value above 1 clamps to 1");
    [s setFloatValue: 0.3 knobProportion: 0.25];
    PASS(eq([s floatValue], 0.3), "a value within range is kept");
  }

  END_SET("NSScroller clamp float value")

  DESTROY(arp);
  return 0;
}
