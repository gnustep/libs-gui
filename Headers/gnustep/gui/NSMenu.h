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

#include <AppKit/NSView.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/PSOperators.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSPanel.h>

@class NSString;
@class NSEvent;
@class NSMatrix;
@class NSMenuView;
@class NSMenuWindow;
@class NSPopUpButton;

@interface      NSMenuWindow : NSPanel

- (void)moveToPoint:(NSPoint)aPoint;

@end

@interface NSMenu : NSObject <NSCoding, NSCopying>
{
  NSString *menu_title;
  NSMutableArray *menu_items;
  NSMenuView *menu_view;
  NSMenu *menu_supermenu;
  NSMenu *menu_attachedMenu;
  BOOL menu_changedMessagesEnabled;
  NSMutableArray *menu_notifications;
  BOOL menu_autoenable;
  BOOL menu_changed;
  BOOL menu_is_tornoff;

  id menu_popb;

  // GNUstepExtra category
  BOOL menu_is_beholdenToPopUpButton;
  BOOL menu_follow_transient;
  BOOL menu_is_visible;
  BOOL menu_isPartlyOffScreen;

  // Reserved for back-end use
  void *be_menu_reserved;

@private
  NSMenuWindow *aWindow;
  NSMenuWindow *bWindow;
  id titleView;
  NSMenu *_oldAttachedMenu;
}

/* Controlling Allocation Zones */
+ (void) setMenuZone: (NSZone*)zone;
+ (NSZone*) menuZone;

/* Creating an NSMenu */
- (id) initWithTitle: (NSString*)aTitle;

/* Setting Up the Menu Commands */
- (void) addItem: (id <NSMenuItem>)newItem;
- (id <NSMenuItem>) addItemWithTitle: (NSString *)aString
                              action: (SEL)aSelector
                       keyEquivalent: (NSString *)keyEquiv;
- (void) insertItem: (id <NSMenuItem>)newItem
            atIndex: (int)index;
- (id <NSMenuItem>) insertItemWithTitle: (NSString *)aString
                                 action: (SEL)aSelector
                          keyEquivalent: (NSString *)charCode
                                atIndex: (unsigned int)index;
- (void) itemChanged: (id <NSMenuItem>)anObject;
- (void) removeItem: (id <NSMenuItem>)anItem;
- (void) removeItemAtIndex: (int)index;

/* Finding menu items */
- (NSArray*) itemArray;
- (id <NSMenuItem>) itemAtIndex: (int)index;
- (id <NSMenuItem>) itemWithTag: (int)aTag;
- (id <NSMenuItem>) itemWithTitle: (NSString*)aString;
- (int) numberOfItems;

/* Finding Indices of Menu Items */
- (int) indexOfItem: (id <NSMenuItem>)anObject;
- (int) indexOfItemWithTitle: (NSString *)aTitle;
- (int) indexOfItemWithTag: (int)aTag;
- (int) indexOfItemWithTarget: (id)anObject
                   andAction: (SEL)actionSelector;
- (int) indexOfItemWithRepresentedObject: (id)anObject;
- (int) indexOfItemWithSubmenu: (NSMenu *)anObject;

/* Managing submenus */
- (void) setSubmenu: (NSMenu*)aMenu forItem: (id <NSMenuItem>)anItem;
- (void) submenuAction: (id)sender;
- (NSMenu*) attachedMenu;
- (BOOL) isAttached;
- (BOOL) isTornOff;
- (NSPoint) locationForSubmenu:(NSMenu*)aSubmenu;
- (NSMenu*) supermenu;
- (void) setSupermenu: (NSMenu *)supermenu;

/* Enabling and disabling menu items */
- (BOOL) autoenablesItems;
- (void) setAutoenablesItems: (BOOL)flag;
- (void) update;

/* Handling keyboard equivalents */
- (BOOL) performKeyEquivalent: (NSEvent*)theEvent;

/* Simulating Mouse Clicks */
- (void) performActionForItemAtIndex: (int)index;

/* Setting the Title */
- (void) setTitle: (NSString*)aTitle;
- (NSString*) title;

/* Setting the representing object */
- (void) setMenuRepresentation: (id)menuRep;
- (id) menuRepresentation;

/* Updating Menu Layout */
- (void) setMenuChangedMessagesEnabled: (BOOL)flag;
- (BOOL) menuChangedMessagesEnabled;
- (void) sizeToFit;

/* Displaying Context-Sensitive Help */
- (void) helpRequested: (NSEvent*)event;

@end


@interface NSObject (NSMenuActionResponder)

- (BOOL)validateMenuItem:(NSMenuItem*)aMenuItem;

@end

#ifndef	NO_GNUSTEP
@interface NSMenu (GNUstepExtra)
- (BOOL)isFollowTransient;
- (NSWindow *)window;

/* Shows the menu window on screen */
- (void)display;
- (void)displayTransient;

/* Close the associated window menu */
- (void)close;
- (void)closeTransient;

/* Moving menus */
- (void)nestedSetFrameOrigin:(NSPoint)aPoint;

/* Shift partly off-screen menus */
- (BOOL)isPartlyOffScreen;
- (void)nestedCheckOffScreen;
- (void)shiftOnScreen;

@end
#endif

/* A menu's title is an instance of this class */
@interface NSMenuWindowTitleView : NSView
{
  int titleHeight;
  id  menu;
  NSButton* button;
  NSButtonCell* buttonCell;
}

- (void) _addCloseButton;
- (void) _releaseCloseButton;
- (void) windowBecomeTornOff;
- (void) setMenu: (NSMenu*)menu;
- (NSMenu*) menu;

@end

extern NSString* const NSMenuDidSendActionNotification;
extern NSString* const NSMenuWillSendActionNotification;
extern NSString* const NSMenuDidAddItemNotification;
extern NSString* const NSMenuDidRemoveItemNotification;
extern NSString* const NSMenuDidChangeItemNotification;


#endif // _GNUstep_H_NSMenu
