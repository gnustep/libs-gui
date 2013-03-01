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
#import <Foundation/NSTimer.h>

#import "AppKit/NSView.h"
#import "AppKit/NSAnimation.h"
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




static NSString* NSCollectionViewMinItemSizeKey              = @"NSMinGridSize";
static NSString* NSCollectionViewMaxItemSizeKey              = @"NSMaxGridSize";
//static NSString* NSCollectionViewVerticalMarginKey           = @"NSCollectionViewVerticalMarginKey";
static NSString* NSCollectionViewMaxNumberOfRowsKey          = @"NSMaxNumberOfGridRows";
static NSString* NSCollectionViewMaxNumberOfColumnsKey       = @"NSMaxNumberOfGridColumns";
static NSString* NSCollectionViewSelectableKey               = @"NSSelectable";
static NSString* NSCollectionViewAllowsMultipleSelectionKey  = @"NSAllowsMultipleSelection";
static NSString* NSCollectionViewBackgroundColorsKey         = @"NSBackgroundColors";

/*
 * Class variables
 */
static NSString *placeholderItem = nil;

@interface NSCollectionView (CollectionViewInternalPrivate)
- (void)_resetItemSize;
- (void)_removeItemsViews;
- (int)_indexAtPoint:(NSPoint)point;
- (void)_modifySelectionWithNewIndex:(int)anIndex
                           direction:(int)aDireection
						      expand:(BOOL)shouldExpand;
							  
- (void)_moveDownAndExpandSelection:(BOOL)shouldExpand;
- (void)_moveUpAndExpandSelection:(BOOL)shouldExpand;
- (void)_moveLeftAndExpandSelection:(BOOL)shouldExpand;
- (void)_moveRightAndExpandSelection:(BOOL)shouldExpand;
@end


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
  [self _resetItemSize];
  _content = [[NSArray alloc] init];
  _items = [[NSMutableArray alloc] init];
  _selectionIndexes = [[NSIndexSet alloc] init];
}

- (void)_resetItemSize
{
  if (itemPrototype)
    {
      _itemSize = [[itemPrototype view] frame].size;
      _minItemSize = NSMakeSize (_itemSize.width, _itemSize.height);
      _maxItemSize = NSMakeSize (_itemSize.width, _itemSize.height);
    }
  else
    {
      // FIXME: This is just arbitrary.
      _itemSize = NSMakeSize(120.0, 100.0);
      _minItemSize = NSMakeSize(120.0, 100.0);
      _maxItemSize = NSMakeSize(120.0, 100.0);
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill([self bounds]);
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  DESTROY (_content);
  //DESTROY (itemPrototype);
  DESTROY (_backgroundColors);
  DESTROY (_selectionIndexes);
  DESTROY (_items);
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
  RELEASE (_content);
  _content = [content retain];
  [self _removeItemsViews];
  
  RELEASE (_items);
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
  RELEASE (itemPrototype);
  itemPrototype = prototype;
  RETAIN (itemPrototype);
  [self _resetItemSize];
}

- (BOOL)isFirstResponder
{
  // FIXME: This will be required for keyboard events
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
  if (!_isSelectable)
    {
      int index = -1;
      while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != NSNotFound)
        {
	      [[_items objectAtIndex:index] setSelected:NO];
	    }
	}
}

- (NSIndexSet *)selectionIndexes
{
  return _selectionIndexes;
}

- (void)setSelectionIndexes:(NSIndexSet *)indexes
{
  if (!_isSelectable || [_selectionIndexes isEqual:indexes])
    {
	  return;
	}
	
  // FIXME: Reset selectionIndexes in SetContent:
  
  RELEASE(_selectionIndexes);
  _selectionIndexes = indexes;
  RETAIN(_selectionIndexes);
  
  
  NSUInteger index = 0;
  while (index < [_items count])
    {
	  [[_items objectAtIndex:index] setSelected:NO];
	  index++;
	}
  
  index = -1;
  while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != NSNotFound)
    {
	  [[_items objectAtIndex:index] setSelected:YES];
	}
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
	  ASSIGN(collectionItem, [itemPrototype copy]);
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

