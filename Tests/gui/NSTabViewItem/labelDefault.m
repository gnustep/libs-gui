/* A default NSTabViewItem label is the empty string, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTabViewItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTabViewItem *item;

  START_SET("NSTabViewItem labelDefault")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  item = AUTORELEASE([[NSTabViewItem alloc] initWithIdentifier: @"l"]);
  PASS([[item label] isEqualToString: @""],
       "default label is the empty string");

  END_SET("NSTabViewItem labelDefault")

  DESTROY(arp);
  return 0;
}
