/* 
   NSWindow.h

   The window class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <AppKit/stdappkit.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSView.h>
#include <AppKit/NSEvent.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSString.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSText.h>
#include <Foundation/NSCoder.h>
#include <AppKit/NSScreen.h>
#include <Foundation/NSNotification.h>

@interface NSWindow : NSResponder <NSCoding>

{
  // Attributes
  NSRect frame;
  NSSize minimum_size;
  NSSize maximum_size;
  id content_view;
  id first_responder;
  id original_responder;
  id delegate;
  int window_num;
  NSColor *background_color;
  NSString *represented_filename;
  NSString *miniaturized_title;
  NSImage *miniaturized_image;
  NSString *window_title;
  NSPoint last_point;
  NSBackingStoreType backing_type;
  unsigned int style_mask;
  int window_level;

  BOOL is_one_shot;
  BOOL needs_display;
  BOOL is_autodisplay;
  BOOL optimize_drawing;
  BOOL views_need_display;
  NSWindowDepth depth_limit;
  BOOL dynamic_depth_limit;

  BOOL cursor_rects_enabled;
  BOOL cursor_rects_valid;

  BOOL visible;
  BOOL is_key;
  BOOL is_main;
  BOOL is_edited;
  BOOL is_released_when_closed;
  BOOL is_miniaturized;
  BOOL disable_flush_window;
  BOOL menu_exclude;
  BOOL hides_on_deactivate;
  BOOL accepts_mouse_moved;

  // Reserved for back-end use
  void *be_wind_reserved;
}

//
// Class methods
//
//
// Computing frame and content rectangles
//
+ (NSRect)contentRectForFrameRect:(NSRect)aRect
			styleMask:(unsigned int)aStyle;

+ (NSRect)frameRectForContentRect:(NSRect)aRect
			styleMask:(unsigned int)aStyle;

+ (NSRect)minFrameWidthWithTitle:(NSString *)aTitle
		       styleMask:(unsigned int)aStyle;

//
// Saving and restoring the frame
//
+ (void)removeFrameUsingName:(NSString *)name;

//
// Initializing and getting a new NSWindow object
//
- initWithContentRect:(NSRect)contentRect
	    styleMask:(unsigned int)aStyle
	      backing:(NSBackingStoreType)bufferingType
		defer:(BOOL)flag;

- initWithContentRect:(NSRect)contentRect
	    styleMask:(unsigned int)aStyle
	      backing:(NSBackingStoreType)bufferingType
		defer:(BOOL)flag
	       screen:aScreen;

//
// Accessing the content view
//
- contentView;
- (void)setContentView:(NSView *)aView;

//
// Window graphics
//
- (NSColor *)backgroundColor;
- (NSString *)representedFilename;
- (void)setBackgroundColor:(NSColor *)color;
- (void)setRepresentedFilename:(NSString *)aString;
- (void)setTitle:(NSString *)aString;
- (void)setTitleWithRepresentedFilename:(NSString *)aString;
- (unsigned int)styleMask;
- (NSString *)title;

//
// Window device attributes
//
- (NSBackingStoreType)backingType;
- (NSDictionary *)deviceDescription;
- (int)gState;
- (BOOL)isOneShot;
- (void)setBackingType:(NSBackingStoreType)type;
- (void)setOneShot:(BOOL)flag;
- (int)windowNumber;
- (void)setWindowNumber:(int)windowNum;

//
// The miniwindow
//
- (NSImage *)miniwindowImage;
- (NSString *)miniwindowTitle;
- (void)setMiniwindowImage:(NSImage *)image;
- (void)setMiniwindowTitle:(NSString *)title;

//
// The field editor
//
- (void)endEditingFor:anObject;
- (NSText *)fieldEditor:(BOOL)createFlag
	      forObject:anObject;

//
// Window status and ordering
//
- (void)becomeKeyWindow;
- (void)becomeMainWindow;
- (BOOL)canBecomeKeyWindow;
- (BOOL)canBecomeMainWindow;
- (BOOL)hidesOnDeactivate;
- (BOOL)isKeyWindow;
- (BOOL)isMainWindow;
- (BOOL)isMiniaturized;
- (BOOL)isVisible;
- (int)level;
- (void)makeKeyAndOrderFront:sender;
- (void)makeKeyWindow;
- (void)makeMainWindow;
- (void)orderBack:sender;
- (void)orderFront:sender;
- (void)orderFrontRegardless;
- (void)orderOut:sender;
- (void)orderWindow:(NSWindowOrderingMode)place
	 relativeTo:(int)otherWin;
- (void)resignKeyWindow;
- (void)resignMainWindow;
- (void)setHidesOnDeactivate:(BOOL)flag;
- (void)setLevel:(int)newLevel;

//
// Moving and resizing the window
//
- (NSPoint)cascadeTopLeftFromPoint:(NSPoint)topLeftPoint;
- (void)center;
- (NSRect)constrainFrameRect:(NSRect)frameRect
		    toScreen:screen;
- (NSRect)frame;
- (NSSize)minSize;
- (NSSize)maxSize;
- (void)setContentSize:(NSSize)aSize;
- (void)setFrame:(NSRect)frameRect
	 display:(BOOL)flag;
- (void)setFrameOrigin:(NSPoint)aPoint;
- (void)setFrameTopLeftPoint:(NSPoint)aPoint;
- (void)setMinSize:(NSSize)aSize;
- (void)setMaxSize:(NSSize)aSize;

//
// Converting coordinates
//
- (NSPoint)convertBaseToScreen:(NSPoint)aPoint;
- (NSPoint)convertScreenToBase:(NSPoint)aPoint;

//
// Managing the display
//
- (void)display;
- (void)disableFlushWindow;
- (void)displayIfNeeded;
- (void)enableFlushWindow;
- (void)flushWindow;
- (void)flushWindowIfNeeded;
- (BOOL)isAutodisplay;
- (BOOL)isFlushWindowDisabled;
- (void)setAutoDisplay:(BOOL)flag;
- (void)setViewsNeedDisplay:(BOOL)flag;
- (void)update;
- (void)useOptimizedDrawing:(BOOL)flag;
- (BOOL)viewsNeedDisplay;

//
// Screens and window depths
//
+ (NSWindowDepth)defaultDepthLimit;
- (BOOL)canStoreColor;
- (NSScreen *)deepestScreen;
- (NSWindowDepth)depthLimit;
- (BOOL)hasDynamicDepthLimit;
- (NSScreen *)screen;
- (void)setDepthLimit:(NSWindowDepth)limit;
- (void)setDynamicDepthLimit:(BOOL)flag;

//
// Cursor management
//
- (BOOL)areCursorRectsEnabled;
- (void)disableCursorRects;
- (void)discardCursorRects;
- (void)enableCursorRects;
- (void)invalidateCursorRectsForView:(NSView *)aView;
- (void)resetCursorRects;

//
// Handling user actions and events
//
- (void)close;
- (void)deminiaturize:sender;
- (BOOL)isDocumentEdited;
- (BOOL)isReleasedWhenClosed;
- (void)miniaturize:sender;
- (void)performClose:sender;
- (void)performMiniaturize:sender;
- (int)resizeFlags;
- (void)setDocumentEdited:(BOOL)flag;
- (void)setReleasedWhenClosed:(BOOL)flag;

//
// Aiding event handling
//
- (BOOL)acceptsMouseMovedEvents;
- (NSEvent *)currentEvent;
- (void)discardEventsMatchingMask:(unsigned int)mask
		      beforeEvent:(NSEvent *)lastEvent;
- (NSResponder *)firstResponder;
- (void)keyDown:(NSEvent *)theEvent;
- (BOOL)makeFirstResponder:(NSResponder *)aResponder;
- (NSPoint)mouseLocationOutsideOfEventStream;
- (NSEvent *)nextEventMatchingMask:(unsigned int)mask;
- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
			 untilDate:(NSDate *)expiration
			    inMode:(NSString *)mode
			   dequeue:(BOOL)deqFlag;
- (void)postEvent:(NSEvent *)event
	  atStart:(BOOL)flag;
- (void)setAcceptsMouseMovedEvents:(BOOL)flag;
- (void)sendEvent:(NSEvent *)theEvent;
- (BOOL)tryToPerform:(SEL)anAction with:anObject;
- (BOOL)worksWhenModal;

//
// Dragging
//
- (void)dragImage:(NSImage *)anImage
	       at:(NSPoint)baseLocation 
	   offset:(NSSize)initialOffset
	    event:(NSEvent *)event
       pasteboard:(NSPasteboard *)pboard
	   source:sourceObject
	slideBack:(BOOL)slideFlag;
- (void)registerForDraggedTypes:(NSArray *)newTypes;
- (void)unregisterDraggedTypes;

//
// Services and windows menu support
//
- (BOOL)isExcludedFromWindowsMenu;
- (void)setExcludedFromWindowsMenu:(BOOL)flag;
- validRequestorForSendType:(NSString *)sendType
		 returnType:(NSString *)returnType;

//
// Saving and restoring the frame
//
- (NSString *)frameAutosaveName;
- (void)saveFrameUsingName:(NSString *)name;
- (BOOL)setFrameAutosaveName:(NSString *)name;
- (void)setFrameFromString:(NSString *)string;
- (BOOL)setFrameUsingName:(NSString *)name;
- (NSString *)stringWithSavedFrame;

//
// Printing and postscript
//
- (NSData *)dataWithEPSInsideRect:(NSRect)rect;
- (void)fax:sender;
- (void)print:sender;

//
// Assigning a delegate
//
- delegate;
- (void)setDelegate:anObject;

//
// Implemented by the delegate
//
- (BOOL)windowShouldClose:sender;
- (NSSize)windowWillResize:(NSWindow *)sender
		    toSize:(NSSize)frameSize;
- windowWillReturnFieldEditor:(NSWindow *)sender
		     toObject:client;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidBecomeMain:(NSNotification *)aNotification;
- (void)windowDidChangeScreen:(NSNotification *)aNotification;
- (void)windowDidDeminiaturize:(NSNotification *)aNotification;
- (void)windowDidExpose:(NSNotification *)aNotification;
- (void)windowDidMiniaturize:(NSNotification *)aNotification;
- (void)windowDidMove:(NSNotification *)aNotification;
- (void)windowDidResignKey:(NSNotification *)aNotification;
- (void)windowDidResignMain:(NSNotification *)aNotification;
- (void)windowDidResize:(NSNotification *)aNotification;
- (void)windowDidUpdate:(NSNotification *)aNotification;
- (void)windowWillClose:(NSNotification *)aNotification;
- (void)windowWillMiniaturize:(NSNotification *)aNotification;
- (void)windowWillMove:(NSNotification *)aNotification;

//
// NSCoding methods
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

//
// GNUstep backend methods
//
@interface NSWindow (GNUstepBackend)

//
// Mouse capture/release
//
- (void)captureMouse: sender;
- (void)releaseMouse: sender;

// Allow subclasses to init without the backend class
// attempting to create an actual window
- (void)initDefaults;
- cleanInit;

@end

#endif // _GNUstep_H_NSWindow
