/* A delegate gets to change the selection a click proposes in a column. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSIndexSet.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSMatrix.h>

static NSArray *rows;

@interface Chooser : NSObject
{
@public
  NSInteger calls;
  NSIndexSet *proposed;
  NSInteger inColumn;
  NSIndexSet *answer;		// Not retained
  BOOL answerWithProposed;
}
@end

@implementation Chooser
- (void) dealloc
{
  DESTROY(proposed);
  DEALLOC
}
- (NSInteger) browser: (NSBrowser *)sender numberOfRowsInColumn: (NSInteger)column
{
  return [rows count];
}
- (void) browser: (NSBrowser *)sender
 willDisplayCell: (id)cell
	   atRow: (NSInteger)row
	  column: (NSInteger)column
{
  [cell setStringValue: [rows objectAtIndex: row]];
  [cell setLeaf: YES];
}
- (NSIndexSet *) browser: (NSBrowser *)browser
selectionIndexesForProposedSelection: (NSIndexSet *)proposedSelectionIndexes
		inColumn: (NSInteger)column
{
  calls++;
  ASSIGN(proposed, proposedSelectionIndexes);
  inColumn = column;
  return answerWithProposed ? proposedSelectionIndexes : answer;
}
@end

static NSBrowser *
browserWithDelegate(id delegate)
{
  NSBrowser *browser = AUTORELEASE([[NSBrowser alloc]
    initWithFrame: NSMakeRect(0, 0, 400, 200)]);

  [browser setDelegate: delegate];
  [browser loadColumnZero];
  return browser;
}

/* The matrix carries the selection a click has just made, then tells the
   browser about it, which is what a click in a column comes down to. */
static void
clickRow(NSBrowser *browser, NSInteger row)
{
  NSMatrix *matrix = [browser matrixInColumn: 0];

  [matrix deselectAllCells];
  [matrix selectCellAtRow: row column: 0];
  [browser doClick: matrix];
}

int
main(int argc, const char **argv)
{
  NSBrowser *browser;
  Chooser *chooser;

  START_SET("NSBrowser proposed selection delegate method")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  rows = [NSArray arrayWithObjects: @"alpha", @"beta", @"Bravo", @"charlie",
		  @"delta", nil];

  NS_DURING
    {
      chooser = AUTORELEASE([[Chooser alloc] init]);
      chooser->answerWithProposed = YES;
      browser = browserWithDelegate(chooser);
      clickRow(browser, 1);
      PASS(chooser->calls == 1,
	"clicking a row asks the delegate what the selection should be");
      PASS([chooser->proposed isEqualToIndexSet:
	     [NSIndexSet indexSetWithIndex: 1]],
	"the delegate is told which row the click proposes");
      PASS(chooser->inColumn == 0,
	"the delegate is told which column the click was in");
      PASS([browser selectedRowInColumn: 0] == 1,
	"a delegate that hands the proposal back leaves the selection alone");

      chooser = AUTORELEASE([[Chooser alloc] init]);
      chooser->answer = [NSIndexSet indexSetWithIndex: 3];
      browser = browserWithDelegate(chooser);
      clickRow(browser, 1);
      PASS([browser selectedRowInColumn: 0] == 3,
	"the row the delegate returns is the row that ends up selected");

      chooser = AUTORELEASE([[Chooser alloc] init]);
      chooser->answer = [NSIndexSet indexSet];
      browser = browserWithDelegate(chooser);
      clickRow(browser, 1);
      PASS([browser selectedRowInColumn: 0] == -1,
	"an empty answer leaves the column with nothing selected");

      chooser = AUTORELEASE([[Chooser alloc] init]);
      chooser->answer = nil;
      browser = browserWithDelegate(chooser);
      clickRow(browser, 1);
      PASS(chooser->calls == 1 && [browser selectedRowInColumn: 0] == 1,
	"a delegate that answers nothing leaves the selection alone");

      chooser = AUTORELEASE([[Chooser alloc] init]);
      chooser->answerWithProposed = YES;
      browser = browserWithDelegate(chooser);
      [browser selectRow: 2 inColumn: 0];
      PASS(chooser->calls == 0,
	"selecting a row in code is not a proposal the delegate rules on");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSBrowser proposed selection delegate method")


  return 0;
}
