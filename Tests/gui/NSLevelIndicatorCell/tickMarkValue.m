/* NSLevelIndicatorCell -tickMarkValueAtIndex: spaces the ticks evenly from
   minValue at index 0 to maxValue at the last index (matching AppKit); a
   single tick reports the midpoint of the range. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <math.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSLevelIndicatorCell.h>

static BOOL eq(double a, double b) { return fabs(a - b) < 1e-9; }

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSLevelIndicatorCell *cell;

  START_SET("NSLevelIndicatorCell tickMarkValue")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  [cell setMinValue: 0.0];
  [cell setMaxValue: 10.0];

  [cell setNumberOfTickMarks: 11];
  PASS(eq([cell tickMarkValueAtIndex: 0], 0.0), "11 ticks: index 0 is minValue");
  PASS(eq([cell tickMarkValueAtIndex: 5], 5.0), "11 ticks: index 5 is the midpoint");
  PASS(eq([cell tickMarkValueAtIndex: 10], 10.0), "11 ticks: last index is maxValue");

  [cell setNumberOfTickMarks: 2];
  PASS(eq([cell tickMarkValueAtIndex: 0], 0.0), "2 ticks: index 0 is minValue");
  PASS(eq([cell tickMarkValueAtIndex: 1], 10.0), "2 ticks: index 1 is maxValue");

  [cell setNumberOfTickMarks: 1];
  PASS(eq([cell tickMarkValueAtIndex: 0], 5.0), "1 tick: reports the midpoint");

  END_SET("NSLevelIndicatorCell tickMarkValue")

  DESTROY(arp);
  return 0;
}
