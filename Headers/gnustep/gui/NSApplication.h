/* 
   NSApplication.h

   The one and only application class

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

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

#ifndef _GNUstep_H_NSApplication
#define _GNUstep_H_NSApplication

#include <AppKit/NSResponder.h>

@class NSArray;
@class NSMutableArray;
@class NSString;
@class NSException;
@class NSNotification;
@class NSDate;
@class NSTimer;

@class NSEvent;
@class NSPasteboard;
@class NSMenu;
@class NSMenuItem;
@class NSImage;
@class NSWindow;
@class NSGraphicsContext;

typedef struct _NSModalSession *NSModalSession;

enum {
  NSRunStoppedResponse,
  NSRunAbortedResponse,
  NSRunContinuesResponse
};

extern NSString	*NSModalPanelRunLoopMode;
extern NSString	*NSEventTrackingRunLoopMode;

@interface NSApplication : NSResponder <NSCoding>
{
  NSEvent		*current_event;
  NSModalSession	session;
  NSWindow		*_key_window;
  NSWindow		*_main_window;
  id			delegate;
  id			listener;
  NSMenu		*main_menu;
  NSMenuItem		*windows_menu;
  unsigned		current_mod;
  BOOL			app_is_running;
  BOOL			app_should_quit;
  BOOL			app_is_active;
  BOOL			app_is_hidden;
  BOOL			unhide_on_activation;
  BOOL			windows_need_update;
  NSImage		*app_icon;
  NSMutableArray	*_hidden;
  NSMutableArray	*_inactive;
  NSWindow		*_hidden_key;

  BOOL			inTrackingLoop;

  // Reserved for back-end use
  void *be_app_reserved;
}

/*
 * Class methods
 */

/*
 * Creating and initializing the NSApplication
 */
+ (NSApplication*) sharedApplication;

/*
 * Instance methods
 */

/*
 * Creating and initializing the NSApplication
 */
- (void) finishLaunching;

/*
 * Changing the active application
 */
- (void) activateIgnoringOtherApps: (BOOL)flag;
- (void) deactivate;
- (BOOL) isActive;

/*
 * Running the event loop
 */
- (void) abortModal;
- (NSModalSession) beginModalSessionForWindow: (NSWindow*)theWindow;
- (void) endModalSession: (NSModalSession)theSession;
- (BOOL) isRunning;
- (void) run;
- (int) runModalForWindow: (NSWindow*)theWindow;
- (int) runModalSession: (NSModalSession)theSession;
- (NSWindow *) modalWindow;
- (void) sendEvent: (NSEvent*)theEvent;
- (void) stop: (id)sender;
- (void) stopModal;
- (void) stopModalWithCode: (int)returnCode;

/*
 * Getting, removing, and posting events
 */
- (NSEvent*) currentEvent;
- (void) discardEventsMatchingMask: (unsigned)mask
		       beforeEvent: (NSEvent*)lastEvent;
- (NSEvent*) nextEventMatchingMask: (unsigned)mask
			 untilDate: (NSDate*)expiration
			    inMode: (NSString*)mode
			   dequeue: (BOOL)flag;
- (void) postEvent: (NSEvent*)event atStart: (BOOL)flag;

/*
 * Sending action messages
 */
- (BOOL) sendAction: (SEL)aSelector
		 to: (id)aTarget
	       from: (id)sender;
- (id) targetForAction: (SEL)aSelector;
- (BOOL) tryToPerform: (SEL)aSelector
		 with: (id)anObject;

/*
 * Setting the application's icon
 */
- (void) setApplicationIconImage: (NSImage*)anImage;
- (NSImage*) applicationIconImage;

/*
 * Hiding all windows
 */
- (void) hide: (id)sender;
- (BOOL) isHidden;
- (void) unhide: (id)sender;
- (void) unhideWithoutActivation;

/*
 * Managing windows
 */
- (NSWindow*) keyWindow;
- (NSWindow*) mainWindow;
- (NSWindow*) makeWindowsPerform: (SEL)aSelector
			 inOrder: (BOOL)flag;
- (void) miniaturizeAll: (id)sender;
- (void) preventWindowOrdering;
- (void) setWindowsNeedUpdate: (BOOL)flag;
- (void) updateWindows;
- (NSArray*) windows;
- (NSWindow*) windowWithWindowNumber: (int)windowNum;

/*
 * Showing Standard Panels
 */
- (void) orderFrontColorPanel: (id)sender;
- (void) orderFrontDataLinkPanel: (id)sender;
- (void) orderFrontHelpPanel: (id)sender;
- (void) runPageLayout: (id)sender;

/*
 * Getting the main menu
 */
- (NSMenu*) mainMenu;
- (void) setMainMenu: (NSMenu*)aMenu;

/*
 * Managing the Windows menu
 */
