/* 
   GNUServicesManager.m

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

#include <gnustep/gui/config.h>

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
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSSerialization.h>
#include <Foundation/NSPortNameServer.h>

#include <Foundation/fast.x>

#include <AppKit/NSApplication.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSWorkspace.h>

#include <AppKit/GNUServicesManager.h>

#define stringify_it(X) #X
#define prog_path(X,Y) \
  stringify_it(X) "/Tools/" GNUSTEP_TARGET_DIR "/" LIBRARY_COMBO

/*
 *	The GNUListener class is for talking to other applications.
 *	It is a proxy with some dangerous methods implemented in a
 *	harmless manner to reduce the chances of a malicious app
 *	messing with us.
 */
@interface      GNUListener : NSObject
+ (id) connectionBecameInvalid: (NSNotification*)notification;
+ (GNUListener*) listener;
+ (id) servicesProvider;
+ (void) setServicesProvider: (id)anObject;
- (Class) class;
- (void) dealloc;
- (void) release;
- (id) retain;
- (id) self;
@end

static NSConnection	*listenerConnection = nil;
static GNUListener	*listener = nil;
static id		servicesProvider = nil;

void
NSUnregisterServicesProvider(NSString *name)
{
  if (listenerConnection)
    {
      /*
       *        Ensure there is no previous listener and nothing else using
       *        the given port name.
       */
      [[NSPortNameServer defaultPortNameServer] removePortForName: name];
      [NSNotificationCenter removeObserver: [GNUListener class]
                                      name: NSConnectionDidDieNotification
                                    object: listenerConnection];
      [listenerConnection release];
      listenerConnection = nil;
    }
  ASSIGN(servicesProvider, nil);
}

void
NSRegisterServicesProvider(id provider, NSString *name)
{
  if (listenerConnection)
    {
      /*
       *	Ensure there is no previous listener and nothing else using
       *	the given port name.
       */
      [[NSPortNameServer defaultPortNameServer] removePortForName: name];
      [NSNotificationCenter removeObserver: [GNUListener class]
				      name: NSConnectionDidDieNotification
				    object: listenerConnection];
      [listenerConnection release];
      listenerConnection = nil;
    }
  if (name && provider)
    {
      listenerConnection = [NSConnection newRegisteringAtName: name
				       withRootObject: [GNUListener listener]];
      if (listenerConnection)
	{
	  [listenerConnection retain];
	  [NotificationDispatcher
                    addObserver: [GNUListener class]
		       selector: @selector(connectionBecameInvalid:)
			   name: NSConnectionDidDieNotification
			 object: listenerConnection];
	}
    }
  ASSIGN(servicesProvider, provider);
}

/*
 *	The GNUListener class exists as a proxy to forward messages to
 *	service provider objects.  It implements very few methods and
 *	those that it does implement are generally designed to defeat
 *	any attack by a malicious program.
 */
@implementation GNUListener

+ (id) connectionBecameInvalid: (NSNotification*)notification
{
  NSAssert(listenerConnection==[notification object],
	NSInternalInconsistencyException);

  [NSNotificationCenter removeObserver: self
				  name: NSConnectionDidDieNotification
				object: listenerConnection];
  [listenerConnection release];
  listenerConnection = nil;
  return self;
}

+ (GNUListener*) listener
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
      appName = [[[NSProcessInfo processInfo] processName] lastPathComponent];
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

  [NSException raise: NSGenericException
	      format: @"method %s not implemented", sel_get_name(aSel)];
  return nil;
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
@end /* GNUListener */



@implementation GNUServicesManager

static GNUServicesManager	*manager = nil;
static NSString         *servicesName = @".GNUstepServices";
static NSString         *disabledName = @".GNUstepDisabled";

/*
 *      Create a new listener for this application.
 *      Uses NSRegisterServicesProvider() to register itsself as a service
 *      provider with the applications name so we can handle incoming
 *      service requests.
 */
+ (GNUServicesManager*) newWithApplication: (NSApplication*)app
{
  NSDictionary	*env;
  NSString	*str;
  NSString	*path;

  if (manager)
    {
      if (manager->application == nil)
	manager->application = app;
      return manager;
    }

  manager = [GNUServicesManager alloc];

  env = [[NSProcessInfo processInfo] environment];
  str = [env objectForKey: @"GNUSTEP_USER_ROOT"];
  if (str == nil)
    str = [NSString stringWithFormat: @"%@/GNUstep",
	    NSHomeDirectory()];
  str = [str stringByAppendingPathComponent: @"Services"];
  path = [str stringByAppendingPathComponent: servicesName];
  manager->servicesPath = [path retain];
  path = [str stringByAppendingPathComponent: disabledName];
  manager->disabledPath = [path retain];
  /*
   *    Don't retain application object - that would reate a cycle.
   */
  manager->application = app;
  manager->returnInfo = [[NSMutableSet alloc] initWithCapacity: 16];
  manager->combinations = [[NSMutableDictionary alloc] initWithCapacity: 16];
  /*
   *	Check for changes to the services cache every thirty seconds.
   */
  manager->timer =
	[NSTimer scheduledTimerWithTimeInterval: 30.0
					 target: manager
				       selector: @selector(loadServices)
				       userInfo: nil
					repeats: YES];

  [manager loadServices];
  return manager;
}

