/* 
   NSScreen.m

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSDictionary.h>
#include <AppKit/NSScreen.h>



@implementation NSScreen

//
// Class variables
//
NSScreen *mainScreen = nil;

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSScreen class])
		[self setVersion:1];
}

//
// Creating NSScreen Instances
//
+ (NSScreen *)mainScreen
{
  NSMutableDictionary *dict;
  
  if (mainScreen)
    return mainScreen; 
  
  dict = [NSMutableDictionary dictionary];
  [dict setObject: @"Main" forKey: @"NSScreenKeyName"];
  mainScreen = [[NSScreen alloc] initWithDeviceDescription: dict];
  return mainScreen;
}

+ (NSScreen *)deepestScreen
{
	return nil;
}

+ (NSArray *)screens
{
	return nil;
}

//
// Instance methods
//
- initWithDeviceDescription: (NSDictionary *)dict
{
  [super init];
  depth = 0;
  frame = NSZeroRect;
  if (dict)
    device_desc = [dict mutableCopy];
  else
    device_desc = [[NSMutableDictionary dictionary] retain];
  return self;
}

- init
{
  return [self initWithDeviceDescription: NULL];
}

//
// Reading Screen Information
//
- (NSWindowDepth)depth
{
	return depth;
}

- (NSRect)frame
{
	return frame;
}

- (NSDictionary *)deviceDescription					// Make a copy of device 
{													// dictionary and return it
NSDictionary *d = [[NSDictionary alloc] initWithDictionary: device_desc];

	return d;
}

@end
