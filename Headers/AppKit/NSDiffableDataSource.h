/*
   NSDiffableDataSource.h

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: Jan 2026

   Diffable data source support for NSCollectionView and NSTableView.

   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSDiffableDataSource
#define _GNUstep_H_NSDiffableDataSource

#if OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST)

#import <AppKit/AppKitDefines.h>
#import <Foundation/NSObject.h>
#import <AppKit/NSTableView.h>

@class NSArray;
@class NSMutableArray;
@class NSMutableDictionary;
@class NSMutableSet;
@class NSCollectionView;
@class NSCollectionViewItem;
@class NSTableView;
@class NSTableColumn;
@class NSIndexPath;
@class NSView;

@protocol NSCollectionViewDataSource;
@protocol NSCollectionViewPrefetching;
@protocol NSTableViewDataSource;

/**
 * Block type for providing collection view items.
 * Takes a collection view, index path, and item identifier,
 * and returns a configured NSCollectionViewItem.
 */
DEFINE_BLOCK_TYPE(GSCollectionViewItemProviderBlock, NSCollectionViewItem*, NSCollectionView*, NSIndexPath*, id);

/**
 * Block type for providing table view cells.
 * Takes a table view, item identifier, table column, and row number,
 * and returns a configured NSView for the cell.
 */
DEFINE_BLOCK_TYPE(GSTableViewCellProviderBlock, NSView*, NSTableView*, id, NSTableColumn*, NSInteger);

/**
 * <p>NSDiffableDataSourceSnapshot represents a snapshot of the current state
 * of data in a collection view or table view. It maintains sections and items,
 * allowing for declarative UI updates by comparing snapshots.</p>
 *
 * <p>A snapshot stores unique identifiers for sections and items, and tracks
 * which sections or items have been marked for reloading. Snapshots are
 * immutable after being applied to a data source, but you can create new
 * snapshots by copying and modifying them.</p>
 */
APPKIT_EXPORT_CLASS
@interface NSDiffableDataSourceSnapshot : NSObject <NSCopying, NSMutableCopying>
{
@private
  NSMutableArray *_sections;
  NSMutableDictionary *_itemsBySection;
  NSMutableSet *_reloadedSections;
  NSMutableSet *_reloadedItems;
}

/**
 * Returns an array of all section identifiers in the snapshot,
 * in the order they appear.
 */
- (NSArray *)sectionIdentifiers;

/**
 * Returns an array of all item identifiers across all sections
 * in the snapshot, in the order they appear.
 */
- (NSArray *)itemIdentifiers;

/**
 * Returns an array of item identifiers in the specified section.
 * sectionIdentifier: The unique identifier for the section.
 */
- (NSArray *)itemIdentifiersInSectionWithIdentifier: (id)sectionIdentifier;

/**
 * Returns the number of sections in the snapshot.
 */
- (NSInteger)numberOfSections;

/**
 * Returns the total number of items across all sections in the snapshot.
 */
- (NSInteger)numberOfItems;

/**
 * Appends the specified sections to the end of the snapshot.
 * sectionIdentifiers: An array of unique identifiers for the sections to append.
 */
- (void)appendSectionsWithIdentifiers: (NSArray *)sectionIdentifiers;

/**
 * Inserts the specified sections before the given section.
 * sectionIdentifiers: An array of unique identifiers for the sections to insert.
 * sectionIdentifier: The identifier of the section before which to insert.
 */
- (void)insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
	    beforeSectionWithIdentifier: (id)sectionIdentifier;

/**
 * Inserts the specified sections after the given section.
 * sectionIdentifiers: An array of unique identifiers for the sections to insert.
 * sectionIdentifier: The identifier of the section after which to insert.
 */
- (void)insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
	     afterSectionWithIdentifier: (id)sectionIdentifier;

/**
 * Removes the specified sections from the snapshot.
 * sectionIdentifiers: An array of unique identifiers for the sections to delete.
 */
- (void)deleteSectionsWithIdentifiers: (NSArray *)sectionIdentifiers;

/**
 * Moves the specified section to a position before another section.
 * sectionIdentifier: The identifier of the section to move.
 * otherSectionIdentifier: The identifier of the section before which to move.
 */
- (void)moveSectionWithIdentifier: (id)sectionIdentifier
      beforeSectionWithIdentifier: (id)otherSectionIdentifier;

/**
 * Moves the specified section to a position after another section.
 * sectionIdentifier: The identifier of the section to move.
 * otherSectionIdentifier: The identifier of the section after which to move.
 */
