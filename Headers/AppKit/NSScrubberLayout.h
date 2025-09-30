/* Definition of class NSScrubberLayout
   Copyright (C) 2020 Free Software Foundation, Inc.
   
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

#ifndef _NSScrubberLayout_h_GNUSTEP_GUI_INCLUDE
#define _NSScrubberLayout_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSGeometry.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSScrubber; 

/**
 * NSScrubberLayoutAttributes defines the layout information for an item
 * in a scrubber layout. It encapsulates properties like frame, alpha,
 * and item index.
 */
APPKIT_EXPORT_CLASS
@interface NSScrubberLayoutAttributes : NSObject <NSCopying>

/**
 * Creates layout attributes for an item at the specified index.
 * index is the index of the item.
 * Returns a new layout attributes object.
 */
+ (NSScrubberLayoutAttributes *) layoutAttributesForItemAtIndex: (NSInteger)index;

/**
 * Returns the alpha (opacity) value for the item.
 */
- (CGFloat) alpha;

/**
 * Sets the alpha (opacity) value for the item.
 * alpha is the opacity value.
 */
- (void) setAlpha: (CGFloat)alpha;

/**
 * Returns the frame rectangle for the item.
 */
- (NSRect) frame;

/**
 * Sets the frame rectangle for the item.
 * frame is the frame rectangle.
 */
- (void) setFrame: (NSRect)frame;

/**
 * Returns the index of the item these attributes represent.
 */
- (NSInteger) itemIndex;

/**
 * Sets the index of the item these attributes represent.
 * itemIndex is the item index.
 */
- (void) setItemIndex: (NSInteger)itemIndex;

@end

/**
 * NSScrubberLayout is an abstract base class for layout objects that 
 * arrange items within a scrubber. Subclasses implement specific layout
 * strategies such as flow layout or proportional layout.
 */
APPKIT_EXPORT_CLASS
@interface NSScrubberLayout : NSObject <NSCoding>

// MARK: - Layout Configuration

/**
 * Returns the class used for layout attributes.
 * Subclasses can override this to provide custom attribute classes.
 * Returns the layout attributes class.
 */
- (Class) layoutAttributesClass;

/**
 * Returns the scrubber that owns this layout object.
 */
- (NSScrubber *) scrubber;

/**
 * Returns the visible rectangle of the scrubber.
 */
- (NSRect) visibleRect;

/**
 * Invalidates the current layout, causing it to be recalculated.
 */
- (void) invalidateLayout;

// MARK: - Subclassing Methods

/**
 * Prepares the layout for use.
 * Subclasses should override this method to perform any necessary setup
 * before layout attributes are requested.
 */
- (void) prepareLayout;

/**
 * Returns the total content size required for all items.
 * Returns the content size.
 */
- (NSSize) scrubberContentSize;

/**
 * Returns the layout attributes for the item at the specified index.
 * index is the index of the item.
 * Returns the layout attributes for the item.
 */
- (NSScrubberLayoutAttributes *) layoutAttributesForItemAtIndex: (NSInteger)index;

/**
 * Returns an array of layout attributes for items in the specified rectangle.
 * rect is the rectangle to query.
 * Returns an array of layout attributes.
 */
- (NSArray<NSScrubberLayoutAttributes *> *) layoutAttributesForItemsInRect: (NSRect)rect;

/**
 * Returns whether the layout should be invalidated when highlighting changes.
 * Returns YES if the layout should be invalidated, NO otherwise.
 */
- (BOOL) shouldInvalidateLayoutForHighlightChange;

/**
 * Returns whether the layout should be invalidated when selection changes.
 * Returns YES if the layout should be invalidated, NO otherwise.
 */
- (BOOL) shouldInvalidateLayoutForSelectionChange;

/**
 * Returns whether the layout should be invalidated for visible rect changes.
 * fromRect is the previous visible rectangle.
 * toRect is the new visible rectangle.
 * Returns YES if the layout should be invalidated, NO otherwise.
 */
- (BOOL) shouldInvalidateLayoutForChangeFromVisibleRect: (NSRect)fromRect
                                          toVisibleRect: (NSRect)toRect;

/**
 * Returns whether the layout automatically mirrors in right-to-left layouts.
 * Returns YES if the layout mirrors automatically, NO otherwise.
 */
- (BOOL) automaticallyMirrorsInRightToLeftLayout;

@end



  
#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSScrubberLayout_h_GNUSTEP_GUI_INCLUDE */

