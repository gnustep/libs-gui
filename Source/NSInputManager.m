/*
    NSInputManager.m

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date:   March, 2004

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
#include "AppKit/NSInputServer.h"
#include "AppKit/NSInputManager.h"

#if !defined USE_INPUT_MANAGER_UTILITIES
#define USE_INPUT_MANAGER_UTILITIES
#endif
#include "NSInputManagerPriv.h"


/* Possible keys of the file Info */
static NSString *_executableNameKey	= @"ExecutableName";
static NSString *_connectionNameKey	= @"ConnectionName";
static NSString *_displayNameKey	= @"DisplayName";
static NSString *_defaultKeyBindingsKey	= @"DefaultKeyBindings";
static NSString *_localizedNamesKey	= @"LocalizedNames";
static NSString *_languageNameKey	= @"LanguageName";

/*
    Possible prefixes are 
	(1) $(GNUSTEP_USER_ROOT)/Library/InputManager and
	(2) $(GNUSTEP_SYSTEM_ROOT)/Library/InputManager.
   The file Info is to be searched in that order.
 */
static NSString *_parentComponent	= @"InputManagers";
static NSString *_extName		= @"app";
static NSString *_resourcesComponent	= @"Resources";
static NSString *_infoFileName		= @"Info";



@interface NSInputManager (Private)
+ (void)addToInputServerList: (id)inputServer;
+ (void)removeFromInputServerList: (id)inputServer;

- (BOOL)readInputServerInfo: (NSString *)inputServerName;
- (BOOL)createKeyBindingTable;
- (BOOL)establishConnectionToInputServer: (NSString *)host;


- (void)setServerInfo: (id)info;
- (IMInputServerInfo *)serverInfo;

- (void)setServerProxy: (id)proxy;
- (id)serverProxy;

- (void)setKeyBindingTable: (IMKeyBindingTable *)table;
- (IMKeyBindingTable *)keyBindingTable;

- (void)setTextView: (id)aTextView;
- (id)textView;

- (id)lookUpTextInputViewInWindow: (NSWindow *)window;

- (NSString *)standardKeyBindingAbsolutePath;
- (NSString *)defaultKeyBindingAbsolutePath;

/* For communication to other players */
- (void)becomeObserverOfConnection;
- (void)becomeObserverOfClient;
- (void)resignObserverOfConnection;
- (void)resignObserverOfClient;

- (void)clientBecomeActive: (NSNotification *)aNotification;
- (void)clientResignActive: (NSNotification *)aNotification;
- (void)clientPossiblyEnabled: (NSNotification *)aNotification;
- (void)clientPossiblyDisabled: (NSNotification *)aNotification;
- (void)lostConnection: (NSNotification *)aNotification;
@end /* @interface NSInputManager (Private) */


/* To ease traffic jam */
@protocol IMUnifiedProtocolForInputServer <NSInputServiceProvider,
                                         NSInputServerMouseTracker>
@end /* @protocol IMUnifiedProtocolForInputServer */


/* Class encapsulating input server's Info file */
@interface IMInputServerInfo : NSObject
{
  NSString	*serverName;
  NSDictionary	*info;
}

- (id)initWithName: (NSString *)inputServerName;

- (void)setServerName: (NSString *)inputServerName;
- (NSString *)serverName;

- (void)setInfo: (NSDictionary *)inputServerInfo;
- (NSDictionary *)info;

/* Value for each key */
- (NSString *)executableName;
- (NSString *)connectionName;
- (NSString *)displayName;
- (NSString *)defaultKeyBindings;
- (NSString *)localizedName;
- (NSString *)languageName;

- (NSString *)serverHomeDir;
- (NSString *)infoAbsolutePath;
- (NSString *)executableAbsolutePath;
- (NSString *)defaultKeyBindingsAbsolutePath;
@end /* @interface ServerInfo : NSObject */


@implementation NSInputManager

