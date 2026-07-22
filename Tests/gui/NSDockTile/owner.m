/* The application's dock tile is owned by the application, so that whatever is
 * handed the tile can find its way back.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDockTile.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the dock tile owner")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSDockTile	*tile;

    tile = [NSApp dockTile];
    PASS([tile owner] == NSApp,
      "the application dock tile is owned by the application");

    /* and the owner is still whatever it is set to */
    [tile setOwner: nil];
    PASS([tile owner] == nil, "the owner round-trips");
    [tile setOwner: NSApp];
    PASS([tile owner] == NSApp, "the owner reads back");
  }

  END_SET("the dock tile owner")

  DESTROY(arp);
  return 0;
}
