/** <title>GSNibTemplates</title>

   <abstract>Contains all of the private classes used in .gorm files.</abstract>

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Gregory John Casamento
   Date: July 2003.
   
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
#include <Foundation/NSNotification.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSSet.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSView.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSApplication.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepGUI/GSNibTemplates.h>

static const int currentVersion = 1; // GSNibItem version number...

@interface NSObject (GSNibPrivateMethods)
- (BOOL) isInInterfaceBuilder;
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
 * This private class is used to collect the nib items while the 
 * .gorm file is being unarchived.  This is done to allow only
 * the top level items to be retained in a clean way.  The reason it's
 * being done this way is because old .gorm files don't have any
 * array within the nameTable which indicates the objects which are
 * considered top level, so there is no clean and generic way to determine
 * this.   Basically the top level items are any instances of or instances
 * of subclasses of NSMenu, NSWindow, or any controller class.
 * It's the last one that's hairy.  Controller classes are
 * represented in .gorm files by the GSNibItem class, but once they transform
 * into the actual class instance it's not easy to tell if it should be 
 * retained or not since there are a lot of other things stored in the nameTable
 * as well.  GJC
 */

static NSString *GSInternalNibItemAddedNotification = @"_GSInternalNibItemAddedNotification";

@interface GSNibItemCollector : NSObject
{
  NSMutableArray *items;
}
- (void) handleNotification: (NSNotification *)notification;
- (NSMutableArray *)items;
@end

@implementation GSNibItemCollector
- (void) handleNotification: (NSNotification *)notification;
{
  id obj = [notification object];
  [items addObject: obj];
}

- init
{
  if((self = [super init]) != nil)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

      // add myself as an observer and initialize the items array.
      [nc addObserver: self
	  selector: @selector(handleNotification:)
	  name: GSInternalNibItemAddedNotification 
	  object: nil];
      items = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(items);
  [super dealloc];
}

