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
#include <Foundation/NSNotification.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSConnection.h>
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

#include <AppKit/IMLoading.h>

#define CONVEY(a, b)	[b retain]; \
						[a release]; \
						a = b;


//*****************************************************************************
//
// 		ApplicationListener 
//
//*****************************************************************************

extern NSDictionary *GSAllServicesDictionary();

/*
 *      Local class for handling incoming service requests etc.
 */
@interface      ApplicationListener : NSObject
{
  id                    servicesProvider;
  NSApplication         *application;
  NSMenu                *servicesMenu;
  NSMutableArray        *languages;
  NSMutableSet          *returnInfo;
  NSMutableDictionary   *combinations;
  NSMutableDictionary   *title2info;
  NSArray               *menuTitles;
  BOOL                  isRegistered;
}
+ (ApplicationListener*) newWithApplication: (NSApplication*)app;
- (void) doService: (NSCell*)item;
- (BOOL) hasRegisteredTypes: (NSDictionary*)service;
- (NSString*) item2title: (NSCell*)item;
- (void) rebuildServices;
- (void) rebuildServicesMenu;
- (void) registerAsServiceProvider;
- (void) registerSendTypes: (NSArray *)sendTypes
               returnTypes: (NSArray *)returnTypes;
- (NSMenu *) servicesMenu;
- (id) servicesProvider;
- (void) setServicesMenu: (NSMenu *)anObject;
- (void) setServicesProvider: (id)anObject;
- (BOOL) validateMenuItem: (NSCell*)item;
- (void) updateServicesMenu;
@end

@implementation ApplicationListener
/*
 *      Create a new listener for this application.
 *      Uses NSRegisterServicesProvider() to register itsself as a service
 *      provider with the applications name so we can handle incoming
 *      service requests.
 */
+ (ApplicationListener*) newWithApplication: (NSApplication*)app
{
  ApplicationListener   *listener = [ApplicationListener alloc];

  /*
   *    Don't retain application object - that would reate a cycle.
   */
  listener->application = app;
  listener->returnInfo = [[NSMutableSet alloc] initWithCapacity: 16];
  listener->combinations = [[NSMutableDictionary alloc] initWithCapacity: 16];
  return listener;
}

- (void) doService: (NSCell*)item
{
  NSString      *title = [self item2title: item];
  NSDictionary  *info = [title2info objectForKey: title];
  NSArray       *sendTypes = [info objectForKey: @"NSSendTypes"];
  NSArray       *returnTypes = [info objectForKey: @"NSReturnTypes"];
  unsigned      i, j;
  unsigned      es = [sendTypes count];
  unsigned      er = [returnTypes count];
  NSWindow      *resp = [[application keyWindow] firstResponder];
  id            obj = nil;

  for (i = 0; i <= es; i++)
    {
      NSString  *sendType;

      sendType = (i < es) ? [sendTypes objectAtIndex: i] : nil;

      for (j = 0; j <= er; j++)
        {
          NSString      *returnType;

          returnType = (j < er) ? [returnTypes objectAtIndex: j] : nil;

          obj = [resp validRequestorForSendType: sendType
                                     returnType: returnType];
          if (obj != nil)
            {
              NSPasteboard      *pb;

              pb = [NSPasteboard pasteboardWithUniqueName];
              if ([obj writeSelectionToPasteboard: pb
                                            types: sendTypes] == NO)
                {
                  NSLog(@"object failed to write to pasteboard\n");
                }
              else if (NSPerformService(title, pb) == NO)
                {
                  NSLog(@"Failed to perform %@\n", title);
                }
              else if ([obj readSelectionFromPasteboard: pb] == NO)
                {
                  NSLog(@"object failed to read from pasteboard\n");
                }
              return;
            }
        }
    }
}

- (BOOL) hasRegisteredTypes: (NSDictionary*)service
{
  NSArray       *sendTypes = [service objectForKey: @"NSSendTypes"];
  NSArray       *returnTypes = [service objectForKey: @"NSReturnTypes"];
  NSString      *type;
  unsigned      i;

  /*
   *    We know that both sendTypes and returnTypes can't be nil since
   *    make_services has validated the service entry for us.
   */
  if (sendTypes == nil || [sendTypes count] == 0)
    {
      for (i = 0; i < [returnTypes count]; i++)
        {
          type = [returnTypes objectAtIndex: i];
          if ([returnInfo member: type] != nil)
            {
              return YES;
            }
        }
    }
  else if (returnTypes == nil || [returnTypes count] == 0)
    {
      for (i = 0; i < [sendTypes count]; i++)
        {
          type = [sendTypes objectAtIndex: i];
          if ([combinations objectForKey: type] != nil)
            {
              return YES;
            }
        }
    }
  else
    {
      for (i = 0; i < [sendTypes count]; i++)
        {
          NSSet *rset;

          type = [sendTypes objectAtIndex: i];
          rset = [combinations objectForKey: type];
          if (rset != nil)
            {
              unsigned  j;

              for (j = 0; j < [returnTypes count]; j++)
                {
                  type = [returnTypes objectAtIndex: j];
                  if ([rset member: type] != nil)
                    {
                      return YES;
                    }
                }
            }
        }
    }
  return NO;
}

