/** <title>NSBundleAdditions</title>

   <abstract>Implementation of NSBundle Additions</abstract>

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
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/IMLoading.h>

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
  if (_src != nil)
    {
      NSString	*selName;
      SEL	sel;

      selName = [NSString stringWithFormat: @"set%@:",
	[_tag capitalizedString]];
      sel = NSSelectorFromString(selName);
	      
      if (sel && [_src respondsToSelector: sel])
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
}
@end



@implementation NSBundle (NSBundleAdditions)

- (NSString*) pathForImageResource: (NSString*)name
{
  NSString	*ext = [name pathExtension];
  NSString	*path = nil;

  if ((ext == nil) || [ext isEqualToString:@""])
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
  else
    {
      name = [name stringByDeletingPathExtension];
      path = [self pathForResource: name ofType: ext];
    }
  return path;
}

static 
Class gmodel_class(void)
{
  static Class gmclass = Nil;

  if (gmclass == Nil)
    {
      NSBundle	*theBundle;
      NSEnumerator *benum;
      NSString	*path;

      /* Find the bundle */
      benum = [NSStandardLibraryPaths() objectEnumerator];
      while ((path = [benum nextObject]))
	{
	  path = [path stringByAppendingPathComponent: @"Bundles"];
	  path = [path stringByAppendingPathComponent: @"libgmodel.bundle"];
	  if ([[NSFileManager defaultManager] fileExistsAtPath: path])
	    break;
	  path = nil;
	}
      NSCAssert(path != nil, @"Unable to load gmodel bundle");
      NSDebugLog(@"Loading gmodel from %@", path);

      theBundle = [NSBundle bundleWithPath: path];
      NSCAssert(theBundle != nil, @"Can't init gmodel bundle");
      gmclass = [theBundle classNamed: @"GMModel"];
      NSCAssert(gmclass, @"Can't load gmodel bundle");
    }
  return gmclass;
}

+ (BOOL) loadNibFile: (NSString*)fileName
   externalNameTable: (NSDictionary*)context
	    withZone: (NSZone*)zone
{
  BOOL		loaded = NO;
  NSUnarchiver	*unarchiver = nil;
  NSString      *ext = [fileName pathExtension];

  if ([ext isEqual: @"nib"])
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*base = [fileName stringByDeletingPathExtension];

      /* We can't read nibs, look for an equivalent gorm or gmodel file */
      fileName = [base stringByAppendingPathExtension: @"gorm"];
      if ([mgr isReadableFileAtPath: fileName])
	{
	  ext = @"gorm";
	}
      else
	{
	  fileName = [base stringByAppendingPathExtension: @"gmodel"];
	  ext = @"gmodel";
	}
    }

  /*
   * If the file to be read is a gmodel, use the GMModel method to
   * read it in and skip the dearchiving below.
   */
  if ([ext isEqualToString: @"gmodel"])
    {
      return [gmodel_class() loadIMFile: fileName
		      owner: [context objectForKey: @"NSOwner"]];
    } 

  NSLog(@"Loading Nib `%@'...\n", fileName);
  NS_DURING
    {
      NSData	*data = [NSData dataWithContentsOfFile: fileName];

      if (data != nil)
	{
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
		      [obj awakeWithContext: context];
		      /*
		       *Ok - it's all done now - just retain the nib container
		       *so that it will not be released when the unarchiver
		       *is released, and the nib contents will persist.
		       */
		      RETAIN(obj);
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
    }
  NS_HANDLER
    {
      TEST_RELEASE(unarchiver);
    }
  NS_ENDHANDLER

  if (loaded == NO)
    {
      NSLog(@"Failed to load Nib\n");
    }
  return loaded;
}

+ (BOOL) loadNibNamed: (NSString *)aNibName
	        owner: (id)owner
{
  NSDictionary	*table;
  NSBundle	*bundle;

  if (owner == nil || aNibName == nil)
    {
      return NO;
    }
  table = [NSDictionary dictionaryWithObject: owner forKey: @"NSOwner"];
  bundle = [self bundleForClass: [owner class]];
  if (bundle == nil)
    {
      bundle = [self mainBundle];
    }
  return [bundle loadNibFile: aNibName
	   externalNameTable: table
		    withZone: [owner zone]];
}

- (NSString *) pathForNibResource: (NSString *)fileName
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
      // If the file does not have an extension, then we need to
      // figure out what type of model file to load.
      if ([ext isEqualToString: @""] == YES)
	{
	  path = [rootPath stringByAppendingPathExtension: @"gorm"];
	  if ([mgr isReadableFileAtPath: path] == NO)
	    {
	      path = [rootPath stringByAppendingPathExtension: @"nib"];
	      if ([mgr isReadableFileAtPath: path] == NO)
		{
		  path = [rootPath stringByAppendingPathExtension: @"gmodel"];
		  if ([mgr isReadableFileAtPath: path] == NO)
		    {
		      continue;
		    }
		}
	    }
	  return path;
	}
      else
	{
	  path = [rootPath stringByAppendingPathExtension: ext];
	  if([mgr isReadableFileAtPath: path])
	    {
	      return path;
	    }
	}
    }

  return nil;
}

- (BOOL) loadNibFile: (NSString*)fileName
   externalNameTable: (NSDictionary*)context
	    withZone: (NSZone*)zone
{
  NSString *path = [self pathForNibResource: fileName];

  if (path != nil)
    {
      return [NSBundle loadNibFile: path
		 externalNameTable: context
			  withZone: (NSZone*)zone];
    }
  else 
    {
      return NO;
    }
}
@end



@interface NSApplication (GSNibContainer)
- (void)_deactivateVisibleWindow: (NSWindow *)win;
@end

@implementation NSApplication (GSNibContainer)
/* Since awakeWithContext often gets called before the the app becomes
   active, [win -orderFront:] requests get ignored, so we add the window
   to the inactive list, so it gets sent an -orderFront when the app
   becomes active. */
- (void) _deactivateVisibleWindow: (NSWindow *)win
{
  if (_inactive)
    [_inactive addObject: win];
}
@end

/*
 *	The GSNibContainer class manages the internals of a nib file.
 */
@implementation GSNibContainer

- (void) awakeWithContext: (NSDictionary*)context
{
  if (_isAwake == NO)
    {
      NSEnumerator	*enumerator;
      NSNibConnector	*connection;
      NSString		*key;
      NSArray		*visible;
      NSMenu		*menu;

      _isAwake = YES;
      /*
       *	Add local entries into name table.
       */
      if ([context count] > 0)
	{
	  [nameTable addEntriesFromDictionary: context];
	}

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
       * See if there are objects that should be made visible.
       */
      visible = [nameTable objectForKey: @"NSVisible"];
      if (visible != nil
	&& [visible isKindOfClass: [NSArray class]] == YES)
	{
	  unsigned	pos = [visible count];

	  while (pos-- > 0)
	    {
	      NSWindow *win = [visible objectAtIndex: pos];
	      if ([NSApp isActive])
		[win orderFront: self];
	      else
		[NSApp _deactivateVisibleWindow: win];
	    }
	}

      /*
       * See if there is a main menu to be set.
       */
      menu = [nameTable objectForKey: @"NSMenu"];
      if (menu != nil && [menu isKindOfClass: [NSMenu class]] == YES)
	{
	  [NSApp setMainMenu: menu];
	}

      /*
       * Now remove any objects added from the context dictionary.
       */
      if ([context count] > 0)
	{
	  [nameTable removeObjectsForKeys: [context allKeys]];
	}
    }
}

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

@implementation	GSCustomView

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  return [super initWithCoder: aCoder];
}
@end
