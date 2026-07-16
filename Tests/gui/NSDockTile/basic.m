/* Coverage for NSDockTile: the tile the application vends, and the badge label,
 * application badge and content view round-trips.  Every assertion here matches
 * AppKit (verified on a macOS runner) and passes on unmodified GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDockTile.h>
#include <AppKit/NSView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the application dock tile")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSDockTile	*tile;
    NSView	*view;

    tile = [NSApp dockTile];
    PASS(tile != nil, "the application has a dock tile");
    PASS([tile badgeLabel] == nil, "the dock tile starts with no badge label");
    PASS([tile size].width > 0 && [tile size].height > 0,
      "the dock tile has a size");

    [tile setBadgeLabel: @"7"];
    PASS([[tile badgeLabel] isEqualToString: @"7"],
      "the badge label round-trips");
    [tile setBadgeLabel: nil];
    PASS([tile badgeLabel] == nil, "the badge label can be cleared");

    [tile setShowsApplicationBadge: NO];
    PASS([tile showsApplicationBadge] == NO,
      "the application badge flag round-trips when unset");
    [tile setShowsApplicationBadge: YES];
    PASS([tile showsApplicationBadge] == YES,
      "the application badge flag round-trips when set");

    view = AUTORELEASE([[NSView alloc]
      initWithFrame: NSMakeRect(0, 0, 10, 10)]);
    [tile setContentView: view];
    PASS([tile contentView] == view, "the content view reads back");
  }

  END_SET("the application dock tile")

  DESTROY(arp);
  return 0;
}
