/* A new NSOutlineView autoresizes its outline column, as AppKit does. It
   round-trips once set. Checked against AppKit on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSOutlineView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSOutlineView *ov;

  START_SET("NSOutlineView autoresizesOutlineColumnDefault")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      ov = AUTORELEASE([[NSOutlineView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      PASS([ov autoresizesOutlineColumn] == YES,
           "a new outline view autoresizes its outline column");

      [ov setAutoresizesOutlineColumn: NO];
      PASS([ov autoresizesOutlineColumn] == NO,
           "autoresizesOutlineColumn round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOutlineView autoresizesOutlineColumnDefault")

  DESTROY(arp);
  return 0;
}
