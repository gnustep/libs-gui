/*
   NSWindow.h

   The window class

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Modified:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: June 1998
   Modified:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:  1998,1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSWindow
#define _GNUstep_H_NSWindow

#include <Foundation/NSDate.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSEvent.h>

@class NSArray;
@class NSData;
@class NSDate;
@class NSDictionary;
@class NSMutableArray;
@class NSNotification;
@class NSString;

@class NSButtonCell;
@class NSColor;
@class NSEvent;
@class NSImage;
@class NSMenu;
@class NSPasteboard;
@class NSScreen;
@class NSText;
@class NSToolbar; 
@class NSView;
@class NSWindowController;
@class NSCachedImageRep;

@class GSWindowDecorationView;

/*
 * Window levels are taken from MacOS-X
 * NSDesktopWindowLevel is copied from Window maker and is intended to be
 * the level at which things on the desktop sit ... so you should be able
 * to put a desktop background just below it.
 */
enum {
  NSDesktopWindowLevel = -1000,	/* GNUstep addition	*/
  NSNormalWindowLevel = 0,
  NSFloatingWindowLevel = 3,
  NSSubmenuWindowLevel = 3,
  NSTornOffMenuWindowLevel = 3,
  NSMainMenuWindowLevel = 20,
  NSDockWindowLevel = 21,	/* Deprecated - use NSStatusWindowLevel */
  NSStatusWindowLevel = 21,
  NSModalPanelWindowLevel = 100,
  NSPopUpMenuWindowLevel = 101,
  NSScreenSaverWindowLevel = 1000
};

enum {
  NSBorderlessWindowMask = 0,
  NSTitledWindowMask = 1,
  NSClosableWindowMask = 2,
  NSMiniaturizableWindowMask = 4,
  NSResizableWindowMask = 8,
  NSIconWindowMask = 64,	/* GNUstep extension - app icon window	*/
  NSMiniWindowMask = 128	/* GNUstep extension - miniwindows	*/
};

typedef enum _NSSelectionDirection {
  NSDirectSelection,
  NSSelectingNext,
  NSSelectingPrevious
} NSSelectionDirection;

APPKIT_EXPORT NSSize NSIconSize;
APPKIT_EXPORT NSSize NSTokenSize;

/**
 * <p>An NSWindow instance represents a window, panel or menu on the
 * screen.<br />
 * Each window has a style, which determines how the window is decorated:
 * ie whether it has a border, a title bar, a resize bar, minimise and
 * close buttons.
 * </p>
 * <p>A window has a <em>frame</em>. This is the frame of the <em>entire</em>
 * window on the screen, including all decorations and borders.  The origin
 * of the frame represents its bottom left corner and the frame is expressed
 * in screen coordinates (see [NSScreen]).<br />
 * </p>
 * <p>When a window is created, it has a <em>private</em> [NSView] instance
 * which fills the entire window frame and whose coordinate system is the
 * same as the base coordinate system of the window (ie zero x and
 * y coordinates are at the bottom left corner of the window, with increasing
 * x and y corresponding to points to the right and above the origin).<br />
 * This view may be used by the library internals (and theme engines) to
 * draw window decorations if the backend library is not handling the
 * window decorations.
 * </p>
 * <p>A window always contains a <em>content view<em> which is the highest
 * level view available for public (application) use.  This view fills the
 * area of the window inside any decoration/border.<br />
 * This is the only part of the window that application programmers are
 * allowed to draw in directly.
 * </p>
 * <p>You can convert between view coordinates and window base coordinates
 * using the [NSView-convertPoint:fromView:], [NSView-convertPoint:toView:],
 * [NSView-convertRect:fromView:], and [NSView-convertRect:toView:]
 * methods with a nil view argument.<br />
 * You can convert between window and screen coordinates using the
 * -convertBaseToScreen: and -convertScreenToBase: methods.
 * </p>
 */
