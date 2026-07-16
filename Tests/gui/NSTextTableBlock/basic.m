/* Coverage for NSTextTableBlock: the initialiser and its getters, the text
 * block defaults it inherits, and what a copy keeps.  Every assertion here
 * matches AppKit (verified on a macOS runner) and passes on unmodified
 * GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextTable.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSTextTableBlock basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTextTable		*table;
    NSTextTableBlock	*block;
    NSTextTableBlock	*copy;

    /* the initialiser */
    table = AUTORELEASE([[NSTextTable alloc] init]);
    block = AUTORELEASE([[NSTextTableBlock alloc] initWithTable: table
                                                   startingRow: 1
                                                       rowSpan: 2
                                                startingColumn: 3
                                                    columnSpan: 4]);
    PASS(block != nil, "a text table block is created");
    PASS([block table] == table, "the block keeps the table it was given");
    PASS([block startingRow] == 1, "the starting row reads back");
    PASS([block rowSpan] == 2, "the row span reads back");
    PASS([block startingColumn] == 3, "the starting column reads back");
    PASS([block columnSpan] == 4, "the column span reads back");

    /* what it inherits from NSTextBlock */
    PASS([block contentWidth] == 0, "a new block has no content width");
    PASS([block contentWidthValueType] == NSTextBlockAbsoluteValueType,
      "a new block's content width is an absolute value");
    PASS([block backgroundColor] == nil, "a new block has no background colour");

    /* the table it belongs to */
    PASS([table numberOfColumns] == 0, "a new table has no columns");
    PASS([table collapsesBorders] == NO,
      "a new table does not collapse its borders");
    PASS([table hidesEmptyCells] == NO, "a new table does not hide empty cells");
    PASS([table layoutAlgorithm] == NSTextTableAutomaticLayoutAlgorithm,
      "a new table lays itself out automatically");

    /* copying */
    [block setContentWidth: 25.0 type: NSTextBlockAbsoluteValueType];
    copy = AUTORELEASE([block copy]);
    PASS(copy != nil && [copy isKindOfClass: [NSTextTableBlock class]],
      "copying a block returns a text table block");
    PASS([copy table] == table, "the copy keeps the table");
    PASS([copy startingRow] == 1 && [copy rowSpan] == 2
      && [copy startingColumn] == 3 && [copy columnSpan] == 4,
      "the copy keeps the row and column it covers");
    PASS([copy contentWidth] == 25.0, "the copy keeps the content width");
  }

  END_SET("NSTextTableBlock basic")

  DESTROY(arp);
  return 0;
}
