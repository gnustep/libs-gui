/* 
   NSMenu.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: 1999

   A completely rewritten version of the original source by Scott Christley.
   and: 
   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: May 1997
   and: 
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   
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
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSMatrix.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSMenuItemCell.h>

static NSZone *menuZone = NULL;

@implementation NSMenu

// Class Methods
+ (void) initialize
{
  if (self == [NSMenu class])
    {
      [self setVersion: 1];
    }
}

+ (void) setMenuZone: (NSZone *)zone
{
  menuZone = zone;
}

// Methods.

- (id) init
{
  return [self initWithTitle: @"Menu"];
}

- (id) initWithTitle: (NSString *)aTitle
{
  [super init];

  // Keep the title.
  ASSIGN(menu_title, aTitle);

  // Create an array to store out cells.
  menu_items = [NSMutableArray new];

  // Create a NSMenuView to draw our cells.
  menu_view = [[NSMenuView alloc] initWithFrame: NSMakeRect(0,0,50,50)];

  // Set ourself as the menu for this view.
  [menu_view setMenu: self];

  // We have no supermenu.
  menu_supermenu = nil;
  menu_is_tornoff = NO;

  menu_changed = YES;
  /* According to the spec, menus do autoenable by default */
  menu_autoenable = YES;

  return self;
}

/*
 * - (void)insertItem: (id <NSMenuItem>)newItem
 *            atIndex: (int)index
 *
 * This method has been modified to convert anything that conforms to the
 * <NSMenuItem> Protocol into a NSMenuItemCell which will be added to the
 * items array.
 *
 * Blame: Michael
 */

- (void) insertItem: (id <NSMenuItem>)newItem
	    atIndex: (int)index
{
  NSNotificationCenter *nc;
  NSDictionary *d;

  if ([(id)newItem conformsToProtocol: @protocol(NSMenuItem)])
    {
      if ([(id)newItem isKindOfClass: [NSMenuItemCell class]])
        {
	  nc = [NSNotificationCenter defaultCenter];
  	  d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:index]
					  forKey: @"NSMenuItemIndex"];
  	  [nc postNotificationName: NSMenuDidAddItemNotification
                    	    object: self
                          userInfo: d];

          [menu_items insertObject: newItem atIndex: index];
	}
      else
        {

	  // The item we received conformed to <NSMenuItem> which is good,
	  // but it wasn't an NSMenuItemCell which is bad. Therefore, we
	  // loop through the system and create an NSMenuItemCell for
	  // this bad boy.

          [self insertItemWithTitle: [newItem title]
			     action: [newItem action]
		      keyEquivalent: [newItem keyEquivalent]
			    atIndex: index];
        }
    }
  else
    NSLog(@"You must use an object that conforms to NSMenuItem.\n");

  menu_changed = YES;
}

- (id <NSMenuItem>) insertItemWithTitle: (NSString *)aString
			         action: (SEL)aSelector
			  keyEquivalent: (NSString *)charCode 
			        atIndex: (unsigned int)index
{
  id anItem = [NSMenuItemCell new];

  [anItem setTitle: aString];
  [anItem setAction: aSelector];
  [anItem setKeyEquivalent: charCode];

  // Insert the new item into the stream.

  [self insertItem:anItem atIndex:index];

  // For returns sake.

  return anItem;
}

- (void) addItem: (id <NSMenuItem>)newItem
{
  [self insertItem: newItem atIndex: [menu_items count]];
}

- (id <NSMenuItem>) addItemWithTitle: (NSString *)aString
			      action: (SEL)aSelector 
		       keyEquivalent: (NSString *)keyEquiv
{
  return [self insertItemWithTitle: aString
			    action: aSelector
		     keyEquivalent: keyEquiv
			   atIndex: [menu_items count]];
}

- (void) removeItem: (id <NSMenuItem>)anItem
{
  [self removeItemAtIndex:[menu_items indexOfObject: anItem]];
}

- (void) removeItemAtIndex: (int)index
{
  NSNotificationCenter *nc;
  NSDictionary *d;
  id anItem = [menu_items objectAtIndex:index];

  if (!anItem)
    return;

  if ([(NSMenuItemCell *)anItem isKindOfClass: [NSMenuItemCell class]])
    {
      nc = [NSNotificationCenter defaultCenter];
      d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:index]
				      forKey: @"NSMenuItemIndex"];
      [nc postNotificationName: NSMenuDidRemoveItemNotification
                        object: self
                      userInfo: d];

      [menu_items removeObjectAtIndex: index];
    }
  else
    {
      NSLog(@"You must use an NSMenuItemCell, or a derivative thereof.\n");
    }

  menu_changed = YES;
}

