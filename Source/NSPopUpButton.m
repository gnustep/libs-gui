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
#include <AppKit/NSMenu.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSFont.h>

//
// class variables
//
Class _nspopupbuttonCellClass = 0;

//
// NSPopUpButton implementation
//

@implementation NSPopUpButton

///////////////////////////////////////////////////////////////
//
// Class methods
//
+ (void) initialize
{
  if (self == [NSPopUpButton class])
    {
      // Initial version
      [self setVersion: 1];
      [self setCellClass: [NSPopUpButtonCell class]];
    } 
}

+ (Class) cellClass
{
  return _nspopupbuttonCellClass;
}

+ (void) setCellClass: (Class)classId
{
  _nspopupbuttonCellClass = classId;
}

//
// Initializing an NSPopUpButton 
//
- (id) init
{
  return [self initWithFrame: NSZeroRect pullsDown: NO];
}

- (id) initWithFrame: (NSRect)frameRect
{
  return [self initWithFrame: frameRect pullsDown: NO];
}

- (id) initWithFrame: (NSRect)frameRect
	   pullsDown: (BOOL)flag
{
  [super initWithFrame: frameRect];
  [self setPullsDown: flag];

  return self;
}

- (void) setMenu: (NSMenu *)menu
{
  [_cell setMenu: menu];
}

- (NSMenu *) menu
{
  return [_cell menu];
}

- (void) setPullsDown: (BOOL)flag
{
  [_cell setPullsDown: flag];
}

- (BOOL) pullsDown
{
  return [_cell pullsDown];
}

- (void) setAutoenablesItems: (BOOL)flag
{
  [_cell setAutoenablesItems: flag];
}

- (BOOL) autoenablesItems
{
  return [_cell autoenablesItems];
}

- (void) addItemWithTitle: (NSString *)title
{
  [_cell addItemWithTitle: title];

  [self synchronizeTitleAndSelectedItem];
}

- (void) addItemsWithTitles: (NSArray *)itemTitles
{
  [_cell addItemsWithTitles: itemTitles];

  [self synchronizeTitleAndSelectedItem];
}

- (void) insertItemWithTitle: (NSString *)title
		     atIndex: (int)index
{
  [_cell insertItemWithTitle: title 
	atIndex: index];

  [self synchronizeTitleAndSelectedItem];
}

- (void) removeAllItems
{
  [_cell removeAllItems];

  [self synchronizeTitleAndSelectedItem];
}

- (void) removeItemWithTitle: (NSString *)title
{
  [_cell removeItemWithTitle: title];

  [self synchronizeTitleAndSelectedItem];
}

- (void) removeItemAtIndex: (int)index
{
  [_cell removeItemAtIndex: index];

  [self synchronizeTitleAndSelectedItem];
}

- (id <NSMenuItem>) selectedItem
{
  return [_cell selectedItem];
}

- (NSString *) titleOfSelectedItem
{
  return [_cell titleOfSelectedItem];
}

- (int) indexOfSelectedItem
{
  return [_cell indexOfSelectedItem];
}

- (void) selectItem: (id <NSMenuItem>)anObject
{
  [_cell selectItem: anObject];
}

- (void) selectItemAtIndex: (int)index
{
  [_cell selectItemAtIndex: index];
}

- (void) selectItemWithTitle: (NSString *)title
{
  [_cell selectItemWithTitle: title];
}

- (int) numberOfItems
{
  return [_cell numberOfItems];
}

- (NSArray *) itemArray 
{
  return [_cell itemArray];
}

- (id <NSMenuItem>) itemAtIndex: (int)index
{
  return [_cell itemAtIndex: index];
}

- (NSString *) itemTitleAtIndex: (int)index
{
  return [_cell itemTitleAtIndex: index];
}

- (NSArray *) itemTitles
{
  return [_cell itemTitles];
}

- (id <NSMenuItem>) itemWithTitle: (NSString *)title
{
  return [_cell itemWithTitle: title];
}

- (id <NSMenuItem>) lastItem
{
  return [_cell lastItem];
}

- (int) indexOfItem: (id <NSMenuItem>)anObject
{
  return [_cell indexOfItem: anObject];
}

- (int) indexOfItemWithTag: (int)tag
{
  return [_cell indexOfItemWithTag: tag];
}

- (int) indexOfItemWithTitle: (NSString *)title
{
  return [_cell indexOfItemWithTitle: title];
}

- (int) indexOfItemWithRepresentedObject: (id)anObject
{
  return [_cell indexOfItemWithRepresentedObject: anObject];
}

- (int) indexOfItemWithTarget: (id)target
		    andAction: (SEL)actionSelector
{
  return [_cell indexOfItemWithTarget: target andAction: actionSelector];
}

- (void) setPreferredEdge: (NSRectEdge)edge
{
  [_cell setPreferredEdge: edge];
}

- (NSRectEdge) preferredEdge
{
  return [_cell preferredEdge];
}

- (void) setTitle: (NSString *)aString
{
  [_cell setTitle: aString];
}

- (void) synchronizeTitleAndSelectedItem
{
  [_cell synchronizeTitleAndSelectedItem];

  [self sizeToFit];

  NSLog(@"synchronizeTitleAndSelectedItem");

  [self setNeedsDisplay: YES];
}

- (void) sizeToFit
{
  [[popb_menu menuRepresentation] sizeToFit];
} 

- (void) mouseDown: (NSEvent *)theEvent
{ 
  NSMenuView *mr = [[_cell menu] menuRepresentation];
  NSEvent    *e;
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  
  if ([self isEnabled] == NO)
    return;

  [nc postNotificationName: NSPopUpButtonWillPopUpNotification
      object: self];

  // Attach the popUp
  [_cell attachPopUpWithFrame: bounds
	inView: self];

  // Process events; we start menu events processing by converting 
  // this event to the menu window, and sending it there. 
  e = [NSEvent mouseEventWithType: [theEvent type]
	       location: [[mr window] convertScreenToBase: 
					[window convertBaseToScreen: 
						  [theEvent locationInWindow]]]
	       modifierFlags: [theEvent modifierFlags]
	       timestamp: [theEvent timestamp]
	       windowNumber: [[mr window] windowNumber]
	       context: nil // TODO ? 
	       eventNumber: [theEvent eventNumber]
	       clickCount: [theEvent clickCount] 
	       pressure: [theEvent pressure]];
  [[mr window] sendEvent: e];

  // Update our selected item
  [self synchronizeTitleAndSelectedItem];
  
  // Dismiss the popUp
  [_cell dismissPopUp];

  // Send action to target
  [super sendAction: [self action]
	 to: [self target]];
  
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
