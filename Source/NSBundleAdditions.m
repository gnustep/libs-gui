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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
#include <Foundation/NSString.h>
#include <AppKit/NSView.h>
#include <AppKit/NSNibLoading.h>

@implementation NSBundle (NSBundleAdditions)

- (NSString *)pathForImageResource:(NSString *)name
{
  return nil;
}

+ (BOOL) loadNibFile: (NSString *)fileName
   externalNameTable: (NSDictionary *)context
	    withZone: (NSZone *)zone
{
  NSData	*data;
  BOOL		loaded = NO;

  data = [NSData dataWithContentsOfFile: fileName];
  if (data)
    {
      NSUnarchiver	*unarchiver;

      unarchiver = [[NSUnarchiver alloc] initWithData: data];
      if (unarchiver)
	{
	  id	obj;

	  [unarchiver setObjectZone: zone];
	  obj = [unarchiver decodeObject];
	  if (obj)
	    {
	      if ([obj isKindOfClass: [GSNibContainer class]])
		{
		  GSNibContainer	*container = obj;
		  NSMutableDictionary	*nameTable;
		  NSEnumerator		*enumerator;
		  NSString		*key;

		  nameTable = [container nameTable];

		  /*
		   *	Go through the table of objects in the nib and
		   *	retain each one (except ones that are overridden
		   *	by values from the 'context table' and retain them
		   *	so they will persist after the container is gone.
		   */
		  enumerator = [nameTable keyEnumerator];
		  while ((key = [enumerator nextObject]) != nil)
		    {
		      if ([context objectForKey: key] == nil)
			{
			  [[nameTable objectForKey: key] retain];
			}
		    }

		  /*
		   *	Now add local context to the name table, replacing
		   *	objects in the nib where the local version have the
		   *	same names.  Get the container to set up the
		   *	outlets from all the objects.  Finally tell the
		   *	unarchived objects to wake up.
		   */
		  [nameTable addEntriesFromDictionary: context];
		  [container setAllOutlets];
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
	  [unarchiver release];
	}
      [data release];
    }
  return loaded;
}

+ (BOOL) loadNibNamed: (NSString *)aNibName
	        owner: (id)owner
{
  NSDictionary	*table;
  NSBundle	*bundle;
  NSString	*file;
  NSString	*ext;
  NSString	*path;

  if (owner == nil || aNibName == nil)
    return NO;

  table = [NSDictionary dictionaryWithObject: owner forKey: @"NSOwner"];
  file = [aNibName stringByDeletingPathExtension];
  ext = [aNibName pathExtension];
  if ([ext isEqualToString: @""])
    {
      ext = @".nib";
    }
  bundle = [self bundleForClass: [owner class]];
  path = [bundle pathForResource: file ofType: ext];
  if (path == nil)
    return NO;
  
  return [self loadNibFile: aNibName
	 externalNameTable: table
		  withZone: [owner zone]];
}

@end



/*
 *	The GSNibContainer class manages the internals os a nib file.
 */
@implementation GSNibContainer
- (void) dealloc
{
  [nameTable release];
  [outletMap release];
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: nameTable];
  [aCoder encodeObject: outletMap];
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      nameTable = [[NSMutableDictionary alloc] initWithCapacity: 8];
      outletMap = [[NSMutableDictionary alloc] initWithCapacity: 8];
    }
  return self;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  self = [super initWithCoder: aCoder];
  [aCoder decodeValueOfObjCType: @encode(id) at: &nameTable];
  [aCoder decodeValueOfObjCType: @encode(id) at: &outletMap];
  return self;
}

- (NSMutableDictionary*) nameTable
{
  return nameTable;
}

- (NSMutableDictionary*) outletsFrom: (NSString*)instanceName
{
  return [outletMap objectForKey: instanceName];
}

- (void) setAllOutlets
{
  NSString	*instanceName;
  NSEnumerator	*instanceEnumerator;

  instanceEnumerator = [outletMap keyEnumerator];
  while ((instanceName = [instanceEnumerator nextObject]) != nil)
    {
      NSDictionary	*outletMappings;
      NSEnumerator	*outletEnumerator;
      NSString		*outletName;
      id		source;

      source = [nameTable objectForKey: instanceName];
      outletMappings = [outletMap objectForKey: instanceName];
      outletEnumerator = [outletMappings keyEnumerator];
      while ((outletName = [outletEnumerator nextObject]) != nil)
	{
	  id	target;

	  target = [outletMappings objectForKey: outletName];
	  [self setOutlet: outletName from: source to: target];
	}
    }
}

- (BOOL) setOutlet: (NSString*)outletName from: (id)source to: (id)target
{
  NSString	*selName;
  SEL		sel;

  selName = [NSString stringWithFormat: @"set%@:",
		[outletName capitalizedString]];
  sel = NSSelectorFromString(selName);
	      
  if ([source respondsToSelector: sel])
    {
      [source performSelector: sel withObject: target];
      return YES;
    }
  else
    {
      /*
       * Use the GNUstep additional function to set the instance variable
       * directly.
       * FIXME - need some way to do this for libFoundation and Foundation
       * based systems.
       */
      GSSetInstanceVariable(source, outletName, (void*)&target); 
      NSLog(@"Direct setting of ivar failed");
    }
  return NO;
}

- (BOOL) setOutlet: (NSString*)outletName
	  fromName: (NSString*)sourceName
	    toName: (NSString*)targetName
{
  NSMutableDictionary	*outletMappings;
  id	source;
  id	target;

  /*
   *	Get the mappings for the source object (create mappings if needed)
   *	and set the mapping for the outlet (replaces any old mapping).
   */
  outletMappings = [outletMap objectForKey: sourceName];
  if (outletMappings == nil)
    {
      outletMappings = [NSMutableDictionary dictionaryWithCapacity: 1];
      [outletMap setObject: outletMappings forKey: sourceName];
    }
  [outletMappings setObject: targetName forKey: outletName];

  /*
   *	Now make the connection in the objects themselves.
   */
  source = [nameTable objectForKey: sourceName];
  target = [nameTable objectForKey: targetName];
  return [self setOutlet: outletName from: source to: target];
}
@end

@implementation	GSNibItem
- (void) dealloc
{
  [theClass release];
  [settings release];
  [self dealloc];
}

- (id) init
{
  self = [super init];
  if (self)
    {
      settings = [[NSMutableArray alloc] initWithCapacity: 0];
    }
  return self;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  id		obj;
  Class		cls;
  unsigned	i;

  self = [super initWithCoder: aCoder];
  [aCoder decodeValueOfObjCType: @encode(BOOL) at: &hasFrame];
  frame = [aCoder decodeRect];
  [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
  [aCoder decodeValueOfObjCType: @encode(id) at: &settings];

  cls = NSClassFromString(theClass);
  obj = [cls allocWithZone: [self zone]];
  if (hasFrame)
    obj = [obj initWithFrame: frame];
  else
    obj = [obj init];

  for (i = 0; i < [settings count]; i++)
    {
      NSInvocation	*inv = [settings objectAtIndex: i];

      [inv setTarget: obj];
      [inv invoke];
    }
  [self release];
  return obj;
}

@end