- (void) itemChanged: (id <NSMenuItem>)anObject
{
  // another nebulous method in NSMenu. Is this correct?

  NSNotificationCenter *nc;
  NSDictionary *d;

  nc = [NSNotificationCenter defaultCenter];
  d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:[self indexOfItem: anObject]]
                                  forKey: @"NSMenuItemIndex"];
  [nc postNotificationName: NSMenuDidChangeItemNotification
                    object: self
                  userInfo: d];  
}

- (id <NSMenuItem>) itemWithTag: (int)aTag
{
  unsigned i, count = [menu_items count];
  id menuCell;

  for (i = 0; i < count; i++)
    {
      menuCell = [menu_items objectAtIndex: i];
      if ([menuCell tag] == aTag)
        return menuCell;
    }
  return nil;
}

- (id <NSMenuItem>) itemWithTitle: (NSString*)aString
{
  unsigned i, count = [menu_items count];
  id menuCell;

  for (i = 0; i < count; i++)
    {
      menuCell = [menu_items objectAtIndex: i];
      if ([[menuCell title] isEqual: aString])
        return menuCell;
    }
  return nil;
}

- (id <NSMenuItem>) itemAtIndex: (int)index
{
  // FIXME should raise an exception if out of range.
  return [menu_items objectAtIndex: index];
}

- (int) numberOfItems
{
  return [menu_items count];
}

- (NSArray *) itemArray
{
  return (NSArray *)menu_items;
}

- (int) indexOfItem: (id <NSMenuItem>)anObject
{
  if (![(NSMenuItemCell *)anObject isKindOfClass: [NSMenuItemCell class]])
    {
      NSLog(@"You must use an NSMenuItemCell, or a derivative thereof.\n");
      return -1;
    }
  return [menu_items indexOfObject: anObject];
}

