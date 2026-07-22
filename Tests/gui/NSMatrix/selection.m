/* Tests NSMatrix cell selection: the single selection of radio mode (with its
 * automatic first selection and its refusal to empty the selection unless
 * allowed), the multiple selection of list mode, selectAll: and
 * deselectAllCells, and selectCellWithTag:.  These are plain model operations.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSButtonCell.h>

/* Build a 2x2 matrix in the given mode with tags 10..13 on its cells. */
static NSMatrix *
matrix(NSMatrixMode mode)
{
  NSButtonCell *proto = AUTORELEASE([[NSButtonCell alloc] init]);
  NSMatrix *m = AUTORELEASE([[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                           mode: mode
                                      prototype: proto
                                   numberOfRows: 2
                                numberOfColumns: 2]);
  int r, c, tag = 10;

  for (r = 0; r < 2; r++)
    for (c = 0; c < 2; c++)
      [[m cellAtRow: r column: c] setTag: tag++];
  return m;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMatrix cell selection")

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

  /* Radio mode selects the first cell automatically and does not allow an
   * empty selection by default. */
  {
    NSMatrix *m = matrix(NSRadioModeMatrix);

    PASS([m allowsEmptySelection] == NO,
      "radio mode disallows an empty selection by default");
    PASS([m selectedCell] != nil && [m selectedRow] == 0
      && [m selectedColumn] == 0 && [[m selectedCells] count] == 1,
      "radio mode selects the first cell automatically");
  }

  /* Radio mode keeps a single selection: selecting another cell moves it. */
  {
    NSMatrix *m = matrix(NSRadioModeMatrix);

    [m selectCellAtRow: 1 column: 1];
    PASS([m selectedRow] == 1 && [m selectedColumn] == 1
      && [[m selectedCells] count] == 1,
      "selecting another radio cell moves the single selection");
  }

  /* deselectAllCells is a no-op in radio mode unless empty selection is
   * allowed. */
  {
    NSMatrix *m = matrix(NSRadioModeMatrix);

    [m selectCellAtRow: 1 column: 0];
    [m deselectAllCells];
    PASS([m selectedCell] != nil && [m selectedRow] == 1
      && [m selectedColumn] == 0,
      "deselectAllCells keeps the selection when empty selection is disallowed");

    [m setAllowsEmptySelection: YES];
    [m deselectAllCells];
    PASS([m selectedCell] == nil && [m selectedRow] == -1
      && [m selectedColumn] == -1 && [[m selectedCells] count] == 0,
      "deselectAllCells clears the selection once empty selection is allowed");
  }

  /* selectCellWithTag: selects the tagged cell and reports whether it exists. */
  {
    NSMatrix *m = matrix(NSRadioModeMatrix);

    PASS([m selectCellWithTag: 13] == YES
      && [m selectedRow] == 1 && [m selectedColumn] == 1,
      "selectCellWithTag: selects the cell carrying the tag");
    PASS([m selectCellWithTag: 99] == NO,
      "selectCellWithTag: returns NO for an unknown tag");
  }

  /* List mode has no automatic selection. */
  {
    NSMatrix *m = matrix(NSListModeMatrix);

    PASS([m selectedCell] == nil && [[m selectedCells] count] == 0,
      "list mode starts with no selection");
  }

  /* selectAll: selects every cell in list mode; deselectAllCells clears it. */
  {
    NSMatrix *m = matrix(NSListModeMatrix);

    [m selectAll: nil];
    PASS([[m selectedCells] count] == 4, "selectAll: selects every cell");
    [m deselectAllCells];
    PASS([[m selectedCells] count] == 0
      && [m selectedCell] == nil,
      "deselectAllCells clears the list selection");
  }

  /* selectAll: does nothing in radio mode. */
  {
    NSMatrix *m = matrix(NSRadioModeMatrix);

    [m selectAll: nil];
    PASS([[m selectedCells] count] == 1,
      "selectAll: does not select multiple cells in radio mode");
  }

  END_SET("NSMatrix cell selection")

  DESTROY(arp);
  return 0;
}
