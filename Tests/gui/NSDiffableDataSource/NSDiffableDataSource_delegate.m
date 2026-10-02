/* Portable diffable providers, without a display server or block syntax. */
#include "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/NSDiffableDataSource.h>

/* These callbacks are implemented by the data source. */
@interface NSTableViewDiffableDataSource (TestCallbacks)
- (NSView *) tableView: (NSTableView *)view
   viewForTableColumn: (NSTableColumn *)column row: (NSInteger)row;
- (NSTableRowView *) tableView: (NSTableView *)view rowViewForRow: (NSInteger)row;
- (NSView *) tableView: (NSTableView *)view
 viewForSectionHeaderInSection: (NSInteger)section;
@end

/* Only the view operations needed by these data sources are simulated. */
@interface DiffableTestView : NSObject
{
@public
  id dataSource;
  NSUInteger reloads;
}
@end
@implementation DiffableTestView
- (void) setDataSource: (id)value { dataSource = value; }
- (void) setPrefetchDataSource: (id)value {}
- (void) reloadData { reloads++; }
- (id) itemAtIndexPath: (NSIndexPath *)path { return nil; }
@end

@interface DiffableTestProvider : NSObject
  <NSCollectionViewDiffableDataSourceDelegate, NSTableViewDiffableDataSourceDelegate>
{
@public
  id identifier;
  NSIndexPath *path;
  NSInteger row;
  NSUInteger completions;
  BOOL lookupReady;
}
@end
@implementation DiffableTestProvider
- (NSCollectionViewItem *) collectionView: (NSCollectionView *)view
                      itemForIdentifier: (id)value
                            atIndexPath: (NSIndexPath *)indexPath
{
  identifier = value;
  path = indexPath;
  return (id)self;
}
- (NSView *) collectionView: (NSCollectionView *)view
 viewForSupplementaryElementOfKind: (NSCollectionViewSupplementaryElementKind)kind
               atIndexPath: (NSIndexPath *)indexPath
{
  identifier = kind;
  path = indexPath;
  return (id)self;
}
- (NSView *) tableView: (NSTableView *)view viewForIdentifier: (id)value
          tableColumn: (NSTableColumn *)column row: (NSInteger)index
{
  identifier = value;
  row = index;
  return (id)self;
}
- (NSTableRowView *) tableView: (NSTableView *)view
         rowViewForIdentifier: (id)value row: (NSInteger)index
{
  identifier = value;
  row = index;
  return (id)self;
}
- (NSView *) tableView: (NSTableView *)view
 viewForSectionIdentifier: (id)value inSection: (NSInteger)index
{
  identifier = value;
  row = index;
  return (id)self;
}
- (void) diffableDataSource: (id)source
          didApplySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
{
  completions++;
  lookupReady = [[source itemIdentifierForIndexPath:
    [NSIndexPath indexPathForItem: 0 inSection: 0]] isEqual: @"item"];
  /* The notification's snapshot must not expose the stored mutable state. */
  [snapshot deleteItemsWithIdentifiers: [snapshot itemIdentifiers]];
}
@end

#if __has_feature(blocks)
/* Return after the captured providers' stack frames have gone away. */
static NSCollectionViewDiffableDataSource *
BlockCollection(DiffableTestView *view, void *token)
{
  NSCollectionViewDiffableDataSource *source =
    [[NSCollectionViewDiffableDataSource alloc] initWithCollectionView: (id)view
      itemProvider: ^NSCollectionViewItem *(NSCollectionView *cv,
                                            NSIndexPath *path, id identifier) {
        return (id)token;
      }];
  [source setSupplementaryViewProvider:
    ^NSView *(NSCollectionView *cv, NSString *kind, NSIndexPath *path) {
      return (id)token;
    }];
  return source;
}

static NSTableViewDiffableDataSource *
BlockTable(DiffableTestView *view, void *token)
{
  NSTableViewDiffableDataSource *source =
    [[NSTableViewDiffableDataSource alloc] initWithTableView: (id)view
      cellProvider: ^NSView *(NSTableView *tv, NSTableColumn *column,
                             NSInteger row, id identifier) {
        return (id)token;
      }];
  [source setRowViewProvider:
    ^NSTableRowView *(NSTableView *tv, NSInteger row, id identifier) {
      return (id)token;
    }];
  [source setSectionHeaderViewProvider:
    ^NSView *(NSTableView *tv, NSInteger section, id identifier) {
      return (id)token;
    }];
  return source;
}
#endif

