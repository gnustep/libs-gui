/** <title>NSCollectionView</title>
 
   Copyright (C) 2013 Free Software Foundation, Inc.
 
   Author: Doug Simons (doug.simons@testplant.com)
           Frank LeGrand (frank.legrand@testplant.com)
   Date: February 2013
 
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#import "AppKit/NSCollectionView.h"
#import "AppKit/NSCollectionViewItem.h"
#import "Foundation/NSKeyedArchiver.h"
#import <Foundation/NSGeometry.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFormatter.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSKeyedArchiver.h>

#import "AppKit/NSView.h"
#import "AppKit/NSNibLoading.h"
#import "AppKit/NSTableView.h"
#import "AppKit/NSApplication.h"
#import "AppKit/NSCell.h"
#import "AppKit/NSClipView.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSEvent.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSKeyValueBinding.h"
#import "AppKit/NSScroller.h"
#import "AppKit/NSScrollView.h"
#import "AppKit/NSTableColumn.h"
#import "AppKit/NSTableHeaderView.h"
#import "AppKit/NSText.h"
#import "AppKit/NSTextFieldCell.h"
#import "AppKit/NSWindow.h"
#import "AppKit/PSOperators.h"
#import "AppKit/NSCachedImageRep.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSDragging.h"
#import "AppKit/NSCustomImageRep.h"
#import "AppKit/NSAttributedString.h"
#import "AppKit/NSStringDrawing.h"
#import "GNUstepGUI/GSTheme.h"
#import "GSBindingHelpers.h"

#include <math.h>




static NSString* NSCollectionViewMinItemSizeKey              = @"NSCollectionViewMinItemSizeKey";
static NSString* NSCollectionViewMaxItemSizeKey              = @"NSCollectionViewMaxItemSizeKey";
static NSString* NSCollectionViewVerticalMarginKey           = @"NSCollectionViewVerticalMarginKey";
static NSString* NSCollectionViewMaxNumberOfRowsKey          = @"NSCollectionViewMaxNumberOfRowsKey";
static NSString* NSCollectionViewMaxNumberOfColumnsKey       = @"NSCollectionViewMaxNumberOfColumnsKey";
static NSString* NSCollectionViewSelectableKey               = @"NSCollectionViewSelectableKey";
static NSString* NSCollectionViewAllowsMultipleSelectionKey  = @"NSCollectionViewAllowsMultipleSelectionKey";
static NSString* NSCollectionViewBackgroundColorsKey         = @"NSCollectionViewBackgroundColorsKey";


/*
 * Class variables
 */
static NSString *placeholderItem = nil;

@implementation NSCollectionView

//
// Class methods
//
+ (void) initialize
{
  placeholderItem = @"Placeholder";
}

- (void)awakeFromNib
{
  // FIXME: This is just preliminary stuff
  _minItemSize = NSMakeSize(120.0, 100.0);
  _maxItemSize = NSMakeSize(120.0, 100.0);
  _content = [[NSArray alloc] init];
  _items = [[NSMutableArray alloc] init];
}

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill([self bounds]);
}

- (void)dealloc
{
  [_content release];
  [itemPrototype release];
  [_backgroundColors release];
  [_selectionIndexes release];
  [super dealloc];
}

- (BOOL)isFlipped
{
  return YES;
}

- (BOOL)allowsMultipleSelection
{
  return _allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)flag
{
  _allowsMultipleSelection = flag;
}

- (NSArray *)backgroundColors
{
  return _backgroundColors;
}

- (void)setBackgroundColors:(NSArray *)colors
{
  _backgroundColors = [colors copy];
}

- (NSArray *)content
{
  return _content;
}

- (void)setContent:(NSArray *)content
{
  [_content release];
  _content = [content retain];
  
  [_items release];
  _items = [[NSMutableArray alloc] initWithCapacity:[_content count]];
  
  int i;
  for (i=0; i<[_content count]; i++)
    {
      [_items addObject:placeholderItem];
    }
  [self reloadContent];
}

- (id < NSCollectionViewDelegate >)delegate
{
  return delegate;
}

- (void)setDelegate:(id < NSCollectionViewDelegate >)aDelegate
{
  delegate = aDelegate;
}

- (NSCollectionViewItem *)itemPrototype
{
  return itemPrototype;
}

