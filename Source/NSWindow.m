/*
   NSWindow.m

   The window class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
            Venkat Ajjanagadde <venkat@ocbi.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: June 1998

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

#include <gnustep/gui/config.h>

#include <Foundation/NSString.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSException.h>

#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSColor.h>
#include <AppKit/GSTrackingRect.h>
#include <AppKit/NSSliderCell.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSCursor.h>
#include <AppKit/PSMatrix.h>



//*****************************************************************************
//
// 		NSWindow
//
//*****************************************************************************

@implementation NSWindow

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSWindow class])
		{
		NSDebugLog(@"Initialize NSWindow class\n");
		[self setVersion:2];
		}
}

+ (NSView *)_windowViewWithFrame:(NSRect)frameRect		// create the view at
{														// the root of window's
	return nil;											// view heirarchy.
}														// (backend)

+ (void)removeFrameUsingName:(NSString *)name
{														// Saving and restoring
}														// the window's frame

+ (NSRect)contentRectForFrameRect:(NSRect)aRect
						styleMask:(unsigned int)aStyle
{														// Computing frame and
	return aRect;										// content rectangles
}

+ (NSRect)frameRectForContentRect:(NSRect)aRect
						styleMask:(unsigned int)aStyle
{
	return aRect;
}

+ (NSRect)minFrameWidthWithTitle:(NSString *)aTitle
					   styleMask:(unsigned int)aStyle
{
	return NSZeroRect;
}

+ (NSWindowDepth)defaultDepthLimit						// default Screen and
{														// window depth
	return 8;
}

//
// Instance methods
//
- init
{
int style;

	NSDebugLog(@"NSWindow -init\n");
															// default window
	style = NSTitledWindowMask | NSClosableWindowMask		// style mask
			| NSMiniaturizableWindowMask | NSResizableWindowMask;

	return [self initWithContentRect:NSZeroRect
				 styleMask:style
				 backing:NSBackingStoreBuffered
				 defer:NO];
}

- (void)dealloc
{
	if (content_view)
		{
    	[[content_view superview] release];			// Release the window view
		[content_view release];						// Release the content view
		}

	if (_fieldEditor)
		[_fieldEditor release];
	[background_color release];
	[represented_filename release];
	[miniaturized_title release];
	[miniaturized_image release];
	[window_title release];
	[_flushRectangles release];

	[super dealloc];
}

//
// Initializing and getting a new NSWindow object
//
- initWithContentRect:(NSRect)contentRect
			styleMask:(unsigned int)aStyle
			backing:(NSBackingStoreType)bufferingType
			defer:(BOOL)flag
{
	NSDebugLog(@"NSWindow -initWithContentRect:\n");

	return [self initWithContentRect:contentRect
				 styleMask:aStyle
				 backing:bufferingType
				 defer:flag
				 screen:nil];
}

- initWithContentRect:(NSRect)contentRect
			styleMask:(unsigned int)aStyle
			backing:(NSBackingStoreType)bufferingType
			defer:(BOOL)flag
			screen:aScreen
{
NSApplication *theApp = [NSApplication sharedApplication];
NSRect r = [[NSScreen mainScreen] frame];
NSRect cframe;

	NSDebugLog(@"NSWindow default initializer\n");
	if (!theApp)
		NSLog(@"No application!\n");

	NSDebugLog(@"NSWindow start of init\n");
													// Initialize attributes
	[self cleanInit];								// and flags

	backing_type = bufferingType;
	style_mask = aStyle;
													// Size the attributes
	frame = [NSWindow frameRectForContentRect: contentRect styleMask: aStyle];
	minimum_size = NSZeroSize;
	maximum_size = r.size;
													// Next responder is the
	[self setNextResponder:theApp];					// application

	cursor_rects_enabled = YES;						// Cursor management
	cursor_rects_valid = NO;

	cframe.origin = NSZeroPoint;					// Create the content view
	cframe.size = frame.size;
	[self setContentView:[[[NSView alloc] initWithFrame:cframe] autorelease]];
													// Register ourselves with
													// the Application object
	[theApp addWindowsItem:self title:window_title filename:NO];

	_flushRectangles = [[NSMutableArray alloc] initWithCapacity:10];

	NSDebugLog(@"NSWindow end of init\n");

	return self;
}

//
// Accessing the content view
//
- contentView								{ return content_view; }

- (void)setContentView:(NSView *)aView
{
NSView *wv;

	if (!aView)										// contentview can't be nil
		aView = [[[NSView alloc] initWithFrame: frame] autorelease];
													// If window view has not
													// been created, create it
	if ((!content_view) || ([content_view superview] == nil))
		{
		wv = [NSWindow _windowViewWithFrame: frame];
		[wv viewWillMoveToWindow: self];
		}
	else
		wv = [content_view superview];

	if (content_view)
		[content_view removeFromSuperview];

	ASSIGN(content_view, aView);

	[wv addSubview: content_view];					// Add to our window view
	NSAssert1 ([[wv subviews] count] == 1, @"window's view has %d  subviews!",
				[[wv subviews] count]);
													// Make self the view's
	[content_view setNextResponder:self];			// next responder
}

//
// Window graphics
//
- (NSColor *)backgroundColor				{ return background_color; }
- (NSString *)representedFilename			{ return represented_filename; }

- (void)setBackgroundColor:(NSColor *)color
{
	ASSIGN(background_color, color);
}

- (void)setRepresentedFilename:(NSString *)aString
{
	ASSIGN(represented_filename, aString);
}

- (void)setTitle:(NSString *)aString		{ ASSIGN(window_title,aString); }

- (void)setTitleWithRepresentedFilename:(NSString *)aString
{
	[self setRepresentedFilename:aString];
	[self setTitle:aString];
}

- (unsigned int)styleMask					{ return style_mask; }
- (NSString *)title							{ return window_title; }

//
// Window device attributes
//
- (NSBackingStoreType)backingType			{ return backing_type; }
- (NSDictionary *)deviceDescription			{ return nil; }
- (int)gState								{ return 0; }
- (BOOL)isOneShot							{ return is_one_shot; }

- (void)setBackingType:(NSBackingStoreType)type
{
	backing_type = type;
}

- (void)setOneShot:(BOOL)flag				{ is_one_shot = flag; }
- (int)windowNumber							{ return window_num; }
- (void)setWindowNumber:(int)windowNum		{ window_num = windowNum; }

//
// The miniwindow
//
- (NSImage *)miniwindowImage				{ return miniaturized_image; }
- (NSString *)miniwindowTitle				{ return miniaturized_title; }

- (void)setMiniwindowImage:(NSImage *)image
{
	ASSIGN(miniaturized_image, image);
}

- (void)setMiniwindowTitle:(NSString *)title;
{
	ASSIGN(miniaturized_title, title);
}

//
// The field editor
//
- (void)endEditingFor:anObject
{
}

- (NSText *)fieldEditor:(BOOL)createFlag forObject:anObject
{													// ask delegate if it can
	if ([delegate respondsToSelector:				// provide a field editor
			@selector(windowWillReturnFieldEditor:toObject:)])
		return [delegate windowWillReturnFieldEditor:self toObject:anObject];

	if (!_fieldEditor && createFlag)					// each window has a global
		{											// text field editor
		_fieldEditor = [[NSText new] retain];
		[_fieldEditor setFieldEditor:YES];
		}

	return _fieldEditor;
}

//
// Window status and ordering
//
- (void)becomeKeyWindow
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	is_key = YES;									// We are the key window

	[self resetCursorRects];						// Reset the cursor rects
														// Post notification
	[nc postNotificationName: NSWindowDidBecomeKeyNotification object: self];
}

- (void)becomeMainWindow
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	is_main = YES;									// We are the main window
														// Post notification
	[nc postNotificationName: NSWindowDidBecomeMainNotification object: self];
}

- (BOOL)canBecomeKeyWindow					{ return YES; }
- (BOOL)canBecomeMainWindow					{ return YES; }
- (BOOL)hidesOnDeactivate					{ return hides_on_deactivate; }
- (BOOL)isKeyWindow							{ return is_key; }
- (BOOL)isMainWindow						{ return is_main; }
- (BOOL)isMiniaturized						{ return is_miniaturized; }
- (BOOL)isVisible							{ return visible; }
- (int)level								{ return window_level; }

- (void)makeKeyAndOrderFront:sender
{
	[self makeKeyWindow];							// Make self the key window
	[self orderFront:sender];						// order self to the front
}

- (void)makeKeyWindow
{
NSApplication *theApp = [NSApplication sharedApplication];
													// Can we become the key
	if (![self canBecomeKeyWindow]) 				// window?
		return;
													// ask the current key
	[[theApp keyWindow] resignKeyWindow];			// window to resign status

	[self becomeKeyWindow];							// become the key window
}

- (void)makeMainWindow
{
NSApplication *theApp = [NSApplication sharedApplication];
													// Can we become the main
	if (![self canBecomeMainWindow]) 				// window?
		return;
													// ask the current main
	[[theApp mainWindow] resignMainWindow];			// window to resign status

	[self becomeMainWindow];						// become the main window
}

- (void)orderBack:sender					{}		// implemented in back end
- (void)orderFront:sender					{}
- (void)orderFrontRegardless				{}
- (void)orderOut:sender						{}

- (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWin
{
}

- (void)resignKeyWindow
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	is_key = NO;
													// Discard the cursor rects
	[self discardCursorRects];
														// Post notification
	[nc postNotificationName: NSWindowDidResignKeyNotification object: self];
}

- (void)resignMainWindow
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	is_main = NO;
														// Post notification
	[nc postNotificationName: NSWindowDidResignMainNotification object: self];
}

- (void)setHidesOnDeactivate:(BOOL)flag		{ hides_on_deactivate = flag; }
- (void)setLevel:(int)newLevel				{ window_level = newLevel; }

//
// Moving and resizing the window
//
- (NSPoint)cascadeTopLeftFromPoint:(NSPoint)topLeftPoint
{
	return NSZeroPoint;
}

- (void)center
{
NSSize screenSize = [[NSScreen mainScreen] frame].size;
NSPoint origin = frame.origin;							// center the window
														// within it's screen
	origin.x = (screenSize.width - frame.size.width) / 2;
	origin.y = (screenSize.height - frame.size.height) / 2;
	[self setFrameOrigin:origin];
}

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:screen
{
	return NSZeroRect;
}

- (NSRect)frame								{ return frame; }
- (NSSize)minSize							{ return minimum_size; }
- (NSSize)maxSize							{ return maximum_size; }
- (void)setContentSize:(NSSize)aSize		{}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	frame = frameRect;
  														// post notification
	[nc postNotificationName: NSWindowDidResizeNotification object: self];

	if (flag) 											// display if requested
		[self display];
}

- (void)setFrameTopLeftPoint:(NSPoint)aPoint
{
}

- (void)setFrameOrigin:(NSPoint)aPoint		{ frame.origin = aPoint; }
- (void)setMinSize:(NSSize)aSize			{ minimum_size = aSize; }
- (void)setMaxSize:(NSSize)aSize			{ maximum_size = aSize; }

//
// Converting coordinates
//
- (NSPoint)convertBaseToScreen:(NSPoint)basePoint
{
NSPoint screenPoint;

	screenPoint.x = frame.origin.x + basePoint.x;
	screenPoint.y = frame.origin.y + basePoint.y;

	return screenPoint;
}

- (NSPoint)convertScreenToBase:(NSPoint)screenPoint
{
NSPoint basePoint;

	basePoint.x = screenPoint.x - frame.origin.x;
	basePoint.y = screenPoint.y - frame.origin.y;

	return basePoint;
}

//
// Managing the display
//
- (void)disableFlushWindow					{ disable_flush_window = YES; }

- (void)display
{
	visible = YES;
	needs_display = NO;								// inform first responder
													// of it's status so it can
	[first_responder becomeFirstResponder];			// set the focus to itself

	[self disableFlushWindow];						// tmp disable display

	[[content_view superview] display];				// Draw the window view

	[self enableFlushWindow];						// Reenable displaying and
}													// flush the window

- (void)displayIfNeeded
{
	if (needs_display)
		{
		[[content_view superview] displayIfNeeded];
		needs_display = NO;
		}
}

- (void)update
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	if (is_autodisplay && needs_display)					// if autodisplay is
		{												// enabled and window
		[self displayIfNeeded];							// display
		[self flushWindowIfNeeded];
    	}

	[nc postNotificationName: NSWindowDidUpdateNotification object: self];
}

- (void)flushWindowIfNeeded
{
	if (!disable_flush_window && needs_flush)
		{
		needs_flush = NO;
		[self flushWindow];
		}
}

- (void)flushWindow							{}		// implemented in back end
- (void)enableFlushWindow					{ disable_flush_window = NO; }
- (BOOL)isAutodisplay						{ return is_autodisplay; }
- (BOOL)isFlushWindowDisabled				{ return disable_flush_window; }
- (void)setAutodisplay:(BOOL)flag			{ is_autodisplay = flag; }
- (void)setViewsNeedDisplay:(BOOL)flag		{ needs_display = flag; }
- (BOOL)viewsNeedDisplay					{ return needs_display; }
- (void)useOptimizedDrawing:(BOOL)flag		{ optimize_drawing = flag; }

- (BOOL)canStoreColor
{
	if (depth_limit > 1)							// If the depth is greater
		return YES;									// than a single bit
	else
		return NO;
}

- (NSScreen *)deepestScreen					{ return [NSScreen deepestScreen];}
- (NSWindowDepth)depthLimit					{ return depth_limit; }
- (BOOL)hasDynamicDepthLimit				{ return dynamic_depth_limit; }
- (NSScreen *)screen						{ return [NSScreen mainScreen]; }
- (void)setDepthLimit:(NSWindowDepth)limit	{ depth_limit = limit; }
- (void)setDynamicDepthLimit:(BOOL)flag		{ dynamic_depth_limit = flag; }

//
// Cursor management
//
- (BOOL)areCursorRectsEnabled				{ return cursor_rects_enabled; }
- (void)disableCursorRects					{ cursor_rects_enabled = NO; }

- (void)discardCursorRectsForView:(NSView *)theView
{
NSArray *s;
id e;
NSView *v;
														// Discard cursor rects
	[theView discardCursorRects];						// for the view

	s = [theView subviews];								// Discard cursor rects
	e = [s objectEnumerator];							// for view's subviews
	while ((v = [e nextObject]))
		[self discardCursorRectsForView: v];
}

- (void)discardCursorRects
{
	[self discardCursorRectsForView: [content_view superview]];
}

- (void)enableCursorRects					{ cursor_rects_enabled = YES; }

- (void)invalidateCursorRectsForView:(NSView *)aView
{
	cursor_rects_valid = NO;
}

- (void)resetCursorRectsForView:(NSView *)theView
{
NSArray *s;
id e;
NSView *v;

	[theView resetCursorRects];					// Reset cursor rects for view

	s = [theView subviews];						// Reset cursor rects for the
	e = [s objectEnumerator];					// view's subviews
	while ((v = [e nextObject]))
		[self resetCursorRectsForView: v];
}

- (void)resetCursorRects						// Tell all the views to reset
{  												// their cursor rects
	[self resetCursorRectsForView: [content_view superview]];
	cursor_rects_valid = YES;					// Cursor rects are now valid
}

//
// Handling user actions and events
//
- (void) close
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
															// Notify delegate
  [nc postNotificationName: NSWindowWillCloseNotification object: self];
  [self orderOut: self];
  visible = NO;

  if (is_released_when_closed)
    [self autorelease];
}

- (void)deminiaturize:sender
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
													// Set ivar flag to say we
	is_miniaturized = NO;							// are not miniaturized
	visible = YES;

	[self performDeminiaturize:self];
													// Notify window's delegate
	[nc postNotificationName:NSWindowDidDeminiaturizeNotification object:self];
}

- (BOOL)isDocumentEdited					{ return is_edited; }
- (BOOL)isReleasedWhenClosed				{ return is_released_when_closed; }

- (void)miniaturize:sender
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
													// Notify window's delegate
	[nc postNotificationName:NSWindowWillMiniaturizeNotification object: self];

	[self performMiniaturize:self];
													// Notify window's delegate
	[nc postNotificationName: NSWindowDidMiniaturizeNotification object: self];
}

- (void)performClose:sender
{
	if (!([self styleMask] & NSClosableWindowMask))
		{											// self must have a close
		NSBeep();									// button in order to be
		return;										// closed
		}

	if ([delegate respondsToSelector:@selector(windowShouldClose:)])
		{											// if delegate responds to
    	if (![delegate windowShouldClose:self])		// windowShouldClose query
			{										// it to see if it's ok to
			NSBeep();								// close the window
			return;
			}
		}
	else
		{
		if ([self respondsToSelector:@selector(windowShouldClose:)])
			{										// else if self responds to
			if (![self windowShouldClose:self])		// windowShouldClose query
				{									// self to see if it's ok
				NSBeep();							// to close self
				return;
		}	}	}

	[self close];									// it's ok to close self
}

- (void)performMiniaturize:sender			{ is_miniaturized = YES; }													- (int)resizeFlags							{ return 0; }
- (void)setDocumentEdited:(BOOL)flag		{ is_edited = flag; }
- (void)setReleasedWhenClosed:(BOOL)flag	{ is_released_when_closed = flag; }

//
// Aiding event handling
//
- (BOOL)acceptsMouseMovedEvents				{ return accepts_mouse_moved; }

- (NSEvent *)currentEvent
{
	return [[NSApplication sharedApplication] currentEvent];
}

- (void)discardEventsMatchingMask:(unsigned int)mask
					  beforeEvent:(NSEvent *)lastEvent
{
NSApplication *theApp = [NSApplication sharedApplication];

	[theApp discardEventsMatchingMask:mask beforeEvent:lastEvent];
}

- (NSResponder *)firstResponder				{ return first_responder; }

- (void) keyDown: (NSEvent*)theEvent
{
  static NSEvent *inProgress = nil;

  if (theEvent == inProgress)
    {
      /*
       * There was a loop in the responser chain - nothin handled the event
       * so we make a warning beep.
       */
      inProgress = nil;
      NSBeep();
    }
  else
    {
      /*
       * Save the first responder so that the key up goes to it and not a
       * possible new first responder.
       * Save the event so we can detect a loop in the responder chain.
       */
      original_responder = first_responder;
      inProgress = theEvent;
      [first_responder keyDown: theEvent];
      inProgress = nil;
    }
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
	if (first_responder == aResponder)				// if responder is already
		return YES;									// first responder return Y

	if (![aResponder isKindOfClass:[NSResponder class]])
		return NO;									// not a responder return N

	if (![aResponder acceptsFirstResponder])		// does not accept status
		return NO;									// of first responder ret N
									// If there is a first responder tell it to
									// resign. Make change only if it replies Y
	if ((first_responder) && (![first_responder resignFirstResponder]))
		return NO;
  													// Make responder the first
	first_responder = aResponder;					// responder

	[first_responder becomeFirstResponder];			// Notify responder that it
													// has become the first
	return YES;										// responder
}