- (NSMutableArray *)items
{
  return items;
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

- (void) awakeWithContext: (NSDictionary *)context
{
  if (isAwake == NO)
    {
      NSEnumerator	*enumerator;
      NSNibConnector	*connection;
      NSString		*key;
      NSArray		*visible;
      NSMenu		*menu;
      NSMutableArray    *topObjects; 
      id                 obj;

      isAwake = YES;
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
       * See if there is a main menu to be set.  Report #4815, mainMenu 
       * should be initialized before awakeFromNib is called.
       */
      menu = [nameTable objectForKey: @"NSMenu"];
      if (menu != nil && [menu isKindOfClass: [NSMenu class]] == YES)
	{
	  [NSApp setMainMenu: menu];
	}

      /*
       * Set the Services menu.
       * Report #5205, Services/Window menu does not behave correctly.
       */
      menu = [nameTable objectForKey: @"NSServicesMenu"];
      if (menu != nil && [menu isKindOfClass: [NSMenu class]] == YES)
	{
	  [NSApp setServicesMenu: menu];
	}

      /*
       * Set the Services menu.
       * Report #5205, Services/Window menu does not behave correctly.
       */
      menu = [nameTable objectForKey: @"NSWindowsMenu"];
      if (menu != nil && [menu isKindOfClass: [NSMenu class]] == YES)
	{
	  [NSApp setWindowsMenu: menu];
	}


      /* 
       * See if the user has passed in the NSTopLevelObjects key.
       * This is an implementation of an undocumented, but commonly used feature
       * of nib files to allow the release of the top level objects in the nib
       * file.
       */
      obj = [context objectForKey: @"NSTopLevelObjects"];
      if([obj isKindOfClass: [NSMutableArray class]])
	{
	  topObjects = obj;
	}
      else
	{
	  topObjects = nil; 
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
	      if([key isEqualToString: @"NSWindowsMenu"] == NO && // we don't want to send a message to these menus twice, 
		 [key isEqualToString: @"NSServicesMenu"] == NO && // if they're custom classes.
		 [key isEqualToString: @"NSVisible"] == NO && // also exclude any other special parts of the nameTable.
		 [key isEqualToString: @"NSDeferred"] == NO &&
		 [key isEqualToString: @"NSTopLevelObjects"] == NO &&
		 [key isEqualToString: @"GSCustomClassMap"] == NO)
		{
		  id o = [nameTable objectForKey: key];

		  // send the awake message, if it responds...
		  if ([o respondsToSelector: @selector(awakeFromNib)])
		    {
		      [o awakeFromNib];
		    }

		  /*
		   * Retain all "top level" items so that, when the container 
		   * is released, they will remain. The GSNibItems instantiated in the gorm need 
		   * to be retained, since we are deallocating the container.  
		   * We don't want to retain the owner.
		   *
		   * Please note: It is encumbent upon the developer of an application to 
		   * release these objects.   Instantiating a window manually or loading in a .gorm 
		   * file are equivalent processes.  These objects need to be released in their 
		   * respective controllers.  If the developer has used the "NSTopLevelObjects" feature, 
		   * then he will get the objects back in an array which he merely must release in
		   * order to release the objects held within.  GJC
		   */
		  if([key isEqualToString: @"NSOwner"] == NO)
		    {
		      if([topLevelObjects containsObject: o]) // anything already designated a top level item..
			{
			  if(topObjects == nil)
			    {
			      // It is expected, if the NSTopLevelObjects key is not passed in,
			      // that the user has opted to either allow these objects to leak or
			      // to release them explicitly.
			      RETAIN(o);
			    }
			  else
			    {
			      // We don't want to do the extra retain if the items are added to the
			      // array, since the array will do the retain for us.   When the array
			      // is released, the top level objects should be released as well.
			      [topObjects addObject: o];
			    }
			}
		    }
		}
	    }
	}
      
      /*
       * See if there are objects that should be made visible.
       * This is the last thing we should do since changes might be made
       * in the awakeFromNib methods which are called on all of the objects.
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
  RELEASE(topLevelObjects);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  int version = [GSNibContainer version];
  if(version == GNUSTEP_NIB_VERSION)
    {
      [aCoder encodeObject: nameTable];
      [aCoder encodeObject: connections];
      [aCoder encodeObject: topLevelObjects];
    }
  else
    {
      // encode it as a version 0 file...
      [aCoder encodeObject: nameTable];
      [aCoder encodeObject: connections];
    }
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      nameTable = [[NSMutableDictionary alloc] initWithCapacity: 8];
      connections = [[NSMutableArray alloc] initWithCapacity: 8];
      topLevelObjects = [[NSMutableSet alloc] initWithCapacity: 8];
    }
  return self;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: @"GSNibContainer"]; 

  // save the version to the ivar, we need it later.
  if(version == GNUSTEP_NIB_VERSION)
    {
      [aCoder decodeValueOfObjCType: @encode(id) at: &nameTable];
      [aCoder decodeValueOfObjCType: @encode(id) at: &connections];
      [aCoder decodeValueOfObjCType: @encode(id) at: &topLevelObjects];
    }
  else if(version == 0)
    {
      GSNibItemCollector *nibitems = [[GSNibItemCollector alloc] init];
      NSEnumerator *en;
      NSString *key;
      
      // initialize the set of top level objects...
      topLevelObjects = [[NSMutableSet alloc] initWithCapacity: 8];

      // unarchive...
      [aCoder decodeValueOfObjCType: @encode(id) at: &nameTable];
      [aCoder decodeValueOfObjCType: @encode(id) at: &connections];
      [topLevelObjects addObjectsFromArray: [nibitems items]]; // get the top level items here...
      RELEASE(nibitems);

      // iterate through the objects returned
      en = [nameTable keyEnumerator];
      while((key = [en nextObject]) != nil)
	{
	  id o = [nameTable objectForKey: key];
	  if(([o isKindOfClass: [NSMenu class]] && [key isEqual: @"NSMenu"]) ||
	     [o isKindOfClass: [NSWindow class]])
	    {
	      [topLevelObjects addObject: o]; // if it's a top level object, add it.
	    }
	}
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to read GSNibContainer version #%d.  GSNibContainer version for the installed gui lib is %d.", version, GNUSTEP_NIB_VERSION];
    }

  return self;
}

- (NSMutableDictionary*) nameTable
{
  return nameTable;
}

- (NSMutableSet*) topLevelObjects
{
  return topLevelObjects;
}
@end

// The first standin objects here are for views and normal objects like controllers
// or data sources.
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
  id obj = nil;

  if (version == 1)
    {
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
		       format: @"Unable to find class '%@', it is not linked into the application.", theClass];
	}
      
      obj = [cls allocWithZone: [self zone]];
      if (theFrame.size.height > 0 && theFrame.size.width > 0)
	{
	  obj = [obj initWithFrame: theFrame];
	}
      else
	{
	  obj = [obj init];
	}

      if ([obj respondsToSelector: @selector(setAutoresizingMask:)])
	{
	  [obj setAutoresizingMask: mask];
	}
    }
  else if (version == 0)
    {
      Class		cls;
      
      [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
      theFrame = [aCoder decodeRect];
      
      cls = NSClassFromString(theClass);
      if (cls == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@', it is not linked into the application.", theClass];
	}
      
      obj = [cls allocWithZone: [self zone]];
      if (theFrame.size.height > 0 && theFrame.size.width > 0)
	{
	  obj = [obj initWithFrame: theFrame];
	}
      else
	{
	  obj = [obj init];
	}
    }
  else
    {
      NSLog(@"no initWithCoder for this version");
    }

  // If this is a nib item and not a custom view, then we need to add it to
  // the set of things to be retained.  Also, the initial version of the nib container
  // needed this code, but subsequent versions don't, so don't send the notification,
  // if the version isn't zero.
  if(obj != nil && [aCoder versionForClassName: NSStringFromClass([GSNibContainer class])] == 0)
    {
      if([self isKindOfClass: [GSNibItem class]] == YES &&
	 [self isKindOfClass: [GSCustomView class]] == NO)
	{
	  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	  [nc postNotificationName: GSInternalNibItemAddedNotification
	      object: obj];
	}
    }

  // release self and return the object this represents...
  RELEASE(self);
  return obj;
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
  These stand-ins are here for use by GUI elements within Gorm.   Since each gui element
  has it's own "designated initializer" it's important to provide a division between these
  so that when they are loaded, the application will call the correct initializer. 
  
  Some "tricks" are employed in this code.   For instance the use of initWithCoder and
  encodeWithCoder directly as opposed to using the encodeObjC..  methods is the obvious
  standout.  To understand this it's necessary to explain a little about how encoding itself
  works.

  When the model is saved by the Interface Builder (whether Gorm or another 
  IB equivalent) these classes should be used to substitute for the actual classes.  The actual
  classes are encoded as part of it, but since they are being replaced we can't use the normal
  encode methods to do it and must encode it directly.

  Also, the reason for encoding the superclass itself is that by doing so the unarchiver knows
  what version is referred to by the encoded object.  This way we can replace the object with
  a substitute class which will allow it to create itself as the custom class when read it by
  the application, and using the encoding system to do it in a clean way.
*/
@implementation GSClassSwapper
+ (void) initialize
{
  if (self == [GSClassSwapper class]) 
    { 
      [self setVersion: GSSWAPPER_VERSION];
    }
}

- (id) initWithObject: (id)object className: (NSString *)className superClassName: (NSString *)superClassName
{
  if((self = [self init]) != nil)
    {
      NSDebugLog(@"Created template %@ -> %@",NSStringFromClass([self class]), className);
      ASSIGN(_object, object);
      ASSIGN(_className, [className copy]);
      NSAssert(![className isEqualToString: superClassName], NSInvalidArgumentException);
      _superClass = NSClassFromString(superClassName);
      if(_superClass == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@', it is not linked into the application.", superClassName];
	}
    }
  return self;
}

- init
{
  if((self = [super init]) != nil)
    {
      _className = nil;
      _superClass = nil;
      _object = nil;
    } 
  return self;
}

- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, [name copy]);
}

