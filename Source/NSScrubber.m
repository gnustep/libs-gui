/* Implementation of class NSScrubber
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr  8 09:16:14 EDT 2020

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

#import "AppKit/NSScrubber.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSScrollView.h"
#import "Foundation/NSIndexSet.h"
#import "Foundation/NSString.h"
#import "Foundation/NSMutableDictionary.h"
#import "Foundation/NSMutableArray.h"

// Private interface for internal state management
@interface NSScrubber()
{
    NSMutableDictionary *_registeredClasses;
    NSMutableDictionary *_registeredNibs;
    NSMutableArray *_itemViews;
    NSMutableArray *_reusableItemViews;
    BOOL _isUpdating;
    BOOL _needsReload;
}

- (void) _commonInit;
- (void) _layoutItemViews;
- (void) _updateItemViewsIfNeeded;
- (NSScrubberItemView *) _dequeueReusableItemViewWithIdentifier: (NSString *)identifier;
- (void) _enqueueReusableItemView: (NSScrubberItemView *)itemView;
- (void) _setNeedsLayout;
- (void) _sendDelegateDidSelectItemAtIndex: (NSInteger)index;
- (void) _sendDelegateDidHighlightItemAtIndex: (NSInteger)index;
- (void) _sendDelegateDidBeginInteracting;
- (void) _sendDelegateDidFinishInteracting;
- (void) _sendDelegateDidCancelInteracting;

@end

@implementation NSScrubber

// MARK: - Class Methods

+ (void) initialize
{
    if (self == [NSScrubber class])
    {
        [self setVersion: 1];
    }
}

// MARK: - Initialization

- (id) init
{
    return [self initWithFrame: NSZeroRect];
}

- (id) initWithFrame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self)
    {
        [self _commonInit];
    }
    return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
    self = [super initWithCoder: coder];
    if (self)
    {
        [self _commonInit];
        
        // Decode properties from the coder if needed
        if ([coder containsValueForKey: @"backgroundColor"])
        {
            _backgroundColor = [coder decodeObjectForKey: @"backgroundColor"];
        }
        
        if ([coder containsValueForKey: @"selectedIndex"])
        {
            _selectedIndex = [coder decodeIntegerForKey: @"selectedIndex"];
        }
        
        if ([coder containsValueForKey: @"highlightedIndex"])
        {
            _highlightedIndex = [coder decodeIntegerForKey: @"highlightedIndex"];
        }
        
        if ([coder containsValueForKey: @"itemAlignment"])
        {
            _itemAlignment = [coder decodeIntegerForKey: @"itemAlignment"];
        }
        
        if ([coder containsValueForKey: @"mode"])
        {
            _mode = [coder decodeIntegerForKey: @"mode"];
        }
        
        if ([coder containsValueForKey: @"continuous"])
        {
            _continuous = [coder decodeBoolForKey: @"continuous"];
        }
        
        if ([coder containsValueForKey: @"showsArrowButtons"])
        {
            _showsArrowButtons = [coder decodeBoolForKey: @"showsArrowButtons"];
        }
        
        if ([coder containsValueForKey: @"showsAdditionalContentIndicators"])
        {
            _showsAdditionalContentIndicators = [coder decodeBoolForKey: @"showsAdditionalContentIndicators"];
        }
        
        if ([coder containsValueForKey: @"floatsSelectionViews"])
        {
            _floatsSelectionViews = [coder decodeBoolForKey: @"floatsSelectionViews"];
        }
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [super encodeWithCoder: coder];
    
    [coder encodeObject: _backgroundColor forKey: @"backgroundColor"];
    [coder encodeInteger: _selectedIndex forKey: @"selectedIndex"];
    [coder encodeInteger: _highlightedIndex forKey: @"highlightedIndex"];
    [coder encodeInteger: _itemAlignment forKey: @"itemAlignment"];
    [coder encodeInteger: _mode forKey: @"mode"];
    [coder encodeBool: _continuous forKey: @"continuous"];
    [coder encodeBool: _showsArrowButtons forKey: @"showsArrowButtons"];
    [coder encodeBool: _showsAdditionalContentIndicators forKey: @"showsAdditionalContentIndicators"];
    [coder encodeBool: _floatsSelectionViews forKey: @"floatsSelectionViews"];
}

- (void) dealloc
{
    [_registeredClasses release];
    [_registeredNibs release];
    [_itemViews release];
    [_reusableItemViews release];
    [_backgroundColor release];
    [_backgroundView release];
    [_scrubberLayout release];
    [_selectionBackgroundStyle release];
    [_selectionOverlayStyle release];
    
    [super dealloc];
}

// MARK: - Private Methods

- (void) _commonInit
{
    _registeredClasses = [[NSMutableDictionary alloc] init];
    _registeredNibs = [[NSMutableDictionary alloc] init];
    _itemViews = [[NSMutableArray alloc] init];
    _reusableItemViews = [[NSMutableArray alloc] init];
    
    // Set default values
    _selectedIndex = NSNotFound;
    _highlightedIndex = NSNotFound;
    _itemAlignment = NSScrubberAlignmentNone;
    _mode = NSScrubberModeFree;
    _continuous = YES;
    _showsArrowButtons = NO;
    _showsAdditionalContentIndicators = NO;
    _floatsSelectionViews = YES;
    _isUpdating = NO;
    _needsReload = YES;
    
    // Set up default background color
    _backgroundColor = [[NSColor clearColor] retain];
}

- (void) _layoutItemViews
{
    if (_scrubberLayout)
    {
        [_scrubberLayout prepareLayout];
        
        NSSize contentSize = [_scrubberLayout scrubberContentSize];
        
        // Layout each visible item view
        for (NSInteger i = 0; i < [_itemViews count]; i++)
        {
            NSScrubberItemView *itemView = [_itemViews objectAtIndex: i];
            if (itemView && itemView != (id)[NSNull null])
            {
                NSScrubberLayoutAttributes *attributes = [_scrubberLayout layoutAttributesForItemAtIndex: i];
                if (attributes)
                {
                    [itemView setFrame: [attributes frame]];
                    [itemView setAlphaValue: [attributes alpha]];
                }
            }
        }
    }
    
    [self setNeedsDisplay: YES];
}

- (void) _updateItemViewsIfNeeded
{
    if (_needsReload && !_isUpdating)
    {
        [self reloadData];
    }
}

- (NSScrubberItemView *) _dequeueReusableItemViewWithIdentifier: (NSString *)identifier
{
    for (NSInteger i = [_reusableItemViews count] - 1; i >= 0; i--)
    {
        NSScrubberItemView *itemView = [_reusableItemViews objectAtIndex: i];
        if ([[itemView reuseIdentifier] isEqualToString: identifier])
        {
            [itemView retain];
            [_reusableItemViews removeObjectAtIndex: i];
            return [itemView autorelease];
        }
    }
    return nil;
}

- (void) _enqueueReusableItemView: (NSScrubberItemView *)itemView
{
    if (itemView)
    {
        [itemView removeFromSuperview];
        [itemView prepareForReuse];
        [_reusableItemViews addObject: itemView];
    }
}

- (void) _setNeedsLayout
{
    [self setNeedsLayout: YES];
    [self setNeedsDisplay: YES];
}

// MARK: - Delegate Methods

- (void) _sendDelegateDidSelectItemAtIndex: (NSInteger)index
{
    if (_delegate && [_delegate respondsToSelector: @selector(scrubber:didSelectItemAt:)])
    {
        [_delegate scrubber: self didSelectItemAt: index];
    }
}

- (void) _sendDelegateDidHighlightItemAtIndex: (NSInteger)index
{
    if (_delegate && [_delegate respondsToSelector: @selector(scrubber:didHighlightItemAt:)])
    {
        [_delegate scrubber: self didHighlightItemAt: index];
    }
}

- (void) _sendDelegateDidBeginInteracting
{
    if (_delegate && [_delegate respondsToSelector: @selector(didBeginInteractingWithScrubber:)])
    {
        [_delegate didBeginInteractingWithScrubber: self];
    }
}

- (void) _sendDelegateDidFinishInteracting
{
    if (_delegate && [_delegate respondsToSelector: @selector(didFinishInteractingWithScrubber:)])
    {
        [_delegate didFinishInteractingWithScrubber: self];
    }
}

- (void) _sendDelegateDidCancelInteracting
{
    if (_delegate && [_delegate respondsToSelector: @selector(didCancelInteractingWithScrubber:)])
    {
        [_delegate didCancelInteractingWithScrubber: self];
    }
}

// MARK: - Property Accessors

- (void) setDataSource: (id<NSScrubberDataSource>)dataSource
{
    if (_dataSource != dataSource)
    {
        _dataSource = dataSource;
        _needsReload = YES;
        [self _setNeedsLayout];
    }
}

- (void) setScrubberLayout: (NSScrubberLayout *)scrubberLayout
{
    if (_scrubberLayout != scrubberLayout)
    {
        [_scrubberLayout release];
        _scrubberLayout = [scrubberLayout retain];
        
        // Set the scrubber reference in the layout
        if (_scrubberLayout && [_scrubberLayout respondsToSelector: @selector(_setScrubber:)])
        {
            [_scrubberLayout performSelector: @selector(_setScrubber:) withObject: self];
        }
        
        [self _setNeedsLayout];
    }
}

- (void) setBackgroundColor: (NSColor *)backgroundColor
{
    if (_backgroundColor != backgroundColor)
    {
        [_backgroundColor release];
        _backgroundColor = [backgroundColor retain];
        [self setNeedsDisplay: YES];
    }
}

- (void) setBackgroundView: (NSView *)backgroundView
{
    if (_backgroundView != backgroundView)
    {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
        _backgroundView = [backgroundView retain];
        
        if (_backgroundView)
        {
            [self addSubview: _backgroundView positioned: NSWindowBelow relativeTo: nil];
        }
        [self setNeedsDisplay: YES];
    }
}

- (void) setSelectedIndex: (NSInteger)selectedIndex
{
    if (_selectedIndex != selectedIndex)
    {
        NSInteger oldIndex = _selectedIndex;
        _selectedIndex = selectedIndex;
        
        // Update selection appearance
        [self setNeedsDisplay: YES];
        
        if (_continuous)
        {
            [self _sendDelegateDidSelectItemAtIndex: selectedIndex];
        }
    }
}

- (void) setHighlightedIndex: (NSInteger)highlightedIndex
{
    if (_highlightedIndex != highlightedIndex)
    {
        _highlightedIndex = highlightedIndex;
        [self setNeedsDisplay: YES];
        [self _sendDelegateDidHighlightItemAtIndex: highlightedIndex];
    }
}

- (void) setItemAlignment: (NSScrubberAlignment)itemAlignment
{
    if (_itemAlignment != itemAlignment)
    {
        _itemAlignment = itemAlignment;
        [self _setNeedsLayout];
    }
}

- (void) setMode: (NSScrubberMode)mode
{
    if (_mode != mode)
    {
        _mode = mode;
        [self _setNeedsLayout];
    }
}

- (void) setContinuous: (BOOL)continuous
{
    _continuous = continuous;
}

- (void) setShowsArrowButtons: (BOOL)showsArrowButtons
{
    if (_showsArrowButtons != showsArrowButtons)
    {
        _showsArrowButtons = showsArrowButtons;
        [self setNeedsDisplay: YES];
    }
}

- (void) setShowsAdditionalContentIndicators: (BOOL)showsAdditionalContentIndicators
{
    if (_showsAdditionalContentIndicators != showsAdditionalContentIndicators)
    {
        _showsAdditionalContentIndicators = showsAdditionalContentIndicators;
        [self setNeedsDisplay: YES];
    }
}

- (void) setFloatsSelectionViews: (BOOL)floatsSelectionViews
{
    if (_floatsSelectionViews != floatsSelectionViews)
    {
        _floatsSelectionViews = floatsSelectionViews;
        [self setNeedsDisplay: YES];
    }
}

- (NSInteger) numberOfItems
{
    if (_dataSource && [_dataSource respondsToSelector: @selector(numberOfItemsForScrubber:)])
    {
        return [_dataSource numberOfItemsForScrubber: self];
    }
    return 0;
}

// MARK: - Item Management

- (void) reloadData
{
    _isUpdating = YES;
    
    // Remove all current item views
    NSEnumerator *enumerator = [_itemViews objectEnumerator];
    NSScrubberItemView *itemView;
    while ((itemView = [enumerator nextObject]))
    {
        if (itemView && itemView != (id)[NSNull null])
        {
            [self _enqueueReusableItemView: itemView];
        }
    }
    [_itemViews removeAllObjects];
    
    // Get the number of items from the data source
    NSInteger itemCount = [self numberOfItems];
    
    // Create placeholder array for item views
    for (NSInteger i = 0; i < itemCount; i++)
    {
        [_itemViews addObject: [NSNull null]];
    }
    
    // Load visible item views
    if (_dataSource && [_dataSource respondsToSelector: @selector(scrubber:viewForItemAt:)])
    {
        // For now, load all items (in a real implementation, this would be optimized for visible items only)
        for (NSInteger i = 0; i < itemCount; i++)
        {
            NSScrubberItemView *itemView = [_dataSource scrubber: self viewForItemAt: i];
            if (itemView)
            {
                [_itemViews replaceObjectAtIndex: i withObject: itemView];
                [self addSubview: itemView];
            }
        }
    }
    
    _needsReload = NO;
    _isUpdating = NO;
    
    [self _layoutItemViews];
}

- (void) reloadItemsAtIndexes: (NSIndexSet *)indexes
{
    if (!_dataSource || _isUpdating)
        return;
    
    [indexes enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
        if (idx < [_itemViews count])
        {
            // Remove existing item view
            NSScrubberItemView *oldItemView = [_itemViews objectAtIndex: idx];
            if (oldItemView && oldItemView != (id)[NSNull null])
            {
                [self _enqueueReusableItemView: oldItemView];
            }
            
            // Load new item view
            if ([_dataSource respondsToSelector: @selector(scrubber:viewForItemAt:)])
            {
                NSScrubberItemView *newItemView = [_dataSource scrubber: self viewForItemAt: idx];
                if (newItemView)
                {
                    [_itemViews replaceObjectAtIndex: idx withObject: newItemView];
                    [self addSubview: newItemView];
                }
                else
                {
                    [_itemViews replaceObjectAtIndex: idx withObject: [NSNull null]];
                }
            }
        }
    }];
    
    [self _layoutItemViews];
}

- (void) insertItemsAtIndexes: (NSIndexSet *)indexes
{
    if (_isUpdating)
        return;
    
    _isUpdating = YES;
    
    // Insert null placeholders for the new items
    [indexes enumerateIndexesWithOptions: NSEnumerationReverse usingBlock: ^(NSUInteger idx, BOOL *stop) {
        [_itemViews insertObject: [NSNull null] atIndex: idx];
    }];
    
    // Reload the inserted items
    [self reloadItemsAtIndexes: indexes];
    
    _isUpdating = NO;
}

- (void) removeItemsAtIndexes: (NSIndexSet *)indexes
{
    if (_isUpdating)
        return;
    
    _isUpdating = YES;
    
    // Remove item views and update selection/highlighting
    [indexes enumerateIndexesWithOptions: NSEnumerationReverse usingBlock: ^(NSUInteger idx, BOOL *stop) {
        if (idx < [_itemViews count])
        {
            NSScrubberItemView *itemView = [_itemViews objectAtIndex: idx];
            if (itemView && itemView != (id)[NSNull null])
            {
                [self _enqueueReusableItemView: itemView];
            }
            [_itemViews removeObjectAtIndex: idx];
        }
        
        // Update selection and highlighting indices
        if (_selectedIndex != NSNotFound && _selectedIndex >= (NSInteger)idx)
        {
            if (_selectedIndex == (NSInteger)idx)
            {
                _selectedIndex = NSNotFound;
            }
            else
            {
                _selectedIndex--;
            }
        }
        
        if (_highlightedIndex != NSNotFound && _highlightedIndex >= (NSInteger)idx)
        {
            if (_highlightedIndex == (NSInteger)idx)
            {
                _highlightedIndex = NSNotFound;
            }
            else
            {
                _highlightedIndex--;
            }
        }
    }];
    
    _isUpdating = NO;
    [self _layoutItemViews];
}

- (void) moveItemAtIndex: (NSInteger)fromIndex 
                 toIndex: (NSInteger)toIndex
{
    if (_isUpdating || fromIndex == toIndex || 
        fromIndex < 0 || fromIndex >= [_itemViews count] ||
        toIndex < 0 || toIndex >= [_itemViews count])
        return;
    
    _isUpdating = YES;
    
    // Move the item view
    NSScrubberItemView *itemView = [[_itemViews objectAtIndex: fromIndex] retain];
    [_itemViews removeObjectAtIndex: fromIndex];
    [_itemViews insertObject: itemView atIndex: toIndex];
    [itemView release];
    
    // Update selection and highlighting indices
    if (_selectedIndex == fromIndex)
    {
        _selectedIndex = toIndex;
    }
    else if (_selectedIndex > fromIndex && _selectedIndex <= toIndex)
    {
        _selectedIndex--;
    }
    else if (_selectedIndex < fromIndex && _selectedIndex >= toIndex)
    {
        _selectedIndex++;
    }
    
    if (_highlightedIndex == fromIndex)
    {
        _highlightedIndex = toIndex;
    }
    else if (_highlightedIndex > fromIndex && _highlightedIndex <= toIndex)
    {
        _highlightedIndex--;
    }
    else if (_highlightedIndex < fromIndex && _highlightedIndex >= toIndex)
    {
        _highlightedIndex++;
    }
    
    _isUpdating = NO;
    [self _layoutItemViews];
}

// MARK: - Item Views and Registration

- (NSScrubberItemView *) itemViewForItemAtIndex: (NSInteger)index
{
    if (index >= 0 && index < [_itemViews count])
    {
        NSScrubberItemView *itemView = [_itemViews objectAtIndex: index];
        if (itemView && itemView != (id)[NSNull null])
        {
            return itemView;
        }
    }
    return nil;
}

- (void) registerClass: (Class)itemViewClass 
     forItemIdentifier: (NSString *)identifier
{
    if (itemViewClass && identifier)
    {
        [_registeredClasses setObject: itemViewClass forKey: identifier];
    }
}

- (void) registerNib: (NSNib *)nib 
   forItemIdentifier: (NSString *)identifier
{
    if (nib && identifier)
    {
        [_registeredNibs setObject: nib forKey: identifier];
    }
}

- (NSScrubberItemView *) makeItemWithIdentifier: (NSString *)identifier 
                                          owner: (id)owner
{
    if (!identifier)
        return nil;
    
    // Try to dequeue a reusable item view
    NSScrubberItemView *itemView = [self _dequeueReusableItemViewWithIdentifier: identifier];
    
    if (!itemView)
    {
        // Try to create from registered nib
        NSNib *nib = [_registeredNibs objectForKey: identifier];
        if (nib)
        {
            NSArray *topLevelObjects = nil;
            if ([nib instantiateWithOwner: owner topLevelObjects: &topLevelObjects])
            {
                NSEnumerator *objEnumerator = [topLevelObjects objectEnumerator];
                id object;
                while ((object = [objEnumerator nextObject]))
                {
                    if ([object isKindOfClass: [NSScrubberItemView class]])
                    {
                        itemView = object;
                        break;
                    }
                }
            }
        }
        else
        {
            // Try to create from registered class
            Class itemViewClass = [_registeredClasses objectForKey: identifier];
            if (itemViewClass && [itemViewClass isSubclassOfClass: [NSScrubberItemView class]])
            {
                itemView = [[[itemViewClass alloc] init] autorelease];
            }
        }
        
        if (itemView)
        {
            [itemView setReuseIdentifier: identifier];
        }
    }
    
    return itemView;
}

// MARK: - Scrolling

- (void) scrollItemAtIndex: (NSInteger)index 
              toAlignment: (NSScrubberAlignment)alignment
{
    if (index < 0 || index >= [self numberOfItems])
        return;
    
    NSScrubberItemView *itemView = [self itemViewForItemAtIndex: index];
    if (!itemView)
        return;
    
    NSRect itemFrame = [itemView frame];
    NSRect visibleRect = [self visibleRect];
    
    // Calculate the target scroll position based on alignment
    CGFloat targetX = 0;
    
    switch (alignment)
    {
        case NSScrubberAlignmentLeading:
            targetX = NSMinX(itemFrame);
            break;
            
        case NSScrubberAlignmentCenter:
            targetX = NSMidX(itemFrame) - NSWidth(visibleRect) / 2.0;
            break;
            
        case NSScrubberAlignmentTrailing:
            targetX = NSMaxX(itemFrame) - NSWidth(visibleRect);
            break;
            
        default:
            return;
    }
    
    NSPoint scrollPoint = NSMakePoint(targetX, NSMinY(visibleRect));
    [self scrollPoint: scrollPoint];
}

// MARK: - Batch Updates

- (void) performSequentialBatchUpdates: (void (^)(void))updates
{
    if (!updates)
        return;
    
    BOOL wasUpdating = _isUpdating;
    _isUpdating = YES;
    
    updates();
    
    _isUpdating = wasUpdating;
    
    if (!_isUpdating)
    {
        [self _layoutItemViews];
    }
}

// MARK: - NSView Overrides

- (void) drawRect: (NSRect)dirtyRect
{
    [super drawRect: dirtyRect];
    
    // Draw background color
    if (_backgroundColor)
    {
        [_backgroundColor setFill];
        NSRectFill(dirtyRect);
    }
    
    // The item views will draw themselves
    
    // Draw selection and highlighting if needed
    if (_selectedIndex != NSNotFound || _highlightedIndex != NSNotFound)
    {
        [self setNeedsDisplay: YES];
    }
}

- (void) layout
{
    [super layout];
    [self _updateItemViewsIfNeeded];
    [self _layoutItemViews];
}

- (void) setFrame: (NSRect)frame
{
    [super setFrame: frame];
    [self _setNeedsLayout];
}

- (void) setBounds: (NSRect)bounds
{
    [super setBounds: bounds];
    [self _setNeedsLayout];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (BOOL) isOpaque
{
    return _backgroundColor && [_backgroundColor alphaComponent] >= 1.0;
}

// MARK: - Mouse Event Handling

- (void) mouseDown: (NSEvent *)event
{
    NSPoint location = [self convertPoint: [event locationInWindow] fromView: nil];
    
    // Find which item was clicked
    for (NSInteger i = 0; i < [_itemViews count]; i++)
    {
        NSScrubberItemView *itemView = [_itemViews objectAtIndex: i];
        if (itemView && itemView != (id)[NSNull null] && NSPointInRect(location, [itemView frame]))
        {
            [self _sendDelegateDidBeginInteracting];
            
            // Update selection
            [self setSelectedIndex: i];
            
            if (!_continuous)
            {
                [self _sendDelegateDidSelectItemAtIndex: i];
            }
            
            [self _sendDelegateDidFinishInteracting];
            return;
        }
    }
    
    [super mouseDown: event];
}

- (void) mouseMoved: (NSEvent *)event
{
    NSPoint location = [self convertPoint: [event locationInWindow] fromView: nil];
    
    // Find which item is under the cursor
    NSInteger newHighlightedIndex = NSNotFound;
    for (NSInteger i = 0; i < [_itemViews count]; i++)
    {
        NSScrubberItemView *itemView = [_itemViews objectAtIndex: i];
        if (itemView && itemView != (id)[NSNull null] && NSPointInRect(location, [itemView frame]))
        {
            newHighlightedIndex = i;
            break;
        }
    }
    
    [self setHighlightedIndex: newHighlightedIndex];
    [super mouseMoved: event];
}

@end

