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
#include <Foundation/NSClassDescription.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSKeyValueCoding.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSSound.h>
#include <AppKit/NSView.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/GSNibTemplates.h>
#include <AppKit/IMLoading.h>

//
// For the template classes since they need to know about any and all subclasses
// of the parent classes covered by them.
//
#include <AppKit/AppKit.h>

static const int currentVersion = 1;

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

      selName = [NSString stringWithFormat: @"set%@%@:",
			  [[_tag substringToIndex: 1] uppercaseString],
			  [_tag substringFromIndex: 1]];
      sel = NSSelectorFromString(selName);
	      
      if (sel && [_src respondsToSelector: sel])
	{
	  [_src performSelector: sel withObject: _dst];
	}
      else
	{
	  const char	*nam = [_tag cString];
	  const char	*type;
	  unsigned int	size;
	  unsigned int	offset;

	  /*
	   * Use the GNUstep additional function to set the instance
	   * variable directly.
	   * FIXME - need some way to do this for libFoundation and
	   * Foundation based systems.
	   */
	  if (GSObjCFindVariable(_src, nam, &type, &size, &offset))
	    {
	      GSObjCSetVariable(_src, offset, size, (void*)&_dst); 
	    }
	}
    }
}
@end



@implementation NSBundle (NSBundleAdditions)

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

  NSDebugLog(@"Loading Nib `%@'...\n", fileName);
  NS_DURING
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      BOOL              isDir = NO;

      if([mgr fileExistsAtPath: fileName isDirectory: &isDir])
	{
	  NSData	*data = nil;
	  
	  // if the data is in a directory, then load from objects.gorm in the directory
	  if(isDir == NO)
	    {
	      data = [NSData dataWithContentsOfFile: fileName];
	      NSDebugLog(@"Loaded data from file...");
	    }
	  else
	    {
	      NSString *newFileName = [fileName stringByAppendingPathComponent: @"objects.gorm"];
	      data = [NSData dataWithContentsOfFile: newFileName];
	      NSDebugLog(@"Loaded data from %@...",newFileName);
	    }

	  if (data != nil)
	    {
	      unarchiver = [[NSUnarchiver alloc] initForReadingWithData: data];
	      if (unarchiver != nil)
		{
		  id	obj;
		  
		  // font fallback and automatic translation...
		  [unarchiver decodeClassName: @"NSFont" asClassName: @"GSFontProxy"];
		  // [unarchiver decodeClassName: @"NSString" asClassName: @"GSStringProxy"];

		  NSDebugLog(@"Invoking unarchiver");
		  [unarchiver setObjectZone: zone];
		  obj = [unarchiver decodeObject];
		  if (obj != nil)
		    {
		      if ([obj isKindOfClass: [GSNibContainer class]])
			{
			  NSDebugLog(@"Calling awakeWithContext");
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
    }
  NS_HANDLER
    {
      NSLog(@"Exception occured while loading model: %@",[localException reason]);
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

+ (void) initialize
{
  if (self == [GSNibContainer class])
    {
      [self setVersion: GNUSTEP_NIB_VERSION];
    }
}

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
	  if ([context objectForKey: key] == nil || 
	      [key isEqualToString: @"NSOwner"]) // we want to send the message to the owner
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
  int version = [aCoder versionForClassName: @"GSNibContainer"]; 
  
  if(version == GNUSTEP_NIB_VERSION)
    {
      [aCoder decodeValueOfObjCType: @encode(id) at: &nameTable];
      [aCoder decodeValueOfObjCType: @encode(id) at: &connections];
    }

  return self;
}

- (NSMutableDictionary*) nameTable
{
  return nameTable;
}

@end

@implementation	GSNibItem
+ (void) initialize
{
  if (self == [GSNibItem class])
    {
      [self setVersion: currentVersion];
    }
}

- (void) dealloc
{
  RELEASE(theClass);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: theClass];
  [aCoder encodeRect: theFrame];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) 
	  at: &autoresizingMask];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: 
			  NSStringFromClass([self class])];

  if (version == 1)
    {
      id		obj;
      Class		cls;
      unsigned int      mask;
      
      [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
      theFrame = [aCoder decodeRect];
      [aCoder decodeValueOfObjCType: @encode(unsigned int) 
	      at: &mask];
      
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

      if ([obj respondsToSelector: @selector(setAutoresizingMask:)])
	{
	  [obj setAutoresizingMask: mask];
	}
      
      RELEASE(self);
      return obj;
    }
  else if (version == 0)
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
  else
    {
      NSLog(@"no initWithCoder for this version");
      RELEASE(self);
      return nil;
    }
}

@end

@implementation	GSCustomView
+ (void) initialize
{
  if (self == [GSCustomView class])
    {
      [self setVersion: currentVersion];
    }
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  return [super initWithCoder: aCoder];
}
@end

/*
 *
 *  Template Classes:  these are used to 
 *  persist custom classes (classes implemented by the user and loaded into Gorm
 *  to .gorm files.
 *
 */

// Template for any class which derives from NSWindow.
@implementation NSWindowTemplate
+ (void) initialize
{
  if (self == [NSWindowTemplate class]) 
    { 
      [self setVersion: 0];
    }
}

- (void) dealloc
{
  RELEASE(_className);
  [super dealloc];
}

- init
{
  [super init];

  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);

  // defer flag...
  _deferFlag = NO;

  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [aCoder decodeValueOfObjCType: @encode(BOOL) at: &_deferFlag];  
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_deferFlag];  
  [super encodeWithCoder: aCoder];
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return [self instantiateObject: coder];
}

