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

#import "AppKit/NSCollectionViewFlowLayout.h"
#import "AppKit/NSCollectionViewItem.h"

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

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
    {
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
          _itemSize = [coder decodeSize];
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
  return NO;
}

- (void) collapseSectionAtIndex: (NSUInteger)sectionIndex
{
}

- (void) expandSectionAtIndex: (NSUInteger)sectionIndex
{
}

// Methods to override for specific layouts...
- (void) prepareLayout
{
  [super prepareLayout];
}

- (NSArray *) layoutAttributesForElementsInRect: (NSRect)rect
{
  return nil;
}

- (NSCollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath
{
  NSCollectionViewLayoutAttributes *attrs = [[NSCollectionViewLayoutAttributes alloc] init];
  NSSize sz = [self itemSize];
  NSInteger s = [indexPath section];
  NSInteger r = [indexPath item];
  CGFloat h = sz.height;
  CGFloat w = sz.width;
  NSRect f = NSMakeRect(r * w, s * h, h, w);
  
  // NSLog(@"Flow layout for index path = %@", indexPath);

  [attrs setFrame: f];
  [attrs setHidden: NO];
  [attrs setZIndex: 0];
  [attrs setSize: sz];

  // NSLog(@"f = %@", NSStringFromRect(f));
  // NSLog(@"s = %@", NSStringFromSize(sz));
  // NSLog(@"self = %@", self);
  
  AUTORELEASE(attrs);
  
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
  return [_collectionView frame].size;
}
// end subclassing hooks...

@end

