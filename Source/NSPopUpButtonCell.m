/** <title>NSPopUpButtonCell</title>

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
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSWindow.h>

/* The image to use in a specific popupbutton is
 * _pbc_image[_pbcFlags.pullsDown]; that is, _pbc_image[0] if it is a
 * popup menu, _pbc_image[1] if it is a pulls down list.  */
static NSImage *_pbc_image[2];

@implementation NSPopUpButtonCell
+ (void) initialize
{
  if (self == [NSPopUpButtonCell class])
    {
      [self setVersion: 1];
      ASSIGN(_pbc_image[0], [NSImage imageNamed: @"common_Nibble"]);
      ASSIGN(_pbc_image[1], [NSImage imageNamed: @"common_3DArrowDown"]);
    }
}

- (id) initTextCell: (NSString *)stringValue
{
  return [self initTextCell: stringValue pullsDown: NO];
}

- (id) initTextCell: (NSString *)stringValue
	  pullsDown: (BOOL)pullDown
{
  [super initTextCell: stringValue];

  _pbcFlags.pullsDown = pullDown;
  _pbcFlags.usesItemFromMenu = YES;
  _pbcFlags.altersStateOfSelectedItem = YES;

  if ([stringValue length] > 0)
    {
      [self addItemWithTitle: stringValue]; 
    }

  _menu = [[NSMenu alloc] initWithTitle: @""];
  [_menu _setOwnedByPopUp: self];

  return self;
}

- (void) setMenu: (NSMenu *)menu
{
  [_menu _setOwnedByPopUp: nil];    
  ASSIGN(_menu, menu);
  [_menu _setOwnedByPopUp: self];
}

- (NSMenu *) menu
{
  return _menu;
}

// Behavior settings
- (void) setPullsDown: (BOOL)flag
{
  _pbcFlags.pullsDown = flag;
}

- (BOOL) pullsDown
{
  return _pbcFlags.pullsDown;
}

- (void) setAutoenablesItems: (BOOL)flag
{
  [_menu setAutoenablesItems: flag];  
}

- (BOOL) autoenablesItems
{
  return [_menu autoenablesItems];
}

// The preferred edge is used for pull down menus and for popups under 
// severe screen position restrictions.  It indicates what edge of the
// cell the menu should pop out from.

- (void) setPreferredEdge: (NSRectEdge)edge
{
  _pbcFlags.preferredEdge = edge;
}

- (NSRectEdge) preferredEdge
{
  return _pbcFlags.preferredEdge;
}

// If YES (the default) the popup button will display an item from the
// menu.  This will be the selected item for a popup or the first item for
// a pull-down.  If this is NO, then the menu item set with -setMenuItem: 
// is always displayed.  This can be useful for a popup button that is an
// icon button that pops up a menu full of textual items, for example.

- (void) setUsesItemFromMenu: (BOOL)flag
{
  _pbcFlags.usesItemFromMenu = flag;
}

- (BOOL) usesItemFromMenu
{
  return _pbcFlags.usesItemFromMenu;
}

// This only has an effect for popups (it is ignored for pulldowns).  
// If YES (the default) then the selected item gets its state set to
// NSOnState.  If NO the items in the menu are left alone.

- (void) setAltersStateOfSelectedItem: (BOOL)flag
{
  _pbcFlags.altersStateOfSelectedItem = flag;
}

- (BOOL) altersStateOfSelectedItem
{
  return _pbcFlags.altersStateOfSelectedItem;
}

// Adding and removing items
- (void) addItemWithTitle: (NSString *)title
{
  [self insertItemWithTitle: title
	atIndex: [_menu numberOfItems]];
}

- (void) addItemsWithTitles: (NSArray *)itemTitles
{
  unsigned	c = [itemTitles count];
  unsigned	i;

  for (i = 0; i < c; i++)
    {
      [self addItemWithTitle: [itemTitles objectAtIndex: i]];
    }
}

