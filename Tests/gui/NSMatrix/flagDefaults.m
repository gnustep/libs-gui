/* A new NSMatrix does not autosize its cells and does not let the tab key
   traverse cells, as AppKit does. Both round-trip once set. Checked against
   AppKit on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSMatrix *m;

  START_SET("NSMatrix flagDefaults")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      m = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);

      PASS([m autosizesCells] == NO,
           "a new matrix does not autosize its cells");
      PASS([m tabKeyTraversesCells] == NO,
           "a new matrix does not let the tab key traverse cells");

      [m setAutosizesCells: YES];
      PASS([m autosizesCells] == YES, "autosizesCells round-trips");
      [m setTabKeyTraversesCells: YES];
      PASS([m tabKeyTraversesCells] == YES, "tabKeyTraversesCells round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMatrix flagDefaults")

  DESTROY(arp);
  return 0;
}
