/*
   NSApplication.m

   The one and only application class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
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
#include <stdio.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSUserDefaults.h>

#ifndef LIB_FOUNDATION_LIBRARY
# include <Foundation/NSConnection.h>
#endif

#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSDocumentController.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSWorkspace.h>
#include <AppKit/GSServicesManager.h>
#include <AppKit/IMLoading.h>
#include <AppKit/DPSOperators.h>

/*
 * Types
 */
struct _NSModalSession {
  int	    runState;
  NSWindow  *window;
  NSModalSession    previous;
};

@interface NSIconWindow : NSWindow
@end

@interface NSAppIconView : NSView
- (void) setImage: (NSImage *)anImage;
@end

/*
 * Class variables
 */
static BOOL gnustep_gui_app_is_in_dealloc;
static NSIconWindow *app_icon_window;
static NSEvent *null_event;
static NSString *NSAbortModalException = @"NSAbortModalException";

NSApplication	*NSApp = nil;

@implementation	NSIconWindow

- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (BOOL) canBecomeKeyWindow
{
  return NO;
}

- (void) initDefaults
{
  [super initDefaults];
  menu_exclude = YES;           // Don't show in windows menu.
  window_level = NSDockWindowLevel;
  is_released_when_closed = NO;
}

@end

@implementation NSAppIconView

// Class variables
static NSCell* dragCell = nil;
static NSCell* tileCell = nil;

+ (void) initialize
{
  NSImage	*defImage = [NSImage imageNamed: @"GNUstep"];
  NSImage	*tileImage = [NSImage imageNamed: @"common_Tile"];

  dragCell = [[NSCell alloc] initImageCell: defImage];
  [dragCell setBordered: NO];
  tileCell = [[NSCell alloc] initImageCell: tileImage];
  [tileCell setBordered: NO];
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

- (void) drawRect: (NSRect)rect
{                                                
  [tileCell drawWithFrame: rect inView: self];
  [dragCell drawWithFrame: rect inView: self];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  if ([theEvent clickCount] >= 2)
    {
      NSWindow *kw = [NSApp keyWindow];

      if (!kw)
	kw = [self window];

      [NSApp unhide: self];
      if (kw)
	{
	  NSGraphicsContext *context = GSCurrentContext();
          [kw orderFrontRegardless];
	  [context flush];
	  DPSsetinputfocus(context, [kw windowNumber]);
	}
    }
  else
    {
      NSPoint	lastLocation;
      NSPoint	location;
      unsigned	eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
				| NSPeriodicMask | NSRightMouseUpMask;
      NSDate	*theDistantFuture = [NSDate distantFuture];
      NSApplication *theApp = [NSApplication sharedApplication];
      BOOL	done = NO;

      lastLocation = [theEvent locationInWindow];
      [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.02];

      while (!done)
	{
	  theEvent = [theApp nextEventMatchingMask: eventMask
					 untilDate: theDistantFuture
					    inMode: NSEventTrackingRunLoopMode
					   dequeue: YES];
	
	  switch ([theEvent type])
	    {
	      case NSRightMouseUp:
	      case NSLeftMouseUp:
	      /* right mouse up or left mouse up means we're done */
		done = YES;
		break;
	      case NSPeriodic:
		location = [window mouseLocationOutsideOfEventStream];
		if (NSEqualPoints(location, lastLocation) == NO)
		  {
		    NSPoint	origin = [window frame].origin;

		    origin.x += (location.x - lastLocation.x);
		    origin.y += (location.y - lastLocation.y);
		    [window setFrameOrigin: origin];
		  }
		break;

	      default:
		break;
	    }
	}
      [NSEvent stopPeriodicEvents];
    }
}                                                        

- (void) setImage: (NSImage *)anImage
{
  [self lockFocus];
  [tileCell drawWithFrame: NSMakeRect(0,0,64,64) inView: self];
  [dragCell setImage: anImage];
  [dragCell drawWithFrame: NSMakeRect(8,8,48,48) inView: self];
  [window flushWindow];
  [self unlockFocus];
}

@end

@implementation NSApplication

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSApplication class])
    {
      /*
       * Dummy functions to fool linker into linking files that contain
       * only catagories - static libraries seem to have problems here.
       */
      extern void	GSStringDrawingDummyFunction();

      GSStringDrawingDummyFunction();

      NSDebugLog(@"Initialize NSApplication class\n");
      [self setVersion: 1];

      /*
       * So the application knows it's within dealloc and
       * can prevent -release loops
       */
      gnustep_gui_app_is_in_dealloc = NO;
    }
}

+ (NSApplication *) sharedApplication
{
  /* If the global application does not yet exist then create it */
  if (!NSApp)
    {
      /*
       * Don't combine the following two statements into one to avoid
       * problems with some classes' initialization code that tries
       * to get the shared application.
       */
      NSApp = [self alloc];
      [NSApp init];
    }
  return NSApp;
}

/*
 * Instance methods
 */
