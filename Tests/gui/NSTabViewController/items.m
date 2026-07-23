#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTabViewController.h>

/* NSTabViewController tab-item management: adding, inserting, removing and
   looking up items backed by view controllers, and the selected index.
   Needs a window server, so the set skips cleanly without one. */

static NSTabViewItem *
itemForController(NSString *ident, NSViewController **outVC)
{
  NSTabViewItem *item = AUTORELEASE([[NSTabViewItem alloc]
    initWithIdentifier: ident]);
  NSViewController *vc = AUTORELEASE([[NSViewController alloc] init]);
  [vc setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 80)])];
  [item setViewController: vc];
  if (outVC != NULL)
    *outVC = vc;
  return item;
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSTabViewController items")

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
      NSViewController *vc1 = nil;
      NSTabViewItem *it1 = itemForController(@"a", &vc1);
      NSTabViewItem *it2 = itemForController(@"b", NULL);
      NSTabViewItem *it3 = itemForController(@"c", NULL);

      [tc setTabView: tv];
      PASS([tc tabView] == tv, "the tab view round-trips");
      PASS([[tc tabViewItems] count] == 0, "a fresh controller has no items");

      [tc addTabViewItem: it1];
      PASS([[tc tabViewItems] count] == 1, "adding an item grows the list");
      PASS([tc selectedTabViewItemIndex] == 0,
        "the first added item is selected");
      PASS([tc tabViewItemForViewController: vc1] == it1,
        "an item is found by its view controller");

      [tc addTabViewItem: it2];
      PASS([[tc tabViewItems] count] == 2, "a second item is added");

      [tc setSelectedTabViewItemIndex: 1];
      PASS([tc selectedTabViewItemIndex] == 1, "the selected index round-trips");

      [tc removeTabViewItem: it1];
      PASS([[tc tabViewItems] count] == 1, "removing an item shrinks the list");

      [tc insertTabViewItem: it3 atIndex: 0];
      PASS([[tc tabViewItems] count] == 2, "an item is inserted");
      PASS([[tc tabViewItems] objectAtIndex: 0] == it3,
        "the item is inserted at the requested index");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabViewController items")
  DESTROY(arp);
  return 0;
}
