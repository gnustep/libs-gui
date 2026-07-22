/* A new NSTableView does not allow column selection, as AppKit does. It
   round-trips once set. Checked against AppKit on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableView *tv;

  START_SET("NSTableView columnSelectionDefault")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      PASS([tv allowsColumnSelection] == NO,
           "a new table does not allow column selection");

      [tv setAllowsColumnSelection: YES];
      PASS([tv allowsColumnSelection] == YES,
           "allowsColumnSelection round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView columnSelectionDefault")

  DESTROY(arp);
  return 0;
}
