/*
    NSInputServer.h

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

#ifndef _GNUstep_NSInputServer_h
#define _GNUstep_NSInputServer_h


#include <Foundation/NSGeometry.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSObject.h>


@class NSString;


@protocol NSInputServiceProvider
- (void)activeConversationChanged: (id)sender
		toNewConversation: (long)newConversation;
- (void)activeConversationWillChange: (id)sender
		 fromOldConversation: (long)oldConversation;
- (BOOL)canBeDisabled;
- (void)doCommandBySelector: (SEL)aSelector
		     client: (id)sender;
- (void)inputClientBecomeActive: (id)sender;
- (void)inputClientDisabled: (id)sender;
- (void)inputClientEnabled: (id)sender;
- (void)inputClientResignActive: (id)sender;
- (void)insertText: (id)aString
	    client: (id)sender;
- (void)markedTextAbandoned: (id)sender;
- (void)markedTextSelectionChanged: (NSRange)newSelection
			    client: (id)sender;
- (void)terminate: (id)sender;
- (BOOL)wantsToDelayTextChangeNotifications;
- (BOOL)wantsToHandleMouseEvent;
- (BOOL)wantsToInterpretAllKeystrokes;
@end /* @interface NSInputServiceProvider */


@protocol NSInputServerMouseTracker
- (BOOL)mouseDownOnCharacterIndex: (unsigned)index
		     atCoordinate: (NSPoint)point
		     withModifier: (unsigned int)flags
			   client: (id)sender;
- (BOOL)mouseDraggedOnCharacterIndex: (unsigned)index
			atCoordinate: (NSPoint)point
			withModifier: (unsigned int)flags
			      client: (id)sender;
- (void)mouseUpOnCharacterIndex: (unsigned)index
		   atCoordinate: (NSPoint)point
		   withModifier: (unsigned int)flags
			 client: (id)sender;
@end /* @interface NSInputServerMouseTracker */


@interface NSInputServer : NSObject <NSInputServiceProvider,
                                     NSInputServerMouseTracker>
{
@private
  id	impl;
}

- (id)initWithDelegate: (id)delegate
		  name: (NSString *)name;
@end /* NSInputServer : NSObject <NSInputServiceProvider,
                                  NSInputServerMouseTracker> */


#endif /* _GNUstep_NSInputServer_h */
