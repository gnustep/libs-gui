/* 
   NSPopUpButtonCell.h

   Cell for Popup list class

   Copyright (C) 1999 Free Software Foundation, Inc.

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

#ifndef _GNUstep_H_NSPopUpButtonCell
#define _GNUstep_H_NSPopUpButtonCell

#include <AppKit/NSMenuItemCell.h>
#include <AppKit/NSMenuItem.h>

@class NSMenu;

typedef enum {
    NSPopUpNoArrow = 0,
    NSPopUpArrowAtCenter = 1,
    NSPopUpArrowAtBottom = 2,
} NSPopUpArrowPosition;

@interface NSPopUpButtonCell : NSMenuItemCell
{
  NSMenuItem	*_selectedItem;
  struct __pbcFlags {
      unsigned int pullsDown: 1;
      unsigned int preferredEdge: 3;
      unsigned int menuIsAttached: 1;
      unsigned int usesItemFromMenu: 1;
      unsigned int altersStateOfSelectedItem: 1;
      unsigned int decoding: 1;
      unsigned int arrowPosition: 2;
  } _pbcFlags;
}

- (id) initTextCell: (NSString*)stringValue pullsDown: (BOOL)pullDown;

// Overrides behavior of NSCell.  This is the menu for the popup, not a 
// context menu.  PopUpButtonCells do not have context menus.
- (void) setMenu: (NSMenu*)menu;
- (NSMenu*) menu;

// Behavior settings
- (void) setPullsDown: (BOOL)flag;
- (BOOL) pullsDown;

- (void) setAutoenablesItems: (BOOL)flag;
- (BOOL) autoenablesItems;

- (void) setPreferredEdge: (NSRectEdge)edge;
- (NSRectEdge) preferredEdge;

- (void) setUsesItemFromMenu: (BOOL)flag;
- (BOOL) usesItemFromMenu;

- (void) setAltersStateOfSelectedItem: (BOOL)flag;
- (BOOL) altersStateOfSelectedItem;

// Adding and removing items
- (void) addItemWithTitle: (NSString*)title;
- (void) addItemsWithTitles: (NSArray*)itemTitles;
- (void) insertItemWithTitle: (NSString*)title atIndex: (int)index;
        
- (void) removeItemWithTitle: (NSString*)title;
- (void) removeItemAtIndex: (int)index; 
- (void) removeAllItems;
        

// Accessing the items
- (NSArray*) itemArray;
- (int) numberOfItems;
 
- (int) indexOfItem: (id <NSMenuItem>)item;
- (int) indexOfItemWithTitle: (NSString*)title;
- (int) indexOfItemWithTag: (int)tag;
- (int) indexOfItemWithRepresentedObject: (id)obj;
- (int) indexOfItemWithTarget: (id)target andAction: (SEL)actionSelector;

- (id <NSMenuItem>) itemAtIndex: (int)index;
- (id <NSMenuItem>) itemWithTitle: (NSString*)title;
- (id <NSMenuItem>) lastItem;


// Dealing with selection
- (void) selectItem: (id <NSMenuItem>)item;
- (void) selectItemAtIndex: (int)index;
- (void) selectItemWithTitle: (NSString*)title;
- (void) setTitle: (NSString*)aString;

- (id <NSMenuItem>) selectedItem;
- (int) indexOfSelectedItem;
- (void) synchronizeTitleAndSelectedItem;

    
// Title conveniences
- (NSString*) itemTitleAtIndex: (int)index;
- (NSArray*) itemTitles;
- (NSString*) titleOfSelectedItem;

- (void) attachPopUpWithFrame: (NSRect)cellFrame inView: (NSView*)controlView;
- (void) dismissPopUp;
- (void) performClickWithFrame: (NSRect)frame inView: (NSView*)controlView;

// Arrow position for bezel style and borderless popups.
- (NSPopUpArrowPosition) arrowPosition;
- (void) setArrowPosition: (NSPopUpArrowPosition)position;
@end    

/* Notifications */ 
APPKIT_EXPORT NSString*NSPopUpButtonCellWillPopUpNotification;

#endif // _GNUstep_H_NSPopUpButtonCell
