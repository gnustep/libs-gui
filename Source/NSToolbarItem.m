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
#include <Foundation/NSDebug.h>

#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSEvent.h"
#include "GNUstepGUI/GSToolbarView.h"

/*
 * Each NSToolbarItem object are coupled with a backView which is their representation 
 * on the screen.
 * backView for the standard toolbar item (without custom view) are NSButton subclass
 * called GSToolbarButton.
 * backView for the toolbar item with a custom view are NSView subclass called
 * GSToolbarBackView.
 * GSToolbarButton and GSToolbarBackView are adjusted according to their content and
 * their title when the method layout is called.
 * The predefined GNUstep toolbar items are implemented with a class cluster pattern :
 * initWithToolbarItemIdentifier: returns differents concrete subclass in accordance
 * with the item identifier.
 */

@interface NSToolbar (GNUstepPrivate)
- (GSToolbarView *) _toolbarView;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (void) _layout;
- (NSView *) _backView;
- (BOOL) _isUpdated;
- (BOOL) _isFlexibleSpace;
- (void) _setToolbar: (NSToolbar *)toolbar;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _reload;
@end

/*
 * NSButton subclass is the toolbar buttons _backView
 */
@interface GSToolbarButton : NSButton
{
  NSToolbarItem *_toolbarItem;
}

- (id) initWithToolbarItem: (NSToolbarItem *)toolbarItem;
- (void) layout;
- (NSToolbarItem *) toolbarItem;
@end

@implementation GSToolbarButton
- (id) initWithToolbarItem: (NSToolbarItem *)toolbarItem
{ 
  self = [super initWithFrame: NSMakeRect(_ItemBackViewX, _ItemBackViewY, _ItemBackViewDefaultWidth, _ItemBackViewDefaultHeight)];
  if (self != nil)
    {
      ASSIGN(_toolbarItem, toolbarItem);
    }
  return self;   
}

- (void) layout
{
  float textWidth, layoutedWidth;
  NSAttributedString *attrStr;
  NSDictionary *attr;
  NSFont *font =[NSFont systemFontOfSize: 11]; // [NSFont smallSystemFontSize] or better should NSControlContentFontSize

  attr = [NSDictionary dictionaryWithObject: font forKey: @"NSFontAttributeName"];
  attrStr = [[NSAttributedString alloc] initWithString: [_toolbarItem label] attributes: attr];
      
  textWidth = [attrStr size].width + 2 * _InsetItemTextX;
  if (textWidth > _ItemBackViewDefaultWidth) 
  {
     layoutedWidth = textWidth;
  }
  else 
  {
     layoutedWidth = _ItemBackViewDefaultWidth;
  }
      
  [self setFrameSize: NSMakeSize(layoutedWidth, _ItemBackViewDefaultHeight)];
   
}

- (NSToolbarItem *) toolbarItem
{
  return _toolbarItem;
}
@end

/*
 * Back view used to enclose toolbar item's custom view
 */
@interface GSToolbarBackView : NSView
{
  NSToolbarItem *_toolbarItem;
  BOOL _enabled;
}

- (id) initWithToolbarItem: (NSToolbarItem *)toolbarItem;
- (NSToolbarItem *) toolbarItem;
- (void) setEnabled: (BOOL)enabled;
@end

@implementation GSToolbarBackView

- (id)initWithToolbarItem: (NSToolbarItem *)toolbarItem
{  
  self = [super initWithFrame: NSMakeRect(_ItemBackViewX, _ItemBackViewY, _ItemBackViewDefaultWidth,
  _ItemBackViewDefaultHeight)];
  
  if (self != nil)
    {  
      ASSIGN(_toolbarItem, toolbarItem);
    }
  
  return self;
}

- (void)drawRect: (NSRect)rect
{
  NSAttributedString *attrString;
  NSDictionary *attr;
  NSFont *font = [NSFont systemFontOfSize: 11]; // [NSFont smallSystemFontSize] or better should be NSControlContentFontSize
  int textX;
  
  [super drawRect: rect]; // We draw _view which is a subview
  
  if (_enabled)
    {
      [[NSColor blackColor] set];
    }
  else
    {
      [[NSColor grayColor] set];
    }

  attr = [NSDictionary dictionaryWithObject: font forKey: @"NSFontAttributeName"];
  attrString = [[NSAttributedString alloc] initWithString: [_toolbarItem label] attributes: attr]; // we draw the label
  textX = (([self frame].size.width - _InsetItemTextX) - [attrString size].width) / 2;
  [attrString drawAtPoint: NSMakePoint(textX, _InsetItemTextY)];
}

