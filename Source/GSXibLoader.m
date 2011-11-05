/* <title>GSXibLoader</title>

   <abstract>Xib (Cocoa XML) model loader</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.

   Written by: Fred Kiefer <FredKiefer@gmx.de>
   Created: March 2010

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSXMLParser.h>
#import	<GNUstepBase/GSMime.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSNibLoading.h"
#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GNUstepGUI/GSNibLoading.h"
#import "GNUstepGUI/GSXibLoading.h"

@interface NSApplication (NibCompatibility)
- (void) _setMainMenu: (NSMenu*)aMenu;
@end

@interface NSCustomObject (NibCompatibility)
- (void) setRealObject: (id)obj;
@end

@interface NSNibConnector (NibCompatibility)
- (id) nibInstantiate;
@end

@implementation FirstResponder

+ (id) allocWithZone: (NSZone*)zone
{
  return nil;
}

@end

@implementation IBClassDescriptionSource

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"majorKey"])
        {
          ASSIGN(majorKey, [coder decodeObjectForKey: @"majorKey"]);
        }
      if ([coder containsValueForKey: @"minorKey"])
        {
          ASSIGN(minorKey, [coder decodeObjectForKey: @"minorKey"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(majorKey);
  DESTROY(minorKey);
  [super dealloc];
}

@end

@implementation IBPartialClassDescription

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"className"])
        {
          ASSIGN(className, [coder decodeObjectForKey: @"className"]);
        }
      if ([coder containsValueForKey: @"superclassName"])
        {
          ASSIGN(superclassName, [coder decodeObjectForKey: @"superclassName"]);
        }
      if ([coder containsValueForKey: @"actions"])
        {
          ASSIGN(actions, [coder decodeObjectForKey: @"actions"]);
        }
      if ([coder containsValueForKey: @"outlets"])
        {
          ASSIGN(outlets, [coder decodeObjectForKey: @"outlets"]);
        }
      if ([coder containsValueForKey: @"sourceIdentifier"])
        {
          ASSIGN(sourceIdentifier, [coder decodeObjectForKey: @"sourceIdentifier"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(className);
  DESTROY(superclassName);
  DESTROY(actions);
  DESTROY(outlets);
  DESTROY(sourceIdentifier);
  [super dealloc];
}

@end

@implementation IBClassDescriber

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"referencedPartialClassDescriptions"])
        {
          ASSIGN(referencedPartialClassDescriptions, [coder decodeObjectForKey: @"referencedPartialClassDescriptions"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(referencedPartialClassDescriptions);
  [super dealloc];
}

@end

@implementation IBConnection

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"label"])
        {
          ASSIGN(label, [coder decodeObjectForKey: @"label"]);
        }
      if ([coder containsValueForKey: @"source"])
        {
          ASSIGN(source, [coder decodeObjectForKey: @"source"]);
        }
      if ([coder containsValueForKey: @"destination"])
        {
          ASSIGN(destination, [coder decodeObjectForKey: @"destination"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME
}

- (void) dealloc
{
  DESTROY(label);
  DESTROY(source);
  DESTROY(destination);
  [super dealloc];
}

- (NSString *) label
{
  return label;
}

- (id) source
{
  return source;
}

- (id) destination
{
  return destination;
}

- (NSNibConnector *) nibConnector
{
  NSString *tag = [self label];
  NSRange colonRange = [tag rangeOfString: @":"];
  unsigned int location = colonRange.location;
  NSNibConnector *result = nil;

  if(location == NSNotFound)
    {
      result = [[NSNibOutletConnector alloc] init];
    }
  else
    {
      result = [[NSNibControlConnector alloc] init];
    }

  [result setDestination: [self destination]];
  [result setSource: [self source]];
  [result setLabel: [self label]];
  
  return result;
}

- (id) nibInstantiate
{
  if ([source respondsToSelector: @selector(nibInstantiate)])
    {
      ASSIGN(source, [source nibInstantiate]);
    }
  if ([destination respondsToSelector: @selector(nibInstantiate)])
    {
      ASSIGN(destination, [destination nibInstantiate]);
    }

  return self;
}

- (void) establishConnection
{
}

@end

@implementation IBActionConnection

- (void) establishConnection
{
  SEL sel = NSSelectorFromString(label);
	      
  [destination setTarget: source];
  [destination setAction: sel];
}

@end

@implementation IBOutletConnection

- (void) establishConnection
{
  NS_DURING
    {
      if (source != nil)
	{
          NSString *selName;
          SEL sel; 	 
          
          selName = [NSString stringWithFormat: @"set%@%@:", 	 
                       [[label substringToIndex: 1] uppercaseString], 	 
                      [label substringFromIndex: 1]]; 	 
          sel = NSSelectorFromString(selName); 	 
          
          if (sel && [source respondsToSelector: sel]) 	 
            { 	 
              [source performSelector: sel withObject: destination]; 	 
            } 	 
          else 	 
            { 	 
              const char *nam = [label cString]; 	 
              const char *type; 	 
              unsigned int size; 	 
              int offset; 	 
              
              /* 	 
               * Use the GNUstep additional function to set the instance 	 
               * variable directly. 	 
               * FIXME - need some way to do this for libFoundation and 	 
               * Foundation based systems. 	 
               */ 	 
              if (GSObjCFindVariable(source, nam, &type, &size, &offset)) 	 
                { 	 
                  GSObjCSetVariable(source, offset, size, (void*)&destination);
                }
            } 	 
	}
    }
  NS_HANDLER
    {
      NSLog(@"Error while establishing connection %@: %@",self,[localException reason]);
    }
  NS_ENDHANDLER;
}

