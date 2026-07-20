/* Coverage for NSSlider value and tick-mark state: the defaults that match
   AppKit (a 0..1 range, no ticks, tick-only off), the setter round-trips and
   the clamping of the double value to the range.  Checked against AppKit on a
   macOS runner (the tick-mark position is compared by its enumerated name).
   The slider uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSlider.h>
#include <AppKit/NSSliderCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSlider *s;

  START_SET("NSSlider slider")

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
      s = AUTORELEASE([[NSSlider alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 24)]);

      /* Defaults. */
      pass([s minValue] == 0.0, "the default minimum is zero");
      pass([s maxValue] == 1.0, "the default maximum is one");
      pass([s doubleValue] == 0.0, "the default value is zero");
      pass([s numberOfTickMarks] == 0, "there are no tick marks by default");
      pass([s tickMarkPosition] == NSTickMarkBelow,
           "the default tick-mark position is below");
      pass([s allowsTickMarkValuesOnly] == NO,
           "the slider is not restricted to tick values by default");

      /* Round-trips. */
      [s setMinValue: 2.0];
      pass([s minValue] == 2.0, "setMinValue: round trips");
      [s setMaxValue: 10.0];
      pass([s maxValue] == 10.0, "setMaxValue: round trips");
      [s setDoubleValue: 5.0];
      pass([s doubleValue] == 5.0, "setDoubleValue: round trips");
      [s setNumberOfTickMarks: 6];
      pass([s numberOfTickMarks] == 6, "setNumberOfTickMarks: round trips");
      [s setTickMarkPosition: NSTickMarkAbove];
      pass([s tickMarkPosition] == NSTickMarkAbove,
           "setTickMarkPosition: round trips");
      [s setAllowsTickMarkValuesOnly: YES];
      pass([s allowsTickMarkValuesOnly] == YES,
           "setAllowsTickMarkValuesOnly: round trips");
      [s setAltIncrementValue: 0.5];
      pass([s altIncrementValue] == 0.5, "setAltIncrementValue: round trips");

      /* Clamping to the range. */
      NSSlider *s2 = AUTORELEASE([[NSSlider alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 24)]);
      [s2 setMinValue: 0.0];
      [s2 setMaxValue: 10.0];
      [s2 setDoubleValue: 100.0];
      pass([s2 doubleValue] == 10.0,
           "a value above the maximum clamps to the maximum");
      [s2 setDoubleValue: -5.0];
      pass([s2 doubleValue] == 0.0,
           "a value below the minimum clamps to the minimum");
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

  END_SET("NSSlider slider")

  DESTROY(arp);
  return 0;
}