- _appIconInit
{
  NSAppIconView	*iv;
  NSGraphicsContext	*context = GSCurrentContext();

  if (app_icon == nil)
    app_icon = [[NSImage imageNamed: @"GNUstep"] retain];

  app_icon_window = [[NSIconWindow alloc] initWithContentRect: 
					    NSMakeRect(0,0,64,64)
				styleMask: NSBorderlessWindowMask
				  backing: NSBackingStoreRetained
				    defer: NO
				   screen: nil];

  iv = [[NSAppIconView alloc] initWithFrame: NSMakeRect(0,0,64,64)];
  [app_icon_window setContentView: iv];
  [iv setImage: app_icon];

  [app_icon_window orderFrontRegardless];
  DPSsetinputfocus(context, [app_icon_window windowNumber]);
  return self;
}

- (id) init
{
  if (NSApp != nil && NSApp != self)
    {
      RELEASE(self);
      return [NSApplication sharedApplication];
    }

  self = [super init];
  NSApp = self;
  if (NSApp == nil)
    {
      NSLog(@"Cannot allocate the application instance!\n");
      return nil;
    }

  NSDebugLog(@"Begin of NSApplication -init\n");

  [self _appIconInit];
  unhide_on_activation = YES;
  app_is_hidden = YES;
  app_is_active = NO;
  listener = [GSServicesManager newWithApplication: self];

  main_menu = nil;
  windows_need_update = YES;

  current_event = [NSEvent new];		// no current event
  null_event = [NSEvent new];			// create dummy event

  /* We are the end of responder chain	*/
  [self setNextResponder: nil];
  return self;
}

- (void) finishLaunching
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSBundle		*mainBundle = [NSBundle mainBundle];
  NSDictionary		*infoDict = [mainBundle infoDictionary];
  NSString		*mainModelFile;
  NSString		*appIconFile;
  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];
  NSString		*filePath;
  NSDictionary		*userInfo;

  mainModelFile = [infoDict objectForKey: @"NSMainNibFile"];
  if (mainModelFile && ![mainModelFile isEqual: @""])
    {
      if (![GMModel loadIMFile: mainModelFile
			 owner: [NSApplication sharedApplication]])
	NSLog (@"Cannot load the main model file '%@", mainModelFile);
    }

  appIconFile = [infoDict objectForKey: @"NSIcon"];
  if (appIconFile && ![appIconFile isEqual: @""])
    {
      NSImage	*image = [NSImage imageNamed: appIconFile];

      if (image != nil)
	{
	  [self setApplicationIconImage: image];
	}
    }

  /* post notification that launch will finish */
  [nc postNotificationName: NSApplicationWillFinishLaunchingNotification
      object: self];

  /* Register our listener to incoming services requests etc. */
  [listener registerAsServiceProvider];

  [self activateIgnoringOtherApps: YES];

#ifndef STRICT_OPENSTEP
  /* Register self as observer to every window closing. */
  [nc addObserver: self selector: @selector(_windowWillClose:)
      name: NSWindowWillCloseNotification object: nil];
#endif

  /* finish the launching post notification that launching has finished */
  [nc postNotificationName: NSApplicationDidFinishLaunchingNotification
		    object: self];

  /*
   *	Now check to see if we were launched with arguments asking to
   *	open a file.  We permit some variations on the default name.
   */
  if ((filePath = [defs stringForKey: @"GSFilePath"]) != nil)
    {
      if ([delegate respondsToSelector: @selector(application:openFile:)])
	{
	  [delegate application: self openFile: filePath];
	}
      else
	{
	  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:filePath display:YES];
	}
    }
  else if ((filePath = [defs stringForKey: @"GSTempPath"]) != nil)
    {
      if ([delegate respondsToSelector: @selector(application:openTempFile:)])
	{
	  [delegate application: self openTempFile: filePath];
	}
      else
	{
	  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:filePath display:YES];
	}
    }

  userInfo = [NSDictionary dictionaryWithObject:
    [[NSProcessInfo processInfo] processName] forKey: @"NSApplicationName"];
  [[[NSWorkspace sharedWorkspace] notificationCenter]
    postNotificationName: NSWorkspaceDidLaunchApplicationNotification
    object: self
    userInfo: userInfo];
}

- (void) dealloc
{
  NSDebugLog(@"Freeing NSApplication\n");

  /* Let ourselves know we are within dealloc */
  gnustep_gui_app_is_in_dealloc = YES;

  RELEASE(listener);
  RELEASE(null_event);
  RELEASE(current_event);

  /* We may need to tidy up nested modal session structures. */
  while (session != 0)
    {
      NSModalSession tmp = session;

      session = tmp->previous;
      NSZoneFree(NSDefaultMallocZone(), tmp);
    }

  [super dealloc];
}

/*
 * Changing the active application
 */
- (void) activateIgnoringOtherApps: (BOOL)flag
{
  if (app_is_active == NO)
    {
      NSGraphicsContext *context = GSCurrentContext();
      NSWindow *kw = [self keyWindow];
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

     /*
       * Menus should observe this notification in order to make themselves
       * visible when the application is active.
       */
      [nc postNotificationName: NSApplicationWillBecomeActiveNotification
			object: self];

      app_is_active = YES;

      if (unhide_on_activation)
	[self unhide: nil];

      if (kw == nil || [kw isVisible] == NO)
	{
	  kw = app_icon_window;
	}
      NSDebugLog(@"activateIgnoringOtherApps start.");
      [context flush];
      DPSsetinputfocus(context, [kw windowNumber]);
      NSDebugLog(@"activateIgnoringOtherApps end.");

      [nc postNotificationName: NSApplicationDidBecomeActiveNotification
			object: self];
    }
}