@end

@implementation IBBindingConnection

- (void) dealloc
{
  DESTROY(connector);
  [super dealloc];
}

- (id) initWithCoder: (NSCoder*)coder
{
  self = [super initWithCoder: coder];
  if (self == nil)
    return nil;

  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"connector"])
        {
          ASSIGN(connector, [coder decodeObjectForKey: @"connector"]);
        }
    }

  return self;
}

- (id) nibInstantiate
{
  [connector nibInstantiate];
  return [super nibInstantiate];
}

- (void) establishConnection
{
  [connector establishConnection];
}

@end

@implementation IBConnectionRecord

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"connection"])
        {
          ASSIGN(connection, [coder decodeObjectForKey: @"connection"]);
        }
      if ([coder containsValueForKey: @"connectionID"])
        {
          connectionID = [coder decodeIntForKey: @"connectionID"];
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(connection);
  [super dealloc];
}

- (IBConnection *) connection
{
  return connection;
}

- (id) nibInstantiate
{
  ASSIGN(connection, [connection nibInstantiate]);
  return self;
}

- (void) establishConnection
{
  [connection establishConnection];
}

@end

@implementation IBToolTipAttribute

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"name"])
        {
          name = [coder decodeObjectForKey: @"name"];
        }
      if ([coder containsValueForKey: @"object"])
        {
          ASSIGN(object, [coder decodeObjectForKey: @"object"]);
        }
      if ([coder containsValueForKey: @"toolTip"])
        {
          ASSIGN(toolTip, [coder decodeObjectForKey: @"toolTip"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(name);
  DESTROY(object);
  DESTROY(toolTip);
  [super dealloc];
}

@end

@implementation IBInitialTabViewItemAttribute

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"name"])
        {
          name = [coder decodeObjectForKey: @"name"];
        }
      if ([coder containsValueForKey: @"object"])
        {
          ASSIGN(object, [coder decodeObjectForKey: @"object"]);
        }
      if ([coder containsValueForKey: @"initialTabViewItem"])
        {
          ASSIGN(initialTabViewItem, [coder decodeObjectForKey: @"initialTabViewItem"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(name);
  DESTROY(object);
  DESTROY(initialTabViewItem);
  [super dealloc];
}

@end

@implementation IBObjectRecord

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"objectID"])
        {
          objectID = [coder decodeIntForKey: @"objectID"];
        }
      if ([coder containsValueForKey: @"object"])
        {
          ASSIGN(object, [coder decodeObjectForKey: @"object"]);
        }
      if ([coder containsValueForKey: @"children"])
        {
          ASSIGN(children, [coder decodeObjectForKey: @"children"]);
        }
      if ([coder containsValueForKey: @"parent"])
        {
          ASSIGN(parent, [coder decodeObjectForKey: @"parent"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(object);
  DESTROY(children);
  DESTROY(parent);
  [super dealloc];
}

- (id) object
{
  return object;
}

- (id) parent
{
  return parent;
}

- (NSInteger) objectID
{
  return objectID;
}

@end

@implementation IBMutableOrderedSet
- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"orderedObjects"])
        {
          ASSIGN(orderedObjects, [coder decodeObjectForKey: @"orderedObjects"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(orderedObjects);
  [super dealloc];
}

- (NSArray *)orderedObjects
{
  return orderedObjects;
}

- (id) objectWithObjectID: (NSInteger)objID
{
  NSEnumerator *en;
  IBObjectRecord *obj;

  en = [orderedObjects objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      if ([obj objectID] == objID)
        {
          return [obj object];
        }
    }
  return nil;
}

@end

@implementation IBObjectContainer

- (id) initWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"connectionRecords"])
        {
          ASSIGN(connectionRecords, [coder decodeObjectForKey: @"connectionRecords"]);
        }
      if ([coder containsValueForKey: @"objectRecords"])
        {
          ASSIGN(objectRecords, [coder decodeObjectForKey: @"objectRecords"]);
        }
      if ([coder containsValueForKey: @"flattenedProperties"])
        {
          ASSIGN(flattenedProperties, [coder decodeObjectForKey: @"flattenedProperties"]);
        }
      // We could load more data here, but we currently don't need it.
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
                   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
                   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME
}

