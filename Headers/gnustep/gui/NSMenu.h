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

@class NSMenuMatrix;

@interface NSMenu : NSObject <NSCoding, NSCopying>
{
  NSString* title;
  NSMenuMatrix* menuCells;
  NSMenu* supermenu;
  NSMenu* attachedMenu;
  BOOL autoenablesItems;
  BOOL menuChangedMessagesEnabled;
  BOOL menuHasChanged;

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
- (id <NSMenuItem>)addItemWithTitle:(NSString*)aString
			     action:(SEL)aSelector
		      keyEquivalent:(NSString*)charCode;
- (id <NSMenuItem>)insertItemWithTitle:(NSString*)aString
				action:(SEL)aSelector
			 keyEquivalent:(NSString*)charCode
			       atIndex:(unsigned int)index;
- (void)removeItem:(id <NSMenuItem>)anItem;
- (NSArray*)itemArray;

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
- (NSMenuMatrix*)menuCells;

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


/* Private class used to display the menu cells and respond to user actions */
@interface NSMenuMatrix : NSControl <NSCopying>
{
  NSMutableArray* cells;
  NSSize cellSize;
  NSMenu* menu;
  id selectedCell;
  NSRect selectedCellRect;
}

- initWithFrame:(NSRect)rect;
- (id <NSMenuItem>)insertItemWithTitle:(NSString*)aString
				action:(SEL)aSelector
			 keyEquivalent:(NSString*)charCode
			       atIndex:(unsigned int)index;
- (void)removeItem:(id <NSMenuItem>)anItem;
- (NSArray*)itemArray;
- (id <NSMenuItem>)itemWithTitle:(NSString*)aString;
- (id <NSMenuItem>)itemWithTag:(int)aTag;
- (NSRect)cellFrameAtRow:(int)index;
- (NSSize)cellSize;
- (void)setMenu:(NSMenu*)menu;
- (void)setSelectedCell:(id)aCell;
- (id)selectedCell;
- (NSRect)selectedCellRect;

@end

extern NSString* const NSMenuDidSendActionNotification;
extern NSString* const NSMenuWillSendActionNotification;

#endif // _GNUstep_H_NSMenu