/*
 *      Use tag in menu cell to identify slot in menu titles array that
 *      contains the full title of the service.
 *      Return nil if this is not one of our service menu cells.
 */
- (NSString*) item2title: (NSCell*)item
{
  unsigned      pos;

  if ([item target] != self)
    return nil;
  pos = [item tag];
  if (pos > [menuTitles count])
    return nil;
  return [menuTitles objectAtIndex: pos];
}


- (void) dealloc
{
  NSRegisterServicesProvider(nil, nil);
  [languages release];
  [servicesProvider release];
  [returnInfo release];
  [combinations release];
  [title2info release];
  [menuTitles release];
  [servicesMenu release];
  [super dealloc];
}

- forward: (SEL)aSel :(arglist_t)frame
{
  NSString      *selName = NSStringFromSelector(aSel);

  /*
   *    If the selector matches the correct form for a services request,
   *    send the message to the services provider - otherwise raise an
   *    exception to say the method is not implemented.
   */
  if ([selName hasSuffix: @":userData:error:"])
    return [servicesProvider performv: aSel :frame];
  else
    return [self notImplemented: aSel];
}

- (void) rebuildServices
{
  NSDictionary          *services;
  NSUserDefaults        *defs;
  NSMutableArray        *newLang;
  NSSet                 *disabled;
  NSMutableSet          *alreadyFound;
  NSMutableDictionary   *newServices;
  unsigned              pos;

  /*
   *    If the application has not yet started up fully and registered us,
   *    we defer the rebuild intil we are registered.  This avoids loads
   *    of successive rebuilds as responder classes register the types they
   *    can handle on startup.
   */
  if (isRegistered == NO)
    return;

  defs = [NSUserDefaults standardUserDefaults];
  newLang = [[[defs arrayForKey: @"Languages"] mutableCopy] autorelease];
  if (newLang == nil)
    {
      newLang = [NSMutableArray arrayWithCapacity: 1];
    }
  if ([newLang containsObject:  @"default"] == NO)
    {
      [newLang addObject: @"default"];
    }
  ASSIGN(languages, newLang);

  disabled = [NSSet setWithArray: [defs arrayForKey: @"DisabledServices"]];
  services = [GSAllServicesDictionary() objectForKey: @"ByService"];

  newServices = [NSMutableDictionary dictionaryWithCapacity: 16];
  alreadyFound = [NSMutableSet setWithCapacity: 16];

  /*
   *    Build dictionary of services we can use.
   *    1. make sure we make dictionary keyed on preferred menu item language
   *    2. don't include entries for services already examined.
   *    3. don't include entries for menu items specifically disabled.
   *    4. don't include entries for which we have no registered types.
   */
  for (pos = 0; pos < [languages count]; pos++)
    {
      NSDictionary      *byLanguage;

      byLanguage = [services objectForKey: [languages objectAtIndex: pos]];
      if (byLanguage != nil)
        {
          NSEnumerator  *enumerator = [byLanguage keyEnumerator];
          NSString      *menuItem;

          while ((menuItem = [enumerator nextObject]) != nil)
            {
              NSDictionary      *service = [byLanguage objectForKey: menuItem];

              if ([alreadyFound member: service] != nil)
                continue;

              [alreadyFound addObject: service];

              if ([disabled member: menuItem] != nil)
                continue;

              if ([self hasRegisteredTypes: service])
                [newServices setObject: service forKey: menuItem];
            }
        }
    }
  if ([newServices isEqual: title2info] == NO)
    {
      NSArray   *titles;

      ASSIGN(title2info, newServices);
      titles = [title2info allKeys];
      titles = [titles sortedArrayUsingSelector: @selector(compare:)];
      ASSIGN(menuTitles, titles);
      [self rebuildServicesMenu];
    }
}

