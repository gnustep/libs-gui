/* 
   NSResponder.m

   Abstract class which is basis of command and event processing

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <gnustep/gui/config.h>
#include <Foundation/NSCoder.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSHelpManager.h>
#include <objc/objc.h>

@implementation NSResponder

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSResponder class])
    {
      NSDebugLog(@"Initialize NSResponder class\n");

      [self setVersion: 1];
    }
}

/*
 * Instance methods
 */
/*
 * Managing the next responder
 */
- (id) nextResponder
{
  return next_responder;
}

- (void) setNextResponder: (NSResponder*)aResponder
{
  next_responder = aResponder;
}

/*
 * Determining the first responder
 */
- (BOOL) acceptsFirstResponder
{
  return NO;
}

- (BOOL) becomeFirstResponder
{
  return YES;
}

- (BOOL) resignFirstResponder
{
  return YES;
}

/*
 * Aid event processing
 */
- (BOOL) performKeyEquivalent: (NSEvent *)theEvent
{
  return NO;
}

- (BOOL) tryToPerform: (SEL)anAction with: (id)anObject
{
  /* Can we perform the action -then do it */
  if ([self respondsToSelector: anAction])
    {
      [self performSelector: anAction withObject: anObject];
      return YES;
    }
  else
    {
      /* If we cannot perform then try the next responder */
      if (!next_responder)
	return NO;
      else
	return [next_responder tryToPerform: anAction with: anObject];
    }
}

/*
 * Forwarding event messages
 */
- (void) flagsChanged: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder flagsChanged: theEvent];
  else
    return [self noResponderFor: @selector(flagsChanged:)];
}

- (void) helpRequested: (NSEvent *)theEvent
{
  if(![[NSHelpManager sharedHelpManager]
	showContextHelpForObject: self
	locationHint: [theEvent locationInWindow]])
    if (next_responder)
      return [next_responder helpRequested: theEvent];
  [NSHelpManager setContextHelpModeActive: NO];
}

- (void) keyDown: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder keyDown: theEvent];
  else
    return [self noResponderFor: @selector(keyDown:)];
}

- (void) keyUp: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder keyUp: theEvent];
  else
    return [self noResponderFor: @selector(keyUp:)];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseDown: theEvent];
  else
    return [self noResponderFor: @selector(mouseDown:)];
}

- (void) mouseDragged: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(mouseDragged:)];
}

- (void) mouseEntered: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseEntered: theEvent];
  else
    return [self noResponderFor: @selector(mouseEntered:)];
}

- (void) mouseExited: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseExited: theEvent];
  else
    return [self noResponderFor: @selector(mouseExited:)];
}

- (void) mouseMoved: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseMoved: theEvent];
  else
    return [self noResponderFor: @selector(mouseMoved:)];
}

- (void) mouseUp: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseUp: theEvent];
  else
    return [self noResponderFor: @selector(mouseUp:)];
}

- (void) noResponderFor: (SEL)eventSelector
{
  /* Only beep for key down events */
  if (sel_eq(eventSelector, @selector(keyDown:)))
    NSBeep();
}

- (void) rightMouseDown: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder rightMouseDown: theEvent];
  else
    {
      NSMenu	*menu = [NSApp mainMenu];

      if (menu)
	[menu _rightMouseDisplay];
      else
	return [self noResponderFor: @selector(rightMouseDown:)];
    }
}

- (void) rightMouseDragged: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder rightMouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseDragged:)];
}

- (void) rightMouseUp: (NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder rightMouseUp: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseUp:)];
}

/*
 * Services menu support
 */
- (id) validRequestorForSendType: (NSString *)typeSent
		      returnType: (NSString *)typeReturned
{
  if (next_responder)
    return [next_responder validRequestorForSendType: typeSent
					  returnType: typeReturned];
  else
    return nil;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeConditionalObject: next_responder];
  [aCoder encodeValueOfObjCType: @encode(NSInterfaceStyle)
			     at: &interface_style];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  next_responder = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(NSInterfaceStyle)
			       at: &interface_style];
  return self;
}

- (NSInterfaceStyle) interfaceStyle
{
  return interface_style;
}

- (void) setInterfaceStyle: (NSInterfaceStyle)aStyle
{
  interface_style = aStyle;
}

@end
