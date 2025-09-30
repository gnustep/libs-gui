/* Implementation of class NSScrubberLayout
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr  8 09:20:18 EDT 2020

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

#import "AppKit/NSScrubberLayout.h"
#import "Foundation/NSArray.h"



@implementation NSScrubberLayoutAttributes 

// MARK: - Class Methods

+ (void) initialize
{
    if (self == [NSScrubberLayoutAttributes class])
    {
        [self setVersion: 1];
    }
}

+ (NSScrubberLayoutAttributes *) layoutAttributesForItemAtIndex: (NSInteger)index
{
    NSScrubberLayoutAttributes *attributes = [[self alloc] init];
    [attributes setItemIndex: index];
    [attributes setAlpha: 1.0];
    [attributes setFrame: NSZeroRect];
    return [attributes autorelease];
}

// MARK: - Initialization

- (id) init
{
    self = [super init];
    if (self)
    {
        _alpha = 1.0;
        _frame = NSZeroRect;
        _itemIndex = NSNotFound;
    }
    return self;
}

// MARK: - NSCopying Protocol

- (id) copyWithZone: (NSZone *)zone
{
    NSScrubberLayoutAttributes *copy = [[[self class] allocWithZone: zone] init];
    [copy setAlpha: _alpha];
    [copy setFrame: _frame];
    [copy setItemIndex: _itemIndex];
    return copy;
}

// MARK: - Equality and Hashing

- (BOOL) isEqual: (id)other
{
    if (![other isKindOfClass: [NSScrubberLayoutAttributes class]])
        return NO;
    
    NSScrubberLayoutAttributes *otherAttrs = (NSScrubberLayoutAttributes *)other;
    return _itemIndex == otherAttrs.itemIndex &&
           _alpha == otherAttrs.alpha &&
           NSEqualRects(_frame, otherAttrs.frame);
}

- (NSUInteger) hash
{
    return _itemIndex ^ (NSUInteger)_alpha ^ NSStringFromRect(_frame).hash;
}

// MARK: - Description

- (NSString *) description
{
    return [NSString stringWithFormat: @"<%@: %p; itemIndex: %ld; frame: %@; alpha: %g>",
            [self className], self, (long)_itemIndex, NSStringFromRect(_frame), _alpha];
}

@end

@implementation NSScrubberLayout

// MARK: - Class Methods

+ (void) initialize
{
    if (self == [NSScrubberLayout class])
    {
        [self setVersion: 1];
    }
}

// MARK: - Initialization

- (id) init
{
    self = [super init];
    if (self)
    {
        _scrubber = nil;
    }
    return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        _scrubber = nil;
        // Decode any layout-specific properties here if needed
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    // Encode any layout-specific properties here if needed
}

// MARK: - Layout Configuration

- (Class) layoutAttributesClass
{
    return [NSScrubberLayoutAttributes class];
}

- (NSScrubber *) scrubber
{
    return _scrubber;
}

- (NSRect) visibleRect
{
    if (_scrubber)
    {
        return [_scrubber visibleRect];
    }
    return NSZeroRect;
}

- (void) invalidateLayout
{
    // Default implementation does nothing
    // Subclasses should override to perform invalidation-specific logic
}

// MARK: - Subclassing Methods

- (void) prepareLayout
{
    /**
     * Default implementation does nothing.
     * Subclasses should override this method to perform any setup
     * required before layout attributes are calculated.
     */
}

- (NSSize) scrubberContentSize
{
    /**
     * Default implementation returns zero size.
     * Subclasses must override this method to return the total
     * content size needed to display all items.
     */
    return NSZeroSize;
}

- (NSScrubberLayoutAttributes *) layoutAttributesForItemAtIndex: (NSInteger)index
{
    /**
     * Default implementation returns nil.
     * Subclasses must override this method to provide layout
     * attributes for the item at the specified index.
     */
    return nil;
}

- (NSArray *) layoutAttributesForItemsInRect: (NSRect)rect
{
    /**
     * Default implementation returns an empty array.
     * Subclasses should override this method to return layout
     * attributes for all items that intersect with the given rectangle.
     */
    return [NSArray array];
}

- (BOOL) shouldInvalidateLayoutForHighlightChange
{
    /**
     * Default implementation returns NO.
     * Subclasses can override this to return YES if highlighting
     * changes require layout recalculation.
     */
    return NO;
}

- (BOOL) shouldInvalidateLayoutForSelectionChange
{
    /**
     * Default implementation returns NO.
     * Subclasses can override this to return YES if selection
     * changes require layout recalculation.
     */
    return NO;
}

- (BOOL) shouldInvalidateLayoutForChangeFromVisibleRect: (NSRect)fromRect
                                          toVisibleRect: (NSRect)toRect
{
    /**
     * Default implementation returns NO.
     * Subclasses can override this to return YES if visible rect
     * changes require layout recalculation.
     */
    return NO;
}

- (BOOL) automaticallyMirrorsInRightToLeftLayout
{
    /**
     * Default implementation returns NO.
     * Subclasses can override this to return YES if the layout
     * should automatically mirror in right-to-left environments.
     */
    return NO;
}

// MARK: - Internal Methods (called by NSScrubber)

- (void) _setScrubber: (NSScrubber *)scrubber
{
    _scrubber = scrubber;
}

@end

