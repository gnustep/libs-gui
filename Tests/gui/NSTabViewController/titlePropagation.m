#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTabViewController.h>

/* With title propagation on, selecting a tab sets the controller's title to
   that tab's label.  Needs a window server, so the set skips cleanly without
   one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSTabViewController title propagation")

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
        initWithFrame: NSMakeRect(0, 0, 220, 160)]);
      NSTabViewItem *item = AUTORELEASE([[NSTabViewItem alloc]
        initWithIdentifier: @"a"]);
      NSViewController *vc = AUTORELEASE([[NSViewController alloc] init]);

      [vc setView: AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 80)])];
      [item setViewController: vc];
      [item setLabel: @"Alpha"];

      [tc setTabView: tv];
      [tc addTabViewItem: item];
      [tc setSelectedTabViewItemIndex: 0];

      PASS([[tc title] isEqualToString: @"Alpha"],
        "selecting a tab propagates its label as the controller title");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabViewController title propagation")
  DESTROY(arp);
  return 0;
}
