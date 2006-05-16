/** <title>GSNibCompatibility</title>

   <abstract>
   These are templates for use with OSX Nib files.  These classes are the
   templates and other things which are needed for reading/writing nib files.
   </abstract>

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author: Gregory John Casamento
   Date: 2003, 2005

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

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
#include <Foundation/NSKeyedArchiver.h>
#include "AppKit/AppKit.h"
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepGUI/GSNibCompatibility.h>
#include <GNUstepGUI/GSInstantiator.h>

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
  RELEASE(_title);
  RELEASE(_viewClass);
  RELEASE(_windowClass);
  RELEASE(_view);
  RELEASE(_autosaveName);
  [super dealloc];
}

- (id) initWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSViewClass"])
        {
	  ASSIGN(_viewClass, [coder decodeObjectForKey: @"NSViewClass"]);
	}
      if ([coder containsValueForKey: @"NSWindowClass"])
        {
	  ASSIGN(_windowClass, [coder decodeObjectForKey: @"NSWindowClass"]);
	}
      if ([coder containsValueForKey: @"NSWindowStyleMask"])
        {
	  _windowStyle = [coder decodeIntForKey: @"NSWindowStyleMask"];
	}
      if([coder containsValueForKey: @"NSWindowBacking"])
	{
	  _backingStoreType = [coder decodeIntForKey: @"NSWindowBacking"];
	}
      if ([coder containsValueForKey: @"NSWindowView"])
        {
	  ASSIGN(_view, [coder decodeObjectForKey: @"NSWindowView"]);
	}
      if ([coder containsValueForKey: @"NSWTFlags"])
        {
	  unsigned long flags = [coder decodeIntForKey: @"NSWTFlags"];
	  memcpy((void *)&_flags,(void *)&flags,sizeof(struct _GSWindowTemplateFlags));
	}
      if ([coder containsValueForKey: @"NSMinSize"])
        {
	  _minSize = [coder decodeSizeForKey: @"NSMinSize"];
	}
      if ([coder containsValueForKey: @"NSMaxSize"])
        {
	  _maxSize = [coder decodeSizeForKey: @"NSMaxSize"];
	}
      if ([coder containsValueForKey: @"NSWindowRect"])
        {
	  _windowRect = [coder decodeRectForKey: @"NSWindowRect"];
	}
      if ([coder containsValueForKey: @"NSFrameAutosaveName"])
        {
	  ASSIGN(_autosaveName, [coder decodeObjectForKey: @"NSFrameAutosaveName"]);
	}
      if ([coder containsValueForKey: @"NSWindowTitle"])
        {
	  ASSIGN(_title, [coder decodeObjectForKey: @"NSWindowTitle"]);
	  _windowStyle |= NSTitledWindowMask;
	}
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
		   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      unsigned long flags = 0; 

      memcpy((void *)&flags,(void *)&_flags,sizeof(unsigned long));

      [aCoder encodeObject: _viewClass forKey: @"NSViewClass"];
      [aCoder encodeObject: _windowClass forKey: @"NSWindowClass"];
      [aCoder encodeInt: _windowStyle forKey: @"NSWindowStyleMask"];
      [aCoder encodeInt: _backingStoreType forKey: @"NSWindowBacking"];
      [aCoder encodeObject: _view forKey: @"NSWindowView"];
      [aCoder encodeInt: flags forKey: @"NSWTFlags"];
      [aCoder encodeSize: _minSize forKey: @"NSMinSize"];
      [aCoder encodeSize: _maxSize forKey: @"NSMaxSize"];
      [aCoder encodeRect: _windowRect forKey: @"NSWindowRect"];
      [aCoder encodeObject: _title forKey: @"NSWindowTitle"];
      [aCoder encodeObject: _autosaveName forKey: @"NSFrameAutosaveName"];
    }
}

- (id) nibInstantiate
{
  if(_realObject == nil)
    {
      Class aClass = NSClassFromString(_windowClass);      
      NSEnumerator *en;
      id v = nil;
      
      if (aClass == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@'", _windowClass];
	}
      
      _realObject = [[aClass allocWithZone: NSDefaultMallocZone()]
		      initWithContentRect: _windowRect
		      styleMask: _windowStyle
		      backing: _backingStoreType
		      defer: _flags.isDeferred
		      screen: nil];
      
      // set flags...
      [_realObject setHidesOnDeactivate: _flags.isHiddenOnDeactivate];
      [_realObject setReleasedWhenClosed: !(_flags.isNotReleasedOnClose)];
      [_realObject setOneShot: _flags.isOneShot];
      // [_realObject setVisible: _flags.isVisible]; // this is determined by whether it's in the visible windows array...
      // [_realObject setWantsToBeColor: _flags.wantsToBeColor]; // not applicable on GNUstep.
      [_realObject setAutodisplay: YES];
      [_realObject setDynamicDepthLimit: _flags.dynamicDepthLimit];
      // [_realObject setAutoPositionMask: _flags.autoPositionMask]; // currently not implemented for nibs
      // [_realObject setAutoPosition: _flags.autoPosition];
      [_realObject setDynamicDepthLimit: _flags.dynamicDepthLimit];
      [_realObject setFrameAutosaveName: _autosaveName];

      // reset attributes...
      [_realObject setContentView: _view];
      [_realObject setMinSize: _minSize];
      [_realObject setMaxSize: _maxSize];
      [_realObject setTitle: _title];
      
      // swap out any views which need to be swapped...
      en = [[[_realObject contentView] subviews] objectEnumerator];
      while((v = [en nextObject]) != nil)
	{
	  if([v respondsToSelector: @selector(nibInstantiate)])
	    {
	      [v nibInstantiate];
	    }
	}
    } 
  return _realObject;
}

// setters and getters
- (void) setBackingStoreType: (NSBackingStoreType)type
{
  _backingStoreType = type;
}

- (NSBackingStoreType) backingStoreType
{
  return _backingStoreType;
}

- (void) setDeferred: (BOOL)flag
{
  _flags.isDeferred = flag;
}

- (BOOL) isDeferred
{
  return _flags.isDeferred;
}

- (void) setMaxSize: (NSSize)maxSize
{
  _maxSize = maxSize;
}

- (NSSize) maxSize
{
  return _maxSize;
}

- (void) setMinSize: (NSSize)minSize
{
  _minSize = minSize;
}

- (NSSize) minSize
{
  return _minSize;
}

- (void) setWindowStyle: (unsigned)style
{
  _windowStyle = style;
}

- (unsigned) windowStyle
{
  return _windowStyle;
}

- (void) setTitle: (NSString *) title
{
  ASSIGN(_title, title);
}

- (NSString *)title;
{
  return _title;
}

- (void) setViewClass: (NSString *)viewClass
{
  ASSIGN(_viewClass,viewClass);
}

- (NSString *)viewClass
{
  return _viewClass;
}

- (void) setWindowRect: (NSRect)rect
{
  _windowRect = rect;
}

- (NSRect)windowRect
{
  return _windowRect;
}

- (void) setScreenRect: (NSRect)rect
{
  _screenRect = rect;
}

- (NSRect) screenRect
{
  return _screenRect;
}

- (id) realObject
{
  return _realObject;
}

- (void) setView: (id)view
{
  ASSIGN(_view,view);
}

- (id) view
{
  return _view;
}

- (void) setClassName: (NSString *)name
{
  ASSIGN(_windowClass, name);
}

- (NSString *)className
{
  return _windowClass;
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

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if(self != nil)
    {
      if([coder allowsKeyedCoding])
	{
	  _className = [coder decodeObjectForKey: @"NSClassName"];
	}
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
		   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      [coder encodeObject: (id)_className forKey: @"NSClassName"];
    }
}

- (id)nibInstantiate
{
  if(_realObject == nil)
    {
      Class aClass = NSClassFromString(_className);
      if(aClass == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@'", _className];
	}
      else
	{
	  _realObject = [[aClass allocWithZone: NSDefaultMallocZone()] initWithFrame: [self frame]];
	  [[self superview] replaceSubview: self with: _realObject]; // replace the old view...
	}
    }

  return _realObject;
}

// setters and getters
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
}

- (NSString *)className
{
  return _className;
}

- (id) realObject
{
  return _realObject;
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

- (id)nibInstantiate
{
  if(_realObject == nil)
    {
      Class aClass = NSClassFromString(_className);
      if(aClass == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@'", _className];
	}
      else
	{
	  _realObject = [[aClass allocWithZone: NSDefaultMallocZone()] initWithFrame: [self frame]];
	  [[self superview] replaceSubview: self with: _realObject]; // replace the old view...
	}
    }

  return _realObject;
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

- (id) initWithCoder: (NSCoder *)aCoder
{
  return nil;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
}

- (id) nibInstantiate
{
  return nil;
}

- (void) setClassName: (NSString *)className
{
  ASSIGN(_menuClass, className);
}

- (NSString *)className
{
  return _menuClass;
}

- (id) realObject
{
  return _realObject;
}
@end

@implementation NSCustomObject
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
}

- (NSString *)className
{
  return _className;
}

- (void) setExtension: (NSString *)name
{
  ASSIGN(_extension, name);
}

- (NSString *)extension
{
  return _extension;
}

- (void) setObject: (id)obj
{
  ASSIGN(_object, obj);
}

- (id) object
{
  return _object;
}

- (id) initWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      ASSIGN(_className, [coder decodeObjectForKey: @"NSClassName"]);
      ASSIGN(_extension, [coder decodeObjectForKey: @"NSExtension"]);
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
		   NSStringFromClass([coder class])];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      [coder encodeObject: (id)_className forKey: @"NSClassName"];
      [coder encodeConditionalObject: (id)_extension forKey: @"NSExtension"];
    }
}

- (id) nibInstantiate
{
  if(_object == nil)
    {
      Class aClass = NSClassFromString(_className);
      if(aClass == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@'", _className];
	}
      
      _object = [[aClass allocWithZone: NSDefaultMallocZone()] init];
    }
  return _object;
}
@end

@implementation NSCustomView
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
}

- (NSString *)className
{
  return _className;
}
- (void) setExtension: (NSString *)ext;
{
  ASSIGN(_extension, ext);
}

- (NSString *)extension
{
  return _extension;
}

- (id)nibInstantiate
{
  if(_view == nil)
    {
      Class aClass = NSClassFromString(_className);
      if(aClass == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@'", _className];
	}
      else
	{
	  _view = [[aClass allocWithZone: NSDefaultMallocZone()] initWithFrame: [self frame]];
	  [[self superview] replaceSubview: self with: _view]; // replace the old view...
	}
    }

  return _view;
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if(self != nil)
    {
      if([coder allowsKeyedCoding])
	{
	  _className = [coder decodeObjectForKey: @"NSClassName"];
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      [coder encodeObject: (id)_className forKey: @"NSClassName"];
    }
}
@end

@implementation NSCustomResource
- (void) setClassName: (NSString *)className
{
  ASSIGN(_className, className);
}

- (NSString *)className
{
  return _className;
}

- (void) setResourceName: (NSString *)resourceName
{
  ASSIGN(_resourceName, resourceName);
}

- (NSString *)resourceName
{
  return _resourceName;
}

- (id)nibInstantiate
{
  return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
  id realObject = nil;
  if([coder allowsKeyedCoding])
    {
      ASSIGN(_className, [coder decodeObjectForKey: @"NSClassName"]);
      ASSIGN(_resourceName, [coder decodeObjectForKey: @"NSResourceName"]);

      // this is a hack, but for now it should do.
      if([_className isEqual: @"NSSound"])
	{
	  realObject = [NSSound soundNamed: _resourceName];
	}
      else if([_className isEqual: @"NSImage"])
	{
	  realObject = [NSImage imageNamed: _resourceName];
	}

      // if an object has been substituted, then release the placeholder.
      if(realObject != nil)
	{
	  RELEASE(self);
	}
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
		   NSStringFromClass([coder class])];
    }

  return realObject;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      [coder encodeObject: (id)_className forKey: @"NSClassName"];
      [coder encodeObject: (id)_resourceName forKey: @"NSResourceName"];
    }
}
@end

@interface NSKeyedUnarchiver (NSClassSwapperPrivate)
- (BOOL) replaceObject: (id)oldObj withObject: (id)newObj;
@end

@implementation NSClassSwapper
- (void) setTemplate: (id)temp
{
  ASSIGN(_template, temp);
}

- (id) template
{
  return _template;
}

- (void) setClassName: (NSString *)className
{
  ASSIGN(_className, className);
}

- (NSString *)className
{
  return _className;
}

+ (BOOL) isInInterfaceBuilder
{
  return NO;
}

- (void) instantiateRealObject: (NSCoder *)coder withClassName: (NSString *)className
{
  Class aClass = NSClassFromString(className);
  id object = nil;
  Class newCellClass = nil;
  NSString *origCellClassName = nil; 
  Class origCellClass = nil;

  if(aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"NSClassSwapper unable to find class '%@'", className];
    }

  // if this is a class which uses cells, override with the new cellClass, if the 
  // subclass responds to cellClass.
  if([aClass respondsToSelector: @selector(cellClass)] && 
     [className isEqualToString: _originalClassName] == NO)
    {
      Class origClass = NSClassFromString(_originalClassName);

      origCellClass = [origClass cellClass];
      newCellClass = [aClass cellClass];
      origCellClassName = NSStringFromClass(origCellClass);
      [(NSKeyedUnarchiver *)coder setClass: newCellClass forClassName: origCellClassName];
    }

  // swap the class...
  object = [aClass allocWithZone: NSDefaultMallocZone()];
  [(NSKeyedUnarchiver *)coder replaceObject: self withObject: object];
  _template = [object initWithCoder: coder];
  if(object != _template)
    {
      [(NSKeyedUnarchiver *)coder replaceObject: object withObject: _template];
    }

  if(newCellClass != nil && origCellClass != nil)
    {
      [(NSKeyedUnarchiver *)coder setClass: origCellClass forClassName: nil];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      ASSIGN(_className, [coder decodeObjectForKey: @"NSClassName"]);  
      ASSIGN(_originalClassName, [coder decodeObjectForKey: @"NSOriginalClassName"]);  

      // build the real object...
      if([NSClassSwapper isInInterfaceBuilder] == YES)
	{
	  [self instantiateRealObject: coder withClassName: _originalClassName];
	}
      else
	{
	  [self instantiateRealObject: coder withClassName: _className];
	}
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
		   NSStringFromClass([coder class])];
    }

  return _template;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      NSString *originalClassName = NSStringFromClass(_template);
      [coder encodeObject: (id)_className forKey: @"NSClassName"];
      [coder encodeObject: (id)originalClassName forKey: @"NSOriginalClassName"];
    }
}
@end

/* Correct some instances where the ":" is missing from the method name in the label */
@interface NSNibControlConnector (NibCompatibility)
- (void) instantiateWithInstantiator: (id<GSInstantiator>)instantiator;
@end

