/* 
   NSMenu.m

   The menu class

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

#include <gnustep/gui/NSMenu.h>
#include <gnustep/gui/NSMenuPrivate.h>
#include <Foundation/NSLock.h>
#include <gnustep/base/NSCoder.h>

NSZone *gnustep_gui_nsmenu_zone = NULL;

@implementation NSMenu

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSMenu class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Controlling Allocation Zones
//
+ (NSZone *)menuZone
{
  return gnustep_gui_nsmenu_zone;
}

+ (void)setMenuZone:(NSZone *)zone
{
  gnustep_gui_nsmenu_zone = zone;
}

//
// Instance methods
//
//
// Initializing a New NSMenu 
//
- init
{
  return [self initWithTitle:@""];
}

// Default initializer
- (id)initWithTitle:(NSString *)aTitle
{
  // Init our superclass but skip any of its backend implementation
  [super cleanInit];

  window_title = aTitle;
  menu_items = [NSMutableArray array];
  super_menu = nil;
  autoenables_items = NO;
  menu_matrix = nil;
  is_torn_off = NO;

  return self;
}

//
// Setting Up the Menu Commands 
//
- (id)addItemWithTitle:(NSString *)aString
		action:(SEL)aSelector
	 keyEquivalent:(NSString *)charCode
{
  NSMenuCell *m;
  unsigned int mi;

  m = [[NSMenuCell alloc] initTextCell:aString];
  [m setAction:aSelector];
  [menu_items addObject:m];

  return m;
}

- (id)insertItemWithTitle:(NSString *)aString
		   action:(SEL)aSelector
	    keyEquivalent:(NSString *)charCode
		  atIndex:(unsigned int)index
{
  NSMenuCell *m;
  unsigned int mi;

  m = [[NSMenuCell alloc] initTextCell:aString];
  [m setAction:aSelector];
  [menu_items insertObject:m atIndex:index];

  return m;
}

- (NSArray *)itemArray
{
  return menu_items;
}

- (NSMatrix *)itemMatrix
{
  return menu_matrix;
}

- (void)setItemMatrix:(NSMatrix *)aMatrix
{
  menu_matrix = aMatrix;
}

//
// Finding Menu Items 
//
- (id)cellWithTag:(int)aTag
{
  int i, j;
  NSMenuCell *m, *found;

  // Recursively find the menu cell with the tag
  found = nil;
  j = [menu_items count];
  for (i = 0;i < j; ++i)
    {
      m = [menu_items objectAtIndex:i];
      if ([m tag] == aTag) return m;
      if ([m hasSubmenu])
	found = [[m submenu] cellWithTag:aTag];
      if (found) return found;
    }
  return found;
}

//
// Building Submenus 
//
- (NSMenuCell *)setSubmenu:(NSMenu *)aMenu
		   forItem:(NSMenuCell *)aCell
{
  int i, j;
  NSMenuCell *m;

  j = [menu_items count];
  for (i = 0;i < j; ++i)
    {
      m = [menu_items objectAtIndex:i];
      if (m == aCell)
	{
	  // Set the menucell's submenu
	  [m setSubmenu:aMenu];

	  // Tell the submenu we are its supermenu
	  [aMenu setSupermenu: self];

	  // Return the menucell
	  return m;
	}
    }
  return nil;
}

- (void)submenuAction:(id)sender
{}

//
// Managing NSMenu Windows 
//
- (NSMenu *)attachedMenu
{
  return self;
}

- (BOOL)isAttached
{
  return !is_torn_off;
}

- (BOOL)isTornOff
{
  return is_torn_off;
}

- (NSPoint)locationForSubmenu:(NSMenu *)aSubmenu
{
  return NSZeroPoint;
}

- (void)sizeToFit
{}

- (NSMenu *)supermenu
{
  return super_menu;
}

//
// Displaying the Menu 
//
- (BOOL)autoenablesItems
{
  return autoenables_items;
}

- (void)setAutoenablesItems:(BOOL)flag
{
  autoenables_items = flag;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: menu_items];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  menu_items = [aDecoder decodeObject];

  return self;
}

@end

@implementation NSMenu (GNUstepPrivate)

- (void)setSupermenu:(NSMenu *)obj
{
  super_menu = obj;
}

@end
