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
#include <AppKit/TrackingRectangle.h>
#include <AppKit/NSSliderCell.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSCursor.h>
#include <AppKit/PSMatrix.h>
#include <AppKit/NSWindowView.h>

#define ASSIGN(a, b)	[b retain]; \
						[a release]; \
						a = b;


//
// NSWindow implementation
//
@implementation NSWindow

static BOOL _needsFlushWindows = YES;

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSWindow class])
    {
      NSDebugLog(@"Initialize NSWindow class\n");

      // Initial version
      [self setVersion:2];
    }
}

// Saving and restoring the frame
+ (void)removeFrameUsingName:(NSString *)name
{
}

// Computing frame and content rectangles
+ (NSRect)contentRectForFrameRect:(NSRect)aRect
			styleMask:(unsigned int)aStyle
{
  return aRect;
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

// Screens and window depths
+ (NSWindowDepth)defaultDepthLimit
{
  return 8;
}

+ (void)_setNeedsFlushWindows:(BOOL)flag
{
  _needsFlushWindows = flag;
}

+ (BOOL)_needsFlushWindows		{ return _needsFlushWindows; }

//
// Instance methods
//
//
// Initialization
//
- init
{
int style;

	NSDebugLog(@"NSWindow -init\n");
															// default style
	style = NSTitledWindowMask | NSClosableWindowMask		// mask		
			| NSMiniaturizableWindowMask | NSResizableWindowMask;

	return [self initWithContentRect:NSZeroRect 
				 styleMask:style
				 backing:NSBackingStoreBuffered 
				 defer:NO];
}

- (void)dealloc
{
  // Release the content view
  if (content_view) {
    // Release the window view
    [[content_view superview] release];
    [content_view release];
  }

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

  // Initialize attributes and flags
  [self cleanInit];

  backing_type = bufferingType;
  style_mask = aStyle;

  // Size attributes
  frame = [NSWindow frameRectForContentRect: contentRect styleMask: aStyle];
  minimum_size = NSZeroSize;
  maximum_size = r.size;

  // Next responder is the application
  [self setNextResponder:theApp];

  // Cursor management
  cursor_rects_enabled = YES;
  cursor_rects_valid = NO;

  // Create our content view
  cframe.origin = NSZeroPoint;
  cframe.size = frame.size;
  [self setContentView:[[[NSView alloc] initWithFrame:cframe] autorelease]];

  // Register ourselves with the Application object
  [theApp addWindowsItem:self title:window_title filename:NO];

  _flushRectangles = [[NSMutableArray alloc] initWithCapacity:10];

  NSDebugLog(@"NSWindow end of init\n");
  return self;
}

//
// Accessing the content view
//
- contentView
{
  return content_view;
}

- (void)setContentView:(NSView *)aView
{
  NSView *wv;

  // Cannot have a nil content view
  if (!aView)
    aView = [[[NSView alloc] initWithFrame: frame] autorelease];

  // If the window view hasn't been created yet
  // then create it
  if ((!content_view) || ([content_view superview] == nil)) {
    wv = [[NSWindowView alloc] initWithFrame: frame];
    [wv viewWillMoveToWindow: self];
  }
  else
    wv = [content_view superview];

  if (content_view)
    [content_view removeFromSuperview];

  ASSIGN(content_view, aView);

  // Add to our window view
  [wv addSubview: content_view];
  NSAssert1 ([[wv subviews] count] == 1,
	     @"window's view has %d  subviews!",
	     [[wv subviews] count]);

  // Make us the view's next responder
  [content_view setNextResponder:self];
}

//
// Window graphics
//
- (NSColor *)backgroundColor
{
  return background_color;
}

- (NSString *)representedFilename
{
  return represented_filename;
}

- (void)setBackgroundColor:(NSColor *)color
{
  ASSIGN(background_color, color);
}

- (void)setRepresentedFilename:(NSString *)aString
{
  ASSIGN(represented_filename, aString);
}

- (void)setTitle:(NSString *)aString
{
  ASSIGN(window_title, aString);
}

- (void)setTitleWithRepresentedFilename:(NSString *)aString
{
  [self setRepresentedFilename:aString];
  [self setTitle:aString];
}

- (unsigned int)styleMask
{
  return style_mask;
}

- (NSString *)title
{
  return window_title;
}

//
// Window device attributes
//
- (NSBackingStoreType)backingType
{
  return backing_type;
}

- (NSDictionary *)deviceDescription
{
  return nil;
}

- (int)gState
{
  return 0;
}

- (BOOL)isOneShot
{
  return is_one_shot;
}

- (void)setBackingType:(NSBackingStoreType)type
{
  backing_type = type;
}

- (void)setOneShot:(BOOL)flag
{
  is_one_shot = flag;
}

- (int)windowNumber
{
  return window_num;
}

- (void)setWindowNumber:(int)windowNum
{
  window_num = windowNum;
}

//
// The miniwindow
//
- (NSImage *)miniwindowImage
{
  return miniaturized_image;
}

- (NSString *)miniwindowTitle
{
  return miniaturized_title;
}

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
{}

- (NSText *)fieldEditor:(BOOL)createFlag forObject:anObject
{
	if(!_fieldEditor && createFlag)					// each window has a global
		_fieldEditor = [[NSText alloc] init];		// text field editor 
													 
	return _fieldEditor;							
}

//
// Window status and ordering
//
- (void)becomeKeyWindow
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  // We are the key window
  is_key = YES;

  // Reset the cursor rects
  [self resetCursorRects];

  // Post notification
  [nc postNotificationName: NSWindowDidBecomeKeyNotification object: self];
}