- (NSPoint)mouseLocationOutsideOfEventStream		// Return mouse location
{													// in reciever's base coord
	return NSZeroPoint;								// system, ignores event
}													// loop status (backend)

- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
{
	return [[NSApplication sharedApplication] nextEventMatchingMask:mask
											  untilDate:nil
											  inMode:NSEventTrackingRunLoopMode
											  dequeue:YES];
}

- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
						 untilDate:(NSDate *)expiration
						 inMode:(NSString *)mode
						 dequeue:(BOOL)deqFlag
{
	return [[NSApplication sharedApplication] nextEventMatchingMask:mask
											  untilDate:expiration
											  inMode:mode
											  dequeue:deqFlag];
}

- (void)postEvent:(NSEvent *)event atStart:(BOOL)flag
{
	[[NSApplication sharedApplication] postEvent:event atStart:flag];
}

- (void)setAcceptsMouseMovedEvents:(BOOL)flag
{
	accepts_mouse_moved = flag;
}

- (void)checkTrackingRectangles:(NSView *)theView forEvent:(NSEvent *)theEvent
{
NSArray *tr = [theView trackingRectangles];
NSArray *sb = [theView subviews];
GSTrackingRect *r;
int i, j;
BOOL last, now;
NSEvent *e;

	j = [tr count];								// Loop through the tracking
	for (i = 0;i < j; ++i)						// rectangles
		{
		r = (GSTrackingRect *)[tr objectAtIndex:i];
												// Check mouse at last point
		last = [theView mouse:last_point inRect:[r rectangle]];
												// Check mouse at current point
		now = [theView mouse:[theEvent locationInWindow] inRect:[r rectangle]];

		if ((!last) && (now))							// Mouse entered event
			{
			id owner = [r owner];
			e = [NSEvent enterExitEventWithType:NSMouseEntered
						 location:[theEvent locationInWindow]
						 modifierFlags:[theEvent modifierFlags]
						 timestamp:0
						 windowNumber:[theEvent windowNumber]
						 context:NULL eventNumber:0
						 trackingNumber:[r tag]
						 userData:[r userData]];
												// Send the event to the owner
			if ([owner respondsToSelector:@selector(mouseEntered:)])
				[owner mouseEntered:e];
			}

		if ((last) && (!now))							// Mouse exited event
			{
			id owner = [r owner];
			e = [NSEvent enterExitEventWithType:NSMouseExited
						 location:[theEvent locationInWindow]
						 modifierFlags:[theEvent modifierFlags]
						 timestamp:0
						 windowNumber:[theEvent windowNumber]
						 context:NULL
						 eventNumber:0
						 trackingNumber:[r tag]
						 userData:[r userData]];
												// Send the event to the owner
			if ([owner respondsToSelector:@selector(mouseExited:)])
				[owner mouseExited:e];
			}
		}

	j = [sb count];								// Check tracking rectangles
	for (i = 0;i < j; ++i)						// for the subviews
		[self checkTrackingRectangles:[sb objectAtIndex:i] forEvent:theEvent];
}

