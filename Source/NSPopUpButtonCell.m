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
#include <AppKit/NSMenu.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/PSOperators.h>

@interface NSMenuItemCell (GNUStepPrivate)
- (void) setBelongsToPopUpButton: (BOOL)flag;
@end
@implementation NSMenuItemCell (GNUStepPrivate)
- (void) setBelongsToPopUpButton: (BOOL)flag
{
  _mcell_belongs_to_popupbutton = flag;
}
@end

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
  [_menu _setOwnedByPopUp: YES];

  return self;
}

- (void) setMenu: (NSMenu *)menu
{
  ASSIGN(_menu, menu);
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
  NSMenuItem *anItem = [NSMenuItem new];
  NSMenuItemCell *aCell;
  int count = [_menu numberOfItems];

  if (index < 0)
    index = 0;
  if (index > count)
    index = count;

  [anItem setTitle: title];
  [anItem setTarget: nil];
  [anItem setAction: NULL];

  [_menu insertItem: anItem atIndex: index];

  RELEASE(anItem);

  aCell = [[_menu menuRepresentation] menuItemCellForItemAtIndex: index];
  [aCell setBelongsToPopUpButton: YES];
  [aCell setImagePosition: NSImageRight];
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
  while ([_menu numberOfItems] > 0)
    {
      [_menu removeItemAtIndex: 0];
    }
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
  if (!item)
    {
      if (_pbcFlags.altersStateOfSelectedItem)
	{
	  [_selectedItem setState: NSOffState];
	  [_selectedItem setChangesState: NO];
	}
      [_selectedItem setImage: nil];
      _selectedItem = nil;
    }
  else
    {
      if (_pbcFlags.altersStateOfSelectedItem)
        {
          [_selectedItem setState: NSOffState];
	  [_selectedItem setChangesState: NO];
      	}
      [_selectedItem setImage: nil];

      _selectedItem = item;

      if (_pbcFlags.altersStateOfSelectedItem)
        {
	  [_selectedItem setState: NSOnState];
	  [_selectedItem setChangesState: NO];
        }
      [_selectedItem setImage: _pbc_image[_pbcFlags.pullsDown]];
    }
  /* Set the item in the menu */
  [(NSMenuView *)[_menu menuRepresentation] setHighlightedItemIndex: 
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
  int                   items;

  [nc postNotificationName: NSPopUpButtonCellWillPopUpNotification
		    object: self];

  [nc postNotificationName: NSPopUpButtonCellWillPopUpNotification
		    object: controlView];

  [mr _setCellSize: cellFrame.size];
  [_menu sizeToFit];

  /*
   * Compute the frame (NB: the temporary frame to be passed 
   * to mr as per spec, not yet the definitive frame where 
   * the menu is going to appear)
   */
  items = [_menu numberOfItems];
  if (items > 1)
    {
      float f;
      
      f = cellFrame.size.height * (items - 1);
      cellFrame.size.height += f;
      cellFrame.origin.y -= f;
    }

  // Convert to Screen Coordinates

  /* Convert to content view */
  cellFrame = [controlView convertRect: cellFrame 
				toView: nil];

  cellFrame.origin = [cvWin convertBaseToScreen: cellFrame.origin];

  // Ask the MenuView to attach the menu to this rect
  if (_pbcFlags.pullsDown)
    {
      [mr setWindowFrameForAttachingToRect: cellFrame
	  onScreen: [cvWin screen]
	  preferredEdge: _pbcFlags.preferredEdge
	  popUpSelectedItem: -1];
    }
  else 
    {
      [mr setWindowFrameForAttachingToRect: cellFrame
	  onScreen: [cvWin screen]
	  preferredEdge: _pbcFlags.preferredEdge
	  popUpSelectedItem: [self indexOfSelectedItem]];
    }
  
  // Last, display the window
  [[_menu window] orderFrontRegardless];
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
 */
- (void) drawInteriorWithFrame: (NSRect)cellFrame
			inView: (NSView*)view
{
  NSSize   size;
  NSPoint  position;
  NSImage *anImage;
  
  // Save last view drawn to
  if (_control_view != view)
    _control_view = view;

  [view lockFocus];

  //  [super drawWithFrame: cellFrame inView: view];

  cellFrame = [self drawingRectForBounds: cellFrame];
  if (_cell.is_bordered || _cell.is_bezeled)
    {
      cellFrame.origin.x += 3;
      cellFrame.size.width -= 6;
      cellFrame.origin.y += 1;
      cellFrame.size.height -= 2;
    }
  // Skip 5 points from left side
  //  cellFrame.origin.x += 5;
  //  cellFrame.size.width -= 5;

  cellFrame.origin.x += 2;
  cellFrame.size.width -= 2;

  [self _drawText: [self titleOfSelectedItem] inFrame: cellFrame];

  cellFrame.origin.x -= 4;
  cellFrame.size.width += 4;
  
  anImage = _pbc_image[_pbcFlags.pullsDown];

  /* NB: If we are drawing here, then the control can't be selected */
  [anImage setBackgroundColor: [NSColor controlBackgroundColor]];

  size = [anImage size];
  position.x = cellFrame.origin.x + cellFrame.size.width - size.width;
  position.y = MAX(NSMidY(cellFrame) - (size.height/2.), 0.);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if ([view isFlipped])
    position.y += size.height;
  [anImage  compositeToPoint: position operation: NSCompositeCopy];

  if (_cell.is_bordered || _cell.is_bezeled)
    {
      cellFrame.origin.x -= 1;
      cellFrame.size.width += 2;
    }

  cellFrame.origin.y -= 1;
  cellFrame.size.height += 2;
  cellFrame.size.width += 2;
  if (_cell.shows_first_responder
      && [[view window] firstResponder] == view)
    NSDottedFrameRect(cellFrame);

  [view unlockFocus]; 
}

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
@end
