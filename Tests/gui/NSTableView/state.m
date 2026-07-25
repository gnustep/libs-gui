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

      PASS([tv allowsColumnReordering] == YES,
           "columns are reorderable by default");
      PASS([tv allowsColumnResizing] == YES,
           "columns are resizable by default");
      PASS([tv allowsMultipleSelection] == NO,
           "multiple selection is off by default");
      PASS([tv allowsEmptySelection] == YES,
           "empty selection is allowed by default");
      PASS([tv usesAlternatingRowBackgroundColors] == NO,
           "alternating row colours are off by default");
      PASS([tv headerView] != nil, "a table has a header view");
      PASS([tv cornerView] != nil, "a table has a corner view");
      PASS([tv backgroundColor] != nil, "a table has a background colour");
      PASS([tv gridColor] != nil, "a table has a grid colour");
      PASS([tv numberOfColumns] == 0, "a new table has no columns");
      PASS([tv numberOfRows] == 0, "a new table with no data source has no rows");
      PASS([tv selectedRow] == -1, "no row is selected by default");
      PASS([tv selectedColumn] == -1, "no column is selected by default");
      PASS([tv numberOfSelectedRows] == 0, "no rows are selected by default");

      /* round-trips */
      [tv setRowHeight: 24.0];
      PASS([tv rowHeight] == 24.0, "rowHeight round-trips");
      [tv setAllowsMultipleSelection: YES];
      PASS([tv allowsMultipleSelection] == YES,
           "allowsMultipleSelection round-trips");
      [tv setUsesAlternatingRowBackgroundColors: YES];
      PASS([tv usesAlternatingRowBackgroundColors] == YES,
           "usesAlternatingRowBackgroundColors round-trips");
      [tv setBackgroundColor: [NSColor redColor]];
      PASS([[tv backgroundColor] isEqual: [NSColor redColor]],
           "backgroundColor round-trips");
      [tv setIntercellSpacing: NSMakeSize(4, 6)];
      {
        NSSize s = [tv intercellSpacing];
        PASS(s.width == 4 && s.height == 6, "intercellSpacing round-trips");
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
