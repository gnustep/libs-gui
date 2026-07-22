/* Coverage for NSMenuToolbarItem: the item identifier from the inherited
 * initialiser, the menu round-trip and the showsIndicator round-trip.  Every
 * assertion here matches AppKit (verified on a macOS runner) and passes on
 * unmodified GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuToolbarItem.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuToolbarItem basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSMenuToolbarItem	*item;
    NSMenu		*menu;

    item = AUTORELEASE([[NSMenuToolbarItem alloc]
      initWithItemIdentifier: @"myItem"]);
    PASS(item != nil, "a menu toolbar item is created");
    PASS([[item itemIdentifier] isEqualToString: @"myItem"],
      "itemIdentifier is the identifier passed in");

    menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"myMenu"]);
    [item setMenu: menu];
    PASS([item menu] == menu, "the menu reads back");
    PASS([[[item menu] title] isEqualToString: @"myMenu"],
      "the menu keeps its title");

    [item setShowsIndicator: NO];
    PASS([item showsIndicator] == NO, "showsIndicator round-trips when unset");
    [item setShowsIndicator: YES];
    PASS([item showsIndicator] == YES, "showsIndicator round-trips when set");
  }

  END_SET("NSMenuToolbarItem basic")

  DESTROY(arp);
  return 0;
}
