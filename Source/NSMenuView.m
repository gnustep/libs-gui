/** <title>NSMenuView</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: Sep 2001
   Author: David Lazaro Saz <khelekir@encomix.es>
   Date: Oct 1999
   Author: Michael Hanni <mhanni@sprintmail.com>
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


#include <Foundation/NSThread.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>

@implementation NSMenuView

static NSRect
_addLeftBorderOffsetToRect(NSRect aRect, BOOL isHorizontal)
{
  if (isHorizontal == NO)
    {
      aRect.origin.x--;
      aRect.size.width++;
    }
  else
    {
      aRect.origin.y--;
      aRect.size.height++;
    }
  return aRect;
}

/*
 * Class methods.
 */
+ (float) menuBarHeight
{
  static float height = 0.0;

  if (height == 0.0)
    {
      NSFont *font = [NSFont menuFontOfSize: 0.0];

      /* Should make up 23 for the default font */
      height = ([font boundingRectForFont].size.height) + 8;
    }

  return height;
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

- (id) initWithFrame: (NSRect)aFrame
{
  NSRect r;
  
  self = [super initWithFrame: aFrame];

  _font = RETAIN([NSFont menuFontOfSize: 0.0]);
  r = [_font boundingRectForFont];
  /* Should make up 110, 20 for default font */
  _cellSize = NSMakeSize (r.size.width * 10., r.size.height + 5.);

  _highlightedItemIndex = -1;
  _horizontalEdgePad = 4.;

  /* Set the necessary offset for the menuView. That is, how many pixels 
   * do we need for our left side border line. For regular menus this 
   * equals 1, for popups it is 0. 
   */
 _leftBorderOffset = 1;

  // Create an array to store our menu item cells.
  _itemCells = [NSMutableArray new];

  return self;
}

- (id)initAsTearOff
{
  //FIXME
  return [self init];
}

- (void) dealloc
{
  // We must remove the menu view from the menu list of observers.
  if ( _menu )
    {
      [[NSNotificationCenter defaultCenter] removeObserver: self  
					    name: nil
					    object: _menu];
    }

  RELEASE(_font);

  /* Clean the pointer to us stored into the _itemCells.  */
  [_itemCells makeObjectsPerformSelector: @selector(setMenuView:)
	      withObject: nil];

  RELEASE(_itemCells);

  [super dealloc];
}

/*
 * Getting and Setting Menu View Attributes
 */
- (void) setMenu: (NSMenu*)menu
{
  NSNotificationCenter	*theCenter = [NSNotificationCenter defaultCenter];

  if (_menu != nil)
    {
      // Remove this menu view from the old menu list of observers.
      [theCenter removeObserver: self  name: nil  object: _menu];
    }

  /* menu is retaining us, so we should not be retaining menu.  */
  _menu = menu;
  _items_link = [_menu itemArray];

  // Add this menu view to the menu's list of observers.
  [theCenter addObserver: self
                selector: @selector(itemChanged:)
                    name: NSMenuDidChangeItemNotification
                  object: _menu];

  [theCenter addObserver: self
                selector: @selector(itemAdded:)
                    name: NSMenuDidAddItemNotification
                  object: _menu];

  [theCenter addObserver: self
                selector: @selector(itemRemoved:)
                    name: NSMenuDidRemoveItemNotification
                  object: _menu];

  // Force menu view's layout to be recalculated.
  [self setNeedsSizing: YES];
}

- (NSMenu*) menu
{
  return _menu;
}

- (void) setHorizontal: (BOOL)flag
{
  _horizontal = flag;
}

- (BOOL) isHorizontal
{
  return _horizontal;
}

- (void) setFont: (NSFont*)font
{
  ASSIGN(_font, font);
}

- (NSFont*) font
{
  return _font;
}

- (void) setHighlightedItemIndex: (int)index
{
  NSMenuItemCell *aCell;

  if (index == _highlightedItemIndex)
    return;

  // Unhighlight old
  if (_highlightedItemIndex != -1)
    {
      aCell  = [_itemCells objectAtIndex: _highlightedItemIndex];
      [aCell setHighlighted: NO];
      [self setNeedsDisplayForItemAtIndex: _highlightedItemIndex];
    }

  // Set ivar to new index.
  _highlightedItemIndex = index;

  // Highlight new
  if (_highlightedItemIndex != -1) 
    {
      aCell  = [_itemCells objectAtIndex: _highlightedItemIndex];
      [aCell setHighlighted: YES];
      [self setNeedsDisplayForItemAtIndex: _highlightedItemIndex];
    } 
}

- (int) highlightedItemIndex
{
  return _highlightedItemIndex;
}

- (void) setMenuItemCell: (NSMenuItemCell *)cell
	  forItemAtIndex: (int)index
{
  NSMenuItem *anItem = [_items_link objectAtIndex: index];
  
  [_itemCells replaceObjectAtIndex: index withObject: cell];

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
  return [_itemCells objectAtIndex: index];
}

- (NSMenuView*) attachedMenuView
{
  NSMenu *attachedMenu;

  if ((attachedMenu = [_menu attachedMenu]))
    return [attachedMenu menuRepresentation];
  else
    return nil;
}

- (NSMenu*) attachedMenu
{
  return [_menu attachedMenu];
}

- (BOOL) isAttached
{
  return [_menu isAttached];
}

- (BOOL) isTornOff
{
  return [_menu isTornOff];
}

- (void) setHorizontalEdgePadding: (float)pad
{
  _horizontalEdgePad = pad;
}

- (float) horizontalEdgePadding
{
  return _horizontalEdgePad;
}

/*
 * Notification Methods
 */
- (void) itemChanged: (NSNotification*)notification
{
  int index = [[[notification userInfo] objectForKey: @"NSMenuItemIndex"]
		intValue];

  // Mark the cell associated with the item as needing resizing.
  [[_itemCells objectAtIndex: index] setNeedsSizing: YES];

  // Mark the menu view as needing to be resized.
  [self setNeedsSizing: YES];
}

- (void) itemAdded: (NSNotification*)notification
{
  int         index  = [[[notification userInfo]
			  objectForKey: @"NSMenuItemIndex"] intValue];
  NSMenuItem *anItem = [_items_link objectAtIndex: index];
  id          aCell  = [NSMenuItemCell new];
  int wasHighlighted = _highlightedItemIndex;

  [aCell setMenuItem: anItem];
  [aCell setMenuView: self];
  [aCell setFont: _font];

  /* Unlight the previous highlighted cell if the index of the highlighted
   * cell will be ruined up by the insertion of the new cell.  */
  if (wasHighlighted >= index)
    {
      [self setHighlightedItemIndex: -1];
    }
  
  [_itemCells insertObject: aCell atIndex: index];
  
  /* Restore the highlighted cell, with the new index for it.  */
  if (wasHighlighted >= index)
    {
      /* Please note that if wasHighlighted == -1, it shouldn't be possible
       * to be here.  */
      [self setHighlightedItemIndex: ++wasHighlighted];
    }

  [aCell setNeedsSizing: YES];
  RELEASE(aCell);

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
  [_itemCells removeObjectAtIndex: index];

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
  NSMenu     *attachedMenu = [_menu attachedMenu];
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
  NSMenu *attachableMenu = [[_items_link objectAtIndex: index] submenu];

  if ([attachableMenu isTornOff] || [_menu isFollowTransient])
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
  [_menu update];

  if (_needsSizing)
    [self sizeToFit];
}

- (void) setNeedsSizing: (BOOL)flag
{
  _needsSizing = flag;
}

- (BOOL) needsSizing
{
  return _needsSizing;
}

- (void) sizeToFit
{
  unsigned	i;
  unsigned	howMany = [_itemCells count];
  float		neededImageAndTitleWidth = [_font widthOfString: 
							   [_menu title]] + 17;
  float		neededKeyEquivalentWidth = 0.0;
  float		neededStateImageWidth = 0.0;
  float		accumulatedOffset = 0.0;

  /* Set the necessary offset for the menuView. That is, how many pixels 
   * do we need for our left side border line. For regular menus this 
   * equals 1, for popups it is 0. 
   *
   * Why here? I could not think of a better place. I figure that everyone 
   * should sizeToFit their popup/menu before using it so we should get 
   * this set properly fairly early.
   */
  if ([_menu _ownedByPopUp])
    _leftBorderOffset = 0;

  // TODO: Optimize this loop.
  for (i = 0; i < howMany; i++)
    {
      float		anImageAndTitleWidth;
      float		anImageWidth;
      float		aKeyEquivalentWidth;
      float		aStateImageWidth;
      float		aTitleWidth;
      NSMenuItemCell	*aCell = [_itemCells objectAtIndex: i];

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
  _stateImageWidth = neededStateImageWidth;
  _imageAndTitleWidth = neededImageAndTitleWidth;
  _keyEqWidth = neededKeyEquivalentWidth;

  // Calculate the offsets and cache them.
  _stateImageOffset = _imageAndTitleOffset = accumulatedOffset 
    = _horizontalEdgePad;
  accumulatedOffset += 2 * _horizontalEdgePad + neededImageAndTitleWidth;

  _keyEqOffset = accumulatedOffset += _horizontalEdgePad;
  accumulatedOffset += neededKeyEquivalentWidth + _horizontalEdgePad;

  // Calculate frame size.
  if (![_menu _ownedByPopUp])
    {
      _cellSize.width = accumulatedOffset + 3; // Add the border width
    }

  if (_horizontal == NO)
    {
      [self setFrameSize: NSMakeSize(_cellSize.width + _leftBorderOffset, 
				     (howMany * _cellSize.height))];
    }
  else
    {
      [self setFrameSize: NSMakeSize((howMany * _cellSize.width), 
				     _cellSize.height + _leftBorderOffset)];
    }

  _needsSizing = NO;
}

- (float) stateImageOffset
{
  if (_needsSizing)
    [self sizeToFit];

  return _stateImageOffset;
}

- (float) stateImageWidth
{
  if (_needsSizing)
    [self sizeToFit];

  return _stateImageWidth;
}

- (float) imageAndTitleOffset
{
  if (_needsSizing)
    [self sizeToFit];

  return _imageAndTitleOffset;
}

- (float) imageAndTitleWidth
{
  if (_needsSizing)
    [self sizeToFit];

  return _imageAndTitleWidth;
}

- (float) keyEquivalentOffset
{
  if (_needsSizing)
    [self sizeToFit];

  return _keyEqOffset;
}

- (float) keyEquivalentWidth
{
  if (_needsSizing)
    [self sizeToFit];

  return _keyEqWidth;
}

- (NSRect) innerRect
{
  if (_horizontal == NO)
    {
      return NSMakeRect(_bounds.origin.x + _leftBorderOffset, _bounds.origin.y,
			_bounds.size.width - _leftBorderOffset, _bounds.size.height);
    }
  else
    {
      return NSMakeRect(_bounds.origin.x, _bounds.origin.y +  _leftBorderOffset,
			_bounds.size.width, _bounds.size.height - _leftBorderOffset);
    }
}

- (NSRect) rectOfItemAtIndex: (int)index
{
  NSRect theRect;

  if (_needsSizing == YES)
    {
      [self sizeToFit];
    }

  /* When we are a normal menu we fiddle with the origin so that the item 
   * rect is shifted 1 pixel over so we do not draw on the heavy line at 
   * origin.x = 0. However, for popups we don't want this modification of 
   * our rect so our _leftBorderOffset = 0 (set in sizeToFit).
   */
  if (_horizontal == NO)
    {
      theRect.origin.y = _bounds.size.height - (_cellSize.height * (index + 1));
      theRect.origin.x = _leftBorderOffset;
    }
  else
    {
      theRect.origin.x = _cellSize.width * index;
      theRect.origin.y = _leftBorderOffset;
    }

  theRect.size = _cellSize;

  /* NOTE: This returns the correct NSRect for drawing cells, but nothing 
   * else (unless we are a popup). This rect will have to be modified for 
   * event calculation, etc..
   */
  return theRect;
}

- (int) indexOfItemAtPoint: (NSPoint)point
{
  unsigned howMany = [_itemCells count];
  int i;

  for (i = 0; i < howMany; i++)
    {
      NSRect aRect = [self rectOfItemAtIndex: i];

      /* We need to modify the rect to take into account the modifications 
       * to origin made by [-rectOfItemAtIndex:] in order to return an 
       * item clicked at the left hand margin. However, for a popup this 
       * calculation is unnecessary since we have no extra margin.
       */
      if (![_menu _ownedByPopUp])
        aRect = _addLeftBorderOffsetToRect(aRect, _horizontal);

      if (NSMouseInRect(point, aRect, NO))
	return i;
    }

  return -1;
}

- (void) setNeedsDisplayForItemAtIndex: (int)index
{
  NSRect aRect;

  aRect = [self rectOfItemAtIndex: index];

  /* We need to modify the rect to take into account the modifications 
   * to origin made by [-rectOfItemAtIndex:] in order to return an 
   * item clicked at the left hand margin. However, for a popup this 
   * calculation is unnecessary since we have no extra margin.
   */
  if (![_menu _ownedByPopUp])
    aRect = _addLeftBorderOffsetToRect(aRect, _horizontal);

  [self setNeedsDisplayInRect: aRect];
}

/**
   Returns the correct frame origin for aSubmenu based on the location
   of the receiver. This location may depend on the current NSInterfaceStyle.
*/
- (NSPoint) locationForSubmenu: (NSMenu *)aSubmenu
{
  NSRect frame = [_window frame];
  NSRect submenuFrame;

  if (_needsSizing)
    [self sizeToFit];

  if (aSubmenu)
    submenuFrame = [[[aSubmenu menuRepresentation] window] frame];
  else
    submenuFrame = NSZeroRect;

  if (_horizontal == NO)
    {
      if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil)
	  == GSWindowMakerInterfaceStyle)
        {
	  NSRect aRect = [self rectOfItemAtIndex: 
				   [_menu indexOfItemWithSubmenu: aSubmenu]];
	  NSPoint subOrigin = [_window convertBaseToScreen: 
					   NSMakePoint(aRect.origin.x,
						       aRect.origin.y)];
	  
	  return NSMakePoint (NSMaxX(frame),
			      subOrigin.y - NSHeight(submenuFrame) - 3 +
			                    2*[NSMenuView menuBarHeight]);
	}
      else
        {
	  return NSMakePoint(NSMaxX(frame),
			     NSMaxY(frame) - NSHeight(submenuFrame));
	}
    }
  else 
    {
      NSRect aRect = [self rectOfItemAtIndex: 
			       [_menu indexOfItemWithSubmenu: aSubmenu]];
      NSPoint subOrigin = [_window convertBaseToScreen: 
				       NSMakePoint(NSMinX(aRect),
						   NSMaxY(aRect))];
      return NSMakePoint(subOrigin.x, 
			 subOrigin.y - NSHeight(submenuFrame));
    }
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
  NSRect cellFrame;
  NSRect screenFrame;
  int items = [_itemCells count];

  // Convert the screen rect to our view
  cellFrame.size = screenRect.size;
  cellFrame.origin = [_window convertScreenToBase: screenRect.origin];
  cellFrame = [self convertRect: cellFrame fromView: nil];

  _cellSize = cellFrame.size;
  [self sizeToFit];

  /*
   * Compute the frame
   */
  screenFrame = screenRect;
  if (items > 1)
    {
      float f;

      if (_horizontal == NO)
	{
	    f = screenRect.size.height * (items - 1);
	    screenFrame.size.height += f;
	    screenFrame.origin.y -= f;
	}
      else
        {
	    f = screenRect.size.width * (items - 1);
	    screenFrame.size.width += f;
	}
    }  

  // Move the menu window to screen?
  // TODO

  // Compute position for popups, if needed
  if (selectedItemIndex > -1)
    {
      if (_horizontal == NO)
        {
	  screenFrame.origin.y += screenRect.size.height * selectedItemIndex;
	}
      else
        {
	  screenFrame.origin.x -= screenRect.size.width * selectedItemIndex;
	}
    }
  
  // Get the frameRect
  r = [NSWindow frameRectForContentRect: screenFrame
		styleMask: [_window styleMask]];
  
  // Update position,if needed, using the preferredEdge;
  // TODO

  // Set the window frame
  [_window setFrame: r display: NO]; 
}

