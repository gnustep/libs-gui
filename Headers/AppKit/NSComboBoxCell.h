/*
   NSComboBoxCell.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Gerrit van Dyk <gerritvd@decillion.net>
   Date: 1999

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
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSComboBoxCell
#define _GNUstep_H_NSComboBoxCell
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>
#import <AppKit/NSTextFieldCell.h>

@class NSButtonCell;
@class NSMutableArray;
@class NSArray;
@class NSString;

/**
 * <title>NSComboBoxCell</title>
 * <abstract>Cell class for combo box controls with dropdown list functionality</abstract>
 * NSComboBoxCell provides the core implementation for combo box functionality,
 * extending NSTextFieldCell to add dropdown list capabilities. It serves as the
 * cell component used by NSComboBox controls and can be used independently in
 * custom controls requiring combo box behavior.
 *
 * Key features include:
 * * Text input with dropdown selection capabilities
 * * Dual data management: internal item storage or external data source
 * * Customizable dropdown appearance and behavior
 * * Mouse tracking for dropdown interaction
 * * Text completion support for enhanced user experience
 * * Flexible selection and navigation API
 * * Full integration with the cell architecture
 *
 * Data Management:
 * Similar to NSComboBox, NSComboBoxCell supports two data management approaches.
 * When usesDataSource is NO, items are managed internally using methods like
 * addItemWithObjectValue: and removeItemAtIndex:. When YES, data is provided
 * through an external data source implementing the NSComboBoxCellDataSource protocol.
 *
 * The cell handles all aspects of dropdown display including scrolling behavior,
 * item height, intercell spacing, and the number of visible items. Mouse tracking
 * is implemented to handle dropdown interaction and item selection.
 *
 * Text completion can be enabled to provide automatic completion of user input
 * based on available items, improving the user experience for data entry tasks.
 *
 * Visual customization includes control over the dropdown button appearance,
 * including bordered and borderless styles. The cell integrates seamlessly
 * with the NSControl/NSCell architecture while providing specialized combo
 * box functionality.
 */
APPKIT_EXPORT_CLASS
@interface NSComboBoxCell : NSTextFieldCell
{
   id			_dataSource;
   NSButtonCell		*_buttonCell;
   NSMutableArray	*_popUpList;
   BOOL			_usesDataSource;
   BOOL			_hasVerticalScroller;
   BOOL                 _completes;
   NSInteger		_visibleItems;
   NSSize		_intercellSpacing;
   float		_itemHeight;
   NSInteger            _selectedItem;
   NSRect               _lastValidFrame;
   NSRange		_prevSelectedRange;

@private
   id		        _popup;
}

/**
 * Returns whether the dropdown list displays a vertical scroller.
 * Returns: YES if a vertical scroller is shown, NO otherwise
 */
- (BOOL)hasVerticalScroller;

/**
 * Sets whether the dropdown list should display a vertical scroller.
 * flag: YES to show a vertical scroller, NO to hide it
 */
- (void)setHasVerticalScroller:(BOOL)flag;

/**
 * Returns the spacing between cells in the dropdown list.
 * Returns: An NSSize specifying the horizontal and vertical intercell spacing
 */
- (NSSize)intercellSpacing;

/**
 * Sets the spacing between cells in the dropdown list.
 * aSize: An NSSize specifying the horizontal and vertical intercell spacing
 */
- (void)setIntercellSpacing:(NSSize)aSize;

/**
 * Returns the height of each item in the dropdown list.
 * Returns: The height in points for dropdown list items
 */
- (CGFloat)itemHeight;

/**
 * Sets the height of each item in the dropdown list.
 * itemHeight: The height in points for dropdown list items
 */
- (void)setItemHeight:(CGFloat)itemHeight;

/**
 * Returns the number of items visible in the dropdown without scrolling.
 * Returns: The number of items shown in the dropdown list
 */
- (NSInteger)numberOfVisibleItems;

/**
 * Sets the number of items visible in the dropdown without scrolling.
 * visibleItems: The number of items to show in the dropdown list
 */
- (void)setNumberOfVisibleItems:(NSInteger)visibleItems;

/**
 * Reloads the dropdown list data from the data source.
 */
- (void)reloadData;

/**
 * Notifies the combo box cell that the number of items has changed.
 */
- (void)noteNumberOfItemsChanged;

/**
 * Returns whether the combo box cell uses an external data source.
 * Returns: YES if using a data source, NO if managing items internally
 */
- (BOOL)usesDataSource;

/**
 * Sets whether the combo box cell should use an external data source.
 * flag: YES to use a data source, NO to manage items internally
 */
- (void)setUsesDataSource:(BOOL)flag;

/**
 * Scrolls the dropdown list to position the specified item at the top.
 * index: The index of the item to scroll to the top of the visible area
 */
- (void)scrollItemAtIndexToTop:(NSInteger)index;

/**
 * Scrolls the dropdown list to make the specified item visible.
 * index: The index of the item to make visible in the dropdown
 */
- (void)scrollItemAtIndexToVisible:(NSInteger)index;

/**
 * Selects the item at the specified index in the dropdown list.
 * index: The index of the item to select
 */
- (void)selectItemAtIndex:(NSInteger)index;

/**
 * Deselects the item at the specified index in the dropdown list.
 * index: The index of the item to deselect
 */
- (void)deselectItemAtIndex:(NSInteger)index;

/**
 * Returns the index of the currently selected item.
 * Returns: The index of the selected item, or -1 if no item is selected
 */
- (NSInteger)indexOfSelectedItem;

