/*
    GSTIMInputServerInfo.m

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
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
#include "GSTIMInputServerInfo.h"


/* Keys in Info */
static NSString *_executableNameKey	= @"ExecutableName";
static NSString *_connectionNameKey	= @"ConnectionName";
static NSString *_displayNameKey	= @"DisplayName";
static NSString *_localizedNamesKey	= @"LocalizedNames";
static NSString *_defaultKeyBindingsKey	= @"DefaultKeyBindings";
static NSString *_languageNameKey	= @"LanguageName";

/* For operations on path names */
static NSString *_parentComponent	= @"InputManagers";
static NSString *_extName		= @"app";
static NSString *_resourcesComponent	= @"Resources";
static NSString *_infoFileName		= @"Info";


@implementation GSTIMInputServerInfo

- (id)init
{
  return [self initWithName: nil];
}


- (id)initWithName: (NSString *)inputServerName
{
  NSString	*path;
  NSDictionary	*dict;

  self = [super init];
  if (self == nil)
    {
      NSLog(@"TIMInputServerInfo: Initialization failed");
      return nil;
    }

  if (inputServerName == nil || [inputServerName length] == 0)
    {
      NSLog(@"%@: Server name not specified", self);
      RELEASE(self);
      return nil;
    }
  [self setServerName: inputServerName];

  if ((path = [self infoAbsolutePath]) == nil)
    {
      NSLog(@"%@: Couldn't find Info for @%", self, serverName);
      RELEASE(self);
      return nil;
    }
  if ((dict = [NSDictionary dictionaryWithContentsOfFile: path]) == nil)
    {
      NSLog(@"%@: Couldn't read Info for @%", self, serverName);
      RELEASE(self);
      return nil;
    }
  [self setInfo: dict];

  return self;
}


- (void)setServerName: (NSString *)inputServerName
{
  RETAIN(inputServerName);
  RELEASE(serverName);
  serverName = inputServerName;
}


- (NSString *)serverName
{
  return serverName;
}


- (void)setInfo: (NSDictionary *)inputServerInfo
{
  RETAIN(inputServerInfo);
  RELEASE(info);
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


- (NSString *)localizedName
{
  NSString	*lang;
  NSDictionary	*dict;
  NSEnumerator	*keyEnum;
  id		key;

  lang = [[NSUserDefaults standardUserDefaults] stringForKey: NSLanguageName];
  if (lang == nil)
    {
      return [self displayName];
    }

  dict = [info objectForKey: _localizedNamesKey];
  if (dict == nil)
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
      if ([key isEqualToString: lang])
	{
	  return [dict objectForKey: key];
	}
    }

  return [self displayName];
}


- (NSString *)defaultKeyBindings
{
  return [info objectForKey: _defaultKeyBindingsKey];
}


- (NSString *)languageName
{
  return [info objectForKey: _languageNameKey];
}


- (NSString *)serverHomeDirectory
{
  NSArray	*prefixes;
  NSEnumerator	*prefixesEnum;
  id		prefix;
  NSString	*path;
  BOOL		isDir;
  NSFileManager	*fm;

  fm = [NSFileManager defaultManager];
  prefixes = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
						 NSUserDomainMask
						 | NSSystemDomainMask,
						 YES);
  prefixesEnum = [prefixes objectEnumerator]; 
  for (path = nil; (prefix = [prefixesEnum nextObject]) != nil; path = nil)
    {
      path = [NSString stringWithString: prefix];
      path = [path stringByAppendingPathComponent: _parentComponent];
      path = [path stringByAppendingPathComponent: serverName];
      path = [path stringByAppendingPathExtension: _extName];
      if ([fm fileExistsAtPath: path isDirectory: &isDir] && isDir)
	{
	  break;
	}
    }
  return path;
}


- (NSString *)infoAbsolutePath
{
  NSString *path;
  path = [self serverHomeDirectory];
  path = [path stringByAppendingPathComponent: _resourcesComponent];
  path = [path stringByAppendingPathComponent: _infoFileName];
  if ([[NSFileManager defaultManager] isReadableFileAtPath: path] == NO)
    {
      path = nil;
    }
  return path;
}


- (NSString *)executableAbsolutePath
{
  NSString *path;

  if ([self executableName] == nil)
    {
      return nil;
    }
  path = [[self serverHomeDirectory] stringByDeletingLastPathComponent];
  path = [path stringByAppendingPathComponent: [self executableName]];
  if ([[NSFileManager defaultManager] isExecutableFileAtPath: path] == NO)
    {
      path = nil;
    }
  return path;
}


- (NSString *)defaultKeyBindingsAbsolutePath
{
  NSString  *path;

  if ([self defaultKeyBindings] == nil)
    {
      return nil;
    }
  path = [self serverHomeDirectory];
  path = [path stringByAppendingPathComponent: _resourcesComponent];
  path = [path stringByAppendingPathComponent: [self defaultKeyBindings]];
  if ([[NSFileManager defaultManager] isReadableFileAtPath: path] == NO)
    {
      path = nil;
    }
  return path;
}


- (void)dealloc
{
  [self setInfo: nil];
  [self setServerName: nil];
  [super dealloc];
}

@end /* @implementation GSTIMInputServerInfo */
