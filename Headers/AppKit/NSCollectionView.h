/* -*-objc-*-
   NSCollectionView.h

   Copyright (C) 2013,2021 Free Software Foundation, Inc.

   Author: Doug Simons (doug.simons@testplant.com)
           Frank LeGrand (frank.legrand@testplant.com)
           Gregory Casamento (greg.casamento@gmail.com)
           (Adding new delegate methods and support for layouts)

   Date: February 2013, December 2021

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

#ifndef _GNUstep_H_NSCollectionView
#define _GNUstep_H_NSCollectionView
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSDragging.h>
#import <AppKit/NSNibDeclarations.h>
#import <AppKit/NSView.h>
#import <AppKit/NSUserInterfaceItemIdentification.h>

@class NSCollectionViewItem;
@class NSCollectionView;
@class NSCollectionViewLayout;
@class NSCollectionViewLayoutAttributes;
@class NSCollectionViewTransitionLayout;
@class NSPasteboard;
@class NSNib;
@class NSMapTable;
@class NSMutableDictionary;
@class NSMutableSet;

@protocol NSPasteboardWriting;

enum
{
  NSCollectionViewDropOn = 0,
  NSCollectionViewDropBefore = 1,
};
typedef NSInteger NSCollectionViewDropOperation;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
enum {
  NSCollectionViewItemHighlightNone = 0,
  NSCollectionViewItemHighlightForSelection = 1,
  NSCollectionViewItemHighlightForDeselection = 2,
  NSCollectionViewItemHighlightAsDropTarget = 3,
};
typedef NSInteger NSCollectionViewItemHighlightState;

enum {
  NSCollectionViewScrollPositionNone                 = 0,

  /*
   * Vertical positions are mutually exclusive to each other, but are bitwise or-able with
   * the horizontal scroll positions.  Combining positions from the same grouping
   * (horizontal or vertical) will result in an NSInvalidArgumentException.
   */
  NSCollectionViewScrollPositionTop                   = 1 << 0,
  NSCollectionViewScrollPositionCenteredVertically    = 1 << 1,
  NSCollectionViewScrollPositionBottom                = 1 << 2,
  NSCollectionViewScrollPositionNearestHorizontalEdge = 1 << 9, /* Nearer of Top,Bottom */

  /*
   * Likewise, the horizontal positions are mutually exclusive to each other.
   */
  NSCollectionViewScrollPositionLeft                 = 1 << 3,
  NSCollectionViewScrollPositionCenteredHorizontally = 1 << 4,
  NSCollectionViewScrollPositionRight                = 1 << 5,
  NSCollectionViewScrollPositionLeadingEdge          = 1 << 6, /* Left if LTR, Right if RTL */
  NSCollectionViewScrollPositionTrailingEdge         = 1 << 7, /* Right if LTR, Left, if RTL */
  NSCollectionViewScrollPositionNearestVerticalEdge  = 1 << 8, /* Nearer of Leading,Trailing */
};
typedef NSUInteger NSCollectionViewScrollPosition;

#endif

typedef NSString *NSCollectionViewSupplementaryElementKind;
typedef NSString *NSUserInterfaceItemIdentifier;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
@protocol NSCollectionViewElement <NSObject, NSUserInterfaceItemIdentification>
#if GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#endif

- (void) prepareForReuse;

- (void) applyLayoutAttributes: (NSCollectionViewLayoutAttributes *)layoutAttributes;

- (void) willTransitionFromLayout: (NSCollectionViewLayout *)oldLayout toLayout: (NSCollectionViewLayout *)newLayout;

- (void) didTransitionFromLayout: (NSCollectionViewLayout *)oldLayout toLayout: (NSCollectionViewLayout *)newLayout;

- (NSCollectionViewLayoutAttributes *) preferredLayoutAttributesFittingAttributes: (NSCollectionViewLayoutAttributes *)layoutAttributes;
@end
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
@protocol NSCollectionViewDataSource <NSObject>
#if GS_PROTOCOLS_HAVE_OPTIONAL
@required
#endif
- (NSInteger) collectionView: (NSCollectionView *)collectionView
      numberOfItemsInSection: (NSInteger)section;

- (NSCollectionViewItem *) collectionView: (NSCollectionView *)collectionView
      itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath;
