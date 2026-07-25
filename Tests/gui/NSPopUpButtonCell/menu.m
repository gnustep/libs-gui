/* Coverage for the NSPopUpButtonCell menu model: the defaults, adding /
   inserting / removing titled items, the automatic selection of the first
   item, the way a duplicate title moves the existing item, the item and
   index queries, selection by index and title, and the pull-down /
   autoenable / edge / arrow-position accessors.  The cell builds a menu in
   -init, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSPopUpButtonCell.h>

static NSPopUpButtonCell *
popup(void)
{
  return AUTORELEASE([[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown: NO]);
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSPopUpButtonCell *cell;

  START_SET("NSPopUpButtonCell menu")

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

  /* Defaults. */
  cell = popup();
  PASS([cell pullsDown] == NO, "a popup cell does not pull down by default");
  PASS([cell autoenablesItems] == YES, "items are auto-enabled by default");
  PASS([cell usesItemFromMenu] == YES, "it uses the item from the menu by default");
  PASS([cell altersStateOfSelectedItem] == YES, "it alters the selected item state by default");
  PASS([cell numberOfItems] == 0, "a new popup cell has no items");
  PASS([cell indexOfSelectedItem] == -1, "a new popup cell has no selection");

  /* Adding the first item selects it automatically. */
  cell = popup();
  [cell addItemWithTitle: @"alpha"];
  PASS([cell numberOfItems] == 1 && [cell indexOfSelectedItem] == 0
    && [[cell titleOfSelectedItem] isEqualToString: @"alpha"],
    "adding the first item selects it");
  [cell addItemsWithTitles: [NSArray arrayWithObjects: @"beta", @"gamma", nil]];
  PASS([cell numberOfItems] == 3 && [cell indexOfSelectedItem] == 0,
    "adding more items leaves the first one selected");
  PASS([[cell itemTitles] isEqualToArray:
         ([NSArray arrayWithObjects: @"alpha", @"beta", @"gamma", nil])],
    "itemTitles returns the titles in order");

  /* A duplicate title moves the existing item rather than adding another. */
  [cell addItemWithTitle: @"beta"];
  PASS([cell numberOfItems] == 3 && [cell indexOfItemWithTitle: @"beta"] == 2,
    "re-adding a title moves the item to the end without duplicating it");

  /* Inserting at a position. */
  cell = popup();
  [cell addItemsWithTitles: [NSArray arrayWithObjects: @"a", @"b", @"c", nil]];
  [cell insertItemWithTitle: @"inserted" atIndex: 1];
  PASS([[cell itemTitleAtIndex: 1] isEqualToString: @"inserted"]
    && [cell numberOfItems] == 4,
    "insertItemWithTitle:atIndex: inserts at the index");

  /* Item and index queries. */
  cell = popup();
  [cell addItemsWithTitles: [NSArray arrayWithObjects: @"one", @"two", @"three", nil]];
  PASS([cell indexOfItemWithTitle: @"two"] == 1, "indexOfItemWithTitle: finds the item");
  PASS([cell indexOfItemWithTitle: @"missing"] == -1,
    "indexOfItemWithTitle: returns -1 for an absent title");
  PASS([cell itemWithTitle: @"three"] != nil, "itemWithTitle: returns the item");
  PASS([[[cell lastItem] title] isEqualToString: @"three"], "lastItem returns the last item");
  PASS([[cell itemAtIndex: 0] title] != nil, "itemAtIndex: returns the item at the index");

  /* Tag lookup. */
  [[cell itemAtIndex: 2] setTag: 42];
  PASS([cell indexOfItemWithTag: 42] == 2, "indexOfItemWithTag: finds the tagged item");
  PASS([cell indexOfItemWithTag: 99] == -1, "indexOfItemWithTag: returns -1 for an absent tag");

  /* Selection by index and title. */
  [cell selectItemAtIndex: 2];
  PASS([cell indexOfSelectedItem] == 2
    && [[cell titleOfSelectedItem] isEqualToString: @"three"],
    "selectItemAtIndex: selects the item at the index");
  [cell selectItemWithTitle: @"one"];
  PASS([cell indexOfSelectedItem] == 0, "selectItemWithTitle: selects the matching item");

  /* Removing by title, and clearing the whole list. */
  [cell removeItemWithTitle: @"two"];
  PASS([cell numberOfItems] == 2 && [cell indexOfItemWithTitle: @"two"] == -1,
    "removeItemWithTitle: removes the item");
  [cell removeAllItems];
  PASS([cell numberOfItems] == 0 && [cell indexOfSelectedItem] == -1,
    "removeAllItems empties the list and clears the selection");

  /* Property accessors round-trip. */
  cell = popup();
  [cell setPullsDown: YES];
  PASS([cell pullsDown] == YES, "setPullsDown: round trips");
  [cell setAutoenablesItems: NO];
  PASS([cell autoenablesItems] == NO, "setAutoenablesItems: round trips");
  [cell setPreferredEdge: NSMinXEdge];
  PASS([cell preferredEdge] == NSMinXEdge, "setPreferredEdge: round trips");
  [cell setArrowPosition: NSPopUpArrowAtBottom];
  PASS([cell arrowPosition] == NSPopUpArrowAtBottom, "setArrowPosition: round trips");

  END_SET("NSPopUpButtonCell menu")

  DESTROY(arp);
  return 0;
}
