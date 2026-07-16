/* Coverage for NSLevelIndicatorCell: the init and per-style defaults, the
   plain setter round-trips, the fact that the cell value is not clamped to
   [min,max], and tickMarkValueAtIndex: at the first tick and out of range.
   Every assertion here matches AppKit (verified on a macOS runner) and passes
   on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSLevelIndicatorCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSLevelIndicatorCell *cell;
  NSLevelIndicatorStyle styles[4];
  double maxes[4];
  int i;
  BOOL raised;

  START_SET("NSLevelIndicatorCell basic")

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

  /* init defaults (AppKit: min 0, max 5, warning/critical/value 0, no ticks) */
  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  pass([cell minValue] == 0.0, "default minValue is 0");
  pass([cell maxValue] == 5.0, "default maxValue is 5");
  pass([cell warningValue] == 0.0, "default warningValue is 0");
  pass([cell criticalValue] == 0.0, "default criticalValue is 0");
  pass([cell doubleValue] == 0.0, "default value is 0");
  pass([cell numberOfTickMarks] == 0, "default numberOfTickMarks is 0");
  pass([cell numberOfMajorTickMarks] == 0, "default numberOfMajorTickMarks is 0");

  /* per-style default maxValue: capacity/relevancy 100, discrete/rating 5 */
  styles[0] = NSRelevancyLevelIndicatorStyle;         maxes[0] = 100.0;
  styles[1] = NSContinuousCapacityLevelIndicatorStyle; maxes[1] = 100.0;
  styles[2] = NSDiscreteCapacityLevelIndicatorStyle;   maxes[2] = 5.0;
  styles[3] = NSRatingLevelIndicatorStyle;             maxes[3] = 5.0;
  for (i = 0; i < 4; i++)
    {
      NSLevelIndicatorCell *s =
          AUTORELEASE([[NSLevelIndicatorCell alloc]
                        initWithLevelIndicatorStyle: styles[i]]);
      pass([s minValue] == 0.0 && [s maxValue] == maxes[i]
             && [s doubleValue] == 0.0,
           "style %d default is min 0, max %g, value 0", (int)styles[i], maxes[i]);
    }

  /* setter round-trips */
  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  [cell setMinValue: 1.0];
  [cell setMaxValue: 20.0];
  [cell setWarningValue: 7.5];
  [cell setCriticalValue: 9.25];
  [cell setNumberOfTickMarks: 9];
  [cell setNumberOfMajorTickMarks: 3];
  pass([cell minValue] == 1.0, "minValue round-trips");
  pass([cell maxValue] == 20.0, "maxValue round-trips");
  pass([cell warningValue] == 7.5, "warningValue round-trips");
  pass([cell criticalValue] == 9.25, "criticalValue round-trips");
  pass([cell numberOfTickMarks] == 9, "numberOfTickMarks round-trips");
  pass([cell numberOfMajorTickMarks] == 3, "numberOfMajorTickMarks round-trips");

  /* the cell value is not clamped to [min,max] (matches AppKit) */
  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  [cell setMinValue: 2.0];
  [cell setMaxValue: 8.0];
  [cell setDoubleValue: 100.0];
  pass([cell doubleValue] == 100.0, "value above max is not clamped");
  [cell setDoubleValue: -100.0];
  pass([cell doubleValue] == -100.0, "value below min is not clamped");

  /* moving min/max past the current value does not re-clamp it */
  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  [cell setMinValue: 0.0];
  [cell setMaxValue: 10.0];
  [cell setDoubleValue: 5.0];
  [cell setMaxValue: 3.0];
  pass([cell doubleValue] == 5.0, "lowering max does not re-clamp the value");
  [cell setMinValue: 4.0];
  pass([cell doubleValue] == 5.0, "raising min does not re-clamp the value");

  /* tickMarkValueAtIndex: the first tick is the minimum value */
  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  [cell setMinValue: 0.0];
  [cell setMaxValue: 10.0];
  [cell setNumberOfTickMarks: 11];
  pass([cell tickMarkValueAtIndex: 0] == 0.0,
       "tickMarkValueAtIndex: 0 is the minimum value");

  /* out-of-range and negative tick indices raise NSRangeException */
  raised = NO;
  NS_DURING
    [cell tickMarkValueAtIndex: 11];
  NS_HANDLER
    raised = [[localException name] isEqualToString: NSRangeException];
  NS_ENDHANDLER
  pass(raised, "tickMarkValueAtIndex: past the last tick raises NSRangeException");

  raised = NO;
  NS_DURING
    [cell tickMarkValueAtIndex: -1];
  NS_HANDLER
    raised = [[localException name] isEqualToString: NSRangeException];
  NS_ENDHANDLER
  pass(raised, "tickMarkValueAtIndex: a negative index raises NSRangeException");

  END_SET("NSLevelIndicatorCell basic")

  DESTROY(arp);
  return 0;
}
