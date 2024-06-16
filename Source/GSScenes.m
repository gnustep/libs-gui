/* Implementation of class GSScenes
   Copyright (C) 2024 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 18-05-2024

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

#import "GSScenes.h"

@implementation GSScenes

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _scenes = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_scenes);
  [super dealloc];
}

- (NSMutableArray *)scenes
{
  return _scenes;
}

- (void) setScenes: (NSMutableArray *)scenes
{
  ASSIGN(_scenes, scenes);
}

- (id) initWithCoder: (NSCoder *)coder
{
  NSLog(@"GSScenes...");
  if ([coder allowsKeyedCoding] == YES)
    {
      if ([coder containsValueForKey: @"GSScenes"])
	{
	  [self setScenes: [coder decodeObjectForKey: @"GSScenes"]];
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}

- (id) copyWithZone: (NSZone *)zone
{
  GSScenes *scenes = [[GSScenes allocWithZone: zone] init];

  [scenes setScenes: [[self scenes] copyWithZone: zone]];

  return scenes;
}

@end

