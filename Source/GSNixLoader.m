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
#import <Foundation/NSCoder.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSFont.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSMenu.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSTextStorage.h"
#import "AppKit/NSNibConnector.h"
#import "AppKit/NSNibControlConnector.h"
#import "AppKit/NSNibOutletConnector.h"
#import "AppKit/NSWindow.h"
#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GNUstepGUI/GSNibLoading.h"
#import "GNUstepGUI/GSNixSerialization.h"

@interface NSObject (GSNixAwaking)
- (void) awakeFromNib;
@end

@interface NSObject (GSNixInterfaceBuilderSubstitution)
+ (id) allocSubstitute;
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
  NSMutableDictionary *_definitionsByIdentifier;
  NSMutableSet *_initializingIdentifiers;
  NSMutableSet *_initializedIdentifiers;
  BOOL _isInterfaceBuilder;
}
- (id) initWithDocument: (NSDictionary *)document
                context: (NSDictionary *)context
                   zone: (NSZone *)zone;
- (BOOL) decode;
- (id) decodedValue: (id)value;
- (void) initializeDefinition: (NSDictionary *)definition;
@end

@interface GSNixKeyedDecodingCoder : NSCoder
{
  GSNixDecoder *_decoder;
  NSDictionary *_properties;
  NSDictionary *_classVersions;
  NSZone *_zone;
}
- (id) initWithDecoder: (GSNixDecoder *)decoder
             properties: (NSDictionary *)properties
         classVersions: (NSDictionary *)classVersions
                   zone: (NSZone *)zone;
@end

@implementation GSNixKeyedDecodingCoder

- (id) initWithDecoder: (GSNixDecoder *)decoder
             properties: (NSDictionary *)properties
         classVersions: (NSDictionary *)classVersions
                   zone: (NSZone *)zone
{
  self = [super init];
  if (self != nil)
    {
      _decoder = decoder;
      _properties = [properties retain];
      _classVersions = [classVersions retain];
      _zone = zone;
    }
  return self;
}

- (void) dealloc
{
  [_properties release];
  [_classVersions release];
  [super dealloc];
}

- (BOOL) allowsKeyedCoding { return YES; }
- (BOOL) requiresSecureCoding { return NO; }
- (NSZone *) objectZone { return _zone; }
- (BOOL) containsValueForKey: (NSString *)key
{
  return [_properties objectForKey: key] != nil;
}
- (id) decodeObjectForKey: (NSString *)key
{
  id value = [_decoder decodedValue: [_properties objectForKey: key]];

  /* Early keyed NIX output flattened NSTextStorage through its
   * NSAttributedString superclass.  Restore the text-system object expected
   * by NSLayoutManager and NSTextView when reading those files. */
  if ([key isEqualToString: @"NSTextStorage"]
      && [value isKindOfClass: [NSAttributedString class]]
      && ![value isKindOfClass: [NSTextStorage class]])
    value = [[[NSTextStorage alloc] initWithAttributedString: value] autorelease];
  return value;
}
- (id) decodeObjectOfClass: (Class)class forKey: (NSString *)key
{
  id value = [self decodeObjectForKey: key];
  return value == nil || [value isKindOfClass: class] ? value : nil;
}
- (id) decodeObjectOfClasses: (NSSet *)classes forKey: (NSString *)key
{
  id value = [self decodeObjectForKey: key];
  NSEnumerator *enumerator = [classes objectEnumerator];
  Class class;
  while ((class = [enumerator nextObject]) != Nil)
    if ([value isKindOfClass: class])
      return value;
  return nil;
}
- (BOOL) decodeBoolForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] boolValue];
}
- (int) decodeIntForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] intValue];
}
- (int32_t) decodeInt32ForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] intValue];
}
- (int64_t) decodeInt64ForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] longLongValue];
}
- (NSInteger) decodeIntegerForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] integerValue];
}
- (float) decodeFloatForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] floatValue];
}
- (double) decodeDoubleForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] doubleValue];
}
- (const uint8_t *) decodeBytesForKey: (NSString *)key
                        returnedLength: (NSUInteger *)length
{
  NSData *data = [self decodeObjectForKey: key];
  if (length != NULL)
    *length = [data length];
  return [data bytes];
}
- (NSPoint) decodePointForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] pointValue];
}
- (NSSize) decodeSizeForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] sizeValue];
}
- (NSRect) decodeRectForKey: (NSString *)key
{
  return [[self decodeObjectForKey: key] rectValue];
}
- (NSInteger) versionForClassName: (NSString *)className
{
  NSNumber *version = [_classVersions objectForKey: className];
  return version != nil ? [version integerValue] : 0;
}

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
      _definitionsByIdentifier = [[NSMutableDictionary alloc] init];
      _initializingIdentifiers = [[NSMutableSet alloc] init];
      _initializedIdentifiers = [[NSMutableSet alloc] init];
      _isInterfaceBuilder = ([context objectForKey: GSNixClassSubstitutions] != nil
        || [NSClassSwapper isInInterfaceBuilder]);
    }
  return self;
}

