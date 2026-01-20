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

@interface NSCollectionView (Private)
- (NSCollectionViewItem *) _itemForIndexPath: (NSIndexPath *)p;
@end

@implementation NSCollectionView (Private)
- (NSCollectionViewItem *) _itemForIndexPath: (NSIndexPath *)p
{
  NSCollectionViewItem *item = [_indexPathsToItems objectForKey: p];
  NSLog(@"[DiffableDataSource] _itemForIndexPath:%@ -> %@", p, item);
  return item;
}
@end

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

  {
    NSEnumerator *sectionEnumerator = [_sections objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        NSArray *items = [_itemsBySection objectForKey: section];
        if (items != nil)
          {
            NSMutableArray *sectionItems = [items mutableCopy];
            [copiedItems setObject: sectionItems forKey: section];
            // RELEASE(sectionItems);
          }
      }
  }

  //DESTROY(copy->_sections);
  //DESTROY(copy->_itemsBySection);
  //DESTROY(copy->_reloadedSections);
  //DESTROY(copy->_reloadedItems);

  ASSIGNCOPY(copy->_sections, copiedSections);
  ASSIGNCOPY(copy->_itemsBySection, copiedItems);
  ASSIGNCOPY(copy->_reloadedSections, _reloadedSections);
  ASSIGNCOPY(copy->_reloadedItems, _reloadedItems);

  return copy;
}

- (id) mutableCopyWithZone: (NSZone *)zone
{
  return [self copyWithZone: zone];
}

- (NSArray *) sectionIdentifiers
{
  if (_sections == nil)
    {
      return [NSArray array];
    }
  return [_sections copy];
}

- (NSArray *) itemIdentifiers
{
  NSMutableArray *result = [NSMutableArray array];

  {
    NSEnumerator *sectionEnumerator = [_sections objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        NSArray *items = [_itemsBySection objectForKey: section];
        if (items != nil)
          {
            [result addObjectsFromArray: items];
          }
      }
  }

  return [result copy];
}

- (NSArray *) itemIdentifiersInSectionWithIdentifier: (id)sectionIdentifier
{
  NSArray *items = [_itemsBySection objectForKey: sectionIdentifier];

  if (items == nil)
    {
      return [NSArray array];
    }

  return [items copy];
}

- (NSInteger) numberOfSections
{
  if (_sections == nil)
    {
      return 0;
    }
  return [_sections count];
}

- (NSInteger) numberOfItems
{
  NSInteger count = 0;

  {
    NSEnumerator *sectionEnumerator = [_sections objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        NSArray *items = [_itemsBySection objectForKey: section];
        count += [items count];
      }
  }

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
  {
    NSEnumerator *sectionEnumerator = [sectionIdentifiers objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        [self _ensureSection: section];
      }
  }
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
  {
    NSEnumerator *sectionEnumerator = [sectionIdentifiers objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        if ([_sections containsObject: section] == NO)
          {
            [_sections insertObject: section atIndex: insertionIndex];
            [_itemsBySection setObject: [NSMutableArray array]
                                forKey: section];
            insertionIndex++;
          }
      }
  }
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
  {
    NSEnumerator *sectionEnumerator = [sectionIdentifiers objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        if ([_sections containsObject: section] == NO)
          {
            [_sections insertObject: section atIndex: insertionIndex];
            [_itemsBySection setObject: [NSMutableArray array]
                                forKey: section];
            insertionIndex++;
          }
      }
  }
}

- (void) deleteSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  {
    NSEnumerator *sectionEnumerator = [sectionIdentifiers objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        [_sections removeObject: section];
        [_itemsBySection removeObjectForKey: section];
        [_reloadedSections removeObject: section];
      }
  }
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
  {
    NSEnumerator *itemEnumerator = [itemIdentifiers objectEnumerator];
    id itemIdentifier;
    while ((itemIdentifier = [itemEnumerator nextObject]) != nil)
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
  }
}

- (void) reloadSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  {
    NSEnumerator *sectionEnumerator = [sectionIdentifiers objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        [_reloadedSections addObject: section];
      }
  }
}

- (void) reloadItemsWithIdentifiers: (NSArray *)itemIdentifiers
{
  {
    NSEnumerator *itemEnumerator = [itemIdentifiers objectEnumerator];
    id item;
    while ((item = [itemEnumerator nextObject]) != nil)
      {
        [_reloadedItems addObject: item];
      }
  }
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
      _creatingIndexPaths = [NSMutableSet new];
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
  DESTROY(_creatingIndexPaths);
  [super dealloc];
}

