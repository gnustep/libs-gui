/* 
   NSMenuView.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  David Lazaro Saz <khelekir@encomix.es>
   Date: Oct 1999

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

#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>

// FIXME Check this strange comment: 
// These private methods are used in NSPopUpButton. For NSPB we need to be
// able to init with a frame, but have a very custom cell size.

// Michael: This simply means that for popups the menu code cannot
// arbitraily decide the cellSize. The size of the popup must be
// consistent.

@implementation NSMenuView

/*
 * Class methods.
 */
+ (float) menuBarHeight
{
  NSFont *font = [NSFont menuFontOfSize: 0.0];

//static float GSMenuBarHeight = 25.0; - A wild guess for default font.
  return [font boundingRectForFont].size.height + 10;
}

/*
 * NSView overrides
 */
- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

/*
 * Init methods.
 */
- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (id) initWithFrame: (NSRect)aFrame
{
  NSRect r = [[NSFont menuFontOfSize: 0.0] boundingRectForFont];
  /* Should make up 110, 20 for default font */
  cellSize = NSMakeSize (r.size.width * 10., r.size.height + 5.);

  menuv_highlightedItemIndex = -1;
  menuv_horizontalEdgePad = 4.;

  // Create an array to store out menu item cells.
  menuv_itemCells = [NSMutableArray new];

  return [super initWithFrame: aFrame];
}

- (void) _setCellSize: (NSSize)aSize
{
  cellSize = aSize;
}

- (id) initWithFrame: (NSRect)aFrame
	    cellSize: (NSSize)aSize
{
  [self initWithFrame: aFrame];

  cellSize = aSize;

  return self;
}

/*
 * Getting and Setting Menu View Attributes
 */
- (void) setMenu: (NSMenu*)menu
{
  NSNotificationCenter	*theCenter = [NSNotificationCenter defaultCenter];

  if (menuv_menu != nil)
    {
      // Remove this menu view from the old menu list of observers.
      [theCenter removeObserver: self name: nil object: menuv_menu];
    }

  ASSIGN(menuv_menu, menu);
  menuv_items_link = [menuv_menu itemArray];

  // Add this menu view to the menu's list of observers.
  [theCenter addObserver: self
                selector: @selector(itemChanged:)
                    name: NSMenuDidChangeItemNotification
                  object: menuv_menu];

  [theCenter addObserver: self
                selector: @selector(itemAdded:)
                    name: NSMenuDidAddItemNotification
                  object: menuv_menu];

  [theCenter addObserver: self
                selector: @selector(itemRemoved:)
                    name: NSMenuDidRemoveItemNotification
                  object: menuv_menu];

  // Force menu view's layout to be recalculated.
  [self setNeedsSizing: YES];
}

- (NSMenu*) menu
{
  return menuv_menu;
}

- (void) setHorizontal: (BOOL)flag
{
  menuv_horizontal = flag;
}

- (BOOL) isHorizontal
{
  return menuv_horizontal;
}

- (void) setFont: (NSFont*)font
{
  ASSIGN(menuv_font, font);
}

- (NSFont*) font
{
  return menuv_font;
}

