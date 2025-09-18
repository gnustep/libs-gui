/* -*-objc-*-
   NSDrawer.h

   The drawer class

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Fred Kiefer <FredKiefer@gmx.de>
   Date: 2001

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

/**
 * <title>NSDrawer</title>
 * <abstract>Sliding panel attachment for window interfaces</abstract>
 *
 * NSDrawer provides a sliding panel interface that can be attached to any
 * edge of a parent window. The drawer slides out from the window edge to
 * reveal additional content, providing space-efficient access to secondary
 * controls, information, or tools without permanently consuming screen space.
 *
 * Key features include:
 * - Attachment to any window edge (top, bottom, left, right)
 * - Smooth sliding animations for open/close operations
 * - Flexible content sizing with minimum and maximum constraints
 * - Offset positioning for precise alignment along the window edge
 * - Delegate-based control over opening/closing behavior
 * - State tracking for open, closed, opening, and closing states
 * - Notification system for drawer state changes
 *
 * The drawer maintains its own content view and can contain any standard
 * AppKit controls or custom views. Size management allows for dynamic
 * content with optional minimum and maximum size constraints. Leading and
 * trailing offsets provide fine-grained control over drawer positioning
 * along the window edge.
 *
 * Common use cases include tool palettes, inspectors, navigation panels,
 * and contextual information displays. The drawer integrates seamlessly
 * with the window system and respects standard window management conventions.
 */

#ifndef _GNUstep_H_NSDrawer
#define _GNUstep_H_NSDrawer
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>
#import <AppKit/NSResponder.h>

@class NSWindow;
@class NSView;
@class NSNotification;

enum {
  NSDrawerClosedState  = 0,
  NSDrawerOpeningState = 1,
  NSDrawerOpenState    = 2,
  NSDrawerClosingState = 3
};

APPKIT_EXPORT_CLASS
@interface NSDrawer : NSResponder
{
  // Attributes
  id _delegate;
  id _drawerWindow;
  NSRectEdge _preferredEdge;
  NSRectEdge _currentEdge;
  NSSize _maxContentSize;
  NSSize _minContentSize;
  NSSize _contentSize;
  CGFloat _leadingOffset;
  CGFloat _trailingOffset;
  NSInteger _state;
}

// Creation

/**
 * Initializes a drawer with specified content size and preferred edge.
 * contentSize: The initial size of the drawer's content area
 * edge: The preferred window edge for drawer attachment (NSMinXEdge, NSMaxXEdge, NSMinYEdge, NSMaxYEdge)
 * Returns: An initialized NSDrawer instance
 */
- (id) initWithContentSize: (NSSize)contentSize
	     preferredEdge: (NSRectEdge)edge;

// Opening and Closing

/**
 * Closes the drawer with default animation.
 * If the drawer is already closed or closing, this method has no effect.
 */
- (void) close;

/**
 * Closes the drawer in response to user action.
 * sender: The object that initiated the close action (typically a control)
 */
- (void) close: (id)sender;

/**
 * Opens the drawer with default animation on the preferred edge.
 * If the drawer is already open or opening, this method has no effect.
 */
- (void) open;

/**
 * Opens the drawer in response to user action.
 * sender: The object that initiated the open action (typically a control)
 */
- (void) open: (id)sender;

/**
 * Opens the drawer on a specific edge of the parent window.
 * edge: The window edge on which to open the drawer
 */
- (void) openOnEdge: (NSRectEdge)edge;

/**
 * Toggles the drawer state between open and closed.
 * sender: The object that initiated the toggle action (typically a control)
 */
- (void) toggle: (id)sender;

// Managing Size

/**
 * Returns the current content size of the drawer.
 * Returns: NSSize representing the drawer's content dimensions
 */
- (NSSize) contentSize;

/**
 * Returns the leading offset along the window edge.
 * The leading offset determines spacing from the edge start to drawer start.
 * Returns: The leading offset in points
 */
- (CGFloat) leadingOffset;

/**
 * Returns the maximum allowed content size for the drawer.
 * Returns: NSSize representing maximum width and height constraints
 */
- (NSSize) maxContentSize;

/**
 * Returns the minimum allowed content size for the drawer.
 * Returns: NSSize representing minimum width and height constraints
 */
- (NSSize) minContentSize;

/**
 * Sets the content size of the drawer.
 * size: The new content size (will be constrained by min/max limits)
 */
- (void) setContentSize: (NSSize)size;

/**
 * Sets the leading offset along the window edge.
 * offset: The leading offset in points from the edge start
 */
- (void) setLeadingOffset: (CGFloat)offset;

/**
 * Sets the maximum allowed content size for the drawer.
 * size: The maximum size constraints for width and height
 */
- (void) setMaxContentSize: (NSSize)size;

/**
 * Sets the minimum allowed content size for the drawer.
 * size: The minimum size constraints for width and height
 */
