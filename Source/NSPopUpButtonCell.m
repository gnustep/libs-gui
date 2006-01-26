/** <title>NSPopUpButtonCell</title>

   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: Jul 2003
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "config.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSMenuView.h"
#include "AppKit/NSPopUpButton.h"
#include "AppKit/NSPopUpButtonCell.h"
#include "AppKit/NSWindow.h"

/* The image to use in a specific popupbutton is
 * _pbc_image[_pbcFlags.pullsDown]; that is, _pbc_image[0] if it is a
 * popup menu, _pbc_image[1] if it is a pulls down list.  */
static NSImage *_pbc_image[2];

@implementation NSPopUpButtonCell
+ (void) initialize
{
  if (self == [NSPopUpButtonCell class])
    {
      [self setVersion: 2];
      ASSIGN(_pbc_image[0], [NSImage imageNamed: @"common_Nibble"]);
      ASSIGN(_pbc_image[1], [NSImage imageNamed: @"common_3DArrowDown"]);
    }
}

- (id) init
{
  return [self initTextCell: @"" pullsDown: NO];
}

- (id) initTextCell: (NSString *)stringValue
{
  return [self initTextCell: stringValue pullsDown: NO];
}

- (id) initTextCell: (NSString *)stringValue
	  pullsDown: (BOOL)pullDown
{
  NSMenu *menu;

  [super initTextCell: stringValue];

  menu = [[NSMenu alloc] initWithTitle: @""];
  [self setMenu: menu];
  RELEASE(menu);

  [self setPullsDown: pullDown];
  _pbcFlags.usesItemFromMenu = YES;

  if ([stringValue length] > 0)
    {
      [self addItemWithTitle: stringValue]; 
    }

  return self;
}

- (void) dealloc
{
  /* 
   * The popup must be closed here, just in case the cell goes away 
   * while the popup is still displayed. In that case the notification
   * center would still send notifications to the deallocated cell.
   */
  if ([[_menu window] isVisible])
    {
      [self dismissPopUp];
    }
  /* 
   * We don't use methods here to clean up the selected item, the menu
   * item and the menu as these methods internally update the menu,
   * which tries to access the target of the menu item (or of this cell). 
   * When the popup is relases this target may already have been freed, 
   * so the local reference to it is invalid and will result in a 
   * segmentation fault. 
   */
  _selectedItem = nil;
  [super dealloc];
}

- (void) setMenu: (NSMenu *)menu
{
  if (_menu == menu)
    {
      return;
    }

  if (_menu != nil)
    {
      [_menu _setOwnedByPopUp: nil];
    }
  ASSIGN(_menu, menu);
  if (_menu != nil)
    {
      [_menu _setOwnedByPopUp: self];
      /* We need to set the menu view so we trigger the special case 
       * popupbutton code in super class NSMenuItemCell
       */
      [self setMenuView: [_menu menuRepresentation]];
    }
  else 
    {
      [self setMenuView: nil];
    }
}

- (NSMenu *) menu
{
  return _menu;
}

