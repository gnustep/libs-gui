/** <title>NSColorList</title>

   <abstract>Manage named lists of NSColors.</abstract>

   Copyright (C) 1996, 2000 Free Software Foundation, Inc.

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

#include "gnustep/gui/config.h"
#include <Foundation/NSNotification.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSString.h>

#include "AppKit/NSColorList.h"
#include "AppKit/NSColor.h"
#include "AppKit/AppKitExceptions.h"

// The list of available color lists is created only once -- this has
// a drawback, that you need to restart your program to get the color
// lists read again.
static NSMutableArray *_gnustep_available_color_lists = nil;
static NSLock *_gnustep_color_list_lock = nil;

@implementation NSColorList

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorList class])
    {
      [self setVersion: 2];
    }
}

/*
 * Private Method which loads the color lists. 
 * Invoke if _gnustep_available_color_lists == nil 
 * before any operation with that object or its lock.
 *
 * The aim is to defer reading the available color lists 
 * till we really need to, so that only programs which really use 
 * this feature get the overhead.
 */
+ (void) _loadAvailableColorLists
{
  NSString		*dir;
  NSString		*file;
  NSEnumerator		*e;
  NSFileManager		*fm = [NSFileManager defaultManager];
  NSDirectoryEnumerator	*de;
  NSColorList		*newList;

  // Create the global array of color lists
  _gnustep_available_color_lists = [[NSMutableArray alloc] init];
  
  /*
   * Load color lists found in standard paths into the array
   * FIXME: Check exactly where in the directory tree we should scan.
   */
  e = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
    NSAllDomainsMask, YES) objectEnumerator];

  while ((dir = (NSString *)[e nextObject])) 
    {
      BOOL flag;

      dir = [dir stringByAppendingPathComponent: @"Colors"];
      if (![fm fileExistsAtPath: dir isDirectory: &flag] || !flag)
        {
	  // Only process existing directories
	  continue;
	}

      de = [fm enumeratorAtPath: dir];
      while ((file = [de nextObject])) 
	{
	  if ([[file pathExtension] isEqualToString: @"clr"])
	    {
	      file = [file stringByDeletingPathExtension];
	      newList = [[NSColorList alloc] initWithName: file
					     fromFile: dir];
	      [_gnustep_available_color_lists addObject: newList];
	      RELEASE(newList);
	    }
	}
    }  
  
  // And create its access lock
  _gnustep_color_list_lock = [[NSLock alloc] init];
}

/*
 * Getting All Color Lists
 */
+ (NSArray*) availableColorLists
{
  NSArray	*a;

  if (_gnustep_available_color_lists == nil)
    [NSColorList _loadAvailableColorLists];
  
  // Serialize access to color list
  [_gnustep_color_list_lock lock];

  a =  [NSArray arrayWithArray: _gnustep_available_color_lists];

  [_gnustep_color_list_lock unlock];

  return a;
}

/*
 * Getting a Color List by Name
 */
