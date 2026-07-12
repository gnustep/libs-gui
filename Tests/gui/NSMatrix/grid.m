/* Coverage for the NSMatrix cell grid: the dimensions, adding, inserting
   and removing rows and columns, the prototype and cell class, the cell
   size and mode, locating a cell with getRow:column:ofCell: and by tag, and
   replacing a cell with putCell:atRow:column:.  The matrix builds cells from
   a prototype that touches the font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSMatrix.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMatrix grid")

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
                                  numberOfColumns: 3]);

    /* Dimensions and cells from the prototype. */
    pass([m numberOfRows] == 2 && [m numberOfColumns] == 3,
      "the matrix has the requested dimensions");
    pass([[m prototype] isKindOfClass: [NSButtonCell class]],
      "the prototype is the given cell");
    pass([[m cellAtRow: 0 column: 0] isKindOfClass: [NSButtonCell class]],
      "cells are built from the prototype");

    /* Adding rows and columns. */
    [m addRow];
    [m addColumn];
    pass([m numberOfRows] == 3 && [m numberOfColumns] == 4,
      "addRow and addColumn grow the grid");

    /* Inserting and removing. */
    [m insertRow: 1];
    pass([m numberOfRows] == 4, "insertRow: adds a row");
    [m removeRow: 0];
    pass([m numberOfRows] == 3, "removeRow: removes a row");
    [m removeColumn: 0];
    pass([m numberOfColumns] == 3, "removeColumn: removes a column");

    /* Locating a cell by its position. */
    {
      NSCell *cell = [m cellAtRow: 1 column: 2];
      NSInteger row = -1, col = -1;
      BOOL found = [m getRow: &row column: &col ofCell: cell];

      pass(found && row == 1 && col == 2,
        "getRow:column:ofCell: reports the cell's position");
    }

    /* Locating a cell by tag. */
    [[m cellAtRow: 0 column: 0] setTag: 77];
    pass([m cellWithTag: 77] == [m cellAtRow: 0 column: 0],
      "cellWithTag: finds the tagged cell");
    pass([m cellWithTag: 99] == nil, "cellWithTag: returns nil for an absent tag");

    /* Cell size and mode. */
    [m setCellSize: NSMakeSize(40.0, 18.0)];
    pass(NSEqualSizes([m cellSize], NSMakeSize(40.0, 18.0)), "setCellSize: round trips");
    [m setMode: NSRadioModeMatrix];
    pass([m mode] == NSRadioModeMatrix, "setMode: round trips");

    /* Replacing a cell. */
    {
      NSButtonCell *repl = AUTORELEASE([[NSButtonCell alloc] init]);

      [repl setTag: 555];
      [m putCell: repl atRow: 0 column: 0];
      pass([[m cellAtRow: 0 column: 0] tag] == 555,
        "putCell:atRow:column: replaces the cell");
    }
  }

  /* setCellClass: sets the class used for new cells. */
  {
    NSMatrix *m = AUTORELEASE([[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);

    [m setCellClass: [NSButtonCell class]];
    pass([m cellClass] == [NSButtonCell class], "setCellClass: sets the cell class");
  }

  END_SET("NSMatrix grid")

  DESTROY(arp);
  return 0;
}
