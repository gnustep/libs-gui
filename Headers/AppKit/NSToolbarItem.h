/* 
   NSToolbarItem.h

   The toolbar item class.
   
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

#ifndef _GNUstep_H_NSToolbarItem
#define _GNUstep_H_NSToolbarItem

#include <Foundation/NSObject.h>
#include <AppKit/NSUserInterfaceValidation.h>
#include <AppKit/AppKitDefines.h>
#include <Foundation/NSGeometry.h>

@class NSArray;
@class NSString;
@class NSDictionary;
@class NSMutableDictionary;
@class NSToolbar;
@class NSImage;
@class NSMenuItem;
@class NSView;

/*
 * Constants
 */
APPKIT_EXPORT NSString *NSToolbarSeperatorItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarSpaceItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarFlexibleSpaceItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarShowColorsItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarShowFontsItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarCustomizeToolbarItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarPrintItemIdentifier;

@interface NSToolbarItem : NSObject <NSCopying, NSValidatedUserInterfaceItem>
{
  // externally visible variables
  SEL _action;
  BOOL _allowsDuplicatesInToolbar;
  BOOL _enabled;
  NSImage *_image;
  NSString *_itemIdentifier;
  NSString *_label;
  NSSize _maxSize;
  NSMenuItem *_menuFormRepresentation;
  NSSize _minSize;
  NSString *_paletteLabel;
  int _tag;
  id _target;
  NSToolbar *_toolbar;
  NSString *_toolTip;
  NSView *_view;
}

// Instance methods
- (SEL)action;
- (BOOL)allowsDuplicatesInToolbar;
- (NSImage *)image;
- (id)initWithItemIdentifier: (NSString *)itemIdentifier;
- (BOOL)isEnabled;
- (NSString *)itemIdentifier;
- (NSString *)label;
- (NSSize)maxSize;
- (NSMenuItem *)menuFormRepresentation;
- (NSSize)minSize;
- (NSString *)paletteLabel;
- (void)setAction: (SEL)action;
- (void)setEnabled: (BOOL)enabled;
- (void)setImage: (NSImage *)image;
- (void)setLabel: (NSString *)label;
- (void)setMaxSize: (NSSize)maxSize;
- (void)setMenuFormRepresentation: (NSMenuItem *)menuItem;
- (void)setMinSize: (NSSize)minSize;
- (void)setPaletteLabel: (NSString *)paletteLabel;
- (void)setTag: (int)tag;
- (void)setTarget: (id)target;
- (void)setToolTip: (NSString *)toolTip;
- (void)setView: (NSView *)view;
- (int)tag;
- (id)target;
- (NSString *)toolTip;
- (NSToolbar *)toolbar;
- (void)validate;
- (NSView *)view;
@end /* interface of NSToolbarItem */

@protocol NSToolbarItemValidation
- (BOOL)validateToolbarItem: (NSToolbarItem *)theItem;
@end

#endif /* _GNUstep_H_NSToolbarItem */
