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
#include <Foundation/NSKeyValueCoding.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSString.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSUserDefaults.h>
#include "AppKit/NSApplication.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSNibLoading.h"
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSWindow+Toolbar.h"
#include "GNUstepGUI/GSToolbarView.h"
#include "GNUstepGUI/GSToolbar.h"

// internal
static NSNotificationCenter *nc = nil;
static const int current_version = 1;

static NSMutableArray *toolbars;

// Validation stuff
static const unsigned int ValidationInterval = 4;
@class GSValidationCenter; // Mandatory because the interface is declared later
static GSValidationCenter *vc;

// Extensions
@implementation NSArray (ObjectsWithValueForKey)

- (NSArray *) objectsWithValue: (id)value forKey: (NSString *)key 
{
  NSMutableArray *result = [NSMutableArray array];
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
  
  return result;
}
@end

/* 
 * Validation support
 * 
 * Validation support is architectured around a shared validation center, which
 * is our public interface to handle the validation, behind the scene each
 * window has an associated validation object created when an observer is added
 * to the validation center.
 * A validation object calls the _validate: method on the observer when the
 * mouse is inside the observed window and only in the case this window is
 * updated or in the case the mouse stays inside more than four seconds, then
 * the action will be reiterated every four seconds until the mouse exits.
 * A validation object owns a window to observe, a tracking rect attached to
 * the window root view to know when the mouse is inside, a timer to be able to
 * send the _validate: message periodically, and one ore more observers, then it
 * is necessary to supply with each registered observer an associated window to
 * observe.
 * In the case, an object would observe several windows, the _validate: has a
 * parameter observedWindow to let us know where the message is coming from.
 * Because we cannot know surely when a validation object is deallocated, a
 * method named clean has been added which permits to invalidate a validation
 * object which must not be used anymore, not calling it would let segmentation
 * faults occurs.
 */

@interface GSValidationObject : NSObject
{
  NSWindow *_window;
  NSView *_trackingRectView;
  NSTrackingRectTag _trackingRect;
  NSMutableArray *_observers;
  NSTimer *_validationTimer;
  BOOL _inside;
  BOOL _validating;
}

- (NSMutableArray *) observers;
- (void) setObservers: (NSMutableArray *)observers;
- (NSWindow *) window;
- (void) setWindow: (NSWindow *)window;
- (void) validate;
- (void) scheduledValidate;
- (void) clean;

@end

@interface GSValidationCenter : NSObject
{
  NSMutableArray *_vobjs;
}

+ (id) sharedValidationCenter;

- (NSArray *) observersWindow: (NSWindow *)window;
- (void) addObserver: (id)observer window: (NSWindow *)window;
- (void) removeObserver: (id)observer window: (NSWindow *)window;

@end

// Validation mechanism

@interface NSWindow (GNUstepPrivate)
- (NSView *) _windowView;
@end

@implementation GSValidationObject

- (id) initWithWindow: (NSWindow *)window
{
  if ((self = [super init]) != nil)
    {
      _observers = [[NSMutableArray alloc] init];
      
      [nc addObserver: self selector: @selector(windowDidUpdate:) 
                 name: NSWindowDidUpdateNotification 
	       object: window];
      [nc addObserver: vc 
      	     selector: @selector(windowWillClose:) 
                 name: NSWindowWillCloseNotification 
	       object: window];
						
       _trackingRectView = [window _windowView];
       _trackingRect 
	 = [_trackingRectView addTrackingRect: [_trackingRectView bounds]
			                owner: self 
			             userData: nil 
			         assumeInside: NO];  
       _window = window;
    }
  return self;
}

- (void) dealloc
{
  // NSLog(@"vobj dealloc");
 
  // [_trackingRectView removeTrackingRect: _trackingRect]; 
  // Not here because the tracking rect retains us, then when the tracking rect
  // would be deallocated that would create a loop and a segmentation fault.
  // See next method.
  
  RELEASE(_observers);
  
  [super dealloc];
}

- (void) clean
{ 
  if ([_validationTimer isValid])
    {
      [_validationTimer invalidate];
      _validationTimer = nil;
    }
  
  [nc removeObserver: vc
                name: NSWindowWillCloseNotification 
              object: _window];
  [nc removeObserver: self 
                name: NSWindowDidUpdateNotification  
              object: _window];
  
  [self setWindow: nil];              
  // Needed because the validation timer can retain us and by this way retain also the toolbar which is
  // currently observing.
  
  [self setObservers: nil]; // To release observers 
	      
  [_trackingRectView removeTrackingRect: _trackingRect];
  // We can safely remove the tracking rect here, because it will never call
  // this method unlike dealloc.   
}

