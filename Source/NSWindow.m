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
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
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
#include <Foundation/NSSet.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSDocument.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSWindowController.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
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
#include <AppKit/NSDragging.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSHelpManager.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/GSWraps.h>

@class	NSMenuWindow;

BOOL GSViewAcceptsDrag(NSView *v, id<NSDraggingInfo> dragInfo);

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

/*
 * Special setFrame: implementation - a minimal autoresize mechanism
 */
- (void) setFrame: (NSRect)frameRect
{
  NSSize oldSize = frame.size;
  NSView *cv = [window contentView];

  autoresize_subviews = NO;
  [super setFrame: frameRect];
  // Safety Check.
  [cv setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [cv resizeWithOldSuperviewSize: oldSize];
}

- (Class) classForCoder: (NSCoder*)aCoder
{
  if ([self class] == [GSWindowView class])
    return [super class];
  return [self class];
}

@end

/*****************************************************************************
 *
 *	NSWindow
 *
 *****************************************************************************/

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
static Class	viewClass;
static NSMutableSet	*autosaveNames;
static NSRecursiveLock	*windowsLock;
static NSMapTable* windowmaps = NULL;

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSWindow class])
    {
      NSDebugLog(@"Initialize NSWindow class\n");
      [self setVersion: 2];
      ccImp = [self instanceMethodForSelector: ccSel];
      ctImp = [self instanceMethodForSelector: ctSel];
      responderClass = [NSResponder class];
      viewClass = [NSView class];
      autosaveNames = [NSMutableSet new];
      windowsLock = [NSRecursiveLock new];
    }
}

+ (void) removeFrameUsingName: (NSString*)name
{
  if (name != nil)
    {
      NSString	*key;

      key = [NSString stringWithFormat: @"NSWindow Frame %@", name];
      [windowsLock lock];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey: key];
      [windowsLock unlock];
    }
}

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

/* default Screen and window depth */
+ (NSWindowDepth) defaultDepthLimit
{
  return 8;
}

/*
 * Instance methods
 */
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
  NSGraphicsContext	*context = GSCurrentContext();

  [[NSNotificationCenter defaultCenter] removeObserver: self];

  if (content_view)
    {
      RELEASE([content_view superview]);	/* Release the window view */
      RELEASE(content_view);
    }
  [self setFrameAutosaveName: nil];
  TEST_RELEASE(_fieldEditor);
  TEST_RELEASE(background_color);
  TEST_RELEASE(represented_filename);
  TEST_RELEASE(miniaturized_title);
  TEST_RELEASE(miniaturized_image);
  TEST_RELEASE(window_title);
  TEST_RELEASE(rectsBeingDrawn);
  TEST_RELEASE(_initial_first_responder);

  /*
   * FIXME This should not be necessary - the views should have removed
   * their drag types, so we should already have been removed.
   */
  [context _removeDragTypes: nil fromWindow: [self windowNumber]];

  if (gstate)
    DPSundefineuserobject(context, gstate);
  DPStermwindow(context, window_num);
  NSMapRemove(windowmaps, (void*)window_num);
  [super dealloc];
}

/*
 * Initializing and getting a new NSWindow object
 */
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
  NSGraphicsContext	*context = GSCurrentContext();
  NSRect		r = [[NSScreen mainScreen] frame];
  NSRect		cframe;

  NSDebugLog(@"NSWindow default initializer\n");
  if (!NSApp)
    NSLog(@"No application!\n");

  NSDebugLog(@"NSWindow start of init\n");
  if (!windowmaps)
    windowmaps = NSCreateMapTable(NSIntMapKeyCallBacks,
				 NSNonRetainedObjectMapValueCallBacks, 20);

  /* Initialize attributes and flags */
  [self cleanInit];

  backing_type = bufferingType;
  style_mask = aStyle;

  frame = [NSWindow frameRectForContentRect: contentRect styleMask: aStyle];
  minimum_size = NSMakeSize(1, 1);
  maximum_size = r.size;

  [self setNextResponder: NSApp];

  _f.cursor_rects_enabled = YES;
  _f.cursor_rects_valid = NO;

  /* Create the content view */
  cframe.origin = NSZeroPoint;
  cframe.size = frame.size;
  [self setContentView: AUTORELEASE([[NSView alloc] initWithFrame: cframe])];

  /* rectBeingDrawn is variable used to optimize flushing the backing store.
     It is set by NSGraphicsContext during a lockFocus to tell NSWindow what
     part a view is drawing in, so NSWindow only has to flush that portion */
  rectsBeingDrawn = RETAIN([NSMutableArray arrayWithCapacity: 10]); 

  DPSwindow(context, NSMinX(contentRect), NSMinY(contentRect),
	    NSWidth(contentRect), NSHeight(contentRect), 
	    bufferingType, &window_num);
  DPSstylewindow(context, aStyle, window_num);
  DPSsetwindowlevel(context, [self level], window_num);

  // Set window in new gstate
  DPSgsave(context);
  DPSwindowdevice(context, window_num);
  DPSgstate(context);
  gstate = GSWDefineAsUserObj(context);
  DPSgrestore(context);

  NSMapInsert (windowmaps, (void*)window_num, self);

  if (_f.menu_exclude == NO)
    {
      BOOL	isDoc = [window_title isEqual: represented_filename];

      [NSApp addWindowsItem: self
		      title: window_title
		   filename: isDoc];
    }

  NSDebugLog(@"NSWindow end of init\n");
  return self;
}

/*
 * Accessing the content view
 */
- (id) contentView
{
  return content_view;
}

- (void) setContentView: (NSView *)aView
{
  NSView *wv;

  if (!aView)
    aView = AUTORELEASE([[NSView alloc] initWithFrame: frame]);

  /* If window view has not been created, create it */
  if ((!content_view) || ([content_view superview] == nil))
    {
      NSRect	rect = frame;

      rect.origin = NSZeroPoint;
      wv = [[GSWindowView allocWithZone: [self zone]] initWithFrame: rect];
      [wv viewWillMoveToWindow: self];
    }
  else
    wv = [content_view superview];

  if (content_view)
    [content_view removeFromSuperview];

  ASSIGN(content_view, aView);

  [content_view setFrame: [wv frame]];		    // Resize to fill window.
  [content_view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [wv addSubview: content_view];		    // Add to our window view
  NSAssert1 ([[wv subviews] count] == 1, @"window's view has %d	 subviews!",
		[[wv subviews] count]);

  [content_view setNextResponder: self];
}

/*
 * Window graphics
 */
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
  ASSIGN(represented_filename, aString);
}

- (void) setTitle: (NSString*)aString
{
  if ([window_title isEqual: aString] == NO)
    {
      ASSIGN(window_title, aString);
      [self setMiniwindowTitle: aString];
      DPStitlewindow(GSCurrentContext(), [aString cString], window_num);
      if (_f.menu_exclude == NO)
	{
	  [NSApp changeWindowsItem: self
			     title: aString
			  filename: NO];
	}
    }
}

