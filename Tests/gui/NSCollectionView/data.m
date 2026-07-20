/* Coverage for NSCollectionView's data source: the section and item counts it
   reports from a data source.  A two-section source (three items then two)
   drives the counts; a second source omits the optional
   numberOfSectionsInCollectionView: and so reports a single section.  GNUstep
   reads the counts from the data source directly; AppKit reaches the same
   counts once the view lays out (a windowless macOS process reports them as
   not yet loaded), so the counts are checked against the data source here.
   The view uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSIndexPath.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionView.h>
#include <AppKit/NSCollectionViewItem.h>

@interface TwoSections : NSObject <NSCollectionViewDataSource>
@end
@implementation TwoSections
- (NSInteger) numberOfSectionsInCollectionView: (NSCollectionView *)cv { return 2; }
- (NSInteger) collectionView: (NSCollectionView *)cv
       numberOfItemsInSection: (NSInteger)section
{
  return section == 0 ? 3 : 2;
}
- (NSCollectionViewItem *) collectionView: (NSCollectionView *)cv
        itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  return AUTORELEASE([[NSCollectionViewItem alloc] init]);
}
@end

@interface OneSection : NSObject <NSCollectionViewDataSource>
@end
@implementation OneSection
- (NSInteger) collectionView: (NSCollectionView *)cv
       numberOfItemsInSection: (NSInteger)section
{
  return 4;
}
- (NSCollectionViewItem *) collectionView: (NSCollectionView *)cv
        itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  return AUTORELEASE([[NSCollectionViewItem alloc] init]);
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionView *cv;
  TwoSections *two;
  OneSection *one;

  START_SET("NSCollectionView data")

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
      two = AUTORELEASE([TwoSections new]);
      cv = AUTORELEASE([[NSCollectionView alloc]
        initWithFrame: NSMakeRect(0, 0, 400, 300)]);
      [cv setDataSource: two];
      [cv reloadData];
      pass([cv numberOfSections] == 2,
           "the data source's section count is reported");
      pass([cv numberOfItemsInSection: 0] == 3,
           "the first section reports three items");
      pass([cv numberOfItemsInSection: 1] == 2,
           "the second section reports two items");

      /* A data source without the optional section method reports one section. */
      one = AUTORELEASE([OneSection new]);
      NSCollectionView *cv2 = AUTORELEASE([[NSCollectionView alloc]
        initWithFrame: NSMakeRect(0, 0, 400, 300)]);
      [cv2 setDataSource: one];
      [cv2 reloadData];
      pass([cv2 numberOfSections] == 1,
           "a data source without a section count reports one section");
      pass([cv2 numberOfItemsInSection: 0] == 4,
           "the single section reports its items");
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

  END_SET("NSCollectionView data")

  DESTROY(arp);
  return 0;
}