int main(void)
{
  START_SET("NSDiffableDataSource portable delegates")
  DiffableTestView *view = [DiffableTestView new];
  DiffableTestProvider *provider = [DiffableTestProvider new];
  NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
  NSIndexPath *path = [NSIndexPath indexPathForItem: 0 inSection: 0];
  [snapshot appendSectionsWithIdentifiers: [NSArray arrayWithObject: @"section"]];
  [snapshot appendItemsWithIdentifiers: [NSArray arrayWithObject: @"item"]];

  NSCollectionViewDiffableDataSource *collection =
    [[NSCollectionViewDiffableDataSource alloc] initWithCollectionView: (id)view
                                                           delegate: provider];
  PASS([collection delegate] == provider && view->dataSource == collection,
    "collection delegate initializer installs the data source");
  [collection applySnapshot: snapshot animatingDifferences: NO];
  PASS(provider->completions == 1 && provider->lookupReady && view->reloads == 1,
    "collection notifies after updating lookup and view");
  PASS([[collection snapshot] numberOfItems] == 1,
    "completion snapshot cannot mutate the data source");
  PASS((id)[collection collectionView: (id)view
    itemForRepresentedObjectAtIndexPath: path] == provider
    && [provider->identifier isEqual: @"item"] && [provider->path isEqual: path],
    "collection requests items by identifier through its delegate");
  PASS((id)[collection collectionView: (id)view
    viewForSupplementaryElementOfKind: @"header" atIndexPath: path] == provider
    && [provider->identifier isEqual: @"header"],
    "collection requests supplementary views through its delegate");
  [collection setDelegate: nil];
  PASS([collection collectionView: (id)view
    itemForRepresentedObjectAtIndexPath: path] == nil,
    "collection delegate can be cleared");
  PASS([collection collectionView: (id)view
    viewForSupplementaryElementOfKind: @"header" atIndexPath: path] == nil,
    "missing supplementary delegate returns nil");

  NSTableViewDiffableDataSource *table =
    [[NSTableViewDiffableDataSource alloc] initWithTableView: (id)view
                                                  delegate: provider];
  PASS([table delegate] == provider && view->dataSource == table,
    "table delegate initializer installs the data source");
  [table applySnapshot: snapshot animatingDifferences: NO];
  PASS(provider->completions == 2 && provider->lookupReady && view->reloads == 2,
    "table notifies after updating lookup and view");
  PASS((id)[table tableView: (id)view viewForTableColumn: nil row: 0] == provider
    && [provider->identifier isEqual: @"item"] && provider->row == 0,
    "table requests cells by identifier through its delegate");
  PASS((id)[table tableView: (id)view rowViewForRow: 0] == provider
    && [provider->identifier isEqual: @"item"],
    "table requests row views through its delegate");
  PASS((id)[table tableView: (id)view viewForSectionHeaderInSection: 0] == provider
    && [provider->identifier isEqual: @"section"],
    "table requests section headers through its delegate");
  PASS([table tableView: (id)view viewForSectionHeaderInSection: 1] == nil,
    "invalid section does not call the delegate");
  [table setDelegate: nil];
  PASS([table tableView: (id)view rowViewForRow: 0] == nil,
    "missing row delegate returns nil");
#if __has_feature(blocks)
  NSCollectionViewDiffableDataSource *blockCollection = BlockCollection(view, provider);
  NSTableViewDiffableDataSource *blockTable = BlockTable(view, provider);
  __block NSUInteger completed = 0;
  [blockCollection applySnapshot: snapshot animatingDifferences: NO
    completionHandler: ^{ completed++; }];
  [blockTable applySnapshot: snapshot animatingDifferences: NO
    completionHandler: ^{ completed++; }];
  PASS(completed == 2 && [blockCollection delegate] == blockCollection
    && [blockTable delegate] == blockTable,
    "block initializers use self delegates and completion adapters run");
  PASS((id)[blockCollection collectionView: (id)view
    itemForRepresentedObjectAtIndexPath: path] == provider,
    "copied item provider survives its creating stack frame");
  PASS((id)[blockCollection collectionView: (id)view
    viewForSupplementaryElementOfKind: @"header" atIndexPath: path] == provider,
    "copied supplementary provider survives its creating stack frame");
  PASS((id)[blockTable tableView: (id)view viewForTableColumn: nil row: 0] == provider,
    "copied cell provider survives its creating stack frame");
  PASS((id)[blockTable tableView: (id)view rowViewForRow: 0] == provider,
    "copied row provider survives its creating stack frame");
  PASS((id)[blockTable tableView: (id)view viewForSectionHeaderInSection: 0] == provider,
    "copied header provider survives its creating stack frame");
  [blockCollection setSupplementaryViewProvider: [blockCollection supplementaryViewProvider]];
  [blockTable setRowViewProvider: [blockTable rowViewProvider]];
  [blockTable setSectionHeaderViewProvider: [blockTable sectionHeaderViewProvider]];
  [blockCollection setSupplementaryViewProvider: NULL];
  [blockTable setRowViewProvider: NULL];
  [blockTable setSectionHeaderViewProvider: NULL];
  PASS([blockCollection collectionView: (id)view
    viewForSupplementaryElementOfKind: @"header" atIndexPath: path] == nil
    && [blockTable tableView: (id)view rowViewForRow: 0] == nil
    && [blockTable tableView: (id)view viewForSectionHeaderInSection: 0] == nil,
    "optional block providers can be reassigned and cleared");
  [blockCollection release];
  [blockTable release];
#endif
  [table release];
  [collection release];
  [snapshot release];
  [provider release];
  [view release];
  END_SET("NSDiffableDataSource portable delegates")
  return 0;
}
