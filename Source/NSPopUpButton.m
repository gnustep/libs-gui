/** <title>NSPopUpButton</title>

   <abstract>Popup list class</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
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

#include <Foundation/Foundation.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenuView.h>

/*
 * class variables
 */
Class _nspopupbuttonCellClass = 0;

/*
 * NSPopUpButton implementation
 */

@implementation NSPopUpButton

/*
 * Class methods
 */
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

/*
 * Initializing an NSPopUpButton 
 */
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
  self = [super initWithFrame: frameRect];
  [self setPullsDown: flag];

  return self;
}


/*
In NSView, -menuForEvent: returns [self menu] as the context menu of the
view. Since our -menu returns the menu for our pop-up, we need to override
this to return nil to indicate that we have no context menu.
*/
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
  return nil;
}


- (void) setMenu: (NSMenu*)menu
{
  [_cell setMenu: menu];
}

- (NSMenu*) menu
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

- (void) addItemsWithTitles: (NSArray*)itemTitles
{
  [_cell addItemsWithTitles: itemTitles];

  [self synchronizeTitleAndSelectedItem];
}

- (void) insertItemWithTitle: (NSString*)title
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

- (void) removeItemWithTitle: (NSString*)title
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

- (NSString*) titleOfSelectedItem
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
  [self synchronizeTitleAndSelectedItem];
}

- (void) selectItemAtIndex: (int)index
{
  [_cell selectItemAtIndex: index];
  [self synchronizeTitleAndSelectedItem];
}

- (void) selectItemWithTitle: (NSString*)title
{
  [_cell selectItemWithTitle: title];
  [self synchronizeTitleAndSelectedItem];
}

- (int) numberOfItems
{
  return [_cell numberOfItems];
}

- (NSArray*) itemArray 
{
  return [_cell itemArray];
}

- (id <NSMenuItem>) itemAtIndex: (int)index
{
  return [_cell itemAtIndex: index];
}

- (NSString*) itemTitleAtIndex: (int)index
{
  return [_cell itemTitleAtIndex: index];
}

- (NSArray*) itemTitles
{
  return [_cell itemTitles];
}

- (id <NSMenuItem>) itemWithTitle: (NSString*)title
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

- (int) indexOfItemWithTitle: (NSString*)title
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

- (void) setTitle: (NSString*)aString
{
  [_cell setTitle: aString];
}

- (void) synchronizeTitleAndSelectedItem
{
  [_cell synchronizeTitleAndSelectedItem];
  [self setNeedsDisplay: YES];
}

- (BOOL) resignFirstResponder
{
  [_cell dismissPopUp];

  return [super resignFirstResponder];
}

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  NSMenu     *m = [self menu];
  NSMenuItem *oldSelectedItem = [_cell selectedItem];

  if (m != nil)
    {
      if ([m performKeyEquivalent: theEvent])
	{
	  // pullsDown does not change selected item
	  if ([_cell pullsDown])
	    {
	      [self selectItem: oldSelectedItem];
	    }
	  else
	    {
	      /* If the key equivalent was performed, redisplay ourselves
	       * to account for potential changes in the selected item.
	       */
	      [self setNeedsDisplay: YES];
	    }
	  return YES;
	}
    }
  return NO;
}

- (void) mouseDown: (NSEvent*)theEvent
{ 
  NSMenuView *mr = [[_cell menu] menuRepresentation];
  NSWindow   *menuWindow = [mr window];
  NSEvent    *e;
  NSPoint    p;
  int        lastSelectedItem = [_cell indexOfSelectedItem];
  int        highlightedItemIndex;

  if ([self isEnabled] == NO)
    return;

  if ([[_cell menu] numberOfItems] == 0)
    {
      NSBeep ();
      return;
    }

  // Attach the popUp
  [_cell attachPopUpWithFrame: _bounds
	               inView: self];
  
  p = [_window convertBaseToScreen: [theEvent locationInWindow]];
  p = [menuWindow convertScreenToBase: p];
  
  // Process events; we start menu events processing by converting 
  // this event to the menu window, and sending it there. 
  e = [NSEvent mouseEventWithType: [theEvent type]
	       location: p
	       modifierFlags: [theEvent modifierFlags]
	       timestamp: [theEvent timestamp]
	       windowNumber: [menuWindow windowNumber]
	       context: [theEvent context]
	       eventNumber: [theEvent eventNumber]
	       clickCount: [theEvent clickCount] 
	       pressure: [theEvent pressure]];
  [NSApp sendEvent: e];

  // Get highlighted item index from _cell because NSMenuView:
  // - tells to NSPopUpButtonCell about current selected item index;
  // - sets own selected item index to -1;
  //
  // So, at this point [mr highlightedItemIndex] always = -1
  highlightedItemIndex = [_cell indexOfSelectedItem];

  // Selection remains unchanged if selected item is disabled
  // or mouse left menu (highlightedItemIndex == -1).
  if ( highlightedItemIndex < 0
       || highlightedItemIndex == lastSelectedItem
       || [[self itemAtIndex: highlightedItemIndex] isEnabled] == NO)
    {
      [mr setHighlightedItemIndex: lastSelectedItem];
    }
  else
    {
      [mr setHighlightedItemIndex: highlightedItemIndex];
    }

  // Dismiss the popUp
  [_cell dismissPopUp];

  // Update our selected item
  [self synchronizeTitleAndSelectedItem];  
}

