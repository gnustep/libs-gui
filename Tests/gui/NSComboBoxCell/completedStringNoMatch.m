/* -[NSComboBoxCell completedString:] returns nil when no item completes the
   substring, as OS X does, rather than echoing the substring back. */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSComboBoxCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSComboBoxCell completedString: no match")

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

  {
    NSComboBoxCell *cell = AUTORELEASE([[NSComboBoxCell alloc] initTextCell: @""]);

    [cell addItemsWithObjectValues:
      ([NSArray arrayWithObjects: @"Apple", @"Apricot", @"Banana", nil])];
    pass([cell completedString: @"xyz"] == nil,
      "completedString: returns nil when no item completes the substring");
    pass([[cell completedString: @"Ap"] isEqualToString: @"Apple"],
      "completedString: still returns a matching completion");
  }

  END_SET("NSComboBoxCell completedString: no match")

  DESTROY(arp);
  return 0;
}