- (void) setHighlightedItemIndex: (int)index
{
  id   aCell;

  [self lockFocus];

  if (index == -1) 
    {
      if (menuv_highlightedItemIndex != -1)
	{
	  NSRect aRect = [self rectOfItemAtIndex: menuv_highlightedItemIndex];

	  aCell  = [menuv_itemCells objectAtIndex: menuv_highlightedItemIndex];

	  [aCell highlight: NO withFrame: aRect inView: self];

	  [_window flushWindow];

	  menuv_highlightedItemIndex = -1;
	}
    } 
  else if (index >= 0)
    {
      if (menuv_highlightedItemIndex != -1)
	{
	  NSRect aRect = [self rectOfItemAtIndex: menuv_highlightedItemIndex];

	  aCell = [menuv_itemCells objectAtIndex: menuv_highlightedItemIndex];

	  [aCell highlight: NO withFrame: aRect inView: self];

	  [_window flushWindow];
	}

      if (index != menuv_highlightedItemIndex)
	{
	  id anItem = [menuv_items_link objectAtIndex: index];

	  if ([anItem isEnabled])
	    {
	      NSRect aRect = [self rectOfItemAtIndex: index];

	      aCell  = [menuv_itemCells objectAtIndex: index];

	      [aCell highlight: YES withFrame: aRect inView: self];

	      [_window flushWindow];
	    }

	  // Set ivar to new index.
	  menuv_highlightedItemIndex = index;
	} 
      else if (menuv_highlightedItemIndex == index)
	{	      
	  menuv_highlightedItemIndex = -1;
	}
    }

  [self unlockFocus];
}

- (int) highlightedItemIndex
{
  return menuv_highlightedItemIndex;
}

- (void) setMenuItemCell: (NSMenuItemCell *)cell
	  forItemAtIndex: (int)index
{
  NSMenuItem *anItem = [menuv_items_link objectAtIndex: index];
  
  [menuv_itemCells replaceObjectAtIndex: index withObject: cell];

  [cell setMenuItem: anItem];
  [cell setMenuView: self];

  if ([self highlightedItemIndex] == index)
    [cell setHighlighted: YES];
  else
    [cell setHighlighted: NO];

  // Mark the new cell and the menu view as needing resizing.
  [cell setNeedsSizing: YES];
  [self setNeedsSizing: YES];
}

- (NSMenuItemCell*) menuItemCellForItemAtIndex: (int)index
{
  return [menuv_itemCells objectAtIndex: index];
}

- (NSMenuView*) attachedMenuView
{
  NSMenu	*attachedMenu;

  if ((attachedMenu = [menuv_menu attachedMenu]))
    return [attachedMenu menuRepresentation];
  else
    return nil;
}

- (NSMenu*) attachedMenu
{
  return [menuv_menu attachedMenu];
}

- (BOOL) isAttached
{
  return [menuv_menu isAttached];
}

- (BOOL) isTornOff
{
  return [menuv_menu isTornOff];
}

- (void) setHorizontalEdgePadding: (float)pad
{
  menuv_horizontalEdgePad = pad;
}

- (float) horizontalEdgePadding
{
  return menuv_horizontalEdgePad;
}

/*
 * Notification Methods
 */
- (void) itemChanged: (NSNotification*)notification
{
  int index = [[[notification userInfo] objectForKey: @"NSMenuItemIndex"]
		intValue];

  // Mark the cell associated with the item as needing resizing.
  [[menuv_itemCells objectAtIndex: index] setNeedsSizing: YES];

  // Mark the menu view as needing to be resized.
  [self setNeedsSizing: YES];
}

- (void) itemAdded: (NSNotification*)notification
{
  int         index  = [[[notification userInfo]
			  objectForKey: @"NSMenuItemIndex"] intValue];
  NSMenuItem *anItem = [menuv_items_link objectAtIndex: index];
  id          aCell  = [NSMenuItemCell new];

  [aCell setMenuItem: anItem];
  [aCell setMenuView: self];

  if ([self highlightedItemIndex] == index)
    [aCell setHighlighted: YES];
  else
    [aCell setHighlighted: NO];

  [menuv_itemCells insertObject: aCell atIndex: index];

  [aCell setNeedsSizing: YES];

  // Mark the menu view as needing to be resized.
  [self setNeedsSizing: YES];
}

- (void) itemRemoved: (NSNotification*)notification
{
  int wasHighlighted = [self highlightedItemIndex];
  int index = [[[notification userInfo] objectForKey: @"NSMenuItemIndex"]
		intValue];

  if (index <= wasHighlighted)
    {
      [self setHighlightedItemIndex: -1];
    }
  [menuv_itemCells removeObjectAtIndex: index];

  if (wasHighlighted > index)
    {
      [self setHighlightedItemIndex: --wasHighlighted];
    }
  // Mark the menu view as needing to be resized.
  [self setNeedsSizing: YES];
}