- (void) dealloc
{
  DESTROY(connectionRecords);
  DESTROY(objectRecords);
  DESTROY(flattenedProperties);
  DESTROY(unlocalizedProperties);
  DESTROY(activeLocalization);
  DESTROY(localizations);
  DESTROY(sourceID);
  [super dealloc];
}

- (NSEnumerator *) connectionRecordEnumerator
{
  return [connectionRecords objectEnumerator];
}

- (NSEnumerator *) objectRecordEnumerator
{
  return [[objectRecords orderedObjects] objectEnumerator];
}

- (id) nibInstantiate
{
  NSEnumerator *en;
  id obj;
  NSString *key;

  en = [connectionRecords objectEnumerator];
  // iterate over connections, instantiate, and then establish them.
  while ((obj = [en nextObject]) != nil)
    {
      [obj nibInstantiate];
      [obj establishConnection];
    }

  // awaken all objects.
  en = [[objectRecords orderedObjects] objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      obj = [obj object];
      if ([obj respondsToSelector: @selector(awakeFromNib)])
        {
          [obj awakeFromNib];
        }
    }

  // Activate windows
  en = [flattenedProperties keyEnumerator];
  while ((key = [en nextObject]) != nil)
    {
      if ([key hasSuffix: @"visibleAtLaunch"])
        {
          id value = [flattenedProperties objectForKey: key];
          
          if ([value boolValue] == YES)
            {
              NSInteger objID = [key integerValue];

              obj = [objectRecords objectWithObjectID: objID];
              if ([obj respondsToSelector: @selector(nibInstantiate)])
                {
                  obj = [obj nibInstantiate];
                }

              if ([obj isKindOfClass: [NSWindow class]])
                {
                  // bring visible windows to front...
                  [(NSWindow *)obj orderFront: self];
                }
            }
        }
    }

  return self;
}

@end

@interface GSXibLoader: GSModelLoader
{
}
@end

@implementation GSXibLoader

+ (NSString *)type
{
  return @"xib";
}

+ (float) priority
{
  return 4.0;
}

