/* 
   <title>GSToolbar.m</title>

   <abstract>The basic toolbar class.</abstract>
   
   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>,
            Fabien Vallon <fabien.vallon@fr.alcove.com>,
	    Quentin Mathe <qmathe@club-internet.fr>
   Date: February 2004
   
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
#include "AppKit/NSApplication.h"
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSView.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSNibLoading.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSWindow+Toolbar.h"
#include "GNUstepGUI/GSToolbarView.h"
#include "GNUstepGUI/GSToolbar.h"

// internal
static NSNotificationCenter *nc = nil;
static const int current_version = 1;

static NSMutableArray *toolbars;

// Validation stuff
static const unsigned int ValidationInterval = 10;
static id validationCenter;

// Extensions
@implementation NSArray (ObjectsWithValueForKey)

- (NSArray *) objectsWithValue: (id)value forKey: (NSString *)key 
{
  NSMutableArray *result = [[NSMutableArray alloc] init];
  NSArray *keys = [self valueForKey: key];
  int i, n = 0;
  
  if (keys == nil)
    return nil;
  
  n = [keys count];
  
  for (i = 0; i < n; i++)
    {
      if ([[keys objectAtIndex: i] isEqual: value])
        {
          [result addObject: [self objectAtIndex: i]];
        }
    }
    
  if ([result count] == 0)
    return nil;
  
  AUTORELEASE(result);
  
  return result;
}
@end

// Validation support

@interface NSView (ToolbarValidation)
- (void) mouseDown: (NSEvent *)event;
@end

@interface GSValidationObject : NSObject
{
  NSMutableArray *_observers;
  NSView *_view;
}

- (id) initWithView: (NSView *)view;
- (NSArray *) observers;
- (void) addObserver: (id)observer;
- (void) removeObserver: (id)observer;
- (void) validate;
- (NSView *) view;
@end

@interface GSValidationManager : NSObject
{
  NSWindow *_window;
  NSView *_trackingRectView;
  NSTrackingRectTag _trackingRect;
  NSTimer *_validationTimer;
  BOOL _inside;
}

- (id) initWithWindow: (NSWindow *)window;
- (void) validate;

- (void) invalidate;

// Tracking rect methods
- (void) mouseEntered: (NSEvent *)event;
- (void) mouseExited: (NSEvent *)event;
@end

@interface GSValidationCenter : NSObject
{
  NSMutableArray *_validationManagers;
  NSMutableArray *_validationObjects;
  NSWindow *_prevWindow;
}

+ (GSValidationCenter *) sharedValidationCenter;
- (id) init;
- (void) viewWillMove: (NSNotification *)notification;
- (void) viewDidMove: (NSNotification *)notification;
- (void) unregisterValidationObject: (GSValidationObject *)validationObject;
- (GSValidationObject *) validationObjectWithView: (NSView *)view;

// Private methods
- (GSValidationManager *) _validationManagerWithWindow: (NSWindow *)window;
- (NSArray *) _validationObjectsWithWindow: (NSWindow *)window;
@end

// Validation mechanism

@implementation NSView (ToolbarValidation)

- (void) mouseDown: (NSEvent *)event
{
  GSValidationManager *validationManager = 
    [[GSValidationCenter sharedValidationCenter] _validationManagerWithWindow: [self window]];

  [validationManager performSelector: @selector(validate) withObject: nil afterDelay: 0.1];
}
@end

@implementation GSValidationObject

- (id) initWithView: (NSView *)view
{
  if ((self = [super init]) != nil)
    {
      ASSIGN(_view, view);
      _observers = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_view);
  RELEASE(_observers);
  [super dealloc];
}

- (NSArray *) observers
{
  return _observers;
}

- (void) addObserver: (id)observer
{
  [_observers addObject: observer];
}

- (void) removeObserver: (id)observer
{
  if ([_observers containsObject: observer])
    [_observers removeObject: observer];
}

- (void) validate
{ 
  if ([_view superview] != nil)
    {
      [_observers makeObjectsPerformSelector: @selector(_validate)];
    }
}

- (NSView *) view
{
  return _view;
}

@end

@interface NSWindow (GNUstepPrivate)
- (NSView *) _windowView;
@end

@implementation GSValidationManager

- (id) initWithWindow: (NSWindow *)window {
  if ((self = [super init]) != nil)
    {;
      NSView *vw = [window _windowView];
      
      ASSIGN(_window, window);
      [nc addObserver: self selector: @selector(windowWillClose:) 
        name: NSWindowWillCloseNotification object: _window];
						
      ASSIGN(_trackingRectView, vw);
      _trackingRect = [_trackingRectView addTrackingRect: [_trackingRectView bounds] 
                                                   owner: self 
			                        userData: nil 
			                    assumeInside: NO];
    }
    
  return self;
}

- (void) invalidate
{
  [_trackingRectView removeTrackingRect: _trackingRect]; // tracking rect retains us, that is normal ?
  [_validationTimer invalidate]; // timer idem
}

- (void) dealloc
{
  RELEASE(_trackingRectView);
  RELEASE(_window);
  
  [super dealloc];
}

- (void) windowWillClose: (NSNotification *)notification
{
  GSValidationCenter *vc = [GSValidationCenter sharedValidationCenter];
  NSEnumerator *e;
  id vo;
  
  [nc removeObserver: self];
 
  e = [[vc _validationObjectsWithWindow: _window] objectEnumerator];
  while ((vo = [e nextObject]) != nil)
    {
      [vc unregisterValidationObject: vo];
    }
}

- (void) mouseEntered: (NSEvent *)event
{ 
  _inside = YES;
  if (_validationTimer == nil || ![_validationTimer isValid])
    {
      _validationTimer = [NSTimer timerWithTimeInterval: ValidationInterval 
                                                 target: self 
					       selector: @selector(validate) 
					       userInfo: nil 
					        repeats: YES];
      [[NSRunLoop currentRunLoop] addTimer: _validationTimer forMode: NSDefaultRunLoopMode];
      [self validate];
    }
}

- (void) mouseExited: (NSEvent *)event
{ 
  _inside = NO;
  [_validationTimer invalidate];
  _validationTimer = nil;
}

- (void) validate
{ 
  [[[GSValidationCenter sharedValidationCenter]
     _validationObjectsWithWindow: _window] makeObjectsPerformSelector: @selector(validate)];
}

@end

@implementation GSValidationCenter

+ (GSValidationCenter *) sharedValidationCenter
{
  if (validationCenter == nil)
    validationCenter = [[GSValidationCenter alloc] init];
    
  return validationCenter;
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      _validationManagers = [[NSMutableArray alloc] init];
      _validationObjects = [[NSMutableArray alloc] init];
      
      [nc addObserver: self selector: @selector(viewWillMove:) name: @"GSViewWillMoveToWindow" object: nil];
      [nc addObserver: self selector: @selector(viewDidMove:) name: @"GSViewDidMoveToWindow" object: nil];
    }
  
  return self;
}

- (void) viewWillMove: (NSNotification *)notification
{
  _prevWindow = [[notification object] window];
  RETAIN(_prevWindow);
}

- (void) viewDidMove: (NSNotification *)notification
{
  NSWindow *window = [[notification object] window];
  GSValidationManager *validationManager = [self _validationManagerWithWindow : _prevWindow];
  
  if (validationManager != nil && [[self _validationObjectsWithWindow: _prevWindow] count] == 0)
    {
      [validationManager invalidate];
      [_validationManagers removeObject: validationManager];
    }
    
  if (window == nil)
    return;
  
  validationManager = [self _validationManagerWithWindow: window];
  if (validationManager == nil)
    {
      validationManager = [[GSValidationManager alloc] initWithWindow: window];
      [_validationManagers addObject: validationManager];
      RELEASE(validationManager);
    }
    
  RELEASE(_prevWindow);
}

/* validationObjectWithView: opposite method
 * Remove the object in the validation objects list.
 * Release the validation manager associated to the window (related to the validation object and its 
 * view) in the case there are no other validation objects related to this window.
 */
