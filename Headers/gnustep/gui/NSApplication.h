/** 
   NSApplication.h

   The one and only application class

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
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
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    AutogsdocSource: NSApplication.m
    AutogsdocSource: GSServicesManager.m

*/ 

#ifndef _GNUstep_H_NSApplication
#define _GNUstep_H_NSApplication

#include <AppKit/NSResponder.h>

@class NSArray;
@class NSAutoreleasePool;
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

@class GSInfoPanel;

typedef struct _NSModalSession *NSModalSession;

enum {
  NSRunStoppedResponse,
  NSRunAbortedResponse,
  NSRunContinuesResponse
};

#ifndef STRICT_OPENSTEP
#define NSUpdateWindowsRunLoopOrdering 600000

typedef enum {
  NSTerminateCancel = NO,
  NSTerminateNow = YES, 
  NSTerminateLater
} NSApplicationTerminateReply;

typedef enum {
  NSCriticalRequest,
  NSInformationalRequest
} NSRequestUserAttentionType;

#define NSAppKitVersionNumber10_0 0
#endif

APPKIT_EXPORT NSString	*NSModalPanelRunLoopMode;
APPKIT_EXPORT NSString	*NSEventTrackingRunLoopMode;

@interface NSApplication : NSResponder <NSCoding>
{
  NSGraphicsContext	*_default_context;
  NSEvent		*_current_event;
  NSModalSession	_session;
  NSWindow		*_key_window;
  NSWindow		*_main_window;
  id			_delegate;
  id			_listener;
  NSMenu		*_main_menu;
  NSMenu		*_windows_menu;
  // 5 bits
  BOOL			_app_is_running;
  BOOL			_app_is_active;
  BOOL			_app_is_hidden;
  BOOL			_unhide_on_activation;
  BOOL			_windows_need_update;
  NSImage		*_app_icon;
  NSWindow		*_app_icon_window;
  NSMutableArray	*_hidden;
  NSMutableArray	*_inactive;
  NSWindow		*_hidden_key;
  GSInfoPanel           *_infoPanel;

  /* This autorelease pool should only be created and used by -run, with
     a single exception (which is why it is stored here as an ivar): the
     -terminate: method will destroy this autorelease pool before exiting
     the program.  */
  NSAutoreleasePool     *_runLoopPool;
}

/*
 * Class methods
 */

#ifndef STRICT_OPENSTEP
+ (void) detachDrawingThread: (SEL)selector 
		    toTarget: (id)target 
		  withObject: (id)argument;
#endif

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
#ifndef STRICT_OPENSTEP
- (void) hideOtherApplications: (id)sender;
- (void) unhideAllApplications: (id)sender;
#endif

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

#ifndef STRICT_OPENSTEP
- (int) runModalForWindow: (NSWindow *)theWindow
	relativeToWindow: (NSWindow *)docWindow;
- (void) beginSheet: (NSWindow *)sheet
     modalForWindow: (NSWindow *)docWindow
      modalDelegate: (id)modalDelegate
     didEndSelector: (SEL)didEndSelector
	contextInfo: (void *)contextInfo;
- (void) endSheet: (NSWindow *)sheet;
- (void) endSheet: (NSWindow *)sheet
       returnCode: (int)returnCode;
#endif

/*
 * Getting, removing, and posting events
 */
- (NSEvent*) currentEvent;
- (void) discardEventsMatchingMask: (unsigned int)mask
		       beforeEvent: (NSEvent*)lastEvent;
- (NSEvent*) nextEventMatchingMask: (unsigned int)mask
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
#ifndef STRICT_OPENSTEP
- (id)targetForAction: (SEL)theAction 
                   to: (id)theTarget 
                 from: (id)sender;
#endif
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
#ifndef	NO_GNUSTEP
/* GNUstep extensions displaying an infoPanel, title is 'Info' */
/* For a list of the useful values in the dictionary, see GSInfoPanel.h. 
   The entries are mostly compatible with macosx. */
- (void) orderFrontStandardInfoPanel: (id)sender;
- (void) orderFrontStandardInfoPanelWithOptions: (NSDictionary *)dictionary;
#endif 
#ifndef STRICT_OPENSTEP
/* macosx extensions displaying an aboutPanel, title is 'About'. 
   NB: These two methods do exactly the same as the two methods above, 
   only the title is different. */
- (void) orderFrontStandardAboutPanel: (id)sender;
- (void) orderFrontStandardAboutPanelWithOptions: (NSDictionary *)dictionary;
#endif 

/*
 * Getting the main menu
 */
- (NSMenu*) mainMenu;
- (void) setMainMenu: (NSMenu*)aMenu;
#ifndef STRICT_OPENSTEP
- (void) setAppleMenu: (NSMenu*)aMenu;
#endif

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
#ifndef STRICT_OPENSTEP
- (void) replyToApplicationShouldTerminate: (BOOL)shouldTerminate;
#endif 
- (void) terminate: (id)sender;

