/* 
   NSPopUpButton.h

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: 1999
   
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

#ifndef _GNUstep_H_NSPopUpButton
#define _GNUstep_H_NSPopUpButton

#include <Foundation/Foundation.h>

#include <AppKit/NSButton.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenu.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSMenuView;
@class NSFont;
@class NSMatrix;

@interface NSPopUpButton : NSButton <NSCoding>
{
  NSMenu *popb_menu;
  BOOL popb_pullsDown;
  BOOL popb_autoenableItems;
  int popb_selectedItem;

  id pub_target;
  SEL pub_action;
  BOOL is_up;
}

//
// Initializing an NSPopUpButton 
//
- (id)initWithFrame:(NSRect)frameRect
	  pullsDown:(BOOL)flag;

- (void)setPullsDown:(BOOL)flag;
- (BOOL)pullsDown;
- (void)setAutoenablesItems:(BOOL)flag;
- (BOOL)autoenablesItems;
- (void)addItemWithTitle:(NSString *)title;
- (void)addItemsWithTitles:(NSArray *)itemTitles;
- (void)insertItemWithTitle:(NSString *)title   
                    atIndex:(int)index;
- (void)removeAllItems;
- (void)removeItemWithTitle:(NSString *)title;
- (void)removeItemAtIndex:(int)index;
- (id <NSMenuItem>)selectedItem;
- (NSString *)titleOfSelectedItem;
- (int)indexOfSelectedItem;
- (void)selectItem:(id <NSMenuItem>)anObject;
- (void)selectItemAtIndex:(int)index;
- (void)selectItemWithTitle:(NSString *)title;
- (int)numberOfItems;
- (NSArray *)itemArray;
- (id <NSMenuItem>)itemAtIndex:(int)index;
- (NSString *)itemTitleAtIndex:(int)index;
- (NSArray *)itemTitles;
- (id <NSMenuItem>)itemWithTitle:(NSString *)title;
- (id <NSMenuItem>)lastItem;
- (int)indexOfItem:(id <NSMenuItem>)anObject;
- (int)indexOfItemWithTag:(int)tag;
- (int)indexOfItemWithTitle:(NSString *)title;
- (int)indexOfItemWithRepresentedObject:(id)anObject;
- (int)indexOfItemWithTarget:(id)target
                   andAction:(SEL)actionSelector;
- (void)setPreferredEdge:(NSRectEdge)edge;
- (NSRectEdge)preferredEdge;
- (int)setTitle:(NSString *)aString;
- (void)synchronizeTitleAndSelectedItem;
- (void)_popup:(NSNotification*)notification;
- (void)mouseDown:(NSEvent *)theEvent;

- (id) initWithCoder: (NSCoder*)aDecoder;
- (void) encodeWithCoder: (NSCoder*)aCoder;
@end

extern NSString *NSPopUpButtonWillPopUpNotification;

#endif // _GNUstep_H_NSPopUpButton