- (NSString *)className
{
  return _className;
}

- (id) initWithCoder: (NSCoder *)coder
{
  id obj = nil;
  int version = [coder versionForClassName: @"GSClassSwapper"];
  if(version == 0)
    {
      if((self = [super init]) != nil)
	{
	  NSUnarchiver *unarchiver = (NSUnarchiver *)coder;

	  // decode class/superclass...
	  [coder decodeValueOfObjCType: @encode(id) at: &_className];  
	  [coder decodeValueOfObjCType: @encode(Class) at: &_superClass];

	  // if we are living within the interface builder app, then don't try to 
	  // morph into the subclass.
	  if([self shouldSwapClass])
	    {
	      Class aClass = NSClassFromString(_className);
	      if(aClass == 0)
		{
		  [NSException raise: NSInternalInconsistencyException
			       format: @"Unable to find class '%@', it is not linked into the application.", _className];
		}
	  
	      // Initialize the object...  dont call decode, since this wont 
	      // allow us to instantiate the class we want. 
	      obj = [aClass alloc];
	    }
	  else
	    {
	      obj = [_superClass alloc];
	    }

	  // inform the coder that this object is to replace the template in all cases.
	  [unarchiver replaceObject: self withObject: obj];
	  obj = [obj initWithCoder: coder]; // unarchive the object... 
	}
    }

  // change the class of the instance to the one we want to see...
  return obj;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(id) at: &_className];  
  [aCoder encodeValueOfObjCType: @encode(Class) at: &_superClass];

  if(_object != nil)
    {
      // Don't call encodeValue, the way templates are used will prevent
      // it from being saved correctly.  Just call encodeWithCoder directly.
      [_object encodeWithCoder: aCoder]; 
    }
}

