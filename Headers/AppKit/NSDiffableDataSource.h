/*
   NSDiffableDataSource.h

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
#import <AppKit/AppKitDefines.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSTableView.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST)

@class NSCollectionView;
@class NSCollectionViewItem;
@class NSTableView;
@class NSTableColumn;
@class NSIndexPath;
@class NSView;

@protocol NSCollectionViewDataSource;
@protocol NSCollectionViewPrefetching;
@protocol NSTableViewDataSource;

APPKIT_EXPORT_CLASS
@interface NSDiffableDataSourceSnapshot : NSObject <NSCopying, NSMutableCopying>
- (NSArray *)sectionIdentifiers;
- (NSArray *)itemIdentifiers;
- (NSArray *)itemIdentifiersInSectionWithIdentifier: (id)sectionIdentifier;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfItems;
- (void)appendSectionsWithIdentifiers: (NSArray *)sectionIdentifiers;
- (void)insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
            beforeSectionWithIdentifier: (id)sectionIdentifier;
- (void)insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
             afterSectionWithIdentifier: (id)sectionIdentifier;
- (void)deleteSectionsWithIdentifiers: (NSArray *)sectionIdentifiers;
- (void)moveSectionWithIdentifier: (id)sectionIdentifier
      beforeSectionWithIdentifier: (id)otherSectionIdentifier;
- (void)moveSectionWithIdentifier: (id)sectionIdentifier
       afterSectionWithIdentifier: (id)otherSectionIdentifier;
- (void)appendItemsWithIdentifiers: (NSArray *)itemIdentifiers;
- (void)appendItemsWithIdentifiers: (NSArray *)itemIdentifiers
           intoSectionWithIdentifier: (id)sectionIdentifier;
- (void)insertItemsWithIdentifiers: (NSArray *)itemIdentifiers
          beforeItemWithIdentifier: (id)beforeIdentifier;
- (void)insertItemsWithIdentifiers: (NSArray *)itemIdentifiers
           afterItemWithIdentifier: (id)afterIdentifier;
- (void)deleteItemsWithIdentifiers: (NSArray *)itemIdentifiers;
- (void)reloadSectionsWithIdentifiers: (NSArray *)sectionIdentifiers;
- (void)reloadItemsWithIdentifiers: (NSArray *)itemIdentifiers;
@end

@protocol NSCollectionViewDiffableItemProvider
- (NSCollectionViewItem *)collectionView: (NSCollectionView *)collectionView
                     itemForIdentifier: (id)itemIdentifier
                               atIndexPath: (NSIndexPath *)indexPath;
@end

@protocol NSTableViewDiffableCellProvider
- (NSView *)tableView: (NSTableView *)tableView
    viewForIdentifier: (id)itemIdentifier
             tableColumn: (NSTableColumn *)tableColumn
                    row: (NSInteger)row;
@end

APPKIT_EXPORT_CLASS
@interface NSCollectionViewDiffableDataSource : NSObject <NSCollectionViewDataSource, NSCollectionViewPrefetching>
{
  NSCollectionView *_collectionView;
  NSDiffableDataSourceSnapshot *_snapshot;
  id _itemProvider;
  NSMutableDictionary *_identifierToIndexPath;
}
- (id)initWithCollectionView: (NSCollectionView *)collectionView
                 itemProvider: (id)itemProvider;
- (void)applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences;
- (NSDiffableDataSourceSnapshot *)snapshot;
- (NSIndexPath *)indexPathForItemIdentifier: (id)itemIdentifier;
- (id)itemIdentifierForIndexPath: (NSIndexPath *)indexPath;
@end

APPKIT_EXPORT_CLASS
@interface NSTableViewDiffableDataSource : NSObject <NSTableViewDataSource>
{
  NSTableView *_tableView;
  NSDiffableDataSourceSnapshot *_snapshot;
  id _cellProvider;
  NSMutableDictionary *_identifierToIndexPath;
}
- (id)initWithTableView: (NSTableView *)tableView
           cellProvider: (id)cellProvider;
- (void)applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences;
- (NSDiffableDataSourceSnapshot *)snapshot;
- (NSIndexPath *)indexPathForItemIdentifier: (id)itemIdentifier;
- (id)itemIdentifierForIndexPath: (NSIndexPath *)indexPath;
- (id)itemIdentifierForRow: (NSInteger)row;
@end

#endif /* OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST) */

#endif /* _GNUstep_H_NSDiffableDataSource */