/*
 * Working with Submenus.
 */
- (void) detachSubmenu
{
  NSMenu     *attachedMenu = [menuv_menu attachedMenu];
  NSMenuView *attachedMenuView;

  if (!attachedMenu)
    return;

  attachedMenuView = [attachedMenu menuRepresentation];

  [attachedMenuView detachSubmenu];

  [attachedMenuView setHighlightedItemIndex: -1];

  if ([attachedMenu isFollowTransient])
    {
      [attachedMenu closeTransient];
      [attachedMenuView setHighlightedItemIndex: _oldHighlightedItemIndex];
    }
  else
    [attachedMenu close];
}

- (void) attachSubmenuForItemAtIndex: (int)index
{
  /*
   * Transient menus are used for torn-off menus, which are already on the
   * screen and for sons of transient menus.  As transients disappear as
   * soon as we release the mouse the user will be able to leave submenus
   * open on the screen and interact with other menus at the same time.
   */
  NSMenu *attachableMenu = [[menuv_items_link objectAtIndex: index] submenu];

  if ([attachableMenu isTornOff] || [menuv_menu isFollowTransient])
    {
      _oldHighlightedItemIndex = [[attachableMenu menuRepresentation]
						  highlightedItemIndex];
      [attachableMenu displayTransient];
      [[attachableMenu menuRepresentation] setHighlightedItemIndex: -1];
    }
  else
    [attachableMenu display];
}

/*
 * Calculating Menu Geometry
 */
- (void) update
{
  [menuv_menu update];

  if (menuv_needsSizing)
    [self sizeToFit];
}

- (void) setNeedsSizing: (BOOL)flag
{
  menuv_needsSizing = flag;
}

- (BOOL) needsSizing
{
  return menuv_needsSizing;
}

- (void) sizeToFit
{
  unsigned	i;
  unsigned	howMany = [menuv_itemCells count];
  float		howHigh = (howMany * cellSize.height);
  float		neededImageAndTitleWidth = [[NSFont boldSystemFontOfSize: 0]
				   widthOfString: [menuv_menu title]] + 17;
  float		neededKeyEquivalentWidth = 0.0;
  float		neededStateImageWidth = 0.0;
  float		accumulatedOffset = 0.0;

  // TODO: Optimize this loop.
  for (i = 0; i < howMany; i++)
    {
      float		anImageAndTitleWidth;
      float		anImageWidth;
      float		aKeyEquivalentWidth;
      float		aStateImageWidth;
      float		aTitleWidth;
      NSMenuItemCell	*aCell = [menuv_itemCells objectAtIndex: i];

      // State image area.
      aStateImageWidth = [aCell stateImageWidth];

      if (aStateImageWidth > neededStateImageWidth)
	neededStateImageWidth = aStateImageWidth;

      // Image and title area.
      aTitleWidth = [aCell titleWidth];
      anImageWidth = [aCell imageWidth];
      switch ([aCell imagePosition])
	{
	  case NSNoImage: 
	    anImageAndTitleWidth = aTitleWidth;
	    break;

	  case NSImageOnly: 
	    anImageAndTitleWidth = anImageWidth;
	    break;

	  case NSImageLeft: 
	  case NSImageRight: 
	    anImageAndTitleWidth = anImageWidth + aTitleWidth + xDist;
	    break;

	  case NSImageBelow: 
	  case NSImageAbove: 
	  case NSImageOverlaps: 
	  default: 
	    if (aTitleWidth > anImageWidth)
	      anImageAndTitleWidth = aTitleWidth;
	    else
	      anImageAndTitleWidth = anImageWidth;
	    break;
	}
      anImageAndTitleWidth += aStateImageWidth;
      if (anImageAndTitleWidth > neededImageAndTitleWidth)
	neededImageAndTitleWidth = anImageAndTitleWidth;

      // Key equivalent area.
      aKeyEquivalentWidth = [aCell keyEquivalentWidth];

      if (aKeyEquivalentWidth > neededKeyEquivalentWidth)
	neededKeyEquivalentWidth = aKeyEquivalentWidth;
    }

  // Cache the needed widths.
  menuv_stateImageWidth = neededStateImageWidth;
  menuv_imageAndTitleWidth = neededImageAndTitleWidth;
  menuv_keyEqWidth = neededKeyEquivalentWidth;

  // Calculate the offsets and cache them.
  menuv_stateImageOffset = menuv_imageAndTitleOffset = accumulatedOffset =
    menuv_horizontalEdgePad;
  accumulatedOffset += 2 * menuv_horizontalEdgePad + neededImageAndTitleWidth;

  menuv_keyEqOffset = accumulatedOffset += menuv_horizontalEdgePad;
  accumulatedOffset += neededKeyEquivalentWidth + menuv_horizontalEdgePad;

  // Calculate frame size.
  if (![menuv_menu _ownedByPopUp])
    cellSize.width = accumulatedOffset + 3; // Add the border width

  [self setFrameSize: NSMakeSize(cellSize.width + 1, howHigh)];

  menuv_needsSizing = NO;
}

