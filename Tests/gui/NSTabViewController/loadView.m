#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTabViewController.h>

/* A programmatic NSTabViewController creates its own NSTabView on first access
   to its view, so tab items can be managed without setting a tab view by hand.
   Needs a window server, so the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSTabViewController loadView")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSTabViewController *tc = AUTORELEASE([[NSTabViewController alloc] init]);
      NSTabViewItem *item = AUTORELEASE([[NSTabViewItem alloc]
        initWithIdentifier: @"a"]);

      PASS([tc tabView] != nil
        && [[tc tabView] isKindOfClass: [NSTabView class]],
        "the controller creates a tab view without one being set");

      [tc addTabViewItem: item];
      PASS([[tc tabViewItems] count] == 1,
        "items can be added to the created tab view");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabViewController loadView")
  DESTROY(arp);
  return 0;
}
