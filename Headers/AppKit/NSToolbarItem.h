/* 
   NSToolbarItem.h

   The toolbar item class.
   
   Copyright (C) 2002 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>,
            Fabien Vallon <fabien.vallon@fr.alcove.com>,
	    Quentin Mathe <qmathe@club-internet.fr>
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

#ifndef _GNUstep_H_NSToolbarItem
#define _GNUstep_H_NSToolbarItem

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/AppKitDefines.h>
#include <AppKit/NSUserInterfaceValidation.h>

@class NSArray;
@class NSString;
@class NSDictionary;
@class NSMutableDictionary;
@class NSImage;
@class NSMenuItem;
@class NSView;
@class GSToolbar;

/*
 * Constants
 */
APPKIT_EXPORT NSString *NSToolbarSeparatorItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarSpaceItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarFlexibleSpaceItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarShowColorsItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarShowFontsItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarCustomizeToolbarItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarPrintItemIdentifier;

@interface NSToolbarItem : NSObject <NSCopying, NSValidatedUserInterfaceItem>
{
  // externally visible variables
  BOOL _allowsDuplicatesInToolbar;
  NSString *_itemIdentifier;
  NSString *_label;
  NSMenuItem *_menuFormRepresentation;
  NSString *_paletteLabel;
  NSImage *_image;

  // toolbar
  GSToolbar *_toolbar;
  NSString *_toolTip;
  id _view;
  NSView *_backView;
  BOOL _modified;
  BOOL _selectable;

  // size
  NSSize _maxSize;
  NSSize _minSize;

  // record the fact that the view responds to these
  // to save time.
  struct __flags
  {
    // gets
    unsigned int _isEnabled:1;
    unsigned int _tag:1;
    unsigned int _action:1;
    unsigned int _target:1;
    unsigned int _image:1;
    // sets
    unsigned int _setEnabled:1;
    unsigned int _setTag:1;
    unsigned int _setAction:1;
    unsigned int _setTarget:1;
    unsigned int _setImage:1;
    // to even out the long.
    unsigned int RESERVED:22;
  } _flags;
}

// Instance methods
- (id)initWithItemIdentifier: (NSString *)itemIdentifier;

- (void)validate;

// Accessors
- (SEL) action;
- (BOOL) allowsDuplicatesInToolbar;
- (NSImage *) image;
- (BOOL) isEnabled;
- (NSString *) itemIdentifier;
- (NSString *) label;
- (NSSize) maxSize;
- (NSMenuItem *) menuFormRepresentation;
- (NSSize) minSize;
- (NSString *) paletteLabel;
- (int) tag;
- (id) target;
- (NSString *) toolTip;
- (GSToolbar *) toolbar;
- (NSView *) view;
- (void) setAction: (SEL)action;
- (void) setEnabled: (BOOL)enabled;
- (void) setImage: (NSImage *)image;
- (void) setLabel: (NSString *)label;
- (void) setMaxSize: (NSSize)maxSize;
- (void) setMenuFormRepresentation: (NSMenuItem *)menuItem;
- (void) setMinSize: (NSSize)minSize;
- (void) setPaletteLabel: (NSString *)paletteLabel;
- (void) setTag: (int)tag;
- (void) setTarget: (id)target;
- (void) setToolTip: (NSString *)toolTip;
- (void) setView: (NSView *)view;

@end /* interface of NSToolbarItem */

// Informal protocol for the toolbar validation
@interface NSObject (NSToolbarItemValidation)
- (BOOL) validateToolbarItem: (NSToolbarItem *)toolbarItem;
@end

#endif /* _GNUstep_H_NSToolbarItem */
