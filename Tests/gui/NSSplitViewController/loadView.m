#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSSplitViewController.h>

/* A programmatic NSSplitViewController creates its own NSSplitView on first
   access to its view.  Needs a window server, so the set skips cleanly without
   one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSplitViewController loadView")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSplitViewController *svc = AUTORELEASE([[NSSplitViewController alloc] init]);

      PASS([svc splitView] != nil
        && [[svc splitView] isKindOfClass: [NSSplitView class]],
        "the controller creates a split view without one being set");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSplitViewController loadView")
  DESTROY(arp);
  return 0;
}