- (void)becomeMainWindow
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  // We are the main window
  is_main = YES;

  // Post notification
  [nc postNotificationName: NSWindowDidBecomeMainNotification object: self];
}

- (BOOL)canBecomeKeyWindow
{
  return YES;
}

- (BOOL)canBecomeMainWindow
{
  return YES;
}

- (BOOL)hidesOnDeactivate
{
  return hides_on_deactivate;
}

- (BOOL)isKeyWindow
{
  return is_key;
}

- (BOOL)isMainWindow
{
  return is_main;
}

- (BOOL)isMiniaturized
{
  return is_miniaturized;
}

- (BOOL)isVisible
{
  return visible;
}

- (int)level
{
  return window_level;
}

- (void)makeKeyAndOrderFront:sender
{
  // Make ourself the key window
  [self makeKeyWindow];

  // Now order to the front
  [self orderFront:sender];
}

- (void)makeKeyWindow
{
  NSApplication *theApp = [NSApplication sharedApplication];

  // Can we become the key window
  if (![self canBecomeKeyWindow]) return;

  // Make the current key window resign
  [[theApp keyWindow] resignKeyWindow];

  // Make ourself become the key window
  [self becomeKeyWindow];
}

- (void)makeMainWindow
{
  NSApplication *theApp = [NSApplication sharedApplication];

  // Can we become the main window
  if (![self canBecomeMainWindow]) return;

  // Make the current main window resign
  [[theApp mainWindow] resignMainWindow];

  // Make ourself become the main window
  [self becomeMainWindow];
}

- (void)orderBack:sender
{
  visible = YES;
}

- (void)orderFront:sender
{
  visible = YES;
}

- (void)orderFrontRegardless
{
  visible = YES;
}

- (void)orderOut:sender
{
  visible = NO;
}

- (void)orderWindow:(NSWindowOrderingMode)place
	 relativeTo:(int)otherWin
{}

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

- (void)setHidesOnDeactivate:(BOOL)flag
{
  hides_on_deactivate = flag;
}

- (void)setLevel:(int)newLevel
{
  window_level = newLevel;
}

//
// Moving and resizing the window
//
- (NSPoint)cascadeTopLeftFromPoint:(NSPoint)topLeftPoint
{
  return NSZeroPoint;
}

- (void)center
{
  float w, h;
  NSRect n;

  // Should use MBScreen
  //w = MB_SCREEN_MAXWIDTH();
  //h = MB_SCREEN_MAXHEIGHT();
  n = frame;
  n.origin.x = (w - frame.size.width) / 2;
  n.origin.y = (h - frame.size.height) / 2;
  [self setFrame:n display:YES];
}

- (NSRect)constrainFrameRect:(NSRect)frameRect
		    toScreen:screen
{
  return NSZeroRect;
}

