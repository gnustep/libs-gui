/*
    GSTIMKeyBindingTable.h

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date: April 2004

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

#if !defined _GNUstep_GSTIMKeyBindingTable_h
#define _GNUstep_GSTIMKeyBindingTable_h

#include <Foundation/NSObject.h>

@class NSString;
@class NSDictionary;
@class NSMutableDictionary;
@class GSTIMKeyStroke;

typedef enum _GSTIMQueryResult
{
  GSTIMNotFound = 0,
  GSTIMFound,
  GSTIMPending
} GSTIMQueryResult;


@interface GSTIMKeyBindingTable : NSObject
{
  NSDictionary	*bindings;
  NSDictionary	*branch;
}

- (id)initWithKeyBindingDictionary: (NSDictionary *)bindingDictionary;

- (void)setBindings: (NSDictionary *)newBindings;
- (NSDictionary *)bindings;

- (GSTIMKeyStroke *)compileForKeyStroke: (NSString *)aStroke;

- (void)compileBindings: (NSMutableDictionary *)draft
	     withSource: (NSDictionary *)source;

- (GSTIMQueryResult)getSelectorFromCharacter: (GSTIMKeyStroke *)character
				    selector: (SEL *)selector;
@end

#endif /* _GNUstep_GSTIMKeyBindingTable_h */
