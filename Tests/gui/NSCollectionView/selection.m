/* -[NSCollectionView setSelectionIndexes:] stores the given indexes even when
   they lie beyond the loaded items (AppKit keeps the selection index set
   regardless of how many items exist).  Setting an index past the item count
   used to raise NSRangeException.  Checked against AppKit on a macOS runner.
   The view uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSIndexSet.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionView *cv;

  START_SET("NSCollectionView selection")

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
      cv = AUTORELEASE([[NSCollectionView alloc]
        initWithFrame: NSMakeRect(0, 0, 400, 300)]);
      [cv setSelectable: YES];

      /* No items are loaded, so index 1 is past the end. */
      [cv setSelectionIndexes: [NSIndexSet indexSetWithIndex: 1]];
      pass([[cv selectionIndexes] count] == 1,
           "an out-of-range selection index is still stored");
      pass([[cv selectionIndexes] containsIndex: 1],
           "the stored selection keeps the given index");

      [cv setSelectionIndexes: [NSIndexSet indexSet]];
      pass([[cv selectionIndexes] count] == 0,
           "the selection can be cleared");
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

  END_SET("NSCollectionView selection")

  DESTROY(arp);
  return 0;
}
