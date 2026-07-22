/* Removing an item from an NSPopUpButtonCell keeps the correct selection,
   as OS X does: removing the selected item selects the first remaining item
   (or clears the selection when the list becomes empty), and removing a
   different item leaves the selection on the item that was selected. */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSPopUpButtonCell.h>

static NSPopUpButtonCell *
popup(void)
{
  NSPopUpButtonCell *c = AUTORELEASE([[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown: NO]);

  [c addItemsWithTitles: [NSArray arrayWithObjects: @"a", @"b", @"c", @"d", nil]];
  return c;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSPopUpButtonCell remove selected")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  /* Removing the selected middle item selects the first item. */
  {
    NSPopUpButtonCell *c = popup();

    [c selectItemAtIndex: 1];
    [c removeItemAtIndex: 1];
    PASS([c indexOfSelectedItem] == 0
      && [[c titleOfSelectedItem] isEqualToString: @"a"],
      "removing the selected middle item selects the first item");
  }

  /* Removing the selected last item also selects the first item. */
  {
    NSPopUpButtonCell *c = popup();

    [c selectItemAtIndex: 3];
    [c removeItemAtIndex: 3];
    PASS([c indexOfSelectedItem] == 0
      && [[c titleOfSelectedItem] isEqualToString: @"a"],
      "removing the selected last item selects the first item");
  }

  /* Removing the only item clears the selection. */
  {
    NSPopUpButtonCell *c = AUTORELEASE([[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown: NO]);

    [c addItemWithTitle: @"only"];
    [c removeItemAtIndex: 0];
    PASS([c numberOfItems] == 0 && [c indexOfSelectedItem] == -1,
      "removing the only item clears the selection");
  }

  /* Removing an item before the selection leaves the selection on the same
     item, whose index shifts down. */
  {
    NSPopUpButtonCell *c = popup();

    [c selectItemAtIndex: 2];      /* c */
    [c removeItemAtIndex: 0];       /* -> b c d */
    PASS([c indexOfSelectedItem] == 1
      && [[c titleOfSelectedItem] isEqualToString: @"c"],
      "removing an earlier item keeps the selection on the same item");
  }

  END_SET("NSPopUpButtonCell remove selected")

  DESTROY(arp);
  return 0;
}
