/*
    GSTIMInputServerMenu.m

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date: April 2004

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
#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSBundle.h>	/* For NSLocalizedString */
#include <Foundation/NSFileManager.h>
#include <Foundation/NSAutoreleasePool.h>
#include "AppKit/NSMenu.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSInputManager.h"
#include "GSTIMInputServerInfo.h"
#include "GSTIMInputServerMenu.h"


static GSTIMInputServerMenu *_inputServerMenu = nil;


@implementation GSTIMInputServerMenu

+ (id)sharedInstance
{
  if (_inputServerMenu == nil)
    {
      _inputServerMenu = [[GSTIMInputServerMenu alloc] init];
    }
  return _inputServerMenu;
}


- (void)collectInputServerInfos
{
  NSAutoreleasePool	*pool;
  NSArray		*domains;
  NSEnumerator		*objEnum;
  id			obj;
  NSString		*path, *path2;
  NSFileManager		*fm;
  NSArray		*dirContents;
  NSEnumerator		*dirContentsEnum;
  id			serverDir;
  NSString		*serverName;
  BOOL			isDir;
  GSTIMInputServerInfo	*info;

  pool = [[NSAutoreleasePool alloc] init];

  fm = [NSFileManager defaultManager];
  domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
						NSUserDomainMask
						| NSSystemDomainMask,
						YES);
  objEnum = [domains objectEnumerator];
  while ((obj = [objEnum nextObject]) != nil)
    {
      if ([obj isKindOfClass: [NSString class]] == NO)
	{
	  continue;
	}
      path = [obj stringByAppendingPathComponent: @"InputManagers"];
      if ((dirContents = [fm directoryContentsAtPath: path]) == nil)
	{
	  continue;
	}
      dirContentsEnum = [dirContents objectEnumerator];
      while ((serverDir = [dirContentsEnum nextObject]) != nil)
	{
	  if ([serverDir hasSuffix: @".app"] == NO)
	    {
	      continue;
	    }
	  path2 = [path stringByAppendingPathComponent: serverDir];
	  if ([fm fileExistsAtPath: path2 isDirectory: &isDir] == NO ||
	      isDir == NO)
	    {
	      continue;
	    }

	  serverName = [serverDir stringByDeletingPathExtension];
	  info = [[GSTIMInputServerInfo alloc] initWithName: serverName];
	  if (info == nil)
	    {
	      continue;
	    }
	  [serverInfos addObject: info];
	  [info release], info = nil;
	}
    }

  [pool release], pool = nil;
}


- (void)launchInputServer: (id)sender
{
  NSString	    *title;
  NSEnumerator	    *objEnum;
  id		    obj;

  if (sender == nil || 
      ([sender isKindOfClass: [NSMenuItem class]] == NO &&
       [sender conformsToProtocol: @protocol(NSMenuItem)] == NO))
    {
      return;
    }

  title = [sender title];
  objEnum = [serverInfos objectEnumerator];
  while ((obj = [objEnum nextObject]) != nil)
    {
      if ([obj isKindOfClass: [GSTIMInputServerInfo class]] == NO)
	{
	  continue;
	}
      if ([[obj localizedName] isEqualToString: title] == NO)
	{
	  continue;
	}
      [[NSInputManager currentInputManager] release];
      [[NSInputManager alloc] initWithName: [obj serverName]
				      host: nil];
    }
}


- (void)addInputServerMenuToApplication: (NSNotification *)aNotification;
{
  NSMenu	    *mainMenu;
  id <NSMenuItem>   editItem;
  NSMenu	    *editSubmenu;
  id <NSMenuItem>   inputItem;
  NSMenu	    *inputSubmenu;
  NSEnumerator	    *objEnum;
  id		    obj;
  id <NSMenuItem>   serverItem;

  if ((mainMenu = [[NSApplication sharedApplication] mainMenu]) == nil)
    {
      return;
    }

  if ((editItem = [mainMenu itemWithTitle: _(@"Edit")]) == nil)
    {
      unsigned int index = [mainMenu numberOfItems];

      index = (index > 1) ? index - 2 : index;
      editItem = [mainMenu insertItemWithTitle: _(@"Edit")
					action: (SEL)0
				 keyEquivalent: @""
				       atIndex: index];
      if (editItem == nil)
	{
	  return;
	}
    }

  if ([editItem hasSubmenu] == NO)
    {
      editSubmenu = [[NSMenu alloc] initWithTitle: _(@"Edit")];
      if (editSubmenu == nil)
	{
	  return;
	}
      [mainMenu setSubmenu: editSubmenu
		   forItem: editItem];
    }
  else
    {
      editSubmenu = [editItem submenu];
    }

  /* Create an input server menu in Edit menu. */
  inputItem = [editSubmenu addItemWithTitle: _(@"Input")
				     action: NULL
			      keyEquivalent: @""];
  inputSubmenu = [[NSMenu alloc] initWithTitle: _(@"Input")];
  [editSubmenu setSubmenu: inputSubmenu
		  forItem: inputItem];

  /* Add input server items to the input server menu. */
  objEnum = [serverInfos objectEnumerator];
  while ((obj = [objEnum nextObject]) != nil)
    {
      if ([obj isKindOfClass: [GSTIMInputServerInfo class]] == NO)
	{
	  continue;
	}
      serverItem = [inputSubmenu addItemWithTitle: [obj localizedName]
					   action: @selector(launchInputServer:)
				    keyEquivalent: @""];
      [serverItem setTarget: self];
    }
}


- (id)init
{
  NSNotificationCenter *ncenter = [NSNotificationCenter defaultCenter];

  if ((self = [super init]) == nil)
    {
      NSLog(@"GSTIMInputServerMenu: Initialization failed");
      return nil;
    }

  if ((serverInfos = [[NSMutableArray alloc] init]) == nil)
    {
      NSLog(@"%@: Initialization failed", self);
      [self release];
      return nil;
    }
  [self collectInputServerInfos];

  [ncenter addObserver: self
	      selector: @selector(addInputServerMenuToApplication:)
		  name: NSApplicationDidFinishLaunchingNotification
		object: nil];

  return self;
}


- (void)dealloc
{
  NSNotificationCenter *ncenter = [NSNotificationCenter defaultCenter];
  [ncenter removeObserver: self];

  [serverInfos release], serverInfos = nil;
  [super dealloc];
}

@end
