/*
    NSInputManagerPriv.h

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

#ifndef _GNUstep_NSInputManagerPriv_h
#define _GNUstep_NSInputManagerPriv_h

#include <AppKit/NSEvent.h>
#include <AppKit/NSInputManager.h>

@class NSArray;
@class NSString;
@class NSDictionary;

@interface NSInputManager (KeyEventHandling)
- (void)interpretKeyEvents: (NSArray *)eventArray;
@end /* @interface NSInputManager (KeyEventHandling) */


#if defined USE_INPUT_MANAGER_UTILITIES

typedef enum _IMState {
    IMNotFound = 0,
    IMFound,
    IMPending,
} IMQueryResult;


@class GSTIMKeyStroke;

@interface IMKeyBindingTable : NSObject
{
  NSDictionary	*bindings;	    /* key - IMCharacter, value - SEL */
  NSDictionary	*branch;	
}

- (id)initWithKeyBindingDictionary: (NSDictionary *)bindingDictionary;

- (void)setBindings: (NSDictionary *)newBindings;
- (NSDictionary *)bindings;

- (GSTIMKeyStroke *)compileForKey: (NSString *)key;
- (void)compileBindings: (NSMutableDictionary *)draft
	     withSource: (NSDictionary *)source;

- (IMQueryResult)getSelectorFromCharacter: (GSTIMKeyStroke *)character
				 selector: (SEL *)selector;
@end /* @interface IMKeyBindingTable */

#endif /* #if defined USE_INPUT_MANAGER_UTILITIES */


#endif /* _GNUstep_NSInputManager_h */