- (void) unregisterValidationObject: (GSValidationObject *)validationObject
{
  int index;
  
  if ((index = [_validationObjects indexOfObject: validationObject]) != NSNotFound)
    {
      NSWindow *window = [[validationObject view] window];
      
      [_validationObjects removeObjectAtIndex: index];
      
      if ([[self _validationObjectsWithWindow: window] count] == 0)
	{ 
	  GSValidationManager *validationManager = [self _validationManagerWithWindow: window];
	  [validationManager invalidate];
	  [_validationManagers removeObject: validationManager];
	}
    }
}

/* Return the validation object associated with the parameter view.
 * If there is no such validation object, create it by using view and then check that an associated 
 * validation manager (bound to the window which the view depends on) exists.
 * If there is no such validation manager, create it.
 */
- (GSValidationObject *) validationObjectWithView: (NSView *)view
{
  GSValidationObject *validationObject;
  GSValidationManager *validationManager;
  NSWindow *window = [view window];
  
  if (view == nil)
    {
      NSLog(@"Validation object cannot be created because the view is nil");
      return nil;
    }
  
  validationObject = [[_validationObjects objectsWithValue: view forKey: @"_view"] objectAtIndex: 0];
  if (validationObject == nil)
    {
      validationObject = [[GSValidationObject alloc] initWithView: view];
      [_validationObjects addObject: validationObject];
      
      if (window == nil)
        return nil;
      
      validationManager = [self _validationManagerWithWindow: window];
      if (validationManager == nil)
        {
	  validationManager = [[GSValidationManager alloc] initWithWindow: window];
	  [_validationManagers addObject: validationManager];
	  RELEASE(validationManager);
	}
    }
  
  return validationObject;
}