// Behaviour settings
- (void) setPullsDown: (BOOL)flag
{
  NSMenuItem *item = _menuItem;

  [self setMenuItem: nil];
  _pbcFlags.pullsDown = flag;
  [self setAltersStateOfSelectedItem: !flag];

  if (!flag)
    {
      // pop up
      [self setArrowPosition: NSPopUpArrowAtCenter];
      [self setPreferredEdge: NSMinYEdge];
    }
  else
    {
      // pull down
      [self setArrowPosition: NSPopUpArrowAtBottom];
      [self setPreferredEdge: NSMaxYEdge];
    }

  [self setMenuItem: item];
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

// If YES (the default for popups) then the selected item gets its state
// set to NSOnState. If NO the items in the menu are left alone.
- (void) setAltersStateOfSelectedItem: (BOOL)flag
{
  id <NSMenuItem> selectedItem = [self selectedItem];

  if (flag)
    {
      [selectedItem setState: NSOffState];
    }
  else
    {
      [selectedItem setState: NSOnState];
    }

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
  id <NSMenuItem> anItem;
  int i, count;
  
  i = [self indexOfItemWithTitle: title];

  if (-1 != i)
    {
      [self removeItemAtIndex: i];
    }

  count = [_menu numberOfItems];

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

  // FIXME: The documentation is unclear what to set here.
  //[anItem setAction: [self action]];
  //[anItem setTarget: [self target]];
}

- (void) removeItemWithTitle: (NSString *)title
{
  [self removeItemAtIndex: [self indexOfItemWithTitle: title]];
}

- (void) removeItemAtIndex: (int)index
{
  if (index == [self indexOfSelectedItem])
    {
      [self selectItem: nil];
    }

  [_menu removeItemAtIndex: index];
}

- (void) removeAllItems
{
  [self selectItem: nil];

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
  if ((index >= 0) && (index < [_menu numberOfItems]))
    {
      return [_menu itemAtIndex: index];
    }
  else 
    {
      return nil;
    }
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

- (id <NSCopying>) objectValue
{
  return [NSNumber numberWithInt: [self indexOfSelectedItem]];
}

- (void) setObjectValue: (id)object
{
  if ([object respondsToSelector: @selector(intValue)])
    {
      int i = [object intValue];
	
      [self selectItemAtIndex: i];
    }
}

- (void) setImage: (NSImage *)anImage
{
  // Do nothing as the image is determined by the current item
}

- (void) setMenuItem: (NSMenuItem *)item
{
  NSImage *image;

  if (_menuItem == item)
    return;

  if (_pbcFlags.arrowPosition == NSPopUpArrowAtBottom)
    {
      image = _pbc_image[1];
    }
  else if (_pbcFlags.arrowPosition == NSPopUpArrowAtCenter)
    {
      image = _pbc_image[0];
    }
  else
    {
      // No image for NSPopUpNoArrow
      image = nil;
    }

  if ([_menuItem image] == image)
    {
      [_menuItem setImage: nil];
    }

  //[super setMenuItem: item];
  ASSIGN (_menuItem, item);

  if ([_menuItem image] == nil)
    {
      [_menuItem setImage: image];
    }
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
    }

  _selectedItem = item;

  if (_selectedItem != nil)
    {
      if (_pbcFlags.altersStateOfSelectedItem)
        {
	  [_selectedItem setState: NSOnState];
        }
    }

  /* Set the item in the menu */
  [[_menu menuRepresentation] setHighlightedItemIndex: 
		   [_menu indexOfItem: _selectedItem]];
}

- (void) selectItemAtIndex: (int)index
{
  id <NSMenuItem> anItem;

  if (index < 0) 
    anItem = nil;
  else
    anItem = [self itemAtIndex: index];

  [self selectItem: anItem];
}

- (void) selectItemWithTitle: (NSString *)title
{
  id <NSMenuItem> anItem = [self itemWithTitle: title];

  [self selectItem: anItem];
}

- (void) setTitle: (NSString *)aString
{
  id <NSMenuItem> anItem;

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
  return [_menu indexOfItem: [self selectedItem]];
}

- (void) synchronizeTitleAndSelectedItem
{
  int index;

  if (!_pbcFlags.usesItemFromMenu)
    return;

  if ([_menu numberOfItems] == 0)
    {
      index = -1;
    }
  else if (_pbcFlags.pullsDown)
    {
      index = 0;
    }
  else
    {
      index = [[_menu menuRepresentation] highlightedItemIndex];

      if (index < 0) 
        {
	  // If no item is highighted, display the selected one ...
	  index = [self indexOfSelectedItem];
	  // ... if there is nown, then the first one, but don't select it.
	  if (index < 0)
	    index = 0;
	}
      else 
        {
	  // Selected the highlighted item
	  [self selectItemAtIndex: index];
	}
    }

  if ((index >= 0)  && ([_menu numberOfItems] > index))
    {
      NSMenuItem *anItem;

      // This conversion is needed as [setMenuItem:] expects an NSMenuItem
      anItem = (NSMenuItem *)[_menu itemAtIndex: index];
      [self setMenuItem: anItem];
    }
  else
    {
      [self setMenuItem: nil];
    }

  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl *)_control_view updateCell: self];
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
  id <NSMenuItem> item = [self selectedItem];

  if (item != nil)
    return [item title];
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

  if (selectedItem > 0)
    {
      [mr setHighlightedItemIndex: selectedItem];
    }

  // Ask the MenuView to attach the menu to this rect
  [mr setWindowFrameForAttachingToRect: cellFrame
      onScreen: [cvWin screen]
      preferredEdge: _pbcFlags.preferredEdge
      popUpSelectedItem: selectedItem];
  
  // Last, display the window
  [[mr window] orderFrontRegardless];

  [nc addObserver: self
      selector: @selector(_handleNotification:)
      name: NSMenuDidSendActionNotification
      object: _menu];
}

- (void) dismissPopUp
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self
      name: NSMenuDidSendActionNotification
      object: _menu];
  [_menu close];
}

/* Private method handles all cases after doing a selection from 
   the popup menu. Especially the obscure case where the user uses the 
   keyboard to open a popup, but subsequently uses the mouse to select
   an item. We'll never know this was done (and thus cannot dismiss
   the popUp) without getting this notification */
- (void) _handleNotification: (NSNotification*)aNotification
{
  NSString      *name = [aNotification name];
  if ([name isEqual: NSMenuDidSendActionNotification] == YES)
    {
      [self dismissPopUp];
      [self synchronizeTitleAndSelectedItem];
    }
}

- (BOOL) trackMouse: (NSEvent *)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView *)controlView
       untilMouseUp: (BOOL)untilMouseUp
{
  NSMenuView *mr = [[self menu] menuRepresentation];
  NSWindow   *menuWindow = [mr window];
  NSEvent    *e;
  NSPoint    p;

  if ([self isEnabled] == NO)
    return NO;

  if ([[self menu] numberOfItems] == 0)
    {
      NSBeep ();
      return NO;
    }

  // Attach the popUp
  [self attachPopUpWithFrame: cellFrame
	              inView: controlView];
  
  p = [[controlView window] convertBaseToScreen: [theEvent locationInWindow]];
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
  
  // End of mouse tracking here -- dismiss popup
  // No synchronization needed here
  if ([[_menu window] isVisible])
    {
      [self dismissPopUp];
    }

  return NO;
}