@interface NSWindow : NSResponder <NSCoding>
{
  NSRect        _frame;
  NSSize        _minimumSize;
  NSSize        _maximumSize;
  NSSize        _increments;
  NSString	*_autosaveName;
  GSWindowDecorationView *_wv;
  id            _contentView;
  id            _firstResponder;
  id            _futureFirstResponder;
  NSView        *_initialFirstResponder;
  id            _delegate;
  id            _fieldEditor;
  id            _lastView;
  id            _lastDragView;
  int           _lastDragOperationMask;
  int           _windowNum;
  int           _gstate;
  void          *_reserved_s;
  NSScreen      *_screen;
  NSColor       *_backgroundColor;
  NSString      *_representedFilename;
  NSString      *_miniaturizedTitle;
  NSImage       *_miniaturizedImage;
  NSString      *_windowTitle;
  NSPoint       _lastPoint;
  NSBackingStoreType _backingType;
  unsigned      _styleMask;
  int           _windowLevel;
  NSRect        _rectNeedingFlush;
  NSMutableArray *_rectsBeingDrawn;
  unsigned	_disableFlushWindow;
  NSSelectionDirection _selectionDirection;

  NSWindowDepth _depthLimit;
  NSWindowController *_windowController;
  int		_counterpart;
  float         _alphaValue;
  
  NSToolbar    *_toolbar; // Not used (see NSWindow+Toolbar now)
  id            _toolbarView; // Not used (see NSWindow+Toolbar now)
  NSCachedImageRep *_cachedImage;
  NSPoint       _cachedImageOrigin;

  struct GSWindowFlagsType {
    unsigned	accepts_drag:1;
    unsigned	is_one_shot:1;
    unsigned	needs_flush:1;
    unsigned	is_autodisplay:1;
    unsigned	optimize_drawing:1;
    unsigned	dynamic_depth_limit:1;
    unsigned	cursor_rects_enabled:1;
    unsigned	cursor_rects_valid:1;
    unsigned	visible:1;
    unsigned	is_key:1;
    unsigned	is_main:1;
    unsigned	is_edited:1;
    unsigned	is_released_when_closed:1;
    unsigned	is_miniaturized:1;
    unsigned	menu_exclude:1;
    unsigned	hides_on_deactivate:1;
    unsigned	accepts_mouse_moved:1;
    unsigned	has_opened:1;
    unsigned	has_closed:1;
    unsigned	default_button_cell_key_disabled:1;
    unsigned	can_hide:1;
    unsigned	has_shadow:1;
    unsigned	is_opaque:1;
    // 3 bits reserved for subclass use
    unsigned subclass_bool_one: 1;
    unsigned subclass_bool_two: 1;
    unsigned subclass_bool_three: 1;
  } _f;
 
  id _defaultButtonCell;
  void          *_reserved_1;
  void          *_reserved_2;
  
}

/*
 * Class methods
 */

/*
 * Computing frame and content rectangles
 */

/**
 * Returns the rectangle which would be used for the content view of
 * a window whose on-screen size and position is specified by aRect
 * and which is decorated with the border and title etc given by aStyle.<br />
 * Both rectangles are expressed in screen coordinates.
 */
+ (NSRect) contentRectForFrameRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle;

/**
 * Returns the rectangle which would be used for the on-screen frame of
 * a window if that window had a content view occupying the rectangle aRect
 * and was decorated with the border and title etc given by aStyle.<br />
 * Both rectangles are expressed in screen coordinates.
 */
+ (NSRect) frameRectForContentRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle;

/**
 * Returns the smallest frame width that will fit the given title
 * and style.  This is the on-screen width of the window including
 * decorations.
 */
+ (float) minFrameWidthWithTitle: (NSString *)aTitle
		       styleMask: (unsigned int)aStyle;


/*
 * Initializing and getting a new NSWindow object
 */
- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag;

/**
 * Creates a new window with the specified characteristics.<br />
 * The contentRect is expressed in screen coordinates (for aScreen)
 * and the window frame is calculated from the content rectangle and
 * the window style mask.
 */
- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
		    screen: (NSScreen*)aScreen;

/**
 * Converts aPoint from the base coordinate system of the receiver
 * to a point in the screen coordinate system.
 */