- (void)moveSectionWithIdentifier: (id)sectionIdentifier
       afterSectionWithIdentifier: (id)otherSectionIdentifier;

/**
 * Appends the specified items to the last section in the snapshot.
 * itemIdentifiers: An array of unique identifiers for the items to append.
 */
- (void)appendItemsWithIdentifiers: (NSArray *)itemIdentifiers;

/**
 * Appends the specified items to the given section.
 * itemIdentifiers: An array of unique identifiers for the items to append.
 * sectionIdentifier: The identifier of the section into which to append items.
 */
- (void)appendItemsWithIdentifiers: (NSArray *)itemIdentifiers
	   intoSectionWithIdentifier: (id)sectionIdentifier;

/**
 * Inserts the specified items before the given item.
 * itemIdentifiers: An array of unique identifiers for the items to insert.
 * beforeIdentifier: The identifier of the item before which to insert.
 */
- (void)insertItemsWithIdentifiers: (NSArray *)itemIdentifiers
	  beforeItemWithIdentifier: (id)beforeIdentifier;

/**
 * Inserts the specified items after the given item.
 * itemIdentifiers: An array of unique identifiers for the items to insert.
 * afterIdentifier: The identifier of the item after which to insert.
 */
- (void)insertItemsWithIdentifiers: (NSArray *)itemIdentifiers
	   afterItemWithIdentifier: (id)afterIdentifier;

/**
 * Removes the specified items from the snapshot.
 * itemIdentifiers: An array of unique identifiers for the items to delete.
 */
- (void)deleteItemsWithIdentifiers: (NSArray *)itemIdentifiers;

/**
 * Marks the specified sections for reloading.
 * When the snapshot is applied, these sections will be reloaded.
 * sectionIdentifiers: An array of unique identifiers for the sections to reload.
 */
- (void)reloadSectionsWithIdentifiers: (NSArray *)sectionIdentifiers;

/**
 * Marks the specified items for reloading.
 * When the snapshot is applied, these items will be reloaded.
 * itemIdentifiers: An array of unique identifiers for the items to reload.
 */
- (void)reloadItemsWithIdentifiers: (NSArray *)itemIdentifiers;
@end

/**
 * <p>Protocol for providing collection view items using diffable data sources.
 * Implement this protocol to supply items for a collection view based on
 * unique identifiers rather than index paths.</p>
 */
@protocol NSCollectionViewDiffableItemProvider

/**
 * Requests a collection view item for the specified identifier.
 * collectionView: The collection view requesting the item.
 * itemIdentifier: The unique identifier for the item.
 * indexPath: The index path where the item will appear.
 * Returns: A configured NSCollectionViewItem.
 */
- (NSCollectionViewItem *)collectionView: (NSCollectionView *)collectionView
		     itemForIdentifier: (id)itemIdentifier
			       atIndexPath: (NSIndexPath *)indexPath;
@end

/**
 * <p>Protocol for providing table view cells using diffable data sources.
 * Implement this protocol to supply cell views for a table view based on
 * unique identifiers rather than row indices.</p>
 */
@protocol NSTableViewDiffableCellProvider

/**
 * Requests a cell view for the specified identifier.
 * tableView: The table view requesting the cell.
 * itemIdentifier: The unique identifier for the item.
 * tableColumn: The column in which the cell will appear.
 * row: The row number where the cell will appear.
 * Returns: A configured NSView for the cell.
 */
- (NSView *)tableView: (NSTableView *)tableView
    viewForIdentifier: (id)itemIdentifier
	  tableColumn: (NSTableColumn *)tableColumn
		  row: (NSInteger)row;
@end

/**
 * <p>NSCollectionViewDiffableDataSource is a data source for NSCollectionView
 * that manages data using snapshots and unique identifiers. It automatically
 * calculates and applies the differences between snapshots, enabling smooth
 * and efficient updates to the collection view.</p>
 *
 * <p>Rather than manually inserting, deleting, or reloading items by index path,
 * you create and apply snapshots that describe the desired state of your data.
 * The data source computes the minimal set of changes needed and applies them
 * with optional animations.</p>
 *
 * <p>This approach simplifies state management and eliminates many common
 * data source errors related to index path management.</p>
 */
