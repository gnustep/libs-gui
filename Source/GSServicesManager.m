/* 
   GSServicesManager.m

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Novemeber 1998
  
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

#include "gnustep/gui/config.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSException.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSDistantObject.h>
#include <Foundation/NSMethodSignature.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSSerialization.h>
#include <Foundation/NSPortNameServer.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSInvocation.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSPanel.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSWorkspace.h"
#include "AppKit/NSDocumentController.h"

#include "gnustep/gui/GSServicesManager.h"

static GSServicesManager	*manager = nil;

/*
 *	The GSListener class is for talking to other applications.
 *	It is a proxy with some dangerous methods implemented in a
 *	harmless manner to reduce the chances of a malicious app
 *	messing with us.  This is responsible for forwarding service
 *      requests and other communications with the outside world.
 */
@interface      GSListener : NSObject
+ (id) connectionBecameInvalid: (NSNotification*)notification;
+ (GSListener*) listener;
+ (id) servicesProvider;
+ (void) setServicesProvider: (id)anObject;
- (Class) class;
- (void) dealloc;
- (void) release;
- (id) retain;
- (id) self;
- (void) performService: (NSString*)name
	 withPasteboard: (NSPasteboard*)pb
	       userData: (NSString*)ud
		  error: (NSString**)e;
@end

static NSConnection	*listenerConnection = nil;
static GSListener	*listener = nil;
static id		servicesProvider = nil;
static NSString		*providerName = nil;

/**
 * Unregisters the service provider registered on the named port.<br />
 * Applications should use [NSApplication-setServicesProvider:] with a nil
 * argument instead.
 */
void
NSUnregisterServicesProvider(NSString *name)
{
  if (listenerConnection != nil)
    {
      /*
       *        Ensure there is no previous listener and nothing else using
       *        the given port name.
       */
      [[NSPortNameServer systemDefaultPortNameServer] removePortForName: name];
      [[NSNotificationCenter defaultCenter]
	removeObserver: [GSListener class]
		  name: NSConnectionDidDieNotification
		object: listenerConnection];
      DESTROY(listenerConnection);
    }
  ASSIGN(servicesProvider, nil);
  ASSIGN(providerName, nil);
}

/**
 * Registers a services providing object using the specified port name.<br />
 * Applications should not need to use this, as they can use the
 * [NSApplication-setServicesProvider:] method instead.  The NSApplication
 * method will use the name of the application rather than an other port name.
 */
void
NSRegisterServicesProvider(id provider, NSString *name)
{
  if (listenerConnection != nil)
    {
      /*
       *	Ensure there is no previous listener and nothing else using
       *	the given port name.
       */
      [[NSPortNameServer systemDefaultPortNameServer] removePortForName: name];
      [[NSNotificationCenter defaultCenter]
	removeObserver: [GSListener class]
		  name: NSConnectionDidDieNotification
		object: listenerConnection];
      DESTROY(listenerConnection);
    }
  if (name != nil && provider != nil)
    {
      listenerConnection = [NSConnection newRegisteringAtName: name
	withRootObject: [GSListener listener]];
      if (listenerConnection != nil)
	{
	  RETAIN(listenerConnection);
	  [[NSNotificationCenter defaultCenter]
                    addObserver: [GSListener class]
		       selector: @selector(connectionBecameInvalid:)
			   name: NSConnectionDidDieNotification
			 object: listenerConnection];
	}
      else
	{
	  [NSException raise: NSGenericException
		      format: @"unable to register %@", name];
	}
    }
  ASSIGN(servicesProvider, provider);
  ASSIGN(providerName, name);
}

/*
 *	The GSListener class exists as a proxy to forward messages to
 *	service provider objects.  It implements very few methods and
 *	those that it does implement are generally designed to defeat
 *	any attack by a malicious program.
 */
@implementation GSListener

+ (id) connectionBecameInvalid: (NSNotification*)notification
{
  NSAssert(listenerConnection==[notification object],
	NSInternalInconsistencyException);

  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: NSConnectionDidDieNotification
	    object: listenerConnection];
  DESTROY(listenerConnection);
  return self;
}

