/*
   NSApplication.m

   The one and only application class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
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

#include <AppKit/GSContext.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSCursor.h>
#include <AppKit/GSServicesManager.h>
#include <AppKit/IMLoading.h>

#ifndef ASSIGN
#define ASSIGN(object,value)    ({\
if (value != object) \
  { \
    if (value) \
      { \
	[value retain]; \
      } \
    if (object) \
      { \
	[object release]; \
      } \
    object = value; \
  } \
})
#endif

//
// Types
//
struct _NSModalSession {
  int       runState;
  NSWindow  *window;
  NSModalSession    previous;
};

//
// Class variables
//
static BOOL gnustep_gui_app_is_in_dealloc;
static NSEvent *null_event;
static NSString *NSAbortModalException = @"NSAbortModalException";

NSApplication	*NSApp = nil;

@implementation NSApplication

//
// Class methods
//
+ (void)initialize
{
    if (self == [NSApplication class])
        {
        NSDebugLog(@"Initialize NSApplication class\n");
                                                    // Initial version
        [self setVersion:1];
                                                    // So the application knows
        gnustep_gui_app_is_in_dealloc = NO;         // it's within dealloc and
        }                                           // can prevent -release
}                                                   // loops.

+ (NSApplication *)sharedApplication
{                                           // If the global application does
    if (!NSApp)                             // not yet exist then create it
        {
        NSApp = [self alloc];               // Don't combine the following two
        [NSApp init];                       // statements into one to avoid
        }                                   // problems with some classes'
                                            // initialization code that tries
    return NSApp;                           // to get the shared application.
}

//
// Instance methods
//
- init
{
  if (NSApp != self)
    {
      [self release];
      return [NSApplication sharedApplication];
    }

    [super init];

    NSDebugLog(@"Begin of NSApplication -init\n");

    listener = [GSServicesManager newWithApplication: self];

    main_menu = nil;
    windows_need_update = YES;

    event_queue = [NSMutableArray new];                 // allocate event queue
    current_event = [NSEvent new];                      // no current event
    null_event = [NSEvent new];                         // create dummy event

    [self setNextResponder:NULL];                       // We are the end of
                                                        // the responder chain

                                                        // Set up the run loop
                                                        // object for the
                                                        // current thread
    [self setupRunLoopInputSourcesForMode:NSDefaultRunLoopMode];
    [self setupRunLoopInputSourcesForMode:NSConnectionReplyMode];
    [self setupRunLoopInputSourcesForMode:NSModalPanelRunLoopMode];
    [self setupRunLoopInputSourcesForMode:NSEventTrackingRunLoopMode];

    return self;
}

- (void)finishLaunching
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
NSBundle* mainBundle = [NSBundle mainBundle];
NSString* resourcePath = [mainBundle resourcePath];
NSString* infoFilePath = [resourcePath
                        stringByAppendingPathComponent:@"Info-gnustep.plist"];
NSDictionary* infoDict;
NSString* mainModelFile;

    infoDict = [[NSString stringWithContentsOfFile:infoFilePath] propertyList];
    mainModelFile = [infoDict objectForKey:@"NSMainNibFile"];

    if (mainModelFile && ![mainModelFile isEqual:@""])
        {
        if (![GMModel loadIMFile:mainModelFile
                      owner:[NSApplication sharedApplication]])
            NSLog (@"Cannot load the main model file '%@", mainModelFile);
        }
                                                    // post notification that
                                                    // launch will finish
    [nc postNotificationName: NSApplicationWillFinishLaunchingNotification
        object: self];
                                                    // Register our listener to
                                                    // handle incoming services
                                                    // requests etc.
    [listener registerAsServiceProvider];

                                                    // finish the launching
                                                    // post notification that
                                                    // launching has finished
    [nc postNotificationName: NSApplicationDidFinishLaunchingNotification
        object: self];
}

- (void) dealloc
{
    NSDebugLog(@"Freeing NSApplication\n");
                                                    // Let ourselves know we
    gnustep_gui_app_is_in_dealloc = YES;            // are within dealloc

    [listener release];
    [event_queue release];
    [current_event release];

    while (session != 0)                            // We may need to tidy up
        {                                           // nested modal session
        NSModalSession tmp = session;               // structures.

        session = tmp->previous;
        NSZoneFree(NSDefaultMallocZone(), tmp);
        }

    [super dealloc];
}

//
// Changing the active application
//
- (void) activateIgnoringOtherApps: (BOOL)flag
{
  if (app_is_active == NO)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      /*
       * Menus should observe this notification in order to make themselves
       * visible when the application is active.
       */
      [nc postNotificationName: NSApplicationWillBecomeActiveNotification
                        object: self];

      app_is_active = YES;

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