/*
 * FIXME: Replace the deprecated method which follows by this one when -base 
 * NSObject will implement it.
 *
- (id) valueForUndefinedKey: (NSString *)key
{
  if ([key isEqualToString: @"window"] || [key isEqualToString: @"_window"])
    return nil;
  
  return [super valueForUndefinedKey: key];
}
 */
 
- (id) handleQueryWithUnboundKey: (NSString *)key
{
  if ([key isEqualToString: @"window"] || [key isEqualToString: @"_window"])
    return [NSNull null];
  
  return [super handleQueryWithUnboundKey: key];
}

- (NSMutableArray *) observers
{
  return _observers;
}

- (void) setObservers: (NSMutableArray *)observers
{
  ASSIGN(_observers, observers);
}

- (NSWindow *) window
{
  return _window;
}

- (void) setWindow: (NSWindow *)window
{
  _window = window;
}

- (void) validate
{ 
  _validating = YES;
  
  // NSLog(@"vobj validate");
  
  [_observers makeObjectsPerformSelector: @selector(_validate:) 
                              withObject: _window];
  
  _validating = NO;
}

- (void) mouseEntered: (NSEvent *)event
{ 
  _inside = YES;
  [self scheduledValidate];
}

- (void) mouseExited: (NSEvent *)event
{ 
  _inside = NO;
  if ([_validationTimer isValid])
    {
      [_validationTimer invalidate];
      _validationTimer = nil;
    }
}

- (void) windowDidUpdate: (NSNotification *)notification
{
  // NSLog(@"Window update %d", [[NSApp currentEvent] type]);
  
  if (!_inside || _validating || [[NSApp currentEvent] type] == NSMouseMoved)
    return;
  // _validating permits in the case the UI/window is refreshed by a validation to 
  // avoid have windowDidUpdate called, which would cause a loop like that :
  // validate -> view update -> windowDidUpdate -> validate etc.
    
  [self validate];
}

- (void) scheduledValidate
{  
  if (!_inside)
    return;
  
  [self validate];
  
  _validationTimer = 
    [NSTimer timerWithTimeInterval: ValidationInterval 
                            target: self 
			  selector: @selector(scheduledValidate) 
			  userInfo: nil
			   repeats: NO];
  [[NSRunLoop currentRunLoop] addTimer: _validationTimer 
                               forMode: NSDefaultRunLoopMode];	  
}

@end


@implementation GSValidationCenter

+ (GSValidationCenter *) sharedValidationCenter
{
  if (vc == nil)
    {
      if ((vc = [[GSValidationCenter alloc] init]) != nil)
        {
           // Nothing special
        }
    }
    
  return vc;
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      _vobjs = [[NSMutableArray alloc] init];
    }
    
  return self;
}

- (void) dealloc
{
  [nc removeObserver: self];
  
  RELEASE(_vobjs);
  
  [super dealloc];
}

- (NSArray *) observersWindow: (NSWindow *)window
{
  int i;
  NSArray *observersArray;
  NSMutableArray *result;
  
  if (window == nil)
    {
      result = [NSMutableArray array];
      observersArray = [_vobjs valueForKey: @"_observers"];
      for (i = 0; i < [observersArray count]; i++)
        {
	  [result addObjectsFromArray: [observersArray objectAtIndex: i]];
	}
      return result;
    }
  else
    {
      result = [[[_vobjs objectsWithValue: window forKey: @"_window"] 
        objectAtIndex: 0] observers];
      return result;
    }
}

- (void) addObserver: (id)observer window: (NSWindow *)window
{
  GSValidationObject *vobj = 
    [[_vobjs objectsWithValue: window forKey: @"_window"] objectAtIndex: 0];
  NSMutableArray *observersWindow = nil;
  
  if (window == nil)
    return;
  
  if (vobj != nil)
    {
      observersWindow = [vobj observers];
    }
  else
    {
      vobj = [[GSValidationObject alloc] initWithWindow: window];
      [_vobjs addObject: vobj];
      RELEASE(vobj);

      observersWindow = [NSMutableArray array];
      [vobj setObservers: observersWindow]; 
    }
  
  [observersWindow addObject: observer];
}

