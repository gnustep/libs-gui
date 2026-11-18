/* Private storyboard archive and instantiation support.
   Copyright (C) 2026 Free Software Foundation, Inc.
   Distributed under the GNU LGPL, version 2.1 or later. */
#ifndef _GSStoryboardArchive_h
#define _GSStoryboardArchive_h

#import <Foundation/Foundation.h>
#import "AppKit/NSStoryboard.h"
#import "AppKit/NSStoryboardSegue.h"

@class GSXibElement;

@interface GSStoryboardArchive : NSObject <NSXMLParserDelegate>
{
  GSXibElement *_document;
  NSMutableArray *_parseStack;
  NSMutableDictionary *_scenes;
  NSMutableDictionary *_identifiers;
  NSMutableSet *_loading;
  NSArray *_applicationObjects;
  NSMapTable *_applicationSegues;
  NSBundle *_bundle;
  NSString *_initialID;
  NSString *_applicationID;
}
- (id) initWithData: (NSData *)data bundle: (NSBundle *)bundle;
- (NSString *) initialControllerID;
- (NSString *) applicationControllerID;
- (id) instantiateIdentifier: (NSString *)identifier
                 storyboard: (NSStoryboard *)storyboard
                    creator: (NSStoryboardControllerCreator)creator;
- (id) instantiateControllerID: (NSString *)identifier
                   storyboard: (NSStoryboard *)storyboard
                      creator: (NSStoryboardControllerCreator)creator;
@end

@interface NSStoryboard (GSInstantiation)
- (id) _instantiateControllerWithID: (NSString *)identifier;
@end

@interface NSStoryboardSegue (GSStoryboardPrivate)
- (void) _setKind: (NSString *)kind;
- (void) _setRelationship: (NSString *)relationship;
- (void) _setPopoverAnchorView: (id)view;
- (void) _setPopoverBehavior: (NSPopoverBehavior)behavior;
- (void) _setPreferredEdge: (NSRectEdge)edge;
@end

/* The controllers' private maps own these bindings.  Bindings never own their
 * source controller; each performance creates a new runtime segue. */
@interface GSStoryboardSegueAction : NSObject
{
  NSDictionary *_definition;
  NSStoryboard *_storyboard;
  id _source;
  id _anchor;
  id _relationshipDestination;
}
- (id) initWithDefinition: (NSDictionary *)definition
              storyboard: (NSStoryboard *)storyboard source: (id)source
                  anchor: (id)anchor;
- (void) doAction: (id)sender;
- (void) performWithSender: (id)sender;
@end

#endif
