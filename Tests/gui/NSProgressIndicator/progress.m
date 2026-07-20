/* Coverage for NSProgressIndicator value and configuration: the defaults that
   match AppKit (a 0..100 range, indeterminate, bezeled, shown when stopped,
   regular size, bar style), the setter round-trips, incrementBy: and the
   clamping of the double value to the range.  Animation is not exercised.
   Checked against AppKit on a macOS runner (control size and style are
   compared by their enumerated names).  The indicator uses the theme and font
   backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSProgressIndicator.h>
#include <AppKit/NSCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSProgressIndicator *pi;

  START_SET("NSProgressIndicator progress")

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
      pi = AUTORELEASE([[NSProgressIndicator alloc]
        initWithFrame: NSMakeRect(0, 0, 160, 20)]);

      /* Defaults. */
      pass([pi minValue] == 0.0, "the default minimum is zero");
      pass([pi maxValue] == 100.0, "the default maximum is one hundred");
      pass([pi doubleValue] == 0.0, "the default value is zero");
      pass([pi isIndeterminate] == YES, "an indicator is indeterminate by default");
      pass([pi isBezeled] == YES, "an indicator is bezeled by default");
      pass([pi isDisplayedWhenStopped] == YES,
           "an indicator is shown when stopped by default");
      pass([pi controlSize] == NSControlSizeRegular,
           "the default control size is regular");
      pass([pi style] == NSProgressIndicatorBarStyle,
           "the default style is the bar style");

      /* Setter round-trips. */
      [pi setIndeterminate: NO];
      pass([pi isIndeterminate] == NO, "setIndeterminate: round trips");
      [pi setMinValue: 10.0];
      pass([pi minValue] == 10.0, "setMinValue: round trips");
      [pi setMaxValue: 200.0];
      pass([pi maxValue] == 200.0, "setMaxValue: round trips");
      [pi setDoubleValue: 50.0];
      pass([pi doubleValue] == 50.0, "setDoubleValue: round trips");
      [pi setControlSize: NSControlSizeSmall];
      pass([pi controlSize] == NSControlSizeSmall, "setControlSize: round trips");
      [pi setStyle: NSProgressIndicatorStyleSpinning];
      pass([pi style] == NSProgressIndicatorStyleSpinning, "setStyle: round trips");
      [pi setDisplayedWhenStopped: NO];
      pass([pi isDisplayedWhenStopped] == NO,
           "setDisplayedWhenStopped: round trips");
      [pi setUsesThreadedAnimation: YES];
      pass([pi usesThreadedAnimation] == YES,
           "setUsesThreadedAnimation: round trips");

      /* incrementBy: and clamping to the range. */
      NSProgressIndicator *p2 = AUTORELEASE([[NSProgressIndicator alloc]
        initWithFrame: NSMakeRect(0, 0, 160, 20)]);
      [p2 setIndeterminate: NO];
      [p2 setMinValue: 0.0];
      [p2 setMaxValue: 100.0];
      [p2 setDoubleValue: 20.0];
      [p2 incrementBy: 5.0];
      pass([p2 doubleValue] == 25.0, "incrementBy: advances the value");
      [p2 setDoubleValue: 500.0];
      pass([p2 doubleValue] == 100.0,
           "a value above the maximum clamps to the maximum");
      [p2 setDoubleValue: -10.0];
      pass([p2 doubleValue] == 0.0,
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

  END_SET("NSProgressIndicator progress")

  DESTROY(arp);
  return 0;
}
