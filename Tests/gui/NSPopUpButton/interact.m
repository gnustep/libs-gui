/* Interaction coverage for NSPopUpButton: choosing an item (the programmatic
   equivalent of picking from the menu) updates the selection - the selected
   index, title and item all track the choice - and selecting by title finds
   the right item.  The pop up uses the font/graphics backend, so the set is
   skipped when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSMenuItem.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSPopUpButton *b;

  START_SET("NSPopUpButton interaction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      b = AUTORELEASE([[NSPopUpButton alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 24) pullsDown: NO]);
      [b addItemsWithTitles:
        [NSArray arrayWithObjects: @"Alpha", @"Bravo", @"Charlie", nil]];

      PASS([b numberOfItems] == 3, "the pop up has the three added items");
      PASS([b indexOfSelectedItem] == 0,
        "the first item is selected by default");

      /* Choosing the third item tracks through index, title and item. */
      [b selectItemAtIndex: 2];
      PASS([b indexOfSelectedItem] == 2, "selecting an item updates the index");
      PASS([[b titleOfSelectedItem] isEqual: @"Charlie"],
        "selecting an item updates the title");
      PASS([b selectedItem] == [b itemAtIndex: 2],
        "the selected item is the chosen item");

      /* Choosing by title finds the right item. */
      [b selectItemWithTitle: @"Bravo"];
      PASS([b indexOfSelectedItem] == 1,
        "selecting by title updates the index");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSPopUpButton interaction")

  DESTROY(arp);
  return 0;
}
