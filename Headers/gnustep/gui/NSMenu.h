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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSMenu
#define _GNUstep_H_NSMenu

#include <AppKit/stdappkit.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenuCell.h>
#include <AppKit/NSMatrix.h>
#include <Foundation/NSCoder.h>

@interface NSMenu : NSWindow <NSCoding>

{
  // Attributes
  NSMutableArray *menu_items;

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

#endif // _GNUstep_H_NSMenu
