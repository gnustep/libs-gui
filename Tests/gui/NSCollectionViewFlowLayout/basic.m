/* Coverage for NSCollectionViewFlowLayout: the init defaults that match AppKit
   (estimatedItemSize, scrollDirection, header/footer reference sizes,
   sectionInset, pin flags) and the plain setter round-trips for all of the
   flow-layout metrics.  Every assertion here matches AppKit (verified on a
   macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionViewFlowLayout.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionViewFlowLayout *l;
  NSEdgeInsets inset;

  START_SET("NSCollectionViewFlowLayout basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* init defaults */
  l = AUTORELEASE([[NSCollectionViewFlowLayout alloc] init]);
  PASS([l estimatedItemSize].width == 0 && [l estimatedItemSize].height == 0,
       "default estimatedItemSize is zero");
  PASS([l scrollDirection] == NSCollectionViewScrollDirectionVertical,
       "default scrollDirection is vertical");
  PASS([l headerReferenceSize].width == 0 && [l headerReferenceSize].height == 0,
       "default headerReferenceSize is zero");
  PASS([l footerReferenceSize].width == 0 && [l footerReferenceSize].height == 0,
       "default footerReferenceSize is zero");
  inset = [l sectionInset];
  PASS(inset.top == 0 && inset.left == 0 && inset.bottom == 0 && inset.right == 0,
       "default sectionInset is zero");
  PASS([l sectionHeadersPinToVisibleBounds] == NO,
       "section headers do not pin by default");
  PASS([l sectionFootersPinToVisibleBounds] == NO,
       "section footers do not pin by default");

  /* setter round-trips */
  l = AUTORELEASE([[NSCollectionViewFlowLayout alloc] init]);
  [l setMinimumLineSpacing: 5.0];
  [l setMinimumInteritemSpacing: 6.0];
  [l setItemSize: NSMakeSize(30, 40)];
  [l setEstimatedItemSize: NSMakeSize(11, 12)];
  [l setScrollDirection: NSCollectionViewScrollDirectionHorizontal];
  [l setHeaderReferenceSize: NSMakeSize(100, 20)];
  [l setFooterReferenceSize: NSMakeSize(100, 10)];
  [l setSectionInset: NSEdgeInsetsMake(1, 2, 3, 4)];
  [l setSectionHeadersPinToVisibleBounds: YES];
  [l setSectionFootersPinToVisibleBounds: YES];
  PASS([l minimumLineSpacing] == 5.0, "minimumLineSpacing round-trips");
  PASS([l minimumInteritemSpacing] == 6.0, "minimumInteritemSpacing round-trips");
  PASS([l itemSize].width == 30 && [l itemSize].height == 40, "itemSize round-trips");
  PASS([l estimatedItemSize].width == 11 && [l estimatedItemSize].height == 12,
       "estimatedItemSize round-trips");
  PASS([l scrollDirection] == NSCollectionViewScrollDirectionHorizontal,
       "scrollDirection round-trips");
  PASS([l headerReferenceSize].width == 100 && [l headerReferenceSize].height == 20,
       "headerReferenceSize round-trips");
  PASS([l footerReferenceSize].width == 100 && [l footerReferenceSize].height == 10,
       "footerReferenceSize round-trips");
  inset = [l sectionInset];
  PASS(inset.top == 1 && inset.left == 2 && inset.bottom == 3 && inset.right == 4,
       "sectionInset round-trips");
  PASS([l sectionHeadersPinToVisibleBounds] == YES,
       "sectionHeadersPinToVisibleBounds round-trips");
  PASS([l sectionFootersPinToVisibleBounds] == YES,
       "sectionFootersPinToVisibleBounds round-trips");

  END_SET("NSCollectionViewFlowLayout basic")

  DESTROY(arp);
  return 0;
}
