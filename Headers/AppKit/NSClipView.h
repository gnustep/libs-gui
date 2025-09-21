/*
   NSClipView.h

   The class that contains the document view displayed by a NSScrollView.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: July 1997

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

#ifndef _GNUstep_H_NSClipView
#define _GNUstep_H_NSClipView
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSView.h>

@class NSNotification;
@class NSCursor;
@class NSColor;

APPKIT_EXPORT_CLASS
/**
 * NSClipView provides the clipping functionality for scroll views by
 * managing a document view within a constrained visible area. This class
 * serves as an intermediary between the scroll view and the content being
 * displayed, handling the translation and clipping of the document view
 * to show only the portion that should be visible within the scrollable
 * area. It manages scrolling operations, coordinate transformations, and
 * optimizations for efficient redrawing during scroll operations.
 */
@interface NSClipView : NSView
{
  NSView* _documentView;
  NSCursor* _cursor;
  NSColor* _backgroundColor;
  BOOL _drawsBackground;
  BOOL _copiesOnScroll;
  /* Cached */
  BOOL _isOpaque;
}

/* Setting the document view */
/**
 * Sets the view that will be displayed and clipped within this clip view.
 * The document view is the content that users scroll through, and this
 * clip view manages showing only the visible portion. The document view
 * can be larger than the clip view's bounds, with scrolling revealing
 * different portions of the content. Pass nil to remove the current
 * document view from the clip view.
 */
- (void)setDocumentView:(NSView*)aView;
/**
 * Returns the view that is currently set as the document view being
 * clipped and displayed. The document view contains the actual content
 * that users interact with, while this clip view handles the scrolling
 * and visible area management. Returns nil if no document view is
 * currently set for this clip view.
 */
- (id)documentView;

/* Scrolling */
/**
 * Scrolls the document view so that the specified point becomes the
 * origin of the visible area within the clip view. The point coordinates
 * are in the document view's coordinate system, allowing precise control
 * over which portion of the document content is displayed. The actual
 * scroll position may be constrained by the document and clip view bounds.
 */
- (void)scrollToPoint:(NSPoint)aPoint;
/**
 * Handles automatic scrolling during drag operations or other continuous
 * user interactions. When the event location is near the edges of the
 * clip view, this method automatically scrolls in the appropriate direction
 * to reveal content beyond the current visible area. Returns whether
 * scrolling occurred as a result of the event.
 */
- (BOOL)autoscroll:(NSEvent*)theEvent;
/**
 * Adjusts the proposed scroll origin to ensure it remains within valid
 * bounds for the current document and clip view configuration. This method
 * prevents scrolling beyond the document boundaries and ensures that the
 * visible area never extends outside the document content when possible.
 * Returns the constrained point that should be used for scrolling.
 */
- (NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin;

/* Determining scrolling efficiency */
/**
 * Sets whether the clip view should use copying optimization during
 * scroll operations. When enabled, the clip view copies pixel data
 * from overlapping areas during scrolling to reduce the amount of
 * redrawing required, improving performance for large document views.
 * When disabled, the entire visible area is redrawn on each scroll.
 */
- (void)setCopiesOnScroll:(BOOL)flag;
/**
 * Returns whether the clip view is currently using copying optimization
 * for scroll operations. Copying on scroll can significantly improve
 * performance by reusing existing pixel data for overlapping areas,
 * but may not be appropriate for all types of document content or
 * rendering situations that require complete redrawing.
 */
- (BOOL)copiesOnScroll;

/* Getting the visible portion */
/**
 * Returns the rectangle that encompasses the entire document view in
 * the clip view's coordinate system. This represents the full bounds
 * of the document content, which may extend beyond the currently visible
 * area. The rectangle indicates the total scrollable area available
 * within the clip view for the document.
 */
- (NSRect)documentRect;
/**
 * Returns the rectangle representing the currently visible portion of
 * the document view in the document's own coordinate system. This
 * indicates which part of the document content is actually displayed
 * within the clip view's bounds, useful for determining what content
 * needs to be drawn or updated during scroll operations.
 */
- (NSRect)documentVisibleRect;

/* Setting the document cursor */
/**
 * Sets the cursor that should be displayed when the mouse is over the
 * document view within this clip view. The document cursor provides
 * visual feedback to users about the type of interaction available
 * with the document content, such as text editing, resizing, or other
 * context-specific operations. Pass nil to use the default cursor.
 */
- (void)setDocumentCursor:(NSCursor*)aCursor;
/**
 * Returns the cursor that is currently set for display over the document
 * view. The document cursor indicates the type of interaction available
 * when the mouse is positioned over the document content within the clip
 * view. Returns nil if no specific document cursor has been set, in
 * which case the default cursor behavior applies.
 */
- (NSCursor*)documentCursor;

/* Setting the background color */
/**
 * Sets the background color that will be displayed in areas of the
 * clip view not covered by the document view. This color is visible
 * when the document is smaller than the clip view bounds or when
 * transparent areas exist in the document content. The background
 * color provides visual consistency for the scrollable area.
 */
- (void)setBackgroundColor:(NSColor*)aColor;
/**
 * Returns the background color currently used for areas not covered
 * by the document view. The background color fills empty space within
 * the clip view bounds, providing a consistent appearance when the
 * document is smaller than the visible area or contains transparent
 * regions that allow the background to show through.
 */
- (NSColor*)backgroundColor;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/* Setting the background drawing */
/**
 * Sets whether the clip view should draw its background color in areas
 * not covered by the document view. When enabled, the background color
 * fills empty space within the clip view bounds. When disabled, those
 * areas remain transparent, allowing views behind the clip view to
 * show through, which can be useful for layered interface designs.
 */
- (void)setDrawsBackground:(BOOL)flag;
/**
 * Returns whether the clip view is currently set to draw its background
 * color. When background drawing is enabled, the clip view fills areas
 * not occupied by the document view with the background color. When
 * disabled, these areas remain transparent, creating different visual
 * effects depending on the surrounding interface elements.
 */
- (BOOL)drawsBackground;
#endif

@end

#endif /* _GNUstep_H_NSClipView */