APPKIT_EXPORT_CLASS
@interface NSCollectionViewDiffableDataSource : NSObject <NSCollectionViewDataSource, NSCollectionViewPrefetching>
{
  NSCollectionView *_collectionView;
  NSDiffableDataSourceSnapshot *_snapshot;
  GSCollectionViewItemProviderBlock _itemProvider;
  NSMutableDictionary *_identifierToIndexPath;
}

/**
 * Initializes a diffable data source for the specified collection view.
 * collectionView: The collection view to provide data for.
 * itemProvider: A block that creates and configures collection view items
 *               based on their identifiers and index paths.
 * Returns: An initialized NSCollectionViewDiffableDataSource.
 */
- (id)initWithCollectionView: (NSCollectionView *)collectionView
		itemProvider: (GSCollectionViewItemProviderBlock)itemProvider;

/**
 * Applies a snapshot to the data source, updating the collection view.
 * snapshot: The snapshot describing the new state of the data.
 * animatingDifferences: Whether to animate the changes between the current
 *                       state and the new snapshot.
 */
- (void)applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
 animatingDifferences: (BOOL)animatingDifferences;

/**
 * Returns the current snapshot representing the state of the data.
 * Returns: An NSDiffableDataSourceSnapshot containing all current sections and items.
 */
- (NSDiffableDataSourceSnapshot *)snapshot;

/**
 * Returns the index path for the item with the specified identifier.
 * itemIdentifier: The unique identifier for the item.
 * Returns: The index path where the item appears, or nil if not found.
 */
- (NSIndexPath *)indexPathForItemIdentifier: (id)itemIdentifier;

/**
 * Returns the item identifier for the item at the specified index path.
 * indexPath: The index path of the item.
 * Returns: The unique identifier for the item at that location, or nil if not found.
 */
- (id)itemIdentifierForIndexPath: (NSIndexPath *)indexPath;
@end

/**
 * <p>NSTableViewDiffableDataSource is a data source for NSTableView
 * that manages data using snapshots and unique identifiers. It automatically
 * calculates and applies the differences between snapshots, enabling smooth
 * and efficient updates to the table view.</p>
 *
 * <p>Similar to NSCollectionViewDiffableDataSource, this class allows you
 * to manage table view data declaratively by creating and applying snapshots.
 * The data source handles all the complexity of computing differences and
 * applying updates with optional animations.</p>
 *
 * <p>This approach is particularly useful for table views with dynamic content
 * that changes frequently, as it eliminates manual index management and reduces
 * the likelihood of crashes due to inconsistent updates.</p>
 */
APPKIT_EXPORT_CLASS
@interface NSTableViewDiffableDataSource : NSObject <NSTableViewDataSource>
{
  NSTableView *_tableView;
  NSDiffableDataSourceSnapshot *_snapshot;
  GSTableViewCellProviderBlock _cellProvider;
  NSMutableDictionary *_identifierToIndexPath;
}

/**
 * Initializes a diffable data source for the specified table view.
 * tableView: The table view to provide data for.
 * cellProvider: A block that creates and configures cell views based on
 *               their identifiers, columns, and row numbers.
 * Returns: An initialized NSTableViewDiffableDataSource.
 */
- (id)initWithTableView: (NSTableView *)tableView
	   cellProvider: (GSTableViewCellProviderBlock)cellProvider;

/**
 * Applies a snapshot to the data source, updating the table view.
 * snapshot: The snapshot describing the new state of the data.
 * animatingDifferences: Whether to animate the changes between the current
 *                       state and the new snapshot.
 */
- (void)applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences;

/**
 * Returns the current snapshot representing the state of the data.
 * Returns: An NSDiffableDataSourceSnapshot containing all current sections and items.
 */
- (NSDiffableDataSourceSnapshot *)snapshot;

/**
 * Returns the index path for the item with the specified identifier.
 * itemIdentifier: The unique identifier for the item.
 * Returns: The index path where the item appears, or nil if not found.
 */
- (NSIndexPath *)indexPathForItemIdentifier: (id)itemIdentifier;

/**
 * Returns the item identifier for the item at the specified index path.
 * indexPath: The index path of the item.
 * Returns: The unique identifier for the item at that location, or nil if not found.
 */
- (id)itemIdentifierForIndexPath: (NSIndexPath *)indexPath;

/**
 * Returns the item identifier for the item at the specified row.
 * row: The row number of the item.
 * Returns: The unique identifier for the item at that row, or nil if not found.
 */
- (id)itemIdentifierForRow: (NSInteger)row;
@end

#endif /* end of #if OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST) */

#endif /* _GNUstep_H_NSDiffableDataSource */
