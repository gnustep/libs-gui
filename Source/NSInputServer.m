/*
    NSInputServer.m

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


#include <Foundation/NSConnection.h>
#include <Foundation/NSString.h>
#include <AppKit/NSInputManager.h>
#include <AppKit/NSInputServer.h>


/* This private class gives an implementation of NSInputServer when it
   is initialized with the delegate being nil.  */
@interface ImplForServerWithNilDelegate : NSObject
				          <NSInputServiceProvider,
					   NSInputServerMouseTracker>
{
  NSInputServer *mainBody;
}
- (id)initWith: (NSInputServer *)server;
@end /* @interface ImplForServerWithNilDelegate */


@implementation ImplForServerWithNilDelegate

- (id)initWith: (NSInputServer *)server
{
  if ((self = [super init]) != nil)
    {
      mainBody = server;
    }
  return self;
}


- (void)activeConversationChanged: (id)sender
		toNewConversation: (long)newConversation
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)activeConversationWillChange: (id)sender
		 fromOldConversation: (long)oldConversation;
{
  [mainBody subclassResponsibility: _cmd];
}


- (BOOL)canBeDisabled
{
  [mainBody subclassResponsibility: _cmd];
  /* Not reached */
  return NO;
}


- (void)doCommandBySelector: (SEL)aSelector
		     client: (id)sender
{
  /* TODO: For the sake of efficiency, caching acceptable selectors
           would give better performance.  (Is this portable?) */

  if ([self respondsToSelector: aSelector] == NO)
    {
      [sender doCommandBySelector: aSelector];
    }
  else
    {
      [self performSelector: aSelector
		 withObject: sender];
    }
}


- (void)inputClientBecomeActive: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)inputClientDisabled: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)inputClientEnabled: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)inputClientResignActive: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)insertText: (id)aString
	    client: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)markedTextAbandoned: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)markedTextSelectionChanged: (NSRange)newSelection
			    client: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (void)terminate: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}


- (BOOL)wantsToDelayTextChangeNotifications
{
  [mainBody subclassResponsibility: _cmd];
  /* Not reached */
  return NO;
}


- (BOOL)wantsToHandleMouseEvents
{
  [mainBody subclassResponsibility: _cmd];
  /* Not reached */
  return NO;
}


- (BOOL)wantsToInterpretAllKeystrokes
{
  [mainBody subclassResponsibility: _cmd];
  /* Not reached */
  return NO;
}


- (BOOL)mouseDownOnCharacterIndex: (unsigned)index
		     atCoordinate: (NSPoint)point
		     withModifier: (unsigned int)flags
			   client: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
  /* Not reached */
  return NO;
}


- (BOOL)mouseDraggedOnCharacterIndex: (unsigned)index
			atCoordinate: (NSPoint)point
			withModifier: (unsigned int)flags
			      client: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
  /* Not reached */
  return NO;
}


- (void)mouseUpOnCharacterIndex: (unsigned)index
		   atCoordinate: (NSPoint)point
		   withModifier: (unsigned int)flags
			 client: (id)sender
{
  [mainBody subclassResponsibility: _cmd];
}

@end /* @implementation ImplForServerWithNilDelegate */


@implementation NSInputServer

- (id)initWithDelegate: (id)delegate
		  name: (NSString *)name
{
  NSConnection*	conn;

  /* CHECK: Does NSLog work like syslog() does? */

  if ((self = [super init]) == nil)
    {
      NSLog(@"NSInputServer: Initialization failed");
      return nil;
    }

  /* Register 'name' for a connection. */
  if (name == nil || [name isEqualToString: @""])
    {
      NSLog(@"%@: Name for IPC isn't given", self);
      [self release];
      return nil;
    }
  if ((conn = [NSConnection defaultConnection]) == nil)
    {
      NSLog(@"%@: Couldn't get default Connection", self);
      [self release];
      return nil;
    }
  [conn setRootObject: self];
  if ([conn registerName: name] == NO)
    {
      NSLog(@"%@: Couldn't register %@ for connection", self, name);
      [self release];
      return nil;
    }

  /* Initialize 'impl'. */
  if (delegate == nil)
    {
      impl = [[ImplForServerWithNilDelegate alloc] initWith: self];
      if (impl == nil)
	{
	  NSLog(@"%@: Initialization (internal) failed", self);
	  [self release];
	  return nil;
	}
    }
  else
    {
      if ([delegate conformsToProtocol: @protocol(NSInputServiceProvider)]
	  == NO)
	{
	  NSLog(@"%@: Delegate doesn't conform to NSInputServiceProvider",
		self);
	  [self release];
	  return nil;
	}
      impl = delegate;
    }

  return self;
}


