/** <title>GSNibCompatibility</title>

   <abstract>
   These are the old template classes which were used in older .gorm files.
   All of these classes are deprecated and should not be used directly. 
   They will be removed from the GUI library in the next few versions as
   they need to be phased out gradually.
   <p/>
   If you have any .gorm files which were created using custom classes, you
   should load them into Gorm and save them so that they will use the new
   system.   Updating the .gorm files should be as easy as that.   These
   classes are included ONLY for backwards compatibility.
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
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

//////////////////////////////////////////////////////////////////////////////////////////
////////////////// DEPRECATED TEMPLATES ----- THESE SHOULD NOT BE USED  //////////////////
//////////////////////////////////////////////////////////////////////////////////////////

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
  RELEASE(_parentClassName);
  RELEASE(_className);
  [super dealloc];
}

- init
{
  [super init];

  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));

  // defer flag...
  _deferFlag = NO;

  return self;
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
    /**/
  if ([aDecoder allowsKeyedCoding])
    {
      //NSRect screenRect = [aDecoder decodeRectForKey: @"NSScreenRect"];
      NSRect windowRect = [aDecoder decodeRectForKey: @"NSWindowRect"];
      //NSString *viewClass = [aDecoder decodeObjectForKey: @"NSViewClass"];
      NSString *windowClass = [aDecoder decodeObjectForKey: @"NSWindowClass"];
      int style = [aDecoder decodeIntForKey: @"NSWindowStyleMask"];
      int backing = [aDecoder decodeIntForKey: @"NSWindowBacking"];
      
      ASSIGN(_className, windowClass);
      self = [self initWithContentRect: windowRect
			     styleMask: style
			       backing: backing
				 defer: NO
				screen: nil];

      if ([aDecoder containsValueForKey: @"NSWindowView"])
        {
	    [self setContentView: 
		      [aDecoder decodeObjectForKey: @"NSWindowView"]];	  
	}
      if ([aDecoder containsValueForKey: @"NSWTFlags"])
        {
	  //int flags = [aDecoder decodeIntForKey: @"NSWTFlags"];
	}
      if ([aDecoder containsValueForKey: @"NSMinSize"])
        {
	  NSSize minSize = [aDecoder decodeSizeForKey: @"NSMinSize"];
	  [self setMinSize: minSize];
	}
      if ([aDecoder containsValueForKey: @"NSMaxSize"])
        {
	  NSSize maxSize = [aDecoder decodeSizeForKey: @"NSMaxSize"];
	  [self setMaxSize: maxSize];
	}
      if ([aDecoder containsValueForKey: @"NSWindowTitle"])
        {
	  [self setTitle: [aDecoder decodeObjectForKey: @"NSWindowTitle"]];
	}

      return self;
    }
  else
    {
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_className];  
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_parentClassName];  
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_deferFlag];  
      return [super initWithCoder: aDecoder];
    }
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
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      // if we live in the interface builder, give them an instance of
      // the parent, not the child..
      [self setClassName: _parentClassName];
    }
  
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
  [(NSWindow*)obj setContentView: [self contentView]];
  [obj setFrameAutosaveName: [self frameAutosaveName]];
  [obj setHidesOnDeactivate: [self hidesOnDeactivate]];
  [obj setInitialFirstResponder: [self initialFirstResponder]];
  [obj setAutodisplay: [self isAutodisplay]];
  [obj setReleasedWhenClosed: [self isReleasedWhenClosed]];
  [obj _setVisible: [self isVisible]];
  [obj setTitle: [self title]];
  [obj setFrame: [self frame] display: NO];
  
  RELEASE(self);
  RETAIN(obj);

  return obj;
}

// setters and getters...
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
  RELEASE(_parentClassName);
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  [super initWithFrame: frame];

  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
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
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      // if we live in the interface builder, give them an instance of
      // the parent, not the child..
      [self setClassName: _parentClassName];
    }
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
  RETAIN(obj);

  return obj;
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
  RELEASE(_parentClassName);
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  [super initWithFrame: frame];
  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
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
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      // if we live in the interface builder, give them an instance of
      // the parent, not the child..
      [self setClassName: _parentClassName];
    }
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
  RETAIN(obj);

  return obj;
}

// accessor methods...
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
  RELEASE(_parentClassName);
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  [super initWithFrame: frame];
  return self;
}

- init
{
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
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
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      // if we live in the interface builder, give them an instance of
      // the parent, not the child..
      [self setClassName: _parentClassName];
    }
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
  RETAIN(obj);

  return obj;
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
  RELEASE(_parentClassName);
  RELEASE(_className);
  [super dealloc];
}

- init
{
  [super init];
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
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
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      // if we live in the interface builder, give them an instance of
      // the parent, not the child..
      [self setClassName: _parentClassName];
    }
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
  RETAIN(obj);

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
  RELEASE(_parentClassName);
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  [super initWithFrame: frame];

  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
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
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      // if we live in the interface builder, give them an instance of
      // the parent, not the child..
      [self setClassName: _parentClassName];
    }
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
  RETAIN(obj);

  return obj;
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
  RELEASE(_parentClassName);
  RELEASE(_className);
  [super dealloc];
}

- initWithFrame: (NSRect)frame
{
  // Start initially with the highest level class...
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
  _buttonType = NSMomentaryLightButton;
  [super initWithFrame: frame];
  
  return self;
}

- init
{
  // Start initially with the highest level class...
  [super init];
  ASSIGN(_className, NSStringFromClass([super class]));
  ASSIGN(_parentClassName, NSStringFromClass([super class]));
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
  if([self respondsToSelector: @selector(isInInterfaceBuilder)])
    {
      // if we live in the interface builder, give them an instance of
      // the parent, not the child..
      [self setClassName: _parentClassName];
    }
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
  RETAIN(obj);

  return obj;
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
