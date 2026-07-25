/* Coverage for NSComboBox internal-list management (usesDataSource NO): adding,
   indexing, selecting, inserting, searching and removing object values.
   Checked against AppKit on a macOS runner.  The combo box uses the theme and
   font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSComboBox.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSComboBox *cb;

  START_SET("NSComboBox items")

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

  NS_DURING
    {
      cb = AUTORELEASE([[NSComboBox alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 22)]);

      [cb addItemWithObjectValue: @"alpha"];
      [cb addItemWithObjectValue: @"beta"];
      [cb addItemWithObjectValue: @"gamma"];
      PASS([cb numberOfItems] == 3, "three items were added");
      PASS([[cb itemObjectValueAtIndex: 1] isEqualToString: @"beta"],
           "the item at index one is the second added");

      [cb selectItemAtIndex: 2];
      PASS([cb indexOfSelectedItem] == 2, "selecting an item reports its index");
      PASS([[cb objectValueOfSelectedItem] isEqualToString: @"gamma"],
           "the selected item's object value is reported");

      [cb insertItemWithObjectValue: @"delta" atIndex: 0];
      PASS([cb numberOfItems] == 4, "inserting adds an item");
      PASS([[cb itemObjectValueAtIndex: 0] isEqualToString: @"delta"],
           "the inserted item is at the given index");
      PASS([cb indexOfItemWithObjectValue: @"beta"] == 2,
           "an item is found by its object value");

      [cb removeItemAtIndex: 0];
      PASS([cb numberOfItems] == 3, "removing an item drops the count");
      [cb removeAllItems];
      PASS([cb numberOfItems] == 0, "removeAllItems empties the list");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSComboBox items")

  DESTROY(arp);
  return 0;
}