//
// Running the main event loop
//
- (void) run
{
  NSEvent *e;
  Class	arpClass = [NSAutoreleasePool class];	 /* Cache the class */
  NSAutoreleasePool* pool;

  NSDebugLog(@"NSApplication -run\n");

  /*
   *  Set this flag here in case the application is actually terminated
   *  inside -finishLaunching.
   */
  app_should_quit = NO;

  [self finishLaunching];

  app_is_running = YES;

  while (app_should_quit == NO)
    {
      pool = [arpClass new];

      e = [self nextEventMatchingMask:NSAnyEventMask
                  untilDate:[NSDate distantFuture]
                  inMode:NSDefaultRunLoopMode
                  dequeue:YES];
      if (e)
	[self sendEvent: e];

					// update (en/disable) the
                                        // services menu's items
      [listener updateServicesMenu];
      [main_menu update];

			       		// send an update message
			       		// to all visible windows
      if (windows_need_update)
	[self updateWindows];

      [pool release];
    }

  NSDebugLog(@"NSApplication end of run loop\n");
}

- (BOOL) isRunning
{
  return app_is_running;
}

//
// Running modal event loops
//
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
                format: @"null pointer passed to endModalSession:"];

                                                // Remove this session from
                                                // linked list of sessions.
  while (tmp && tmp != theSession)
    tmp = tmp->previous;

  if (tmp == 0)
    [NSException raise: NSInvalidArgumentException
                format: @"unknown session passed to endModalSession:"];

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

  theSession = NULL;
  code = NSRunContinuesResponse;

  NS_DURING
    {
      theSession = [self beginModalSessionForWindow:theWindow];
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
          [self endModalSession: theSession];
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
  BOOL found = NO;
  NSEvent *event;
  unsigned count;
  unsigned i;

  if (theSession != session)
    [NSException raise: NSInvalidArgumentException
                format: @"runModalSession: with wrong session"];

  theSession->runState = NSRunContinuesResponse;
  [theSession->window display];
  [theSession->window makeKeyAndOrderFront: self];

    // First we make sure
    // that there is an
    // event.
  do
    {
      count = [event_queue count];
      for (i = 0; i < count; i++)
        {
          event = [event_queue objectAtIndex: 0];
          if ([event window] == theSession->window)
            {
              found = YES;
              break;
            }
          else
            {
              // dump events not for
              // the modal window
              [event_queue removeObjectAtIndex: 0];
            }
        }

      if (found == NO)
        {
          NSDate *limitDate = [NSDate distantFuture];

          [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                       beforeDate: limitDate];
        }
    }
  while (found == NO && theSession->runState == NSRunContinuesResponse);

  /*
   *    Deal with the events in the queue.
   */
  while (found == YES && theSession->runState == NSRunContinuesResponse)
    {
      NSAutoreleasePool *pool = [NSAutoreleasePool new];

      found = NO;
      count = [event_queue count];
      for (i = 0; i < count; i++)
        {
          event = [event_queue objectAtIndex: i];
          if ([event window] == theSession->window)
            {
              ASSIGN(current_event, event);
              [event_queue removeObjectAtIndex: i];
              found = YES;

              break;
            }
        }

      if (found == YES)
        {
          [self sendEvent: current_event];

          /*
           *    Check to see if the window has gone away - if so, end session.
           */
          if ([[self windows] indexOfObjectIdenticalTo: session->window] ==
            NSNotFound || [session->window isVisible] == NO)
            [self stopModal];
          if (windows_need_update)
            [self updateWindows];
        }

      [pool release];
    }

  NSAssert(session == theSession, @"Session was changed while running");

  return theSession->runState;
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
                format:@"stopModalWithCode: when not in a modal session"];
  else
    if (returnCode == NSRunContinuesResponse)
      [NSException raise: NSInvalidArgumentException
                  format: @"stopModalWithCode: with NSRunContinuesResponse"];

  session->runState = returnCode;
}