/**
 * Returns the total number of items in the combo box cell.
 * Returns: The count of items available for selection
 */
- (NSInteger)numberOfItems;

/* These two methods can only be used when usesDataSource is YES */

/**
 * Returns the data source object providing items to the combo box cell.
 * Returns: The data source object, or nil if none is set
 */
- (id)dataSource;

/**
 * Sets the data source object to provide items to the combo box cell.
 * aSource: The data source object implementing NSComboBoxCellDataSource protocol
 */
- (void)setDataSource:(id)aSource;

/* These methods can only be used when usesDataSource is NO */

/**
 * Adds an item to the end of the dropdown list.
 * object: The object value to add to the list
 */
- (void)addItemWithObjectValue:(id)object;

/**
 * Adds multiple items to the end of the dropdown list.
 * objects: An array of object values to add to the list
 */
- (void)addItemsWithObjectValues:(NSArray *)objects;

/**
 * Inserts an item at the specified index in the dropdown list.
 * object: The object value to insert
 * index: The index at which to insert the item
 */
- (void)insertItemWithObjectValue:(id)object atIndex:(NSInteger)index;

/**
 * Removes the first occurrence of the specified object from the list.
 * object: The object value to remove from the list
 */
- (void)removeItemWithObjectValue:(id)object;

/**
 * Removes the item at the specified index from the dropdown list.
 * index: The index of the item to remove
 */
- (void)removeItemAtIndex:(NSInteger)index;

/**
 * Removes all items from the dropdown list.
 */
- (void)removeAllItems;

/**
 * Selects the first item in the list that matches the specified object.
 * object: The object value to select in the list
 */
- (void)selectItemWithObjectValue:(id)object;

/**
 * Returns the object value at the specified index.
 * index: The index of the desired item
 * Returns: The object value at the specified index
 */
- (id)itemObjectValueAtIndex:(NSInteger)index;

/**
 * Returns the object value of the currently selected item.
 * Returns: The object value of the selected item, or nil if none selected
 */
- (id)objectValueOfSelectedItem;

/**
 * Returns the index of the first item matching the specified object.
 * object: The object value to search for
 * Returns: The index of the matching item, or -1 if not found
 */
- (NSInteger)indexOfItemWithObjectValue:(id)object;

/**
 * Returns an array containing all object values in the dropdown list.
 * Returns: An NSArray of all object values in the list
 */
- (NSArray *)objectValues;

/**
 * Tracks mouse events for the combo box cell.
 * theEvent: The mouse event to track
 * inRect: The rectangle in which to track
 * ofView: The view containing the cell
 * untilMouseUp: YES to track until mouse up, NO otherwise
 * Returns: YES if the mouse tracking was successful
 */
- (BOOL) trackMouse: (NSEvent *)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView *)controlView
       untilMouseUp: (BOOL)untilMouseUp;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/* text completion */
/**
 * Returns a completed string based on the substring.
 * substring: The partial string to complete
 * Returns: The completed string, or the original if no completion found
 */
- (NSString *)completedString:(NSString *)substring;

/**
 * Sets whether the combo box cell automatically completes text.
 * completes: YES to enable automatic text completion, NO to disable
 */
- (void)setCompletes:(BOOL)completes;

/**
 * Returns whether the combo box cell automatically completes text.
 * Returns: YES if automatic text completion is enabled, NO otherwise
 */
- (BOOL)completes;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Returns whether the combo box button has a border.
 * Returns: YES if the button is bordered, NO otherwise
 */
- (BOOL) isButtonBordered;

/**
 * Sets whether the combo box button has a border.
 * flag: YES to draw a border around the button, NO to remove it
 */
- (void) setButtonBordered:(BOOL)flag;
#endif
@end

/**
 * <title>NSComboBoxCellDataSource Protocol</title>
 * <abstract>Data source protocol for NSComboBoxCell</abstract>
 * This protocol defines methods that a data source must implement
 * to provide data for a combo box cell when using external data management.
 */
@protocol NSComboBoxCellDataSource <NSObject>
#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST) && GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#else
@end
@interface NSObject (NSComboBoxCellDataSource)
#endif

/**
 * Returns the total number of items in the combo box.
 * comboBoxCell: The combo box cell requesting the count
 * Returns: The number of items available from the data source
 */
- (NSInteger)numberOfItemsInComboBoxCell:(NSComboBoxCell *)comboBoxCell;

/**
 * Returns the object value for the item at the specified index.
 * aComboBoxCell: The combo box cell requesting the data
 * index: The index of the requested item
 * Returns: The object value at the specified index
 */
- (id)comboBoxCell:(NSComboBoxCell *)aComboBoxCell
  objectValueForItemAtIndex:(NSInteger)index;

/**
 * Returns the index of the first item that matches the given string.
 * aComboBoxCell: The combo box cell performing the search
 * string: The string value to search for
 * Returns: The index of the first matching item, or NSNotFound if none found
 */
- (NSUInteger)comboBoxCell:(NSComboBoxCell *)aComboBoxCell
  indexOfItemWithStringValue:(NSString *)string;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/* text completion */
/**
 * Returns a completed string based on the partial input.
 * aComboBoxCell: The combo box cell requesting completion
 * uncompletedString: The partial string to complete
 * Returns: The completed string, or the original if no completion found
 */
- (NSString *)comboBoxCell:(NSComboBoxCell *)aComboBoxCell
	   completedString:(NSString *)uncompletedString;
#endif
@end

#endif /* _GNUstep_H_NSComboBoxCell */
