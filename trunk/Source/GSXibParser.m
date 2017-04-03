/* <title>GSXibParser</title>

   <abstract>Xib v5 (Cocoa XML) parser</abstract>

   Copyright (C) 2014 Free Software Foundation, Inc.

   Written by: Gregory Casamento <greg.casamento@gmail.com>
   Created: March 2014

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

#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSXMLParser.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

#import "GNUstepGUI/GSXibParser.h"
#import "GNUstepGUI/GSXibElement.h"

// XIB Object...
@interface XIBObject : NSObject
{
  NSMutableArray *connections;
}
- (id) initWithXibElement: (GSXibElement *)element;
- (id) instantiateObject;
@end

@implementation XIBObject
- (id) initWithXibElement: (GSXibElement *)element
{
  if ((self = [super init]) != nil)
    {
      connections = [[NSMutableArray alloc] initWithCapacity: 10];
    }
  return self;
}

- (void) dealloc
{
  [connections release];
  [super dealloc];
}

- (id) instantiateObject
{
  return nil;
}

- (NSArray *) connections
{
  return connections;
}
@end

@interface XIBAction : XIBObject
- (void) setSelector: (NSString *)selectorName;
- (NSString *) selector;
- (void) setTarget: (NSString *)targetId;
- (NSString *) target;
@end

@interface XIBOutlet : XIBObject
- (void) setProperty: (NSString *)propertyName;
- (NSString *) property;
- (void) setDestination: (NSString *)destinationId;
- (NSString *) destination;
@end

@interface XIBCustomObject
- (void) setUserLabel: (NSString *)label;
- (NSString *) userLabel;
- (void) setCustomClass: (NSString *)className;
- (NSString *) customClass;
@end



@implementation GSXibParser 

- (id) initWithData: (NSData *)data
{
  if ((self = [super init]) != nil)
    {
      theParser = [[NSXMLParser alloc] initWithData: data];
      [theParser setDelegate: self];

      objects = [[NSMutableDictionary alloc] initWithCapacity: 100];
      stack = [[NSMutableArray alloc] initWithCapacity: 100];
      currentElement = nil;
    }

  return self;
}

- (NSDictionary *) parse
{
  NS_DURING
    {
      [theParser parse];
    }
  NS_HANDLER
    {
      NSLog(@"%@",[localException reason]);
    }
  NS_ENDHANDLER;
  
  return objects;
}

- (NSMutableDictionary *) instantiateObjects
{
  return nil;
}

- (NSString *)classNameFromType: (NSString *)typeName
{
  NSString *className = [@"XIB" stringByAppendingString: [typeName capitalizedString]];
  return className;
}

- (id) instantiateObjectForElement: (GSXibElement *)element
{
  NSString *className = [self classNameFromType: [element type]];
  id obj = nil;

  if (className != nil)
    {
      Class cls = NSClassFromString(className);
      if (cls != nil)
	{
	  obj = [[cls alloc] initWithXibElement:element];
	}
    }

  return obj;
}

- (void) parser: (NSXMLParser*)parser
foundCharacters: (NSString*)string
{
  [currentElement setValue: string];
}

- (void) parser: (NSXMLParser*)parser
didStartElement: (NSString*)elementName
   namespaceURI: (NSString*)namespaceURI
  qualifiedName: (NSString*)qualifiedName
     attributes: (NSDictionary*)attributeDict
{
  GSXibElement *element = [[GSXibElement alloc] initWithType: elementName
					       andAttributes: attributeDict];
  NSString *key = [attributeDict objectForKey: @"id"];

  // FIXME: We should use proper memory management here
  AUTORELEASE(element);
  if ([@"document" isEqualToString: elementName])
    {
      currentElement = element;
    }
  else
    {
      if (key != nil)
	{
	  // id obj = [self instantiateObjectForElement: element];
	  [currentElement setElement: element forKey: key];
	}
      else
	{
	  // For Arrays
	  [currentElement addElement: element];
	}
      currentElement = element;
    }

  [stack addObject: currentElement];
}

- (void) parser: (NSXMLParser*)parser
  didEndElement: (NSString*)elementName
   namespaceURI: (NSString*)namespaceURI
  qualifiedName: (NSString*)qName
{
  if (![@"document" isEqualToString: elementName])
    {
      currentElement = [stack lastObject];
      [stack removeLastObject];
    }
  else
    {
      objects = [self instantiateObjects];
    }
}
@end
