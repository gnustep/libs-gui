/** <title>NSInputServer</title>                                -*-objc-*-

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de> 
   Date: August 2001

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

#include "AppKit/NSInputServer.h"

@implementation NSInputServer

- (id) initWithDelegate: (id)aDelegate
		   name: (NSString *)name
{
    return nil;
}

// NSInputServerMouseTracker protocol
- (BOOL) mouseDownOnCharacterIndex: (unsigned)index
		      atCoordinate: (NSPoint)point
		      withModifier: (unsigned int)flags
			    client: (id)sender
{
  return NO;
}

- (BOOL) mouseDraggedOnCharacterIndex: (unsigned)index
			 atCoordinate: (NSPoint)point
			 withModifier: (unsigned int)flags
			       client: (id)sender
{
  return NO;
}

- (void) mouseUpOnCharacterIndex: (unsigned)index
		    atCoordinate: (NSPoint)point
		    withModifier: (unsigned int)flags
			  client: (id)sender
{}

// NSInputServiceProvider protocol
- (void) activeConversationChanged: (id)sender
		 toNewConversation: (long)newConversation
{}

- (void) activeConversationWillChange: (id)sender
		  fromOldConversation: (long)oldConversation
{}

- (BOOL) canBeDisabled
{
  return NO;
}

- (void) doCommandBySelector: (SEL)aSelector
		      client: (id)sender
{}

- (void) inputClientBecomeActive: (id)sender
{}

- (void) inputClientDisabled: (id)sender
{}

- (void) inputClientEnabled: (id)sender
{}

- (void) inputClientResignActive: (id)sender
{}

- (void) insertText: (id)aString
	     client: (id)sender
{}

- (void) markedTextAbandoned: (id)sender
{}

- (void) markedTextSelectionChanged: (NSRange)newSelection
			     client: (id)sender
{}

- (void) terminate: (id)sender
{}

- (BOOL) wantsToDelayTextChangeNotifications
{
  return NO;
}

- (BOOL) wantsToHandleMouseEvents
{
  return NO;
}

- (BOOL) wantsToInterpretAllKeystrokes
{
  return NO;
}

@end
