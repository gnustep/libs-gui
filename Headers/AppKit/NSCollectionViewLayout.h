/* Interface of class NSCollectionViewLayout
   Copyright (C) 2021 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: 30-05-2021

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

#ifndef _NSCollectionViewLayout_h_GNUSTEP_GUI_INCLUDE
#define _NSCollectionViewLayout_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

#import <AppKit/NSCollectionView.h>
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

enum
{
 NSCollectionElementCategoryItem,
 NSCollectionElementCategorySupplementaryView,
 NSCollectionElementCategoryDecorationView,
 NSCollectionElementCategoryInterItemGap
};
typedef NSInteger NSCollectionElementCategory;


typedef NSString *NSCollectionViewDecorationElementKind;
APPKIT_EXPORT NSCollectionViewSupplementaryElementKind NSCollectionElementKindInterItemGapIndicator;

@class NSCollectionViewLayoutAttributes;
@class NSCollectionView;
@class NSDictionary;
@class NSIndexPath;
@class NSMutableDictionary;
@class NSNib;
@class NSSet;

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewLayoutAttributes encapsulates the visual attributes
 * for collection view elements, including position, size, transparency,
 * visibility, and z-ordering information. These attributes define how
 * collection view items, supplementary views, and decoration views
 * appear within the layout. Layout objects create and configure these
 * attributes to specify the visual presentation of each element in the
 * collection view's coordinate system.
 */
@interface NSCollectionViewLayoutAttributes : NSObject <NSCopying>
{
  NSRect _frame;
  CGFloat _alpha;
  NSInteger _zIndex;
  BOOL _hidden;
  NSIndexPath *_indexPath;
  NSCollectionElementCategory _representedElementCategory;
  NSString *_representedElementKind;
}

// Initializers
/**
 * Creates layout attributes for a collection view item at the specified
 * index path. Item attributes define the visual presentation of primary
 * content elements within the collection view. The index path identifies
 * the item's position within the collection's section and item structure,
 * allowing the layout to provide appropriate positioning and styling.
 */
+ (instancetype) layoutAttributesForItemWithIndexPath: (NSIndexPath *)indexPath;
/**
 * Creates layout attributes for an inter-item gap before the specified
 * index path. Gap attributes represent spacing or separators between
 * collection view items, providing visual organization and structure.
 * These attributes can be used to create dynamic spacing that responds
 * to layout changes or user interactions.
 */
+ (instancetype) layoutAttributesForInterItemGapBeforeIndexPath: (NSIndexPath *)indexPath;
/**
 * Creates layout attributes for a supplementary view of the specified
 * kind at the given index path. Supplementary views include headers,
 * footers, and other supporting content that provides context or
 * organization for the primary collection view items. The element kind
 * identifies the type of supplementary view being configured.
 */
+ (instancetype) layoutAttributesForSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
                                              withIndexPath: (NSIndexPath *)indexPath;
/**
 * Creates layout attributes for a decoration view of the specified kind
 * at the given index path. Decoration views provide visual enhancements
 * such as backgrounds, borders, or other aesthetic elements that are
 * managed by the layout rather than the data source. These views are
 * purely presentational and do not represent data content.
 */
+ (instancetype)layoutAttributesForDecorationViewOfKind:(NSCollectionViewDecorationElementKind)decorationViewKind
                                              withIndexPath: (NSIndexPath*)indexPath;

// Properties
/**
 * Returns the frame rectangle that defines the element's position and
 * size within the collection view's coordinate system. The frame
 * determines where the element will be displayed and how much space
 * it will occupy. Layout objects calculate and set this frame based
 * on their positioning algorithms and constraints.
 */
- (NSRect) frame;
/**
 * Sets the frame rectangle that defines the element's position and size
 * within the collection view. Changing the frame affects where the
 * element appears and how much space it occupies. The frame should be
 * specified in the collection view's coordinate system and will be
 * used during layout and display operations.
 */
- (void) setFrame: (NSRect)frame;

/**
 * Returns the size component of the element's frame rectangle. This
 * provides convenient access to the element's width and height without
 * needing to extract the size from the complete frame rectangle. The
 * size determines the element's visual footprint within the layout.
 */
- (NSSize) size;
/**
 * Sets the size component of the element's frame rectangle while
 * preserving the frame's origin. This provides a convenient way to
 * adjust an element's dimensions without affecting its position within
 * the collection view. The size change affects the element's visual
 * appearance and space utilization.
 */
- (void) setSize: (NSSize)size;