- (void) deactivate
{
  if (app_is_active == YES)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      /*
       * Menus should observe this notification in order to make themselves
       * invisible when the application is not active.
       */
      [nc postNotificationName: NSApplicationWillResignActiveNotification
			object: self];

      app_is_active = NO;

      [nc postNotificationName: NSApplicationDidResignActiveNotification
			object: self];
    }
}

- (BOOL) isActive
{
  return app_is_active;
}

/*
 * Running the main event loop
 */
- (void) run
{
  NSEvent *e;
  Class arpClass = [NSAutoreleasePool class];	 /* Cache the class */
  NSAutoreleasePool* pool;

  NSDebugLog(@"NSApplication -run\n");

  /*
   *  Set this flag here in case the application is actually terminated
   *  inside -finishLaunching.
   */
  app_should_quit = NO;

  [self finishLaunching];

  app_is_running = YES;

  [listener updateServicesMenu];
  [main_menu update];
  while (app_should_quit == NO)
    {
      pool = [arpClass new];

      e = [self nextEventMatchingMask: NSAnyEventMask
			    untilDate: [NSDate distantFuture]
			       inMode: NSDefaultRunLoopMode
			      dequeue: YES];
      if (e)
	[self sendEvent: e];

      // update (en/disable) the services menu's items
      [listener updateServicesMenu];
      [main_menu update];

      // send an update message to all visible windows
      if (windows_need_update)
	[self updateWindows];

      RELEASE(pool);
    }

  [GSCurrentContext() destroyContext];
  NSDebugLog(@"NSApplication end of run loop\n");
}

- (BOOL) isRunning
{
  return app_is_running;
}

/*
 * Running modal event loops
 */
- (void) abortModal
{
  if (session == 0)
    [NSException raise: NSAbortModalException
		format: @"abortModal called while not in a modal session"];

  [NSException raise: NSAbortModalException format: @"abortModal"];
}

- (NSModalSession) beginModalSessionForWindow: (NSWindow*)theWindow
{
  NSModalSession theSession;

  theSession = (NSModalSession)NSZoneMalloc(NSDefaultMallocZone(),
		    sizeof(struct _NSModalSession));
  theSession->runState = NSRunContinuesResponse;
  theSession->window = theWindow;
  theSession->previous = session;
  session = theSession;

  return theSession;
}

- (void) endModalSession: (NSModalSession)theSession
{
  NSModalSession tmp = session;

  if (theSession == 0)
    [NSException raise: NSInvalidArgumentException
		format: @"null pointer passed to endModalSession: "];

  /* Remove this session from linked list of sessions. */
  while (tmp && tmp != theSession)
    tmp = tmp->previous;

  if (tmp == 0)
    [NSException raise: NSInvalidArgumentException
		format: @"unknown session passed to endModalSession: "];

  while (session != theSession)
    {
      tmp = session;
      session = tmp->previous;
      NSZoneFree(NSDefaultMallocZone(), tmp);
    }

  session = session->previous;
  NSZoneFree(NSDefaultMallocZone(), session);
}

- (int) runModalForWindow: (NSWindow*)theWindow
{
  static NSModalSession theSession;
  static int code;

  /*
   * The NSWindow documentation says runModalForWindow centers panels.
   */
  if ([theWindow isKindOfClass: [NSPanel class]])
    [theWindow center];

  if ([self isActive])
    [theWindow makeKeyWindow];
  [theWindow orderFrontRegardless];

  theSession = NULL;
  code = NSRunContinuesResponse;

  NS_DURING
    {
      theSession = [self beginModalSessionForWindow: theWindow];
      while (code == NSRunContinuesResponse)
	{
	  code = [self runModalSession: theSession];
	}

      [self endModalSession: theSession];
    }
  NS_HANDLER
    {
      if (theSession)
	{
	  NSWindow *win_to_close = theSession->window;
	  
	  [self endModalSession: theSession];
	  [win_to_close close];
	}
      if ([[localException name] isEqual: NSAbortModalException] == NO)
	[localException raise];
      
      code = NSRunAbortedResponse;
    }
    NS_ENDHANDLER

  return code;
}