- (void) awake: (NSArray *)rootObjects 
   inContainer: (IBObjectContainer *)objects 
   withContext: (NSDictionary *)context
{
  NSEnumerator *en;
  id obj;
  NSMutableArray *topLevelObjects = [context objectForKey: NSNibTopLevelObjects];
  id owner = [context objectForKey: NSNibOwner];

  // Use the owner as first root object
  [(NSCustomObject*)[rootObjects objectAtIndex: 0] setRealObject: owner];
  en = [rootObjects objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      if ([obj respondsToSelector: @selector(nibInstantiate)])
        {
          obj = [obj nibInstantiate];
        }

      if (obj != nil)
        {
          [topLevelObjects addObject: obj];
          // All top level objects must be released by the caller to avoid
          // leaking, unless they are going to be released by other nib
          // objects on behalf of the owner.
          RETAIN(obj);
        }

      if ([obj isKindOfClass: [NSMenu class]])
        {
          // add the menu...
          [NSApp _setMainMenu: obj];
        }
    }

  // Load connections and awaken objects
  [objects nibInstantiate];
}

- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
{
  BOOL loaded = NO;
  NSKeyedUnarchiver *unarchiver = nil;

  NS_DURING
    {
      if (data != nil)
	{
          unarchiver = [[GSXibKeyedUnarchiver alloc] initForReadingWithData: data];
	  if (unarchiver != nil)
	    {
              NSArray *rootObjects;
              IBObjectContainer *objects;

	      NSDebugLLog(@"XIB", @"Invoking unarchiver");
	      [unarchiver setObjectZone: zone];
              rootObjects = [unarchiver decodeObjectForKey: @"IBDocument.RootObjects"];
              objects = [unarchiver decodeObjectForKey: @"IBDocument.Objects"];
              NSDebugLLog(@"XIB", @"rootObjects %@", rootObjects);
              [self awake: rootObjects inContainer: objects withContext: context];
              loaded = YES;
              RELEASE(unarchiver);
	    }
	  else
	    {
	      NSLog(@"Could not instantiate Xib unarchiver.");
	    }
	}
      else
	{
	  NSLog(@"Data passed to Xib loading method is nil.");
	}
    }
  NS_HANDLER
    {
      NSLog(@"Exception occured while loading model: %@",[localException reason]);
      // TEST_RELEASE(unarchiver);
    }
  NS_ENDHANDLER

  if (loaded == NO)
    {
      NSLog(@"Failed to load Xib\n");
    }

  return loaded;
}

- (NSData *) dataForFile: (NSString *)fileName
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  BOOL isDir = NO;

  NSDebugLLog(@"XIB", @"Loading Xib `%@'...\n", fileName);
  if ([mgr fileExistsAtPath: fileName isDirectory: &isDir])
    {
      if (isDir == NO)
	{
	  return [NSData dataWithContentsOfFile: fileName];
        }
      else
        {
          NSLog(@"Xib file specified %@, is directory.", fileName);
        }
    }
  else
    {
      NSLog(@"Xib file specified %@, could not be found.", fileName);
    }
  return nil;
}

@end

@implementation GSXibElement

- (GSXibElement*) initWithType: (NSString*)typeName 
               andAttributes: (NSDictionary*)attribs
{
  ASSIGN(type, typeName);
  ASSIGN(attributes, attribs);
  elements = [[NSMutableDictionary alloc] init];
  values = [[NSMutableArray alloc] init];

  return self;
}

- (void) dealloc
{
  DESTROY(type);
  DESTROY(attributes);
  DESTROY(elements);
  DESTROY(values);
  DESTROY(value);
  [super dealloc];
}

- (NSString*) type
{
  return type;
}

- (NSString*) value
{
  return value;
}

- (NSDictionary*) elements
{
  return elements;
}

- (NSArray*) values
{
  return values;
}

- (void) addElement: (GSXibElement*)element
{
  [values addObject: element];
}

- (void) setElement: (GSXibElement*)element forKey: (NSString*)key
{
  [elements setObject: element forKey: key];
}

- (void) setValue: (NSString*)text
{
  ASSIGN(value, text);
}

