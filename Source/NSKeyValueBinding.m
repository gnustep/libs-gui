/**  <title>NSKeyValueBinding informal protocol reference</title>

   Implementation of KeyValueBinding for GNUStep

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
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSKeyValueObserving.h>
#include <Foundation/NSKeyValueCoding.h>
#include <Foundation/NSValueTransformer.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSException.h>
#include <GNUstepBase/GSLock.h>

#include "AppKit/NSKeyValueBinding.h"
#include "GSBindingHelpers.h"

static NSRecursiveLock *bindingLock = nil;
static NSMapTable *classTable = NULL;      //available bindings
static NSMapTable *objectTable = NULL;     //bound bindings

static inline void setup()
{
  if (bindingLock == nil)
    {
      bindingLock = [GSLazyRecursiveLock new];
      classTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
          NSOwnedPointerMapValueCallBacks, 128);
      objectTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
          NSOwnedPointerMapValueCallBacks, 128);
    }
}

@implementation NSObject (NSKeyValueBindingCreation)

+ (void) exposeBinding: (NSString *)binding
{
  NSMutableArray *bindings;
  
  setup();
  [bindingLock lock];
  bindings = (NSMutableArray *)NSMapGet(classTable, (void*)self);
  if (bindings == nil)
    {
      bindings = [NSMutableArray arrayWithCapacity: 15];
      NSMapInsert(classTable, (void*)self, (void*)bindings);
    }
  [bindings addObject: binding];
  [bindingLock unlock];
}

- (NSArray *) exposedBindings
{
  NSMutableArray *exposedBindings = [NSMutableArray array];
  NSArray *tmp;
  Class class = [self class];

  setup();
  [bindingLock lock];
  while (class && class != [NSObject class])
    {
      tmp = NSMapGet(classTable, (void*)class);
      if (tmp != nil)
        {
          [exposedBindings addObjectsFromArray: tmp];
        }
      class = [class superclass];
    }
  [bindingLock unlock];

  return exposedBindings;
}

- (Class) valueClassForBinding: (NSString *)binding
{
  return [NSString class];
}

- (void)bind: (NSString *)binding 
    toObject: (id)anObject
 withKeyPath: (NSString *)keyPath
     options: (NSDictionary *)options
{
  NSMutableDictionary *bindings;
  NSDictionary *info;
  id newValue;
  
  if ([[self exposedBindings] containsObject: binding])
    {
      [self unbind: binding];

      info = [NSDictionary dictionaryWithObjectsAndKeys:
        anObject, NSObservedObjectKey,
        keyPath, NSObservedKeyPathKey,
        options, NSOptionsKey,
        nil];
      [anObject addObserver: self
                 forKeyPath: keyPath
                    options: NSKeyValueObservingOptionNew
                    context: binding];
      [bindingLock lock];
      bindings = (NSMutableDictionary *)NSMapGet(objectTable, (void *)self);
      if (bindings == nil)
        {
          bindings = [NSMutableDictionary dictionary];
          NSMapInsert(objectTable, (void*)self, (void*)bindings);
        }
      [bindings setValue: info forKey: binding];
      [bindingLock unlock];

      newValue = [anObject valueForKeyPath: keyPath];
      newValue = GSBindingTransformedValue(newValue, options);
      [self setValue: newValue forKey: binding];
    }
  else
    {
      NSLog(@"No binding exposed on %@ for %@", self, binding);
    }
}

- (NSDictionary *) infoForBinding: (NSString *)binding
{
  NSMutableDictionary *bindings;
  NSDictionary *info;

  setup();
  [bindingLock lock];
  bindings = (NSMutableDictionary *)NSMapGet(objectTable, (void *)self);
  if (bindings != nil)
    {
      info = [bindings objectForKey: binding];
    }
  [bindingLock unlock];
  return [[info copy] autorelease];
}

- (void) unbind: (NSString *)binding
{
  NSMutableDictionary *bindings;
  NSDictionary *info;
  id observedObject;
  NSString *keyPath;

  if (!objectTable)
    return;

  [bindingLock lock];
  bindings = (NSMutableDictionary *)NSMapGet(objectTable, (void *)self);
  if (bindings != nil)
    {
      info = [bindings objectForKey: binding];
      if (info != nil)
        {
          observedObject = [info objectForKey: NSObservedObjectKey];
          keyPath = [info objectForKey: NSObservedKeyPathKey];
          [observedObject removeObserver: self forKeyPath: keyPath];
          [bindings setValue: nil forKey: binding];
        }
    }
  [bindingLock unlock];
}

// FIXME: This method should not be defined on this class, as it make all
// other value observation impossible. Better add a new GSBinding class
// to handle this. Perhaps with plenty of specific subclasses for the 
// different special cases?
- (void) observeValueForKeyPath: (NSString *)keyPath
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  NSMutableDictionary *bindings;
  NSString *binding = (NSString *)context;

  setup();
  [bindingLock lock];
  bindings = (NSMutableDictionary *)NSMapGet(objectTable, (void *)self);
  if (bindings != nil)
    {
      NSDictionary *info;

      info = [bindings objectForKey: binding];
      if (info != nil)
        {
          NSDictionary *options;
          id newValue;

          options = [info objectForKey: NSOptionsKey];
          newValue = [change objectForKey: NSKeyValueChangeNewKey];
          newValue = GSBindingTransformedValue(newValue, options);
          [self setValue: newValue forKey: binding];
        }
    }
  [bindingLock unlock];
}

@end


//Helper functions
BOOL GSBindingResolveMultipleValueBool(NSString *key, NSDictionary *bindings,
    GSBindingOperationKind operationKind)
{
  NSString *bindingName;
  NSDictionary *info;
  int count = 1;
  id object;
  NSString *keyPath;
  id value;
  NSDictionary *options;
 
  bindingName = key;
  while ((info = [bindings objectForKey: bindingName]))
    {
      object = [info objectForKey: NSObservedObjectKey];
      keyPath = [info objectForKey: NSObservedKeyPathKey];
      options = [info objectForKey: NSOptionsKey];

      value = [object valueForKeyPath: keyPath];
      value = GSBindingTransformedValue(value, options);
      if ([value boolValue] == operationKind)
        {
          return operationKind;
        }
      bindingName = [NSString stringWithFormat: @"%@%i", key, ++count];
    }
  return !operationKind;
}

void GSBindingInvokeAction(NSString *targetKey, NSString *argumentKey,
    NSDictionary *bindings)
{
  NSString *bindingName;
  NSDictionary *info;
  NSDictionary *options;
  int count = 1;
  id object;
  id target;
  SEL selector;
  NSString *keyPath;
  NSInvocation *invocation;

  info = [bindings objectForKey: targetKey];
  object = [info objectForKey: NSObservedObjectKey];
  keyPath = [info objectForKey: NSObservedKeyPathKey];
  options = [info objectForKey: NSOptionsKey];

  target = [object valueForKeyPath: keyPath];
  selector = NSSelectorFromString([options objectForKey: 
      NSSelectorNameBindingOption]);
  if (target == nil || selector == NULL) return;

  invocation = [NSInvocation invocationWithMethodSignature:
    [target methodSignatureForSelector: selector]];
  [invocation setSelector: selector];

  bindingName = argumentKey;
  while ((info = [bindings objectForKey: bindingName]))
    {
      object = [info objectForKey: NSObservedObjectKey];
      keyPath = [info objectForKey: NSObservedKeyPathKey];
      if ((object = [object valueForKeyPath: keyPath]))
        {
          [invocation setArgument: object atIndex: ++count];
        }
      bindingName = [NSString stringWithFormat: @"%@%i", argumentKey, count];
    }
  [invocation invoke];
}

void GSBindingLock()
{
  [bindingLock lock];
}

void GSBindingReleaseLock()
{
  [bindingLock unlock];
}

NSMutableDictionary *GSBindingListForObject(id object)
{
  NSMutableDictionary *list;

  if (!objectTable)
    return nil;

  list = (NSMutableDictionary *)NSMapGet(objectTable, (void *)object);
  if (list == nil)
    {
      list = [NSMutableDictionary dictionary];
      NSMapInsert(objectTable, (void *)object, (void *)list);
    }
  return list;
}

void GSBindingUnbindAll(id object)
{
  NSEnumerator *enumerator;
  NSString *binding;
  NSDictionary *list;

  if (!objectTable)
    return;

  [bindingLock lock];
  list = (NSDictionary *)NSMapGet(objectTable, (void *)object);
  if (list != nil)
    {
      enumerator = [list keyEnumerator];
      while ((binding = [enumerator nextObject]))
        {
          [object unbind: binding];
        }
      NSMapRemove(objectTable, (void *)object);
    }
  [bindingLock unlock];
}
  
NSArray *GSBindingExposeMultipleValueBindings(
    NSArray *bindingNames,
    NSMutableDictionary *bindingList)
{
  NSEnumerator *nameEnum;
  NSString *name;
  NSString *numberedName;
  NSMutableArray *additionalBindings;
  int count;

  additionalBindings = [NSMutableArray array];
  nameEnum = [bindingNames objectEnumerator];
  while ((name = [nameEnum nextObject]))
    {
      count = 1;
      numberedName = name;
      while ([bindingList objectForKey: numberedName] != nil)
        {
          numberedName = [NSString stringWithFormat: @"%@%i", name, ++count];
          [additionalBindings addObject: numberedName];
        }
    }
  return additionalBindings;
}


NSArray *GSBindingExposePatternBindings(
    NSArray *bindingNames,
    NSMutableDictionary *bindingList)
{
  NSEnumerator *nameEnum;
  NSString *name;
  NSString *numberedName;
  NSMutableArray *additionalBindings;
  int count;

  additionalBindings = [NSMutableArray array];
  nameEnum = [bindingNames objectEnumerator];
  while ((name = [nameEnum nextObject]))
    {
      count = 1;
      numberedName = [NSString stringWithFormat:@"%@1", name];
      while ([bindingList objectForKey: numberedName] != nil)
        {
          numberedName = [NSString stringWithFormat:@"%@%i", name, ++count];
          [additionalBindings addObject: numberedName];
        }
    }
  return additionalBindings;
}

id GSBindingTransformedValue(id value, NSDictionary *options)
{
  NSString *valueTransformerName;
  NSValueTransformer *valueTransformer;
  NSString *placeholder;

  if (value == NSMultipleValuesMarker)
    {
      placeholder = [options objectForKey: NSMultipleValuesPlaceholderBindingOption];
      if (placeholder == nil)
        {
          placeholder = @"Multiple Values";
        }
      return placeholder;
    }
  if (value == NSNoSelectionMarker)
    {
      placeholder = [options objectForKey: NSNoSelectionPlaceholderBindingOption];
      if (placeholder == nil)
        {
          placeholder = @"No Selection";
        }
      return placeholder;
    }
  if (value == NSNotApplicableMarker)
    {
      if ([[options objectForKey: NSRaisesForNotApplicableKeysBindingOption]
          boolValue])
        {
          [NSException raise: NSGenericException
                      format: @"This binding does not accept not applicable keys"];
        }

      placeholder = [options objectForKey:
        NSNotApplicablePlaceholderBindingOption];
      if (placeholder == nil)
        {
          placeholder = @"Not Applicable";
        }
      return placeholder;
    }
  if (value == nil)
    {
      placeholder = [options objectForKey:
        NSNullPlaceholderBindingOption];
      if (placeholder == nil)
        {
          placeholder = @"";
        }
      return placeholder;
    }

  valueTransformerName = [options objectForKey:
    NSValueTransformerNameBindingOption];
  if (valueTransformerName != nil)
    {
      valueTransformer = [NSValueTransformer valueTransformerForName:
                                                 valueTransformerName];
    }
  else
    {
      valueTransformer = [options objectForKey:
                                      NSValueTransformerBindingOption];
    }

  if (valueTransformer != nil)
    {
      value = [valueTransformer transformedValue: value];
    }

  return value;
}
      
id GSBindingReverseTransformedValue(id value, NSDictionary *options)
{
  NSValueTransformer *valueTransformer;
  NSString *valueTransformerName;

  valueTransformerName = [options objectForKey: 
    NSValueTransformerNameBindingOption];
  valueTransformer = [NSValueTransformer valueTransformerForName:
    valueTransformerName];
  if (valueTransformer && [[valueTransformer class]
      allowsReverseTransformation])
    {
      value = [valueTransformer reverseTransformedValue: value];
    }
  return value;
}

/*
@interface _GSStateMarker : NSObject
{
  NSString * description;
}
@end

@implementation _GSStateMarker

- (id) initWithType: (int)type
{
  if (type == 0)
    {
      description = @"<MULTIPLE VALUES MARKER>";
    }
  else if (type == 1)
    {
     description = @"<NO SELECTION MARKER>";
    }
  else
    {
      description = @"<NOT APPLICABLE MARKER>";
    }

  return self;
}

- (id) valueForKey: (NSString *)key
{
  return self;
}

- (id) retain { return self; }
- (oneway void) release {}

- (NSString *) description
{
  return description;
}

@end
*/
