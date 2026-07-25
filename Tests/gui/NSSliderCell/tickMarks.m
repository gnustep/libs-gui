/* Tests the NSSliderCell tick mark value logic, which minMax.m does not cover:
 * the tick mark count, tickMarkValueAtIndex:, and closestTickMarkValueToValue:
 * (which snaps a value to the nearest tick and clamps out-of-range values to
 * the end ticks).  These are plain value operations on a cell.
 */
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

  START_SET("NSSliderCell tick marks")

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

  /* Defaults: no tick marks, values not restricted to ticks. */
  PASS([cell numberOfTickMarks] == 0, "a new slider cell has no tick marks");
  PASS([cell allowsTickMarkValuesOnly] == NO,
       "a new slider cell does not restrict values to ticks");

  /* With no tick marks the closest tick value is the value itself. */
  PASS(eq([cell closestTickMarkValueToValue: 3.7], 3.7),
       "with no tick marks the value is returned unchanged");

  /* A single tick sits at the middle of the range. */
  [cell setNumberOfTickMarks: 1];
  PASS(eq([cell closestTickMarkValueToValue: 3.7], 5.0),
       "with one tick mark the closest value is the middle of the range");
  PASS(eq([cell tickMarkValueAtIndex: 0], 5.0),
       "the single tick mark is at the middle of the range");

  /* Eleven ticks over 0..10 sit at every integer. */
  [cell setNumberOfTickMarks: 11];
  PASS([cell numberOfTickMarks] == 11, "the tick mark count is stored");

  PASS(eq([cell tickMarkValueAtIndex: 0], 0.0)
    && eq([cell tickMarkValueAtIndex: 5], 5.0)
    && eq([cell tickMarkValueAtIndex: 10], 10.0),
    "tickMarkValueAtIndex spaces the ticks evenly across the range");

  /* Snapping to the nearest tick. */
  PASS(eq([cell closestTickMarkValueToValue: 3.4], 3.0),
       "a value just below a tick snaps down");
  PASS(eq([cell closestTickMarkValueToValue: 3.6], 4.0),
       "a value just above a tick snaps up");

  /* Out-of-range values clamp to the end ticks. */
  PASS(eq([cell closestTickMarkValueToValue: -5.0], 0.0),
       "a value below the range snaps to the first tick");
  PASS(eq([cell closestTickMarkValueToValue: 15.0], 10.0),
       "a value above the range snaps to the last tick");

  /* tickMarkValueAtIndex: out of range raises. */
  {
    BOOL raised = NO;

    NS_DURING
    {
      [cell tickMarkValueAtIndex: 99];
    }
    NS_HANDLER
    {
      raised = [[localException name] isEqualToString: NSRangeException];
    }
    NS_ENDHANDLER
    PASS(raised, "tickMarkValueAtIndex: out of range raises NSRangeException");
  }

  /* The restrict-to-ticks flag round-trips. */
  [cell setAllowsTickMarkValuesOnly: YES];
  PASS([cell allowsTickMarkValuesOnly] == YES,
       "setAllowsTickMarkValuesOnly: is stored");

  /* A fractional range snaps to the quarter ticks. */
  {
    NSSliderCell *c = AUTORELEASE([[NSSliderCell alloc] init]);

    [c setMinValue: 0];
    [c setMaxValue: 1];
    [c setNumberOfTickMarks: 5];
    PASS(eq([c closestTickMarkValueToValue: 0.3], 0.25),
         "a value near a quarter tick snaps to it");
    PASS(eq([c closestTickMarkValueToValue: 0.4], 0.5),
         "a value nearer the half tick snaps to the half");
  }

  END_SET("NSSliderCell tick marks")

  DESTROY(arp);
  return 0;
}
