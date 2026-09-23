/** <title>GSNixSerialization</title>

   Writer for Native Interface XML (NIX) files.

   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.
*/

#import "config.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSCharacterSet.h>
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
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSUUID.h>

#include <string.h>
#include <objc/runtime.h>

#import "GNUstepGUI/GSNixSerialization.h"

@interface GSNixEncoder : NSObject
{
  NSDictionary *_keyValuePairs;
  NSDictionary *_excludedKeys;
  NSMapTable *_explicitIdentifiers;
  NSMapTable *_identifiers;
  NSMutableDictionary *_definitionsByIdentifier;
}
- (id) initWithKeyValuePairs: (NSDictionary *)keyValuePairs
                excludedKeys: (NSDictionary *)excludedKeys
                 identifiers: (NSMapTable *)identifiers;
- (NSDictionary *) documentWithTopLevelObjects: (NSArray *)topLevelObjects
                                      connections: (NSArray *)connections;
@end

static char GSNixIdentifierAssociationKey;

static NSInteger
GSNixKeyRank(NSString *key)
{
  static NSArray *keys = nil;
  NSUInteger index;

  if (keys == nil)
    keys = [[NSArray alloc] initWithObjects:
      @"format", @"version", @"objects", @"topLevelObjects",
      @"$id", @"$class", @"properties", @"connections",
      @"$ref", @"$type", @"$value",
      @"kind", @"source", @"destination", @"label", nil];
  index = [keys indexOfObject: key];
  return index == NSNotFound ? 1000 : (NSInteger)index;
}

static NSComparisonResult
GSNixCompareKeys(id left, id right, void *context)
{
  NSInteger leftRank = GSNixKeyRank(left);
  NSInteger rightRank = GSNixKeyRank(right);

  if (leftRank < rightRank)
    return NSOrderedAscending;
  if (leftRank > rightRank)
    return NSOrderedDescending;
  return [left compare: right];
}

static NSString *
GSNixConnectionSortKey(NSDictionary *connection)
{
  return [NSString stringWithFormat: @"%@\t%@\t%@\t%@",
    [[connection objectForKey: @"source"] objectForKey: @"$ref"],
    [connection objectForKey: @"kind"],
    [connection objectForKey: @"label"],
    [[connection objectForKey: @"destination"] objectForKey: @"$ref"]];
}

static NSComparisonResult
GSNixCompareConnections(id left, id right, void *context)
{
  return [GSNixConnectionSortKey(left) compare: GSNixConnectionSortKey(right)];
}

static BOOL
GSNixIsBuiltInTransientKey(NSString *key)
{
  static NSSet *transientKeys = nil;

  if (transientKeys == nil)
    transientKeys = [[NSSet alloc] initWithObjects:
      @"superview", @"window", @"nextResponder", @"undoManager",
      @"delegate", @"dataSource", @"target",
      @"currentEditor", @"firstResponder", @"fieldEditor",
      @"graphicsContext", @"inLiveResize", nil];

  /* Invalidation flags describe pending work, never model state. */
  return ([transientKeys containsObject: key]
          || [key hasPrefix: @"needs"]);
}

@interface GSNixXMLWriter : NSObject
{
  NSMutableString *_xml;
}
- (NSData *) dataWithPropertyList: (id)propertyList;
@end


@implementation GSNixXMLWriter

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
      NSArray *keys = [[value allKeys] sortedArrayUsingFunction: GSNixCompareKeys
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
                format: @"Unsupported NIX property-list value %@", value];
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

@implementation GSNixEncoder

- (id) initWithKeyValuePairs: (NSDictionary *)keyValuePairs
                excludedKeys: (NSDictionary *)excludedKeys
                 identifiers: (NSMapTable *)identifiers
{
  self = [super init];
  if (self != nil)
    {
      _keyValuePairs = [keyValuePairs copy];
      _excludedKeys = [excludedKeys copy];
      _explicitIdentifiers = [identifiers retain];
      _identifiers = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                                      NSObjectMapValueCallBacks, 0);
      _definitionsByIdentifier = [[NSMutableDictionary alloc] init];
    }
  return self;
}

- (void) dealloc
{
  [_keyValuePairs release];
  [_excludedKeys release];
  [_explicitIdentifiers release];
  [_definitionsByIdentifier release];
  NSFreeMapTable(_identifiers);
  [super dealloc];
}

