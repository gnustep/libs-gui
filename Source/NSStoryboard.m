/* Implementation of class NSStoryboard
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory Casamento
   Date: Mon Jan 20 15:57:37 EST 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSBundle.h>
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSXMLDocument.h>
#import <Foundation/NSXMLElement.h>
#import <Foundation/NSXMLNode.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSUUID.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSStoryboard.h"
#import "AppKit/NSWindowController.h"
#import "AppKit/NSViewController.h"
#import "AppKit/NSWindow.h"

#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GSFastEnumeration.h"

static NSStoryboard *__mainStoryboard = nil;

// The storyboard needs to set this information on controllers...
@interface NSWindowController (__StoryboardPrivate__)
- (void) _setOwner: (id)owner;
- (void) _setTopLevelObjects: (NSArray *)array;
- (void) _setSegueMap: (NSMapTable *)map;
- (void) _setStoryboard: (NSStoryboard *)storyboard;
@end

@interface NSViewController (__StoryboardPrivate__)
- (void) _setTopLevelObjects: (NSArray *)array;
- (void) _setSegueMap: (NSMapTable *)map;
- (void) _setStoryboard: (NSStoryboard *)storyboard;
@end

@interface NSStoryboardSegue (__StoryboardPrivate__)
- (void) _setKind: (NSString *)k;
- (void) _setRelationship: (NSString *)r;
- (NSString *) _kind;
- (NSString *) _relationship;
@end

// this needs to be set on segues
@implementation NSStoryboardSegue (__StoryboardPrivate__)
- (void) _setKind: (NSString *)k
{
  ASSIGN(_kind, k);
}

- (void) _setRelationship: (NSString *)r
{
  ASSIGN(_relationship, r);
}

- (NSString *) _kind
{
  return _kind;
}

- (NSString *) _relationship
{
  return _relationship;
}
@end

@implementation NSWindowController (__StoryboardPrivate__)
- (void) _setOwner: (id)owner
{
  _owner = owner; // weak
}

- (void) _setTopLevelObjects: (NSArray *)array
{
  _top_level_objects = array;
}

- (void) _setSegueMap: (NSMapTable *)map
{
  ASSIGN(_segueMap, map);
}

- (void) _setStoryboard: (NSStoryboard *)storyboard
{
  _storyboard = storyboard;
}
@end

@implementation NSViewController (__StoryboardPrivate__)
- (void) _setTopLevelObjects: (NSArray *)array
{
  _topLevelObjects = array;
}

- (void) _setSegueMap: (NSMapTable *)map
{
  ASSIGN(_segueMap, map);
}

- (void) _setStoryboard: (NSStoryboard *)storyboard
{
  _storyboard = storyboard;
}
@end
// end private methods...

@interface NSStoryboardSeguePerformAction : NSObject <NSCoding, NSCopying>
{
  id        _target;
  SEL       _action;
  id        _sender;
  NSString *_identifier;
  NSString *_kind;
}

- (id) target;
- (void) setTarget: (id)target;

- (NSString *) selector;
- (void) setSelector: (NSString *)s;

- (SEL) action;
- (void) setAction: (SEL)action;

- (id) sender;
- (void) setSender: (id)sender;

- (NSString *) identifier;
- (void) setIdentifier: (NSString *)identifier;

- (NSString *) kind;
- (void) setKind: (NSString *)kind;
@end

@implementation NSStoryboardSeguePerformAction
- (id) target
{
  return _target;
}

- (void) setTarget: (id)target
{
  ASSIGN(_target, target);
}

- (SEL) action
{
  return _action;
}

- (void) setAction: (SEL)action
{
  _action = action;
}

- (NSString *) selector
{
  return NSStringFromSelector(_action);
}

- (void) setSelector: (NSString *)s
{
  _action = NSSelectorFromString(s);
}

- (id) sender
{
  return _sender;
}

- (void) setSender: (id)sender
{
  ASSIGN(_sender, sender);
}

- (NSString *) identifier
{
  return _identifier;
}

- (void) setIdentifier: (NSString *)identifier
{
  ASSIGN(_identifier, identifier);
}

- (NSString *) kind
{
  return _kind;
}

- (void) setKind: (NSString *)kind
{
  ASSIGN(_kind, kind);
}

- (id) nibInstantiate
{
  return self;
}

- (IBAction) doAction: (id)sender
{
  [_sender performSegueWithIdentifier: _identifier
                               sender: _sender];
}

- (id) copyWithZone: (NSZone *)z
{
  NSStoryboardSeguePerformAction *pa = [[NSStoryboardSeguePerformAction allocWithZone: z] init];
  [pa setTarget: _target];
  [pa setSelector: [self selector]];
  [pa setSender: _sender];
  [pa setIdentifier: _identifier];
  return pa;
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSTarget"])
        {
          [self setTarget: [coder decodeObjectForKey: @"NSTarget"]];
        }
      if ([coder containsValueForKey: @"NSSelector"])
        {
          [self setSelector: [coder decodeObjectForKey: @"NSSelector"]];
        }
      if ([coder containsValueForKey: @"NSSender"])
        {
          [self setSender: [coder decodeObjectForKey: @"NSSender"]];
        }
      if ([coder containsValueForKey: @"NSIdentifier"])
        {
          [self setIdentifier: [coder decodeObjectForKey: @"NSIdentifier"]];
        }
      if ([coder containsValueForKey: @"NSKind"])
        {
          [self setKind: [coder decodeObjectForKey: @"NSKind"]];
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  // this is never encoded directly...
}
@end


@interface NSControllerPlaceholder : NSObject <NSCoding, NSCopying> // , NSSeguePerforming>
{
  NSString *_storyboardName;
}

- (NSString *) storyboardName;
- (void) setStoryboardName: (NSString *)name;

- (id) instantiate;

@end

@implementation NSControllerPlaceholder

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
    }
  return self;
}

- (NSString *) storyboardName
{
  return _storyboardName;
}

- (void) setStoryboardName: (NSString *)name
{
  ASSIGNCOPY(_storyboardName, name);
}

- (id) copyWithZone: (NSZone *)z
{
  NSControllerPlaceholder *c = [[NSControllerPlaceholder allocWithZone: z] init];
  [c setStoryboardName: _storyboardName];
  return c;
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSStoryboardName"])
        {
          [self setStoryboardName: [coder decodeObjectForKey: @"NSStoryboardName"]];
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  // this is never encoded directly...
}

- (id) instantiate
{
  NSStoryboard *sb = [NSStoryboard storyboardWithName: _storyboardName
                                               bundle: [NSBundle mainBundle]];
  return [sb instantiateInitialController];
}

@end

@implementation NSStoryboard

- (NSXMLElement *) _createCustomObjectWithId: (NSString *)ident
                                   userLabel: (NSString *)userLabel
                                 customClass: (NSString *)className
{
  NSXMLElement *customObject =
    [[NSXMLElement alloc] initWithName: @"customObject"];
  NSXMLNode *idValue =
    [NSXMLNode attributeWithName: @"id"
                     stringValue: ident];
  NSXMLNode *usrLabel =
    [NSXMLNode attributeWithName: @"userLabel"
                     stringValue: userLabel];
  NSXMLNode *customCls =
    [NSXMLNode attributeWithName: @"customClass"
                     stringValue: className];
  
  [customObject addAttribute: idValue];
  [customObject addAttribute: usrLabel];
  [customObject addAttribute: customCls];

  AUTORELEASE(customObject);
  
  return customObject;
}

- (void) _processStoryboard: (NSXMLDocument *)storyboardXml
{
  NSArray *docNodes = [storyboardXml nodesForXPath: @"document" error: NULL];

  if ([docNodes count] > 0)
    {
      NSXMLElement *docNode = [docNodes objectAtIndex: 0];
      NSArray *array = [docNode nodesForXPath: @"//scene" error: NULL];
      NSString *customClassString = nil;
      
      // Set initial view controller...
      ASSIGN(_initialViewControllerId, [[docNode attributeForName: @"initialViewController"] stringValue]);             
      _scenesMap = [[NSMutableDictionary alloc] initWithCapacity: [array count]];
      _controllerMap = [[NSMutableDictionary alloc] initWithCapacity: [array count]];
      _documentsMap = [[NSMutableDictionary alloc] initWithCapacity: [array count]];
      
      //while ((e = [en nextObject]) != nil)
      FOR_IN(NSXMLElement*, e, array) 
        {
          NSXMLElement *doc = [[NSXMLElement alloc] initWithName: @"document"];
          NSArray *children = [e children];
          NSEnumerator *ce = [children objectEnumerator];
          NSXMLElement *child = nil;
          NSXMLDocument *document = nil;
          NSString *sceneId = [[e attributeForName: @"sceneID"] stringValue]; 
          NSString *controllerId = nil;

          // Copy children...
          while ((child = [ce nextObject]) != nil)
            {
              if ([[child name] isEqualToString: @"point"] == YES)
                continue; // go on if it's point, we don't use that in the app...
              
              NSArray *subnodes = [child nodesForXPath: @"//application" error: NULL];
              NSXMLNode *appNode = [subnodes objectAtIndex: 0];
              if (appNode != nil)
                {
                  NSXMLElement *objects = (NSXMLElement *)[appNode parent];
                  NSArray *appConsArr = [appNode nodesForXPath: @"connections" error: NULL];
                  NSXMLNode *appCons = [appConsArr objectAtIndex: 0];
                  if (appCons != nil)
                    {
                      [appCons detach];
                    }
                  
                  NSArray *appChildren = [appNode children];
                  NSEnumerator *ace = [appChildren objectEnumerator];
                  NSXMLElement *ae = nil;
                  
                  // Move all application children to objects...
                  while ((ae = [ace nextObject]) != nil)
                    {
                      [ae detach];
                      [objects addChild: ae];
                    }
                  
                  // Remove the appNode
                  [appNode detach];
                  
                  // create a customObject entry for NSApplication reference...
                  NSXMLNode *appCustomClass = (NSXMLNode *)[(NSXMLElement *)appNode
                                                               attributeForName: @"customClass"];
                  customClassString = ([appCustomClass stringValue] == nil) ?
                    @"NSApplication" : [appCustomClass stringValue];
                  NSXMLElement *customObject = nil;
                  
                  customObject = 
                    [self _createCustomObjectWithId: @"-3"
                                          userLabel: @"Application"
                                        customClass: @"NSObject"];
                  [child insertChild: customObject
                             atIndex: 0];
                  customObject = 
                    [self _createCustomObjectWithId: @"-1"
                                          userLabel: @"First Responder"
                                        customClass: @"FirstResponder"];
                  [child insertChild: customObject
                             atIndex: 0];
                  customObject =
                    [self _createCustomObjectWithId: @"-2"
                                          userLabel: @"File's Owner"
                                        customClass: customClassString];
                  if (appCons != nil)
                    {
                      [customObject addChild: appCons];
                    }
                  [child insertChild: customObject
                             atIndex: 0];
                  

                  // Add it to the document
                  [objects detach];
                  [doc addChild: objects];
                  
                  // Assign application scene...
                  ASSIGN(_applicationSceneId, sceneId);
                }
              else
                {
                  NSXMLElement *customObject = nil;

                  customObject = 
                    [self _createCustomObjectWithId: @"-3"
                                          userLabel: @"Application"
                                        customClass: @"NSObject"];
                  [child insertChild: customObject
                             atIndex: 0];
                  customObject = 
                    [self _createCustomObjectWithId: @"-1"
                                          userLabel: @"First Responder"
                                        customClass: @"FirstResponder"];
                  [child insertChild: customObject
                             atIndex: 0];
                  customObject = 
                    [self _createCustomObjectWithId: @"-2"
                                          userLabel: @"File's Owner"
                                        customClass: customClassString];
                  [child insertChild: customObject
                             atIndex: 0];

                  [child detach];
                  [doc addChild: child];
                }

              // Add other custom objects...
              
              // fix other custom objects
              document = [[NSXMLDocument alloc] initWithRootElement: doc]; // put it into the document, so we can use Xpath.
              NSArray *windowControllers = [document nodesForXPath: @"//windowController" error: NULL];
              NSArray *viewControllers = [document nodesForXPath: @"//viewController" error: NULL];
              NSArray *controllerPlaceholders = [document nodesForXPath: @"//controllerPlaceholder" error: NULL];
              RELEASE(doc);
              
              if ([windowControllers count] > 0)
                {
                  NSXMLElement *ce = [windowControllers objectAtIndex: 0];
                  NSXMLNode *attr = [ce attributeForName: @"id"];
                  controllerId = [attr stringValue];

                  NSEnumerator *windowControllerEnum = [windowControllers objectEnumerator];
                  NSXMLElement *o = nil;
                  while ((o = [windowControllerEnum nextObject]) != nil)
                    {
                      NSXMLElement *objects = (NSXMLElement *)[o parent];
                      NSArray *windows = [o nodesForXPath: @"//window" error: NULL];
                      NSEnumerator *windowEn = [windows objectEnumerator];
                      NSXMLNode *w = nil;
                      while ((w = [windowEn nextObject]) != nil)
                        {
                          [w detach];
                          [objects addChild: w];
                        }
                    }
                }
              
              if ([viewControllers count] > 0)
                {
                  NSXMLElement *ce = [viewControllers objectAtIndex: 0];
                  NSXMLNode *attr = [ce attributeForName: @"id"];
                  controllerId = [attr stringValue];
                }

              if ([controllerPlaceholders count] > 0)
                {
                  NSXMLElement *ce = [controllerPlaceholders objectAtIndex: 0];
                  NSXMLNode *attr = [ce attributeForName: @"id"];
                  controllerId = [attr stringValue];
                }

              NSArray *customObjects = [document nodesForXPath: @"//objects/customObject" error: NULL];
              NSEnumerator *coen = [customObjects objectEnumerator];
              NSXMLElement *coel = nil;
              while ((coel = [coen nextObject]) != nil)
                {
                   NSXMLNode *attr = [coel attributeForName: @"sceneMemberID"];
                  if ([[attr stringValue] isEqualToString: @"firstResponder"])
                    {
                      NSXMLNode *customClassAttr = [coel attributeForName: @"customClass"];
                      NSXMLNode *idAttr = [coel attributeForName: @"id"];
                      NSString *originalId = [idAttr stringValue];

                      [idAttr setStringValue: @"-1"]; // set to first responder id
                      [customClassAttr setStringValue: @"FirstResponder"];

                      // Actions
                      NSArray *cons = [document nodesForXPath: @"//action" error: NULL];
                      NSEnumerator *consen = [cons objectEnumerator];
                      NSXMLElement *celem = nil;

                      while ((celem = [consen nextObject]) != nil)
                        {
                          NSXMLNode *targetAttr = [celem attributeForName: @"target"];
                          NSString *val = [targetAttr stringValue];
                          if ([val isEqualToString: originalId])
                            {
                              [targetAttr setStringValue: @"-1"];
                            }
                        }

                      // Outlets
                      cons = [document nodesForXPath: @"//outlet" error: NULL];
                      consen = [cons objectEnumerator];
                      celem = nil;
                      while ((celem = [consen nextObject]) != nil)
                        {
                          NSXMLNode *attr = [celem attributeForName: @"destination"];
                          NSString *val = [attr stringValue];
                          if ([val isEqualToString: originalId])
                            {
                              [attr setStringValue: @"-1"];
                            }
                        }
                    }
                }

              // Delete extra firstResponder...
              /*
              NSArray *ar = [document nodesForXPath: @"//customObject[@sceneMemberID=\"firstResponder\"]"
                                              error: NULL];
              if ([ar count] > 0)
                {
                  id node = [ar objectAtIndex: 0];
                  [node detach];
                }
              */
              
              // Create document...
              [_scenesMap setObject: document
                             forKey: sceneId];
              
              // Map controllerId's to scenes...
              if (controllerId != nil)
                {
                  [_controllerMap setObject: sceneId
                                     forKey: controllerId];
                }
              
              RELEASE(document);
            }
        }
      END_FOR_IN(array);
    }
  else
    {
      NSLog(@"No document element in storyboard file");
    }
}