- (void)checkCursorRectangles:(NSView *)theView forEvent:(NSEvent *)theEvent
{
NSArray *tr = [theView cursorRectangles];
NSArray *sb = [theView subviews];
GSTrackingRect *r;
int i, j;
BOOL last, now;
NSEvent *e;
NSPoint loc = [theEvent locationInWindow];
NSPoint lastPointConverted;
NSPoint locationConverted;
NSRect rect;
											// Loop through cursor rectangles
	j = [tr count];
	for (i = 0;i < j; ++i)							// Convert cursor rectangle
		{											// to window coordinates
		r = (GSTrackingRect *)[tr objectAtIndex:i];

		lastPointConverted = [theView convertPoint:last_point fromView:nil];
		locationConverted = [theView convertPoint:loc fromView:nil];

		rect = [r rectangle];						// Check mouse's last point
		last = [theView mouse:lastPointConverted inRect:rect];
		now = [theView mouse:locationConverted inRect:rect];
															// Mouse entered
		if ((!last) && (now))
			{										// Post cursor update event
			e = [NSEvent enterExitEventWithType: NSCursorUpdate
						 location: loc
						 modifierFlags: [theEvent modifierFlags]
						 timestamp: 0
						 windowNumber: [theEvent windowNumber]
						 context: [theEvent context]
						 eventNumber: 0
						 trackingNumber: (int)YES
						 userData: (void *)r];
			[self postEvent: e atStart: YES];
			}
															// Mouse exited
		if ((last) && (!now))
			{										// Post cursor update event
			e = [NSEvent enterExitEventWithType: NSCursorUpdate
						 location: loc
						 modifierFlags: [theEvent modifierFlags]
						 timestamp: 0
						 windowNumber: [theEvent windowNumber]
						 context: [theEvent context]
						 eventNumber: 0
						 trackingNumber: (int)NO
						 userData: (void *)r];
			[self postEvent: e atStart: YES];
			}
		}
													// Check cursor rectangles
	j = [sb count];									// for the subviews
	for (i = 0;i < j; ++i)
		[self checkCursorRectangles:[sb objectAtIndex:i] forEvent:theEvent];
}