- (NSDictionary *) inferredPairsDeclaredByClass: (Class)objectClass
{
  NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
  Method *methods;
  unsigned int count = 0;
  unsigned int index;

  methods = class_copyMethodList(objectClass, &count);
  for (index = 0; index < count; index++)
    {
      SEL selector = method_getName(methods[index]);
      const char *selectorName = sel_getName(selector);
      size_t length = strlen(selectorName);

      if (length > 4
          && strncmp(selectorName, "set", 3) == 0
          && selectorName[length - 1] == ':'
          && strchr(selectorName, ':') == selectorName + length - 1
          && method_getNumberOfArguments(methods[index]) == 3)
        {
          NSString *stem = [NSString stringWithUTF8String: selectorName + 3];
          NSString *first;
          NSString *key;
          SEL getter;

          stem = [stem substringToIndex: [stem length] - 1];
          if ([stem length] > 1
              && [[NSCharacterSet uppercaseLetterCharacterSet]
                   characterIsMember: [stem characterAtIndex: 0]]
              && [[NSCharacterSet uppercaseLetterCharacterSet]
                   characterIsMember: [stem characterAtIndex: 1]])
            key = stem;
          else
            {
              first = [[stem substringToIndex: 1] lowercaseString];
              key = [first stringByAppendingString: [stem substringFromIndex: 1]];
            }
          getter = NSSelectorFromString(key);
          if (![objectClass instancesRespondToSelector: getter])
            getter = NSSelectorFromString([@"is" stringByAppendingString: stem]);
          if ([objectClass instancesRespondToSelector: getter])
            [pairs setObject: key forKey: key];
        }
    }
  free(methods);
  return pairs;
}

- (NSDictionary *) keyValuePairsForObject: (id)object
{
  NSMutableArray *classes = [NSMutableArray array];
  NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
  NSMutableSet *explicitKeys = [NSMutableSet set];
  NSMutableSet *excluded = [NSMutableSet set];
  Class currentClass = [object class];
  NSEnumerator *enumerator;

  while (currentClass != Nil && currentClass != [NSObject class])
    {
      [classes insertObject: currentClass atIndex: 0];
      currentClass = [currentClass superclass];
    }

  enumerator = [classes objectEnumerator];
  while ((currentClass = [enumerator nextObject]) != Nil)
    {
      NSString *className = NSStringFromClass(currentClass);
      NSDictionary *explicitPairs = [_keyValuePairs objectForKey: className];
      NSArray *classExclusions = [_excludedKeys objectForKey: className];

      if (classExclusions != nil)
        [excluded addObjectsFromArray: classExclusions];
      if (explicitPairs != nil)
        {
          [pairs addEntriesFromDictionary: explicitPairs];
          [explicitKeys addObjectsFromArray: [explicitPairs allKeys]];
        }
      else
        [pairs addEntriesFromDictionary:
          [self inferredPairsDeclaredByClass: currentClass]];
    }

  {
    NSEnumerator *keys = [[[[pairs allKeys] copy] autorelease] objectEnumerator];
    NSString *key;
    while ((key = [keys nextObject]) != nil)
      if (GSNixIsBuiltInTransientKey(key) && ![explicitKeys containsObject: key])
        [pairs removeObjectForKey: key];
  }
  [pairs removeObjectsForKeys: [excluded allObjects]];
  return pairs;
}

- (NSString *) newIdentifierForObject: (id)object
{
  NSString *identifier = _explicitIdentifiers != NULL
    ? NSMapGet(_explicitIdentifiers, object) : nil;

  if (identifier == nil)
    identifier = [GSNixSerialization identifierForObject: object];
  if (identifier == nil)
    {
      identifier = [NSString stringWithFormat: @"nix-%@",
        [[[NSUUID UUID] UUIDString] lowercaseString]];
    }
  if (![identifier isKindOfClass: [NSString class]]
      || [identifier length] == 0
      || [identifier isEqualToString: @"owner"]
      || [identifier isEqualToString: @"application"])
    [NSException raise: NSInvalidArgumentException
                format: @"Invalid NIX object identifier '%@'", identifier];
  if ([_definitionsByIdentifier objectForKey: identifier] != nil)
    [NSException raise: NSInvalidArgumentException
                format: @"Duplicate NIX object identifier '%@'", identifier];

  [GSNixSerialization setIdentifier: identifier forObject: object];
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
                  format: @"NIX cannot encode NSValue with type '%s'", type];
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
                format: @"NIX does not support NSNull property values"];
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
                        format: @"NIX cannot encode nil in an array"];
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
                        format: @"NIX dictionary keys must be strings"];
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
    [_definitionsByIdentifier setObject: definition forKey: identifier];
    properties = [NSMutableDictionary dictionary];
    /* Register before descending so cycles become references. */
    [definition setObject: properties forKey: @"properties"];

    {
      NSDictionary *pairs = [self keyValuePairsForObject: value];
      enumerator = [[[pairs allKeys]
        sortedArrayUsingSelector: @selector(compare:)] objectEnumerator];
      while ((key = [enumerator nextObject]) != nil)
        {
          NSString *kvcKey = [pairs objectForKey: key];
          id encoded;

          if (![key isKindOfClass: [NSString class]]
              || ![kvcKey isKindOfClass: [NSString class]])
            [NSException raise: NSInvalidArgumentException
                        format: @"NIX key/value mappings must contain strings"];
          encoded = [self encodedValue: [value valueForKey: kvcKey]];
          if (encoded != nil)
            [properties setObject: encoded forKey: key];
        }
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
                format: @"NIX connection endpoint %@ is not in the object graph",
                        endpoint];
  return [NSDictionary dictionaryWithObject: identifier forKey: @"$ref"];
}