- (void) removeObserver: (id)observer window: (NSWindow *)window
{
  GSValidationObject *vobj;
  NSMutableArray *observersWindow;
  NSMutableArray *windows;
  NSEnumerator *e;
  NSWindow *w;

  if (window == nil)
    {
      windows = [_vobjs valueForKey: @"_window"];
    }
  else
    {
      windows = [NSArray arrayWithObject: window];
    }
  
  e = [windows objectEnumerator];
  
  while ((w = [e nextObject]) != nil)
    { 
      vobj = [[_vobjs objectsWithValue: w forKey: @"_window"] objectAtIndex: 0];
      observersWindow = [vobj observers];
  
      if (observersWindow != nil && [observersWindow containsObject: observer])
        {
          [observersWindow removeObject: observer];
	  if ([observersWindow count] == 0)
	    {  
              [vobj clean];
	      [_vobjs removeObjectIdenticalTo: vobj];
	    }
	}
    }
 
}

- (void) windowWillClose: (NSNotification *)notification
{
  GSValidationObject *vobj;
 
  // NSLog(@"Window will close");
 
  vobj = [[_vobjs objectsWithValue: [notification object] forKey: @"_window"] 
    objectAtIndex: 0];
  if (vobj != nil)
    {
      [vobj clean];
      [_vobjs removeObjectIdenticalTo: vobj];
    }
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
- (void) _moveItemFromIndex: (int)index toIndex: (int)newIndex broadcast: (BOOL)broadcast;

// Few other private methods
- (void) _build;
- (int) _indexOfItem: (NSToolbarItem *)item;
- (void) _insertPassivelyItem: (NSToolbarItem *)item atIndex: (int)newIndex; 
- (void) _performRemoveItem: (NSToolbarItem *)item;
- (void) _concludeRemoveItem: (NSToolbarItem *)item atIndex: (int)index broadcast: (BOOL)broadcast;
- (void) _loadConfig;
- (NSToolbarItem *) _toolbarItemForIdentifier: (NSString *)itemIdent;
- (GSToolbar *) _toolbarModel;
- (void) _validate: (NSWindow *)observedWindow;
- (void) _toolbarViewWillMoveToSuperview: (NSView *)newSuperview;

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
- (BOOL) _usesStandardBackgroundColor;
- (BOOL) _willBeVisible;
- (void) _setUsesStandardBackgroundColor: (BOOL)standard;
- (void) _setWillBeVisible: (BOOL)willBeVisible;
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
      vc = [GSValidationCenter sharedValidationCenter];
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
	  // Raise an exception.
	}
	
      // [self _loadConfig];
    }
  else
    {
      _customizationPaletteIsRunning = NO;
      _allowsUserCustomization = NO;
      _autosavesConfiguration = NO;
      _configurationDictionary = nil;

      // [self _loadConfig];
    
       _delegate = nil;
    }
    
  _displayMode = displayMode; 
  _sizeMode = sizeMode;
  
  [toolbars addObject: self];
  
  return self;
}

