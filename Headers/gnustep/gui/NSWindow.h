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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef _GNUstep_H_NSWindow
#define _GNUstep_H_NSWindow

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
@class NSView;
@class NSWindowController;

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

#ifndef STRICT_OPENSTEP
typedef enum _NSSelectionDirection {
  NSDirectSelection,
  NSSelectingNext,
  NSSelectingPrevious
} NSSelectionDirection;
#endif

APPKIT_EXPORT NSSize NSIconSize;
APPKIT_EXPORT NSSize NSTokenSize;

@interface NSWindow : NSResponder <NSCoding>
{
  NSRect        _frame;
  NSSize        _minimumSize;
  NSSize        _maximumSize;
  NSSize        _increments;
  NSString	*_autosaveName;
  id		_wv;
  id            _contentView;
  id            _firstResponder;
  id            _originalResponder;
  id            _futureFirstResponder;
  NSView        *_initialFirstResponder;
  id            _delegate;
  id            _fieldEditor;
  id            _lastDragView;
  int           _windowNum;
  int           _gstate;
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
  } _f;
 
  /* Reserved for back-end use */
  void *_be_wind_reserved;

  id _defaultButtonCell;
}

/*
 * Class methods
 */

/*
 * Computing frame and content rectangles
 */
+ (NSRect) contentRectForFrameRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle;

+ (NSRect) frameRectForContentRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle;

+ (NSRect) minFrameWidthWithTitle: (NSString *)aTitle
			styleMask: (unsigned int)aStyle;


/*
 * Saving and restoring the frame
 */
+ (void) removeFrameUsingName: (NSString*)name;

/*
 * Initializing and getting a new NSWindow object
 */
- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag;

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
		    screen: (NSScreen*)aScreen;

/*
 * Accessing the content view
 */
- (id) contentView;
- (void) setContentView: (NSView*)aView;

/*
 * Window graphics
 */
- (NSColor*) backgroundColor;
- (NSString*) representedFilename;
- (void) setBackgroundColor: (NSColor*)color;
- (void) setRepresentedFilename: (NSString*)aString;
- (void) setTitle: (NSString*)aString;
- (void) setTitleWithRepresentedFilename: (NSString*)aString;
- (unsigned int) styleMask;
- (NSString*) title;

/*
 * Window device attributes
 */
- (NSBackingStoreType) backingType;
- (NSDictionary*) deviceDescription;
- (int) gState;
- (BOOL) isOneShot;
- (void) setBackingType: (NSBackingStoreType)type;
- (void) setOneShot: (BOOL)flag;
- (int) windowNumber;

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

/*
 * The field editor
 */
- (void) endEditingFor: anObject;
- (NSText*) fieldEditor: (BOOL)createFlag
	      forObject: (id)anObject;

/*
 * The window controller
 */
- (void) setWindowController: (NSWindowController*)windowController;
- (id) windowController;

/*
 * Window status and ordering
 */
- (void) becomeKeyWindow;
- (void) becomeMainWindow;
- (BOOL) canBecomeKeyWindow;
- (BOOL) canBecomeMainWindow;
- (BOOL) hidesOnDeactivate;
- (BOOL) isKeyWindow;
- (BOOL) isMainWindow;
- (BOOL) isMiniaturized;
- (BOOL) isVisible;
- (int) level;
- (void) makeKeyAndOrderFront: (id)sender;
- (void) makeKeyWindow;
- (void) makeMainWindow;
- (void) orderBack: sender;
- (void) orderFront: sender;
- (void) orderFrontRegardless;
- (void) orderOut: (id)sender;
- (void) orderWindow: (NSWindowOrderingMode)place
	  relativeTo: (int)otherWin;
- (void) resignKeyWindow;
- (void) resignMainWindow;
- (void) setHidesOnDeactivate: (BOOL)flag;
- (void) setLevel: (int)newLevel;

/*
 * Moving and resizing the window
 */
- (NSPoint) cascadeTopLeftFromPoint: (NSPoint)topLeftPoint;
- (void) center;
- (NSRect) constrainFrameRect: (NSRect)frameRect
		     toScreen: (NSScreen*)screen;
- (NSRect) frame;
- (NSSize) minSize;
- (NSSize) maxSize;
- (void) setContentSize: (NSSize)aSize;
- (void) setFrame: (NSRect)frameRect
	  display: (BOOL)flag;
- (void) setFrameOrigin: (NSPoint)aPoint;
- (void) setFrameTopLeftPoint: (NSPoint)aPoint;
- (void) setMinSize: (NSSize)aSize;
- (void) setMaxSize: (NSSize)aSize;

/*
 * Converting coordinates
 */
- (NSPoint) convertBaseToScreen: (NSPoint)aPoint;
- (NSPoint) convertScreenToBase: (NSPoint)aPoint;

/*
 * Managing the display
 */
