/* 
   <title>NSToolbar.m</title>

   <abstract>The toolbar class.</abstract>
   
   Copyright (C) 2002 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>,
            Fabien Vallon <fabien.vallon@fr.alcove.com>
   Date: May 2002
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSView.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSNibLoading.h"

// internal
static NSNotificationCenter *nc = nil;
static const int current_version = 1;

@interface GSToolbarView : NSView
{
  NSToolbar *_toolbar;
}
- (void) setToolbar: (NSToolbar *)toolbar;
- (NSToolbar *) toolbar;
@end

@implementation GSToolbarView
- (void) setToolbar: (NSToolbar *)toolbar
{
  ASSIGN(_toolbar, toolbar);
}

- (NSToolbar *) toolbar
{
  return _toolbar;
}

- (void) drawRect: (NSRect)aRect
{
  [super drawRect: aRect];
}
@end

@interface GSToolbarButton : NSButton
{
  NSToolbarItem *_item;
}
@end

@implementation GSToolbarButton
- (id) initWithItem: (NSToolbarItem *)item
{
  [super init];
  ASSIGN(_item, item);
  return self;
}

- (void) dealloc
{
  RELEASE (_item);
  [super dealloc];
}

- (void) drawRect: (NSRect)aRect
{
  // set the image and draw using the super class...
  [super drawRect: aRect];
}
@end

@implementation NSToolbar (GNUstepPrivate)
- (GSToolbarView *) _toolbarView
{
  return _toolbarView;
}
@end


@implementation NSToolbar
// Initialize the class when it is loaded
+ (void) initialize
{
  if (self == [NSToolbar class])
    {
      [self setVersion: current_version];
      nc = [NSNotificationCenter defaultCenter];
    }
}

// Instance methods
- (BOOL) allowsUserCustomization
{
  return _allowsUserCustomization;
}

- (BOOL) autosavesConfiguration
{
  return _autosavesConfiguration;
}

- (NSDictionary *) configurationDictionary
{
  return _configurationDictionary;
}

- (BOOL) customizationPaletteIsRunning
{
  return _customizationPaletteIsRunning;
}

- (id) delegate
{
  return _delegate;
}

- (NSToolbarDisplayMode) displayMode
{
  return _displayMode;
}

- (NSString *) identifier
{
  return _identifier;
}

- (void) _loadConfig
{
  if(_identifier != nil)
    { 
      NSUserDefaults     *defaults;
      NSString           *tableKey;
      id                  config;
      
      defaults  = [NSUserDefaults standardUserDefaults];
      tableKey = [NSString stringWithFormat: @"NSToolbar Config %@", 
			   _identifier];
      config = [defaults objectForKey: tableKey];
      if (config != nil) 
	{
	  [self setConfigurationFromDictionary: config];
	}
    }
}


- (id) initWithIdentifier: (NSString*)identifier
{
  [super init];
  ASSIGN(_identifier, identifier);
  [self _loadConfig];
  
  return self;
}

- (void) dealloc
{
  DESTROY (_identifier);

  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
      _delegate = nil;
    }

  [super dealloc];
}


- (void) insertItemWithItemIdentifier: (NSString *)itemIdentifier
			      atIndex: (int)index
{
  NSToolbarItem *item = [_delegate toolbar: self 
				   itemForItemIdentifier: itemIdentifier
				   willBeInsertedIntoToolbar: YES];
  [nc postNotificationName: NSToolbarWillAddItemNotification
      object: self];
  [_items insertObject: item atIndex: index];
}

- (BOOL) isVisible
{
  return _visible;
}

- (NSArray *) items
{
  return _items;
}

- (void) removeItemAtIndex: (int)index
{
  
  id obj = [_items objectAtIndex: index]; 
  [_items removeObjectAtIndex: index];
  [_visibleItems removeObject: obj];
  [nc postNotificationName: NSToolbarDidRemoveItemNotification
      object: self];
}

- (void) runCustomizationPalette: (id)sender
{
  _customizationPaletteIsRunning = [NSBundle loadNibNamed: @"GSToolbarCustomizationPalette" 
					     owner: self];
}

- (void) setAllowsUserCustomization: (BOOL)flag
{
  _allowsUserCustomization = flag;
}

- (void) setAutosavesConfiguration: (BOOL)flag
{
  _autosavesConfiguration = flag;
}

- (void) setConfigurationFromDictionary: (NSDictionary *)configDict
{
  if(!_configurationDictionary)
    {
      RELEASE(_configurationDictionary);
    }
  ASSIGN(_configurationDictionary, configDict);
}

/**
 * Sets the receivers delgate ... this is the object which will receive
 * -toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:
 * -toolbarAllowedItemIdentifiers: and -toolbarDefaultItemIdentifiers:
 * messages.
 */
- (void) setDelegate: (id)delegate
{ 
#define CHECK_REQUIRED_METHOD(selector_name) \
  if (![delegate respondsToSelector: @selector(selector_name)]) \
    [NSException raise: NSInternalInconsistencyException \
                 format: @"delegate does not respond to %@",@#selector_name]

  CHECK_REQUIRED_METHOD(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:);
  CHECK_REQUIRED_METHOD(toolbarAllowedItemIdentifiers:);
  CHECK_REQUIRED_METHOD(toolbarDefaultItemIdentifiers:);

  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = delegate;


#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(toolbar##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(toolbar##notif_name:) \
      name: NSToolbar##notif_name##Notification object: self]
  
  SET_DELEGATE_NOTIFICATION(DidRemoveItem);
  SET_DELEGATE_NOTIFICATION(WillAddItem);
}

- (void) setDisplayMode: (NSToolbarDisplayMode)displayMode
{
  _displayMode = displayMode;
}

- (void) setVisible: (BOOL)shown
{
  _visible = shown;
}

- (void) validateVisibleItems
{
  NSEnumerator *en = [_visibleItems objectEnumerator];
  NSToolbarItem *item = nil;

  while((item = [en nextObject]) != nil)
    {
      [item validate];
    }
}

- (NSArray *) visibleItems
{
  return _visibleItems;
}
@end /* interface of NSToolbar */