/**
 * Returns the alpha transparency value for the element, ranging from
 * 0.0 (completely transparent) to 1.0 (completely opaque). Alpha values
 * control the element's transparency during display and can be used for
 * fading effects, disabled states, or other visual feedback. The default
 * alpha value is typically 1.0 for normal visibility.
 */
- (CGFloat) alpha;
/**
 * Sets the alpha transparency value for the element. Values should range
 * from 0.0 (invisible) to 1.0 (opaque), with intermediate values creating
 * semi-transparent effects. Alpha changes are useful for animations,
 * highlighting, or indicating disabled states. Setting alpha to 0.0
 * makes the element invisible but does not remove it from the layout.
 */
- (void) setAlpha: (CGFloat)alpha;

/**
 * Returns whether the element is currently hidden from display. Hidden
 * elements are not rendered but may still participate in layout
 * calculations depending on the layout implementation. This property
 * provides an alternative to alpha transparency for controlling element
 * visibility with a simple boolean state.
 */
- (BOOL) isHidden;
/**
 * Sets whether the element should be hidden from display. Hidden elements
 * are not rendered to the screen but may still occupy space in the layout
 * depending on the layout's behavior. This provides a convenient way to
 * temporarily remove elements from visibility without removing them from
 * the layout structure entirely.
 */
- (void) setHidden: (BOOL)hidden;

/**
 * Returns the index path that identifies the element's position within
 * the collection view's structure. The index path specifies the section
 * and item location for primary content or the section and position for
 * supplementary and decoration views. This path provides the key for
 * associating layout attributes with specific data elements.
 */
- (NSIndexPath *) indexPath;
/**
 * Sets the index path that identifies where this element is located
 * within the collection view's organizational structure. The index path
 * establishes the connection between layout attributes and the data
 * source or layout-provided elements. This association is essential for
 * proper element identification and updates.
 */
- (void) setIndexPath: (NSIndexPath *)indexPath;

/**
 * Returns the category of element that these attributes represent,
 * such as item, supplementary view, or decoration view. The category
 * determines how the element is created, managed, and updated by the
 * collection view system. Different categories have different lifecycle
 * and data source relationships.
 */
- (NSCollectionElementCategory) representedElementCategory;
/**
 * Returns the specific kind identifier for supplementary or decoration
 * elements. For items, this is typically nil, but for supplementary
 * views like headers or footers, and decoration views like backgrounds,
 * this string identifies the specific type of element being represented
 * by these attributes.
 */
- (NSString *) representedElementKind;

/**
 * Returns the z-index value that determines the element's layering order
 * within the collection view. Elements with higher z-index values appear
 * in front of those with lower values. The z-index affects the visual
 * stacking order when elements overlap and is particularly important for
 * decoration views and special visual effects.
 */
- (NSInteger) zIndex;
/**
 * Sets the z-index value for controlling the element's position in the
 * display layer stack. Higher z-index values cause elements to appear
 * in front of elements with lower values. This is crucial for managing
 * overlapping elements and ensuring proper visual hierarchy, especially
 * for decoration views and interactive feedback.
 */
- (void) setZIndex: (NSInteger)zIndex;

@end

enum
{
 NSCollectionUpdateActionInsert,
 NSCollectionUpdateActionDelete,
 NSCollectionUpdateActionReload,
 NSCollectionUpdateActionMove,
 NSCollectionUpdateActionNone
};
typedef NSInteger NSCollectionUpdateAction;

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewUpdateItem represents a single change operation during
 * collection view updates, such as insertions, deletions, moves, or
 * reloads. These objects provide information about what changed and where,
 * allowing layout objects to prepare appropriate animations and adjust
 * their arrangements accordingly. Update items are created automatically
 * during batch update operations and passed to layout methods.
 */
@interface NSCollectionViewUpdateItem : NSObject
{
  NSIndexPath *_indexPathBeforeUpdate;
  NSIndexPath *_indexPathAfterUpdate;
  NSCollectionUpdateAction _updateAction;
}

/**
 * Returns the index path where the affected item was located before
 * the update operation. For insertions, this is nil since the item
 * didn't exist previously. For deletions and moves, this indicates
 * the item's original position. For reloads, this is the same as
 * the after-update path since the item remains in place.
 */
- (NSIndexPath *) indexPathBeforeUpdate;
/**
 * Returns the index path where the affected item will be located after
 * the update operation completes. For deletions, this is nil since the
 * item will no longer exist. For insertions and moves, this indicates
 * the item's new position. For reloads, this matches the before-update
 * path.
 */