- (id) instantiateObject: (NSCoder *)coder
{
  id obj = nil;
  Class aClass = NSClassFromString(_className);      

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }
  
  obj = [[aClass allocWithZone: [self zone]] 
	  initWithContentRect: [self frame]
	  styleMask: [self styleMask]
	  backing: [self backingType]
	  defer: _deferFlag];
  
  // fill in actual object from template...
  [obj setBackgroundColor: [self backgroundColor]];
  [obj setContentView: [self contentView]];
  [obj setFrameAutosaveName: [self frameAutosaveName]];
  [obj setHidesOnDeactivate: [self hidesOnDeactivate]];
  [obj setInitialFirstResponder: [self initialFirstResponder]];
  [obj setAutodisplay: [self isAutodisplay]];
  [obj setReleasedWhenClosed: [self isReleasedWhenClosed]];
  [obj _setVisible: [self isVisible]];
  [obj setTitle: [self title]];
  [obj setFrame: [self frame] display: NO];

  RELEASE(self);
  return obj;
}

// setters and getters...
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);
}

- (NSString *)className
{
  return _className;
}

- (BOOL)deferFlag
{
  return _deferFlag;
}

- (void)setDeferFlag: (BOOL)flag
{
  _deferFlag = flag;
}
@end

// Template for any classes which derive from NSView
@implementation NSViewTemplate
+ (void) initialize
{
  if (self == [NSViewTemplate class]) 
    {
      [self setVersion: 0];
    }
}

- (void) dealloc
{
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  [super initWithFrame: frame];

  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [super encodeWithCoder: aCoder];
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return [self instantiateObject: coder];
}

- (id) instantiateObject: (NSCoder *)coder
{
  Class       aClass = NSClassFromString(_className);
  NSRect theFrame = [self frame];
  id obj = nil;

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }

  obj =  [[aClass allocWithZone: NSDefaultMallocZone()]
	   initWithFrame: theFrame];

  // set the attributes for the view
  [obj setBounds: [self bounds]];
  
  RELEASE(self);
  return obj;
}

// setters and getters
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);
}

- (NSString *)className
{
  return _className;
}

@end

// Template for any classes which derive from NSText
@implementation NSTextTemplate
+ (void) initialize
{
  if (self == [NSTextTemplate class]) 
    {
      [self setVersion: 0];
    }
}

- (void) dealloc
{
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  [super initWithFrame: frame];
  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [super encodeWithCoder: aCoder];
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return [self instantiateObject: coder];
}

- (id) instantiateObject: (NSCoder *)coder
{
  Class  aClass = NSClassFromString(_className);
  NSRect theFrame = [self frame];
  id     obj = nil;

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }

  obj = [[aClass allocWithZone: NSDefaultMallocZone()]
	  initWithFrame: theFrame];

  // set the attributes for the view
  [obj setBounds: [self bounds]];

  // set the attributes for text
  [obj setBackgroundColor: [self backgroundColor]];
  [obj setDrawsBackground: [self drawsBackground]];
  [obj setEditable: [self isEditable]];
  [obj setSelectable: [self isSelectable]];
  [obj setFieldEditor: [self isFieldEditor]];
  [obj setRichText: [self isRichText]];
  [obj setImportsGraphics: [self importsGraphics]];
  [obj setDelegate: [self delegate]];

  RELEASE(self);
  return obj;
}

