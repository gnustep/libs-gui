/*
   The window class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
            Venkat Ajjanagadde <venkat@ocbi.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: June 1998
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: December 1998

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
#include <Foundation/NSGeometry.h>
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
#include <AppKit/NSView.h>
#include <AppKit/NSCursor.h>
#include <AppKit/PSOperators.h>


@interface GSWindowView : NSView
{
}
@end

@implementation GSWindowView

- (BOOL) isOpaque
{
  return YES;
}

- (void) drawRect: (NSRect)rect
{
  NSColor *c = [[self window] backgroundColor];

  [c set];
  NSRectFill(rect);
}

- (Class) classForCoder: (NSCoder*)aCoder
{
  if ([self class] == [GSWindowView class])
    return [super class];
  return [self class];
}

@end

//*****************************************************************************
//
//      NSWindow
//
//*****************************************************************************

@implementation NSWindow

typedef struct NSView_struct
{
  @defs(NSView)
} *NSViewPtr;


/*
 * Class variables
 */
static SEL	ccSel = @selector(_checkCursorRectangles:forEvent:);
static SEL	ctSel = @selector(_checkTrackingRectangles:forEvent:);
static IMP	ccImp;
static IMP	ctImp;
static Class	responderClass;

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSWindow class])
    {
      NSDebugLog(@"Initialize NSWindow class\n");
      [self setVersion: 2];
      ccImp = [self instanceMethodForSelector: ccSel];
      ctImp = [self instanceMethodForSelector: ctSel];
      responderClass = [NSResponder class];
    }
}

+ (void) removeFrameUsingName: (NSString *)name
{                                                       // Saving and restoring
}                                                       // the window's frame

+ (NSRect) contentRectForFrameRect: (NSRect)aRect
                         styleMask: (unsigned int)aStyle
{
  return aRect;
}

+ (NSRect) frameRectForContentRect: (NSRect)aRect
                         styleMask: (unsigned int)aStyle
{
  return aRect;
}

+ (NSRect) minFrameWidthWithTitle: (NSString *)aTitle
                        styleMask: (unsigned int)aStyle
{
  return NSZeroRect;
}

+ (NSWindowDepth) defaultDepthLimit                      // default Screen and
{                                                       // window depth
  return 8;
}

//
// Instance methods
//
- (id) init
{
  int style;

  NSDebugLog(@"NSWindow -init\n");

  style = NSTitledWindowMask | NSClosableWindowMask
	  | NSMiniaturizableWindowMask | NSResizableWindowMask;

  return [self initWithContentRect: NSZeroRect
			 styleMask: style
			   backing: NSBackingStoreBuffered
			     defer: NO];
}

- (void) dealloc
{
  if (content_view)
    {
      RELEASE([content_view superview]);	/* Release the window view */
      RELEASE(content_view);
    }

  TEST_RELEASE(_fieldEditor);
  TEST_RELEASE(background_color);
  TEST_RELEASE(represented_filename);
  TEST_RELEASE(miniaturized_title);
  TEST_RELEASE(miniaturized_image);
  TEST_RELEASE(window_title);
  TEST_RELEASE(rectsBeingDrawn);
  [self unregisterDraggedTypes];

  [super dealloc];
}