//
// Getting, removing, and posting events
//
- (void)sendEvent:(NSEvent *)theEvent
{
    if (theEvent == null_event)                     // Don't send null event
        {
        NSDebugLog(@"Not sending the Null Event\n");
        return;
        }

    switch ([theEvent type])                        // determine the event type
        {
        case NSPeriodic:                            // NSApplication traps the
            break;                                  // periodic events

        case NSKeyDown:
            {
            NSDebugLog(@"send key down event\n");
            [[theEvent window] sendEvent:theEvent];
            break;
            }

        case NSKeyUp:
            {
            NSDebugLog(@"send key up event\n");
            [[theEvent window] sendEvent:theEvent];
            break;
            }

        case NSRightMouseDown:                              // Right mouse down
            if (main_menu)
                {
                static NSMenu *copyOfMainMenu = nil;
                NSWindow *copyMenuWindow;

                if (!copyOfMainMenu)                        // display the menu
                    copyOfMainMenu = [main_menu copy];      // under the mouse
                copyMenuWindow = [copyOfMainMenu menuWindow];
                [copyOfMainMenu _rightMouseDisplay];
                [copyMenuWindow _captureMouse:self];
                [[copyOfMainMenu menuCells] mouseDown:theEvent];
                [copyMenuWindow _releaseMouse:self];
                }
            break;

        default:                                    // pass all other events to
            {                                       // the event's window
            NSWindow* window = [theEvent window];

            if (!theEvent)
                NSDebugLog(@"NSEvent is nil!\n");
            NSDebugLog(@"NSEvent type: %d", [theEvent type]);
            NSDebugLog(@"send event to window");
            NSDebugLog([window description]);
            if (!window)
                NSDebugLog(@"no window");
            [window sendEvent:theEvent];
            }
        }
}

- (NSEvent*) currentEvent;
{
  return current_event;
}

- (void) discardEventsMatchingMask:(unsigned int)mask
                       beforeEvent:(NSEvent *)lastEvent
{
int i = 0, count, loop;
NSEvent* event = nil;
BOOL match;
                                                        // if queue contains
    if ((count = [event_queue count]))                  // events check them
        {
        for (loop = 0; ((event != lastEvent) && (loop < count)); loop++)
            {
            event = [event_queue objectAtIndex:i];      // Get next event from
            match = NO;                                 // the events queue

            if (mask == NSAnyEventMask)                 // the any event mask
                match = YES;                            // matches all events
            else
                {
                switch([event type])
                    {
                    case NSLeftMouseDown:
                        if (mask & NSLeftMouseDownMask)
                            match = YES;
                        break;

                    case NSLeftMouseUp:
                        if (mask & NSLeftMouseUpMask)
                            match = YES;
                        break;

                    case NSRightMouseDown:
                        if (mask & NSRightMouseDownMask)
                            match = YES;
                        break;

                    case NSRightMouseUp:
                        if (mask & NSRightMouseUpMask)
                            match = YES;
                        break;

                    case NSMouseMoved:
                        if (mask & NSMouseMovedMask)
                            match = YES;
                        break;

                    case NSMouseEntered:
                        if (mask & NSMouseEnteredMask)
                            match = YES;
                        break;

                    case NSMouseExited:
                        if (mask & NSMouseExitedMask)
                            match = YES;
                        break;

                    case NSLeftMouseDragged:
                        if (mask & NSLeftMouseDraggedMask)
                            match = YES;
                        break;

                    case NSRightMouseDragged:
                        if (mask & NSRightMouseDraggedMask)
                            match = YES;
                        break;

                    case NSKeyDown:
                        if (mask & NSKeyDownMask)
                            match = YES;
                        break;

                    case NSKeyUp:
                        if (mask & NSKeyUpMask)
                            match = YES;
                        break;

                    case NSFlagsChanged:
                        if (mask & NSFlagsChangedMask)
                            match = YES;
                        break;

                    case NSPeriodic:
                        if (mask & NSPeriodicMask)
                            match = YES;
                        break;

                    case NSCursorUpdate:
                        if (mask & NSCursorUpdateMask)
                            match = YES;
                        break;

                    default:
                        break;
                }   }                                   // remove event from
                                                        // the queue if it
            if (match)                                  // matched the mask
                [event_queue removeObjectAtIndex:i];
            else                                        // inc queue cntr only
                i++;                                    // if not a match else
            }                                           // we will run off the
        }                                               // end of the queue
}