- (void)setItemPrototype:(NSCollectionViewItem *)prototype
{
  [itemPrototype release];
  itemPrototype = [prototype retain];
  
  //TODO: Re-enabled this
//  if (itemPrototype)
//    _itemSize = [[itemPrototype view] frame].size;
//  else
//    {
//      // TODO: Figure out what to do if prototype==nil
//      _itemSize = NSMakeSize (1,1);
//    }
}

- (BOOL)isFirstResponder
{
  // FIXME
  return NO;
}

- (float)verticalMargin
{
  return _verticalMargin;
}

- (void)setVerticalMargin:(float)margin
{
  if (_verticalMargin == margin)
    return;
    
  _verticalMargin = margin;
  [self tile];
}

- (NSSize)maxItemSize
{
  return _maxItemSize;
}

- (void)setMaxItemSize:(NSSize)size
{
  if (NSEqualSizes(_maxItemSize, size))
    return;
    
  _maxItemSize = size;
  [self tile];
}

- (NSUInteger)maxNumberOfColumns
{
  return _maxNumberOfColumns;
}

- (void)setMaxNumberOfColumns:(NSUInteger)number
{
  _maxNumberOfColumns = number;
}

- (NSUInteger)maxNumberOfRows
{
  return _maxNumberOfRows;
}

- (void)setMaxNumberOfRows:(NSUInteger)number
{
  _maxNumberOfRows = number;
}

- (NSSize)minItemSize
{
  return _minItemSize;
}

- (void)setMinItemSize:(NSSize)size
{
  if (NSEqualSizes(_minItemSize, size))
    return;
    
  _minItemSize = size;
  [self tile];
}

- (BOOL)isSelectable
{
  return _isSelectable;
}

- (void)setSelectable:(BOOL)flag
{
  _isSelectable = flag;
}

- (NSIndexSet *)selectionIndexes
{
  return _selectionIndexes;
}

- (void)setSelectionIndexes:(NSIndexSet *)indexes
{
  [_selectionIndexes release];
  _selectionIndexes = [indexes copy];
}

- (NSRect)frameForItemAtIndex:(NSUInteger)index
{
  return [[[self itemAtIndex:index] view] frame];
}