// accessor methods...
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);
}

- (NSString *)className
{
  return _className;
}
@end

// Template for any classes which derive from NSTextView
@implementation NSTextViewTemplate
+ (void) initialize
{
  if (self == [NSTextViewTemplate class]) 
    {
      [self setVersion: 0];
    }
}

- (void) dealloc
{
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  [super initWithFrame: frame];
  return self;
}

- init
{
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [super encodeWithCoder: aCoder];
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return [self instantiateObject: coder];
}

- (id) instantiateObject: (NSCoder *)coder
{
  Class  aClass = NSClassFromString(_className);
  NSRect theFrame = [self frame];
  id     obj = nil;

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }

  obj = [[aClass allocWithZone: NSDefaultMallocZone()]
	  initWithFrame: theFrame];

  // set the attributes for the view
  [obj setBounds: [self bounds]];

  // set the attributes for text
  [obj setBackgroundColor: [self backgroundColor]];
  [obj setDrawsBackground: [self drawsBackground]];
  [obj setEditable: [self isEditable]];
  [obj setSelectable: [self isSelectable]];
  [obj setFieldEditor: [self isFieldEditor]];
  [obj setRichText: [self isRichText]];
  [obj setImportsGraphics: [self importsGraphics]];
  [obj setDelegate: [self delegate]];

  // text view
  [obj setRulerVisible: [self isRulerVisible]];
  [obj setInsertionPointColor: [self insertionPointColor]];

  RELEASE(self);
  return obj;
}

// accessors
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);
}

- (NSString *)className
{
  return _className;
}
@end

// Template for any classes which derive from NSMenu.
@implementation NSMenuTemplate
+ (void) initialize
{
  if (self == [NSMenuTemplate class]) 
    {
      [self setVersion: 0];
    }
}

- (void) dealloc
{
  RELEASE(_className);
  [super dealloc];
}

- init
{
  [super init];
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [super encodeWithCoder: aCoder];
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return [self instantiateObject: coder];
}

- (id) instantiateObject: (NSCoder *)coder
{
  Class       aClass = NSClassFromString(_className);
  id          obj = nil;

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }

  obj = [[aClass allocWithZone: NSDefaultMallocZone()] init];

  // copy attributes
  [obj setAutoenablesItems: [self autoenablesItems]];
  [obj setTitle: [self title]];

  RELEASE(self);
  return obj;
}

// accessors
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);

}

- (NSString *)className
{
  return _className;
}
@end


// Template for any classes which derive from NSControl
@implementation NSControlTemplate
+ (void) initialize
{
  if (self == [NSControlTemplate class]) 
    {
      [self setVersion: 0];
    }
}

- (void) dealloc
{
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  [super initWithFrame: frame];

  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_delegate];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_dataSource];  
  [aCoder decodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];  
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_delegate];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_dataSource];  
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];  
  [super encodeWithCoder: aCoder];
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return [self instantiateObject: coder];
}

- (id) instantiateObject: (NSCoder *)coder
{
  Class       aClass = NSClassFromString(_className);
  NSRect theFrame = [self frame];
  id obj = nil;

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }

  obj =  [[aClass allocWithZone: NSDefaultMallocZone()]
	   initWithFrame: theFrame];

  // set the attributes for the view
  [obj setBounds: [self bounds]];

  // set the attributes for the control
  [obj setDoubleValue: [self doubleValue]];
  [obj setFloatValue: [self floatValue]];
  [obj setIntValue: [self intValue]];
  [obj setObjectValue: [self objectValue]];
  [obj setStringValue: [self stringValue]];
  [obj setTag: [self tag]];
  [obj setFont: [self font]];
  [obj setAlignment: [self alignment]];
  [obj setEnabled: [self isEnabled]];
  [obj setContinuous: [self isContinuous]];

  // since only some controls have delegates, we need to test...
  if([obj respondsToSelector: @selector(setDelegate:)])
      [obj setDelegate: _delegate];

  // since only some controls have data sources, we need to test...
  if([obj respondsToSelector: @selector(setDataSource:)])
      [obj setDataSource: _dataSource];

  // since only some controls have data sources, we need to test...
  if([obj respondsToSelector: @selector(setUsesDataSource:)])
      [obj setUsesDataSource: _usesDataSource];

  RELEASE(self);
  return obj;
}