- (NSEvent*)_eventMatchingMask:(unsigned int)mask dequeue:(BOOL)flag
{
NSEvent* event;                                         // return the next
int i, count;                                           // event in the queue
BOOL match = NO;                                        // which matches mask

    [self _nextEvent];

    if ((count = [event_queue count]))                  // if queue contains
        {                                               // events check them
        for (i = 0; i < count; i++)
            {                                           // Get next event from
            event = [event_queue objectAtIndex:i];      // the events queue

            if (mask == NSAnyEventMask)                 // the any event mask
                match = YES;                            // matches all events
            else
                {
                if (event == null_event)                // do not send the null
                    {                                   // event
                    match = NO;
                    if (flag)                           // dequeue null event
                        {                               // if flag is set
                        [event retain];
                        [event_queue removeObjectAtIndex:i];
                        }
                    }
                else
                    {
                    switch([event type])
                        {
                        case NSLeftMouseDown:
                            if (mask & NSLeftMouseDownMask)
                                match = YES;
                            break;

                        case NSLeftMouseUp:
                            if (mask & NSLeftMouseUpMask)
                                match = YES;
                            break;

                        case NSRightMouseDown:
                            if (mask & NSRightMouseDownMask)
                                match = YES;
                            break;

                        case NSRightMouseUp:
                            if (mask & NSRightMouseUpMask)
                                match = YES;
                            break;

                        case NSMouseMoved:
                            if (mask & NSMouseMovedMask)
                                match = YES;
                            break;

                        case NSMouseEntered:
                            if (mask & NSMouseEnteredMask)
                                match = YES;
                            break;

                        case NSMouseExited:
                            if (mask & NSMouseExitedMask)
                                match = YES;
                            break;

                        case NSLeftMouseDragged:
                            if (mask & NSLeftMouseDraggedMask)
                                match = YES;
                            break;

                        case NSRightMouseDragged:
                            if (mask & NSRightMouseDraggedMask)
                                match = YES;
                            break;

                        case NSKeyDown:
                            if (mask & NSKeyDownMask)
                                match = YES;
                            break;

                        case NSKeyUp:
                            if (mask & NSKeyUpMask)
                                match = YES;
                            break;

                        case NSFlagsChanged:
                            if (mask & NSFlagsChangedMask)
                                match = YES;
                            break;

                        case NSPeriodic:
                            if (mask & NSPeriodicMask)
                                match = YES;
                            break;

                        case NSCursorUpdate:
                            if (mask & NSCursorUpdateMask)
                                match = YES;
                            break;

                        default:
                            match = NO;
                            break;
                }   }   }

            if (match)
                {
                if (flag)                               // dequeue the event if
                    {                                   // flag is set
                    [event retain];
                    [event_queue removeObjectAtIndex:i];
                    }
                ASSIGN(current_event, event);

                return event;                           // return an event from
                }                                       // the queue which
            }                                           // matches the mask
        }
                                                        // no event in the
    return nil;                                         // queue matches mask
}

