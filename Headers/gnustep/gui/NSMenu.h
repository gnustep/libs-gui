/* 
   NSMenu.h

   The menu class
   Here is your menu sir, our specials today are...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <AppKit/stdappkit.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenuCell.h>
#include <AppKit/NSMatrix.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSZone.h>

@interface NSMenu : NSObject <NSCoding>

{
  // Attributes
  NSString *window_title;
  NSMutableArray *menu_items;
  NSMenu *super_menu;
  BOOL autoenables_items;
  NSMatrix *menu_matrix;
  BOOL is_torn_off;

  // Reserved for back-end use
  void *be_menu_reserved;
}

//
// Controlling Allocation Zones
//
+ (NSZone *)menuZone;
+ (void)setMenuZone:(NSZone *)zone;

//
// Initializing a New NSMenu 
//
- (id)initWithTitle:(NSString *)aTitle;

//
// Setting Up the Menu Commands 
//
- (id)addItemWithTitle:(NSString *)aString
		action:(SEL)aSelector
	 keyEquivalent:(NSString *)charCode;
- (id)insertItemWithTitle:(NSString *)aString
		   action:(SEL)aSelector
	    keyEquivalent:(NSString *)charCode
		  atIndex:(unsigned int)index;
- (NSArray *)itemArray;
- (NSMatrix *)itemMatrix;
- (void)setItemMatrix:(NSMatrix *)aMatrix;

//
// Finding Menu Items 
//
- (id)cellWithTag:(int)aTag;

//
// Building Submenus 
//
- (NSMenuCell *)setSubmenu:(NSMenu *)aMenu
		   forItem:(NSMenuCell *)aCell;
- (void)submenuAction:(id)sender;

//
// Managing NSMenu Windows 
//
- (NSMenu *)attachedMenu;
- (BOOL)isAttached;
- (BOOL)isTornOff;
- (NSPoint)locationForSubmenu:(NSMenu *)aSubmenu;
- (void)sizeToFit;
- (NSMenu *)supermenu;

//
// Displaying the Menu 
//
- (BOOL)autoenablesItems;
- (void)setAutoenablesItems:(BOOL)flag;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

@interface NSObject (NSMenuActionResponder)

//
// Updating NSMenuCells
//
- (BOOL)validateCell:(id)aCell;

@end

#endif // _GNUstep_H_NSMenu