@implementation NSNibControlConnector (NibCompatibility)
- (void) instantiateWithInstantiator: (id<GSInstantiator>)instantiator
{
  NSRange colonRange = [_tag rangeOfString: @":"];
  unsigned int location = colonRange.location;
  
  if(location == NSNotFound)
    {
      NSString *newTag = [NSString stringWithFormat: @"%@:",_tag];
      [self setLabel: (id)newTag];
    }

  [super instantiateWithInstantiator: instantiator];
}
@end

@implementation NSIBObjectData
- (id)instantiateObject: (id)obj
{
  id newObject = obj;
  if([obj respondsToSelector: @selector(nibInstantiate)])
    {
      newObject = [obj nibInstantiate];
      if([newObject respondsToSelector: @selector(awakeFromNib)])
	{
	  // awaken the object.
	  [newObject awakeFromNib];
	}
    }
  return newObject;
}

- (void) nibInstantiateWithOwner: (id)owner
{
  [self nibInstantiateWithOwner: owner topLevelObjects: nil];
}

- (void) nibInstantiateWithOwner: (id)owner topLevelObjects: (NSMutableArray *)topLevelObjects
{
  NSEnumerator *en = [_connections objectEnumerator];
  id obj = nil;
  id menu = nil;

  // replace the owner with the actual instance provided.
  [_root setObject: owner];
  
  // iterate over connections, instantiate, and then establish them.
  while((obj = [en nextObject]) != nil)
    {
      if([obj respondsToSelector: @selector(instantiateWithInstantiator:)])
	{
	  [obj instantiateWithInstantiator: self];	  
	  [obj establishConnection];
	}
    }

  en = [_visibleWindows objectEnumerator];
  while((obj = [en nextObject]) != nil)
    {
      id w = [self instantiateObject: obj];
      [w orderFront: self];
    }

  menu = [self objectForName: @"MainMenu"];
  if(menu != nil)
    {
      menu = [self instantiateObject: menu];
      [NSApp setMainMenu: menu];
    }
}

