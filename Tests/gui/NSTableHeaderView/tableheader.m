/* Coverage for NSTableHeaderView, driven by a table view with two columns: the
   header is wired to its table view, no column is being dragged or resized, the
   per-column header rectangles run left to right with positive widths, and
   columnAtPoint: maps a point back to its column.  The exact header rectangle
   metrics are theme dependent and are not compared against AppKit; the
   relationships and the point mapping are.  Checked against AppKit on a macOS
   runner.  The header uses the theme and font backend, so the set is skipped
   when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableHeaderView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableView *tv;

  START_SET("NSTableHeaderView tableheader")

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
      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);
      NSTableColumn *c0 = AUTORELEASE([[NSTableColumn alloc]
        initWithIdentifier: @"c0"]);
      NSTableColumn *c1 = AUTORELEASE([[NSTableColumn alloc]
        initWithIdentifier: @"c1"]);
      [c0 setWidth: 50.0];
      [c1 setWidth: 50.0];
      [tv addTableColumn: c0];
      [tv addTableColumn: c1];

      NSTableHeaderView *h = [tv headerView];

      PASS(h != nil, "a table view has a header view");
      PASS([h tableView] == tv, "the header is wired to its table view");
      PASS([h draggedColumn] == -1, "no column is being dragged");
      PASS([h resizedColumn] == -1, "no column is being resized");

      NSRect r0 = [h headerRectOfColumn: 0];
      NSRect r1 = [h headerRectOfColumn: 1];
      PASS(r0.size.width > 0.0 && r1.size.width > 0.0,
           "the header rectangles have positive widths");
      PASS(r1.origin.x > r0.origin.x,
           "the second column's header is to the right of the first");
      PASS([h columnAtPoint: NSMakePoint(NSMidX(r0), NSMidY(r0))] == 0,
           "a point in the first header maps to column zero");
      PASS([h columnAtPoint: NSMakePoint(NSMidX(r1), NSMidY(r1))] == 1,
           "a point in the second header maps to column one");
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

  END_SET("NSTableHeaderView tableheader")

  DESTROY(arp);
  return 0;
}
