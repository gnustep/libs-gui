/* 
   NSResponder.m

   Abstract class which is basis of command and event processing

   Copyright (C) 1996 Free Software Foundation, Inc.

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

#include <gnustep/gui/NSResponder.h>
#include <gnustep/base/NSCoder.h>

@implementation NSResponder

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSResponder class])
    {
      NSDebugLog(@"Initialize NSResponder class\n");

      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//
//
// Managing the next responder
//
- nextResponder
{
  return next_responder;
}

- (void)setNextResponder:aResponder
{
  next_responder = aResponder;
}

//
// Determining the first responder
//
- (BOOL)acceptsFirstResponder
{
  return NO;
}

- (BOOL)becomeFirstResponder
{
  return YES;
}

- (BOOL)resignFirstResponder
{
  return YES;
}

//
// Aid event processing
//
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
  return NO;
}

- (BOOL)tryToPerform:(SEL)anAction with:anObject
{
  // Can we perform the action -then do it
  if ([self respondsToSelector:anAction])
    {
      [self perform:anAction withObject:anObject];
      return YES;
    }
  else
    {
      // If we cannot perform then try the next responder
      if (!next_responder)
	return NO;
      else
	return [next_responder tryToPerform:anAction with:anObject];
    }
}

//
// Forwarding event messages
//
- (void)flagsChanged:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder flagsChanged:theEvent];
  else
    return [self noResponderFor:@selector(flagsChanged:)];
}

- (void)helpRequested:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder helpRequested:theEvent];
  else
    return [self noResponderFor:@selector(helpRequested:)];
}

- (void)keyDown:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder keyDown:theEvent];
  else
    return [self noResponderFor:@selector(keyDown:)];
}

- (void)keyUp:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder keyUp:theEvent];
  else
    return [self noResponderFor:@selector(keyUp:)];
}

- (void)mouseDown:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseDown:theEvent];
  else
    return [self noResponderFor:@selector(mouseDown:)];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseDragged:theEvent];
  else
    return [self noResponderFor:@selector(mouseDragged:)];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseEntered:theEvent];
  else
    return [self noResponderFor:@selector(mouseEntered:)];
}

- (void)mouseExited:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseExited:theEvent];
  else
    return [self noResponderFor:@selector(mouseExited:)];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseMoved:theEvent];
  else
    return [self noResponderFor:@selector(mouseMoved:)];
}

- (void)mouseUp:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder mouseUp:theEvent];
  else
    return [self noResponderFor:@selector(mouseUp:)];
}

- (void)noResponderFor:(SEL)eventSelector
{
  // Only beep for key down events
  if (eventSelector != @selector(keyDown:))
    return;

  NSBeep();
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder rightMouseDown:theEvent];
  else
    return [self noResponderFor:@selector(rightMouseDown:)];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder rightMouseDragged:theEvent];
  else
    return [self noResponderFor:@selector(rightMouseDragged:)];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
  if (next_responder)
    return [next_responder rightMouseUp:theEvent];
  else
    return [self noResponderFor:@selector(rightMouseUp:)];
}

//
// Services menu support
//
- validRequestorForSendType:(NSString *)typeSent
		 returnType:(NSString *)typeReturned
{
  if (next_responder)
    return [next_responder validRequestorForSendType:typeSent
			   returnType:typeReturned];
  else
    return nil;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObjectReference: next_responder withName: @"Next responder"];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeObjectAt: &next_responder withName: NULL];

  return self;
}

@end