- (int) runModalSession: (NSModalSession)theSession
{
  NSAutoreleasePool	*pool;
  NSGraphicsContext	*ctxt;
  BOOL		found = NO;
  NSEvent	*event;
  NSDate	*limit;

  if (theSession != session)
    [NSException raise: NSInvalidArgumentException
		format: @"runModalSession: with wrong session"];

  pool = [NSAutoreleasePool new];
  [theSession->window makeKeyAndOrderFront: self];

  ctxt = GSCurrentContext();

  /*
   * Set a limit date in the distant future so we wait until we get an
   * event.  We discard events that are not for this window.  When we
   * find one for this window, we push it back at the start of the queue.
   */
  limit = [NSDate distantFuture];
  do
    {
      event = DPSGetEvent(ctxt, NSAnyEventMask, limit, NSDefaultRunLoopMode);
      if (event != nil)
	{
	  NSWindow	*eventWindow = [event window];

	  if (eventWindow == theSession->window || [eventWindow worksWhenModal])
	    {
	      DPSPostEvent(ctxt, event, YES);
	      found = YES;
	    }
	}
    }
  while (found == NO && theSession->runState == NSRunContinuesResponse);

  RELEASE(pool);
  /*
   *	Deal with the events in the queue.
   */
  while (found == YES && theSession->runState == NSRunContinuesResponse)
    {
      pool = [NSAutoreleasePool new];

      event = DPSGetEvent(ctxt, NSAnyEventMask, limit, NSDefaultRunLoopMode);
      if (event != nil)
	{
	  NSWindow	*eventWindow = [event window];

	  if (eventWindow == theSession->window || [eventWindow worksWhenModal])
	    {
	      ASSIGN(current_event, event);
	    }
	  else
	    {
	      found = NO;
	    }
	}
      else
	{
	  found = NO;
	}

      if (found == YES)
	{
	  [self sendEvent: current_event];

	  /*
	   *	Check to see if the window has gone away - if so, end session.
	   */
#if 0
	  if ([[self windows] indexOfObjectIdenticalTo: session->window] ==
	    NSNotFound || [session->window isVisible] == NO)
#else
	  if ([[self windows] indexOfObjectIdenticalTo: session->window] ==
	    NSNotFound)
#endif
	    [self stopModal];
	  if (windows_need_update)
	    [self updateWindows];
	}

      RELEASE(pool);
    }

  NSAssert(session == theSession, @"Session was changed while running");

  return theSession->runState;
}

- (NSWindow *) modalWindow
{
  if (session) 
    return (session->window);
  else
    return nil;
}

- (void) stop: (id)sender
{
  if (session)
    [self stopModal];
  else
    app_is_running = NO;
}

- (void) stopModal
{
  [self stopModalWithCode: NSRunStoppedResponse];
}

- (void) stopModalWithCode: (int)returnCode
{
  if (session == 0)
    [NSException raise: NSInvalidArgumentException
		format: @"stopModalWithCode: when not in a modal session"];
  else
    if (returnCode == NSRunContinuesResponse)
      [NSException raise: NSInvalidArgumentException
		  format: @"stopModalWithCode: with NSRunContinuesResponse"];

  session->runState = returnCode;
}

/*
 * Getting, removing, and posting events
 */
- (void) sendEvent: (NSEvent *)theEvent
{
  if (theEvent == null_event)
    {
      NSDebugLog(@"Not sending the Null Event\n");
      return;
    }

  switch ([theEvent type])
    {
      case NSPeriodic:	/* NSApplication traps the periodic events	*/
	break;

      case NSKeyDown:
	{
	  NSDebugLog(@"send key down event\n");
	  if ([theEvent modifierFlags] & NSCommandKeyMask)
	    {
	      NSArray	*window_list = [self windows];
	      unsigned	i;
	      unsigned	count = [window_list count];

	      for (i = 0; i < count; i++)
		{
		  NSWindow	*window = [window_list objectAtIndex: i];

		  if ([window performKeyEquivalent: theEvent] == YES)
		    break;
		}
	    }
	  else
	    [[theEvent window] sendEvent: theEvent];
	  break;
	}

      case NSKeyUp:
	{
	  NSDebugLog(@"send key up event\n");
	  [[theEvent window] sendEvent: theEvent];
	  break;
	}

      default:	/* pass all other events to the event's window	*/
	{
	  NSWindow	*window = [theEvent window];

	  if (!theEvent)
	    NSDebugLog(@"NSEvent is nil!\n");
	  NSDebugLog(@"NSEvent type: %d", [theEvent type]);
	  NSDebugLog(@"send event to window");
	  NSDebugLog([window description]);
	  if (window)
	    [window sendEvent: theEvent];
	  else if ([theEvent type] == NSRightMouseDown)
	    [self rightMouseDown: theEvent];
	  else
	    NSDebugLog(@"no window");
	}
    }
}

- (NSEvent*) currentEvent;
{
  return current_event;
}

- (void) discardEventsMatchingMask: (unsigned int)mask
		       beforeEvent: (NSEvent *)lastEvent
{
  DPSDiscardEvents(GSCurrentContext(), mask, lastEvent);
}

- (NSEvent*) nextEventMatchingMask: (unsigned int)mask
			 untilDate: (NSDate*)expiration
			    inMode: (NSString*)mode
			   dequeue: (BOOL)flag
{
  NSEvent	*event;

  if (!expiration)
    expiration = [NSDate distantFuture];

  if (flag)
    event = DPSGetEvent(GSCurrentContext(), mask, expiration, mode);
  else
    event = DPSPeekEvent(GSCurrentContext(), mask, expiration, mode);

  if (event)
    {
NSAssert([event retainCount] > 0, NSInternalInconsistencyException);
      /*
       * If we are not in a tracking loop, we may want to unhide a hidden
       * because the mouse has been moved.
       */
      if (mode != NSEventTrackingRunLoopMode)
	{
	  if ([NSCursor isHiddenUntilMouseMoves])
	    {
	      NSEventType type = [event type];

	      if ((type == NSLeftMouseDown) || (type == NSLeftMouseUp)
		|| (type == NSRightMouseDown) || (type == NSRightMouseUp)
		|| (type == NSMouseMoved))
		{
		  [NSCursor unhide];
		}
	    }
	}

      ASSIGN(current_event, event);
    }
  return event;
}

