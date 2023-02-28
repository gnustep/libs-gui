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

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSString.h>

#import "AppKit/NSDictionaryController.h"
#import "AppKit/NSKeyValueBinding.h"

#import "GSBindingHelpers.h"
#import "GSFastEnumeration.h"

// Private methods for NSString and NSDictionary...
@interface NSDictionary (GSPrivate_DictionaryToStrings)

- (NSString *) _stringsFromDictionary;

@end

@implementation NSDictionary (GSPrivate_DictionaryToStrings)

- (NSString *) _stringsFromDictionary
{
  NSEnumerator *en = [self keyEnumerator];
  NSString *k = nil;
  NSString *result = @"";

  while ((k = [en nextObject]) != nil)
    {
      NSString *v = [self objectForKey: k];
      result = [result stringByAppendingString:
			 [NSString stringWithFormat: @"\"%@\" = \"%@\";\n", k, v]];
    }

  return result;
}

@end

@interface NSString (GSPrivate_StringsToDictionary)

- (NSDictionary *) _dictionaryFromStrings;

@end

@implementation NSString (GSPrivate_StringsToDictionary)

- (NSDictionary *) _dictionaryFromStrings
{
  NSError *error = nil;
  NSDictionary *dictionary =
    [NSPropertyListSerialization
      propertyListWithData: [self dataUsingEncoding: NSUTF8StringEncoding]
		   options: NSPropertyListImmutable
		    format: NULL
		     error: &error];
  if (error != nil)
    {
      NSLog(@"Error reading strings file: %@", error);
    }

  return dictionary;
}

@end

@interface NSDictionaryController (GSPrivate_BuildArray)

- (NSArray *) _buildArray: (NSDictionary *)content;
- (NSDictionary *) _rebuildDictionary;

@end

@implementation NSDictionaryController (GSPrivate_BuildArray)

- (NSArray *) _buildArray: (NSDictionary *)content
{
  NSArray *allKeys = [content keysSortedByValueUsingSelector: @selector(compare:)];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: [allKeys count]];

  FOR_IN(id, k, allKeys)
    {
      NSDictionaryControllerKeyValuePair *kvp =
	AUTORELEASE([[NSDictionaryControllerKeyValuePair alloc] init]);
      id v = [content objectForKey: k];
      NSString *localizedKey = [_localizedKeyDictionary objectForKey: k];

      [kvp setLocalizedKey: localizedKey];
      [kvp setKey: k];
      [kvp setValue: v];

      if (![_excludedKeys containsObject: k])
	{
	  [kvp setExplicitlyIncluded: NO];
	}

      if ([_includedKeys containsObject: k])
	{
	  [kvp setExplicitlyIncluded: YES];
	}
      else
	{
	  [kvp setExplicitlyIncluded: NO];
	}

      [result addObject: kvp];
    }
  END_FOR_IN(allKeys);

  return result;
}

- (NSDictionary *) _rebuildDictionary
{
  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  FOR_IN(NSDictionaryControllerKeyValuePair*, kvp, _content)
    {
      NSString *k = [kvp key];
      NSString *v = [kvp value];

      [result setObject: v forKey: k];
    }
  END_FOR_IN(_content);

  return [result copy];
}

@end

// NSDictionary class implementation...
@implementation NSDictionaryController

+ (void) initialize
{
  if (self == [NSDictionaryController class])
    {
      [self exposeBinding: NSContentDictionaryBinding];
      [self exposeBinding: NSIncludedKeysBinding];
      [self exposeBinding: NSExcludedKeysBinding];
      [self exposeBinding: NSInitialKeyBinding];
      [self exposeBinding: NSInitialValueBinding];
      [self setKeys: [NSArray arrayWithObjects: NSContentBinding, NSContentObjectBinding,
			      NSExcludedKeysBinding, NSIncludedKeysBinding, nil]
	    triggerChangeNotificationsForDependentKey: @"arrangedObjects"];
    }
}

- (void) _setup
{
  _contentDictionary = [[NSMutableDictionary alloc] init];
  _includedKeys = [[NSArray alloc] init];
  _excludedKeys = [[NSArray alloc] init];
  _initialKey = @"key";
  _initialValue = @"value";
  _count = 0;
}

