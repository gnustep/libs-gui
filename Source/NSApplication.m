/* 
   NSApplication.m

   The one and only application class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
  
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
#include <AppKit/GNUServicesManager.h>
#include <AppKit/IMLoading.h>


#define CONVEY(a, b)	[b retain]; \
						[a release]; \
						a = b;
//
// Types
//
struct _NSModalSession {
  int		runState;
  NSWindow	*window;
  NSModalSession	previous;
};

//
// Class variables
//
static BOOL gnustep_gui_app_is_in_dealloc;
static NSEvent *null_event;                                     
static id NSApp;
static NSString	*NSAbortModalException = @"NSAbortModalException";



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
		gnustep_gui_app_is_in_dealloc = NO;			// it's within dealloc and
		}											// can prevent -release 
}													// loops.

+ (NSApplication *)sharedApplication
{											// If the global application does 
	if (!NSApp) 							// not yet exist then create it
		{
		NSApp = [self alloc];				// Don't combine the following two
		[NSApp init];						// statements into one to avoid
		}									// problems with some classes'
											// initialization code that tries
	return NSApp;							// to get the shared application.
}

//
// Instance methods
//
- init
{
	[super init];

	NSDebugLog(@"Begin of NSApplication -init\n");

	listener = [GNUServicesManager newWithApplication: self];
	window_list = [NSMutableArray new];					// allocate window list
	window_count = 1;

	main_menu = nil;
	windows_need_update = YES;
  
	event_queue = [NSMutableArray new];					// allocate event queue
	current_event = [NSEvent new];						// no current event
	null_event = [NSEvent new];							// create dummy event

	[self setNextResponder:NULL];						// We are the end of 
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
	[listener registerAsServiceProvider];			// requests etc.

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
	gnustep_gui_app_is_in_dealloc = YES;			// are within dealloc
	
	[listener release];
	[window_list release];
	[event_queue release];
	[current_event release];

	while (session != 0)							// We may need to tidy up 
		{											// nested modal session 
		NSModalSession tmp = session;				// structures.
	
		session = tmp->previous;
		NSZoneFree(NSDefaultMallocZone(), tmp);
		}

	[super dealloc];
}

//
// Changing the active application
//
- (void)activateIgnoringOtherApps:(BOOL)flag
{
    app_is_active = YES;
}

- (void)deactivate
{
	app_is_active = NO;
}

- (BOOL)isActive				{ return app_is_active; }

//
// Running the main event loop
//
- (void)run
{
NSEvent *e;
NSAutoreleasePool* pool;

	NSDebugLog(@"NSApplication -run\n");

	[self finishLaunching];

	app_should_quit = NO;
	app_is_running = YES;

	do	{
		pool = [NSAutoreleasePool new];				

		e = [self nextEventMatchingMask:NSAnyEventMask			
				  untilDate:[NSDate distantFuture]				
				  inMode:NSDefaultRunLoopMode 
				  dequeue:YES];
		if (e)
			[self sendEvent: e];

		if(windows_need_update)						// send an update message
			[self updateWindows];					// to all visible windows
									
		[listener updateServicesMenu]; 				// update (en/disable) the 
													// services menu's items
		[pool release];
		} 
	while (!app_should_quit);

	NSDebugLog(@"NSApplication end of run loop\n");
}

- (BOOL)isRunning
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
					 format:@"abortModal called while not in a modal session"];

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

	while (tmp && tmp != theSession)				// Remove this session from 
		tmp = tmp->previous;						// linked list of sessions.

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

	do {												// First we make sure 
		count = [event_queue count];					// that there is an 
		for (i = 0; i < count; i++)						// event.
			{
			event = [event_queue objectAtIndex: 0];
			if ([event window] == theSession->window)
				{
				found = YES;
				break;
				}
			else										// dump events not for 
				[event_queue removeObjectAtIndex:0];	// the modal window
			}

		if (found == NO)
			{
			NSDate *limitDate = [NSDate distantFuture];

			[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
										beforeDate: limitDate];
			}
		}
	while (found == NO && theSession->runState == NSRunContinuesResponse);

														// Deal with the events
														// in the queue.
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

			if (windows_need_update)
				[self updateWindows];
							/* xxx should we update the services menu? */
			[listener updateServicesMenu];
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
	if (theEvent == null_event)						// Don't send null event
		{
		NSDebugLog(@"Not sending the Null Event\n");
		return;
		}

	switch ([theEvent type])						// determine the event type					
		{
		case NSPeriodic:							// NSApplication traps the 
			break;									// periodic events

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

		case NSRightMouseDown:								// Right mouse down
			if(main_menu)
				{
				static NSMenu *copyOfMainMenu = nil;
				NSWindow *copyMenuWindow;
																	
				if(!copyOfMainMenu)							// display the menu
					copyOfMainMenu = [main_menu copy];		// under the mouse
				copyMenuWindow = [copyOfMainMenu menuWindow];
				[copyOfMainMenu _rightMouseDisplay];
				[copyMenuWindow captureMouse:self];
				[[copyOfMainMenu menuCells] mouseDown:theEvent];
				[copyMenuWindow releaseMouse:self];
				}
			break;

		default:									// pass all other events to 
			{										// the event's window
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

- (NSEvent *)currentEvent;
{
	return current_event;
}

- (void)discardEventsMatchingMask:(unsigned int)mask
					  beforeEvent:(NSEvent *)lastEvent
{
int i = 0, count, loop;
NSEvent* event = nil;
BOOL match;										
														// if queue contains
	if ((count = [event_queue count])) 					// events check them  
		{												
		for (loop = 0; ((event != lastEvent) && (loop < count)); loop++) 
			{											
			event = [event_queue objectAtIndex:i];		// Get next event from
			match = NO;									// the events queue

			if (mask == NSAnyEventMask)					// the any event mask
				match = YES;							// matches all events		
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
				}	}									// remove event from
														// the queue if it 
			if (match) 									// matched the mask
				[event_queue removeObjectAtIndex:i];
			else										// inc queue cntr only
				i++;									// if not a match else
			}											// we will run off the
		}												// end of the queue
}