- (NSEvent*) nextEventMatchingMask:(unsigned int)mask
                         untilDate:(NSDate *)expiration
                         inMode:(NSString *)mode
                         dequeue:(BOOL)flag
{
NSEvent *event;
BOOL done = NO;

    if (mode == NSEventTrackingRunLoopMode)             // temporary hack to
        inTrackingLoop = YES;                           // regulate translation
    else                                                // of X motion events
        inTrackingLoop = NO;                            // while not in a
                                                        // tracking loop
    if ((event = [self _eventMatchingMask:mask dequeue:flag]))
        done = YES;
    else
        if (!expiration)
            expiration = [NSDate distantFuture];

    while (!done)                                       // Not in queue so wait
        {                                               // for next event
        NSDate *limitDate, *originalLimitDate;
        NSRunLoop* currentLoop = [NSRunLoop currentRunLoop];
                        // Retain the limitDate so that it doesn't get released
                        // accidentally by runMode:beforeDate: if a timer which
                        // has this date as fire date gets released.
        limitDate = [[currentLoop limitDateForMode:mode] retain];
        originalLimitDate = limitDate;

        if ((event = [self _eventMatchingMask:mask dequeue:flag]))
            {
            [limitDate release];
            break;
            }

        if (limitDate)
            limitDate = [expiration earlierDate:limitDate];
        else
            limitDate = expiration;

        [currentLoop runMode:mode beforeDate:limitDate];
        [originalLimitDate release];

        if ((event = [self _eventMatchingMask:mask dequeue:flag]))
            break;
        }
                                                    // no need to unhide cursor
    if (!inTrackingLoop)                            // while in a tracking loop
        {
        if ([NSCursor isHiddenUntilMouseMoves])     // do so only if we should
            {                                       // unhide when mouse moves
            NSEventType type = [event type];        // and event is mouse event
            if ((type == NSLeftMouseDown) || (type == NSLeftMouseUp)
                    || (type == NSRightMouseDown) || (type == NSRightMouseUp)
                    || (type == NSMouseMoved))
                {
                [NSCursor unhide];
                }
            }
        }

    return event;
}

- (void)postEvent:(NSEvent *)event atStart:(BOOL)flag
{
  if (!flag)
    [event_queue addObject: event];
  else
    [event_queue insertObject: event atIndex: 0];
}

//
// Sending action messages
//
- (BOOL) sendAction: (SEL)aSelector to: aTarget from: sender
{
  /*
   * If target responds to the selector then have it perform it.
   */
  if ([aTarget respondsToSelector: aSelector])
    {
      [aTarget performSelector: aSelector withObject: sender];
      return YES;
    }
  else
    {
      id        resp = [self targetForAction: aSelector];

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
  NSWindow      *keyWindow;
  NSWindow      *mainWindow;
  id    resp;

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
  ASSIGN(app_icon, anImage);
}

- (NSImage*) applicationIconImage
{
  return app_icon;
}

//
// Hiding and arranging windows
//
- (void) hide: (id)sender
{
  if (app_is_hidden == NO)
    {
      NSMenu *menu;
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      [nc postNotificationName: NSApplicationWillHideNotification
                        object: self];

      menu = [self windowsMenu];
      if (menu)
        {
          NSArray   *itemArray;
          unsigned  count;
          unsigned  i;

          itemArray = [menu itemArray];
          count = [itemArray count];
          for (i = 0; i < count; i++)
            {
              id    win = [[itemArray objectAtIndex: i] target];

              if ([win isKindOfClass: [NSWindow class]])
                {
                  [win orderOut: self];
                }
            }
        }
      app_is_hidden = YES;

      [nc postNotificationName: NSApplicationDidHideNotification
                        object: self];

      /*
       * On hiding we also deactivate the application which will make the menus
       * go away too.
       */
      [self deactivate];
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
    }
}

- (void) unhideWithoutActivation
{
  if (app_is_hidden == YES)
    {
      NSMenu    *menu;
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      [nc postNotificationName: NSApplicationWillUnhideNotification
                        object: self];

      menu = [self windowsMenu];
      if (menu)
        {
          NSArray   *itemArray;
          unsigned  count;
          unsigned  i;

          itemArray = [menu itemArray];
          count = [itemArray count];
          for (i = 0; i < count; i++)
            {
              id    win = [[itemArray objectAtIndex: i] target];

              if ([win isKindOfClass: [NSWindow class]])
                {
                  [win orderFront: self];
                }
            }
        }
      app_is_hidden = NO;

      [nc postNotificationName: NSApplicationDidUnhideNotification
                        object: self];

      [[self keyWindow] makeKeyAndOrderFront: self];
    }
}

- (void) arrangeInFront: (id)sender                 // preliminary FIX ME
{
  NSMenu        *menu;

  menu = [self windowsMenu];
  if (menu)
    {
      NSArray   *itemArray;
      unsigned  count;
      unsigned  i;

      itemArray = [menu itemArray];
      count = [itemArray count];
      for (i = 0; i < count; i++)
        {
          id    win = [[itemArray objectAtIndex: i] target];

          if ([win isKindOfClass: [NSWindow class]])
            {
              [win orderFront: sender];
            }
        }
    }
}

//
// Managing windows
//
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
      w = [window_list objectAtIndex:i];
      if ([w isMainWindow])
        return w;
    }

  return nil;
}