- (NSDictionary *) documentWithTopLevelObjects: (NSArray *)topLevelObjects
                                      connections: (NSArray *)connections
{
  NSMutableArray *objects = [NSMutableArray array];
  NSMutableArray *topLevel = [NSMutableArray array];
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
      NSDictionary *source;
      NSDictionary *destination;
      NSString *anchorIdentifier;
      NSMutableDictionary *anchor;
      NSMutableArray *objectConnections;
      NSDictionary *encodedConnection;

      if ((!([kind isEqualToString: @"outlet"]
             || [kind isEqualToString: @"action"])) || label == nil)
        [NSException raise: NSInvalidArgumentException
                    format: @"Invalid NIX connection %@", object];
      source = [self referenceForEndpoint: [object objectForKey: @"source"]];
      destination = [self referenceForEndpoint: [object objectForKey: @"destination"]];
      encodedConnection = [NSDictionary dictionaryWithObjectsAndKeys:
        kind, @"kind",
        source, @"source", destination, @"destination",
        label, @"label", nil];

      anchorIdentifier = [source objectForKey: @"$ref"];
      anchor = [_definitionsByIdentifier objectForKey: anchorIdentifier];
      if (anchor == nil)
        {
          anchorIdentifier = [destination objectForKey: @"$ref"];
          anchor = [_definitionsByIdentifier objectForKey: anchorIdentifier];
        }
      if (anchor == nil)
        [NSException raise: NSInvalidArgumentException
                    format: @"NIX connection %@ has no archivable object endpoint",
                            object];

      objectConnections = [anchor objectForKey: @"connections"];
      if (objectConnections == nil)
        {
          objectConnections = [NSMutableArray array];
          [anchor setObject: objectConnections forKey: @"connections"];
        }
      [objectConnections addObject: encodedConnection];
    }

  enumerator = [_definitionsByIdentifier objectEnumerator];
  while ((object = [enumerator nextObject]) != nil)
    [[object objectForKey: @"connections"]
      sortUsingFunction: GSNixCompareConnections context: NULL];

  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"NIX", @"format",
    [NSNumber numberWithInteger: 1], @"version",
    objects, @"objects",
    topLevel, @"topLevelObjects", nil];
}

@end

@implementation GSNixSerialization

+ (NSString *) identifierForObject: (id)object
{
  return objc_getAssociatedObject(object, &GSNixIdentifierAssociationKey);
}

+ (void) setIdentifier: (NSString *)identifier forObject: (id)object
{
  if (object != nil)
    objc_setAssociatedObject(object, &GSNixIdentifierAssociationKey, identifier,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                       keyValuePairs: (NSDictionary *)keyValuePairs
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription
{
  return [self dataWithTopLevelObjects: topLevelObjects
                        keyValuePairs: keyValuePairs
                         excludedKeys: nil
                          identifiers: nil
                           connections: connections
                      errorDescription: errorDescription];
}

+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                       keyValuePairs: (NSDictionary *)keyValuePairs
                        excludedKeys: (NSDictionary *)excludedKeys
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription
{
  return [self dataWithTopLevelObjects: topLevelObjects
                        keyValuePairs: keyValuePairs
                         excludedKeys: excludedKeys
                          identifiers: nil
                           connections: connections
                      errorDescription: errorDescription];
}

+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                       keyValuePairs: (NSDictionary *)keyValuePairs
                        excludedKeys: (NSDictionary *)excludedKeys
                         identifiers: (NSMapTable *)identifiers
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription
{
  NSData *data = nil;

  if (errorDescription != NULL)
    *errorDescription = nil;
  NS_DURING
    {
      GSNixEncoder *encoder = [[[GSNixEncoder alloc]
        initWithKeyValuePairs: keyValuePairs
                excludedKeys: excludedKeys
                 identifiers: identifiers] autorelease];
      NSDictionary *document = [encoder
        documentWithTopLevelObjects: topLevelObjects
                        connections: connections != nil ? connections : [NSArray array]];
      data = [[[[GSNixXMLWriter alloc] init] autorelease]
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

+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                        propertyKeys: (NSDictionary *)propertyKeys
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription
{
  NSMutableDictionary *pairsByClass = [NSMutableDictionary dictionary];
  NSEnumerator *classes = [propertyKeys keyEnumerator];
  NSString *className;

  while ((className = [classes nextObject]) != nil)
    {
      NSArray *keys = [propertyKeys objectForKey: className];
      NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
      NSEnumerator *enumerator = [keys objectEnumerator];
      NSString *key;
      while ((key = [enumerator nextObject]) != nil)
        [pairs setObject: key forKey: key];
      [pairsByClass setObject: pairs forKey: className];
    }
  return [self dataWithTopLevelObjects: topLevelObjects
                        keyValuePairs: pairsByClass
                           connections: connections
                      errorDescription: errorDescription];
}

@end
