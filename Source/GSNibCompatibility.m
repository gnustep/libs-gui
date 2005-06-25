/** <title>GSNibCompatibility</title>

   <abstract>
   This file contains the classes necessary for compatibility with OSX nib
   files.
   </abstract>

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author: Gregory John Casamento
   Date: Oct 2003, Jun 2005

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
#include <AppKit/AppKit.h>

#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepGUI/GSNibCompatibility.h>
#include <GNUstepGUI/GSNibTemplates.h>

/** These classes are for compatibility with OSX nibs. */

@interface NSObject (GSNibCompatibility)
- (BOOL) isInInterfaceBuilder;
@end

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
  if((self = [super init]) != nil)
    {      
      // Start initially with the highest level class
      ASSIGN(_className, NSStringFromClass([super class]));
 
      // defer flag
      _deferFlag = NO;

      // real object...
      _realObject = nil;
    }

  return self;
}

- (id) initWithObject: (id)object className: (NSString *)className
{
  if((self = [self init]) != nil)
    {
      NSDebugLog(@"Created template %@ -> %@",NSStringFromClass([self class]), className);
      ASSIGN(_realObject, object);
      ASSIGN(_className, className);
    }
  return self;
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  id obj = nil;
  if ([aDecoder allowsKeyedCoding])
    {
      NSRect windowRect = [aDecoder decodeRectForKey: @"NSWindowRect"];
      int style = [aDecoder decodeIntForKey: @"NSWindowStyleMask"];
      int backing = [aDecoder decodeIntForKey: @"NSWindowBacking"];
      
      // the class
      _className = [aDecoder decodeObjectForKey: @"NSWindowClass"];

      // if we're not in interface builder...
      if([self respondsToSelector: @selector(isInInterfaceBuilder)] == NO)
	{
	  if([self isInInterfaceBuilder] == NO)
	    {
	      Class cls = NSClassFromString(_className);
	      
	      // if we've got the class...
	      if(cls != nil)
		{
		  // instantiate the object...
		  obj = [cls alloc];
		  
		  // if the obj responds to the designated init.
		  if(GSGetMethod([obj class], @selector(initWithContentRect:styleMask:backing:defer:), YES, NO) != NULL
		     && !([_className isEqualToString: @"NSWindow"] || [_className isEqualToString: @"NSPanel"]))
		    {
		      // call the object's initializer...
		      obj = [obj initWithContentRect: windowRect
				 styleMask: style
				 backing: backing
				 defer: NO
				 screen: nil];
		    }
		}
	    }
	}
      else
	{
	  // instantiate a window...  
	  obj = [NSWindow alloc];
	}

      // initialize the object from the template...
      if(obj != nil)
	{
	  if ([aDecoder containsValueForKey: @"NSWindowView"])
	    {
	      [(NSWindow *)obj setContentView: 
		     [aDecoder decodeObjectForKey: @"NSWindowView"]];	  
	    }
	  if ([aDecoder containsValueForKey: @"NSWTFlags"])
	    {
	      // int flags = [aDecoder decodeIntForKey: @"NSWTFlags"];
	      // TODO: Decode flags properly.
	    }
	  if ([aDecoder containsValueForKey: @"NSMinSize"])
	    {
	      NSSize minSize = [aDecoder decodeSizeForKey: @"NSMinSize"];
	      [obj setMinSize: minSize];
	    }
	  if ([aDecoder containsValueForKey: @"NSMaxSize"])
	    {
	      NSSize maxSize = [aDecoder decodeSizeForKey: @"NSMaxSize"];
	      [obj setMaxSize: maxSize];
	    }
	  if ([aDecoder containsValueForKey: @"NSWindowTitle"])
	    {
	      [obj setTitle: [aDecoder decodeObjectForKey: @"NSWindowTitle"]];
	    }

	  RELEASE(self); // release template.
	}
    }
  else
    {
      // raise an exception, since we do not want to handle non-keyed archiving.
      [NSException raise: NSInvalidArgumentException
		   format: @"%@ cannot handle keyed archiving/unarchiving.",
		   aDecoder];
    }

  return obj;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  if([aCoder allowsKeyedCoding])
    {
    }
  else
    {
      // raise an exception, since we do not want to handle non-keyed archiving.
      [NSException raise: NSInvalidArgumentException
		   format: @"%@ cannot handle keyed archiving/unarchiving.",
		   aCoder];
    }
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
  if((self = [super initWithFrame: frame]) != nil)
    {
      // Start initially with the highest level class
      ASSIGN(_className, NSStringFromClass([super class]));
    }

  return self;
}

- (id) initWithObject: (id)object className: (NSString *)className
{
  if((self = [self init]) != nil)
    {
      NSDebugLog(@"Created template %@ -> %@",NSStringFromClass([self class]), className);
      ASSIGN(_realObject, object);
      ASSIGN(_className, className);
    }
  return self;
}

- init
{
  // Start initially with the highest level class
  if((self = [super init]) != nil)
    {
      ASSIGN(_className, NSStringFromClass([super class]));
    }
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
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
  if((self = [super initWithFrame: frame]) != nil)
    {
      // Start initially with the highest level class
      ASSIGN(_className, NSStringFromClass([super class]));
    }
  return self;
}

- init
{
  // Start initially with the highest level class
  if((self = [super init]) != nil)
    {
      ASSIGN(_className, NSStringFromClass([super class]));
    }
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
}

// accessor methods
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
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
  if((self = [super initWithFrame: frame]) != nil)
    {
      // Start initially with the highest level class
      ASSIGN(_className, NSStringFromClass([super class]));
    }
  return self;
}

- init
{
  if((self = [super init]) != nil)
    {
      ASSIGN(_className, NSStringFromClass([super class]));
    }
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  return [super initWithCoder: aCoder];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
}

// accessors
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
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
  if((self = [super init]) != nil)
    {
      // Start initially with the highest level class
      ASSIGN(_className, NSStringFromClass([super class]));
    }
  return self;
}

- (id) initWithObject: (id)object className: (NSString *)className
{
  if((self = [self init]) != nil)
    {
      NSDebugLog(@"Created template %@ -> %@",NSStringFromClass([self class]), className);
      ASSIGN(_realObject, object);
      ASSIGN(_className, className);
    }
  return self;
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  return nil;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
}

// accessors
- (void) setClassName: (NSString *)name
{
  ASSIGN(_className, name);
}

- (NSString *)className
{
  return _className;
}
@end

