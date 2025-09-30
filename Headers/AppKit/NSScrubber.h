/* Definition of class NSScrubber
   Copyright (C) 2020 Free Software Foundation, Inc.
   
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

#ifndef _NSScrubber_h_GNUSTEP_GUI_INCLUDE
#define _NSScrubber_h_GNUSTEP_GUI_INCLUDE

#import "AppKit/NSView.h"

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#import "AppKit/NSScrubberLayout.h"
#import "AppKit/NSScrubberItemView.h"

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSScrubberLayout, NSColor, NSView;
@protocol NSScrubberDataSource, NSScrubberDelegate;

/**
 * Alignment options for scrubber items.
 */
typedef NS_ENUM(NSInteger, NSScrubberAlignment) {
    NSScrubberAlignmentNone,
    NSScrubberAlignmentLeading,
    NSScrubberAlignmentTrailing,
    NSScrubberAlignmentCenter
};

/**
 * Mode options for scrubber interaction.
 */
typedef NS_ENUM(NSInteger, NSScrubberMode) {
    NSScrubberModeFree,
    NSScrubberModeFixed
};

/**
 * Selection background style options.
 */
typedef NS_ENUM(NSInteger, NSScrubberSelectionStyle) {
    NSScrubberSelectionStyleNone,
    NSScrubberSelectionStyleOutline,
    NSScrubberSelectionStyleRoundedBackground
};

/**
 * Protocol defining data source methods for NSScrubber.
 * The data source provides the scrubber with information about the number of items 
 * and the view to display for each item.
 */
@protocol NSScrubberDataSource <NSObject>

@required
/**
 * Returns the number of items in the scrubber.
 * scrubber is the scrubber requesting this information.
 * Returns the number of items to display.
 */
- (NSInteger) numberOfItemsForScrubber: (NSScrubber *)scrubber;

/**
 * Returns the view to display at the specified index.
 * scrubber is the scrubber requesting the view.
 * index is the index of the item.
 * Returns the view to display for the item at the given index.
 */
- (NSScrubberItemView *) scrubber: (NSScrubber *)scrubber 
                     viewForItemAt: (NSInteger)index;

@end

/**
 * Protocol defining delegate methods for NSScrubber.
 * The delegate receives notifications about user interactions and state changes.
 */
@protocol NSScrubberDelegate <NSObject>

@optional
/**
 * Called when the user selects an item in the scrubber.
 * scrubber is the scrubber in which the selection occurred.
 * selectedIndex is the index of the selected item.
 */
- (void) scrubber: (NSScrubber *)scrubber 
    didSelectItemAt: (NSInteger)selectedIndex;

/**
 * Called when the user highlights an item in the scrubber.
 * scrubber is the scrubber in which the highlighting occurred.
 * highlightedIndex is the index of the highlighted item.
 */
- (void) scrubber: (NSScrubber *)scrubber 
didHighlightItemAt: (NSInteger)highlightedIndex;

/**
 * Called when the user begins interacting with the scrubber.
 * scrubber is the scrubber with which interaction began.
 */
- (void) didBeginInteractingWithScrubber: (NSScrubber *)scrubber;

/**
 * Called when the user finishes interacting with the scrubber.
 * scrubber is the scrubber with which interaction finished.
 */
- (void) didFinishInteractingWithScrubber: (NSScrubber *)scrubber;

/**
 * Called when the user cancels interaction with the scrubber.
 * scrubber is the scrubber with which interaction was cancelled.
 */
- (void) didCancelInteractingWithScrubber: (NSScrubber *)scrubber;

@end

/**
 * NSScrubber is a horizontal scrolling list control for displaying a set of items 
 * in the Touch Bar or other interface elements. It provides smooth scrolling and 
 * selection capabilities for navigating through collections of items.
 */
APPKIT_EXPORT_CLASS
@interface NSScrubber : NSView

// MARK: - Initialization

/**
 * Initializes a scrubber with the specified frame.
 * frameRect is the frame rectangle for the scrubber.
 * Returns an initialized scrubber object.
 */
- (id) initWithFrame: (NSRect)frameRect;

// MARK: - Data Source and Delegate

/**
 * Returns the object that acts as the data source of the scrubber.
 */
- (id<NSScrubberDataSource>) dataSource;

/**
 * Sets the object that acts as the data source of the scrubber.
 * dataSource is the data source object.
 */
- (void) setDataSource: (id<NSScrubberDataSource>)dataSource;

/**
 * Returns the object that acts as the delegate of the scrubber.
 */
- (id<NSScrubberDelegate>) delegate;

/**
 * Sets the object that acts as the delegate of the scrubber.
 * delegate is the delegate object.
 */
- (void) setDelegate: (id<NSScrubberDelegate>)delegate;

// MARK: - Layout and Appearance

/**
 * Returns the layout object used to arrange items in the scrubber.
 */
- (NSScrubberLayout *) scrubberLayout;

/**
 * Sets the layout object used to arrange items in the scrubber.
 * scrubberLayout is the layout object.
 */
- (void) setScrubberLayout: (NSScrubberLayout *)scrubberLayout;

/**
 * Returns the background color of the scrubber.
 */
- (NSColor *) backgroundColor;

/**
 * Sets the background color of the scrubber.
 * backgroundColor is the background color.
 */
- (void) setBackgroundColor: (NSColor *)backgroundColor;

/**
 * Returns the background view displayed behind the scrubber items.
 */
- (NSView *) backgroundView;

/**
 * Sets the background view displayed behind the scrubber items.
 * backgroundView is the background view.
 */
- (void) setBackgroundView: (NSView *)backgroundView;

/**
 * Returns the alignment of items within the scrubber.
 */
- (NSScrubberAlignment) itemAlignment;

