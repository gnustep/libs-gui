/* 
   NSColorList.h

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

#ifndef _GNUstep_H_NSColorList
#define _GNUstep_H_NSColorList

#include <Foundation/NSCoder.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;

@class NSColor;

@interface NSColorList : NSObject <NSCoding>

{
  // Attributes
  NSString *list_name;
  NSString *file_name;
  NSMutableDictionary *color_list;
  NSMutableArray *color_list_keys;
  BOOL is_editable;
}

//
// Initializing an NSColorList
//
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name
	  fromFile:(NSString *)path;

//
// Getting All Color Lists
//
+ (NSArray *)availableColorLists;

//
// Getting a Color List by Name
//
+ (NSColorList *)colorListNamed:(NSString *)name;
- (NSString *)name;

//
// Managing Colors by Key
//
- (NSArray *)allKeys;
- (NSColor *)colorWithKey:(NSString *)key;
- (void)insertColor:(NSColor *)color
		key:(NSString *)key
	    atIndex:(unsigned)location;
- (void)removeColorWithKey:(NSString *)key;
- (void)setColor:(NSColor *)aColor
	  forKey:(NSString *)key;

//
// Editing
//
- (BOOL)isEditable;

//
// Writing and Removing Files
//
- (BOOL)writeToFile:(NSString *)path;
- (void)removeFile;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

/* Notifications */
extern NSString *NSColorListChangedNotification;

#endif // _GNUstep_H_NSColorList