- (void) postEvent: (NSEvent *)event atStart: (BOOL)flag
{
  DPSPostEvent(GSCurrentContext(), event, flag);
}

/*
 * Sending action messages
 */
- (BOOL) sendAction: (SEL)aSelector to: aTarget from: sender
{
  /*
   * If target responds to the selector then have it perform it.
   */
  if (aTarget && [aTarget respondsToSelector: aSelector])
    {
      [aTarget performSelector: aSelector withObject: sender];
      return YES;
    }
  else
    {
      id	resp = [self targetForAction: aSelector];

      if (resp)
	{
	  [resp performSelector: aSelector withObject: sender];
	  return YES;
	}
    }
  return NO;
}

- (id) targetForAction: (SEL)aSelector
{
  NSWindow	*keyWindow;
  NSWindow	*mainWindow;
  id	resp;

  keyWindow = [self keyWindow];
  if (keyWindow != nil)
    {
      resp = [keyWindow firstResponder];
      while (resp != nil)
	{
	  if ([resp respondsToSelector: aSelector])
	    {
	      return resp;
	    }
	  resp = [resp nextResponder];
	}
      if ([keyWindow respondsToSelector: aSelector])
	{
	  return keyWindow;
	}
      resp = [keyWindow delegate];
      if (resp != nil && [resp respondsToSelector: aSelector])
	{
	  return resp;
	}
    }

  mainWindow = [self mainWindow];
  if (keyWindow != mainWindow && mainWindow != nil)
    {
      resp = [mainWindow firstResponder];
      while (resp != nil)
	{
	  if ([resp respondsToSelector: aSelector])
	    {
	      return resp;
	    }
	  resp = [resp nextResponder];
	}
      if ([mainWindow respondsToSelector: aSelector])
	{
	  return mainWindow;
	}
      resp = [mainWindow delegate];
      if (resp != nil && [resp respondsToSelector: aSelector])
	{
	  return resp;
	}
    }

  if ([self respondsToSelector: aSelector])
    {
      return self;
    }
  if (delegate != nil && [delegate respondsToSelector: aSelector])
    {
      return delegate;
    }
  return nil;
}

- (BOOL) tryToPerform: (SEL)aSelector with: (id)anObject
{
  if ([super tryToPerform: aSelector with: anObject] == YES)
    {
      return YES;
    }
  if (delegate != nil && [delegate respondsToSelector: aSelector])
    {
      [delegate performSelector: aSelector withObject: anObject];
      return YES;
    }
  return NO;
}

// Set the app's icon
- (void) setApplicationIconImage: (NSImage*)anImage
{
  [app_icon setName: nil];
  [anImage setName: @"NSApplicationIcon"];
  ASSIGN(app_icon, anImage);
  [[app_icon_window contentView] setImage: anImage];
  [[app_icon_window contentView] setNeedsDisplay: YES];
}

- (NSImage*) applicationIconImage
{
  return app_icon;
}

/*
 * Hiding and arranging windows
 */
- (void) hide: (id)sender
{
  if (app_is_hidden == NO)
    {
      NSNotificationCenter	*nc;
      NSArray			*windowArray;
      unsigned			count;
      unsigned			i;

      nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName: NSApplicationWillHideNotification
			object: self];

      windowArray = [self windows];
      count = [windowArray count];
      for (i = 0; i < count; i++)
	{
	  id    win = [windowArray objectAtIndex: i];

	  if ([win isKindOfClass: [NSWindow class]]
	    && ![win isKindOfClass: [NSMenuWindow class]]
	    && ![win isKindOfClass: [NSIconWindow class]])
	    {
	      [win orderOut: self];
	    }
	}
      app_is_hidden = YES;
      /*
       * On hiding we also deactivate the application which will make the menus
       * go away too.
       */
      [self deactivate];
      unhide_on_activation = YES;


      [nc postNotificationName: NSApplicationDidHideNotification
			object: self];
    }
}

- (BOOL) isHidden
{
  return app_is_hidden;
}

- (void) unhide: (id)sender
{
  if (app_is_hidden)
    {
      [self unhideWithoutActivation];
      if (app_is_active == NO)
	{
	  /*
	   * Activation should make the applications menus visible.
	   */
	  [self activateIgnoringOtherApps: YES];
	}
      unhide_on_activation = NO;
    }
}

- (void) unhideWithoutActivation
{
  if (app_is_hidden == YES)
    {
      NSNotificationCenter	*nc;
      NSWindow			*key;
      NSArray			*windowArray;
      unsigned			count;
      unsigned			i;

      nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName: NSApplicationWillUnhideNotification
			object: self];

      key = [self keyWindow];
      windowArray = [self windows];
      count = [windowArray count];
      for (i = 0; i < count; i++)
	{
	  id    win = [windowArray objectAtIndex: i];

	  if (win != key && [win isKindOfClass: [NSWindow class]]
	    && ![win isKindOfClass: [NSMenuWindow class]]
	    && ![win isKindOfClass: [NSIconWindow class]])
	    {
	      if (win != key && [win isKindOfClass: [NSWindow class]])
		{
		  [win orderFrontRegardless];
		}
	    }
	}
      app_is_hidden = NO;

      [nc postNotificationName: NSApplicationDidUnhideNotification
			object: self];

      if ([self keyWindow] != key)
	[key orderFront: self];
      [[self keyWindow] makeKeyAndOrderFront: self];
    }
}