- (NSRect)frame
{
  return frame;
}

- (NSSize)minSize
{
  return minimum_size;
}

- (NSSize)maxSize
{
  return maximum_size;
}

- (void)setContentSize:(NSSize)aSize
{
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
  frame = frameRect;									
  														// post notification
  [nc postNotificationName: NSWindowDidResizeNotification object: self];

  if (flag) 											// display if requested
  	[self display];									
}

- (void)setFrameOrigin:(NSPoint)aPoint
{
  frame.origin = aPoint;
}

- (void)setFrameTopLeftPoint:(NSPoint)aPoint
{}

- (void)setMinSize:(NSSize)aSize
{
  minimum_size = aSize;
}

- (void)setMaxSize:(NSSize)aSize
{
  maximum_size = aSize;
}

//
// Converting coordinates
//
- (NSPoint)convertBaseToScreen:(NSPoint)aPoint
{
  return NSZeroPoint;
}

- (NSPoint)convertScreenToBase:(NSPoint)aPoint
{
  return NSZeroPoint;
}


//
// Managing the display
//
- (void)disableFlushWindow
{
  disable_flush_window = YES;
}

- (void)display
{
  visible = YES;
  needs_display = NO;

  // Tell the first responder that it is the first responder
  // So it can set the focus to itself
  [first_responder becomeFirstResponder];

  /* Temporary disable displaying */
  [self disableFlushWindow];

  // Draw the window view
  [[content_view superview] display];

  /* Reenable displaying and flush the window */
  [self enableFlushWindow];
}

- (void)displayIfNeeded
{
  if (needs_display) {
    [[content_view superview] _displayNeededViews];
    needs_display = NO;
  }
}

- (void)enableFlushWindow
{
  disable_flush_window = NO;
}

- (void)flushWindow
{
  needs_flush = NO;
  [_flushRectangles removeAllObjects];
  [[content_view superview] _recursivelyResetNeedsDisplayInAllViews];
}

- (void)flushWindowIfNeeded
{
  if (!disable_flush_window && needs_flush) {
    needs_flush = NO;
    [self flushWindow];
  }
}

- (void)_collectFlushRectangles
{
  PSMatrix* originMatrix;
  PSMatrix* sizeMatrix;

  if (disable_flush_window || backing_type == NSBackingStoreNonretained)
    return;

//  NSLog (@"_collectFlushRectangles");
  [_flushRectangles removeAllObjects];

  originMatrix = [PSMatrix new];
  sizeMatrix = [PSMatrix new];

  [[content_view superview]
    _collectInvalidatedRectanglesInArray:_flushRectangles
    originMatrix:originMatrix
    sizeMatrix:sizeMatrix];

  [originMatrix release];
  [sizeMatrix release];
}

- (BOOL)isAutodisplay
{
  return is_autodisplay;
}

- (BOOL)isFlushWindowDisabled
{
  return disable_flush_window;
}

- (void)setAutodisplay:(BOOL)flag
{
  is_autodisplay = flag;
}

- (void)setViewsNeedDisplay:(BOOL)flag
{
  views_need_display = flag;
}

- (void)update
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	if(is_autodisplay && needs_display)					// if autodisplay is
		{												// enabled
		[self _collectFlushRectangles];
		[self displayIfNeeded];
		[self flushWindowIfNeeded];
    	}

	[nc postNotificationName: NSWindowDidUpdateNotification object: self];
}

- (void)useOptimizedDrawing:(BOOL)flag
{
  optimize_drawing = flag;
}

- (BOOL)viewsNeedDisplay
{
  return views_need_display;
}

// Screens and window depths
- (BOOL)canStoreColor
{
  // If the depth is greater than a single bit
  if (depth_limit > 1)
    return YES;
  else
    return NO;
}

- (NSScreen *)deepestScreen
{
  return [NSScreen deepestScreen];
}

- (NSWindowDepth)depthLimit
{
  return depth_limit;
}

- (BOOL)hasDynamicDepthLimit
{
  return dynamic_depth_limit;
}

- (NSScreen *)screen
{
  return [NSScreen mainScreen];
}

- (void)setDepthLimit:(NSWindowDepth)limit
{
  depth_limit = limit;
}