#if GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#endif
- (NSInteger) numberOfSectionsInCollectionView: (NSCollectionView *)collectionView;

- (NSView *) collectionView: (NSCollectionView *)collectionView
             viewForSupplementaryElementOfKind: (NSCollectionViewSupplementaryElementKind)kind
                atIndexPath: (NSIndexPath *)indexPath;
@end
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
@protocol NSCollectionViewPrefetching <NSObject>
#if GS_PROTOCOLS_HAVE_OPTIONAL
@required
#endif
/**
 * Load the items listed in indexPaths in collectionView before they are displayed
 */
- (void)collectionView: (NSCollectionView *)collectionView prefetchItemsAtIndexPaths: (NSArray *)indexPaths;
#if GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#endif
/**
 * Cancel the prefetch request for the listed indexPaths.
 */
- (void)collectionView: (NSCollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths: (NSArray *)indexPaths;
@end
#endif

@protocol NSCollectionViewDelegate <NSObject>

#if GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Return a boolean indicating if the indexPaths on collectionView can be dragged with the passed in event.
 */
- (BOOL) collectionView: (NSCollectionView *)collectionView
         canDragItemsAtIndexPaths: (NSSet *)indexPaths
              withEvent: (NSEvent *)event;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Return a boolean indicating if the indexes on collectionView can be dragged with the passed in event.
 */
- (BOOL) collectionView: (NSCollectionView *)collectionView
  canDragItemsAtIndexes: (NSIndexSet *)indexes
              withEvent: (NSEvent *)event;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Return a boolean if the items at indexPaths can be written to the pasteboard
 */
- (BOOL) collectionView: (NSCollectionView *)collectionView
         writeItemsAtIndexPaths: (NSSet *)indexPaths
           toPasteboard: (NSPasteboard *)pasteboard;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Return a boolean if the items at indexes can be written to the pasteboard
 */
- (BOOL) collectionView: (NSCollectionView *)collectionView
    writeItemsAtIndexes: (NSIndexSet *)indexes
           toPasteboard: (NSPasteboard *)pasteboard;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Returns an array of filenames for files at indexPaths that will be dropped at the destination specified by NSURL.
 */
- (NSArray *) collectionView: (NSCollectionView *)collectionView
              namesOfPromisedFilesDroppedAtDestination: (NSURL *)dropURL
 forDraggedItemsAtIndexPaths: (NSSet *)indexPaths;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Returns an array of filenames for files at indexes that will be dropped at the destination specified by NSURL.
 */
- (NSArray *) collectionView: (NSCollectionView *)collectionView
              namesOfPromisedFilesDroppedAtDestination: (NSURL *)dropURL
    forDraggedItemsAtIndexes: (NSIndexSet *)indexes;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Returns an NSImage representing the items at indexPaths which are being dragged.
 */
- (NSImage *) collectionView: (NSCollectionView *)collectionView
              draggingImageForItemsAtIndexPaths: (NSSet *)indexPaths
                   withEvent: (NSEvent *)event
                      offset: (NSPointPointer)dragImageOffset;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Returns an NSImage representing the items at indexes which are being dragged.
 */
- (NSImage *) collectionView: (NSCollectionView *)collectionView
              draggingImageForItemsAtIndexes: (NSIndexSet *)indexes
                   withEvent: (NSEvent *)event
                      offset: (NSPointPointer)dragImageOffset;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Return NSDragOperation when performing drag and drop on collectionView at proposedDropIndexPath.
 */
- (NSDragOperation) collectionView: (NSCollectionView *)collectionView
                      validateDrop: (id < NSDraggingInfo >)draggingInfo
                 proposedIndexPath: (NSIndexPath **)proposedDropIndexPath
                     dropOperation: (NSCollectionViewDropOperation *)proposedDropOperation;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Return NSDragOperation when performing drag and drop on collectionView at proposedIndex.
 */
- (NSDragOperation) collectionView: (NSCollectionView *)collectionView
                      validateDrop: (id < NSDraggingInfo >)draggingInfo
                     proposedIndex: (NSInteger *)proposedDropIndex
                     dropOperation: (NSCollectionViewDropOperation *)proposedDropOperation;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Returns a BOOL to indicate if the drop at indexPath was accepted
 */
- (BOOL) collectionView: (NSCollectionView *)collectionView
             acceptDrop: (id < NSDraggingInfo >)draggingInfo
              indexPath: (NSIndexPath *)indexPath
          dropOperation: (NSCollectionViewDropOperation)dropOperation;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Returns a BOOL to indicate if the drop at index was accepted
 */
- (BOOL) collectionView: (NSCollectionView *)collectionView
             acceptDrop: (id < NSDraggingInfo >)draggingInfo
                  index: (NSInteger)index
          dropOperation: (NSCollectionViewDropOperation)dropOperation;
#endif

/* Multi-image drag and drop */

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Return NSPasteboardWriting object for collectionView at indexPath
 */
- (id <NSPasteboardWriting>) collectionView: (NSCollectionView *)collectionView
         pasteboardWriterForItemAtIndexPath: (NSIndexPath *)indexPath;
#endif

/**
 * Return NSPasteboardWriting object for collectionView at index
 */
- (id <NSPasteboardWriting>) collectionView: (NSCollectionView *)collectionView
             pasteboardWriterForItemAtIndex: (NSUInteger)index;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Allows application to specify the screenPoint at which a dragging session will begin
 * for the given indexPaths
 */
- (void) collectionView: (NSCollectionView *)collectionView
        draggingSession: (NSDraggingSession *)session
       willBeginAtPoint: (NSPoint)screenPoint
   forItemsAtIndexPaths: (NSSet *)indexPaths;
#endif

/**
 * Allows application to specify the screenPoint at which a dragging session will begin
 * for the given indexes
 */
- (void) collectionView: (NSCollectionView *)collectionView
        draggingSession: (NSDraggingSession *)session
       willBeginAtPoint: (NSPoint)screenPoint
      forItemsAtIndexes: (NSIndexSet *)indexes;

/**
 * Allows application to specify the screenPoint at which a dragging session did end
 */
- (void) collectionView: (NSCollectionView *)collectionView
        draggingSession: (NSDraggingSession *)session
           endedAtPoint: (NSPoint)screenPoint
          dragOperation: (NSDragOperation)operation;
/**
 * Update items include in the drag operation for collectionView.
 */
- (void) collectionView: (NSCollectionView *)collectionView
         updateDraggingItemsForDrag: (id <NSDraggingInfo>)draggingInfo;

/* Selection and Highlighting */

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Returns the set of indexPaths that should change their selection.  This is sent to inform the delegate of
 * those items that the collectionView would like to change to highlightState.
 */
- (NSSet *) collectionView: (NSCollectionView *)collectionView
            shouldChangeItemsAtIndexPaths: (NSSet *)indexPaths
          toHighlightState: (NSCollectionViewItemHighlightState)highlightState;

/**
 * This is sent to inform the delegate of those items that did change highlightState.
 */
- (void) collectionView: (NSCollectionView *)collectionView
         didChangeItemsAtIndexPaths: (NSSet *)indexPaths
       toHighlightState: (NSCollectionViewItemHighlightState)highlightState;

/**
 * Returns the set of indexPaths that should change.
 */
- (NSSet *) collectionView: (NSCollectionView *)collectionView
shouldSelectItemsAtIndexPaths: (NSSet *)indexPaths;

/**
 * Returns the set of NSIndexPath objects that should be deselected given the proposed indexPaths.
 */
- (NSSet *) collectionView: (NSCollectionView *)collectionView shouldDeselectItemsAtIndexPaths: (NSSet *)indexPaths;

/**
 * Called to inform the delegate of those items that were selected.
 */
- (void) collectionView: (NSCollectionView *)collectionView didSelectItemsAtIndexPaths: (NSSet *)indexPaths;

/**
 * Called to inform the delegate of those items that were deselected.
 */
- (void) collectionView: (NSCollectionView *)collectionView didDeselectItemsAtIndexPaths: (NSSet *)indexPaths;

/* Display Notification */

/**
 * Called to inform the delegate that the item representing the object at indexPath will be displayed.
 */
- (void) collectionView: (NSCollectionView *)collectionView
        willDisplayItem: (NSCollectionViewItem *)item
        forRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath;

/**
 * Called to inform the delegate that the supplementary view for the elementKind will be displayed
 * at indexPath.
 */
- (void) collectionView: (NSCollectionView *)collectionView
         willDisplaySupplementaryView: (NSView *)view
         forElementKind: (NSCollectionViewSupplementaryElementKind)elementKind
            atIndexPath: (NSIndexPath *)indexPath;

/**
 * Called to inform the delegate that the collectionView will end display of item for the object at indexPath.
 */
- (void) collectionView: (NSCollectionView *)collectionView
   didEndDisplayingItem: (NSCollectionViewItem *)item
   forRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath;

/**
 * Called to inform the delegate that the collectionView will end display of supplementaryView for the
 * object at indexPath.
 */
- (void) collectionView: (NSCollectionView *)collectionView
         didEndDisplayingSupplementaryView: (NSView *)view
       forElementOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
            atIndexPath: (NSIndexPath *)indexPath;

/* Layout Transition Support */

/**
 * Called to inform the delegate that the collectionView is transitioning from the old to the new
 * layout indicated.
 */
- (NSCollectionViewTransitionLayout *) collectionView: (NSCollectionView *)collectionView
                         transitionLayoutForOldLayout: (NSCollectionViewLayout *)fromLayout
                                            newLayout: (NSCollectionViewLayout *)toLayout;
#endif
@end

APPKIT_EXPORT_CLASS
/**
 * NSCollectionView provides a flexible container for displaying collections
 * of items arranged in a customizable layout. This view manages the display
 * of multiple collection view items, handles user selection and interaction,
 * supports drag and drop operations, and provides extensive customization
 * through layouts and delegate methods. It serves as the primary interface
 * for displaying grid-based or custom arranged content with efficient
 * recycling of view components for optimal performance with large datasets.
 */
@interface NSCollectionView : NSView //<NSDraggingDestination, NSDraggingSource>
{
  // Content
  NSArray *_content;
  NSMutableArray *_items;
  NSIndexSet *_selectionIndexes;
  NSSet *_selectionIndexPaths;
  NSArray *_backgroundColors;

  // Delegate and datasource
  IBOutlet NSCollectionViewItem *itemPrototype;
  IBOutlet id <NSCollectionViewDelegate> _delegate;
  IBOutlet id <NSCollectionViewDataSource> _dataSource;
  IBOutlet NSView *_backgroundView;
  IBOutlet id <NSCollectionViewPrefetching> _prefetchDataSource;

  // Layout
  NSCollectionViewLayout *_collectionViewLayout;

  // Managing items
  NSMutableArray *_visibleItems;
  NSMutableDictionary *_visibleSupplementaryViews;
  NSMutableSet *_indexPathsForSupplementaryElementsOfKind;

  // Private
  // Map items -> indexPath
  NSMapTable *_itemsToIndexPaths;
  NSMapTable *_indexPathsToItems;
  NSMapTable *_itemsToAttributes;

  // Registered class/nib for item identifier
  NSMapTable *_registeredNibs;
  NSMapTable *_registeredClasses;

  // Selection management...
  BOOL _allowsMultipleSelection;
  BOOL _isSelectable;
  BOOL _allowsEmptySelection;
  BOOL _backgroundViewScrollsWithContent;
  BOOL _allowReload;

  // Size
  NSSize _itemSize;
  NSSize _maxItemSize;
  NSSize _minItemSize;
  CGFloat _tileWidth;
  CGFloat _verticalMargin;
  CGFloat _horizontalMargin;

  NSUInteger _maxNumberOfColumns;
  NSUInteger _maxNumberOfRows;
  NSUInteger _numberOfColumns;

  // Drag & Drop
  NSDragOperation _draggingSourceOperationMaskForLocal;
  NSDragOperation _draggingSourceOperationMaskForRemote;
  NSUInteger _draggingOnRow;
  NSUInteger _draggingOnIndex;
}

/**
 * Returns whether the collection view allows selection of multiple items
 * simultaneously. When enabled, users can select multiple collection view
 * items using standard multi-selection techniques such as command-click
 * or shift-click. When disabled, selecting one item automatically
 * deselects all others, maintaining single-item selection behavior.
 */
- (BOOL) allowsMultipleSelection;
/**
 * Sets whether the collection view should allow multiple items to be
 * selected at the same time. Multiple selection enables users to
 * perform batch operations on several items and provides more flexible
 * interaction patterns. Single selection mode is appropriate when only
 * one item should be active or highlighted at any given time.
 */
- (void) setAllowsMultipleSelection: (BOOL)flag;

/**
 * Returns the array of background colors used for alternating item
 * backgrounds in the collection view. Background colors provide visual
 * distinction between items and can create striping effects or other
 * visual patterns to improve readability and organization of the
 * displayed content.
 */
- (NSArray *) backgroundColors;
/**
 * Sets the array of background colors to be used for item backgrounds
 * in the collection view. The colors cycle through the provided array
 * to create alternating background patterns. Pass nil or an empty
 * array to disable background coloring and use the default appearance
 * for all items.
 */
- (void) setBackgroundColors: (NSArray *)colors;

/**
 * Returns the array of objects that serves as the data source for the
 * collection view items. Each object in the content array corresponds
 * to one item displayed in the collection view, with the item prototype
 * or registered classes determining how each object is presented
 * visually to the user.
 */
- (NSArray *) content;
/**
 * Sets the array of objects that will be displayed as items in the
 * collection view. Each object becomes the represented object for
 * a collection view item, which handles the visual presentation and
 * user interaction. Setting new content triggers a refresh of the
 * displayed items to reflect the updated data.
 */
- (void) setContent: (NSArray *)content;

/**
 * Returns the object that serves as the delegate for this collection view.
 * The delegate handles various aspects of user interaction, selection
 * behavior, drag and drop operations, and provides feedback about
 * item display and lifecycle events. The delegate enables customization
 * of the collection view's behavior beyond its default functionality.
 */
- (id < NSCollectionViewDelegate >) delegate;
/**
 * Sets the delegate object that will handle collection view events and
 * customize behavior. The delegate receives notifications about user
 * interactions, selection changes, drag and drop operations, and item
 * lifecycle events. Pass nil to remove the current delegate and use
 * default behavior for all collection view operations.
 */
- (void) setDelegate: (id < NSCollectionViewDelegate >)aDelegate;

/**
 * Returns the prototype collection view item used as a template for
 * creating new items when content is displayed. The prototype defines
 * the basic structure, appearance, and behavior that will be copied
 * for each item in the collection view. This provides a convenient
 * way to configure items without programmatic setup.
 */
- (NSCollectionViewItem *) itemPrototype;
/**
 * Sets the prototype collection view item that will serve as the template
 * for creating new items. The prototype's configuration, including view
 * hierarchy, bindings, and other properties, is copied when creating
 * items for display. Setting a new prototype affects subsequently
 * created items but does not modify existing ones.
 */
- (void) setItemPrototype: (NSCollectionViewItem *)prototype;

/**
 * Returns the maximum size allowed for collection view items. Items
 * will not be displayed larger than this size regardless of their
 * content or other sizing constraints. The maximum size provides an
 * upper bound that prevents items from growing too large and disrupting
 * the overall layout and visual balance of the collection.
 */
- (NSSize) maxItemSize;
/**
 * Sets the maximum size that collection view items are allowed to reach.
 * Items that would naturally size larger than this limit are constrained
 * to fit within the maximum bounds. This prevents oversized items from
 * dominating the display and maintains consistent visual proportions
 * across the collection view layout.
 */
- (void) setMaxItemSize: (NSSize)size;

/**
 * Returns the maximum number of columns that the collection view will
 * display in its layout. This constraint affects how items are arranged
 * and can force items to wrap to new rows when the column limit is
 * reached. The column limit provides control over the aspect ratio
 * and density of the collection view's content arrangement.
 */
- (NSUInteger) maxNumberOfColumns;
/**
 * Sets the maximum number of columns for the collection view layout.
 * Items will wrap to new rows when this column limit is exceeded,
 * creating a constrained grid arrangement. Setting this value affects
 * the overall shape and organization of the collection view's content
 * presentation.
 */
- (void) setMaxNumberOfColumns: (NSUInteger)number;

/**
 * Returns the maximum number of rows that the collection view will
 * display in its layout. This constraint controls the vertical extent
 * of the collection and can force items to wrap to new columns when
 * the row limit is reached, depending on the layout configuration
 * and item arrangement strategy.
 */
- (NSUInteger) maxNumberOfRows;
/**
 * Sets the maximum number of rows for the collection view layout.
 * When this limit is reached, the layout behavior depends on the
 * configuration, potentially wrapping items to additional columns
 * or constraining the total number of visible items within the
 * specified row count.
 */
- (void) setMaxNumberOfRows: (NSUInteger)number;

/**
 * Returns the minimum size allowed for collection view items. Items
 * will not be displayed smaller than this size, ensuring they remain
 * visible and usable even when content would naturally size smaller.
 * The minimum size provides a lower bound that maintains item
 * accessibility and visual consistency.
 */
- (NSSize) minItemSize;
/**
 * Sets the minimum size that collection view items must maintain.
 * Items that would naturally size smaller than this limit are expanded
 * to meet the minimum requirements. This ensures all items remain
 * visible and interactive while maintaining consistent appearance
 * standards across the collection view.
 */
- (void) setMinItemSize: (NSSize)size;

/**
 * Returns whether items in the collection view can be selected by user
 * interaction. When selectable, users can click items to select them,
 * and the collection view manages selection state and visual feedback.
 * When not selectable, items are display-only and do not respond to
 * selection attempts, though they may still handle other interactions.
 */
- (BOOL) isSelectable;
/**
 * Sets whether items in the collection view should respond to selection
 * attempts. Enabling selection allows users to interact with items and
 * receive visual feedback about their choices. Disabling selection
 * creates a read-only display where items cannot be highlighted or
 * chosen, though other interactions may still function.
 */
- (void) setSelectable: (BOOL)flag;

/**
 * Returns the set of indexes identifying currently selected items in
 * the collection view. The index set contains the positions of all
 * items that are currently selected, allowing access to the selected
 * content objects and providing information for batch operations
 * on the selection.
 */
- (NSIndexSet *) selectionIndexes;
/**
 * Sets the indexes of items that should be selected in the collection
 * view. This programmatically changes the selection state, potentially
 * triggering delegate notifications and visual updates. The selection
 * respects the collection view's multiple selection settings and
 * other selection constraints.
 */
- (void) setSelectionIndexes: (NSIndexSet *)indexes;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/**
 * Returns the set of index paths identifying currently selected items
 * in the collection view. Index paths provide section and item
 * information for each selected item, enabling precise identification
 * in complex layouts with multiple sections. This is the preferred
 * method for selection access in modern collection view implementations.
 */
- (NSSet *) selectionIndexPaths;
/**
 * Sets the index paths of items that should be selected in the
 * collection view. Index paths specify both section and item positions,
 * providing precise control over selection in multi-section layouts.
 * This programmatically updates the selection state and may trigger
 * delegate notifications and visual feedback updates.
 */
- (void) setSelectionIndexPaths: (NSSet *)indexPaths;


/**
 * Returns the collection view layout object that determines how items
 * are positioned and arranged within the collection view. The layout
 * controls item placement, sizing, spacing, and other visual arrangement
 * aspects. Different layout classes provide various presentation styles
 * such as grids, flows, or custom arrangements.
 */
- (NSCollectionViewLayout *) collectionViewLayout;
/**
 * Sets the layout object that will control item arrangement within
 * the collection view. Changing the layout can dramatically alter
 * the visual presentation and behavior of the collection. The layout
 * change may be animated depending on the implementation and can
 * trigger extensive repositioning of visible items.
 */
- (void) setCollectionViewLayout: (NSCollectionViewLayout *)layout;
#endif

/**
 * Returns the frame rectangle for the item at the specified index
 * within the collection view's coordinate system. The frame defines
 * the item's position and size as determined by the current layout,
 * useful for hit testing, scrolling to specific items, or custom
 * drawing and animation operations.
 */
- (NSRect) frameForItemAtIndex: (NSUInteger)index;
/**
 * Returns the collection view item object currently displayed at the
 * specified index. This provides access to the item's view hierarchy
 * and properties for direct manipulation or inspection. Returns nil
 * if no item exists at the given index or if the item is not currently
 * visible and instantiated.
 */
- (NSCollectionViewItem *) itemAtIndex: (NSUInteger)index;
/**
 * Creates and returns a new collection view item configured to represent
 * the specified object. This method uses the item prototype or registered
 * classes to instantiate and configure the item appropriately for
 * displaying the given represented object within the collection view
 * layout.
 */
- (NSCollectionViewItem *) newItemForRepresentedObject: (id)object;

/**
 * Recalculates and updates the layout of all items in the collection
 * view. This method triggers a complete relayout operation, repositioning
 * items according to the current layout configuration, content changes,
 * and view bounds. Tiling is typically called automatically when needed
 * but can be invoked manually for custom layout updates.
 */
- (void) tile;

/**
 * Sets the drag operations that this collection view supports when
 * acting as a drag source. The operation mask determines what types
 * of drag operations (copy, move, link, etc.) are offered to potential
 * drop destinations. The local flag indicates whether the mask applies
 * to drops within the same application or external destinations.
 */
- (void) setDraggingSourceOperationMask: (NSDragOperation)dragOperationMask
                               forLocal: (BOOL)localDestination;

/**
 * Returns a drag image representing the items at the specified indexes
 * during a drag operation. The image provides visual feedback to users
 * about what content is being dragged and can be customized to show
 * item previews, counts, or other relevant information. The offset
 * parameter specifies the image position relative to the mouse cursor.
 */
- (NSImage *) draggingImageForItemsAtIndexes: (NSIndexSet *)indexes
                                   withEvent: (NSEvent *)event
                                      offset: (NSPointPointer)dragImageOffset;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
/* Locating Items and Views */

/**
 * Returns an array of currently visible collection view items within
 * the collection view's bounds. Visible items are those that are at
 * least partially displayed and have been instantiated for rendering.
 * This provides access to the actual item objects for direct inspection
 * or manipulation of the currently displayed content.
 */
- (NSArray *) visibleItems;

/**
 * Returns a set of index paths identifying all currently visible items
 * within the collection view's bounds. Index paths specify both section
 * and item positions for precise identification in multi-section layouts.
 * This information is useful for optimizing updates and managing visible
 * content efficiently.
 */
- (NSSet *) indexPathsForVisibleItems;

/**
 * Returns an array of visible supplementary views of the specified kind.
 * Supplementary views include headers, footers, and other decorative
 * or informational views that are not primary content items. This method
 * provides access to currently displayed supplementary views for
 * inspection or direct manipulation.
 */
- (NSArray *) visibleSupplementaryViewsOfKind: (NSCollectionViewSupplementaryElementKind)elementKind;

/**
 * Returns a set of index paths for visible supplementary elements of
 * the specified kind. Supplementary elements include section headers,
 * footers, and other layout-provided decorative views. The index paths
 * identify the location of currently visible supplementary views within
 * the collection view's section structure.
 */
- (NSSet *) indexPathsForVisibleSupplementaryElementsOfKind: (NSCollectionViewSupplementaryElementKind)elementKind;

/**
 * Returns the index path for the specified collection view item object.
 * The index path identifies the item's position within the collection
 * view's section and item structure. Returns nil if the item is not
 * found or is not currently associated with a valid position in the
 * collection view.
 */
- (NSIndexPath *) indexPathForItem: (NSCollectionViewItem *)item;

/**
 * Returns the index path for the item located at the specified point
 * within the collection view's coordinate system. This method performs
 * hit testing to determine which item, if any, is positioned at the
 * given location. Returns nil if no item is found at the specified
 * point.
 */
- (NSIndexPath *) indexPathForItemAtPoint: (NSPoint)point;

/**
 * Returns the collection view item object at the specified index path.
 * The item may be created if it's not currently instantiated but is
 * within the displayable range. Returns nil if no item exists at the
 * given index path or if the path is invalid for the current content
 * configuration.
 */
- (NSCollectionViewItem *) itemAtIndexPath: (NSIndexPath *)indexPath;

/**
 * Returns the supplementary view of the specified kind at the given
 * index path. Supplementary views provide additional layout elements
 * such as section headers, footers, or decorative content that
 * complements the primary collection view items. Returns nil if no
 * supplementary view exists at the specified location.
 */
- (NSView *)supplementaryViewForElementKind: (NSCollectionViewSupplementaryElementKind)elementKind
                                atIndexPath: (NSIndexPath *)indexPath;

- (void) scrollToItemsAtIndexPaths: (NSSet *)indexPaths
                    scrollPosition: (NSCollectionViewScrollPosition)scrollPosition;

/* Creating Collection view Items */

- (NSCollectionViewItem *) makeItemWithIdentifier: (NSUserInterfaceItemIdentifier)identifier
                                     forIndexPath: (NSIndexPath *)indexPath;

- (void) registerClass: (Class)itemClass
 forItemWithIdentifier: (NSUserInterfaceItemIdentifier)identifier;

- (void) registerNib: (NSNib *)nib
 forItemWithIdentifier: (NSUserInterfaceItemIdentifier)identifier;

- (NSView *) makeSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
                          withIdentifier: (NSUserInterfaceItemIdentifier)identifier
                            forIndexPath: (NSIndexPath *)indexPath;

- (void)registerClass: (Class)viewClass
        forSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)kind
       withIdentifier: (NSUserInterfaceItemIdentifier)identifier;

