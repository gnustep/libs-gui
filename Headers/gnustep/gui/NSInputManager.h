/* -*-objc-*-
   NSInputManager.h

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: August 2001

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 2001

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

#ifndef _GNUstep_H_NSInputManager
#define _GNUstep_H_NSInputManager

#include <objc/Protocol.h>
#include <objc/objc.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAttributedString.h>

@class NSInputServer;
@class NSEvent;
@class NSImage;

@protocol NSTextInput
- (void) setMarkedText: (id)aString  selectedRange: (NSRange)selRange;
- (BOOL) hasMarkedText;
- (NSRange) markedRange;
- (NSRange) selectedRange;
- (void) unmarkText;
- (NSArray*) validAttributesForMarkedText;


- (NSAttributedString *) attributedSubstringFromRange: (NSRange)theRange;
- (unsigned int) characterIndexForPoint: (NSPoint)thePoint;
- (long) conversationIdentifier;
- (void) doCommandBySelector: (SEL)aSelector;
- (NSRect) firstRectForCharacterRange: (NSRange)theRange;
- (void) insertText: (id)aString;
@end

struct _GSInputManagerBinding 
{
  /* The character this binding is about.  */
  unichar character;

  /* The character is bound to different selectors according to the
     various modifiers which can be used with the character.

     There are eight selectors for the eight possibilities - each of
     NSShiftKeyMask, NSControlKeyMask, NSAlternateKeyMask might be on
     or off and each combination gives a different selector.

     The index of the selector to use is given by

     (modifiers & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask)) / 2
     
     a NULL selector means use the default action */
  SEL selector[8];
};



@interface NSInputManager: NSObject <NSTextInput>
{
  id _currentClient;
  
  /* An array of bindings.  */
  struct _GSInputManagerBinding *_bindings;

  /* The size of the array.  */
  int _bindingsCount;
}
+ (NSInputManager *) currentInputManager;

- (id) initWithName: (NSString *)inputServerName
	       host: (NSString *)hostName;

- (BOOL) handleMouseEvent: (NSEvent *)theMouseEvent;
- (void) handleKeyboardEvents: (NSArray *)eventArray
		       client: (id)client;
- (NSString *) language;
- (NSString *) localizedInputManagerName;
- (void) markedTextAbandoned: (id)client;
- (void) markedTextSelectionChanged: (NSRange)newSel
			    client: (id)client;
- (BOOL) wantsToDelayTextChangeNotifications;
- (BOOL) wantsToHandleMouseEvents;
- (BOOL) wantsToInterpretAllKeystrokes;
@end

#endif /* _GNUstep_H_NSInputManager */
