/* 
   GSToolbar.h

   The basic toolbar class.
   
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

#ifndef _GNUstep_H_GSToolbar
#define _GNUstep_H_GSToolbar

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSNotification;
@class NSToolbarItem;
@class GSToolbarView;
@class NSWindow;

/*
 * Constants
 */

typedef enum 
{ 
  NSToolbarDisplayModeDefault,
  NSToolbarDisplayModeIconAndLabel,
  NSToolbarDisplayModeIconOnly,
  NSToolbarDisplayModeLabelOnly
} NSToolbarDisplayMode;

typedef enum 
{ 
  NSToolbarSizeModeDefault,
  NSToolbarSizeModeRegular,
  NSToolbarSizeModeSmall,
} NSToolbarSizeMode;

APPKIT_EXPORT NSString *NSToolbarDidRemoveItemNotification;
APPKIT_EXPORT NSString *NSToolbarWillAddItemNotification;

@interface GSToolbar : NSObject
{
  BOOL _allowsUserCustomization;
  BOOL _autosavesConfiguration;
  NSMutableDictionary *_configurationDictionary;
  BOOL _customizationPaletteIsRunning;
  id _delegate;
  NSToolbarDisplayMode _displayMode;
  NSToolbarSizeMode _sizeMode;
  NSString *_identifier;
  NSString *_selectedItemIdentifier;
  NSMutableArray *_items;
  GSToolbarView *_toolbarView;
  BOOL _build;
}

// Instance methods
- (id) initWithIdentifier: (NSString*)identifier;
- (id) initWithIdentifier: (NSString *)identifier 
              displayMode: (NSToolbarDisplayMode)displayMode 
                 sizeMode: (NSToolbarSizeMode)sizeMode;

- (void) insertItemWithItemIdentifier: (NSString*)itemIdentifier atIndex: (int)index;
- (void) removeItemAtIndex: (int)index;
- (void) runCustomizationPalette: (id)sender;
- (void) validateVisibleItems;

// Accessors
- (BOOL) allowsUserCustomization;
- (BOOL) autosavesConfiguration;
- (NSDictionary*) configurationDictionary;
- (BOOL) customizationPaletteIsRunning;
- (id) delegate;
- (NSToolbarDisplayMode) displayMode;
- (NSString*) identifier;
- (NSArray*) items;
- (NSString *) selectedItemIdentifier;
- (NSArray*) visibleItems;
- (void) setAllowsUserCustomization: (BOOL)flag;
- (void) setAutosavesConfiguration: (BOOL)flag;
- (void) setConfigurationFromDictionary: (NSDictionary*)configDict;
- (void) setDelegate: (id)delegate;
- (void) setSelectedItemIdentifier: (NSString *) identifier;
- (void) setUsesStandardBackgroundColor: (BOOL)standard;
- (NSToolbarSizeMode) sizeMode;


// Private class method

+ (NSMutableArray *) _toolbars;

@end /* interface of NSToolbar */

/*
 * Methods Implemented by the Delegate
 */
@interface NSObject (GSToolbarDelegate)
// notification methods
- (void) toolbarDidRemoveItem: (NSNotification*)aNotification;
- (void) toolbarWillAddItem: (NSNotification*)aNotification;

// delegate methods
// required method
- (NSToolbarItem*)toolbar: (GSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag;
// required method
- (NSArray*) toolbarAllowedItemIdentifiers: (GSToolbar*)toolbar;
// required method
- (NSArray*) toolbarDefaultItemIdentifiers: (GSToolbar*)toolbar;
// optional method
- (NSArray *) toolbarSelectableItemIdentifiers: (GSToolbar *)toolbar;
@end


// Extensions

@interface NSArray (ObjectsWithValueForKey)
- (NSArray *) objectsWithValue: (id)value forKey: (NSString *)key;
@end

#endif /* _GNUstep_H_NSToolbar */
