/* Coverage for NSTabView selection: selectTabViewItemAtIndex:, the
   first / last / next / previous movers, selectedTabViewItem, and the
   NSTabState transitions on the items. Every assertion matches AppKit
   (checked on a macOS runner) and passes on unmodified GNUstep. */
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
  NSTabViewItem *a, *b, *c;

  START_SET("NSTabView selection")

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
      a = mk(@"ia", @"A");
      b = mk(@"ib", @"B");
      c = mk(@"ic", @"C");
      [tv addTabViewItem: a];
      [tv addTabViewItem: b];
      [tv addTabViewItem: c];

      /* the selected item is NSSelectedTab, the others NSBackgroundTab */
      pass([a tabState] == NSSelectedTab,
           "the selected item's tabState is NSSelectedTab");
      pass([b tabState] == NSBackgroundTab,
           "an unselected item's tabState is NSBackgroundTab");

      [tv selectTabViewItemAtIndex: 2];
      pass([tv selectedTabViewItem] == c,
           "selectTabViewItemAtIndex: 2 selects c");
      pass([c tabState] == NSSelectedTab, "c becomes NSSelectedTab");
      pass([a tabState] == NSBackgroundTab,
           "the previously selected a returns to NSBackgroundTab");

      [tv selectFirstTabViewItem: nil];
      pass([tv selectedTabViewItem] == a, "selectFirstTabViewItem: selects a");
      [tv selectLastTabViewItem: nil];
      pass([tv selectedTabViewItem] == c, "selectLastTabViewItem: selects c");

      [tv selectFirstTabViewItem: nil];
      [tv selectNextTabViewItem: nil];
      pass([tv selectedTabViewItem] == b,
           "selectNextTabViewItem: moves from a to b");
      [tv selectPreviousTabViewItem: nil];
      pass([tv selectedTabViewItem] == a,
           "selectPreviousTabViewItem: moves from b to a");

      /* removing the selected item leaves a valid selection */
      [tv selectTabViewItemAtIndex: 1];
      [tv removeTabViewItem: b];
      pass([tv numberOfTabViewItems] == 2, "the item count drops after remove");
      pass([tv selectedTabViewItem] != nil,
           "a selection survives removing the selected item");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabView selection")

  DESTROY(arp);
  return 0;
}
