/*
    NSInputManager.m

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date:   March 2004

    This file is part of the GNUstep GUI Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; see the file COPYING.LIB.
    If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <Foundation/NSString.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSDistantObject.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSAutoreleasePool.h>
#include "AppKit/NSEvent.h"
#include "AppKit/NSResponder.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSView.h"
#include "AppKit/NSText.h"
#include "AppKit/NSInputServer.h"
#include "AppKit/NSInputManager.h"
#include "GSTIMInputServerInfo.h"
#include "GSTIMKeyBindingTable.h"
#include "GSTIMInputServerMenu.h"
#include "NSInputManagerPriv.h"


@interface NSInputManager (Private)
+ (void)addToInputServerList: (id)inputServer;
+ (void)removeFromInputServerList: (id)inputServer;

- (BOOL)readInputServerInfo: (NSString *)inputServerName;
- (BOOL)createKeyBindingTable;
- (BOOL)establishConnectionToInputServer: (NSString *)host;


- (void)setServerInfo: (id)info;
- (GSTIMInputServerInfo *)serverInfo;

- (void)setServerProxy: (id)proxy;
- (id)serverProxy;

- (void)setKeyBindingTable: (GSTIMKeyBindingTable *)table;
- (GSTIMKeyBindingTable *)keyBindingTable;

- (void)setPendingCharacters: (NSMutableArray *)array;
- (NSMutableArray *)pendingCharacters;

- (id)clientView;

- (NSString *)standardKeyBindingAbsolutePath;
- (NSString *)defaultKeyBindingAbsolutePath;

/* For communication to other players */
- (void)becomeObserverOfConnection;
- (void)becomeObserverOfClient;
- (void)resignObserverOfConnection;
- (void)resignObserverOfClient;

- (void)clientBecomeActive: (NSNotification *)aNotification;
- (void)clientResignActive: (NSNotification *)aNotification;
- (void)connectionDidDie: (NSNotification *)aNotification;
@end /* @interface NSInputManager (Private) */


/* To ease traffic jam */
@protocol IMUnifiedProtocolForInputServer <NSInputServiceProvider,
                                           NSInputServerMouseTracker>
@end /* @protocol IMUnifiedProtocolForInputServer */


@implementation NSInputManager

static NSMutableArray *_inputServerList = nil;


+ (void)initialize
{
  static BOOL done = NO;

  if (done == NO)
    {
      [GSTIMInputServerMenu sharedInstance];
      done = YES;
    }
}


+ (NSInputManager *)currentInputManager
{
  return [_inputServerList lastObject];
}


/* Deprecated */
+ (void)cycleToNextInputLanguage: (id)sender
{ }


/* Deprecated */
+ (void)cycleToNextInputServerInLanguage: (id)sender
{ }


- (BOOL)handleMouseEvent: (NSEvent *)theMouseEvent
{
  unsigned int	flags;
  NSPoint	point;
  unsigned	index;
  BOOL		consumed;

  flags = [theMouseEvent modifierFlags];
  point = [[self clientView] convertPoint: [theMouseEvent locationInWindow]
			     fromView: nil];
  index = [[self clientView] characterIndexForPoint: [NSEvent mouseLocation]];

  switch ([theMouseEvent type])
    {
    case NSLeftMouseDown:
      consumed = [serverProxy mouseDownOnCharacterIndex: index
					   atCoordinate: point
					   withModifier: flags
						 client: [self clientView]];
      break;

    case NSLeftMouseDragged:
      consumed = [serverProxy mouseDraggedOnCharacterIndex: index
					      atCoordinate: point
					      withModifier: flags
						    client: [self clientView]];
      break;

    case NSLeftMouseUp:
      [serverProxy mouseUpOnCharacterIndex: index
			      atCoordinate: point
			      withModifier: flags
				    client: [self clientView]];
      consumed = YES;
      break;

    default:
      consumed = NO;
      break;
    }
  
  return consumed;
}


/* Deprecated */
- (NSImage *)image
{ return nil; }