- (NSIndexPath *) indexPathAfterUpdate;
/**
 * Returns the type of update operation being performed, such as insert,
 * delete, move, or reload. The update action determines how the layout
 * should handle the change and what animation or transition effects
 * should be applied. Different actions require different layout
 * adjustments and animation strategies.
 */
- (NSCollectionUpdateAction) updateAction;

@end

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewLayoutInvalidationContext provides information about
 * what aspects of a collection view layout need to be recalculated and
 * updated. This context object specifies which elements require
 * invalidation, what adjustments should be made to content size or
 * offset, and the scope of the layout refresh. Layout objects use
 * this context to optimize their update process and minimize
 * unnecessary recalculations.
 */
@interface NSCollectionViewLayoutInvalidationContext : NSObject
{
  NSPoint _contentOffsetAdjustment;
  NSSize _contentSizeAdjustment;
  NSSet *_invalidatedItemIndexPaths;
  NSDictionary *_invalidatedSupplementaryIndexPaths;
  NSDictionary *_invalidatedDecorationIndexPaths;
}

// Initializers
/**
 * Marks the specified items for invalidation, indicating that their
 * layout attributes need to be recalculated. This method allows for
 * selective invalidation of specific items rather than invalidating
 * the entire layout, improving performance by limiting the scope of
 * recalculation to only the elements that actually need updates.
 */
- (void)invalidateItemsAtIndexPaths: (NSSet *)indexPaths;
/**
 * Marks supplementary elements of the specified kind at the given
 * index paths for invalidation. Supplementary elements include headers,
 * footers, and other supporting views that may need layout updates
 * independently of the main collection items. This enables targeted
 * updates for specific supplementary view types.
 */
- (void)invalidateSupplementaryElementsOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
                                 atIndexPaths: (NSSet *)indexPaths;
/**
 * Marks decoration elements of the specified kind at the given index
 * paths for invalidation. Decoration elements are visual enhancements
 * managed by the layout that may require updates when layout conditions
 * change. This method allows precise control over which decoration
 * views need recalculation.
 */
- (void)invalidateDecorationElementsOfKind: (NSCollectionViewDecorationElementKind)elementKind
                              atIndexPaths: (NSSet *)indexPaths;

// Properties
- (BOOL) invalidateEverything;
- (BOOL) invalidateDataSourceCounts;

- (NSSet *) invalidatedItemIndexPaths;

- (NSPoint) contentOffsetAdjustment;
- (void) setContentOffsetAdjustment: (NSPoint)point;

- (NSSize) contentSizeAdjustment;
- (void) setContentSizeAdjustment: (NSSize)size;

- (NSDictionary *) invalidatedSupplementaryIndexPaths;
- (NSDictionary *) invalidatedDecorationIndexPaths;

@end

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewLayout serves as the abstract base class for all
 * collection view layout objects. It defines the interface for
 * calculating and providing layout attributes for collection view
 * elements, managing invalidation and updates, and handling layout
 * transitions. Subclasses implement specific layout algorithms such
 * as grids, flows, or custom arrangements, while this base class
 * provides the fundamental infrastructure and lifecycle management
 * for layout operations.
 */
@interface NSCollectionViewLayout : NSObject <NSCoding>
{
  NSCollectionView *_collectionView; // weak
  BOOL _valid;

  Class _layoutAttributesClass;
  Class _invalidationContextClass;
  NSSize _collectionViewContentSize;
}

// Initializers
/**
 * Invalidates the current layout, marking it for recalculation on the
 * next layout pass. This method triggers a complete layout refresh,
 * causing all elements to have their attributes recalculated. Use this
 * when layout parameters or data have changed significantly enough to
 * require a comprehensive layout update.
 */
- (void)invalidateLayout;
/**
 * Invalidates the layout using the specified invalidation context to
 * control the scope and details of the invalidation. The context allows
 * for more precise control over what gets invalidated, potentially
 * improving performance by limiting recalculation to only the affected
 * elements and adjusting content size or offset as needed.
 */
- (void)invalidateLayoutWithContext: (NSCollectionViewLayoutInvalidationContext *)context;

/**
 * Registers a view class to be used for creating decoration views of
 * the specified kind. Decoration views are visual elements managed
 * by the layout that provide backgrounds, borders, or other aesthetic
 * enhancements. The registered class will be instantiated when the
 * layout requests decoration views of the given element kind.
 */
- (void)registerClass: (Class)viewClass
        forDecorationViewOfKind: (NSCollectionViewDecorationElementKind)elementKind;
