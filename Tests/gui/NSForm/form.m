/* Coverage for NSForm entry management: adding entries as form cells, the
   entry count, the cell at an index, finding a cell by tag and removing an
   entry.  Checked against AppKit on a macOS runner.  The form uses the theme
   and font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSForm *f;

  START_SET("NSForm form")

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
      f = AUTORELEASE([[NSForm alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);

      pass([f numberOfRows] == 0, "a new form has no entries");

      NSFormCell *e0 = [f addEntry: @"Name"];
      NSFormCell *e1 = [f addEntry: @"Email"];
      [e1 setTag: 42];

      pass([e0 isKindOfClass: [NSFormCell class]],
           "addEntry: returns a form cell");
      pass([f numberOfRows] == 2, "adding two entries makes two rows");
      pass([f cellAtIndex: 0] == e0, "the cell at index zero is the first entry");
      pass([[[f cellAtIndex: 1] title] isEqualToString: @"Email"],
           "the second entry keeps its title");
      pass([f indexOfCellWithTag: 42] == 1, "an entry is found by its tag");

      [f removeEntryAtIndex: 0];
      pass([f numberOfRows] == 1, "removing an entry drops a row");
      pass([[[f cellAtIndex: 0] title] isEqualToString: @"Email"],
           "the remaining entry shifts into index zero");
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

  END_SET("NSForm form")

  DESTROY(arp);
  return 0;
}
