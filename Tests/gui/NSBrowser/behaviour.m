/* Behavioural coverage for NSBrowser under a passive delegate: loading
   column zero, branch and leaf selection, the column the selection reaches,
   the selection path and setPath:.  Column 0 holds three rows (two branches
   and a leaf); each branch's child column holds two leaves.  The values are
   checked against AppKit on a macOS runner.  The browser uses the theme and
   font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>

@interface BrowserContent : NSObject
@end

@implementation BrowserContent
- (NSInteger) browser: (NSBrowser *)sender numberOfRowsInColumn: (NSInteger)column
{
  if (column == 0) return 3;
  if (column == 1) return 2;
  return 0;
}
- (void) browser: (NSBrowser *)sender
  willDisplayCell: (id)cell
            atRow: (NSInteger)row
           column: (NSInteger)column
{
  if (column == 0)
    {
      [cell setStringValue: [NSString stringWithFormat: @"c0r%ld", (long)row]];
      [cell setLeaf: (row == 2)];
    }
  else
    {
      [cell setStringValue: [NSString stringWithFormat: @"c1r%ld", (long)row]];
      [cell setLeaf: YES];
    }
}
- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (NSInteger)column
{
  return [NSString stringWithFormat: @"col%ld", (long)column];
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSBrowser *browser;
  BrowserContent *content;

  START_SET("NSBrowser behaviour")

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
      content = AUTORELEASE([BrowserContent new]);
      browser = AUTORELEASE([[NSBrowser alloc]
        initWithFrame: NSMakeRect(0, 0, 300, 200)]);
      [browser setDelegate: content];

      /* Nothing is loaded or selected yet. */
      pass([browser selectedColumn] == -1,
           "no column is selected before loading");
      pass([browser lastColumn] == -1, "no column is loaded before loading");

      /* Loading column zero loads but does not select. */
      [browser loadColumnZero];
      pass([browser lastColumn] == 0, "column zero is the last column after loading it");
      pass([browser selectedColumn] == -1,
           "loading column zero selects nothing");
      pass([browser matrixInColumn: 0] != nil,
           "column zero has a matrix after loading");
      pass([[[browser loadedCellAtRow: 0 column: 0] stringValue]
             isEqualToString: @"c0r0"],
           "the delegate titles the first cell of column zero");
      pass([[browser loadedCellAtRow: 0 column: 0] isLeaf] == NO,
           "the first row of column zero is a branch");
      pass([[browser loadedCellAtRow: 2 column: 0] isLeaf] == YES,
           "the third row of column zero is a leaf");
      pass([[browser titleOfColumn: 0] isEqualToString: @"col0"],
           "the delegate titles column zero");

      /* Selecting a branch row loads the next column. */
      [browser selectRow: 0 inColumn: 0];
      pass([browser selectedColumn] == 0,
           "column zero is selected after selecting a row in it");
      pass([browser selectedRowInColumn: 0] == 0,
           "the selected row in column zero is row zero");
      pass([[[browser selectedCell] stringValue] isEqualToString: @"c0r0"],
           "the selected cell is the branch cell");
      pass([browser lastColumn] == 1,
           "selecting a branch loads the next column");

      /* Descending selects a leaf in the child column. */
      [browser selectRow: 1 inColumn: 1];
      pass([browser selectedColumn] == 1,
           "the child column is selected after selecting a row in it");
      pass([browser selectedRowInColumn: 1] == 1,
           "the selected row in the child column is row one");
      pass([[[browser selectedCell] stringValue] isEqualToString: @"c1r1"],
           "the selected cell is the child leaf");
      pass([[browser path] isEqualToString: @"/c0r0/c1r1"],
           "the path names the branch and the leaf");

      /* setPath: drives the selection down a named path. */
      NSBrowser *b2 = AUTORELEASE([[NSBrowser alloc]
        initWithFrame: NSMakeRect(0, 0, 300, 200)]);
      [b2 setDelegate: content];
      [b2 loadColumnZero];
      pass([b2 setPath: @"/c0r1/c1r0"] == YES, "setPath: accepts a valid path");
      pass([[b2 path] isEqualToString: @"/c0r1/c1r0"], "setPath: round trips");
      pass([b2 selectedColumn] == 1, "setPath: leaves the leaf column selected");
      pass([[[b2 selectedCell] stringValue] isEqualToString: @"c1r0"],
           "setPath: selects the named leaf");
      pass([[b2 pathToColumn: 1] isEqualToString: @"/c0r1"],
           "pathToColumn: returns the path up to that column");
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

  END_SET("NSBrowser behaviour")

  DESTROY(arp);
  return 0;
}