- (void) rebuildServicesMenu
{
  if (isRegistered && servicesMenu)
    {
      NSArray           *itemArray;
      NSMutableSet      *keyEquivalents;
      unsigned          pos;
      unsigned          loc0;
      unsigned          loc1;
      SEL               sel = @selector(doService:);
      NSMenu            *submenu = nil;

      itemArray = [[servicesMenu itemArray] retain];
      pos = [itemArray count];
      while (pos > 0)
        {
          [servicesMenu removeItem: [itemArray objectAtIndex: --pos]];
        }
      [itemArray release];

      keyEquivalents = [NSMutableSet setWithCapacity: 4];
      for (loc0 = pos = 0; pos < [menuTitles count]; pos++)
        {
          NSString      *title = [menuTitles objectAtIndex: pos];
          NSString      *equiv = @"";
          NSDictionary  *info = [title2info objectForKey: title];
          NSDictionary  *titles;
          NSDictionary  *equivs;
          NSRange       r;
          unsigned      lang;
          id<NSMenuItem>        item;

          /*
           *    Find the key equivalent corresponding to this menu title
           *    in the service definition.
           */
          titles = [info objectForKey: @"NSMenuItem"];
          equivs = [info objectForKey: @"NSKeyEquivalent"];
          for (lang = 0; lang < [languages count]; lang++)
            {
              NSString  *language = [languages objectAtIndex: lang];
              NSString  *t = [titles objectForKey: language];

              if ([t isEqual: title])
                {
                  equiv = [equivs objectForKey: language]; 
                }
            }

          /*
           *    Make a note that we are using the key equivalent, or
           *    set to nil if we have already used it in this menu.
           */
          if (equiv)
            {
              if ([keyEquivalents member: equiv] == nil)
                {
                  [keyEquivalents addObject: equiv];
                }
              else
                {
                  equiv = @"";
                }
            }

          r = [title rangeOfString: @"/"];
          if (r.length > 0)
            {
              NSString  *subtitle = [title substringFromIndex: r.location+1];
              NSString  *parentTitle = [title substringToIndex: r.location];
              NSMenu    *menu;

              item = [servicesMenu itemWithTitle: parentTitle];
              if (item == nil)
                {
                  loc1 = 0;
                  item = [servicesMenu insertItemWithTitle: parentTitle
                                                    action: 0
                                             keyEquivalent: @""
                                                   atIndex: loc0++];
                  menu = [[NSMenu alloc] initWithTitle: parentTitle];
                  [servicesMenu setSubmenu: submenu
                                   forItem: item];
                }
              else
                {
                  menu = (NSMenu*)[item target];
                }
              if (menu != submenu)
                {
                  [submenu sizeToFit];
                  submenu = menu;
                }
              item = [submenu insertItemWithTitle: subtitle
                                           action: sel
                                    keyEquivalent: equiv
                                          atIndex: loc1++];
              [item setTarget: self];
              [item setTag: pos];
            }
          else
            {
              item = [servicesMenu insertItemWithTitle: title
                                                action: sel
                                         keyEquivalent: equiv
                                               atIndex: loc0++];
              [item setTarget: self];
              [item setTag: pos];
            }
        }
      [submenu sizeToFit];
      [servicesMenu sizeToFit];
      [servicesMenu update];
    }
}

/*
 *      Set up connection to listen for incoming service requests.
 */
- (void) registerAsServiceProvider
{
  if (isRegistered == NO)
    {
      NSString          *appName;

      isRegistered = YES;
      [self rebuildServices];
      appName = [[[NSProcessInfo processInfo] processName] lastPathComponent];
      NSRegisterServicesProvider(self, appName);
    }
}

/*
 * Register send and return types that an object can handle - we keep
 * a note of all the possible combinations -
 * 'returnInfo' is a set of all the return types that can be handled
 * without a send.
 * 'combinations' is a dictionary of all send types, with the assciated
 * values being sets of possible return types.
 */
- (void) registerSendTypes: (NSArray *)sendTypes
               returnTypes: (NSArray *)returnTypes
{
  BOOL          didChange = NO;
  unsigned      i;

  for (i = 0; i < [sendTypes count]; i++)
    {
      NSString          *sendType = [sendTypes objectAtIndex: i];
      NSMutableSet      *returnSet = [combinations objectForKey: sendType];

      if (returnSet == nil)
        {
          returnSet = [NSMutableSet setWithCapacity: [returnTypes count]];
          [combinations setObject: returnSet forKey: sendType];
          [returnSet addObjectsFromArray: returnTypes];
          didChange = YES;
        }
      else
        {
          unsigned      count = [returnSet count];

          [returnSet addObjectsFromArray: returnTypes];
          if ([returnSet count] != count)
            {
              didChange = YES;
            }
        }
    }

  i = [returnInfo count];
  [returnInfo addObjectsFromArray: returnTypes];
  if ([returnInfo count] != i)
    {
      didChange = YES;
    }

  if (didChange)
    {
      [self rebuildServices];
    }
}

- (NSMenu*) servicesMenu
{
  return servicesMenu;
}

- (id) servicesProvider
{
  return servicesProvider;
}

- (void) setServicesMenu: (NSMenu*)aMenu
{
  ASSIGN(servicesMenu, aMenu);
  [self rebuildServicesMenu];
}

- (void) setServicesProvider: (id)anObject
{
  ASSIGN(servicesProvider, anObject);
}