- (void) awakeWithContext: (NSDictionary *)context
{
  NSMutableArray *tlo = [context objectForKey: @"NSTopLevelObjects"];
  id owner = [context objectForKey: @"NSOwner"];
  [self nibInstantiateWithOwner: owner topLevelObjects: tlo];
}

- (NSMutableArray *) connections
{
  return _connections;
}

- (NSMutableSet *) topLevelObjects
{
  return nil;
}

- (NSMutableDictionary *) nameTable
{
  return nil;
}

- (id) objectForName: (NSString *)name
{
  NSArray *nameKeys = (NSArray *)NSAllMapTableKeys(_names);
  NSArray *nameValues = (NSArray *)NSAllMapTableValues(_names);
  int i = [nameValues indexOfObject: name];
  id result = nil;

  if(i != NSNotFound)
    {
      result = [nameKeys objectAtIndex: i];
    }

  return result;
}

- (NSString *) nameForObject: (id)obj
{
  NSArray *nameKeys = (NSArray *)NSAllMapTableKeys(_names);
  NSArray *nameValues = (NSArray *)NSAllMapTableValues(_names);
  int i = [nameKeys indexOfObject: obj];
  NSString *result = [nameValues objectAtIndex: i];
  return result;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      NSArray *accessibilityOidsKeys = (NSArray *)NSAllMapTableKeys(_accessibilityOids);
      NSArray *accessibilityOidsValues = (NSArray *)NSAllMapTableValues(_accessibilityOids);
      NSArray *classKeys = (NSArray *)NSAllMapTableKeys(_classes);
      NSArray *classValues = (NSArray *)NSAllMapTableValues(_classes);
      NSArray *nameKeys = (NSArray *)NSAllMapTableKeys(_names);
      NSArray *nameValues = (NSArray *)NSAllMapTableValues(_names);
      NSArray *objectsKeys = (NSArray *)NSAllMapTableKeys(_objects);
      NSArray *objectsValues = (NSArray *)NSAllMapTableValues(_objects);
      NSArray *oidsKeys = (NSArray *)NSAllMapTableKeys(_oids);
      NSArray *oidsValues = (NSArray *)NSAllMapTableValues(_oids);

      [coder encodeObject: (id)_accessibilityConnectors forKey: @"NSAccessibilityConnectors"];
      [coder encodeObject: (id) accessibilityOidsKeys forKey: @"NSAccessibilityOidsKeys"];
      [coder encodeObject: (id) accessibilityOidsValues forKey: @"NSAccessibilityOidsValues"];
      [coder encodeObject: (id) classKeys forKey: @"NSClassesKeys"];
      [coder encodeObject: (id) classValues forKey: @"NSClassesValues"];
      [coder encodeObject: (id) nameKeys forKey: @"NSNamesKeys"];
      [coder encodeObject: (id) nameValues forKey: @"NSNamesValues"];
      [coder encodeObject: (id) objectsKeys forKey: @"NSObjectsKeys"];
      [coder encodeObject: (id) objectsValues forKey: @"NSObjectsValues"];
      [coder encodeObject: (id) oidsKeys forKey: @"NSOidsKeys"];
      [coder encodeObject: (id) oidsValues forKey: @"NSOidsValues"];
      [coder encodeObject: (id) _connections forKey: @"NSConnections"];
      [coder encodeConditionalObject: (id) _fontManager forKey: @"NSFontManager"];
      [coder encodeConditionalObject: (id) _framework forKey: @"NSFramework"];
      [coder encodeObject: (id) _visibleWindows forKey: @"NSVisibleWindows"];
      [coder encodeInt: _nextOid forKey: @"NSNextOid"];
      [coder encodeConditionalObject: (id) _root forKey: @"NSRoot"];
    }
}