- (void) insertItemWithTitle: (NSString *)title atIndex: (int)index
{
  NSMenuItem *anItem;
  int count = [_menu numberOfItems];

  if (index < 0)
    index = 0;
  if (index > count)
    index = count;

  anItem = [_menu insertItemWithTitle: title
		  action: NULL
		  keyEquivalent: @""
		  atIndex: index];
  /* Disable showing the On/Off/Mixed state.  We change the state of
     menu items when selected, according to the doc, but we don't want
     it to appear on the screen.  */
  [anItem setOnStateImage: nil];
  [anItem setMixedStateImage: nil];
}

- (void) removeItemWithTitle: (NSString *)title
{
  [_menu removeItemAtIndex: [_menu indexOfItemWithTitle: title]];
}

- (void) removeItemAtIndex: (int)index
{
  [_menu removeItemAtIndex: index];
}

- (void) removeAllItems
{
  while ([_menu numberOfItems] > 1)
    {
      [_menu removeItemAtIndex: 0];
    }
  [[_menu itemAtIndex: 0] setTitle: @""];
}

// Accessing the items
- (NSArray *) itemArray
{
  return [_menu itemArray];
}

- (int) numberOfItems
{
  return [_menu numberOfItems];
}

- (int) indexOfItem: (id <NSMenuItem>)item
{
  return [_menu indexOfItem: item];
}

- (int) indexOfItemWithTitle: (NSString *)title
{
  return [_menu indexOfItemWithTitle: title];
}

- (int) indexOfItemWithTag: (int)aTag
{
  return [_menu indexOfItemWithTag: aTag];
}

- (int) indexOfItemWithRepresentedObject: (id)obj
{
  return [_menu indexOfItemWithRepresentedObject: obj];
}

- (int) indexOfItemWithTarget: (id)aTarget andAction: (SEL)actionSelector
{
  return [_menu indexOfItemWithTarget: aTarget andAction: actionSelector];
}

- (id <NSMenuItem>) itemAtIndex: (int)index
{
  return [_menu itemAtIndex: index];
}

- (id <NSMenuItem>) itemWithTitle: (NSString *)title
{
  return [_menu itemWithTitle: title];
}

- (id <NSMenuItem>) lastItem
{
  int	end = [_menu numberOfItems] - 1;

  if (end < 0)
    return nil;
  return [_menu itemAtIndex: end];
}

// Dealing with selection
- (void) selectItem: (id <NSMenuItem>)item
{
  if (_selectedItem == item)
    return;

  if (_selectedItem != nil)
    {
      if (_pbcFlags.altersStateOfSelectedItem)
	{
	  [_selectedItem setState: NSOffState];
	}
      if ([_selectedItem image] == _pbc_image[_pbcFlags.pullsDown])
  	[_selectedItem setImage: nil];
    }

  _selectedItem = item;

  if (_selectedItem != nil)
    {
      if (_pbcFlags.altersStateOfSelectedItem)
        {
	  [_selectedItem setState: NSOnState];
        }
      if ([_selectedItem image] == nil)
	[_selectedItem setImage: _pbc_image[_pbcFlags.pullsDown]];
    }

  /* Set the item in the menu */
  [[_menu menuRepresentation] setHighlightedItemIndex: 
		   [_menu indexOfItem: _selectedItem]];
}

- (void) selectItemAtIndex: (int)index
{
  NSMenuItem	*anItem;

  if (index < 0) 
    anItem = nil;
  else
    anItem = [self itemAtIndex: index];

  [self selectItem: anItem];
}

- (void) selectItemWithTitle: (NSString *)title
{
  NSMenuItem	*anItem = [self itemWithTitle: title];

  [self selectItem: anItem];
}

- (void) setTitle: (NSString *)aString
{
  NSMenuItem	*anItem;

  if (_pbcFlags.pullsDown)
    {
      if ([_menu numberOfItems] == 0)
	{
	  anItem = nil;
	}
      else
	{
	  anItem = [_menu itemAtIndex: 0];
	}
    }
  else
    {
      anItem = [_menu itemWithTitle: aString];
      if (anItem == nil)
	{
          [self addItemWithTitle: aString];
	  anItem = [_menu itemWithTitle: aString];
	}
    }
  [self selectItem: anItem];
}