- (void)setDynamicDepthLimit:(BOOL)flag
{
  dynamic_depth_limit = flag;
}

//
// Cursor management
//
- (BOOL)areCursorRectsEnabled
{
  return cursor_rects_enabled;
}

- (void)disableCursorRects
{
  cursor_rects_enabled = NO;
}

- (void)discardCursorRectsForView:(NSView *)theView
{
  NSArray *s;
  id e;
  NSView *v;

  // Discard for the view
  [theView discardCursorRects];

  // Discard for the view's subviews
  s = [theView subviews];
  e = [s objectEnumerator];
  while ((v = [e nextObject]))
    [self discardCursorRectsForView: v];
}

- (void)discardCursorRects
{
  [self discardCursorRectsForView: [content_view superview]];
}

- (void)enableCursorRects
{
  cursor_rects_enabled = YES;
}

- (void)invalidateCursorRectsForView:(NSView *)aView
{
  cursor_rects_valid = NO;
}

- (void)resetCursorRectsForView:(NSView *)theView
{
  NSArray *s;
  id e;
  NSView *v;

  // Reset the view
  [theView resetCursorRects];

  // Reset the view's subviews
  s = [theView subviews];
  e = [s objectEnumerator];
  while ((v = [e nextObject]))
    [self resetCursorRectsForView: v];
}

- (void)resetCursorRects
{
  // Tell all the views to reset their cursor rects
  [self resetCursorRectsForView: [content_view superview]];

  // Cursor rects are now valid
  cursor_rects_valid = YES;
}

//
// Handling user actions and events
//
- (void)close
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
															// Notify delegate
	[nc postNotificationName: NSWindowWillCloseNotification object: self];
	[self orderOut:self];
	visible = NO;
															// if app has no
	if(![[NSApplication sharedApplication] mainMenu])		// menu terminate
		[[NSApplication sharedApplication] terminate:self];
	else													// otherwise just 
		[self autorelease];									// release self 
}

- (void)deminiaturize:sender
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  // Set our flag to say we are not miniaturized
  is_miniaturized = NO;
  visible = YES;

  [self performDeminiaturize:self];

  // Notify our delegate
  [nc postNotificationName: NSWindowDidDeminiaturizeNotification object: self];
}

- (BOOL)isDocumentEdited
{
  return is_edited;
}

- (BOOL)isReleasedWhenClosed
{
  return is_released_when_closed;
}

- (void)miniaturize:sender
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  // Notify our delegate
  [nc postNotificationName: NSWindowWillMiniaturizeNotification object: self];

  [self performMiniaturize:self];

  // Notify our delegate
  [nc postNotificationName: NSWindowDidMiniaturizeNotification object: self];
}

- (void)performClose:sender									
{
	if([self styleMask] & NSClosableWindowMask)
		{											// self must have a close
		NSBeep();									// button in order to be
		return;										// closed
		}
															
	if ([delegate respondsToSelector:@selector(windowShouldClose:)])
		{											// if delegate responds to
    	if(![delegate windowShouldClose:self])		// windowShouldClose query
			{										// it to see if it's ok to
			NSBeep();								// close the window
			return;									
			}
		}											
	else
		{
		if ([self respondsToSelector:@selector(windowShouldClose:)])
			{										// else if self responds to
			if(![self windowShouldClose:self])		// windowShouldClose query
				{									// self to see if it's ok
				NSBeep();							// to close self
				return;								
				} 
			}										
		}

	[self close];									// it's ok to close self								
}

- (void)performMiniaturize:sender
{
  // Set our flag to say we are miniaturized
  is_miniaturized = YES;
}

- (int)resizeFlags
{
  return 0;
}

- (void)setDocumentEdited:(BOOL)flag
{
  is_edited = flag;
}

- (void)setReleasedWhenClosed:(BOOL)flag
{
  is_released_when_closed = flag;
}

//
// Aiding event handling
//
- (BOOL)acceptsMouseMovedEvents
{
  return accepts_mouse_moved;
}

- (NSEvent *)currentEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];

  return [theApp currentEvent];
}

- (void)discardEventsMatchingMask:(unsigned int)mask
		      beforeEvent:(NSEvent *)lastEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];

  [theApp discardEventsMatchingMask: mask beforeEvent: lastEvent];
}

