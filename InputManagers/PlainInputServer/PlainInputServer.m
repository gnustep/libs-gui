/*
    PlainInputServer.m  (PlainInputServer)

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date: March, 2004

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


#include <AppKit/NSResponder.h>
#include <AppKit/NSTextView.h>
#include "ConversationManager.h"
#include "Context.h"
#include "PlainInputServer.h"


static PlainInputServer *sharedInstance = nil;


@implementation PlainInputServer

+ (id)sharedInstance
{
  if (sharedInstance == nil)
    {
      sharedInstance = [[PlainInputServer alloc] init];
    }
  return sharedInstance;
}


- (id)init
{
  if ((self = [super init]) == nil)
    {
      return nil;
    }

  clientManager = [[ClientManager alloc]
    initWithConversationManagerClass: [ConversationManager class]
			contextClass: [Context class]];
  if (clientManager == nil)
    {
      [self release];
      return nil;
    }

  return self;
}


- (void)dealloc
{
  [clientManager release];
  [super dealloc];
}


- (void)inputMethodToggle: (id)sender
{
  NSLog(@"%@: inputMethodToggle: called", self);
}


/* ----------------------------------------------------------------------------
    NSInputServiceProvider protocol methods
 --------------------------------------------------------------------------- */
- (void)activeConversationChanged: (id)sender
		toNewConversation: (long)newConversation
{
  // Not implemented yet
}


- (void)activeConversationWillChange: (id)sender
		 fromOldConversation: (long)oldConversation
{
  // Not implemented yet
}


- (BOOL)canBeDisabled
{
  return NO;
}


- (void)doCommandBySelector: (SEL)aSelector
		     client: (id)sender
{
  if ([clientManager enabledConversationIdentifier]
      != [sender conversationIdentifier])
    {
      NSLog(@"%@: Mismatch conversation ID's: sender's: %x -- server's: %x",
	    self,
	    [sender conversationIdentifier],
	    [clientManager enabledConversationIdentifier]);
      return;
    }

  if ([self respondsToSelector: aSelector])
    {
      [self performSelector: aSelector
		 withObject: sender];
    }
  else
    {
      [sender doCommandBySelector: aSelector];
    }
}


- (void)inputClientBecomeActive: (id)sender
{
  [clientManager clientBecomeActive: sender];
}


- (void)inputClientDisabled: (id)sender
{
  NSLog(@"%@: disabled: %x", self, [sender conversationIdentifier]);

  [clientManager clientDisabled: sender];
}


- (void)inputClientEnabled: (id)sender
{
  NSLog(@"%@: enabled: %x", self, [sender conversationIdentifier]);

  [clientManager clientEnabled: sender];
}


- (void)inputClientResignActive: (id)sender
{
  [clientManager clientResignActive: sender];
}


- (void)insertText: (id)aString
	    client: (id)sender
{
  if ([clientManager enabledConversationIdentifier]
      != [sender conversationIdentifier])
    {
      NSLog(@"%@: Mismatch conversation ID's: sender's: %x -- server's: %x",
	    self,
	    [sender conversationIdentifier],
	    [clientManager enabledConversationIdentifier]);
      return;
    }

  [sender insertText: aString];
}


- (void)markedTextAbandoned: (id)sender
{
  // Not implemented yet
}


- (void)markedTextSelectionChanged: (NSRange)newSelection
			    client: (id)sender
{
  // Not implemented yet
}


- (void)terminate: (id)sender
{
  [clientManager terminateClient: sender];
}


- (BOOL)wantsToDelayTextChangeNotifications
{
  return YES;
}


- (BOOL)wantsToHandleMouseEvents
{
  return NO;
}


- (BOOL)wantsToInterpretAllKeystrokes
{
  return NO;
}


/* ----------------------------------------------------------------------------
    NSInputServerMouseTracker protocol methods
 --------------------------------------------------------------------------- */
- (BOOL)mouseDownOnCharacterIndex: (unsigned)index
		     atCoordinate: (NSPoint)point
		     withModifier: (unsigned int)flags
			   client: (id)sender
{
  return NO;
}


- (BOOL)mouseDraggedOnCharacterIndex: (unsigned)index
			atCoordinate: (NSPoint)point
			withModifier: (unsigned int)flags
			      client: (id)sender
{
  return NO;
}


- (void)mouseUpOnCharacterIndex: (unsigned)index
		   atCoordinate: (NSPoint)point
		   withModifier: (unsigned int)flags
			 client: (id)sender
{
}

@end /* @implementation PlainInputServer */