- (void) arrangeInFront: (id)sender
{
  NSMenu	*menu;

  menu = [self windowsMenu];
  if (menu)
    {
      NSArray	*itemArray;
      unsigned	count;
      unsigned	i;

      itemArray = [menu itemArray];
      count = [itemArray count];
      for (i = 0; i < count; i++)
	{
	  id	win = [[itemArray objectAtIndex: i] target];

	  if ([win isKindOfClass: [NSWindow class]])
	    {
	      [win orderFront: sender];
	    }
	}
    }
}

/*
 * Managing windows
 */
- (NSWindow*) keyWindow
{
  NSArray *window_list = [self windows];
  int i, j;
  id w;

  j = [window_list count];
  for (i = 0; i < j; ++i)
    {
      w = [window_list objectAtIndex: i];
      if ([w isKeyWindow])
	return w;
    }

  return nil;
}

- (NSWindow*) mainWindow
{
  NSArray *window_list = [self windows];
  int i, j;
  id w;

  j = [window_list count];
  for (i = 0; i < j; ++i)
    {
      w = [window_list objectAtIndex: i];
      if ([w isMainWindow])
	return w;
    }

  return nil;
}

- (NSWindow*) makeWindowsPerform: (SEL)aSelector inOrder: (BOOL)flag
{
  NSArray	*window_list = [self windows];
  unsigned	i;

  if (flag)
    {
      unsigned	count = [window_list count];

      for (i = 0; i < count; i++)
	{
	  NSWindow *window = [window_list objectAtIndex: i];

	  if ([window performSelector: aSelector] != nil)
	    {
	      return window;
	    }
	}
    }
  else
    {
      i = [window_list count];
      while (i-- > 0)
	{
	  NSWindow *window = [window_list objectAtIndex: i];

	  if ([window performSelector: aSelector] != nil)
	    {
	      return window;
	    }
	}
    }
  return nil;
}

- (void) miniaturizeAll: sender
{
  NSArray *window_list = [self windows];
  unsigned i, count;

  for (i = 0, count = [window_list count]; i < count; i++)
    [[window_list objectAtIndex: i] miniaturize: sender];
}

- (void) preventWindowOrdering
{
}

- (void) setWindowsNeedUpdate: (BOOL)flag
{
  windows_need_update = flag;
}

- (void) updateWindows
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSArray		*window_list = [self windows];
  unsigned		count = [window_list count];
  unsigned		i;

  windows_need_update = NO;
  [nc postNotificationName: NSApplicationWillUpdateNotification object: self];

  for (i = 0; i < count; i++)
    {
      NSWindow *win = [window_list objectAtIndex: i];
      if ([win isVisible])
	[win update];
    }
  [nc postNotificationName: NSApplicationDidUpdateNotification object: self];
}

- (NSArray*) windows
{
  return [NSWindow _windowList];
}

- (NSWindow *) windowWithWindowNumber: (int)windowNum
{
  return [NSWindow _windowWithNumber: windowNum];
}

/*
 * Showing Standard Panels
 */
- (void) orderFrontColorPanel: sender
{
}

- (void) orderFrontDataLinkPanel: sender
{
}

- (void) orderFrontHelpPanel: sender
{
}

- (void) runPageLayout: sender
{
}

/*
 * Getting the main menu
 */
- (NSMenu*) mainMenu
{
  return main_menu;
}

- (void) setMainMenu: (NSMenu*)aMenu
{
  unsigned	i, j;
  NSMenuItem	*mc;
  NSArray	*mi;

  if (main_menu != nil && main_menu != aMenu)
    {
      [main_menu close];
    }

  ASSIGN(main_menu, aMenu);

  [main_menu setTitle: [[NSProcessInfo processInfo] processName]];
  [main_menu sizeToFit];
  /*
   * Find a menucell with the title Windows this is the default windows menu
   */
  mi = [main_menu itemArray];
  j = [mi count];
  windows_menu = nil;
  for (i = 0; i < j; ++i)
    {
      mc = [mi objectAtIndex: i];
      if ([[mc stringValue] compare: @"Windows"] == NSOrderedSame)
	{
	  windows_menu = mc;
	  break;
	}
    }

  if ([self isActive])
    {
      [main_menu update];
      [main_menu display];
    }
}

/*
 * Managing the Windows menu
 */
- (void) addWindowsItem: (NSWindow*)aWindow
		  title: (NSString*)aString
	       filename: (BOOL)isFilename
{
  [self changeWindowsItem: aWindow title: aString filename: isFilename];
}