- (NSResponder *)firstResponder
{
  return first_responder;
}

- (void)keyDown:(NSEvent *)theEvent
{
  // save the first responder so that the key up
  // goes to it and not a possible new first responder
  original_responder = first_responder;

  // Send the first responder the key down
  [first_responder keyDown:theEvent];
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
  // If already the first responder then return
  if (first_responder == aResponder)
    return YES;

  // If not a NSResponder then forget it
  if (![aResponder isKindOfClass:[NSResponder class]])
    return NO;

  // Does it accept the first responder?
  if (![aResponder acceptsFirstResponder])
    return NO;

  // Notify current first responder that it should resign
  // If it says NO then no change
  // But make sure that there even is a first responder
  if ((first_responder) && (![first_responder resignFirstResponder]))
    return NO;

  // Make it the first responder
  first_responder = aResponder;

  // Notify it that it just became the first responder
  [first_responder becomeFirstResponder];

  return YES;
}

- (NSPoint)mouseLocationOutsideOfEventStream
{
  return NSZeroPoint;
}

- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
{
  NSApplication *theApp = [NSApplication sharedApplication];
  return [theApp nextEventMatchingMask: mask untilDate: nil
		 inMode:NSEventTrackingRunLoopMode dequeue: YES];
}

- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
			 untilDate:(NSDate *)expiration
			    inMode:(NSString *)mode
			 dequeue:(BOOL)deqFlag
{
  NSApplication *theApp = [NSApplication sharedApplication];
  return [theApp nextEventMatchingMask: mask untilDate: expiration
		 inMode: mode dequeue: deqFlag];
}

- (void)postEvent:(NSEvent *)event
	  atStart:(BOOL)flag
{
  NSApplication *theApp = [NSApplication sharedApplication];

  [theApp postEvent:event atStart:flag];
}

- (void)setAcceptsMouseMovedEvents:(BOOL)flag
{
  accepts_mouse_moved = flag;
}

- (void)checkTrackingRectangles:(NSView *)theView forEvent:(NSEvent *)theEvent
{
  NSArray *tr = [theView trackingRectangles];
  NSArray *sb = [theView subviews];
  TrackingRectangle *r;
  int i, j;
  BOOL last, now;
  NSEvent *e;

  // Loop through tracking rectangles
  j = [tr count];
  for (i = 0;i < j; ++i)
    {
      r = (TrackingRectangle *)[tr objectAtIndex:i];
      // Check mouse at last point
      last = [theView mouse:last_point inRect:[r rectangle]];
      // Check mouse at current point
      now = [theView mouse:[theEvent locationInWindow] inRect:[r rectangle]];

      // Mouse entered event
      if ((!last) && (now))
	{
	  id owner = [r owner];
	  e = [NSEvent enterExitEventWithType:NSMouseEntered
		       location:[theEvent locationInWindow] 
		       modifierFlags:[theEvent modifierFlags]
		       timestamp:0 windowNumber:[theEvent windowNumber]
		       context:NULL eventNumber:0 
		       trackingNumber:[r tag] userData:[r userData]];
	  // Send the event to the owner
	  if ([owner respondsToSelector:@selector(mouseEntered:)])
	    [owner mouseEntered:e];
	}

      // Mouse exited event
      if ((last) && (!now))
	{
	  id owner = [r owner];
	  e = [NSEvent enterExitEventWithType:NSMouseExited
		       location:[theEvent locationInWindow] 
		       modifierFlags:[theEvent modifierFlags]
		       timestamp:0 windowNumber:[theEvent windowNumber]
		       context:NULL eventNumber:0 
		       trackingNumber:[r tag] userData:[r userData]];
	  // Send the event to the owner
	  if ([owner respondsToSelector:@selector(mouseExited:)])
	    [owner mouseExited:e];
	}
    }

  // Check the tracking rectangles for the subviews
  j = [sb count];
  for (i = 0;i < j; ++i)
    [self checkTrackingRectangles:[sb objectAtIndex:i] forEvent:theEvent];
}

