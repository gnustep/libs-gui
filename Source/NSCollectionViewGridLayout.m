/* Implementation of class NSCollectionViewGridLayout
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

#import "AppKit/NSCollectionViewGridLayout.h"

#import "GSGuiPrivate.h"

@implementation NSCollectionViewGridLayout

- (void) _initDefaults
{
  _maximumNumberOfRows = 0;
  _maximumNumberOfColumns = 0;
  _minimumItemSize = NSMakeSize(50.0, 50.0);
  _maximumItemSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
  _margins = NSEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
  _minimumInteritemSpacing = 0.0;
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      [self _initDefaults];
    }
  return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
    {
      // Initialize defaults
      [self _initDefaults];

      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSMaximumNumberOfRows"])
            {
              _maximumNumberOfRows = [coder decodeIntegerForKey: @"NSMaximumNumberOfRows"];
            }

          if ([coder containsValueForKey: @"NSMaximumNumberOfColumns"])
            {
              _maximumNumberOfColumns = [coder decodeIntegerForKey: @"NSMaximumNumberOfColumns"];
            }

          if ([coder containsValueForKey: @"NSMaximumItemSize"])
            {
              _maximumItemSize = [coder decodeSizeForKey: @"NSMaximumItemSize"];
            }
          
          if ([coder containsValueForKey: @"NSMinimumItemSize"])
            {
              _minimumItemSize = [coder decodeSizeForKey: @"NSMinimumItemSize"];
            }
          
          if ([coder containsValueForKey: @"NSMinimumInteritemSpacing"])
            {
              _minimumInteritemSpacing = [coder decodeFloatForKey: @"NSMinimumInteritemSpacing"];
            }
          
          // margins...
          if ([coder containsValueForKey: @"NSCollectionViewGridLayoutMargins.bottom"])
            {
              _margins.bottom = [coder decodeFloatForKey: @"NSCollectionViewGridLayoutMargins.bottom"];
            }

          if ([coder containsValueForKey: @"NSCollectionViewGridLayoutMargins.top"])
            {
              _margins.top = [coder decodeFloatForKey: @"NSCollectionViewGridLayoutMargins.top"];
            }

          if ([coder containsValueForKey: @"NSCollectionViewGridLayoutMargins.left"])
            {
              _margins.left = [coder decodeFloatForKey: @"NSCollectionViewGridLayoutMargins.left"];
            }

          if ([coder containsValueForKey: @"NSCollectionViewGridLayoutMargins.right"])
            {
              _margins.right = [coder decodeFloatForKey: @"NSCollectionViewGridLayoutMargins.right"];
            }
        }
      else
        {
          decode_NSUInteger(coder, &_maximumNumberOfRows); 
          decode_NSUInteger(coder, &_maximumNumberOfColumns);
          
          _maximumItemSize = [coder decodeSize];
          _minimumItemSize = [coder decodeSize];
          
          [coder decodeValueOfObjCType: @encode(CGFloat) at: &_minimumInteritemSpacing];
          [coder decodeValueOfObjCType: @encode(CGFloat) at: &_margins.bottom];
          [coder decodeValueOfObjCType: @encode(CGFloat) at: &_margins.top];
          [coder decodeValueOfObjCType: @encode(CGFloat) at: &_margins.left];
          [coder decodeValueOfObjCType: @encode(CGFloat) at: &_margins.right];        
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeInteger: _maximumNumberOfRows
                    forKey: @"NSMaximumNumberOfRows"];
      [coder encodeInteger: _maximumNumberOfColumns
                    forKey: @"NSMaximumNumberOfColumns"];

      [coder encodeSize: _maximumItemSize
                 forKey: @"NSMaximumItemSize"];
      [coder encodeSize: _minimumItemSize
                 forKey: @"NSMinimumItemSize"];

      [coder encodeFloat: _minimumInteritemSpacing
                  forKey: @"NSMinimumInteritemSpacing"];
      
      [coder encodeFloat: _margins.bottom
                  forKey: @"NSCollectionViewGridLayoutMargins.bottom"];
      [coder encodeFloat: _margins.top
                  forKey: @"NSCollectionViewGridLayoutMargins.top"];
      [coder encodeFloat: _margins.left
                  forKey: @"NSCollectionViewGridLayoutMargins.left"];
      [coder encodeFloat: _margins.right
                  forKey: @"NSCollectionViewGridLayoutMargins.right"];
    }
  else
    {
      encode_NSUInteger(coder, &_maximumNumberOfRows);
      encode_NSUInteger(coder, &_maximumNumberOfColumns);

      [coder encodeSize: _maximumItemSize];
      [coder encodeSize: _minimumItemSize];

      [coder encodeValueOfObjCType: @encode(CGFloat) at: &_minimumInteritemSpacing];
      [coder encodeValueOfObjCType: @encode(CGFloat) at: &_margins.bottom];
      [coder encodeValueOfObjCType: @encode(CGFloat) at: &_margins.top];
      [coder encodeValueOfObjCType: @encode(CGFloat) at: &_margins.left];
      [coder encodeValueOfObjCType: @encode(CGFloat) at: &_margins.right];
    }
}

- (void) setMaximumNumberOfRows: (NSUInteger)maxRows
{
  _maximumNumberOfRows = maxRows;
}

- (NSUInteger) maximumNumberOfRows
{
  return _maximumNumberOfRows;
}

- (void) setMaximumNumberOfColumns: (NSUInteger)maxCols
{
  _maximumNumberOfColumns = maxCols;
}

- (NSUInteger) maximumNumberOfColumns
{
  return _maximumNumberOfColumns;
}

- (void) setMinimumItemSize: (NSSize)minSize
{
  _minimumItemSize = minSize;
}

- (NSSize) minimumItemSize
{
  return _minimumItemSize;
}

- (void) setMaximumItemSize: (NSSize)maxSize
{
  _maximumItemSize = maxSize;
}

- (NSSize) maximumItemSize
{
  return _maximumItemSize;
}

- (void) setMargins: (NSEdgeInsets)insets
{
  _margins = insets;
}

- (NSEdgeInsets) margins
{
  return _margins;
}

- (void) setMinimumInteritemSpacing: (CGFloat)spacing
{
  _minimumInteritemSpacing = spacing;
}
  
- (CGFloat) minimumInteritemSpacing
{
  return _minimumInteritemSpacing;
}

// Methods to override for specific layouts...
- (NSCollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath
{
  NSCollectionViewLayoutAttributes *attrs = AUTORELEASE([[NSCollectionViewLayoutAttributes alloc] init]);
  NSSize sz = NSZeroSize;
  NSInteger s = [indexPath section];
  NSInteger r = [indexPath item];
  NSEdgeInsets si;
  CGFloat mls = 0.0;
  CGFloat mis = 0.0;
  CGFloat h = 0.0, w = 0.0, x = 0.0, y = 0.0;
  NSRect f = NSZeroRect;
  NSRect vf = [_collectionView frame];
  NSInteger ni = [_collectionView numberOfItemsInSection: s];
  NSUInteger columns = 0;
  NSUInteger row = 0;
  NSUInteger col = 0;
  
  sz = [self minimumItemSize];
  si = [self margins];
  mls = [self minimumInteritemSpacing];
  mis = [self minimumInteritemSpacing];

  // Determine number of columns
  if (_maximumNumberOfColumns > 0)
    {
      columns = _maximumNumberOfColumns;
    }
  else
    {
      // Calculate based on available width
      CGFloat availableWidth = vf.size.width - si.left - si.right;
      if (sz.width + mis > 0)
        {
          columns = floor((availableWidth + mis) / (sz.width + mis));
          if (columns == 0) columns = 1;
        }
      else
        {
          columns = 1;
        }
    }

  // Ensure we don't exceed max rows if set
  if (_maximumNumberOfRows > 0)
    {
      NSUInteger maxItems = columns * _maximumNumberOfRows;
      if (r >= maxItems)
        {
          // Item doesn't fit, hide it
          [attrs setFrame: NSZeroRect];
          [attrs setZIndex: 0];
          [attrs setSize: NSZeroSize];
          [attrs setHidden: YES];
          [attrs setAlpha: 1.0];
          return attrs;
        }
    }

  // Calculate item size
  h = sz.height;
  w = sz.width;

  // Adjust size if needed to fit
  if (_maximumNumberOfColumns == 0)
    {
      // If columns were calculated, adjust width to fit
      CGFloat availableWidth = vf.size.width - si.left - si.right;
      CGFloat totalSpacing = (columns - 1) * mis;
      w = (availableWidth - totalSpacing) / columns;
      if (w > [self maximumItemSize].width)
        {
          w = [self maximumItemSize].width;
        }
    }

  // Calculate row and column
  row = r / columns;
  col = r % columns;

  // Calculate position
  x = col * (w + mis) + si.left;
  y = row * (h + mls) + si.top;

  f = NSMakeRect(x, y, w, h);

  // Build attrs object...
  [attrs setFrame: f];
  [attrs setZIndex: 0];
  [attrs setSize: f.size];
  [attrs setHidden: NO];
  [attrs setAlpha: 1.0];

  return attrs;
}

- (NSSize) collectionViewContentSize
{
  NSRect vf = [_collectionView frame];
  NSEdgeInsets si = [self margins];
  CGFloat mis = [self minimumInteritemSpacing];
  CGFloat mls = [self minimumInteritemSpacing];
  NSSize sz = [self minimumItemSize];
  CGFloat w = sz.width;
  CGFloat h = sz.height;
  NSUInteger totalSections = [_collectionView numberOfSections];
  NSUInteger maxRows = 0;
  NSUInteger maxCols = 0;

  // Find the maximum number of items in any section
  for (NSUInteger s = 0; s < totalSections; s++)
    {
      NSUInteger ni = [_collectionView numberOfItemsInSection: s];
      NSUInteger columns = 0;

      if (_maximumNumberOfColumns > 0)
        {
          columns = _maximumNumberOfColumns;
        }
      else
        {
          CGFloat availableWidth = vf.size.width - si.left - si.right;
          if (sz.width + mis > 0)
            {
              columns = floor((availableWidth + mis) / (sz.width + mis));
              if (columns == 0) columns = 1;
            }
          else
            {
              columns = 1;
            }
        }

      NSUInteger rows = (ni + columns - 1) / columns; // Ceiling division
      if (rows > maxRows) maxRows = rows;
      if (columns > maxCols) maxCols = columns;
    }

  // Calculate content size
  CGFloat contentWidth = maxCols * (w + mis) - mis + si.left + si.right;
  CGFloat contentHeight = maxRows * (h + mls) - mls + si.top + si.bottom;

  // Ensure minimum size
  if (contentWidth < vf.size.width) contentWidth = vf.size.width;
  if (contentHeight < vf.size.height) contentHeight = vf.size.height;

  return NSMakeSize(contentWidth, contentHeight);
}

@end