- (void) changeWindowsItem: (NSWindow*)aWindow
		     title: (NSString*)aString
		  filename: (BOOL)isFilename
{
  NSMenu	*menu;
  NSArray	*itemArray;
  unsigned	count;
  unsigned	i;
  id		item;

  if (![aWindow isKindOfClass: [NSWindow class]])
    [NSException raise: NSInvalidArgumentException
		format: @"Object of bad type passed as window"];

  /*
   *	If Menus are implemented as a subclass of window we must make sure
   *	to exclude them from the windows menu.
   */
  if ([aWindow isKindOfClass: [NSMenu class]])
    return;

  /*
   * Can't permit an untitled window in the window menu.
   */
  if (aString == nil || [aString isEqualToString: @""])
    return;

  /*
   * If there is no menu and nowhere to put one, we can't do anything.
   */
  if (windows_menu == nil)
    return;

  /*
   * If the menu exists and the window is already in the menu -
   * remove it so it can be re-inserted in the correct place.
   * If the menu doesn't exist - create it.
   */
  menu = [self windowsMenu];
  if (menu)
    {
      itemArray = [menu itemArray];
      count = [itemArray count];
      for (i = 0; i < count; i++)
	{
	  id	item = [itemArray objectAtIndex: i];

	  if ([item target] == aWindow)
	    {
	      [menu removeItem: item];
	      break;
	    }
	}
    }
  else
    {
      menu = [[NSMenu alloc] initWithTitle: [windows_menu title]];
      [self setWindowsMenu: menu];
    }

  /*
   * Now we insert a menu item for the window in the correct order.
   * Make special allowance for menu entries to 'arrangeInFront: '
   * 'performMiniaturize: ' and 'preformClose: '.  If these exist the
   * window entries should stay after the first one and before the
   * other two.
   */
  itemArray = [menu itemArray];
  count = [itemArray count];

  i = 0;
  if (count > 0 && sel_eq([[itemArray objectAtIndex: 0] action],
		@selector(arrangeInFront:)))
    i++;
  if (count > i && sel_eq([[itemArray objectAtIndex: count-1] action],
		@selector(performClose:)))
    count--;
  if (count > i && sel_eq([[itemArray objectAtIndex: count-1] action],
		@selector(performMiniaturize:)))
    count--;

  while (i < count)
    {
      item = [itemArray objectAtIndex: i];

      if ([[item title] compare: aString] == NSOrderedDescending)
	break;
      i++;
    }
  item = [menu insertItemWithTitle: aString
			    action: @selector(makeKeyAndOrderFront:)
		     keyEquivalent: @""
			   atIndex: i];
  [item setTarget: aWindow];
  [menu sizeToFit];
  [menu update];
}

- (void) removeWindowsItem: (NSWindow*)aWindow
{
  NSMenu	*menu;

  menu = [self windowsMenu];
  if (menu)
    {
      NSArray	*itemArray;
      unsigned	count;
      unsigned	i;

      itemArray = [menu itemArray];
      count = [itemArray count];
      for (i = 0; i < count; i++)
	{
	  id	item = [itemArray objectAtIndex: i];

	  if ([item target] == aWindow)
	    {
	      [menu removeItem: item];
	      [menu sizeToFit];
	      [menu update];
	      break;
	    }
	}
    }
}

- (void) setWindowsMenu: (NSMenu*)aMenu
{
  if (windows_menu)
    {
      NSMutableArray	*windows;
      NSMenu		*menu;
      id		win;

      menu = [self windowsMenu];
      if (menu == aMenu)
	return;

      /*
       * Remove all the windows from the old windows menu and store
       * them in a temporary array for insertion into the new menu.
       */
      windows = [NSMutableArray arrayWithCapacity: 10];
      if (menu)
	{
	  NSArray   *itemArray;
	  unsigned  count;
	  unsigned  i;

	  itemArray = [menu itemArray];
	  count = [itemArray count];
	  for (i = 0; i < count; i++)
	    {
	      id    item = [itemArray objectAtIndex: i];

	      win = [item target];
	      if ([win isKindOfClass: [NSWindow class]])
		{
		  [windows addObject: win];
		  [menu removeItem: item];
		}
	    }
	}

      /*
       * Now use [-changeWindowsItem: title: filename: ] to build the new menu.
       */
      [main_menu setSubmenu: aMenu forItem: (id<NSMenuItem>)windows_menu];
      while ((win = [windows lastObject]) != nil)
	{
	  [self changeWindowsItem: win
			    title: [win title]
			 filename: [win representedFilename] != nil];
	  [windows removeLastObject];
	}
      [aMenu sizeToFit];
      [aMenu update];
    }
}

- (void) updateWindowsItem: aWindow
{
  NSMenu	*menu;

  menu = [self windowsMenu];
  if (menu)
    {
      NSArray	*itemArray;
      unsigned	count;
      unsigned	i;

      itemArray = [menu itemArray];
      count = [itemArray count];
      for (i = 0; i < count; i++)
	{
	  id	item = [itemArray objectAtIndex: i];

	  if ([item target] == aWindow)
	    {
	      NSCellImagePosition	oldPos = [item imagePosition];
	      NSImage			*oldImage = [item image];
	      BOOL			changed = NO;

	      if ([aWindow representedFilename] == nil)
		{
		  if (oldPos != NSNoImage)
		    {
		      [item setImagePosition: NSNoImage];
		      changed = YES;
		    }
		}
	      else
		{
		  NSImage	*newImage = oldImage;

		  if (oldPos != NSImageLeft)
		    {
		      [item setImagePosition: NSImageLeft];
		      changed = YES;
		    }
		  if ([aWindow isDocumentEdited])
		    {
		      newImage = [NSImage imageNamed: @"common_WMCloseBroken"];
		    }
		  else
		    {
		      newImage = [NSImage imageNamed: @"common_WMClose"];
		    }
		  if (newImage != oldImage)
		    {
		      [item setImage: newImage];
		      changed = YES;
		    }
		}
	      if (changed)
		{
		  [(id)[item controlView] sizeToFit];
		  [menu sizeToFit];
		  [menu update];
		}
	      break;
	    }
	}
    }
}