+ (GSListener*) listener
{
  if (listener == nil)
    {
      listener = (id)NSAllocateObject(self, 0, NSDefaultMallocZone());
    }
  return listener;
}

+ (id) servicesProvider
{
  return servicesProvider;
}

+ (void) setServicesProvider: (id)anObject
{
  NSString	*appName;

  if (servicesProvider != anObject)
    {
      appName = [[NSProcessInfo processInfo] processName];
      NSRegisterServicesProvider(anObject, appName);
    }
}

- (Class) class
{
  return 0;
}

- (void) dealloc
{
}

/*
 * Obsolete ... prefer forwardInvocation now.
 */
- forward: (SEL)aSel :(arglist_t)frame
{
  NSString      *selName = NSStringFromSelector(aSel);
  id            delegate;

  /*
   *    If the selector matches the correct form for a services request,
   *    send the message to the services provider - otherwise raise an
   *    exception to say the method is not implemented.
   */
  if ([selName hasSuffix: @":userData:error:"])
    return [servicesProvider performv: aSel :frame];

  /*
   * If the applications delegate can handle the message - forward to it.
   */
  delegate = [[NSApplication sharedApplication] delegate];
  if ([delegate respondsToSelector: aSel] == YES)
    return [delegate performv: aSel :frame];

  /*
   *    If the selector matches the correct form for a file operaqtion
   *    send the message to the manager.
   */
  if ([selName hasPrefix: @"application:"] == YES
    && [manager respondsToSelector: aSel] == YES)
    return [(id)manager performv: aSel :frame];

  [NSException raise: NSGenericException
	      format: @"method %@ not implemented", selName];
  return nil;
}

- (void) forwardInvocation: (NSInvocation*)anInvocation
{
  SEL		aSel = [anInvocation selector];
  NSString      *selName = NSStringFromSelector(aSel);
  id            delegate;

  /*
   *    If the selector matches the correct form for a services request,
   *    send the message to the services provider.
   */
  if ([selName hasSuffix: @":userData:error:"])
    {
      [anInvocation invokeWithTarget: servicesProvider];
      return;
    }

  /*
   * If the applications delegate can handle the message - forward to it.
   */
  delegate = [[NSApplication sharedApplication] delegate];
  if ([delegate respondsToSelector: aSel] == YES)
    {
      [anInvocation invokeWithTarget: delegate];
      return;
    }

  /*
   *    If the selector matches the correct form for a file operaqtion
   *    send the message to the manager.
   */
  if ([selName hasPrefix: @"application:"] == YES
    && [manager respondsToSelector: aSel] == YES)
    {
      [anInvocation invokeWithTarget: manager];
      return;
    }

  [NSException raise: NSGenericException
	      format: @"method %@ not implemented", selName];
}

- (void) performService: (NSString*)name
	 withPasteboard: (NSPasteboard*)pb
	       userData: (NSString*)ud
		  error: (NSString**)e
{
  id	obj = servicesProvider;
  SEL	msgSel = NSSelectorFromString(name);
  IMP	msgImp;

  /*
  Create a local NSPasteboard object for this pasteboard. If we try to
  use the remote NSPasteboard object, we get trouble when setting property
  lists since the remote NSPasteboard fails to serialize the local property
  list objects for sending to gpbs.
  */
  pb = [NSPasteboard pasteboardWithName: [pb name]];

  if (obj != nil && [obj respondsToSelector: msgSel])
    {
      msgImp = [obj methodForSelector: msgSel];
      if (msgImp != 0)
	{
	  (*msgImp)(obj, msgSel, pb, ud, e);
	  return;
	}
    }

  obj = [[NSApplication sharedApplication] delegate];
  if (obj != nil && [obj respondsToSelector: msgSel])
    {
      msgImp = [obj methodForSelector: msgSel];
      if (msgImp != 0)
	{
	  (*msgImp)(obj, msgSel, pb, ud, e);
	  return;
	}
    }

  *e = @"No object available to provide service"; 
}

- (void) release
{
}

- (id) retain
{
  return self;
}

- (id) self
{
  return self;
}
@end /* GSListener */



@implementation GSServicesManager

static NSString         *servicesName = @".GNUstepServices";
static NSString         *disabledName = @".GNUstepDisabled";

