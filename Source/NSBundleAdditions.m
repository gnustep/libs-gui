/* 
   NSBundle.m

   Implementation of NSBundle Additions

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1999
   
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
   License along with this library;
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSView.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSNibLoading.h>


@implementation	NSNibConnector

- (void) dealloc
{
  RELEASE(_src);
  RELEASE(_dst);
  RELEASE(_tag);
  [super dealloc];
}

- (id) destination
{
  return _dst;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _src];
  [aCoder encodeObject: _dst];
  [aCoder encodeObject: _tag];
}

- (void) establishConnection
{
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_src];
  [aCoder decodeValueOfObjCType: @encode(id) at: &_dst];
  [aCoder decodeValueOfObjCType: @encode(id) at: &_tag];
  return self;
}

- (NSString*) label
{
  return _tag;
}

- (void) replaceObject: (id)anObject withObject: (id)anotherObject
{
  if (_src == anObject)
    {
      ASSIGN(_src, anotherObject);
    }
  if (_dst == anObject)
    {
      ASSIGN(_dst, anotherObject);
    }
  if (_tag == anObject)
    {
      ASSIGN(_tag, anotherObject);
    }
}

- (id) source
{
  return _src;
}

- (void) setDestination: (id)anObject
{
  ASSIGN(_dst, anObject);
}

- (void) setLabel: (NSString*)label
{
  ASSIGN(_tag, label);
}

- (void) setSource: (id)anObject
{
  ASSIGN(_src, anObject);
}

@end

@implementation	NSNibControlConnector
- (void) establishConnection
{
  SEL		sel = NSSelectorFromString(_tag);
	      
  [_src setTarget: _dst];
  [_src setAction: sel];
}
@end

@implementation	NSNibOutletConnector
- (void) establishConnection
{
  NSString	*selName;
  SEL		sel;

  selName = [NSString stringWithFormat: @"set%@:", [_tag capitalizedString]];
  sel = NSSelectorFromString(selName);
	      
  if ([_src respondsToSelector: sel])
    {
      [_src performSelector: sel withObject: _dst];
    }
  else
    {
      /*
       * Use the GNUstep additional function to set the instance variable
       * directly.
       * FIXME - need some way to do this for libFoundation and Foundation
       * based systems.
       */
      GSSetInstanceVariable(_src, _tag, (void*)&_dst); 
    }
}
@end



@implementation NSBundle (NSBundleAdditions)

- (NSString*) pathForImageResource: (NSString*)name
{
  NSString	*ext = [name pathExtension];
  NSString	*path = nil;

  if (ext != nil)
    {
      name = [name stringByDeletingPathExtension];
      path = [self pathForResource: name ofType: ext];
    }
  else
    {
      NSArray	*types = [NSImage imageUnfilteredFileTypes];
      unsigned	c = [types count];
      unsigned	i;

      for (i = 0; path == nil && i < c; i++)
	{
	  ext = [types objectAtIndex: i];
	  path = [self pathForResource: name ofType: ext];
	}
    }
  return path;
}

+ (BOOL) loadNibFile: (NSString *)fileName
   externalNameTable: (NSDictionary *)context
	    withZone: (NSZone *)zone
{
  NSData	*data;
  BOOL		loaded = NO;

  data = [NSData dataWithContentsOfFile: fileName];
  if (data != nil)
    {
      NSUnarchiver	*unarchiver;

      unarchiver = [[NSUnarchiver alloc] initForReadingWithData: data];
      if (unarchiver != nil)
	{
	  id	obj;

	  [unarchiver setObjectZone: zone];
	  obj = [unarchiver decodeObject];
	  if (obj != nil)
	    {
	      if ([obj isKindOfClass: [GSNibContainer class]])
		{
		  GSNibContainer	*container = obj;
		  NSMutableDictionary	*nameTable = [container nameTable];
		  NSMutableArray	*connections = [container connections];
		  NSEnumerator		*enumerator;
		  NSNibConnector	*connection;
		  NSString		*key;

		  /*
		   *	Go through the table of objects in the nib and
		   *	retain each one (except ones that are overridden
		   *	by values from the 'context table' and retain them
		   *	so they will persist after the container is gone.
		   *	Add local entries into name table.
		   */
		  enumerator = [nameTable keyEnumerator];
		  while ((key = [enumerator nextObject]) != nil)
		    {
		      if ([context objectForKey: key] == nil)
			{
			  RETAIN([nameTable objectForKey: key]);
			}
		    }
		  [nameTable addEntriesFromDictionary: context];

		  /*
		   *	Now establish all connections by taking the names
		   *	stored in the connection objects, and replaciong them
		   *	with the corresponding values from the name table
		   *	before telling the connections to establish themselves.
		   */
		  enumerator = [connections objectEnumerator];
		  while ((connection = [enumerator nextObject]) != nil)
		    {
		      id	val;

		      val = [nameTable objectForKey: [connection source]];
		      [connection setSource: val];
		      val = [nameTable objectForKey: [connection destination]];
		      [connection setDestination: val];
		      [connection establishConnection];
		    }

		  /*
		   * Now tell all the objects that they have been loaded from
		   * a nib.
		   */
		  enumerator = [nameTable keyEnumerator];
		  while ((key = [enumerator nextObject]) != nil)
		    {
		      if ([context objectForKey: key] == nil)
			{
			  id	o;

			  o = [nameTable objectForKey: key];
			  if ([o respondsToSelector: @selector(awakeFromNib)])
			    {
			      [o awakeFromNib];
			    }
			}
		    }
		
		  /*
		   *	Ok - it's all done now - the nib container will
		   *	be released when the unarchiver is released, so
		   *	we will just be left with the real nib contents.
		   */
		  loaded = YES;
		}
	      else
		{
		  NSLog(@"Nib '%@' without container object!", fileName);
		}
	    }
	  RELEASE(unarchiver);
	}
    }
  return loaded;
}

