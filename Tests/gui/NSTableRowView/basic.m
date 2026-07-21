/* Coverage for NSTableRowView: the selection highlight style enumeration, the
 * init defaults and the setter round-trips.  Every assertion here matches
 * AppKit (verified on a macOS runner) and passes on unmodified GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTableRowView.h>
#include <AppKit/NSTableView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSTableRowView basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTableRowView	*view;
    NSColor		*color;

    /* the enumeration */
    PASS(NSTableViewSelectionHighlightStyleNone == -1
      && NSTableViewSelectionHighlightStyleRegular == 0
      && NSTableViewSelectionHighlightStyleSourceList == 1,
      "the selection highlight styles have their AppKit values");

    /* init defaults */
    view = AUTORELEASE([[NSTableRowView alloc]
      initWithFrame: NSMakeRect(0, 0, 100, 20)]);
    PASS(view != nil, "a table row view is created");
    PASS([view isEmphasized] == NO, "a new row view is not emphasized");
    PASS([view isFloating] == NO, "a new row view is not floating");
    PASS([view isSelected] == NO, "a new row view is not selected");
    PASS([view isNextRowSelected] == NO,
      "a new row view has no next row selected");
    PASS([view isPreviousRowSelected] == NO,
      "a new row view has no previous row selected");
    PASS([view selectionHighlightStyle]
      == NSTableViewSelectionHighlightStyleRegular,
      "a new row view has the regular selection highlight style");
    PASS([view interiorBackgroundStyle] == NSBackgroundStyleNormal,
      "a new row view has the normal interior background style");
    PASS([view indentationForDropOperation] == 0,
      "a new row view has no drop indentation");
    PASS([view numberOfColumns] == 0, "a row view on its own has no columns");
    PASS([view backgroundColor] == nil,
      "a new row view has no background colour");

    /* setter round-trips */
    color = [NSColor redColor];
    [view setEmphasized: YES];
    [view setFloating: YES];
    [view setSelected: YES];
    [view setNextRowSelected: YES];
    [view setPreviousRowSelected: YES];
    [view setIndentationForDropOperation: 12.5];
    [view setBackgroundColor: color];
    [view setSelectionHighlightStyle:
      NSTableViewSelectionHighlightStyleSourceList];

    PASS([view isEmphasized] == YES, "emphasized round-trips");
    PASS([view isFloating] == YES, "floating round-trips");
    PASS([view isSelected] == YES, "selected round-trips");
    PASS([view isNextRowSelected] == YES, "the next row selection round-trips");
    PASS([view isPreviousRowSelected] == YES,
      "the previous row selection round-trips");
    PASS([view indentationForDropOperation] == 12.5,
      "the drop indentation round-trips");
    PASS([view backgroundColor] == color, "the background colour reads back");
    PASS([view selectionHighlightStyle]
      == NSTableViewSelectionHighlightStyleSourceList,
      "the selection highlight style round-trips");
  }

  END_SET("NSTableRowView basic")

  DESTROY(arp);
  return 0;
}
