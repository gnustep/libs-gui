/*
   NSPopUpButtonCell.m

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

#include <gnustep/gui/config.h>  
#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/PSOperators.h>

@interface NSPopUpButtonCell (GNUstepPrivate)
- (void)_popUpItemAction:(id)sender;
@end

@implementation NSPopUpButtonCell
- (id)initTextCell:(NSString *)stringValue
{
  return [self initTextCell: stringValue pullsDown: NO];
}

- (id)initTextCell:(NSString *)stringValue
	 pullsDown:(BOOL)pullDown
{
  [super initTextCell: stringValue];

  _pbcFlags.pullsDown = pullDown;
  _pbcFlags.usesItemFromMenu = YES;
  _pbcFlags.altersStateOfSelectedItem = YES;

  if ([stringValue length] > 0)
    {
      id anItem;

      [self insertItemWithTitle:stringValue atIndex:0];

      anItem = [self itemAtIndex:0];
      [anItem setTarget: self];
      [anItem setAction: @selector(_popUpItemAction:)];
    }

  _menu = [NSMenu initWithTitle:@""];
  [_menu _setOwnedByPopUp: YES];

  return self;
}

- (void)setMenu:(NSMenu *)menu
{
  ASSIGN(_menu, menu);
}

- (NSMenu *)menu
{
  return _menu;
}

// Behavior settings
- (void)setPullsDown:(BOOL)flag
{
  _pbcFlags.pullsDown = flag;
}

- (BOOL)pullsDown
{
  return _pbcFlags.pullsDown;
}

- (void)setAutoenablesItems:(BOOL)flag
{
  [_menu setAutoenablesItems: flag];  
}

- (BOOL)autoenablesItems
{
  return [_menu autoenablesItems];
}

// The preferred edge is used for pull down menus and for popups under 
// severe screen position restrictions.  It indicates what edge of the
// cell the menu should pop out from.

- (void)setPreferredEdge:(NSRectEdge)edge
{
  _pbcFlags.preferredEdge = edge;
}

- (NSRectEdge)preferredEdge
{
  return _pbcFlags.preferredEdge;
}

// If YES (the default) the popup button will display an item from the
// menu.  This will be the selected item for a popup or the first item for
// a pull-down.  If this is NO, then the menu item set with -setMenuItem:
// is always displayed.  This can be useful for a popup button that is an
// icon button that pops up a menu full of textual items, for example.

- (void)setUsesItemFromMenu:(BOOL)flag
{
  _pbcFlags.usesItemFromMenu = flag;
}

- (BOOL)usesItemFromMenu
{
  return _pbcFlags.usesItemFromMenu;
}

// This only has an effect for popups (it is ignored for pulldowns).  
// If YES (the default) then the selected item gets its state set to
// NSOnState.  If NO the items in the menu are left alone.

- (void)setAltersStateOfSelectedItem:(BOOL)flag
{
  _pbcFlags.altersStateOfSelectedItem = flag;
}

- (BOOL)altersStateOfSelectedItem
{
  return _pbcFlags.altersStateOfSelectedItem;
}

// Adding and removing items
- (void)addItemWithTitle:(NSString *)title
{
  NSMenuItem *anItem = [NSMenuItem new];

  [anItem setTitle:title];
  [anItem setTarget: self];
  [anItem setAction: @selector(_popUpItemAction:)];

  [_menu insertItem: anItem atIndex: [_menu numberOfItems]];
}

- (void)addItemsWithTitles:(NSArray *)itemTitles
{
  int i;

  for (i=0; i<[itemTitles count]; i++)
    {
      [self addItemWithTitle: [itemTitles objectAtIndex:i]];
    }
}

- (void)insertItemWithTitle:(NSString *)title atIndex:(int)index
{
  NSMenuItem *anItem = [NSMenuItem new];

  [anItem setTitle:title];
  [anItem setTarget: self];
  [anItem setAction: @selector(_popUpItemAction:)];

  [[_menu itemArray] insertObject: anItem atIndex: index];
}

- (void)removeItemWithTitle:(NSString *)title
{
  [_menu removeItemWithTitle: title];
}

- (void)removeItemAtIndex:(int)index
{
  [[_menu itemArray] removeObjectAtIndex: index];
}

- (void)removeAllItems
{
  [_menu removeAllItems];
}

// Accessing the items
- (NSArray *)itemArray
{
  return [_menu itemArray];
}

- (int)numberOfItems
{
  return [_menu numberOfItems];
}

- (int)indexOfItem:(id <NSMenuItem>)item
{
  return [_menu indexOfItem: item];
}

- (int)indexOfItemWithTitle:(NSString *)title
{
  return [_menu indexOfItemWithTitle: title];
}

- (int)indexOfItemWithTag:(int)tag
{
  return [_menu indexOfItemWithTag: tag];
}

- (int)indexOfItemWithRepresentedObject:(id)obj
{
  return [_menu indexOfItemWithRepresentedObject: obj];
}

- (int)indexOfItemWithTarget:(id)target andAction:(SEL)actionSelector
{
  return [_menu indexOfItemWithTarget: target andAction: actionSelector];
}

- (id <NSMenuItem>)itemAtIndex:(int)index
{
  return [_menu itemAtIndex: index];
}

- (id <NSMenuItem>)itemWithTitle:(NSString *)title
{
  return [_menu itemWithTitle: title];
}

- (id <NSMenuItem>)lastItem
{
  return [_menu lastItem];
}

// Dealing with selection
- (void)selectItem:(id <NSMenuItem>)item
{
  if (!item)
    {
      if (_pbcFlags.altersStateOfSelectedItem)
        [[self itemAtIndex: _selectedIndex] setState: NSOffState];

      _selectedIndex = -1;
    }
  else
    {
      int aIndex = [self indexOfItem: item];

      if (_pbcFlags.altersStateOfSelectedItem)
        {
          [[self itemAtIndex: _selectedIndex] setState: NSOffState];
          [[self itemAtIndex: aIndex] setState: NSOnState];
        }

      _selectedIndex = aIndex;
    }
}

- (void)selectItemAtIndex:(int)index
{
  if (index == -1)
    {
      if (_pbcFlags.altersStateOfSelectedItem)
        [[self itemAtIndex: _selectedIndex] setState: NSOffState];

      _selectedIndex = -1;
    }
  else
    {
      if (_pbcFlags.altersStateOfSelectedItem)
        {
          [[self itemAtIndex: _selectedIndex] setState: NSOffState];
          [[self itemAtIndex: index] setState: NSOnState];
        }

      _selectedIndex = index;
    }
}

- (void)selectItemWithTitle:(NSString *)title
{

  if ([title length] < 1)
    {
      if (_pbcFlags.altersStateOfSelectedItem)
        [[self itemAtIndex: _selectedIndex] setState: NSOffState];

      _selectedIndex = -1;
    }
  else
    {
      int aIndex = [self indexOfItemWithTitle: title];

      if (_pbcFlags.altersStateOfSelectedItem)
        {
          [[self itemAtIndex: _selectedIndex] setState: NSOffState];
          [[self itemAtIndex: aIndex] setState: NSOnState];
        }

      _selectedIndex = aIndex;
    }
}

- (void)setTitle:(NSString *)aString
{
  if (_pbcFlags.pullsDown)
    {
    }
  else
    {
      int aIndex;

      if (aIndex = [self indexOfItemWithTitle: aString])
        {
          [self selectItemAtIndex: aIndex];
        }
      else
        {
          [self addItemWithTitle: aString];
          [self selectItemWithTitle: aString];
	}
    }
}

- (id <NSMenuItem>)selectedItem
{
  if (_selectedIndex != -1)
    return [self itemAtIndex: _selectedIndex];
  else
    return nil;
}

- (int)indexOfSelectedItem
{
  return _selectedIndex;
}

- (void)synchronizeTitleAndSelectedItem
{
  if (!_pbcFlags.usesItemFromMenu)
    return;

  // Add test for null menus.

  if (_pbcFlags.pullsDown)
    {
      [self selectItem: [self itemAtIndex: 0]];
    }
  else
    {
      if (_selectedIndex >= 0)
        [self selectItem: [self itemAtIndex: _selectedIndex]];
      else
        [self selectItem: [self itemAtIndex: 0]];        
    }
}

// Title conveniences
- (NSString *)itemTitleAtIndex:(int)index
{
  return [[self itemAtIndex: index] title];
}

- (NSArray *)itemTitles
{
  NSMutableArray *anArray = [NSMutableArray new];
  int i;

  for (i=0; i<[[_menu itemArray] count]; i++)
    {
      [anArray addObject: [[[_menu itemArray] objectAtIndex: i] title]];    
    }

  return (NSArray *)anArray;
}

- (NSString *)titleOfSelectedItem
{
  if (_selectedIndex >= 0)
    return [[self itemAtIndex: _selectedIndex] title];
  else
    return @"";
}

- (void)attachPopUpWithFrame:(NSRect)cellFrame
		      inView:(NSView *)controlView
{
  NSNotificationCenter *_aCenter = [NSNotificationCenter defaultCenter];
  NSNotification *_aNotif;
  NSRect scratchRect = cellFrame;
  NSRect winf;

  _aNotif = [NSNotification
		notificationWithName: NSPopUpButtonCellWillPopUpNotification
			      object: controlView
			    userInfo: nil];

  [_aCenter postNotification: _aNotif];

  _aNotif = [NSNotification
		notificationWithName: NSPopUpButtonCellWillPopUpNotification
			      object: self
			    userInfo: nil];

  [_aCenter postNotification: _aNotif];

  scratchRect.origin = [[controlView window] convertBaseToScreen: cellFrame.origin];

  [[_menu menuRepresentation] _setCellSize: cellFrame.size];
  [_menu sizeToFit];

  winf = [NSMenuWindow
           frameRectForContentRect: [[_menu menuRepresentation] frame]
                         styleMask: [[_menu window] styleMask]];
  /*
   * Set popup window frame origin so that the top-left corner of the
   * window lines up with the top-left corner of this button.
   */
  winf.origin = scratchRect.origin;
  winf.origin.y += scratchRect.size.height - winf.size.height;
 
  /*
   * Small hack to fix line up.
   */

  winf.origin.x += 1;
  winf.origin.y -= 1;
 