// Private methods

- (GSValidationManager *) _validationManagerWithWindow: (NSWindow *)window
{
  GSValidationManager *validationManager = 
    [[_validationManagers objectsWithValue: window forKey: @"_window"] objectAtIndex: 0];									 

  return validationManager;
}

- (NSArray *) _validationObjectsWithWindow: (NSWindow *)window
{
  NSEnumerator *e = [_validationObjects objectEnumerator];
  id validationObject;
  NSMutableArray *array = [NSMutableArray array];
  
  while ((validationObject = [e nextObject]) != nil)
    {
      if ([[validationObject view] window] == window)
        [array addObject: validationObject];
    }
  
  return array;
}

@end

// ---

@interface GSToolbar (GNUstepPrivate)

// Private class method

+ (NSMutableArray *) _toolbars;

- (void) _insertItemWithItemIdentifier: (NSString *)itemIdentifier 
                               atIndex: (int)index 
                             broadcast: (BOOL)broadcast;

// Private methods with broadcast support
- (void) _insertItemWithItemIdentifier: (NSString *)itemIdentifier 
                               atIndex: (int)index 
                             broadcast: (BOOL)broadcast;
- (void) _removeItemAtIndex: (int)index broadcast: (BOOL)broadcast;
- (void) _setAllowsUserCustomization: (BOOL)flag broadcast: (BOOL)broadcast;
- (void) _setAutosavesConfiguration: (BOOL)flag broadcast: (BOOL)broadcast;
- (void) _setConfigurationFromDictionary: (NSDictionary *)configDict 
                               broadcast: (BOOL)broadcast;
- (void) _setDelegate: (id)delegate broadcast: (BOOL)broadcast;

// Few other private methods
- (void) _build;
- (void) _loadConfig;
- (NSToolbarItem *) _toolbarItemForIdentifier: (NSString *)itemIdent;
- (GSToolbar *) _toolbarModel;
- (void) _validate;

// Accessors
- (void) _setToolbarView: (GSToolbarView *)toolbarView;
- (GSToolbarView *) _toolbarView;
- (void) _setWindow: (NSWindow *)window;
- (NSWindow *) _window;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (BOOL) _selectable;
- (void) _setSelectable: (BOOL)selectable;
- (BOOL) _selected;
- (void) _setSelected: (BOOL)selected;
- (void) _setToolbar: (GSToolbar *)toolbar;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _reload;

// Accessors
- (NSArray *) _visibleBackViews;
- (BOOL) _willBeVisible;
- (void) _setWillBeVisible: (BOOL)willBeVisible;
- (void) _setUsesStandardBackgroundColor: (BOOL)standard;
@end

// ---

@implementation GSToolbar

// Class methods

// Initialize the class when it is loaded
+ (void) initialize
{
  if (self == [GSToolbar class])
    {
      [self setVersion: current_version];
      nc = [NSNotificationCenter defaultCenter];
      toolbars = [[NSMutableArray alloc] init];
    }
}

// Private class method to access static variable toolbars in subclasses

+ (NSMutableArray *) _toolbars
{
  return toolbars;
}

// Instance methods

- (id) initWithIdentifier: (NSString *)identifier
{
  return [self initWithIdentifier: identifier 
                      displayMode: NSToolbarDisplayModeIconAndLabel 
		         sizeMode: NSToolbarSizeModeRegular];
}


// default initialiser
- (id) initWithIdentifier: (NSString *)identifier 
              displayMode: (NSToolbarDisplayMode)displayMode 
                 sizeMode: (NSToolbarSizeMode)sizeMode
{
  GSToolbar *toolbarModel;
  
  if ((self = [super init]) == nil) 
    return nil;
  
  ASSIGN(_identifier, identifier);
  
  _items = [[NSMutableArray alloc] init];
    
  toolbarModel = [self _toolbarModel];
  
  if (toolbarModel != nil)
    {
      _customizationPaletteIsRunning = NO;
      _allowsUserCustomization = [toolbarModel allowsUserCustomization];
      _autosavesConfiguration = [toolbarModel autosavesConfiguration];
      ASSIGN(_configurationDictionary, [toolbarModel configurationDictionary]);
      
      if ([toolbarModel displayMode] != displayMode 
        && [toolbarModel sizeMode] != sizeMode)
	{
	  // raise an exception.
	}
	
      //[self _loadConfig];
    }
  else
    {
      _customizationPaletteIsRunning = NO;
      _allowsUserCustomization = NO;
      _autosavesConfiguration = NO;
      _configurationDictionary = nil;

      //[self _loadConfig];
    
       _delegate = nil;
    }
    
  _displayMode = displayMode; 
  _sizeMode = sizeMode;
  
  [toolbars addObject: self];
  
  return self;
}

- (void) dealloc
{
  // use DESTROY ?
  RELEASE(_identifier);
  RELEASE(_selectedItemIdentifier);
  RELEASE(_configurationDictionary);
  RELEASE(_items);

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
  [self _insertItemWithItemIdentifier: itemIdentifier 
                              atIndex: index 
                            broadcast: YES]; 
}

- (void) removeItemAtIndex: (int)index
{
  [self _removeItemAtIndex: index broadcast: YES];
}

- (void) runCustomizationPalette: (id)sender
{
  _customizationPaletteIsRunning = 
    [NSBundle loadNibNamed: @"GSToolbarCustomizationPalette" owner: self];

  if(!_customizationPaletteIsRunning)
    {
      NSLog(@"Failed to load gorm for GSToolbarCustomizationPalette");
    }
}

