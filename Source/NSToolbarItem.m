/* 
   NSToolbarItem.m

   The Toolbar item class.
   
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
#include <Foundation/NSString.h>
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSImage.h"

@implementation NSToolbarItem
- (BOOL)allowsDuplicatesInToolbar
{
  return _allowsDuplicatesInToolbar;
}

- (NSImage *)image
{
  return _image;
}

- (id)initWithItemIdentifier: (NSString *)itemIdentifier
{
  ASSIGN(_itemIdentifier,itemIdentifier);
  return self;
}

- (BOOL)isEnabled
{
  return _enabled;
}

- (NSString *)itemIdentifier
{
  return _itemIdentifier;
}

- (NSString *)label
{
  return _label;
}

- (NSSize)maxSize
{
  return _maxSize;
}

- (NSMenuItem *)menuFormRepresentation
{
  return _menuFormRepresentation;
}

- (NSSize)minSize
{
  return _minSize;
}

- (NSString *)paletteLabel
{
  return _paletteLabel;
}

- (void)setAction: (SEL)action
{
  _action = action;
}

- (void)setEnabled: (BOOL)enabled
{
  enabled = _enabled;
}

- (void)setImage: (NSImage *)image
{
  ASSIGN(_image, image);
}

- (void)setLabel: (NSString *)label
{
  ASSIGN(_label, label);
}

- (void)setMaxSize: (NSSize)maxSize
{
  _maxSize = maxSize;
}

- (void)setMenuFormRepresentation: (NSMenuItem *)menuItem
{
  ASSIGN(_menuFormRepresentation, menuItem);
}

- (void)setMinSize: (NSSize)minSize
{
  _minSize = minSize;
}

- (void)setPaletteLabel: (NSString *)paletteLabel
{
  ASSIGN(_paletteLabel, paletteLabel);
}

- (void)setTag: (int)tag
{
  _tag = tag;
}

- (void)setTarget: (id)target
{
  ASSIGN(_target, target);
}

- (void)setToolTip: (NSString *)toolTip
{
  ASSIGN(_toolTip, toolTip);
}

- (void)setView: (NSView *)view
{
  ASSIGN(_view, view);
}

- (int)tag
{
  return _tag;
}

- (NSString *)toolTip
{
  return _toolTip;
}

- (NSToolbar *)toolbar
{
  return _toolbar;
}

- (void)validate
{
  // validate by default, we know that all of the
  // "standard" items are correct.
  _enabled = YES;
}

- (NSView *)view
{
  return _view;
}

// NSValidatedUserInterfaceItem protocol
- (SEL)action
{
  return _action;
}

- (id)target
{
  return _target;
}

// NSCopying protocol
- (id)copyWithZone: (NSZone *)zone 
{
  return self;
}
@end

/*
 *
 * Standard toolbar items.
 *
 */

// ---- NSToolbarSeperatorItemIdentifier
@interface GSToolbarSeperatorItem : NSToolbarItem
{
}
@end

@implementation GSToolbarSeperatorItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"GSToolbarSeperatorItem"];
  [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  return self;
}
@end

// ---- NSToolbarSpaceItemIdentifier
@interface GSToolbarSpaceItem : NSToolbarItem
{
}
@end

@implementation GSToolbarSpaceItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"GSToolbarSpaceItem"];
  [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  return self;
}
@end

// ---- NSToolbarFlexibleSpaceItemIdentifier
@interface GSToolbarFlexibleSpaceItem : NSToolbarItem
{
}
@end

@implementation GSToolbarFlexibleSpaceItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"GSToolbarFlexibleSpaceItem"];
  [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  return self;
}
@end

// ---- NSToolbarShowColorsItemIdentifier
@interface GSToolbarShowColorsItem : NSToolbarItem
{
}
@end

@implementation GSToolbarShowColorsItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"GSToolbarShowColorsItem"];
  [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  return self;
}
@end

// ---- NSToolbarShowFontsItemIdentifier
@interface GSToolbarShowFontsItem : NSToolbarItem
{
}
@end

@implementation GSToolbarShowFontsItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"GSToolbarShowFontsItem"];
  [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  return self;
}
@end

// ---- NSToolbarCustomizeToolbarItemIdentifier
@interface GSToolbarCustomizeToolbarItem : NSToolbarItem
{
}
@end

@implementation GSToolbarCustomizeToolbarItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"GSToolbarCustomizeToolbarItem"];
  [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  return self;
}
@end

// ---- NSToolbarPrintItemIdentifier
@interface GSToolbarPrintItem : NSToolbarItem
{
}
@end

@implementation GSToolbarPrintItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"GSToolbarPrintItem"];
  [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  return self;
}
@end
