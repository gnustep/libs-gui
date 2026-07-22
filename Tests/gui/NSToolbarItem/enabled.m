/* A fresh NSToolbarItem is enabled by default, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbarItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSToolbarItem *item;

  START_SET("NSToolbarItem enabled")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  item = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"e"]);
  PASS([item isEnabled] == YES, "a fresh toolbar item is enabled by default");

  END_SET("NSToolbarItem enabled")

  DESTROY(arp);
  return 0;
}