+ (NSColorList *) colorListNamed: (NSString *)name
{
  NSColorList  *r;
  NSEnumerator *e;
  BOOL         found = NO;

  if (_gnustep_available_color_lists == nil)
    [NSColorList _loadAvailableColorLists];

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

/*
 * Instance methods
 */
- (id) initWithName: (NSString *)name
{
  return [self initWithName: name
		   fromFile: nil];
}

- (id) initWithName: (NSString *)name
	   fromFile: (NSString *)path
{
  NSColorList *cl;
  BOOL        could_load = NO; 

  ASSIGN (_name, name);

  if (path != nil)
    {
      ASSIGN (_fullFileName, [[path stringByAppendingPathComponent: name] 
	stringByAppendingPathExtension: @"clr"]);
  
      // Unarchive the color list
      
      // TODO [Optm]: Rewrite to initialize directly without unarchiving 
      // in another object

      cl = (NSColorList*)[NSUnarchiver unarchiveObjectWithFile: _fullFileName];
      
      if (cl && [cl isKindOfClass: [NSColorList class]])
	{
	  could_load = YES;

	  _is_editable = [[NSFileManager defaultManager] 
	    isWritableFileAtPath: _fullFileName];
	  
	  ASSIGN(_colorDictionary, [NSMutableDictionary 
	    dictionaryWithDictionary: cl->_colorDictionary]);

	  ASSIGN(_orderedColorKeys, [NSMutableArray 
	    arrayWithArray: cl->_orderedColorKeys]);
	}
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

- (void) dealloc
{
  RELEASE (_name);
  TEST_RELEASE (_fullFileName);
  RELEASE (_colorDictionary);
  RELEASE (_orderedColorKeys);
  [super dealloc];
}

/*
 * Getting a Color List by Name
 */
- (NSString *) name
{
  return _name;
}

/*
 * Managing Colors by Key
 */
- (NSArray *) allKeys
{
  return [NSArray arrayWithArray: _orderedColorKeys];
}

- (NSColor *) colorWithKey: (NSString *)key
{
  return [_colorDictionary objectForKey: key];
}

- (void) insertColor: (NSColor *)color
		 key: (NSString *)key
	     atIndex: (unsigned)location
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

- (void) removeColorWithKey: (NSString *)key
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

- (void) setColor: (NSColor *)aColor
	   forKey: (NSString *)key
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

/*
 * Editing
 */
- (BOOL) isEditable
{
  return _is_editable;
}

/*
 * Writing and Removing Files
 */
- (BOOL) writeToFile: (NSString *)path
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString      *tmpPath;
  BOOL          isDir;
  BOOL          success;
  BOOL          path_is_standard = YES;

  /*
   * We need to initialize before saving, to avoid the new file being 
   * counted as a different list thus making us appear twice
   */
  if (_gnustep_available_color_lists == nil)
    [NSColorList _loadAvailableColorLists];

  if (path == nil || ([fm fileExistsAtPath: path isDirectory: &isDir] == NO))
    {
      // FIXME the standard path for saving color lists?
      path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
	NSUserDomainMask, YES) objectAtIndex: 0]
	stringByAppendingPathComponent: @"Colors"]; 
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
      if ([[path pathExtension] isEqual: @"clr"] == YES)
	{
	  ASSIGN (_fullFileName, path);
	}
      else
	{
	  ASSIGN (_fullFileName, [[path stringByDeletingPathExtension]
	    stringByAppendingPathExtension: @"clr"]);
	}
    }

  // Check if the path is a standard path
  if ([[path lastPathComponent] isEqualToString: @"Colors"] == NO)
    path_is_standard = NO;
  else 
    {
      tmpPath = [path stringByDeletingLastPathComponent];
      if (![NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
	NSAllDomainsMask, YES) containsObject: tmpPath])
	{
	  path_is_standard = NO;
	}
    }

  /*
   * If path is standard and it does not exist, try to create it.
   * System standard paths should always be assumed to exist; 
   * this will normally then only try to create user paths.
   */
  if (path_is_standard && ([fm fileExistsAtPath: path] == NO))
    {
      if([fm createDirectoryAtPath: path 
			attributes: nil])
	{
	  NSLog (@"Created standard directory %@", path);
	}
      else
	{
	  NSLog (@"Failed attemp to create directory %@", path);
	}
    }

  success = [NSArchiver archiveRootObject: self 
				   toFile: _fullFileName];

  if (success && path_is_standard)
    {
      [_gnustep_color_list_lock lock];
      if ([_gnustep_available_color_lists containsObject: self] == NO)
	[_gnustep_available_color_lists addObject: self];
      [_gnustep_color_list_lock unlock];      
      return YES;
    }
  
  return NO;
}

- (void) removeFile
{
  if (_fullFileName && _is_editable)
    {
      // Remove the file
      [[NSFileManager defaultManager] removeFileAtPath: _fullFileName
					       handler: nil];
      
      // Remove the color list from the global list of colors
      if (_gnustep_available_color_lists == nil)
	[NSColorList _loadAvailableColorLists];

      [_gnustep_color_list_lock lock];
      [_gnustep_available_color_lists removeObject: self];
      [_gnustep_color_list_lock unlock];

      // Reset file name
      _fullFileName = nil;
    }
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _name];
  [aCoder encodeObject: _colorDictionary];
  [aCoder encodeObject: _orderedColorKeys];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_name];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_colorDictionary];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_orderedColorKeys];

  return self;
}

@end

