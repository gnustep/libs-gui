/* A new NSGridView carries AppKit's placement and spacing defaults: leading x
   placement, top y placement and a six-point column and row spacing (they were
   zero).  Checked against AppKit on a macOS runner.  The grid uses the theme
   and font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSGridView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSGridView *g;

  START_SET("NSGridView defaults")

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
      g = [NSGridView gridViewWithNumberOfColumns: 2 rows: 2];

      PASS([g xPlacement] == NSGridCellPlacementLeading,
           "the default x placement is leading");
      PASS([g yPlacement] == NSGridCellPlacementTop,
           "the default y placement is top");
      PASS([g columnSpacing] == 6.0, "the default column spacing is six");
      PASS([g rowSpacing] == 6.0, "the default row spacing is six");
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

  END_SET("NSGridView defaults")

  DESTROY(arp);
  return 0;
}