static NSMutableArray *_inputServerList = nil;


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
  point = [[self textView] convertPoint: [theMouseEvent locationInWindow]
			       fromView: nil];
  index = [[self textView] characterIndexForPoint: [NSEvent mouseLocation]];

  switch ([theMouseEvent type])
    {
    case NSLeftMouseDown:
      consumed = [serverProxy mouseDownOnCharacterIndex: index
					   atCoordinate: point
					   withModifier: flags
						 client: [self textView]];
      break;

    case NSLeftMouseDragged:
      consumed = [serverProxy mouseDraggedOnCharacterIndex: index
					      atCoordinate: point
					      withModifier: flags
						    client: [self textView]];
      break;

    case NSLeftMouseUp:
      [serverProxy mouseUpOnCharacterIndex: index
			      atCoordinate: point
			      withModifier: flags
				    client: [self textView]];
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
      return nil;
    }
  if ([self standardKeyBindingAbsolutePath] == nil)
    {
      NSLog(@"%@: Couldn't read StandardKeyBinding.dict",
	    self, [self standardKeyBindingAbsolutePath]);
      [self release];
      return nil;
    }
  if (inputServerName)
    {
      if ([self readInputServerInfo: inputServerName] == NO ||
	  [self createKeyBindingTable] == NO ||
	  [self establishConnectionToInputServer: host] == NO)
	{
	  [self release];
	  return nil;
	}
    }
  else
    {
      if ([self createKeyBindingTable] == NO)
	{
	  [self release];
	  return nil;
	}
    }

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
      return [serverProxy wantsToHandleMouseEvent];
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
  [self resignObserverOfConnection];

  [NSInputManager removeFromInputServerList: self]; 

  [self setKeyBindingTable: nil];
  [self setServerProxy: nil];
  [self setServerInfo: nil];

  [super dealloc];
}


/* ----------------------------------------------------------------------------
    NSTextInput protocol methods
 --------------------------------------------------------------------------- */
- (NSAttributedString *)attributedSubstringFromRange: (NSRange)theRange
{
  return [[self textView] attributedSubstringFromRange: theRange];
}


- (unsigned int)characterIndexForPoint: (NSPoint)thePoint
{
  return [[self textView] characterIndexForPoint: thePoint];
}


- (long)conversationIdentifier
{
  return [[self textView] conversationIdentifier];
}


- (void)doCommandBySelector: (SEL)aSelector
{
  if (serverProxy)
    {
      [serverProxy doCommandBySelector: aSelector
				client: [self textView]];
    }
  else
    {
      [[self textView] doCommandBySelector: aSelector];
    }
}


- (NSRect)firstRectForCharacterRange: (NSRange)theRange
{
  return [[self textView] firstRectForCharacterRange: theRange];
}


- (BOOL)hasMarkedText
{
  return [[self textView] hasMarkedText];
}


- (void)insertText: (id)aString
{
  if (serverProxy)
    {
      [serverProxy insertText: aString
		       client: [self textView]];
    }
  else
    {
      [[self textView] insertText: aString];
    }
}


- (NSRange)markedRange
{
  return [[self textView] markedRange];
}


- (NSRange)selectedRange
{
  return [[self textView] selectedRange];
}


- (void)setMarkedText: (id)aString
	selectedRange: (NSRange)selRange
{
  return [[self textView] setMarkedText: aString
			  selectedRange: selRange];
}


- (void)unmarkText
{
  [[self textView] unmarkText];
}


- (NSArray *)validAttributesForMarkedText
{
  return [[self textView] validAttributesForMarkedText];
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
  IMInputServerInfo *info;

  if ((info = [[IMInputServerInfo alloc] initWithName: inputServerName]) == nil)
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
  IMKeyBindingTable	*table	= nil;

  if ([self wantsToInterpretAllKeystrokes] == NO)
    {
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
    }

  if ((path = [serverInfo defaultKeyBindingsAbsolutePath]))
    {
      dict = [[NSDictionary alloc] initWithContentsOfFile: path];
      [src addEntriesFromDictionary: dict];
      [dict release], dict = nil;
    }

  if ([src count] == 0)
    {
      NSLog(@"%@: Couldn't construct a key-binding table");
      [src release], src = nil;
      return NO;
    }

  table = [[IMKeyBindingTable alloc] initWithKeyBindingDictionary: src];
  if (table == nil)
    {
      NSLog(@"%@: Couldn't construct a key-binding table");
      [src release], src = nil;
      return NO;
    }
  [self setKeyBindingTable: table];
  [table release], table = nil;

  return YES;
}


/* Return YES if succeeded, NO otherwise. */
- (BOOL)establishConnectionToInputServer: (NSString *)host
{
  NSString	*name	    = [serverInfo connectionName];
  NSString	*exec	    = [serverInfo executableAbsolutePath];
  const float	interval    = 5.0;
  int		count	    = 0;
  const int	limit	    = 3;
  id		proxy;

  if (host == nil)
    {
      NSLog(@"%@: Host name wasn't specified", self);
      return NO;
    }

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
      NSLog(@"%@: Failed to connect to server", self);
      return NO;
    }

  [self setServerProxy: proxy];

  [self becomeObserverOfConnection];
  [proxy setProtocolForProxy: @protocol(IMUnifiedProtocolForInputServer)];
  [proxy inputClientBecomeActive: self];


  return YES;
}


