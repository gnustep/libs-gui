/* 
   NSToolbar.h

   The toolbar class.
   
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

#ifndef _GNUstep_H_NSToolbar
#define _GNUstep_H_NSToolbar

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

@class NSArray;
@class NSMutableArray;
@class NSString;
@class NSDictionary;
@class NSMutableDictionary;
@class NSToolbarItem;
@class NSNotification;

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

APPKIT_EXPORT NSString *NSToolbarDidRemoveItemNotification;
APPKIT_EXPORT NSString *NSToolbarWillAddItemNotification;

@interface NSToolbar : NSObject
{
  BOOL _allowsUserCustomization;
  BOOL _autosavesConfiguration;
  NSMutableDictionary *_configurationDictionary;
  BOOL _customizationPaletteIsRunning;
  id _delegate;
  NSToolbarDisplayMode _displayMode;
  NSString *_identifier;
  BOOL _visible;
  NSMutableArray *_items;
  NSMutableArray *_visibleItems;
  id _toolbarView;
}

// Instance methods
- (BOOL)allowsUserCustomization;
- (BOOL)autosavesConfiguration;
- (NSDictionary *)configurationDictionary;
- (BOOL)customizationPaletteIsRunning;
- (id)delegate;
- (NSToolbarDisplayMode)displayMode;
- (NSString *)identifier;
- (id)initWithIdentifier: (NSString *)indentifier;
- (void)insertItemWithItemIdentifier: (NSString *)itemIdentifier
                             atIndex: (int)index;
- (BOOL)isVisible;
- (NSArray *)items;
- (void)removeItemAtIndex: (int)index;
- (void)runCustomizationPalette: (id)sender;

- (void)setAllowsUserCustomization: (BOOL)flag;
- (void)setAutosavesConfiguration: (BOOL)flag;
- (void)setConfigurationFromDictionary: (NSDictionary *)configDict;
- (void)setDelegate: (id)delegate;
- (void)setDisplayMode: (NSToolbarDisplayMode)displayMode;
- (void)setVisible: (BOOL)shown;
- (void)validateVisibleItems;
- (NSArray *)visibleItems;
@end /* interface of NSToolbar */

/*
 * Methods Implemented by the Delegate
 */
@interface NSObject (NSToolbarDelegate)
// notification methods
- (void) toolbarDidRemoveItem: (NSNotification *)aNotification;
- (void) toolbarWillAddItem: (NSNotification *)aNotification;

// delegate methods
// required method
- (NSToolbarItem *)toolbar: (NSToolbar *)toolbar
     itemForItemIdentifier: (NSString *)itemIdentifier
 willBeInsertedIntoToolbar: (BOOL)flag;
// required method
- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar;
// required method
- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar;
@end

#endif /* _GNUstep_H_NSToolbar */