- (NSString*) attributeForKey: (NSString*)key
{
  return [attributes objectForKey: key];
}

- (GSXibElement*) elementForKey: (NSString*)key
{
  return [elements objectForKey: key];
}

- (NSString*) description
{
  return [NSString stringWithFormat: 
                     @"GSXibElement <%@> attrs (%@) elements [%@] values [%@] %@", 
                   type, attributes, elements, values, value, nil];
}

@end

@implementation GSXibKeyedUnarchiver

- (id) initForReadingWithData: (NSData*)data
{
  NSXMLParser *theParser;

  objects = [[NSMutableDictionary alloc] init];
  stack = [[NSMutableArray alloc] init];
  decoded = [[NSMutableDictionary alloc] init];

  theParser = [[NSXMLParser alloc] initWithData: data];
  [theParser setDelegate: self];
      
  NS_DURING
    {
      // Parse the XML data
      [theParser parse];
    }
  NS_HANDLER
    {
      NSLog(@"Exception occured while parsing Xib: %@",[localException reason]);
      DESTROY(self);
    }
  NS_ENDHANDLER

  DESTROY(theParser);
    
  return self;
}

- (void) dealloc
{
  DESTROY(objects);
  DESTROY(stack);
  DESTROY(decoded);
  
  [super dealloc];
}

- (void) parser: (NSXMLParser *)parser
foundCharacters: (NSString *)string
{
  [currentElement setValue: string];
}

- (void) parser: (NSXMLParser *)parser
didStartElement: (NSString *)elementName
   namespaceURI: (NSString *)namespaceURI
  qualifiedName: (NSString *)qualifiedName
     attributes: (NSDictionary *)attributeDict
{
  GSXibElement *element = [[GSXibElement alloc] initWithType: elementName
                                           andAttributes: attributeDict];
  NSString *key = [attributeDict objectForKey: @"key"];
  NSString *ref = [attributeDict objectForKey: @"id"];
  
  if (key != nil)
    {
      [currentElement setElement: element forKey: key];
    }
  else
    {
      // For Arrays
      [currentElement addElement: element];
    }
  if (ref != nil)
    {
      [objects setObject: element forKey: ref];
    }

  if (![@"archive" isEqualToString: elementName] &&
      ![@"data" isEqualToString: elementName])
    {
      // only used for the root element
      // push
      [stack addObject: currentElement];
    }

  if (![@"archive" isEqualToString: elementName])
    {
      currentElement = element;
    }
}

- (void) parser: (NSXMLParser *)parser
  didEndElement: (NSString *)elementName
   namespaceURI: (NSString *)namespaceURI
  qualifiedName: (NSString *)qName
{
  if (![@"archive" isEqualToString: elementName] &&
      ![@"data" isEqualToString: elementName])
    {
      // pop
      currentElement = [stack lastObject];
      [stack removeLastObject];
    }
}

- (id) allocObjectForClassName: (NSString *)classname
{
  Class c = [self classForClassName: classname];
  id delegate = [self delegate];

  if (c == nil)
    {
      c = [[self class] classForClassName: classname];
      if (c == nil)
        {
          c = NSClassFromString(classname);
          if (c == nil)
            {
              c = [delegate unarchiver: self
                            cannotDecodeObjectOfClassName: classname
                       originalClasses: nil];
              if (c == nil)
                {
                  [NSException raise: NSInvalidUnarchiveOperationException
                              format: @"[%@ -%@]: no class for name '%@'",
                               NSStringFromClass([self class]),
                               NSStringFromSelector(_cmd),
                               classname];
                }
            }
        }
    }

  // Create instance.
  return [c allocWithZone: [self zone]];
 }

