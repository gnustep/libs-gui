/* 
   NSMenu.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: May 1997
   A completely rewritten version of the original source by Scott Christley.
   
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

#ifndef _GNUstep_H_NSMenu
#define _GNUstep_H_NSMenu

#include <AppKit/NSMenuItem.h>
#include <AppKit/NSControl.h>

@class NSString;
@class NSEvent;
@class NSMatrix;

@class NSMenuView;
@class NSMenuMatrix;
@class NSMenuWindow;

@interface NSMenu : NSObject <NSCoding, NSCopying>
{
  NSString *menu_title;
  NSMutableArray *menu_items;
  NSMenuView *menu_view;
  NSMenu *menu_supermenu;
  NSMenu *menu_attached_menu;
  id menu_rep;
  BOOL menu_ChangedMessagesEnabled;
  BOOL menu_autoenable;
  BOOL menu_changed;
  BOOL menu_is_tornoff;

  // Private.
  BOOL menu_follow_transient;

  // Reserved for back-end use
  void *be_menu_reserved;
}

/* Controlling allocation zones */
+ (void)setMenuZone:(NSZone*)zone;
+ (NSZone*)menuZone;

/* Setting the menu cell class */
+ (void)setCellClass:(Class)aClass;
+ (Class)cellClass;

/* Initializing a new NSMenu */
- (id)initWithTitle:(NSString*)aTitle;

/* Setting up the menu commands */
- (void) insertItem: (id <NSMenuItem>)newItem
            atIndex: (int)index;
- (id <NSMenuItem>) insertItemWithTitle: (NSString *)aString
                                 action: (SEL)aSelector
                          keyEquivalent: (NSString *)charCode
                                atIndex: (unsigned int)index;
- (void) addItem: (id <NSMenuItem>)newItem;
- (id <NSMenuItem>) addItemWithTitle: (NSString *)aString
                              action: (SEL)aSelector
                       keyEquivalent: (NSString *)keyEquiv;
- (void) removeItem: (id <NSMenuItem>)anItem;
- (void) removeItemAtIndex: (int)index;

- (NSArray*)itemArray;

- (int) indexOfItem: (id <NSMenuItem>)anObject;
- (int) indexOfItemWithTitle: (NSString *)aTitle;
- (int) indexOfItemWithTag: (int)aTag;
- (int) indexOfItemWithTarget: (id)anObject
                   andAction: (SEL)actionSelector;
- (int) indexOfItemWithRepresentedObject: (id)anObject;
- (int) indexOfItemWithSubmenu: (NSMenu *)anObject;

/* Finding menu items */
- (id <NSMenuItem>)itemWithTag:(int)aTag;
- (id <NSMenuItem>)itemWithTitle:(NSString*)aString;

/* Managing submenus */
- (void)setSubmenu:(NSMenu*)aMenu forItem:(id <NSMenuItem>)anItem;
- (void)submenuAction:(id)sender;
- (NSMenu*)attachedMenu;
- (BOOL)isAttached;
- (BOOL)isTornOff;
- (NSPoint)locationForSubmenu:(NSMenu*)aSubmenu;
- (NSMenu*)supermenu;

/* Enabling and disabling menu items */
- (void)setAutoenablesItems:(BOOL)flag;
- (BOOL)autoenablesItems;
- (void)update;

/* Perform a menu item action (not an OpenStep method) */
- (void)performActionForItem:(id <NSMenuItem>)anItem;

/* Handling keyboard equivalents */
- (BOOL)performKeyEquivalent:(NSEvent*)theEvent;

/* Updating menu layout */
- (void)setMenuChangedMessagesEnabled:(BOOL)flag;
- (BOOL)menuChangedMessagesEnabled;
- (void)sizeToFit;

/* Getting and setting the menu title */
- (void)setTitle:(NSString*)aTitle;
- (NSString*)title;

/* Getting the menu cells matrix */
- (NSMenuView *)menuView;

// non OS spec methods
- (void)_rightMouseDisplay;

@end


@interface NSObject (NSMenuActionResponder)
- (BOOL)validateMenuItem:(NSMenuItem*)aMenuItem;
@end


@interface NSMenu (PrivateMethods)
/* Shows the menu window on screen */
- (void)display;

/* Close the associated window menu */
- (void)close;
@end

extern NSString* const NSMenuDidSendActionNotification;
extern NSString* const NSMenuWillSendActionNotification;
extern NSString* const NSMenuDidAddItemNotification;
extern NSString* const NSMenuDidRemoveItemNotification;
extern NSString* const NSMenuDidChangeItemNotification;


#endif // _GNUstep_H_NSMenu