/**
 * Sets the alignment of items within the scrubber.
 * itemAlignment is the alignment value.
 */
- (void) setItemAlignment: (NSScrubberAlignment)itemAlignment;

// MARK: - Selection and Highlighting

/**
 * Returns the index of the currently selected item, or NSNotFound if no item is selected.
 */
- (NSInteger) selectedIndex;

/**
 * Sets the index of the currently selected item.
 * selectedIndex is the index to select, or NSNotFound for no selection.
 */
- (void) setSelectedIndex: (NSInteger)selectedIndex;

/**
 * Returns the index of the currently highlighted item, or NSNotFound if no item is highlighted.
 */
- (NSInteger) highlightedIndex;

/**
 * Sets the index of the currently highlighted item.
 * highlightedIndex is the index to highlight, or NSNotFound for no highlighting.
 */
- (void) setHighlightedIndex: (NSInteger)highlightedIndex;

/**
 * Returns the selection background style for selected items.
 */
- (NSView *) selectionBackgroundStyle;

/**
 * Sets the selection background style for selected items.
 * selectionBackgroundStyle is the background style view.
 */
- (void) setSelectionBackgroundStyle: (NSView *)selectionBackgroundStyle;

/**
 * Returns the selection overlay style for selected items.
 */
- (NSView *) selectionOverlayStyle;

/**
 * Sets the selection overlay style for selected items.
 * selectionOverlayStyle is the overlay style view.
 */
- (void) setSelectionOverlayStyle: (NSView *)selectionOverlayStyle;

/**
 * Returns whether selection views float above items.
 */
- (BOOL) floatsSelectionViews;

/**
 * Sets whether selection views float above items.
 * floatsSelectionViews is YES to float selection views, NO otherwise.
 */
- (void) setFloatsSelectionViews: (BOOL)floatsSelectionViews;

// MARK: - Behavior

/**
 * Returns the interaction mode of the scrubber.
 */
- (NSScrubberMode) mode;

/**
 * Sets the interaction mode of the scrubber.
 * mode is the interaction mode.
 */
- (void) setMode: (NSScrubberMode)mode;

/**
 * Returns whether the scrubber sends actions continuously.
 */
- (BOOL) continuous;

/**
 * Sets whether the scrubber sends actions continuously.
 * continuous is YES to send actions continuously, NO otherwise.
 */
- (void) setContinuous: (BOOL)continuous;

/**
 * Returns whether arrow buttons are shown at the edges.
 */
- (BOOL) showsArrowButtons;

/**
 * Sets whether arrow buttons are shown at the edges.
 * showsArrowButtons is YES to show arrow buttons, NO otherwise.
 */
- (void) setShowsArrowButtons: (BOOL)showsArrowButtons;

/**
 * Returns whether additional content indicators are shown.
 */
- (BOOL) showsAdditionalContentIndicators;

/**
 * Sets whether additional content indicators are shown.
 * showsAdditionalContentIndicators is YES to show indicators, NO otherwise.
 */
- (void) setShowsAdditionalContentIndicators: (BOOL)showsAdditionalContentIndicators;

// MARK: - Item Management

/**
 * Returns the total number of items in the scrubber.
 */
- (NSInteger) numberOfItems;

/**
 * Reloads all data in the scrubber.
 */
- (void) reloadData;

/**
 * Reloads the items at the specified indexes.
 * indexes specifies the indexes of the items to reload.
 */
- (void) reloadItemsAtIndexes: (NSIndexSet *)indexes;

/**
 * Inserts new items at the specified indexes.
 * indexes specifies the indexes at which to insert items.
 */
- (void) insertItemsAtIndexes: (NSIndexSet *)indexes;

/**
 * Removes items at the specified indexes.
 * indexes specifies the indexes of the items to remove.
 */
- (void) removeItemsAtIndexes: (NSIndexSet *)indexes;

/**
 * Moves an item from one index to another.
 * fromIndex is the current index of the item.
 * toIndex is the destination index for the item.
 */
- (void) moveItemAtIndex: (NSInteger)fromIndex 
                 toIndex: (NSInteger)toIndex;

// MARK: - Item Views and Registration

/**
 * Returns the item view for the item at the specified index.
 * index is the index of the item.
 * Returns the item view, or nil if the item is not visible.
 */
- (NSScrubberItemView *) itemViewForItemAtIndex: (NSInteger)index;

/**
 * Registers a class to use when creating new item views.
 * itemViewClass is the class to register.
 * identifier is the reuse identifier for the class.
 */
- (void) registerClass: (Class)itemViewClass 
     forItemIdentifier: (NSString *)identifier;

/**
 * Registers a nib to use when creating new item views.
 * nib is the nib to register.
 * identifier is the reuse identifier for the nib.
 */
- (void) registerNib: (NSNib *)nib 
   forItemIdentifier: (NSString *)identifier;

/**
 * Returns a reusable item view located by its identifier.
 * identifier is the reuse identifier.
 * owner is the owner object for loading the nib.
 * Returns a reusable item view or a newly created one.
 */
- (NSScrubberItemView *) makeItemWithIdentifier: (NSString *)identifier 
                                          owner: (id)owner;

// MARK: - Scrolling

/**
 * Scrolls the scrubber to make the item at the specified index visible.
 * index is the index of the item to scroll to.
 * alignment is the alignment for positioning the item.
 */
- (void) scrollItemAtIndex: (NSInteger)index 
              toAlignment: (NSScrubberAlignment)alignment;

// MARK: - Batch Updates

/**
 * Performs a batch of updates to the scrubber in sequence.
 * updates is a block containing the updates to perform.
 */
- (void) performSequentialBatchUpdates: (void (^)(void))updates;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSScrubber_h_GNUSTEP_GUI_INCLUDE */