- (float) stateImageOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_stateImageOffset;
}

- (float) stateImageWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_stateImageWidth;
}

- (float) imageAndTitleOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_imageAndTitleOffset;
}

- (float) imageAndTitleWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_imageAndTitleWidth;
}

- (float) keyEquivalentOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_keyEqOffset;
}

- (float) keyEquivalentWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_keyEqWidth;
}

- (NSRect) innerRect
{
  NSRect aRect = {{_bounds.origin.x + 1, _bounds.origin.y},
		  {_bounds.size.width - 1, _bounds.size.height}};

  return aRect;
}

- (NSRect) rectOfItemAtIndex: (int)index
{
  NSRect theRect;

  if (menuv_needsSizing)
    [self sizeToFit];

  if (index == 0)
    theRect.origin.y = _bounds.size.height - cellSize.height;
  else
    theRect.origin.y = _bounds.size.height - (cellSize.height * (index + 1));
  theRect.origin.x = 1;
  theRect.size = cellSize;

  return theRect;
}

- (int) indexOfItemAtPoint: (NSPoint)point
{
  // The MacOSX API says that this method calls - rectOfItemAtIndex for
  // *every* cell to figure this out. Well, instead we will just do some
  // simple math. (NOTE: if we get horizontal methods we will have to do
  // this. Very much like NSTabView.

  return (   point.x <  _frame.origin.x
	  || point.x >  _frame.size.width + _frame.origin.x
	  || point.y <= _frame.origin.y
	  || point.y >  _frame.size.height + _frame.origin.y) ?
          -1 : 
          (_frame.size.height - point.y) / cellSize.height;
}

- (void) setNeedsDisplayForItemAtIndex: (int)index
{
  NSRect aRect = [self rectOfItemAtIndex: index];

  [self setNeedsDisplayInRect: aRect];
}

- (NSPoint) locationForSubmenu: (NSMenu *)aSubmenu
{
  if (menuv_needsSizing)
    [self sizeToFit];

  // find aSubmenu's parent

  // position aSubmenu's window to be adjacent to its parent.

  // return new origin of window.
  return NSZeroPoint;
}

- (void) resizeWindowWithMaxHeight: (float)maxHeight
{
  // set the menuview's window to max height in order to keep on screen?
}