- (void)setServerInfo: (id)info
{
  [info retain];
  [serverInfo release];
  serverInfo = info;
}


- (IMInputServerInfo *)serverInfo
{
  return serverInfo;
}


- (void)setServerProxy: (id)proxy
{
  [proxy retain];
  [serverProxy release];
  serverProxy = proxy;
}


- (id)serverProxy
{
  return serverProxy;
}


- (void)setKeyBindingTable: (IMKeyBindingTable *)table
{
  [table retain];
  [keyBindingTable release];
  keyBindingTable = table;
}


- (IMKeyBindingTable *)keyBindingTable
{
  return keyBindingTable;
}


- (void)setTextView: (id)aTextView
{
  /* Don't retain or cache it. */
  textView = aTextView;
}


- (id)textView
{
  return textView;
}


- (id)lookUpTextInputViewInWindow: (NSWindow *)window
{
  id obj = [window firstResponder];

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
  path = [path stringByAppendingPathComponent: _parentComponent];
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
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  [center addObserver: self
	     selector: @selector(lostConnection:)
		 name: NSConnectionDidDieNotification
	       object: [serverProxy connectionForProxy]];
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
  [center addObserver: self
	     selector: @selector(clientPossiblyEnabled:)
		 name: NSWindowDidBecomeKeyNotification
	       object: nil];
  [center addObserver: self
	     selector: @selector(clientPossiblyDisabled:)
		 name: NSWindowDidResignKeyNotification
	       object: nil];
}


