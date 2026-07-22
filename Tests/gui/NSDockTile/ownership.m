/* A dock tile lets go of what it holds when it is deallocated, not on every
 * release: a tile that is retained and released again is still whole.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDockTile.h>
#include <AppKit/NSView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("a balancing release keeps the tile whole")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSDockTile	*tile;
    NSView	*view;

    tile = [[NSDockTile alloc] init];
    view = [tile contentView];
    RETAIN(view);

    /* One retain and one release, leaving the tile alive throughout. */
    RETAIN(tile);
    RELEASE(tile);

    PASS([tile contentView] == view, "the tile still has its content view");
    PASS([view retainCount] == 2,
      "a balancing release does not let go of the content view");

    [tile setBadgeLabel: @"7"];
    RETAIN(tile);
    RELEASE(tile);
    PASS([[tile badgeLabel] isEqualToString: @"7"],
      "a balancing release does not let go of the badge label");

    RELEASE(view);
    RELEASE(tile);
  }

  END_SET("a balancing release keeps the tile whole")

  DESTROY(arp);
  return 0;
}
