/** <title>GSNibCompatibility</title>

   <abstract>
   These are templates for use with OSX Nib files.  These classes are the
   templates and other things which are needed for reading/writing nib files.
   </abstract>

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author: Gregory John Casamento
   Date: Oct 2003

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

/*
  As these classes are deprecated, they should disappear from the gnustep distribution
  in the next major release.
*/

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
  RELEASE(_title);
  [super dealloc];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      if ([aDecoder containsValueForKey: @"NSViewClass"])
        {
	  _viewClass = RETAIN([aDecoder decodeObjectForKey: @"NSViewClass"]);
	}
      if ([aDecoder containsValueForKey: @"NSWindowClass"])
        {
	  _windowClass = RETAIN([aDecoder decodeObjectForKey: @"NSWindowClass"]);
	}
      if ([aDecoder containsValueForKey: @"NSWindowStyleMask"])
        {
	  _interfaceStyle = [aDecoder decodeIntForKey: @"NSWindowStyleMask"];
	}
      if([aDecoder containsValueForKey: @"NSWindowBacking"])
	{
	  _backingStoreType = [aDecoder decodeIntForKey: @"NSWindowBacking"];
	}
      if ([aDecoder containsValueForKey: @"NSWindowView"])
        {
	  _view = RETAIN([aDecoder decodeObjectForKey: @"NSWindowView"]);
	}
      if ([aDecoder containsValueForKey: @"NSWTFlags"])
        {
	  _flags = [aDecoder decodeIntForKey: @"NSWTFlags"];
	}
      if ([aDecoder containsValueForKey: @"NSMinSize"])
        {
	  _minSize = [aDecoder decodeSizeForKey: @"NSMinSize"];
	}
      if ([aDecoder containsValueForKey: @"NSMaxSize"])
        {
	  _maxSize = [aDecoder decodeSizeForKey: @"NSMaxSize"];
	}
      if ([aDecoder containsValueForKey: @"NSWindowTitle"])
        {
	  _title = RETAIN([aDecoder decodeObjectForKey: @"NSWindowTitle"]);
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
    }
}

- (id) nibInstantiate
{
  Class aClass = NSClassFromString(_windowClass);      
  
  if (aClass == nil)
    {
	[NSException raise: NSInternalInconsistencyException
		     format: @"Unable to find class '%@'", _windowClass];
    }
  
  _realObject = [[aClass allocWithZone: NSDefaultMallocZone()]
		  initWithContentRect: _windowRect
		  styleMask: _interfaceStyle
		  backing: _backingStoreType
		  defer: _deferFlag
		  screen: nil];

  // reset attributes...
  [_realObject setContentView: _view];
  [_realObject setMinSize: _minSize];
  [_realObject setMaxSize: _maxSize];
  [_realObject setTitle: _title];

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
  _deferFlag = flag;
}

- (BOOL) isDeferred
{
  return _deferFlag;
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

- (void) setInterfaceStyle: (unsigned)style
{
  _interfaceStyle = style;
}

- (unsigned) interfaceStyle
{
  return _interfaceStyle;
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

- (id) initWithCoder: (NSCoder *)aCoder
{
  return nil;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
}

- (id) nibInstantiate
{
  Class       aClass = NSClassFromString(_className);

  if (aClass == nil)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find class '%@'", _className];
    }

  _realObject =  [[aClass allocWithZone: NSDefaultMallocZone()]
		   initWithFrame: _frame];
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

- initWithFrame: (NSRect)frame
{
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  return nil;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
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

- (id) initWithCoder: (NSCoder *)aCoder
{
  return nil;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
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
  /*
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
  RETAIN(obj);

  return obj;
  */
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

- (id) initWithCoder: (NSCoder *)coder
{
  Class aClass;
  _className = [coder decodeObjectForKey: @"NSClassName"];
  aClass = NSClassFromString(_className);
  if(aClass == nil)
    {
	[NSException raise: NSInternalInconsistencyException
		     format: @"Unable to find class '%@'", _className];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeObject: (id)_className forKey: @"NSClassName"];
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
  return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if(self != nil)
    {
      Class aClass;
      _className = [coder decodeObjectForKey: @"NSClassName"];
      aClass = NSClassFromString(_className);
      if(aClass == nil)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Unable to find class '%@'", _className];
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeObject: (id)_className forKey: @"NSClassName"];
}
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

- (id) initWithCoder: (NSCoder *)coder
{
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}
@end

@implementation NSIBObjectData
- (id)instantiateObject: (id)obj
{
  return nil;
}

- (void) nibInstantiateWithOwner: (id)owner
{
}

- (void) nibInstantiateWithOwner: (id)owner topLevelObjects: (id)toplevel
{
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
      [coder encodeObject: (id) _fontManager forKey: @"NSFontManager"];
      [coder encodeObject: (id) _framework forKey: @"NSFramework"];
      [coder encodeObject: (id) _visibleWindows forKey: @"NSVisibleWindows"];
      [coder encodeInt: _nextOid forKey: @"NSNextOid"];
      [coder encodeObject: (id) _root forKey: @"NSRoot"];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      NSMutableArray *accessibilityOidsKeys = (NSMutableArray *)
	[coder decodeObjectForKey: @"NSAccessibilityOidsKeys"];
      NSMutableArray *accessibilityOidsValues = (NSMutableArray *)
	[coder decodeObjectForKey: @"NSAccessibilityOidsValues"];      
      NSMutableArray *classKeys = (NSMutableArray *)[coder decodeObjectForKey: @"NSClassesKeys"];
      NSMutableArray *classValues = (NSMutableArray *)[coder decodeObjectForKey: @"NSClassesValues"];
      NSMutableArray *nameKeys = (NSMutableArray *)[coder decodeObjectForKey: @"NSNamesKeys"];
      NSMutableArray *nameValues = (NSMutableArray *)[coder decodeObjectForKey: @"NSNamesValues"];
      NSMutableArray *objectsKeys = (NSMutableArray *)[coder decodeObjectForKey: @"NSObjectsKeys"];
      NSMutableArray *objectsValues = (NSMutableArray *)[coder decodeObjectForKey: @"NSObjectsValues"];
      NSMutableArray *oidsKeys = (NSMutableArray *)[coder decodeObjectForKey: @"NSOidsKeys"];
      NSMutableArray *oidsValues = (NSMutableArray *)[coder decodeObjectForKey: @"NSOidsValues"];
      
      _accessibilityConnectors = (NSMutableArray *)[coder decodeObjectForKey: @"NSAccessibilityConnectors"];
      _connections = [coder decodeObjectForKey: @"NSConnections"];
      _fontManager = [coder decodeObjectForKey: @"NSFontManager"];
      _framework = [coder decodeObjectForKey: @"NSFramework"];
      _visibleWindows = [coder decodeObjectForKey: @"NSVisibleWindows"];
      _nextOid = [coder decodeIntForKey: @"NSNextOid"];
      _root = [coder decodeObjectForKey: @"NSRoot"];
    }

  return self;
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
