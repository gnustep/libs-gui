/* Coverage for NSMenuItemCell: init defaults (needs sizing, not highlighted,
   does not need display), setMenuItem: (identity, needs sizing afterwards, tag
   taken from the item), and the highlighted / needsSizing / needsDisplay
   setters.  Every assertion was checked against Apple AppKit (macOS 26) and
   matches.  Creating the cell pulls in the menu font, which needs the backend,
   so the body is guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSMenuItemCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuItemCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSMenuItemCell *c = [[NSMenuItemCell alloc] init];
  PASS(c != nil, "NSMenuItemCell -init returns an instance");

  /* Defaults that match AppKit. */
  PASS([c needsSizing] == YES, "a fresh cell needs sizing");
  PASS([c isHighlighted] == NO, "a fresh cell is not highlighted");
  PASS([c needsDisplay] == NO, "a fresh cell does not need display");

  /* setMenuItem: keeps the item, flags for sizing and drives -tag. */
  NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: @"Item"
                                                action: NULL
                                         keyEquivalent: @""];
  [item setTag: 42];
  [c setMenuItem: item];
  PASS([c menuItem] == item, "setMenuItem: keeps the same item");
  PASS([c needsSizing] == YES, "setMenuItem: flags the cell for sizing");
  PASS([c tag] == 42, "-tag comes from the menu item");

  /* Flag setters round-trip. */
  [c setHighlighted: YES];
  PASS([c isHighlighted] == YES, "setHighlighted: round-trips");

  [c setNeedsSizing: NO];
  PASS([c needsSizing] == NO, "setNeedsSizing: round-trips");

  [c setNeedsDisplay: YES];
  PASS([c needsDisplay] == YES, "setNeedsDisplay: round-trips");

  RELEASE(item);
  RELEASE(c);

  END_SET("NSMenuItemCell basic")

  DESTROY(arp);
  return 0;
}