- (void) _buildMap: (NSMapTable *)mapTable 
	  withKeys: (NSArray *)keys 
	 andValues: (NSArray *)values
{
  NSEnumerator *ken = [keys objectEnumerator];
  NSEnumerator *ven = [values objectEnumerator];
  id key = nil;
  id value = nil;
  
  while((key = [ken nextObject]) != nil && (value = [ven nextObject]) != nil)
    {
      NSMapInsert(mapTable, key, value);
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      ASSIGN(_root, [coder decodeObjectForKey: @"NSRoot"]);
      ASSIGN(_visibleWindows,  (NSMutableArray *)[coder decodeObjectForKey: @"NSVisibleWindows"]);
      ASSIGN(_accessibilityConnectors, (NSMutableArray *)[coder decodeObjectForKey: @"NSAccessibilityConnectors"]);
      ASSIGN(_fontManager, [coder decodeObjectForKey: @"NSFontManager"]);
      ASSIGN(_framework, [coder decodeObjectForKey: @"NSFramework"]);
      ASSIGN(_connections,  (NSMutableArray *)[coder decodeObjectForKey: @"NSConnections"]);
      _nextOid = [coder decodeIntForKey: @"NSNextOid"];

      {
	NSArray *objectsKeys = (NSArray *)
	  [coder decodeObjectForKey: @"NSObjectsKeys"];
	NSArray *objectsValues = (NSArray *)
	  [coder decodeObjectForKey: @"NSObjectsValues"];
	NSArray *nameKeys = (NSArray *)
	  [coder decodeObjectForKey: @"NSNamesKeys"];
	NSArray *nameValues = (NSArray *)
	  [coder decodeObjectForKey: @"NSNamesValues"];
	NSArray *oidsKeys = (NSArray *)
	  [coder decodeObjectForKey: @"NSOidsKeys"];
	NSArray *oidsValues = (NSArray *)
	  [coder decodeObjectForKey: @"NSOidsValues"];
	NSArray *classKeys = (NSArray *)
	  [coder decodeObjectForKey: @"NSClassesKeys"];
	NSArray *classValues = (NSArray *)
	  [coder decodeObjectForKey: @"NSClassesValues"];
	NSArray *accessibilityOidsKeys = (NSArray *)
	  [coder decodeObjectForKey: @"NSAccessibilityOidsKeys"];
	NSArray *accessibilityOidsValues = (NSArray *)
	  [coder decodeObjectForKey: @"NSAccessibilityOidsValues"];      
	
	// instantiate the maps..
	_objects = NSCreateMapTable(NSObjectMapKeyCallBacks,
				    NSObjectMapValueCallBacks, 2);
	_names = NSCreateMapTable(NSObjectMapKeyCallBacks,
				  NSObjectMapValueCallBacks, 2);
	_oids = NSCreateMapTable(NSObjectMapKeyCallBacks,
				 NSObjectMapValueCallBacks, 2);
	_classes = NSCreateMapTable(NSObjectMapKeyCallBacks,
				    NSObjectMapValueCallBacks, 2);
	_accessibilityOids = NSCreateMapTable(NSObjectMapKeyCallBacks,
					      NSObjectMapValueCallBacks, 2);
	
	// fill in the maps...
	[self _buildMap: _accessibilityOids withKeys: accessibilityOidsKeys andValues: accessibilityOidsValues];
	[self _buildMap: _classes withKeys: classKeys andValues: classValues];
	[self _buildMap: _names withKeys: nameKeys andValues: nameValues];
	[self _buildMap: _objects withKeys: objectsKeys andValues: objectsValues];
	[self _buildMap: _oids withKeys: oidsKeys andValues: oidsValues];
      }
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
		   NSStringFromClass([coder class])];
    }
 
  return self;
}