/*
 *      Create a new listener for this application.
 *      Uses NSRegisterServicesProvider() to register itsself as a service
 *      provider with the applications name so we can handle incoming
 *      service requests.
 */
+ (GSServicesManager*) newWithApplication: (NSApplication*)app
{
  NSString	*str;
  NSString	*path;

  if (manager != nil)
    {
      if (manager->_application == nil)
	{
	  manager->_application = app;
	}
      return manager;
    }

  manager = [GSServicesManager alloc];

  str = [NSSearchPathForDirectoriesInDomains(NSUserDirectory,
          NSUserDomainMask, YES) objectAtIndex: 0];
  str = [str stringByAppendingPathComponent: @"Library/Services"];
  path = [str stringByAppendingPathComponent: servicesName];
  manager->_servicesPath = [path copy];
  path = [str stringByAppendingPathComponent: disabledName];
  manager->_disabledPath = [path copy];
  /*
   *    Don't retain application object - that would create a cycle.
   */
  manager->_application = app;
  manager->_returnInfo = [[NSMutableSet alloc] initWithCapacity: 16];
  manager->_combinations = [[NSMutableDictionary alloc] initWithCapacity: 16];
  /*
   *	Check for changes to the services cache every thirty seconds.
   */
  manager->_timer =
	[NSTimer scheduledTimerWithTimeInterval: 30.0
					 target: manager
				       selector: @selector(loadServices)
				       userInfo: nil
					repeats: YES];

  [manager loadServices];
  return manager;
}

+ (GSServicesManager*) manager
{
  if (manager == nil)
    {
      [self newWithApplication: nil];
    }
  return manager;
}

- (BOOL) application: (NSApplication*)theApp
	    openFile: (NSString*)file
{
  id	del = [NSApp delegate];
  BOOL	result = NO;

  if ([del respondsToSelector: _cmd])
    {
      result = [del application: theApp openFile: file];
    }
  else if ([[NSDocumentController sharedDocumentController]
    openDocumentWithContentsOfFile: file display: YES] != nil)
    {
      [NSApp activateIgnoringOtherApps: YES];
      result = YES;
    }
  return result;
}

- (BOOL) application: (NSApplication*)theApp
   openFileWithoutUI: (NSString*)file
{
  id	del = [NSApp delegate];
  BOOL	result = NO;

  if ([del respondsToSelector: _cmd])
    {
      result = [del application: theApp openFileWithoutUI: file];
    }
  else if ([[NSDocumentController sharedDocumentController]
    openDocumentWithContentsOfFile: file display: NO] != nil)
    {
      result = YES;
    }
  return result;
}

- (BOOL) application: (NSApplication*)theApp
	openTempFile: (NSString*)file
{
  BOOL	result = [self application: theApp openFile: file];

  [[NSFileManager defaultManager] removeFileAtPath: file handler: nil];

  return result;
}

- (BOOL) application: (NSApplication*)theApp
	   printFile: (NSString*)file
{
  id	del = [NSApp delegate];

  if ([del respondsToSelector: _cmd])
    return [del application: theApp printFile: file];
  return NO;
}

- (void) dealloc
{
  NSString          *appName;

  appName = [[NSProcessInfo processInfo] processName];
  [_timer invalidate];
  NSUnregisterServicesProvider(appName);
  RELEASE(_languages);
  RELEASE(_returnInfo);
  RELEASE(_combinations);
  RELEASE(_title2info);
  RELEASE(_menuTitles);
  RELEASE(_servicesMenu);
  RELEASE(_disabledPath);
  RELEASE(_servicesPath);
  RELEASE(_disabledStamp);
  RELEASE(_servicesStamp);
  RELEASE(_allDisabled);
  RELEASE(_allServices);
  [super dealloc];
}