- (void) setTitleWithRepresentedFilename: (NSString*)aString
{
  [self setRepresentedFilename: aString];
  aString = [NSString stringWithFormat:
    @"%@  --  %@", [aString lastPathComponent],
    [aString stringByDeletingLastPathComponent]];
  if ([window_title isEqual: aString] == NO)
    {
      ASSIGN(window_title, aString);
      [self setMiniwindowTitle: aString];
      DPStitlewindow(GSCurrentContext(), [aString cString], window_num);
      if (_f.menu_exclude == NO)
	{
	  [NSApp changeWindowsItem: self
			     title: aString
			  filename: YES];
	}
    }
}

- (unsigned int) styleMask
{
  return style_mask;
}

- (NSString *) title
{
  return window_title;
}

/*
 * Window device attributes
 */
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
  return _f.is_one_shot;
}

- (void) setBackingType: (NSBackingStoreType)type
{
  backing_type = type;
}

- (void) setOneShot: (BOOL)flag
{
  _f.is_one_shot = flag;
}

- (int) windowNumber
{
  return window_num;
}

/*
 * The miniwindow
 */
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
  ASSIGN(miniaturized_title, title);
}

/*
 * The field editor
 */
- (void) endEditingFor: (id)anObject
{
  NSText *t = [self fieldEditor: NO 
		    forObject: anObject];

  if (t && (first_responder == t))
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: NSTextDidEndEditingNotification 
	object: t];
      [t setText: @""];
      [t setDelegate: nil];
      [t removeFromSuperview];
      first_responder = self;
      [first_responder becomeFirstResponder];
    }
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

/*
 * Window controller
 */
- (void)setWindowController:(NSWindowController *)windowController
{
  ASSIGN(_windowController, windowController);
}
   
- (id) windowController
{ 
  return _windowController;
}

/*
 * Window status and ordering
 */
- (void) becomeKeyWindow
{
  if (_f.is_key == NO)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      _f.is_key = YES;
      DPSsetinputfocus(GSCurrentContext(), [self windowNumber]);
      [self resetCursorRects];
      [nc postNotificationName: NSWindowDidBecomeKeyNotification object: self];
    }
}

- (void) becomeMainWindow
{
  if (_f.is_main == NO)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      _f.is_main = YES;
      [nc postNotificationName: NSWindowDidBecomeMainNotification object: self];
    }
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
  return _f.hides_on_deactivate;
}

- (BOOL) isKeyWindow
{
  return _f.is_key;
}

- (BOOL) isMainWindow
{
  return _f.is_main;
}

- (BOOL) isMiniaturized
{
  return _f.is_miniaturized;
}

- (BOOL) isVisible
{
  return _f.visible;
}

- (int) level
{
  return window_level;
}

- (void) makeKeyAndOrderFront: (id)sender
{
  [self makeKeyWindow];
  /*
   * OPENSTEP makes a window the main window when it makes it the key window.
   * So we do the same (though the documentation doesn't mention it).
   */
  [self makeMainWindow];
  [self orderFront: sender];
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
{
  [self orderWindow: NSWindowBelow relativeTo: 0];
}

- (void) orderFront: (id)sender
{
  if ([NSApp isActive] == YES)
    {
      [self orderWindow: NSWindowAbove relativeTo: 0];
    }
}

- (void) orderFrontRegardless
{
  [self orderWindow: NSWindowAbove relativeTo: 0];
}

- (void) orderOut: (id)sender
{
  [self orderWindow: NSWindowOut relativeTo: 0];
}

- (void) orderWindow: (NSWindowOrderingMode)place relativeTo: (int)otherWin
{
  if (place == NSWindowOut)
    {
      NSArray	*windowList = [NSWindow _windowList];
      unsigned	pos = [windowList indexOfObjectIdenticalTo: self];
      unsigned	c = [windowList count];
      unsigned	i;
      NSWindow	*w;

      if (_rFlags.needs_display == YES)
	{
	  /*
	   * Don't keep trying to update the window while it is ordered out
	   */
	  [[NSRunLoop currentRunLoop]
             cancelPerformSelector: @selector(_handleWindowNeedsDisplay:)
                            target: self
                          argument: nil];
	}
      if ([self isKeyWindow])
	{
	  [self resignKeyWindow];
	  for (i = pos + 1; i != pos; i++)
	    {
	      if (i == c)
		{
		  i = 0;
		}
	      w = [windowList objectAtIndex: i];
	      if ([w isVisible] && [w canBecomeKeyWindow])
		{
		  [w makeKeyWindow];
		  break;
		}
	    }
	  /*
	   * if we didn't find a possible key window - use tha app icon or,
	   * failing that, use the menu window.
	   */
	  if (i == pos)
	    {
	      w = [NSApp iconWindow];
	      if (w != nil && [w isVisible] == YES)
		{
		  [GSCurrentContext() DPSsetinputfocus: [w windowNumber]];
		}
	      else
		{
		  w = [[NSApp mainMenu] window];
		  [GSCurrentContext() DPSsetinputfocus: [w windowNumber]];
		}
	    }
	}
      if ([self isMainWindow])
	{
	  NSWindow	*w = [NSApp keyWindow];

	  [self resignMainWindow];
	  if (w != nil && [w canBecomeMainWindow])
	    {
	      [w makeKeyWindow];
	    }
	  else
	    {
	      for (i = pos + 1; i != pos; i++)
		{
		  if (i == c)
		    {
		      i = 0;
		    }
		  w = [windowList objectAtIndex: i];
		  if ([w isVisible] && [w canBecomeMainWindow])
		    {
		      [w makeMainWindow];
		      break;
		    }
		}
	    }
	}
    }
  else
    {
      if (_rFlags.needs_display == NO)
	{
	  /*
	   * Once we are ordered back in, we will want to update the window
	   * whenever there is anything to do.
	   */
	  [[NSRunLoop currentRunLoop]
		 performSelector: @selector(_handleWindowNeedsDisplay:)
			  target: self
			argument: nil
			   order: 600000 
			   modes: [NSArray arrayWithObjects:
					   NSDefaultRunLoopMode,
					   NSModalPanelRunLoopMode,
					   NSEventTrackingRunLoopMode, nil]];
	}
    }
  DPSorderwindow(GSCurrentContext(), place, otherWin, [self windowNumber]);
}

- (void) resignKeyWindow
{
  if (_f.is_key == YES)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      _f.is_key = NO;
      [self discardCursorRects];
      [nc postNotificationName: NSWindowDidResignKeyNotification object: self];
    }
}

- (void) resignMainWindow
{
  if (_f.is_main == YES)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      _f.is_main = NO;
      [nc postNotificationName: NSWindowDidResignMainNotification object: self];
    }
}

- (void) setHidesOnDeactivate: (BOOL)flag
{
  if (flag != _f.hides_on_deactivate)
    {
      _f.hides_on_deactivate = flag;
    }
}

- (void) setLevel: (int)newLevel
{
  window_level = newLevel;
}

/*
 * Moving and resizing the window
 */
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
{
  NSRect	r = frame;

  r.size = aSize;
  [self setFrame: r display: YES];
}