- (BOOL) validateMenuItem: (NSCell*)item
{
  NSString      *title = [self item2title: item];
  NSDictionary  *info = [title2info objectForKey: title];
  NSArray       *sendTypes = [info objectForKey: @"NSSendTypes"];
  NSArray       *returnTypes = [info objectForKey: @"NSReturnTypes"];
  unsigned      i, j;
  unsigned      es = [sendTypes count];
  unsigned      er = [returnTypes count];
  NSWindow      *resp = [[application keyWindow] firstResponder];

  /*
   *    If the menu item is not in our map, it must be the cell containing
   *    a sub-menu - so we see if any cell in the submenu is valid.
   */
  if (title == nil)
    {
      NSMenu    *sub = [item target];

      if (sub && [sub isKindOfClass: [NSMenu class]])
        {
          NSArray       *a = [sub itemArray];

          for (i = 0; i < [a count]; i++)
            {
              if ([self validateMenuItem: [a objectAtIndex: i]] == YES)
                {
                  return YES;
                }
            }
        }
      return NO;
    }

  /*
   *    The cell corresponds to one of our services - so we check to see if
   *    there is anything that can deal with it.
   */
  for (i = 0; i <= es; i++)
    {
      NSString  *sendType;

      sendType = (i < es) ? [sendTypes objectAtIndex: i] : nil;

      for (j = 0; j <= er; j++)
        {
          NSString      *returnType;

          returnType = (j < er) ? [returnTypes objectAtIndex: j] : nil;

          if ([resp validRequestorForSendType: sendType
                                   returnType: returnType] != nil)
            {
              return YES;
            }
        }
    }
  return NO;
}

- (void) updateServicesMenu
{
  if (servicesMenu)
    {
      NSArray   *a = [servicesMenu itemArray];
      unsigned  i;

      for (i = 0; i < [a count]; i++)
        {
          NSCell        *cell = [a objectAtIndex: i];

          if ([self validateMenuItem: cell] == YES)
            {
              [cell setEnabled: YES];
            }
        }
    }
}

@end /* ApplicationListener */

//*****************************************************************************
//
// 		NSApplication 
//
//*****************************************************************************

//
// Class variables
//
static BOOL gnustep_gui_app_is_in_dealloc;
static NSEvent *null_event;                                     
static id NSApp;

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
		gnustep_gui_app_is_in_dealloc = NO;			// its within dealloc and
		}											// can prevent -release 
}													// loops.

+ (NSApplication *)sharedApplication
{											// If the global application does 
	if (!NSApp) 							// not exist yet then create it
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

//
// Creating and initializing the NSApplication
//
- init
{
	[super init];

	NSDebugLog(@"Begin of NSApplication -init\n");

	listener = [ApplicationListener newWithApplication: self];
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

- (void)dealloc
{
	NSDebugLog(@"Freeing NSApplication\n");
													// Let ourselves know we 
	gnustep_gui_app_is_in_dealloc = YES;			// are within dealloc
	
	[listener release];
	[window_list release];
	[event_queue release];
	[current_event release];
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

- (BOOL)isActive
{
	return app_is_active;
}

//
// Running the event loop
//
- (void)abortModal
{
}

- (NSModalSession)beginModalSessionForWindow:(NSWindow *)theWindow
{
	return NULL;
}

- (void)endModalSession:(NSModalSession)theSession
{
}

- (BOOL)isRunning
{
	return app_is_running;
}

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

- (int)runModalForWindow:(NSWindow *)theWindow
{
	[theWindow display];
	[theWindow makeKeyAndOrderFront: self];

	return 0;
}

- (int)runModalSession:(NSModalSession)theSession
{
	return 0;
}

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

- (void)stop:sender
{
	app_is_running = NO;
}

- (void)stopModal
{
}

- (void)stopModalWithCode:(int)returnCode
{
}

//
// Getting, removing, and posting events
//

- (NSEvent *)currentEvent;
{
	return current_event;
}

- (void)discardEventsMatchingMask:(unsigned int)mask
					  beforeEvent:(NSEvent *)lastEvent
{
int i = 0, count;
NSEvent* event = nil;
BOOL match = NO;										

	count = [event_queue count];
	event = [event_queue objectAtIndex:i];
	while((event != lastEvent) && (i < count))						
		{
		if (mask == NSAnyEventMask)						// any event is a match
			match = YES;									
		else
			{
			if (event == null_event) 
				match = YES;							// dump all null events 
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
			}	}	}									// remove event from
														// the queue if it 
		if (match) 										// matched the mask
			[event_queue removeObjectAtIndex:i];		
		event = [event_queue objectAtIndex:++i];		// get the next event
    	};												// in the queue
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
// Hiding all windows
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
		[[window_list objectAtIndex:i] performHide:sender];

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
		[[window_list objectAtIndex:i] performUnhide:sender];

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

- (void)arrangeInFront:sender
{
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
