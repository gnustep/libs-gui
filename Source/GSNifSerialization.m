/** <title>GSNifSerialization</title>

   Writer for Native Interface Format (NIF) files.

   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.
*/

#import "config.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSString.h>

#include <string.h>

#import "GNUstepGUI/GSNifSerialization.h"

@interface GSNifEncoder : NSObject
{
  NSDictionary *_propertyKeys;
  NSMapTable *_identifiers;
  NSUInteger _nextIdentifier;
}
- (id) initWithPropertyKeys: (NSDictionary *)propertyKeys;
- (NSDictionary *) documentWithTopLevelObjects: (NSArray *)topLevelObjects
                                      connections: (NSArray *)connections;
@end

@implementation GSNifEncoder

- (id) initWithPropertyKeys: (NSDictionary *)propertyKeys
{
  self = [super init];
  if (self != nil)
    {
      _propertyKeys = [propertyKeys copy];
      _identifiers = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                                      NSObjectMapValueCallBacks, 0);
      _nextIdentifier = 1;
    }
  return self;
}

- (void) dealloc
{
  [_propertyKeys release];
  NSFreeMapTable(_identifiers);
  [super dealloc];
}

- (NSArray *) propertyKeysForObject: (id)object
{
  Class currentClass = [object class];
  NSArray *keys = nil;

  while (currentClass != Nil && keys == nil)
    {
      keys = [_propertyKeys objectForKey: NSStringFromClass(currentClass)];
      currentClass = [currentClass superclass];
    }
  return keys != nil ? keys : [NSArray array];
}

- (NSString *) newIdentifierForObject: (id)object
{
  NSString *identifier = [NSString stringWithFormat: @"object-%lu",
    (unsigned long)_nextIdentifier++];
  NSMapInsert(_identifiers, object, identifier);
  return identifier;
}

- (NSDictionary *) typedValue: (NSValue *)value
{
  const char *type = [value objCType];
  NSString *name = nil;
  NSString *string = nil;

  if (strcmp(type, @encode(NSRect)) == 0)
    {
      name = @"rect";
      string = NSStringFromRect([value rectValue]);
    }
  else if (strcmp(type, @encode(NSPoint)) == 0)
    {
      name = @"point";
      string = NSStringFromPoint([value pointValue]);
    }
  else if (strcmp(type, @encode(NSSize)) == 0)
    {
      name = @"size";
      string = NSStringFromSize([value sizeValue]);
    }
  else if (strcmp(type, @encode(NSRange)) == 0)
    {
      name = @"range";
      string = NSStringFromRange([value rangeValue]);
    }
  else if (strcmp(type, @encode(SEL)) == 0)
    {
      SEL selector;
      [value getValue: &selector];
      name = @"selector";
      string = NSStringFromSelector(selector);
    }
  else
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"NIF cannot encode NSValue with type '%s'", type];
    }

  return [NSDictionary dictionaryWithObjectsAndKeys:
    name, @"$type", string, @"$value", nil];
}

- (id) encodedValue: (id)value
{
  if (value == nil)
    return nil;
  if ([value isKindOfClass: [NSString class]]
      || [value isKindOfClass: [NSNumber class]]
      || [value isKindOfClass: [NSData class]]
      || [value isKindOfClass: [NSDate class]])
    return value;
  if ([value isKindOfClass: [NSNull class]])
    [NSException raise: NSInvalidArgumentException
                format: @"NIF does not support NSNull property values"];
  if ([value isKindOfClass: [NSValue class]])
    return [self typedValue: value];
  if ([value isKindOfClass: [NSArray class]])
    {
      NSMutableArray *result = [NSMutableArray arrayWithCapacity: [value count]];
      NSEnumerator *enumerator = [value objectEnumerator];
      id child;
      while ((child = [enumerator nextObject]) != nil)
        {
          id encoded = [self encodedValue: child];
          if (encoded == nil)
            [NSException raise: NSInvalidArgumentException
                        format: @"NIF cannot encode nil in an array"];
          [result addObject: encoded];
        }
      return result;
    }
  if ([value isKindOfClass: [NSDictionary class]])
    {
      NSMutableDictionary *result = [NSMutableDictionary dictionary];
      NSEnumerator *enumerator = [value keyEnumerator];
      id key;
      while ((key = [enumerator nextObject]) != nil)
        {
          id encoded;
          if (![key isKindOfClass: [NSString class]])
            [NSException raise: NSInvalidArgumentException
                        format: @"NIF dictionary keys must be strings"];
          encoded = [self encodedValue: [value objectForKey: key]];
          if (encoded != nil)
            [result setObject: encoded forKey: key];
        }
      return result;
    }

  {
    NSString *identifier = NSMapGet(_identifiers, value);
    NSMutableDictionary *definition;
    NSMutableDictionary *properties;
    NSEnumerator *enumerator;
    NSString *key;

    if (identifier != nil)
      return [NSDictionary dictionaryWithObject: identifier forKey: @"$ref"];

    identifier = [self newIdentifierForObject: value];
    definition = [NSMutableDictionary dictionaryWithObjectsAndKeys:
      identifier, @"$id", NSStringFromClass([value class]), @"$class", nil];
    properties = [NSMutableDictionary dictionary];
    /* Register before descending so cycles become references. */
    [definition setObject: properties forKey: @"properties"];

    enumerator = [[self propertyKeysForObject: value] objectEnumerator];
    while ((key = [enumerator nextObject]) != nil)
      {
        id encoded = [self encodedValue: [value valueForKey: key]];
        if (encoded != nil)
          [properties setObject: encoded forKey: key];
      }
    return definition;
  }
}