- (void) setWindowFrameForAttachingToRect: (NSRect)screenRect 
				 onScreen: (NSScreen*)screen
			    preferredEdge: (NSRectEdge)edge
			popUpSelectedItem: (int)selectedItemIndex
{
  NSRect r;

  // Move the menu window to screen?
  // TODO

  // Compute position for popups, if needed
  if (selectedItemIndex > -1)
    {
      screenRect.origin.y
	+= [self convertSize: cellSize toView: nil].height * selectedItemIndex;
    }
  
  // Get the frameRect
  r = [NSMenuWindow frameRectForContentRect: screenRect
				  styleMask: [_window styleMask]];
  
  // Update position,if needed, using the preferredEdge;
  // It seems we should be calling [self resizeWindowWithMaxHeight:];
  // see the (quite obscure) doc.
  // TODO

  // Set the window frame
  [_window setFrame: r 
	    display: YES]; 
}

/*
 * Drawing.
 */
- (void) drawRect: (NSRect)rect
{
  int    i;
  NSRect aRect   = [self innerRect];
  int    howMany = [menuv_itemCells count];

  NSGraphicsContext *ctxt = GSCurrentContext();

  // Draw a dark gray line at the left of the menu item cells.
  DPSgsave(ctxt);
  DPSsetlinewidth(ctxt, 1);
  DPSsetgray(ctxt, 0.333);
  DPSmoveto(ctxt, _bounds.origin.x, _bounds.origin.y);
  DPSrlineto(ctxt, 0, _bounds.size.height);
  DPSstroke(ctxt);
  DPSgrestore(ctxt);

  // Draw the menu cells.
  aRect.origin.y = cellSize.height * (howMany - 1);
  aRect.size = cellSize;

  for (i = 0; i < howMany; i++)
    {
      id aCell;

      aCell = [menuv_itemCells objectAtIndex: i];

      [aCell drawWithFrame: aRect inView: self];
      aRect.origin.y -= cellSize.height;
    }
}

/*
 * Event Handling
 */