- (NSWindow*) makeWindowsPerform: (SEL)aSelector inOrder: (BOOL)flag
{
  NSArray       *window_list = [self windows];
  unsigned      i;

  if (flag)
    {
      unsigned  count = [window_list count];

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

- (void)miniaturizeAll:sender
{
  NSArray *window_list = [self windows];
  unsigned i, count;

  for (i = 0, count = [window_list count]; i < count; i++)
    [[window_list objectAtIndex:i] miniaturize:sender];
}

- (void) preventWindowOrdering
{
}

- (void) setWindowsNeedUpdate: (BOOL)flag
{
  windows_need_update = flag;
}

- (void) updateWindows                               // send an update message
{                                                   // to all visible windows
  int i, count;
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  NSArray *window_list = [self windows];

  windows_need_update = NO;
                                                    // notify that an update is
                                                    // imminent
  [nc postNotificationName:NSApplicationWillUpdateNotification object: self];

  for (i = 0, count = [window_list count]; i < count; i++)
    {
      NSWindow *win = [window_list objectAtIndex: i];
      if ([win isVisible])                        // send update only if the
	[win update];                           // window is visible
    }
						  // notify update did occur
  [nc postNotificationName:NSApplicationDidUpdateNotification object:self];
}

- (NSArray*) windows
{
  // Implemented by backend.
  return nil;
}

- (NSWindow *)windowWithWindowNumber:(int)windowNum
{
  NSArray *window_list = [self windows];
  unsigned i, j;
  NSWindow *w;

  j = [window_list count];
  for (i = 0; i < j; ++i)
    {
      w = [window_list objectAtIndex: i];
      if ([w windowNumber] == windowNum)
        return w;
    }

  return nil;
}

//
// Showing Standard Panels
//
- (void)orderFrontColorPanel:sender
{
}

- (void)orderFrontDataLinkPanel:sender
{
}

- (void)orderFrontHelpPanel:sender
{
}

- (void)runPageLayout:sender
{
}

//
// Getting the main menu
//
- (NSMenu*) mainMenu
{
  return main_menu;
}

- (void) setMainMenu: (NSMenu*)aMenu
{
  unsigned i, j;
  NSMenuItem *mc;
  NSArray *mi;

  [aMenu retain];                                       // Release old menu and
  if (main_menu)                                        // retain new
    [main_menu release];
  main_menu = aMenu;

  mi = [main_menu itemArray];                           // find a menucell with
  j = [mi count];                                       // the title Windows
  windows_menu = nil;                                   // this is the default
  for (i = 0; i < j; ++i)                               // windows menu
    {
      mc = [mi objectAtIndex:i];
      if ([[mc stringValue] compare: @"Windows"] == NSOrderedSame)
        {
          windows_menu = mc;                            // Found it!
          break;
        }
    }
}

//
// Managing the Windows menu
//
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
  NSMenu        *menu;
  NSArray       *itemArray;
  unsigned      count;
  unsigned      i;
  id            item;

  if (![aWindow isKindOfClass: [NSWindow class]])
    [NSException raise: NSInvalidArgumentException
                format: @"Object of bad type passed as window"];

  /*
   *    If Menus are implemented as a subclass of window we must make sure
   *    to exclude them from the windows menu.
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
          id    item = [itemArray objectAtIndex: i];

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
   * Make special allowance for menu entries to 'arrangeInFront:'
   * 'performMiniaturize:' and 'preformClose:'.  If these exist the
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
  NSMenu        *menu;

  menu = [self windowsMenu];
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
      NSMenu	        *menu;
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
       * Now use [-changeWindowsItem:title:filename:] to build the new menu.
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
  NSMenu        *menu;

  menu = [self windowsMenu];
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
		  [[item controlView] sizeToFit];
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

//
// Managing the Service menu
//
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

- (GSContext *)context                              // return the current draw
{                                                   // context (drawing dest)
  return [GSContext currentContext];
}

- (void) reportException: (NSException *)anException
{                                                   // Reporting an exception
  if (anException)
    NSLog(@"reported exception - %@", anException);
}

//
// Terminating the application
//
- (void) terminate: (id)sender
{
  if ([self applicationShouldTerminate: self])
    {                                       // app should end run loop
      app_should_quit = YES;
      [event_queue addObject: null_event];          // add dummy event to queue
    }                                       // to assure loop cycles
}                                                   // at least one more time

- (id) delegate                                     // Assigning a delegate
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
  if ([delegate respondsToSelector:@selector(application##notif_name:)]) \
    [nc addObserver:delegate \
      selector:@selector(application##notif_name:) \
      name:NSApplication##notif_name##Notification object:self]

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

//
// Implemented by the delegate
//
- (BOOL)application:sender openFileWithoutUI:(NSString *)filename
{
BOOL result = NO;

  if ([delegate respondsToSelector:@selector(application:openFileWithoutUI:)])
    result = [delegate application:sender openFileWithoutUI:filename];

  return result;
}

- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename
{
BOOL result = NO;

  if ([delegate respondsToSelector:@selector(application:openFile:)])
    result = [delegate application:app openFile:filename];

  return result;
}

- (BOOL)application:(NSApplication *)app openTempFile:(NSString *)filename
{
BOOL result = NO;

  if ([delegate respondsToSelector:@selector(application:openTempFile:)])
    result = [delegate application:app openTempFile:filename];

  return result;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationDidBecomeActive:)])
    [delegate applicationDidBecomeActive:aNotification];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationDidFinishLaunching:)])
    [delegate applicationDidFinishLaunching:aNotification];
}

- (void)applicationDidHide:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationDidHide:)])
    [delegate applicationDidHide:aNotification];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationDidResignActive:)])
    [delegate applicationDidResignActive:aNotification];
}

- (void)applicationDidUnhide:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationDidUnhide:)])
    [delegate applicationDidUnhide:aNotification];
}

- (void)applicationDidUpdate:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationDidUpdate:)])
    [delegate applicationDidUpdate:aNotification];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)app
{
BOOL result = NO;

  if ([delegate respondsToSelector:@selector(applicationOpenUntitledFile:)])
    result = [delegate applicationOpenUntitledFile:app];

  return result;
}

- (BOOL)applicationShouldTerminate:sender
{
BOOL result = YES;

  if ([delegate respondsToSelector:@selector(applicationShouldTerminate:)])
    result = [delegate applicationShouldTerminate:sender];

  return result;
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationWillBecomeActive:)])
    [delegate applicationWillBecomeActive:aNotification];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationWillFinishLaunching:)])
    [delegate applicationWillFinishLaunching:aNotification];
}

- (void)applicationWillHide:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationWillHide:)])
    [delegate applicationWillHide:aNotification];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationWillResignActive:)])
    [delegate applicationWillResignActive:aNotification];
}

- (void)applicationWillUnhide:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationWillUnhide:)])
    [delegate applicationWillUnhide:aNotification];
}

- (void)applicationWillUpdate:(NSNotification *)aNotification
{
  if ([delegate respondsToSelector:@selector(applicationWillUpdate:)])
    [delegate applicationWillUpdate:aNotification];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeConditionalObject:key_window];
  [aCoder encodeConditionalObject:main_window];
  [aCoder encodeConditionalObject:delegate];
  [aCoder encodeObject:main_menu];
  [aCoder encodeConditionalObject:windows_menu];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  key_window = [aDecoder decodeObject];
  main_window = [aDecoder decodeObject];
  delegate = [aDecoder decodeObject];
  main_menu = [aDecoder decodeObject];
  windows_menu = [aDecoder decodeObject];
  return self;
}

+ (void)setNullEvent:(NSEvent *)e
{
  ASSIGN(null_event, e);
}

+ (NSEvent *)getNullEvent;
{                                                           // return the class
    return null_event;                                      // dummy event
}

- (void)_nextEvent                                          // get next event
{                                                           // implemented in
}                                                           // backend

- (void)setupRunLoopInputSourcesForMode:(NSString*)mode
{                                                           // implemented in
}                                                           // backend

@end /* NSApplication */

