/*
    NSInputManager.h

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

#ifndef _GNUstep_NSInputManager_h
#define _GNUstep_NSInputManager_h

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

@class NSString;
@class NSArray;
@class NSAttributedString;
@class NSDictionary;
@class NSEvent;
@class NSInputServer;
@class NSImage;
@class GSTIMInputServerInfo;
@class IMKeyBindingTable;


@protocol NSTextInput
- (NSAttributedString *)attributedSubstringFromRange: (NSRange)theRange;
- (unsigned int)characterIndexForPoint: (NSPoint)thePoint;
- (long)conversationIdentifier;
- (void)doCommandBySelector: (SEL)aSelector;
- (NSRect)firstRectForCharacterRange: (NSRange)theRange;
- (BOOL)hasMarkedText;
- (void)insertText: (id)aString;
- (NSRange)markedRange;
- (NSRange)selectedRange;
- (void)setMarkedText: (id)aString
	selectedRange: (NSRange)selRange;
- (void)unmarkText;
- (NSArray *)validAttributesForMarkedText;
@end /* @protocol NSTextInput */


@interface NSInputManager : NSObject <NSTextInput>
{
  GSTIMInputServerInfo	*serverInfo;
  IMKeyBindingTable	*keyBindingTable;
  id			serverProxy;
}

+ (NSInputManager *)currentInputManager;
+ (void)cycleToNextInputLanguage: (id)sender;		/* Deprecated */
+ (void)cycleToNextInputServerInLanguage: (id)sender;	/* Deprecated */

- (BOOL)handleMouseEvent: (NSEvent *)theMouseEvent;
- (NSImage *)image;					/* Deprecated */
- (NSInputManager *)initWithName: (NSString *)inputServerName
			    host: (NSString *)host;
- (NSString *)language;
- (NSString *)localizedInputManagerName;
- (void)markedTextAbandoned: (id)client;
- (void)markedTextSelectionChanged: (NSRange)newSel
			    client: (id)client;
- (NSInputServer *)server;				/* Deprecated */
- (BOOL)wantsToDelayTextChangeNotifications;
- (BOOL)wantsToHandleMouseEvents;
- (BOOL)wantsToInterpretAllKeystrokes;
@end /* @interface NSInputManager : NSObject <NSTextInput> */


#endif /* _GNUstep_NSInputManager_h */
