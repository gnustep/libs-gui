/* A new NSCollectionView carries AppKit's selection and background defaults:
   empty selection is allowed, the selection index paths are an empty set (not
   nil) and there is a non-empty backgroundColors array.  Checked against
   AppKit on a macOS runner.  The view uses the theme and font backend, so the
   set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSSet.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionView *cv;

  START_SET("NSCollectionView defaults")

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

      PASS([cv allowsEmptySelection] == YES,
           "empty selection is allowed by default");
      PASS([cv selectionIndexPaths] != nil,
           "the default selection index paths set is not nil");
      PASS([[cv selectionIndexPaths] count] == 0,
           "the default selection index paths set is empty");
      PASS([cv backgroundColors] != nil
           && [[cv backgroundColors] count] > 0,
           "there is a non-empty backgroundColors array by default");
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

  END_SET("NSCollectionView defaults")

  DESTROY(arp);
  return 0;
}
