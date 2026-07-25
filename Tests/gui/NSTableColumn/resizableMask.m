/* An NSTableColumn's resizable flag and its resizing mask stay consistent,
   as on OS X: setResizingMask: with no resizing makes the column not
   resizable, and setResizable: sets the mask to the auto/user resizing
   combination or to no resizing. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableColumn.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSTableColumn resizable / mask")

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

  /* The resizing mask drives isResizable. */
  {
    NSTableColumn *col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"c"]);

    [col setResizingMask: NSTableColumnNoResizing];
    PASS([col isResizable] == NO, "a no-resizing mask makes the column not resizable");
    [col setResizingMask: NSTableColumnUserResizingMask];
    PASS([col isResizable] == YES, "a user-resizing mask makes the column resizable");
  }

  /* setResizable: drives the mask. */
  {
    NSTableColumn *col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"c"]);

    [col setResizable: NO];
    PASS([col resizingMask] == NSTableColumnNoResizing
      && [col isResizable] == NO,
      "setResizable: NO clears the resizing mask");
    [col setResizable: YES];
    PASS([col resizingMask] == (NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask)
      && [col isResizable] == YES,
      "setResizable: YES sets the auto and user resizing mask");
  }

  END_SET("NSTableColumn resizable / mask")

  DESTROY(arp);
  return 0;
}
