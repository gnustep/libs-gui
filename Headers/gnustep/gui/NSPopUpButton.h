/* 
   NSPopUpButton.h

   Popup list class

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

#ifndef _GNUstep_H_NSPopUpButton
#define _GNUstep_H_NSPopUpButton

#include <AppKit/stdappkit.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSMenuCell.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSFont.h>
#include <Foundation/NSCoder.h>

@interface NSPopUpButton : NSButton <NSCoding>

{
  // Attributes
  NSMutableArray *list_items;
  NSRect list_rect;
  int selected_item;
  id pub_target;
  SEL pub_action;
  BOOL is_up;
  BOOL pulls_down;

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
- (NSMenuCell *)itemAtIndex:(int)index;
- (NSMatrix *)itemMatrix;
- (NSString *)itemTitleAtIndex:(int)index;
- (NSArray *)itemTitles;
- (NSMenuCell *)itemWithTitle:(NSString *)title;
- (NSMenuCell *)lastItem;
- (NSMenuCell *)selectedItem;
- (NSString *)titleOfSelectedItem;

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

#endif // _GNUstep_H_NSPopUpButton
