/* 
   NSApplication.h

   The one and only application class

   Copyright (C) 1996 Free Software Foundation, Inc.

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSApplication
#define _GNUstep_H_NSApplication

#include <AppKit/stdappkit.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSImage.h>
#include <Foundation/NSDate.h>
#include <gnustep/base/Queue.h>
#include <Foundation/NSCoder.h>

@interface NSApplication : NSResponder <NSCoding>

{
  // Attributes
  NSMutableArray *window_list;
  Queue *event_queue;
  NSEvent *current_event;
  id key_window;
  id main_window;
  id delegate;
  int window_count;
  NSMenu *main_menu;
  NSMenuCell *windows_menu;
  unsigned int current_mod;
  BOOL app_is_running;
  BOOL app_should_quit;
  BOOL app_is_active;
  BOOL app_is_hidden;
  NSImage *app_icon;

  // Reserved for back-end use
  void *be_app_reserved;
}

//
// Class methods
//
//
// Creating and initializing the NSApplication
//
+ (NSApplication *)sharedApplication;

//
// Instance methods
//
//
// Creating and initializing the NSApplication
//
- (void)finishLaunching;

//
// Changing the active application
//
- (void)activateIgnoringOtherApps:(BOOL)flag;
- (void)deactivate;
- (BOOL)isActive;

//
// Running the event loop
//
- (void)abortModal;
- (NSModalSession)beginModalSessionForWindow:(NSWindow *)theWindow;
- (void)endModalSession:(NSModalSession)theSession;
- (BOOL)isRunning;
- (void)run;
- (int)runModalForWindow:(NSWindow *)theWindow;
- (int)runModalSession:(NSModalSession)theSession;
- (void)sendEvent:(NSEvent *)theEvent;
- (void)stop:sender;
- (void)stopModal;
- (void)stopModalWithCode:(int)returnCode;

//
// Getting, removing, and posting events
//
- (NSEvent *)currentEvent;
- (void)discardEventsMatchingMask:(unsigned int)mask
		      beforeEvent:(NSEvent *)lastEvent;
- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
			 untilDate:(NSDate *)expiration
			    inMode:(NSString *)mode
			   dequeue:(BOOL)flag;
- (void)postEvent:(NSEvent *)event atStart:(BOOL)flag;

//
// Sending action messages
//
- (BOOL)sendAction:(SEL)aSelector
		to:aTarget
	      from:sender;
- targetForAction:(SEL)aSelector;
- (BOOL)tryToPerform:(SEL)aSelector
		with:anObject;

//
// Setting the application's icon
//
- (void)setApplicationIconImage:(NSImage *)anImage;
- (NSImage *)applicationIconImage;

//
// Hiding all windows
//
- (void)hide:sender;
- (BOOL)isHidden;
- (void)unhide:sender;
- (void)unhideWithoutActivation;

//
// Managing windows
//
- (NSWindow *)keyWindow;
- (NSWindow *)mainWindow;
- (NSWindow *)makeWindowsPerform:(SEL)aSelector
			 inOrder:(BOOL)flag;
- (void)miniaturizeAll:sender;
- (void)preventWindowOrdering;
- (void)setWindowsNeedUpdate:(BOOL)flag;
- (void)updateWindows;
- (NSArray *)windows;
- (NSWindow *)windowWithWindowNumber:(int)windowNum;

//
// Showing Standard Panels
//
- (void)orderFrontColorPanel:sender;
- (void)orderFrontDataLinkPanel:sender;
- (void)orderFrontHelpPanel:sender;
- (void)runPageLayout:sender;

//
// Getting the main menu
//
- (NSMenu *)mainMenu;
- (void)setMainMenu:(NSMenu *)aMenu;

//
// Managing the Windows menu
//
- (void)addWindowsItem:aWindow
		 title:(NSString *)aString
	      filename:(BOOL)isFilename;
- (void)arrangeInFront:sender;
- (void)changeWindowsItem:aWindow
		 title:(NSString *)aString
		 filename:(BOOL)isFilename;
- (void)removeWindowsItem:aWindow;
- (void)setWindowsMenu:aMenu;
- (void)updateWindowsItem:aWindow;
- (NSMenu *)windowsMenu;

//
// Managing the Service menu
//
- (void)registerServicesMenuSendTypes:(NSArray *)sendTypes
			  returnTypes:(NSArray *)returnTypes;
- (NSMenu *)servicesMenu;
- (void)setServicesMenu:(NSMenu *)aMenu;
- validRequestorForSendType:(NSString *)sendType
		 returnType:(NSString *)returnType;

//
// Getting the display postscript context
//
// - (NSDOSContext *)context;

//
// Reporting an exception
//
//- (void)reportException:(NSException *)anException

//
// Terminating the application
//
- (void)terminate:sender;

//
// Assigning a delegate
//
- delegate;
- (void)setDelegate:anObject;

//
// Implemented by the delegate
//
- (BOOL)application:sender openFileWithoutUI:(NSString *)filename;
- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename;
- (BOOL)application:(NSApplication *)app openTempFile:(NSString *)filename;
- (void)applicationDidBecomeActive:sender;
- (void)applicationDidFinishLaunching:sender;
- (void)applicationDidHide:sender;
- (void)applicationDidResignActive:sender;
- (void)applicationDidUnhide:sender;
- (void)applicationDidUpdate:sender;
- (BOOL)applicationOpenUntitledFile:(NSApplication *)app;
- (BOOL)applicationShouldTerminate:sender;
- (void)applicationWillBecomeActive:sender;
- (void)applicationWillFinishLaunching:sender;
- (void)applicationWillHide:sender;
- (void)applicationWillResignActive:sender;
- (void)applicationWillUnhide:sender;
- (void)applicationWillUpdate:sender;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

//
// Backend methods
//
@interface NSApplication (GNUstepBackend)

// Get next event
- (NSEvent *)getNextEvent;

// handle a non-translated event
- (void)handleNullEvent;

@end

#endif // _GNUstep_H_NSApplication
