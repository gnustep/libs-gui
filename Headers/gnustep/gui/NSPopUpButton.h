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
  // Attributes
  NSMutableArray *list_items;
  NSMenuView *popb_view;
  NSRect list_rect;
  int selected_item;
  id pub_target;
  SEL pub_action;
  BOOL is_up;
  BOOL pulls_down;

  NSMenuWindow *popb_win;

  // Reserved for back-end use
  void *be_pub_reserved;
}

//
// Initializing an NSPopUpButton 
//
- (id)initWithFrame:(NSRect)frameRect
	  pullsDown:(BOOL)flag;

//
// Target and Action 
//
- (SEL)action;
- (void)setAction:(SEL)aSelector;
- (id)target;
- (void)setTarget:(id)anObject;

//
// Adding Items 
//
- (void)addItemWithTitle:(NSString *)title;
- (void)addItemsWithTitles:(NSArray *)itemTitles;
- (void)insertItemWithTitle:(NSString *)title
		    atIndex:(unsigned int)index;

//
// Removing Items 
//
- (void)removeAllItems;
- (void)removeItemWithTitle:(NSString *)title;
- (void)removeItemAtIndex:(int)index;

//
// Querying the NSPopUpButton about Its Items 
//
- (int)indexOfItemWithTitle:(NSString *)title;
- (int)indexOfSelectedItem;
- (int)numberOfItems;
- (id <NSMenuItem>)itemAtIndex:(int)index;
- (NSArray *)itemArray;
- (NSString *)itemTitleAtIndex:(int)index;
- (NSArray *)itemTitles;
- (id <NSMenuItem>)itemWithTitle:(NSString *)title;
- (id <NSMenuItem>)lastItem;
- (id <NSMenuItem>)selectedItem;
- (NSString*)titleOfSelectedItem;

//
// Manipulating the NSPopUpButton
//
- (NSFont *)font;
- (BOOL)pullsDown;
- (void)selectItemAtIndex:(int)index;
- (void)selectItemWithTitle:(NSString *)title;
- (void)setFont:(NSFont *)fontObject;
- (void)setPullsDown:(BOOL)flag;
- (void)setTitle:(NSString *)aString;
- (NSString *)stringValue;
- (void)synchronizeTitleAndSelectedItem;

//
// Displaying the NSPopUpButton's Items 
//
- (BOOL)autoenablesItems;
- (void)setAutoenablesItems:(BOOL)flag;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

extern NSString *NSPopUpButtonWillPopUpNotification;

#endif // _GNUstep_H_NSPopUpButton
