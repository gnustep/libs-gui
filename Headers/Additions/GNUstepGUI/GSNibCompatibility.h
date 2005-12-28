/* 
   GSNibCompatibility.h

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2002
   
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
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/ 

#ifndef _GNUstep_H_GSNibCompatibility
#define _GNUstep_H_GSNibCompatibility

#include <Foundation/NSObject.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSView.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSButton.h>

#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSEvent.h>

// templates
@protocol OSXNibTemplate
- (void) setClassName: (NSString *)className;
- (NSString *)className;
- (id) realObject;
@end

/**
 * This class acts as a placeholder for the window.  It doesn't derive from
 * NSWindow for two reasons. First, it shouldn't instantiate a window immediately
 * when it's unarchived and second, it holds certain attributes (but doesn't set them
 * on the window, when the window is being edited in the application builder.
 */
@interface NSWindowTemplate : NSObject <OSXNibTemplate, NSCoding>
{
  NSBackingStoreType   _backingStoreType;
  BOOL                 _deferFlag;
  NSSize               _maxSize;
  NSSize               _minSize;
  unsigned             _interfaceStyle;
  NSString            *_title;
  NSString            *_viewClass;
  NSString            *_windowClass;
  NSRect               _windowRect;
  NSRect               _screenRect;
  id                   _realObject;
  id                   _view;
  unsigned             _flags;
}
- (void) setBackingStoreType: (NSBackingStoreType)type;
- (NSBackingStoreType) backingStoreType;
- (void) setDeferred: (BOOL)flag;
- (BOOL) isDeferred;
- (void) setMaxSize: (NSSize)maxSize;
- (NSSize) maxSize;
- (void) setMinSize: (NSSize)minSize;
- (NSSize) minSize;
- (void) setInterfaceStyle: (unsigned)sty;
- (unsigned) interfaceStyle;
- (void) setTitle: (NSString *) title;
- (NSString *)title;
- (void) setViewClass: (NSString *)viewClass;
- (NSString *)viewClass;
- (void) setWindowRect: (NSRect)rect;
- (NSRect)windowRect;
- (void) setScreenRect: (NSRect)rect;
- (NSRect) screenRect;
- (id) realObject;
- (void) setView: (id)view;
- (id) view;
@end

@interface NSViewTemplate : NSView <OSXNibTemplate, NSCoding>
{
  NSString            *_className;
  id                   _realObject;
  NSRect               _frame;
}
@end

@interface NSTextTemplate : NSViewTemplate
{
}
@end

@interface NSTextViewTemplate : NSViewTemplate
{
}
@end

@interface NSMenuTemplate : NSObject <OSXNibTemplate, NSCoding>
{
  NSString            *_menuClass;
  NSString            *_title;
  id                   _realObject;
  id                   _parentMenu;
  NSPoint              _location;
  BOOL                 _isWindowsMenu;
  BOOL                 _isServicesMenu;
  BOOL                 _isFontMenu;
  NSInterfaceStyle     _interfaceStyle;
}
@end

@interface NSIBObjectData : NSObject <NSCoding>
{
  id              _root;
  NSMapTable     *_objects;
  NSMapTable     *_names;
  NSMapTable     *_oids;
  NSMapTable     *_classes;
  NSMapTable     *_instantiatedObjs;
  NSMutableSet   *_visibleWindows;
  NSMutableArray *_connections;
  id              _firstResponder;
  id              _fontManager;
  NSString       *_framework;
  id              _document;
  unsigned        _nextOid;
  NSMutableArray *_accessibilityConnectors;
  NSMapTable     *_accessibilityOids;
}
- (id)instantiateObject: (id)obj;
- (void) nibInstantiateWithOwner: (id)owner;
- (void) nibInstantiateWithOwner: (id)owner topLevelObjects: (id)toplevel;
@end

#endif /* _GNUstep_H_GSNibCompatibility */
