/** <title>GSNixLoader</title>

   Loader for Native Interface XML (NIX) files.

   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.
*/

#import "config.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSNibConnector.h"
#import "AppKit/NSNibControlConnector.h"
#import "AppKit/NSNibOutletConnector.h"
#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GNUstepGUI/GSNibLoading.h"
#import "GNUstepGUI/GSNixSerialization.h"

@interface NSObject (GSNixAwaking)
- (void) awakeFromNib;
@end

/*
 * NIX deliberately uses only property-list types.  A dictionary containing
 * "$class" is an object definition; "$ref" refers to its id.  Definitions
 * may be nested, making the on-disk representation follow the view hierarchy,
 * while ids retain the graph semantics of a nib archive.
 */
@interface GSNixDecoder : NSObject
{
  NSDictionary *_document;
  NSDictionary *_context;
  NSZone *_zone;
  NSMutableDictionary *_objects;
  NSMutableArray *_definitions;
}
- (id) initWithDocument: (NSDictionary *)document
                context: (NSDictionary *)context
                   zone: (NSZone *)zone;
- (BOOL) decode;
@end

@implementation GSNixDecoder

- (id) initWithDocument: (NSDictionary *)document
                context: (NSDictionary *)context
                   zone: (NSZone *)zone
{
  self = [super init];
  if (self != nil)
    {
      _document = [document retain];
      _context = [context retain];
      _zone = zone;
      _objects = [[NSMutableDictionary alloc] init];
      _definitions = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  [_document release];
  [_context release];
  [_objects release];
  [_definitions release];
  [super dealloc];
}

- (void) collectDefinitions: (id)value
{
  if ([value isKindOfClass: [NSArray class]])
    {
      NSEnumerator *enumerator = [value objectEnumerator];
      id child;
      while ((child = [enumerator nextObject]) != nil)
        [self collectDefinitions: child];
    }
  else if ([value isKindOfClass: [NSDictionary class]])
    {
      NSString *className = [value objectForKey: @"$class"];
      if (className != nil)
        {
          NSString *identifier = [value objectForKey: @"$id"];
          NSString *superclassName = [value objectForKey: @"$superclass"];
          Class objectClass;
          id object;

          if (identifier == nil || [identifier length] == 0)
            [NSException raise: NSInvalidArgumentException
                        format: @"NIX object %@ has no $id", value];
          if ([_objects objectForKey: identifier] != nil)
            [NSException raise: NSInvalidArgumentException
                        format: @"Duplicate NIX object id '%@'", identifier];
          objectClass = NSClassFromString(className);
          if (objectClass == Nil)
            {
              if ([NSClassSwapper isInInterfaceBuilder] && superclassName != nil)
                objectClass = NSClassFromString(superclassName);
              if (objectClass == Nil)
                [NSException raise: NSInvalidArgumentException
                            format: @"Unknown NIX class '%@'", className];
            }

          object = [[objectClass allocWithZone: _zone] init];
          if (object == nil)
            [NSException raise: NSInvalidArgumentException
                        format: @"Could not initialize NIX object '%@' as %@",
                               identifier, className];
          [_objects setObject: object forKey: identifier];
          [GSNixSerialization setIdentifier: identifier forObject: object];
          [GSNixSerialization setIntendedClassName: className
                               designSuperclassName: superclassName
                                          forObject: object];
          [GSNixSerialization setPreservedConnections:
            [value objectForKey: @"connections"] forObject: object];
          [object release];
          [_definitions addObject: value];
        }

      {
        NSEnumerator *enumerator = [value objectEnumerator];
        id child;
        while ((child = [enumerator nextObject]) != nil)
          [self collectDefinitions: child];
      }
    }
}

- (id) objectForReference: (NSString *)identifier
{
  id object;

  if ([identifier isEqualToString: @"owner"])
    return [_context objectForKey: NSNibOwner];
  if ([identifier isEqualToString: @"application"])
    return NSApp;

  object = [_objects objectForKey: identifier];
  if (object == nil)
    [NSException raise: NSInvalidArgumentException
                format: @"Unknown NIX object reference '%@'", identifier];
  return object;
}

- (id) decodedValue: (id)value
{
  if ([value isKindOfClass: [NSArray class]])
    {
      NSMutableArray *result = [NSMutableArray arrayWithCapacity: [value count]];
      NSEnumerator *enumerator = [value objectEnumerator];
      id child;
      while ((child = [enumerator nextObject]) != nil)
        {
          id decoded = [self decodedValue: child];
          [result addObject: decoded != nil ? decoded : [NSNull null]];
        }
      return result;
    }
  if ([value isKindOfClass: [NSDictionary class]])
    {
      NSString *reference = [value objectForKey: @"$ref"];
      NSString *className = [value objectForKey: @"$class"];
      NSString *type = [value objectForKey: @"$type"];

      if (reference != nil)
        return [self objectForReference: reference];
      if (className != nil)
        return [self objectForReference: [value objectForKey: @"$id"]];
      if (type != nil)
        {
          NSString *string = [value objectForKey: @"$value"];
          if ([type isEqualToString: @"rect"])
            return [NSValue valueWithRect: NSRectFromString(string)];
          if ([type isEqualToString: @"point"])
            return [NSValue valueWithPoint: NSPointFromString(string)];
          if ([type isEqualToString: @"size"])
            return [NSValue valueWithSize: NSSizeFromString(string)];
          if ([type isEqualToString: @"range"])
            return [NSValue valueWithRange: NSRangeFromString(string)];
          if ([type isEqualToString: @"selector"])
            {
              SEL selector = NSSelectorFromString(string);
              return [NSValue value: &selector withObjCType: @encode(SEL)];
            }
          [NSException raise: NSInvalidArgumentException
                      format: @"Unknown NIX value type '%@'", type];
        }

      {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        NSEnumerator *enumerator = [value keyEnumerator];
        NSString *key;
        while ((key = [enumerator nextObject]) != nil)
          {
            id decoded = [self decodedValue: [value objectForKey: key]];
            [result setObject: decoded != nil ? decoded : [NSNull null]
                       forKey: key];
          }
        return result;
      }
    }
  return value;
}

- (void) configureObjects
{
  NSEnumerator *enumerator = [_definitions objectEnumerator];
  NSDictionary *definition;

  while ((definition = [enumerator nextObject]) != nil)
    {
      id object = [_objects objectForKey: [definition objectForKey: @"$id"]];
      NSDictionary *properties = [definition objectForKey: @"properties"];
      NSEnumerator *keys = [properties keyEnumerator];
      NSString *key;

      if ([NSClassSwapper isInInterfaceBuilder]
          && ![NSStringFromClass([object class])
                isEqualToString: [definition objectForKey: @"$class"]])
        [GSNixSerialization setPreservedProperties: properties forObject: object];

      while ((key = [keys nextObject]) != nil)
        {
          NS_DURING
            {
              [object setValue: [self decodedValue: [properties objectForKey: key]]
                       forKey: key];
            }
          NS_HANDLER
            {
              if (![NSClassSwapper isInInterfaceBuilder])
                [localException raise];
            }
          NS_ENDHANDLER
        }
    }
}

- (void) establishConnectionsInArray: (NSArray *)connections
{
  NSEnumerator *enumerator = [connections objectEnumerator];
  NSDictionary *connection;

  while ((connection = [enumerator nextObject]) != nil)
    {
      NSString *kind = [connection objectForKey: @"kind"];
      NSNibConnector *connector;

      if ([kind isEqualToString: @"outlet"])
        connector = [[NSNibOutletConnector alloc] init];
      else if ([kind isEqualToString: @"action"])
        connector = [[NSNibControlConnector alloc] init];
      else
        [NSException raise: NSInvalidArgumentException
                    format: @"Unknown NIX connection kind '%@'", kind];

      [connector setSource: [self decodedValue: [connection objectForKey: @"source"]]];
      [connector setDestination: [self decodedValue: [connection objectForKey: @"destination"]]];
      [connector setLabel: [connection objectForKey: @"label"]];
      [connector establishConnection];
      [connector release];
    }
}

- (void) establishConnections
{
  NSEnumerator *enumerator;
  NSDictionary *definition;

  if ([NSClassSwapper isInInterfaceBuilder])
    return;

  /* Accept version 1 files written before connections became object-local. */
  [self establishConnectionsInArray: [_document objectForKey: @"connections"]];

  enumerator = [_definitions objectEnumerator];
  while ((definition = [enumerator nextObject]) != nil)
    [self establishConnectionsInArray:
      [definition objectForKey: @"connections"]];
}

- (BOOL) decode
{
  NSArray *roots = [_document objectForKey: @"objects"];
  NSArray *topLevel = [_document objectForKey: @"topLevelObjects"];
  NSMutableArray *result = [_context objectForKey: NSNibTopLevelObjects];
  NSEnumerator *enumerator;
  id value;

  [self collectDefinitions: roots];
  [self configureObjects];
  [self establishConnections];

  if (![NSClassSwapper isInInterfaceBuilder])
    {
      enumerator = [_definitions objectEnumerator];
      while ((value = [enumerator nextObject]) != nil)
        {
          id object = [_objects objectForKey: [value objectForKey: @"$id"]];
          if ([object respondsToSelector: @selector(awakeFromNib)])
            [object awakeFromNib];
        }
    }

  enumerator = [topLevel objectEnumerator];
  while ((value = [enumerator nextObject]) != nil)
    {
      id object = [self decodedValue: value];
      if (object != nil && object != [_context objectForKey: NSNibOwner])
        {
          [result addObject: object];
          /* Match nib ownership: the caller releases top-level objects. */
          [object retain];
        }
    }
  return YES;
}

@end

@interface GSNixLoader : GSModelLoader
@end

@implementation GSNixLoader

+ (BOOL) canReadData: (NSData *)data
{
  NSString *header;
  NSUInteger length = MIN((NSUInteger)4096, [data length]);

  if (length == 0)
    return NO;
  header = [[[NSString alloc] initWithBytes: [data bytes]
                                     length: length
                                   encoding: NSUTF8StringEncoding] autorelease];
  return ([header rangeOfString: @"<key>format</key>"].location != NSNotFound
          && [header rangeOfString: @"<string>NIX</string>"].location != NSNotFound);
}

+ (NSString *) type
{
  return @"nix";
}

+ (float) priority
{
  return 5.0;
}

- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone
{
  NSPropertyListFormat format;
  NSString *error = nil;
  id document;
  BOOL loaded = NO;

  NS_DURING
    {
      document = [NSPropertyListSerialization propertyListFromData: data
                                                  mutabilityOption: NSPropertyListImmutable
                                                            format: &format
                                                  errorDescription: &error];
      if (![document isKindOfClass: [NSDictionary class]]
          || ![[document objectForKey: @"format"] isEqualToString: @"NIX"]
          || [[document objectForKey: @"version"] integerValue] != 1)
        [NSException raise: NSInvalidArgumentException
                    format: @"Invalid or unsupported NIX document"];
      if (![[document objectForKey: @"objects"] isKindOfClass: [NSArray class]]
          || ![[document objectForKey: @"topLevelObjects"] isKindOfClass: [NSArray class]])
        [NSException raise: NSInvalidArgumentException
                    format: @"NIX objects and topLevelObjects must be arrays"];

      loaded = [[[[GSNixDecoder alloc] initWithDocument: document
                                                context: context
                                                   zone: zone] autorelease] decode];
    }
  NS_HANDLER
    {
      NSLog(@"Exception occurred while loading NIX: %@", [localException reason]);
    }
  NS_ENDHANDLER

  [error release];
  return loaded;
}

@end