- (id) decodeObjectForXib: (GSXibElement*)element
             forClassName: (NSString *)classname
                   withID: (NSString *)objID
{
  GSXibElement *last;
  id o, r;
  id delegate = [self delegate];

  // Create instance.
  o = [self allocObjectForClassName: classname];
  // Make sure the object stays around, even when replaced.
  RETAIN(o);
  if (objID != nil)
    [decoded setObject: o forKey: objID];

  // push
  last = currentElement;
  currentElement = element;

  r = [o initWithCoder: self];

  // pop
  currentElement = last;
  
  if (r != o)
    {
      [delegate unarchiver: self
         willReplaceObject: o
                withObject: r];
      ASSIGN(o, r);
      if (objID != nil)
        [decoded setObject: o forKey: objID];
    }

  r = [o awakeAfterUsingCoder: self];
  if (r != o)
    {
      [delegate unarchiver: self
         willReplaceObject: o
                withObject: r];
      ASSIGN(o, r);
      if (objID != nil)
        [decoded setObject: o forKey: objID];
    }

  if (delegate != nil)
    {
      r = [delegate unarchiver: self didDecodeObject: o];
      if (r != o)
        {
          [delegate unarchiver: self
             willReplaceObject: o
                    withObject: r];
          ASSIGN(o, r);
          if (objID != nil)
            [decoded setObject: o forKey: objID];
        }
    }

  // Balance the retain above
  RELEASE(o);
  
  if (objID != nil)
    {
      NSDebugLLog(@"XIB", @"decoded object %@ for id %@", o, objID);
    }

  return AUTORELEASE(o);
}

/*
  This method is a copy of decodeObjectForXib:forClassName:withKey:
  The only difference being in the way we decode the object and the 
  missing context switch.
 */
- (id) decodeDictionaryForXib: (GSXibElement*)element
                 forClassName: (NSString *)classname
                       withID: (NSString *)objID
{
  id o, r;
  id delegate = [self delegate];

  // Create instance.
  o = [self allocObjectForClassName: classname];
  // Make sure the object stays around, even when replaced.
  RETAIN(o);
  if (objID != nil)
    [decoded setObject: o forKey: objID];

  r = [o initWithDictionary: [self _decodeDictionaryOfObjectsForElement: element]];
  if (r != o)
    {
      [delegate unarchiver: self
         willReplaceObject: o
                withObject: r];
      ASSIGN(o, r);
      if (objID != nil)
        [decoded setObject: o forKey: objID];
    }

  r = [o awakeAfterUsingCoder: self];
  if (r != o)
    {
      [delegate unarchiver: self
         willReplaceObject: o
                withObject: r];
      ASSIGN(o, r);
      if (objID != nil)
        [decoded setObject: o forKey: objID];
    }

  if (delegate != nil)
    {
      r = [delegate unarchiver: self didDecodeObject: o];
      if (r != o)
        {
          [delegate unarchiver: self
             willReplaceObject: o
                    withObject: r];
          ASSIGN(o, r);
          if (objID != nil)
            [decoded setObject: o forKey: objID];
        }
    }
  // Balance the retain above
  RELEASE(o);
  
  if (objID != nil)
    {
      NSDebugLLog(@"XIB", @"decoded object %@ for id %@", o, objID);
    }

  return AUTORELEASE(o);
}

