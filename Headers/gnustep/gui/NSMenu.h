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

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSMenuItem.h>
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSEvent;
@class NSMatrix;
@class NSMenuView;
@class NSPopUpButton;
@class NSPopUpButtonCell;
@class NSView;
@class NSWindow;

@interface NSMenu : NSObject <NSCoding, NSCopying>
{
  NSString *_title;
  NSMutableArray *_items;
  NSMenuView *_view;
  NSMenu *_superMenu;
  NSMenu *_attachedMenu;
  NSMutableArray *_notifications;
  BOOL _changedMessagesEnabled;
  BOOL _autoenable;
  BOOL _changed;
  BOOL _is_tornoff;

  // GNUstepExtra category
  NSPopUpButtonCell *_popUpButtonCell;
  BOOL _follow_transient;
  BOOL _isPartlyOffScreen;

@private
  NSWindow *_aWindow;
  NSWindow *_bWindow;
  id _titleView;
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
+ (void) popUpContextMenu: (NSMenu*)menu
		withEvent: (NSEvent*)event
		  forView: (NSView*)view;

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

/* Popup behaviour */
- (BOOL)_ownedByPopUp;
- (void)_setOwnedByPopUp: (NSPopUpButtonCell*)popUp;

/* Show menu on right mouse down */
- (void) _rightMouseDisplay: (NSEvent*)theEvent;
@end
#endif

APPKIT_EXPORT NSString* const NSMenuDidSendActionNotification;
APPKIT_EXPORT NSString* const NSMenuWillSendActionNotification;
APPKIT_EXPORT NSString* const NSMenuDidAddItemNotification;
APPKIT_EXPORT NSString* const NSMenuDidRemoveItemNotification;
APPKIT_EXPORT NSString* const NSMenuDidChangeItemNotification;

#endif // _GNUstep_H_NSMenu
