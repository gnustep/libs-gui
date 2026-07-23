#import "Testing.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSSplitViewItem.h>
#import <AppKit/NSSplitViewController.h>

/* NSSplitViewController split-item management: setting the items, looking one
   up by its view controller, and the split view round-trip.  Needs a window
   server, so the set skips cleanly without one. */

static NSSplitViewItem *
itemForController(NSViewController **outVC)
{
  NSSplitViewItem *item = AUTORELEASE([[NSSplitViewItem alloc] init]);
  NSViewController *vc = AUTORELEASE([[NSViewController alloc] init]);
  [vc setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 120, 100)])];
  [item setViewController: vc];
  if (outVC != NULL)
    *outVC = vc;
  return item;
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSplitViewController items")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSplitViewController *svc = AUTORELEASE([[NSSplitViewController alloc] init]);
      NSSplitView *sv = AUTORELEASE([[NSSplitView alloc]
        initWithFrame: NSMakeRect(0, 0, 240, 160)]);
      NSViewController *vc1 = nil;
      NSSplitViewItem *it1 = itemForController(&vc1);
      NSSplitViewItem *it2 = itemForController(NULL);

      [svc setSplitView: sv];
      PASS([svc splitView] == sv, "the split view round-trips");

      [svc setSplitViewItems: [NSArray arrayWithObjects: it1, it2, nil]];
      PASS([[svc splitViewItems] count] == 2,
        "setting the items populates the list");
      PASS([[svc splitViewItems] objectAtIndex: 0] == it1,
        "the items keep their order");
      PASS([svc splitViewItemForViewController: vc1] == it1,
        "an item is found by its view controller");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSplitViewController items")
  DESTROY(arp);
  return 0;
}