- (void) setMinContentSize: (NSSize)size;

/**
 * Sets the trailing offset along the window edge.
 * offset: The trailing offset in points from the edge end
 */
- (void) setTrailingOffset: (CGFloat)offset;

/**
 * Returns the trailing offset along the window edge.
 * The trailing offset determines spacing from drawer end to edge end.
 * Returns: The trailing offset in points
 */
- (CGFloat) trailingOffset;

// Managing Edge

/**
 * Returns the window edge where the drawer is currently attached.
 * Returns: NSRectEdge indicating the current attachment edge
 */
- (NSRectEdge) edge;

/**
 * Returns the preferred edge for drawer attachment.
 * Returns: NSRectEdge indicating the preferred attachment edge
 */
- (NSRectEdge) preferredEdge;

/**
 * Sets the preferred edge for drawer attachment.
 * preferredEdge: The window edge where the drawer should preferentially attach
 */
- (void) setPreferredEdge: (NSRectEdge)preferredEdge;

// Managing Views

/**
 * Returns the drawer's content view.
 * The content view contains all the drawer's visible content and controls.
 * Returns: The NSView serving as the drawer's content container
 */
- (NSView *) contentView;

/**
 * Returns the parent window to which the drawer is attached.
 * Returns: The NSWindow that owns this drawer, or nil if not attached
 */
- (NSWindow *) parentWindow;

/**
 * Sets the drawer's content view.
 * aView: The NSView to use as the drawer's content container
 */
- (void) setContentView: (NSView *)aView;

/**
 * Sets the parent window for drawer attachment.
 * parent: The NSWindow to which this drawer should be attached
 */
- (void) setParentWindow: (NSWindow *)parent;

// Delegation and State

/**
 * Returns the drawer's delegate object.
 * Returns: The object serving as the drawer's delegate, or nil if none is set
 */
- (id) delegate;

/**
 * Sets the drawer's delegate object.
 * anObject: The object to serve as the drawer's delegate (should implement NSDrawerDelegate methods)
 */
- (void) setDelegate: (id)anObject;

/**
 * Returns the current state of the drawer.
 * Returns: NSInteger representing the drawer state (closed, opening, open, closing)
 */
- (NSInteger) state;

@end

/**
 * <title>NSDrawerDelegate</title>
 * <abstract>Protocol for drawer delegate methods</abstract>
 *
 * The NSDrawerDelegate protocol defines methods that a delegate object
 * can implement to control drawer behavior and respond to state changes.
 * Delegate methods provide fine-grained control over opening/closing
 * operations and content resizing.
 */
@interface NSDrawerDelegate

/**
 * Asks the delegate whether the drawer should close.
 * sender: The drawer requesting to close
 * Returns: YES to allow closing, NO to prevent it
 */
- (BOOL) drawerShouldClose: (NSDrawer *)sender;

/**
 * Asks the delegate whether the drawer should open.
 * sender: The drawer requesting to open
 * Returns: YES to allow opening, NO to prevent it
 */
- (BOOL) drawerShouldOpen: (NSDrawer *)sender;

/**
 * Allows the delegate to modify the drawer's content size during resizing.
 * sender: The drawer being resized
 * contentSize: The proposed new content size
 * Returns: The actual content size to use (may be different from proposed)
 */
- (NSSize) drawerWillResizeContents: (NSDrawer *)sender
			    toSize: (NSSize)contentSize;

/**
 * Notifies the delegate that the drawer has finished closing.
 * notification: NSNotification containing drawer information
 */
- (void) drawerDidClose: (NSNotification *)notification;

/**
 * Notifies the delegate that the drawer has finished opening.
 * notification: NSNotification containing drawer information
 */
- (void) drawerDidOpen: (NSNotification *)notification;

/**
 * Notifies the delegate that the drawer is about to close.
 * notification: NSNotification containing drawer information
 */
- (void) drawerWillClose: (NSNotification *)notification;

/**
 * Notifies the delegate that the drawer is about to open.
 * notification: NSNotification containing drawer information
 */
- (void) drawerWillOpen: (NSNotification *)notification;
@end

// Notifications

/**
 * Notification posted when a drawer has finished closing.
 * The notification object is the NSDrawer that closed.
 */
APPKIT_EXPORT NSString *NSDrawerDidCloseNotification;

/**
 * Notification posted when a drawer has finished opening.
 * The notification object is the NSDrawer that opened.
 */
APPKIT_EXPORT NSString *NSDrawerDidOpenNotification;

/**
 * Notification posted when a drawer is about to close.
 * The notification object is the NSDrawer that will close.
 */
APPKIT_EXPORT NSString *NSDrawerWillCloseNotification;

/**
 * Notification posted when a drawer is about to open.
 * The notification object is the NSDrawer that will open.
 */
APPKIT_EXPORT NSString *NSDrawerWillOpenNotification;

#endif // _GNUstep_H_NSDrawer

