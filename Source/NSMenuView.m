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

#include <Foundation/NSRunLoop.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>

#include <Foundation/NSDebug.h>

#include <AppKit/NSImage.h>

/*
  NSMenuView contains:

  a) Title, if needed, this is a subview
  b) menu items


*/
/* A menu's title is an instance of this class */
@class NSButton;

@interface NSMenuWindowTitleView : NSView
{
  NSMenu *menu;
  NSButton *button;
}

- (void) addCloseButton;
- (void) removeCloseButton;
- (void) createButton;
- (void) setMenu: (NSMenu*)menu;
- (NSMenu*) menu;

@end

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
// We do not want to popup menus in this menu.
- (id) menuForEvent: (NSEvent*) theEvent
{
  NSDebugLLog (@"NSMenu", @"Query for menu in view");
  return nil;
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

  // Create title view and add it.  CHECKME, should we do this here?
  _titleView = [[NSMenuWindowTitleView alloc] init];

  [self addSubview: _titleView];
  
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

  [_titleView setMenu: _menu];  // WO CHECKME does this needs reorganizing?
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
  return [[_menu attachedMenu] menuRepresentation];
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

  NSDebugLLog (@"NSMenu", @"detach submenu: %@ from: %@",
               attachedMenu, _menu);
  
  if ([attachedMenu isTransient])
    {
      [attachedMenu closeTransient];
    }
  else
    {
      [attachedMenu close];
    }
}

/**
   Attach submenu if the item at index is a submenu.
   It will figure out if the new submenu should be transient
   or not.
*/
- (void) attachSubmenuForItemAtIndex: (int)index
{
  /*
   * Transient menus are used for torn-off menus, which are already on the
   * screen and for sons of transient menus.  As transients disappear as
   * soon as we release the mouse the user will be able to leave submenus
   * open on the screen and interact with other menus at the same time.
   */
  NSMenu *attachableMenu;

  if (index < 0)
    {
      return;
    }
  
  attachableMenu = [[_items_link objectAtIndex: index] submenu];

  if ([attachableMenu isTornOff] || [_menu isTransient])
    {
      NSDebugLLog (@"NSMenu",  @"Will open transient: %@", attachableMenu);
      [attachableMenu displayTransient];
      [[attachableMenu menuRepresentation] setHighlightedItemIndex: -1]; 
    }
  else
    {
      NSDebugLLog (@"NSMenu",  @"Will open normal: %@", attachableMenu);
      [attachableMenu display];
    }
}

/*
 * Calculating Menu Geometry
 */
