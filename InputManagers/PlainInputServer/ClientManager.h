/*
    ClientManager.h

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

#if !defined ClientManager_h
#define ClientManager_h

#include <Foundation/NSObject.h>

@class NSDictionary;
@class NSMutableDictionary;


@protocol ClientAndConversationProtocol
- (id)initWithContextClass: (Class)theClass;
- (void)activate;
- (void)deactivate;
- (BOOL)isActive;
- (void)conversationEnabled: (id)textView;
- (void)conversationDisabled: (id)textView;
- (long)enabledConversationIdentifier;
- (id)enabledContext;
@end


@interface ClientManager : NSObject
{
  /* key -- input manager, value -- conversation manager */
  NSMutableDictionary	*clients;
  Class			conversationManagerClass;
  Class			contextClass;
}

- (id)initWithConversationManagerClass: (Class)mClass
			  contextClass: (Class)cClass;

- (void)setConversationManagerClass: (Class)theClass;
- (Class)conversationManagerClass;

- (void)setContextClass: (Class)theClass;
- (Class)contextClass;

- (void)setClients: (NSMutableDictionary *)aDictionary;
- (NSDictionary *)clients;

- (void)clientBecomeActive: (id)inputManager;
- (void)clientResignActive: (id)inputManager;
- (void)terminateClient: (id)inputManager;

- (void)clientEnabled: (id)textView;
- (void)clientDisabled: (id)textView;

- (id)activeClientID;
- (id)activeConversationManager;
- (long)enabledConversationIdentifier;
- (id)enabledContext;
@end


#endif /* ClientManager_h */