- (NSEvent*)_eventMatchingMask:(unsigned int)mask dequeue:(BOOL)flag		 
{														
NSEvent* event;											// return the next
int i, count;											// event in the queue
BOOL match = NO;										// which matches mask

	[self _nextEvent];

	if ((count = [event_queue count])) 					// if queue contains  
		{												// events check them
		for (i = 0; i < count; i++) 
			{											// Get next event from
			event = [event_queue objectAtIndex:i];		// the events queue

    		if (mask == NSAnyEventMask)					// the any event mask
				match = YES;							// matches all events		
			else
				{
    			if (event == null_event) 				// do not send the null
					{									// event
					match = NO;							 
					if(flag)							// dequeue null event
						{								// if flag is set
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
				}	}	}
						
			if (match) 
				{
				if(flag)								// dequeue the event if
					{									// flag is set
					[event retain];
					[event_queue removeObjectAtIndex:i];
					}									
				CONVEY(current_event, event);			 
		
				return event;							// return an event from
      			}										// the queue which 
    		}											// matches the mask
  		}
														// no event in the
	return nil;											// queue matches mask 
}                                                       

- (NSEvent*) nextEventMatchingMask:(unsigned int)mask
						 untilDate:(NSDate *)expiration
						 inMode:(NSString *)mode
						 dequeue:(BOOL)flag
{
NSEvent *event;
BOOL done = NO;

	if(mode == NSEventTrackingRunLoopMode)				// temporary hack to
		inTrackingLoop = YES;							// regulate translation 
	else												// of X motion events
		inTrackingLoop = NO;							// while not in a 
														// tracking loop
	if ((event = [self _eventMatchingMask:mask dequeue:flag]))
		done = YES;
	else 
		if (!expiration)
			expiration = [NSDate distantFuture];

	while (!done) 										// Not in queue so wait
		{												// for next event
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
	if (!inTrackingLoop)							// while in a tracking loop
		{											
		if ([NSCursor isHiddenUntilMouseMoves])		// do so only if we should
			{		 								// unhide when mouse moves
			NSEventType type = [event type];		// and event is mouse event
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
- (BOOL)sendAction:(SEL)aSelector to:aTarget from:sender
{														// If target responds 
	if ([aTarget respondsToSelector:aSelector])			// to the selector then
		{												// have it perform it
		[aTarget performSelector:aSelector withObject:sender];

		return YES;
		}

	return NO;											// Otherwise traverse 
}												

- targetForAction:(SEL)aSelector
{
	return self;
}

- (BOOL)tryToPerform:(SEL)aSelector with:anObject
{
	return NO;
}

- (void)setApplicationIconImage:(NSImage *)anImage
{														// Set the app's icon
    if (app_icon != nil)
        [app_icon release];

    app_icon = [anImage retain];
}

- (NSImage *)applicationIconImage
{
	return app_icon;
}

//
// Hiding and arranging windows
//
- (void)hide:sender
{
int i, count;
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

													// notify that we will hide
	[nc postNotificationName: NSApplicationWillHideNotification
		object: self];
													// TODO: hide the menu

													// Tell the windows to hide
	for (i = 0, count = [window_list count]; i < count; i++)
//		[[window_list objectAtIndex:i] performHide:sender];
		[[window_list objectAtIndex:i] orderOut:sender];

	app_is_hidden = YES;
													// notify that we did hide
	[nc postNotificationName: NSApplicationDidHideNotification
		object: self];
}

- (BOOL)isHidden
{
	return app_is_hidden;
}

- (void)unhide:sender
{
int i, count;
													// Tell windows to unhide
	for (i = 0, count = [window_list count]; i < count; i++)
//		[[window_list objectAtIndex:i] performUnhide:sender];
		[[window_list objectAtIndex:i] orderFront:sender];

													// TODO: unhide the menu

	app_is_hidden = NO;
													// Bring the key window to
	[[self keyWindow] makeKeyAndOrderFront:self];	// the front
}

- (void)unhideWithoutActivation
{
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
													// notify we will unhide
  [nc postNotificationName: NSApplicationWillUnhideNotification
      object: self];

  [self unhide: self];
													// notify we did unhide
  [nc postNotificationName: NSApplicationDidUnhideNotification
      object: self];
}

- (void)arrangeInFront:sender						// preliminary FIX ME
{
int i, count;
													// Tell windows to unhide
	for (i = 0, count = [window_list count]; i < count; i++)
		[[window_list objectAtIndex:i] orderFront:sender];
}

//
// Managing windows
//
- (NSWindow *)keyWindow
{
int i, j;
id w;

	j = [window_list count];
	for (i = 0;i < j; ++i)
		{
		w = [window_list objectAtIndex:i];
		if ([w isKeyWindow]) 
			return w;
		}

	return nil;
}

- (NSWindow *)mainWindow
{
int i, j;
id w;

	j = [window_list count];
	for (i = 0;i < j; ++i)
		{
		w = [window_list objectAtIndex:i];
		if ([w isMainWindow]) 
			return w;
		}

	return nil;
}

- (NSWindow *)makeWindowsPerform:(SEL)aSelector inOrder:(BOOL)flag
{
	return nil;
}

- (void)miniaturizeAll:sender
{
int i, count;

	for (i = 0, count = [window_list count]; i < count; i++)
		[[window_list objectAtIndex:i] miniaturize:sender];
}

- (void)preventWindowOrdering
{
}

- (void)setWindowsNeedUpdate:(BOOL)flag
{
	windows_need_update = flag;
}

- (void)updateWindows								// send an update message
{													// to all visible windows
int i, count;									
NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  													// notify that an update is 
													// imminent
	[nc postNotificationName:NSApplicationWillUpdateNotification object:self];

	for (i = 0, count = [window_list count]; i < count; i++)
		{
		NSWindow *win = [window_list objectAtIndex:i];
		if([win isVisible])							// send update only if the
    		[win update];							// window is visible
		}
  													// notify update did occur
	[nc postNotificationName:NSApplicationDidUpdateNotification object:self];
}

- (NSArray *)windows
{
	return window_list;
}

- (NSWindow *)windowWithWindowNumber:(int)windowNum
{
int i, j;
NSWindow *w;

	j = [window_list count];
	for (i = 0;i < j; ++i)
		{
		w = [window_list objectAtIndex:i];
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
- (NSMenu *)mainMenu
{
	return main_menu;
}

- (void)setMainMenu:(NSMenu *)aMenu
{
int i, j;
NSMenuItem *mc;
NSArray *mi;

	[aMenu retain];										// Release old menu and 
	if(main_menu)										// retain new
		[main_menu release];
	main_menu = aMenu;

	mi = [main_menu itemArray];							// find a menucell with
	j = [mi count];										// the title Windows
	windows_menu = nil;									// this is the default
	for (i = 0;i < j; ++i)								// windows menu
		{
		mc = [mi objectAtIndex:i];
		if ([[mc stringValue] compare:@"Windows"] == NSOrderedSame)
			{
			windows_menu = mc;							// Found it!
			break;
			}
		}
}

//
// Managing the Windows menu
//
- (void)addWindowsItem:aWindow
				 title:(NSString *)aString
				 filename:(BOOL)isFilename
{
int i;

	if (![aWindow isKindOfClass:[NSWindow class]])	// proceed only if subclass
		return;										// of window

	i = [window_list count];						// Add to our window list,
	[window_list addObject:aWindow];				// the array retains it

	[aWindow setWindowNumber:window_count];			// set its window number
	++window_count;
	
	if (i == 0)										// If this was the first 
		{											// window then make it the
		[aWindow becomeMainWindow];					// main and key window
		[aWindow becomeKeyWindow];
		}
}

- (void)changeWindowsItem:aWindow 
					title:(NSString *)aString 
					filename:(BOOL)isFilename
{
}

- (void)removeWindowsItem:aWindow
{
	if (aWindow == key_window)						// This should be different
		key_window = nil;
	if (aWindow == main_window)
		main_window = nil;

				// If we are within our dealloc then don't remove the window
				// Most likely dealloc is removing windows from our window list
				// and subsequently NSWindow is caling us to remove itself.
	if (gnustep_gui_app_is_in_dealloc)
		return;
													// Remove window from the 
	[window_list removeObject: aWindow];			// window list

	return;
}

- (void)setWindowsMenu:aMenu
{
	if (windows_menu)
		[windows_menu setSubmenu:aMenu];
}

- (void)updateWindowsItem:aWindow
{
}

- (NSMenu *)windowsMenu
{
	if(windows_menu)
		return [windows_menu submenu];
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

- (GSContext *)context								// return the current draw
{													// context (drawing dest)
    return [GSContext currentContext];
}

- (void) reportException: (NSException *)anException
{													// Reporting an exception
	if (anException)
		NSLog(@"reported exception - %@", anException);
}

//
// Terminating the application
//
- (void)terminate:sender
{
	if ([self applicationShouldTerminate:self])
		{											// app should end run loop
		app_should_quit = YES;
		[event_queue addObject: null_event];		// add dummy event to queue
		}											// to assure loop cycles
}													// at least one more time

- delegate											// Assigning a delegate
{
	return delegate;
}

- (void)setDelegate:anObject
{
NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

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

  [aCoder encodeObject: window_list];
  [aCoder encodeConditionalObject:key_window];
  [aCoder encodeConditionalObject:main_window];
  [aCoder encodeConditionalObject:delegate];
  [aCoder encodeObject:main_menu];
  [aCoder encodeConditionalObject:windows_menu];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  window_list = [aDecoder decodeObject];
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
{															// return the class
	return null_event;										// dummy event
}

- (void)_nextEvent											// get next event	
{															// implemented in
}															// backend

- (void)setupRunLoopInputSourcesForMode:(NSString*)mode
{															// implemented in
}															// backend

@end /* NSApplication */


/* Some utilities */
NSString *NSOpenStepRootDirectory(void)
{
NSString* root = [[[NSProcessInfo processInfo] environment]
                    objectForKey:@"GNUSTEP_SYSTEM_ROOT"];

    if (!root)
        root = @"/";

    return root;
}