//
// Initializing and getting a new NSWindow object
//
- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
{
  NSDebugLog(@"NSWindow -initWithContentRect: \n");

  return [self initWithContentRect: contentRect
			 styleMask: aStyle
			   backing: bufferingType
			     defer: flag
			    screen: nil];
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
                    screen: (NSScreen*)aScreen
{
  NSRect r = [[NSScreen mainScreen] frame];
  NSRect cframe;

  NSDebugLog(@"NSWindow default initializer\n");
  if (!NSApp)
    NSLog(@"No application!\n");

  NSDebugLog(@"NSWindow start of init\n");
                                                    // Initialize attributes
  [self cleanInit];                               // and flags

  backing_type = bufferingType;
  style_mask = aStyle;
                                                    // Size the attributes
  frame = [NSWindow frameRectForContentRect: contentRect styleMask: aStyle];
  minimum_size = NSZeroSize;
  maximum_size = r.size;
                                                    // Next responder is the
  [self setNextResponder: NSApp];                 // application

  cursor_rects_enabled = YES;                     // Cursor management
  cursor_rects_valid = NO;

  cframe.origin = NSZeroPoint;                    // Create the content view
  cframe.size = frame.size;
  [self setContentView: AUTORELEASE([[NSView alloc] initWithFrame: cframe])];

  /* rectBeingDrawn is variable used to optimize flushing the backing store.
     It is set by NSGraphicContext during a lockFocus to tell NSWindow what
     part a view is drawing in, so NSWindow only has to flush that portion */
  rectsBeingDrawn = RETAIN([NSMutableArray arrayWithCapacity: 10]); 
  NSDebugLog(@"NSWindow end of init\n");

  return self;
}

//
// Accessing the content view
//
- (id) contentView
{
  return content_view;
}

- (void) setContentView: (NSView *)aView
{
  NSView *wv;

  // contentview can't be nil
  if (!aView)
    aView = AUTORELEASE([[NSView alloc] initWithFrame: frame]);

  // If window view has not been created, create it
  if ((!content_view) || ([content_view superview] == nil))
    {
      wv = [[GSWindowView allocWithZone: [self zone]] initWithFrame: frame];
      [wv viewWillMoveToWindow: self];
    }
  else
    wv = [content_view superview];

  if (content_view)
    [content_view removeFromSuperview];

  ASSIGN(content_view, aView);

  [content_view setFrame: [wv frame]];		    // Resize to fill window.
  [content_view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [wv addSubview: content_view];                    // Add to our window view
  NSAssert1 ([[wv subviews] count] == 1, @"window's view has %d  subviews!",
                [[wv subviews] count]);
                                                    // Make self the view's
  [content_view setNextResponder: self];             // next responder
  [content_view setNeedsDisplay: YES];		    // Make sure we redraw.
}

//
// Window graphics
//
- (NSColor *) backgroundColor
{
  return background_color;
}

- (NSString *) representedFilename
{
  return represented_filename;
}

- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGN(background_color, color);
}

- (void) setRepresentedFilename: (NSString*)aString
{
  id  old = represented_filename;

  ASSIGN(represented_filename, aString);
  if (menu_exclude == NO
    && ((represented_filename != nil && old == nil)
      || (represented_filename == nil && old != nil)))
    {
      [NSApp updateWindowsItem: self];
    }
}

- (void) setTitle: (NSString*)aString
{
  ASSIGN(window_title, aString);
  [self setMiniwindowTitle: aString];
}

- (void) setTitleWithRepresentedFilename: (NSString*)aString
{
  [self setRepresentedFilename: aString];
  [self setTitle: aString];
}

- (unsigned int) styleMask
{
  return style_mask;
}

- (NSString *) title
{
  return window_title;
}

//
// Window device attributes
//
- (NSBackingStoreType) backingType
{
  return backing_type;
}

- (NSDictionary *) deviceDescription
{
  return nil;
}

- (int) gState
{
  return gstate;
}

- (BOOL) isOneShot
{
  return is_one_shot;
}

- (void) setBackingType: (NSBackingStoreType)type
{
  backing_type = type;
}

- (void) setOneShot: (BOOL)flag
{
  is_one_shot = flag;
}

- (int) windowNumber
{
  return window_num;
}

//
// The miniwindow
//
- (NSImage *) miniwindowImage
{
  return miniaturized_image;
}

- (NSString *) miniwindowTitle
{
  return miniaturized_title;
}

- (void) setMiniwindowImage: (NSImage *)image
{
  ASSIGN(miniaturized_image, image);
}

- (void) setMiniwindowTitle: (NSString*)title
{
  BOOL isDoc = NO;

  ASSIGN(miniaturized_title, title);
  if (is_miniaturized == NO)
    title = window_title;
  if ([title isEqual: represented_filename])
    isDoc = YES;
  if (menu_exclude == NO)
    [NSApp changeWindowsItem: self
		       title: title
		    filename: isDoc];
}

//
// The field editor
//
- (void) endEditingFor: (id)anObject
{
}

- (NSText *) fieldEditor: (BOOL)createFlag forObject: (id)anObject
{
  /* ask delegate if it can provide a field editor */
  if ([delegate respondsToSelector:
            @selector(windowWillReturnFieldEditor:toObject:)])
    return [delegate windowWillReturnFieldEditor: self toObject: anObject];

  /*
   * Each window has a global text field editor, if it doesn't exist create it
   * if create flag is set
   */
  if (!_fieldEditor && createFlag)
    {
      _fieldEditor = [NSText new];
      [_fieldEditor setFieldEditor: YES];
    }

  return _fieldEditor;
}

//
// Window status and ordering
//
- (void) becomeKeyWindow
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  is_key = YES;
  [self resetCursorRects];
  [nc postNotificationName: NSWindowDidBecomeKeyNotification object: self];
}

- (void) becomeMainWindow
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  is_main = YES;
  [nc postNotificationName: NSWindowDidBecomeMainNotification object: self];
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

- (BOOL) canBecomeMainWindow
{
  return YES;
}

- (BOOL) hidesOnDeactivate
{
  return hides_on_deactivate;
}

- (BOOL) isKeyWindow
{
  return is_key;
}

- (BOOL) isMainWindow
{
  return is_main;
}

- (BOOL) isMiniaturized
{
  return is_miniaturized;
}

- (BOOL) isVisible
{
  return visible;
}

- (int) level
{
  return window_level;
}

- (void) makeKeyAndOrderFront: (id)sender
{
  [self makeKeyWindow];                           // Make self the key window
  /*
   * OPENSTEP makes a window the main window when it makes it the key window.
   * So we do the same (though the documentation doesn't mention it).
   */
  [self makeMainWindow];
  [self orderFront: sender];                      // order self to the front
}

- (void) makeKeyWindow
{
  if (![self canBecomeKeyWindow])
    return;
  [[NSApp keyWindow] resignKeyWindow];

  [self becomeKeyWindow];
}

