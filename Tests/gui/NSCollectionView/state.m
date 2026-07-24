/* Coverage for NSCollectionView selection state: the defaults that match
   AppKit (no multiple selection, not selectable, empty selection sets, no
   layout) and the setter round-trips.  Checked against AppKit on a macOS
   runner.  The view uses the theme and font backend, so the set is skipped
   when the backend is unavailable.
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

  START_SET("NSCollectionView state")

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

      /* Defaults that match AppKit. */
      PASS([cv allowsMultipleSelection] == NO,
           "multiple selection is off by default");
      PASS([cv isSelectable] == NO, "the view is not selectable by default");
      PASS([cv selectionIndexes] != nil
           && [[cv selectionIndexes] count] == 0,
           "the default selection index set is empty");
      PASS([cv collectionViewLayout] == nil,
           "there is no layout by default");

      /* Setter round-trips. */
      [cv setAllowsMultipleSelection: YES];
      PASS([cv allowsMultipleSelection] == YES,
           "setAllowsMultipleSelection: round trips");
      [cv setSelectable: YES];
      PASS([cv isSelectable] == YES, "setSelectable: round trips");
      [cv setAllowsEmptySelection: YES];
      PASS([cv allowsEmptySelection] == YES,
           "setAllowsEmptySelection: YES round trips");
      [cv setAllowsEmptySelection: NO];
      PASS([cv allowsEmptySelection] == NO,
           "setAllowsEmptySelection: NO round trips");
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

  END_SET("NSCollectionView state")

  DESTROY(arp);
  return 0;
}
