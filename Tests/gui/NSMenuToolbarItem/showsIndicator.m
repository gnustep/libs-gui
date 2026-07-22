/* A new menu toolbar item shows its indicator, and the initialiser gives it the
 * indicator image to match.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenuToolbarItem.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("showsIndicator default")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSMenuToolbarItem	*item;

    item = AUTORELEASE([[NSMenuToolbarItem alloc]
      initWithItemIdentifier: @"myItem"]);
    PASS([item showsIndicator] == YES, "a new item shows its indicator");
    PASS([item image] != nil, "a new item has the indicator image");

    [item setShowsIndicator: NO];
    PASS([item showsIndicator] == NO, "showsIndicator round-trips when unset");
    [item setShowsIndicator: YES];
    PASS([item showsIndicator] == YES, "showsIndicator round-trips when set");
  }

  END_SET("showsIndicator default")

  DESTROY(arp);
  return 0;
}
