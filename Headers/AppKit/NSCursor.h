/*
   NSCursor.h

   Holds an image to use as a cursor

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

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

#ifndef _GNUstep_H_NSCursor
#define _GNUstep_H_NSCursor
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>

@class NSImage;
@class NSEvent;
@class NSColor;

/**
 * NSCursor represents the visual appearance and behavior of the mouse cursor.
 * It combines an image with a hot spot that defines the precise location within
 * the image that corresponds to the cursor's position. NSCursor manages a stack
 * of active cursors and provides methods for showing, hiding, and tracking
 * cursor changes throughout the application.
 *
 * Key features include:
 * - Custom cursor creation from images with specified hot spots
 * - Predefined system cursors for common operations
 * - Cursor stack management with push/pop operations
 * - Automatic cursor changes on mouse enter/exit events
 * - System-wide cursor hiding and visibility control
 * - Support for foreground and background color hints
 *
 * NSCursor maintains a cursor stack where cursors can be pushed and popped,
 * allowing temporary cursor changes that automatically revert to previous
 * cursors. The class also provides numerous predefined cursors for standard
 * operations like text selection, resizing, and drag-and-drop operations.
 *
 * Cursor changes can be tied to mouse tracking events, automatically switching
 * cursors when the mouse enters or exits specific regions. The system can also
 * hide the cursor until the mouse moves, useful for fullscreen applications
 * or media players.
 */
APPKIT_EXPORT_CLASS
@interface NSCursor : NSObject <NSCoding>
{
  /** The image that defines the visual appearance of the cursor. */
  NSImage	*_cursor_image;

  /** The hot spot point within the cursor image that corresponds to the actual cursor position. */
  NSPoint	_hot_spot;

  /** Internal flags structure containing cursor state information. */
  struct GSCursorFlagsType {
    /** Whether this cursor is automatically set when mouse enters a tracking area. */
    unsigned int is_set_on_mouse_entered: 1;
    /** Whether this cursor is automatically set when mouse exits a tracking area. */
    unsigned int is_set_on_mouse_exited: 1;
    /** The cursor type identifier for predefined system cursors. */
    unsigned int type: 5;
    /** Reserved bits for future use. */
    unsigned int reserved: 25;
  } _cursor_flags;

  /** Platform-specific cursor identifier used by the underlying windowing system. */
  void		*_cid;
}

// Method needed on Windows to handle the cursor.
#ifdef WIN32
/**
 * Returns the count of cursor instances (Windows only).
 * This method is used internally on Windows platforms for cursor management.
 * Returns: The number of active cursor instances
 */
+ (NSUInteger) count;
#endif

/*
 * Initializing a New NSCursor Object
 */
#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/**
 * Initializes a cursor with the specified image using default hot spot.
 * The hot spot is automatically set to the center of the image.
 * newImage: The image to use for the cursor appearance
 * Returns: An initialized NSCursor object
 */
- (id) initWithImage: (NSImage *)newImage;
#endif

/**
 * Initializes a cursor with the specified image and hot spot.
 * This is the designated initializer for creating custom cursors.
 * The hot spot defines the precise pixel within the image that
 * corresponds to the cursor's position on screen.
 * newImage: The image to use for the cursor appearance
 * hotSpot: The point within the image that represents the cursor position
 * Returns: An initialized NSCursor object
 */
- (id) initWithImage: (NSImage *)newImage
	     hotSpot: (NSPoint)hotSpot;


#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Initializes a cursor with image, color hints, and hot spot.
 * This method allows for creation of cursors with color hints that may be
 * used by the underlying system to optimize cursor appearance on different
 * backgrounds or display modes. The color hints are advisory and may be
 * ignored by some systems.
 * newImage: The image to use for the cursor appearance
 * fg: Foreground color hint for the cursor
 * bg: Background color hint for the cursor
 * hotSpot: The point within the image that represents the cursor position
 * Returns: An initialized NSCursor object
 */
- (id)initWithImage:(NSImage *)newImage
foregroundColorHint:(NSColor *)fg
backgroundColorHint:(NSColor *)bg
	    hotSpot:(NSPoint)hotSpot;
#endif

/*
 * Defining the Cursor
 */
/**
 * Returns the hot spot point of the cursor.
 * The hot spot defines the precise pixel within the cursor image that
 * corresponds to the cursor's position on screen. This is typically
 * the tip of an arrow or the center of a crosshair.
 * Returns: The hot spot point within the cursor image
 */
- (NSPoint) hotSpot;

/**
 * Returns the image used for the cursor.
 * Returns: The NSImage object that defines the cursor's appearance
 */
- (NSImage*) image;

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/**
 * Sets the hot spot point of the cursor.
 * This method is used internally and should not be called directly.
 * spot: The new hot spot point within the cursor image
 */
- (void) setHotSpot: (NSPoint)spot;

/**
 * Sets the image used for the cursor.
 * This method is used internally and should not be called directly.
 * newImage: The new image to use for the cursor
 */
- (void) setImage: (NSImage *)newImage;
#endif