- (void)sendEvent:(NSEvent *)theEvent
{
NSView *v;

	if (!cursor_rects_valid)				// If the cursor rects are invalid
    	{									// Then discard and reset
		[self discardCursorRects];
		[self resetCursorRects];
    	}

	switch ([theEvent type])
    	{
		case NSLeftMouseDown:								// Left mouse down
			v = [content_view hitTest:[theEvent locationInWindow]];
			NSDebugLog([v description]);
			NSDebugLog(@"\n");
			if (first_responder != v)				// if hit view is not first
				[self makeFirstResponder:v];		// responder ask it to be
			[v mouseDown:theEvent];
			last_point = [theEvent locationInWindow];
			break;

		case NSLeftMouseUp:									// Left mouse up
			v = [content_view hitTest:[theEvent locationInWindow]];
			[v mouseUp:theEvent];
			last_point = [theEvent locationInWindow];
			break;

		case NSRightMouseDown:								// Right mouse down
			v = [content_view hitTest:[theEvent locationInWindow]];
			[v rightMouseDown:theEvent];
			last_point = [theEvent locationInWindow];
			break;

		case NSRightMouseUp:								// Right mouse up
			v = [content_view hitTest:[theEvent locationInWindow]];
			[v rightMouseUp:theEvent];
			last_point = [theEvent locationInWindow];
			break;

		case NSMouseMoved:									// Mouse moved
			v = [content_view hitTest:[theEvent locationInWindow]];
			[v mouseMoved:theEvent];	// First send the NSMouseMoved event
						// We need to go through all of the views, and any with
						// a tracking rectangle then we need to determine if we
						// should send a NSMouseEntered or NSMouseExited event
			[self checkTrackingRectangles:content_view forEvent:theEvent];
						// We need to go through all of the views, and any with
						// a cursor rectangle then we need to determine if we
						// should send a cursor update event
						// We only do this if we are the key window
			if (is_key)
				[self checkCursorRectangles: content_view forEvent: theEvent];

			last_point = [theEvent locationInWindow];
			break;

		case NSLeftMouseDragged:						// Left mouse dragged
			last_point = [theEvent locationInWindow];
			break;

		case NSRightMouseDragged:						// Right mouse dragged
			last_point = [theEvent locationInWindow];
			break;

		case NSMouseEntered:								// Mouse entered
		case NSMouseExited:									// Mouse exited
			break;

		case NSKeyDown:											// Key down
			[self keyDown:theEvent];
			break;

		case NSKeyUp:											// Key up
			if (original_responder)						// send message to the
				[original_responder keyUp:theEvent];	// object that got the
			break;										// key down

		case NSFlagsChanged:								// Flags changed
			break;

		case NSCursorUpdate:								// Cursor update
			if ([theEvent trackingNumber])			// if it's a mouse entered
				{									// push the cursor
	    		GSTrackingRect *r =(GSTrackingRect *)[theEvent userData];
				NSCursor *c = (NSCursor *)[r owner];
				[c push];
				}									// it is a mouse exited
			else									// so pop the cursor
				[NSCursor pop];
			break;

		case NSPeriodic:
			break;
		}
}

