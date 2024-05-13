/* Implementation of class GSScene
   Copyright (C) 2024 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 12-05-2024

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSKeyedArchiver.h>

#import "GSScene.h"

@implementation GSScene

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _sceneID = nil;
      _objects = nil;
      _canvasLocation = NSMakePoint(0.0, 0.0);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_sceneID);
  RELEASE(_objects);
  [super dealloc];
}

- (NSString *) sceneID
{
  return _sceneID;
}

- (void) setSceneID: (NSString *)sceneID
{
  ASSIGN(_sceneID, sceneID);
}

- (NSMutableArray *) objects
{
  return _objects;
}

- (void) setObjects: (NSMutableArray *)objects
{
  ASSIGN(_objects, objects);
}

- (NSPoint) canvasLocation
{
  return _canvasLocation;
}

- (void) setCanvasLocation: (NSPoint)point
{
  _canvasLocation = point;
}

// NSCoding

- (instancetype) initWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSSceneID"])
	{
	  [self setSceneID: [coder decodeObjectForKey: @"NSSceneID"]];
	}

      if ([coder containsValueForKey: @"NSObjects"])
	{
	  [self setObjects: [coder decodeObjectForKey: @"NSObjects"]];
	}

      if ([coder containsValueForKey: @"NSCanvasLocation"])
	{
	  [self setCanvasLocation: [coder decodePointForKey: @"NSCanvasLocation"]];
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}

// NSCopying

- (id) copyWithZone: (NSZone *)zone
{
  GSScene *scene = [[GSScene allocWithZone: zone] init];

  [scene setSceneID: [self sceneID]];
  [scene setObjects: [self objects]];
  [scene setCanvasLocation: [self canvasLocation]];

  return scene;
}

@end

