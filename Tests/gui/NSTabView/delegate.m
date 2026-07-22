/* Coverage for the NSTabView delegate: didSelect fires on selection,
   tabViewDidChangeNumberOfTabViewItems fires when the item count changes, and
   a shouldSelect of NO keeps the current selection. Every assertion matches
   AppKit (checked on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSTabViewItem.h>

@interface Recorder : NSObject
{
@public
  NSString *lastDidSelect;
  int changeCount;
  BOOL vetoB;
}
@end

@implementation Recorder
- (BOOL) tabView: (NSTabView *)tv shouldSelectTabViewItem: (NSTabViewItem *)it
{
  if (vetoB && [[it label] isEqualToString: @"B"])
    return NO;
  return YES;
}
- (void) tabView: (NSTabView *)tv didSelectTabViewItem: (NSTabViewItem *)it
{
  ASSIGN(lastDidSelect, [it label]);
}
- (void) tabViewDidChangeNumberOfTabViewItems: (NSTabView *)tv
{
  changeCount++;
}
@end

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
  Recorder *rec;

  START_SET("NSTabView delegate")

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
      rec = AUTORELEASE([Recorder new]);
      [tv setDelegate: rec];
      PASS([tv delegate] == rec, "delegate round-trips");

      [tv addTabViewItem: mk(@"ia", @"A")];
      [tv addTabViewItem: mk(@"ib", @"B")];
      PASS(rec->changeCount == 2,
           "tabViewDidChangeNumberOfTabViewItems: fires on each add");

      [tv selectTabViewItemAtIndex: 1];
      PASS([rec->lastDidSelect isEqualToString: @"B"],
           "didSelectTabViewItem: reports the newly selected item");

      /* veto keeps the current selection */
      tv = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      rec = AUTORELEASE([Recorder new]);
      rec->vetoB = YES;
      [tv setDelegate: rec];
      [tv addTabViewItem: mk(@"pa", @"A")];
      [tv addTabViewItem: mk(@"pb", @"B")];
      [tv selectTabViewItemAtIndex: 1];
      PASS([[[tv selectedTabViewItem] label] isEqualToString: @"A"],
           "a shouldSelect of NO keeps the current selection");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabView delegate")

  DESTROY(arp);
  return 0;
}