- (void) update
{
  [_menu update];

  if ([_menu isTornOff] && ![_menu isTransient])
    {
      [_titleView addCloseButton];
    }
  else
    {
      [_titleView removeCloseButton];
    }
  
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
  unsigned i;
  unsigned howMany = [_itemCells count];
  float    neededImageAndTitleWidth = [_font widthOfString: [_menu title]];
  float    neededKeyEquivalentWidth = 0.0;
  float    neededStateImageWidth = 0.0;
  float    accumulatedOffset = 0.0;

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
      float menuBarHeight = [[self class] menuBarHeight];
      
      [self setFrameSize: NSMakeSize(_cellSize.width + _leftBorderOffset, 
	(howMany * _cellSize.height) + menuBarHeight)];
      [_titleView setFrame: NSMakeRect (0, howMany * _cellSize.height,
                                        NSWidth (_bounds), menuBarHeight)];
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
      theRect.origin.y = _cellSize.height * ([_itemCells count] - index - 1);
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

/**
   Returns the index of the item below point.
   Returns -1 if mouse is not above
   a menu item.
*/
- (int) indexOfItemAtPoint: (NSPoint)point
{
  unsigned howMany = [_itemCells count];
  unsigned i;

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
	return (int)i;
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
  if (selectedItemIndex != -1) 
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
  int        oldHighlightedIndex;
  
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

  oldHighlightedIndex = [targetMenuView highlightedItemIndex];
  [targetMenuView setHighlightedItemIndex: indexToHighlight];

  /* We need to let the run loop run a little so that the fact that
   * the item is highlighted gets displayed on screen.
   */
  [[NSRunLoop currentRunLoop] 
    runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];

  [_menu performActionForItemAtIndex: index];

  if (![_menu _ownedByPopUp])
    {
      [targetMenuView setHighlightedItemIndex: oldHighlightedIndex];
    }
}

#define MOVE_THRESHOLD_DELTA 2.0
#define DELAY_MULTIPLIER     10

/**
   This method is responsible for tracking the mouse while this menu
   is on the screen and the user is busy navigating the menu or one
   of it submenus.  Responsible does not mean that this method does it
   all.  For submenus for example it will call, indirectly, itself for
   submenu under consideration.

   It will return YES if user released mouse, not above a submenu item.
   NO in all other circumstances.

   Implementation detail:

   <list>
   <item> It use periodic events to update the highlight state
     and attach / detach submenus.
   </item>
   <item> The flag justAttachedNewSubmenu is set to YES when
     a new submenu is attached.  The effect is that the
     highlightin / attaching / detaching is surpressed
     for this menu.  This is done so the user is given
     a change to move the mouse pointer into the newly
     attached submenu.  Otherwise it would immediately
     be removed as the mouse pointer move over another
     item.

     The logic for resetting the flag is rather adhoc.

   <item> the flag subMenusNeedRemoving means that we
     will remove all the submenus after we are done.

     This flag is used to clean up the submenus
     when the user has opened a submenu by clicking
     and wants to close it again by clicking on the
     hihglighted item.
   </item>  
   <item> When the user released the mouse this method
     will cleanup all the transient menus.

     Not only its own, but also its attached menu
     and all its transient super menus.
   </item>
   <item> The clean up is done BEFORE the action is executed.
     This is needed otherwise `hiding' the application
     leaves a dangling menu.   If this is not acceptable,
     there should be another mechanism of handling
     the hiding.  BTW besides the `hiding' the application,
     model panels are also a problem when the menu
     is not cleared before executing the action.
    </item>
    </list>
*/
- (BOOL) trackWithEvent: (NSEvent*)event
{
  unsigned	eventMask = NSPeriodicMask;
  NSDate        *theDistantFuture = [NSDate distantFuture];
  NSPoint	lastLocation = {0,0};
  BOOL		justAttachedNewSubmenu = NO;
  BOOL          subMenusNeedRemoving = YES;
  int		delayCount = 0;
  int           indexOfActionToExecute = -1;
  NSEvent	*original;
  NSEventType	type;
  NSEventType	end;
  
  /*
   * The original event is unused except to determine whether the method
   * was invoked in response to a right or left mouse down.
   * We pass the same event on when we want tracking to move into a
   * submenu.
   */
  original = AUTORELEASE(RETAIN(event));

  type = [event type];

  if (type == NSRightMouseDown || type == NSRightMouseDragged)
    {
      end = NSRightMouseUp;
      eventMask |= NSRightMouseUpMask | NSRightMouseDraggedMask;
    }
  else if (type == NSOtherMouseDown || type == NSOtherMouseDragged)
    {
      end = NSOtherMouseUp;
      eventMask |= NSOtherMouseUpMask | NSOtherMouseDraggedMask;
    }
  else if (type == NSLeftMouseDown || type == NSLeftMouseDragged)
    {
      end = NSLeftMouseUp;
      eventMask |= NSLeftMouseUpMask | NSLeftMouseDraggedMask;
    }
  else
    {
      NSLog (@"Unexpected event: %d during event tracking in NSMenuView", type);
      end = NSLeftMouseUp;
      eventMask |= NSLeftMouseUpMask | NSLeftMouseDraggedMask;
    }
  
  do
    {
      if (type == NSPeriodic || event == original)
	{
          NSPoint	location;
          int           index;
          
          location     = [_window mouseLocationOutsideOfEventStream];
          index        = [self indexOfItemAtPoint: location];

	  /*
           * 1 - if menus is only partly visible and the mouse is at the
           *     edge of the screen we move the menu so it will be visible.
           */ 
	  if ([_menu isPartlyOffScreen])
	    {
	      NSPoint pointerLoc = [_window convertBaseToScreen: location];
              /*
	       * The +/-1 in the y - direction is because the flipping
	       * between X-coordinates and GNUstep coordinates let the
	       * GNUstep screen coordinates start with 1.
	       */
	      if (pointerLoc.x == 0 || pointerLoc.y == 1
                  || pointerLoc.x == [[_window screen] frame].size.width - 1
                  || pointerLoc.y == [[_window screen] frame].size.height)
		[_menu shiftOnScreen];
	    }


          /*
	   * 2 - Check if we have to reset the justAttachedNewSubmenu
	   * flag to NO.
	   */
          if (justAttachedNewSubmenu && index != -1
	    && index != _highlightedItemIndex)
            { 
              if (location.x - lastLocation.x > MOVE_THRESHOLD_DELTA)
                {
                  delayCount ++;
                  if (delayCount >= DELAY_MULTIPLIER)
                    {
                      justAttachedNewSubmenu = NO;
                    }
                }
              else
                {
                  justAttachedNewSubmenu = NO;
                }
            }


          // 3 - If we have moved outside this menu, take appropriate action
          if (index == -1)
            {
              NSPoint   locationInScreenCoordinates;
              NSWindow *windowUnderMouse;
              NSMenu   *candidateMenu;
              
              subMenusNeedRemoving = NO;
              
              locationInScreenCoordinates
		= [_window convertBaseToScreen: location];

	      /*
               * 3a - Check if moved into one of the ancester menus.
               *      This is tricky, there are a few possibilities:
               *          We are a transient attached menu of a
	       *          non-transient menu
               *          We are a non-transient attached menu
               *          We are a root: isTornOff of AppMenu
	       */
              candidateMenu = [_menu supermenu];
              while (candidateMenu  
		&& !NSMouseInRect (locationInScreenCoordinates, [[candidateMenu window] frame], NO) // not found yet
		&& (! ([candidateMenu isTornOff] && ![candidateMenu isTransient]))  // no root of display tree
		&& [candidateMenu isAttached]) // has displayed parent
                {
                  candidateMenu = [candidateMenu supermenu];
                }
              
              if (candidateMenu != nil
		&& NSMouseInRect (locationInScreenCoordinates,
		  [[candidateMenu window] frame], NO))
                {
                  // The call to fetch attachedMenu is not needed.  But putting
                  // it here avoids flicker when we go back to an ancester meu
                  // and the attached menu is alreay correct.
                  [[[candidateMenu attachedMenu] menuRepresentation]
		    detachSubmenu];
                  return [[candidateMenu menuRepresentation]
                           trackWithEvent: original];
                }

              // 3b - Check if we enter the attached submenu
              windowUnderMouse = [[_menu attachedMenu] window];
              if (windowUnderMouse != nil
		&& NSMouseInRect (locationInScreenCoordinates,
		  [windowUnderMouse frame], NO))
                {
                  BOOL wasTransient = [_menu isTransient];
                  BOOL subMenuResult;
                  
                  subMenuResult
		    = [[self attachedMenuView] trackWithEvent: original];
                  if (subMenuResult && wasTransient == [_menu isTransient])
                    {
                      [self detachSubmenu];
                    }
                  return subMenuResult;
                }
            }
          
          // 4 - We changed the selected item and should update.
          if (!justAttachedNewSubmenu && index != _highlightedItemIndex)
            {
              subMenusNeedRemoving = NO;
              [self detachSubmenu];
              [self setHighlightedItemIndex: index];

              // WO: Question?  Why the ivar _items_link
              if (index >= 0 && [[_items_link objectAtIndex: index] submenu])
                {
                  [self attachSubmenuForItemAtIndex: index];
                  justAttachedNewSubmenu = YES;
                  delayCount = 0;
                }
            }
          
          // Update last seen location for the justAttachedNewSubmenu logic.
          lastLocation = location;
	}

      event = [NSApp nextEventMatchingMask: eventMask
		                 untilDate: theDistantFuture
		                    inMode: NSEventTrackingRunLoopMode
		                   dequeue: YES];
      type = [event type];
    }
  while (type != end);

  /*
   * Ok, we released the mouse
   * There are now a few possibilities:
   * A - We released the mouse outside the menu.
   *     Then we want the situation as it was before
   *     we entered everything.
   * B - We released the mouse on a submenu item
   *     (i) - this was highlighted before we started clicking:
   *           Remove attached menus
   *     (ii) - this was not highlighted before pressed the mouse button;
   *            Keep attached menus.
   * C - We released the mouse above an ordinary action:
   *     Execute the action.
   *
   *  In case A, B and C we want the transient menus to be removed
   *  In case A and C we want to remove the menus that were created
   *  during the dragging.
   *
   *  So we should do the following things:
   * 
   * 1 - Stop periodic events,
   * 2 - Determine the action.
   * 3 - Remove the Transient menus from the screen.
   * 4 - Perform the action if there is one.
   */
  
  [NSEvent stopPeriodicEvents];

  /*
   * We need to store this, because _highlightedItemIndex
   * will not be valid after we removed this menu from the screen.
   */
  indexOfActionToExecute = _highlightedItemIndex;
  
  // remove transient menus. --------------------------------------------
  {
    NSMenu *currentMenu = _menu;

    while (currentMenu && ![currentMenu isTransient])
      {
        currentMenu = [currentMenu attachedMenu];
      }
    
    while ([currentMenu isTransient] &&
           [currentMenu supermenu])
      {
        currentMenu = [currentMenu supermenu];
      }

    [[currentMenu menuRepresentation] detachSubmenu];
    
    if ([currentMenu isTransient])
      {
        [currentMenu closeTransient];
      }
  }

  // ---------------------------------------------------------------------
  if (indexOfActionToExecute == -1)
    {
      return YES;
    }
  
  if (indexOfActionToExecute >= 0
      && [_menu attachedMenu] != nil && [_menu attachedMenu] ==
      [[_items_link objectAtIndex: indexOfActionToExecute] submenu])
    {
      if (subMenusNeedRemoving)
        {
          [self detachSubmenu];
        }
      // Clicked on a submenu.
      return NO;
    }

  [_menu performActionForItemAtIndex: indexOfActionToExecute];

  /*
   * Remove highlighting.
   * We first check if it still highlighted because it could be the
   * case that we choose an action in a transient window which
   * has already dissappeared.  
   */
  if (indexOfActionToExecute == _highlightedItemIndex)
    {
      [self setHighlightedItemIndex: -1];
    }
  return YES;
}

/**
   This method is called when the user clicks on a button
   in the menu.  Or, if a right click happens and the
   app menu is brought up.

   The original position is stored, so we can restore
   the position of menu.  The position of the menu
   can change during the event tracking because
   the menu will automatillay move when parts
   are outside the screen and the user move the
   mouse pointer to the edge of the screen.
*/
- (void) mouseDown: (NSEvent*)theEvent
{
  NSRect	currentFrame;
  NSRect	originalFrame;
  NSPoint	currentTopLeft;
  NSPoint	originalTopLeft;
  BOOL          restorePosition;
  /*
   * Only for non transient menus do we want
   * to remember the position.
   */ 
  restorePosition = ![_menu isTransient];

  if (restorePosition)
    { // store old position;
      originalFrame = [_window frame];
      originalTopLeft = originalFrame.origin;
      originalTopLeft.y += originalFrame.size.height;
    }
  
  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.05];
  [self trackWithEvent: theEvent];
  [NSEvent stopPeriodicEvents];

  if (restorePosition)
    {
      currentFrame = [_window frame];
      currentTopLeft = currentFrame.origin;
      currentTopLeft.y += currentFrame.size.height;

      if (NSEqualPoints(currentTopLeft, originalTopLeft) == NO)
        {
          NSPoint	origin = currentFrame.origin;
          
          origin.x += (originalTopLeft.x - currentTopLeft.x);
          origin.y += (originalTopLeft.y - currentTopLeft.y);
          [_menu nestedSetFrameOrigin: origin];
        }
    }
}

- (void) rightMouseDown: (NSEvent*) theEvent
{
  [self mouseDown: theEvent];
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

@implementation NSMenuWindowTitleView

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
} 
 
- (void) setMenu: (NSMenu*)aMenu
{
  menu = aMenu;
}

- (NSMenu*) menu
{
  return menu;
}
  
- (void) drawRect: (NSRect)rect
{
  NSRect workRect = [self bounds];
  NSSize titleSize;
  NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge};
  float grays[] = {NSDarkGray, NSDarkGray};
  /* Cache the title attributes */
  static NSDictionary *attr = nil;

  // Draw the dark gray upper left lines.
  workRect = NSDrawTiledRects(workRect, workRect, sides, grays, 2);
  
  // Draw the title box's button.
  NSDrawButton(workRect, workRect);
  
  // Paint it Black!
  workRect.origin.x += 1;
  workRect.origin.y += 2;
  workRect.size.height -= 3;
  workRect.size.width -= 3;
  [[NSColor windowFrameColor] set];
  NSRectFill(workRect);

  // Draw the title
  if (attr == nil)
    {
      attr = [[NSDictionary alloc] 
	       initWithObjectsAndKeys: 
		 [NSFont boldSystemFontOfSize: 0], NSFontAttributeName,
	       [NSColor windowFrameTextColor], NSForegroundColorAttributeName,
	       nil];
    }

  titleSize = [[menu title] sizeWithAttributes: attr];
  workRect.origin.x += 5;
  workRect.origin.y = NSMidY (workRect) - titleSize.height / 2;
  workRect.size.height = titleSize.height;
  [[menu title] drawInRect: workRect  withAttributes: attr];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSPoint		lastLocation;
  NSPoint		location;
  unsigned		eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
  BOOL			done = NO;
  NSDate		*theDistantFuture = [NSDate distantFuture];

  NSDebugLLog (@"NSMenu", @"Mouse down in title!");
  
  lastLocation = [theEvent locationInWindow];
   
  if (![menu isTornOff] && [menu supermenu])
    {
      [menu setTornOff: YES];
    }

  while (!done)
    {
      theEvent = [NSApp nextEventMatchingMask: eventMask
                                     untilDate: theDistantFuture
                                        inMode: NSEventTrackingRunLoopMode
                                       dequeue: YES];
  
      switch ([theEvent type])
        {
        case NSRightMouseUp:
        case NSLeftMouseUp: 
	  done = YES; 
	  break;
        case NSRightMouseDragged:
	case NSLeftMouseDragged:   
	  location = [_window mouseLocationOutsideOfEventStream];
	  if (NSEqualPoints(location, lastLocation) == NO)
	    {
	      NSPoint origin = [_window frame].origin;

	      origin.x += (location.x - lastLocation.x);
	      origin.y += (location.y - lastLocation.y);
	      [menu nestedSetFrameOrigin: origin];
	    }
	  break;
         
	default: 
	  break;
        }
    }
}

