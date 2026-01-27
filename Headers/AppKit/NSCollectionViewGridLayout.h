/* Definition of class NSCollectionViewGridLayout
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

#ifndef _NSCollectionViewGridLayout_h_GNUSTEP_GUI_INCLUDE
#define _NSCollectionViewGridLayout_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSGeometry.h>
#import <AppKit/NSCollectionViewLayout.h>
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewGridLayout provides a concrete implementation of
 * NSCollectionViewLayout that arranges collection view items in a
 * structured grid pattern. This layout automatically calculates item
 * positions based on configurable constraints including maximum row
 * and column counts, item size limits, margins, and inter-item spacing.
 * It provides a flexible grid system that can adapt to different content
 * sizes while maintaining consistent visual organization and alignment.
 */
@interface NSCollectionViewGridLayout : NSCollectionViewLayout
{
  NSUInteger _maximumNumberOfRows;
  NSUInteger _maximumNumberOfColumns;
  NSSize _minimumItemSize;
  NSSize _maximumItemSize;
  NSEdgeInsets _margins;
  CGFloat _minimumInteritemSpacing;
}

/**
 * Sets the maximum number of rows that the grid layout will display
 * before wrapping items to additional columns. This constraint controls
 * the vertical extent of the grid and affects how items flow and wrap
 * within the layout. When the row limit is reached, additional items
 * will be arranged in subsequent columns, creating a multi-column
 * grid structure.
 */
- (void) setMaximumNumberOfRows: (NSUInteger)maxRows;
/**
 * Returns the maximum number of rows currently configured for the grid
 * layout. This value determines the vertical constraint that controls
 * item arrangement and wrapping behavior. The row limit affects the
 * overall shape and organization of the grid, influencing how items
 * are distributed across the available space.
 */
- (NSUInteger) maximumNumberOfRows;

/**
 * Sets the maximum number of columns that the grid layout will display
 * before wrapping items to additional rows. This constraint controls
 * the horizontal extent of the grid and determines the item flow pattern.
 * When the column limit is reached, additional items will be arranged
 * in subsequent rows, creating a structured grid with consistent
 * horizontal organization.
 */
- (void) setMaximumNumberOfColumns: (NSUInteger)maxCols;
/**
 * Returns the maximum number of columns currently configured for the
 * grid layout. This value determines the horizontal constraint that
 * controls item arrangement and wrapping behavior. The column limit
 * affects the grid's aspect ratio and how items are distributed
 * across the horizontal space of the collection view.
 */
- (NSUInteger) maximumNumberOfColumns;

/**
 * Sets the minimum size that items in the grid layout must maintain.
 * Items will not be sized smaller than this constraint, ensuring they
 * remain visible and usable regardless of available space or content
 * requirements. This minimum size provides a lower bound that maintains
 * item accessibility and visual consistency across the grid layout.
 */
- (void) setMinimumItemSize: (NSSize)minSize;
/**
 * Returns the minimum size constraint currently applied to items in
 * the grid layout. This size represents the smallest dimensions that
 * items will be allowed to have, ensuring they remain visible and
 * functional. The minimum size constraint helps maintain consistent
 * item presentation and prevents items from becoming too small to use.
 */
- (NSSize) minimumItemSize;

/**
 * Sets the maximum size that items in the grid layout are allowed to
 * reach. Items will not be sized larger than this constraint, preventing
 * them from dominating the layout or disrupting the grid's visual
 * balance. This maximum size provides an upper bound that maintains
 * proportional item relationships and consistent grid organization.
 */
- (void) setMaximumItemSize: (NSSize)maxSize;
/**
 * Returns the maximum size constraint currently applied to items in
 * the grid layout. This size represents the largest dimensions that
 * items will be allowed to have, preventing oversized items from
 * disrupting the grid's structure. The maximum size constraint helps
 * maintain visual harmony and proportional relationships between items.
 */
- (NSSize) maximumItemSize;

/**
 * Sets the margin insets that define the spacing between the grid
 * content and the edges of the collection view. Margins provide visual
 * breathing room around the entire grid, creating separation from the
 * collection view boundaries. The insets specify top, left, bottom,
 * and right margins that frame the grid layout within the available space.
 */
- (void) setMargins: (NSEdgeInsets)insets;
/**
 * Returns the current margin insets applied to the grid layout. The
 * margins define the spacing between the grid content and the collection
 * view edges, providing visual separation and framing for the grid.
 * These insets affect the available space for item placement and
 * contribute to the overall visual presentation of the layout.
 */
- (NSEdgeInsets) margins;

/**
 * Sets the minimum spacing between adjacent items in the grid layout.
 * This spacing creates visual separation between items, improving
 * readability and organization. The inter-item spacing is applied
 * uniformly between items both horizontally and vertically, contributing
 * to the grid's visual structure and preventing items from appearing
 * crowded or overlapping.
 */
- (void) setMinimumInteritemSpacing: (CGFloat)spacing;
/**
 * Returns the current minimum spacing applied between adjacent items
 * in the grid layout. This spacing value determines the visual
 * separation between items and contributes to the grid's overall
 * appearance and organization. Consistent inter-item spacing helps
 * create a clean, structured layout that enhances content readability.
 */
- (CGFloat) minimumInteritemSpacing;


@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSCollectionViewGridLayout_h_GNUSTEP_GUI_INCLUDE */

