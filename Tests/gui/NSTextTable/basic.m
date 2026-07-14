/* Coverage for NSTextBlock, NSTextTable and NSTextTableBlock: the defaults,
 * the dimension, width, colour and vertical alignment accessors, the table
 * defaults and flags, and the table block position accessors.  These are
 * plain value objects and need no backend.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTextTable.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("dimension constant values")
    PASS(NSTextBlockWidth == 0 && NSTextBlockMinimumWidth == 1
      && NSTextBlockMaximumWidth == 2 && NSTextBlockHeight == 4
      && NSTextBlockMinimumHeight == 5 && NSTextBlockMaximumHeight == 6,
      "the NSTextBlockDimension values match AppKit");
    PASS(NSTextBlockPadding == -1 && NSTextBlockBorder == 0
      && NSTextBlockMargin == 1,
      "the NSTextBlockLayer values match AppKit");
  END_SET("dimension constant values")

  START_SET("NSTextBlock defaults")
    NSTextBlock	*b = AUTORELEASE([[NSTextBlock alloc] init]);

    PASS([b verticalAlignment] == NSTextBlockTopAlignment,
      "the default vertical alignment is top");
    PASS(EQ([b valueForDimension: NSTextBlockWidth], 0.0),
      "a dimension defaults to zero");
    PASS(EQ([b widthForLayer: NSTextBlockBorder edge: NSMinXEdge], 0.0),
      "a layer width defaults to zero");
    PASS([b backgroundColor] == nil, "the default background colour is nil");
    PASS([b borderColorForEdge: NSMinXEdge] == nil,
      "the default border colour is nil");
  END_SET("NSTextBlock defaults")

  START_SET("NSTextBlock dimensions")
    NSTextBlock	*b = AUTORELEASE([[NSTextBlock alloc] init]);

    [b setValue: 50.0 type: NSTextBlockPercentageValueType
      forDimension: NSTextBlockMinimumWidth];
    PASS(EQ([b valueForDimension: NSTextBlockMinimumWidth], 50.0),
      "setValue:type:forDimension: stores the value");
    PASS([b valueTypeForDimension: NSTextBlockMinimumWidth]
      == NSTextBlockPercentageValueType,
      "setValue:type:forDimension: stores the value type");

    [b setContentWidth: 100.0 type: NSTextBlockAbsoluteValueType];
    PASS(EQ([b contentWidth], 100.0), "setContentWidth: sets the width dimension");
    PASS([b contentWidthValueType] == NSTextBlockAbsoluteValueType,
      "setContentWidth: sets the width value type");
  END_SET("NSTextBlock dimensions")

  START_SET("NSTextBlock widths")
    NSTextBlock	*b = AUTORELEASE([[NSTextBlock alloc] init]);

    [b setWidth: 3.0 type: NSTextBlockAbsoluteValueType
      forLayer: NSTextBlockBorder edge: NSMaxYEdge];
    PASS(EQ([b widthForLayer: NSTextBlockBorder edge: NSMaxYEdge], 3.0),
      "setWidth:type:forLayer:edge: stores the width for one edge");
    PASS([b widthValueTypeForLayer: NSTextBlockBorder edge: NSMaxYEdge]
      == NSTextBlockAbsoluteValueType,
      "setWidth:type:forLayer:edge: stores the width type");

    [b setWidth: 5.0 type: NSTextBlockAbsoluteValueType
      forLayer: NSTextBlockMargin];
    PASS(EQ([b widthForLayer: NSTextBlockMargin edge: NSMinXEdge], 5.0)
      && EQ([b widthForLayer: NSTextBlockMargin edge: NSMinYEdge], 5.0)
      && EQ([b widthForLayer: NSTextBlockMargin edge: NSMaxXEdge], 5.0)
      && EQ([b widthForLayer: NSTextBlockMargin edge: NSMaxYEdge], 5.0),
      "setWidth:type:forLayer: sets every edge");
  END_SET("NSTextBlock widths")

  START_SET("NSTextBlock colours and alignment")
    NSTextBlock	*b = AUTORELEASE([[NSTextBlock alloc] init]);

    [b setVerticalAlignment: NSTextBlockMiddleAlignment];
    PASS([b verticalAlignment] == NSTextBlockMiddleAlignment,
      "setVerticalAlignment: round trips");

    [b setBackgroundColor: [NSColor redColor]];
    PASS([[b backgroundColor] isEqual: [NSColor redColor]],
      "setBackgroundColor: round trips");

    [b setBorderColor: [NSColor blueColor] forEdge: NSMinXEdge];
    PASS([[b borderColorForEdge: NSMinXEdge] isEqual: [NSColor blueColor]],
      "setBorderColor:forEdge: sets one edge");
    PASS([b borderColorForEdge: NSMaxXEdge] == nil,
      "setBorderColor:forEdge: leaves the other edges alone");

    [b setBorderColor: [NSColor greenColor]];
    PASS([[b borderColorForEdge: NSMinXEdge] isEqual: [NSColor greenColor]]
      && [[b borderColorForEdge: NSMinYEdge] isEqual: [NSColor greenColor]]
      && [[b borderColorForEdge: NSMaxXEdge] isEqual: [NSColor greenColor]]
      && [[b borderColorForEdge: NSMaxYEdge] isEqual: [NSColor greenColor]],
      "setBorderColor: sets every edge");
  END_SET("NSTextBlock colours and alignment")

  START_SET("NSTextTable defaults and flags")
    NSTextTable	*t = AUTORELEASE([[NSTextTable alloc] init]);

    PASS([t numberOfColumns] == 0, "the default column count is zero");
    PASS([t layoutAlgorithm] == NSTextTableAutomaticLayoutAlgorithm,
      "the default layout algorithm is automatic");
    PASS([t collapsesBorders] == NO, "borders are not collapsed by default");
    PASS([t hidesEmptyCells] == NO, "empty cells are not hidden by default");

    [t setNumberOfColumns: 3];
    PASS([t numberOfColumns] == 3, "setNumberOfColumns: round trips");
    [t setLayoutAlgorithm: NSTextTableFixedLayoutAlgorithm];
    PASS([t layoutAlgorithm] == NSTextTableFixedLayoutAlgorithm,
      "setLayoutAlgorithm: round trips");
    [t setCollapsesBorders: YES];
    PASS([t collapsesBorders] == YES, "setCollapsesBorders: round trips");
    [t setHidesEmptyCells: YES];
    PASS([t hidesEmptyCells] == YES, "setHidesEmptyCells: round trips");
  END_SET("NSTextTable defaults and flags")

  START_SET("NSTextTableBlock position")
    NSTextTable	*t = AUTORELEASE([[NSTextTable alloc] init]);
    NSTextTableBlock	*tb = AUTORELEASE([[NSTextTableBlock alloc]
      initWithTable: t startingRow: 1 rowSpan: 2
      startingColumn: 3 columnSpan: 4]);

    PASS([tb startingRow] == 1, "the starting row is stored");
    PASS([tb rowSpan] == 2, "the row span is stored");
    PASS([tb startingColumn] == 3, "the starting column is stored");
    PASS([tb columnSpan] == 4, "the column span is stored");
    PASS([tb table] == t, "the table is stored");
  END_SET("NSTextTableBlock position")

  DESTROY(arp);
  return 0;
}