- (void) createButton
{
  // create the menu's close button
  NSImage* closeImage = [NSImage imageNamed: @"common_Close"];
  NSImage* closeHImage = [NSImage imageNamed: @"common_CloseH"];
  NSSize imageSize = [closeImage size];
  NSRect rect = { { _frame.size.width - imageSize.width - 4,
		    (_frame.size.height - imageSize.height) / 2},
		  { imageSize.height, imageSize.width } };

  button = [[NSButton alloc] initWithFrame: rect];
  [button setButtonType: NSMomentaryLight];
  [button setImagePosition: NSImageOnly];
  [button setImage: closeImage];
  [button setAlternateImage: closeHImage];
  [button setBordered: NO];
  [button setTarget: menu];
  [button setAction: @selector(_performMenuClose:)];
  [button setAutoresizingMask: NSViewMinXMargin];
  
  [self setAutoresizingMask:
    NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin];
}
            
- (void) removeCloseButton
{
  [button removeFromSuperview];
}
  
- (void) addCloseButton
{
  if (button == nil)
    [self createButton];
  [self addSubview: button];
  [self setNeedsDisplay: YES];
}


- (void) rightMouseDown: (NSEvent*)theEvent
{
}

// We do not want to popup menus in this menu.
- (id) menuForEvent: (NSEvent*) theEvent
{
  return nil;
}

@end /* NSMenuWindowTitleView */
