/* Definition of class NSCollectionViewFlowLayout
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

#ifndef _NSCollectionViewFlowLayout_h_GNUSTEP_GUI_INCLUDE
#define _NSCollectionViewFlowLayout_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSCollectionViewLayout.h>
#import <AppKit/AppKitDefines.h>

@class NSCollectionViewLayout, NSMutableIndexSet;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

enum
{
 NSCollectionViewScrollDirectionVertical,
 NSCollectionViewScrollDirectionHorizontal
};
typedef NSInteger NSCollectionViewScrollDirection;

APPKIT_EXPORT NSCollectionViewSupplementaryElementKind NSCollectionElementKindSectionHeader;
APPKIT_EXPORT NSCollectionViewSupplementaryElementKind NSCollectionElementKindSectionFooter;

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewFlowLayoutInvalidationContext provides specialized
 * invalidation control for flow layouts, extending the base invalidation
 * context with flow-specific invalidation options. This context allows
 * fine-grained control over what aspects of the flow layout need to be
 * recalculated, including delegate metrics and flow-specific layout
 * attributes. It enables optimization by allowing selective invalidation
 * of only the necessary components during layout updates.
 */
@interface NSCollectionViewFlowLayoutInvalidationContext : NSCollectionViewLayoutInvalidationContext
{
  BOOL _invalidateFlowLayoutDelegateMetrics;
  BOOL _invalidateFlowLayoutAttributes;
}

/**
 * Sets whether the flow layout should invalidate and recalculate metrics
 * obtained from its delegate. When enabled, this forces the layout to
 * re-query the delegate for item sizes, spacing, insets, and other
 * flow-specific measurements. This is necessary when delegate behavior
 * changes or when the factors that influence delegate responses have
 * been modified.
 */
- (void) setInvalidateFlowLayoutDelegateMetrics: (BOOL)flag;
/**
 * Returns whether the flow layout will invalidate and recalculate
 * delegate-provided metrics during the next layout pass. When this
 * flag is set, the layout will re-query its delegate for all size
 * and spacing information, ensuring that layout calculations reflect
 * any changes in delegate behavior or data dependencies.
 */
- (BOOL) invalidateFlowLayoutDelegateMetrics;

/**
 * Sets whether the flow layout should invalidate and recalculate its
 * flow-specific layout attributes. This includes the positioning and
 * sizing calculations that are unique to flow layouts, such as line
 * breaking, item arrangement within lines, and flow direction handling.
 * Enable this when flow-specific layout parameters have changed.
 */
- (void) setInvalidateFlowLayoutAttributes: (BOOL)flag;
/**
 * Returns whether the flow layout will invalidate and recalculate its
 * flow-specific layout attributes during the next layout pass. When
 * this flag is set, the layout will recompute item positions, line
 * arrangements, and other flow-specific positioning calculations to
 * reflect changes in layout configuration or constraints.
 */
- (BOOL) invalidateFlowLayoutAttributes;
@end

@protocol NSCollectionViewDelegateFlowLayout <NSCollectionViewDelegate>