- (void) makeMainWindow
{
  if (![self canBecomeMainWindow])
    return;
  [[NSApp mainWindow] resignMainWindow];
  [self becomeMainWindow];
}

- (void) orderBack: (id)sender
{}      // implemented in back end

- (void) orderFront: (id)sender
{}

- (void) orderFrontRegardless
{}

- (void) orderOut: (id)sender
{}

- (void) orderWindow: (NSWindowOrderingMode)place relativeTo: (int)otherWin
{
}

- (void) resignKeyWindow
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  is_key = NO;
  [self discardCursorRects];
  [nc postNotificationName: NSWindowDidResignKeyNotification object: self];
}

- (void) resignMainWindow
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  is_main = NO;
  [nc postNotificationName: NSWindowDidResignMainNotification object: self];
}

- (void) setHidesOnDeactivate: (BOOL)flag
{
  hides_on_deactivate = flag;
}

- (void) setLevel: (int)newLevel
{
  window_level = newLevel;
}

//
// Moving and resizing the window
//
- (NSPoint) cascadeTopLeftFromPoint: (NSPoint)topLeftPoint
{
  return NSZeroPoint;
}

- (void) center
{
  NSSize screenSize = [[NSScreen mainScreen] frame].size;
  NSPoint origin = frame.origin;

  // center the window within it's screen
  origin.x = (screenSize.width - frame.size.width) / 2;
  origin.y = (screenSize.height - frame.size.height) / 2;
  [self setFrameOrigin: origin];
}

- (NSRect) constrainFrameRect: (NSRect)frameRect toScreen: screen
{
  return NSZeroRect;
}

- (NSRect) frame
{
  return frame;
}

- (NSSize) minSize
{
  return minimum_size;
}

- (NSSize) maxSize
{
  return maximum_size;
}

- (void) setContentSize: (NSSize)aSize
{}

- (void) setFrame: (NSRect)frameRect display: (BOOL)flag
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  frame = frameRect;
  [nc postNotificationName: NSWindowDidResizeNotification object: self];

  if (flag)
    [self display];
}

- (void) setFrameTopLeftPoint: (NSPoint)aPoint
{
}

- (void) setFrameOrigin: (NSPoint)aPoint
{
  frame.origin = aPoint;
}

- (void) setMinSize: (NSSize)aSize
{
  minimum_size = aSize;
}

- (void) setMaxSize: (NSSize)aSize
{
  maximum_size = aSize;
}

- (NSSize) resizeIncrements
{
  return increments;
}

- (void) setResizeIncrements: (NSSize)aSize
{
  increments = aSize;
}

//
// Converting coordinates
//
- (NSPoint) convertBaseToScreen: (NSPoint)basePoint
{
  NSPoint screenPoint;

  screenPoint.x = frame.origin.x + basePoint.x;
  screenPoint.y = frame.origin.y + basePoint.y;

  return [GSCurrentContext() convertBaseToScreen: screenPoint];
}

- (NSPoint) convertScreenToBase: (NSPoint)screenPoint
{
  NSPoint basePoint;

  screenPoint = [GSCurrentContext() convertScreenToBase: screenPoint];
  basePoint.x = screenPoint.x - frame.origin.x;
  basePoint.y = screenPoint.y - frame.origin.y;

  return basePoint;
}

//
// Managing the display
//
- (void) disableFlushWindow
{
  disable_flush_window = YES;
}

- (void) display
{
  needs_display = NO;                             // inform first responder
						  // of it's status so it can
  [first_responder becomeFirstResponder];         // set the focus to itself

  [self disableFlushWindow];                      // tmp disable display

  [[content_view superview] display];             // Draw the window view

  [self enableFlushWindow];                       // Reenable displaying and
  [self flushWindowIfNeeded];                     // flush the window
}

- (void) displayIfNeeded
{
  if (needs_display)
    {
      [[content_view superview] displayIfNeeded];
      needs_display = NO;
    }
}

- (void) update
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  /*
   *	if autodisplay is enabled and window display
   */
  if (is_autodisplay && needs_display)
    {
      [self disableFlushWindow];
      [self displayIfNeeded];
      [self enableFlushWindow];
      [self flushWindowIfNeeded];
    }
  [nc postNotificationName: NSWindowDidUpdateNotification object: self];
}

- (void) flushWindowIfNeeded
{
  if (!disable_flush_window && needs_flush)
    {
      needs_flush = NO;
      [self flushWindow];
    }
}

- (void) flushWindow
{
  // implemented in back end
}

- (void) enableFlushWindow
{
  disable_flush_window = NO;
}

- (BOOL) isAutodisplay
{
  return is_autodisplay;
}

- (BOOL) isFlushWindowDisabled
{
  return disable_flush_window;
}

- (void) setAutodisplay: (BOOL)flag
{
  is_autodisplay = flag;
}

- (void) setViewsNeedDisplay: (BOOL)flag
{
  needs_display = flag;
  [NSApp setWindowsNeedUpdate: YES];
}

- (BOOL) viewsNeedDisplay
{
  return needs_display;
}

- (void) useOptimizedDrawing: (BOOL)flag
{
  optimize_drawing = flag;
}

