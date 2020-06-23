/* Implementation of class NSStoryboard
   Copyright (C) 2019 Free Software Foundation, Inc.
   
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

#import "AppKit/NSApplication.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSStoryboard.h"
#import "AppKit/NSWindowController.h"
#import "AppKit/NSViewController.h"
#import "AppKit/NSWindow.h"

#import "GNUstepGUI/GSModelLoaderFactory.h"

static NSStoryboard *mainStoryboard = nil;

@implementation NSStoryboard

- (void) _processStoryboard: (NSXMLDocument *)storyboardXml
{
  NSArray *docNodes = [storyboardXml nodesForXPath: @"document" error: NULL];

  if ([docNodes count] > 0)
    {
      NSXMLElement *docNode = [docNodes objectAtIndex: 0];
      NSArray *array = [docNode nodesForXPath: @"//scene" error: NULL];
      NSEnumerator *en = [array objectEnumerator];
      NSXMLElement *e = nil;  
      NSString *customClassString = nil;
      
      // Set initial view controller...
      ASSIGN(_initialViewControllerId, [[docNode attributeForName: @"initialViewController"] stringValue]);             
      _scenesMap = [[NSMutableDictionary alloc] initWithCapacity: [array count]];
      _controllerMap = [[NSMutableDictionary alloc] initWithCapacity: [array count]];

      while ((e = [en nextObject]) != nil)
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
              if ([[appNode name] isEqualToString: @"application"] == YES)
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
                  NSXMLNode *appCustomClass = (NSXMLNode *)[(NSXMLElement *)appNode attributeForName: @"customClass"];
                  customClassString = ([appCustomClass stringValue] == nil) ?
                    @"NSApplication" :  [appCustomClass stringValue];
                  NSXMLElement *customObject = [[NSXMLElement alloc] initWithName: @"customObject"];
                  NSXMLNode *idValue   = [NSXMLNode attributeWithName: @"id"
                                                          stringValue: @"-3"];
                  NSXMLNode *usrLabel  = [NSXMLNode attributeWithName: @"userLabel"
                                                          stringValue: @"File's Owner"];
                  NSXMLNode *customCls = [NSXMLNode attributeWithName: @"customClass"
                                                          stringValue: customClassString];
                  [customObject addAttribute: idValue];
                  [customObject addAttribute: usrLabel];
                  [customObject addAttribute: customCls];

                  if (appCons != nil)
                    {
                      [customObject addChild: appCons];
                    }

                  // Add it to the document
                  [objects addChild: customObject];
                  [objects detach];
                  [doc addChild: objects];
                  RELEASE(customObject);
                  
                  // Assign application scene...
                  ASSIGN(_applicationSceneId, sceneId);
                }
              else
                {
                  NSXMLElement *customObject = [[NSXMLElement alloc] initWithName: @"customObject"];
                  NSXMLNode *idValue   = [NSXMLNode attributeWithName: @"id"
                                                          stringValue: @"-3"];
                  NSXMLNode *usrLabel  = [NSXMLNode attributeWithName: @"userLabel"
                                                          stringValue: @"File's Owner"];
                  NSXMLNode *customCls = [NSXMLNode attributeWithName: @"customClass"
                                                          stringValue: customClassString];
                  [customObject addAttribute: idValue];
                  [customObject addAttribute: usrLabel];
                  [customObject addAttribute: customCls];

                  [child detach];
                  [child addChild: customObject];
                  [doc addChild: child];
                }

              // fix other custom objects
              document = [[NSXMLDocument alloc] initWithRootElement: doc]; // put it into the document, so we can use Xpath.
              NSArray *windowControllers = [document nodesForXPath: @"//windowController" error: NULL];
              NSArray *viewControllers = [document nodesForXPath: @"//viewController" error: NULL];
          
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
    }
  else
    {
      NSLog(@"No document element in storyboard file");
    }
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
+ (void) setMainStoryboard: (NSStoryboard *)storyboard  // private, only called from NSApplicationMain()
{
  mainStoryboard = storyboard;
}

+ (NSStoryboard *) mainStoryboard // 10.13
{
  return mainStoryboard;
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
  [super dealloc];
}

- (id) instantiateInitialController
{
  id controller = nil;
  NSDictionary	*table;

  table = [NSDictionary dictionaryWithObject: NSApp
                                      forKey: NSNibOwner];

  NSXMLDocument *xml = [_scenesMap objectForKey: _applicationSceneId];
  NSData *xmlData = [xml XMLData];
  GSModelLoader *loader = [GSModelLoaderFactory modelLoaderForFileType: @"xib"];
  BOOL success = [loader loadModelData: xmlData
                     externalNameTable: table
                              withZone: [self zone]];

  if (success)
    {
      NSMutableArray *topLevelObjects = [NSMutableArray arrayWithCapacity: 5];
      NSDictionary *table = [NSDictionary dictionaryWithObjectsAndKeys: topLevelObjects,
                                          NSNibTopLevelObjects,
                                          NSApp,
                                          NSNibOwner,
                                          nil];
      NSString *initialSceneId = [_controllerMap objectForKey: _initialViewControllerId];
      xml = [_scenesMap objectForKey: initialSceneId];
      xmlData = [xml XMLData];
      loader = [GSModelLoaderFactory modelLoaderForFileType: @"xib"];
      success = [loader loadModelData: xmlData
                    externalNameTable: table
                             withZone: [self zone]];
      NSLog(@"table = %@", table);
      
      if (success)
        {
          NSEnumerator *en = [topLevelObjects objectEnumerator];
          id o = nil;
          while ((o = [en nextObject]) != nil)
            {
              if ([o isKindOfClass: [NSWindowController class]])
                {
                  controller = o;
                }
              if ([o isKindOfClass: [NSWindow class]] &&
                  [controller isKindOfClass: [NSWindowController class]])
                {
                  [controller setWindow: o];
                  [controller showWindow: self];
                }              
              else if ([o isKindOfClass: [NSViewController class]])
                {
                }
            }
        }
      else
        {
          NSLog(@"Couldn't load initial controller scene");
        }
    }
  else
    {
      NSLog(@"Couldn't load application scene.");
    }
  
  return controller;
}

- (id) instantiateInitialControllerWithCreator: (NSStoryboardControllerCreator)block // 10.15
{
  return nil;
}

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier
{
  return nil;
}

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier
                                   creator: (NSStoryboardControllerCreator)block  // 10.15
{
  return nil;
}
@end