- (BOOL) shouldSwapClass
{
  BOOL result = YES;
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      result = !([self isInInterfaceBuilder]);
    }
  return result;
}
@end

@implementation GSWindowTemplate
+ (void) initialize
{
  if (self == [GSWindowTemplate class]) 
    { 
      [self setVersion: GSWINDOWT_VERSION];
    }
}

- (BOOL)deferFlag
{
  return _deferFlag;
}

- (void)setDeferFlag: (BOOL)flag
{
  _deferFlag = flag;
}

// NSCoding...
- (id) initWithCoder: (NSCoder *)coder
{
  id obj = [super initWithCoder: coder];
  if(obj != nil)
    {
      NSView *contentView = nil;

      // decode the defer flag...
      [coder decodeValueOfObjCType: @encode(BOOL) at: &_deferFlag];      

      if([self shouldSwapClass])
      {
	if(GSGetMethod([obj class], @selector(initWithContentRect:styleMask:backing:defer:), YES, NO) != NULL)
	  {
	    // if we are not in interface builder, call 
	    // designated initializer per spec...
	    contentView = [obj contentView];
	    obj = [obj initWithContentRect: [obj frame]
		       styleMask: [obj styleMask]
		       backing: [obj backingType]
		       defer: _deferFlag];
	    
	    // set the content view back
	    [obj setContentView: contentView];
	  }
      }
      RELEASE(self);
    }
  return obj;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];
  [coder encodeValueOfObjCType: @encode(BOOL) at: &_deferFlag];      
}
@end