- (NSPoint) convertBaseToScreen: (NSPoint)aPoint;

/**
 * Converts aPoint from the screen coordinate system to a point in
 * the base coordinate system of the receiver.
 */
- (NSPoint) convertScreenToBase: (NSPoint)aPoint;

/**
 * Returns the frame of the receiver ... the rectangular area that the window
 * (including any border, title, and other decorations) occupies on screen.
 */
- (NSRect) frame;

/**
 * <p>Sets the frame for the receiver to frameRect and if flag is YES causes
 * the window contents to be refreshed.  The value of frameRect is the
 * desired on-screen size and position of the window including all
 * border/decoration.
 * </p>
 * <p>The size of the frame is constrained to the minimum and maximum
 * sizes set for the receiver (if any).<br />
 * Its position is constrained to be on screen if it is a titled window.
 * </p>
 */
- (void) setFrame: (NSRect)frameRect
	  display: (BOOL)flag;

/**
 * Sets the origin (bottom left corner) of the receiver's frame to be the
 * specified point (in screen coordinates).
 */
- (void) setFrameOrigin: (NSPoint)aPoint;

/**
 * Sets the top left corner of the receiver's frame to be the
 * specified point (in screen coordinates).
 */
- (void) setFrameTopLeftPoint: (NSPoint)aPoint;

/**
 * Sets the size of the receiver's content view  to aSize, implicitly
 * adjusting the size of the receiver's frame to match.
 */
- (void) setContentSize: (NSSize)aSize;

/**
 * Positions the receiver at topLeftPoint (or if topLeftPoint is NSZeroPoint,
 * leaves the receiver unmoved except for any necessary constraint to fit
 * on screen).<br />
 * Returns the position of the top left corner of the receivers content
 * view (after repositioning), so that another window cascaded at the
 * returned point will not obscure the title bar of the receiver.
 */
- (NSPoint) cascadeTopLeftFromPoint: (NSPoint)topLeftPoint;

- (void) center;
- (int) resizeFlags;
#ifndef STRICT_OPENSTEP
- (void) setFrame: (NSRect)frameRect
	  display: (BOOL)displayFlag
	  animate: (BOOL)animationFlag;
- (NSTimeInterval) animationResizeTime: (NSRect)newFrame;
- (void) performZoom: (id)sender;
- (void) zoom: (id)sender;
- (BOOL) showsResizeIndicator;
- (void) setShowsResizeIndicator: (BOOL)show;
#endif

/*
 * Constraining size
 */
- (NSSize) minSize;
- (NSSize) maxSize;
- (void) setMinSize: (NSSize)aSize;
- (void) setMaxSize: (NSSize)aSize;
- (NSRect) constrainFrameRect: (NSRect)frameRect
		     toScreen: (NSScreen*)screen;
#ifndef STRICT_OPENSTEP
- (NSSize) aspectRatio;
- (void) setAspectRatio: (NSSize)ratio;
- (NSSize) resizeIncrements;
- (void) setResizeIncrements: (NSSize)aSize;
#endif

/*
 * Saving and restoring the frame
 */
+ (void) removeFrameUsingName: (NSString*)name;
- (NSString*) frameAutosaveName;
- (void) saveFrameUsingName: (NSString*)name;
- (BOOL) setFrameAutosaveName: (NSString*)name;
- (void) setFrameFromString: (NSString*)string;
- (BOOL) setFrameUsingName: (NSString*)name;
- (NSString*) stringWithSavedFrame;
#ifndef STRICT_OPENSTEP
- (BOOL) setFrameUsingName: (NSString *)name
		     force: (BOOL)force;
#endif

/*
 * Window status and ordering
 */
- (void) orderBack: sender;
- (void) orderFront: sender;
- (void) orderFrontRegardless;
- (void) orderOut: (id)sender;
- (void) orderWindow: (NSWindowOrderingMode)place
	  relativeTo: (int)otherWin;
- (BOOL) isVisible;
- (int) level;
- (void) setLevel: (int)newLevel;

