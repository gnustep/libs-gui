#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSDrawer.h>

/* A new drawer places no lower bound on its content size and does not cap the
   maximum at the initial size, so it can grow.  Creating a drawer builds a
   drawer window, so the set skips cleanly without a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSDrawer content size defaults")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSDrawer *d = AUTORELEASE([[NSDrawer alloc]
        initWithContentSize: NSMakeSize(100, 100)
              preferredEdge: NSMinXEdge]);

      PASS(NSEqualSizes([d minContentSize], NSZeroSize),
        "a new drawer has no minimum content size");
      PASS([d maxContentSize].width > 100.0 && [d maxContentSize].height > 100.0,
        "a new drawer's maximum content size is not capped at the initial size");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSDrawer content size defaults")
  DESTROY(arp);
  return 0;
}
