/* 
   NSColorList.m

   Manage named lists of NSColors.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: January 2000
   
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
#include <Foundation/NSNotification.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>

#include <AppKit/NSColorList.h>
#include <AppKit/NSColor.h>
#include <AppKit/AppKitExceptions.h>

// The list of available color lists is created only once -- this has
// a drawback, that you need to restart your program to get the color
// lists read again.
static NSMutableArray *_gnustep_available_color_lists;
static NSLock *_gnustep_color_list_lock;

@implementation NSColorList

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorList class])
    {
      // Initial version
      [self setVersion:2];

      // Initialize the global array of color lists
      _gnustep_available_color_lists = [[NSMutableArray alloc] init];

      /*** TODO: Load color lists in the array !! [fairly easy]***/
      // Sorry, I [NP] am asleep now -- going to work on this tomorrow.

      // And its access lock
      _gnustep_color_list_lock = [[NSLock alloc] init];
    }
}

//
// Getting All Color Lists
//
+ (NSArray *)availableColorLists
{
  NSArray *a;

  // Serialize access to color list
  [_gnustep_color_list_lock lock];

  a =  [NSArray arrayWithArray: _gnustep_available_color_lists];

  [_gnustep_color_list_lock unlock];

  return a;
}

//
// Getting a Color List by Name
//
+ (NSColorList *)colorListNamed:(NSString *)name
{
  NSColorList*  r;
  NSEnumerator* e;
  BOOL          found = NO;

  // Serialize access to color list
  [_gnustep_color_list_lock lock];

  e = [_gnustep_available_color_lists objectEnumerator];
  
  while ((r = (NSColorList *)[e nextObject])) 
    {
      if ([[r name] isEqualToString: name])
	{
	  found = YES;
	  break;
	}
    }
  
  [_gnustep_color_list_lock unlock];

  if (found)
    return r;
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
  return [self initWithName: name
	       fromFile: nil];
}

- (id)initWithName:(NSString *)name
	  fromFile:(NSString *)path
{
  NSColorList* cl;
  BOOL         could_load = NO; 

  ASSIGN (_name, name);

  if (path)
    {
      ASSIGN (_fullFileName, [[path stringByAppendingPathComponent: name] 
			       stringByAppendingPathExtension: @"clr"]);
  
      // Unarchive the color list
      
      // TODO: Unarchive from other formats as well?
      
      cl = (NSColorList*)[NSUnarchiver unarchiveObjectWithFile: _fullFileName];
      
      if (cl && [cl isKindOfClass: [NSColorList class]])
	{
	  could_load = YES;

	  _is_editable = [[NSFileManager defaultManager] 
			   isWritableFileAtPath: _fullFileName];
	  
	  if (_is_editable)
	    {
	      _colorDictionary = [NSMutableDictionary dictionaryWithDictionary: 
							cl->_colorDictionary];
	      _orderedColorKeys = [NSMutableArray arrayWithArray: 
						    cl->_orderedColorKeys];
	    }
	  else
	    {
	      _colorDictionary = [NSDictionary dictionaryWithDictionary: 
						 cl->_colorDictionary];
	      _orderedColorKeys = [NSArray arrayWithArray: 
					     cl->_orderedColorKeys];
	    }
	}	  
      [cl release];
    }
  
  if (could_load == NO)
    {
      _fullFileName = nil;
      _colorDictionary = [[NSMutableDictionary alloc] init];
      _orderedColorKeys = [[NSMutableArray alloc] init];
      _is_editable = YES;  
    }
  
  return self;
}

- (void)dealloc
{
  RELEASE (_name);
  TEST_RELEASE (_fullFileName);
  RELEASE (_colorDictionary);
  RELEASE (_orderedColorKeys);
  [super dealloc];
}

//
// Getting a Color List by Name
//
- (NSString *)name
{
  return _name;
}

//
// Managing Colors by Key
//
- (NSArray *)allKeys
{
  return [NSArray arrayWithArray: _orderedColorKeys];
}

- (NSColor *)colorWithKey:(NSString *)key
{
  return [_colorDictionary objectForKey: key];
}

- (void)insertColor:(NSColor *)color
		key:(NSString *)key
	    atIndex:(unsigned)location
{
  if (_is_editable == NO)
    [NSException raise: NSColorListNotEditableException
		 format: @"Color list cannot be edited\n"];

  [_colorDictionary setObject: color forKey: key];
  [_orderedColorKeys removeObject: key];
  [_orderedColorKeys insertObject: key atIndex: location];
  
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: NSColorListChangedNotification
    object: self];
}

- (void)removeColorWithKey:(NSString *)key
{
  if (_is_editable == NO)
    [NSException raise: NSColorListNotEditableException
		 format: @"Color list cannot be edited\n"];
  
  [_colorDictionary removeObjectForKey: key];
  [_orderedColorKeys removeObject: key];

  [[NSNotificationCenter defaultCenter] 
      postNotificationName: NSColorListChangedNotification
      object: self];
}

- (void)setColor:(NSColor *)aColor
	  forKey:(NSString *)key
{
  if (_is_editable == NO)
    [NSException raise: NSColorListNotEditableException
		 format: @"Color list cannot be edited\n"];
  
  [_colorDictionary setObject: aColor forKey: key];

  if ([_orderedColorKeys containsObject: key] == NO)
    [_orderedColorKeys addObject: key];

  [[NSNotificationCenter defaultCenter] 
      postNotificationName: NSColorListChangedNotification
      object: self];
}

//
// Editing
//
- (BOOL)isEditable
{
  return _is_editable;
}

//
// Writing and Removing Files
//
- (BOOL)writeToFile:(NSString *)path
{
  NSFileManager* fm = [NSFileManager defaultManager];
  BOOL           isDir;
  BOOL           success;

  if (path == nil || ([fm fileExistsAtPath: path isDirectory: &isDir] == NO))
    {
      // FIXME the standard path for saving color lists
      path = @"~/GNUstep/Library/Colors/"; 
      isDir = YES;
    }

  if (isDir)
    {
      ASSIGN (_fullFileName, [[path stringByAppendingPathComponent: _name] 
			       stringByAppendingPathExtension: @"clr"]);
    }
  else // it is a file
    {
      _fullFileName = path;
      if ([path pathExtension] == @"clr")
	{
	  ASSIGN (_fullFileName, path);
	}
      else
	{
	  ASSIGN (_fullFileName, [[path stringByDeletingPathExtension]
				   stringByAppendingPathExtension: @"clr"]);
	}
    }

  success = [NSArchiver archiveRootObject: self 
			toFile: _fullFileName];

  if (success)
    {
      [_gnustep_color_list_lock lock];
      [_gnustep_available_color_lists addObject: self];
      [_gnustep_color_list_lock unlock];      
      return YES;
    }
  
  return NO;
}

- (void)removeFile
{
  if (_fullFileName && _is_editable)
    {
      // Remove the file
      [[NSFileManager defaultManager] removeFileAtPath: _fullFileName
				      handler: nil];
      
      // Remove the color list from the global list of colors
      [_gnustep_color_list_lock lock];
      [_gnustep_available_color_lists removeObject: self];
      [_gnustep_color_list_lock unlock];

      // Reset file name
      _fullFileName = nil;
    }
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _name];
  [aCoder encodeObject: _colorDictionary];
  [aCoder encodeObject: _orderedColorKeys];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_editable];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_name];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_colorDictionary];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_orderedColorKeys];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_editable];

  return self;
}

@end