+ (BOOL) loadNibNamed: (NSString *)aNibName
	        owner: (id)owner
{
  NSDictionary	*table;
  NSBundle	*bundle;
  NSString	*file;

  if (owner == nil || aNibName == nil)
    return NO;

  table = [NSDictionary dictionaryWithObject: owner forKey: @"NSOwner"];
  file = [aNibName stringByDeletingPathExtension];
  bundle = [self bundleForClass: [owner class]];
  if (bundle == nil)
    {
      bundle = [self mainBundle];
    }
  return [bundle loadNibFile: aNibName
	   externalNameTable: table
		    withZone: [owner zone]];
}

- (BOOL) loadNibFile: (NSString*)fileName
   externalNameTable: (NSDictionary*)context
	    withZone: (NSZone*)zone
{
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSMutableArray	*array = [NSMutableArray arrayWithCapacity: 8];
  NSArray		*languages = [NSUserDefaults userLanguages];
  NSString		*rootPath = [self bundlePath];
  NSString		*primary;
  NSString		*language;
  NSEnumerator		*enumerator;
  NSString		*ext;

  ext = [fileName pathExtension];
  fileName = [fileName stringByDeletingPathExtension];

  /*
   * Build an array of resource paths that differs from the normal order -
   * we want a localized file in preference to a generic one.
   */
  primary = [rootPath stringByAppendingPathComponent: @"Resources"];
  enumerator = [languages objectEnumerator];
  while ((language = [enumerator nextObject]))
    {
      NSString	*langDir;

      langDir = [NSString stringWithFormat: @"%@.lproj", language];
      [array addObject: [primary stringByAppendingPathComponent: langDir]];
    }
  [array addObject: primary];
  primary = rootPath;
  enumerator = [languages objectEnumerator];
  while ((language = [enumerator nextObject]))
    {
      NSString	*langDir;

      langDir = [NSString stringWithFormat: @"%@.lproj", language];
      [array addObject: [primary stringByAppendingPathComponent: langDir]];
    }
  [array addObject: primary];

  enumerator = [array objectEnumerator];
  while ((rootPath = [enumerator nextObject]) != nil)
    {
      NSString	*path;

      rootPath = [rootPath stringByAppendingPathComponent: fileName]; 
      if ([ext isEqualToString: @""] == NO)
	{
	  path = [rootPath stringByAppendingPathExtension: ext];
	  if ([mgr isReadableFileAtPath: path] == NO)
	    {
	      path = [rootPath stringByAppendingPathExtension: @".gorm"];
	      if ([mgr isReadableFileAtPath: path] == NO)
		{
		  path = [rootPath stringByAppendingPathExtension: @".nib"];
		  if ([mgr isReadableFileAtPath: path] == NO)
		    {
		      continue;
		    }
		}
	    }
	  return [NSBundle loadNibFile: path
		     externalNameTable: context
			      withZone: (NSZone*)zone];
	}
    }
  return NO;
}
@end



/*
 *	The GSNibContainer class manages the internals os a nib file.
 */
@implementation GSNibContainer

- (NSMutableArray*) connections
{
  return connections;
}

- (void) dealloc
{
  RELEASE(nameTable);
  RELEASE(connections);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: nameTable];
  [aCoder encodeObject: connections];
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      nameTable = [[NSMutableDictionary alloc] initWithCapacity: 8];
      connections = [[NSMutableArray alloc] initWithCapacity: 8];
    }
  return self;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  self = [super initWithCoder: aCoder];
  [aCoder decodeValueOfObjCType: @encode(id) at: &nameTable];
  [aCoder decodeValueOfObjCType: @encode(id) at: &connections];
  return self;
}

- (NSMutableDictionary*) nameTable
{
  return nameTable;
}

@end

@implementation	GSNibItem

- (void) dealloc
{
  RELEASE(theClass);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: theClass];
  [aCoder encodeRect: theFrame];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  id		obj;
  Class		cls;

  [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
  theFrame = [aCoder decodeRect];

  cls = NSClassFromString(theClass);
  if (cls == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		  format: @"Unable to find class '%@'", theClass];
    }

  obj = [cls allocWithZone: [self zone]];
  if (theFrame.size.height > 0 && theFrame.size.width > 0)
    obj = [obj initWithFrame: theFrame];
  else
    obj = [obj init];

  RELEASE(self);
  return obj;
}

@end

