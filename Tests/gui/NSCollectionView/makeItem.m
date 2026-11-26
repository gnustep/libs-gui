/* NSCollectionView's -makeItemWithIdentifier:forIndexPath: makes an item of
   the class registered for the identifier, as AppKit's does; it does not ask
   the data source, which calls it to make the items it returns.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSIndexPath.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionView.h>
#include <AppKit/NSCollectionViewFlowLayout.h>
#include <AppKit/NSCollectionViewItem.h>
#include <AppKit/NSView.h>

@interface Card : NSCollectionViewItem
@end
@implementation Card
- (void) loadView
{
  [self setView: AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 40, 30)])];
}
@end

@interface Other : NSCollectionViewItem
@end
@implementation Other
@end

/* Its own items, made without the collection view. */
@interface MakesItsOwn : NSObject <NSCollectionViewDataSource>
@end
@implementation MakesItsOwn
- (NSInteger) collectionView: (NSCollectionView *)cv
       numberOfItemsInSection: (NSInteger)section
{
  return 3;
}
- (NSCollectionViewItem *) collectionView: (NSCollectionView *)cv
        itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  return AUTORELEASE([[Other alloc] init]);
}
@end

/* Its items made by the collection view, of the class registered. */
@interface MakesThemThere : NSObject <NSCollectionViewDataSource>
@end
@implementation MakesThemThere
- (NSInteger) collectionView: (NSCollectionView *)cv
       numberOfItemsInSection: (NSInteger)section
{
  return 3;
}
- (NSCollectionViewItem *) collectionView: (NSCollectionView *)cv
        itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  return [cv makeItemWithIdentifier: @"card" forIndexPath: indexPath];
}
@end

int
main(int argc, char **argv)
{
  NSCollectionView *cv;
  NSCollectionViewItem *made;
  NSIndexPath *first;

  START_SET("NSCollectionView makeItemWithIdentifier:forIndexPath:")

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

  first = [NSIndexPath indexPathForItem: 0 inSection: 0];
  cv = AUTORELEASE([[NSCollectionView alloc]
    initWithFrame: NSMakeRect(0, 0, 400, 300)]);
  [cv setCollectionViewLayout: AUTORELEASE([[NSCollectionViewFlowLayout alloc] init])];
  [cv registerClass: [Card class] forItemWithIdentifier: @"card"];
  [cv setDataSource: AUTORELEASE([MakesItsOwn new])];

  made = [cv makeItemWithIdentifier: @"card" forIndexPath: first];
  PASS([made isKindOfClass: [Card class]],
       "an item of the class registered for the identifier is made");
  PASS([made view] != nil, "with its view loaded");
  PASS(made != [cv makeItemWithIdentifier: @"card" forIndexPath: first],
       "a new one each time");

  if ([made isKindOfClass: [Card class]])
    {
      [cv setDataSource: AUTORELEASE([MakesThemThere new])];
      [cv reloadData];
      [cv layoutSubtreeIfNeeded];
      PASS([[cv itemAtIndexPath: first] isKindOfClass: [Card class]],
           "a data source that makes its items so has them shown");
    }

  END_SET("NSCollectionView makeItemWithIdentifier:forIndexPath:")
  return 0;
}