- (NSMapTable *) _processSegues: (NSXMLDocument *)xmlIn
{
  NSMapTable *mapTable = [NSMapTable strongToWeakObjectsMapTable];
  NSArray *connectionsArray = [xmlIn nodesForXPath: @"//connections"
                                             error: NULL];
  NSArray *array = [xmlIn nodesForXPath: @"//objects"
                                  error: NULL];
  NSXMLElement *objects = [array objectAtIndex: 0]; // get the "objects" section
  NSArray *controllers = [objects nodesForXPath: @"windowController"
                                          error: NULL];

  NSString *uuidString = nil;
  NSArray *docArray = [xmlIn nodesForXPath: @"document" error: NULL];
  if ([docArray count] > 0)
    {
      NSXMLElement *docElem = (NSXMLElement *)[docArray objectAtIndex: 0];
      NSXMLNode *a = [docElem attributeForName: @"uuid"];
      NSString *value = [a stringValue];
      if (value != nil)
        {
          return [_documentsMap objectForKey: value];
        }
      else
        {
          uuidString = [[NSUUID UUID] UUIDString];
          NSXMLNode *new_uuid_attr = [NSXMLNode attributeWithName: @"uuid"
                                                      stringValue: uuidString];
          [docElem addAttribute: new_uuid_attr];
        }
    }
  
  NSString *src = nil;
  if ([controllers count] > 0)
    {
      NSXMLElement *controller = (NSXMLElement *)[controllers objectAtIndex: 0];
      NSXMLNode *idAttr = [controller attributeForName: @"id"];
      src = [idAttr stringValue];
    }
  else
    {
      controllers = [objects nodesForXPath: @"viewController"
                                     error: NULL];
      if ([controllers count] > 0)
        {
          NSXMLElement *controller = (NSXMLElement *)[controllers objectAtIndex: 0];
          NSXMLNode *idAttr = [controller attributeForName: @"id"];
          src = [idAttr stringValue];
        }
    }
  
  if ([connectionsArray count] > 0)
    {
      NSEnumerator *connectionsEnum = [connectionsArray objectEnumerator];
      id connObj = nil;
      while ((connObj = [connectionsEnum nextObject]) != nil)
        {
          NSXMLElement *connections = (NSXMLElement *)connObj;
          NSArray *children = [connections children]; // there should be only one per set.
          NSEnumerator *en = [children objectEnumerator];
          id obj = nil;
          
          while ((obj = [en nextObject]) != nil)
            {
              if ([[obj name] isEqualToString: @"segue"])
                {
                  // get the information from the segue.
                  id segue_parent_parent = [[obj parent] parent];
                  id segue_parent = [obj parent];
                  NSString *segue_parent_parent_name = [segue_parent_parent name];
                  NSXMLNode *attr = [obj attributeForName: @"destination"];
                  NSString *dst = [attr stringValue];
                  attr = [obj attributeForName: @"kind"];
                  NSString *kind =  [attr stringValue];
                  attr = [obj attributeForName: @"relationship"];
                  NSString *rel = [attr stringValue];
                  [obj detach]; // segue can't be in the archive since it doesn't conform to NSCoding
                  attr = [obj attributeForName: @"id"];
                  NSString *uid = [attr stringValue];
                  attr = [obj attributeForName: @"identifier"];
                  NSString *identifier = [attr stringValue];
                  if (identifier == nil)
                    {
                      identifier = [[NSUUID UUID] UUIDString];
                    }
                  
                  // Create proxy object to invoke methods on the window controller
                  NSXMLElement *sbproxy = [NSXMLElement elementWithName: @"storyboardSeguePerformAction"];
                  NSXMLNode *pselector
                    = [NSXMLNode attributeWithName: @"selector"
                                       stringValue: @"doAction:"];
                  NSXMLNode *ptarget
                    = [NSXMLNode attributeWithName: @"target"
                                       stringValue: dst];
                  NSString *pident_value = [[NSUUID UUID] UUIDString];
                  NSXMLNode *pident
                    = [NSXMLNode attributeWithName: @"id"
                                       stringValue: pident_value];
                  NSXMLNode *psegueIdent
                    = [NSXMLNode attributeWithName: @"identifier"
                                       stringValue: identifier];
                  NSXMLNode *psender
                    = [NSXMLNode attributeWithName: @"sender"
                                       stringValue: src];
                  NSXMLNode *pkind
                    = [NSXMLNode attributeWithName: @"kind"
                                       stringValue: kind];
                  
                  [sbproxy addAttribute: pselector];
                  [sbproxy addAttribute: ptarget];
                  [sbproxy addAttribute: pident];
                  [sbproxy addAttribute: psegueIdent];
                  [sbproxy addAttribute: psender];
                  [sbproxy addAttribute: pkind];
                  NSUInteger count = [[objects children] count];
                  [objects insertChild: sbproxy
                               atIndex: count - 1];
                  
                  // add action to parent ONLY if it is NOT a controller..
                  if (![segue_parent_parent_name isEqualToString: @"windowController"] &&
                      ![segue_parent_parent_name isEqualToString: @"viewController"])
                    {              
                      // Create action...
                      NSXMLElement *action = [NSXMLElement elementWithName: @"action"];
                      NSXMLNode *selector
                        = [NSXMLNode attributeWithName: @"selector"
                                           stringValue: @"doAction:"];
                      NSXMLNode *target
                        = [NSXMLNode attributeWithName: @"target"
                                           stringValue: pident_value];
                      NSXMLNode *ident
                        = [NSXMLNode attributeWithName: @"id"
                                           stringValue: uid]; 
                      [action addAttribute: selector];
                      [action addAttribute: target];
                      [action addAttribute: ident];
                      [segue_parent addChild: action];
                    }
                  
                  // Create the segue...
                  NSStoryboardSegue *ss = [[NSStoryboardSegue alloc] initWithIdentifier: identifier
                                                                                 source: src
                                                                            destination: dst];
                  [ss _setKind: kind];
                  [ss _setRelationship: rel];
                  
                  // Add to maptable...
                  [mapTable setObject: ss
                               forKey: identifier];
                  
                } // only process segue objects...
            } // iterate over objects in each set of connections
        } // iterate over connection objs

      // Add to cache...
      [_documentsMap setObject: mapTable
                        forKey: uuidString];
      
    }  // if connections > 0
  return mapTable;
}

