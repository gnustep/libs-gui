/* A default NSToolbarItem tag is -1, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbarItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSToolbarItem *item;

  START_SET("NSToolbarItem tag")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  item = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"t"]);
  PASS([item tag] == -1, "default tag is -1");

  END_SET("NSToolbarItem tag")

  DESTROY(arp);
  return 0;
}