// This method is called to simulate programmatically a click by overriding 
// -[NSCell performClickWithFrame:inView:]
// This method is not executed upon mouse down; rather, it should simulate what
// would happen upon mouse down.  It should not start any real mouse tracking.
/**
 * Simulates a single click in the pop up button cell (the display of the cell
 * with this event occurs in the area delimited by <var>frame</var> in the view
 * <var>controlView</var>) and displays the popup button cell menu attached to
 * the view <var>controlView</var>, the menu width depends on the
 * <var>frame</var> width value. 
 */
- (void) performClickWithFrame: (NSRect)frame inView: (NSView *)controlView
{  
  [super performClickWithFrame: frame inView: controlView];
  
  [self attachPopUpWithFrame: frame inView: controlView];
}

// Arrow position for bezel style and borderless popups.
- (NSPopUpArrowPosition) arrowPosition
{
  return _pbcFlags.arrowPosition;
}

- (void) setArrowPosition: (NSPopUpArrowPosition)position
{
  _pbcFlags.arrowPosition = position;
}

/*
 * This drawing uses the same code that is used to draw cells in the menu.
 */
- (void) drawInteriorWithFrame: (NSRect)cellFrame
			inView: (NSView*)controlView
{
  BOOL new = NO;

  if ([self menuItem] == nil)
    {
      NSMenuItem *anItem;

      /* 
       * Create a temporary NSMenuItemCell to at least draw our control,
       * if items array is empty.
       */
      anItem = [NSMenuItem new];
      [anItem setTitle: [self title]];
      /* We need this menu item because NSMenuItemCell gets its contents 
       * from the menuItem not from what is set in the cell */
      [self setMenuItem: anItem];
      RELEASE(anItem);
      new = YES;
    }      

  /* We need to calc our size to get images placed correctly */
  [self calcSize];
  [super drawInteriorWithFrame: cellFrame inView: controlView];

  if (_cell.shows_first_responder)
    {
      cellFrame = [self drawingRectForBounds: cellFrame];
      NSDottedFrameRect(cellFrame);
    }

  /* Unset the item to restore balance if a new was created */
  if (new)
    {
      [self setMenuItem: nil];
    }
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
  [aCoder encodeConditionalObject: [self selectedItem]];
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
  NSMenu *menu;

  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      if ([aDecoder containsValueForKey: @"NSAltersState"])
        {
	  BOOL alters = [aDecoder decodeBoolForKey: @"NSAltersState"];
	  
	  [self setAltersStateOfSelectedItem: alters];
	}
      if ([aDecoder containsValueForKey: @"NSUsesItemFromMenu"])
        {
	  BOOL usesItem = [aDecoder decodeBoolForKey: @"NSUsesItemFromMenu"];
	  
	  [self setUsesItemFromMenu: usesItem];
	}
      if ([aDecoder containsValueForKey: @"NSArrowPosition"])
        {
	  NSPopUpArrowPosition position = [aDecoder decodeIntForKey: 
							@"NSArrowPosition"];
	  
	  [self setArrowPosition: position];
	}
      if ([aDecoder containsValueForKey: @"NSPreferredEdge"])
        {
	  NSRectEdge edge = [aDecoder decodeIntForKey: @"NSPreferredEdge"];
	  
	  [self setPreferredEdge: edge];
	}

      menu = [aDecoder decodeObjectForKey: @"NSMenu"];
      [self setMenu: menu];
    }
  else
    {
      int flag;
      id<NSMenuItem> selectedItem;
      int version = [aDecoder versionForClassName: 
				  @"NSPopUpButtonCell"];

      menu = [aDecoder decodeObject];
      /* 
	 FIXME: This same ivar already gets set in NSCell initWithCoder, 
	 but there it is used directly not via a method call. So here we first 
	 unset it and than set it again as our setMenu: method tries to optimize 
	 duplicate calls.
      */
      [self setMenu: nil];
      [self setMenu: menu];
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
      
      if (version < 2)
        {
	  int i;
	  
	  // Not the stored format did change but the interpretation of it.
	  // in version 1 most of the ivars were not used, so their values may
	  // be arbitray. We overwrite them with valid settings.
	  [self setPullsDown: _pbcFlags.pullsDown];
	  _pbcFlags.usesItemFromMenu = YES;
	  
	  for (i = 0; i < [_menu numberOfItems]; i++)
	    {
	      id <NSMenuItem> anItem = [menu itemAtIndex: i];
	      
	      [anItem setOnStateImage: nil];
	      [anItem setMixedStateImage: nil];
	    }
	  [self setEnabled: YES];
	}
      [self selectItem: selectedItem];
    }
  return self;
}

@end
