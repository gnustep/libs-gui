#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSSplitViewItem.h>
#import <AppKit/NSSplitViewController.h>

/* Adding, inserting and removing split items on a freshly created controller
   updates its item list.  Needs a window server, so the set skips cleanly
   without one. */

static NSSplitViewItem *
anItem(void)
{
  NSSplitViewItem *item = AUTORELEASE([[NSSplitViewItem alloc] init]);
  NSViewController *vc = AUTORELEASE([[NSViewController alloc] init]);
  [vc setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 120, 100)])];
  [item setViewController: vc];
  return item;
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSplitViewController add items")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSplitViewController *svc = AUTORELEASE([[NSSplitViewController alloc] init]);
      NSSplitViewItem *it1 = anItem();
      NSSplitViewItem *it2 = anItem();
      NSSplitViewItem *it3 = anItem();

      [svc addSplitViewItem: it1];
      PASS([[svc splitViewItems] count] == 1, "adding an item grows the list");

      [svc addSplitViewItem: it2];
      PASS([[svc splitViewItems] count] == 2, "a second item is added");

      [svc insertSplitViewItem: it3 atIndex: 0];
      PASS([[svc splitViewItems] count] == 3, "an item is inserted");
      PASS([[svc splitViewItems] objectAtIndex: 0] == it3,
        "the item is inserted at the requested index");

      [svc removeSplitViewItem: it1];
      PASS([[svc splitViewItems] count] == 2, "removing an item shrinks the list");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSplitViewController add items")
  DESTROY(arp);
  return 0;
}
