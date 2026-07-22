/* Coverage for NSTabView membership: add / insert / remove, the item counts
   and indices, the item-to-tab-view wiring, and that the first item added
   becomes the selection. Every assertion matches AppKit (checked on a macOS
   runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSTabViewItem.h>

static NSTabViewItem *
mk(NSString *ident, NSString *label)
{
  NSTabViewItem *it = AUTORELEASE([[NSTabViewItem alloc]
    initWithIdentifier: ident]);
  [it setLabel: label];
  [it setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 50, 50)])];
  return it;
}

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTabView *tv;
  NSTabViewItem *a, *b, *c, *d;

  START_SET("NSTabView structure")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);

      PASS([tv numberOfTabViewItems] == 0, "a new tab view has no items");
      PASS([tv selectedTabViewItem] == nil,
           "a new tab view has no selection");

      a = mk(@"ia", @"A");
      b = mk(@"ib", @"B");
      c = mk(@"ic", @"C");

      [tv addTabViewItem: a];
      PASS([tv selectedTabViewItem] == a,
           "the first item added becomes the selection");
      PASS([a tabView] == tv, "an added item points back at the tab view");
      PASS([[a view] superview] != nil,
           "an added item's view is placed in the view hierarchy");

      [tv addTabViewItem: b];
      [tv addTabViewItem: c];
      PASS([tv numberOfTabViewItems] == 3, "three items were added");
      PASS([tv indexOfTabViewItem: b] == 1, "indexOfTabViewItem: finds b at 1");
      PASS([tv tabViewItemAtIndex: 1] == b, "tabViewItemAtIndex: 1 is b");
      PASS([tv indexOfTabViewItemWithIdentifier: @"ic"] == 2,
           "indexOfTabViewItemWithIdentifier: finds ic at 2");
      PASS([[tv tabViewItems] count] == 3, "tabViewItems has three entries");
      PASS([tv selectedTabViewItem] == a,
           "later adds do not change the selection");

      /* insert at an index */
      d = mk(@"id", @"D");
      [tv insertTabViewItem: d atIndex: 1];
      PASS([tv numberOfTabViewItems] == 4, "insert raises the count");
      PASS([tv tabViewItemAtIndex: 1] == d, "inserted item lands at its index");
      PASS([tv indexOfTabViewItem: b] == 2, "insert shifts later items up");

      /* remove */
      [tv removeTabViewItem: d];
      PASS([tv numberOfTabViewItems] == 3, "remove lowers the count");
      PASS([tv indexOfTabViewItem: b] == 1, "remove shifts later items down");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabView structure")

  DESTROY(arp);
  return 0;
}
