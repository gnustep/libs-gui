/* 
   NSWindow.m

   The window class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
            Venkat Ajjanagadde <venkat@ocbi.com>
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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSWindow.h>
#include <gnustep/gui/NSApplication.h>
#include <gnustep/gui/NSTextFieldCell.h>
#include <gnustep/gui/NSTextField.h>
#include <gnustep/gui/NSColor.h>
#include <gnustep/gui/TrackingRectangle.h>
#include <gnustep/gui/NSSliderCell.h>
#include <gnustep/base/NSCoder.h>

// NSWindow notifications
NSString *NSWindowDidBecomeKeyNotification;
NSString *NSWindowDidBecomeMainNotification;
NSString *NSWindowDidChangeScreenNotification;
NSString *NSWindowDidDeminiaturizeNotification;
NSString *NSWindowDidExposeNotification;
NSString *NSWindowDidMiniaturizeNotification;
NSString *NSWindowDidMoveNotification;
NSString *NSWindowDidResignKeyNotification;
NSString *NSWindowDidResignMainNotification;
NSString *NSWindowDidResizeNotification;
NSString *NSWindowDidUpdateNotification;
NSString *NSWindowWillCloseNotification;
NSString *NSWindowWillMiniaturizeNotification;
NSString *NSWindowWillMoveNotification;

//
// NSWindow implementation
//
@implementation NSWindow

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSWindow class])
    {
      NSLog(@"Initialize NSWindow class\n");

      // Initial version
      [self setVersion:1];
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
  NSRect t;
  return t;
}

+ (NSRect)frameRectForContentRect:(NSRect)aRect
			styleMask:(unsigned int)aStyle
{
  NSRect t;
  return t;
}

+ (NSRect)minFrameWidthWithTitle:(NSString *)aTitle
		       styleMask:(unsigned int)aStyle
{
  NSRect t;
  return t;
}

// Screens and window depths
//+ (NSWindowDepth)defaultDepthLimit

//
// Instance methods
//
//
// Initialization
//
- init
{
  int style;

  NSLog(@"NSWindow -init\n");
  style = NSTitledWindowMask | NSClosableWindowMask
    | NSMiniaturizableWindowMask | NSResizableWindowMask;
  return [self initWithContentRect:NSZeroRect styleMask:style
	       backing:NSBackingStoreBuffered defer:NO];
}

- (void)dealloc
{
  NSApplication *theApp = [NSApplication sharedApplication];

  NSDebugLog(@"Remove NSWindow from application\n");
  // Remove ourselves from the application window list
  [theApp removeWindowsItem:self];

  // Release the content view
  NSDebugLog(@"Release content view\n");
  if (content_view) [content_view release];

  NSDebugLog(@"NSWindow dealloc super\n");
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
  NSLog(@"NSWindow -initWithContentRect:\n");
  return [self initWithContentRect:contentRect styleMask:aStyle
	       backing:bufferingType defer:flag screen:nil];
}

- initWithContentRect:(NSRect)contentRect
	    styleMask:(unsigned int)aStyle
	      backing:(NSBackingStoreType)bufferingType
		defer:(BOOL)flag
	       screen:aScreen
{
  NSApplication *theApp = [NSApplication sharedApplication];

  NSLog(@"NSWindow default initializer\n");
  if (!theApp)
    NSLog(@"No application!\n");

  [super init];

  NSLog(@"NSWindow start of init\n");

  frame = contentRect;
  style_mask = aStyle;

  // Next responder is the application
  [self setNextResponder:theApp];

  // Initialize attributes and flags
  frame_view = nil;
  [self setContentView:[[NSView alloc] initWithFrame:frame]];
  first_responder = nil;
  delegate = nil;
  window_num = 0;
  background_color = [NSColor grayColor];
  represented_filename = @"Window";
  miniaturized_title = @"Window";
  window_title = @"Window";
  visible = NO;
  is_key = NO;
  is_main = NO;
  is_edited = NO;
  is_miniaturized = NO;
  menu_exclude = NO;
  backing_type = bufferingType;
  disable_flush_window = NO;

  // Register ourselves with the Application object
  [theApp addWindowsItem:self title:window_title filename:NO];

  NSLog(@"NSWindow end of init\n");
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
  // Not an NSView -then forget it
  if (![aView isKindOfClass:[NSView class]])
    return;

	// Release current content view
  if (content_view)
    {
      // Tell view it is no longer in a window
      [content_view viewWillMoveToWindow:nil];
      [content_view release];
    }

  content_view = aView;
  [content_view retain];
  // Tell the view its changing windows
  [content_view viewWillMoveToWindow:self];
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
  background_color = color;
}

- (void)setRepresentedFilename:(NSString *)aString
{
  represented_filename = aString;
}

- (void)setTitle:(NSString *)aString
{
  window_title = aString;
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
  return NO;
}

- (void)setBackingType:(NSBackingStoreType)type
{
  backing_type = type;
}

- (void)setOneShot:(BOOL)flag
{}

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
  return nil;
}

- (NSString *)miniwindowTitle
{
  return miniaturized_title;
}

- (void)setMiniwindowImage:(NSImage *)image
{}

- (void)setMiniwindowTitle:(NSString *)title;
{
  miniaturized_title = title;
}

//
// The field editor
//
- (void)endEditingFor:anObject
{}

- (NSText *)fieldEditor:(BOOL)createFlag
	      forObject:anObject
{
  return nil;
}

//
// Window status and ordering
//
- (void)becomeKeyWindow
{
  // We are the key window
  is_key = YES;

  // Post notification
  [self windowDidBecomeKey:self];
}

- (void)becomeMainWindow
{
  // We are the main window
  is_main = YES;

  // Post notification
  [self windowDidBecomeMain:self];
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
  return NO;
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
  return 0;
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
  visible = YES;
}

- (void)orderWindow:(NSWindowOrderingMode)place
	 relativeTo:(int)otherWin
{}

- (void)resignKeyWindow
{
  is_key = NO;

  // Post notification
  [self windowDidResignKey: self];
}

- (void)resignMainWindow
{
  is_main = NO;

  // Post notification
  [self windowDidResignMain: self];
}

- (void)setHidesOnDeactivate:(BOOL)flag
{}

- (void)setLevel:(int)newLevel
{}

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
  return NSZeroSize;
}

- (NSSize)maxSize
{
  return NSZeroSize;
}

- (void)setContentSize:(NSSize)aSize
{
}

- (void)setFrame:(NSRect)frameRect
	 display:(BOOL)flag
{
  frame = frameRect;

  if (!flag) return;
  [self display];
}

- (void)setFrameOrigin:(NSPoint)aPoint
{}

- (void)setFrameTopLeftPoint:(NSPoint)aPoint
{}

- (void)setMinSize:(NSSize)aSize
{}

- (void)setMaxSize:(NSSize)aSize
{}

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
- (void)display
{
  visible = YES;

  // Tell the first responder that it is the first responder
  // So it can set the focus to itself
  [first_responder becomeFirstResponder];
}

- (void)disableFlushWindow
{
  disable_flush_window = YES;
}

- (void)displayIfNeeded
{}

- (void)enableFlushWindow
{
  disable_flush_window = NO;
}

- (void)flushWindow
{}

- (void)flushWindowIfNeeded
{}

- (BOOL)isAutodisplay
{
  return YES;
}

- (BOOL)isFlushWindowDisabled
{
  return NO;
}

- (void)setAutoDisplay:(BOOL)flag
{}

- (void)setViewsNeedDisplay:(BOOL)flag
{}

- (void)update
{}

- (void)useOptimizedDrawing:(BOOL)flag
{}

- (BOOL)viewsNeedDisplay
{
  return NO;
}

// Screens and window depths
//- (BOOL)canStoreColor;
//- (NSScreen *)deepestScreen;
//- (NSWindowDepth)depthLimit;
//- (BOOL)hasDynamicDepthLimit;
//- (NSScreen *)screen;
//- (void)setDepthLimit:(NSWindowDepth)limit;
//- (void)setDynamicDepthLimit:(BOOL)flag;

//
// Cursor management
//
- (BOOL)areCursorRectsEnabled
{
  return NO;
}

- (void)disableCursorRects
{}

- (void)discardCursorRects
{}

- (void)enableCursorRects
{}

- (void)invalidateCursorRectsForView:(NSView *)aView
{}

- (void)resetCursorRects
{}

//
// Handling user actions and events
//
- (void)close
{
  // Notify our delegate
  [self windowWillClose:self];

  [self performClose:self];
}

- (void)deminiaturize:sender
{
  // Set our flag to say we are not miniaturized
  is_miniaturized = NO;
  visible = YES;

  // Notify our delegate
  [self windowDidDeminiaturize:self];
}

- (BOOL)isDocumentEdited
{
  return is_edited;
}

- (BOOL)isReleasedWhenClosed
{
  return YES;
}

- (void)miniaturize:sender
{
  // Notify our delegate
  [self windowWillMiniaturize:self];

  [self performMiniaturize:self];

  // Notify our delegate
  [self windowDidMiniaturize:self];
}

- (void)performClose:sender
{
  visible = NO;
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
{}

- (void)setReleasedWhenClosed:(BOOL)flag
{}

//
// Aiding event handling
//
- (BOOL)acceptsMouseMovedEvents
{
  return YES;
}

- (NSEvent *)currentEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];

  return [theApp currentEvent];
}

- (void)discardEventsMatchingMask:(unsigned int)mask
		      beforeEvent:(NSEvent *)lastEvent
{}

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
  if ((![first_responder resignFirstResponder]) && first_responder)
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
  return nil;
}

- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
			 untilDate:(NSDate *)expiration
			    inMode:(NSString *)mode
			 dequeue:(BOOL)deqFlag
{
  return nil;
}

- (void)postEvent:(NSEvent *)event
	  atStart:(BOOL)flag
{
  NSApplication *theApp = [NSApplication sharedApplication];

  [theApp postEvent:event atStart:flag];
}

- (void)setAcceptsMouseMovedEvents:(BOOL)flag
{}

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
	  e = [NSEvent enterExitEventWithType:NSMouseEntered
		       location:[theEvent locationInWindow] 
		       modifierFlags:[theEvent modifierFlags]
		       timestamp:0 windowNumber:[theEvent windowNumber]
		       context:NULL eventNumber:0 
		       trackingNumber:[r tag] userData:[r userData]];
	  // Send the event to the view
	  [theView mouseEntered:e];
	}

      // Mouse exited event
      if ((last) && (!now))
	{
	  e = [NSEvent enterExitEventWithType:NSMouseExited
		       location:[theEvent locationInWindow] 
		       modifierFlags:[theEvent modifierFlags]
		       timestamp:0 windowNumber:[theEvent windowNumber]
		       context:NULL eventNumber:0 
		       trackingNumber:[r tag] userData:[r userData]];
	  // Send the event to the view
	  [theView mouseExited:e];
	}
    }

  // Check the tracking rectangles for the subviews
  j = [sb count];
  for (i = 0;i < j; ++i)
    [self checkTrackingRectangles:[sb objectAtIndex:i] forEvent:theEvent];
}

- (void)sendEvent:(NSEvent *)theEvent
{

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
	NSLog([content_view description]);
	NSLog(@"\n");
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
	break;
      }
    }
}

- (BOOL)tryToPerform:(SEL)anAction with:anObject
{
  return ([super tryToPerform:anAction with:anObject]);
}

- (BOOL)worksWhenModal
{
  return YES;
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
- (NSDate *)dataWithEPSInsideRect:(NSRect)rect
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
  if ([delegate respondsTo:@selector(windowShouldClose:)])
    return [delegate windowShouldClose:sender];
  else
    return YES;
}

- (NSSize)windowWillResize:(NSWindow *)sender
		    toSize:(NSSize)frameSize
{
  if ([delegate respondsTo:@selector(windowWillResize:toSize:)])
    return [delegate windowWillResize:sender toSize:frameSize];
  else
    return frameSize;
}

- windowWillReturnFieldEditor:(NSWindow *)sender
		     toObject:client
{
  return nil;
}

- (void)windowDidBecomeKey:sender
{
  if ([delegate respondsTo:@selector(windowDidBecomeKey:)])
    return [delegate windowDidBecomeKey:sender];
}

- (void)windowDidBecomeMain:sender
{
  if ([delegate respondsTo:@selector(windowDidBecomeMain:)])
    return [delegate windowDidBecomeMain:sender];
}

- (void)windowDidChangeScreen:sender
{
  if ([delegate respondsTo:@selector(windowDidChangeScreen:)])
    return [delegate windowDidChangeScreen:sender];
}

- (void)windowDidDeminiaturize:sender
{
  if ([delegate respondsTo:@selector(windowDidDeminiaturize:)])
    return [delegate windowDidDeminiaturize:sender];
}

- (void)windowDidExpose:sender
{
  if ([delegate respondsTo:@selector(windowDidExpose:)])
    return [delegate windowDidExpose:sender];
}

- (void)windowDidMiniaturize:sender
{
  if ([delegate respondsTo:@selector(windowDidMiniaturize:)])
    return [delegate windowDidMiniaturize:sender];
}

- (void)windowDidMove:sender
{
  if ([delegate respondsTo:@selector(windowDidMove:)])
    return [delegate windowDidMove:sender];
}

- (void)windowDidResignKey:sender
{
  if ([delegate respondsTo:@selector(windowDidResignKey:)])
    return [delegate windowDidResignKey:sender];
}

- (void)windowDidResignMain:sender
{
  if ([delegate respondsTo:@selector(windowDidResignMain:)])
    return [delegate windowDidResignMain:sender];
}

- (void)windowDidResize:sender
{
  if ([delegate respondsTo:@selector(windowDidResize:)])
    return [delegate windowDidResize:sender];
}

- (void)windowDidUpdate:sender
{
  if ([delegate respondsTo:@selector(windowDidUpdate:)])
    return [delegate windowDidUpdate:sender];
}

- (void)windowWillClose:sender
{
  if ([delegate respondsTo:@selector(windowWillClose:)])
    return [delegate windowWillClose:sender];
}

- (void)windowWillMiniaturize:sender
{
  if ([delegate respondsTo:@selector(windowWillMiniaturize:)])
    return [delegate windowWillMiniaturize:sender];
}

- (void)windowWillMove:sender
{
  if ([delegate respondsTo:@selector(windowWillMove:)])
    return [delegate windowWillMove:sender];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  NSApplication *theApp = [NSApplication sharedApplication];

  [self setNextResponder: nil];

  [super encodeWithCoder:aCoder];

  NSLog(@"NSWindow: start encoding\n");
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
  NSLog(@"NSWindow: finish encoding\n");
}

- initWithCoder:aDecoder
{
  NSApplication *theApp;

  [super initWithCoder:aDecoder];

  NSLog(@"NSWindow: start decoding\n");
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

  // Register ourselves with the Application object
  // +++ we shouldn't do this because coding may not be done?
  //     better to do it in the awakeFromCoder method
  theApp = [NSApplication sharedApplication];
  [theApp addWindowsItem:self title:nil filename:NO];
  NSLog(@"NSWindow: finish decoding\n");

  return self;
}

//
// GNUstep additional methods
//

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

@end
