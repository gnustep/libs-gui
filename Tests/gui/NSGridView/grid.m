/* Coverage for NSGridView grid management: the constructor's row and column
   counts, the cell at an index, adding and removing rows, and the column
   spacing round-trip.  Checked against AppKit on a macOS runner.  The grid
   uses the theme and font backend, so the set is skipped when the backend is
   unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSGridView.h>
#include <AppKit/NSView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSGridView *g;

  START_SET("NSGridView grid")

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
      g = [NSGridView gridViewWithNumberOfColumns: 2 rows: 3];

      PASS([g numberOfColumns] == 2, "the constructor sets the column count");
      PASS([g numberOfRows] == 3, "the constructor sets the row count");
      PASS([g cellAtColumnIndex: 1 rowIndex: 2] != nil,
           "there is a cell at a valid column and row");

      NSView *v1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]);
      NSView *v2 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]);
      [g addRowWithViews: [NSArray arrayWithObjects: v1, v2, nil]];
      PASS([g numberOfRows] == 4, "addRowWithViews: adds a row");
      [g removeRowAtIndex: 0];
      PASS([g numberOfRows] == 3, "removeRowAtIndex: drops a row");

      [g setColumnSpacing: 12.0];
      PASS([g columnSpacing] == 12.0, "setColumnSpacing: round trips");
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

  END_SET("NSGridView grid")

  DESTROY(arp);
  return 0;
}
