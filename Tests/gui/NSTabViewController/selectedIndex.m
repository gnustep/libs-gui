#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewController.h>

/* With no tab selected the selected index is -1, not a not-found sentinel.
   Needs a window server, so the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSTabViewController selected index")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSTabViewController *tc = AUTORELEASE([[NSTabViewController alloc] init]);
      NSTabView *tv = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 150)]);

      [tc setTabView: tv];
      PASS([tc selectedTabViewItemIndex] == -1,
        "an empty tab controller has a selected index of -1");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabViewController selected index")
  DESTROY(arp);
  return 0;
}