- (void)_removeItemsViews
{
  if (!_items)
	return;
	
  long count = [_items count];
    
  while (count--)
    {
       if ([[_items objectAtIndex:count] respondsToSelector:@selector(view)])
         {
           [[[_items objectAtIndex:count] view] removeFromSuperview];
           [[_items objectAtIndex:count] setSelected:NO];
         }
    }
}

- (void)reloadContent
{
  [self _removeItemsViews];
    
  if (!itemPrototype)
    return;
    
  long index = 0;
    
  long count = [_content count];
    
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
  // TODO: - Animate items, Add Fade-in/Fade-out (as in Cocoa)
  //       - Put the tiling on a delay
  if (!_items)
    return;
    
  float width = [self bounds].size.width;
    
  if (width == _tileWidth)
    return;
    
  NSSize itemSize = NSMakeSize(_minItemSize.width, _minItemSize.height);
    
  _numberOfColumns = MAX(1.0, floor(width / itemSize.width));
    
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
    
  _horizontalMargin = floor((width - _numberOfColumns * itemSize.width) / (_numberOfColumns + 1));
    
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
}

- (void)resizeSubviewsWithOldSize:(NSSize)aSize
{
  NSSize currentSize = [self frame].size;
  if (!NSEqualSizes(currentSize, aSize))
    {
      [self tile];
    }
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
        
      //_verticalMargin = [aCoder decodeFloatForKey:NSCollectionViewVerticalMarginKey];
        
      _isSelectable = [aCoder decodeBoolForKey:NSCollectionViewSelectableKey];
      _allowsMultipleSelection = [aCoder decodeBoolForKey:NSCollectionViewAllowsMultipleSelectionKey];
        
      [self setBackgroundColors:[aCoder decodeObjectForKey:NSCollectionViewBackgroundColorsKey]];
        
      _tileWidth = -1.0;
        
      _selectionIndexes = [NSIndexSet indexSet];
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
    
  //[aCoder encodeFloat:_verticalMargin forKey:NSCollectionViewVerticalMarginKey];
    
  [aCoder encodeObject:_backgroundColors forKey:NSCollectionViewBackgroundColorsKey];
}

- (void)mouseDown:(NSEvent *)theEvent
{
  // FIXME: This implements only a single mouse click.
  // TODO: Handle double-click & mouse drag
  NSPoint initialLocation = [theEvent locationInWindow];
  NSPoint location = [self convertPoint: initialLocation fromView: nil];
  int index = [self _indexAtPoint:location];
  NSMutableIndexSet *currentIndexSet = [[NSMutableIndexSet alloc] initWithIndexSet:[self selectionIndexes]];

  if (_isSelectable && (index >= 0 && index < [_items count]))
    {
      if (_allowsMultipleSelection
          && (([theEvent modifierFlags] & NSControlKeyMask) || ([theEvent modifierFlags] & NSShiftKeyMask)))

        {
          if ([theEvent modifierFlags] & NSControlKeyMask)
            {
              if ([currentIndexSet containsIndex:index])
                {
                  [currentIndexSet removeIndex:index];
                }
              else
                {
                  [currentIndexSet addIndex:index];
                }
              [self setSelectionIndexes:currentIndexSet];
            }
          else if ([theEvent modifierFlags] & NSShiftKeyMask)
            {
              long firstSelectedIndex = [currentIndexSet firstIndex];
              NSRange selectedRange;
                
              if (firstSelectedIndex == NSNotFound)
                {
                  selectedRange = NSMakeRange(index, index);
                }
              else if (index < firstSelectedIndex)
                {
                  selectedRange = NSMakeRange(index, (firstSelectedIndex - index + 1));
                }
              else
                {
                  selectedRange = NSMakeRange(firstSelectedIndex, (index - firstSelectedIndex + 1));
                }
              [currentIndexSet addIndexesInRange:selectedRange];
              [self setSelectionIndexes:currentIndexSet];
            }
        }
      else
        {
          [self setSelectionIndexes:[NSIndexSet indexSetWithIndex:index]];
        }
      [[self window] makeFirstResponder:self];
    }
    else
    {
        [self setSelectionIndexes:[NSIndexSet indexSet]];
    }
    RELEASE (currentIndexSet);
}

