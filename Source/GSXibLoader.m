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

- (id) nibInstantiate
{
  NSEnumerator *en;
  id obj;

  en = [connectionRecords objectEnumerator];
  // iterate over connections, instantiate, and then establish them.
  while ((obj = [en nextObject]) != nil)
    {
      [obj nibInstantiate];
      [obj establishConnection];
    }

  return self;
}

- (NSEnumerator *) objectRecordEnumerator
{
  return [[objectRecords orderedObjects] objectEnumerator];
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

- (void) awakeData: (NSDictionary*)data withContext: (NSDictionary *)context
{
  NSArray *rootObjects;
  NSEnumerator *en;
  id obj;
  IBObjectContainer *objects;
  NSMutableArray *topLevelObjects = [context objectForKey: NSNibTopLevelObjects];
  //id owner = [context objectForKey: NSNibOwner];

  objects = [data objectForKey: @"IBDocument.Objects"];
  [objects nibInstantiate];
  
  // FIXME: Use the owner as first root object
  rootObjects = [data objectForKey: @"IBDocument.RootObjects"];
  NSDebugLog(@"rootObjects %@", rootObjects);
  en = [rootObjects objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      if ([obj respondsToSelector: @selector(nibInstantiate)])
        {
          obj = [obj nibInstantiate];
          [topLevelObjects addObject: obj];
          RETAIN(obj);
        }

      // instantiate all windows and fill in the top level array.
      if ([obj isKindOfClass: [NSWindow class]])
        {
          // bring visible windows to front...
          //if ([obj isVisible])
            {
              [(NSWindow *)obj orderFront: self];
            }
        }
      else if ([obj isKindOfClass: [NSMenu class]])
        {
          // add the menu...
          [NSApp _setMainMenu: obj];
        }
    }
      
  // awaken all objects.
  en = [objects objectRecordEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      obj = [obj object];
      if ([obj respondsToSelector: @selector(awakeFromNib)])
        {
          [obj awakeFromNib];
        }
    }
}

- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
{
  BOOL		loaded = NO;
  NSKeyedUnarchiver *unarchiver = nil;

  NS_DURING
    {
      if (data != nil)
	{
          unarchiver = [[GSXibKeyedUnarchiver alloc] initForReadingWithData: data];
	  if (unarchiver != nil)
	    {
              NSDictionary *root;
              
	      NSDebugLog(@"Invoking unarchiver");
	      [unarchiver setObjectZone: zone];
              root = [unarchiver decodeObjectForKey: @"root"];
              if (root != nil)
                {
                  [self awakeData: root withContext: context];
                  loaded = YES;
                }
	      else
		{
		  NSLog(@"Data not found when loading xib.");
		}

              RELEASE(unarchiver);
	    }
	  else
	    {
	      NSLog(@"Could not instantiate unarchiver.");
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

  NSDebugLog(@"Loading Xib `%@'...\n", fileName);
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
                     @"GSXibElement <%@> attrs (%@) elements [%@] %@", 
                   type, attributes, elements, value, nil];
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

  if (![@"archive" isEqualToString: elementName])
    {
      // only used for the root element
      // push
      [stack addObject: currentElement];
    }

  if ([@"data" isEqualToString: elementName])
    {
      // only used for the element below root
      [currentElement setElement: element forKey: @"root"];
    }

  currentElement = element;
}

- (void) parser: (NSXMLParser *)parser
  didEndElement: (NSString *)elementName
   namespaceURI: (NSString *)namespaceURI
  qualifiedName: (NSString *)qName
{
  if (![@"archive" isEqualToString: elementName])
    {
      // pop
      currentElement = [stack lastObject];
      [stack removeLastObject];
    }
}

- (id) objectForXib: (GSXibElement*)element
{
  NSString *elementName;
  NSString *key = [element attributeForKey: @"id"];

  if (element == nil)
    return nil;

  elementName = [element type];
  if ([@"object" isEqualToString: elementName])
    {
      GSXibElement *last;
      NSString *classname = [element attributeForKey: @"class"];
      Class c = [self classForClassName: classname];
      id o, r;
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
		      [NSException raise:
			NSInvalidUnarchiveOperationException
			format: @"[%@ +%@]: no class for name '%@'",
			NSStringFromClass([self class]),
			NSStringFromSelector(_cmd),
			classname];
		    }
		}
	    }
	}

      // push
      last = currentElement;
      currentElement = element;

      // Create instance.
      o = [c allocWithZone: [self zone]];
      if (key != nil)
        [decoded setObject: o forKey: key];
      r = [o initWithCoder: self];
      if (r != o)
	{
	  [delegate unarchiver: self
	      willReplaceObject: o
		     withObject: r];
	  o = r;
          if (key != nil)
            [decoded setObject: o forKey: key];
	}
      r = [o awakeAfterUsingCoder: self];
      if (r != o)
	{
	  [delegate unarchiver: self
	      willReplaceObject: o
		     withObject: r];
	  o = r;
          if (key != nil)
            [decoded setObject: o forKey: key];
	}
      if (delegate != nil)
	{
	  r = [delegate unarchiver: self didDecodeObject: o];
	  if (r != o)
	    {
	      [delegate unarchiver: self
		  willReplaceObject: o
			 withObject: r];
	      o = r;
              if (key != nil)
                [decoded setObject: o forKey: key];
	    }
	}
      if (key != nil)
        {
          // Retained in decoded
          RELEASE(o);
        }
      else
        AUTORELEASE(o);

      // pop
      currentElement = last;

      return o;
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

      if (key != nil)
        [decoded setObject: new forKey: key];
      
      return new;
    }
  else if ([@"int" isEqualToString: elementName])
    {
      id new = [NSNumber numberWithInt: [[element value] intValue]];

      if (key != nil)
        [decoded setObject: new forKey: key];
      
      return new;
    }
  else if ([@"double" isEqualToString: elementName])
    {
      id new = [NSNumber numberWithDouble: [[element value] doubleValue]];

      if (key != nil)
        [decoded setObject: new forKey: key];
      
      return new;
    }
  else if ([@"bool" isEqualToString: elementName])
    {
      id new = [NSNumber numberWithBool: [[element value] boolValue]];

      if (key != nil)
        [decoded setObject: new forKey: key];
      
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

          if (new == nil)
            {
              // push
              GSXibElement *last = currentElement;

              element = [objects objectForKey: ref];
              currentElement = element;

              // pop
              currentElement = last;
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

      if (key != nil)
        [decoded setObject: new forKey: key];
      
      return new;
    }
  else if ([@"integer" isEqualToString: elementName])
    {
      id new = [NSNumber numberWithInteger: [[element value] integerValue]];

      if (key != nil)
        [decoded setObject: new forKey: key];
      
      return new;
    }
  else if ([@"bytes" isEqualToString: elementName])
    {
      id new = [[element value] dataUsingEncoding: NSASCIIStringEncoding
                           allowLossyConversion: NO];
      new = [GSMimeDocument decodeBase64: new];

      if (key != nil)
        [decoded setObject: new forKey: key];
      
      return new;
    }
  else if ([@"data" isEqualToString: elementName])
    {
      NSDictionary *elements = [element elements];
      NSEnumerator *keyEnumerator = [elements keyEnumerator];
      NSString *nextKey;
      GSXibElement *nextXib;
      id nextObject;
      NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 
                                                            [elements count]];

      while ((nextKey = (NSString*)[keyEnumerator nextObject]) != nil)
        {
          nextXib = (GSXibElement*)[elements objectForKey: nextKey];
          nextObject = [self objectForXib: nextXib];
          if (nextObject != nil)
            {
              [dict setObject: nextObject forKey: nextKey];
            }
          else
            {
              NSLog(@"nil object in data dictionary for key %@", nextKey);
            }
        }

      return dict;
    }
  else
    {
      NSLog(@"Unknown element type %@", elementName);
    }

  return nil;
}

- (id) _decodeArrayOfObjectsForKey: (NSString*)aKey
{
  NSArray *values = [currentElement values];
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
