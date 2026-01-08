/** <title>NSDiffableDataSource</title>

   Diffable data source helpers for collection and table views.

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

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSIndexPath.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSSet.h>
#import <GNUstepBase/GSBlocks.h>
#import <objc/runtime.h>

#import "AppKit/NSCollectionView.h"
#import "AppKit/NSCollectionViewItem.h"
#import "AppKit/NSDiffableDataSource.h"
#import "AppKit/NSTableColumn.h"
#import "AppKit/NSTableView.h"
#import "AppKit/NSTextField.h"
#import "AppKit/NSColor.h"

#import "GSFastEnumeration.h"

#import "GSGuiPrivate.h"

/* 
#ifndef GS_BLOCKS_AVAILABLE
#define GS_BLOCKS_AVAILABLE 1
#endif

// Helper macro for checking blocks; fall back to runtime probing when GNUstep does not supply one.
#ifndef GS_IS_BLOCK
static inline BOOL
GS_IS_BLOCK(id obj)
{
  if (obj == nil)
    {
      return NO;
    }

  Class blockClass = objc_getClass("NSBlock");
  Class stackBlockClass = objc_getClass("_NSConcreteStackBlock");
  Class globalBlockClass = objc_getClass("_NSConcreteGlobalBlock");

  if ((blockClass != Nil && [obj isKindOfClass: blockClass])
      || (stackBlockClass != Nil && [obj isKindOfClass: stackBlockClass])
      || (globalBlockClass != Nil && [obj isKindOfClass: globalBlockClass]))
    {
      return YES;
    }

  return NO;
}
#endif
*/

static id
GSDiffableDefaultSectionIdentifier()
{
  static id defaultIdentifier = nil;

  if (defaultIdentifier == nil)
    {
      defaultIdentifier = RETAIN(@"__GSDiffableDefaultSectionIdentifier");
    }

  return defaultIdentifier;
}

@implementation NSDiffableDataSourceSnapshot

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      _sections = [NSMutableArray new];
      _itemsBySection = [NSMutableDictionary new];
      _reloadedSections = [NSMutableSet new];
      _reloadedItems = [NSMutableSet new];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_sections);
  DESTROY(_itemsBySection);
  DESTROY(_reloadedSections);
  DESTROY(_reloadedItems);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
  NSDiffableDataSourceSnapshot *copy = [[[self class] allocWithZone: zone] init];
  NSMutableArray *copiedSections = [_sections mutableCopy];
  NSMutableDictionary *copiedItems = [NSMutableDictionary dictionaryWithCapacity: [_itemsBySection count]];

  FOR_IN(id, section, _sections)
    {
      NSArray *items = [_itemsBySection objectForKey: section];
      if (items != nil)
        {
          NSMutableArray *sectionItems = [items mutableCopy];
          [copiedItems setObject: sectionItems forKey: section];
          RELEASE(sectionItems);
        }
    }
  END_FOR_IN(_sections);

  DESTROY(copy->_sections);
  DESTROY(copy->_itemsBySection);
  copy->_sections = copiedSections;
  copy->_itemsBySection = RETAIN(copiedItems);
  copy->_reloadedSections = [_reloadedSections mutableCopy];
  copy->_reloadedItems = [_reloadedItems mutableCopy];
  return copy;
}

- (id) mutableCopyWithZone: (NSZone *)zone
{
  return [self copyWithZone: zone];
}

- (NSArray *) sectionIdentifiers
{
  return AUTORELEASE([_sections copy]);
}

- (NSArray *) itemIdentifiers
{
  NSMutableArray *result = [NSMutableArray array];

  FOR_IN(id, section, _sections)
    {
      NSArray *items = [_itemsBySection objectForKey: section];
      if (items != nil)
        {
          [result addObjectsFromArray: items];
        }
    }
  END_FOR_IN(_sections);

  return AUTORELEASE([result copy]);
}

- (NSArray *) itemIdentifiersInSectionWithIdentifier: (id)sectionIdentifier
{
  NSArray *items = [_itemsBySection objectForKey: sectionIdentifier];

  if (items == nil)
    {
      return [NSArray array];
    }

  return AUTORELEASE([items copy]);
}

- (NSInteger) numberOfSections
{
  return [_sections count];
}

- (NSInteger) numberOfItems
{
  NSInteger count = 0;

  FOR_IN(id, section, _sections)
    {
      NSArray *items = [_itemsBySection objectForKey: section];
      count += [items count];
    }
  END_FOR_IN(_sections);

  return count;
}