- (void) dealloc
{ 
  NSLog(@"Toolbar dealloc %@", self);
  
  [vc removeObserver: self window: nil];
  
  // Use DESTROY ?
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

- (void) release
{ 
  // We currently only worry about when our toolbar view is deallocated.
  // Views which belongs to a window which is deallocated, are released.
  // In such case, it's necessary to remove the toolbar which belongs to this
  // view from the master list when nobody else still retains us, so that it
  // doesn't cause a memory leak.
  if ([self retainCount] == 2)
    [toolbars removeObjectIdenticalTo: self];
    
  [super release];
}

/*
 * FIXME: Replace the deprecated method which follows by this one when -base 
 * NSObject will implement it.
 *
- (id) valueForUndefinedKey: (NSString *)key
{
  if ([key isEqualToString: @"window"] || [key isEqualToString: @"_window"])
    return nil;
  
  return [super valueForUndefinedKey: key];
}
 */
 
- (id) handleQueryWithUnboundKey: (NSString *)key
{
  if ([key isEqualToString: @"window"] || [key isEqualToString: @"_window"])
    return [NSNull null];
  
  return [super handleQueryWithUnboundKey: key];
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
  NSArray *selectableIdentifiers = nil;
  BOOL updated = NO;
  
  //  First, we have to deselect the previous selected toolbar items 
  selectedItems = [[self items] objectsWithValue: [self selectedItemIdentifier] 
                                          forKey: @"_itemIdentifier"];
  e = [selectedItems objectEnumerator];    
  while ((item = [e nextObject]) != nil)
    {
      [item _setSelected: NO];
    }   
   
   if ([_delegate respondsToSelector:
     @selector(toolbarSelectableItemIdentifiers:)]) 
     {
       selectableIdentifiers = 
         [_delegate toolbarSelectableItemIdentifiers: self]; 
     }
   else
     {
       NSLog(@"Toolbar delegate does not respond to %@", 
         @selector(toolbarSelectableItemIdentifiers:));
       return;
     }
   
   if (selectableIdentifiers == nil)
     {
       NSLog(@"Toolbar delegate returns no such selectable item identifiers");
       return;
     }
   
   itemsToSelect = [_items objectsWithValue: itemIdentifier 
                                     forKey: @"_itemIdentifier"]; 
   e = [itemsToSelect objectEnumerator];
   while ((item = [e nextObject]) != nil)
     {
       if ([selectableIdentifiers containsObject: [item itemIdentifier]])
         {
	   if (![item _selected])
	     [item _setSelected: YES];
	   updated = YES;
	 }
     }
   
   if (updated)
     {
       ASSIGN(_selectedItemIdentifier, itemIdentifier);
     }
   else
     {
       NSLog(@"Toolbar delegate returns no such selectable item identifiers");
     }
}

- (NSToolbarSizeMode) sizeMode
{
  return _sizeMode;
}

- (BOOL) usesStandardBackgroundColor
{
  return [_toolbarView _usesStandardBackgroundColor];
}

- (void) setUsesStandardBackgroundColor: (BOOL)standard
{
  [_toolbarView _setUsesStandardBackgroundColor: standard];
}

// Private methods

- (void) _build
{
  /*
   * Toolbar build :
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

- (int) _indexOfItem: (NSToolbarItem *)item
{
  return [_items indexOfObjectIdenticalTo: item];
}

- (void) _insertPassivelyItem: (NSToolbarItem *)item atIndex: (int)newIndex
{
  if (![_items containsObject: item])
    {
      [_items insertObject: item atIndex: newIndex];
    }
  else
    {
      NSLog(@"Error: the toolbar already contains the item to insert.");
    }
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
      
      // Toolbar model class must be identical to self class :
      // an NSToolbar instance cannot use a GSToolbar instance as a model
      if ([toolbar isMemberOfClass: [self class]] && toolbar != self)
        return toolbar;
      else
        return nil;
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
 * Warning : broadcast process only happens between instances based on the same
 * class. 
 */

#define TRANSMIT(signature) \
  NSEnumerator *e = [[toolbars objectsWithValue: _identifier forKey: \
    @"_identifier"] objectEnumerator]; \
  GSToolbar *toolbar; \
  \
  while ((toolbar = [e nextObject]) != nil) \
    { \
      if (toolbar != self && [toolbar isMemberOfClass: [self class]]) \
        [toolbar signature]; \
    } \

- (void) _insertItemWithItemIdentifier: (NSString *)itemIdentifier 
                               atIndex: (int)index 
                             broadcast: (BOOL)broadcast
{
  NSToolbarItem *item = nil;
  NSArray *allowedItems = [_delegate toolbarAllowedItemIdentifiers: self];
  
  if([allowedItems containsObject: itemIdentifier])
    {
      item = [self _toolbarItemForIdentifier: itemIdentifier];
      if (item == nil)
	{
	  item = 
            [_delegate toolbar: self itemForItemIdentifier: itemIdentifier
			         willBeInsertedIntoToolbar: YES];
	}
      
      if (item != nil)
        {
          NSArray *selectableItems;
	  
	  if ([_delegate respondsToSelector:
	    @selector(toolbarSelectableItemIdentifiers:)]) 
	    {
	      selectableItems = 
	        [_delegate toolbarSelectableItemIdentifiers: self]; 
	      if ([selectableItems containsObject: itemIdentifier])
	        [item _setSelectable: YES];
	    }
	  
	  [nc postNotificationName: NSToolbarWillAddItemNotification 
                            object: self
			  userInfo: [NSDictionary dictionaryWithObject: item  forKey: @"item"]];
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
  id item = [_items objectAtIndex: index];
  
  RETAIN(item);
  [self _performRemoveItem: item];
  [self _concludeRemoveItem: item atIndex: index broadcast: broadcast];
  RELEASE(item);
}

- (void) _performRemoveItem: (NSToolbarItem *)item
{
  [_items removeObject: item];
  [_toolbarView _reload];
}

- (void) _concludeRemoveItem: (NSToolbarItem *)item atIndex: (int)index broadcast: (BOOL)broadcast
{
  [nc postNotificationName: NSToolbarDidRemoveItemNotification
	            object: self
	          userInfo: [NSDictionary dictionaryWithObject: item  forKey: @"item"]];

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
  //if(_delegate)
  //  [nc removeObserver: _delegate name: nil object: self];
  
  if (_delegate == delegate 
    || (broadcast == NO && [_delegate isMemberOfClass: [delegate class]]))
    return;
  /* We don't reload instances which received this message and already have a
   * delegate based on a class identical to the parameter delegate, it permits
   * to use only one nib owner class as a toolbar delegate even if a new
   * instance of the nib owner are created with each new window (see
   * MiniController.m in the toolbar example application).
   */
  
  if(_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  
  #define CHECK_REQUIRED_METHOD(selector_name) \
  if (![delegate respondsToSelector: @selector(selector_name)]) \
    [NSException raise: NSInternalInconsistencyException \
                format: @"delegate does not respond to %@",@#selector_name]

  CHECK_REQUIRED_METHOD(toolbar:itemForItemIdentifier:
    willBeInsertedIntoToolbar:); 
  CHECK_REQUIRED_METHOD(toolbarAllowedItemIdentifiers:);
  CHECK_REQUIRED_METHOD(toolbarDefaultItemIdentifiers:);

  // Assign the delegate...
  _delegate = delegate;

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
  
  // Broadcast now...
    
  if (broadcast) 
    {
      TRANSMIT(_setDelegate: _delegate broadcast: NO);
    } 
}

- (void) _moveItemFromIndex: (int)index toIndex: (int)newIndex broadcast: (BOOL)broadcast
{
  id item;

  item = RETAIN([_items objectAtIndex: index]);
  [_items removeObjectAtIndex: index];
  if (newIndex > [_items count] - 1)
    {
      [_items addObject: item];
    }
  else
    {
      [_items insertObject: item atIndex: newIndex];
    }
  [_toolbarView _reload];

  RELEASE(item);

  if (broadcast) 
    {
      TRANSMIT(_moveItemFromIndex: index toIndex: newIndex broadcast: NO);
    }
}

// Private Accessors

- (void) _setToolbarView: (GSToolbarView *)toolbarView
{
  GSToolbar *toolbarModel = [self _toolbarModel];
  
  if (_toolbarView != nil)
    {
      [vc removeObserver: self window: nil];
    }
  if (toolbarView != nil)
    {
      [vc addObserver: self window: [toolbarView window]];
      // In the case the window parameter is a nil value, nothing happens.
    }
    
  // Don't do an ASSIGN here, the toolbar itself retains us.
  _toolbarView = toolbarView;
  
  if (_toolbarView == nil)
    return;
   
  /* In the case, the user hasn't set a delegate until now, we set it.
   * Why ?
   * We don't set it before when the toolbar is initialized, to do only one 
   * toolbar content load.
   * ...
   * 1 toolbar = [[GSToolbar alloc] initWithIdentifier: @"blabla"];
   * 2 [toolbar setDelegate: myDelegate];
   * In case such method like 1 sets a default delegate for the identifier by
   * requesting a toolbar model, a toolbar content load would occur.
   * With a method like 2 which follows immediatly :
   * Another toolbar load content would occur related to a probably different
   * delegate. 
   */    
  if (_delegate == nil)
   [self _setDelegate: [toolbarModel delegate] broadcast: NO];
}

- (GSToolbarView *) _toolbarView 
{
  return _toolbarView;
}

- (void) _toolbarViewWillMoveToSuperview: (NSView *)newSuperview
{
  // Must synchronize the validation system
  // _toolbarView should never be nil here
  // We don't handle synchronization when the toolbar view is added to a superview not
  // binded to a window, such superview being later moved to a window. (FIX ME ?)
  
  // NSLog(@"Moving to window %@", [newSuperview window]);
  
  [vc removeObserver: self window: nil];
  if (newSuperview != nil)
    [vc addObserver: self window: [newSuperview window]];
}

- (void) _validate: (NSWindow *)observedWindow
{
  // We observe only one window, then we ignore observedWindow.
  
  [self validateVisibleItems];
}

@end
