/* 
   NSColorList.m

   Manage named lists of NSColors.

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
#include <Foundation/NSNotification.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSException.h>

// NSColorList notifications
NSString *NSColorListChangedNotification = @"NSColorListChange";

// global variable
static NSMutableArray *gnustep_available_color_lists;
static NSLock *gnustep_color_list_lock;

@interface NSColorList (GNUstepPrivate)

- (void)setFileNameFromPath: (NSString *)path;
- (NSDictionary *)colorListDictionary;

@end

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

      // Initialize the global array of color lists
      gnustep_available_color_lists = [NSMutableArray array];
      // And its access lock
      gnustep_color_list_lock = [[NSLock alloc] init];
    }
}

//
// Getting All Color Lists
//
+ (NSArray *)availableColorLists
{
  NSArray *a;

  // Serialize access to color list
  [gnustep_color_list_lock lock];
  a =  [[[NSArray alloc] initWithArray: gnustep_available_color_lists]
	   autorelease];
  [gnustep_color_list_lock unlock];

  return a;
}

//
// Getting a Color List by Name
//
+ (NSColorList *)colorListNamed:(NSString *)name
{
  id o, e;
  BOOL found = NO;

  // Serialize access to color list
  [gnustep_color_list_lock lock];
  e = [gnustep_available_color_lists objectEnumerator];
  o = [e nextObject];
  while ((o) && (!found))
    {
      if ([name compare: [o name]] == NSOrderedSame)
	found = YES;
      else
	o = [e nextObject];
    }
  [gnustep_color_list_lock unlock];

  if (found)
    return o;
  else
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
  [super init];

  // Initialize instance variables
  list_name = name;
  [list_name retain];
  color_list = [NSMutableDictionary dictionary];
  [color_list retain];
  color_list_keys = [NSMutableArray array];
  [color_list_keys retain];
  is_editable = YES;
  file_name = @"";

  // Add to global list of colors
  [gnustep_color_list_lock lock];
  [gnustep_available_color_lists addObject: self];
  [gnustep_color_list_lock unlock];

  return self;
}

- (id)initWithName:(NSString *)name
	  fromFile:(NSString *)path
{
  id cl;

  [super init];

  // Initialize instance variables
  list_name = name;
  [list_name retain];
  [self setFileNameFromPath: path];

  // Unarchive the color list
  cl = [NSUnarchiver unarchiveObjectWithFile: file_name];

  // Copy the color list elements to self
  is_editable = [cl isEditable];
  color_list = [NSMutableDictionary alloc];
  [color_list initWithDictionary: [cl colorListDictionary]];
  color_list_keys = [NSMutableArray alloc];
  [color_list_keys initWithArray: [cl allKeys]];

  [cl release];

  // Add to global list of colors
  [gnustep_color_list_lock lock];
  [gnustep_available_color_lists addObject: self];
  [gnustep_color_list_lock unlock];

  return self;
}

- (void)dealloc
{
  [list_name release];
  [color_list release];
  [color_list_keys release];
  [super dealloc];
}

//
// Getting a Color List by Name
//
- (NSString *)name
{
  return list_name;
}

//
// Managing Colors by Key
//
- (NSArray *)allKeys
{
  return [[[NSArray alloc] initWithArray: color_list_keys]
	     autorelease];
}

- (NSColor *)colorWithKey:(NSString *)key
{
  return [color_list objectForKey: key];
}

- (void)insertColor:(NSColor *)color
		key:(NSString *)key
	    atIndex:(unsigned)location
{
  // Are we even editable?
  if (!is_editable)
    [NSException raise: NSColorListNotEditableException
		 format: @"Color list cannot be edited\n"];

  // add color
  [color_list setObject: color forKey: key];
  [color_list_keys removeObject: key];
  [color_list_keys insertObject: key atIndex: location];

  // post notification
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: NSColorListChangedNotification
      object: self];
}

- (void)removeColorWithKey:(NSString *)key
{
  // Are we even editable?
  if (!is_editable)
    [NSException raise: NSColorListNotEditableException
		 format: @"Color list cannot be edited\n"];

  [color_list removeObjectForKey: key];
  [color_list_keys removeObject: key];

  // post notification
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: NSColorListChangedNotification
      object: self];
}

- (void)setColor:(NSColor *)aColor
	  forKey:(NSString *)key
{
  // Are we even editable?
  if (!is_editable)
    [NSException raise: NSColorListNotEditableException
		 format: @"Color list cannot be edited\n"];

  [color_list setObject: aColor forKey: key];

  // Add to list if doesn't already exist
  if (![color_list_keys containsObject: key])
    [color_list_keys addObject: key];

  // post notification
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: NSColorListChangedNotification
      object: self];
}

//
// Editing
//
- (BOOL)isEditable
{
  return is_editable;
}

//
// Writing and Removing Files
//
- (BOOL)writeToFile:(NSString *)path
{
  [self setFileNameFromPath: path];

  // Archive to the file
  return [NSArchiver archiveRootObject: self toFile: file_name];
}

- (void)removeFile
{
  // xxx Tell NSWorkspace to remove the file

  // Remove from global list of colors
  [gnustep_color_list_lock lock];
  [gnustep_available_color_lists removeObject: self];
  [gnustep_color_list_lock unlock];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject: list_name];
  [aCoder encodeObject: color_list];
  [aCoder encodeObject: color_list_keys];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_editable];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];
  list_name = [aDecoder decodeObject];
  color_list = [aDecoder decodeObject];
  color_list_keys = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_editable];

  return self;
}

@end

@implementation NSColorList (GNUstepPrivate)

- (void)setFileNameFromPath: (NSString *)path
{
  NSMutableString *s = [NSMutableString stringWithCString: ""];

  // Construct filename
  // xxx Need to determine if path already contains filename
  [s appendString: path];
  [s appendString: @"/"];
  [s appendString: list_name];
  [s appendString: @".clr"];
  file_name = s;
}

- (NSDictionary *)colorListDictionary
{
  return color_list;
}

@end
