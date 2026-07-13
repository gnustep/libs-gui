/* Coverage for the NSComboBoxCell internal item list (the usesDataSource ==
   NO case): the defaults, adding/inserting/removing items, the item and
   object-value queries, selection by index and by object value, and the
   prefix completion of completedString:.  The cell builds a button cell in
   -init, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSComboBoxCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSComboBoxCell *cell;

  START_SET("NSComboBoxCell item list")

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
  cell = AUTORELEASE([[NSComboBoxCell alloc] initTextCell: @""]);
  pass([cell usesDataSource] == NO, "a combo box cell uses its own list by default");
  pass([cell hasVerticalScroller] == YES, "it has a vertical scroller by default");
  pass([cell completes] == NO, "automatic completion is off by default");
  pass([cell isButtonBordered] == YES, "the button is bordered by default");
  pass([cell numberOfItems] == 0, "a new combo box cell has no items");
  pass([cell indexOfSelectedItem] == -1, "a new combo box cell has no selection");

  /* Adding items. */
  [cell addItemWithObjectValue: @"alpha"];
  [cell addItemsWithObjectValues: [NSArray arrayWithObjects: @"beta", @"gamma", nil]];
  pass([cell numberOfItems] == 3, "adding items grows the list");
  pass([[cell itemObjectValueAtIndex: 0] isEqual: @"alpha"]
    && [[cell itemObjectValueAtIndex: 2] isEqual: @"gamma"],
    "itemObjectValueAtIndex: returns the item at the index");
  pass([[cell objectValues] isEqualToArray:
         ([NSArray arrayWithObjects: @"alpha", @"beta", @"gamma", nil])],
    "objectValues returns the items in order");
  pass([cell indexOfItemWithObjectValue: @"beta"] == 1,
    "indexOfItemWithObjectValue: finds the item");
  pass([cell indexOfItemWithObjectValue: @"missing"] == NSNotFound,
    "indexOfItemWithObjectValue: returns NSNotFound for an absent item");

  /* Inserting keeps the position. */
  [cell insertItemWithObjectValue: @"inserted" atIndex: 1];
  pass([[cell itemObjectValueAtIndex: 1] isEqual: @"inserted"]
    && [cell numberOfItems] == 4,
    "insertItemWithObjectValue:atIndex: inserts at the index");

  /* Selection by index and by object value. */
  [cell selectItemAtIndex: 2];   /* alpha, inserted, beta, gamma */
  pass([cell indexOfSelectedItem] == 2
    && [[cell objectValueOfSelectedItem] isEqual: @"beta"],
    "selectItemAtIndex: selects the item at the index");
  [cell selectItemWithObjectValue: @"alpha"];
  pass([cell indexOfSelectedItem] == 0,
    "selectItemWithObjectValue: selects the matching item");
  [cell selectItemWithObjectValue: @"nothere"];
  pass([cell indexOfSelectedItem] == 0,
    "selectItemWithObjectValue: leaves the selection when the value is absent");
  [cell deselectItemAtIndex: 0];
  pass([cell indexOfSelectedItem] == -1, "deselectItemAtIndex: clears the selection");

  /* Removing items. */
  [cell removeItemWithObjectValue: @"beta"];
  pass([cell numberOfItems] == 3
    && [cell indexOfItemWithObjectValue: @"beta"] == NSNotFound,
    "removeItemWithObjectValue: removes the item");
  [cell removeItemAtIndex: 0];
  pass([[cell itemObjectValueAtIndex: 0] isEqual: @"inserted"]
    && [cell numberOfItems] == 2,
    "removeItemAtIndex: removes the item at the index");
  [cell removeAllItems];
  pass([cell numberOfItems] == 0, "removeAllItems empties the list");

  /* Prefix completion. */
  cell = AUTORELEASE([[NSComboBoxCell alloc] initTextCell: @""]);
  [cell addItemsWithObjectValues:
    ([NSArray arrayWithObjects: @"Apple", @"Apricot", @"Banana", nil])];
  pass([[cell completedString: @"Ap"] isEqualToString: @"Apple"],
    "completedString: returns the first item with the given prefix");
  pass([[cell completedString: @"Ban"] isEqualToString: @"Banana"],
    "completedString: matches a later item by its prefix");

  END_SET("NSComboBoxCell item list")

  DESTROY(arp);
  return 0;
}