- (BOOL)tryToPerform:(SEL)anAction with:anObject
{
	return ([super tryToPerform:anAction with:anObject]);
}

- (BOOL)worksWhenModal
{
	return NO;
}

//
// Dragging
//
- (void)dragImage:(NSImage *)anImage
			   at:(NSPoint)baseLocation
			   offset:(NSSize)initialOffset
			   event:(NSEvent *)event
			   pasteboard:(NSPasteboard *)pboard
			   source:sourceObject
			   slideBack:(BOOL)slideFlag
{
}

- (void)registerForDraggedTypes:(NSArray *)newTypes
{
}

- (void)unregisterDraggedTypes
{
}

//
// Services and windows menu support
//
- (BOOL)isExcludedFromWindowsMenu
{
	return menu_exclude;
}

- (void)setExcludedFromWindowsMenu:(BOOL)flag
{
	menu_exclude = flag;
}

- validRequestorForSendType:(NSString *)sendType
				 returnType:(NSString *)returnType
{
id result = nil;

	if (delegate && [delegate respondsToSelector: _cmd])
		result = [delegate validRequestorForSendType: sendType
						   returnType: returnType];

	if (result == nil)
		result = [[NSApplication sharedApplication]
					   			 validRequestorForSendType: sendType
								 returnType: returnType];
	return result;
}