- (void)dealloc
{
  [[NSConnection defaultConnection] registerName: nil];

  if ([impl isKindOfClass: [ImplForServerWithNilDelegate class]])
    {
      [impl release], impl = nil;
    }

  [super dealloc];
}


/* ----------------------------------------------------------------------------
    NSInputServiceProvider protocol methods
 --------------------------------------------------------------------------- */
- (void)activeConversationChanged: (id)sender
		toNewConversation: (long)newConversation
{
  [impl activeConversationChanged: sender
		 toNewConversation: newConversation];
}


- (void)activeConversationWillChange: (id)sender
		 fromOldConversation: (long)oldConversation;
{
  [impl activeConversationWillChange: sender
		  fromOldConversation: oldConversation];
}


- (BOOL)canBeDisabled
{
  return [impl canBeDisabled];
}


- (void)doCommandBySelector: (SEL)aSelector
		     client: (id)sender
{
  [impl doCommandBySelector: aSelector
		      client: sender];
}


- (void)inputClientBecomeActive: (id)sender
{
  [impl inputClientBecomeActive: sender];
}


- (void)inputClientDisabled: (id)sender
{
  [impl inputClientDisabled: sender];
}


- (void)inputClientEnabled: (id)sender
{
  [impl inputClientEnabled: sender];
}


- (void)inputClientResignActive: (id)sender
{
  [impl inputClientResignActive: sender];
}


- (void)insertText: (id)aString
	    client: (id)sender
{
  [impl insertText: aString
	     client: sender];
}


- (void)markedTextAbandoned: (id)sender
{
  [impl markedTextAbandoned: sender];
}


- (void)markedTextSelectionChanged: (NSRange)newSelection
			    client: (id)sender
{
  [impl markedTextSelectionChanged: newSelection
			     client: sender];
}


- (void)terminate: (id)sender
{
  [impl terminate: sender];
}


- (BOOL)wantsToDelayTextChangeNotifications
{
  return [impl wantsToDelayTextChangeNotifications];
}


- (BOOL)wantsToHandleMouseEvents
{
  return [impl wantsToHandleMouseEvents];
}


- (BOOL)wantsToInterpretAllKeystrokes
{
  return [impl wantsToInterpretAllKeystrokes];
}


/* ----------------------------------------------------------------------------
    NSInputServerMouseTracker protocol methods

    These methods are supposedly invoked when -wantsToHandleMouseEvents
    returns YES, which in turn implies that impl is implemented in such
    way that it conforms to the NSInputServerMouseTracker
    protocol.  Hence, the messages are forwarded to impl without
    checking the conformance.

 --------------------------------------------------------------------------- */
- (BOOL)mouseDownOnCharacterIndex: (unsigned)index
		     atCoordinate: (NSPoint)point
		     withModifier: (unsigned int)flags
			   client: (id)sender
{
  return [impl mouseDownOnCharacterIndex: index
			     atCoordinate: point
			     withModifier: flags
				   client: sender];
}


- (BOOL)mouseDraggedOnCharacterIndex: (unsigned)index
			atCoordinate: (NSPoint)point
			withModifier: (unsigned int)flags
			      client: (id)sender
{
  return [impl mouseDraggedOnCharacterIndex: index
				atCoordinate: point
				withModifier: flags
				      client: sender];
}


- (void)mouseUpOnCharacterIndex: (unsigned)index
		   atCoordinate: (NSPoint)point
		   withModifier: (unsigned int)flags
			 client: (id)sender
{
  [impl mouseUpOnCharacterIndex: index
		    atCoordinate: point
		    withModifier: flags
			  client: sender];
}

@end /* @implementation NSInputServer */