// Private instance methods...
- (id) initWithName: (NSStoryboardName)name
             bundle: (NSBundle *)bundle
{
  self = [super init];
  if (self != nil)
    {
      NSString *path = [bundle pathForResource: name
                                        ofType: @"storyboard"];
      NSData *data = [NSData dataWithContentsOfFile: path];
      
      NSXMLDocument *storyboardXml = [[NSXMLDocument alloc] initWithData: data
                                                                 options: 0
                                                                   error: NULL];
      [self _processStoryboard: storyboardXml];
      RELEASE(storyboardXml);
    }
  return self;
}

// Class methods...
+ (void) _setMainStoryboard: (NSStoryboard *)storyboard  // private, only called from NSApplicationMain()
{
  if (__mainStoryboard == nil)
    {
      ASSIGN(__mainStoryboard, storyboard);
    }
}

+ (NSStoryboard *) mainStoryboard // 10.13
{
  return __mainStoryboard;
}

+ (instancetype) storyboardWithName: (NSStoryboardName)name
                             bundle: (NSBundle *)bundle
{
  return AUTORELEASE([[NSStoryboard alloc] initWithName: name
                                                 bundle: bundle]);
}

// Instance methods...
- (void) dealloc
{
  RELEASE(_initialViewControllerId);
  RELEASE(_applicationSceneId);
  RELEASE(_scenesMap);
  RELEASE(_controllerMap);
  RELEASE(_documentsMap);
  [super dealloc];
}