- (void) becomeKeyWindow;
- (void) becomeMainWindow;
- (BOOL) canBecomeKeyWindow;
- (BOOL) canBecomeMainWindow;
- (BOOL) isKeyWindow;
- (BOOL) isMainWindow;
- (void) makeKeyAndOrderFront: (id)sender;
- (void) makeKeyWindow;
- (void) makeMainWindow;
- (void) resignKeyWindow;
- (void) resignMainWindow;

#ifndef STRICT_OPENSTEP
- (NSButtonCell*) defaultButtonCell;
- (void) setDefaultButtonCell: (NSButtonCell*)aCell;
- (void) disableKeyEquivalentForDefaultButtonCell;
- (void) enableKeyEquivalentForDefaultButtonCell;
#endif

/*
 * Managing the display
 */
- (void) display;
- (void) displayIfNeeded;
- (BOOL) isAutodisplay;
- (void) setAutodisplay: (BOOL)flag;
- (void) setViewsNeedDisplay: (BOOL)flag;
- (void) update;
- (void) useOptimizedDrawing: (BOOL)flag;
- (BOOL) viewsNeedDisplay;

- (BOOL) isFlushWindowDisabled;
- (void) disableFlushWindow;
- (void) enableFlushWindow;
- (void) flushWindow;
- (void) flushWindowIfNeeded;

#ifndef STRICT_OPENSTEP
- (void) cacheImageInRect: (NSRect)aRect;
- (void) discardCachedImage;
- (void) restoreCachedImage;
#endif

/*
 * Window device attributes
 */
- (int) windowNumber;
- (int) gState;
- (NSDictionary*) deviceDescription;
- (NSBackingStoreType) backingType;
- (void) setBackingType: (NSBackingStoreType)type;
- (BOOL) isOneShot;
- (void) setOneShot: (BOOL)flag;

/*
 * Screens and window depths
 */
+ (NSWindowDepth) defaultDepthLimit;
- (BOOL) canStoreColor;
- (NSWindowDepth) depthLimit;
- (BOOL) hasDynamicDepthLimit;
- (void) setDepthLimit: (NSWindowDepth)limit;
- (void) setDynamicDepthLimit: (BOOL)flag;

- (NSScreen*) deepestScreen;
- (NSScreen*) screen;

- (NSResponder*) firstResponder;

/**
 * This method attempts to make aResponder the first responder.<br />
 * If aResponder is already the first responder, this method has no
 * effect and simply returns YES.
 * Otherwise, the method sends a -resignFirstResponder message to the
 * current first responder (if there is one) and immediately returns NO if
 * the current first responder refuses to resign.<br />
 * Then the method asks aResponder to become first responder by sending
 * it a -becomeFirstResponder message, and if that returns YES then this
 * method immediately returns YES.<br />
 * However, if that returns NO, the receiver is made the first responder by
 * sending it a -becomeFirstResponder message, and this method returns NO.<br />
 * If aResponder is neither nil nor an instance of NSResponder (or of a
 * subclass of NSResponder) then behavior is undefined (though the current
 * GNUstep implementation just returns NO).
 */
- (BOOL) makeFirstResponder: (NSResponder*)aResponder;

/*
 * Aiding event handling
 */
- (NSEvent*) currentEvent;
- (NSEvent*) nextEventMatchingMask: (unsigned int)mask;
- (NSEvent*) nextEventMatchingMask: (unsigned int)mask
			 untilDate: (NSDate*)expiration
			    inMode: (NSString*)mode
			   dequeue: (BOOL)deqFlag;
- (void) discardEventsMatchingMask: (unsigned int)mask
		       beforeEvent: (NSEvent*)lastEvent;
- (void) postEvent: (NSEvent*)event
	   atStart: (BOOL)flag;
- (void) sendEvent: (NSEvent*)theEvent;
- (BOOL) tryToPerform: (SEL)anAction with: (id)anObject;
- (void) keyDown: (NSEvent*)theEvent;
- (NSPoint) mouseLocationOutsideOfEventStream;
- (BOOL) acceptsMouseMovedEvents;
- (void) setAcceptsMouseMovedEvents: (BOOL)flag;