- (void) layout
{
  NSView *view;
  float textWidth;
  NSAttributedString *attrStr;
  NSDictionary *attr;
  NSFont *font = [NSFont systemFontOfSize: 11]; // [NSFont smallSystemFontSize] or better should be NSControlContentFontSize

  view = [_toolbarItem view];
  
  if ([view frame].size.height <= _ItemBackViewDefaultHeight)
    {
      [view setFrameOrigin: NSMakePoint(_InsetItemViewX, _InsetItemViewY)];
      [self addSubview: view];
    }
    else
    {
      [view removeFromSuperview];
    }
  
  [self setFrameSize: NSMakeSize([view frame].size.width + 2 * _InsetItemViewX, _ItemBackViewDefaultHeight)];
 
  attr = [NSDictionary dictionaryWithObject: font forKey: @"NSFontAttributeName"];
  attrStr = [[NSAttributedString alloc] initWithString: [_toolbarItem label] attributes: attr];
      
  textWidth = [attrStr size].width + 2 * _InsetItemTextX;
  if (textWidth > [self frame].size.width)
    {
      [self setFrameSize: NSMakeSize(textWidth, _ItemBackViewDefaultHeight)];
      [view setFrameOrigin: NSMakePoint((textWidth - [view frame].size.width) / 2, _InsetItemViewY)];
    }  
}

- (NSToolbarItem *)toolbarItem
{
  return _toolbarItem;
}

- (void) setEnabled: (BOOL)enabled
{
  id view = [_toolbarItem view];
 
  _enabled = enabled;
  if ([view respondsToSelector: @selector(setEnabled:)])
  {
    [view setEnabled: enabled];
  }
}

@end

/*
 *
 * Standard toolbar items.
 *
 */

// ---- NSToolbarSeparatorItemIdentifier
@interface GSToolbarSeparatorItem : NSToolbarItem
{
}
@end

@implementation GSToolbarSeparatorItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarSeperatorItem"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [(NSButton *)[self _backView] setImagePosition: NSImageOnly];
  [(NSButton *)[self _backView] setImage: image];
  // We bypass the toolbar item accessor to set the image in order to have it (48 * 48) not resized
   
  [[self _backView] setFrameSize: NSMakeSize(15, _ItemBackViewDefaultHeight)];
  
  return self;
}

- (NSMenuItem *) menuFormRepresentation 
{
  return nil; // override the default implementation in order to do nothing
}

- (void) _layout 
{
  // override the default implementation in order to do nothing
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
  self = [super initWithItemIdentifier: itemIdentifier];
  [self setLabel: @""];
  
  return self;
}

- (NSMenuItem *) menuFormRepresentation 
{
  return nil;// override the default implementation in order to do nothing
}

- (void) _layout 
{
  // override the default implementation in order to do nothing
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
  self = [super initWithItemIdentifier: itemIdentifier];
  [self setLabel: @""];
  [self _layout];
  
  return self;
}

- (NSMenuItem *) menuFormRepresentation 
{
  return nil;// override the default implementation in order to do nothing
}