- (void) _instantiateApplicationScene
{
  NSDictionary	*table;

  table = [NSDictionary dictionaryWithObject: NSApp
                                      forKey: NSNibOwner];

  NSXMLDocument *xml = [_scenesMap objectForKey: _applicationSceneId];
  NSData *xmlData = [xml XMLData];
  GSModelLoader *loader = [GSModelLoaderFactory modelLoaderForFileType: @"xib"];
  BOOL success = [loader loadModelData: xmlData
                     externalNameTable: table
                              withZone: [self zone]];
  if (!success)
    {
      NSLog(@"Unabled to load Application scene");
    }
}

- (id) instantiateInitialController
{
  return [self instantiateControllerWithIdentifier: _initialViewControllerId];
}

- (id) instantiateInitialControllerWithCreator: (NSStoryboardControllerCreator)block // 10.15
{
  id controller = [self instantiateInitialController];
  CALL_BLOCK(block, self);
  return controller;
}

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier
{
  id result = nil;
  NSMutableArray *topLevelObjects = [NSMutableArray arrayWithCapacity: 5];
  NSDictionary *table = [NSDictionary dictionaryWithObjectsAndKeys: topLevelObjects,
                                      NSNibTopLevelObjects,
                                      NSApp,
                                      NSNibOwner,
                                      nil];
  NSString *sceneId = [_controllerMap objectForKey: identifier];
  NSXMLDocument *xml = [[_scenesMap objectForKey: sceneId] copy];
  NSMapTable *segueMap = [self _processSegues: xml];
  NSData *xmlData = [xml XMLData];
  GSModelLoader *loader = [GSModelLoaderFactory modelLoaderForFileType: @"xib"];
  BOOL  success = [loader loadModelData: xmlData
                      externalNameTable: table
                               withZone: [self zone]];
    
  if (success)
    {
      NSMutableArray *seguesToPerform = [NSMutableArray array];
      NSMutableArray *placeholders = [NSMutableArray array];
      NSWindowController *wc = nil;
      NSViewController *vc = nil;
      NSWindow *w = nil;
      NSEnumerator *en = [topLevelObjects objectEnumerator];
      id o = nil;
      
      while ((o = [en nextObject]) != nil)
        {
          if ([o isKindOfClass: [NSWindowController class]])
            {
              wc = (NSWindowController *)o;
              [wc _setSegueMap: segueMap];
              [wc _setTopLevelObjects: topLevelObjects];
              [wc _setStoryboard: self];
              [wc _setOwner: NSApp];
              result = o;
            }
          else if ([o isKindOfClass: [NSViewController class]])
            {
              vc = (NSViewController *)o;
              [vc _setSegueMap: segueMap];
              [vc _setTopLevelObjects: topLevelObjects];
              [vc _setStoryboard: self];
              result = o;
            }
          else if ([o isKindOfClass: [NSWindow class]])
            {
              w = (NSWindow *)o;
            }
          else if ([o isKindOfClass: [NSControllerPlaceholder class]])
            {
              [placeholders addObject: o];
            }             
        }

      // Process action proxies after so we know we have the windowController...
      en = [topLevelObjects objectEnumerator];
      o = nil;
      while ((o = [en nextObject]) != nil)
        {
          if ([o isKindOfClass: [NSStoryboardSeguePerformAction class]])
            {
              NSStoryboardSeguePerformAction *ssa = (NSStoryboardSeguePerformAction *)o;
              [ssa setSender: result]; // resolve controller here...
              if ([[ssa kind] isEqualToString: @"relationship"]) // if it is a relationship, perform immediately
                {
                  [seguesToPerform addObject: ssa];
                }
            }
        }

      // Depending on which kind of controller we have, do the correct thing....
      if (w != nil && wc != nil)
        {
          [wc setWindow: w];
        }
          
      // perform segues after all is initialized.
      en = [seguesToPerform objectEnumerator];
      o = nil;
      while ((o = [en nextObject]) != nil)
        {
          NSStoryboardSeguePerformAction *ssa = (NSStoryboardSeguePerformAction *)o;
          [ssa doAction: result];  // this will, as far as I know, only happen with window controllers, to set content.
        }

      en = [placeholders objectEnumerator];
      o = nil;
      while ((o = [en nextObject]) != nil)
        {
          NSControllerPlaceholder *ph = (NSControllerPlaceholder *)o;
          result = [ph instantiate];
        }
    }
  else
    {
      NSLog(@"Couldn't load controller scene id = %@", sceneId);
    }
  
  return result;
}

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier
                                   creator: (NSStoryboardControllerCreator)block  // 10.15
{
  id controller = [self instantiateControllerWithIdentifier: identifier];
  CALL_BLOCK(block, self);
  return controller;
}
@end

