/*
    ConversationManager.m

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
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include "AppKit/NSInputManager.h"
#include "ConversationManager.h"


@implementation ConversationManager

- (id)initWithContextClass: (Class)theClass
{
  NSMutableDictionary *dict;

  if ((self = [super init]) == nil)
    {
      return nil;
    }

  dict = [[NSMutableDictionary alloc] initWithCapacity: 1];
  if (dict == nil)
    {
      [self release];
      return nil;
    }

  [self setConversations: dict], [dict release], dict = nil;
  [self setContextClass: theClass];
  [self setActive: NO];

  return self;
}


- (void)setConversations: (NSMutableDictionary *)aDictionary
{
  [aDictionary retain];
  [conversations release];
  conversations = aDictionary;
}


- (NSDictionary *)conversations
{
  return conversations;
}


- (void)setContextClass: (Class)theClass
{
  contextClass = theClass;
}


- (Class)contextClass
{
  return contextClass;
}


- (void)setActive: (BOOL)yn
{
  active = yn;
}


- (BOOL)active
{
  return active;
}


- (void)activate
{
  [self setActive: YES];
}


- (void)deactivate
{
  [self setActive: NO];
}


- (BOOL)isActive
{
  return [self active];
}


/* Private method */
- (NSNumber *)keyFromConversationID: (long)num
{
  return [NSNumber numberWithLong: num];
}


/* Private method */
- (long)conversationIDFromKey: (NSNumber *)key
{
  return [key longValue];
}


/* Private method */
- (id)lookupContextOfConversationID: (long)num
{
  NSEnumerator	*keyEnum;
  id		key;

  keyEnum = [conversations keyEnumerator];
  while ((key = [keyEnum nextObject]) != nil)
    {
      if ([self conversationIDFromKey: key] == num)
	{
	  return [conversations objectForKey: key];
	}
    }
  return nil;
}


- (void)conversationEnabled: (id)textView
{
  long	convID;
  BOOL	shouldRelease;
  id	context;

#if 0
  if ([textView conformsToProtocol: @protocol(NSTextInput)] == NO)
    {
      return;
    }
#endif
  convID = [textView conversationIdentifier];

  shouldRelease = NO;
  context = [self lookupContextOfConversationID: convID];
  if (context == nil)
    {
      context = [[contextClass alloc] init];
      if (context == nil)
	{
	  return;
	}
      shouldRelease = YES;
      [conversations setObject: context
			forKey: [self keyFromConversationID: convID]];
    }

  [context setEnabled: YES];

  if (shouldRelease)
    {
      [context release], context = nil;
      shouldRelease = NO;
    }
}


- (void)conversationDisabled: (id)textView
{
  long	convID;
  id	context;

#if 0
  if ([textView conformsToProtocol: @protocol(NSTextInput)] == NO)
    {
      return;
    }
#endif
  convID = [textView conversationIdentifier];

  context = [self lookupContextOfConversationID: convID];
  if (context == nil)
    {
      return;
    }

  [context setEnabled: NO];
}


- (void)dealloc
{
  [self setConversations: nil];
  [super dealloc];
}


- (long)enabledConversationIdentifier
{
  NSEnumerator	*keyEnum;
  id		key;
  id		value;

  keyEnum = [conversations keyEnumerator];
  while ((key = [keyEnum nextObject]) != nil)
    {
      value = [conversations objectForKey: key];
      if ([value isEnabled])
	{
	  return [self conversationIDFromKey: key];
	}
    }
  return 0;
}


- (id)enabledContext
{
  NSEnumerator	*objEnum;
  id		obj;

  objEnum = [conversations objectEnumerator];
  while ((obj = [objEnum nextObject]) != nil)
    {
      if ([obj isEnabled])
	{
	  return obj;
	}
    }
  return nil;
}

@end
