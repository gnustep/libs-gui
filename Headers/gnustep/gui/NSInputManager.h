/*                                                    -*-objc-*-
   NSInputManager.h

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

#ifndef _GNUstep_H_NSInputManager
#define _GNUstep_H_NSInputManager

#include <objc/Protocol.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAttributedString.h>

@class NSInputServer;
@class NSEvent;
@class NSImage;

@protocol NSTextInput
// Marking text
- (void) setMarkedText: (id)aString 
	 selectedRange: (NSRange)selRange;
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

@interface NSInputManager: NSObject <NSTextInput>
+ (NSInputManager *) currentInputManager;
+ (void) cycleToNextInputLanguage: (id)sender;
+ (void) cycleToNextInputServerInLanguage: (id)sender;

- (BOOL) handleMouseEvent: (NSEvent *)theMouseEvent;
- (NSImage *) image;
- (NSInputManager *) initWithName: (NSString *)inputServerName
			    host: (NSString *)hostName;
- (NSString *) language;
- (NSString *) localizedInputManagerName;
- (void) markedTextAbandoned: (id)client;
- (void) markedTextSelectionChanged: (NSRange)newSel
			    client: (id)client;
- (NSInputServer *) server;
- (BOOL) wantsToDelayTextChangeNotifications;
- (BOOL) wantsToHandleMouseEvents;
- (BOOL) wantsToInterpretAllKeystrokes;
@end

#endif //_GNUstep_H_NSInputManager