- (void) _ensureSection: (id)sectionIdentifier
{
  if (sectionIdentifier == nil)
    {
      sectionIdentifier = GSDiffableDefaultSectionIdentifier();
    }

  if ([_sections containsObject: sectionIdentifier] == NO)
    {
      [_sections addObject: sectionIdentifier];
    }

  if ([_itemsBySection objectForKey: sectionIdentifier] == nil)
    {
      [_itemsBySection setObject: [NSMutableArray array]
                          forKey: sectionIdentifier];
    }
}

- (void) appendSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  FOR_IN(id, section, sectionIdentifiers)
    {
      [self _ensureSection: section];
    }
  END_FOR_IN(sectionIdentifiers);
}

- (NSInteger) _indexForSection: (id)sectionIdentifier
{
  return [_sections indexOfObject: sectionIdentifier];
}

- (void) insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
            beforeSectionWithIdentifier: (id)sectionIdentifier
{
  NSUInteger index = [_sections indexOfObject: sectionIdentifier];

  if (index == NSNotFound)
    {
      index = [_sections count];
    }

  NSUInteger insertionIndex = index;
  FOR_IN(id, section, sectionIdentifiers)
    {
      if ([_sections containsObject: section] == NO)
        {
          [_sections insertObject: section atIndex: insertionIndex];
          [_itemsBySection setObject: [NSMutableArray array]
                              forKey: section];
          insertionIndex++;
        }
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
             afterSectionWithIdentifier: (id)sectionIdentifier
{
  NSUInteger index = [_sections indexOfObject: sectionIdentifier];

  if (index == NSNotFound)
    {
      [self appendSectionsWithIdentifiers: sectionIdentifiers];
      return;
    }

  NSUInteger insertionIndex = index + 1;
  FOR_IN(id, section, sectionIdentifiers)
    {
      if ([_sections containsObject: section] == NO)
        {
          [_sections insertObject: section atIndex: insertionIndex];
          [_itemsBySection setObject: [NSMutableArray array]
                              forKey: section];
          insertionIndex++;
        }
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) deleteSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  FOR_IN(id, section, sectionIdentifiers)
    {
      [_sections removeObject: section];
      [_itemsBySection removeObjectForKey: section];
      [_reloadedSections removeObject: section];
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) moveSectionWithIdentifier: (id)sectionIdentifier
      beforeSectionWithIdentifier: (id)otherSectionIdentifier
{
  NSUInteger fromIndex = [_sections indexOfObject: sectionIdentifier];
  NSUInteger toIndex = [_sections indexOfObject: otherSectionIdentifier];

  if (fromIndex == NSNotFound || toIndex == NSNotFound)
    {
      return;
    }

  [_sections removeObjectAtIndex: fromIndex];
  if (fromIndex < toIndex)
    {
      toIndex--;
    }
  [_sections insertObject: sectionIdentifier atIndex: toIndex];
}

- (void) moveSectionWithIdentifier: (id)sectionIdentifier
       afterSectionWithIdentifier: (id)otherSectionIdentifier
{
  NSUInteger fromIndex = [_sections indexOfObject: sectionIdentifier];
  NSUInteger toIndex = [_sections indexOfObject: otherSectionIdentifier];

  if (fromIndex == NSNotFound || toIndex == NSNotFound)
    {
      return;
    }

  [_sections removeObjectAtIndex: fromIndex];
  if (fromIndex <= toIndex)
    {
      toIndex++;
    }
  [_sections insertObject: sectionIdentifier atIndex: toIndex];
}

- (void) appendItemsWithIdentifiers: (NSArray *)itemIdentifiers
{
  id section = [_sections lastObject];
  if (section == nil)
    {
      section = GSDiffableDefaultSectionIdentifier();
      [self appendSectionsWithIdentifiers: [NSArray arrayWithObject: section]];
    }
  [self appendItemsWithIdentifiers: itemIdentifiers intoSectionWithIdentifier: section];
}

- (void) appendItemsWithIdentifiers: (NSArray *)itemIdentifiers
           intoSectionWithIdentifier: (id)sectionIdentifier
{
  [self _ensureSection: sectionIdentifier];

  NSMutableArray *items = [_itemsBySection objectForKey: (sectionIdentifier ?: GSDiffableDefaultSectionIdentifier())];
  [items addObjectsFromArray: itemIdentifiers];
}

- (BOOL) _findItemIdentifier: (id)itemIdentifier
                   inSection: (id *)sectionOut
                       index: (NSUInteger *)indexOut
{
  NSUInteger sectionIndex = 0;

  for (sectionIndex = 0; sectionIndex < [_sections count]; sectionIndex++)
    {
      id section = [_sections objectAtIndex: sectionIndex];
      NSMutableArray *items = [_itemsBySection objectForKey: section];
      NSUInteger itemIndex = [items indexOfObject: itemIdentifier];
      if (itemIndex != NSNotFound)
        {
          if (sectionOut)
            {
              *sectionOut = section;
            }
          if (indexOut)
            {
              *indexOut = itemIndex;
            }
          return YES;
        }
    }
  return NO;
}

- (void) insertItemsWithIdentifiers: (NSArray *)itemIdentifiers
          beforeItemWithIdentifier: (id)beforeIdentifier
{
  if ([itemIdentifiers count] == 0)
    {
      return;
    }

  id section = nil;
  NSUInteger itemIndex = 0;

  if ([self _findItemIdentifier: beforeIdentifier inSection: &section index: &itemIndex])
    {
      NSMutableArray *items = [_itemsBySection objectForKey: section];
      NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(itemIndex, [itemIdentifiers count])];
      [items insertObjects: itemIdentifiers atIndexes: indexes];
    }
  else
    {
      [self appendItemsWithIdentifiers: itemIdentifiers];
    }
}

- (void) insertItemsWithIdentifiers: (NSArray *)itemIdentifiers
           afterItemWithIdentifier: (id)afterIdentifier
{
  if ([itemIdentifiers count] == 0)
    {
      return;
    }

  id section = nil;
  NSUInteger itemIndex = 0;

  if ([self _findItemIdentifier: afterIdentifier inSection: &section index: &itemIndex])
    {
      NSMutableArray *items = [_itemsBySection objectForKey: section];
      NSUInteger start = itemIndex + 1;
      NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(start, [itemIdentifiers count])];
      [items insertObjects: itemIdentifiers atIndexes: indexes];
    }
  else
    {
      [self appendItemsWithIdentifiers: itemIdentifiers];
    }
}

- (void) deleteItemsWithIdentifiers: (NSArray *)itemIdentifiers
{
  FOR_IN(id, itemIdentifier, itemIdentifiers)
    {
      id section = nil;
      NSUInteger index = 0;
      if ([self _findItemIdentifier: itemIdentifier inSection: &section index: &index])
        {
          NSMutableArray *items = [_itemsBySection objectForKey: section];
          if (index < [items count])
            {
              [items removeObjectAtIndex: index];
            }
        }
      [_reloadedItems removeObject: itemIdentifier];
    }
  END_FOR_IN(itemIdentifiers);
}

- (void) reloadSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  FOR_IN(id, section, sectionIdentifiers)
    {
      [_reloadedSections addObject: section];
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) reloadItemsWithIdentifiers: (NSArray *)itemIdentifiers
{
  FOR_IN(id, item, itemIdentifiers)
    {
      [_reloadedItems addObject: item];
    }
  END_FOR_IN(itemIdentifiers);
}

@end

@implementation NSCollectionViewDiffableDataSource

- (id) initWithCollectionView: (NSCollectionView *)collectionView
                  itemProvider: (GSCollectionViewItemProviderBlock)itemProvider
{
  self = [super init];
  if (self != nil)
    {
      _collectionView = collectionView;
      _snapshot = [NSDiffableDataSourceSnapshot new];
      _itemProvider = RETAIN( itemProvider );
      _identifierToIndexPath = [NSMutableDictionary new];
      [_collectionView setDataSource: self];
      if ([_collectionView respondsToSelector: @selector(setPrefetchDataSource:)])
        {
          [_collectionView setPrefetchDataSource: (id<NSCollectionViewPrefetching>)self];
        }
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_snapshot);
  // DESTROY(_itemProvider);
  DESTROY(_identifierToIndexPath);
  [super dealloc];
}

- (void) _rebuildIndexLookup
{
  [_identifierToIndexPath removeAllObjects];

  NSUInteger sectionIndex = 0;
  NSArray *sections = [_snapshot sectionIdentifiers];
  FOR_IN(id, section, sections)
    {
      NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
      NSUInteger itemIndex = 0;

      for (itemIndex = 0; itemIndex < [items count]; itemIndex++)
        {
          NSIndexPath *path = [NSIndexPath indexPathForItem: itemIndex inSection: sectionIndex];
          [_identifierToIndexPath setObject: RETAIN(path) forKey: [items objectAtIndex: itemIndex]];
        }
      sectionIndex++;
    }
  END_FOR_IN(sections);
}

- (void) applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences
{
  (void)animatingDifferences;
  DESTROY(_snapshot);
  if (snapshot == nil)
    {
      _snapshot = [NSDiffableDataSourceSnapshot new];
    }
  else
    {
      _snapshot = [snapshot copy];
    }
  [self _rebuildIndexLookup];
  [_collectionView reloadData];
}

- (NSDiffableDataSourceSnapshot *) snapshot
{
  return AUTORELEASE([_snapshot copy]);
}

- (NSIndexPath *) indexPathForItemIdentifier: (id)itemIdentifier
{
  return [_identifierToIndexPath objectForKey: itemIdentifier];
}

- (id) itemIdentifierForIndexPath: (NSIndexPath *)indexPath
{
  if (_snapshot == nil)
    {
      return nil;
    }

  NSArray *sections = [_snapshot sectionIdentifiers];
  NSUInteger sectionIndex = [indexPath section];
  if (sectionIndex >= [sections count])
    {
      return nil;
    }

  id sectionIdentifier = [sections objectAtIndex: sectionIndex];
  NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: sectionIdentifier];
  NSUInteger itemIndex = [indexPath item];
  if (itemIndex >= [items count])
    {
      return nil;
    }

  return [items objectAtIndex: itemIndex];
}