- (void) setFrame: (NSRect)frameRect display: (BOOL)flag
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  if (maximum_size.width > 0 && frameRect.size.width > maximum_size.width)
    {
      frameRect.size.width = maximum_size.width;
    }
  if (maximum_size.height > 0 && frameRect.size.height > maximum_size.height)
    {
      frameRect.size.height = maximum_size.height;
    }
  if (frameRect.size.width < minimum_size.width)
    {
      frameRect.size.width = minimum_size.width;
    }
  if (frameRect.size.height < minimum_size.height)
    {
      frameRect.size.height = minimum_size.height;
    }

  if (NSEqualSizes(frameRect.size, frame.size) == NO)
    {
      if ([delegate respondsToSelector: @selector(windowWillResize:toSize:)])
	{
	  frameRect.size = [delegate windowWillResize: self
					       toSize: frameRect.size];
	}
    }

  if (NSEqualPoints(frame.origin, frameRect.origin) == NO)
    [nc postNotificationName: NSWindowWillMoveNotification object: self];

  /*
   * Now we can tell the graphics context to do the actual resizing.
   * We will recieve an event to tell us when the resize is done.
   */
  DPSplacewindow(GSCurrentContext(), frameRect.origin.x, frameRect.origin.y,
    frameRect.size.width, frameRect.size.height, [self windowNumber]);

  if (flag)
    [self display];
}

- (void) setFrameOrigin: (NSPoint)aPoint
{
  NSRect	r = frame;

  r.origin = aPoint;
  [self setFrame: r display: YES];
}

- (void) setFrameTopLeftPoint: (NSPoint)aPoint
{
  NSRect	r = frame;

  r.origin = aPoint;
  r.origin.y -= frame.size.height;
  [self setFrame: r display: YES];
}

- (void) setMinSize: (NSSize)aSize
{
  if (aSize.width < 1)
    aSize.width = 1;
  if (aSize.height < 1)
    aSize.height = 1;
  minimum_size = aSize;
  DPSsetminsize(GSCurrentContext(), aSize.width, aSize.height, window_num);
}

- (void) setMaxSize: (NSSize)aSize
{
  /*
   * Documented maximum size for macOS-X - do we need this restriction?
   */
  if (aSize.width > 10000)
    aSize.width = 10000;
  if (aSize.height > 10000)
    aSize.height = 10000;
  maximum_size = aSize;
  DPSsetmaxsize(GSCurrentContext(), aSize.width, aSize.height, window_num);
}

- (NSSize) resizeIncrements
{
  return increments;
}

- (void) setResizeIncrements: (NSSize)aSize
{
  increments = aSize;
  DPSsetresizeincrements(GSCurrentContext(), aSize.width, aSize.height, 
			 window_num);
}

/*
 * Converting coordinates
 */
- (NSPoint) convertBaseToScreen: (NSPoint)basePoint
{
  NSView	*wv = [content_view superview];
  NSPoint	screenPoint;

  screenPoint.x = frame.origin.x + basePoint.x;
  screenPoint.y = frame.origin.y + basePoint.y;

  /*
   * Window coordiates are relative to the windowview - but the windowview
   * may be offset from the windows position on the screen to allow for a
   * title-bar and border, so we allow for that here.
   */
  if (wv != nil)
    {
      NSPoint	offset = [wv bounds].origin;

      screenPoint.x += offset.x;
      screenPoint.y += offset.y;
    }
  return screenPoint;
}

- (NSPoint) convertScreenToBase: (NSPoint)screenPoint
{
  NSView	*wv = [content_view superview];
  NSPoint basePoint;

  basePoint.x = screenPoint.x - frame.origin.x;
  basePoint.y = screenPoint.y - frame.origin.y;

  /*
   * Window coordiates are relative to the windowview - but the windowview
   * may be offset from the windows position on the screen to allow for a
   * title-bar and border, so we allow for that here.
   */
  if (wv != nil)
    {
      NSPoint	offset = [wv bounds].origin;

      basePoint.x -= offset.x;
      basePoint.y -= offset.y;
    }
  return basePoint;
}

/*
 * Managing the display
 */
- (void) disableFlushWindow
{
  disable_flush_window++;
}

- (void) display
{
  _rFlags.needs_display = NO;
  if ((!first_responder) || (first_responder == self))
    if (_initial_first_responder)
      [self makeFirstResponder: _initial_first_responder];
  /*
   * inform first responder of it's status so it can set the focus to itself
   */
  [first_responder becomeFirstResponder];

  [self disableFlushWindow];
  [[content_view superview] display];
  [self enableFlushWindow];
  [self flushWindowIfNeeded];
}

- (void) displayIfNeeded
{
  if (_rFlags.needs_display)
    {
      [[content_view superview] displayIfNeeded];
      _rFlags.needs_display = NO;
    }
}

- (void) update
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  /*
   *	if autodisplay is enabled and window display
   */
  if (_f.is_autodisplay && _rFlags.needs_display)
    {
      [self disableFlushWindow];
      [self displayIfNeeded];
      [self enableFlushWindow];
      [self flushWindowIfNeeded];
    }
  [GSCurrentContext() flush];
  [nc postNotificationName: NSWindowDidUpdateNotification object: self];
}

- (void) flushWindowIfNeeded
{
  if (disable_flush_window == 0 && _f.needs_flush == YES)
    {
      _f.needs_flush = NO;
      [self flushWindow];
    }
}

- (void) flushWindow
{
  int i;
  NSGraphicsContext* context = GSCurrentContext();

  // do nothing if backing is not buffered
  if (backing_type == NSBackingStoreNonretained)
    {
      [context flush];
      return;
    }

  if (disable_flush_window)		// if flushWindow is called
    {					// while flush is disabled
      _f.needs_flush = YES;		// mark self as needing a
      return;				// flush, then return
    }

  /* Check for special case of flushing while we are lock focused.
     For instance, when we are highlighting a button. */
  if (NSIsEmptyRect(rectNeedingFlush))
    {
      if ([rectsBeingDrawn count] == 0)
	{
	  _f.needs_flush = NO;
	  return;
	}
    }

  /*
   * Accumulate the rectangles from all nested focus locks.
   */
  i = [rectsBeingDrawn count];
  while (i-- > 0)
    {
      rectNeedingFlush = NSUnionRect(rectNeedingFlush, 
       [[rectsBeingDrawn objectAtIndex: i] rectValue]);
    }
  
  DPSflushwindowrect(context, 
		     NSMinX(rectNeedingFlush), NSMinY(rectNeedingFlush),
		     NSWidth(rectNeedingFlush), NSHeight(rectNeedingFlush),
		     window_num);
  _f.needs_flush = NO;
  rectNeedingFlush = NSZeroRect;
}

- (void) enableFlushWindow
{
  if (disable_flush_window > 0)
    {
      disable_flush_window--;
    }
}

- (BOOL) isAutodisplay
{
  return _f.is_autodisplay;
}

- (BOOL) isFlushWindowDisabled
{
  return disable_flush_window == 0 ? NO : YES;
}

- (void) setAutodisplay: (BOOL)flag
{
  _f.is_autodisplay = flag;
}

- (void) _handleWindowNeedsDisplay: (id)bogus
{
  [self displayIfNeeded];
}