- (void) performActionWithHighlightingForItemAtIndex: (int)index
{
  NSMenu     *candidateMenu = menuv_menu;
  NSMenuView *targetMenuView;
  int         indexToHighlight = index;

  for (;;)
    {
      if (![candidateMenu supermenu]
	|| [candidateMenu isAttached]
	|| [candidateMenu isTornOff])
	{
	  targetMenuView = [candidateMenu menuRepresentation];

	  break;
	}
      else
	{
	  NSMenu *superMenu = [candidateMenu supermenu];

	  indexToHighlight = [superMenu indexOfItemWithSubmenu: candidateMenu];
	  candidateMenu = superMenu;
	}
    }

  if ([targetMenuView attachedMenu])
    [targetMenuView detachSubmenu];

  [targetMenuView setHighlightedItemIndex: indexToHighlight];

  [menuv_menu performActionForItemAtIndex: index];

  [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
  [targetMenuView setHighlightedItemIndex: -1];
}

#define MOVE_THRESHOLD_DELTA 2.0
#define DELAY_MULTIPLIER     6

- (BOOL) trackWithEvent: (NSEvent*)event
{
  unsigned	eventMask = NSPeriodicMask;
  NSDate        *theDistantFuture = [NSDate distantFuture];
  int		index;
  NSPoint	location;
  NSPoint	lastLocation = {0,0};
  NSMenu	*alreadyAttachedMenu = NO;
  BOOL		mouseMoved = NO;
  BOOL		delayedSelect = NO;
  int		delayCount = 0;
  float		xDelta = MOVE_THRESHOLD_DELTA;
  float		yDelta = 0.0;
  NSEvent	*original;
  NSEventType	type = [event type];
  NSEventType	end;

  /*
   * The original event is unused except to determine whether the method
   * was invoked in response to a right or left mouse down.
   * We pass the same event on when we want tracking to move into a
   * submenu.
   */
  original = AUTORELEASE(RETAIN(event));
  if (type == NSRightMouseDown)
    {
      end = NSRightMouseUp;
      eventMask |= NSRightMouseUpMask | NSRightMouseDraggedMask;
    }
  else if (type == NSMiddleMouseDown)
    {
      end = NSMiddleMouseUp;
      eventMask |= NSMiddleMouseUpMask | NSMiddleMouseDraggedMask;
    }
  else
    {
      end = NSLeftMouseUp;
      eventMask |= NSLeftMouseUpMask | NSLeftMouseDraggedMask;
    }
      
  do
    {
      location     = [_window mouseLocationOutsideOfEventStream];
      index        = [self indexOfItemAtPoint: location];

      if (index != menuv_highlightedItemIndex)
	{
	  mouseMoved = YES;	/* Ok - had an initial movement. */
	}
      if (type == NSPeriodic)
	{
	  if ([menuv_menu isPartlyOffScreen])
	    {
	      NSPoint pointerLoc = [_window convertBaseToScreen: location];

	      // TODO: Why 1 in the Y axis?
	      if (pointerLoc.x == 0 || pointerLoc.y == 1
		|| pointerLoc.x == [[_window screen] frame].size.width - 1)
		[menuv_menu shiftOnScreen];
	    }

	  if (delayedSelect && mouseMoved && [event type] == NSPeriodic)
	    {
	      float	xDiff = location.x - lastLocation.x;
	      float	yDiff = location.y - lastLocation.y;

	      /*
               * Once the mouse movement has started in one vertical
	       * direction, it must continue in the same direction if
	       * selection is to be delayed.
	       */
	      if (yDelta == 0.0)
		{
		  if (yDiff < 0.0)
		    yDelta = -MOVE_THRESHOLD_DELTA;
		  else if (yDiff > 0.0)
		    yDelta = MOVE_THRESHOLD_DELTA;
		}
	      /*
               * Check to see if movement is less than the threshold.
	       */
	      if (xDiff < xDelta
		|| (yDelta < 0.0 && yDiff > yDelta)
		|| (yDelta > 0.0 && yDiff < yDelta))
		{
		  /*
		   * if we have had too many successive small movements, or
		   * a single movement too far in the wrong direction, we
		   * leave 'delayedSelect' mode.
		   */
		  delayCount++;
		  if (delayCount >= DELAY_MULTIPLIER
		    || (xDiff < 0)
		    || (yDelta < 0.0 && yDiff > -yDelta)
		    || (yDelta > 0.0 && yDiff < -yDelta))
		    {
		      delayedSelect = NO;
		    }
		}
	      else
		{
		  delayCount = 0;
		}
	      lastLocation = location;
	    }
	}

      if (index == -1)
	{
	  NSWindow	*w;

	  location = [_window convertBaseToScreen: location];

	  /*
	   * If the mouse is back in the supermenu, we return NO so that
	   * our caller knows the button was not released.
	   */
	  w = [[menuv_menu supermenu] window];
	  if (w != nil && NSMouseInRect(location, [w frame], NO) == YES)
	    {
	      return NO;
	    }
	  /*
	   * if the mouse is in our attached menu - get that menu to track it.
	   */
	  w = [[menuv_menu attachedMenu] window];
	  if (w != nil && NSMouseInRect(location, [w frame], NO) == YES)
	    {
	      if ([[self attachedMenuView] trackWithEvent: original])
		return YES;
	    }
	  else
	    {
	      if (index != menuv_highlightedItemIndex)
		[self setHighlightedItemIndex: index];
	    }
#if 0
	  if (([menuv_menu supermenu] && ![menuv_menu isTornOff])
	      || [menuv_menu isFollowTransient])
	    return NO;
#endif
	}
      else
	{
	  if (index != menuv_highlightedItemIndex)
	    {
	      if (![menuv_menu attachedMenu] || !delayedSelect)
		{
		  [self setHighlightedItemIndex: index];

		  if ([menuv_menu attachedMenu])
		    [self detachSubmenu];

		  if ((alreadyAttachedMenu =
		       [[menuv_items_link objectAtIndex: index] submenu]))
		    {
		      [self attachSubmenuForItemAtIndex: index];
		      mouseMoved = NO;
		      delayedSelect = YES;
		      delayCount = 0;
		      yDelta = 0.0;
		    }
		  else
		    {
		      delayedSelect = NO;
		    }
		}
	    }
	}

      event = [NSApp nextEventMatchingMask: eventMask
		                 untilDate: theDistantFuture
		                    inMode: NSEventTrackingRunLoopMode
		                   dequeue: YES];
      type = [event type];
    }
  while (type != end);

  // Perform actions as needed.
  if (index != -1 && !alreadyAttachedMenu)
    {
      // Stop the periodic events before performing the action
      [NSEvent stopPeriodicEvents];
      [menuv_menu performActionForItemAtIndex: index];

      if (![menuv_menu isFollowTransient] && ![menuv_menu _ownedByPopUp])
	[self setHighlightedItemIndex: -1];
    }

  // Close menus if needed.
  if (!menuv_keepAttachedMenus || index == -1
    || (alreadyAttachedMenu && [alreadyAttachedMenu isFollowTransient]))
    {
      NSMenu     *parentMenu;
      NSMenu     *masterMenu;

      for (parentMenu = masterMenu = menuv_menu;
	   (parentMenu = [masterMenu supermenu])
	    && (![masterMenu isTornOff] || [masterMenu isFollowTransient]);
	   masterMenu = parentMenu);

      if ([masterMenu attachedMenu])
	{
	  NSMenuView *masterMenuView = [masterMenu menuRepresentation];

	  [masterMenuView detachSubmenu];
	  [masterMenuView setHighlightedItemIndex: -1];
	}
    }

  return YES;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSMenu	*masterMenu;
  NSMenuView	*masterMenuView;
  NSPoint	originalLocation;

  menuv_keepAttachedMenus = YES;

  masterMenu = menuv_menu;

  originalLocation = [[masterMenu window] frame].origin;

  masterMenuView = [masterMenu menuRepresentation];

  masterMenuView->menuv_keepAttachedMenus = YES;

  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.05];

  [masterMenuView trackWithEvent: theEvent];

  [NSEvent stopPeriodicEvents];

  if (!NSEqualPoints(originalLocation, [[masterMenu window] frame].origin))
    {
      [masterMenu nestedSetFrameOrigin: originalLocation];
      [masterMenu nestedCheckOffScreen];
    }
  masterMenuView->menuv_keepAttachedMenus = NO;

  menuv_keepAttachedMenus = NO;
}