- (void) _layout 
{
  NSView *backView = [self _backView];
  
  [backView setFrameSize: NSMakeSize(0, [backView frame].size.height)];
  
  // override the default implementation in order to reset the _backView to a zero width
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
  NSImage *image = [NSImage imageNamed: @"common_ToolbarShowColorsItem"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Colors"];

  // set action...
  [self setTarget: nil]; // goes to first responder..
  [self setAction: @selector(orderFrontColorPanel:)];

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
  NSImage *image = [NSImage imageNamed: @"common_ToolbarShowFontsItem"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Fonts"];

  // set action...
  [self setTarget: nil]; // goes to first responder..
  [self setAction: @selector(orderFrontFontPanel:)];

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
  NSImage *image = [NSImage imageNamed: @"common_ToolbarCustomizeToolbarItem"];
  
  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Customize"];

  // set action...
  [self setTarget: nil]; // goes to first responder..
  [self setAction: @selector(runCustomizationPalette:)];

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
  NSImage *image = [NSImage imageNamed: @"common_Printer"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Print..."];

  // set action...
  [self setTarget: nil]; // goes to first responder..
  [self setAction: @selector(print:)];

  return self;
}
@end


@implementation NSToolbarItem
- (BOOL)allowsDuplicatesInToolbar
{
  return _allowsDuplicatesInToolbar;
}

- (NSImage *)image
{
  if(_flags._image)
    {
      return [(id)_backView image];
    }
  return nil;
}

- (id)initWithItemIdentifier: (NSString *)itemIdentifier
{
  GSToolbarButton *button;
  NSButtonCell *cell;
  
  if ((self = [super init]) != nil)
    {   
    
      // GNUstep predefined toolbar items
       
      if ([itemIdentifier isEqualToString: @"NSToolbarSeparatorItemIdentifier"] 
           && ![self isKindOfClass:[GSToolbarSeparatorItem class]])
        {
          [self release];
          self = [[GSToolbarSeparatorItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarSpaceItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarSpaceItem class]])
        {
          [self release];
          self = [[GSToolbarSpaceItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarFlexibleSpaceItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarFlexibleSpaceItem class]])
        {
          [self release];
          self = [[GSToolbarFlexibleSpaceItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarShowColorsItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarShowColorsItem class]])
        {
          [self release];
          self = [[GSToolbarShowColorsItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarShowFontsItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarShowFontsItem class]])
        {
          [self release];
          self = [[GSToolbarShowFontsItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarCustomizeToolbarItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarCustomizeToolbarItem class]])
        {
          [self release];
          self = [[GSToolbarCustomizeToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
        }
     
      else if ([itemIdentifier isEqualToString: @"NSToolbarPrintItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarPrintItem class]])
        {
          [self release];
          self = [[GSToolbarPrintItem alloc] initWithItemIdentifier: itemIdentifier];
        }
	
      // Normal toolbar items
      else
        {
      
          ASSIGN(_itemIdentifier, itemIdentifier);
      
          button = [[GSToolbarButton alloc] initWithToolbarItem: self];
          cell = [button cell];
	  [button setTitle: @""];
	  [button setEnabled: NO];
          [button setBordered: NO];
          [button setImagePosition: NSImageAbove];
	  [cell setBezeled: YES];
          [cell setHighlightsBy: NSChangeGrayCellMask | NSChangeBackgroundCellMask];
          [cell setFont: [NSFont systemFontOfSize: 11]]; // [NSFont smallSystemFontSize] or better should be controlContentFontSize

          [_backView release];
          _backView = button;
        }
        
      // gets
      _flags._isEnabled  = [_backView respondsToSelector: @selector(isEnabled)];
      _flags._tag        = YES;
      _flags._action     = [_backView respondsToSelector: @selector(action)];
      _flags._target     = [_backView respondsToSelector: @selector(target)];
      _flags._image      = [_backView respondsToSelector: @selector(image)];
      // sets
      _flags._setEnabled = [_backView respondsToSelector: @selector(setEnabled:)];
      _flags._setTag     = YES;
      _flags._setAction  = [_backView respondsToSelector: @selector(setAction:)];
      _flags._setTarget  = [_backView respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_backView respondsToSelector: @selector(setImage:)];
    
    }
  
  return self;
}

- (BOOL)isEnabled
{
  if(_flags._isEnabled)
    {
      return [(id)_backView isEnabled];
    }
  return NO;
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
  NSMenuItem *menuItem;
  
  if (_menuFormRepresentation == nil)
  {
    menuItem = [[NSMenuItem alloc] initWithTitle: [self label]  
                                          action: [self action] 
                                   keyEquivalent: @""];
    [menuItem setTarget: [self target]];
    AUTORELEASE(menuItem);
  }
  else
  {
    menuItem = [_menuFormRepresentation copy];
  }
  
  return menuItem;
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
  if(_flags._setAction)
    {
      if ([_backView isKindOfClass: [NSButton class]])
        [(NSButton *)_backView setAction: action];
	if (action != NULL)
	  {
	    [(NSButton *)_backView setEnabled: YES];
	  }
	else
	  {
	    [(NSButton *)_backView setEnabled: NO];
	  }
    }
}

- (void)setEnabled: (BOOL)enabled
{
  if(_flags._setEnabled)
    [(id)_backView setEnabled: enabled];
}

- (void)setImage: (NSImage *)image
{
  if(_flags._setImage)
    {  
      ASSIGN(_image, image);  
      
      [_image setScalesWhenResized: YES];
      [_image setSize: NSMakeSize(32, 32)];
      
      if ([_backView isKindOfClass: [NSButton class]])
        [(NSButton *)_backView setImage: _image];
    }
}

- (void)setLabel: (NSString *)label
{
  ASSIGN(_label, label);
  
  if ([_backView isKindOfClass: [NSButton class]])
    [(NSButton *)_backView setTitle:_label];

  _updated = YES;
  if (_toolbar != nil)
    [[_toolbar _toolbarView] _reload];
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
  if(_flags._tag)
    [_backView setTag: tag];
}

- (void)setTarget: (id)target
{
   if(_flags._target)
     {
       if ([_backView isKindOfClass: [NSButton class]])
         [(NSButton *)_backView setTarget: target];
     }
}

- (void)setToolTip: (NSString *)toolTip
{
  ASSIGN(_toolTip, toolTip);
}

- (void)setView: (NSView *)view
{
  ASSIGN(_view, view);
  
  if (_view == nil)
    {
      // gets
      _flags._isEnabled  = [_backView respondsToSelector: @selector(isEnabled)];
      _flags._action     = [_backView respondsToSelector: @selector(action)];
      _flags._target     = [_backView respondsToSelector: @selector(target)];
      _flags._image      = [_backView respondsToSelector: @selector(image)];
      // sets
      _flags._setEnabled = [_backView respondsToSelector: @selector(setEnabled:)];
      _flags._setAction  = [_backView respondsToSelector: @selector(setAction:)];
      _flags._setTarget  = [_backView respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_backView respondsToSelector: @selector(setImage:)];
    }
  else
    {
      // gets
      _flags._isEnabled  = [_view respondsToSelector: @selector(isEnabled)];
      _flags._action     = [_view respondsToSelector: @selector(action)];
      _flags._target     = [_view respondsToSelector: @selector(target)];
      _flags._image      = [_backView respondsToSelector: @selector(image)];
      // sets
      _flags._setEnabled = [_view respondsToSelector: @selector(setEnabled:)];
      _flags._setAction  = [_view respondsToSelector: @selector(setAction:)];
      _flags._setTarget  = [_view respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_backView respondsToSelector: @selector(setImage:)];
    }
  
  [_backView release];
  _backView = [[GSToolbarBackView alloc] initWithToolbarItem: self];
}

- (int)tag
{
  if(_flags._tag)
    return [_backView tag];

  return 0;
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
}

- (NSView *)view
{
  return _view;
}

// Private or package like visibility methods

- (NSView *)_backView
{
  return _backView;
}

- (void) _layout
{
  [(id)_backView layout];
}

- (BOOL)_isUpdated
{
  return _updated;
}

- (BOOL)_isFlexibleSpace
{
  return [self isKindOfClass: [GSToolbarFlexibleSpaceItem class]];
}

- (void) _setToolbar: (NSToolbar *)toolbar
{
  ASSIGN(_toolbar, toolbar);
}

// NSValidatedUserInterfaceItem protocol
- (SEL)action
{
  if(_flags._action)
    {
      if ([_backView isKindOfClass: [NSButton class]])
        return [(NSButton *)_backView action];
    }
  return 0;
}

- (id)target
{
  if(_flags._target)
    {
      if ([_backView isKindOfClass: [NSButton class]])
        return [(NSButton *)_backView target];
    }

  return nil;
}

// NSCopying protocol
- (id)copyWithZone: (NSZone *)zone 
{
  NSToolbarItem *new = [[NSToolbarItem allocWithZone: zone] initWithItemIdentifier: _itemIdentifier];

  // copy all items individually...
  [new setTarget: [self target]];
  [new setAction: [self action]];
  [new setView: [self view]];
  [new setToolTip: [[self toolTip] copyWithZone: zone]];
  [new setTag: [self tag]];
  [new setImage: [[self image] copyWithZone: zone]];
  [new setEnabled: [self isEnabled]];
  [new setPaletteLabel: [[self paletteLabel] copyWithZone: zone]];
  [new setMinSize: NSMakeSize(_minSize.width, _minSize.height)];
  [new setMaxSize: NSMakeSize(_maxSize.width, _maxSize.height)];

  return self;
}
@end
