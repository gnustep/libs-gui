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
  pass([browser allowsEmptySelection] == YES, "empty selection is allowed by default");
  pass([browser reusesColumns] == NO, "columns are not reused by default");
  pass([browser takesTitleFromPreviousColumn] == YES,
       "a column takes its title from the previous one by default");
  pass([browser separatesColumns] == YES, "columns are separated by default");
  pass([browser isTitled] == YES, "the browser is titled by default");
  pass([browser prefersAllColumnUserResizing] == NO,
       "it does not prefer all-column user resizing by default");
  pass([[browser pathSeparator] isEqualToString: @"/"], "the path separator is a slash");
  pass([browser minColumnWidth] == 100.0, "the default minimum column width is 100");
  pass([[browser cellPrototype] isKindOfClass: [NSBrowserCell class]],
       "the cell prototype is an NSBrowserCell");

  /* Defaults that follow GNUstep's configuration (macOS differs here). */
  pass([browser allowsBranchSelection] == YES, "branch selection is allowed by default");
  pass([browser allowsMultipleSelection] == YES, "multiple selection is allowed by default");
  pass([browser hasHorizontalScroller] == YES, "it has a horizontal scroller by default");
  pass([browser sendsActionOnArrowKeys] == YES, "it sends the action on arrow keys by default");
  pass([browser maxVisibleColumns] == 3, "up to three columns are visible by default");
  pass([browser columnResizingType] == NSBrowserNoColumnResizing,
       "columns do not resize by default");

  /* Accessors round-trip. */
  [browser setAllowsMultipleSelection: NO];
  pass([browser allowsMultipleSelection] == NO, "setAllowsMultipleSelection: round trips");
  [browser setAllowsBranchSelection: NO];
  pass([browser allowsBranchSelection] == NO, "setAllowsBranchSelection: round trips");
  [browser setAllowsEmptySelection: NO];
  pass([browser allowsEmptySelection] == NO, "setAllowsEmptySelection: round trips");
  [browser setHasHorizontalScroller: NO];
  pass([browser hasHorizontalScroller] == NO, "setHasHorizontalScroller: round trips");
  [browser setSendsActionOnArrowKeys: NO];
  pass([browser sendsActionOnArrowKeys] == NO, "setSendsActionOnArrowKeys: round trips");
  [browser setReusesColumns: YES];
  pass([browser reusesColumns] == YES, "setReusesColumns: round trips");
  [browser setPathSeparator: @":"];
  pass([[browser pathSeparator] isEqualToString: @":"], "setPathSeparator: round trips");
  [browser setMinColumnWidth: 120.0];
  pass([browser minColumnWidth] == 120.0, "setMinColumnWidth: round trips");
  [browser setMaxVisibleColumns: 4];
  pass([browser maxVisibleColumns] == 4, "setMaxVisibleColumns: round trips");
  [browser setColumnResizingType: NSBrowserUserColumnResizing];
  pass([browser columnResizingType] == NSBrowserUserColumnResizing,
       "setColumnResizingType: round trips");

  /* A titled browser keeps its columns separated: separatesColumns only
     changes once the browser is no longer titled. */
  [browser setSeparatesColumns: NO];
  pass([browser separatesColumns] == YES,
       "separatesColumns is unchanged while the browser is titled");
  [browser setTitled: NO];
  pass([browser isTitled] == NO, "setTitled: round trips");
  [browser setSeparatesColumns: NO];
  pass([browser separatesColumns] == NO,
       "separatesColumns changes once the browser is not titled");

  END_SET("NSBrowser config")

  DESTROY(arp);
  return 0;
}