- (void) registerNib: (NSNib *)nib
         forSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)kind
      withIdentifier: (NSUserInterfaceItemIdentifier)identifier;

/* Providing the collection view's data */

- (id<NSCollectionViewDataSource>) dataSource;

- (void) setDataSource: (id<NSCollectionViewDataSource>)dataSource;

/* Configuring the Collection view */

- (NSView *) backgroundView;

- (void) setBackgroundView: (NSView *)backgroundView;

- (BOOL) backgroundViewScrollsWithContent;

- (void) setBackgroundViewScrollsWithContent: (BOOL)f;

/* Reloading Content */

- (void) reloadData;

- (void) reloadSections: (NSIndexSet *)sections;

- (void) reloadItemsAtIndexPaths: (NSSet *)indexPaths;

/* Prefetching Collection View Cells and Data */

- (id<NSCollectionViewPrefetching>) prefetchDataSource;

- (void) setPrefetchDataSource: (id<NSCollectionViewPrefetching>)prefetchDataSource;

/* Getting the State of the Collection View */

- (NSInteger) numberOfSections;

- (NSInteger) numberOfItemsInSection: (NSInteger)section;

/* Inserting, Moving and Deleting Items */

- (void) insertItemsAtIndexPaths: (NSSet *)indexPaths;