- (void)checkCursorRectangles:(NSView *)theView forEvent:(NSEvent *)theEvent
{
  NSArray *tr = [theView cursorRectangles];
  NSArray *sb = [theView subviews];
  TrackingRectangle *r;
  int i, j;
  BOOL last, now;
  NSEvent *e;
  NSPoint loc = [theEvent locationInWindow];
  NSPoint lastPointConverted;
  NSPoint locationConverted;
  NSRect rect;

  // Loop through cursor rectangles
  j = [tr count];
  for (i = 0;i < j; ++i)
    {
      // Convert cursor rectangle to window coordinates
      r = (TrackingRectangle *)[tr objectAtIndex:i];

      lastPointConverted = [theView convertPoint:last_point fromView:nil];
      locationConverted = [theView convertPoint:loc fromView:nil];

      // Check mouse at last point
      rect = [r rectangle];
      last = [theView mouse:lastPointConverted inRect:rect];
      now = [theView mouse:locationConverted inRect:rect];

      // Mouse entered
      if ((!last) && (now))
	{
	  // Post cursor update event
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

      // Mouse exited event
      if ((last) && (!now))
	{
	  // Post cursor update event
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

  // Check the cursor rectangles for the subviews
  j = [sb count];
  for (i = 0;i < j; ++i)
    [self checkCursorRectangles:[sb objectAtIndex:i] forEvent:theEvent];
}

- (void)sendEvent:(NSEvent *)theEvent
{
  // If the cursor rects are invalid
  // Then discard and reset
  if (!cursor_rects_valid)
    {
      [self discardCursorRects];
      [self resetCursorRects];
    }

  switch ([theEvent type])
    {
      //
      // Mouse events
      //
      //
      // Left mouse down
      //
    case NSLeftMouseDown:
      {
	NSView *v = [content_view hitTest:[theEvent locationInWindow]];
	NSDebugLog([v description]);
	NSDebugLog(@"\n");
	[v mouseDown:theEvent];
	last_point = [theEvent locationInWindow];
	break;
      }
      //
      // Left mouse up
      //
    case NSLeftMouseUp:
      {
	NSView *v = [content_view hitTest:[theEvent locationInWindow]];
	[v mouseUp:theEvent];
	last_point = [theEvent locationInWindow];
	break;
      }
      //
      // Right mouse down
      //
    case NSRightMouseDown:
      {
	NSView *v = [content_view hitTest:[theEvent locationInWindow]];
	[v rightMouseDown:theEvent];
	last_point = [theEvent locationInWindow];
	break;
      }
      //
      // Right mouse up
      //
    case NSRightMouseUp:
      {
	NSView *v = [content_view hitTest:[theEvent locationInWindow]];
	[v rightMouseUp:theEvent];
	last_point = [theEvent locationInWindow];
	break;
      }
      //
      // Mouse moved
      //
    case NSMouseMoved:
      {
	NSView *v = [content_view hitTest:[theEvent locationInWindow]];

	// First send the NSMouseMoved event
	[v mouseMoved:theEvent];

	// We need to go through all of the views, and any with
	//   a tracking rectangle then we need to determine if we
	//   should send a NSMouseEntered or NSMouseExited event
	[self checkTrackingRectangles:content_view forEvent:theEvent];

	// We need to go through all of the views, and any with
	// a cursor rectangle then we need to determine if we
	// should send a cursor update event
	// We only do this if we are the key window
	if ([self isKeyWindow])
	  [self checkCursorRectangles: content_view forEvent: theEvent];

	last_point = [theEvent locationInWindow];
	break;
      }
      //
      // Left mouse dragged
      //
    case NSLeftMouseDragged:
      {
	last_point = [theEvent locationInWindow];
	break;
      }
      //
      // Right mouse dragged
      //
    case NSRightMouseDragged:
      {
	last_point = [theEvent locationInWindow];
	break;
      }
      //
      // Mouse entered
      //
    case NSMouseEntered:
      {
	break;
      }
      //
      // Mouse exited
      //
    case NSMouseExited:
      {
	break;
      }

      //
      // Keyboard events
      //
      //
      // Key down
      //
    case NSKeyDown:
      {
	[self keyDown:theEvent];
	break;
      }
      //
      // Key up
      //
    case NSKeyUp:
      {
	// send message to object that got the key down
	if (original_responder)
	  [original_responder keyUp:theEvent];
	break;
      }

      //
      // Miscellaneous events
      //
      //
      // Flags changed
      //
    case NSFlagsChanged:
      {
	break;
      }
      //
      // Cursor update
      //
    case NSCursorUpdate:
      {
	// Is it a mouse entered
	if ([theEvent trackingNumber])
	  {
	    // push the cursor
	    TrackingRectangle *r = (TrackingRectangle *)[theEvent userData];
	    NSCursor *c = (NSCursor *)[r owner];
	    [c push];
	  }
	else
	  {
	    // it is a mouse exited
	    // so pop the cursor
	    [NSCursor pop];
	  }
	break;
      }
    case NSPeriodic:
      {
        break;
      }
    }

  [NSWindow _flushWindows];
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
{}

- (void)registerForDraggedTypes:(NSArray *)newTypes
{}

- (void)unregisterDraggedTypes
{}

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
  return nil;
}

//
// Saving and restoring the frame
//
- (NSString *)frameAutosaveName
{
  return nil;
}

- (void)saveFrameUsingName:(NSString *)name
{}

- (BOOL)setFrameAutosaveName:(NSString *)name
{
  return NO;
}

- (void)setFrameFromString:(NSString *)string
{}

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
- (NSData *)dataWithEPSInsideRect:(NSRect)rect
{
  return nil;
}

- (void)fax:sender
{}

- (void)print:sender
{}

//
// Assigning a delegate
//
- delegate
{
  return delegate;
}

- (void)setDelegate:anObject
{
  delegate = anObject;
}

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

- (NSSize)windowWillResize:(NSWindow *)sender
		    toSize:(NSSize)frameSize
{
  if ([delegate respondsToSelector:@selector(windowWillResize:toSize:)])
    return [delegate windowWillResize:sender toSize:frameSize];
  else
    return frameSize;
}

- windowWillReturnFieldEditor:(NSWindow *)sender
		     toObject:client
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

- (void)_setNeedsFlush
{
//  NSLog (@"NSWindow _setNeedsFlush");
  needs_flush = YES;
  _needsFlushWindows = YES;
}

- (void)_view:(NSView*)view needsFlushInRect:(NSRect)rect
{
  [self _setNeedsFlush];

  /* Convert the rectangle to the window coordinates */
  rect = [view convertRect:rect toView:nil];

  /* If the view is rotated then compute the bounding box of the rectangle in
     the window's coordinates */
  if ([view isRotatedFromBase])
    rect = [view _boundingRectFor:rect];

  /* TODO: Optimize adding rect to the already existing arrays */

  [_flushRectangles addObject:[NSValue valueWithRect:rect]];
}

- (void)_setNeedsDisplay
{
//  NSLog (@"NSWindow setNeedsDisplay");
  needs_display = YES;
  [self _setNeedsFlush];
}

- (BOOL)_needsFlush				{ return needs_flush; }

+ (BOOL)_flushWindows
{
  int i, count;
  NSArray* windowList;

  if (!_needsFlushWindows)
    return NO;

//  NSLog (@"_flushWindows");

  windowList = [[NSApplication sharedApplication] windows];
  
  for (i = 0, count = [windowList count]; i < count; i++) 
	{
    NSWindow* window = [windowList objectAtIndex:i];

    if (window->needs_display || window->needs_flush) 
		{
		[window _collectFlushRectangles];
		[window displayIfNeeded];
		[window flushWindowIfNeeded];
    	}
  }

  _needsFlushWindows = NO;
  return YES;
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

+ (NSWindow*)windowWithNumber:(int)windowNumber
{
  return nil;
}

//
// Mouse capture/release
//
- (void)captureMouse: sender
{
    // Do nothing, should be overridden by back-end
}

- (void)releaseMouse: sender
{
    // Do nothing, should be overridden by back-end
}

// Allow subclasses to init without the backend class
// attempting to create an actual window
- (void)initDefaults
{
  first_responder = nil;
  original_responder = nil;
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

- (void)performDeminiaturize:sender
{
  // Do nothing, should be overridden by back-end
}

- (void)performHide:sender
{
  // Do nothing, should be overridden by back-end
}

- (void)performUnhide:sender
{
  // Do nothing, should be overridden by back-end
}

@end
