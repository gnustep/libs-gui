/*                                                    -*-objc-*-
   NSInputManager.m

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

#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSInputManager.h>
#include <AppKit/NSInputServer.h>

@implementation NSInputManager

// Class methods
+ (NSInputManager *) currentInputManager
{
  return nil;
}

+ (void) cycleToNextInputLanguage: (id)sender
{}

+ (void) cycleToNextInputServerInLanguage: (id)sender;
{}


- (NSInputManager *) initWithName: (NSString *)inputServerName
			    host: (NSString *)hostName
{
  return nil;
}

- (BOOL) handleMouseEvent: (NSEvent *)theMouseEvent
{
  return NO;
}

- (NSImage *) image
{
  return nil;
}

- (NSString *) language
{
  return nil;
}

- (NSString *) localizedInputManagerName
{
  return nil;
}

- (void) markedTextAbandoned: (id)client
{}

- (void) markedTextSelectionChanged: (NSRange)newSel
			    client: (id)client
{}

- (NSInputServer *) server
{
  return nil;
}

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

// NSTextInput protocol
- (void) setMarkedText: (id)aString 
	 selectedRange: (NSRange)selRange
{}

- (BOOL) hasMarkedText
{
  return NO;
}

- (NSRange) markedRange
{
  return NSMakeRange(NSNotFound, 0);
}

- (NSRange) selectedRange
{
  return NSMakeRange(NSNotFound, 0);
}

- (void) unmarkText
{}

- (NSArray*) validAttributesForMarkedText
{
  return nil;
}

- (NSAttributedString *) attributedSubstringFromRange: (NSRange)theRange;
{
  return nil;
}

- (unsigned int) characterIndexForPoint: (NSPoint)thePoint
{
  return 0;
}

- (long) conversationIdentifier
{
  return 0;
}

- (void) doCommandBySelector: (SEL)aSelector
{}

- (NSRect) firstRectForCharacterRange: (NSRange)theRange
{
  return NSZeroRect;
}

- (void) insertText: (id)aString
{}

@end
