/* Coverage for NSSearchFieldCell: the init defaults, the setter round-trips,
 * the ceiling on the number of recent searches, and how many searches are kept
 * when more are given than the maximum.  Every assertion here matches AppKit
 * (verified on a macOS runner) and passes on unmodified GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSSearchFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSSearchFieldCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSSearchFieldCell	*cell;
    NSArray		*searches;
    NSArray		*many;
    NSMenu		*menu;

    /* init defaults */
    cell = AUTORELEASE([[NSSearchFieldCell alloc] initTextCell: @"find"]);
    PASS(cell != nil, "a search field cell is created");
    PASS([cell sendsWholeSearchString] == NO,
      "a new cell does not send the whole search string");
    PASS([cell sendsSearchStringImmediately] == NO,
      "a new cell does not send the search string immediately");
    PASS([cell recentsAutosaveName] == nil,
      "a new cell has no recents autosave name");
    PASS([cell searchMenuTemplate] == nil,
      "a new cell has no search menu template");
    PASS([cell cancelButtonCell] != nil, "a new cell has a cancel button cell");
    PASS([cell searchButtonCell] != nil, "a new cell has a search button cell");

    /* setter round-trips */
    [cell setSendsWholeSearchString: YES];
    PASS([cell sendsWholeSearchString] == YES,
      "sendsWholeSearchString round-trips");
    [cell setSendsSearchStringImmediately: YES];
    PASS([cell sendsSearchStringImmediately] == YES,
      "sendsSearchStringImmediately round-trips");

    [cell setRecentsAutosaveName: @"saved"];
    PASS([[cell recentsAutosaveName] isEqualToString: @"saved"],
      "the recents autosave name round-trips");

    menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"m"]);
    [cell setSearchMenuTemplate: menu];
    PASS([cell searchMenuTemplate] == menu,
      "the search menu template reads back");

    /* the maximum number of recents */
    cell = AUTORELEASE([[NSSearchFieldCell alloc] initTextCell: @"find"]);
    [cell setMaximumRecents: 5];
    PASS([cell maximumRecents] == 5, "the maximum recents round-trips");
    [cell setMaximumRecents: 0];
    PASS([cell maximumRecents] == 0, "a maximum of no recents round-trips");
    [cell setMaximumRecents: 254];
    PASS([cell maximumRecents] == 254, "the largest maximum round-trips");
    [cell setMaximumRecents: 255];
    PASS([cell maximumRecents] == 254,
      "a maximum past the largest is brought back to it");
    [cell setMaximumRecents: 1000];
    PASS([cell maximumRecents] == 254,
      "a maximum far past the largest is brought back to it");

    /* recent searches */
    cell = AUTORELEASE([[NSSearchFieldCell alloc] initTextCell: @"find"]);
    searches = [NSArray arrayWithObjects: @"one", @"two", nil];
    [cell setRecentSearches: searches];
    PASS([[cell recentSearches] count] == 2, "the recent searches are set");
    PASS([[cell recentSearches] isEqualToArray: searches],
      "the recent searches read back");

    cell = AUTORELEASE([[NSSearchFieldCell alloc] initTextCell: @"find"]);
    many = [NSArray arrayWithObjects: @"1", @"2", @"3", @"4", @"5", nil];
    [cell setMaximumRecents: 3];
    [cell setRecentSearches: many];
    PASS([[cell recentSearches] count] == 3,
      "no more searches are kept than the maximum allows");
  }

  END_SET("NSSearchFieldCell basic")

  DESTROY(arp);
  return 0;
}