- (NSInputManager *)initWithName: (NSString *)inputServerName
			    host: (NSString *)host
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  if ((self = [super init]) == nil)
    {
      NSLog(@"NSInputManager: Initialization failed");
      [pool release];
      return nil;
    }
  if ([self standardKeyBindingAbsolutePath] == nil)
    {
      NSLog(@"%@: Couldn't read StandardKeyBinding.dict",
	    self, [self standardKeyBindingAbsolutePath]);
      [pool release], pool = nil;
      [self release];
      return nil;
    }
  if (inputServerName)
    {
      if ([self readInputServerInfo: inputServerName] == NO ||
	  [self createKeyBindingTable] == NO ||
	  [self establishConnectionToInputServer: host] == NO)
	{
	  [pool release], pool = nil;
	  [self release];
	  return nil;
	}
    }
  else
    {
      if ([self createKeyBindingTable] == NO)
	{
	  [pool release], pool = nil;
	  [self release];
	  return nil;
	}
    }

  [self setPendingCharacters: [[NSMutableArray alloc] init]];

  [self becomeObserverOfClient];
  [NSInputManager addToInputServerList: self];

  [pool release], pool = nil;
  return self;
}


- (NSString *)language
{
  return [serverInfo languageName];
}


- (NSString *)localizedInputManagerName
{
  return [serverInfo localizedName];
}


- (void)markedTextAbandoned: (id)client
{
  [serverProxy markedTextAbandoned: client];
}


- (void)markedTextSelectionChanged: (NSRange)newSel
			    client: (id)client
{
  [serverProxy markedTextSelectionChanged: newSel
				   client: client];
}


/* Deprecated */
- (NSInputServer *)server
{
  return serverProxy;
}


- (BOOL)wantsToDelayTextChangeNotifications
{
  if (serverProxy)
    {
      return [serverProxy wantsToDelayTextChangeNotifications];
    }
  else
    {
      return YES;
    }
}


- (BOOL)wantsToHandleMouseEvents
{
  if (serverProxy)
    {
      return [serverProxy wantsToHandleMouseEvents];
    }
  else
    {
      return NO;
    }
}


- (BOOL)wantsToInterpretAllKeystrokes
{
  if (serverProxy)
    {
      return [serverProxy wantsToInterpretAllKeystrokes];
    }
  else
    {
      return NO;
    }
}


- (void)dealloc
{
  [serverProxy terminate: self];

  [self resignObserverOfClient];

  [NSInputManager removeFromInputServerList: self]; 

  [self setPendingCharacters: nil];
  [self setServerProxy: nil];
  [self setKeyBindingTable: nil];
  [self setServerInfo: nil];

  [super dealloc];
}


/* ----------------------------------------------------------------------------
    NSTextInput protocol methods
 --------------------------------------------------------------------------- */
- (NSAttributedString *)attributedSubstringFromRange: (NSRange)theRange
{
  return [[self clientView] attributedSubstringFromRange: theRange];
}


- (unsigned int)characterIndexForPoint: (NSPoint)thePoint
{
  return [[self clientView] characterIndexForPoint: thePoint];
}


- (long)conversationIdentifier
{
  return [[self clientView] conversationIdentifier];
}


- (void)doCommandBySelector: (SEL)aSelector
{
  if (serverProxy)
    {
      [serverProxy doCommandBySelector: aSelector
				client: [self clientView]];
    }
  else
    {
      [[self clientView] doCommandBySelector: aSelector];
    }
}


- (NSRect)firstRectForCharacterRange: (NSRange)theRange
{
  return [[self clientView] firstRectForCharacterRange: theRange];
}


- (BOOL)hasMarkedText
{
  return [[self clientView] hasMarkedText];
}


- (void)insertText: (id)aString
{
  if (serverProxy)
    {
      [serverProxy insertText: aString
		       client: [self clientView]];
    }
  else
    {
      [[self clientView] insertText: aString];
    }
}


- (NSRange)markedRange
{
  return [[self clientView] markedRange];
}


- (NSRange)selectedRange
{
  return [[self clientView] selectedRange];
}


- (void)setMarkedText: (id)aString
	selectedRange: (NSRange)selRange
{
  return [[self clientView] setMarkedText: aString
			  selectedRange: selRange];
}


- (void)unmarkText
{
  [[self clientView] unmarkText];
}


- (NSArray *)validAttributesForMarkedText
{
  return [[self clientView] validAttributesForMarkedText];
}

@end /* @implementation NSInputManager */


@implementation NSInputManager (Private)

+ (void)addToInputServerList: (id)inputServer
{
  if (_inputServerList == nil)
    {
      _inputServerList = [[NSMutableArray alloc] init];
    }
  [_inputServerList addObject: inputServer];
}


+ (void)removeFromInputServerList: (id)inputServer
{
  [_inputServerList removeObjectIdenticalTo: inputServer];
  if ([_inputServerList count] == 0)
    {
      [_inputServerList release];
      _inputServerList = nil;
    }
}


