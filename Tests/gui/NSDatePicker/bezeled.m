/* A new NSDatePicker is bezeled by default, matching AppKit, and -setBezeled:
   round-trips.  Checked against AppKit on a macOS runner.  The picker uses the
   theme and font backend, so the set is skipped when the backend is
   unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePicker.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePicker *dp;

  START_SET("NSDatePicker bezeled")

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
      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0, 0, 180, 24)]);

      pass([dp isBezeled] == YES, "a date picker is bezeled by default");

      [dp setBezeled: NO];
      pass([dp isBezeled] == NO, "setBezeled: NO round trips");
      [dp setBezeled: YES];
      pass([dp isBezeled] == YES, "setBezeled: YES round trips");
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

  END_SET("NSDatePicker bezeled")

  DESTROY(arp);
  return 0;
}