//
// Saving and restoring the frame
//
- (NSString *)frameAutosaveName
{
	return nil;
}

- (void)saveFrameUsingName:(NSString *)name
{
}

- (BOOL)setFrameAutosaveName:(NSString *)name
{
	return NO;
}

- (void)setFrameFromString:(NSString *)string
{
}

- (BOOL)setFrameUsingName:(NSString *)name
{
	return NO;
}

- (NSString *)stringWithSavedFrame
{
	return nil;
}

//
// Printing and postscript
//
- (NSData *)dataWithEPSInsideRect:(NSRect)rect	{ return nil; }
- (void)fax:sender								{}
- (void)print:sender							{}

//
// Assigning a delegate
//
- delegate										{ return delegate; }
- (void)setDelegate:anObject					{ delegate = anObject; }

//
// Implemented by the delegate
//
- (BOOL)windowShouldClose:sender
{
	if ([delegate respondsToSelector:@selector(windowShouldClose:)])
		return [delegate windowShouldClose:sender];
	else
		return YES;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	if ([delegate respondsToSelector:@selector(windowWillResize:toSize:)])
		return [delegate windowWillResize:sender toSize:frameSize];
	else
		return frameSize;
}

- windowWillReturnFieldEditor:(NSWindow *)sender toObject:client
{
	return nil;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidBecomeKey:)])
    return [delegate windowDidBecomeKey:aNotification];
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidBecomeMain:)])
    return [delegate windowDidBecomeMain:aNotification];
}