- (void) _rebuildIndexLookup
{
  [_identifierToIndexPath removeAllObjects];

  NSUInteger sectionIndex = 0;
  NSArray *sections = [_snapshot sectionIdentifiers];
  {
    NSEnumerator *sectionEnumerator = [sections objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
      {
        NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
        NSUInteger itemIndex = 0;

        for (itemIndex = 0; itemIndex < [items count]; itemIndex++)
          {
            // Build an index path explicitly to avoid any Foundation-specific
            // convenience method issues with item/section on some platforms.
            NSIndexPath *path = [NSIndexPath indexPathWithIndex: sectionIndex];
            path = [path indexPathByAddingIndex: itemIndex];
            [_identifierToIndexPath setObject: RETAIN(path) forKey: [items objectAtIndex: itemIndex]];
          }
        sectionIndex++;
      }
  }
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
  return [_snapshot copy];
}

- (NSIndexPath *) indexPathForItemIdentifier: (id)itemIdentifier
{
  return [_identifierToIndexPath objectForKey: itemIdentifier];
}

- (id) itemIdentifierForIndexPath: (NSIndexPath *)indexPath
{
  NSLog(@"- (id) itemIdentifierForIndexPath: %@", indexPath);
  if (_snapshot == nil || indexPath == nil)
    {
      return nil;
    }

  NSArray *sections = [_snapshot sectionIdentifiers];
  if (sections == nil)
    {
      return nil;
    }

  // Avoid relying on section/item accessors which may return 0 on some platforms.
  NSUInteger sectionIndex = 0;
  NSUInteger itemIndex = 0;

  if ([indexPath respondsToSelector: @selector(length)] && [indexPath length] >= 2)
    {
      sectionIndex = [indexPath indexAtPosition: 0];
      itemIndex = [indexPath indexAtPosition: 1];
    }
  else
    {
      // Fallback to accessors if available
      if ([indexPath respondsToSelector: @selector(section)])
        {
          sectionIndex = [indexPath section];
        }
      if ([indexPath respondsToSelector: @selector(item)])
        {
          itemIndex = [indexPath item];
        }
    }

  if (sectionIndex >= [sections count])
    {
      return nil;
    }

  id sectionIdentifier = [sections objectAtIndex: sectionIndex];
  NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: sectionIdentifier];
  if (itemIndex >= [items count])
    {
      NSLog(@"No items");
      return nil;
    }

  NSLog(@"items = %@", items);

  return [items objectAtIndex: itemIndex];
}

- (NSInteger) numberOfSectionsInCollectionView: (NSCollectionView *)collectionView
{
  (void)collectionView;
  if (_snapshot == nil)
    {
      NSLog(@"[DiffableDataSource] numberOfSectionsInCollectionView: 0 (nil snapshot)");
      return 0;
    }
  NSInteger count = [_snapshot numberOfSections];
  NSLog(@"[DiffableDataSource] numberOfSectionsInCollectionView: %ld", (long)count);
  return count;
}

- (NSInteger) collectionView: (NSCollectionView *)collectionView
       numberOfItemsInSection: (NSInteger)section
{
  (void)collectionView;
  if (_snapshot == nil)
    {
      NSLog(@"[DiffableDataSource] numberOfItemsInSection:%ld -> 0 (nil snapshot)", (long)section);
      return 0;
    }
  
  NSArray *sections = [_snapshot sectionIdentifiers];
  if (sections == nil || section < 0 || section >= (NSInteger)[sections count])
    {
      NSLog(@"[DiffableDataSource] numberOfItemsInSection:%ld -> 0 (invalid)", (long)section);
      return 0;
    }

  id sectionIdentifier = [sections objectAtIndex: section];
  if (sectionIdentifier == nil)
    {
      NSLog(@"[DiffableDataSource] numberOfItemsInSection:%ld -> 0 (nil section identifier)", (long)section);
      return 0;
    }
  
  NSInteger count = [[_snapshot itemIdentifiersInSectionWithIdentifier: sectionIdentifier] count];
  NSLog(@"[DiffableDataSource] numberOfItemsInSection:%ld -> %ld", (long)section, (long)count);
  return count;
}