// accessors
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);
}

- (NSString *)className
{
  return _className;
}
@end

// Template for any classes which derive from NSButton
@implementation NSButtonTemplate
+ (void) initialize
{
  if (self == [NSButtonTemplate class]) 
    {
      [self setVersion: 0];
    }
}

- (void) dealloc
{
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  _buttonType = NSMomentaryLightButton;
  [super initWithFrame: frame];
  
  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  RETAIN(_className);
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  RETAIN(_parentClassName);
  _buttonType = NSMomentaryLightButton;
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [aCoder decodeValueOfObjCType: @encode(int) at: &_buttonType];  
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(id) at: &_parentClassName];  
  [aCoder encodeValueOfObjCType: @encode(int) at: &_buttonType];  
  [super encodeWithCoder: aCoder];
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return [self instantiateObject: coder];
}

- (id) instantiateObject: (NSCoder *)coder
{
  Class       aClass = NSClassFromString(_className);
  NSRect theFrame = [self frame];
  id obj = nil;

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }

  obj =  [[aClass allocWithZone: NSDefaultMallocZone()]
	   initWithFrame: theFrame];

  // set the attributes for the view
  [obj setBounds: [self bounds]];

  // set the attributes for the control
  [obj setDoubleValue: [self doubleValue]];
  [obj setFloatValue: [self floatValue]];
  [obj setIntValue: [self intValue]];
  [obj setObjectValue: [self objectValue]];
  [obj setStringValue: [self stringValue]];
  [obj setTag: [self tag]];
  [obj setFont: [self font]];
  [obj setAlignment: [self alignment]];
  [obj setEnabled: [self isEnabled]];
  [obj setContinuous: [self isContinuous]];

  // button
  [obj setButtonType: _buttonType];
  [obj setBezelStyle: [self bezelStyle]];
  [obj setBordered: [self isBordered]];
  [obj setAllowsMixedState: [self allowsMixedState]];
  [obj setTitle: [self title]];
  [obj setAlternateTitle: [self alternateTitle]];
  [obj setImage: [self image]];
  [obj setAlternateImage: [self alternateImage]];
  [obj setImagePosition: [self imagePosition]];
  [obj setKeyEquivalent: [self keyEquivalent]];

  RELEASE(self);
  return obj;
}

// accessors
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);
}

- (NSString *)className
{
  return _className;
}
@end


// This class uses the templates above to persist the correct type of
// custom object into the nib file.
@implementation GSClassSwapper
+ (void) initialize
{
  if (self == [GSClassSwapper class]) 
    {
      [self setVersion: 0];
    }
}

- (id) init
{
  _className = nil;
  _template = nil;
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  [aCoder decodeValueOfObjCType: @encode(id) at: &_className]; 
  [aCoder decodeValueOfObjCType: @encode(id) at: &_template];
  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className]; 
  [aCoder encodeValueOfObjCType: @encode(id) at: &_template];
}

- (void) dealloc
{
  RELEASE(_className);
  RELEASE(_template);
  [super dealloc];
}

- (NSString *) className
{
  return _className;
}

- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
  RETAIN(_className);
}

- (id) template
{
  return _template;
}

- (void) setTemplate: (id)template
{
  ASSIGN(_template, template);
}
@end

// Font proxy...
@implementation GSFontProxy
- (id) initWithCoder: (NSCoder *)aDecoder
{
  id result = [super initWithCoder: aDecoder];
  NSDebugLog(@"Inside font proxy...");
  if(result == nil)
    {
      NSDebugLog(@"Couldn't find the font specified, so supply a system font instead.");
      result = [NSFont systemFontOfSize: [NSFont systemFontSize]];
    }

  return result;
}
@end

// String proxy for dynamic translation...
/*
@implementation GSStringProxy
- (id) initWithCoder: (NSCoder *)aDecoder
{
  id result = [[NSString alloc] initWithCoder: aDecoder];
  NSLog(@"Do your translation here... %@", result);
  return result;
}
@end
*/
// end of NSBundleAdditions...
