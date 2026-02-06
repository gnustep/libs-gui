/* -*-objc-*-
   NSCollectionViewItem.h

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

#ifndef _GNUstep_H_NSCollectionViewItem
#define _GNUstep_H_NSCollectionViewItem
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSArray.h>
#import <AppKit/NSViewController.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)

#if defined(__cplusplus)
extern "C" {
#endif

@class NSImageView, NSTextField;

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewItem serves as the controller for individual items
 * within a collection view. This class manages the view hierarchy and
 * state for a single collection item, providing outlets for common
 * UI elements like text fields and image views. It handles selection
 * state, drag and drop operations, and coordinates between the data
 * model and the visual presentation. Collection view items are typically
 * configured as prototypes and then copied for each displayed item.
 */
@interface NSCollectionViewItem : NSViewController <NSCopying>
{
  IBOutlet NSTextField *textField;
  IBOutlet NSImageView *imageView;
  BOOL _isSelected;
}

/**
 * Returns the collection view that contains this item. The collection
 * view manages the display and interaction of multiple collection view
 * items, handling layout, scrolling, and selection coordination. This
 * relationship allows the item to access collection-wide properties
 * and participate in collection-level operations when necessary.
 */
- (NSCollectionView *)collectionView;
/**
 * Returns an array of dragging image components that represent this
 * item during drag operations. These components define how the item
 * appears while being dragged, including image content, positioning,
 * and visual effects. The components allow for customized drag
 * representations that can differ from the item's normal appearance.
 */
- (NSArray *)draggingImageComponents;

/**
 * Sets the selection state of the collection view item. When selected,
 * the item typically changes its visual appearance to indicate its
 * chosen status to the user. The selection state affects how the item
 * renders itself and may trigger visual feedback such as highlighting,
 * color changes, or other selection indicators. This method coordinates
 * with the collection view's overall selection management.
 */
- (void)setSelected:(BOOL)shouldBeSelected;
/**
 * Returns whether the collection view item is currently selected. The
 * selection state determines the item's visual appearance and interaction
 * behavior within the collection view. Selected items typically display
 * distinct visual styling to indicate their status and may participate
 * differently in user interactions and operations.
 */
- (BOOL)isSelected;

/**
 * Returns the text field outlet that displays textual content for this
 * collection view item. The text field typically shows labels, titles,
 * or other textual information associated with the item's represented
 * object. This outlet provides a convenient way to access and configure
 * the primary text display component of the item's user interface.
 */
- (NSTextField *)textField;
/**
 * Sets the text field outlet for displaying textual content in this
 * collection view item. The text field becomes the primary text display
 * component and is typically configured to show information from the
 * item's represented object. Setting this outlet establishes the
 * connection between the item controller and its text display element.
 */
- (void)setTextField:(NSTextField *)aTextField;

/**
 * Returns the image view outlet that displays visual content for this
 * collection view item. The image view typically shows icons, thumbnails,
 * or other graphical information associated with the item's represented
 * object. This outlet provides convenient access to the primary image
 * display component of the item's user interface for configuration
 * and content updates.
 */
- (NSImageView *)imageView;
/**
 * Sets the image view outlet for displaying visual content in this
 * collection view item. The image view becomes the primary graphical
 * display component and is typically configured to show imagery from
 * the item's represented object. Setting this outlet establishes the
 * connection between the item controller and its image display element.
 */
- (void)setImageView:(NSImageView *)anImageView;

@end

#if defined(__cplusplus)
}
#endif

#endif /* OS_API_MACOSX */

#endif /* _GNUstep_H_NSCollectionViewItem */
