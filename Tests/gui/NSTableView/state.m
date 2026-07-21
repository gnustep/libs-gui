/* Coverage for NSTableView scalar state: the selection and column flag
   defaults, the header/corner/colour accessors, and the setter round-trips.
   Machine dependent geometry (rowHeight, intercellSpacing) is not asserted for
   its value, only that it round-trips. Checked against AppKit on a macOS
   runner; all pass on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTableView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableView *tv;

  START_SET("NSTableView state")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);

      pass([tv allowsColumnReordering] == YES,
           "columns are reorderable by default");
      pass([tv allowsColumnResizing] == YES,
           "columns are resizable by default");
      pass([tv allowsMultipleSelection] == NO,
           "multiple selection is off by default");
      pass([tv allowsEmptySelection] == YES,
           "empty selection is allowed by default");
      pass([tv usesAlternatingRowBackgroundColors] == NO,
           "alternating row colours are off by default");
      pass([tv headerView] != nil, "a table has a header view");
      pass([tv cornerView] != nil, "a table has a corner view");
      pass([tv backgroundColor] != nil, "a table has a background colour");
      pass([tv gridColor] != nil, "a table has a grid colour");
      pass([tv numberOfColumns] == 0, "a new table has no columns");
      pass([tv numberOfRows] == 0, "a new table with no data source has no rows");
      pass([tv selectedRow] == -1, "no row is selected by default");
      pass([tv selectedColumn] == -1, "no column is selected by default");
      pass([tv numberOfSelectedRows] == 0, "no rows are selected by default");

      /* round-trips */
      [tv setRowHeight: 24.0];
      pass([tv rowHeight] == 24.0, "rowHeight round-trips");
      [tv setAllowsMultipleSelection: YES];
      pass([tv allowsMultipleSelection] == YES,
           "allowsMultipleSelection round-trips");
      [tv setUsesAlternatingRowBackgroundColors: YES];
      pass([tv usesAlternatingRowBackgroundColors] == YES,
           "usesAlternatingRowBackgroundColors round-trips");
      [tv setBackgroundColor: [NSColor redColor]];
      pass([[tv backgroundColor] isEqual: [NSColor redColor]],
           "backgroundColor round-trips");
      [tv setIntercellSpacing: NSMakeSize(4, 6)];
      {
        NSSize s = [tv intercellSpacing];
        pass(s.width == 4 && s.height == 6, "intercellSpacing round-trips");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView state")

  DESTROY(arp);
  return 0;
}