- (id) init
{
  if((self = [super init]) != nil)
    {
      // instantiate the maps..
      _objects = NSCreateMapTable(NSObjectMapKeyCallBacks,
				  NSObjectMapValueCallBacks, 2);
      _names = NSCreateMapTable(NSObjectMapKeyCallBacks,
				NSObjectMapValueCallBacks, 2);
      _oids = NSCreateMapTable(NSObjectMapKeyCallBacks,
			       NSObjectMapValueCallBacks, 2);
      _classes = NSCreateMapTable(NSObjectMapKeyCallBacks,
				  NSObjectMapValueCallBacks, 2);
      _accessibilityOids = NSCreateMapTable(NSObjectMapKeyCallBacks,
					    NSObjectMapValueCallBacks, 2);  

      // initialize the objects...
      _accessibilityConnectors = [[NSMutableArray alloc] init];
      _connections = [[NSMutableArray alloc] init];
      _visibleWindows = [[NSMutableArray alloc] init];
      _framework = nil;
      _fontManager = nil;
      _root = nil;
      _nextOid = 0;
    }
  return self;
}

- (void) dealloc
{
  // free the maps.
  NSFreeMapTable(_objects);
  NSFreeMapTable(_names);
  NSFreeMapTable(_oids);
  NSFreeMapTable(_classes);
  NSFreeMapTable(_accessibilityOids);

  // free other objects.
  RELEASE(_accessibilityConnectors);
  RELEASE(_connections);
  RELEASE(_fontManager);
  RELEASE(_framework);
  RELEASE(_visibleWindows);
  RELEASE(_root);
  [super dealloc];
}

- (void) setRoot: (id) root
{
  ASSIGN(_root, root);
}

- (id) root
{
  return _root;
}
@end

@interface NSButtonImageSource : NSObject <NSCoding>
{
  NSString *imageName;
}
- (NSString *)imageName;
@end

@implementation NSButtonImageSource
- (id) initWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      ASSIGN(imageName, [coder decodeObjectForKey: @"NSImageName"]);
    }
  RELEASE(self);
  return [NSImage imageNamed: imageName];
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      [coder encodeObject: imageName forKey: @"NSImageName"];
    }
}

- (NSString *)imageName
{
  return imageName;
}

- (void) dealloc
{
  RELEASE(imageName);
  [super dealloc];
}
@end

// ...dummy/placeholder classes...
// overridden in NSTableView to be GSTableCornerView, 
// but the class needs to be present to be overridden.
@interface _NSCornerView : NSView
@end

@implementation _NSCornerView
@end

@interface NSKeyedUnarchiver (GSNibCompatibilityAdditions)
- (NSDictionary *)keyMap;
@end

@implementation NSKeyedUnarchiver (GSNibCompatibilityAdditions)
- (NSDictionary *)keyMap
{
  return _keyMap;
}
@end