- (void) moveItemAtIndexPath: (NSIndexPath *)indexPath
                 toIndexPath: (NSIndexPath *)newIndexPath;

- (void) deleteItemsAtIndexPaths: (NSSet *)indexPaths;

/* Inserting, Moving, Deleting and Collapsing Sections */

- (void) insertSections: (NSIndexSet *)sections;

- (void) moveSection: (NSInteger)section
           toSection: (NSInteger)newSection;

- (void) deleteSections: (NSIndexSet *)sections;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)
- (IBAction) toggleSectionCollapse: (id)sender;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)
- (BOOL) allowsEmptySelection;

- (void) setAllowsEmptySelection: (BOOL)flag;

- (NSSet *) selectionIndexPaths; // copy

- (IBAction) selectAll: (id)sender;

- (IBAction) deselectAll: (id)sender;

- (void) selectItemsAtIndexPaths: (NSSet *)indexPaths
                  scrollPosition: (NSCollectionViewScrollPosition)scrollPosition;

- (void) deselectItemsAtIndexPaths: (NSSet *)indexPaths;

/* Getting Layout Information */

- (NSCollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath;

- (NSCollectionViewLayoutAttributes *) layoutAttributesForSupplementaryElementOfKind: (NSCollectionViewSupplementaryElementKind)kind
                                                                         atIndexPath: (NSIndexPath *)indexPath;
/* Animating Multiple Changes */

DEFINE_BLOCK_TYPE_NO_ARGS(GSCollectionViewPerformBatchUpdatesBlock, void);
DEFINE_BLOCK_TYPE(GSCollectionViewCompletionHandlerBlock, void, BOOL);

- (void) performBatchUpdates: (GSCollectionViewPerformBatchUpdatesBlock) updates
           completionHandler: (GSCollectionViewCompletionHandlerBlock) completionHandler;

#endif

@end

#endif /* _GNUstep_H_NSCollectionView */
