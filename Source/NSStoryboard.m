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
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSStoryboard.h"
#import "AppKit/NSWindowController.h"
#import "AppKit/NSViewController.h"
#import "AppKit/NSWindow.h"

#import "GSStoryboardArchive.h"

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

@implementation NSWindowController (__StoryboardPrivate__)
- (void) _setOwner: (id)owner
{
  _owner = owner; // weak
}

- (void) _setTopLevelObjects: (NSArray *)array
{
  // Match the nib ownership convention used by the controller's dealloc.
  // The scene's primary controller is deliberately excluded from this array.
  [array makeObjectsPerformSelector: @selector(retain)];
  [_top_level_objects makeObjectsPerformSelector: @selector(release)];
  ASSIGN(_top_level_objects, array);
}

- (void) _setSegueMap: (NSMapTable *)map
{
  ASSIGN(_segueMap, map);
}

- (void) _setStoryboard: (NSStoryboard *)storyboard
{
  ASSIGN(_storyboard, storyboard);
}
@end

@implementation NSViewController (__StoryboardPrivate__)

- (void) _setTopLevelObjects: (NSArray *)array
{
  // Match the nib ownership convention used by the controller's dealloc.
  // The scene's primary controller is deliberately excluded from this array.
  [array makeObjectsPerformSelector: @selector(retain)];
  [_topLevelObjects makeObjectsPerformSelector: @selector(release)];
  ASSIGN(_topLevelObjects, array);
}

- (void) _setSegueMap: (NSMapTable *)map
{
  ASSIGN(_segueMap, map);
}

- (void) _setStoryboard: (NSStoryboard *)storyboard
{
  ASSIGN(_storyboard, storyboard);
}
@end
// end private methods...

@implementation NSStoryboard

- (id) initWithName: (NSStoryboardName)name bundle: (NSBundle *)bundle
{
  if ((self = [super init]) != nil)
    {
      NSString *path;
      bundle = bundle ?: [NSBundle mainBundle];
      @try
        {
          path = name ? [bundle pathForResource: name ofType: @"storyboard"] : nil;
          if (path == nil)
            [NSException raise: NSInvalidArgumentException
                        format: @"Cannot find storyboard %@ in %@", name, bundle];
          _transform = [[GSStoryboardArchive alloc]
            initWithData: [NSData dataWithContentsOfFile: path] bundle: bundle];
        }
      @catch (id exception)
        {
          RELEASE(self);
          @throw;
        }
    }
  return self;
}

+ (void) _setMainStoryboard: (NSStoryboard *)storyboard
{
  if (__mainStoryboard == nil)
    ASSIGN(__mainStoryboard, storyboard);
}

+ (NSStoryboard *) mainStoryboard { return __mainStoryboard; }

+ (instancetype) storyboardWithName: (NSStoryboardName)name bundle: (NSBundle *)bundle
{
  return AUTORELEASE([[self alloc] initWithName: name bundle: bundle]);
}

- (void) dealloc
{
  RELEASE(_transform);
  [super dealloc];
}

- (void) _instantiateApplicationScene
{
  NSString *identifier = [_transform applicationControllerID];
  if (identifier != nil)
    [self _instantiateControllerWithID: identifier];
}

- (id) _instantiateControllerWithID: (NSString *)identifier
{
  return [_transform instantiateControllerID: identifier storyboard: self creator: NULL];
}

- (id) instantiateInitialController
{
  return [self instantiateInitialControllerWithCreator: NULL];
}

- (id) instantiateInitialControllerWithCreator: (NSStoryboardControllerCreator)creator
{
  NSString *identifier = [_transform initialControllerID];
  if (identifier == nil)
    return nil;
  return [_transform instantiateControllerID: identifier storyboard: self creator: creator];
}

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier
{
  return [self instantiateControllerWithIdentifier: identifier creator: NULL];
}

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier
                                   creator: (NSStoryboardControllerCreator)creator
{
  return [_transform instantiateIdentifier: identifier storyboard: self creator: creator];
}
@end
