/* 
   NSResponder.h

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSResponder
#define _GNUstep_H_NSResponder

#include <AppKit/stdappkit.h>
#include <AppKit/NSEvent.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSCoder.h>

@interface NSResponder : NSObject <NSCoding>

{
  // Attributes
  id next_responder;
}

//
// Instance methods
//

//
// Managing the next responder
//
- nextResponder;
- (void)setNextResponder:aResponder;

//
// Determining the first responder
//
- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

//
// Aid event processing
//
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (BOOL)tryToPerform:(SEL)anAction with:anObject;

//
// Forwarding event messages
//
- (void)flagsChanged:(NSEvent *)theEvent;
- (void)helpRequested:(NSEvent *)theEvent;
- (void)keyDown:(NSEvent *)theEvent;
- (void)keyUp:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)mouseMoved:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)noResponderFor:(SEL)eventSelector;
- (void)rightMouseDown:(NSEvent *)theEvent;
- (void)rightMouseDragged:(NSEvent *)theEvent;
- (void)rightMouseUp:(NSEvent *)theEvent;

//
// Services menu support
//
- validRequestorForSendType:(NSString *)typeSent
		 returnType:(NSString *)typeReturned;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSResponder
