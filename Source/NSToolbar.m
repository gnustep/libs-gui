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
#include <Foundation/NSLock.h>
#include <Foundation/NSUserDefaults.h>
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSView.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSNibLoading.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSToolbarView.h"

// internal
static NSNotificationCenter *nc = nil;
static const int current_version = 1;

static NSMutableArray *toolbars;


@interface NSToolbar (GNUstepPrivate)
// Private class methods
+ (NSArray *) _toolbars;
+ (NSArray *) _toolbarsForIdentifier: (NSString *)identifier;

// ---

- (void) _insertItemWithItemIdentifier: (NSString *)itemIdentifier atIndex: (int)index broadcast: (BOOL)broadcast;

// Private methods with broacast support
- (void) _insertItemWithItemIdentifier: (NSString *)itemIdentifier atIndex: (int)index broadcast: (BOOL)broadcast;
- (void) _removeItemAtIndex: (int)index broadcast: (BOOL)broadcast;
- (void) _setAllowsUserCustomization: (BOOL)flag broadcast: (BOOL)broadcast;
- (void) _setAutosavesConfiguration: (BOOL)flag broadcast: (BOOL)broadcast;
- (void) _setConfigurationFromDictionary: (NSDictionary *)configDict broadcast: (BOOL)broadcast;
- (void) _setDisplayMode: (NSToolbarDisplayMode)displayMode broadcast: (BOOL)broadcast;
- (void) _setVisible: (BOOL)shown broadcast: (BOOL)broadcast;
- (void) _setDelegate: (id)delegate broadcast: (BOOL)broadcast;

// Few other private methods
- (void) _build;
- (void) _loadConfig;

// Accessors
- (void) _setToolbarView: (GSToolbarView *)toolbarView;
- (GSToolbarView *) _toolbarView;
- (void) _setWindow: (NSWindow *)window;
- (NSWindow *) _window;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (void) _setToolbar: (NSToolbar *)toolbar;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _reload;
- (NSArray *) _visibleBackViews;
- (BOOL) _willBeVisible;
- (void) _setWillBeVisible: (BOOL)willBeVisible;
@end

// ---

@implementation NSToolbar

// Class methods

// Initialize the class when it is loaded
+ (void) initialize
{
  if (self == [NSToolbar class])
    {
      [self setVersion: current_version];
      nc = [NSNotificationCenter defaultCenter];
      toolbars = [[NSMutableArray alloc] init];
    }
}

// Private class methods

+ (NSArray *) _toolbars
{
  return toolbars;
}

+ (NSArray *) _toolbarsForIdentifier: (NSString *)identifier
{
  NSMutableArray *wanted = [[NSMutableArray alloc] init];
  NSArray *identifiers = [toolbars valueForKey: @"identifier"];
  int i, n;
  
  if (identifiers == nil)
    return nil;
  
  n = [identifiers count];
  
  for (i = 0; i < n; i++)
    {
      if ([[identifiers objectAtIndex: i] isEqualToString: identifier])
        {
          [wanted addObject: [toolbars objectAtIndex: i]];
        }
    }
  
  return wanted;
}

// ---

// Instance methods

- (id) initWithIdentifier: (NSString*)identifier
{
  NSArray *linked;
  NSToolbar *toolbarModel = nil;
  
  [super init];
  
  ASSIGN(_identifier, identifier);
  
  _items = [[NSMutableArray alloc] init];

  linked = [NSToolbar _toolbarsForIdentifier: _identifier];
    
  if (linked != nil && [linked count] > 0)
    {
      toolbarModel = [linked objectAtIndex: 0];
    }
  
  if (toolbarModel != nil)
    {
      _customizationPaletteIsRunning = NO;
      _allowsUserCustomization = [toolbarModel allowsUserCustomization];
      _autosavesConfiguration = [toolbarModel autosavesConfiguration];
      ASSIGN(_configurationDictionary, [toolbarModel configurationDictionary]);
      _displayMode = [toolbarModel displayMode]; 
      _visible = [toolbarModel isVisible];
   
      //[self _loadConfig];
    
      [self _setDelegate: [toolbarModel delegate] broadcast: NO];
    }
  else
    {
      _customizationPaletteIsRunning = NO;
      _allowsUserCustomization = NO;
      _autosavesConfiguration = NO;
      _configurationDictionary = nil;
      _displayMode = NSToolbarDisplayModeDefault; 
      _visible = YES;
      _items = [[NSMutableArray alloc] init];
   
      [self _loadConfig];
    
       _delegate = nil;
    }
  
  [toolbars addObject: self];
  
  return self;
}

- (void) dealloc
{
  DESTROY (_identifier);
  DESTROY (_configurationDictionary);

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
  [self _insertItemWithItemIdentifier: itemIdentifier atIndex: index broadcast: YES];
}

- (void) removeItemAtIndex: (int)index
{
  [self _removeItemAtIndex: index broadcast: YES];
}

- (void) runCustomizationPalette: (id)sender
{
  _customizationPaletteIsRunning = [NSBundle loadNibNamed: @"GSToolbarCustomizationPalette" 
					     owner: self];
  if(!_customizationPaletteIsRunning)
    {
      NSLog(@"Failed to load gorm for GSToolbarCustomizationPalette");
    }
}

- (void) validateVisibleItems
{
  NSEnumerator *en = [[self visibleItems]  objectEnumerator];
  NSToolbarItem *item = nil;

  while((item = [en nextObject]) != nil)
    {
      [item validate];
    }
}

// Accessors

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

- (BOOL) isVisible
{
  return _visible;
}

- (NSArray *) items
{ 
  return _items;
}

- (NSString *) selectedItemIdentifier
{
  return nil;
}

- (NSArray *) visibleItems
{
  return [[_toolbarView _visibleBackViews] valueForKey: @"toolbarItem"];
}

- (void) setAllowsUserCustomization: (BOOL)flag
{
  [self _setAllowsUserCustomization: flag broadcast: YES];
}

- (void) setAutosavesConfiguration: (BOOL)flag
{
  [self _setAutosavesConfiguration: flag broadcast: YES];
}

- (void) setConfigurationFromDictionary: (NSDictionary *)configDict
{
  ASSIGN(_configurationDictionary, configDict);
}

/**
 * Sets the receivers delegate ... this is the object which will receive
 * -toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:
 * -toolbarAllowedItemIdentifiers: and -toolbarDefaultItemIdentifiers:
 * messages.
 */
 
- (void) setDelegate: (id)delegate
{ 
  [self _setDelegate: delegate broadcast: YES];
}

- (void) setDisplayMode: (NSToolbarDisplayMode)displayMode
{
  [self _setDisplayMode: displayMode broadcast: YES];
}

- (void) setSelectedItemIdentifier: (NSString *)itemIdentifier
{

}

- (void) setSizeMode: (NSToolbarSizeMode)sizeMode
{

}

- (void) setVisible: (BOOL)shown
{
  [self _setVisible: shown broadcast: NO];
}

- (NSToolbarSizeMode) sizeMode
{
  return 0;
}

// Private methods