@implementation GSViewTemplate
+ (void) initialize
{
  if (self == [GSViewTemplate class]) 
    {
      [self setVersion: GSVIEWT_VERSION];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  id obj = [super initWithCoder: coder];
  if(obj != nil)
    {
      if([self shouldSwapClass])
      {
	if(GSGetMethod([obj class],@selector(initWithFrame:), YES, NO) != NULL)
	  {
	    NSRect theFrame = [obj frame];
	    obj =  [obj initWithFrame: theFrame];
	  }
      }
      RELEASE(self);
    }
  return obj;
}
@end

// Template for any classes which derive from NSText
@implementation GSTextTemplate
+ (void) initialize
{
  if (self == [GSTextTemplate class]) 
    {
      [self setVersion: GSTEXTT_VERSION];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  id     obj = [super initWithCoder: coder];
  if(obj != nil)
    {
      if([self shouldSwapClass])
      {
	if(GSGetMethod([obj class],@selector(initWithFrame:), YES, NO) != NULL)
	  {
	    NSRect theFrame = [obj frame]; 
	    obj = [obj initWithFrame: theFrame];
	  }
      }
      RELEASE(self);
    }
  return obj;
}
@end

// Template for any classes which derive from GSTextView
@implementation GSTextViewTemplate
+ (void) initialize
{
  if (self == [GSTextViewTemplate class]) 
    {
      [self setVersion: GSTEXTVIEWT_VERSION];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  id     obj = [super initWithCoder: coder];
  if(obj != nil)
    {
      if([self shouldSwapClass])
      {
	if(GSGetMethod([obj class],@selector(initWithFrame:textContainer:), YES, NO) != NULL)
	  {
	    NSRect theFrame = [obj frame];
	    id textContainer = [obj textContainer];
	    obj = [obj initWithFrame: theFrame 
		       textContainer: textContainer];
	  }
      }
      RELEASE(self);
    }
  return obj;
}
@end

// Template for any classes which derive from NSMenu.
@implementation GSMenuTemplate
+ (void) initialize
{
  if (self == [GSMenuTemplate class]) 
    {
      [self setVersion: GSMENUT_VERSION];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  id     obj = [super initWithCoder: coder];
  if(obj != nil)
    {
      if([self shouldSwapClass])
      {
	if(GSGetMethod([obj class],@selector(initWithTitle:), YES, NO) != NULL)
	  {
	    NSString *theTitle = [obj title]; 
	    obj = [obj initWithTitle: theTitle];
	  }
      }
      RELEASE(self);
    }
  return obj;
}
@end


// Template for any classes which derive from NSControl
@implementation GSControlTemplate
+ (void) initialize
{
  if (self == [GSControlTemplate class]) 
    {
      [self setVersion: GSCONTROLT_VERSION];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  id     obj = [super initWithCoder: coder];
  if(obj != nil)
    {
      /* 
      if([self shouldSwapClass])
      {
	if(GSGetMethod([obj class],@selector(initWithFrame:), YES, NO) != NULL)
	  {
	    NSRect theFrame = [obj frame]; 
	    obj = [obj initWithFrame: theFrame];
	  }
      }
      */
      RELEASE(self);
    }
  return obj;
}
@end

@implementation GSObjectTemplate
+ (void) initialize
{
  if (self == [GSObjectTemplate class]) 
    {
      [self setVersion: GSOBJECTT_VERSION];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  id     obj = [super initWithCoder: coder];
  if(obj != nil)
    {
      if([self shouldSwapClass])
      {
	if(GSGetMethod([obj class],@selector(init), YES, NO) != NULL)
	  {
	    obj = [self init];
	  }
      }
      RELEASE(self);
    }
  return obj;
}
@end

// Order in this factory method is very important.  
// Which template to create must be determined
// in sequence because of the class hierarchy.
@implementation GSTemplateFactory
+ (id) templateForObject: (id) object 
	   withClassName: (NSString *)className
      withSuperClassName: (NSString *)superClassName
{
  id template = nil;
  if(object != nil)
    {
      // NSData *objectData = nil;
      // [archiver encodeRootObject: object];
      // objectData = [archiver archiverData];
      if ([object isKindOfClass: [NSWindow class]])
	{
	  template = [[GSWindowTemplate alloc] initWithObject: object
					       className: className 
					       superClassName: superClassName];
	}
      else if ([object isKindOfClass: [NSTextView class]])
	{
	  template = [[GSTextViewTemplate alloc] initWithObject: object
						 className: className 
						 superClassName: superClassName];
	}
      else if ([object isKindOfClass: [NSText class]])
	{
	  template = [[GSTextTemplate alloc] initWithObject: object
					     className: className 
					     superClassName: superClassName];
	}
      else if ([object isKindOfClass: [NSControl class]])
	{
	  template = [[GSControlTemplate alloc] initWithObject: object
						className: className 
						superClassName: superClassName];
	}
      else if ([object isKindOfClass: [NSView class]])
	{
	  template = [[GSViewTemplate alloc] initWithObject: object
					     className: className 
					     superClassName: superClassName];
	}
      else if ([object isKindOfClass: [NSMenu class]])
	{
	  template = [[GSMenuTemplate alloc] initWithObject: object
					     className: className 
					     superClassName: superClassName];
	}
      else if ([object isKindOfClass: [NSObject class]]) // for gui elements derived from NSObject
	{
	  template = [[GSObjectTemplate alloc] initWithObject: object
					       className: className 
					       superClassName: superClassName];
	}
    }
  return template;
}
@end
