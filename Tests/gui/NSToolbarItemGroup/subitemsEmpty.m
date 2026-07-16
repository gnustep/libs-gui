/* -subitems returns an empty array rather than nil for a group that has none,
 * both for a new group and after the subitems have been set back to nil, so
 * that callers can enumerate the result without a nil check.
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

  START_SET("empty subitems")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSToolbarItemGroup	*group;
    NSToolbarItem	*subitem;

    group = AUTORELEASE([[NSToolbarItemGroup alloc]
      initWithItemIdentifier: @"group"]);
    PASS([group subitems] != nil, "a new group has an empty subitems array");
    PASS([[group subitems] count] == 0, "a new group has no subitems");

    subitem = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"s"]);
    [group setSubitems: [NSArray arrayWithObject: subitem]];
    PASS([[group subitems] count] == 1, "the subitems are set");

    [group setSubitems: nil];
    PASS([group subitems] != nil,
      "clearing the subitems leaves an empty array");
    PASS([[group subitems] count] == 0, "clearing the subitems removes them");
  }

  END_SET("empty subitems")

  DESTROY(arp);
  return 0;
}