- (NSInteger) numberOfSectionsInCollectionView: (NSCollectionView *)collectionView
{
  (void)collectionView;
  return [_snapshot numberOfSections];
}

- (NSInteger) collectionView: (NSCollectionView *)collectionView
       numberOfItemsInSection: (NSInteger)section
{
  (void)collectionView;
  NSArray *sections = [_snapshot sectionIdentifiers];
  if (section < 0 || section >= (NSInteger)[sections count])
    {
      return 0;
    }

  id sectionIdentifier = [sections objectAtIndex: section];
  return [[_snapshot itemIdentifiersInSectionWithIdentifier: sectionIdentifier] count];
}

- (NSCollectionViewItem *) collectionView: (NSCollectionView *)collectionView
      itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  id identifier = [self itemIdentifierForIndexPath: indexPath];
  if (identifier == nil || _itemProvider == nil)
    {
      return nil;
    }
  /*
  if ([_itemProvider respondsToSelector: @selector(collectionView:itemForIdentifier:atIndexPath:)])
    {
      NSCollectionViewItem *item = [(id)_itemProvider collectionView: collectionView
                                                   itemForIdentifier: identifier
                                                         atIndexPath: indexPath];
      if ([item respondsToSelector: @selector(setRepresentedObject:)])
        {
          [item setRepresentedObject: identifier];
        }
      return item;
    }
  */
  if (_itemProvider != nil)
    {
      /* Apple-compatible block order: collectionView, indexPath, identifier */
      NSCollectionViewItem *item = (NSCollectionViewItem *)CALL_NON_NULL_BLOCK(_itemProvider, collectionView, indexPath, identifier);
      if ([item respondsToSelector: @selector(setRepresentedObject:)])
        {
          [item setRepresentedObject: identifier];
        }
      return item;
    }

  return nil;
}