/*
 * Drawing.
 */
- (void) drawRect: (NSRect)rect
{
  int    i;
  int    howMany = [_itemCells count];

  /* For popupButtons we do not want this dark line. */

  if (![_menu _ownedByPopUp])
    {
      NSGraphicsContext *ctxt = GSCurrentContext();

      // Draw a dark gray line at the left of the menu item cells.
      DPSgsave(ctxt);
      DPSsetlinewidth(ctxt, 1);
      DPSsetgray(ctxt, NSDarkGray);
      if (_horizontal == NO)
        {
	  DPSmoveto(ctxt, NSMinX(_bounds), NSMinY(_bounds));
	  DPSrlineto(ctxt, 0, _bounds.size.height);
        }
      else
        {
	  DPSmoveto(ctxt, NSMinX(_bounds), NSMaxY(_bounds));
	  DPSrlineto(ctxt, _bounds.size.width, 0);
        }
      DPSstroke(ctxt);
      DPSgrestore(ctxt);
    }

  // Draw the menu cells.
  for (i = 0; i < howMany; i++)
    {
      NSRect		aRect;
      NSMenuItemCell	*aCell;

      aRect = [self rectOfItemAtIndex: i];
      if (NSIntersectsRect(rect, aRect) == YES)
        {
          aCell = [_itemCells objectAtIndex: i];
	  [aCell drawWithFrame: aRect inView: self];
        }
    }
}

