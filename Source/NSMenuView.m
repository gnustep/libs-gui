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

static float GSMenuBarHeight = 25.0; // A wild guess.

// FIXME Check this strange comment:
// These private methods are used in NSPopUpButton. For NSPB we need to be
// able to init with a frame, but have a very custom cell size.

// Michael: This simply means that for popups the menu code cannot
// arbitraily decide the cellSize. The size of the popup must be
// consistent.

@implementation NSMenuView

//
// Class methods.
//
+ (float)menuBarHeight
{
  return GSMenuBarHeight;
}

//
// NSView overrides
//
- (BOOL)acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

//
// Init methods.
//
- (id)init
{
  return [self initWithFrame: NSZeroRect];
}

- (id)initWithFrame: (NSRect)aFrame
{
  cellSize = NSMakeSize(110,20);

  menuv_highlightedItemIndex = -1;
  menuv_horizontalEdgePad = 4.;

  // Create an array to store out menu item cells.
  menuv_itemCells = [NSMutableArray new];

  return [super initWithFrame: aFrame];
}

- (void)_setCellSize:(NSSize)aSize
{
  cellSize = aSize;
}

- (id)initWithFrame: (NSRect)aFrame
 	   cellSize: (NSSize)aSize
{
  [self initWithFrame:aFrame];

  cellSize = aSize;

  return self;
}

