/* -[NSSliderCell closestTickMarkValueToValue:] snaps to the nearest tick,
   breaking exact halves towards the lower tick, as OS X does (2.5 -> 2,
   7.5 -> 7 with integer ticks). */
#include "Testing.h"

#include <math.h>
#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSliderCell.h>

static BOOL
eq(double a, double b)
{
  return fabs(a - b) < 0.0001;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSliderCell *cell;

  START_SET("NSSliderCell tick rounding")

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

  cell = AUTORELEASE([[NSSliderCell alloc] init]);
  [cell setMinValue: 0];
  [cell setMaxValue: 10];
  [cell setNumberOfTickMarks: 11];

  PASS(eq([cell closestTickMarkValueToValue: 3.4], 3.0),
       "a value just below a tick snaps down");
  PASS(eq([cell closestTickMarkValueToValue: 3.6], 4.0),
       "a value just above a tick snaps up");
  PASS(eq([cell closestTickMarkValueToValue: 2.5], 2.0),
       "a halfway value snaps to the lower tick");
  PASS(eq([cell closestTickMarkValueToValue: 7.5], 7.0),
       "another halfway value also snaps to the lower tick");

  END_SET("NSSliderCell tick rounding")

  DESTROY(arp);
  return 0;
}
