/* Coverage for NSToolbarItemGroup: the item identifier from the inherited
 * initialiser and the subitems round-trip.  Every assertion here matches AppKit
 * (verified on a macOS runner) and passes on unmodified GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSToolbarItemGroup.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSToolbarItemGroup basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSToolbarItemGroup	*group;
    NSToolbarItem	*first;
    NSToolbarItem	*second;
    NSArray		*subitems;

    group = AUTORELEASE([[NSToolbarItemGroup alloc]
      initWithItemIdentifier: @"myGroup"]);
    PASS(group != nil, "a toolbar item group is created");
    PASS([[group itemIdentifier] isEqualToString: @"myGroup"],
      "itemIdentifier is the identifier passed in");

    first = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"a"]);
    second = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"b"]);
    subitems = [NSArray arrayWithObjects: first, second, nil];
    [group setSubitems: subitems];

    PASS([[group subitems] count] == 2, "the subitems are set");
    PASS([[group subitems] isEqualToArray: subitems],
      "the subitems read back");
    PASS([[[[group subitems] objectAtIndex: 0] itemIdentifier]
      isEqualToString: @"a"], "the subitems keep their order");
  }

  END_SET("NSToolbarItemGroup basic")

  DESTROY(arp);
  return 0;
}