- (void) addWindowsItem: (NSWindow*)aWindow
		  title: (NSString*)aString
	       filename: (BOOL)isFilename;
- (void) arrangeInFront: (id)sender;
- (void) changeWindowsItem: (NSWindow*)aWindow
		     title: (NSString*)aString
		  filename: (BOOL)isFilename;
- (void) removeWindowsItem: (NSWindow*)aWindow;
- (void) setWindowsMenu: (NSMenu*)aMenu;
- (void) updateWindowsItem: (NSWindow*)aWindow;
- (NSMenu*) windowsMenu;

/*
 * Managing the Service menu
 */
- (void) registerServicesMenuSendTypes: (NSArray*)sendTypes
			   returnTypes: (NSArray*)returnTypes;
- (NSMenu*) servicesMenu;
- (id) servicesProvider;
- (void) setServicesMenu: (NSMenu*)aMenu;
- (void) setServicesProvider: (id)anObject;
- (id) validRequestorForSendType: (NSString*)sendType
		      returnType: (NSString*)returnType;

/*
 * Getting the display context
 */
- (NSGraphicsContext*) context;

/*
 * Reporting an exception
 */
- (void) reportException: (NSException*)anException;

/*
 * Terminating the application
 */
- (void) terminate: (id)sender;

/*
 * Assigning a delegate
 */
- (id) delegate;
- (void) setDelegate: (id)anObject;

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder;
- (id) initWithCoder: (NSCoder*)aDecoder;

@end

@interface NSObject (NSServicesRequests)

/*
 * Pasteboard Read/Write
 */
- (BOOL) readSelectionFromPasteboard: (NSPasteboard*)pboard;
- (BOOL) writeSelectionToPasteboard: (NSPasteboard*)pboard
                              types: (NSArray*)types;

@end


/* Backend functions */
extern BOOL initialize_gnustep_backend (void);

#ifndef	NO_GNUSTEP
/*
 * A formal protocol that duplicates the informal protocol for delegates.
 */
@protocol	GSAppDelegateProtocol
- (BOOL) application: (NSApplication*)app
   openFileWithoutUI: (NSString*)filename;
- (BOOL) application: (NSApplication*)app
	    openFile: (NSString*)filename;
- (BOOL) application: (NSApplication*)app
	openTempFile: (NSString*)filename;
- (void) applicationDidBecomeActive: (NSNotification*)aNotification;
- (void) applicationDidFinishLaunching: (NSNotification*)aNotification;
- (void) applicationDidHide: (NSNotification*)aNotification;
- (void) applicationDidResignActive: (NSNotification*)aNotification;
- (void) applicationDidUnhide: (NSNotification*)aNotification;
- (void) applicationDidUpdate: (NSNotification*)aNotification;
- (BOOL) applicationOpenUntitledFile: (NSApplication*)app;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillBecomeActive: (NSNotification*)aNotification;
- (void) applicationWillFinishLaunching: (NSNotification*)aNotification;
- (void) applicationWillHide: (NSNotification*)aNotification;
- (void) applicationWillResignActive: (NSNotification*)aNotification;
- (void) applicationWillUnhide: (NSNotification*)aNotification;
- (void) applicationWillUpdate: (NSNotification*)aNotification;
@end
#endif

/*
 * Notifications
 */
extern NSString	*NSApplicationDidBecomeActiveNotification;
extern NSString	*NSApplicationDidFinishLaunchingNotification;
extern NSString	*NSApplicationDidHideNotification;
extern NSString	*NSApplicationDidResignActiveNotification;
extern NSString	*NSApplicationDidUnhideNotification;
extern NSString	*NSApplicationDidUpdateNotification;
extern NSString	*NSApplicationWillBecomeActiveNotification;
extern NSString	*NSApplicationWillFinishLaunchingNotification;
extern NSString	*NSApplicationWillTerminateNotification;
extern NSString	*NSApplicationWillHideNotification;
extern NSString	*NSApplicationWillResignActiveNotification;
extern NSString	*NSApplicationWillUnhideNotification;
extern NSString	*NSApplicationWillUpdateNotification;

/*
 * Determine Whether an Item Is Included in Services Menus
 */
int
NSSetShowsServicesMenuItem(NSString *item, BOOL showService);

BOOL
NSShowsServicesMenuItem(NSString *item);

/*
 * Programmatically Invoke a Service
 */
BOOL
NSPerformService(NSString *item, NSPasteboard *pboard);

/*
 * Force Services Menu to Update Based on New Services
 */
void
NSUpdateDynamicServices(void);

/*
 * Register object to handle services requests.
 */
void
NSRegisterServicesProvider(id provider, NSString *name);

int
NSApplicationMain(int argc, const char **argv);

NSString*
NSOpenStepRootDirectory(void);

/*
 * The NSApp global variable.
 */
extern NSApplication	*NSApp;

#endif // _GNUstep_H_NSApplication
