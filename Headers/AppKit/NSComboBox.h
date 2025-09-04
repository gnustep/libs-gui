/*
   NSComboBox.h

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

#ifndef _GNUstep_H_NSComboBox
#define _GNUstep_H_NSComboBox
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSTextField.h>

@class NSArray;
@class NSString;
@class NSNotification;

/**
 * <title>NSComboBox</title>
 * <abstract>Text field with dropdown list for selection and entry</abstract>
 * NSComboBox combines a text field with a dropdown list, providing users with
 * both direct text entry and selection from predefined options. It extends
 * NSTextField to add list management, selection handling, and dropdown display
 * capabilities.
 *
 * Key features include:
 * * Dual input modes: direct text entry and dropdown selection
 * * Two data management approaches: internal item storage or external data source
 * * Customizable dropdown appearance with scrolling and sizing options
 * * Text completion for enhanced user experience
 * * Rich selection and navigation API
 * * Delegate notifications for popup and selection events
 * * Full integration with Interface Builder and archiving
 * * Support for bordered and borderless button styles
 *
 * Data Management:
 * NSComboBox supports two data management modes controlled by the usesDataSource
 * property. When NO (default), items are managed internally using methods like
 * addItemWithObjectValue: and removeItemAtIndex:. When YES, data is provided
 * through an external data source implementing NSComboBoxDataSource protocol.
 *
 * The dropdown list can be customized with intercell spacing, item height,
 * number of visible items, and optional vertical scrolling. Text completion
 * can be enabled to automatically complete user input based on available items.
 *
 * Selection and navigation methods allow programmatic control over the dropdown
 * state, including scrolling items into view and managing selection state.
 * Delegate methods provide notifications for popup display and selection changes.
 *
 * Visual appearance includes customizable button borders and standard text field
 * styling inherited from the NSTextField superclass.
 */
APPKIT_EXPORT_CLASS
@interface NSComboBox : NSTextField
{
}

/**
 * Returns whether the dropdown list displays a vertical scroller.
 * Returns: YES if a vertical scroller is shown, NO otherwise
 */
- (BOOL) hasVerticalScroller;

/**
 * Sets whether the dropdown list should display a vertical scroller.
 * flag: YES to show a vertical scroller, NO to hide it
 */
- (void) setHasVerticalScroller: (BOOL)flag;

/**
 * Returns the spacing between cells in the dropdown list.
 * Returns: An NSSize specifying the horizontal and vertical intercell spacing
 */
- (NSSize) intercellSpacing;

/**
 * Sets the spacing between cells in the dropdown list.
 * aSize: An NSSize specifying the horizontal and vertical intercell spacing
 */
- (void) setIntercellSpacing: (NSSize)aSize;

/**
 * Returns the height of each item in the dropdown list.
 * Returns: The height in points for dropdown list items
 */
- (CGFloat) itemHeight;

/**
 * Sets the height of each item in the dropdown list.
 * itemHeight: The height in points for dropdown list items
 */
- (void) setItemHeight: (CGFloat)itemHeight;

/**
 * Returns the number of items visible in the dropdown without scrolling.
 * Returns: The number of items shown in the dropdown list
 */
- (NSInteger) numberOfVisibleItems;

/**
 * Sets the number of items visible in the dropdown without scrolling.
 * visibleItems: The number of items to show in the dropdown list
 */
- (void) setNumberOfVisibleItems: (NSInteger)visibleItems;

/**
 * Reloads the dropdown list data from the data source.
 */
- (void) reloadData;

/**
 * Notifies the combo box that the number of items has changed.
 */
- (void) noteNumberOfItemsChanged;

/**
 * Returns whether the combo box uses an external data source.
 * Returns: YES if using a data source, NO if managing items internally
 */
- (BOOL) usesDataSource;

/**
 * Sets whether the combo box should use an external data source.
 * flag: YES to use a data source, NO to manage items internally
 */
- (void) setUsesDataSource: (BOOL)flag;

/**
 * Scrolls the dropdown list to position the specified item at the top.
 * index: The index of the item to scroll to the top of the visible area
 */
- (void) scrollItemAtIndexToTop: (NSInteger)index;

/**
 * Scrolls the dropdown list to make the specified item visible.
 * index: The index of the item to make visible in the dropdown
 */
- (void) scrollItemAtIndexToVisible: (NSInteger)index;

/**
 * Selects the item at the specified index in the dropdown list.
 * index: The index of the item to select
 */
- (void) selectItemAtIndex: (NSInteger)index;

/**
 * Deselects the item at the specified index in the dropdown list.
 * index: The index of the item to deselect
 */
- (void) deselectItemAtIndex: (NSInteger)index;

/**
 * Returns the index of the currently selected item.
 * Returns: The index of the selected item, or -1 if no item is selected
 */
- (NSInteger) indexOfSelectedItem;

/**
 * Returns the total number of items in the combo box.
 * Returns: The count of items available for selection
 */
- (NSInteger) numberOfItems;

/* These two methods can only be used when usesDataSource is YES */

/**
 * Returns the data source object providing items to the combo box.
 * Returns: The data source object, or nil if none is set
 */
- (id) dataSource;

/**
 * Sets the data source object to provide items to the combo box.
 * aSource: The data source object implementing NSComboBoxDataSource protocol
 */