- (BOOL) performKeyEquivalent: (NSEvent *)theEvent
{
  return [menuv_menu performKeyEquivalent: theEvent];
}

/*
 * NSCoding Protocol
 */
- (void) encodeWithCoder: (NSCoder*)encoder
{
  [super encodeWithCoder: encoder];

  [encoder encodeObject: menuv_itemCells];
  [encoder encodeObject: menuv_font];
  [encoder encodeValueOfObjCType: @encode(BOOL) at: &menuv_horizontal];
  [encoder encodeValueOfObjCType: @encode(float) at: &menuv_horizontalEdgePad];
  [encoder encodeValueOfObjCType: @encode(NSSize) at: &cellSize];
}

- (id) initWithCoder: (NSCoder*)decoder
{
  self = [super initWithCoder: decoder];

  [decoder decodeValueOfObjCType: @encode(id) at: &menuv_itemCells];
  [decoder decodeValueOfObjCType: @encode(id) at: &menuv_font];
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &menuv_horizontal];
  [decoder decodeValueOfObjCType: @encode(float) at: &menuv_horizontalEdgePad];
  [decoder decodeValueOfObjCType: @encode(NSSize) at: &cellSize];

  menuv_highlightedItemIndex = -1;
  menuv_needsSizing = YES;

  return self;
}

@end