- (NSString *)stringValue
{
  return [self titleOfSelectedItem];
}

- (id <NSMenuItem>) selectedItem
{
  return _selectedItem;
}

- (int) indexOfSelectedItem
{
  return [_menu indexOfItem: _selectedItem];
}

- (void) synchronizeTitleAndSelectedItem
{
  if (!_pbcFlags.usesItemFromMenu)
    return;

  if ([_menu numberOfItems] == 0)
    {
      _selectedItem = nil;
    }
  else if (_pbcFlags.pullsDown)
    {
      [self selectItem: [self itemAtIndex: 0]];
    }
  else
    {
      int index = [[_menu menuRepresentation] highlightedItemIndex];
      
      if (index < 0)
	index = [self indexOfSelectedItem];
      if (index < 0)
	index = 0;

      [self selectItemAtIndex: index];
    }
}

// Title conveniences
- (NSString *) itemTitleAtIndex: (int)index
{
  return [[self itemAtIndex: index] title];
}

- (NSArray *) itemTitles
{
  unsigned		count = [_menu numberOfItems];
  id			items[count];
  unsigned		i;

  [[_menu itemArray] getObjects: items];
  for (i = 0; i < count; i++)
    {
      items[i] = [items[i] title];
    }

  return [NSArray arrayWithObjects: items count: count];
}

- (NSString *) titleOfSelectedItem
{
  if (_selectedItem != nil)
    return [_selectedItem title];
  else
    return @"";
}

- (void) attachPopUpWithFrame: (NSRect)cellFrame
		       inView: (NSView *)controlView
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSWindow              *cvWin = [controlView window];
  NSMenuView            *mr = [_menu menuRepresentation];
  int                   selectedItem;

  [nc postNotificationName: NSPopUpButtonCellWillPopUpNotification
		    object: self];

  [nc postNotificationName: NSPopUpButtonWillPopUpNotification
		    object: controlView];

  // Convert to Screen Coordinates
  cellFrame = [controlView convertRect: cellFrame toView: nil];
  cellFrame.origin = [cvWin convertBaseToScreen: cellFrame.origin];

  if (_pbcFlags.pullsDown)
    selectedItem = -1;
  else 
    selectedItem = [self indexOfSelectedItem];

  // Ask the MenuView to attach the menu to this rect
  [mr setWindowFrameForAttachingToRect: cellFrame
      onScreen: [cvWin screen]
      preferredEdge: _pbcFlags.preferredEdge
      popUpSelectedItem: selectedItem];
  
  // Last, display the window
  [[mr window] orderFrontRegardless];
}

- (void) dismissPopUp
{
  [_menu close];
}

- (BOOL) trackMouse: (NSEvent *)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView *)controlView
       untilMouseUp: (BOOL)untilMouseUp
{
  return NO;
}

- (void) performClickWithFrame: (NSRect)frame
			inView: (NSView *)controlView
{
  // TODO

  // This method is called to simulate programmatically a click
  // [as NSCell's performClick:]
  // This method is not executed upon mouse down; rather, it should
  // simulate what would happen upon mouse down.  It should not start
  // any real mouse tracking.
}

// Arrow position for bezel style and borderless popups.
- (NSPopUpArrowPosition) arrowPosition
{
  return _pbcFlags.arrowPosition;
}

/*
 * Does nothing for now.
 */
- (void) setArrowPosition: (NSPopUpArrowPosition)position
{
  _pbcFlags.arrowPosition = position;
}

/*
 * What would be nice and natural is to make this drawing using the same code 
 * that is used to draw cells in the menu.
 * This looks like a mess to do in this framework.
 *
 * Well, here is an attempt to make this work.
 */
- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSMenuItemCell    *aCell;

  // Save last view drawn to
  if (_control_view != controlView)
    _control_view = controlView;

  // Transparent buttons never draw 
  if (_buttoncell_is_transparent)
    return;

  // Do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  // Do nothing if the window is deferred
  if ([[controlView window] gState] == 0)
    return;

  /* Get the NSMenuItemCell of the selected item */
  aCell = [[_menu menuRepresentation] 
           menuItemCellForItemAtIndex: [self indexOfSelectedItem]];

  /* Turn off highlighting so the NSPopUpButton looks right */
  [aCell setHighlighted: NO];
  
  [aCell drawWithFrame: cellFrame inView: controlView];

  /* Draw our own interior so we pick up our dotted frame */
  [self drawInteriorWithFrame: cellFrame inView: controlView];

  /* Rehighlight item for consistency */
  [aCell setHighlighted: YES];
}

/* FIXME: This needs to be removed in favor of allowing the cell to draw 
 * our NSDottedRect.
 */
- (void) drawInteriorWithFrame: (NSRect)cellFrame
			inView: (NSView*)view
{
  // Transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  cellFrame = [self drawingRectForBounds: cellFrame];

  if (_cell.shows_first_responder
      && [[view window] firstResponder] == view)
    NSDottedFrameRect(cellFrame);
}

/* FIXME: this method needs to be rewritten to be something like 
 * NSMenuView's sizeToFit. That way if you call [NSPopUpButton sizeToFit]; 
 * you will get the absolutely correct cellSize.
 */
- (NSSize) cellSize
{
  NSSize s;
  NSSize imageSize;
  NSSize titleSize;
  int i, count;
  NSString *title;

  count = [_menu numberOfItems];

  if (count == 0)
    return NSZeroSize;
  
  imageSize = [_pbc_image[_pbcFlags.pullsDown] size];
  s = NSMakeSize(0, imageSize.height);
  
  for (i = 0; i < count; i++)
    {
      title = [[_menu itemAtIndex: i] title];
      titleSize = [self _sizeText: title];

      if (titleSize.width > s.width)
	s.width = titleSize.width;
      if (titleSize.height > s.height)
	s.height = titleSize.height;
    }

  s.width += imageSize.width; 
  s.width += 5; /* Left border to text (border included) */
  s.width += 3; /* Text to Image */
  s.width += 4; /* Right border to image (border included) */

  /* (vertical) border: */
  s.height += 2 * (_sizeForBorderType (NSBezelBorder).height);

  /* Spacing between border and inside: */
  s.height += 2 * 1;
  s.width  += 2 * 3;
  
  return s;
}

- (void) setAction: (SEL)aSelector
{
  [super setAction: aSelector];
  [_menu update];
}

- (void) setTarget: (id)anObject
{
  [super setTarget: anObject];
  [_menu update];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  int flag;
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: _menu];
  [aCoder encodeConditionalObject: _selectedItem];
  flag = _pbcFlags.pullsDown;
  [aCoder encodeValueOfObjCType: @encode(int) at: &flag];
  flag = _pbcFlags.preferredEdge;
  [aCoder encodeValueOfObjCType: @encode(int) at: &flag];
  flag = _pbcFlags.usesItemFromMenu;
  [aCoder encodeValueOfObjCType: @encode(int) at: &flag];
  flag = _pbcFlags.altersStateOfSelectedItem;
  [aCoder encodeValueOfObjCType: @encode(int) at: &flag];
  flag = _pbcFlags.arrowPosition;
  [aCoder encodeValueOfObjCType: @encode(int) at: &flag];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  int flag;
  id<NSMenuItem> selectedItem;

  self = [super initWithCoder: aDecoder];
  _menu = [aDecoder decodeObject];
  selectedItem = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &flag];
  _pbcFlags.pullsDown = flag;
  [aDecoder decodeValueOfObjCType: @encode(int) at: &flag];
  _pbcFlags.preferredEdge = flag;
  [aDecoder decodeValueOfObjCType: @encode(int) at: &flag];
  _pbcFlags.usesItemFromMenu = flag;
  [aDecoder decodeValueOfObjCType: @encode(int) at: &flag];
  _pbcFlags.altersStateOfSelectedItem = flag;
  [aDecoder decodeValueOfObjCType: @encode(int) at: &flag];
  _pbcFlags.arrowPosition = flag;

  [_menu _setOwnedByPopUp: self];
  [self selectItem: selectedItem];
  return self;
}

@end