- (void)windowDidChangeScreen:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidChangeScreen:)])
    return [delegate windowDidChangeScreen:aNotification];
}

- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidDeminiaturize:)])
    return [delegate windowDidDeminiaturize:aNotification];
}

- (void)windowDidExpose:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidExpose:)])
    return [delegate windowDidExpose:aNotification];
}

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidMiniaturize:)])
    return [delegate windowDidMiniaturize:aNotification];
}

- (void)windowDidMove:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidMove:)])
    return [delegate windowDidMove:aNotification];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidResignKey:)])
    return [delegate windowDidResignKey:aNotification];
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidResignMain:)])
    return [delegate windowDidResignMain:aNotification];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidResize:)])
    return [delegate windowDidResize:aNotification];
}

- (void)windowDidUpdate:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowDidUpdate:)])
    return [delegate windowDidUpdate:aNotification];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowWillClose:)])
    return [delegate windowWillClose:aNotification];
}

- (void)windowWillMiniaturize:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowWillMiniaturize:)])
    return [delegate windowWillMiniaturize:aNotification];
}

- (void)windowWillMove:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(windowWillMove:)])
    return [delegate windowWillMove:aNotification];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [self setNextResponder: nil];

  [super encodeWithCoder:aCoder];

  NSDebugLog(@"NSWindow: start encoding\n");
  [aCoder encodeRect:frame];
  [aCoder encodeObject:content_view];
