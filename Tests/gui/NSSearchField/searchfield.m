/* Coverage for NSSearchField: it is backed by an NSSearchFieldCell, its recent
   searches start empty and have no autosave name, its cell does not send the
   whole search string or send immediately by default, and the recent-searches,
   autosave-name, send-whole and maximum-recents setters round-trip.  Checked
   against AppKit on a macOS runner.  The field uses the theme and font backend,
   so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSearchField.h>
#include <AppKit/NSSearchFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSearchField *sf;

  START_SET("NSSearchField search")

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
      sf = AUTORELEASE([[NSSearchField alloc]
        initWithFrame: NSMakeRect(0, 0, 160, 24)]);
      NSSearchFieldCell *cell = [sf cell];

      /* Defaults. */
      PASS([cell isKindOfClass: [NSSearchFieldCell class]],
           "a search field is backed by a search field cell");
      PASS([sf recentSearches] != nil
           && [[sf recentSearches] count] == 0,
           "the recent searches start empty");
      PASS([sf recentsAutosaveName] == nil,
           "there is no recents autosave name by default");
      PASS([cell sendsWholeSearchString] == NO,
           "the whole search string is not sent by default");
      PASS([cell sendsSearchStringImmediately] == NO,
           "the search string is not sent immediately by default");

      /* Round-trips. */
      [sf setRecentSearches: [NSArray arrayWithObjects: @"a", @"b", nil]];
      PASS([[sf recentSearches] count] == 2, "setRecentSearches: round trips");
      [sf setRecentsAutosaveName: @"mySearches"];
      PASS([[sf recentsAutosaveName] isEqualToString: @"mySearches"],
           "setRecentsAutosaveName: round trips");
      [cell setSendsWholeSearchString: YES];
      PASS([cell sendsWholeSearchString] == YES,
           "setSendsWholeSearchString: round trips");
      [cell setMaximumRecents: 5];
      PASS([cell maximumRecents] == 5, "setMaximumRecents: round trips");
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

  END_SET("NSSearchField search")

  DESTROY(arp);
  return 0;
}