- (void) collectionView: (NSCollectionView *)collectionView
   prefetchItemsAtIndexPaths: (NSArray *)indexPaths
{
  (void)collectionView;
  (void)indexPaths;
  /* Prefetch is currently a no-op; snapshot drives item creation. */
}

- (void) collectionView: (NSCollectionView *)collectionView
cancelPrefetchingForItemsAtIndexPaths: (NSArray *)indexPaths
{
  (void)collectionView;
  (void)indexPaths;
  /* Prefetch cancellation is currently a no-op. */
}

@end

@implementation NSTableViewDiffableDataSource

- (id) initWithTableView: (NSTableView *)tableView
            cellProvider: (GSTableViewCellProviderBlock)cellProvider
{
  self = [super init];
  if (self != nil)
    {
      _tableView = tableView;
      _snapshot = [NSDiffableDataSourceSnapshot new];
      _cellProvider = RETAIN(cellProvider);
      _identifierToIndexPath = [NSMutableDictionary new];
      [_tableView setDataSource: self];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_snapshot);
  DESTROY(_cellProvider);
  DESTROY(_identifierToIndexPath);
  [super dealloc];
}

- (void) _rebuildIndexLookup
{
  [_identifierToIndexPath removeAllObjects];

  NSUInteger sectionIndex = 0;
  NSArray *sections = [_snapshot sectionIdentifiers];
  FOR_IN(id, section, sections)
    {
      NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
      NSUInteger itemIndex = 0;

      for (itemIndex = 0; itemIndex < [items count]; itemIndex++)
        {
          NSIndexPath *path = [NSIndexPath indexPathForItem: itemIndex inSection: sectionIndex];
          [_identifierToIndexPath setObject: RETAIN(path) forKey: [items objectAtIndex: itemIndex]];
        }
      sectionIndex++;
    }
  END_FOR_IN(sections);
}