- (BOOL) canStoreColor
{
  if (depth_limit > 1)                            // If the depth is greater
    return YES;                                 // than a single bit
  else
    return NO;
}

- (NSScreen *) deepestScreen
{
  return [NSScreen deepestScreen];
}

- (NSWindowDepth) depthLimit
{
  return depth_limit;
}

- (BOOL) hasDynamicDepthLimit
{
  return dynamic_depth_limit;
}

- (NSScreen *) screen
{
  return [NSScreen mainScreen];
}

- (void) setDepthLimit: (NSWindowDepth)limit
{
  depth_limit = limit;
}

- (void) setDynamicDepthLimit: (BOOL)flag
{
  dynamic_depth_limit = flag;
}

//
// Cursor management
//
- (BOOL) areCursorRectsEnabled
{
  return cursor_rects_enabled;
}

- (void) disableCursorRects
{
  cursor_rects_enabled = NO;
}

- (void) discardCursorRectsForView: (NSView *)theView
{
  if (((NSViewPtr)theView)->_rFlags.has_currects)
    [theView discardCursorRects];

  if (((NSViewPtr)theView)->_rFlags.has_subviews)
    {
      NSArray	*s = ((NSViewPtr)theView)->sub_views;
      unsigned	count = [s count];

      if (count)
	{
	  NSView	*subs[count];
	  unsigned	i;

	  [s getObjects: subs];
	  for (i = 0; i < count; i++)
	    [self discardCursorRectsForView: subs[i]];
	}
    }
}

- (void) discardCursorRects
{
  [self discardCursorRectsForView: [content_view superview]];
}

- (void) enableCursorRects
{
  cursor_rects_enabled = YES;
}

- (void) invalidateCursorRectsForView: (NSView *)aView
{
  cursor_rects_valid = NO;
}

- (void) resetCursorRectsForView: (NSView *)theView
{
  if (((NSViewPtr)theView)->_rFlags.has_currects)
    [theView resetCursorRects];

  if (((NSViewPtr)theView)->_rFlags.has_subviews)
    {
      NSArray	*s = ((NSViewPtr)theView)->sub_views;
      unsigned	count = [s count];

      if (count)
	{
	  NSView	*subs[count];
	  unsigned	i;

	  [s getObjects: subs];
	  for (i = 0; i < count; i++)
	    [self resetCursorRectsForView: subs[i]];
	}
    }
}

- (void) resetCursorRects
{
  [self resetCursorRectsForView: [content_view superview]];
  cursor_rects_valid = YES;
}

//
// Handling user actions and events
//
- (void) close
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  /*
   * If 'is_released_when_closed' then the window will be removed from the
   * global list of windows (causing it to be released) - so we must
   * bracket any work we do in a retain/release sequence in case that
   * removal takes place when we post the notification.
   */
  if (is_released_when_closed)
    RETAIN(self);

  [nc postNotificationName: NSWindowWillCloseNotification object: self];
  [NSApp removeWindowsItem: self];
  [self orderOut: self];

  if (is_released_when_closed)
    RELEASE(self);
}

- (void) deminiaturize: sender
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  is_miniaturized = NO;

  [self performDeminiaturize: self];
  [nc postNotificationName: NSWindowDidDeminiaturizeNotification object: self];
}

- (BOOL) isDocumentEdited
{
  return is_edited;
}

- (BOOL) isReleasedWhenClosed
{
  return is_released_when_closed;
}

- (void) miniaturize: sender
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  [nc postNotificationName: NSWindowWillMiniaturizeNotification object: self];

  [self performMiniaturize: self];
  [nc postNotificationName: NSWindowDidMiniaturizeNotification object: self];
}

- (void) performClose: sender
{
  /* self must have a close button in order to be closed */
  if (!([self styleMask] & NSClosableWindowMask))
    {
      NSBeep();
      return;
    }

  if ([delegate respondsToSelector: @selector(windowShouldClose:)])
    {
      /*
       *	if delegate responds to windowShouldClose query it to see if
       *	it's ok to close the window
       */
      if (![delegate windowShouldClose: self])
	{
	  NSBeep();
	  return;
	}
    }
  else
    {
      /*
       *	else if self responds to windowShouldClose query
       *	self to see if it's ok to close self
       */
      if ([self respondsToSelector: @selector(windowShouldClose:)])
	{
	  if (![self windowShouldClose: self])
	    {
	      NSBeep();
	      return;
	    }
	}
    }

  [self close];
}

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  if (content_view)
    return [content_view performKeyEquivalent: theEvent];
  return NO;
}

- (void) performMiniaturize: (id)sender
{
  is_miniaturized = YES;
}

- (int) resizeFlags
{
  return 0;
}

- (void) setDocumentEdited: (BOOL)flag
{
  if (is_edited != flag)
    {
      is_edited = flag;
      if (menu_exclude == NO)
        {
          [NSApp updateWindowsItem: self];
        }
    }
}

- (void) setReleasedWhenClosed: (BOOL)flag
{
  is_released_when_closed = flag;
}

//
// Aiding event handling
//
- (BOOL) acceptsMouseMovedEvents
{
  return accepts_mouse_moved;
}

