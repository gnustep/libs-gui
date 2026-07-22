/* Coverage for the NSBrowser configuration: the selection, column and title
   flags, the path separator, the column width and count limits, the column
   resizing type and the cell prototype, plus their accessors.  Several
   defaults follow GNUstep's own configuration and differ from current
   macOS; the test documents the behaviour GNUstep implements.  The browser
   uses the theme and font backend, so the set is skipped when the backend
   is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSBrowser *browser;

  START_SET("NSBrowser config")

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

  browser = AUTORELEASE([[NSBrowser alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)]);

  /* Defaults that match macOS. */
  PASS([browser allowsEmptySelection] == YES, "empty selection is allowed by default");
  PASS([browser reusesColumns] == NO, "columns are not reused by default");
  PASS([browser takesTitleFromPreviousColumn] == YES,
       "a column takes its title from the previous one by default");
  PASS([browser separatesColumns] == YES, "columns are separated by default");
  PASS([browser isTitled] == YES, "the browser is titled by default");
  PASS([browser prefersAllColumnUserResizing] == NO,
       "it does not prefer all-column user resizing by default");
  PASS([[browser pathSeparator] isEqualToString: @"/"], "the path separator is a slash");
  PASS([browser minColumnWidth] == 100.0, "the default minimum column width is 100");
  PASS([[browser cellPrototype] isKindOfClass: [NSBrowserCell class]],
       "the cell prototype is an NSBrowserCell");

  /* Defaults that follow GNUstep's configuration (macOS differs here). */
  PASS([browser allowsBranchSelection] == YES, "branch selection is allowed by default");
  PASS([browser allowsMultipleSelection] == YES, "multiple selection is allowed by default");
  PASS([browser hasHorizontalScroller] == YES, "it has a horizontal scroller by default");
  PASS([browser sendsActionOnArrowKeys] == YES, "it sends the action on arrow keys by default");
  PASS([browser maxVisibleColumns] == 3, "up to three columns are visible by default");
  PASS([browser columnResizingType] == NSBrowserNoColumnResizing,
       "columns do not resize by default");

  /* Accessors round-trip. */
  [browser setAllowsMultipleSelection: NO];
  PASS([browser allowsMultipleSelection] == NO, "setAllowsMultipleSelection: round trips");
  [browser setAllowsBranchSelection: NO];
  PASS([browser allowsBranchSelection] == NO, "setAllowsBranchSelection: round trips");
  [browser setAllowsEmptySelection: NO];
  PASS([browser allowsEmptySelection] == NO, "setAllowsEmptySelection: round trips");
  [browser setHasHorizontalScroller: NO];
  PASS([browser hasHorizontalScroller] == NO, "setHasHorizontalScroller: round trips");
  [browser setSendsActionOnArrowKeys: NO];
  PASS([browser sendsActionOnArrowKeys] == NO, "setSendsActionOnArrowKeys: round trips");
  [browser setReusesColumns: YES];
  PASS([browser reusesColumns] == YES, "setReusesColumns: round trips");
  [browser setPathSeparator: @":"];
  PASS([[browser pathSeparator] isEqualToString: @":"], "setPathSeparator: round trips");
  [browser setMinColumnWidth: 120.0];
  PASS([browser minColumnWidth] == 120.0, "setMinColumnWidth: round trips");
  [browser setMaxVisibleColumns: 4];
  PASS([browser maxVisibleColumns] == 4, "setMaxVisibleColumns: round trips");
  [browser setColumnResizingType: NSBrowserUserColumnResizing];
  PASS([browser columnResizingType] == NSBrowserUserColumnResizing,
       "setColumnResizingType: round trips");

  /* A titled browser keeps its columns separated: separatesColumns only
     changes once the browser is no longer titled. */
  [browser setSeparatesColumns: NO];
  PASS([browser separatesColumns] == YES,
       "separatesColumns is unchanged while the browser is titled");
  [browser setTitled: NO];
  PASS([browser isTitled] == NO, "setTitled: round trips");
  [browser setSeparatesColumns: NO];
  PASS([browser separatesColumns] == NO,
       "separatesColumns changes once the browser is not titled");

  END_SET("NSBrowser config")

  DESTROY(arp);
  return 0;
}
