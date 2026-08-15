/** <title>NSDiffableDataSource</title>

   Diffable data source helpers for collection and table views.

   Author: Gregory Casamento <greg.casamento@gmail.com>
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
#import <Foundation/NSException.h>
#import <Foundation/NSSet.h>
#import <GNUstepBase/GSBlocks.h>

#import "AppKit/NSCollectionView.h"
#import "AppKit/NSCollectionViewItem.h"
#import "AppKit/NSDiffableDataSource.h"
#import "AppKit/NSTableColumn.h"
#import "AppKit/NSTableRowView.h"
#import "AppKit/NSTableView.h"
#import "AppKit/NSTextField.h"
#import "AppKit/NSColor.h"

#import "GSGuiPrivate.h"
#import "GSFastEnumeration.h"

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

@interface NSDiffableDataSourceSnapshot (GSDiffablePrivate)
- (NSSet *) _gsReloadedSections;
- (NSSet *) _gsReloadedItems;
@end

static NSInteger
GSDiffableRowForItemInSnapshot(NSDiffableDataSourceSnapshot *snapshot,
			       id itemIdentifier)
{
  NSArray *sections = [snapshot sectionIdentifiers];
  NSInteger row = 0;

  FOR_IN(id, section, sections)
    {
      NSArray *items = [snapshot itemIdentifiersInSectionWithIdentifier: section];
      NSUInteger itemIndex = [items indexOfObject: itemIdentifier];

      if (itemIndex != NSNotFound)
	{
	  return row + itemIndex;
	}
      row += [items count];
    }
  END_FOR_IN(sections);

  return NSNotFound;
}

static id
GSDiffableSectionForRowInSnapshot(NSDiffableDataSourceSnapshot *snapshot,
				  NSInteger row)
{
  NSArray *sections = [snapshot sectionIdentifiers];
  NSInteger runningTotal = 0;

  FOR_IN(id, section, sections)
    {
      NSInteger itemCount =
	[[snapshot itemIdentifiersInSectionWithIdentifier: section] count];

      if (row >= runningTotal && row < runningTotal + itemCount)
	{
	  return section;
	}
      runningTotal += itemCount;
    }
  END_FOR_IN(sections);

  return nil;
}

static NSInteger
GSDiffableRowForSectionInSnapshot(NSDiffableDataSourceSnapshot *snapshot,
				  id sectionIdentifier)
{
  NSArray *sections = [snapshot sectionIdentifiers];
  NSInteger runningTotal = 0;

  FOR_IN(id, section, sections)
    {
      if ([section isEqual: sectionIdentifier])
	{
	  return runningTotal;
	}
      runningTotal +=
	[[snapshot itemIdentifiersInSectionWithIdentifier: section] count];
    }
  END_FOR_IN(sections);

  return NSNotFound;
}

@implementation NSDiffableDataSourceSnapshot

- (id) _normalizedSectionIdentifier: (id)sectionIdentifier
{
  return sectionIdentifier ?: GSDiffableDefaultSectionIdentifier();
}

- (void) _raiseInvalidArgument: (NSString *)reason
{
  [NSException raise: NSInvalidArgumentException format: @"%@", reason];
}

- (NSSet *) _gsReloadedSections
{
  return _reloadedSections;
}

- (NSSet *) _gsReloadedItems
{
  return _reloadedItems;
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      _sections = [[NSMutableArray alloc] init];
      _itemsBySection = [[NSMutableDictionary alloc] init];
      _reloadedSections = [[NSMutableSet alloc] init];
      _reloadedItems = [[NSMutableSet alloc] init];
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
  NSDiffableDataSourceSnapshot	*copy;
  NSMutableDictionary 		*copiedItems;
  NSMutableArray 		*copiedSections;
  NSEnumerator 			*sectionEnumerator;
  id 				section;

  copy = [[[self class] allocWithZone: zone] init];
  copiedItems = [NSMutableDictionary dictionaryWithCapacity:
    [_itemsBySection count]];
  copiedSections = AUTORELEASE([_sections mutableCopy]);
  sectionEnumerator = [copiedSections objectEnumerator];

  while ((section = [sectionEnumerator nextObject]) != nil)
    {
      NSArray *items = [_itemsBySection objectForKey: section];

      if (items != nil)
	{
	  NSMutableArray *sectionItems = [items mutableCopy];
	  [copiedItems setObject: sectionItems forKey: section];
	  RELEASE(sectionItems);
	}
    }

  // These are already copied above, simply assign...
  ASSIGN(copy->_sections, copiedSections);
  ASSIGN(copy->_itemsBySection, copiedItems);
  ASSIGN(copy->_reloadedSections, AUTORELEASE([_reloadedSections mutableCopy]));
  ASSIGN(copy->_reloadedItems, AUTORELEASE([_reloadedItems mutableCopy]));

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
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];

  NSArray *items = [_itemsBySection objectForKey: sectionIdentifier];

  if (items == nil)
    {
      return [NSArray array];
    }

  return AUTORELEASE([items copy]);
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
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];

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
      section = [self _normalizedSectionIdentifier: section];
      if ([_sections containsObject: section])
	{
	  [self _raiseInvalidArgument:
	    [NSString stringWithFormat: @"Section identifier %@ already exists", section]];
	}
      [self _ensureSection: section];
    }
  END_FOR_IN(sectionIdentifiers);
}

- (NSInteger) _indexForSection: (id)sectionIdentifier
{
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];
  return [_sections indexOfObject: sectionIdentifier];
}

- (void) insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
	   beforeSectionWithIdentifier: (id)sectionIdentifier
{
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];
  NSUInteger insertionIndex = [_sections indexOfObject: sectionIdentifier];

  if (insertionIndex == NSNotFound)
    {
      insertionIndex = [_sections count];
    }

  FOR_IN(id, section, sectionIdentifiers)
    {
      section = [self _normalizedSectionIdentifier: section];
      if ([_sections containsObject: section])
	{
	  [self _raiseInvalidArgument:
	    [NSString stringWithFormat: @"Section identifier %@ already exists", section]];
	}
      [_sections insertObject: section atIndex: insertionIndex];
      [_itemsBySection setObject: [NSMutableArray array]
			  forKey: section];
      insertionIndex++;
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) insertSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
	    afterSectionWithIdentifier: (id)sectionIdentifier
{
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];
  NSUInteger index = [_sections indexOfObject: sectionIdentifier];

  if (index == NSNotFound)
    {
      [self appendSectionsWithIdentifiers: sectionIdentifiers];
      return;
    }

  NSUInteger insertionIndex = index + 1;
  FOR_IN(id, section, sectionIdentifiers)
    {
      section = [self _normalizedSectionIdentifier: section];
      if ([_sections containsObject: section])
	{
	  [self _raiseInvalidArgument:
	    [NSString stringWithFormat: @"Section identifier %@ already exists", section]];
	}
      [_sections insertObject: section atIndex: insertionIndex];
      [_itemsBySection setObject: [NSMutableArray array]
			  forKey: section];
      insertionIndex++;
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) deleteSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  FOR_IN(id, section, sectionIdentifiers)
    {
      section = [self _normalizedSectionIdentifier: section];
      [_sections removeObject: section];
      [_itemsBySection removeObjectForKey: section];
      [_reloadedSections removeObject: section];
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) moveSectionWithIdentifier: (id)sectionIdentifier
       beforeSectionWithIdentifier: (id)otherSectionIdentifier
{
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];
  otherSectionIdentifier = [self _normalizedSectionIdentifier: otherSectionIdentifier];
  NSUInteger fromIndex = [_sections indexOfObject: sectionIdentifier];
  NSUInteger toIndex = [_sections indexOfObject: otherSectionIdentifier];

  if ([sectionIdentifier isEqual: otherSectionIdentifier])
    {
      return;
    }

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
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];
  otherSectionIdentifier = [self _normalizedSectionIdentifier: otherSectionIdentifier];
  NSUInteger fromIndex = [_sections indexOfObject: sectionIdentifier];
  NSUInteger toIndex = [_sections indexOfObject: otherSectionIdentifier];

  if ([sectionIdentifier isEqual: otherSectionIdentifier])
    {
      return;
    }

  if (fromIndex == NSNotFound || toIndex == NSNotFound)
    {
      return;
    }

  [_sections removeObjectAtIndex: fromIndex];
  if (fromIndex < toIndex)
    {
      toIndex--;
    }

  [_sections insertObject: sectionIdentifier atIndex: toIndex + 1];
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
  sectionIdentifier = [self _normalizedSectionIdentifier: sectionIdentifier];
  [self _ensureSection: sectionIdentifier];

  NSMutableArray *items = [_itemsBySection objectForKey: sectionIdentifier];
  [self _validateNewItemIdentifiers: itemIdentifiers];
  [items addObjectsFromArray: itemIdentifiers];
}

- (BOOL) _findItemIdentifier: (id)itemIdentifier
		   inSection: (id *)sectionOut
		       index: (NSUInteger *)indexOut
{
  NSUInteger sectionIndex = 0;
  NSUInteger count = [_sections count];

  for (sectionIndex = 0; sectionIndex < count; sectionIndex++)
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

- (void) _validateNewItemIdentifiers: (NSArray *)itemIdentifiers
{
  NSMutableSet *seen = [NSMutableSet set];

  FOR_IN(id, item, itemIdentifiers)
    {
      if ([seen containsObject: item]
	  || [self _findItemIdentifier: item inSection: NULL index: NULL])
	{
	  [self _raiseInvalidArgument:
	    [NSString stringWithFormat: @"Item identifier %@ already exists", item]];
	}
      [seen addObject: item];
    }
  END_FOR_IN(itemIdentifiers);
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
      [self _validateNewItemIdentifiers: itemIdentifiers];
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
      [self _validateNewItemIdentifiers: itemIdentifiers];
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
	      [_reloadedItems removeObject: itemIdentifier];
	    }
	}
    }
  END_FOR_IN(itemIdentifiers);
}

- (void) moveItemWithIdentifier: (id)itemIdentifier
       beforeItemWithIdentifier: (id)toIdentifier
{
  id fromSection = nil;
  id toSection = nil;
  NSUInteger fromIndex = 0;
  NSUInteger toIndex = 0;

  if ([itemIdentifier isEqual: toIdentifier])
    {
      return;
    }

  if ([self _findItemIdentifier: itemIdentifier inSection: &fromSection index: &fromIndex] == NO
      || [self _findItemIdentifier: toIdentifier inSection: &toSection index: &toIndex] == NO)
    {
      return;
    }

  NSMutableArray *fromItems = [_itemsBySection objectForKey: fromSection];
  NSMutableArray *toItems = [_itemsBySection objectForKey: toSection];

  RETAIN(itemIdentifier);
  [fromItems removeObjectAtIndex: fromIndex];
  if (fromItems == toItems && fromIndex < toIndex)
    {
      toIndex--;
    }
  [toItems insertObject: itemIdentifier atIndex: toIndex];
  RELEASE(itemIdentifier);
}

- (void) moveItemWithIdentifier: (id)itemIdentifier
	afterItemWithIdentifier: (id)toIdentifier
{
  id fromSection = nil;
  id toSection = nil;
  NSUInteger fromIndex = 0;
  NSUInteger toIndex = 0;

  if ([itemIdentifier isEqual: toIdentifier])
    {
      return;
    }

  if ([self _findItemIdentifier: itemIdentifier inSection: &fromSection index: &fromIndex] == NO
      || [self _findItemIdentifier: toIdentifier inSection: &toSection index: &toIndex] == NO)
    {
      return;
    }

  NSMutableArray *fromItems = [_itemsBySection objectForKey: fromSection];
  NSMutableArray *toItems = [_itemsBySection objectForKey: toSection];

  RETAIN(itemIdentifier);
  [fromItems removeObjectAtIndex: fromIndex];
  if (fromItems == toItems && fromIndex < toIndex)
    {
      toIndex--;
    }
  [toItems insertObject: itemIdentifier atIndex: toIndex + 1];
  RELEASE(itemIdentifier);
}

- (void) reloadSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  FOR_IN(id, section, sectionIdentifiers)
    {
      section = [self _normalizedSectionIdentifier: section];
      if ([_sections containsObject: section])
	{
	  [_reloadedSections addObject: section];
	}
    }
  END_FOR_IN(sectionIdentifiers);
}

- (void) reloadItemsWithIdentifiers: (NSArray *)itemIdentifiers
{
  FOR_IN(id, item, itemIdentifiers)
    {
      if ([self _findItemIdentifier: item inSection: NULL index: NULL])
	{
	  [_reloadedItems addObject: item];
	}
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
      _snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
      _itemProvider = (void*)RETAIN(itemProvider);
      _identifierToIndexPath = [[NSMutableDictionary alloc] init];
      _creatingIndexPaths = [[NSMutableSet alloc] init];
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
  DESTROY(_itemProvider);
  DESTROY(_supplementaryViewProvider);
  DESTROY(_identifierToIndexPath);
  DESTROY(_creatingIndexPaths);
  [super dealloc];
}

- (void) _rebuildIndexLookup
{
  [_identifierToIndexPath removeAllObjects];

  NSArray *sections = [_snapshot sectionIdentifiers];
  NSUInteger sectionIndex = 0;
  FOR_IN(id, section, sections)
    {
      NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
      NSUInteger itemIndex = 0;
      NSUInteger count = [items count];

      for (itemIndex = 0; itemIndex < count; itemIndex++)
	{
	  NSIndexPath *path = [NSIndexPath indexPathForItem: itemIndex inSection: sectionIndex];
	  [_identifierToIndexPath setObject: path forKey: [items objectAtIndex: itemIndex]];
	}
      sectionIndex++;
    }
  END_FOR_IN(sections);
}

- (void) applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences
{
  [self applySnapshot: snapshot
 animatingDifferences: animatingDifferences
     completionHandler: NULL];
}

- (void) applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences
     completionHandler: (GSDiffableDataSourceCompletionBlock)completion
{
  if (snapshot == nil)
    {
      snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
      AUTORELEASE(snapshot);
    }

  ASSIGNCOPY(_snapshot, snapshot);
  [self _rebuildIndexLookup];
  [_collectionView reloadData];

  if (completion != NULL)
    {
      CALL_BLOCK_NO_ARGS(completion);
    }
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
  NSUInteger sectionIndex = 0;
  NSUInteger itemIndex = 0;
  NSArray *sections = nil;

  if (_snapshot == nil || indexPath == nil)
    {
      return nil;
    }

  sections = [_snapshot sectionIdentifiers];
  if (sections == nil)
    {
      return nil;
    }

  if ([indexPath length] >= 2)
    {
      sectionIndex = [indexPath indexAtPosition: 0];
      itemIndex = [indexPath indexAtPosition: 1];
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

  return [items objectAtIndex: itemIndex];
}

- (NSInteger) numberOfSectionsInCollectionView: (NSCollectionView *)collectionView
{
  NSInteger count = 0;

  if (_snapshot == nil)
    {
      return 0;
    }

  count = [_snapshot numberOfSections];

  return count;
}

- (NSInteger) collectionView: (NSCollectionView *)collectionView
      numberOfItemsInSection: (NSInteger)section
{
  (void)collectionView;
  if (_snapshot == nil)
    {
      return 0;
    }

  NSArray *sections = [_snapshot sectionIdentifiers];
  if (sections == nil || section < 0 || section >= (NSInteger)[sections count])
    {
      return 0;
    }

  id sectionIdentifier = [sections objectAtIndex: section];
  if (sectionIdentifier == nil)
    {
      return 0;
    }

  return [[_snapshot itemIdentifiersInSectionWithIdentifier: sectionIdentifier] count];
}

- (NSCollectionViewItem *) collectionView: (NSCollectionView *)collectionView
      itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
  // Recursion guard: if we're already creating an item for this index path, return nil
  if ([_creatingIndexPaths containsObject: indexPath])
    {
      return nil;
    }

  id identifier = [self itemIdentifierForIndexPath: indexPath];
  NSCollectionViewItem *result = [collectionView itemAtIndexPath: indexPath];

  if (result == nil)
    {
      if (identifier == nil || _itemProvider == NULL)
	{
	  return nil;
	}

      if (_itemProvider != NULL)
	{
	  // Mark that we're creating an item for this index path
	  [_creatingIndexPaths addObject: indexPath];

	  result = (NSCollectionViewItem *)
	    CALL_NON_NULL_BLOCK(_itemProvider,
				collectionView,
				indexPath,
				identifier);

	  if ([result respondsToSelector: @selector(setRepresentedObject:)])
	    {
	      [result setRepresentedObject: identifier];
	    }

	  // Always remove from the creating set
	  [_creatingIndexPaths removeObject: indexPath];
	}
    }

  return result;
}

- (NSView *) collectionView: (NSCollectionView *)collectionView
viewForSupplementaryElementOfKind: (NSCollectionViewSupplementaryElementKind)kind
		atIndexPath: (NSIndexPath *)indexPath
{
  if (_supplementaryViewProvider == NULL)
    {
      return nil;
    }

  return (NSView *)CALL_NON_NULL_BLOCK(_supplementaryViewProvider,
				      collectionView,
				      kind,
				      indexPath);
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

- (void) reloadSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  NSArray *sections = [_snapshot sectionIdentifiers];
  FOR_IN(id, section, sectionIdentifiers)
    {
      NSUInteger index = [sections indexOfObject: section];
      if (index != NSNotFound)
	{
	  [indexes addIndex: index];
	}
    }
  END_FOR_IN(sectionIdentifiers);
  [_collectionView reloadSections: indexes];
}

- (void) reloadItemsWithIdentifiers: (NSArray *)itemIdentifiers
{
  NSMutableArray *indexPaths = [NSMutableArray array];
  FOR_IN(id, item, itemIdentifiers)
    {
      NSIndexPath *path = [self indexPathForItemIdentifier: item];
      if (path != nil)
	{
	  [indexPaths addObject: path];
	}
    }
  END_FOR_IN(itemIdentifiers);
  [_collectionView reloadItemsAtIndexPaths: [NSSet setWithArray: indexPaths]];
}

- (GSCollectionViewSupplementaryViewProviderBlock) supplementaryViewProvider
{
  return _supplementaryViewProvider;
}

- (void) setSupplementaryViewProvider: (GSCollectionViewSupplementaryViewProviderBlock)provider
{
  id oldProvider = (id)_supplementaryViewProvider;
  _supplementaryViewProvider = (void *)RETAIN((id)provider);
  RELEASE(oldProvider);
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
      _snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
      _cellProvider = (void*)RETAIN(cellProvider);
      _defaultRowAnimation = NSTableViewAnimationEffectFade;
      _identifierToIndexPath = [[NSMutableDictionary alloc] init];
      _creatingIndexPaths = [[NSMutableSet alloc] init];
      [_tableView setDataSource: self];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_snapshot);
  DESTROY(_cellProvider);
  DESTROY(_rowViewProvider);
  DESTROY(_sectionHeaderViewProvider);
  DESTROY(_identifierToIndexPath);
  DESTROY(_creatingIndexPaths);
  [super dealloc];
}

- (void) _rebuildIndexLookup
{
  [_identifierToIndexPath removeAllObjects];

  NSArray *sections = [_snapshot sectionIdentifiers];
  NSUInteger sectionIndex = 0;
  FOR_IN(id, section, sections)
    {
      NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
      NSUInteger itemIndex = 0;

      for (itemIndex = 0; itemIndex < [items count]; itemIndex++)
	{
	  NSIndexPath *path = [NSIndexPath indexPathForItem: itemIndex inSection: sectionIndex];
	  [_identifierToIndexPath setObject: path forKey: [items objectAtIndex: itemIndex]];
	}
      sectionIndex++;
    }
  END_FOR_IN(sections);
}

- (void) applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences
{
  [self applySnapshot: snapshot
 animatingDifferences: animatingDifferences
     completionHandler: NULL];
}

- (void) applySnapshot: (NSDiffableDataSourceSnapshot *)snapshot
  animatingDifferences: (BOOL)animatingDifferences
     completionHandler: (GSDiffableDataSourceCompletionBlock)completion
{
  NSDiffableDataSourceSnapshot *oldSnapshot = [_snapshot copy];
  NSMutableIndexSet *deletedRows = [NSMutableIndexSet indexSet];
  NSMutableIndexSet *insertedRows = [NSMutableIndexSet indexSet];
  NSMutableIndexSet *reloadedRows = [NSMutableIndexSet indexSet];
  NSArray *oldItems = nil;
  NSArray *newItems = nil;

  if (snapshot == nil)
    {
      snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
      AUTORELEASE(snapshot);
    }

  oldItems = [oldSnapshot itemIdentifiers];
  newItems = [snapshot itemIdentifiers];

  FOR_IN(id, item, oldItems)
    {
      if ([newItems containsObject: item] == NO)
	{
	  NSInteger row = GSDiffableRowForItemInSnapshot(oldSnapshot, item);
	  if (row != NSNotFound)
	    {
	      [deletedRows addIndex: row];
	    }
	}
    }
  END_FOR_IN(oldItems);

  FOR_IN(id, item, newItems)
    {
      NSInteger newRow = GSDiffableRowForItemInSnapshot(snapshot, item);
      NSInteger oldRow = GSDiffableRowForItemInSnapshot(oldSnapshot, item);

      if (oldRow == NSNotFound)
	{
	  [insertedRows addIndex: newRow];
	}
      else if (oldRow != newRow)
	{
	  [reloadedRows addIndex: newRow];
	}
    }
  END_FOR_IN(newItems);

  NSSet *reloadedSections = [snapshot _gsReloadedSections];
  FOR_IN(id, section, reloadedSections)
    {
      NSInteger firstRow = GSDiffableRowForSectionInSnapshot(snapshot, section);
      NSInteger count = [[snapshot itemIdentifiersInSectionWithIdentifier: section] count];

      if (firstRow != NSNotFound && count > 0)
	{
	  [reloadedRows addIndexesInRange: NSMakeRange(firstRow, count)];
	}
    }
  END_FOR_IN(reloadedSections);

  NSSet *reloadedItems = [snapshot _gsReloadedItems];
  FOR_IN(id, item, reloadedItems)
    {
      NSInteger row = GSDiffableRowForItemInSnapshot(snapshot, item);
      if (row != NSNotFound)
	{
	  [reloadedRows addIndex: row];
	}
    }
  END_FOR_IN(reloadedItems);

  ASSIGNCOPY(_snapshot, snapshot);
  [self _rebuildIndexLookup];

  if (animatingDifferences == NO)
    {
      [_tableView reloadData];
    }
  else
    {
      [_tableView beginUpdates];
      if ([deletedRows count] > 0)
	{
	  [_tableView removeRowsAtIndexes: deletedRows
			    withAnimation: _defaultRowAnimation];
	}
      if ([insertedRows count] > 0)
	{
	  [_tableView insertRowsAtIndexes: insertedRows
			    withAnimation: _defaultRowAnimation];
	}
      [_tableView endUpdates];

      if ([reloadedRows count] > 0)
	{
	  NSIndexSet *columns =
	    [NSIndexSet indexSetWithIndexesInRange:
	      NSMakeRange(0, [_tableView numberOfColumns])];
	  [_tableView reloadDataForRowIndexes: reloadedRows
				columnIndexes: columns];
	}
    }

  if (completion != NULL)
    {
      CALL_BLOCK_NO_ARGS(completion);
    }

  RELEASE(oldSnapshot);
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
  NSUInteger sectionIndex = 0;
  NSUInteger itemIndex = 0;

  if ([indexPath length] >= 2)
    {
      sectionIndex = [indexPath indexAtPosition: 0];
      itemIndex = [indexPath indexAtPosition: 1];
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

  if (row < 0)
    {
      return nil;
    }

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

- (NSInteger) rowForItemIdentifier: (id)itemIdentifier
{
  return GSDiffableRowForItemInSnapshot(_snapshot, itemIdentifier);
}

- (id) sectionIdentifierForRow: (NSInteger)row
{
  return GSDiffableSectionForRowInSnapshot(_snapshot, row);
}

- (NSInteger) rowForSectionIdentifier: (id)sectionIdentifier
{
  return GSDiffableRowForSectionInSnapshot(_snapshot, sectionIdentifier);
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
  return [_snapshot numberOfItems];
}

- (void) reloadSectionsWithIdentifiers: (NSArray *)sectionIdentifiers
{
  NSMutableIndexSet *rowsToReload = [NSMutableIndexSet indexSet];
  FOR_IN(id, section, sectionIdentifiers)
    {
      NSUInteger sectionIndex = [[_snapshot sectionIdentifiers] indexOfObject: section];
      if (sectionIndex != NSNotFound)
	{
	  NSInteger runningTotal = 0;
	  NSUInteger i = 0;

	  for (i = 0; i < sectionIndex; i++)
	    {
	      id sec = [[_snapshot sectionIdentifiers] objectAtIndex: i];
	      runningTotal += [[_snapshot itemIdentifiersInSectionWithIdentifier: sec] count];
	    }

	  NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
	  [rowsToReload addIndexesInRange: NSMakeRange(runningTotal, [items count])];
	}
    }
  END_FOR_IN(sectionIdentifiers);
  if ([rowsToReload count] > 0)
    {
      NSIndexSet *columns = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, [_tableView numberOfColumns])];
      [_tableView reloadDataForRowIndexes: rowsToReload columnIndexes: columns];
    }
}

- (void) reloadItemsWithIdentifiers: (NSArray *)itemIdentifiers
{
  NSMutableIndexSet *rowsToReload = [NSMutableIndexSet indexSet];
  FOR_IN(id, item, itemIdentifiers)
    {
      NSInteger runningTotal = 0;
      NSArray *sections = [_snapshot sectionIdentifiers];
      FOR_IN(id, section, sections)
	{
	  NSArray *items = [_snapshot itemIdentifiersInSectionWithIdentifier: section];
	  NSUInteger index = [items indexOfObject: item];
	  if (index != NSNotFound)
	    {
	      NSInteger row = runningTotal + index;
	      [rowsToReload addIndex: row];
	      break;
	    }
	  runningTotal += [items count];
	}
      END_FOR_IN(sections);
    }
  END_FOR_IN(itemIdentifiers);
  if ([rowsToReload count] > 0)
    {
      NSIndexSet *columns = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, [_tableView numberOfColumns])];
      [_tableView reloadDataForRowIndexes: rowsToReload columnIndexes: columns];
    }
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

  if (_cellProvider != NULL)
    {
      NSView *view =
	(NSView *)CALL_NON_NULL_BLOCK(_cellProvider,
				      tableView,
				      tableColumn,
				      rowIndex,
				      identifier);
      if (view != nil)
	{
	  return view;
	}
    }

  // Fallback to a simple text field if no provider is supplied.
  NSTextField *textField = [[NSTextField alloc] init];
  [textField setEditable: NO];
  [textField setBordered: NO];
  [textField setBackgroundColor: [NSColor clearColor]];
  [textField setStringValue: [identifier description]];
  return textField;
}

- (NSTableRowView *) tableView: (NSTableView *)tableView
		  rowViewForRow: (NSInteger)rowIndex
{
  id identifier = [self itemIdentifierForRow: rowIndex];

  if (_rowViewProvider == NULL)
    {
      return nil;
    }

  return (NSTableRowView *)CALL_NON_NULL_BLOCK(_rowViewProvider,
					      tableView,
					      rowIndex,
					      identifier);
}

- (NSView *) tableView: (NSTableView *)tableView
 viewForSectionHeaderInSection: (NSInteger)section
{
  NSArray *sections = [_snapshot sectionIdentifiers];
  id sectionIdentifier = nil;

  if (section < 0 || section >= (NSInteger)[sections count]
      || _sectionHeaderViewProvider == NULL)
    {
      return nil;
    }

  sectionIdentifier = [sections objectAtIndex: section];
  return (NSView *)CALL_NON_NULL_BLOCK(_sectionHeaderViewProvider,
				      tableView,
				      section,
				      sectionIdentifier);
}

- (NSTableViewAnimationOptions) defaultRowAnimation
{
  return _defaultRowAnimation;
}

- (void) setDefaultRowAnimation: (NSTableViewAnimationOptions)animation
{
  _defaultRowAnimation = animation;
}

- (GSTableViewRowViewProviderBlock) rowViewProvider
{
  return _rowViewProvider;
}

- (void) setRowViewProvider: (GSTableViewRowViewProviderBlock)provider
{
  id oldProvider = (id)_rowViewProvider;
  _rowViewProvider = (void *)RETAIN((id)provider);
  RELEASE(oldProvider);
}

- (GSTableViewSectionHeaderViewProviderBlock) sectionHeaderViewProvider
{
  return _sectionHeaderViewProvider;
}

- (void) setSectionHeaderViewProvider: (GSTableViewSectionHeaderViewProviderBlock)provider
{
  id oldProvider = (id)_sectionHeaderViewProvider;
  _sectionHeaderViewProvider = (void *)RETAIN((id)provider);
  RELEASE(oldProvider);
}

@end