/*
 * Setting the Cursor
 */
/**
 * Hides the cursor system-wide.
 * The cursor becomes invisible but continues to function normally.
 * Use unhide to make the cursor visible again. Hide/unhide calls
 * are balanced, so multiple hide calls require multiple unhide calls.
 */
+ (void) hide;

/**
 * Removes the current cursor from the cursor stack.
 * This restores the previous cursor that was active before the
 * current cursor was pushed onto the stack.
 */
+ (void) pop;

/**
 * Sets whether the cursor should remain hidden until the mouse moves.
 * This is useful for applications that want to hide the cursor during
 * periods of inactivity, such as media players or fullscreen applications.
 * flag: YES to hide cursor until mouse moves, NO for normal visibility
 */
+ (void) setHiddenUntilMouseMoves: (BOOL)flag;

/**
 * Returns whether the cursor is hidden until the mouse moves.
 * Returns: YES if cursor is hidden until mouse movement, NO otherwise
 */
+ (BOOL) isHiddenUntilMouseMoves;

/**
 * Makes the cursor visible system-wide.
 * This counteracts a previous hide operation. Hide/unhide calls are
 * balanced, so the cursor becomes visible only when all hide operations
 * have been matched with unhide operations.
 */
+ (void) unhide;

/**
 * Returns whether this cursor is automatically set on mouse entered events.
 * Returns: YES if cursor is set on mouse entered events, NO otherwise
 */
- (BOOL) isSetOnMouseEntered;

/**
 * Returns whether this cursor is automatically set on mouse exited events.
 * Returns: YES if cursor is set on mouse exited events, NO otherwise
 */
- (BOOL) isSetOnMouseExited;

/**
 * Handles mouse entered events for automatic cursor switching.
 * This method is called automatically when the mouse enters a tracking
 * area that has this cursor associated with it.
 * theEvent: The mouse entered event
 */
- (void) mouseEntered: (NSEvent*)theEvent;

/**
 * Handles mouse exited events for automatic cursor switching.
 * This method is called automatically when the mouse exits a tracking
 * area that has this cursor associated with it.
 * theEvent: The mouse exited event
 */
- (void) mouseExited: (NSEvent*)theEvent;

/**
 * Removes this cursor from the cursor stack.
 * This restores the previous cursor that was active before this
 * cursor was pushed onto the stack.
 */
- (void) pop;

/**
 * Pushes this cursor onto the cursor stack and makes it current.
 * The previous cursor is preserved and can be restored by calling
 * pop on this cursor or the class method pop.
 */
- (void) push;

/**
 * Sets this cursor as the current cursor.
 * Unlike push, this method does not preserve the previous cursor
 * on a stack. The cursor remains active until another cursor is set.
 */
- (void) set;

/**
 * Sets whether this cursor should be automatically set on mouse entered events.
 * When enabled, this cursor will automatically become active when the mouse
 * enters tracking areas associated with this cursor.
 * flag: YES to enable automatic setting on mouse entered, NO to disable
 */
- (void) setOnMouseEntered: (BOOL)flag;

/**
 * Sets whether this cursor should be automatically set on mouse exited events.
 * When enabled, this cursor will automatically become active when the mouse
 * exits tracking areas associated with this cursor.
 * flag: YES to enable automatic setting on mouse exited, NO to disable
 */
- (void) setOnMouseExited: (BOOL)flag;

/*
 * Getting the Cursor
 */
/**
 * Returns the standard arrow cursor.
 * This is the default cursor used throughout the system for normal
 * pointer operations and general user interface interaction.
 * Returns: The standard arrow cursor
 */
+ (NSCursor*) arrowCursor;

/**
 * Returns the currently active cursor.
 * This method returns whichever cursor is currently being displayed,
 * whether it's a system cursor or a custom cursor.
 * Returns: The currently active NSCursor object
 */
+ (NSCursor*) currentCursor;

/**
 * Returns the I-beam cursor used for text editing.
 * This cursor indicates that the user can click to place a text
 * insertion point or drag to select text.
 * Returns: The I-beam text editing cursor
 */
+ (NSCursor*) IBeamCursor;

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/**
 * Returns a green arrow cursor (GNUstep extension).
 * This is a GNUstep-specific cursor variant not available in other systems.
 * Returns: A green-colored arrow cursor
 */
+ (NSCursor*) greenArrowCursor;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Returns the closed hand cursor used for dragging operations.
 * This cursor indicates that the user is actively dragging an item.
 * Returns: The closed hand cursor
 */
+ (NSCursor*) closedHandCursor;

/**
 * Returns the crosshair cursor used for precise selection.
 * This cursor is typically used in graphics applications for precise
 * positioning or selection operations.
 * Returns: The crosshair cursor
 */
+ (NSCursor*) crosshairCursor;

/**
 * Returns the disappearing item cursor used for item deletion.
 * This cursor indicates that an item will be deleted or removed
 * if dropped at the current location.
 * Returns: The disappearing item cursor
 */
+ (NSCursor*) disappearingItemCursor;

