/* Giving a cell a recents autosave name loads the searches saved under it, but
 * a name with nothing saved under it says nothing about the searches the cell
 * already has.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSearchFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the recents autosave name")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSSearchFieldCell	*cell;
    NSArray		*searches;
    NSString		*unusedName = @"GSTestSearchesNothingSavedHere";
    NSString		*savedName = @"GSTestSearchesSomethingSavedHere";

    [[NSUserDefaults standardUserDefaults] removeObjectForKey: unusedName];

    /* a name with nothing saved under it leaves the searches alone */
    cell = AUTORELEASE([[NSSearchFieldCell alloc] initTextCell: @"find"]);
    searches = [NSArray arrayWithObjects: @"one", @"two", nil];
    [cell setRecentSearches: searches];
    [cell setRecentsAutosaveName: unusedName];

    PASS([[cell recentsAutosaveName] isEqualToString: unusedName],
      "the autosave name is set");
    PASS([[cell recentSearches] count] == 2,
      "an autosave name with nothing saved leaves the searches alone");

    /* and a name with searches saved under it loads them */
    [[NSUserDefaults standardUserDefaults]
      setObject: [NSArray arrayWithObject: @"saved"]
         forKey: savedName];

    cell = AUTORELEASE([[NSSearchFieldCell alloc] initTextCell: @"find"]);
    [cell setRecentSearches: [NSArray arrayWithObjects: @"one", @"two", nil]];
    [cell setRecentsAutosaveName: savedName];
    PASS([[cell recentSearches] count] == 1
      && [[[cell recentSearches] objectAtIndex: 0] isEqualToString: @"saved"],
      "an autosave name with searches saved under it loads them");

    [[NSUserDefaults standardUserDefaults] removeObjectForKey: savedName];
  }

  END_SET("the recents autosave name")

  DESTROY(arp);
  return 0;
}