- (NSEvent *) currentEvent
{
  return [NSApp currentEvent];
}

- (void) discardEventsMatchingMask: (unsigned int)mask
                       beforeEvent: (NSEvent *)lastEvent
{
  [NSApp discardEventsMatchingMask: mask beforeEvent: lastEvent];
}

- (NSResponder*) firstResponder
{
  return first_responder;
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) makeFirstResponder: (NSResponder*)aResponder
{
  if (first_responder == aResponder)
    return YES;

  if (![aResponder isKindOfClass: responderClass])
    return NO;

  if (![aResponder acceptsFirstResponder])
    return NO;

  // If there is a first responder tell it to resign.
  // Change only if it replies Y
  if ((first_responder) && (![first_responder resignFirstResponder]))
    return NO;

  first_responder = aResponder;
  [first_responder becomeFirstResponder];
  return YES;
}

/* Return mouse location in reciever's base coord system, ignores event
 * loop status */
- (NSPoint) mouseLocationOutsideOfEventStream
{
  float	x;
  float	y;

  DPSmouselocation(GSCurrentContext(), &x, &y);
  x -= frame.origin.x;
  y -= frame.origin.y;
  return NSMakePoint(x, y);
}

- (NSEvent *) nextEventMatchingMask: (unsigned int)mask
{
  return [NSApp nextEventMatchingMask: mask
			    untilDate: nil
			       inMode: NSEventTrackingRunLoopMode
			      dequeue: YES];
}

- (NSEvent *) nextEventMatchingMask: (unsigned int)mask
                          untilDate: (NSDate *)expiration
			     inMode: (NSString *)mode
			    dequeue: (BOOL)deqFlag
{
  return [NSApp nextEventMatchingMask: mask
			    untilDate: expiration
			       inMode: mode
			      dequeue: deqFlag];
}

- (void) postEvent: (NSEvent *)event atStart: (BOOL)flag
{
  [NSApp postEvent: event atStart: flag];
}

- (void) setAcceptsMouseMovedEvents: (BOOL)flag
{
  accepts_mouse_moved = flag;
}

- (void) _checkTrackingRectangles: (NSView *)theView
			 forEvent: (NSEvent *)theEvent
{
  if (((NSViewPtr)theView)->_rFlags.has_trkrects)
    {
      NSArray	*tr = ((NSViewPtr)theView)->tracking_rects;
      unsigned	count = [tr count];

      /*
       * Loop through the tracking rectangles
       */
      if (count > 0)
	{
	  GSTrackingRect	*rects[count];
	  NSPoint		loc = [theEvent locationInWindow];
	  BOOL		flipped = ((NSViewPtr)theView)->_rFlags.flipped_view;
	  unsigned		i;

	  [tr getObjects: rects];

	  for (i = 0; i < count; ++i)
	    {
	      BOOL		last;
	      BOOL		now;
	      GSTrackingRect	*r = rects[i];

	      /* Check mouse at last point */
	      last = NSMouseInRect(last_point, r->rectangle, flipped);
	      /* Check mouse at current point */
	      now = NSMouseInRect(loc, r->rectangle, flipped);

	      if ((!last) && (now))		// Mouse entered event
		{
		  if (r->ownerRespondsToMouseEntered)
		    {
		      NSEvent	*e;

		      e = [NSEvent enterExitEventWithType: NSMouseEntered
			location: loc
			modifierFlags: [theEvent modifierFlags]
			timestamp: 0
			windowNumber: [theEvent windowNumber]
			context: NULL
			eventNumber: 0
			trackingNumber: r->tag
			userData: r->user_data];
		      [r->owner mouseEntered: e];
		    }
		}

	      if ((last) && (!now))		// Mouse exited event
		{
		  if (r->ownerRespondsToMouseExited)
		    {
		      NSEvent	*e;

		      e = [NSEvent enterExitEventWithType: NSMouseExited
			location: loc
			modifierFlags: [theEvent modifierFlags]
			timestamp: 0
			windowNumber: [theEvent windowNumber]
			context: NULL
			eventNumber: 0
			trackingNumber: r->tag
			userData: r->user_data];
		      [r->owner mouseExited: e];
		    }
		}
	    }
	}
    }

  /*
   * Check tracking rectangles for the subviews
   */
  if (((NSViewPtr)theView)->_rFlags.has_subviews)
    {
      NSArray	*sb = ((NSViewPtr)theView)->sub_views;
      unsigned	count = [sb count];

      if (count > 0)
	{
	  NSView	*subs[count];
	  unsigned	i;

	  [sb getObjects: subs];
	  for (i = 0; i < count; ++i)
	    (*ctImp)(self, ctSel, subs[i], theEvent);
	}
    }
}