+ (GNUServicesManager*) manager
{
  if (manager == nil)
    {
      [self newWithApplication: nil];
    }
  return manager;
}

- (void) checkServices
{
  system(prog_path(GNUSTEP_INSTALL_PREFIX, "/make_services"));

  [self loadServices];
}

- (void) dealloc
{
  NSString          *appName;

  appName = [[[NSProcessInfo processInfo] processName] lastPathComponent];
  [timer invalidate];
  NSUnregisterServicesProvider(appName);
  [languages release];
  [returnInfo release];
  [combinations release];
  [title2info release];
  [menuTitles release];
  [servicesMenu release];
  [disabledPath release];
  [servicesPath release];
  [disabledStamp release];
  [servicesStamp release];
  [allDisabled release];
  [allServices release];
  [super dealloc];
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

- (void) loadServices
{
  NSFileManager         *mgr = [NSFileManager defaultManager];
  NSDate		*stamp = [NSDate date];
  BOOL			changed = NO;

  if ([mgr fileExistsAtPath: disabledPath])
    {
      NSDictionary	*attr;
      NSDate		*mod;

      attr = [mgr fileAttributesAtPath: disabledPath
			  traverseLink: YES];
      mod = [attr objectForKey: NSFileModificationDate];
      if (disabledStamp == nil || [disabledStamp laterDate: mod] == mod)
	{
	  NSData	*data;
	  id		plist = nil;

	  data = [NSData dataWithContentsOfFile: disabledPath];
	  if (data)
	    {
	      plist = [NSDeserializer deserializePropertyListFromData: data
						    mutableContainers: NO];
	      if (plist)
		{
		  NSMutableSet	*s;
		  stamp = mod;
		  changed = YES;
		  s = (NSMutableSet*)[NSMutableSet setWithArray: plist];
		  ASSIGN(allDisabled, s);
		}
	    }
	}
    }
  /* Track most recent version of file loaded or last time we checked */
  ASSIGN(disabledStamp, stamp);

  stamp = [NSDate date];
  if ([mgr fileExistsAtPath: servicesPath])
    {
      NSDictionary	*attr;
      NSDate		*mod;

      attr = [mgr fileAttributesAtPath: servicesPath
			  traverseLink: YES];
      mod = [attr objectForKey: NSFileModificationDate];
      if (servicesStamp == nil || [servicesStamp laterDate: mod] == mod)
	{
	  NSData	*data;
	  id		plist = nil;

	  data = [NSData dataWithContentsOfFile: servicesPath];
	  if (data)
	    {
	      plist = [NSDeserializer deserializePropertyListFromData: data
						    mutableContainers: YES];
	      if (plist)
		{
		  stamp = mod;
		  ASSIGN(allServices, plist);
		  changed = YES;
		}
	    }
	}
    }
  /* Track most recent version of file loaded or last time we checked */
  ASSIGN(servicesStamp, stamp);
  if (changed)
    {
      [self rebuildServices];
    }
}

- (NSDictionary*) menuServices
{
  if (allServices == nil)
    {
      [self loadServices];
    }
  return title2info;
}

- (void) rebuildServices
{
  NSDictionary          *services;
  NSUserDefaults        *defs;
  NSMutableArray        *newLang;
  NSMutableSet          *alreadyFound;
  NSMutableDictionary   *newServices;
  unsigned              pos;

  if (allServices == nil)
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

  services = [allServices objectForKey: @"ByService"];

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

	      /* See if this service item is disabled. */
              if ([allDisabled member: menuItem] != nil)
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
  if (servicesMenu)
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
  NSString          *appName;

  appName = [[[NSProcessInfo processInfo] processName] lastPathComponent];
  NSRegisterServicesProvider(self, appName);
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
  return [GNUListener servicesProvider];
}

- (void) setServicesMenu: (NSMenu*)aMenu
{
  ASSIGN(servicesMenu, aMenu);
  [self rebuildServicesMenu];
}

- (void) setServicesProvider: (id)anObject
{
  [GNUListener setServicesProvider: anObject];
}

- (int) setShowsServicesMenuItem: (NSString*)item to: (BOOL)enable
{
  NSData	*d;

  [self loadServices];
  if (allDisabled == nil)
    allDisabled = [[NSMutableSet setWithCapacity: 1] retain];
  if (enable)
    [allDisabled removeObject: item];
  else
    [allDisabled addObject: item];
  d = [NSSerializer serializePropertyList: [allDisabled allObjects]];
  if ([d writeToFile: disabledPath atomically: YES] == YES)
    return 0;
  return -1;
}

- (BOOL) showsServicesMenuItem: (NSString*)item
{
  [self loadServices];
  if ([allDisabled member: item] == nil)
    return YES;
  return NO;
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
  if (servicesMenu && [[application mainMenu] autoenablesItems])
    {
      NSMenuMatrix	*menuCells;
      NSArray   	*a;
      unsigned  	i;
      NSMenu		*mainMenu = [application mainMenu];
      BOOL		found = NO;

      a = [mainMenu itemArray];
      for (i = 0; i < [a count]; i++)
	if ([[a objectAtIndex: i] target] == servicesMenu)
	  found = YES;
      if (found == NO)
	{
	  NSLog(@"Services menu not in main menu!\n");
	  return;
	}

      menuCells = [servicesMenu menuCells];
      a = [menuCells itemArray];

      for (i = 0; i < [a count]; i++)
        {
          NSCell        *cell = [a objectAtIndex: i];
	  BOOL		wasEnabled = [cell isEnabled];
	  BOOL		shouldBeEnabled = [self validateMenuItem: cell];

          if (wasEnabled != shouldBeEnabled)
            {
              [cell setEnabled: shouldBeEnabled];
	      [menuCells setNeedsDisplayInRect: [menuCells cellFrameAtRow: i]];
            }
        }
	/* FIXME - only doing this here 'cos auto-display doesn't work */
	if ([menuCells needsDisplay])
	  [menuCells display];
    }
}

@end /* GNUServicesManager */


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
  NSConnection		*connection;
  NSString		*message;
  NSString		*selName;
  SEL			msgSel;
  NSString		*userData;
  IMP			msgImp;
  NSString		*error = nil;

  service = [[manager menuServices] objectForKey: serviceItem]; 
  if (service == nil)
    return NO;			/* No matching service.	*/

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
  msgSel = NSSelectorFromString(selName);

  /*
   *	If there is no selector - we need to generate one with the
   *	appropriate types.
   */
  if (msgSel == 0)
    {
      NSMethodSignature	*sig;
      const char	*name;
      const char	*type;

      sig = [NSMethodSignature signatureWithObjCTypes: "v@:@@^@"];
      type = [sig methodType];
      name = [selName cString];
      msgSel = sel_register_typed_name(name, type);
    }

  provider = [NSConnection rootProxyForConnectionWithRegisteredName: port  
							       host: @""];
  if (provider == nil)
    {
      if ([[NSWorkspace sharedWorkspace] launchApplication: appPath] == NO)
	{
	  return NO;		/* Unable to launch.	*/
	}

      provider = [NSConnection rootProxyForConnectionWithRegisteredName: port  
								   host: @""];
      while (provider == nil && [finishBy timeIntervalSinceNow] > 1.0)
	{
	  NSRunLoop	*loop = [NSRunLoop currentRunLoop];
	  NSDate	*next;

	  [NSTimer scheduledTimerWithTimeInterval: 1.0
				       invocation: nil
					  repeats: NO];
	  next = [NSDate dateWithTimeIntervalSinceNow: 5.0];
	  [loop runUntilDate: next];
	  provider = [NSConnection
			rootProxyForConnectionWithRegisteredName: port  
							    host: @""];
	}
    }

  if (provider == nil)
    {
      return NO;		/* Unable to contact.	*/
    }
  connection = [(NSDistantObject*)provider connectionForProxy];
  seconds = [finishBy timeIntervalSinceNow];
  [connection setRequestTimeout: seconds];
  [connection setReplyTimeout: seconds];

  msgImp = get_imp(fastClass(provider), msgSel);
  NS_DURING
    {
      (*msgImp)(provider, msgSel, pboard, userData, &error);
    }
  NS_HANDLER
    {
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%s", [[localException reason] cString]];
    }
  NS_ENDHANDLER

  if (error != nil)
    {
      NSLog(error);
      return NO;
    }

  return YES;
}

int
NSSetShowsServicesMenuItem(NSString *name, BOOL enabled)
{

  return [[GNUServicesManager manager] setShowsServicesMenuItem: name
							     to: enabled];
}

BOOL
NSShowsServicesMenuItem(NSString * name)
{
  return [[GNUServicesManager manager] showsServicesMenuItem: itemName];
}