/**
 * Returns the open hand cursor used for draggable items.
 * This cursor indicates that an item can be grabbed and dragged.
 * Returns: The open hand cursor
 */
+ (NSCursor*) openHandCursor;

/**
 * Returns the pointing hand cursor used for clickable items.
 * This cursor indicates that an item is clickable, typically used
 * for hyperlinks or buttons.
 * Returns: The pointing hand cursor
 */
+ (NSCursor*) pointingHandCursor;

/**
 * Returns the resize down cursor used for vertical resizing.
 * This cursor indicates that the user can resize an element downward.
 * Returns: The resize down cursor
 */
+ (NSCursor*) resizeDownCursor;

/**
 * Returns the resize left cursor used for horizontal resizing.
 * This cursor indicates that the user can resize an element leftward.
 * Returns: The resize left cursor
 */
+ (NSCursor*) resizeLeftCursor;

/**
 * Returns the resize left-right cursor used for horizontal resizing.
 * This cursor indicates that the user can resize an element horizontally
 * in either direction.
 * Returns: The resize left-right cursor
 */
+ (NSCursor*) resizeLeftRightCursor;

/**
 * Returns the resize right cursor used for horizontal resizing.
 * This cursor indicates that the user can resize an element rightward.
 * Returns: The resize right cursor
 */
+ (NSCursor*) resizeRightCursor;

/**
 * Returns the resize up cursor used for vertical resizing.
 * This cursor indicates that the user can resize an element upward.
 * Returns: The resize up cursor
 */
+ (NSCursor*) resizeUpCursor;

/**
 * Returns the resize up-down cursor used for vertical resizing.
 * This cursor indicates that the user can resize an element vertically
 * in either direction.
 * Returns: The resize up-down cursor
 */
+ (NSCursor*) resizeUpDownCursor;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Returns the current system cursor.
 * This method returns the cursor that the system would normally display
 * based on the current context and application state.
 * Returns: The current system cursor
 */
+ (NSCursor*) currentSystemCursor;

/**
 * Returns the contextual menu cursor.
 * This cursor indicates that a contextual menu is available at the
 * current location, typically shown during right-click operations.
 * Returns: The contextual menu cursor
 */
+ (NSCursor*) contextualMenuCursor;

/**
 * Returns the drag copy cursor used for copy operations.
 * This cursor indicates that dragging will result in copying the item
 * to the destination location.
 * Returns: The drag copy cursor
 */
+ (NSCursor*) dragCopyCursor;

/**
 * Returns the drag link cursor used for link creation.
 * This cursor indicates that dragging will create a link to the item
 * at the destination location.
 * Returns: The drag link cursor
 */
+ (NSCursor*) dragLinkCursor;

/**
 * Returns the operation not allowed cursor.
 * This cursor indicates that the current operation cannot be performed
 * at the current location, typically shown during invalid drag operations.
 * Returns: The operation not allowed cursor
 */
+ (NSCursor*) operationNotAllowedCursor;
#endif

@end

/**
 * This enumeration defines constants for the various predefined cursor types
 * available in the system. These values are used internally to identify
 * different cursor types and map them to their corresponding system cursors.
 *
 * The values correspond to the cursor types available through the various
 * class methods of NSCursor, providing a numeric identifier for each
 * standard cursor appearance.
 */
/* Cursor types */
typedef enum {
  /** Standard arrow cursor for general pointing operations */
  GSArrowCursor = 0,
  /** I-beam cursor for text editing and selection */
  GSIBeamCursor,
  /** Drag link cursor indicating link creation during drag operations */
  GSDragLinkCursor,
  /** Operation not allowed cursor for invalid operations */
  GSOperationNotAllowedCursor,
  /** Drag copy cursor indicating copy operation during drag (value 5) */
  GSDragCopyCursor = 5,
  /** Closed hand cursor for active dragging operations (value 11) */
  GSClosedHandCursor = 11,
  /** Open hand cursor indicating draggable items */
  GSOpenHandCursor,
  /** Pointing hand cursor for clickable items like links */
  GSPointingHandCursor,
  /** Resize left cursor for leftward horizontal resizing (value 17) */
  GSResizeLeftCursor = 17,
  /** Resize right cursor for rightward horizontal resizing */
  GSResizeRightCursor,
  /** Resize left-right cursor for bidirectional horizontal resizing */
  GSResizeLeftRightCursor,
  /** Crosshair cursor for precise selection and positioning */
  GSCrosshairCursor,
  /** Resize up cursor for upward vertical resizing */
  GSResizeUpCursor,
  /** Resize down cursor for downward vertical resizing */
  GSResizeDownCursor,
  /** Resize up-down cursor for bidirectional vertical resizing */
  GSResizeUpDownCursor,
  /** Contextual menu cursor indicating available context menu */
  GSContextualMenuCursor,
  /** Disappearing item cursor for item deletion operations */
  GSDisappearingItemCursor,
  /** Green arrow cursor (GNUstep extension) */
  GSGreenArrowCursor
} GSCursorTypes;

#endif /* _GNUstep_H_NSCursor */