- (NSSize) collectionView: (NSCollectionView *)collectionView
                   layout: (NSCollectionViewLayout*)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSEdgeInsets)collectionView: (NSCollectionView *)collectionView
                        layout: (NSCollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex: (NSInteger)section;

- (CGFloat) collectionView: (NSCollectionView *)collectionView
                    layout: (NSCollectionViewLayout *)collectionViewLayout
                    minimumLineSpacingForSectionAtIndex: (NSInteger)section;

- (CGFloat) collectionView: (NSCollectionView *)collectionView
                    layout: (NSCollectionViewLayout *)collectionViewLayout
                    minimumInteritemSpacingForSectionAtIndex: (NSInteger)section;

- (NSSize) collectionView: (NSCollectionView *)collectionView
                   layout: (NSCollectionViewLayout *)collectionViewLayout
                   referenceSizeForHeaderInSection: (NSInteger)section;

- (NSSize) collectionView: (NSCollectionView *)collectionView
                   layout: (NSCollectionViewLayout *)collectionViewLayout
                   referenceSizeForFooterInSection: (NSInteger)section;

@end

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewFlowLayout provides a flexible flow-based layout
 * system for collection views that arranges items in lines with
 * automatic wrapping and spacing. This layout supports both vertical
 * and horizontal scroll directions, customizable item sizes, spacing
 * between items and lines, section insets, and header/footer views.
 * It includes delegate support for dynamic sizing and spacing, section
 * collapse/expand functionality, and pinning behavior for headers and
 * footers during scrolling.
 */
@interface NSCollectionViewFlowLayout : NSCollectionViewLayout
{
  CGFloat _minimumLineSpacing;
  CGFloat _minimumInteritemSpacing;
  NSSize _itemSize;
  NSSize _estimatedItemSize;
  NSCollectionViewScrollDirection _scrollDirection;
  NSSize _headerReferenceSize;
  NSSize _footerReferenceSize;
  NSEdgeInsets _sectionInset;
  BOOL _sectionHeadersPinToVisibleBounds;
  BOOL _sectionFootersPinToVisibleBounds;
  NSMutableIndexSet *_collapsedSections;

  NSInteger _ds; // deltas for when overflow happens...
  NSInteger _dr;

}

/**
 * Returns the minimum spacing between lines in the flow layout. Line
 * spacing is measured perpendicular to the flow direction, creating
 * vertical gaps in horizontal flows and horizontal gaps in vertical
 * flows. This spacing ensures visual separation between rows or columns
 * of items, improving readability and organization of the content.
 */
- (CGFloat) minimumLineSpacing;
/**
 * Sets the minimum spacing between lines in the flow layout. The line
 * spacing creates visual separation between rows in vertical flows or
 * between columns in horizontal flows. This value serves as a minimum
 * constraint, with actual spacing potentially being larger to achieve
 * proper alignment and distribution of items within the available space.
 */
- (void) setMinimumLineSpacing: (CGFloat)spacing;

/**
 * Returns the minimum spacing between items within the same line in
 * the flow layout. Inter-item spacing is measured parallel to the flow
 * direction, creating gaps between adjacent items in the same row or
 * column. This spacing prevents items from appearing crowded and
 * enhances the visual organization of content within each line.
 */
- (CGFloat) minimumInteritemSpacing;
/**
 * Sets the minimum spacing between items within the same line. The
 * inter-item spacing creates horizontal gaps in vertical flows or
 * vertical gaps in horizontal flows between adjacent items. This value
 * serves as a minimum constraint, with actual spacing potentially being
 * larger to achieve proper item distribution and alignment.
 */
- (void) setMinimumInteritemSpacing: (CGFloat)spacing;

/**
 * Returns the default size for items in the flow layout. This size
 * is used for items when the delegate does not provide specific sizing
 * information or when no delegate is present. The item size determines
 * the default dimensions that items will have unless overridden by
 * delegate methods or other sizing constraints.
 */
- (NSSize) itemSize;
/**
 * Sets the default size for items in the flow layout. This becomes
 * the standard size used for items throughout the layout unless
 * overridden by delegate methods that provide custom sizing for
 * specific items. Setting a consistent item size helps create uniform
 * grid-like appearances in the flow layout.
 */
- (void) setItemSize: (NSSize)itemSize;

/**
 * Returns the estimated size used for items during layout calculation
 * optimization. The estimated size helps the layout system perform
 * more efficient calculations by providing size hints before exact
 * measurements are available. This is particularly useful for layouts
 * with dynamic or variable item sizes.
 */
- (NSSize) estimatedItemSize;
/**
 * Sets the estimated size for items to optimize layout calculations.
 * Providing accurate size estimates helps the layout system perform
 * better, especially when dealing with large numbers of items or
 * complex sizing requirements. The estimated size should approximate
 * the typical size of items in the collection.
 */
- (void) setEstimatedItemSize: (NSSize)size;

/**
 * Returns the primary scroll direction for the flow layout. The scroll
 * direction determines how items flow and wrap within the layout, with
 * vertical scrolling creating horizontal rows that wrap vertically, and
 * horizontal scrolling creating vertical columns that wrap horizontally.
 * This affects the overall organization and navigation of content.
 */
- (NSCollectionViewScrollDirection) scrollDirection;
/**
 * Sets the primary scroll direction for the flow layout. Changing the
 * scroll direction fundamentally alters how items are arranged and how
 * users navigate through the content. Vertical scrolling creates
 * row-based layouts, while horizontal scrolling creates column-based
 * layouts with corresponding wrapping and flow behaviors.
 */
- (void) setScrollDirection: (NSCollectionViewScrollDirection)direction;

/**
 * Returns the default reference size for section headers in the flow
 * layout. The header size determines the dimensions allocated for header
 * views, with the relevant dimension (width for vertical flow, height
 * for horizontal flow) determining the header's extent along the scroll
 * direction. A zero size indicates that headers are not displayed.
 */
- (NSSize) headerReferenceSize;
/**
 * Sets the default reference size for section headers. The header size
 * establishes the space allocated for header views within each section,
 * providing context and organization for the section's items. The size
 * can be overridden by delegate methods for section-specific header
 * sizing when more dynamic behavior is required.
 */
- (void) setHeaderReferenceSize: (NSSize)size;

/**
 * Returns the default reference size for section footers in the flow
 * layout. The footer size determines the dimensions allocated for footer
 * views, similar to headers but positioned at the end of sections. A
 * zero size indicates that footers are not displayed, while non-zero
 * sizes create space for footer content and organization.
 */
- (NSSize) footerReferenceSize;
/**
 * Sets the default reference size for section footers. The footer size
 * establishes the space allocated for footer views at the end of each
 * section, providing closure and additional context for section content.
 * Like headers, footer sizes can be customized per section through
 * delegate methods for dynamic sizing behavior.
 */
- (void) setFooterReferenceSize: (NSSize)size;

/**
 * Returns the default insets applied to sections in the flow layout.
 * Section insets create padding around the content area of each section,
 * providing visual separation between sections and from the collection
 * view edges. The insets affect the available space for item placement
 * and contribute to the overall visual organization of content.
 */
- (NSEdgeInsets) sectionInset;
/**
 * Sets the default insets for sections in the flow layout. Section
 * insets provide padding around each section's content, creating visual
 * breathing room and separation. These insets can be overridden by
 * delegate methods for section-specific spacing requirements, allowing
 * for varied visual treatment of different sections.
 */
- (void) setSectionInset: (NSEdgeInsets)inset;

/**
 * Returns whether section headers are pinned to the visible bounds
 * during scrolling. When enabled, headers remain visible at the top
 * of their sections as the user scrolls, providing continuous context
 * about the current section. This creates a sticky header effect that
 * enhances navigation and section identification during scrolling.
 */
- (BOOL) sectionHeadersPinToVisibleBounds;
/**
 * Sets whether section headers should be pinned to the visible bounds
 * during scrolling. Pinned headers stay visible at the edge of the
 * collection view as their sections scroll through, providing persistent
 * section context. This feature improves usability by maintaining
 * section identification even when scrolling through long sections.
 */
- (void) setSectionHeadersPinToVisibleBounds: (BOOL)f;

/**
 * Returns whether section footers are pinned to the visible bounds
 * during scrolling. When enabled, footers remain visible at the bottom
 * of their sections as the user scrolls, similar to header pinning
 * but for footer views. This creates persistent footer visibility that
 * can provide continuous section context or actions.
 */
- (BOOL) sectionFootersPinToVisibleBounds;
/**
 * Sets whether section footers should be pinned to the visible bounds
 * during scrolling. Pinned footers maintain their visibility at the
 * collection view edge as content scrolls, providing persistent access
 * to footer content such as section summaries, actions, or additional
 * navigation elements.
 */
- (void) setSectionFootersPinToVisibleBounds: (BOOL)f;

/**
 * Returns whether the section at the specified index is currently
 * collapsed. Collapsed sections hide their content items while typically
 * maintaining their headers and footers, providing a way to organize
 * and manage large amounts of content. This allows users to focus on
 * specific sections while minimizing visual clutter from others.
 */
- (BOOL) sectionAtIndexIsCollapsed: (NSUInteger)sectionIndex;

/**
 * Collapses the section at the specified index, hiding its content
 * items while maintaining section headers and footers. Collapsing
 * sections provides an organizational tool that allows users to manage
 * large collections by hiding sections they're not currently interested
 * in, reducing visual complexity and improving focus.
 */
- (void) collapseSectionAtIndex: (NSUInteger)sectionIndex;

/**
 * Expands the section at the specified index, revealing its content
 * items that were previously hidden due to collapse. Expanding sections
 * restores full visibility of section content, allowing users to access
 * and interact with all items within the section after it has been
 * collapsed for organizational purposes.
 */
- (void) expandSectionAtIndex: (NSUInteger)sectionIndex;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSCollectionViewFlowLayout_h_GNUSTEP_GUI_INCLUDE */