/*
 * The field editor
 */
- (void) endEditingFor: anObject;
- (NSText*) fieldEditor: (BOOL)createFlag
	      forObject: (id)anObject;

#ifndef STRICT_OPENSTEP
- (NSView*) initialFirstResponder;
- (NSSelectionDirection) keyViewSelectionDirection;
- (void) selectKeyViewFollowingView: (NSView*)aView;
- (void) selectKeyViewPrecedingView: (NSView*)aView;
- (void) selectNextKeyView: (id)sender;
- (void) selectPreviousKeyView: (id)sender;
- (void) setInitialFirstResponder: (NSView*)aView;
#endif

/*
 * Window graphics
 */
- (NSString*) representedFilename;
- (void) setRepresentedFilename: (NSString*)aString;
- (void) setTitle: (NSString*)aString;
- (void) setTitleWithRepresentedFilename: (NSString*)aString;
- (NSString*) title;

- (BOOL) isDocumentEdited;
- (void) setDocumentEdited: (BOOL)flag;

/*
 * Handling user actions and events
 */
- (void) close;
- (void) performClose: (id)sender;
- (void) setReleasedWhenClosed: (BOOL)flag;
- (BOOL) isReleasedWhenClosed;

- (void) deminiaturize: (id)sender;
- (void) miniaturize: (id)sender;
- (void) performMiniaturize: (id)sender;
- (BOOL) isMiniaturized;

/*
 * The miniwindow
 */
- (NSImage*) miniwindowImage;
- (NSString*) miniwindowTitle;
- (void) setMiniwindowImage: (NSImage*)image;
- (void) setMiniwindowTitle: (NSString*)title;
#ifndef	NO_GNUSTEP
- (NSWindow*) counterpart;
#endif

#ifndef STRICT_OPENSTEP
+ (void) menuChanged: (NSMenu*)aMenu;
#endif

/*
 * Windows menu support
 */
- (BOOL) isExcludedFromWindowsMenu;
- (void) setExcludedFromWindowsMenu: (BOOL)flag;

/*
 * Cursor management
 */
- (BOOL) areCursorRectsEnabled;
- (void) disableCursorRects;
- (void) discardCursorRects;
- (void) enableCursorRects;
- (void) invalidateCursorRectsForView: (NSView*)aView;
- (void) resetCursorRects;

/*
 * Dragging
 */
- (void) dragImage: (NSImage*)anImage
		at: (NSPoint)baseLocation
	    offset: (NSSize)initialOffset
	     event: (NSEvent*)event
	pasteboard: (NSPasteboard*)pboard
	    source: sourceObject
	 slideBack: (BOOL)slideFlag;
- (void) registerForDraggedTypes: (NSArray*)newTypes;
- (void) unregisterDraggedTypes;

- (BOOL) hidesOnDeactivate;
- (void) setHidesOnDeactivate: (BOOL)flag;
- (BOOL) worksWhenModal;
#ifndef STRICT_OPENSTEP
- (void) setCanHide: (BOOL)flag;
- (BOOL) canHide;
#endif

/*
 * Accessing the content view
 */
- (id) contentView;
- (void) setContentView: (NSView*)aView;
- (void) setBackgroundColor: (NSColor*)color;
- (NSColor*) backgroundColor;
- (unsigned int) styleMask;
#ifndef STRICT_OPENSTEP
- (void) setHasShadow: (BOOL)hasShadow;
- (BOOL) hasShadow;
- (void) setAlphaValue: (float)windowAlpha;
- (float) alphaValue;
- (void) setOpaque: (BOOL)isOpaque;
- (BOOL) isOpaque;
#endif

/*
 * Services menu support
 */
- (id) validRequestorForSendType: (NSString*)sendType
		      returnType: (NSString*)returnType;

/*
 * Printing and postscript
 */
- (void) fax: (id)sender;
- (void) print: (id)sender;
- (NSData*) dataWithEPSInsideRect: (NSRect)rect;
#ifndef STRICT_OPENSTEP
- (NSData*) dataWithPDFInsideRect:(NSRect)aRect;
#endif