/**
 * Registers a nib file to be used for creating decoration views of the
 * specified kind. The nib provides a way to define complex decoration
 * view layouts and configurations that will be instantiated when the
 * layout requires decoration views of the given element kind. This
 * allows for sophisticated visual designs in decoration views.
 */
- (void)registerNib: (NSNib *)nib
        forDecorationViewOfKind: (NSCollectionViewDecorationElementKind)elementKind;

// Properties
- (NSCollectionView *) collectionView;
- (void) setCollectionView: (NSCollectionView *)cv;

@end

APPKIT_EXPORT_CLASS
/**
 * Category containing the essential methods that subclasses override
 * to implement specific layout behaviors. These methods define the core
 * layout calculation and attribute provision interface that collection
 * views use to arrange and display their content. Subclasses implement
 * these methods to create different layout styles such as grids, flows,
 * or custom arrangements.
 */
@interface NSCollectionViewLayout (NSSubclassingHooks)

// Methods to override for specific layouts...
/**
 * Performs initial calculations and setup required before layout
 * attributes are requested. Subclasses override this method to compute
 * element positions, cache calculated values, and prepare any data
 * structures needed for efficient attribute queries. This method is
 * called before any layout attributes are requested from the layout.
 */
- (void) prepareLayout;
/**
 * Returns an array of layout attributes for all elements that intersect
 * or are contained within the specified rectangle. This method is the
 * primary way the collection view queries for visible elements during
 * scrolling and display updates. Subclasses must implement this to
 * provide attributes for all relevant elements in the given area.
 */
- (NSArray *) layoutAttributesForElementsInRect: (NSRect)rect;
/**
 * Returns the layout attributes for the item at the specified index path.
 * This method provides attributes for individual collection view items,
 * defining their position, size, and visual properties. Subclasses
 * implement this to calculate and return the specific attributes for
 * the requested item based on their layout algorithm.
 */