- (void) _checkCursorRectangles: (NSView *)theView forEvent: (NSEvent *)theEvent
{
  if (((NSViewPtr)theView)->_rFlags.has_currects)
    {
      NSArray	*tr = ((NSViewPtr)theView)->cursor_rects;
      unsigned	count = [tr count];

      // Loop through cursor rectangles
      if (count > 0)
	{
	  GSTrackingRect	*rects[count];
	  NSPoint		loc = [theEvent locationInWindow];
	  NSPoint		lastConv;
	  NSPoint		locConv;
	  BOOL		flipped = ((NSViewPtr)theView)->_rFlags.flipped_view;
	  unsigned		i;

	  /*
	   * Convert points from window to view coordinates.
	   */
	  lastConv = [theView convertPoint: last_point fromView: nil];
	  locConv = [theView convertPoint: loc fromView: nil];

	  [tr getObjects: rects];

	  for (i = 0; i < count; ++i)
	    {
	      GSTrackingRect	*r = rects[i];
	      BOOL			last;
	      BOOL			now;

	      if ([r isValid] == NO)
		continue;

	      /*
	       * Check for presence of point in rectangle.
	       */
	      last = NSMouseInRect(lastConv, r->rectangle, flipped);
	      now = NSMouseInRect(locConv, r->rectangle, flipped);

	      // Mouse entered
	      if ((!last) && (now))
		{
		  NSEvent	*e;

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
		{
		  NSEvent	*e;

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
	}
    }

  /*
   * Check cursor rectangles for the subviews
   */
  if (((NSViewPtr)theView)->_rFlags.has_subviews)
    {
      NSArray	*sb = ((NSViewPtr)theView)->sub_views;
      unsigned	count = [sb count];

      if (count > 0)
	{
	  NSView	*subs[count];
	  unsigned	i;

	  [sb getObjects: subs];
	  for (i = 0; i < count; ++i)
	    (*ccImp)(self, ccSel, subs[i], theEvent);
	}
    }
}

- (void) sendEvent: (NSEvent *)theEvent
{
  NSView	*v;
  NSEventType	type;

  if (!cursor_rects_valid)                // If the cursor rects are invalid
    {                                   // Then discard and reset
      [self discardCursorRects];
      [self resetCursorRects];
    }

  type = [theEvent type];
  switch (type)
    {
      case NSLeftMouseDown:                               // Left mouse down
	v = [content_view hitTest: [theEvent locationInWindow]];
	if (first_responder != v)
	  {
	    [self makeFirstResponder: v];
	    if ([v acceptsFirstMouse: theEvent] == YES)
	      [v mouseDown: theEvent];
	  }
	else
	  [v mouseDown: theEvent];
	last_point = [theEvent locationInWindow];
	break;

      case NSLeftMouseUp:                                 // Left mouse up
	v = first_responder;	/* Send to the view that got the mouse down. */
	[v mouseUp: theEvent];
	last_point = [theEvent locationInWindow];
	break;

      case NSRightMouseDown:                              // Right mouse down
	v = [content_view hitTest: [theEvent locationInWindow]];
	[v rightMouseDown: theEvent];
	last_point = [theEvent locationInWindow];
	break;

      case NSRightMouseUp:                                // Right mouse up
	v = [content_view hitTest: [theEvent locationInWindow]];
	[v rightMouseUp: theEvent];
	last_point = [theEvent locationInWindow];
	break;

      case NSLeftMouseDragged:				// Left mouse dragged
      case NSRightMouseDragged:				// Right mouse dragged
      case NSMouseMoved:				// Mouse moved
	switch (type)
	  {
	    case NSLeftMouseDragged:
	      v = [content_view hitTest: [theEvent locationInWindow]];
	      [v mouseDragged: theEvent];
	      break;
	    case NSRightMouseDragged:
	      v = [content_view hitTest: [theEvent locationInWindow]];
	      [v rightMouseDragged: theEvent];
	      break;
	    default:
	      if (accepts_mouse_moved)
		{
		  // If the window is set to accept mouse movements, we need to
		  // forward the mouse movement to the correct view.
		  v = [content_view hitTest: [theEvent locationInWindow]];
		  [v mouseMoved: theEvent];
		}
	      break;
	  }

	// We need to go through all of the views, and if there is any with
	// a tracking rectangle then we need to determine if we should send
	// a NSMouseEntered or NSMouseExited event.
	(*ctImp)(self, ctSel, content_view, theEvent);

	if (is_key)
	  {
	    // We need to go through all of the views, and if there is any with
	    // a cursor rectangle then we need to determine if we should send a
	    // cursor update event.
	    (*ccImp)(self, ccSel, content_view, theEvent);
	  }

	last_point = [theEvent locationInWindow];
	break;

      case NSMouseEntered:                                // Mouse entered
      case NSMouseExited:                                 // Mouse exited
	break;

      case NSKeyDown: 
	/*
	 * Save the first responder so that the key up goes to it and not a
	 * possible new first responder.
	 */
	original_responder = first_responder;
	[first_responder keyDown: theEvent];
	break;

      case NSKeyUp:                                           // Key up
	  if (original_responder)                     // send message to the
	    [original_responder keyUp: theEvent];    // object that got the
	  break;                                      // key down

      case NSFlagsChanged:                                // Flags changed
	  break;

      case NSCursorUpdate:                                // Cursor update
	{
	  GSTrackingRect *r =(GSTrackingRect *)[theEvent userData];
	  NSCursor *c = (NSCursor *)[r owner];

	  c = (NSCursor *)[r owner];
	  if ([theEvent trackingNumber])          // It's a mouse entered
	    {
	      if (c && [c isSetOnMouseEntered])
		[c set];
	    }
	  else                                    // it is a mouse exited
	    {
	      if (c && [c isSetOnMouseExited])
		[c set];
	    }
	}
	break;

      case NSPeriodic: 
	break;
    }
}

- (BOOL) tryToPerform: (SEL)anAction with: anObject
{
  return ([super tryToPerform: anAction with: anObject]);
}

- (BOOL) worksWhenModal
{
  return NO;
}

//
// Dragging
//
- (void) dragImage: (NSImage *)anImage
               at: (NSPoint)baseLocation
               offset: (NSSize)initialOffset
               event: (NSEvent *)event
               pasteboard: (NSPasteboard *)pboard
               source: sourceObject
               slideBack: (BOOL)slideFlag
{
}

- (void) registerForDraggedTypes: (NSArray*)newTypes
{
  GSRegisterDragTypes(self, newTypes);
  _rFlags.has_draginfo = 1;
}

- (void) unregisterDraggedTypes
{
  if (_rFlags.has_draginfo)
    {
      GSUnregisterDragTypes(self);
      _rFlags.has_draginfo = 0;
    }
}

//
// Services and windows menu support
//
- (BOOL) isExcludedFromWindowsMenu
{
  return menu_exclude;
}

- (void) setExcludedFromWindowsMenu: (BOOL)flag
{
  menu_exclude = flag;
}

- validRequestorForSendType: (NSString *)sendType
                 returnType: (NSString *)returnType
{
  id result = nil;

  if (delegate && [delegate respondsToSelector: _cmd])
    result = [delegate validRequestorForSendType: sendType
				      returnType: returnType];

  if (result == nil)
    result = [NSApp validRequestorForSendType: sendType
				   returnType: returnType];
  return result;
}

//
// Saving and restoring the frame
//
- (NSString *) frameAutosaveName
{
  return nil;
}

- (void) saveFrameUsingName: (NSString *)name
{
}

- (BOOL) setFrameAutosaveName: (NSString *)name
{
  return NO;
}

- (void) setFrameFromString: (NSString *)string
{
}

- (BOOL) setFrameUsingName: (NSString *)name
{
  return NO;
}

- (NSString *) stringWithSavedFrame
{
  return nil;
}

//
// Printing and postscript
//
- (NSData *) dataWithEPSInsideRect: (NSRect)rect
{
  return nil;
}

- (void) fax: (id)sender
{}

- (void) print: (id)sender
{}

//
// Assigning a delegate
//
- (id) delegate
{
  return delegate;
}

- (void) setDelegate: (id)anObject
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  if (delegate)
    [nc removeObserver: delegate name: nil object: self];
  delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([delegate respondsToSelector: @selector(window##notif_name:)]) \
    [nc addObserver: delegate \
      selector: @selector(window##notif_name:) \
      name: NSWindow##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidBecomeKey);
  SET_DELEGATE_NOTIFICATION(DidBecomeMain);
  SET_DELEGATE_NOTIFICATION(DidChangeScreen);
  SET_DELEGATE_NOTIFICATION(DidDeminiaturize);
  SET_DELEGATE_NOTIFICATION(DidExpose);
  SET_DELEGATE_NOTIFICATION(DidMiniaturize);
  SET_DELEGATE_NOTIFICATION(DidMove);
  SET_DELEGATE_NOTIFICATION(DidResignKey);
  SET_DELEGATE_NOTIFICATION(DidResignMain);
  SET_DELEGATE_NOTIFICATION(DidResize);
  SET_DELEGATE_NOTIFICATION(DidUpdate);
  SET_DELEGATE_NOTIFICATION(WillClose);
  SET_DELEGATE_NOTIFICATION(WillMiniaturize);
  SET_DELEGATE_NOTIFICATION(WillMove);
}

//
// Implemented by the delegate
//
- (BOOL) windowShouldClose: (id)sender
{
  if ([delegate respondsToSelector: @selector(windowShouldClose:)])
    return [delegate windowShouldClose: sender];
  else
    return YES;
}

- (NSSize) windowWillResize: (NSWindow *)sender toSize: (NSSize)frameSize
{
  if ([delegate respondsToSelector: @selector(windowWillResize:toSize:)])
    return [delegate windowWillResize: sender toSize: frameSize];
  else
    return frameSize;
}

- (id) windowWillReturnFieldEditor: (NSWindow *)sender toObject: client
{
  return nil;
}

- (void) windowDidBecomeKey: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidBecomeKey:)])
    return [delegate windowDidBecomeKey: aNotification];
}

- (void) windowDidBecomeMain: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidBecomeMain:)])
    return [delegate windowDidBecomeMain: aNotification];
}

