/*
    ConversationManager.h

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

#if !defined ConversationManager_h
#define ConversationManager_h

#include "ClientManager.h"

@class NSDictionary;
@class NSMutableDictionary;


@protocol ConversationAndContextProtocol
- (void)setEnabled: (BOOL)yn;
- (BOOL)enabled;
- (BOOL)isEnabled;
@end


@interface ConversationManager : NSObject <ClientAndConversationProtocol>
{
  /* key -- conversation, value -- context */
  NSMutableDictionary	*conversations;
  Class			contextClass;
  BOOL			active;
}

- (void)setConversations: (NSMutableDictionary *)aDictionary;
- (NSDictionary *)conversations;

- (void)setContextClass: (Class)theClass;
- (Class)contextClass;

- (void)setActive: (BOOL)yn;
- (BOOL)active;

- (long)enabledConversationIdentifier;
- (id)enabledContext;
@end


#endif /* ConversationManager_h */
