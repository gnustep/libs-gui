/* Implementation of class NSCollectionViewFlowLayout
   Copyright (C) 2021 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 30-05-2021

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSIndexPath.h>

#import "AppKit/NSCollectionView.h"
#import "AppKit/NSCollectionViewFlowLayout.h"
#import "AppKit/NSCollectionViewItem.h"

#import "GSGuiPrivate.h"

@implementation NSCollectionViewFlowLayoutInvalidationContext

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _invalidateFlowLayoutAttributes = YES;
      _invalidateFlowLayoutDelegateMetrics = YES;
    }
  return self;
}

- (void) setInvalidateFlowLayoutDelegateMetrics: (BOOL)flag
{
  _invalidateFlowLayoutDelegateMetrics = flag;
}

- (BOOL) invalidateFlowLayoutDelegateMetrics
{
  return _invalidateFlowLayoutDelegateMetrics;
}

- (void) setInvalidateFlowLayoutAttributes: (BOOL)flag
{
  _invalidateFlowLayoutAttributes = flag;
}

- (BOOL) invalidateFlowLayoutAttributes
{
  return _invalidateFlowLayoutAttributes;
}

@end

@implementation NSCollectionViewFlowLayout

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _collapsedSections = [[NSMutableIndexSet alloc] init];
      _minimumLineSpacing = 10.0;
      _minimumInteritemSpacing = 10.0;
      _itemSize = NSMakeSize(50, 50);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_itemFrames);
  RELEASE(_collapsedSections);
  [super dealloc];
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
    {
      _collapsedSections = [[NSMutableIndexSet alloc] init];
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSMinimumLineSpacing"])
            {
              _minimumLineSpacing = [coder decodeFloatForKey: @"NSMinimumLineSpacing"];
            }
          if ([coder containsValueForKey: @"NSMinimumInteritemSpacing"])
            {
              _minimumInteritemSpacing = [coder decodeFloatForKey: @"NSMinimumInteritemSpacing"];
            }
          if ([coder containsValueForKey: @"NSItemSize"])
            {
              _itemSize = [coder decodeSizeForKey: @"NSItemSize"];
            }
          if ([coder containsValueForKey: @"NSEstimatedItemSize"])
            {
              _estimatedItemSize = [coder decodeSizeForKey: @"NSEstimatedItemSize"];
            }
          if ([coder containsValueForKey: @"NSScrollDirection"])
            {
              _scrollDirection = [coder decodeIntForKey: @"NSScrollDirection"];
            }
          if ([coder containsValueForKey: @"NSHeaderReferenceSize"])
            {
              _headerReferenceSize = [coder decodeSizeForKey: @"NSHeaderReferneceSize"];
            }
          if ([coder containsValueForKey: @"NSFooterReferenceSize"])
            {
              _footerReferenceSize = [coder decodeSizeForKey: @"NSFooterReferenceSize"];
            }

          // decode inset...
          if ([coder containsValueForKey: @"NSSectionInset.bottom"])
            {
              _sectionInset.bottom = [coder decodeFloatForKey: @"NSSectionInset.bottom"];
            }
          if ([coder containsValueForKey: @"NSSectionInset.top"])
            {
              _sectionInset.top = [coder decodeFloatForKey: @"NSSectionInset.top"];
            }
          if ([coder containsValueForKey: @"NSSectionInset.left"])
            {
              _sectionInset.left = [coder decodeFloatForKey: @"NSSectionInset.left"];
            }
          if ([coder containsValueForKey: @"NSSectionInset.right"])
            {
              _sectionInset.right = [coder decodeFloatForKey: @"NSSectionInset.right"];
            }
          
          if ([coder containsValueForKey: @"NSSectionHeadersPinToVisibleBounds"])
            {
              _sectionHeadersPinToVisibleBounds = [coder decodeBoolForKey: @"NSSectionHeadersPinToVisibleBounds"];
            }
          if ([coder containsValueForKey: @"NSSectionFootersPinToVisibleBounds"])
            {
              _sectionFootersPinToVisibleBounds = [coder decodeBoolForKey: @"NSSectionFootersPinToVisibleBounds"];
            }
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_minimumInteritemSpacing];
          _itemSize = [coder decodeSize];
          _estimatedItemSize = [coder decodeSize];
          decode_NSInteger(coder, &_scrollDirection);
          _headerReferenceSize = [coder decodeSize];
          _footerReferenceSize = [coder decodeSize];
          
          // decode inset...
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_sectionInset.bottom];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_sectionInset.top];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_sectionInset.left];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_sectionInset.right];
          
          
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_sectionHeadersPinToVisibleBounds];
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_sectionFootersPinToVisibleBounds];
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeFloat: _minimumLineSpacing
                  forKey: @"NSMinimumLineSpacing"];
      [coder encodeFloat: _minimumInteritemSpacing
                  forKey: @"NSMinimumInteritemSpacing"];
      [coder encodeSize: _itemSize
                 forKey: @"NSItemSize"];
      [coder encodeSize: _estimatedItemSize
                 forKey: @"NSEstimatedItemSize"];
      [coder encodeInt: _scrollDirection
                forKey: @"NSScrollDirection"];
      [coder encodeSize: _headerReferenceSize
                 forKey: @"NSHeaderReferneceSize"];
      [coder encodeSize: _footerReferenceSize
                 forKey: @"NSFooterReferenceSize"];
      
      // decode inset...
      [coder encodeFloat: _sectionInset.bottom
                  forKey: @"NSSectionInset.bottom"];
      [coder encodeFloat: _sectionInset.top
                  forKey: @"NSSectionInset.top"];
      [coder encodeFloat: _sectionInset.left
                  forKey: @"NSSectionInset.left"];
      [coder encodeFloat: _sectionInset.right
                  forKey: @"NSSectionInset.right"];

      [coder encodeBool: _sectionHeadersPinToVisibleBounds
                 forKey: @"NSSectionHeadersPinToVisibleBounds"];
      [coder encodeBool: _sectionFootersPinToVisibleBounds
                 forKey: @"NSSectionFootersPinToVisibleBounds"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_minimumInteritemSpacing];
      [coder encodeSize: _itemSize];
      [coder encodeSize: _estimatedItemSize];
      encode_NSInteger(coder, &_scrollDirection);
      [coder encodeSize: _headerReferenceSize];
      [coder encodeSize: _footerReferenceSize];
      
      // decode inset...
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_sectionInset.bottom];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_sectionInset.top];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_sectionInset.left];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_sectionInset.right];


      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_sectionHeadersPinToVisibleBounds];
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_sectionFootersPinToVisibleBounds];
    }
}

- (CGFloat) minimumLineSpacing
{
  return _minimumLineSpacing;
}

- (void) setMinimumLineSpacing: (CGFloat)spacing
{
  _minimumLineSpacing = spacing;
}

- (CGFloat) minimumInteritemSpacing
{
  return _minimumInteritemSpacing;
}

- (void) setMinimumInteritemSpacing: (CGFloat)spacing
{
  _minimumInteritemSpacing = spacing;
}
  
- (NSSize) itemSize
{  
  return _itemSize;
}

- (void) setItemSize: (NSSize)itemSize
{
  _itemSize = itemSize;
}
  
- (NSSize) estimatedItemSize
{
  return _estimatedItemSize;
}

- (void) setEstimatedItemSize: (NSSize)size
{
  _estimatedItemSize = size;
}
  
- (NSCollectionViewScrollDirection) scrollDirection
{
  return _scrollDirection;
}

- (void) setScrollDirection: (NSCollectionViewScrollDirection)direction
{
  _scrollDirection = direction;
}
  
- (NSSize) headerReferenceSize
{
  return _headerReferenceSize;
}

- (void) setHeaderReferenceSize: (NSSize)size
{
  _headerReferenceSize = size;
}
  
- (NSSize) footerReferenceSize
{
  return _footerReferenceSize;
}

- (void) setFooterReferenceSize: (NSSize)size
{
  _footerReferenceSize = size;
}
  
- (NSEdgeInsets) sectionInset
{
  return _sectionInset;
}

- (void) setSectionInset: (NSEdgeInsets)inset
{
  _sectionInset = inset;
}

- (BOOL) sectionHeadersPinToVisibleBounds
{
  return _sectionHeadersPinToVisibleBounds;
}

- (void) setSectionHeadersPinToVisibleBounds: (BOOL)f
{
  _sectionHeadersPinToVisibleBounds = f;
}

- (BOOL) sectionFootersPinToVisibleBounds
{
  return _sectionFootersPinToVisibleBounds;
}

- (void) setSectionFootersPinToVisibleBounds: (BOOL)f
{
  _sectionFootersPinToVisibleBounds = f;
}

- (BOOL) sectionAtIndexIsCollapsed: (NSUInteger)sectionIndex
{
  return [_collapsedSections containsIndex: sectionIndex];
}

- (void) collapseSectionAtIndex: (NSUInteger)sectionIndex
{
  [_collapsedSections addIndex: sectionIndex];
}

- (void) expandSectionAtIndex: (NSUInteger)sectionIndex
{
  [_collapsedSections removeIndex: sectionIndex];
}

// Methods to override for specific layouts...
- (NSSize) _sizeForItemAtIndexPath: (NSIndexPath *)indexPath
{
  id <NSCollectionViewDelegateFlowLayout> delegate = (id <NSCollectionViewDelegateFlowLayout>)[_collectionView delegate];

  if ([delegate respondsToSelector: @selector(collectionView:layout:sizeForItemAtIndexPath:)])
    {
      return [delegate collectionView: _collectionView
			       layout: self
	       sizeForItemAtIndexPath: indexPath];
    }
  return [self itemSize];
}

- (NSEdgeInsets) _insetForSection: (NSInteger)section
{
  id <NSCollectionViewDelegateFlowLayout> delegate = (id <NSCollectionViewDelegateFlowLayout>)[_collectionView delegate];

  if ([delegate respondsToSelector: @selector(collectionView:layout:insetForSectionAtIndex:)])
    {
      return [delegate collectionView: _collectionView
			       layout: self
	       insetForSectionAtIndex: section];
    }
  return [self sectionInset];
}

- (CGFloat) _lineSpacingForSection: (NSInteger)section
{
  id <NSCollectionViewDelegateFlowLayout> delegate = (id <NSCollectionViewDelegateFlowLayout>)[_collectionView delegate];

  if ([delegate respondsToSelector: @selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)])
    {
      return [delegate collectionView: _collectionView
			       layout: self
		    minimumLineSpacingForSectionAtIndex: section];
    }
  return [self minimumLineSpacing];
}

- (CGFloat) _interitemSpacingForSection: (NSInteger)section
{
  id <NSCollectionViewDelegateFlowLayout> delegate = (id <NSCollectionViewDelegateFlowLayout>)[_collectionView delegate];

  if ([delegate respondsToSelector: @selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)])
    {
      return [delegate collectionView: _collectionView
			       layout: self
	       minimumInteritemSpacingForSectionAtIndex: section];
    }
  return [self minimumInteritemSpacing];
}

- (void) prepareLayout
{
  BOOL across = (_scrollDirection == NSCollectionViewScrollDirectionHorizontal);
  NSScrollView *sv = [_collectionView enclosingScrollView];
  NSSize visible = sv != nil ? [sv contentSize] : [_collectionView frame].size;
  CGFloat room = across ? visible.height : visible.width;
  NSInteger sections = [_collectionView numberOfSections];
  NSInteger section;
  CGFloat along = 0.0; // where the next section begins, in the scrolling direction

  [super prepareLayout];
  DESTROY(_itemFrames);
  _itemFrames = [[NSMutableArray alloc] initWithCapacity: sections];

  for (section = 0; section < sections; section++)
    {
      NSInteger items = [_collectionView numberOfItemsInSection: section];
      NSMutableArray *frames = [NSMutableArray arrayWithCapacity: items];
      NSEdgeInsets in = [self _insetForSection: section];
      CGFloat mls = [self _lineSpacingForSection: section];
      CGFloat mis = [self _interitemSpacingForSection: section];
      CGFloat start = across ? in.top : in.left;
      CGFloat end = room - (across ? in.bottom : in.right);
      CGFloat line = along + (across ? in.left : in.top); // the line's top (left, across)
      CGFloat thickness = 0.0; // the line's height (width, across)
      CGFloat at = start;
      NSInteger item;

      for (item = 0; item < items; item++)
	{
	  NSSize sz = [self _sizeForItemAtIndexPath:
	    [NSIndexPath indexPathForItem: item inSection: section]];
	  CGFloat length = across ? sz.height : sz.width;
	  CGFloat depth = across ? sz.width : sz.height;

	  if (at > start && at + length > end)
	    {
	      line += thickness + mls;
	      thickness = 0.0;
	      at = start;
	    }
	  [frames addObject: [NSValue valueWithRect: across
	    ? NSMakeRect(line, at, sz.width, sz.height)
	    : NSMakeRect(at, line, sz.width, sz.height)]];
	  at += length + mis;
	  thickness = MAX(thickness, depth);
	}
      [_itemFrames addObject: frames];
      along = line + thickness + (across ? in.right : in.bottom);
    }

  _contentSize = across ? NSMakeSize(along, visible.height)
    : NSMakeSize(visible.width, along);
}

- (NSCollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath
{
  NSCollectionViewLayoutAttributes *attrs;
  NSInteger section = [indexPath section];
  NSInteger item = [indexPath item];
  NSRect f;

  if (_itemFrames == nil)
    {
      [self prepareLayout];
    }
  if (section >= (NSInteger)[_itemFrames count]
      || item >= (NSInteger)[[_itemFrames objectAtIndex: section] count])
    {
      return nil;
    }
  f = [[[_itemFrames objectAtIndex: section] objectAtIndex: item] rectValue];

  attrs = [NSCollectionViewLayoutAttributes layoutAttributesForItemWithIndexPath: indexPath];
  [attrs setFrame: f];
  [attrs setZIndex: 0];
  [attrs setSize: f.size];
  [attrs setHidden: NO];
  [attrs setAlpha: 1.0];

  return attrs;
}

- (NSCollectionViewLayoutAttributes *)
  layoutAttributesForSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
                                 atIndexPath: (NSIndexPath *)indexPath
{
  return nil;
}

- (NSCollectionViewLayoutAttributes *)
  layoutAttributesForDecorationViewOfKind: (NSCollectionViewDecorationElementKind)elementKind
                              atIndexPath: (NSIndexPath *)indexPath
{
  return nil;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForDropTargetAtPoint: (NSPoint)pointInCollectionView
{
  return nil;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForInterItemGapBeforeIndexPath: (NSIndexPath *)indexPath
{
  return nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange: (NSRect)newBounds
{
  return NO;
}

- (NSCollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange: (NSRect)newBounds
{
  return nil;
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes: (NSCollectionViewLayoutAttributes *)preferredAttributes
                                    withOriginalAttributes: (NSCollectionViewLayoutAttributes *)originalAttributes
{
  return NO;
}

- (NSCollectionViewLayoutInvalidationContext *)
  invalidationContextForPreferredLayoutAttributes: (NSCollectionViewLayoutAttributes *)preferredAttributes
                           withOriginalAttributes: (NSCollectionViewLayoutAttributes *)originalAttributes
{
  return nil;
}

- (NSPoint) targetContentOffsetForProposedContentOffset: (NSPoint)proposedContentOffset
                                  withScrollingVelocity: (NSPoint)velocity
{
  return NSZeroPoint;
}

- (NSPoint) targetContentOffsetForProposedContentOffset: (NSPoint)proposedContentOffset
{
  return NSZeroPoint;  
}

- (NSSize) collectionViewContentSize
{
  if (_itemFrames == nil)
    {
      [self prepareLayout];
    }
  return _contentSize;
}
// end subclassing hooks...

@end