//  [aCoder encodeObjectReference: first_responder withName:NULL];
//  [aCoder encodeObjectReference: original_responder withName:NULL];
//  [aCoder encodeObjectReference: delegate withName:NULL];
  [aCoder encodeValueOfObjCType:"i" at:&window_num];
  [aCoder encodeObject:background_color];
  [aCoder encodeObject:represented_filename];
  [aCoder encodeObject:miniaturized_title];
  [aCoder encodeObject:window_title];
  [aCoder encodePoint:last_point];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &visible];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_key];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_main];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_edited];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_miniaturized];
  [aCoder encodeValueOfObjCType:"I" at: &style_mask];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &menu_exclude];

  // Version 2
  [aCoder encodeSize:minimum_size];
  [aCoder encodeSize:maximum_size];
  [aCoder encodeObject:miniaturized_image];
  [aCoder encodeValueOfObjCType:@encode(NSBackingStoreType) at: &backing_type];
  [aCoder encodeValueOfObjCType:@encode(int) at: &window_level];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_one_shot];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_autodisplay];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &optimize_drawing];
  [aCoder encodeValueOfObjCType:@encode(NSWindowDepth) at: &depth_limit];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &dynamic_depth_limit];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &cursor_rects_enabled];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_released_when_closed];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &disable_flush_window];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &hides_on_deactivate];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &accepts_mouse_moved];

  NSDebugLog(@"NSWindow: finish encoding\n");
}

- initWithCoder:aDecoder
{
  NSApplication *theApp;

  [super initWithCoder:aDecoder];

  NSDebugLog(@"NSWindow: start decoding\n");
  frame = [aDecoder decodeRect];
  content_view = [aDecoder decodeObject];
//  [aDecoder decodeObjectAt: &first_responder withName:NULL];
//  [aDecoder decodeObjectAt: &original_responder withName:NULL];
//  [aDecoder decodeObjectAt: &delegate withName:NULL];
  [aDecoder decodeValueOfObjCType:"i" at:&window_num];
  background_color = [aDecoder decodeObject];
  represented_filename = [aDecoder decodeObject];
  miniaturized_title = [aDecoder decodeObject];
  window_title = [aDecoder decodeObject];
  last_point = [aDecoder decodePoint];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &visible];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_key];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_main];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_edited];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_miniaturized];
  [aDecoder decodeValueOfObjCType:"I" at: &style_mask];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &menu_exclude];

  // Version 2
  minimum_size = [aDecoder decodeSize];
  maximum_size = [aDecoder decodeSize];
  miniaturized_image = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType:@encode(NSBackingStoreType)
	    at: &backing_type];
  [aDecoder decodeValueOfObjCType:@encode(int) at: &window_level];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_one_shot];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_autodisplay];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &optimize_drawing];
  [aDecoder decodeValueOfObjCType:@encode(NSWindowDepth) at: &depth_limit];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &dynamic_depth_limit];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &cursor_rects_enabled];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_released_when_closed];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &disable_flush_window];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &hides_on_deactivate];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &accepts_mouse_moved];

  // Register ourselves with the Application object
  // +++ we shouldn't do this because coding may not be done?
  //     better to do it in the awakeFromCoder method
  theApp = [NSApplication sharedApplication];
  [theApp addWindowsItem:self title:nil filename:NO];
  NSDebugLog(@"NSWindow: finish decoding\n");

  return self;
}

@end

//
// GNUstep backend methods
//
@implementation NSWindow (GNUstepBackend)

+ (NSWindow*)_windowWithTag:(int)windowNumber
{
	return nil;
}

//
// Mouse capture/release
//
- (void)_captureMouse: sender			{}			// Do nothing, should be
- (void)_releaseMouse: sender			{}			// implemented by back-end
- (void)performDeminiaturize:sender		{}
- (void)performHide:sender				{}
- (void)performUnhide:sender			{}

- (void)initDefaults								// Allow subclasses to init
{													// without the backend
	first_responder = nil;							// class attempting to
	original_responder = nil;						// create an actual window
	delegate = nil;
	window_num = 0;
	background_color = [[NSColor lightGrayColor] retain];
	represented_filename = @"Window";
	miniaturized_title = @"Window";
	miniaturized_image = nil;
	window_title = @"Window";
	last_point = NSZeroPoint;
	window_level = NSNormalWindowLevel;

	is_one_shot = NO;
	needs_display = NO;
	is_autodisplay = YES;
	optimize_drawing = YES;
	views_need_display = NO;
	depth_limit = 8;
	dynamic_depth_limit = YES;
	cursor_rects_enabled = NO;
	visible = NO;
	is_key = NO;
	is_main = NO;
	is_edited = NO;
	is_released_when_closed = NO;
	is_miniaturized = NO;
	disable_flush_window = NO;
	menu_exclude = NO;
	hides_on_deactivate = NO;
	accepts_mouse_moved = YES;
}

- cleanInit
{
	[super init];

	[self initDefaults];
	return self;
}

@end
