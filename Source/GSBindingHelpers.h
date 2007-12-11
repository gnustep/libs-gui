/** Private Bindings helper functions for GNUstep

   Copyright (C) 2007 Free Software Foundation, Inc.

   Written by:  Chris Farber <chris@chrisfarber.net>
   Date: 2007

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#ifndef _GS_BINDING_HELPER_H
#define _GS_BINDING_HELPER_H

@class NSString;
@class NSDictionary;
@class NSMutableDictionary;
@class NSArray;

typedef enum {
  GSBindingOperationAnd = 0,
  GSBindingOperationOr
} GSBindingOperationKind;

//Obtain a lock 
void GSBindingLock();

//Releases the lock
void GSBindingReleaseLock();


//Get the mutable list of bindings for an object. You must obtain a lock
//with GSBindingLock() before calling this function and release the lock with
//GSBindingReleaseLock() when done with the dictionary.
NSMutableDictionary *GSBindingListForObject(id object);

//TODO: document
BOOL GSBindingResolveMultipleValueBool(NSString *key, NSDictionary *bindings,
    GSBindingOperationKind operationKind);

//TODO: document
void GSBindingInvokeAction(NSString *targetKey, NSString *argumentKey,
    NSDictionary *bindings);


NSArray *GSBindingExposeMultipleValueBindings(
    NSArray *bindingNames,
    NSMutableDictionary *bindingList);

NSArray *GSBindingExposePatternBindings(
    NSArray *bindingNames,
    NSMutableDictionary *bindingList);

void GSBindingUnbindAll(id object);

/* Transforms the value with a value transformer, if specified and available,
 * and takes care of any placeholders
 */
id GSBindingTransformedValue(id value, NSDictionary *options);
id GSBindingReverseTransformedValue(id value, NSDictionary *options);

#endif //_GS_BINDING_HELPER_H