- (NSCollectionViewItem *) collectionView: (NSCollectionView *)collectionView
      itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  NSLog(@"[DiffableDataSource] itemForRepresentedObjectAtIndexPath:%@", indexPath);

  // Recursion guard: if we're already creating an item for this index path, return nil
  if ([_creatingIndexPaths containsObject: indexPath])
    {
      NSLog(@"[DiffableDataSource] Preventing recursive call for indexPath %@", indexPath);
      return nil;
    }

  id identifier = [self itemIdentifierForIndexPath: indexPath];
  NSCollectionViewItem *result = [collectionView _itemForIndexPath: indexPath];

  NSLog(@"[DiffableDataSource] identifier=%@, existing result=%@", identifier, result);

  if (result == nil)
    {
      if (identifier == nil || _itemProvider == nil)
	{
	  NSLog(@"[DiffableDataSource] Cannot create item: identifier=%@, itemProvider=%@", identifier, _itemProvider);
	  return nil;
	}

      if (_itemProvider != nil)
	{
	  NSLog(@"[DiffableDataSource] Creating new item for identifier=%@", identifier);
	  
	  // Mark that we're creating an item for this index path
	  [_creatingIndexPaths addObject: indexPath];

	  // Build a provider-friendly index path using item/section semantics.
	  {
	    NSUInteger sectionIndex = 0;
	    NSUInteger itemIndex = 0;

	    if ([indexPath respondsToSelector: @selector(length)] && [indexPath length] >= 2)
	      {
		sectionIndex = [indexPath indexAtPosition: 0];
		itemIndex = [indexPath indexAtPosition: 1];
	      }
	    else
	      {
		if ([indexPath respondsToSelector: @selector(section)])
		  {
		    sectionIndex = [indexPath section];
		  }
		if ([indexPath respondsToSelector: @selector(item)])
		  {
		    itemIndex = [indexPath item];
		  }
	      }

	    NSIndexPath *providerIndexPath = [NSIndexPath indexPathForItem: itemIndex
							       inSection: sectionIndex];
	    
	    NSLog(@"[DiffableDataSource] Calling item provider with indexPath=%@, identifier=%@", providerIndexPath, identifier);
	    
	    result = (NSCollectionViewItem *)
	      CALL_NON_NULL_BLOCK(_itemProvider,
				  collectionView,
				  providerIndexPath,
				  identifier);

	    NSLog(@"[DiffableDataSource] Item provider returned: %@", result);

	    if ([result respondsToSelector: @selector(setRepresentedObject:)])
	      {
		[result setRepresentedObject: identifier];
	      }
	  }
	  
	  // Always remove from the creating set
	  [_creatingIndexPaths removeObject: indexPath];
	  NSLog(@"[DiffableDataSource] Removed indexPath %@ from creating set", indexPath);
	}
    }

  NSLog(@"[DiffableDataSource] Returning result: %@", result);
  return result;
}

- (void) collectionView: (NSCollectionView *)collectionView
   prefetchItemsAtIndexPaths: (NSArray *)indexPaths
{
  /* Prefetch is currently a no-op; snapshot drives item creation. */
}

- (void) collectionView: (NSCollectionView *)collectionView
cancelPrefetchingForItemsAtIndexPaths: (NSArray *)indexPaths
{
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
      _creatingIndexPaths = [NSMutableSet new];
      [_tableView setDataSource: self];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_snapshot);
  DESTROY(_cellProvider);
  DESTROY(_identifierToIndexPath);
  DESTROY(_creatingIndexPaths);
  [super dealloc];
}

- (void) _rebuildIndexLookup
{
  [_identifierToIndexPath removeAllObjects];

  NSUInteger sectionIndex = 0;
  NSArray *sections = [_snapshot sectionIdentifiers];
  {
    NSEnumerator *sectionEnumerator = [sections objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
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
  }
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
  return [_snapshot copy];
}

- (NSIndexPath *) indexPathForItemIdentifier: (id)itemIdentifier
{
  return [_identifierToIndexPath objectForKey: itemIdentifier];
}

- (id) itemIdentifierForIndexPath: (NSIndexPath *)indexPath
{
  NSArray *sections = [_snapshot sectionIdentifiers];

  NSUInteger sectionIndex = 0;
  NSUInteger itemIndex = 0;

  if ([indexPath respondsToSelector: @selector(length)] && [indexPath length] >= 2)
    {
      sectionIndex = [indexPath indexAtPosition: 0];
      itemIndex = [indexPath indexAtPosition: 1];
    }
  else
    {
      if ([indexPath respondsToSelector: @selector(section)])
        {
          sectionIndex = [indexPath section];
        }
      if ([indexPath respondsToSelector: @selector(item)])
        {
          itemIndex = [indexPath item];
        }
    }

  if (sectionIndex >= [sections count])
    {
      return nil;
    }
  id sectionIdentifier = [sections objectAtIndex: sectionIndex];
  NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: sectionIdentifier];
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
  {
    NSEnumerator *sectionEnumerator = [sections objectEnumerator];
    id section;
    while ((section = [sectionEnumerator nextObject]) != nil)
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
  }

  return nil;
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
  return [_snapshot numberOfItems];
}

- (id) tableView: (NSTableView *)tableView
objectValueForTableColumn: (NSTableColumn *)tableColumn
             row: (NSInteger)rowIndex
{
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

  if (_cellProvider != nil) // (GS_BLOCKS_AVAILABLE && GS_IS_BLOCK(_cellProvider))
    {
      NSView *view = (NSView *)CALL_NON_NULL_BLOCK(_cellProvider, tableView, identifier, tableColumn, rowIndex);
      if (view != nil)
        {
          return view;
        }
    }

  // Fallback to a simple text field if no provider is supplied.
  NSTextField *textField = [NSTextField new];
  [textField setEditable: NO];
  [textField setBordered: NO];
  [textField setBackgroundColor: [NSColor clearColor]];
  [textField setStringValue: [identifier description]];
  return textField;
}

@end