- (int)_indexAtPoint:(NSPoint)point
{
  int row = floor(point.y / (_itemSize.height + _verticalMargin));
  int column = floor(point.x / (_itemSize.width + _horizontalMargin));
  return (column + (row * _numberOfColumns));
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
  [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}
 
-(IBAction)moveUp:(id)sender
{
  [self _moveUpAndExpandSelection:NO];
}
 
-(IBAction)moveUpAndModifySelection:(id)sender
{
  [self _moveUpAndExpandSelection:YES];
}

- (void)_moveUpAndExpandSelection:(BOOL)shouldExpand
{
  int index = [[self selectionIndexes] firstIndex];
  if (index != NSNotFound && (index - _numberOfColumns) >= 0)
    {
      [self _modifySelectionWithNewIndex:index - _numberOfColumns
                               direction:-1 
		    				      expand:shouldExpand];
	}
}
 
-(IBAction)moveDown:(id)sender
{
 [self _moveDownAndExpandSelection:NO];
}

-(IBAction)moveDownAndModifySelection:(id)sender
{
  [self _moveDownAndExpandSelection:YES];
}
 
-(void)_moveDownAndExpandSelection:(BOOL)shouldExpand
{
  int index = [[self selectionIndexes] lastIndex];
  if (index != NSNotFound && (index + _numberOfColumns) < [_items count])
    {
      [self _modifySelectionWithNewIndex:index + _numberOfColumns
                               direction:1 
		    				      expand:shouldExpand];
	}
}
 
-(IBAction)moveLeft:(id)sender
{
  [self _moveLeftAndExpandSelection:NO];
}

-(IBAction)moveLeftAndModifySelection:(id)sender
{
  [self _moveLeftAndExpandSelection:YES];
}

-(IBAction)moveBackwardAndModifySelection:(id)sender
{
  [self _moveLeftAndExpandSelection:YES];
}

-(void)_moveLeftAndExpandSelection:(BOOL)shouldExpand
{
  int index = [[self selectionIndexes] firstIndex];
  if (index != NSNotFound && index != 0)
    {
      [self _modifySelectionWithNewIndex:index-1 direction:-1 expand:shouldExpand];
	}
}
 
-(IBAction)moveRight:(id)sender
{
  [self _moveRightAndExpandSelection:NO];
}

-(IBAction)moveRightAndModifySelection:(id)sender
{
  [self _moveRightAndExpandSelection:YES];
}

-(IBAction)moveForwardAndModifySelection:(id)sender
{
  [self _moveRightAndExpandSelection:YES];
}

-(void)_moveRightAndExpandSelection:(BOOL)shouldExpand
{
  int index = [[self selectionIndexes] lastIndex];
  if (index != NSNotFound && index != ([_items count] - 1))
    {
      [self _modifySelectionWithNewIndex:index+1 direction:1 expand:shouldExpand];
	}
}
 
- (void)_modifySelectionWithNewIndex:(int)anIndex
                           direction:(int)aDirection
						      expand:(BOOL)shouldExpand
{
  anIndex = MIN (MAX (anIndex, 0), [_items count] - 1);
  
  if (_allowsMultipleSelection && shouldExpand)
    {
	  NSMutableIndexSet *newIndexSet = [[NSMutableIndexSet alloc] initWithIndexSet:_selectionIndexes];
	  int firstIndex = [newIndexSet firstIndex];
	  int lastIndex = [newIndexSet lastIndex];
	  if (aDirection == -1)
	    {
		  [newIndexSet addIndexesInRange:NSMakeRange (anIndex, firstIndex - anIndex + 1)];
		}
      else
	    {
		  [newIndexSet addIndexesInRange:NSMakeRange (lastIndex, anIndex - lastIndex + 1)];
		}
	  [self setSelectionIndexes:newIndexSet];
	  RELEASE (newIndexSet);
	}
  else
    {
	  [self setSelectionIndexes:[NSIndexSet indexSetWithIndex:anIndex]];
	}
}

@end
