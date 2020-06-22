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

#import "AppKit/NSStoryboard.h"
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
      
      // Set initial view controller...
      ASSIGN(_initialViewControllerId, [[docNode attributeForName: @"initialViewController"] stringValue]);             
      _scenesMap = [[NSMutableDictionary alloc] initWithCapacity: [array count]];

      while ((e = [en nextObject]) != nil)
        {
          NSXMLElement *doc = [[NSXMLElement alloc] initWithName: @"document"];
          NSArray *children = [e children];
          NSEnumerator *ce = [children objectEnumerator];
          NSXMLElement *child = nil;
          NSXMLDocument *document = nil;
          NSString *sceneId = [[e attributeForName: @"sceneID"] stringValue]; 
          
          // Copy children...
          while ((child = [ce nextObject]) != nil)
            {
              if ([[child name] isEqualToString: @"point"] == YES)
                continue; // go on if it's point, we don't use that in the app...
              
              NSArray *subnodes = [child nodesForXPath: @"//application" error: NULL];
              NSXMLNode *appNode = [subnodes objectAtIndex: 0];
              if ([[appNode name] isEqualToString: @"application"] == YES)
                {
                  NSXMLElement *objects = (NSXMLElement *)[appNode parent];// [[appNode children] objectAtIndex: 0];
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
                  
                  /*
                    <customObject id="-2" userLabel="File's Owner" customClass="NSApplication">
                      <connections>
                        <outlet property="delegate" destination="Voe-Tx-rLC" id="GzC-gU-4Uq"/>
                      </connections>
                    </customObject>
                  */
                  
                  // create a customObject entry for NSApplication reference...
                  NSXMLElement *customObject = [[NSXMLElement alloc] initWithName: @"customObject"];
                  NSXMLNode *idValue   = [NSXMLNode attributeWithName: @"id"
                                                          stringValue: @"-2"];
                  NSXMLNode *usrLabel  = [NSXMLNode attributeWithName: @"userLabel"
                                                          stringValue: @"File's Owner"];
                  NSXMLNode *customCls = [NSXMLNode attributeWithName: @"customClass"
                                                          stringValue: @"NSApplication"];
                  [customObject addAttribute: idValue];
                  [customObject addAttribute: usrLabel];
                  [customObject addAttribute: customCls];
                  
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
                  [child detach];
                  [doc addChild: child];
                }
              
              // Create document...
              document = [[NSXMLDocument alloc] initWithRootElement: doc];
              [_scenesMap setObject: document
                             forKey: sceneId];
              RELEASE(document);
            }
        }
    }
  else
    {
      NSLog(@"No document element in storyboard file");
    }

  NSLog(@"map = %@", _scenesMap);
  NSLog(@"initial = %@", _initialViewControllerId);
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
      AUTORELEASE(storyboardXml);

      [self _processStoryboard: storyboardXml];
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
  [super dealloc];
}

- (id) instantiateInitialController
{
  NSXMLDocument *xml = [_scenesMap objectForKey: _applicationSceneId];
  NSData *xmlData = [xml XMLData];
  GSModelLoader *loader = [GSModelLoaderFactory modelLoaderForFileType: @"xib"];
  BOOL success = [loader loadModelData: xmlData
                     externalNameTable: nil
                              withZone: [self zone]];

  if (success)
    {
      xml = [_scenesMap objectForKey: _applicationSceneId];
      xmlData = [xml XMLData];
      loader = [GSModelLoaderFactory modelLoaderForFileType: @"xib"];
      success = [loader loadModelData: xmlData
                    externalNameTable: nil
                             withZone: [self zone]];
      
      if (success == NO)
        {
          NSLog(@"Couldn't load initial view controller");
        }
    }
  else
    {
      NSLog(@"Couldn't load application scene.");
    }
  
  return nil;
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