- (void)resignObserverOfConnection
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  [center removeObserver: self
		    name: NSConnectionDidDieNotification
		  object: [serverProxy connectionForProxy]];
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
  [center removeObserver: self
		    name: NSWindowDidBecomeKeyNotification
		  object: nil];
  [center removeObserver: self
		    name: NSWindowDidResignKeyNotification
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


- (void)clientPossiblyEnabled: (NSNotification *)aNotification
{
  id obj = [self lookUpTextInputViewInWindow: [aNotification object]];

  if (obj)
    {
      [self setTextView: obj];
      [serverProxy inputClientEnabled: obj];
    }
}


- (void)clientPossiblyDisabled: (NSNotification *)aNotification
{
  id obj = [self lookUpTextInputViewInWindow: [aNotification object]];

  if (obj)
    {
      [serverProxy inputClientDisabled: obj];
      if (obj == [self textView])
	{
	  [self setTextView: nil];
	}
    }
}


- (void)lostConnection: (NSNotification *)aNotification
{
  NSMutableDictionary	*src	= [[NSMutableDictionary alloc] init];
  NSDictionary		*dict	= nil;
  NSString		*path	= nil;
  IMKeyBindingTable	*table	= nil;

  NSLog(@"%@: Lost connection to input server %@", [serverProxy serverName]);
  /* Release all resources to related to the server */
  [self resignObserverOfConnection];
  [self setKeyBindingTable: nil];
  [self setServerProxy: nil];
  [self setServerInfo: nil];

  /* To fall back to the stand-alone internal input manager, re-initialize
     the key-binding table.  No error check because this is the last resort. */
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
  table = [[IMKeyBindingTable alloc] initWithKeyBindingDictionary: src];
  [self setKeyBindingTable: table];
  [table release], table = nil;
}

@end /* @implementation NSInputManager (Private) */


@implementation IMInputServerInfo

- (id)initWithName: (NSString *)inputServerName
{
  NSString	*path;
  NSDictionary	*dict;

  if ((self = [super init]) == nil)
    {
      NSLog(@"NSInputManager: Initialization for %@ failed",
	    inputServerName);
      return nil;
    }

  if (inputServerName == nil)
    {
      NSLog(@"NSInputManager: Input server name wasn't specified");
      [self release];
      return nil;
    }
  [self setServerName: inputServerName];

  if ((path = [self infoAbsolutePath]) == nil)
    {
      NSLog(@"%@: Couldn't find Info for %@", self, inputServerName);
      [self release];
      return nil;
    }
  if ((dict = [NSDictionary dictionaryWithContentsOfFile: path]) == nil)
    {
      NSLog(@"%@: Couldn't read Info for %@", self, inputServerName);
      [self release];
      return nil;
    }
  [self setInfo: dict];

  return self;
}


- (void)dealloc
{
  [self setInfo: nil];
  [self setServerName: nil];
  [super dealloc];
}


- (void)setServerName: (NSString *)inputServerName
{
  [inputServerName retain];
  [serverName release];
  serverName = inputServerName;
}


- (NSString *)serverName
{
  return serverName;
}


- (void)setInfo: (NSDictionary *)inputServerInfo
{
  [inputServerInfo retain];
  [info release];
  info = inputServerInfo;
}


- (NSDictionary *)info
{
  return info;
}


- (NSString *)executableName
{
  return [info objectForKey: _executableNameKey];
}


- (NSString *)connectionName
{
  return [info objectForKey: _connectionNameKey];
}


- (NSString *)displayName
{
  return [info objectForKey: _displayNameKey];
}


- (NSString *)defaultKeyBindings
{
  return [info objectForKey: _defaultKeyBindingsKey];
}


- (NSString *)localizedName
{
  NSString	*lang;
  NSDictionary	*dict;
  NSEnumerator	*keyEnum;
  id		key;

  if ((lang = [[NSUserDefaults standardUserDefaults]
       stringForKey: NSLanguageName]) == nil)
    {
      return [self displayName];
    }

  if ((dict = [info objectForKey: _localizedNamesKey]) == nil)
    {
      return [self displayName];
    }

  keyEnum = [dict keyEnumerator];
  while ((key = [keyEnum nextObject]) != nil)
    {
      if ([key isKindOfClass: [NSString class]] == NO)
	{
	  continue;
	}

      if ([(NSString *)key isEqualToString: lang])
	{
	  return [dict objectForKey: key];
	}
    }

  return [self displayName];
}


- (NSString *)languageName
{
  return [info objectForKey: _languageNameKey];
}


/* Return nil if the directory is not found. */
- (NSString *)serverHomeDir
{
  NSArray	*prefixes   = nil;
  NSEnumerator	*objEnum    = nil;
  id		obj	    = nil;
  NSString	*path	    = nil;
  BOOL		isDir;

  prefixes = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
						 NSUserDomainMask
						 | NSSystemDomainMask,
						 YES);
  objEnum = [prefixes objectEnumerator];
  /* Assuming the user domain directory comes first, */
  for (path = nil; (obj = [objEnum nextObject]) != nil; path = nil)
    {
      path = [NSString stringWithString: obj];
      path = [path stringByAppendingPathComponent: _parentComponent];
      path = [path stringByAppendingPathComponent: serverName];
      path = [path stringByAppendingPathExtension: _extName];

      if ([[NSFileManager defaultManager] fileExistsAtPath: path
					       isDirectory: &isDir] && isDir)
	{
	  break;
	}
    }
  return path;
}


/* Return nil if the file is not readable. */
- (NSString *)infoAbsolutePath
{
  NSString *absPath = [self serverHomeDir];

  absPath = [absPath stringByAppendingPathComponent: _resourcesComponent];
  absPath = [absPath stringByAppendingPathComponent: _infoFileName];

  if ([[NSFileManager defaultManager] isReadableFileAtPath: absPath] == NO)
    {
      absPath = nil;
    }

  return absPath;
}


/* Return nil if the file is not executable. */
- (NSString *)executableAbsolutePath
{
  NSString *absPath = [self serverHomeDir];
  NSString *relPath = [self executableName];

  absPath = [absPath stringByDeletingLastPathComponent];
  absPath = [absPath stringByAppendingPathComponent: relPath];

  if ([[NSFileManager defaultManager] isExecutableFileAtPath: absPath] == NO)
    {
      absPath = nil;
    }

  return absPath;
}


/* Return nil if the file is not readable. */
- (NSString *)defaultKeyBindingsAbsolutePath
{
  NSString *absPath = [self serverHomeDir];
  NSString *file = [self defaultKeyBindings];

  absPath = [absPath stringByAppendingPathComponent: _resourcesComponent];
  absPath = [absPath stringByAppendingPathComponent: file];

  if ([[NSFileManager defaultManager] isReadableFileAtPath: absPath] == NO)
    {
      absPath = nil;
    }
  return absPath;
}

@end /* @implementation	IMInputServerInfo */