- (void) doService: (NSMenuItem*)item
{
  NSString      *title = [self item2title: item];
  NSDictionary  *info = [_title2info objectForKey: title];
  NSArray       *sendTypes = [info objectForKey: @"NSSendTypes"];
  NSArray       *returnTypes = [info objectForKey: @"NSReturnTypes"];
  unsigned      i, j;
  unsigned      es = [sendTypes count];
  unsigned      er = [returnTypes count];
  NSWindow      *resp = [[_application keyWindow] firstResponder];
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
	      if (sendType
		  && [obj writeSelectionToPasteboard: pb
					       types: sendTypes] == NO)
		{
		  NSRunAlertPanel(nil,
			@"object failed to write to pasteboard",
			@"Continue", nil, nil);
		}
	      else if (NSPerformService(title, pb) == YES)
		{
		  if (returnType
		      && [obj readSelectionFromPasteboard: pb] == NO)
		    {
		      NSRunAlertPanel(nil,
			    @"object failed to read from pasteboard",
			    @"Continue", nil, nil);
		    }
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
          if ([_returnInfo member: type] != nil)
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
          if ([_combinations objectForKey: type] != nil)
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
          rset = [_combinations objectForKey: type];
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
 *      Use tag in menu item to identify slot in menu titles array that
 *      contains the full title of the service.
 *      Return nil if this is not one of our service menu items.
 */
- (NSString*) item2title: (NSMenuItem*)item
{
  unsigned      pos;

  if ([item target] != self)
    return nil;
  pos = [item tag];
  if (pos > [_menuTitles count])
    return nil;
  return [_menuTitles objectAtIndex: pos];
}

- (void) loadServices
{
  NSFileManager         *mgr = [NSFileManager defaultManager];
  NSDate		*stamp = [NSDate date];
  BOOL			changed = NO;

  if ([mgr fileExistsAtPath: _disabledPath])
    {
      NSDictionary	*attr;
      NSDate		*mod;

      attr = [mgr fileAttributesAtPath: _disabledPath
			  traverseLink: YES];
      mod = [attr objectForKey: NSFileModificationDate];
      if (_disabledStamp == nil || [_disabledStamp laterDate: mod] == mod)
	{
	  NSData	*data;
	  id		plist = nil;

	  data = [NSData dataWithContentsOfFile: _disabledPath];
	  if (data)
	    {
	      plist = [NSDeserializer deserializePropertyListFromData: data
						    mutableContainers: NO];
	      if (plist)
		{
		  NSMutableSet	*s;
		  changed = YES;
		  s = (NSMutableSet*)[NSMutableSet setWithArray: plist];
		  ASSIGN(_allDisabled, s);
		}
	    }
	  /* Track most recent version of file loaded */
	  ASSIGN(_disabledStamp, mod);
	}
    }

  stamp = [NSDate date];
  if ([mgr fileExistsAtPath: _servicesPath])
    {
      NSDictionary	*attr;
      NSDate		*mod;

      attr = [mgr fileAttributesAtPath: _servicesPath
			  traverseLink: YES];
      mod = [attr objectForKey: NSFileModificationDate];
      if (_servicesStamp == nil || [_servicesStamp laterDate: mod] == mod)
	{
	  NSData	*data;
	  id		plist = nil;

	  data = [NSData dataWithContentsOfFile: _servicesPath];
	  if (data)
	    {
	      plist = [NSDeserializer deserializePropertyListFromData: data
						    mutableContainers: YES];
	      if (plist)
		{
		  ASSIGN(_allServices, plist);
		  changed = YES;
		}
	    }
	  /* Track most recent version of file loaded */
	  ASSIGN(_servicesStamp, mod);
	}
    }
  if (changed)
    {
      [self rebuildServices];
    }
}

- (NSDictionary*) menuServices
{
  if (_allServices == nil)
    {
      [self loadServices];
    }
  return _title2info;
}

- (void) rebuildServices
{
  NSDictionary          *services;
  NSMutableArray        *newLang;
  NSMutableSet          *alreadyFound;
  NSMutableDictionary   *newServices;
  unsigned              pos;

  if (_allServices == nil)
    return;

  newLang = AUTORELEASE([[NSUserDefaults userLanguages] mutableCopy]);
  if (newLang == nil)
    {
      newLang = [NSMutableArray arrayWithCapacity: 1];
    }
  if ([newLang containsObject:  @"default"] == NO)
    {
      [newLang addObject: @"default"];
    }
  ASSIGN(_languages, newLang);

  services = [_allServices objectForKey: @"ByService"];

  newServices = [NSMutableDictionary dictionaryWithCapacity: 16];
  alreadyFound = [NSMutableSet setWithCapacity: 16];

  /*
   *    Build dictionary of services we can use.
   *    1. make sure we make dictionary keyed on preferred menu item language
   *    2. don't include entries for services already examined.
   *    3. don't include entries for menu items specifically disabled.
   *    4. don't include entries for which we have no registered types.
   */
  for (pos = 0; pos < [_languages count]; pos++)
    {
      NSDictionary      *byLanguage;

      byLanguage = [services objectForKey: [_languages objectAtIndex: pos]];
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

	      /* See if this service item is disabled. */
              if ([_allDisabled member: menuItem] != nil)
                continue;

              if ([self hasRegisteredTypes: service])
                [newServices setObject: service forKey: menuItem];
            }
        }
    }
  if ([newServices isEqual: _title2info] == NO)
    {
      NSArray   *titles;

      ASSIGN(_title2info, newServices);
      titles = [_title2info allKeys];
      titles = [titles sortedArrayUsingSelector: @selector(compare:)];
      ASSIGN(_menuTitles, titles);
      [self rebuildServicesMenu];
    }
}

