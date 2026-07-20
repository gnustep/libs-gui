/* An NSImageView animates its image by default (matching AppKit), and
   -setAnimates: round-trips.  The accessors used to be stubs: -animates always
   returned NO and -setAnimates: did nothing.  Checked against AppKit on a
   macOS runner.  The view uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImageView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSImageView *iv;

  START_SET("NSImageView animates")

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
      iv = AUTORELEASE([[NSImageView alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 80)]);

      pass([iv animates] == YES, "an image view animates by default");

      [iv setAnimates: NO];
      pass([iv animates] == NO, "setAnimates: NO round trips");
      [iv setAnimates: YES];
      pass([iv animates] == YES, "setAnimates: YES round trips");
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

  END_SET("NSImageView animates")

  DESTROY(arp);
  return 0;
}
