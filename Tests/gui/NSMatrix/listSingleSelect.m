/* -[NSMatrix selectCellAtRow:column:] selects a single cell, deselecting
   any others, even in list mode, as OS X does.  (Mouse dragging, which
   uses other methods, still extends the selection.) */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSButtonCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMatrix list single selection")

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
    NSButtonCell *proto = AUTORELEASE([[NSButtonCell alloc] init]);
    NSMatrix *m = AUTORELEASE([[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                             mode: NSListModeMatrix
                                        prototype: proto
                                     numberOfRows: 2
                                  numberOfColumns: 2]);

    [m selectCellAtRow: 0 column: 1];
    [m selectCellAtRow: 1 column: 0];
    PASS([[m selectedCells] count] == 1,
      "selectCellAtRow:column: keeps a single selection in list mode");
    PASS([m selectedRow] == 1 && [m selectedColumn] == 0,
      "the last selected cell is the selected one");
  }

  END_SET("NSMatrix list single selection")

  DESTROY(arp);
  return 0;
}
