/* <title>GSXibLoader</title>

   <abstract>Xib (Cocoa XML) model loader</abstract>

   Copyright (C) 2010, 2011 Free Software Foundation, Inc.

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
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSXMLParser.h>
#import <Foundation/NSXMLDocument.h>
#import <Foundation/NSXMLElement.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSNibLoading.h"
#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GNUstepGUI/GSNibLoading.h"
#import "GNUstepGUI/GSXibLoading.h"
#import "GNUstepGUI/GSXibParser.h"
#import "GNUstepGUI/GSXibObjectContainer.h"
#import "GNUstepGUI/GSXibElement.h"
#import "GNUstepGUI/GSXibKeyedUnarchiver.h"

@interface NSApplication (NibCompatibility)
- (void) _setMainMenu: (NSMenu*)aMenu;
@end

@interface NSMenu (XibCompatibility)
- (BOOL) _isMainMenu;
@end

@interface NSCustomObject (NibCompatibility)
- (id) realObject;
- (void) setRealObject: (id)obj;
- (NSString *)className;
@end

@interface NSNibConnector (NibCompatibility)
- (id) nibInstantiate;
@end

@implementation NSMenu (XibCompatibility)

- (BOOL) _isMainMenu
{
  if (_name)
    return [_name isEqualToString:@"_NSMainMenu"];
  return NO;
}

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

- (NSString*) label
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

- (NSNibConnector*) nibConnector
{
  NSString *tag = [self label];
  NSRange colonRange = [tag rangeOfString: @":"];
  NSUInteger location = colonRange.location;
  NSNibConnector *result = nil;

  if (location == NSNotFound)
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
              /*
               * We cannot use the KVC mechanism here, as this would always retain _dst
               * and it could also affect _setXXX methods and _XXX ivars that aren't
               * affected by the Cocoa code.
               */ 	 
              const char *name = [label cString];
              Class class = object_getClass(source);
              Ivar ivar = class_getInstanceVariable(class, name);
              
              if (ivar != 0)
                {
                  object_setIvar(source, ivar, destination);
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
      else
        {
          NSString *format = [NSString stringWithFormat:@"%s:Can't decode %@ without a connection ID",
                              __PRETTY_FUNCTION__,
                              NSStringFromClass([self class])];
          [NSException raise: NSInvalidArgumentException
                      format: @"%@", format];
        }
      
      // Load the connection ID....
      if ([coder containsValueForKey: @"connectionID"])
        {
          // PRE-4.6 XIBs....
          connectionID = [coder decodeIntForKey: @"connectionID"];
        }
      else if ([coder containsValueForKey: @"id"])
        {
          // 4.6+ XIBs....
          NSString *string = [coder decodeObjectForKey: @"id"];

          if (string && [string isKindOfClass:[NSString class]] && [string length])
            {
              connectionID = [string intValue];
            }
          else
            {
              NSString *format = [NSString stringWithFormat:@"%s:class: %@ - connection ID is missing or zero!",
                                  __PRETTY_FUNCTION__, NSStringFromClass([self class])];
              [NSException raise: NSInvalidArgumentException
                          format: @"%@", format];
            }
        }
      else
        {
          NSString *format = [NSString stringWithFormat:@"%s:Can't decode %@ without a connection ID",
                              __PRETTY_FUNCTION__,
                              NSStringFromClass([self class])];
          [NSException raise: NSInvalidArgumentException
                      format: @"%@", format];
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

- (IBConnection*) connection
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

- (NSString*) toolTip
{
  return toolTip;
}

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"name"])
        {
          ASSIGN(name, [coder decodeObjectForKey: @"name"]);
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
          ASSIGN(name, [coder decodeObjectForKey: @"name"]);
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
          // PRE-4.6 XIBs....
          objectID = [coder decodeObjectForKey: @"objectID"];
        }
      else if ([coder containsValueForKey: @"id"])
        {
          // 4.6+ XIBs....
          objectID = [coder decodeObjectForKey: @"id"];
        }
      else
        {
          // Cannot process without object ID...
          NSString *format = [NSString stringWithFormat:@"%s:Can't decode %@ without an object ID",
                              __PRETTY_FUNCTION__,
                              NSStringFromClass([self class])];
          [NSException raise: NSInvalidArgumentException
                      format: @"%@", format];
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

- (id) objectID
{
  return objectID;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"<%@, %@, %@, %p>",
		   [self className],
		   object,
		   parent,
		   objectID];
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

- (NSArray*)orderedObjects
{
  return orderedObjects;
}

- (id) objectWithObjectID: (id)objID
{
  NSEnumerator *en;
  IBObjectRecord *obj;

  en = [orderedObjects objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      if ([[obj objectID] isEqual:objID])
        {
          return [obj object];
        }
    }
  return nil;
}

@end

@implementation IBObjectContainer

- (id) initWithCoder: (NSCoder*)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"sourceID"])
        {
          ASSIGN(sourceID, [coder decodeObjectForKey: @"sourceID"]);
        }
      if ([coder containsValueForKey: @"maxID"])
        {
          maxID = [coder decodeIntForKey: @"maxID"];
        }
      if ([coder containsValueForKey: @"flattenedProperties"])
        {
          ASSIGN(flattenedProperties, [coder decodeObjectForKey: @"flattenedProperties"]);
        }
      if ([coder containsValueForKey: @"objectRecords"])
        {
          ASSIGN(objectRecords, [coder decodeObjectForKey: @"objectRecords"]);
        }
      if ([coder containsValueForKey: @"connectionRecords"])
        {
          ASSIGN(connectionRecords, [coder decodeObjectForKey: @"connectionRecords"]);
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

- (NSEnumerator*) connectionRecordEnumerator
{
  return [connectionRecords objectEnumerator];
}

- (NSEnumerator*) objectRecordEnumerator
{
  return [[objectRecords orderedObjects] objectEnumerator];
}

- (NSDictionary*) propertiesForObjectID: (id)objectID
{
  NSEnumerator *en;
  NSString *idString;
  NSString *key;
  NSMutableDictionary *properties;
  int idLength;

  idString = [NSString stringWithFormat: @"%@.", objectID];
  idLength = [idString length];
  properties = [[NSMutableDictionary alloc] init];
  en = [flattenedProperties keyEnumerator];
  while ((key = [en nextObject]) != nil)
    {
      if ([key hasPrefix: idString])
        {
          id value = [flattenedProperties objectForKey: key];
          [properties setObject: value forKey: [key substringFromIndex: idLength]];
        }
    }

  return AUTORELEASE(properties);
}

/*
  Returns a dictionary of the custom class names keyed on the objectIDs.
 */
- (NSDictionary*) customClassNames
{
  NSMutableDictionary *properties;
  int i;

  properties = [[NSMutableDictionary alloc] init];
  // We have special objects at -3, -2, -1 and 0
  for (i = -3; i < maxID; i++)
    {
      NSString *idString;
      id value;

      idString = [NSString stringWithFormat: @"%d.CustomClassName", i];
      value = [flattenedProperties objectForKey: idString];
      if (value)
        {
          NSString *key;

          key = [NSString stringWithFormat: @"%d", i];
          [properties setObject: value forKey: key];
        }
    }

  return properties;
}

- (id) nibInstantiate
{
  NSEnumerator *en;
  id obj;

  // iterate over connections, instantiate, and then establish them.
  en = [connectionRecords objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      [obj nibInstantiate];
      [obj establishConnection];
    }

  // awaken all objects.
  en = [[objectRecords orderedObjects] objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      id realObj;
      NSDictionary *properties;
      id value;

      realObj = [obj object];
      if ([realObj respondsToSelector: @selector(nibInstantiate)])
        {
          realObj = [realObj nibInstantiate];
        }

      properties = [self propertiesForObjectID: [obj objectID]];
      NSDebugLLog(@"XIB", @"object %ld props %@", (long)[obj objectID], properties);

      //value = [properties objectForKey: @"windowTemplate.maxSize"];
      //value = [properties objectForKey: @"CustomClassName"];

      // Activate windows
      value = [properties objectForKey: @"NSWindowTemplate.visibleAtLaunch"];
      if (value != nil)
        {
          if ([value boolValue] == YES)
            {
              if ([realObj isKindOfClass: [NSWindow class]])
                {
                  // bring visible windows to front...
                  [(NSWindow *)realObj orderFront: self];
                }
            }
        }

      // Tool tips
      value = [properties objectForKey: @"IBAttributePlaceholdersKey"];
      if (value != nil)
        {
          NSDictionary *infodict = (NSDictionary*)value;
          
          // Process tooltips...
          IBToolTipAttribute *tooltip = [infodict objectForKey: @"ToolTip"];

          if (tooltip && [realObj respondsToSelector: @selector(setToolTip:)])
            {
              [realObj setToolTip: [tooltip toolTip]];
            }
          
          // Process XIB runtime attributes...
          if ([infodict objectForKey:@"IBUserDefinedRuntimeAttributesPlaceholderName"])
            {
              IBUserDefinedRuntimeAttributesPlaceholder *placeholder =
                [infodict objectForKey:@"IBUserDefinedRuntimeAttributesPlaceholderName"];
              NSArray *attributes = [placeholder runtimeAttributes];
              NSEnumerator *objectIter = [attributes objectEnumerator];
              IBUserDefinedRuntimeAttribute *attribute;
              
              while ((attribute = [objectIter nextObject]) != nil)
                {
                  [realObj setValue: [attribute value] forKeyPath: [attribute keyPath]];
                }
            }
        }

      if ([realObj respondsToSelector: @selector(awakeFromNib)])
        {
          [realObj awakeFromNib];
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

+ (NSString*) type
{
  return @"xib";
}

+ (float) priority
{
  return 4.0;
}

- (void) awake: (NSArray *)rootObjects 
   inContainer: (id)objects 
   withContext: (NSDictionary *)context
{
  NSEnumerator *en;
  id obj;
  NSMutableArray *topLevelObjects = [context objectForKey: NSNibTopLevelObjects];
  id owner = [context objectForKey: NSNibOwner];
  id first = nil;
  id app   = nil;
  NSCustomObject *object;
  NSString *className;

  // Get the file's owner and NSApplication object references...
  object = (NSCustomObject*)[rootObjects objectAtIndex: 1];
  if ([[object className] isEqualToString: @"FirstResponder"])
    {
      first = [object realObject];
    }
  else
    {
      NSLog(@"%s:first responder missing\n", __PRETTY_FUNCTION__);
    }

  object = (NSCustomObject*)[rootObjects objectAtIndex: 2];
  className = [object className];
  if ([className isEqualToString: @"NSApplication"] ||
      [NSClassFromString(className) isSubclassOfClass:[NSApplication class]])
    {
      app = [object realObject];
    }
  else
    {
      NSLog(@"%s:NSApplication missing '%@'\n", __PRETTY_FUNCTION__, className);
    }

  // Use the owner as first root object
  [(NSCustomObject*)[rootObjects objectAtIndex: 0] setRealObject: owner];

  en = [rootObjects objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      if ([obj respondsToSelector: @selector(nibInstantiate)])
        {
          obj = [obj nibInstantiate];
        }

      // IGNORE file's owner, first responder and NSApplication instances...
      if ((obj != nil) && (obj != owner) && (obj != first) && (obj != app))
        {
          [topLevelObjects addObject: obj];
          // All top level objects must be released by the caller to avoid
          // leaking, unless they are going to be released by other nib
          // objects on behalf of the owner.
          RETAIN(obj);
        }

      if (([obj isKindOfClass: [NSMenu class]]) &&
          ([obj _isMainMenu]))
        {
          // add the menu...
          [NSApp _setMainMenu: obj];
        }
    }

  // Load connections and awaken objects
  if ([objects respondsToSelector:@selector(nibInstantiate)])
    {
      [objects nibInstantiate];
    }
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
              [self awake: rootObjects 
		    inContainer: objects 
		    withContext: context];
              loaded = YES;
              RELEASE(unarchiver);
	    }
	  else
	    {
	      GSXibParser *parser = [[GSXibParser alloc] initWithData: data]; 
	      NSDictionary *result = [parser parse];
	      if (result != nil)
		{
		  NSArray *rootObjects = [result objectForKey: @"IBDocument.RootObjects"];
		  GSXibObjectContainer *objects = [result objectForKey: @"IBDocument.Objects"];
		  [self awake: rootObjects
			inContainer: objects
			withContext: context];
		}
	      else
		{
		  NSLog(@"Could not instantiate Xib unarchiver/Unable to parse Xib.");
		}
	    }
	}
      else
	{
	  NSLog(@"Data passed to Xib loading method is nil.");
	}
    }
  NS_HANDLER
    {
      NSLog(@"Exception occurred while loading model: %@",[localException reason]);
      // TEST_RELEASE(unarchiver);
    }
  NS_ENDHANDLER

  if (loaded == NO)
    {
      NSLog(@"Failed to load Xib\n");
    }

  return loaded;
}

- (NSData*) dataForFile: (NSString*)fileName
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
