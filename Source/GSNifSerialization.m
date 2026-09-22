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
#import <Foundation/NSTimeZone.h>

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

static NSInteger
GSNifKeyRank(NSString *key)
{
  static NSArray *keys = nil;
  NSUInteger index;

  if (keys == nil)
    keys = [[NSArray alloc] initWithObjects:
      @"format", @"version", @"objects", @"topLevelObjects", @"connections",
      @"$id", @"$class", @"properties", @"$ref", @"$type", @"$value",
      @"kind", @"source", @"destination", @"label", nil];
  index = [keys indexOfObject: key];
  return index == NSNotFound ? 1000 : (NSInteger)index;
}

static NSComparisonResult
GSNifCompareKeys(id left, id right, void *context)
{
  NSInteger leftRank = GSNifKeyRank(left);
  NSInteger rightRank = GSNifKeyRank(right);

  if (leftRank < rightRank)
    return NSOrderedAscending;
  if (leftRank > rightRank)
    return NSOrderedDescending;
  return [left compare: right];
}

static NSString *
GSNifConnectionSortKey(NSDictionary *connection)
{
  return [NSString stringWithFormat: @"%@\t%@\t%@\t%@",
    [[connection objectForKey: @"source"] objectForKey: @"$ref"],
    [connection objectForKey: @"kind"],
    [connection objectForKey: @"label"],
    [[connection objectForKey: @"destination"] objectForKey: @"$ref"]];
}

static NSComparisonResult
GSNifCompareConnections(id left, id right, void *context)
{
  return [GSNifConnectionSortKey(left) compare: GSNifConnectionSortKey(right)];
}

@interface GSNifXMLWriter : NSObject
{
  NSMutableString *_xml;
}
- (NSData *) dataWithPropertyList: (id)propertyList;
@end


@implementation GSNifXMLWriter

- (NSString *) escapedString: (NSString *)string
{
  NSMutableString *escaped = [NSMutableString stringWithString: string];
  [escaped replaceOccurrencesOfString: @"&" withString: @"&amp;"
                              options: 0 range: NSMakeRange(0, [escaped length])];
  [escaped replaceOccurrencesOfString: @"<" withString: @"&lt;"
                              options: 0 range: NSMakeRange(0, [escaped length])];
  [escaped replaceOccurrencesOfString: @">" withString: @"&gt;"
                              options: 0 range: NSMakeRange(0, [escaped length])];
  return escaped;
}

- (NSString *) base64StringForData: (NSData *)data
{
  static const char alphabet[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  const unsigned char *bytes = [data bytes];
  NSUInteger length = [data length];
  NSMutableString *result = [NSMutableString stringWithCapacity: ((length + 2) / 3) * 4];
  NSUInteger index;

  for (index = 0; index < length; index += 3)
    {
      unsigned value = ((unsigned)bytes[index]) << 16;
      NSUInteger remaining = length - index;
      if (remaining > 1) value |= ((unsigned)bytes[index + 1]) << 8;
      if (remaining > 2) value |= bytes[index + 2];
      [result appendFormat: @"%c%c%c%c",
        alphabet[(value >> 18) & 63], alphabet[(value >> 12) & 63],
        remaining > 1 ? alphabet[(value >> 6) & 63] : '=',
        remaining > 2 ? alphabet[value & 63] : '='];
    }
  return result;
}

- (void) appendIndent: (NSUInteger)indent
{
  while (indent-- != 0)
    [_xml appendString: @"  "];
}

- (void) appendValue: (id)value indent: (NSUInteger)indent
{
  [self appendIndent: indent];
  if ([value isKindOfClass: [NSString class]])
    [_xml appendFormat: @"<string>%@</string>\n", [self escapedString: value]];
  else if ([value isKindOfClass: [NSNumber class]])
    {
      const char *type = [value objCType];
      if (strcmp(type, @encode(BOOL)) == 0)
        [_xml appendString: [value boolValue] ? @"<true/>\n" : @"<false/>\n"];
      else if (strchr("fd", type[0]) != NULL)
        [_xml appendFormat: @"<real>%.17g</real>\n", [value doubleValue]];
      else if (strchr("CISLQ", type[0]) != NULL)
        [_xml appendFormat: @"<integer>%llu</integer>\n", [value unsignedLongLongValue]];
      else
        [_xml appendFormat: @"<integer>%lld</integer>\n", [value longLongValue]];
    }
  else if ([value isKindOfClass: [NSData class]])
    [_xml appendFormat: @"<data>%@</data>\n", [self base64StringForData: value]];
  else if ([value isKindOfClass: [NSDate class]])
    {
      NSString *date = [value descriptionWithCalendarFormat: @"%Y-%m-%dT%H:%M:%SZ"
                                                   timeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]
                                                     locale: nil];
      [_xml appendFormat: @"<date>%@</date>\n", date];
    }
  else if ([value isKindOfClass: [NSArray class]])
    {
      NSEnumerator *enumerator = [value objectEnumerator];
      id child;
      [_xml appendString: @"<array>\n"];
      while ((child = [enumerator nextObject]) != nil)
        [self appendValue: child indent: indent + 1];
      [self appendIndent: indent];
      [_xml appendString: @"</array>\n"];
    }
  else if ([value isKindOfClass: [NSDictionary class]])
    {
      NSArray *keys = [[value allKeys] sortedArrayUsingFunction: GSNifCompareKeys
                                                        context: NULL];
      NSEnumerator *enumerator = [keys objectEnumerator];
      NSString *key;
      [_xml appendString: @"<dict>\n"];
      while ((key = [enumerator nextObject]) != nil)
        {
          [self appendIndent: indent + 1];
          [_xml appendFormat: @"<key>%@</key>\n", [self escapedString: key]];
          [self appendValue: [value objectForKey: key] indent: indent + 1];
        }
      [self appendIndent: indent];
      [_xml appendString: @"</dict>\n"];
    }
  else
    [NSException raise: NSInvalidArgumentException
                format: @"Unsupported NIF property-list value %@", value];
}

- (NSData *) dataWithPropertyList: (id)propertyList
{
  _xml = [NSMutableString stringWithString:
    @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
     "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "
     "\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
     "<plist version=\"1.0\">\n"];
  [self appendValue: propertyList indent: 0];
  [_xml appendString: @"</plist>\n"];
  return [_xml dataUsingEncoding: NSUTF8StringEncoding];
}

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
      NSArray *keys = [[value allKeys] sortedArrayUsingSelector: @selector(compare:)];
      NSEnumerator *enumerator = [keys objectEnumerator];
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

    enumerator = [[[self propertyKeysForObject: value]
      sortedArrayUsingSelector: @selector(compare:)] objectEnumerator];
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

  [encodedConnections sortUsingFunction: GSNifCompareConnections context: NULL];

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
      data = [[[[GSNifXMLWriter alloc] init] autorelease]
        dataWithPropertyList: document];
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
