/* 
   NSColorList.m

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

#include <gnustep/gui/NSColorList.h>

// NSColorList notifications
NSString *NSColorListChangedNotification;

@implementation NSColorList

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorList class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Getting All Color Lists
//
+ (NSArray *)availableColorLists
{
  return nil;
}

//
// Getting a Color List by Name
//
+ (NSColorList *)colorListNamed:(NSString *)name
{
  return nil;
}

//
// Instance methods
//
//
// Initializing an NSColorList
//
- (id)initWithName:(NSString *)name
{
  return nil;
}

- (id)initWithName:(NSString *)name
	  fromFile:(NSString *)path
{
  return nil;
}

//
// Getting a Color List by Name
//
- (NSString *)name
{
  return nil;
}

//
// Managing Colors by Key
//
- (NSArray *)allKeys
{
  return nil;
}

- (NSColor *)colorWithKey:(NSString *)key
{
  return nil;
}

- (void)insertColor:(NSColor *)color
		key:(NSString *)key
atIndex:(unsigned)location
{}

- (void)removeColorWithKey:(NSString *)key
{}

- (void)setColor:(NSColor *)aColor
	  forKey:(NSString *)key
{}

//
// Editing
//
- (BOOL)isEditable
{
  return NO;
}

//
// Writing and Removing Files
//
- (BOOL)writeToFile:(NSString *)path
{
  return NO;
}

- (void)removeFile
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