- (void) windowDidChangeScreen: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidChangeScreen:)])
    return [delegate windowDidChangeScreen: aNotification];
}

- (void) windowDidDeminiaturize: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidDeminiaturize:)])
    return [delegate windowDidDeminiaturize: aNotification];
}

- (void) windowDidExpose: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidExpose:)])
    return [delegate windowDidExpose: aNotification];
}

- (void) windowDidMiniaturize: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidMiniaturize:)])
    return [delegate windowDidMiniaturize: aNotification];
}

- (void) windowDidMove: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidMove:)])
    return [delegate windowDidMove: aNotification];
}

- (void) windowDidResignKey: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidResignKey:)])
    return [delegate windowDidResignKey: aNotification];
}

- (void) windowDidResignMain: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidResignMain:)])
    return [delegate windowDidResignMain: aNotification];
}

- (void) windowDidResize: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidResize:)])
    return [delegate windowDidResize: aNotification];
}

- (void) windowDidUpdate: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowDidUpdate:)])
    return [delegate windowDidUpdate: aNotification];
}

- (void) windowWillClose: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowWillClose:)])
    return [delegate windowWillClose: aNotification];
}

- (void) windowWillMiniaturize: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowWillMiniaturize:)])
    return [delegate windowWillMiniaturize: aNotification];
}