- (int) indexOfItemWithTitle: (NSString *)aTitle
{
  id anItem;

  if ((anItem = [self itemWithTitle: aTitle]))
    return [menu_items indexOfObject: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTag: (int)aTag
{
  id anItem;

  if ((anItem = [self itemWithTag: aTag]))
    return [menu_items indexOfObject: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTarget: (id)anObject
		   andAction: (SEL)actionSelector
{
  return -1;
}

- (int) indexOfItemWithRepresentedObject: (id)anObject
{
  return -1;
}

- (int) indexOfItemWithSubmenu: (NSMenu *)anObject
{
  return -1;
}

// Dealing with submenus.

- (void) setSubmenu: (NSMenu *)aMenu
	    forItem: (id <NSMenuItem>) anItem 
{
  [anItem setTarget: aMenu];
  [anItem setAction: @selector(submenuAction:)];
  if (aMenu)
    aMenu->menu_supermenu = self;

  ASSIGN(aMenu->menu_title, [anItem title]);

  // notification that the menu has changed.
}

- (void) submenuAction: (id)sender
{
}

- (NSMenu *) attachedMenu
{
  return menu_attached_menu;
}

- (BOOL) isAttached
{
  // eh?
  return menu_supermenu && [menu_supermenu attachedMenu] == self;
}

- (BOOL) isTornOff
{
  return menu_is_tornoff;
}

- (NSPoint) locationForSubmenu: (NSMenu *)aSubmenu
{
  return NSZeroPoint;
}

- (NSMenu *) supermenu
{
  return menu_supermenu;
}

- (void) setSupermenu: (NSMenu *)supermenu
{
  ASSIGN(menu_supermenu, supermenu);
}

- (void) setAutoenablesItems: (BOOL)flag
{
  menu_autoenable = flag;
}

- (BOOL) autoenablesItems
{
  return menu_autoenable;
}

- (void) update
{
  // FIXME: needs to be checked.
  id		cells;
  unsigned	i, count;
  id		theApp = [NSApplication sharedApplication];
  
  if (menu_changed)
    [self sizeToFit];

  if (![self autoenablesItems])
    return;
      
  count = [menu_items count];  
      
  /* Temporary disable automatic displaying of menu */
  [self setMenuChangedMessagesEnabled: NO];
      
  for (i = 0; i < count; i++)
    {
      id<NSMenuItem>	cell = [menu_items objectAtIndex: i];
      SEL		action = [cell action];
      id		target;
      NSWindow		*keyWindow;
      NSWindow		*mainWindow;
      id		responder;
      id		delegate;
      id		validator = nil;
      BOOL		 wasEnabled = [cell isEnabled];
      BOOL		shouldBeEnabled;
  
      /* Update the submenu items if any */
      if ([cell hasSubmenu])
        [[cell target] update];
      
      /* If there is no action - there can be no validator for the cell */
      if (action)
        {
          /* If there is a target use that for validation (or nil). */
          if ((target = [cell target]))
            {
              if ([target respondsToSelector: action])
                {  
                  validator = target;
                }
            }
          else
            {
              validator = [theApp targetForAction: action];
            }
        }
      
      if (validator == nil)
        {
          shouldBeEnabled = NO;
        }
      else if ([validator respondsToSelector: @selector(validateMenuItem:)])
        {
          shouldBeEnabled = [validator validateMenuItem: cell];
        }
      else
        {
          shouldBeEnabled = YES;
        }
             
      if (shouldBeEnabled != wasEnabled)
        {
          [cell setEnabled: shouldBeEnabled];
// FIXME
//          [menuCells setNeedsDisplayInRect: [menuCells cellFrameAtRow: i]];
        }
    }
          
  if (menu_changed)
    [self sizeToFit];
         
  /* Reenable displaying of menus */
  [self setMenuChangedMessagesEnabled: YES];
}

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  unsigned      i;
  unsigned      count = [menu_items count];
  NSEventType   type = [theEvent type];
         
  if (type != NSKeyDown && type != NSKeyUp) 
    return NO;
             
  for (i = 0; i < count; i++)
    {
      id<NSMenuItem> cell = [menu_items objectAtIndex: i];
                                    
      if ([cell hasSubmenu])
        {
          if ([[cell target] performKeyEquivalent: theEvent])
            {
              /* The event has been handled by a cell in submenu */
              return YES;
            }
        }
      else
        {
          if ([[cell keyEquivalent] isEqual: 
            [theEvent charactersIgnoringModifiers]])
            {
              [menu_view lockFocus];
              [(id)cell performClick: self];
              [menu_view unlockFocus];
              return YES;           
            }
        }
    }
  return NO; 
}

- (void)  performActionForItem: (id <NSMenuItem>)cell
{
  NSNotificationCenter *nc;
  NSDictionary *d;

  if (![cell isEnabled])
    return;
  
  nc = [NSNotificationCenter defaultCenter];
  d = [NSDictionary dictionaryWithObject: cell forKey: @"MenuItem"];
  [nc postNotificationName: NSMenuWillSendActionNotification
                    object: self
                  userInfo: d];
  [[NSApplication sharedApplication] sendAction: [cell action]
                                             to: [cell target]
                                           from: cell];
  [nc postNotificationName: NSMenuDidSendActionNotification
                                    object: self
                                  userInfo: d];
}

- (void) setTitle: (NSString*)aTitle
{
  ASSIGN(menu_title, aTitle);
  [self sizeToFit];
}
  
- (NSString*) title
{
  return menu_title;
}

- (void) setMenuRepresentation: (id)menuRep
{
  ASSIGN(menu_rep, menuRep);
}

- (id) menuRepresentation
{
  return menu_rep;
}

- (void) setMenuChangedMessagesEnabled: (BOOL)flag
{ 
  menu_ChangedMessagesEnabled = flag;
}
 
- (BOOL) menuChangedMessagesEnabled
{
  return menu_ChangedMessagesEnabled;
}

- (void) sizeToFit
{ 
//  NSLog(@"- sizeToFit called in NSMenu\n");
//
//  [menu_view sizeToFit];
//  [menu_view setNeedsDisplay: YES];
//  menu_changed = NO;
}

- (void) helpRequested: (NSEvent *)event
{
  // Won't be implemented until we have NSHelp*
}

// NSCoding
- (id) initWithCoder: (NSCoder*)aDecoder
{
  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
}

//NSCopying
- (id) copyWithZone: (NSZone*)zone
{
  return self;
}
@end