- (void) setViewsNeedDisplay: (BOOL)flag
{
  _rFlags.needs_display = flag;
  if (flag)
    {
      [NSApp setWindowsNeedUpdate: YES];
      [[NSRunLoop currentRunLoop]
             performSelector: @selector(_handleWindowNeedsDisplay:)
                      target: self
                    argument: nil
                       order: 600000 /*NSDisplayWindowRunLoopOrdering in OS*/
                       modes: [NSArray arrayWithObjects:
                                       NSDefaultRunLoopMode,
                                       NSModalPanelRunLoopMode,
                                       NSEventTrackingRunLoopMode, nil]];
    }
  else
    {
      [[NSRunLoop currentRunLoop]
             cancelPerformSelector: @selector(_handleWindowNeedsDisplay:)
                            target: self
                          argument: nil];
    }
}

- (BOOL) viewsNeedDisplay
{
  return _rFlags.needs_display;
}

- (void) useOptimizedDrawing: (BOOL)flag
{
  _f.optimize_drawing = flag;
}

- (BOOL) canStoreColor
{
  if (depth_limit > 1)
    return YES;
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
  return _f.dynamic_depth_limit;
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
  _f.dynamic_depth_limit = flag;
}

/*
 * Cursor management
 */
- (BOOL) areCursorRectsEnabled
{
  return _f.cursor_rects_enabled;
}

- (void) disableCursorRects
{
  _f.cursor_rects_enabled = NO;
}

static void
discardCursorRectsForView(NSView *theView)
{
  if (theView != nil)
    {
      if (((NSViewPtr)theView)->_rFlags.has_currects)
	{
	  [theView discardCursorRects];
	}

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
		{
		  discardCursorRectsForView(subs[i]);
		}
	    }
	}
    }
}

- (void) discardCursorRects
{
  discardCursorRectsForView([content_view superview]);
}

- (void) enableCursorRects
{
  _f.cursor_rects_enabled = YES;
}

- (void) invalidateCursorRectsForView: (NSView *)aView
{
  if (((NSViewPtr)aView)->_rFlags.valid_rects)
    {
      [((NSViewPtr)aView)->cursor_rects
	makeObjectsPerformSelector: @selector(invalidate)];
      ((NSViewPtr)aView)->_rFlags.valid_rects = 0;
      _f.cursor_rects_valid = NO;
    }
}

static void
resetCursorRectsForView(NSView *theView)
{
  if (theView != nil)
    {
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
		{
		  resetCursorRectsForView(subs[i]);
		}
	    }
	}
    }
}

- (void) resetCursorRects
{
  [self discardCursorRects];
  resetCursorRectsForView([content_view superview]);
  _f.cursor_rects_valid = YES;
}

/*
 * Handling user actions and events
 */
- (void) close
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  /*
   * If '_f.is_released_when_closed' then the window will be removed from the
   * global list of windows (causing it to be released) - so we must
   * bracket any work we do in a retain/release sequence in case that
   * removal takes place when we post the notification.
   */
  if (_f.is_released_when_closed)
    RETAIN(self);

  [nc postNotificationName: NSWindowWillCloseNotification object: self];
  [NSApp removeWindowsItem: self];
  [self orderOut: self];

  if (_f.is_released_when_closed)
    RELEASE(self);
}

- (void) deminiaturize: sender
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  _f.is_miniaturized = NO;

  [self performDeminiaturize: self];
  [nc postNotificationName: NSWindowDidDeminiaturizeNotification object: self];
}

- (BOOL) isDocumentEdited
{
  return _f.is_edited;
}

- (BOOL) isReleasedWhenClosed
{
  return _f.is_released_when_closed;
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
  DPSminiwindow(GSCurrentContext(), window_num);
  _f.is_miniaturized = YES;
}

- (int) resizeFlags
{
  return 0;
}

- (void) setDocumentEdited: (BOOL)flag
{
  if (_f.is_edited != flag)
    {
      _f.is_edited = flag;
      if (_f.menu_exclude == NO)
	{
	  [NSApp updateWindowsItem: self];
	}
    }
}

- (void) setReleasedWhenClosed: (BOOL)flag
{
  _f.is_released_when_closed = flag;
}

/*
 * Aiding event handling
 */
- (BOOL) acceptsMouseMovedEvents
{
  return _f.accepts_mouse_moved;
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

  /*
   * If there is a first responder tell it to resign.
   * Change only if it replies Y
   */
  if ((first_responder) && (![first_responder resignFirstResponder]))
    return NO;

// FIXME
//  [first_responder resignFirstResponder];
  first_responder = aResponder;
  [first_responder becomeFirstResponder];
  return YES;
}

- (void) setInitialFirstResponder: (NSView *)aView
{ 
  if ([aView isKindOfClass: viewClass])
    {
      if (_initial_first_responder)
	[_initial_first_responder autorelease];
      _initial_first_responder = [aView retain];
    }
}

- (NSView *) initialFirstResponder
{ 
  return _initial_first_responder;
}

- (void) keyDown: (NSEvent *)theEvent
{ 
  unsigned int key_code = [theEvent keyCode];

  // If this is a TAB or TAB+SHIFT event, move to the next key view
  if (key_code == 0x09) 
    {
      if ([theEvent modifierFlags] & NSShiftKeyMask)
	[self selectPreviousKeyView: self];
      else
	[self selectNextKeyView: self];
      return;
    }    
  
  // If this is an ESC event, abort modal loop 
  if (key_code == 0x1b)
    {
      NSApplication *app = [NSApplication sharedApplication];
      if ([app modalWindow] == self)
	{
	  // NB: The following *never* returns.
	  [app abortModal];
	}
      return;
    }

  // Try to process the event as a key equivalent 
  // without Command having being pressed
  {
    NSEvent *new_event 
      =  [NSEvent keyEventWithType: [theEvent type] 
		  location: NSZeroPoint 
		  modifierFlags: ([theEvent modifierFlags] | NSCommandKeyMask)
		  timestamp: [theEvent timestamp] 
		  windowNumber: [theEvent windowNumber]
		  context: [theEvent context] 
		  characters: [theEvent characters]
		  charactersIgnoringModifiers: [theEvent 
						 charactersIgnoringModifiers]
		  isARepeat: [theEvent isARepeat]
		  keyCode: key_code];
    if ([self performKeyEquivalent: new_event])
      return;
  }
  
  // Otherwise, pass the event up
  [super keyDown: theEvent];
}

/* Return mouse location in reciever's base coord system, ignores event
 * loop status */