- (id) objectForXib: (GSXibElement*)element
{
  NSString *elementName;
  NSString *objID;

  if (element == nil)
    return nil;

  NSDebugLLog(@"XIB", @"decoding element %@", element);
  objID = [element attributeForKey: @"id"];
  if (objID)
    {
      id new = [decoded objectForKey: objID];
      if (new != nil)
        {
          // The object was already decoded as a reference
          return new;
        }
    }

  elementName = [element type];
  if ([@"object" isEqualToString: elementName])
    {
      NSString *classname = [element attributeForKey: @"class"];
      return [self decodeObjectForXib: element
                         forClassName: classname
                               withID: objID];
    }
  else if ([@"string" isEqualToString: elementName])
    {
      NSString *type = [element attributeForKey: @"type"];
      id new = [element value];

      if ([type isEqualToString: @"base64-UTF8"])
        {
          NSData *d = [new dataUsingEncoding: NSASCIIStringEncoding];
          d = [GSMimeDocument decodeBase64: d];
          new = AUTORELEASE([[NSString alloc] initWithData: d 
                                                  encoding: NSUTF8StringEncoding]);
        }

      // empty strings are not nil!
      if (new == nil)
        new = @"";

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"int" isEqualToString: elementName])
    {
      id new = [NSNumber numberWithInt: [[element value] intValue]];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"double" isEqualToString: elementName])
    {
      id new = [NSNumber numberWithDouble: [[element value] doubleValue]];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"bool" isEqualToString: elementName])
    {
      id new = [NSNumber numberWithBool: [[element value] boolValue]];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"integer" isEqualToString: elementName])
    {
      NSString *value = [element attributeForKey: @"value"];
      id new = [NSNumber numberWithInteger: [value integerValue]];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"real" isEqualToString: elementName])
    {
      NSString *value = [element attributeForKey: @"value"];
      id new = [NSNumber numberWithFloat: [value floatValue]];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"boolean" isEqualToString: elementName])
    {
      NSString *value = [element attributeForKey: @"value"];
      id new = [NSNumber numberWithBool: [value boolValue]];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"reference" isEqualToString: elementName])
    {
      NSString *ref = [element attributeForKey: @"ref"];

      if (ref == nil)
        {
          return nil;
        }
      else
        {
          id new = [decoded objectForKey: ref];

          // FIXME: We need a marker for nil
          if (new == nil)
            {
              //NSLog(@"Decoding reference %@", ref);
              element = [objects objectForKey: ref];
              if (element != nil)
                {
                  // Decode the real object
                  new = [self objectForXib: element];
                }
            }

          return new;
        }
    }
  else if ([@"nil" isEqualToString: elementName])
    {
      return nil;
    }
  else if ([@"characters" isEqualToString: elementName])
    {
      id new = [element value];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"bytes" isEqualToString: elementName])
    {
      id new = [[element value] dataUsingEncoding: NSASCIIStringEncoding
                           allowLossyConversion: NO];
      new = [GSMimeDocument decodeBase64: new];

      if (objID != nil)
        [decoded setObject: new forKey: objID];
      
      return new;
    }
  else if ([@"array" isEqualToString: elementName])
    {
      NSString *classname = [element attributeForKey: @"class"];

      if (classname == nil)
        {
          classname = @"NSArray";
        }
      return [self decodeObjectForXib: element
                         forClassName: classname
                               withID: objID];
    }
  else if ([@"dictionary" isEqualToString: elementName])
    {
      NSString *classname = [element attributeForKey: @"class"];

      if (classname == nil)
        {
          classname = @"NSDictionary";
        }

      return [self decodeDictionaryForXib: element
                             forClassName: classname
                                   withID: objID];
    }
  else
    {
      NSLog(@"Unknown element type %@", elementName);
    }

  return nil;
}

- (id) _decodeArrayOfObjectsForKey: (NSString*)aKey
{
  // FIXME: This is wrong but the only way to keep the code for
  // [NSArray-initWithCoder:] working
  return [self _decodeArrayOfObjectsForElement: currentElement];
}

- (id) _decodeArrayOfObjectsForElement: (GSXibElement*)element
{
  NSArray *values = [element values];
  int max = [values count];
  id list[max];
  int i;

  for (i = 0; i < max; i++)
    {
      list[i] = [self objectForXib: [values objectAtIndex: i]];
      if (list[i] == nil)
        NSLog(@"No object for %@ at index %d", [values objectAtIndex: i], i);
    }

  return [NSArray arrayWithObjects: list count: max];
}

- (id) _decodeDictionaryOfObjectsForElement: (GSXibElement*)element
{
  NSDictionary *elements = [element elements];
  NSEnumerator *en;
  NSString *key;
  NSMutableDictionary *dict;

  dict = [[NSMutableDictionary alloc] init];
  en = [elements keyEnumerator];
  while ((key = [en nextObject]) != nil)
    {
      id obj = [self objectForXib: [elements objectForKey: key]];
      if (obj == nil)
        NSLog(@"No object for %@ at key %@", [elements objectForKey: key], key);
      else
        [dict setObject: obj forKey: key];
    }

  return AUTORELEASE(dict);
}

