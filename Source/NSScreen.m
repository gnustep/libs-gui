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
	if (!mainScreen)
		mainScreen = [[NSScreen alloc] init];

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
- init
{
	[super init];				// Create our device description dictionary
								// The backend will have to fill the dictionary
	device_desc = [NSMutableDictionary dictionary];

	return self;
}

//
// Reading Screen Information
//
- (NSWindowDepth)depth
{
	return 0;
}

- (NSRect)frame
{
	return NSZeroRect;
}

- (NSDictionary *)deviceDescription					// Make a copy of device 
{													// dictionary and return it
NSDictionary *d = [[NSDictionary alloc] initWithDictionary: device_desc];

	return d;
}

@end