- (NSPoint) mouseLocationOutsideOfEventStream
{
  float x;
  float y;

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
  _f.accepts_mouse_moved = flag;
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
	  unsigned		i;

	  [tr getObjects: rects];

	  for (i = 0; i < count; ++i)
	    {
	      BOOL		last;
	      BOOL		now;
	      GSTrackingRect	*r = rects[i];

	      /* Check mouse at last point */
	      last = NSMouseInRect(last_point, r->rectangle, NO);
	      /* Check mouse at current point */
	      now = NSMouseInRect(loc, r->rectangle, NO);

	      if ((!last) && (now))		// Mouse entered event
		{
		  if (r->flags.checked == NO)
		    {
		      if ([r->owner respondsToSelector:
			@selector(mouseEntered:)])
			r->flags.ownerRespondsToMouseEntered = YES;
		      if ([r->owner respondsToSelector:
			@selector(mouseExited:)])
			r->flags.ownerRespondsToMouseExited = YES;
		      r->flags.checked = YES;
		    }
		  if (r->flags.ownerRespondsToMouseEntered)
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
		  if (r->flags.checked == NO)
		    {
		      if ([r->owner respondsToSelector:
			@selector(mouseEntered:)])
			r->flags.ownerRespondsToMouseEntered = YES;
		      if ([r->owner respondsToSelector:
			@selector(mouseExited:)])
			r->flags.ownerRespondsToMouseExited = YES;
		      r->flags.checked = YES;
		    }
		  if (r->flags.ownerRespondsToMouseExited)
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
  if (((NSViewPtr)theView)->_rFlags.valid_rects)
    {
      NSArray	*tr = ((NSViewPtr)theView)->cursor_rects;
      unsigned	count = [tr count];

      // Loop through cursor rectangles
      if (count > 0)
	{
	  GSTrackingRect	*rects[count];
	  NSPoint		loc = [theEvent locationInWindow];
	  unsigned		i;

	  [tr getObjects: rects];

	  for (i = 0; i < count; ++i)
	    {
	      GSTrackingRect	*r = rects[i];
	      BOOL		last;
	      BOOL		now;

	      if ([r isValid] == NO)
		continue;

	      /*
	       * Check for presence of point in rectangle.
	       */
	      last = NSMouseInRect(last_point, r->rectangle, NO);
	      now = NSMouseInRect(loc, r->rectangle, NO);

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

- (void) _processResizeEvent
{
  NSGraphicsContext* context = GSCurrentContext();

  if (gstate)
    {
      DPSgsave(context);
      DPSsetgstate(context, gstate);
    }
  DPSupdatewindow(context, window_num);
  if (gstate)
    DPSgrestore(context);

  [self update];
}


- (void) sendEvent: (NSEvent *)theEvent
{
  NSView	*v;
  NSEventType	type;

  if (!_f.cursor_rects_valid)
    {
      [self resetCursorRects];
    }

  type = [theEvent type];
  switch (type)
    {
      case NSLeftMouseDown:				  // Left mouse down
	v = [content_view hitTest: [theEvent locationInWindow]];
	if (first_responder != v)
	  {
	    [self makeFirstResponder: v];
	    if (_f.is_key || [v acceptsFirstMouse: theEvent] == YES)
	      {
		if([NSHelpManager isContextHelpModeActive])
		  {
		    [v helpRequested: theEvent];
		  }
		else
		  {
		    [v mouseDown: theEvent];
		  }
	      }
	  }
	else
	  {
	    if([NSHelpManager isContextHelpModeActive])
	      {
		[v helpRequested: theEvent];
	      }
	    else
	      {
		[v mouseDown: theEvent];
	      }
	  }
	last_point = [theEvent locationInWindow];
	break;

      case NSLeftMouseUp:				  // Left mouse up
	v = first_responder;	/* Send to the view that got the mouse down. */
	[v mouseUp: theEvent];
	last_point = [theEvent locationInWindow];
	break;

      case NSRightMouseDown:				  // Right mouse down
	v = [content_view hitTest: [theEvent locationInWindow]];
	[v rightMouseDown: theEvent];
	last_point = [theEvent locationInWindow];
	break;

      case NSRightMouseUp:				  // Right mouse up
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
	      if (_f.accepts_mouse_moved)
		{
		  /*
		   * If the window is set to accept mouse movements, we need to
		   * forward the mouse movement to the correct view.
		   */
		  v = [content_view hitTest: [theEvent locationInWindow]];
		  [v mouseMoved: theEvent];
		}
	      break;
	  }

	/*
	 * We need to go through all of the views, and if there is any with
	 * a tracking rectangle then we need to determine if we should send
	 * a NSMouseEntered or NSMouseExited event.
	 */
	(*ctImp)(self, ctSel, content_view, theEvent);

	if (_f.is_key)
	  {
	    /*
	     * We need to go through all of the views, and if there is any with
	     * a cursor rectangle then we need to determine if we should send a
	     * cursor update event.
	     */
	    (*ccImp)(self, ccSel, content_view, theEvent);
	  }

	last_point = [theEvent locationInWindow];
	break;

      case NSMouseEntered:				  // Mouse entered
      case NSMouseExited:				  // Mouse exited
	break;

      case NSKeyDown: 
	/*
	 * Save the first responder so that the key up goes to it and not a
	 * possible new first responder.
	 */
	original_responder = first_responder;
	[first_responder keyDown: theEvent];
	break;

      case NSKeyUp:					      // Key up
	  /*
	   * send message to the object that got the key down
	   */
	  if (original_responder)
	    [original_responder keyUp: theEvent];
	  break;

      case NSFlagsChanged:				  // Flags changed
	  break;

      case NSCursorUpdate:				  // Cursor update
	{
	  GSTrackingRect	*r =(GSTrackingRect *)[theEvent userData];
	  NSCursor		*c = (NSCursor *)[r owner];

	  if ([theEvent trackingNumber])	  // It's a mouse entered
	    {
	      [c mouseEntered: theEvent];
	    }
	  else					  // it is a mouse exited
	    {
	      [c mouseExited: theEvent];
	    }
	}
	break;

      case NSAppKitDefined:
	{
	  id                    dragInfo;
	  int                   action;
	  NSEvent               *e;
	  GSAppKitSubtype	sub = [theEvent subtype];
	  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

	  switch (sub)
	    {
	      case GSAppKitWindowMoved:
		frame.origin.x = (float)[theEvent data1];
		frame.origin.y = (float)[theEvent data2];
		if (autosave_name != nil)
		  {
		    [self saveFrameUsingName: autosave_name];
		  }
		[nc postNotificationName: NSWindowDidMoveNotification
				  object: self];
		break;

	      case GSAppKitWindowResized:
		frame.size.width = (float)[theEvent data1];
		frame.size.height = (float)[theEvent data2];
		if (autosave_name != nil)
		  {
		    [self saveFrameUsingName: autosave_name];
		  }
		if (content_view)
		  {
		    NSView	*wv = [content_view superview];			
		    NSRect	rect = frame;

		    rect.origin = NSZeroPoint;
		    [wv setFrame: rect];
		    [wv setNeedsDisplay: YES];
		  }
		[self _processResizeEvent];
		[nc postNotificationName: NSWindowDidResizeNotification
				  object: self];
		break;
	      case GSAppKitWindowClose:
		[self performClose: NSApp];
		break;

#define     GSPerformDragSelector(view, sel, info, action)		     \
		if (view == content_view && delegate)			     \
                  action = (int)[delegate performSelector: sel withObject:   \
					    info];			     \
		else							     \
		  action = (int)[view performSelector: sel withObject: info]
#define     GSPerformVoidDragSelector(view, sel, info)			\
		if (view == content_view && delegate)			\
                  [delegate performSelector: sel withObject: info];	\
		else							\
		  [view performSelector: sel withObject: info]

	    case GSAppKitDraggingEnter:
	    case GSAppKitDraggingUpdate:
	      v = [content_view hitTest: [theEvent locationInWindow]];
	      if (!v)
		v = content_view;
	      dragInfo = [GSCurrentContext() _dragInfo];
	      if (_lastDragView && _lastDragView != v && _f.accepts_drag)
		{
		  GSPerformVoidDragSelector(_lastDragView, 
				      @selector(draggingExited:), dragInfo);
		}
	      _f.accepts_drag = GSViewAcceptsDrag(v, dragInfo);
	      if (_lastDragView != v && _f.accepts_drag)
		{
		  GSPerformDragSelector(v, @selector(draggingEntered:), 
				      dragInfo, action);
		}
	      else
		{
		  GSPerformDragSelector(v, @selector(draggingUpdated:), 
				      dragInfo, action);
		}
	      e = [NSEvent otherEventWithType: NSAppKitDefined
			   location: [theEvent locationInWindow]
			   modifierFlags: 0
			   timestamp: 0
			   windowNumber: [self windowNumber]
			   context: GSCurrentContext()
			   subtype: GSAppKitDraggingStatus
			   data1: [theEvent data1]
			   data2: action];
	      [GSCurrentContext() _postExternalEvent: e];
	      _lastDragView = v;
	      break;

	    case GSAppKitDraggingStatus:
	      NSLog(@"Internal: dropped GSAppKitDraggingStatus event\n");
	      break;

	    case GSAppKitDraggingExit:
	      dragInfo = [GSCurrentContext() _dragInfo];
	      if (_lastDragView && _f.accepts_drag)
		{
		  GSPerformDragSelector(_lastDragView, 
				      @selector(draggingExited:), dragInfo,
				      action);
		}
	      break;

	    case GSAppKitDraggingDrop:
	      if (_lastDragView && _f.accepts_drag)
		{
	          dragInfo = [GSCurrentContext() _dragInfo];
		  GSPerformDragSelector(_lastDragView, 
					@selector(prepareForDragOperation:), 
					dragInfo, action);
		  if (action)
		    {
		      GSPerformDragSelector(_lastDragView, 
					  @selector(performDragOperation:),  
					  dragInfo, action);
		    }
		  if (action)
		    {
		      GSPerformVoidDragSelector(_lastDragView, 
					  @selector(concludeDragOperation:),  
					  dragInfo);
		    }
		}
	      e = [NSEvent otherEventWithType: NSAppKitDefined
			   location: [theEvent locationInWindow]
			   modifierFlags: 0
			   timestamp: 0
			   windowNumber: [self windowNumber]
			   context: GSCurrentContext()
			   subtype: GSAppKitDraggingFinished
			   data1: [theEvent data1]
			   data2: 0];
	      [GSCurrentContext() _postExternalEvent: e];
	      break;

	    case GSAppKitDraggingFinished:
	      NSLog(@"Internal: dropped GSAppKitDraggingFinished event\n");
	      break;

	    default:
	      break;
	    }
	}
	break;

      case NSPeriodic: 
      case NSSystemDefined:
      case NSApplicationDefined:
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

- (void) selectKeyViewFollowingView: (NSView *)aView
{
  NSView *theView = nil;
  
  if ([aView isKindOfClass: viewClass])
    theView = [aView nextValidKeyView];
  if (theView)
    {
      [self makeFirstResponder: theView];
      if ([theView respondsToSelector:@selector(selectText:)])
	{
	  _selection_direction =  NSSelectingNext;
	  [(id)theView selectText: self];
	  _selection_direction =  NSDirectSelection;
      	}
    }
}

- (void) selectKeyViewPrecedingView: (NSView *)aView
{
  NSView *theView = nil;

  if ([aView isKindOfClass: viewClass])
    theView = [aView previousValidKeyView];
  if (theView)
    {
      [self makeFirstResponder: theView];
      if ([theView respondsToSelector:@selector(selectText:)])
	{
	  _selection_direction =  NSSelectingPrevious;
	  [(id)theView selectText: self];
	  _selection_direction =  NSDirectSelection;
	}
    }
}

- (void) selectNextKeyView: (id)sender
{
  NSView *theView = nil;
  
  if ([first_responder isKindOfClass: viewClass])    
    theView = [first_responder nextValidKeyView];
  
  if ((theView == nil) && (_initial_first_responder))
    {
      if ([_initial_first_responder acceptsFirstResponder])
	theView = _initial_first_responder;
      else 
	theView = [_initial_first_responder nextValidKeyView];
    }

  if (theView)
    {
      [self makeFirstResponder: theView];
      if ([theView respondsToSelector:@selector(selectText:)])
	{
	  _selection_direction =  NSSelectingNext;
	  [(id)theView selectText: self];
	  _selection_direction =  NSDirectSelection;
	}
    }
}

- (void) selectPreviousKeyView: (id)sender
{
  NSView *theView = nil;
  
  if ([first_responder isKindOfClass: viewClass])    
    theView = [first_responder previousValidKeyView];
  
  if ((theView == nil) && (_initial_first_responder))
    {
      if ([_initial_first_responder acceptsFirstResponder])
	theView = _initial_first_responder;
      else 
	theView = [_initial_first_responder previousValidKeyView];
    }

  if (theView)
    {
      [self makeFirstResponder: theView];
      if ([theView respondsToSelector:@selector(selectText:)])
	{
	  _selection_direction =  NSSelectingPrevious;
	  [(id)theView selectText: self];
	  _selection_direction =  NSDirectSelection;
	}
    }
}

// This is invoked by selectText: of some views (eg matrixes),
// to know whether they have received it from the window, and
// if so, in which direction is the selection moving (so that they know 
// if they should select the last or the first editable cell).
- (NSSelectionDirection)keyViewSelectionDirection
{ 
  return _selection_direction;
}

/*
 * Dragging
 */
- (void) dragImage: (NSImage*)anImage
	        at: (NSPoint)baseLocation
	    offset: (NSSize)initialOffset
	     event: (NSEvent*)event
        pasteboard: (NSPasteboard*)pboard
	    source: (id)sourceObject
	 slideBack: (BOOL)slideFlag
{
  /*
   * Ensure we have a content view and it's associated window view.
   */
  if (content_view == nil)
    [self setContentView: nil];
  [[content_view superview] dragImage: anImage
				   at: baseLocation
			       offset: initialOffset
			        event: event
			   pasteboard: pboard
			       source: sourceObject
			    slideBack: slideFlag];
}

- (void) registerForDraggedTypes: (NSArray*)newTypes
{
  /*
   * Ensure we have a content view and it's associated window view.
   */
  if (content_view == nil)
    [self setContentView: nil];
  [[content_view superview] registerForDraggedTypes: newTypes];
}

- (void) unregisterDraggedTypes
{
  [[content_view superview] unregisterDraggedTypes];
}

/*
 * Services and windows menu support
 */
- (BOOL) isExcludedFromWindowsMenu
{
  return _f.menu_exclude;
}

- (void) setExcludedFromWindowsMenu: (BOOL)flag
{
  if (_f.menu_exclude != flag)
    {
      _f.menu_exclude = flag;
      if (_f.menu_exclude == NO)
	{
	  [NSApp addWindowsItem: self
			  title: window_title
		       filename: [window_title isEqual: represented_filename]];
	}
      else
	{
	  [NSApp removeWindowsItem: self];
	}
    }
}

- (id) validRequestorForSendType: (NSString *)sendType
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

/*
 * Saving and restoring the frame
 */
- (NSString *) frameAutosaveName
{
  return autosave_name;
}

- (void) saveFrameUsingName: (NSString *)name
{
  NSUserDefaults	*defs;
  NSString		*key;
  id			obj;

  [windowsLock lock];
  defs = [NSUserDefaults standardUserDefaults];
  obj = [self stringWithSavedFrame];
  if ([self isKindOfClass: [NSMenuWindow class]]) 
    {
      id	dict;

      key = @"NSMenuLocations";
      dict = [defs objectForKey: key];
      if (dict == nil)
	{
	  dict = [NSMutableDictionary dictionaryWithCapacity: 1];
	} 
      else if ([dict isKindOfClass: [NSDictionary class]] == NO)
	{
	  NSLog(@"NSMenuLocations default is not a dictionary - overwriting");
	  dict = [NSMutableDictionary dictionaryWithCapacity: 1];
	}
      else
	{
	  dict = AUTORELEASE([dict mutableCopy]);
	}
      [dict setObject: obj forKey: name];
      obj = dict;
    }
  else
    {
      key = [NSString stringWithFormat: @"NSWindow Frame %@", name];
    }
  [defs setObject: obj forKey: key];
  [windowsLock unlock];
}

- (BOOL) setFrameAutosaveName: (NSString *)name
{
  if ([name isEqual: autosave_name])
    {
      return YES;		/* That's our name already.	*/
    }

  [windowsLock lock];
  if ([autosaveNames member: name] != nil)
    {
      [windowsLock unlock];
      return NO;		/* Name in use elsewhere.	*/
    }
  if (autosave_name != nil)
    {
      [autosaveNames removeObject: autosave_name];
      autosave_name = nil;
    }
  if (name != nil && [name isEqual: @""] == NO)
    {
      name = [name copy];
      [autosaveNames addObject: name];
      autosave_name = name;
      [name release];
    }
  else
    {
      NSUserDefaults	*defs;
      NSString		*key;

      /*
       * Autosave name cleared - remove from defaults database.
       */
      defs = [NSUserDefaults standardUserDefaults];
      if ([self isKindOfClass: [NSMenuWindow class]]) 
	{
	  id	dict;

	  key = @"NSMenuLocations";
	  dict = [defs objectForKey: key];
	  if (dict == nil)
	    {
	      dict = [NSMutableDictionary dictionaryWithCapacity: 1];
	    } 
	  else if ([dict isKindOfClass: [NSDictionary class]] == NO)
	    {
	      NSLog(@"NSMenuLocations is not a dictionary - overwriting");
	      dict = [NSMutableDictionary dictionaryWithCapacity: 1];
	    }
	  else
	    {
	      dict = AUTORELEASE([dict mutableCopy]);
	    }
	  [dict removeObjectForKey: name];
	  [defs setObject: dict forKey: key];
	}
      else
	{
	  key = [NSString stringWithFormat: @"NSWindow Frame %@", name];
	  [defs removeObjectForKey: key];
	}
    }
  [windowsLock unlock];
  return YES;
}

- (void) setFrameFromString: (NSString *)string
{
  NSScanner	*scanner = [NSScanner scannerWithString: string];
  NSRect	nRect;
  NSRect	sRect;
  NSRect	fRect;
  int		value;

  /*
   * Scan in the window frame (flipped coordinate system).
   */
  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad window frame format - x-coord missing");
      return;
    }
  fRect.origin.x = value;

  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad window frame format - y-coord missing");
      return;
    }
  fRect.origin.y = value;

  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad window frame format - width missing");
      return;
    }
  fRect.size.width = value;

  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad window frame format - height missing");
      return;
    }
  fRect.size.height = value;

  /*
   * Scan in the frame for the area the window was placed in in screen.
   */
  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad screen frame format - x-coord missing");
      return;
    }
  sRect.origin.x = value;

  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad screen frame format - y-coord missing");
      return;
    }
  sRect.origin.y = value;

  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad screen frame format - width missing");
      return;
    }
  sRect.size.width = value;

  if ([scanner scanInt: &value] == NO)
    {
      NSLog(@"Bad screen frame format - height missing");
      return;
    }
  sRect.size.height = value;

  /*
   * FIXME - the screen rectangle should give the area of the screen in which
   * the window could be placed (ie a rectangle excluding the dock), but
   * there is no API for that yet - so we just use the screen at present.
   */
  nRect = [[NSScreen mainScreen] frame];

  /*
   * FIXME - if the stored screen area is not the same as that currently
   * available, we should probably adjust the window frame (position) in
   * some way to try to amke layout sensible.
   */
  if (NSEqualRects(nRect, sRect) == NO)
    {
    }

  /*
   * Convert frame from flipped to normal coordinates.
   */
  fRect.origin.y -= fRect.size.height;

  /*
   * Check and set frame.
   */
  if (maximum_size.width > 0 && fRect.size.width > maximum_size.width)
    {
      fRect.size.width = maximum_size.width;
    }
  if (maximum_size.height > 0 && fRect.size.height > maximum_size.height)
    {
      fRect.size.height = maximum_size.height;
    }
  if (fRect.size.width < minimum_size.width)
    {
      fRect.size.width = minimum_size.width;
    }
  if (fRect.size.height < minimum_size.height)
    {
      fRect.size.height = minimum_size.height;
    }
  [self setFrame: fRect display: YES];
}