- (void) applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences
{
  (void)animatingDifferences;
  DESTROY(_snapshot);
  if (snapshot == nil)
    {
      _snapshot = [NSDiffableDataSourceSnapshot new];
    }
  else
    {
      _snapshot = [snapshot copy];
    }
  [self _rebuildIndexLookup];
  [_tableView reloadData];
}

- (NSDiffableDataSourceSnapshot *) snapshot
{
  return AUTORELEASE([_snapshot copy]);
}

- (NSIndexPath *) indexPathForItemIdentifier: (id)itemIdentifier
{
  return [_identifierToIndexPath objectForKey: itemIdentifier];
}

- (id) itemIdentifierForIndexPath: (NSIndexPath *)indexPath
{
  NSArray *sections = [_snapshot sectionIdentifiers];
  NSUInteger sectionIndex = [indexPath section];
  if (sectionIndex >= [sections count])
    {
      return nil;
    }
  id sectionIdentifier = [sections objectAtIndex: sectionIndex];
  NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: sectionIdentifier];
  NSUInteger itemIndex = [indexPath item];
  if (itemIndex >= [items count])
    {
      return nil;
    }
  return [items objectAtIndex: itemIndex];
}

- (id) itemIdentifierForRow: (NSInteger)row
{
  NSInteger runningTotal = 0;

  NSArray *sections = [_snapshot sectionIdentifiers];
  FOR_IN(id, section, sections)
    {
      NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
      NSInteger nextTotal = runningTotal + [items count];
      if (row < nextTotal)
        {
          NSInteger localIndex = row - runningTotal;
          return [items objectAtIndex: localIndex];
        }
      runningTotal = nextTotal;
    }
  END_FOR_IN(sections);

  return nil;
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
  (void)tableView;
  return [_snapshot numberOfItems];
}

- (id) tableView: (NSTableView *)tableView
objectValueForTableColumn: (NSTableColumn *)tableColumn
             row: (NSInteger)rowIndex
{
  (void)tableView;
  (void)tableColumn;
  return [self itemIdentifierForRow: rowIndex];
}

- (NSView *) tableView: (NSTableView *)tableView
    viewForTableColumn: (NSTableColumn *)tableColumn
                   row: (NSInteger)rowIndex
{
  id identifier = [self itemIdentifierForRow: rowIndex];
  if (identifier == nil)
    {
      return nil;
    }

  if (_cellProvider != nil
      && [_cellProvider respondsToSelector: @selector(tableView:viewForIdentifier:tableColumn:row:)])
    {
      NSView *view = [(id)_cellProvider tableView: tableView
                                  viewForIdentifier: identifier
                                       tableColumn: tableColumn
                                              row: rowIndex];
      if (view != nil)
        {
          return view;
        }
    }

  if (_cellProvider != nil) // (GS_BLOCKS_AVAILABLE && GS_IS_BLOCK(_cellProvider))
    {
      NSView *view = (NSView *)CALL_NON_NULL_BLOCK(_cellProvider, tableView, identifier, tableColumn, rowIndex);
      if (view != nil)
        {
          return view;
        }
    }

  // Fallback to a simple text field if no provider is supplied.
  NSTextField *textField = AUTORELEASE([NSTextField new]);
  [textField setEditable: NO];
  [textField setBordered: NO];
  [textField setBackgroundColor: [NSColor clearColor]];
  [textField setStringValue: [identifier description]];
  return textField;
}

@end
