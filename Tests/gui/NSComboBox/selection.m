/* NSComboBox internal-list selection tracking across insertion and removal
   (usesDataSource NO).  The raw selected index is kept when an item is inserted
   or when a removal leaves the index inside the list, and it is reset to -1 when
   a removal leaves it past the last item.  The relationships were checked
   against AppKit on a macOS runner.  The combo box uses the theme and font
   backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSComboBox.h>

static NSComboBox *
threeItemComboBox(void)
{
  NSComboBox *cb = AUTORELEASE([[NSComboBox alloc]
    initWithFrame: NSMakeRect(0, 0, 120, 22)]);

  [cb addItemWithObjectValue: @"alpha"];
  [cb addItemWithObjectValue: @"beta"];
  [cb addItemWithObjectValue: @"gamma"];
  return cb;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSComboBox *cb;

  START_SET("NSComboBox selection")

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
      /* Inserting an item before the selection keeps the raw index; the
         selection then reports the item that moved into that slot. */
      cb = threeItemComboBox();
      [cb selectItemAtIndex: 2];
      [cb insertItemWithObjectValue: @"delta" atIndex: 0];
      PASS([cb indexOfSelectedItem] == 2,
           "an insertion before the selection keeps the selected index");
      PASS([[cb objectValueOfSelectedItem] isEqualToString: @"beta"],
           "the selection reports the item now at the kept index");

      /* A removal that leaves the selected index past the last item resets the
         selection to -1. */
      cb = threeItemComboBox();
      [cb selectItemAtIndex: 2];
      [cb removeItemAtIndex: 0];
      PASS([cb indexOfSelectedItem] == -1,
           "a removal that leaves the index out of range resets the selection");
      PASS([cb objectValueOfSelectedItem] == nil,
           "the reset selection has no object value");

      /* A removal that leaves the selected index inside the list keeps it; the
         selection then reports the item now at that index. */
      cb = threeItemComboBox();
      [cb selectItemAtIndex: 1];
      [cb removeItemAtIndex: 1];
      PASS([cb indexOfSelectedItem] == 1,
           "a removal that leaves the index in range keeps the selection");
      PASS([[cb objectValueOfSelectedItem] isEqualToString: @"gamma"],
           "the kept selection reports the item now at its index");

      /* Removing by object value follows the same rule. */
      cb = threeItemComboBox();
      [cb selectItemAtIndex: 2];
      [cb removeItemWithObjectValue: @"alpha"];
      PASS([cb indexOfSelectedItem] == -1,
           "removeItemWithObjectValue: resets a now out-of-range selection");

      /* Removing every item clears the selection. */
      cb = threeItemComboBox();
      [cb selectItemAtIndex: 1];
      [cb removeAllItems];
      PASS([cb indexOfSelectedItem] == -1,
           "removeAllItems clears the selection");
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

  END_SET("NSComboBox selection")

  DESTROY(arp);
  return 0;
}