- (void) setDataSource: (id)aSource;

/* These methods can only be used when usesDataSource is NO */

/**
 * Adds an item to the end of the dropdown list.
 * object: The object value to add to the list
 */
- (void) addItemWithObjectValue: (id)object;

/**
 * Adds multiple items to the end of the dropdown list.
 * objects: An array of object values to add to the list
 */
- (void) addItemsWithObjectValues: (NSArray *)objects;

/**
 * Inserts an item at the specified index in the dropdown list.
 * object: The object value to insert
 * index: The index at which to insert the item
 */
- (void) insertItemWithObjectValue: (id)object atIndex:(NSInteger)index;

/**
 * Removes the first occurrence of the specified object from the list.
 * object: The object value to remove from the list
 */
- (void) removeItemWithObjectValue: (id)object;

/**
 * Removes the item at the specified index from the dropdown list.
 * index: The index of the item to remove
 */
- (void) removeItemAtIndex: (NSInteger)index;

/**
 * Removes all items from the dropdown list.
 */
- (void) removeAllItems;

/**
 * Selects the first item in the list that matches the specified object.
 * object: The object value to select in the list
 */
- (void) selectItemWithObjectValue: (id)object;

/**
 * Returns the object value at the specified index.
 * index: The index of the desired item
 * Returns: The object value at the specified index
 */
- (id) itemObjectValueAtIndex: (NSInteger)index;

/**
 * Returns the object value of the currently selected item.
 * Returns: The object value of the selected item, or nil if none selected
 */
- (id) objectValueOfSelectedItem;

/**
 * Returns the index of the first item matching the specified object.
 * object: The object value to search for
 * Returns: The index of the matching item, or -1 if not found
 */
- (NSInteger) indexOfItemWithObjectValue: (id)object;

/**
 * Returns an array containing all object values in the dropdown list.
 * Returns: An NSArray of all object values in the list
 */
- (NSArray *) objectValues;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/* text completion */

/**
 * Sets whether the combo box performs automatic text completion.
 * completes: YES to enable text completion, NO to disable
 */
- (void) setCompletes: (BOOL)completes;

/**
 * Returns whether the combo box performs automatic text completion.
 * Returns: YES if text completion is enabled, NO otherwise
 */
- (BOOL) completes;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Returns whether the dropdown button displays a border.
 * Returns: YES if the button has a border, NO otherwise
 */
- (BOOL) isButtonBordered;

/**
 * Sets whether the dropdown button should display a border.
 * flag: YES to show a border on the button, NO for borderless appearance
 */
- (void) setButtonBordered:(BOOL)flag;
#endif
@end

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
@protocol NSComboBoxDataSource <NSObject>
#if GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#endif
#else
/** <ignore> */
@interface NSObject (NSComboBoxDataSource)
/** </ignore> */
#endif
/**
 * Returns the number of items available in the combo box.
 * aComboBox: The combo box requesting the item count
 * Returns: The total number of items available for selection
 */
- (NSInteger) numberOfItemsInComboBox: (NSComboBox *)aComboBox;

/**
 * Returns the object value for the item at the specified index.
 * aComboBox: The combo box requesting the object value
 * index: The index of the requested item
 * Returns: The object value for the item at the specified index
 */
- (id) comboBox: (NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index;

/**
 * Returns the index of the item with the specified string value.
 * aComboBox: The combo box requesting the index
 * string: The string value to search for
 * Returns: The index of the item matching the string, or NSNotFound if not found
 */
- (NSUInteger) comboBox: (NSComboBox *)aComboBox
  indexOfItemWithStringValue: (NSString *)string;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/* text completion */

/**
 * Returns a completed string based on the partial input string.
 * aComboBox: The combo box requesting the completion
 * aString: The partial string to complete
 * Returns: A completed string, or nil if no completion is available
 */
- (NSString *) comboBox: (NSComboBox *)aComboBox
	completedString: (NSString *)aString;
#endif
@end

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
@protocol NSComboBoxDelegate <NSTextFieldDelegate>
#if GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#endif
#else
/** <ignore> */
@interface NSObject (NSComboBoxNotifications)
/** </ignore> */
#endif
/**
 * Called when the combo box dropdown is about to appear.
 * notification: The notification containing the combo box as the object
 */
- (void) comboBoxWillPopUp: (NSNotification *)notification;

/**
 * Called when the combo box dropdown is about to disappear.
 * notification: The notification containing the combo box as the object
 */
- (void) comboBoxWillDismiss: (NSNotification *)notification;

/**
 * Called when the combo box selection has changed.
 * notification: The notification containing the combo box as the object
 */
- (void) comboBoxSelectionDidChange: (NSNotification *)notification;

/**
 * Called when the combo box selection is in the process of changing.
 * notification: The notification containing the combo box as the object
 */
- (void) comboBoxSelectionIsChanging: (NSNotification *)notification;
@end

APPKIT_EXPORT	NSString *NSComboBoxWillPopUpNotification;
APPKIT_EXPORT	NSString *NSComboBoxWillDismissNotification;
APPKIT_EXPORT	NSString *NSComboBoxSelectionDidChangeNotification;
APPKIT_EXPORT	NSString *NSComboBoxSelectionIsChangingNotification;

#endif /* _GNUstep_H_NSComboBox */
