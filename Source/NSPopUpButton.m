/* 
   NSPopUpButton.m

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Michael Hanni <mhanni@sprintmail.com>
   Date: June 1999
   
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

#include <gnustep/gui/config.h>
#import <Foundation/Foundation.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSFont.h>

//
// class variables
//
id _nspopupbuttonCellClass = nil;

//
// NSPopUpButton implementation
//

@implementation NSPopUpButton

///////////////////////////////////////////////////////////////
//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPopUpButton class])
    {
      // Initial version
      [self setVersion:1];
      [self setCellClass: [NSPopUpButtonCell class]];
    } 
}
  
//
// Initializing an NSPopUpButton 
//
- (id)init
{
  return [self initWithFrame:NSZeroRect pullsDown:NO];
}

- (id)initWithFrame:(NSRect)frameRect
{
  return [self initWithFrame:frameRect pullsDown:NO];
}

- (id)initWithFrame:(NSRect)frameRect
	  pullsDown:(BOOL)flag
{
  NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];

  [super initWithFrame:frameRect];

  [defaultCenter addObserver: self
		    selector: @selector(_popup:)
			name: NSPopUpButtonWillPopUpNotification
		      object: self];

  return self;
}

- (void)setMenu:(NSMenu *)menu
{
  [cell setMenu: menu];
}

- (NSMenu *)menu
{
  return [cell menu];
}

- (void)setPullsDown:(BOOL)flag
{
  [cell setPullsDown: flag];
}

- (BOOL)pullsDown
{
  return [cell pullsDown];
}

- (void)setAutoenablesItems:(BOOL)flag
{
  [cell setAutoenablesItems: flag];
}

- (BOOL)autoenablesItems
{
  return [cell autoenablesItems];
}

- (void)addItemWithTitle:(NSString *)title
{
  [cell addItemWithTitle: title];

  [self synchronizeTitleAndSelectedItem];
}

- (void)addItemsWithTitles:(NSArray *)itemTitles
{
  [cell addItemWithTitles: itemTitles];

  [self synchronizeTitleAndSelectedItem];
}

- (void)insertItemWithTitle:(NSString *)title
		    atIndex:(int)index
{
  [cell insertItemWithTitle: title adIndex: index];

  [self synchronizeTitleAndSelectedItem];
}

- (void)removeAllItems
{
  [cell removeAllItems];

  [self synchronizeTitleAndSelectedItem];
}

- (void)removeItemWithTitle:(NSString *)title
{
  [cell removeItemWithTitle];

  [self synchronizeTitleAndSelectedItem];
}

- (void)removeItemAtIndex:(int)index
{
  [cell removeItemAtIndex: index];

  [self synchronizeTitleAndSelectedItem];
}

- (id <NSMenuItem>)selectedItem
{
  return [cell selectedItem];
}

- (NSString *)titleOfSelectedItem
{
  return [cell titleOfSelectedItem];
}

- (int)indexOfSelectedItem
{
  return [cell indexOfSelectedItem];
}

- (void)selectItem:(id <NSMenuItem>)anObject
{
  [cell selectedItem: anObject];
}

- (void)selectItemAtIndex:(int)index
{
  [cell selectItemAtIndex: index];

  [self synchronizeTitleAndSelectedItem];
}

- (void)selectItemWithTitle:(NSString *)title
{
  [cell selectItemWithTitle: title];

  [self synchronizeTitleAndSelectedItem];
}

- (int)numberOfItems
{
  return [cell numberOfItems];
}

- (NSArray *)itemArray 
{
  return [cell itemArray];
}

- (id <NSMenuItem>)itemAtIndex:(int)index
{
  return [cell itemAtIndex: index];
}

- (NSString *)itemTitleAtIndex:(int)index
{
  return [cell itemTitleAtIndex: index];
}

- (NSArray *)itemTitles
{
  return [cell itemTitles];
}

- (id <NSMenuItem>)itemWithTitle:(NSString *)title
{
  return [cell itemWithTitle: title];
}

- (id <NSMenuItem>)lastItem
{
  return [cell lastItem];
}

- (int)indexOfItem:(id <NSMenuItem>)anObject
{
  return [cell indexOfItem: anObject];
}

- (int)indexOfItemWithTag:(int)tag
{
  return [cell indexOfItemWithTag: tag];
}

- (int)indexOfItemWithTitle:(NSString *)title
{
  return [cell indexOfItemWithTitle: title];
}

- (int)indexOfItemWithRepresentedObject:(id)anObject
{
  return [cell indexOfItemWithRepresentedObject: anObject];
}

- (int)indexOfItemWithTarget:(id)target
		   andAction:(SEL)actionSelector
{
  return [cell indexOfItemWithTarget: target andAction: actionSelector];
}

- (void)setPreferredEdge:(NSRectEdge)edge
{
  [cell setPreferredEdge: edge];
}

- (NSRectEdge)preferredEdge
{
  return [cell preferredEdge];
}

- (void)setTitle:(NSString *)aString
{
  [cell setTitle: aString];
}

- (void)synchronizeTitleAndSelectedItem
{
  [cell synchronizeTitleAndSelectedItem];

  [self sizeToFit];
}

- (void)sizeToFit
{
  [[popb_menu menuRepresentation] sizeToFit];
} 

- (void)_popup:(NSNotification*)notification
{
  [cell performClickWithFrame: [[notification object] frame]
                       inView: self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSNotificationCenter *nc;

  nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName: NSPopUpButtonWillPopUpNotification
                    object: self
                  userInfo: nil];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
/*
  [aCoder encodeObject: list_items];
  [aCoder encodeRect: list_rect];
  [aCoder encodeValueOfObjCType: @encode(int) at: &selected_item];
  [aCoder encodeConditionalObject: pub_target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &pub_action];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_up];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &pulls_down];
*/
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];
/*
  [aDecoder decodeValueOfObjCType: @encode(id) at: &list_items];
  list_rect = [aDecoder decodeRect];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &selected_item];
  pub_target = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &pub_action];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_up];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &pulls_down];
*/
  return self;
}
@end
