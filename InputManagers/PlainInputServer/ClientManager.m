/*
    ClientManager.m

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

#include <Foundation/NSValue.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include "ClientManager.h"


@implementation ClientManager

- (id)initWithConversationManagerClass: (Class)mClass
			  contextClass: (Class)cClass
{
  NSMutableDictionary *dict;

  if ((self = [super init]) == nil)
    {
      return nil;
    }

  if ((dict = [[NSMutableDictionary alloc] initWithCapacity: 1]) == nil)
    {
      [self release];
      return nil;
    }

  [self setConversationManagerClass: mClass];
  [self setContextClass: cClass];
  [self setClients: dict], [dict release], dict = nil;

  return self;
}


- (void)setConversationManagerClass: (Class)theClass;
{
  conversationManagerClass = theClass;
}


- (Class)conversationManagerClass
{
  return conversationManagerClass;
}


- (void)setContextClass: (Class)theClass
{
  contextClass = theClass;
}


- (Class)contextClass
{
  return contextClass;
}


- (void)setClients: (NSMutableDictionary *)aDictionary
{
  [aDictionary retain];
  [clients release];
  clients = aDictionary;
}


- (NSDictionary *)clients
{
  return clients;
}


/* Private method */
- (NSNumber *)keyFromClientID: (id)anObject
{
  return [NSNumber numberWithUnsignedInt: (unsigned int)anObject];
}


/* Private method */
- (id)clientIDFromKey: (NSNumber *)key
{
  return (id)[key unsignedIntValue];
}


/* Private method */
- (id)lookupConversationManagerOfClientID: (id)client
{
  NSEnumerator	*keyEnum;
  id		key;

  keyEnum = [clients keyEnumerator];
  while ((key = [keyEnum nextObject]) != nil)
    {
      if ([self clientIDFromKey: key] == client)
	{
	  return [clients objectForKey: key];
	}
    }
  return nil;
}


- (void)clientBecomeActive: (id)inputManager
{
  id	subManager;
  BOOL	shouldRelease;

  shouldRelease = NO;
  subManager = [self lookupConversationManagerOfClientID: inputManager];
  if (subManager == nil)
    {
      subManager
	= [[conversationManagerClass alloc] initWithContextClass: contextClass];
      if (subManager == nil)
	{
	  return;
	}
      shouldRelease = YES;
      [clients setObject: subManager
		  forKey: [self keyFromClientID: inputManager]];
    }

  [subManager activate];

  if (shouldRelease)
    {
      [subManager release], subManager = nil;
      shouldRelease = NO;
    }
}


- (void)clientResignActive: (id)inputManager
{
  id subManager;

  subManager = [self lookupConversationManagerOfClientID: inputManager];
  if (subManager == nil)
    {
      return;
    }
  [subManager deactivate];
}


- (void)terminateClient: (id)inputManager
{
  id subManager;

  subManager = [self lookupConversationManagerOfClientID: inputManager];
  if (subManager == nil)
    {
      return;
    }
  [subManager deactivate];

  [clients removeObjectForKey: [self keyFromClientID: inputManager]];
}


- (void)clientEnabled: (id)textView
{
  [[self activeConversationManager] conversationEnabled: textView];
}


- (void)clientDisabled: (id)textView
{
  [[self activeConversationManager] conversationDisabled: textView];
}


- (id)activeClientID
{
  NSEnumerator	*keyEnum;
  id		key;
  id		value;

  keyEnum = [clients keyEnumerator];
  while ((key = [keyEnum nextObject]) != nil)
    {
      value = [clients objectForKey: key];
      if ([value isActive])
	{
	  return [self clientIDFromKey: key];
	}
    }
  return nil;
}


- (id)activeConversationManager
{
  NSEnumerator	*objEnum;
  id		obj;

  objEnum = [clients objectEnumerator];
  while ((obj = [objEnum nextObject]) != nil)
    {
      if ([obj isActive])
	{
	  return obj;
	}
    }
  return nil;
}


- (long)enabledConversationIdentifier
{
  return [[self activeConversationManager] enabledConversationIdentifier];
}


- (id)enabledContext
{
  return [[self activeConversationManager] enabledContext];
}


- (void)dealloc
{
  [self setClients: nil];
  [self setContextClass: nil];
  [self setConversationManagerClass: nil];
  [super dealloc];
}

@end
