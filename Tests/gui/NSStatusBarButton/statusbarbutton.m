/* Coverage for NSStatusBarButton: it is a kind of NSButton, it does not appear
   disabled by default, and setAppearsDisabled: round-trips.  Checked against
   AppKit on a macOS runner.  The button uses the theme and font backend, so
   the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSStatusBarButton.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSStatusBarButton *b;

  START_SET("NSStatusBarButton statusbarbutton")

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
      b = AUTORELEASE([[NSStatusBarButton alloc]
        initWithFrame: NSMakeRect(0, 0, 24, 24)]);

      PASS([b isKindOfClass: [NSButton class]],
           "a status bar button is a kind of button");
      PASS([b appearsDisabled] == NO,
           "a status bar button does not appear disabled by default");

      [b setAppearsDisabled: YES];
      PASS([b appearsDisabled] == YES, "setAppearsDisabled: YES round trips");
      [b setAppearsDisabled: NO];
      PASS([b appearsDisabled] == NO, "setAppearsDisabled: NO round trips");
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

  END_SET("NSStatusBarButton statusbarbutton")

  DESTROY(arp);
  return 0;
}