- (NSMenu*) windowsMenu
{
  if (windows_menu)
    return [windows_menu target];
  else
    return nil;
}

/*
 * Managing the Service menu
 */
- (void) registerServicesMenuSendTypes: (NSArray *)sendTypes
			   returnTypes: (NSArray *)returnTypes
{
  [listener registerSendTypes: sendTypes
		  returnTypes: returnTypes];
}

- (NSMenu *) servicesMenu
{
  return [listener servicesMenu];
}

- (id) servicesProvider
{
  return [listener servicesProvider];
}

- (void) setServicesMenu: (NSMenu *)aMenu
{
  [listener setServicesMenu: aMenu];
}

- (void) setServicesProvider: (id)anObject
{
  [listener setServicesProvider: anObject];
}

- (id) validRequestorForSendType: (NSString *)sendType
		      returnType: (NSString *)returnType
{
  return nil;
}

- (NSGraphicsContext *) context
{
  return GSCurrentContext();
}

- (void) reportException: (NSException *)anException
{
  if (anException)
    NSLog(@"reported exception - %@", anException);
}

/*
 * Terminating the application
 */
- (void) terminate: (id)sender
{
  BOOL	shouldTerminate = YES;

  if ([delegate respondsToSelector: @selector(applicationShouldTerminate:)])
    shouldTerminate = [delegate applicationShouldTerminate: sender];
  else
    shouldTerminate = [[NSDocumentController sharedDocumentController] reviewUnsavedDocumentsWithAlertTitle:@"Quit" cancellable:YES];

  if (shouldTerminate)
    {
      NSDictionary	*userInfo;

      app_should_quit = YES;
      /*
       * add dummy event to queue to assure loop cycles
       * at least one more time
       */
      DPSPostEvent(GSCurrentContext(), null_event, NO);

      /*
       * Tell the Workspace that we really did terminate
       */
      userInfo = [NSDictionary dictionaryWithObject:
	[[NSProcessInfo processInfo] processName] forKey: @"NSApplicationName"];
      [[[NSWorkspace sharedWorkspace] notificationCenter]
        postNotificationName: NSWorkspaceDidTerminateApplicationNotification
		      object: self
		    userInfo: userInfo];
    }
}

- (id) delegate
{
  return delegate;
}

- (void) setDelegate: (id)anObject
{
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  if (delegate)
    [nc removeObserver: delegate name: nil object: self];
  delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([delegate respondsToSelector: @selector(application##notif_name:)]) \
    [nc addObserver: delegate \
      selector: @selector(application##notif_name:) \
      name: NSApplication##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidBecomeActive);
  SET_DELEGATE_NOTIFICATION(DidFinishLaunching);
  SET_DELEGATE_NOTIFICATION(DidHide);
  SET_DELEGATE_NOTIFICATION(DidResignActive);
  SET_DELEGATE_NOTIFICATION(DidUnhide);
  SET_DELEGATE_NOTIFICATION(DidUpdate);
  SET_DELEGATE_NOTIFICATION(WillBecomeActive);
  SET_DELEGATE_NOTIFICATION(WillFinishLaunching);
  SET_DELEGATE_NOTIFICATION(WillHide);
  SET_DELEGATE_NOTIFICATION(WillResignActive);
  SET_DELEGATE_NOTIFICATION(WillUnhide);
  SET_DELEGATE_NOTIFICATION(WillUpdate);
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: delegate];
  [aCoder encodeObject: main_menu];
  [aCoder encodeConditionalObject: windows_menu];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  id	obj;

  [super initWithCoder: aDecoder];

  obj = [aDecoder decodeObject];
  [self setDelegate: obj];
  obj = [aDecoder decodeObject];
  [self setMainMenu: obj];
  obj = [aDecoder decodeObject];
  [self setWindowsMenu: obj];
  return self;
}

#ifndef STRICT_OPENSTEP
- (void) _windowWillClose: (NSNotification*) notification
{
  int count, wincount, realcount;
  id win =  [self windows];
  wincount = [win count];
  realcount = 0;
  for(count = 0; count < wincount; count++)
    {
      if([[win objectAtIndex: count] canBecomeMainWindow])
	{
	  realcount ++;
	}
    }
  
  /* If there's only one window left, and that's the one being closed, 
     then we ask the delegate if the app is to be terminated. */
  if ((realcount <= 1) && [[notification object] isMainWindow])
    {
      NSLog(@"asking delegate whether to terminate app...");
      if ([delegate respondsToSelector: @selector(applicationShouldTerminateAfterLastWindowClosed:)])
	{
	  if([delegate applicationShouldTerminateAfterLastWindowClosed: self])
	    {
	      [self terminate: self];
	    }
	}
    }
}
#endif

@end /* NSApplication */