/*
 * Event Handling
 */
- (void) performActionWithHighlightingForItemAtIndex: (int)index
{
  NSMenu     *candidateMenu = _menu;
  NSMenuView *targetMenuView;
  int        indexToHighlight = index;

  for (;;)
    {
      NSMenu *superMenu = [candidateMenu supermenu];

      if (superMenu == nil
	|| [candidateMenu isAttached]
	|| [candidateMenu isTornOff])
	{
	  targetMenuView = [candidateMenu menuRepresentation];

	  break;
	}
      else
	{
	  indexToHighlight = [superMenu indexOfItemWithSubmenu: candidateMenu];
	  candidateMenu = superMenu;
	}
    }

  if ([targetMenuView attachedMenu])
    [targetMenuView detachSubmenu];

  [targetMenuView setHighlightedItemIndex: indexToHighlight];

  [_menu performActionForItemAtIndex: index];
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
  else if (type == NSOtherMouseDown)
    {
      end = NSOtherMouseUp;
      eventMask |= NSOtherMouseUpMask | NSOtherMouseDraggedMask;
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

      if (index != _highlightedItemIndex)
	{
	  mouseMoved = YES;	/* Ok - had an initial movement. */
	}
      if (type == NSPeriodic)
	{
	  if ([_menu isPartlyOffScreen])
	    {
	      NSPoint pointerLoc = [_window convertBaseToScreen: location];

	      // TODO: Why 1 in the Y axis?
	      if (pointerLoc.x == 0 || pointerLoc.y == 1
		|| pointerLoc.x == [[_window screen] frame].size.width - 1)
		[_menu shiftOnScreen];
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
	  w = [[_menu supermenu] window];
	  if (w != nil && NSMouseInRect(location, [w frame], NO) == YES)
	    {
	      return NO;
	    }
	  /*
	   * if the mouse is in our attached menu - get that menu to track it.
	   */
	  w = [[_menu attachedMenu] window];
	  if (w != nil && NSMouseInRect(location, [w frame], NO) == YES)
	    {
	      if ([[self attachedMenuView] trackWithEvent: original])
		return YES;
	    }
	  else
	    {
	      if (index != _highlightedItemIndex)
		[self setHighlightedItemIndex: index];
	    }
#if 0
	  if (([_menu supermenu] && ![_menu isTornOff])
	      || [_menu isFollowTransient])
	    return NO;
#endif
	}
      else
	{
	  if (index != _highlightedItemIndex)
	    {
	      if (![_menu attachedMenu] || !delayedSelect)
		{
		  [self setHighlightedItemIndex: index];

		  if ([_menu attachedMenu])
		    [self detachSubmenu];

		  if ((alreadyAttachedMenu =
		       [[_items_link objectAtIndex: index] submenu]))
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
      [_menu performActionForItemAtIndex: index];

      if (![_menu isFollowTransient] && ![_menu _ownedByPopUp])
	[self setHighlightedItemIndex: -1];
    }

  // Close menus if needed.
  if (!_keepAttachedMenus || index == -1
    || (alreadyAttachedMenu && [alreadyAttachedMenu isFollowTransient]))
    {
      NSMenu     *parentMenu;
      NSMenu     *masterMenu;

      for (parentMenu = masterMenu = _menu;
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
  NSRect	currentFrame;
  NSRect	originalFrame;
  NSPoint	currentTopLeft;
  NSPoint	originalTopLeft;

  _keepAttachedMenus = YES;
  originalFrame = [_window frame];
  originalTopLeft = originalFrame.origin;
  originalTopLeft.y += originalFrame.size.height;

  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.05];
  [self trackWithEvent: theEvent];
  [NSEvent stopPeriodicEvents];

  currentFrame = [_window frame];
  currentTopLeft = currentFrame.origin;
  currentTopLeft.y += currentFrame.size.height;

  if (NSEqualPoints(currentTopLeft, originalTopLeft) == NO)
    {
      NSPoint	origin = currentFrame.origin;

      origin.x += (originalTopLeft.x - currentTopLeft.x);
      origin.y += (originalTopLeft.y - currentTopLeft.y);
      [_menu nestedSetFrameOrigin: origin];
      [_menu nestedCheckOffScreen];
    }
  _keepAttachedMenus = NO;
}

- (BOOL) performKeyEquivalent: (NSEvent *)theEvent
{
  return [_menu performKeyEquivalent: theEvent];
}

/*
 * NSCoding Protocol
 *
 * Normally unused because NSMenu does not encode its NSMenuView since
 * NSMenuView is considered a platform specific way of rendering the menu.
 */
- (void) encodeWithCoder: (NSCoder*)encoder
{
  [super encodeWithCoder: encoder];

  [encoder encodeObject: _itemCells];
  [encoder encodeObject: _font];
  [encoder encodeValueOfObjCType: @encode(BOOL) at: &_horizontal];
  [encoder encodeValueOfObjCType: @encode(float) at: &_horizontalEdgePad];
  [encoder encodeValueOfObjCType: @encode(NSSize) at: &_cellSize];
}

- (id) initWithCoder: (NSCoder*)decoder
{
  self = [super initWithCoder: decoder];

  [decoder decodeValueOfObjCType: @encode(id) at: &_itemCells];
  
  [_itemCells makeObjectsPerformSelector: @selector(setMenuView:)
	      withObject: self];

  [decoder decodeValueOfObjCType: @encode(id) at: &_font];
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &_horizontal];
  [decoder decodeValueOfObjCType: @encode(float) at: &_horizontalEdgePad];
  [decoder decodeValueOfObjCType: @encode(NSSize) at: &_cellSize];

  _highlightedItemIndex = -1;
  _needsSizing = YES;

  return self;
}

@end

@implementation NSMenuView (GNUstepPrivate)
- (NSArray *)_itemCells
{
  return _itemCells;
}
@end