- (NSCollectionViewItem *)itemAtIndex:(NSUInteger)index
{
  id item = [_items objectAtIndex:index];
  if (item == placeholderItem)
    {
      item = [self newItemForRepresentedObject:[_content objectAtIndex:index]];
      [_items replaceObjectAtIndex:index withObject:item];
    }
  return item;
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object
{
  NSCollectionViewItem *collectionItem = nil;
  if (itemPrototype)
    {
      NSData *itemAsData = [NSKeyedArchiver archivedDataWithRootObject:itemPrototype];
      collectionItem = [NSKeyedUnarchiver unarchiveObjectWithData:itemAsData];
      [collectionItem setRepresentedObject:object];
    }
  return collectionItem;
}

- (void)setDraggingSourceOperationMask:(NSDragOperation)dragOperationMask forLocal:(BOOL)localDestination
{
  return;
}

- (NSImage *)draggingImageForItemsAtIndexes:(NSIndexSet *)indexes
                                  withEvent:(NSEvent *)event
                                     offset:(NSPointPointer)dragImageOffset
{
  return nil;
}

- (void)reloadContent
{
  // First of all clean off the current item views:
  long count = [_items count];
    
  while (count--)
    {
       if (![[_items objectAtIndex:count] isKindOfClass:[NSString class]])
         {
           [[[_items objectAtIndex:count] view] removeFromSuperview];
           [[_items objectAtIndex:count] setSelected:NO];
         }
    }
    
  if (!itemPrototype)
    return;
    
  long index = 0;
    
  count = [_content count];
    
  for (; index < count; ++index)
    {
      [_items replaceObjectAtIndex:index
                        withObject:[self newItemForRepresentedObject:[_content objectAtIndex:index]]];
        
      [self addSubview:[[_items objectAtIndex:index] view]];
    }

  // TODO: Restore item's selected state    

  [self tile];
}

- (void)tile
{
  if (!_items)
    return;
    
  float width = [self bounds].size.width;
    
  if (width == _tileWidth)
    return;
    
  NSSize itemSize = NSMakeSize(_minItemSize.width, _minItemSize.height);
    
  long _numberOfColumns = MAX(1.0, floor(width / itemSize.width));
    
  if (_maxNumberOfColumns > 0)
    _numberOfColumns = MIN(_maxNumberOfColumns, _numberOfColumns);
    
  float remaining = width - _numberOfColumns * itemSize.width;
  BOOL itemsNeedSizeUpdate = NO;
    
  if (remaining > 0 && itemSize.width < _maxItemSize.width)
    itemSize.width = MIN(_maxItemSize.width, itemSize.width + floor(remaining / _numberOfColumns));
    
  if (_maxNumberOfColumns == 1 && itemSize.width < _maxItemSize.width && itemSize.width < width)
    itemSize.width = MIN(_maxItemSize.width, width);
    
  if (!NSEqualSizes(_itemSize, itemSize))
    {
      _itemSize = itemSize;
      itemsNeedSizeUpdate = YES;
    }
    
  int index = 0;
  long count = (long)[_items count];
    
  if (_maxNumberOfColumns > 0 && _maxNumberOfRows > 0)
    count = MIN(count, _maxNumberOfColumns * _maxNumberOfRows);
    
  float _horizontalMargin = floor((width - _numberOfColumns * itemSize.width) / (_numberOfColumns + 1));
    
  float x = _horizontalMargin;
  float y = -itemSize.height;
    
  for (; index < count; ++index)
    {
      if (index % _numberOfColumns == 0)
        {
          x = _horizontalMargin;
          y += _verticalMargin + itemSize.height;
        }
        
      NSView *view = [[_items objectAtIndex:index] view];
        
      [view setFrameOrigin:NSMakePoint(x, y)];
        
      if (itemsNeedSizeUpdate)
          [view setFrameSize:_itemSize];

      x += itemSize.width + _horizontalMargin;
    }
    
    float proposedHeight = y + itemSize.height + _verticalMargin;

    _tileWidth = width;
    [self setFrameSize:NSMakeSize(width, proposedHeight)];
    _tileWidth = -1.0;

}

- (void)resizeSubviewsWithOldSize:(NSSize)aSize
{
  [self tile];
}

- (id)initWithCoder:(NSCoder *)aCoder
{
  self = [super initWithCoder:aCoder];
    
  if (self)
    {
      _items = [NSMutableArray array];
      _content = [NSArray array];
        
      _itemSize = NSMakeSize(0, 0);
        
      _minItemSize = [aCoder decodeSizeForKey:NSCollectionViewMinItemSizeKey];
      _maxItemSize = [aCoder decodeSizeForKey:NSCollectionViewMaxItemSizeKey];
        
      _maxNumberOfRows = [aCoder decodeInt64ForKey:NSCollectionViewMaxNumberOfRowsKey];
      _maxNumberOfColumns = [aCoder decodeInt64ForKey:NSCollectionViewMaxNumberOfColumnsKey];
        
      _verticalMargin = [aCoder decodeFloatForKey:NSCollectionViewVerticalMarginKey];
        
      _isSelectable = [aCoder decodeBoolForKey:NSCollectionViewSelectableKey];
      _allowsMultipleSelection = [aCoder decodeBoolForKey:NSCollectionViewAllowsMultipleSelectionKey];
        
      [self setBackgroundColors:[aCoder decodeObjectForKey:NSCollectionViewBackgroundColorsKey]];
        
      _tileWidth = -1.0;
        
      _selectionIndexes = [NSIndexSet indexSet];
      
	  // FIXME	  
      //_allowsEmptySelection = YES;
    }
    
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
    
  if (!NSEqualSizes(_minItemSize, NSMakeSize(0, 0)))
      [aCoder encodeSize:_minItemSize forKey:NSCollectionViewMinItemSizeKey];
    
  if (!NSEqualSizes(_maxItemSize, NSMakeSize(0, 0)))
      [aCoder encodeSize:_maxItemSize forKey:NSCollectionViewMaxItemSizeKey];
    
  [aCoder encodeInt64:_maxNumberOfRows forKey:NSCollectionViewMaxNumberOfRowsKey];
  [aCoder encodeInt64:_maxNumberOfColumns forKey:NSCollectionViewMaxNumberOfColumnsKey];
    
  [aCoder encodeBool:_isSelectable forKey:NSCollectionViewSelectableKey];
  [aCoder encodeBool:_allowsMultipleSelection forKey:NSCollectionViewAllowsMultipleSelectionKey];
    
  [aCoder encodeFloat:_verticalMargin forKey:NSCollectionViewVerticalMarginKey];
    
  [aCoder encodeObject:_backgroundColors forKey:NSCollectionViewBackgroundColorsKey];
}

@end
