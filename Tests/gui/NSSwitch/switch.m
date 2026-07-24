/* Coverage for NSSwitch: it is off by default, setState: round-trips, and the
   state maps to the double and integer values (on is one, off is zero).
   Checked against AppKit on a macOS runner.  The switch uses the theme and
   font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSwitch.h>
#include <AppKit/NSCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSwitch *sw;

  START_SET("NSSwitch switch")

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
      sw = AUTORELEASE([[NSSwitch alloc]
        initWithFrame: NSMakeRect(0, 0, 40, 24)]);

      PASS([sw state] == NSControlStateValueOff, "a switch is off by default");

      [sw setState: NSControlStateValueOn];
      PASS([sw state] == NSControlStateValueOn, "setState: on round trips");
      PASS([sw doubleValue] == 1.0, "an on switch has a double value of one");
      PASS([sw intValue] == 1, "an on switch has an integer value of one");

      [sw setState: NSControlStateValueOff];
      PASS([sw state] == NSControlStateValueOff, "setState: off round trips");
      PASS([sw doubleValue] == 0.0, "an off switch has a double value of zero");
      PASS([sw intValue] == 0, "an off switch has an integer value of zero");
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

  END_SET("NSSwitch switch")

  DESTROY(arp);
  return 0;
}
