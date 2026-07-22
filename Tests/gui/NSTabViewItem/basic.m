/* Coverage for NSTabViewItem: the init defaults (identifier, view, initial
   first responder, tabState, toolTip, viewController) and the plain setter
   round-trips for the identifier, label and toolTip.  Every assertion here
   matches AppKit (verified on a macOS runner) and passes on unmodified
   GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTabViewItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTabViewItem *item;

  START_SET("NSTabViewItem basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* init defaults */
  item = AUTORELEASE([[NSTabViewItem alloc] initWithIdentifier: @"myId"]);
  PASS([[item identifier] isEqual: @"myId"],
       "identifier is the identifier passed in");
  PASS([item view] != nil, "a new item has a view");
  PASS([item initialFirstResponder] == nil,
       "default initialFirstResponder is nil");
  PASS([item tabState] == NSBackgroundTab, "default tabState is background");
  PASS([item toolTip] == nil, "default toolTip is nil");
  PASS([item viewController] == nil, "default viewController is nil");

  /* setter round-trips */
  item = AUTORELEASE([[NSTabViewItem alloc] initWithIdentifier: @"x"]);
  [item setIdentifier: @"ID2"];
  [item setLabel: @"L"];
  [item setToolTip: @"T"];
  PASS([[item identifier] isEqual: @"ID2"], "identifier round-trips");
  PASS([[item label] isEqualToString: @"L"], "label round-trips");
  PASS([[item toolTip] isEqualToString: @"T"], "toolTip round-trips");

  END_SET("NSTabViewItem basic")

  DESTROY(arp);
  return 0;
}