- (void) rebuildServicesMenu
{
  if (_servicesMenu != nil)
    {
      NSMutableSet      *keyEquivalents;
      unsigned          pos;
      unsigned          loc0;
      unsigned          loc1 = 0;
      SEL               sel = @selector(doService:);
      NSMenu            *submenu = nil;

      [_servicesMenu setAutoenablesItems: NO];
      pos = [_servicesMenu numberOfItems];
      for (; pos; pos--)
        [_servicesMenu removeItemAtIndex: 0];
      [_servicesMenu setAutoenablesItems: YES];

      keyEquivalents = [NSMutableSet setWithCapacity: 4];
      for (loc0 = pos = 0; pos < [_menuTitles count]; pos++)
        {
          NSString      *title = [_menuTitles objectAtIndex: pos];
          NSString      *equiv = @"";
          NSDictionary  *info = [_title2info objectForKey: title];
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
          for (lang = 0; lang < [_languages count]; lang++)
            {
              NSString  *language = [_languages objectAtIndex: lang];
              NSString  *t = [titles objectForKey: language];

              if ([t isEqual: title])
                {
                  equiv = [equivs objectForKey: language]; 
		  if (equiv == nil)
		    {
		      equiv = [equivs objectForKey: @"default"];
		    }		  
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

              item = [_servicesMenu itemWithTitle: parentTitle];
              if (item == nil)
                {
                  loc1 = 0;
                  item = [_servicesMenu insertItemWithTitle: parentTitle
                                                    action: 0
                                             keyEquivalent: @""
                                                   atIndex: loc0++];
                  menu = [[NSMenu alloc] initWithTitle: parentTitle];
                  [_servicesMenu setSubmenu: menu
                                   forItem: item];
                  RELEASE(menu);
                }
              else
                {
                  menu = (NSMenu*)[item submenu];
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
              item = [_servicesMenu insertItemWithTitle: title
                                                action: sel
                                         keyEquivalent: equiv
                                               atIndex: loc0++];
              [item setTarget: self];
              [item setTag: pos];
            }
        }
      [submenu update];
//      [submenu sizeToFit];
//      [_servicesMenu sizeToFit];
      [_servicesMenu update];
    }
}

/*
 *      Set up connection to listen for incoming service requests.
 */
- (void) registerAsServiceProvider
{
  NSString      *appName;
  BOOL          registered;

  appName = [[NSProcessInfo processInfo] processName];
  NS_DURING
    {
      NSRegisterServicesProvider(self, appName);
      registered = YES;
    }
  NS_HANDLER
    {
      registered = NO;
    }
  NS_ENDHANDLER

  if (registered == NO)
    {
      int result = NSRunAlertPanel(appName,
	@"Application may already be running with this name",
	@"Continue", @"Abort", @"Rename");

      if (result == NSAlertDefaultReturn || result == NSAlertOtherReturn)
        {
          if (result == NSAlertOtherReturn)
	    appName = [[NSProcessInfo processInfo] globallyUniqueString];

          [[NSPortNameServer systemDefaultPortNameServer]
	    removePortForName: appName];

          NS_DURING
            {
              NSRegisterServicesProvider(self, appName);
              registered = YES;
            }
          NS_HANDLER
            {
              registered = NO;
              NSLog(@"Warning: Could not register application due to "
                    @"exception: %@\n", [localException reason]);
            }
          NS_ENDHANDLER

	  /*
	   *	Something is seriously wrong - we can't talk to the
	   *	nameserver, so all interaction with the workspace manager
	   *	and/or other applications will fail.
	   *	Give the user a chance to keep on going anyway.
	   */
	  if (registered == NO)
	    {
	      result = NSRunAlertPanel(appName,
		@"Unable to register application with ANY name",
		@"Abort", @"Continue", nil);

	      if (result == NSAlertDefaultReturn)
		registered = YES;
	    }
        }

      if (registered == NO)
        [[NSApplication sharedApplication] terminate: self];
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
      NSMutableSet      *returnSet = [_combinations objectForKey: sendType];

      if (returnSet == nil)
        {
          returnSet = [NSMutableSet setWithCapacity: [returnTypes count]];
          [_combinations setObject: returnSet forKey: sendType];
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

  i = [_returnInfo count];
  [_returnInfo addObjectsFromArray: returnTypes];
  if ([_returnInfo count] != i)
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
  return _servicesMenu;
}

- (id) servicesProvider
{
  return [GSListener servicesProvider];
}

- (void) setServicesMenu: (NSMenu*)aMenu
{
  ASSIGN(_servicesMenu, aMenu);
  [self rebuildServicesMenu];
}

- (void) setServicesProvider: (id)anObject
{
  [GSListener setServicesProvider: anObject];
}

- (int) setShowsServicesMenuItem: (NSString*)item to: (BOOL)enable
{
  NSData	*d;

  [self loadServices];
  if (_allDisabled == nil)
    {
      _allDisabled = [[NSMutableSet alloc] initWithCapacity: 1];
    }
  if (enable)
    {
      [_allDisabled removeObject: item];
    }
  else
    {
      [_allDisabled addObject: item];
    }
  d = [NSSerializer serializePropertyList: [_allDisabled allObjects]];
  if ([d writeToFile: _disabledPath atomically: YES] == YES)
    {
      return 0;
    }
  return -1;
}

- (BOOL) showsServicesMenuItem: (NSString*)item
{
  [self loadServices];
  if ([_allDisabled member: item] == nil)
    return YES;
  return NO;
}

- (BOOL) validateMenuItem: (NSMenuItem*)item
{
  NSString      *title = [self item2title: item];
  NSDictionary  *info = [_title2info objectForKey: title];
  NSArray       *sendTypes = [info objectForKey: @"NSSendTypes"];
  NSArray       *returnTypes = [info objectForKey: @"NSReturnTypes"];
  unsigned      i, j;
  unsigned      es = [sendTypes count];
  unsigned      er = [returnTypes count];
  NSWindow      *resp = [[_application keyWindow] firstResponder];

  /*
   *    If the menu item is not in our map, it must be the item containing
   *    a sub-menu - so we see if any item in the submenu is valid.
   */
  if (title == nil)
    {
      NSMenu    *sub;

      if (![item isKindOfClass: [NSMenuItem class]])
        return NO;

      sub = [item submenu];

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
   *    The item corresponds to one of our services - so we check to see if
   *    there is anything that can deal with it.
   */
  if (es == 0)
    {
      if (er == 0)
	{
	  if ([resp validRequestorForSendType: nil
				   returnType: nil] != nil)
	    return YES;
	}
      else
	{
	  for (j = 0; j < er; j++)
	    {
	      NSString      *returnType;

	      returnType = [returnTypes objectAtIndex: j];
	      if ([resp validRequestorForSendType: nil
				       returnType: returnType] != nil)
		return YES;
	    }
	}
    }
  else
    {
      for (i = 0; i < es; i++)
	{
	  NSString  *sendType;

	  sendType = [sendTypes objectAtIndex: i];

	  if (er == 0)
	    {
	      if ([resp validRequestorForSendType: sendType
				       returnType: nil] != nil)
		return YES;
	    }
	  else
	    {
	      for (j = 0; j < er; j++)
		{
		  NSString      *returnType;

		  returnType = [returnTypes objectAtIndex: j];
		  if ([resp validRequestorForSendType: sendType
					   returnType: returnType] != nil)
		    return YES;
		}
	    }
	}
    }
  return NO;
}

- (void) updateServicesMenu
{
  if (_servicesMenu && [[_application mainMenu] autoenablesItems])
    {
      NSArray   	*a;
      unsigned  	i;
      NSMenu		*mainMenu = [_application mainMenu];
      BOOL		found = NO;

      a = [mainMenu itemArray];
      for (i = 0; i < [a count]; i++)
	if ([[a objectAtIndex: i] submenu] == _servicesMenu)
	  found = YES;
      if (found == NO)
	{
	  NSLog(@"Services menu not in main menu!\n");
	  return;
	}

      a = [_servicesMenu itemArray];

      for (i = 0; i < [a count]; i++)
        {
          NSMenuItem    *item = [a objectAtIndex: i];
	  BOOL		wasEnabled = [item isEnabled];
	  BOOL		shouldBeEnabled;
	  NSString      *title = [self item2title: item];

	  /*
	   *	If there is no title mapping, this item must be a
	   *	submenu - so we check the submenu items.
	   */
	  if (title == nil && [[item submenu] isKindOfClass: [NSMenu class]])
	    {
	      NSArray		*sub = [[item submenu] itemArray];
	      unsigned		j;

	      shouldBeEnabled = NO;
	      for (j = 0; j < [sub count]; j++)
		{
		  NSMenuItem	*subitem = [sub objectAtIndex: j];
		  BOOL		subWasEnabled = [subitem isEnabled];
		  BOOL		subShouldBeEnabled = NO;

		  if ([self validateMenuItem: subitem] == YES)
		    {
		      shouldBeEnabled = YES;	/* Enabled menu */
		      subShouldBeEnabled = YES;
		    }
		  if (subWasEnabled != subShouldBeEnabled)
		    {
		      [subitem setEnabled: subShouldBeEnabled];
//		      [subMenuCells setNeedsDisplayInRect:
//				[subMenuCells cellFrameAtRow: j]];
		    }
		}
	    }
	  else
	    shouldBeEnabled = [self validateMenuItem: item];

          if (wasEnabled != shouldBeEnabled)
            {
              [item setEnabled: shouldBeEnabled];
//	      [menuCells setNeedsDisplayInRect: [menuCells cellFrameAtRow: i]];
            }
        }
    }
}

@end /* GSServicesManager */


/**
 * <p>Establishes an NSConnection to the application listening at port
 * (by convention usually the application name), launching appName 
 * if necessary.  Returns the proxy to the remote application, or nil
 * on failure.
 * </p>
 * The value of expire provides a timeout in case the application cannot
 * be contacted promptly.
 */
id
GSContactApplication(NSString *appName, NSString *port, NSDate *expire)
{
  id	app;

  if (providerName != nil && [port isEqual: providerName] == YES)
    {
      app = [GSListener listener];	// Contect our own listener.
    }
  else
    {
      NS_DURING
	{
	  app = [NSConnection rootProxyForConnectionWithRegisteredName: port  
								  host: @""];
	}
      NS_HANDLER
	{
	  return nil;                /* Fatal error in DO    */
	}
      NS_ENDHANDLER
    }
  if (app == nil)
    {
      if ([[NSWorkspace sharedWorkspace] launchApplication: appName] == NO)
	{
	  return nil;		/* Unable to launch.	*/
	}

      NS_DURING
	{
	  app = [NSConnection
			rootProxyForConnectionWithRegisteredName: port  
							    host: @""];
	  while (app == nil && [expire timeIntervalSinceNow] > 0.1)
	    {
	      NSRunLoop	*loop = [NSRunLoop currentRunLoop];
	      NSDate	*next;

	      [NSTimer scheduledTimerWithTimeInterval: 0.1
					   invocation: nil
					      repeats: NO];
	      next = [NSDate dateWithTimeIntervalSinceNow: 0.2];
	      [loop runUntilDate: next];
	      app = [NSConnection
			    rootProxyForConnectionWithRegisteredName: port  
								host: @""];
	    }
	}
      NS_HANDLER
	{
	  return nil;
	}
      NS_ENDHANDLER
    }

  return app;
}

/**
 * <p>Given the name of a serviceItem, and some data in a pasteboard
 * this function sends the data to the service provider (launching
 * another application if necessary) and retrieves the result of
 * the service in the pastebaord.
 * </p>
 * Returns YES on success, NO otherwise.
 */
BOOL
NSPerformService(NSString *serviceItem, NSPasteboard *pboard)
{
  NSDictionary		*service;
  NSString		*port;
  NSString		*timeout;
  double		seconds;
  NSDate		*finishBy;
  NSString		*appPath;
  id			provider;
  NSString		*message;
  NSString		*selName;
  NSString		*userData;
  NSString		*error = nil;

  service = [[manager menuServices] objectForKey: serviceItem]; 
  if (service == nil)
    {
      NSRunAlertPanel(nil,
	@"No service matching '%@'",
	@"Continue", nil, nil,
	serviceItem);
      return NO;			/* No matching service.	*/
    }

  port = [service objectForKey: @"NSPortName"];
  timeout = [service objectForKey: @"NSTimeout"];
  if (timeout && [timeout floatValue] > 100)
    {
      seconds = [timeout floatValue] / 1000.0;
    }
  else
    {
      seconds = 30.0;
    }
  finishBy = [NSDate dateWithTimeIntervalSinceNow: seconds];
  appPath = [service objectForKey: @"ServicePath"];
  userData = [service objectForKey: @"NSUserData"];
  message = [service objectForKey: @"NSMessage"];
  selName = [message stringByAppendingString: @":userData:error:"];

  /*
   * Locate the service provider ... this will be a proxy to the remote
   * object, or a local object (if we provide the service ourself)
   */
  provider = GSContactApplication(appPath, port, finishBy);
  if (provider == nil)
    {
      NSRunAlertPanel(nil,
	@"Failed to contact service provider for '%@'",
	@"Continue", nil, nil,
	serviceItem);
      return NO;
    }

  /*
   * If the service provider is a remote object, we can set timeouts on
   * the NSConnection so we don't hang waiting for it to reply.
   */
  if ([provider isProxy] == YES)
    {
      NSConnection	*connection;

      connection = [(NSDistantObject*)provider connectionForProxy];
      seconds = [finishBy timeIntervalSinceNow];
      [connection setRequestTimeout: seconds];
      [connection setReplyTimeout: seconds];
    }

  /*
   * At last, we ask for the service to be performed.
   */
  NS_DURING
    {
      [provider performService: selName
		withPasteboard: pboard
		      userData: userData
			 error: &error];
    }
  NS_HANDLER
    {
      error = [NSString stringWithFormat: @"%@", [localException reason]];
    }
  NS_ENDHANDLER

  if (error != nil)
    {
      NSRunAlertPanel(nil,
	@"Failed to contact service provider for '%@': %@",
        @"Continue", nil, nil,
	serviceItem, error);
      return NO;
    }

  return YES;
}

/**
 * <p>Controls whether the item name should be included in the services menu.
 * </p>
 * <p>If enabled is YES then the services menu for each application will
 * include the named item, if enabled is NO then the service will not be
 * shown in application services menus.
 * </p>
 * <p>Returns 0 if the setting is successfuly changed. Non-zero otherwise.
 * </p>
 */
int
NSSetShowsServicesMenuItem(NSString *name, BOOL enabled)
{
  return [[GSServicesManager manager] setShowsServicesMenuItem: name
							    to: enabled];
}

/**
 * Returns a flag indicating whether the named service is supposed to be
 * displayed in application services menus.
 */
BOOL
NSShowsServicesMenuItem(NSString *name)
{
  return [[GSServicesManager manager] showsServicesMenuItem: name];
}

/**
 * A services providing application may use this to update the list of
 * services it provides.
 */
void
NSUpdateDynamicServices(void)
{
  [[GSServicesManager manager] loadServices];
}