- (void) display;
- (void) disableFlushWindow;
- (void) displayIfNeeded;
- (void) enableFlushWindow;
- (void) flushWindow;
- (void) flushWindowIfNeeded;
- (BOOL) isAutodisplay;
- (BOOL) isFlushWindowDisabled;
- (void) setAutodisplay: (BOOL)flag;
- (void) setViewsNeedDisplay: (BOOL)flag;
- (void) update;
- (void) useOptimizedDrawing: (BOOL)flag;
- (BOOL) viewsNeedDisplay;

/*
 * Screens and window depths
 */
+ (NSWindowDepth) defaultDepthLimit;
- (BOOL) canStoreColor;
- (NSScreen*) deepestScreen;
- (NSWindowDepth) depthLimit;
- (BOOL) hasDynamicDepthLimit;
- (NSScreen*) screen;
- (void) setDepthLimit: (NSWindowDepth)limit;
- (void) setDynamicDepthLimit: (BOOL)flag;

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
 * Handling user actions and events
 */
- (void) close;
- (void) deminiaturize: (id)sender;
- (BOOL) isDocumentEdited;
- (BOOL) isReleasedWhenClosed;
- (void) miniaturize: (id)sender;
- (void) performClose: (id)sender;
- (void) performMiniaturize: (id)sender;
- (int) resizeFlags;
- (void) setDocumentEdited: (BOOL)flag;
- (void) setReleasedWhenClosed: (BOOL)flag;

/*
 * Aiding event handling
 */
- (BOOL) acceptsMouseMovedEvents;
- (NSEvent*) currentEvent;
- (void) discardEventsMatchingMask: (unsigned int)mask
		       beforeEvent: (NSEvent*)lastEvent;
- (NSResponder*) firstResponder;
- (void) keyDown: (NSEvent*)theEvent;
- (BOOL) makeFirstResponder: (NSResponder*)aResponder;
- (NSPoint) mouseLocationOutsideOfEventStream;
- (NSEvent*) nextEventMatchingMask: (unsigned int)mask;
- (NSEvent*) nextEventMatchingMask: (unsigned int)mask
			 untilDate: (NSDate*)expiration
			    inMode: (NSString*)mode
			   dequeue: (BOOL)deqFlag;
- (void) postEvent: (NSEvent*)event
	   atStart: (BOOL)flag;
- (void) setAcceptsMouseMovedEvents: (BOOL)flag;
- (void) sendEvent: (NSEvent*)theEvent;
- (BOOL) tryToPerform: (SEL)anAction with: (id)anObject;
- (BOOL) worksWhenModal;

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

/*
 * Services and windows menu support
 */
- (BOOL) isExcludedFromWindowsMenu;
- (void) setExcludedFromWindowsMenu: (BOOL)flag;
- (id) validRequestorForSendType: (NSString*)sendType
		      returnType: (NSString*)returnType;

/*
 * Saving and restoring the frame
 */
- (NSString*) frameAutosaveName;
- (void) saveFrameUsingName: (NSString*)name;
- (BOOL) setFrameAutosaveName: (NSString*)name;
- (void) setFrameFromString: (NSString*)string;
- (BOOL) setFrameUsingName: (NSString*)name;
- (NSString*) stringWithSavedFrame;

/*
 * Printing and postscript
 */
- (NSData*) dataWithEPSInsideRect: (NSRect)rect;
- (void) fax: (id)sender;
- (void) print: (id)sender;

/*
 * Assigning a delegate
 */
- (id) delegate;
- (void) setDelegate: (id)anObject;


/*
 * NSCoding methods
 */
- (void) encodeWithCoder: (NSCoder*)aCoder;
- (id) initWithCoder: (NSCoder*)aDecoder;

#ifndef STRICT_OPENSTEP
+ (void) menuChanged: (NSMenu*)aMenu;

- (NSSize) aspectRatio;
- (void) cacheImageInRect: (NSRect)aRect;
- (NSButtonCell*) defaultButtonCell;
- (void) disableKeyEquivalentForDefaultButtonCell;
- (void) discardCachedImage;
- (void) enableKeyEquivalentForDefaultButtonCell;
- (NSView*) initialFirstResponder;
- (NSInterfaceStyle) interfaceStyle;
- (NSSelectionDirection) keyViewSelectionDirection;
- (void) performZoom: (id)sender;
- (NSSize) resizeIncrements;
- (void) restoreCachedImage;
- (void) selectKeyViewFollowingView: (NSView*)aView;
- (void) selectKeyViewPrecedingView: (NSView*)aView;
- (void) selectNextKeyView: (id)sender;
- (void) selectPreviousKeyView: (id)sender;
- (void) setAspectRatio: (NSSize)ratio;
- (void) setDefaultButtonCell: (NSButtonCell*)aCell;
- (void) setInitialFirstResponder: (NSView*)aView;
- (void) setInterfaceStyle: (NSInterfaceStyle)aStyle;
- (void) setResizeIncrements: (NSSize)aSize;
- (void) zoom: (id)sender;
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