/*
 * Assigning a delegate
 */
- (id) delegate;
- (void) setDelegate: (id)anObject;

#ifndef STRICT_OPENSTEP
/*
 * Methods for scripting
 */
- (NSArray *) orderedDocuments;
- (NSArray *) orderedWindows;
/*
 * Methods for user attention requests
 */
- (void) cancelUserAttentionRequest: (int)request;
- (int) requestUserAttention: (NSRequestUserAttentionType)requestType;
#endif

@end

@interface NSObject (NSServicesRequests)

/*
 * Pasteboard Read/Write
 */
- (BOOL) readSelectionFromPasteboard: (NSPasteboard*)pboard;
- (BOOL) writeSelectionToPasteboard: (NSPasteboard*)pboard
                              types: (NSArray*)types;

#ifndef	NO_GNUSTEP
- (NSWindow*) iconWindow;
#endif
@end

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
- (BOOL) application: (NSApplication *)theApplication 
           printFile:(NSString *)filename;
- (BOOL) applicationOpenUntitledFile: (NSApplication*)app;
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender;
#ifndef STRICT_OPENSTEP
- (BOOL) applicationShouldTerminate: (id)sender;
#else
- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *)sender;
#endif 
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (id)sender;

- (void) applicationDidBecomeActive: (NSNotification*)aNotification;
- (void) applicationDidFinishLaunching: (NSNotification*)aNotification;
- (void) applicationDidHide: (NSNotification*)aNotification;
- (void) applicationDidResignActive: (NSNotification*)aNotification;
- (void) applicationDidUnhide: (NSNotification*)aNotification;
- (void) applicationDidUpdate: (NSNotification*)aNotification;
- (void) applicationWillBecomeActive: (NSNotification*)aNotification;
- (void) applicationWillFinishLaunching: (NSNotification*)aNotification;
- (void) applicationWillHide: (NSNotification*)aNotification;
- (void) applicationWillResignActive: (NSNotification*)aNotification;
- (void) applicationWillTerminate:(NSNotification *)aNotification;
- (void) applicationWillUnhide: (NSNotification*)aNotification;
- (void) applicationWillUpdate: (NSNotification*)aNotification;
#ifndef STRICT_OPENSTEP
- (BOOL) application: (NSApplication *)sender 
  delegateHandlesKey: (NSString *)key;
- (NSMenu *) applicationDockMenu: (NSApplication *)sender;
- (BOOL) applicationShouldHandleReopen: (NSApplication *)theApplication 
		   hasVisibleWindows: (BOOL)flag;
- (void) applicationDidChangeScreenParameters: (NSNotification *)aNotification;
#endif 
@end
#endif

/*
 * Notifications
 */
APPKIT_EXPORT NSString	*NSApplicationDidBecomeActiveNotification;
APPKIT_EXPORT NSString	*NSApplicationDidFinishLaunchingNotification;
APPKIT_EXPORT NSString	*NSApplicationDidHideNotification;
APPKIT_EXPORT NSString	*NSApplicationDidResignActiveNotification;
APPKIT_EXPORT NSString	*NSApplicationDidUnhideNotification;
APPKIT_EXPORT NSString	*NSApplicationDidUpdateNotification;
APPKIT_EXPORT NSString	*NSApplicationWillBecomeActiveNotification;
APPKIT_EXPORT NSString	*NSApplicationWillFinishLaunchingNotification;
APPKIT_EXPORT NSString	*NSApplicationWillHideNotification;
APPKIT_EXPORT NSString	*NSApplicationWillResignActiveNotification;
APPKIT_EXPORT NSString	*NSApplicationWillTerminateNotification;
APPKIT_EXPORT NSString	*NSApplicationWillUnhideNotification;
APPKIT_EXPORT NSString	*NSApplicationWillUpdateNotification;

/*
 * Determine Whether an Item Is Included in Services Menus
 */
APPKIT_EXPORT int
NSSetShowsServicesMenuItem(NSString *item, BOOL showService);

APPKIT_EXPORT BOOL
NSShowsServicesMenuItem(NSString *item);

/*
 * Programmatically Invoke a Service
 */
APPKIT_EXPORT BOOL
NSPerformService(NSString *item, NSPasteboard *pboard);

/*
 * Force Services Menu to Update Based on New Services
 */
APPKIT_EXPORT void
NSUpdateDynamicServices(void);

/*
 * Register object to handle services requests.
 */
APPKIT_EXPORT void
NSRegisterServicesProvider(id provider, NSString *name);

APPKIT_EXPORT void 
NSUnRegisterServicesProvider(NSString *name);

APPKIT_EXPORT int
NSApplicationMain(int argc, const char **argv);

APPKIT_EXPORT void 
NSShowSystemInfoPanel(NSDictionary *options);

/*
 * The NSApp global variable.
 */
APPKIT_EXPORT NSApplication	*NSApp;

#endif // _GNUstep_H_NSApplication