/*
 * Assigning a delegate
 */
- (id) delegate;
- (void) setDelegate: (id)anObject;

/*
 * The window controller
 */
- (void) setWindowController: (NSWindowController*)windowController;
- (id) windowController;

#ifndef STRICT_OPENSTEP
- (NSArray *) drawers;
- (id) initWithWindowRef: (void *)windowRef;
- (void *)windowRef;
- (void*) windowHandle;
#endif
@end

#ifndef NO_GNUSTEP
/*
 * GNUstep backend methods
 */
@interface NSWindow (GNUstepBackend)

/*
 * Mouse capture/release
 */
- (void) _captureMouse: (id)sender;
- (void) _releaseMouse: (id)sender;

/*
 * Allow subclasses to init without the backend class
 * attempting to create an actual window
 */
- (void) _initDefaults;

/*
 * Let backend set window visibility.
 */
- (void) _setVisible: (BOOL)flag;

@end
#endif

#ifndef NO_GNUSTEP
@interface NSWindow (GNUstepTextView)
/*
 * Called from NSTextView's resignFirstResponder to know which is 
 * the next first responder.
 */
- (id) _futureFirstResponder;
@end
#endif

/*
 * Implemented by the delegate
 */

#ifdef GNUSTEP
@interface NSObject (NSWindowDelegate)
- (BOOL) windowShouldClose: (id)sender;
#ifndef STRICT_OPENSTEP
- (BOOL) windowShouldZoom: (NSWindow*)sender
		  toFrame: (NSRect)aFrame;
- (NSRect) windowWillUseStandardFrame: (NSWindow*)sender
			 defaultFrame: (NSRect)aFrame;
#endif
- (NSSize) windowWillResize: (NSWindow*)sender
		     toSize: (NSSize)frameSize;
- (id) windowWillReturnFieldEditor: (NSWindow*)sender
			  toObject: (id)client;
- (void) windowDidBecomeKey: (NSNotification*)aNotification;
- (void) windowDidBecomeMain: (NSNotification*)aNotification;
- (void) windowDidChangeScreen: (NSNotification*)aNotification;
- (void) windowDidDeminiaturize: (NSNotification*)aNotification;
- (void) windowDidExpose: (NSNotification*)aNotification;
- (void) windowDidMiniaturize: (NSNotification*)aNotification;
- (void) windowDidMove: (NSNotification*)aNotification;
- (void) windowDidResignKey: (NSNotification*)aNotification;
- (void) windowDidResignMain: (NSNotification*)aNotification;
- (void) windowDidResize: (NSNotification*)aNotification;
- (void) windowDidUpdate: (NSNotification*)aNotification;
- (void) windowWillClose: (NSNotification*)aNotification;
- (void) windowWillMiniaturize: (NSNotification*)aNotification;
- (void) windowWillMove: (NSNotification*)aNotification;
@end
#endif

/* Notifications */
APPKIT_EXPORT NSString *NSWindowDidBecomeKeyNotification;
APPKIT_EXPORT NSString *NSWindowDidBecomeMainNotification;
APPKIT_EXPORT NSString *NSWindowDidChangeScreenNotification;
APPKIT_EXPORT NSString *NSWindowDidDeminiaturizeNotification;
APPKIT_EXPORT NSString *NSWindowDidExposeNotification;
APPKIT_EXPORT NSString *NSWindowDidMiniaturizeNotification;
APPKIT_EXPORT NSString *NSWindowDidMoveNotification;
APPKIT_EXPORT NSString *NSWindowDidResignKeyNotification;
APPKIT_EXPORT NSString *NSWindowDidResignMainNotification;
APPKIT_EXPORT NSString *NSWindowDidResizeNotification;
APPKIT_EXPORT NSString *NSWindowDidUpdateNotification;
APPKIT_EXPORT NSString *NSWindowWillCloseNotification;
APPKIT_EXPORT NSString *NSWindowWillMiniaturizeNotification;
APPKIT_EXPORT NSString *NSWindowWillMoveNotification;

#endif /* _GNUstep_H_NSWindow */