- (BOOL) setFrameUsingName: (NSString *)name
{
  NSUserDefaults	*defs;
  id			obj;

  [windowsLock lock];
  defs = [NSUserDefaults standardUserDefaults];
  if ([self isKindOfClass: [NSMenuWindow class]] == YES) 
    {
      obj = [defs objectForKey: @"NSMenuLocations"];
      if (obj != nil)
	{
	  if ([obj isKindOfClass: [NSDictionary class]] == YES)
	    {
	      obj = [obj objectForKey: name];
	    }
	  else
	    {
	      NSLog(@"NSMenuLocations default is not a dictionary");
	      obj = nil;
	    }
	}
    }
  else
    {
      NSString	*key;

      key = [NSString stringWithFormat: @"NSWindow Frame %@", name];
      obj = [defs objectForKey: key];
    }
  [windowsLock unlock];
  if (obj == nil)
    return NO;
  [self setFrameFromString: obj];
  return YES;
}

- (NSString *) stringWithSavedFrame
{
  NSRect	fRect;
  NSRect	sRect;

  fRect = frame;
  fRect.origin.y += fRect.size.height;	/* Make flipped	*/
  /*
   * FIXME - the screen rectangle should give the area of the screen in which
   * the window could be placed (ie a rectangle excluding the dock), but
   * there is no API for that yet - so we just use the screen at present.
   */
  sRect = [[NSScreen mainScreen] frame];

  return [NSString stringWithFormat: @"%d %d %d %d %d %d % d %d ",
    (int)fRect.origin.x, (int)fRect.origin.y,
    (int)fRect.size.width, (int)fRect.size.height,
    (int)sRect.origin.x, (int)sRect.origin.y,
    (int)sRect.size.width, (int)sRect.size.height];
}

