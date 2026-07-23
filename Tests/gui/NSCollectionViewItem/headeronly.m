/* NSCollectionViewItem.h is self-contained: including it on its own declares
   the NSCollectionView type used by -collectionView, so this compiles without
   including NSCollectionView.h. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionViewItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionViewItem *item;

  START_SET("NSCollectionViewItem header")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  item = AUTORELEASE([[NSCollectionViewItem alloc] init]);
  PASS([item collectionView] == nil,
       "collectionView is nil for an item that is not in a collection");

  END_SET("NSCollectionViewItem header")

  DESTROY(arp);
  return 0;
}