- (NSDictionary *) referenceForEndpoint: (id)endpoint
{
  NSString *identifier;

  if ([endpoint isKindOfClass: [NSString class]]
      && ([endpoint isEqualToString: @"owner"]
          || [endpoint isEqualToString: @"application"]))
    identifier = endpoint;
  else
    identifier = NSMapGet(_identifiers, endpoint);

  if (identifier == nil)
    [NSException raise: NSInvalidArgumentException
                format: @"NIF connection endpoint %@ is not in the object graph",
                        endpoint];
  return [NSDictionary dictionaryWithObject: identifier forKey: @"$ref"];
}

- (NSDictionary *) documentWithTopLevelObjects: (NSArray *)topLevelObjects
                                      connections: (NSArray *)connections
{
  NSMutableArray *objects = [NSMutableArray array];
  NSMutableArray *topLevel = [NSMutableArray array];
  NSMutableArray *encodedConnections = [NSMutableArray array];
  NSEnumerator *enumerator = [topLevelObjects objectEnumerator];
  id object;

  while ((object = [enumerator nextObject]) != nil)
    {
      id encoded = [self encodedValue: object];
      NSString *identifier = NSMapGet(_identifiers, object);
      if ([encoded objectForKey: @"$class"] != nil)
        [objects addObject: encoded];
      [topLevel addObject:
        [NSDictionary dictionaryWithObject: identifier forKey: @"$ref"]];
    }

  enumerator = [connections objectEnumerator];
  while ((object = [enumerator nextObject]) != nil)
    {
      NSString *kind = [object objectForKey: @"kind"];
      NSString *label = [object objectForKey: @"label"];
      if ((!([kind isEqualToString: @"outlet"]
             || [kind isEqualToString: @"action"])) || label == nil)
        [NSException raise: NSInvalidArgumentException
                    format: @"Invalid NIF connection %@", object];
      [encodedConnections addObject: [NSDictionary dictionaryWithObjectsAndKeys:
        kind, @"kind",
        [self referenceForEndpoint: [object objectForKey: @"source"]], @"source",
        [self referenceForEndpoint: [object objectForKey: @"destination"]], @"destination",
        label, @"label", nil]];
    }

  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"NIF", @"format",
    [NSNumber numberWithInteger: 1], @"version",
    objects, @"objects",
    topLevel, @"topLevelObjects",
    encodedConnections, @"connections", nil];
}

@end

@implementation GSNifSerialization

+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                        propertyKeys: (NSDictionary *)propertyKeys
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription
{
  NSData *data = nil;

  if (errorDescription != NULL)
    *errorDescription = nil;
  NS_DURING
    {
      GSNifEncoder *encoder = [[[GSNifEncoder alloc]
        initWithPropertyKeys: propertyKeys] autorelease];
      NSDictionary *document = [encoder
        documentWithTopLevelObjects: topLevelObjects
                        connections: connections != nil ? connections : [NSArray array]];
      data = [NSPropertyListSerialization dataFromPropertyList: document
                                                        format: NSPropertyListXMLFormat_v1_0
                                              errorDescription: errorDescription];
    }
  NS_HANDLER
    {
      if (errorDescription != NULL)
        *errorDescription = [[localException reason] copy];
      data = nil;
    }
  NS_ENDHANDLER
  return data;
}

@end
