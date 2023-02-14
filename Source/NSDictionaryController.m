/* Implementation of class NSDictionaryController
   Copyright (C) 2021 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: 16-10-2021

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSException.h>

#import "AppKit/NSDictionaryController.h"
#import "AppKit/NSKeyValueBinding.h"

#import "GSBindingHelpers.h"
#import "GSFastEnumeration.h"

@implementation NSDictionaryController

+ (void) initialize
{
  if (self == [NSDictionaryController class])
    {
      [self exposeBinding: NSContentDictionaryBinding];
      [self exposeBinding: NSIncludedKeysBinding];
      //[self exposeBinding: NSExcludedKeysBinding];
      //[self exposeBinding: NSInitialKeyBinding];
      //[self exposeBinding: NSInitialValueBinding];
      //[self setKeys: [NSArray arrayWithObjects: NSContentBinding, NSContentObjectBinding, nil]
      //    triggerChangeNotificationsForDependentKey: @"arrangedObjects"];
    }
}

- (NSDictionaryControllerKeyValuePair *) newObject
{
  NSDictionaryControllerKeyValuePair *o = [[NSDictionaryControllerKeyValuePair alloc] init];
  NSString *k = [NSString stringWithFormat: @"%@%lu", _initialKey, _count];
  NSString *v = [NSString stringWithFormat: @"%@%lu", _initialValue, _count];

  [o setKey: k];
  [o setValue: v];

  _count++;
  AUTORELEASE(o);

  return o;
}

- (NSString *) initialKey
{
  return [_initialKey copy];
}

- (void) setInitialKey: (NSString *)key
{
  ASSIGN(_initialKey, key);
}

- (id) initialValue
{
  return [_initialValue copy];
}

- (void) setInitialValue: (id)value
{
  ASSIGN(_initialValue, value);
}

- (NSArray *) includedKeys
{
  return [_includedKeys copy];
}

- (void) setIncludedKeys: (NSArray *)includedKeys
{
  ASSIGN(_includedKeys, includedKeys);
}

- (NSArray *) excludedKeys
{
  return [_excludedKeys copy];
}

- (void) setExcludedKeys: (NSArray *)excludedKeys
{
  ASSIGN(_excludedKeys, excludedKeys);
}

- (NSDictionary *) localizedKeyDictionary
{
  return [_localizedKeyDictionary copy];
}

- (void) setLocalizedKeyDictionary: (NSDictionary *)dict
{
  ASSIGN(_localizedKeyDictionary, dict);
}

- (NSString *) localizedKeyTable
{
  return [_localizedKeyTable copy];
}

- (void) setLocalizedKeyTable: (NSString *)keyTable
{
  ASSIGN(_localizedKeyTable, keyTable);
}

- (NSArray *) _buildArray: (NSDictionary *)content
{
  NSArray *allKeys = [content allKeys];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: [allKeys count]];

  NSLog(@"includedKeys = %@", _includedKeys);
  FOR_IN(id, k, allKeys)
    {
      NSDictionaryControllerKeyValuePair *kvp =
	AUTORELEASE([[NSDictionaryControllerKeyValuePair alloc] init]);
      id v = [[self content] objectForKey: k];

      [kvp setKey: k];
      [kvp setValue: v];

      if (![_excludedKeys containsObject: k])
	{
	  [kvp setExplicitlyIncluded: NO];
	}

      [result addObject: kvp];
    }
  END_FOR_IN(allKeys);

  return result;
}

- (void) setContent: (id)content
{
  [super setContent: [self _buildArray: content]];
}

- (void) observeValueForKeyPath: (NSString*)aPath
		       ofObject: (id)anObject
			 change: (NSDictionary*)aChange
			context: (void*)aContext
{
  [NSException raise: NSInvalidArgumentException
	      format: @"-%@ cannot be sent to %@ ..."
	      @" create an instance overriding this",
	      NSStringFromSelector(_cmd), NSStringFromClass([self class])];
  return;
}

- (void) bind: (NSString *)binding
     toObject: (id)anObject
  withKeyPath: (NSString *)keyPath
      options: (NSDictionary *)options
{
  if ([binding isEqual: NSContentDictionaryBinding])
    {
      GSKeyValueBinding *kvb;

      [self unbind: binding];
      kvb = [[GSKeyValueBinding alloc] initWithBinding: @"content"
					      withName: binding
					      toObject: anObject
					   withKeyPath: keyPath
					       options: options
					    fromObject: self];
      // The binding will be retained in the binding table
      RELEASE(kvb);
    }
  else
    {
      [super bind: binding
	 toObject: anObject
      withKeyPath: keyPath
	  options: options];
    }
}

- (Class) valueClassForBinding: (NSString *)binding
{
  if ([binding isEqual: NSContentDictionaryBinding])
    {
      return [NSDictionary class];
    }
  else
    {
      return [super valueClassForBinding: binding];
    }
}

@end

@implementation NSDictionaryControllerKeyValuePair

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _key = nil;
      _value = nil;
      _localizedKey = nil;
      _explicitlyIncluded = YES;
    }
  return self;
}

/**
 * Returns a copy of the key
 */
- (NSString *) key
{
  return [_key copy];
}

- (void) setKey: (NSString *)key
{
  ASSIGN(_key, key);
}

/**
 * Returns a strong reference to the value
 */
- (id) value
{
  return [_value copy];
}

- (void) setValue: (id)value
{
  ASSIGN(_value, value);
}

- (NSString *) localizedKey
{
  return [_localizedKey copy];
}

- (void) setLocalizedKey: (NSString *)localizedKey
{
  ASSIGN(_localizedKey, localizedKey);
}

- (BOOL) isExplicitlyIncluded
{
  return _explicitlyIncluded;
}

- (void) setExplicitlyIncluded: (BOOL)flag
{
  _explicitlyIncluded = flag;
}

@end
