/* NSCollectionViewFlowLayout places items in lines: across, as many as fit
   between the section's insets with the minimum spacing between them, then
   the next line below, the minimum line spacing apart; the content is as
   tall as the lines.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSIndexPath.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionView.h>
#include <AppKit/NSCollectionViewFlowLayout.h>
#include <AppKit/NSCollectionViewItem.h>

@interface Seven : NSObject <NSCollectionViewDataSource>
@end
@implementation Seven
- (NSInteger) collectionView: (NSCollectionView *)cv
       numberOfItemsInSection: (NSInteger)section
{
  return 7;
}
- (NSCollectionViewItem *) collectionView: (NSCollectionView *)cv
        itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  return AUTORELEASE([[NSCollectionViewItem alloc] init]);
}
@end

static NSRect
frameOf(NSCollectionViewFlowLayout *flow, NSInteger item)
{
  return [[flow layoutAttributesForItemAtIndexPath:
    [NSIndexPath indexPathForItem: item inSection: 0]] frame];
}

int
main(int argc, char **argv)
{
  NSCollectionView *cv;
  NSCollectionViewFlowLayout *flow;

  START_SET("NSCollectionViewFlowLayout lines")

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

  cv = AUTORELEASE([[NSCollectionView alloc]
    initWithFrame: NSMakeRect(0, 0, 340, 100)]);
  flow = AUTORELEASE([[NSCollectionViewFlowLayout alloc] init]);
  [flow setItemSize: NSMakeSize(100, 50)];
  [flow setMinimumInteritemSpacing: 10];
  [flow setMinimumLineSpacing: 10];
  [flow setSectionInset: NSEdgeInsetsMake(5, 5, 5, 5)];
  [cv setCollectionViewLayout: flow];
  [cv setDataSource: AUTORELEASE([Seven new])];
  [flow prepareLayout];

  PASS(NSEqualRects(frameOf(flow, 0), NSMakeRect(5, 5, 100, 50)),
       "the first item is inside the section's insets");
  PASS(NSEqualRects(frameOf(flow, 1), NSMakeRect(115, 5, 100, 50)),
       "the next is beside it, the minimum spacing away");
  PASS(NSEqualRects(frameOf(flow, 2), NSMakeRect(225, 5, 100, 50)),
       "as many in a line as fit");
  PASS(NSEqualRects(frameOf(flow, 3), NSMakeRect(5, 65, 100, 50)),
       "the one that does not fit begins the next line");
  PASS(NSEqualRects(frameOf(flow, 5), NSMakeRect(225, 65, 100, 50)),
       "which fills as the first did");
  PASS(NSEqualRects(frameOf(flow, 6), NSMakeRect(5, 125, 100, 50)),
       "and so on");
  PASS(NSEqualSizes([flow collectionViewContentSize], NSMakeSize(340, 180)),
       "the content is as tall as the lines and the insets");

  [flow setScrollDirection: NSCollectionViewScrollDirectionHorizontal];
  [cv setFrame: NSMakeRect(0, 0, 100, 180)];
  [flow prepareLayout];
  PASS(NSEqualRects(frameOf(flow, 1), NSMakeRect(5, 65, 100, 50)),
       "scrolling across, a line goes down");
  PASS(NSEqualRects(frameOf(flow, 3), NSMakeRect(115, 5, 100, 50)),
       "and the next line is beside it");
  PASS(NSEqualSizes([flow collectionViewContentSize], NSMakeSize(330, 180)),
       "the content as wide as the lines");

  END_SET("NSCollectionViewFlowLayout lines")
  return 0;
}