- (void) dealloc
{
  [_document release];
  [_context release];
  [_objects release];
  [_definitions release];
  [_definitionsByIdentifier release];
  [_initializingIdentifiers release];
  [_initializedIdentifiers release];
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
          NSString *codingClassName = [value objectForKey: @"$codingClass"];
          NSString *allocationClassName = codingClassName != nil
            ? codingClassName : className;
          BOOL isKeyed = [[value objectForKey: @"$coding"] isEqual: @"keyed"];
          NSDictionary *properties = [value objectForKey: @"properties"];
          NSDictionary *substitutions =
            [_context objectForKey: GSNixClassSubstitutions];
          NSString *substituteName;
          Class objectClass;
          id object;

          /* NIX writers predating the replacement-object fix could attach
           * NSButtonImageSource metadata to the shared NSImage returned by
           * -initWithCoder:, then save that image's keyed fields under the
           * wrong class name.  Decode those existing files as the NSImage
           * payload they actually contain. */
          if ([className isEqualToString: @"NSButtonImageSource"]
              && [properties objectForKey: @"NSImageName"] == nil
              && ([properties objectForKey: @"NSName"] != nil
                  || [[value objectForKey: @"$classVersions"]
                       objectForKey: @"NSImage"] != nil))
            allocationClassName = @"NSImage";

          /* Resolve the Interface Builder substitute only after legacy
           * payload normalization has selected the effective coding class. */
          substituteName = [substitutions objectForKey: allocationClassName];

          if (identifier == nil || [identifier length] == 0)
            [NSException raise: NSInvalidArgumentException
                        format: @"NIX object %@ has no $id", value];
          if ([_objects objectForKey: identifier] != nil)
            [NSException raise: NSInvalidArgumentException
                        format: @"Duplicate NIX object id '%@'", identifier];
          objectClass = substituteName != nil
            ? NSClassFromString(substituteName)
            : NSClassFromString(allocationClassName);
          if (objectClass == Nil)
            {
              if (codingClassName == nil
                  && _isInterfaceBuilder && superclassName != nil)
                {
                  substituteName = [substitutions objectForKey: superclassName];
                  objectClass = NSClassFromString(substituteName != nil
                    ? substituteName : superclassName);
                }
              if (objectClass == Nil)
                [NSException raise: NSInvalidArgumentException
                            format: @"Unknown NIX class '%@'", className];
            }

          /* Keyed objects must receive initWithCoder: after every placeholder
           * has been registered, so references and cycles can resolve.
           * Existing version-1 objects retain their legacy init-plus-KVC path. */
          if (isKeyed)
            {
              if (_isInterfaceBuilder
                  && [objectClass respondsToSelector: @selector(allocSubstitute)])
                object = [objectClass allocSubstitute];
              else
                object = [objectClass allocWithZone: _zone];
            }
          /* Early NIX writers emitted NSFont as an empty object definition.
           * NSFont is a factory class and rejects -init. */
          else if ([className isEqualToString: @"NSFont"])
            object = [[NSFont systemFontOfSize: [NSFont systemFontSize]] retain];
          else if ([className isEqualToString: @"NSAttributedString"]
                   || [className isEqualToString: @"GSAttributedString"])
            object = [[NSAttributedString alloc] initWithString: @""];
          else if (_isInterfaceBuilder
              && [objectClass respondsToSelector: @selector(allocSubstitute)])
            object = [[objectClass allocSubstitute] init];
          else
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
          [_definitionsByIdentifier setObject: value forKey: identifier];
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
  if ([identifier isEqualToString: @"firstResponder"])
    return nil;

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
          if ([type isEqualToString: @"color"])
            {
              NSString *catalog = [value objectForKey: @"$catalog"];
              NSString *name = [value objectForKey: @"$name"];
              NSArray *components = [value objectForKey: @"$components"];
              if (catalog != nil && name != nil)
                return [NSColor colorWithCatalogName: catalog colorName: name];
              if ([components count] == 4)
                return [NSColor colorWithCalibratedRed:
                  [[components objectAtIndex: 0] doubleValue]
                  green: [[components objectAtIndex: 1] doubleValue]
                  blue: [[components objectAtIndex: 2] doubleValue]
                  alpha: [[components objectAtIndex: 3] doubleValue]];
              [NSException raise: NSInvalidArgumentException
                          format: @"Invalid NIX color value %@", value];
            }
          if ([type isEqualToString: @"font"])
            {
              NSString *name = [value objectForKey: @"$name"];
              NSNumber *size = [value objectForKey: @"$size"];
              NSFont *font = nil;
              if (name != nil && size != nil)
                font = [NSFont fontWithName: name size: [size doubleValue]];
              if (font == nil)
                [NSException raise: NSInvalidArgumentException
                            format: @"Invalid NIX font value %@", value];
              return font;
            }
          if ([type isEqualToString: @"attributedString"])
            {
              NSString *plainString = [value objectForKey: @"$string"];
              NSArray *runs = [value objectForKey: @"$runs"];
              NSMutableAttributedString *result;
              NSEnumerator *enumerator;
              NSDictionary *run;
              if (plainString == nil || runs == nil)
                [NSException raise: NSInvalidArgumentException
                            format: @"Invalid NIX attributed string %@", value];
              result = [[[NSMutableAttributedString alloc]
                initWithString: plainString] autorelease];
              enumerator = [runs objectEnumerator];
              while ((run = [enumerator nextObject]) != nil)
                {
                  NSRange range = NSMakeRange(
                    [[run objectForKey: @"location"] unsignedIntegerValue],
                    [[run objectForKey: @"length"] unsignedIntegerValue]);
                  NSDictionary *attributes = [self decodedValue:
                    [run objectForKey: @"attributes"]];
                  if (NSMaxRange(range) > [result length])
                    [NSException raise: NSInvalidArgumentException
                                format: @"Invalid NIX attributed string run %@", run];
                  [result setAttributes: attributes range: range];
                }
              return result;
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

- (void) initializeReferencesInValue: (id)value
{
  if ([value isKindOfClass: [NSArray class]])
    {
      NSEnumerator *enumerator = [value objectEnumerator];
      id child;
      while ((child = [enumerator nextObject]) != nil)
        [self initializeReferencesInValue: child];
    }
  else if ([value isKindOfClass: [NSDictionary class]])
    {
      NSString *identifier = [value objectForKey: @"$ref"];
      if (identifier == nil && [value objectForKey: @"$class"] != nil)
        identifier = [value objectForKey: @"$id"];
      if (identifier != nil)
        {
          NSDictionary *definition =
            [_definitionsByIdentifier objectForKey: identifier];
          if (definition != nil)
            [self initializeDefinition: definition];
        }
      else
        {
          NSEnumerator *enumerator = [value objectEnumerator];
          id child;
          while ((child = [enumerator nextObject]) != nil)
            [self initializeReferencesInValue: child];
        }
    }
}

- (void) initializeDefinition: (NSDictionary *)definition
{
  NSString *identifier = [definition objectForKey: @"$id"];
  id object;
  id initialized;
  GSNixKeyedDecodingCoder *coder;

  if (![[definition objectForKey: @"$coding"] isEqual: @"keyed"]
      || [_initializedIdentifiers containsObject: identifier])
    return;
  /* A reference back to an object currently being initialized is a genuine
   * archive cycle.  Its registered placeholder is the only possible value
   * until the outer initializer completes. */
  if ([_initializingIdentifiers containsObject: identifier])
    return;

  [_initializingIdentifiers addObject: identifier];
  [self initializeReferencesInValue: [definition objectForKey: @"properties"]];

  object = [_objects objectForKey: identifier];
  coder = [[GSNixKeyedDecodingCoder alloc]
    initWithDecoder: self
         properties: [definition objectForKey: @"properties"]
     classVersions: [definition objectForKey: @"$classVersions"]
               zone: _zone];
  if ([[definition objectForKey: @"$class"]
        isEqualToString: @"NSButtonImageSource"]
      && [[definition objectForKey: @"properties"]
           objectForKey: @"NSImageName"] == nil
      && [[definition objectForKey: @"properties"]
           objectForKey: @"NSName"] == nil
      && [[[definition objectForKey: @"$classVersions"]
            objectForKey: @"NSImage"] integerValue] != 0)
    {
      /* Some already-written hybrid entries lost even the shared image name.
       * No pixels can be recovered, but a valid empty NSImage preserves graph
       * identity and lets the owning cell apply its remaining keyed state. */
      initialized = [[NSImage alloc] initWithSize: NSMakeSize(1.0, 1.0)];
    }
  else
    {
      [object retain];
      initialized = [object initWithCoder: coder];
    }
  [coder release];
  if (initialized == nil)
    [NSException raise: NSInvalidArgumentException
                format: @"Could not decode keyed NIX object '%@' (%@)",
                       identifier, [definition objectForKey: @"$class"]];
  if ([initialized respondsToSelector: @selector(nibInstantiate)])
    initialized = [initialized nibInstantiate];
  if (initialized != object)
    {
      NSString *declaredClass = [definition objectForKey: @"$class"];
      NSString *designSuperclass = [definition objectForKey: @"$superclass"];
      if (designSuperclass != nil
          || [NSStringFromClass([initialized class])
               isEqualToString: declaredClass])
        {
          [GSNixSerialization setIdentifier: identifier forObject: initialized];
          [GSNixSerialization setIntendedClassName: declaredClass
                             designSuperclassName: designSuperclass
                                        forObject: initialized];
        }
      [_objects setObject: initialized forKey: identifier];
    }
  [initialized release];
  [_initializingIdentifiers removeObject: identifier];
  [_initializedIdentifiers addObject: identifier];
}

- (void) configureObjects
{
  NSEnumerator *enumerator;
  NSDictionary *definition;

  /* Initialize dependencies before their owners.  Definition nesting alone
   * is insufficient because keyed archives freely share and forward-reference
   * objects; cycles continue to resolve through registered placeholders. */
  enumerator = [_definitions objectEnumerator];
  while ((definition = [enumerator nextObject]) != nil)
    [self initializeDefinition: definition];

  enumerator = [_definitions objectEnumerator];
  while ((definition = [enumerator nextObject]) != nil)
    {
      id object = [_objects objectForKey: [definition objectForKey: @"$id"]];
      NSDictionary *properties = [definition objectForKey: @"properties"];
      NSEnumerator *keys = [properties keyEnumerator];
      NSString *key;
      id frameValue = nil;
      id visibilityValue = nil;
      id menuItems = nil;

      if ([[definition objectForKey: @"$coding"] isEqual: @"keyed"])
        continue;

      if (_isInterfaceBuilder
          && ![NSStringFromClass([object class])
                isEqualToString: [definition objectForKey: @"$class"]])
        [GSNixSerialization setPreservedProperties: properties forObject: object];

      /* A window must own its decoded content view before its final frame is
       * restored. Dictionary enumeration order is otherwise unspecified. */
      if ([object isKindOfClass: [NSWindow class]])
        {
          id contentDefinition = [properties objectForKey: @"contentView"];
          if (contentDefinition != nil)
            [object setValue: [self decodedValue: contentDefinition]
                     forKey: @"contentView"];
          frameValue = [properties objectForKey: @"frame"];
          visibilityValue = [properties objectForKey: @"isVisible"];
        }

      if ([object isKindOfClass: [NSMenu class]])
        menuItems = [properties objectForKey: @"items"];

      while ((key = [keys nextObject]) != nil)
        {
          if (([object isKindOfClass: [NSWindow class]]
               && ([key isEqualToString: @"contentView"]
                   || [key isEqualToString: @"frame"]
                   || [key isEqualToString: @"isVisible"]))
              || ([object isKindOfClass: [NSMenu class]]
                  && [key isEqualToString: @"items"]))
            continue;
          NS_DURING
            {
              id decoded = [self decodedValue: [properties objectForKey: key]];

              /* Early Gorm NIX output could write character-backed control
               * values as plist data.  Passing that NSData to setTitle: or
               * setStringValue: corrupts controls and later crashes menu
               * layout.  Limit this repair to Interface Builder loading. */
              if ([decoded isKindOfClass: [NSData class]]
                  && ([key isEqualToString: @"title"]
                      || [key isEqualToString: @"alternateTitle"]
                      || [key isEqualToString: @"stringValue"]
                      || [key isEqualToString: @"placeholderString"]
                      || [key isEqualToString: @"keyEquivalent"]
                      || [key isEqualToString: @"toolTip"]))
                decoded = [[[NSString alloc] initWithData: decoded
                  encoding: NSUTF8StringEncoding] autorelease];
              [object setValue: decoded forKey: key];
            }
          NS_HANDLER
            {
              if (!_isInterfaceBuilder)
                [localException raise];
            }
          NS_ENDHANDLER
        }

      /* Direct KVC assignment to NSMenu's _items ivar bypasses menu-item
       * ownership, sizing, notifications, and its menu representation. */
      if (menuItems != nil)
        {
          NSEnumerator *items = [[self decodedValue: menuItems] objectEnumerator];
          NSMenuItem *item;
          [(NSMenu *)object removeAllItems];
          while ((item = [items nextObject]) != nil)
            [(NSMenu *)object addItem: item];
        }

      if (frameValue != nil)
        [(NSWindow *)object setFrame: [[self decodedValue: frameValue] rectValue]
                             display: NO];
      if (visibilityValue != nil)
        [(NSWindow *)object setIsVisible:
          [[self decodedValue: visibilityValue] boolValue]];
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

  if (_isInterfaceBuilder)
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

  if (!_isInterfaceBuilder)
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
