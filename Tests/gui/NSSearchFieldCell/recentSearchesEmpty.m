/* -recentSearches returns an empty array rather than nil for a cell that has
 * none, so that callers can enumerate the result without a nil check.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSearchFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("empty recent searches")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSSearchFieldCell	*cell;

    cell = AUTORELEASE([[NSSearchFieldCell alloc] initTextCell: @"find"]);
    PASS([cell recentSearches] != nil,
      "a new cell has an empty recent searches array");
    PASS([[cell recentSearches] count] == 0, "a new cell has no recent searches");

    [cell setRecentSearches: [NSArray arrayWithObject: @"one"]];
    PASS([[cell recentSearches] count] == 1, "the recent searches are set");

    [cell setRecentSearches: nil];
    PASS([cell recentSearches] != nil,
      "clearing the recent searches leaves an empty array");
    PASS([[cell recentSearches] count] == 0,
      "clearing the recent searches removes them");
  }

  END_SET("empty recent searches")

  DESTROY(arp);
  return 0;
}