- (void) windowWillMove: (NSNotification *)aNotification
{
  if ([delegate respondsToSelector: @selector(windowWillMove:)])
    return [delegate windowWillMove: aNotification];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [self setNextResponder: nil];

  [super encodeWithCoder: aCoder];

  NSDebugLog(@"NSWindow: start encoding\n");
  [aCoder encodeRect: frame];
  [aCoder encodeObject: content_view];
  [aCoder encodeValueOfObjCType: @encode(int) at: &window_num];
  [aCoder encodeObject: background_color];
  [aCoder encodeObject: represented_filename];
  [aCoder encodeObject: miniaturized_title];
  [aCoder encodeObject: window_title];
  [aCoder encodePoint: last_point];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &visible];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_key];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_main];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_edited];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_miniaturized];
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &style_mask];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &menu_exclude];

  // Version 2
  [aCoder encodeSize: minimum_size];
  [aCoder encodeSize: maximum_size];
  [aCoder encodeObject: miniaturized_image];
  [aCoder encodeValueOfObjCType: @encode(NSBackingStoreType) at: &backing_type];
  [aCoder encodeValueOfObjCType: @encode(int) at: &window_level];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_one_shot];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_autodisplay];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &optimize_drawing];
  [aCoder encodeValueOfObjCType: @encode(NSWindowDepth) at: &depth_limit];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &dynamic_depth_limit];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cursor_rects_enabled];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_released_when_closed];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &disable_flush_window];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &hides_on_deactivate];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &accepts_mouse_moved];

  NSDebugLog(@"NSWindow: finish encoding\n");
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  NSDebugLog(@"NSWindow: start decoding\n");
  frame = [aDecoder decodeRect];
  content_view = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &window_num];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &background_color];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &represented_filename];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &miniaturized_title];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &window_title];
  last_point = [aDecoder decodePoint];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &visible];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_key];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_main];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_edited];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_miniaturized];
  [aDecoder decodeValueOfObjCType: @encode(unsigned) at: &style_mask];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &menu_exclude];

  // Version 2
  minimum_size = [aDecoder decodeSize];
  maximum_size = [aDecoder decodeSize];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &miniaturized_image];
  [aDecoder decodeValueOfObjCType: @encode(NSBackingStoreType)
        at: &backing_type];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &window_level];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_one_shot];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_autodisplay];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &optimize_drawing];
  [aDecoder decodeValueOfObjCType: @encode(NSWindowDepth) at: &depth_limit];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &dynamic_depth_limit];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cursor_rects_enabled];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_released_when_closed];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &disable_flush_window];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &hides_on_deactivate];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &accepts_mouse_moved];

  NSDebugLog(@"NSWindow: finish decoding\n");

  return self;
}

- (NSInterfaceStyle) interfaceStyle
{
  return interface_style;
}

- (void) setInterfaceStyle: (NSInterfaceStyle)aStyle
{
  interface_style = aStyle;
}

@end

//
// GNUstep backend methods
//
@implementation NSWindow (GNUstepBackend)

+ (NSWindow*) _windowWithTag: (int)windowNumber
{
  return nil;
}

- (void) setWindowNumber: (int)windowNum
{
  window_num = windowNum;
}

//
// Mouse capture/release
//
- (void) _captureMouse: sender           {}          // Do nothing, should be
- (void) _releaseMouse: sender           {}          // implemented by back-end

- (void) performDeminiaturize: sender     {}
- (void) performHide: sender              {}
- (void) performUnhide: sender            {}

/*
 * Allow subclasses to init without the backend
 * class attempting to create an actual window
 */
- (void) initDefaults
{
  first_responder = nil;
  original_responder = nil;
  delegate = nil;
  window_num = 0;
  gstate = 0;
  background_color = RETAIN([NSColor controlColor]);
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
  is_released_when_closed = YES;
  is_miniaturized = NO;
  disable_flush_window = NO;
  menu_exclude = NO;
  hides_on_deactivate = NO;
  accepts_mouse_moved = NO;
}

- (id) cleanInit
{
  [super init];

  [self initDefaults];
  return self;
}

@end