//NSLog(@"butf %@", NSStringFromRect(butf));
  
  if (!_pbcFlags.pullsDown)
    {
      winf.origin.y += (_selectedIndex * scratchRect.size.height);
    }

NSLog(@"winf %@", NSStringFromRect(winf));

  NSLog(@"here comes the popup.");
                         
  [[_menu window] setFrame: winf display: YES];
  [[_menu window] orderFrontRegardless];
}

- (void)dismissPopUp
{
  [[_menu window] orderOut: nil];
}

- (BOOL)trackMouse:(NSEvent *)theEvent
	    inRect:(NSRect)cellFrame
            ofView:(NSView *)controlView
      untilMouseUp:(BOOL)untilMouseUp
{
}

- (void)performClickWithFrame:(NSRect)frame
		       inView:(NSView *)controlView
{
  int indexToClick;

  [self attachPopUpWithFrame: frame
                      inView: controlView];
  indexToClick = [[_menu menuRepresentation] indexOfItemAtPoint: 
			[[_menu window] mouseLocationOutsideOfEventStream]];
  [[_menu menuRepresentation] mouseDown: [NSApp currentEvent]];

//  [[[_menu menuRepresentation] menuItemCellForItemAtIndex: indexToClick]
//  performClick: nil];
}

// Arrow position for bezel style and borderless popups.
- (NSPopUpArrowPosition)arrowPosition
{
  return _pbcFlags.arrowPosition;
}

- (void)setArrowPosition:(NSPopUpArrowPosition)position
{
  _pbcFlags.arrowPosition = position;
}

- (void) drawWithFrame: (NSRect)cellFrame
                inView: (NSView*)view  
{
  NSSize   size;
  NSPoint  position;
  NSImage *aImage;
                                  
  // Save last view drawn to
  [self setControlView: view];

  [view lockFocus];

  [super drawWithFrame: cellFrame inView: view];

  if (_pbcFlags.pullsDown)
    {
      aImage = [NSImage imageNamed:@"common_3DArrowDown"];
    }
  else
    {
      aImage = [NSImage imageNamed:@"common_Nibble"];
    }

  size = [aImage size];
  position.x = cellFrame.origin.x + cellFrame.size.width - size.width - 4;
  position.y = MAX(NSMidY(cellFrame) - (size.height/2.), 0.);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if ([control_view isFlipped])
    position.y += size.height;
  [aImage  compositeToPoint: position operation: NSCompositeCopy];

  [view unlockFocus]; 
}

- (void)_popUpItemAction:(id)sender
{
  [self selectItemWithTitle: [sender title]];
  NSLog(@"%@", [sender title]);
  [self dismissPopUp];
}
@end