/*
 * Printing and postscript
 */
- (NSData *) dataWithEPSInsideRect: (NSRect)rect
{
  return nil;
}

- (void) fax: (id)sender
{}

- (void) print: (id)sender
{}

/*
 * Assigning a delegate
 */
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

/*
 * Implemented by the delegate
 */
- (BOOL) windowShouldClose: (id)sender
{
  if ([delegate respondsToSelector: @selector(windowShouldClose:)])
    {
      BOOL ourReturn; 

      ourReturn = [delegate windowShouldClose: sender];

      if (ourReturn)
	{
	  ourReturn = [[_windowController document] shouldCloseWindowController: _windowController];
	}

      return ourReturn;
    }
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

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL	flag;
  id	nxt = RETAIN([self nextResponder]);

  [self setNextResponder: nil];

  [super encodeWithCoder: aCoder];

  NSDebugLog(@"NSWindow: start encoding\n");
  [aCoder encodeRect: [[self contentView] frame]];
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &style_mask];
  [aCoder encodeValueOfObjCType: @encode(NSBackingStoreType) at: &backing_type];

  [aCoder encodeObject: content_view];
  [aCoder encodeObject: background_color];
  [aCoder encodeObject: represented_filename];
  [aCoder encodeObject: miniaturized_title];
  [aCoder encodeObject: window_title];

  [aCoder encodeSize: minimum_size];
  [aCoder encodeSize: maximum_size];

  [aCoder encodeValueOfObjCType: @encode(int) at: &window_level];

  flag = _f.menu_exclude;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.visible;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.is_key;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.is_main;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];

  flag = _f.is_one_shot;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.is_autodisplay;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.optimize_drawing;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.dynamic_depth_limit;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.cursor_rects_enabled;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.is_released_when_closed;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.hides_on_deactivate;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _f.accepts_mouse_moved;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];

  [aCoder encodeObject: miniaturized_image];
  [aCoder encodeConditionalObject: _initial_first_responder];

  NSDebugLog(@"NSWindow: finish encoding\n");

  [self setNextResponder: nxt];
  RELEASE(nxt);
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  id	oldself = self;
  BOOL	flag;

  if ((self = [super initWithCoder: aDecoder]) == oldself)
    {
      NSSize			aSize;
      NSRect			aRect;
      unsigned			aStyle;
      NSBackingStoreType	aBacking;
      int			anInt;
      id			obj;

      NSDebugLog(@"NSWindow: start decoding\n");
      aRect = [aDecoder decodeRect];
      [aDecoder decodeValueOfObjCType: @encode(unsigned)
				   at: &aStyle];
      [aDecoder decodeValueOfObjCType: @encode(NSBackingStoreType)
				   at: &aBacking];

      self = [self initWithContentRect: aRect
			     styleMask: aStyle
			       backing: aBacking
				 defer: NO
				screen: nil];

      obj = [aDecoder decodeObject];
      [self setContentView: obj];
      obj = [aDecoder decodeObject];
      [self setBackgroundColor: obj];
      obj = [aDecoder decodeObject];
      [self setRepresentedFilename: obj];
      obj = [aDecoder decodeObject];
      [self setMiniwindowTitle: obj];
      obj = [aDecoder decodeObject];
      [self setTitle: obj];

      aSize = [aDecoder decodeSize];
      [self setMinSize: aSize];
      aSize = [aDecoder decodeSize];
      [self setMaxSize: aSize];

      [aDecoder decodeValueOfObjCType: @encode(int)
				   at: &anInt];
      [self setLevel: anInt];

      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setExcludedFromWindowsMenu: flag];

      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      if (flag)
        [self orderFrontRegardless];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      if (flag)
        [self makeKeyWindow];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      if (flag)
        [self makeMainWindow];
  
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setOneShot: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setAutodisplay: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self useOptimizedDrawing: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setDynamicDepthLimit: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      if (flag)
	[self enableCursorRects];
      else
	[self disableCursorRects];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setReleasedWhenClosed: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setHidesOnDeactivate: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setAcceptsMouseMovedEvents: flag];

      [aDecoder decodeValueOfObjCType: @encode(id)
				   at: &miniaturized_image];
      [aDecoder decodeValueOfObjCType: @encode(id)
				   at: &_initial_first_responder];

      NSDebugLog(@"NSWindow: finish decoding\n");
    }

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