/* Return YES if succeeded, NO otherwise. */
- (BOOL)readInputServerInfo: (NSString *)inputServerName
{
  GSTIMInputServerInfo *info;

  info = [[GSTIMInputServerInfo alloc] initWithName: inputServerName];
  if (info == nil)
    {
      NSLog(@"%@: Couldn't read Info for %@", self, inputServerName);
      return NO;
    }
  else if ([info executableAbsolutePath] == nil)
    {
      NSLog(@"%@: Couldn't find the executable for %@", self, inputServerName);
      [self release];
      return NO;
    }
  [self setServerInfo: info];
  [info release], info = nil;
  return YES;
}


/* Return YES if succeeded, NO otherwise. */
- (BOOL)createKeyBindingTable
{
  NSMutableDictionary	*src	= [[NSMutableDictionary alloc] init];
  NSDictionary		*dict	= nil;
  NSString		*path	= nil;
  GSTIMKeyBindingTable	*table	= nil;

  if ((path = [self standardKeyBindingAbsolutePath]) == nil)
    {
      NSLog(@"%@: Couldn't read StandardKeyBinding.dict", self);
      return NO;
    }
  else
    {
      dict = [[NSDictionary alloc] initWithContentsOfFile: path];
      [src addEntriesFromDictionary: dict];
      [dict release], dict = nil;
    }

  if ((path = [self defaultKeyBindingAbsolutePath]))
    {
      dict = [[NSDictionary alloc] initWithContentsOfFile: path];
      [src addEntriesFromDictionary: dict];
      [dict release], dict = nil;
    }

  if ((path = [serverInfo defaultKeyBindingsAbsolutePath]))
    {
      dict = [[NSDictionary alloc] initWithContentsOfFile: path];
      [src addEntriesFromDictionary: dict];
      [dict release], dict = nil;
    }

  if ([src count] == 0)
    {
      NSLog(@"%@: Couldn't construct key-binding table");
      [src release], src = nil;
      return NO;
    }

  table = [[GSTIMKeyBindingTable alloc] initWithKeyBindingDictionary: src];
  if (table == nil)
    {
      NSLog(@"%@: Couldn't construct key-binding table");
      [src release], src = nil;
      return NO;
    }
  [src release], src = nil;

  [self setKeyBindingTable: table];
  [table release], table = nil;

  return YES;
}


/* Return YES if succeeded, NO otherwise. */
- (BOOL)establishConnectionToInputServer: (NSString *)host
{
  NSString	*name	    = [serverInfo connectionName];
  NSString	*exec	    = [serverInfo executableAbsolutePath];
  const float	interval    = 2.0;
  int		count	    = 0;
  const int	limit	    = 3;
  id		proxy;

  do
    {
      proxy = [NSConnection rootProxyForConnectionWithRegisteredName: name
								host: host];
      if (proxy)
	{
	  break;
	}

      NSLog(@"%@: Trying to launch %@", self, exec);
      [NSTask launchedTaskWithLaunchPath: exec
			       arguments: nil];
      [NSTimer scheduledTimerWithTimeInterval: interval
				   invocation: nil
				      repeats: NO];
      [[NSRunLoop currentRunLoop] runUntilDate:
			    [NSDate dateWithTimeIntervalSinceNow: interval]];
    }
  while (count++ < limit && proxy == nil);

  if (proxy == nil)
    {
      NSLog(@"%@: Failed to launch %@", self, exec);
      return NO;
    }
  [proxy setProtocolForProxy: @protocol(IMUnifiedProtocolForInputServer)];

  [self setServerProxy: proxy];

  return YES;
}


- (void)setServerInfo: (id)info
{
  [info retain];
  [serverInfo release];
  serverInfo = info;
}


- (GSTIMInputServerInfo *)serverInfo
{
  return serverInfo;
}


- (void)setServerProxy: (id)proxy
{
  [proxy retain];
  [self resignObserverOfConnection];
  [serverProxy release];
  serverProxy = proxy;
  [self becomeObserverOfConnection];
}


- (id)serverProxy
{
  return serverProxy;
}


- (void)setKeyBindingTable: (GSTIMKeyBindingTable *)table
{
  [table retain];
  [keyBindingTable release];
  keyBindingTable = table;
}


- (GSTIMKeyBindingTable *)keyBindingTable
{
  return keyBindingTable;
}


- (void)setPendingCharacters: (NSMutableArray *)array
{
  [array retain];
  [pendingCharacters release];
  pendingCharacters = array;
}


- (NSMutableArray *)pendingCharacters
{
  return pendingCharacters;
}