- (NSCollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath;
/**
 * Returns the layout attributes for a supplementary view of the specified
 * kind at the given index path. Supplementary views include headers,
 * footers, and other supporting elements that provide context for the
 * main collection items. Subclasses implement this to position and
 * configure supplementary views according to their layout design.
 */
- (NSCollectionViewLayoutAttributes *)
  layoutAttributesForSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
  atIndexPath: (NSIndexPath *)indexPath;

/**
 * Returns the layout attributes for a decoration view of the specified
 * kind at the given index path. Decoration views are visual elements
 * like backgrounds, borders, or separators that are managed entirely
 * by the layout. Subclasses implement this method when they need to
 * provide decorative visual elements as part of their design.
 */
- (NSCollectionViewLayoutAttributes *)
  layoutAttributesForDecorationViewOfKind: (NSCollectionViewDecorationElementKind)elementKind
                              atIndexPath: (NSIndexPath *)indexPath;

/**
 * Returns layout attributes for visual feedback at the specified drop
 * target point during drag and drop operations. This method allows
 * layouts to provide custom visual indicators for potential drop
 * locations, enhancing the drag and drop user experience with
 * layout-specific feedback and guidance.
 */
- (NSCollectionViewLayoutAttributes *) layoutAttributesForDropTargetAtPoint: (NSPoint)pointInCollectionView;
/**
 * Returns layout attributes for an inter-item gap before the specified
 * index path. Gap attributes define spacing or separator elements
 * between collection items, allowing layouts to create dynamic spacing
 * that can respond to user interactions or layout changes. These gaps
 * can be styled and animated like other layout elements.
 */
- (NSCollectionViewLayoutAttributes *) layoutAttributesForInterItemGapBeforeIndexPath: (NSIndexPath *)indexPath;

/**
 * Determines whether the layout should be invalidated when the collection
 * view's bounds change to the specified new bounds. Subclasses return
 * YES if the layout needs to be recalculated for the new bounds, such
 * as when item positions depend on the view size. Returning NO improves
 * performance when bounds changes don't affect the layout.
 */
- (BOOL) shouldInvalidateLayoutForBoundsChange: (NSRect)newBounds;
- (NSCollectionViewLayoutInvalidationContext *) invalidationContextForBoundsChange: (NSRect)newBounds;

- (BOOL) shouldInvalidateLayoutForPreferredLayoutAttributes: (NSCollectionViewLayoutAttributes *)preferredAttributes
                                     withOriginalAttributes: (NSCollectionViewLayoutAttributes *)originalAttributes;

- (NSCollectionViewLayoutInvalidationContext *)
  invalidationContextForPreferredLayoutAttributes: (NSCollectionViewLayoutAttributes *)preferredAttributes
                           withOriginalAttributes: (NSCollectionViewLayoutAttributes *)originalAttributes;

- (NSPoint) targetContentOffsetForProposedContentOffset: (NSPoint)proposedContentOffset
                                  withScrollingVelocity: (NSPoint)velocity;
- (NSPoint) targetContentOffsetForProposedContentOffset: (NSPoint)proposedContentOffset;

/**
 * Returns the total content size for the collection view layout. This
 * size defines the scrollable area and determines the collection view's
 * scrolling behavior and scroll bar appearance. Subclasses must calculate
 * and return the size that encompasses all layout elements, typically
 * computed during prepareLayout and cached for efficient access.
 */
- (NSSize) collectionViewContentSize;

@end

APPKIT_EXPORT_CLASS
/**
 * Category containing methods for handling collection view updates and
 * transitions. These methods allow layouts to participate in animated
 * insertions, deletions, moves, and layout changes. Subclasses can
 * override these methods to provide custom animations and transitions
 * that coordinate with their specific layout algorithms and visual
 * designs.
 */
@interface NSCollectionViewLayout (NSUpdateSupportHooks)

// Update support
/**
 * Prepares the layout for a set of collection view updates that will
 * be animated. This method is called before update animations begin,
 * allowing the layout to analyze the changes and prepare any necessary
 * adjustments or animation configurations. The update items describe
 * the specific changes that will occur.
 */
- (void) prepareForCollectionViewUpdates: (NSArray *)updateItems;
/**
 * Performs final cleanup after collection view update animations have
 * completed. This method allows the layout to perform any necessary
 * cleanup, cache invalidation, or state updates that should occur
 * after all update animations have finished and the collection view
 * has settled into its new configuration.
 */
- (void) finalizeCollectionViewUpdates;
- (void) prepareForAnimatedBoundsChange: (NSRect)oldBounds;
- (void) finalizeAnimatedBoundsChange;

- (void) prepareForTransitionToLayout: (NSCollectionViewLayout *)newLayout;
- (void) prepareForTransitionFromLayout: (NSCollectionViewLayout *)oldLayout;
- (void) finalizeLayoutTransition;

/**
 * Returns the layout attributes that should be used for an item that
 * is appearing during an update animation, such as during insertion.
 * This method allows layouts to specify custom starting attributes for
 * appearing items, enabling sophisticated entrance animations. The
 * attributes define the item's initial state before it animates to
 * its final position.
 */
- (NSCollectionViewLayoutAttributes *) initialLayoutAttributesForAppearingItemAtIndexPath: (NSIndexPath *)itemIndexPath;
/**
 * Returns the layout attributes that should be used for an item that
 * is disappearing during an update animation, such as during deletion.
 * This method allows layouts to specify custom ending attributes for
 * disappearing items, enabling sophisticated exit animations. The
 * attributes define the item's final state as it animates away.
 */
- (NSCollectionViewLayoutAttributes *) finalLayoutAttributesForDisappearingItemAtIndexPath: (NSIndexPath *)itemIndexPath;
- (NSCollectionViewLayoutAttributes *)
  initialLayoutAttributesForAppearingSupplementaryElementOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
                                                    atIndexPath: (NSIndexPath *)elementIndexPath;
- (NSCollectionViewLayoutAttributes *)
  finalLayoutAttributesForDisappearingSupplementaryElementOfKind: (NSCollectionViewSupplementaryElementKind)elementKind
                                                     atIndexPath: (NSIndexPath *)elementIndexPath;
- (NSCollectionViewLayoutAttributes *)
  initialLayoutAttributesForAppearingDecorationElementOfKind: (NSCollectionViewDecorationElementKind)elementKind
                                                 atIndexPath: (NSIndexPath *)decorationIndexPath;
- (NSCollectionViewLayoutAttributes *)
  finalLayoutAttributesForDisappearingDecorationElementOfKind: (NSCollectionViewDecorationElementKind)elementKind
                                                   atIndexPath: (NSIndexPath *)decorationIndexPath;

- (NSSet *) indexPathsToDeleteForSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)elementKind;
- (NSSet *) indexPathsToDeleteForDecorationViewOfKind: (NSCollectionViewDecorationElementKind)elementKind;
- (NSSet *) indexPathsToInsertForSupplementaryViewOfKind: (NSCollectionViewSupplementaryElementKind)elementKind;
- (NSSet *) indexPathsToInsertForDecorationViewOfKind: (NSCollectionViewDecorationElementKind)elementKind;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSCollectionViewLayout_h_GNUSTEP_GUI_INCLUDE */