- (BOOL) containsValueForKey: (NSString*)aKey
{
  GSXibElement *element = [currentElement elementForKey: aKey];

  return (element != nil);
}

- (id) decodeObjectForKey: (NSString*)aKey
{
  GSXibElement *element = [currentElement elementForKey: aKey];

  if (element == nil)
    return nil;

  return [self objectForXib: element];
}

- (BOOL) decodeBoolForKey: (NSString*)aKey
{
  id o = [self decodeObjectForKey: aKey];

  if (o != nil)
    {
      if ([o isKindOfClass: [NSNumber class]] == YES)
	{
	  return [o boolValue];
	}
      else
	{
	  [NSException raise: NSInvalidUnarchiveOperationException
		      format: @"[%@ +%@]: value for key(%@) is '%@'",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    aKey, o];
	}
    }
  return NO;
}

- (const uint8_t*) decodeBytesForKey: (NSString*)aKey
		      returnedLength: (NSUInteger*)length
{
  id o = [self decodeObjectForKey: aKey];

  if (o != nil)
    {
      if ([o isKindOfClass: [NSData class]] == YES)
	{
	  *length = [o length];
	  return [o bytes];
	}
      else
	{
	  [NSException raise: NSInvalidUnarchiveOperationException
		      format: @"[%@ +%@]: value for key(%@) is '%@'",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    aKey, o];
	}
    }
  *length = 0;
  return 0;
}

- (double) decodeDoubleForKey: (NSString*)aKey
{
  id o = [self decodeObjectForKey: aKey];

  if (o != nil)
    {
      if ([o isKindOfClass: [NSNumber class]] == YES)
	{
	  return [o doubleValue];
	}
      else
	{
	  [NSException raise: NSInvalidUnarchiveOperationException
		      format: @"[%@ +%@]: value for key(%@) is '%@'",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    aKey, o];
	}
    }
  return 0.0;
}

- (float) decodeFloatForKey: (NSString*)aKey
{
  id o = [self decodeObjectForKey: aKey];

  if (o != nil)
    {
      if ([o isKindOfClass: [NSNumber class]] == YES)
	{
	  return [o floatValue];
	}
      else
	{
	  [NSException raise: NSInvalidUnarchiveOperationException
		      format: @"[%@ +%@]: value for key(%@) is '%@'",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    aKey, o];
	}
    }
  return 0.0;
}

- (int) decodeIntForKey: (NSString*)aKey
{
  id o = [self decodeObjectForKey: aKey];

  if (o != nil)
    {
      if ([o isKindOfClass: [NSNumber class]] == YES)
	{
	  long long l = [o longLongValue];

	  return l;
	}
      else
	{
	  [NSException raise: NSInvalidUnarchiveOperationException
		      format: @"[%@ +%@]: value for key(%@) is '%@'",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    aKey, o];
	}
    }
  return 0;
}

- (int32_t) decodeInt32ForKey: (NSString*)aKey
{
  id o = [self decodeObjectForKey: aKey];

  if (o != nil)
    {
      if ([o isKindOfClass: [NSNumber class]] == YES)
	{
	  long long l = [o longLongValue];

	  return l;
	}
      else
	{
	  [NSException raise: NSInvalidUnarchiveOperationException
		      format: @"[%@ +%@]: value for key(%@) is '%@'",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    aKey, o];
	}
    }
  return 0;
}

- (int64_t) decodeInt64ForKey: (NSString*)aKey
{
  id o = [self decodeObjectForKey: aKey];

  if (o != nil)
    {
      if ([o isKindOfClass: [NSNumber class]] == YES)
	{
	  long long l = [o longLongValue];

	  return l;
	}
      else
	{
	  [NSException raise: NSInvalidUnarchiveOperationException
		      format: @"[%@ +%@]: value for key(%@) is '%@'",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    aKey, o];
	}
    }
  return 0;
}

@end
