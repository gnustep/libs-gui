/* Coverage for NSLevelIndicator: the value, threshold and tick-mark defaults,
   the setter round-trips, the value reported at a tick index, and the fact
   that the double value is not clamped to the min/max range.  Checked against
   AppKit on a macOS runner (the tick-mark position is compared by its
   enumerated name, whose raw value differs between GNUstep and macOS).  The
   indicator uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSLevelIndicator.h>
#include <AppKit/NSSliderCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSLevelIndicator *li;

  START_SET("NSLevelIndicator levels")

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

  NS_DURING
    {
      li = AUTORELEASE([[NSLevelIndicator alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 20)]);

      /* Defaults. */
      PASS([li minValue] == 0.0, "the default minimum is zero");
      PASS([li maxValue] == 5.0, "the default maximum is five");
      PASS([li warningValue] == 0.0, "the default warning value is zero");
      PASS([li criticalValue] == 0.0, "the default critical value is zero");
      PASS([li numberOfTickMarks] == 0, "there are no tick marks by default");
      PASS([li numberOfMajorTickMarks] == 0,
           "there are no major tick marks by default");
      PASS([li tickMarkPosition] == NSTickMarkBelow,
           "the default tick-mark position is below");
      PASS([li doubleValue] == 0.0, "the default value is zero");

      /* Setter round-trips. */
      [li setMinValue: 2.0];
      PASS([li minValue] == 2.0, "setMinValue: round trips");
      [li setMaxValue: 10.0];
      PASS([li maxValue] == 10.0, "setMaxValue: round trips");
      [li setWarningValue: 6.0];
      PASS([li warningValue] == 6.0, "setWarningValue: round trips");
      [li setCriticalValue: 8.0];
      PASS([li criticalValue] == 8.0, "setCriticalValue: round trips");
      [li setNumberOfTickMarks: 11];
      PASS([li numberOfTickMarks] == 11, "setNumberOfTickMarks: round trips");
      [li setNumberOfMajorTickMarks: 3];
      PASS([li numberOfMajorTickMarks] == 3,
           "setNumberOfMajorTickMarks: round trips");
      [li setTickMarkPosition: NSTickMarkAbove];
      PASS([li tickMarkPosition] == NSTickMarkAbove,
           "setTickMarkPosition: round trips");

      /* The value at a tick index maps linearly across the range. */
      NSLevelIndicator *li2 = AUTORELEASE([[NSLevelIndicator alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 20)]);
      [li2 setMinValue: 0.0];
      [li2 setMaxValue: 10.0];
      [li2 setNumberOfTickMarks: 11];
      PASS([li2 tickMarkValueAtIndex: 0] == 0.0,
           "the first tick is at the minimum");
      PASS([li2 tickMarkValueAtIndex: 5] == 5.0,
           "the middle tick is at the midpoint");
      PASS([li2 tickMarkValueAtIndex: 10] == 10.0,
           "the last tick is at the maximum");

      /* The double value is stored as given, not clamped to the range. */
      NSLevelIndicator *li3 = AUTORELEASE([[NSLevelIndicator alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 20)]);
      [li3 setMinValue: 0.0];
      [li3 setMaxValue: 10.0];
      [li3 setDoubleValue: 100.0];
      PASS([li3 doubleValue] == 100.0,
           "a value above the maximum is not clamped");
      [li3 setDoubleValue: -5.0];
      PASS([li3 doubleValue] == -5.0,
           "a value below the minimum is not clamped");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSLevelIndicator levels")

  DESTROY(arp);
  return 0;
}