/*
 * GNUstep backend methods
 */
@implementation NSWindow (GNUstepPrivate)

+ (NSWindow *) _windowWithNumber: (int)windowNumber
{
  return NSMapGet(windowmaps, (void *)windowNumber);
}

+ (NSArray *) _windowList
{
  return NSAllMapTableValues(windowmaps);
}

/*
 * Mouse capture/release
 */
- (void) _captureMouse: sender
{
  DPScapturemouse(GSCurrentContext(), window_num);
}

- (void) _releaseMouse: sender
{
  DPSreleasemouse(GSCurrentContext());
}

- (void) setContentViewSize: (NSSize)aSize
{
  NSRect r;

  r.origin = NSZeroPoint;
  r.size = aSize;
  if (content_view)
    [content_view setFrame: r];
}

- (void) _setVisible: (BOOL)flag
{
  _f.visible = flag;
}

- (void) performDeminiaturize: sender	  {}
- (void) performHide: sender		  {}
- (void) performUnhide: sender		  {}

/*
 * Allow subclasses to init without the backend
 * class attempting to create an actual window
 */
- (void) initDefaults
{
  first_responder = self;
  original_responder = nil;
  _initial_first_responder = nil;
  _selection_direction = NSDirectSelection;
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

  depth_limit = 8;
  disable_flush_window = 0;

  _f.is_one_shot = NO;
  _f.is_autodisplay = YES;
  _f.optimize_drawing = YES;
  _f.dynamic_depth_limit = YES;
  _f.cursor_rects_enabled = NO;
  _f.visible = NO;
  _f.is_key = NO;
  _f.is_main = NO;
  _f.is_edited = NO;
  _f.is_released_when_closed = YES;
  _f.is_miniaturized = NO;
  _f.menu_exclude = NO;
  _f.hides_on_deactivate = NO;
  _f.accepts_mouse_moved = NO;
}

- (id) cleanInit
{
  [super init];

  [self initDefaults];
  return self;
}

@end

BOOL GSViewAcceptsDrag(NSView *v, id<NSDraggingInfo> dragInfo)
{
  NSPasteboard *pb = [dragInfo draggingPasteboard];
  if ([pb availableTypeFromArray: GSGetDragTypes(v)])
    return YES;
  return NO;
}