/* Private method which covers an obscure case where the user uses the
   keyboard to open a popup, but subsequently uses the mouse to select
   an item. We'll never know this was done (and thus cannot dismiss
   the popUp) without getting this notification */
- (void) _handleNotification: (NSNotification*)aNotification
{
  NSString      *name = [aNotification name];
  if ([name isEqual: NSMenuDidSendActionNotification] == YES)
    {
      [_cell dismissPopUp];
      [self synchronizeTitleAndSelectedItem];
    }
}

- (void) keyDown: (NSEvent*)theEvent
{
  if ([self isEnabled])
    {
      NSString *characters = [theEvent characters];
      unichar character = 0;

      if ([characters length] > 0)
	{
	  character = [characters characterAtIndex: 0];
	}

      switch (character)
	{
	case NSNewlineCharacter:
	case NSEnterCharacter: 
	case NSCarriageReturnCharacter:
	case ' ':
	  {
	    int selectedIndex;
	    NSMenuView *menuView;
	    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	    // Beep, as on OS, and then return.
	    if ([[_cell menu] numberOfItems] == 0)
	      {
		NSBeep();
		return;
	      }

	    menuView = [[_cell menu] menuRepresentation];
	    if ([[menuView window] isVisible] == NO)
	      {

		// Attach the popUp
		[_cell attachPopUpWithFrame: _bounds
		       inView: self];


		selectedIndex = [self indexOfSelectedItem];
		if (selectedIndex > -1)
		  [menuView setHighlightedItemIndex: selectedIndex];

		/* This covers an obscure case where the user subsequently
		   uses the mouse to select an item. We'll never know
		   this was done (and thus cannot dismiss the popUp) without
		   getting this notification */
		[nc addObserver: self
		       selector: @selector(_handleNotification:)
		           name: NSMenuDidSendActionNotification
		         object: [_cell menu]];

	      }
	    else
	      {
		[nc removeObserver: self
		              name: NSMenuDidSendActionNotification
		            object: [_cell menu]];
		selectedIndex = [menuView highlightedItemIndex];
		[[_cell menu] performActionForItemAtIndex: selectedIndex];

		// Dismiss the popUp
		[_cell dismissPopUp];

		// Update our selected item
		[self synchronizeTitleAndSelectedItem];
	      }
	  }
	  return;
	case '\e':
	  [_cell dismissPopUp];
	  return;
	case NSUpArrowFunctionKey:
	  {
	    NSMenuView *menuView;
	    int selectedIndex, numberOfItems;

	    menuView = [[_cell menu] menuRepresentation];
	    selectedIndex = [menuView highlightedItemIndex];
	    numberOfItems = [self numberOfItems];

	    switch (selectedIndex)
	      {
	      case -1:
		selectedIndex = numberOfItems - 1;
		break;
	      case 0:
		return;
	      default:
		selectedIndex--;
		break;
	      }

	    [menuView setHighlightedItemIndex: selectedIndex];
	  }
	  return;
	case NSDownArrowFunctionKey:
	  {
	    NSMenuView *menuView;
	    int selectedIndex, numberOfItems;

	    menuView = [[_cell menu] menuRepresentation];
	    selectedIndex = [menuView highlightedItemIndex];
	    numberOfItems = [self numberOfItems];

	    if (selectedIndex < numberOfItems-1)
	      [menuView setHighlightedItemIndex: selectedIndex + 1];
	  }
	  return;
	}
    }
  
  [super keyDown: theEvent];
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  return [super initWithCoder: aDecoder];
}

@end