- (id)clientView
{
  id obj = [[[NSApplication sharedApplication] keyWindow] firstResponder];

  while (obj)
    {
      if ([obj conformsToProtocol: @protocol(NSTextInput)])
	{
	  return obj;
	}
      if ([obj isKindOfClass: [NSResponder class]])
	{
	  obj = [obj nextResponder];
	}
      else
	{
	  obj = nil;
	}
    }
  return nil;
}


/* Return nil if not readable. */
- (NSString *)standardKeyBindingAbsolutePath
{
  NSArray *array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
						       NSSystemDomainMask,
						       YES);
  NSString *path = [array objectAtIndex: 0];
  path = [path stringByAppendingPathComponent: @"InputManagers"];
  path = [path stringByAppendingPathComponent: @"StandardKeyBinding"];
  path = [path stringByAppendingPathExtension: @"dict"];
  if ([[NSFileManager defaultManager] isReadableFileAtPath: path] == NO)
    {
      path = nil;
    }
  return path;
}


/* Return nil if not readable. */
- (NSString *)defaultKeyBindingAbsolutePath;
{
  NSArray *array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
						       NSUserDomainMask,
						       YES);
  NSString *path = [array objectAtIndex: 0];
  path = [path stringByAppendingPathComponent: @"KeyBindings"];
  path = [path stringByAppendingPathComponent: @"DefaultKeyBinding"];
  path = [path stringByAppendingPathExtension: @"dict"];
  if ([[NSFileManager defaultManager] isReadableFileAtPath: path] == NO)
    {
      path = nil;
    }
  return path;
}


- (void)becomeObserverOfConnection
{
  NSNotificationCenter *center;
  
  if (serverProxy)
    {
      center = [NSNotificationCenter defaultCenter];
      [center addObserver: self
		 selector: @selector(connectionDidDie:)
		     name: NSConnectionDidDieNotification
		   object: [serverProxy connectionForProxy]];
    }
}


- (void)becomeObserverOfClient
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  [center addObserver: self
	     selector: @selector(clientBecomeActive:)
		 name: NSApplicationDidBecomeActiveNotification
	       object: nil];
  [center addObserver: self
	     selector: @selector(clientResignActive:)
		 name: NSApplicationWillResignActiveNotification
	       object: nil];
}


- (void)resignObserverOfConnection
{
  NSNotificationCenter *center;

  if (serverProxy)
    {
      center = [NSNotificationCenter defaultCenter];
      [center removeObserver: self
			name: NSConnectionDidDieNotification
		      object: [serverProxy connectionForProxy]];
    }
}


- (void)resignObserverOfClient
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  [center removeObserver: self
		    name: NSApplicationDidBecomeActiveNotification
		  object: nil];
  [center removeObserver: self
		    name: NSApplicationWillResignActiveNotification
		  object: nil];
}


- (void)clientBecomeActive: (NSNotification *)aNotification
{
  [serverProxy inputClientBecomeActive: self];
}


- (void)clientResignActive: (NSNotification *)aNotification
{
  [serverProxy inputClientResignActive: self];
}


- (void)connectionDidDie: (NSNotification *)aNotification
{
  NSMutableDictionary	*src	= [[NSMutableDictionary alloc] init];
  NSDictionary		*dict	= nil;
  NSString		*path	= nil;
  GSTIMKeyBindingTable	*table	= nil;

  NSLog(@"%@: Lost connection to input server %@",
	self, [serverInfo serverName]);
  NSLog(@"%@: Invalidate key-bindings %@",
	self, [serverInfo defaultKeyBindings]); 
  /* Release all resources related to the server */
  [self setServerProxy: nil];
  [self setKeyBindingTable: nil];
  [self setServerInfo: nil];

  /* To fall back to the stand-alone internal input manager, re-initialize
     the key-binding table.  No error check because this is a last resort. */

  if ((path = [self standardKeyBindingAbsolutePath]))
    {
      dict = [[NSDictionary alloc] initWithContentsOfFile: path];
      [src addEntriesFromDictionary: dict];
      [dict release], dict = nil;
    }
  if ((path = [self defaultKeyBindingAbsolutePath]))
    {
      dict = [[NSDictionary alloc] initWithContentsOfFile: path];
      [src addEntriesFromDictionary: dict];
      [dict release], dict = nil;
    }
  table = [[GSTIMKeyBindingTable alloc] initWithKeyBindingDictionary: src];
  if (table)
    {
      NSLog(@"%@: Key-bindings re-initialized", self);
    }
  else
    {
      NSLog(@"%@: (CRITICAL) All key bindings lost", self);
    }
  [self setKeyBindingTable: table];
  [table release], table = nil;
}

@end /* @implementation NSInputManager (Private) */