- (void) validateVisibleItems
{
  NSEnumerator *e = [[self visibleItems]  objectEnumerator];
  NSToolbarItem *item = nil;

  while((item = [e nextObject]) != nil)
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

- (NSArray *) items
{ 
  return _items;
}

- (NSString *) selectedItemIdentifier
{
  return _selectedItemIdentifier;
}

- (NSArray *) visibleItems
{
  if ([_toolbarView superview] == nil)
    {
      return nil;
    }
  else
    {
      return [[_toolbarView _visibleBackViews] valueForKey: @"toolbarItem"];
    }
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

- (void) setSelectedItemIdentifier: (NSString *)itemIdentifier
{
  NSArray *selectedItems;
  NSArray *itemsToSelect;
  NSEnumerator *e;
  NSToolbarItem *item;
  NSArray *selectableIdentifiers;
  
  //  First, we have to deselect the previous selected toolbar items 
  selectedItems = [[self items] objectsWithValue: [self selectedItemIdentifier] 
                                             forKey: @"_itemIdentifier"];
  e = [selectedItems objectEnumerator];    
  while ((item = [e nextObject]) != nil)
    {
      [item _setSelected: NO];
    }
    
   ASSIGN(_selectedItemIdentifier, itemIdentifier);
   
   if ([_delegate respondsToSelector: @selector(toolbarSelectableItemIdentifiers:)])
     selectableIdentifiers = [_delegate toolbarSelectableItemIdentifiers: self];
   
   itemsToSelect = [_items objectsWithValue: _selectedItemIdentifier forKey: @"_itemIdentifier"];
   e = [itemsToSelect objectEnumerator];
   while ((item = [e nextObject]) != nil)
     {
       if ([selectableIdentifiers containsObject: [item itemIdentifier]] && ![item _selected])
         [item _setSelected: YES];
     }
}

- (NSToolbarSizeMode) sizeMode
{
  return _sizeMode;
}

- (void) setUsesStandardBackgroundColor: (BOOL)standard
{
  [_toolbarView _setUsesStandardBackgroundColor: standard];
}

// Private methods

- (void) _build
{
  /*
   * toolbar build :
   * will use the delegate when there is no toolbar model
   */
  
  GSToolbar *toolbarModel;
  NSArray *wantedItemIdentifiers;
  NSEnumerator *e;
  id itemIdentifier;
  int i = 0;
  
  _build = YES;

  RELEASE(_items);
  _items = [[NSMutableArray alloc] init];
    
  toolbarModel = [self _toolbarModel];

  if (toolbarModel != nil && [toolbarModel delegate] == _delegate)
    {
      wantedItemIdentifiers = 
        [[toolbarModel items] valueForKey: @"_itemIdentifier"];
    }
  else
    {
      wantedItemIdentifiers = [_delegate toolbarDefaultItemIdentifiers:self];
    }
    
  e = [wantedItemIdentifiers objectEnumerator];
  while ((itemIdentifier = [e nextObject]) != nil) 
    {
      [self _insertItemWithItemIdentifier: itemIdentifier 
                                  atIndex: i 
                                broadcast: NO];
      i++;
    }
  
  _build = NO;
}

- (void) _loadConfig
{
  if (_identifier != nil)
    { 
      NSUserDefaults     *defaults;
      NSString           *tableKey;
      id                  config;
      
      defaults  = [NSUserDefaults standardUserDefaults];
      tableKey = 
        [NSString stringWithFormat: @"GSToolbar Config %@",_identifier];

      config = [defaults objectForKey: tableKey];
      
      if (config != nil) 
	{
	  [self setConfigurationFromDictionary: config];
	}
    }
}

- (GSToolbar *) _toolbarModel
{
  NSArray *linked;
  id toolbar;

  linked = [toolbars objectsWithValue: [self identifier] 
                               forKey: @"_identifier"];
    
  if (linked != nil && [linked count] > 0)
    {
      toolbar = [linked objectAtIndex: 0];
      
      // toolbar model class must be identical to self class :
      // an NSToolbar instance cannot use a GSToolbar instance as a model
      if ([toolbar isMemberOfClass: [self class]] && toolbar != self)
        return toolbar;
    }
  
  return nil;
}

- (NSToolbarItem *) _toolbarItemForIdentifier: (NSString *)itemIdent
{
  NSToolbarItem *item = nil;
  
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
 * The methods below handles the toolbar edition and broacasts each associated
 * event to the other toolbars with identical identifiers. 
 * Warning : broadcast process only happens between instances based on the same class.
 */

#define TRANSMIT(signature) \
  NSEnumerator *e = [[toolbars objectsWithValue: _identifier forKey: @"_identifier"] objectEnumerator]; \
  GSToolbar *toolbar; \
  \
  while ((toolbar = [e nextObject]) != nil) \
    { \
      if (toolbar != self && [toolbar isMemberOfClass: [self class]]) \
        [toolbar signature]; \
    }

- (void) _insertItemWithItemIdentifier: (NSString *)itemIdentifier 
                               atIndex: (int)index 
                             broadcast: (BOOL)broadcast
{
  NSToolbarItem *item = nil;
  NSArray *allowedItems = [_delegate toolbarAllowedItemIdentifiers: self];
  
  if([allowedItems containsObject: itemIdentifier])
    {
      item = [self _toolbarItemForIdentifier: itemIdentifier];
      if(item == nil)
	{
	  item = 
            [_delegate toolbar: self itemForItemIdentifier: itemIdentifier
			         willBeInsertedIntoToolbar: YES];
	}
      
      if (item != nil)
        {
          NSArray *selectableItems;
	  
	  if ([_delegate respondsToSelector: @selector(toolbarSelectableItemIdentifiers:)])
	    {
	      selectableItems = [_delegate toolbarSelectableItemIdentifiers: self];
	      if ([selectableItems containsObject: itemIdentifier])
	        [item _setSelectable: YES];
	    }
	  
	  [nc postNotificationName: NSToolbarWillAddItemNotification 
                            object: self];
          [item _setToolbar: self];
          [_items insertObject: item atIndex: index];
	  
	  // We reload the toolbarView each time a new item is added except when
	  // we build/create the toolbar
          if (!_build) 
	    [_toolbarView _reload];
    
          if (broadcast)
            {    
              TRANSMIT(_insertItemWithItemIdentifier: itemIdentifier 
                                             atIndex: index 
                                           broadcast: NO);
            }
        }  
    } 
    
}

- (void) _removeItemAtIndex: (int)index broadcast: (BOOL)broadcast
{
  
  [_items removeObjectAtIndex: index];
  [_toolbarView _reload];
  [nc postNotificationName: NSToolbarDidRemoveItemNotification object: self];

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
      TRANSMIT(_setAllowsUserCustomization: _allowsUserCustomization 
                                 broadcast: NO);
    }
}

- (void) _setAutosavesConfiguration: (BOOL)flag broadcast: (BOOL)broadcast
{
  _autosavesConfiguration = flag;
     
  if (broadcast) 
    {
      TRANSMIT(_setAutosavesConfiguration: _autosavesConfiguration 
                                broadcast: NO);
    }
}

- (void) _setConfigurationFromDictionary: (NSDictionary *)configDict 
                               broadcast: (BOOL)broadcast
{
  ASSIGN(_configurationDictionary, configDict);
    
  if (broadcast) 
    {
      TRANSMIT(_setConfigurationFromDictionary: _configurationDictionary 
          			     broadcast: NO);
    }
}

- (void) _setDelegate: (id)delegate broadcast: (BOOL)broadcast
{   
  
  if (_delegate == delegate 
    || (broadcast == NO && [_delegate isMemberOfClass: [delegate class]]))
    return;
  // We don't reload instances which received this message and already have a
  // delegate based on a class identical to the parameter delegate, it permits
  // to use only one nib owner class as a toolbar delegate even if a new instance
  // of the nib owner are created with each new window (see MiniController.m in
  // the toolbar example application).
    
  
  #define CHECK_REQUIRED_METHOD(selector_name) \
  if (![delegate respondsToSelector: @selector(selector_name)]) \
    [NSException raise: NSInternalInconsistencyException \
                format: @"delegate does not respond to %@",@#selector_name]

  CHECK_REQUIRED_METHOD(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:);
  CHECK_REQUIRED_METHOD(toolbarAllowedItemIdentifiers:);
  CHECK_REQUIRED_METHOD(toolbarDefaultItemIdentifiers:);

  if (_delegate) 
    [nc removeObserver: _delegate name: nil object: self];

  ASSIGN(_delegate, delegate);

  #define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(toolbar##notif_name:)]) \
    [nc addObserver: _delegate \
           selector: @selector(toolbar##notif_name:) \
               name: NSToolbar##notif_name##Notification object: self]
  
  SET_DELEGATE_NOTIFICATION(DidRemoveItem);
  SET_DELEGATE_NOTIFICATION(WillAddItem);
    
  [self _build];
  if (_toolbarView != nil)
    [_toolbarView _reload];
  
  // broadcast now...
    
  if (broadcast) 
    {
      TRANSMIT(_setDelegate: _delegate broadcast: NO);
    } 
}

// Private Accessors

- (void) _setToolbarView: (GSToolbarView *)toolbarView
{
  GSValidationObject *validationObject = nil;
  GSValidationCenter *vc = [GSValidationCenter sharedValidationCenter];
  GSToolbar *toolbarModel = [self _toolbarModel];
  
  validationObject = [vc validationObjectWithView: _toolbarView];
  if (validationObject != nil)
    {
      [validationObject removeObserver: self];
      if ([[validationObject observers] count] == 0)
        [vc unregisterValidationObject: validationObject];
    }
  
  ASSIGN(_toolbarView, toolbarView);
      
  validationObject = [vc validationObjectWithView: _toolbarView];
  if (validationObject != nil)
   [validationObject addObserver: self];
    
  if (_delegate == nil)
   [self _setDelegate: [toolbarModel delegate] broadcast: NO];
}

- (GSToolbarView *) _toolbarView 
{
  return _toolbarView;
}

- (void) _validate
{
  [self validateVisibleItems];
}

@end