//
// Getting and Setting Menu View Attributes
//
- (void)setMenu: (NSMenu *)menu
{
  NSNotificationCenter *theCenter = [NSNotificationCenter defaultCenter];

  if (menuv_menu)
    {
      // Remove this menu view from the old menu list of observers.
      [theCenter removeObserver: self name: nil object: menuv_menu];
      [menuv_menu release];
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

- (NSMenu *)menu
{
  return menuv_menu;
}

- (void)setHorizontal: (BOOL)flag
{
  menuv_horizontal = flag;
}

- (BOOL)isHorizontal
{
  return menuv_horizontal;
}

- (void)setFont: (NSFont *)font
{
  ASSIGN(menuv_font, font);
}

- (NSFont *)font
{
  return menuv_font;
}

- (void)setHighlightedItemIndex: (int)index
{
  id   aCell;

  [self lockFocus];

  if (index == -1) 
    {
      if (menuv_highlightedItemIndex != -1)
	{
	  NSRect aRect = [self rectOfItemAtIndex: menuv_highlightedItemIndex];

	  aCell  = [menuv_itemCells objectAtIndex: menuv_highlightedItemIndex];

	  [aCell highlight: NO withFrame:aRect inView: self];

	  [window flushWindow];

	  menuv_highlightedItemIndex = -1;
	}
    } 
  else if (index >= 0)
    {
      if ( menuv_highlightedItemIndex != -1)
	{
	  NSRect aRect = [self rectOfItemAtIndex: menuv_highlightedItemIndex];

	  aCell = [menuv_itemCells objectAtIndex: menuv_highlightedItemIndex];

	  [aCell highlight: NO withFrame: aRect inView: self];

	  [window flushWindow];
	}

      if (index != menuv_highlightedItemIndex)
	{
	  id anItem = [menuv_items_link objectAtIndex: index];

	  if ([anItem isEnabled])
	    {
	      NSRect aRect = [self rectOfItemAtIndex: index];

	      aCell  = [menuv_itemCells objectAtIndex: index];

	      [aCell highlight: YES withFrame: aRect inView: self];

	      [window flushWindow];
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

- (int)highlightedItemIndex
{
  return menuv_highlightedItemIndex;
}

- (void)setMenuItemCell: (NSMenuItemCell *)cell
	 forItemAtIndex: (int)index
{
  [menuv_itemCells replaceObjectAtIndex: index withObject: cell];

  // Mark the new cell and the menu view as needing resizing.
  [cell setNeedsSizing: YES];
  [self setNeedsSizing: YES];
}

- (NSMenuItemCell *)menuItemCellForItemAtIndex: (int)index
{
  return [menuv_itemCells objectAtIndex: index];
}

- (NSMenuView *)attachedMenuView
{
  NSMenu *attachedMenu;

  if ((attachedMenu = [menuv_menu attachedMenu]))
    return [attachedMenu menuRepresentation];
  else
    return nil;
}

- (NSMenu *)attachedMenu
{
  return [menuv_menu attachedMenu];
}

- (BOOL)isAttached
{
  return [menuv_menu isAttached];
}

- (BOOL)isTornOff
{
  return [menuv_menu isTornOff];
}

- (void)setHorizontalEdgePadding: (float)pad
{
  menuv_horizontalEdgePad = pad;
}

- (float)horizontalEdgePadding
{
  return menuv_horizontalEdgePad;
}

//
// Notification Methods
//
- (void) itemChanged: (NSNotification *)notification
{
  int index = [[[notification userInfo] objectForKey: @"NSMenuItemIndex"]
		intValue];

  // Mark the cell associated with the item as needing resizing.
  [[menuv_itemCells objectAtIndex: index] setNeedsSizing: YES];

  // Mark the menu view as needing to be resized.
  [self setNeedsSizing: YES];
}

- (void) itemAdded: (NSNotification *)notification
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

- (void) itemRemoved: (NSNotification *)notification
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

//
// Working with Submenus.
//
- (void)detachSubmenu
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

- (void)attachSubmenuForItemAtIndex: (int)index
{
  // Transient menus are used for torn-off menus, which are already on the
  // screen and for sons of transient menus.  As transients disappear as
  // soon as we release the mouse the user will be able to leave submenus
  // open on the screen and interact with other menus at the same time.

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

//
// Calculating Menu Geometry
//
- (void)update
{
  [menuv_menu update];

  if (menuv_needsSizing)
    [self sizeToFit];
}

- (void)setNeedsSizing: (BOOL)flag
{
  menuv_needsSizing = flag;
}

- (BOOL)needsSizing
{
  return menuv_needsSizing;
}

- (void) sizeToFit
{
  unsigned	i;
  unsigned	howMany = [menuv_itemCells count];
  float		howHigh = (howMany * cellSize.height);
  float		neededImageAndTitleWidth = [[NSFont boldSystemFontOfSize: 12]
				   widthOfString: [menuv_menu title]] + 17;
  float		neededKeyEquivalentWidth = 0.;
  float		neededStateImageWidth = 0.;
  float		accumulatedOffset = 0.;

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
#if 0
  if (![menuv_menu _isBeholdenToPopUpButton])
#endif
    cellSize.width = accumulatedOffset + 3; // Add the border width

  [self setFrameSize: NSMakeSize(cellSize.width + 1, howHigh)];

  menuv_needsSizing = NO;
}

- (void) sizeToFitForPopUpButton
{
  int howHigh = ([menuv_items_link count] * cellSize.height);

  if ([window contentView] == self)
    [window setContentSize: NSMakeSize(cellSize.width,howHigh)];
  else
    [self setFrame: NSMakeRect(0,0,cellSize.width,howHigh)];
}

- (float)stateImageOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_stateImageOffset;
}

- (float)stateImageWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_stateImageWidth;
}

- (float)imageAndTitleOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_imageAndTitleOffset;
}

- (float)imageAndTitleWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_imageAndTitleWidth;
}

- (float)keyEquivalentOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_keyEqOffset;
}

- (float)keyEquivalentWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_keyEqWidth;
}

- (NSRect)innerRect
{
  NSRect aRect = {{bounds.origin.x + 1, bounds.origin.y},
		  {bounds.size.width - 1, bounds.size.height}};

  return aRect;
}

- (NSRect)rectOfItemAtIndex: (int)index
{
  NSRect theRect;

  if (menuv_needsSizing)
    [self sizeToFit];

  if (index == 0)
    theRect.origin.y = bounds.size.height - cellSize.height;
  else
    theRect.origin.y = bounds.size.height - (cellSize.height * (index + 1));
  theRect.origin.x = 1;
  theRect.size = cellSize;

  return theRect;
}

- (int)indexOfItemAtPoint: (NSPoint)point
{
  // The MacOSX API says that this method calls - rectOfItemAtIndex for
  // *every* cell to figure this out. Well, instead we will just do some
  // simple math. (NOTE: if we get horizontal methods we will have to do
  // this. Very much like NSTabView.

  return (   point.x <  frame.origin.x
	  || point.x >  frame.size.width + frame.origin.x
	  || point.y <= frame.origin.y
	  || point.y >  frame.size.height + frame.origin.y) ?
          -1 :
          (frame.size.height - point.y) / cellSize.height;
}

- (void) setNeedsDisplayForItemAtIndex: (int)index
{
  NSRect aRect = [self rectOfItemAtIndex: index];

  [self setNeedsDisplayInRect: aRect];
}

- (NSPoint)locationForSubmenu: (NSMenu *)aSubmenu
{
  if (menuv_needsSizing)
    [self sizeToFit];

  // find aSubmenu's parent

  // position aSubmenu's window to be adjacent to its parent.

  // return new origin of window.
  return NSZeroPoint;
}

- (void)resizeWindowWithMaxHeight: (float)maxHeight
{
  // set the menuview's window to max height in order to keep on screen?
}

- (void)setWindowFrameForAttachingToRect: (NSRect)screenRect 
			        onScreen: (NSScreen *)screen
			   preferredEdge: (NSRectEdge)edge
		       popUpSelectedItem: (int)selectedItemIndex
{
  // Huh!?
}

//
// Drawing.
//
- (void)drawRect: (NSRect)rect
{
  int    i;
  NSRect aRect   = [self innerRect];
  int    howMany = [menuv_itemCells count];

  NSGraphicsContext *ctxt = GSCurrentContext();

  // Draw a dark gray line at the left of the menu item cells.
  DPSgsave(ctxt);
    DPSsetlinewidth(ctxt, 1);
    DPSsetgray(ctxt, 0.333);
    DPSmoveto(ctxt, bounds.origin.x, bounds.origin.y);
    DPSrlineto(ctxt, 0, bounds.size.height);
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

//
// Event Handling
//
- (void)performActionWithHighlightingForItemAtIndex: (int)index
{
  NSMenu     *candidateMenu = menuv_menu;
  NSMenuView *targetMenuView;
  int         indexToHighlight = index;

  for (;;)
    {
      if (![candidateMenu supermenu] ||
	  [candidateMenu isAttached] ||
	  [candidateMenu isTornOff])
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

#define MOVE_THRESHOLD_DELTA 1.0
#define DELAY_MULTIPLIER     12

- (BOOL)trackWithEvent: (NSEvent *)event
{
  NSApplication *theApp           = [NSApplication sharedApplication];  
  unsigned       eventMask        = NSLeftMouseUpMask 
			          | NSLeftMouseDraggedMask
                                  | NSPeriodicMask;
  NSDate        *theDistantFuture = [NSDate distantFuture];

  int      index;
  NSPoint  location;
  NSPoint  lastLocation = {0,0};
  NSMenu  *alreadyAttachedMenu = NO;
  BOOL     delayedSelect = NO;
  int      delayCount = DELAY_MULTIPLIER;

  do
    {
      location     = [window mouseLocationOutsideOfEventStream];
      index        = [self indexOfItemAtPoint: location];

      if ([event type] == NSPeriodic)
	{
	  if ([menuv_menu isPartlyOffScreen])
	    {
	      NSPoint pointerLoc = [window convertBaseToScreen:
					     location];

	      // TODO: Why 1 in the Y axis?
	      if (pointerLoc.x == 0 || pointerLoc.y == 1 ||
		  pointerLoc.x == [[window screen] frame].size.width
		  - 1)
		[menuv_menu shiftOnScreen];
	    }

	  if ([event type] == NSPeriodic && delayedSelect && !delayCount)
	    {
	      if (location.x - lastLocation.x < MOVE_THRESHOLD_DELTA ||
		  abs(location.y - lastLocation.y) < MOVE_THRESHOLD_DELTA)
		delayedSelect = NO;

	      lastLocation = location;
	    }

	  delayCount   = delayCount ? --delayCount : DELAY_MULTIPLIER;
	}

      if (index == -1)
	{
	  if ([menuv_menu attachedMenu])
	    {
	      if ([[self attachedMenuView] trackWithEvent: event])
		return YES;
	    }
	  else
	    {
	      if (index != menuv_highlightedItemIndex)
		[self setHighlightedItemIndex: index];
	    }

	  if (([menuv_menu supermenu] && ![menuv_menu isTornOff])
	      || [menuv_menu isFollowTransient])
	    return NO;
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
		      delayedSelect = YES;
		      delayCount    = DELAY_MULTIPLIER;
		    }
		  else
		    {
		      delayedSelect = NO;
		    }
		}
	    }
	}

      event = [theApp nextEventMatchingMask: eventMask
		                  untilDate: theDistantFuture
		                     inMode: NSEventTrackingRunLoopMode
		                    dequeue: YES];
    }
  while ([event type] != NSLeftMouseUp);

  // Perform actions as needed.
  if (index != -1 && !alreadyAttachedMenu)
    {
      // Stop the periodic events before performing the action
      [NSEvent stopPeriodicEvents];
      [menuv_menu performActionForItemAtIndex: index];

      if (![menuv_menu isFollowTransient])
	[self setHighlightedItemIndex: -1];
    }

  // Close menus if needed.
  if (!menuv_keepAttachedMenus ||
      index == -1 ||
      (alreadyAttachedMenu && [alreadyAttachedMenu isFollowTransient]))
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

- (void)mouseDown: (NSEvent *)theEvent
{
  NSMenu     *candidateMenu;
  NSMenu     *masterMenu;
  NSMenuView *masterMenuView;
  NSPoint     originalLocation;

  menuv_keepAttachedMenus = YES;

  for (candidateMenu = masterMenu = menuv_menu;
       (candidateMenu = [masterMenu supermenu])
	 && (![masterMenu isTornOff] || [masterMenu isFollowTransient]);
       masterMenu = candidateMenu);

  originalLocation = [[masterMenu window] frame].origin;

  masterMenuView = [masterMenu menuRepresentation];

  masterMenuView->menuv_keepAttachedMenus = YES;

  [NSEvent startPeriodicEventsAfterDelay: 0.2 withPeriod: 0.05];

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

-(BOOL) performKeyEquivalent: (NSEvent *)theEvent
{
  return [menuv_menu performKeyEquivalent: theEvent];
}

//
// NSCoding Protocol
//
- (void)encodeWithCoder:(NSCoder *)encoder
{
  [super encodeWithCoder: encoder];

  [encoder encodeObject: menuv_itemCells];
  [encoder encodeObject: menuv_font];
  [encoder encodeConditionalObject: menuv_menu];
  [encoder encodeConditionalObject: menuv_items_link];
  [encoder encodeValueOfObjCType: @encode(BOOL) at: &menuv_horizontal];
  [encoder encodeValueOfObjCType: @encode(float) at: &menuv_horizontalEdgePad];
  [encoder encodeValueOfObjCType: @encode(NSSize) at: &cellSize];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder: decoder];

  menuv_itemCells  = [decoder decodeObject];
  menuv_font       = [decoder decodeObject];
  menuv_menu       = [decoder decodeObject];
  menuv_items_link = [decoder decodeObject];
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &menuv_horizontal];
  [decoder decodeValueOfObjCType: @encode(float) at: &menuv_horizontalEdgePad];
  [decoder decodeValueOfObjCType: @encode(NSSize) at: &cellSize];

  menuv_highlightedItemIndex = -1;
  menuv_needsSizing = YES;

  return self;
}

@end
