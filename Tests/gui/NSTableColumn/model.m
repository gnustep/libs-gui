/* Coverage for the NSTableColumn model: the identifier, the defaults, the
   width clamping done by setWidth:/setMinWidth:/setMaxWidth:, the resizing
   mask, the title (which goes through the header cell), the default header
   and data cells, and the editable/hidden accessors.  The column builds a
   header and data cell in -init, so the set is skipped when the backend is
   unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSTextFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableColumn *col;

  START_SET("NSTableColumn model")

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

  /* Identifier and defaults. */
  col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"col1"]);
  pass([[col identifier] isEqual: @"col1"], "initWithIdentifier: stores the identifier");
  pass([col width] == 100.0, "the default width is 100");
  pass([col minWidth] == 10.0, "the default minimum width is 10");
  pass([col resizingMask] == (NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask),
       "the default resizing mask allows auto and user resizing");
  pass([col isResizable] == YES, "a column is resizable by default");
  pass([col isEditable] == YES, "a column is editable by default");
  pass([col isHidden] == NO, "a column is not hidden by default");
  pass([[col headerCell] isKindOfClass: [NSTableHeaderCell class]],
       "the default header cell is an NSTableHeaderCell");
  pass([[col dataCell] isKindOfClass: [NSTextFieldCell class]],
       "the default data cell is an NSTextFieldCell");

  /* Width clamping to [minWidth, maxWidth]. */
  [col setMinWidth: 20.0];
  [col setMaxWidth: 200.0];
  [col setWidth: 50.0];
  pass([col width] == 50.0, "a width within the range is kept");
  [col setWidth: 5.0];
  pass([col width] == 20.0, "a width below the minimum clamps to the minimum");
  [col setWidth: 500.0];
  pass([col width] == 200.0, "a width above the maximum clamps to the maximum");

  /* Changing the bounds pushes the width. */
  [col setWidth: 100.0];
  [col setMinWidth: 150.0];
  pass([col width] == 150.0, "raising the minimum above the width pushes the width up");
  [col setWidth: 180.0];
  [col setMaxWidth: 160.0];
  pass([col width] == 160.0, "lowering the maximum below the width pushes the width down");

  /* The resizing mask round-trips. */
  [col setResizingMask: NSTableColumnUserResizingMask];
  pass([col resizingMask] == NSTableColumnUserResizingMask, "setResizingMask: round trips");

  /* The title goes through the header cell. */
  [col setTitle: @"Name"];
  pass([[col title] isEqualToString: @"Name"], "setTitle: sets the title");
  pass([[[col headerCell] stringValue] isEqualToString: @"Name"],
       "the title is the header cell's string value");

  /* Simple accessors. */
  [col setEditable: NO];
  pass([col isEditable] == NO, "setEditable: round trips");
  [col setHidden: YES];
  pass([col isHidden] == YES, "setHidden: round trips");
  [col setIdentifier: @"other"];
  pass([[col identifier] isEqual: @"other"], "setIdentifier: round trips");

  END_SET("NSTableColumn model")

  DESTROY(arp);
  return 0;
}
