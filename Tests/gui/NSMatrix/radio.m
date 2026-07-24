/* Coverage for NSMatrix radio-mode single selection and cell geometry:
   selecting one cell turns the previously selected one off, selectedRow /
   selectedColumn track the selection, and cellFrameAtRow:column: follows the
   cell size and intercell spacing. Every assertion matches AppKit (checked on
   a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSMatrix *r;
  NSButtonCell *proto;

  START_SET("NSMatrix radio")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      proto = AUTORELEASE([[NSButtonCell alloc] init]);
      r = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)
                 mode: NSRadioModeMatrix
            prototype: proto
         numberOfRows: 2
      numberOfColumns: 2]);

      PASS([r numberOfRows] == 2, "the matrix has two rows");
      PASS([r numberOfColumns] == 2, "the matrix has two columns");

      [r selectCellAtRow: 0 column: 0];
      PASS([r selectedRow] == 0, "selectedRow is 0 after selecting (0,0)");
      PASS([r selectedColumn] == 0, "selectedColumn is 0 after selecting (0,0)");
      PASS([r selectedCell] != nil, "there is a selected cell");

      [r selectCellAtRow: 1 column: 1];
      PASS([r selectedRow] == 1, "selectedRow follows to 1");
      PASS([r selectedColumn] == 1, "selectedColumn follows to 1");
      PASS([[r cellAtRow: 0 column: 0] state] == NSOffState,
           "radio mode turns the previously selected cell off");
      PASS([[r cellAtRow: 1 column: 1] state] == NSOnState,
           "the newly selected cell is on");

      /* geometry from an explicit cell size and zero intercell spacing */
      [r setIntercellSpacing: NSMakeSize(0, 0)];
      [r setCellSize: NSMakeSize(40, 20)];
      {
        NSRect f00 = [r cellFrameAtRow: 0 column: 0];
        NSRect f11 = [r cellFrameAtRow: 1 column: 1];
        PASS(NSEqualRects(f00, NSMakeRect(0, 0, 40, 20)),
             "cellFrameAtRow:0 column:0 is the first cell rect");
        PASS(NSEqualRects(f11, NSMakeRect(40, 20, 40, 20)),
             "cellFrameAtRow:1 column:1 is offset by the cell size");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMatrix radio")

  DESTROY(arp);
  return 0;
}