- (instancetype) initWithContent: (id)content
{
  self = [super initWithContent: content];

  if (self != nil)
    {
      [self _setup];
    }

  return self;
}

- (void) dealloc
{
  RELEASE(_contentDictionary);
  RELEASE(_includedKeys);
  RELEASE(_excludedKeys);
  RELEASE(_initialKey);
  RELEASE(_initialValue);
  [super dealloc];
}

- (void) addObject: (id)obj
{
  NSString *k = [obj key];
  NSString *v = [obj value];

  [super addObject: obj];
  [_contentDictionary setObject: v
			 forKey: k];
}

- (void) addObjects: (NSArray *)array
{
  [super addObjects: array];

  FOR_IN(NSDictionaryControllerKeyValuePair*, kvp, array)
    {
      NSString *k = [kvp key];
      NSString *v = [kvp value];

      [_contentDictionary setObject: v
			     forKey: k];
    }
  END_FOR_IN(array);
}

- (void) removeObject: (id)obj
{
  NSString *k = [obj key];

  [super removeObject: obj];
  [_contentDictionary removeObjectForKey: k];
}

- (void) removeObjects: (NSArray *)array
{
  [super addObjects: array];

  FOR_IN(NSDictionaryControllerKeyValuePair*, kvp, array)
    {
      NSString *k = [kvp key];

      [_contentDictionary removeObjectForKey: k];
    }
  END_FOR_IN(array);
}

- (NSDictionaryControllerKeyValuePair *) newObject
{
  NSDictionaryControllerKeyValuePair *kvp = [[NSDictionaryControllerKeyValuePair alloc] init];
  NSString *k = nil;

  if (_count > 0)
    {
      k = [NSString stringWithFormat: @"%@%lu", _initialKey, _count];
    }
  else
    {
      k = [_initialKey copy];
    }
  
  [kvp setKey: k];
  [kvp setValue: _initialValue];

  _count++;
  AUTORELEASE(kvp);

  return kvp;
}

- (NSString *) initialKey
{
  return _initialKey;
}

- (void) setInitialKey: (NSString *)key
{
  ASSIGNCOPY(_initialKey, key);
}

- (id) initialValue
{
  return _initialValue;
}

- (void) setInitialValue: (id)value
{
  ASSIGNCOPY(_initialValue, value);
}

- (NSArray *) includedKeys
{
  return _includedKeys;
}

- (void) setIncludedKeys: (NSArray *)includedKeys
{
  ASSIGNCOPY(_includedKeys, includedKeys);
  [self rearrangeObjects];
}

- (NSArray *) excludedKeys
{
  return _excludedKeys;
}

- (void) setExcludedKeys: (NSArray *)excludedKeys
{
  [self willChangeValueForKey: NSContentBinding];
  ASSIGNCOPY(_excludedKeys, excludedKeys);
  [self setContent: _contentDictionary];
  [self didChangeValueForKey: NSContentBinding];
}

- (NSDictionary *) localizedKeyDictionary
{
  return _localizedKeyDictionary;
}

- (void) setLocalizedKeyDictionary: (NSDictionary *)dict
{
  NSString *strings = [dict _stringsFromDictionary];
  ASSIGN(_localizedKeyTable, strings);
  ASSIGNCOPY(_localizedKeyDictionary, dict);
  [self rearrangeObjects];
}

- (NSString *) localizedKeyTable
{
  return _localizedKeyTable;
}

- (void) setLocalizedKeyTable: (NSString *)keyTable
{
  NSDictionary *dictionary = [keyTable _dictionaryFromStrings];
  ASSIGN(_localizedKeyDictionary, dictionary);
  ASSIGNCOPY(_localizedKeyTable, keyTable);
  [self rearrangeObjects];
}

- (void) setContent: (id)content
{
  ASSIGN(_contentDictionary, content);
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
      return [NSObject class];
    }
  else
    {
      return nil;
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];

  if (self != nil)
    {
      [self _setup];
    }

  return self;
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