- (void) _build
{
  /*
   * toolbar build :
   * will use the delegate when there is no toolbar model
   */
  
  NSToolbar *toolbarModel;
  NSArray *wantedItemIdentifiers;
  NSEnumerator *e;
  id itemIdentifier;
  int i = 0;
  
  _build = YES;

  RELEASE(_items);
  _items = [[NSMutableArray alloc] init];
    
  toolbarModel = [[NSToolbar _toolbarsForIdentifier: _identifier] objectAtIndex: 0];
  if (toolbarModel != nil && toolbarModel != self)
    {
      wantedItemIdentifiers = [[toolbarModel items] valueForKey: @"itemIdentifier"];
    }
  else
    {
      wantedItemIdentifiers = [_delegate toolbarDefaultItemIdentifiers:self];
    }
    
  e = [wantedItemIdentifiers objectEnumerator];
  while ((itemIdentifier = [e nextObject]) != nil) 
    {
      [self _insertItemWithItemIdentifier: itemIdentifier atIndex: i broadcast: NO];
      i++;
    }
  
  _build = NO;
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

- (id) _toolbarItemForIdentifier: (NSString *)itemIdent
{
  id item = nil;
  if([itemIdent isEqual: NSToolbarSeparatorItemIdentifier] ||
     [itemIdent isEqual: NSToolbarSpaceItemIdentifier] ||
     [itemIdent isEqual: NSToolbarFlexibleSpaceItemIdentifier] ||
     [itemIdent isEqual: NSToolbarShowColorsItemIdentifier] ||
     [itemIdent isEqual: NSToolbarShowFontsItemIdentifier] ||
     [itemIdent isEqual: NSToolbarCustomizeToolbarItemIdentifier] ||
     [itemIdent isEqual: NSToolbarPrintItemIdentifier])
    {
      item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    }
  return item;
}

/*
 *
 * The methods below handles the toolbar edition and broacasts each associated event
 * to the other toolbars with identical identifiers. 
 *
 */

#define TRANSMIT(signature) \
  NSEnumerator *e = [[NSToolbar _toolbarsForIdentifier: _identifier] objectEnumerator]; \
  NSToolbar *toolbar; \
  \
  while ((toolbar = [e nextObject]) != nil) \
    { \
      if (toolbar != self) \
        [toolbar signature]; \
    }

- (void) _insertItemWithItemIdentifier: (NSString *)itemIdentifier atIndex: (int)index broadcast: (BOOL)broadcast
{
  NSToolbarItem *item = nil;
  NSArray *allowedItems = [_delegate toolbarAllowedItemIdentifiers: self];
  
  if([allowedItems containsObject: itemIdentifier])
    {
      item = [self _toolbarItemForIdentifier: itemIdentifier];
      if(item == nil)
	{
	  item = [_delegate toolbar: self 
			    itemForItemIdentifier: itemIdentifier
			    willBeInsertedIntoToolbar: YES];
	}
	  
      if (item != nil)
	{
	  [nc postNotificationName: NSToolbarWillAddItemNotification object: self];
	  [item _setToolbar: self];
	  [_items insertObject: item atIndex: index];
	  // We reload the toolbarView each time a new item is 
	  // added except when we build/create the toolbar
	  if (!_build) 
	    [_toolbarView _reload];
	  
	  if (broadcast)
	    {    
	      TRANSMIT(_insertItemWithItemIdentifier: itemIdentifier 
		       atIndex: index broadcast: NO);
	    }
	}
    }
}

- (void) _removeItemAtIndex: (int)index broadcast: (BOOL)broadcast
{
  
  [_items removeObjectAtIndex: index];
  [_toolbarView _reload];
  [nc postNotificationName: NSToolbarDidRemoveItemNotification
      object: self];

  if (broadcast) 
    {
      TRANSMIT(_removeItemAtIndex: index broadcast: NO);
    }
}

- (void) _setAllowsUserCustomization: (BOOL)flag broadcast: (BOOL)broadcast
{
  _allowsUserCustomization = flag;
     
  if (broadcast) 
    {
      TRANSMIT(_setAllowsUserCustomization: _allowsUserCustomization broadcast: NO);
    }
}

- (void) _setAutosavesConfiguration: (BOOL)flag broadcast: (BOOL)broadcast
{
  _autosavesConfiguration = flag;
     
  if (broadcast) 
    {
      TRANSMIT(_setAutosavesConfiguration: _autosavesConfiguration broadcast: NO);
    }
}

- (void) _setConfigurationFromDictionary: (NSDictionary *)configDict broadcast: (BOOL)broadcast
{
  ASSIGN(_configurationDictionary, configDict);
    
  if (broadcast) 
    {
      TRANSMIT(_setConfigurationFromDictionary: _configurationDictionary broadcast: NO);
    }
}

- (void) _setDisplayMode: (NSToolbarDisplayMode)displayMode broadcast: (BOOL)broadcast
{
   _displayMode = displayMode;
     
   if (broadcast) 
     {
      TRANSMIT(_setDisplayMode: _displayMode broadcast: NO);
     }
}

- (void) _setVisible: (BOOL)shown broadcast: (BOOL)broadcast
{
  if (_visible != shown)
    {  
      if (_window) 
        {
          if (shown)
	    [_toolbarView _setWillBeVisible: YES];
	  
	  [_window toggleToolbarShown: self];
	  
	  [_toolbarView _setWillBeVisible: NO];
	  _visible = shown; 
	  // Important to set _visible after the toolbar has been toggled
	  // because NSWindow method contentViewWithoutToolbar uses [NSToolbar visible]
	  // when we toggle the toolbar
        }
      else
        {
          NSLog(@"setVisible: doesn't work because the toolbar is not a window toolbar.");
        }
    }
    
    if (broadcast) 
      {
        TRANSMIT(_setVisible: _visible broadcast: NO);
      }
}

- (void)_setDelegate: (id)delegate broadcast: (BOOL)broadcast
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
    
  if (_window != nil) // The delegate should be called when the toolbar will become visible (= window not nil)
    {
      [self _build]; // Build the toolbar with the delegate or a toolbar model
      [_toolbarView _reload];
    }
  
  // broadcast now...
    
  if (broadcast) 
    {
      TRANSMIT(_setDelegate: _delegate broadcast: NO);
    } 
}

// Private Accessors

- (void) _setToolbarView: (GSToolbarView *)toolbarView
{
  ASSIGN(_toolbarView, toolbarView);
}

- (GSToolbarView *) _toolbarView 
{
  return _toolbarView;
}

- (void)_setWindow: (NSWindow *)window 
{
  ASSIGN(_window, window); // call [NSWindow(Toolbar) setToolbar:] to set the toolbar window
}

- (NSWindow *) _window
{
  return _window;
}

@end
