/* 
   NSMenuView.m

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

#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>

static float GSMenuBarHeight = 25.0; // a guess.

// These private methods are used in NSPopUpButton. For NSPB we need to be
// able to init with a frame, but have a very custom cell size.

@implementation NSMenuView

// Class methods.

+ (float)menuBarHeight
{
  return GSMenuBarHeight;
}

- (BOOL)acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

// Init methods.

- (id)init
{
  return [self initWithFrame: NSZeroRect];
}

- (id)initWithFrame: (NSRect)aFrame
{
  cellSize = NSMakeSize(110,20);
  i_titleWidth = 110;
  menuv_highlightedItemIndex = -1;

  return [super initWithFrame: aFrame];
}

- (id)initWithFrame: (NSRect)aFrame
 	   cellSize: (NSSize)aSize
{
  [self initWithFrame:aFrame];

  cellSize = aSize;

  return self;
}

// Our menu.

- (void)setMenu: (NSMenu *)menu
{
  ASSIGN(menuv_menu, menu);
  menuv_items_link = [menuv_menu itemArray];
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

/* 
 * - (void)setHighlightedItemIndex: (int)index
 *
 * MacOS-X defines this function as the central way of switching to a new
 * highlighted item. The index value is == to the item you want
 * highlighted. When used this method unhighlights the last item (if
 * applicable) and selects the new item. If index == -1 highlighting is
 * turned off.
 *
 * NOTES (Michael Hanni): 
 *
 * I modified this method for GNUstep to take submenus into account. This
 * way we get maximum performance while still using a method outside the
 * loop.
 *
 */

- (void)setHighlightedItemIndex: (int)index
{
  id anItem;

  [self lockFocus];

  if (index == -1) 
    {
      if (menuv_highlightedItemIndex != -1)
	{
	  NSRect aRect = [self rectOfItemAtIndex: menuv_highlightedItemIndex];

	  anItem  = [menuv_items_link objectAtIndex: menuv_highlightedItemIndex];
	  
	  [anItem highlight: NO
		  withFrame: aRect
		  inView: self];

	  [self setNeedsDisplayInRect: aRect];

	  [window flushWindow];

	  if ([anItem hasSubmenu] 
	      && ![[anItem target] isTornOff])
	    [[anItem target] close];
	  else if ([anItem hasSubmenu] 
		   && [[anItem target] isTornOff])
	    [[anItem target] closeTransient];

	  [anItem setState: 0];
	  menuv_highlightedItemIndex = -1;
	}
    } 
  else if (index >= 0) 
    {
      if ( menuv_highlightedItemIndex != -1)
	{
	  NSRect aRect = [self rectOfItemAtIndex: menuv_highlightedItemIndex];

	  anItem  = [menuv_items_link objectAtIndex: menuv_highlightedItemIndex];

	  [anItem highlight: NO
		  withFrame: aRect
		  inView: self];

	  [self setNeedsDisplayInRect: aRect]; 

	  [window flushWindow];

	  if ([anItem hasSubmenu] 
	      && ![[anItem target] isTornOff])
	    [[anItem target] close];
	  else if ([anItem hasSubmenu] 
		   && [[anItem target] isTornOff])
	    [[anItem target] closeTransient];

	  [anItem setState: 0];
	}

      if (index != menuv_highlightedItemIndex)
	{
	  anItem = [menuv_items_link objectAtIndex: index];

	  if ([anItem isEnabled])
	    {
	      NSRect aRect = [self rectOfItemAtIndex: index];

	      [anItem highlight: YES
		      withFrame: aRect
		      inView: self];
	      [self setNeedsDisplayInRect: aRect]; 

	      [window flushWindow];

	      if ([anItem hasSubmenu] 
		  && ![[anItem target] isTornOff])
		[[anItem target] display];
	      else if ([anItem hasSubmenu] 
		       && [[anItem target] isTornOff])
		[[anItem target] displayTransient];

	      [anItem setState: 1];
	    }

	  // set ivar to new index
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
//  [menuv_items insertObject: cell atIndex: index];

  // resize the cell
  [cell setNeedsSizing: YES];

  // resize menuview
  [self setNeedsSizing: YES];
}

- (NSMenuItemCell *)menuItemCellForItemAtIndex: (int)index
{
  return [menuv_items_link objectAtIndex: index];
}

- (NSMenuView *)attachedMenuView
{
  return [[menuv_menu attachedMenu] menuView];
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
  menuv_hEdgePad = pad;
}

- (float)horizontalEdgePadding
{
  return menuv_hEdgePad;
}

- (void)itemChanged: (NSNotification *)notification
{
}

- (void)itemAdded: (NSNotification *)notification
{
}

- (void)itemRemoved: (NSNotification *)notification
{
}

// Submenus.

- (void)detachSubmenu
{
}

- (void)attachSubmenuForItemAtIndex: (int)index
{
  // create rect to display submenu in.

  // order window with submenu in it to front.
}

- (void)update
{
//  [menuv_menu update];

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

/*
================
-setTitleWidth:
================
*/
- (void)setTitleWidth:(float)titleWidth
{
  i_titleWidth = titleWidth;
  [self sizeToFit];
}

- (void)sizeToFit
{
  int i;
  int howMany = [menuv_items_link count];
  int howHigh = (howMany * cellSize.height);
  float neededWidth = i_titleWidth;

  for (i=0;i<howMany;i++)
  {
    float aWidth;

    NSMenuItemCell *anItem = [menuv_items_link objectAtIndex: i];
    aWidth = [anItem titleWidth];

    if (aWidth > neededWidth)
      neededWidth = aWidth;
  }

  if (![menuv_menu _isBeholdenToPopUpButton])
    cellSize.width = 7 + neededWidth + 7 + 7 + 5;

//  if ([window contentView] == self)
//    [window setContentSize: NSMakeSize(cellSize.width,howHigh)];
//  else
//  [self setFrame: NSMakeRect(0,0,cellSize.width,howHigh)];
  [self setFrameSize: NSMakeSize(cellSize.width,howHigh)];
}

- (void)sizeToFitForPopUpButton
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
  return bounds;

  // this could change if we drew menuitemcells as
  // plain rects with no bezel like in macOSX. Talk to Michael Hanni if
  // you would like to see this configurable.
}

- (NSRect)rectOfItemAtIndex: (int)index
{
  NSRect theRect;

  if (menuv_needsSizing)
    [self sizeToFit];

  if (index == 0)
    theRect.origin.y = frame.size.height - cellSize.height;
  else
    theRect.origin.y = frame.size.height - (cellSize.height * (index + 1));
  theRect.origin.x = 0;
  theRect.size = cellSize;

  return theRect;
}

- (int)indexOfItemAtPoint: (NSPoint)point
{
  // The MacOSX API says that this method calls - rectOfItemAtIndex for
  // *every* cell to figure this out. Well, instead we will just do some
  // simple math. (NOTE: if we get horizontal methods we will have to do
  // this. Very much like NSTabView.
  NSRect aRect = [self rectOfItemAtIndex: 0];

  // this will need some finnessing but should be close.
  return (frame.size.height - point.y) / aRect.size.height;
}

- (void)setNeedsDisplayForItemAtIndex: (int)index
{
  [[menuv_items_link objectAtIndex: index] setNeedsDisplay: YES];  
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
  // huh.
}

// Drawing.
 
- (void)drawRect: (NSRect)rect
{
  int i;
  NSRect aRect = frame;
  int howMany = [menuv_items_link count];

  // This code currently doesn't take intercell spacing into account. I'll
  // need to fix that.

  aRect.origin.y = cellSize.height * (howMany - 1);
  aRect.size = cellSize;

  for (i=0;i<howMany;i++)
  {
    id aCell = [menuv_items_link objectAtIndex: i];

    [aCell drawWithFrame: aRect inView: self];
    aRect.origin.y -= cellSize.height;
  }
}

// Event.

- (void)performActionWithHighlightingForItemAtIndex: (int)index
{
  // for use with key equivalents.
}

- (BOOL)trackWithEvent: (NSEvent *)event
{
  NSPoint       lastLocation = [event locationInWindow];
  float         height = frame.size.height;
  int index;
  int lastIndex = 0;
  unsigned      eventMask =   NSLeftMouseUpMask | NSLeftMouseDownMask
                            | NSRightMouseUpMask | NSRightMouseDraggedMask
			    | NSLeftMouseDraggedMask;
  BOOL          done = NO;
  NSApplication *theApp = [NSApplication sharedApplication];  
  NSDate        *theDistantFuture = [NSDate distantFuture];
  int theCount = [menuv_items_link count];
  id selectedCell;

// These 3 BOOLs are misnomers. I'll rename them later. -Michael. FIXME.

  BOOL weWereOut = NO;
  BOOL weLeftMenu = NO;
  BOOL weRightMenu = NO;

  // Get our mouse location, regardless of where it may be it the event
  // stream.

  lastLocation = [window mouseLocationOutsideOfEventStream];

  index = (height - lastLocation.y) / cellSize.height;
                                         
  if (index >= 0 && index < theCount)
    {
      if (menuv_highlightedItemIndex > -1)
        {
	  BOOL finished = NO;
	  NSMenu *aMenu = menuv_menu;

	  while (!finished)
	    { // "forward"cursive menu find.
	      if ([aMenu attachedMenu])
		{
		  aMenu = [aMenu attachedMenu];
		}
	      else
		finished = YES;
	    }

	  finished = NO;

	  while (!finished)
	    { // Recursive menu close & deselect.
	      if ([aMenu supermenu] && aMenu != menuv_menu)
		{
		  [[aMenu menuView] setHighlightedItemIndex: -1];
		  aMenu = [aMenu supermenu];
		} 
	      else
		finished = YES;

	      //	      [window flushWindow];
	    }
	}

      [self setHighlightedItemIndex: index];

      lastIndex = index;
    }
  
  while (!done)
    {
      event = [theApp nextEventMatchingMask: eventMask
				  untilDate: theDistantFuture
				     inMode: NSEventTrackingRunLoopMode
				    dequeue: YES];

      switch ([event type])
	{
	  case NSRightMouseUp: 
	  case NSLeftMouseUp: 
//	    [self setHighlightedItemIndex:-1];
	  /* right mouse up or left mouse up means we're done */
	    done = YES;
	    break;
	  case NSRightMouseDragged: 
	  case NSLeftMouseDragged: 
	    lastLocation = [window mouseLocationOutsideOfEventStream];
	    lastLocation = [self convertPoint: lastLocation fromView: nil];

#if 0
	    NSLog (@"location = (%f, %f, %f)", lastLocation.x, [window
	      frame].origin.x, [window frame].size.width);  
	    NSLog (@"location = %f (%f, %f)", lastLocation.y, [window
	      frame].origin.y, [window frame].size.height);  
#endif

	    /* If the location of the mouse is inside the window on the
	       x-axis. */

	    if (lastLocation.x > 0
	      && lastLocation.x < [window frame].size.width)
	      {

		/* Get the index from some simple math. */

		index = (height - lastLocation.y) / cellSize.height;
#if 0                                         
		NSLog (@"location = (%f, %f)",
		  lastLocation.x, lastLocation.y);  
		NSLog (@"index = %d\n", index);
#endif
		/* If the index generated above is valid, use it. */

		if (index >= 0 && index < theCount)
		  {
		    if (index != lastIndex)
		      {
			[self setHighlightedItemIndex: index];
			lastIndex = index;
		      }
		    else
		      {
			if (weWereOut)
			  {
			    [self setHighlightedItemIndex: index];
			    lastIndex = index;
			    weWereOut = NO;
			  } 
		      }
		  }

		/* If we leave the bottom or top deselect menu items in
		   the current view. This should check to see if the
		   current item, if any, has an open submenu. */

	        if (lastLocation.y > [window frame].size.height
	           || lastLocation.y < 0)
	          {
		    weWereOut = YES;
		    [self setHighlightedItemIndex: -1];
	          }

	      }

	    /* If the location of the mouse is greater than the width of
	       the current window we need to see if we should display a
	       submenu. */

	    else if (lastLocation.x > [window frame].size.width)
	      {
		NSRect aRect = [self rectOfItemAtIndex: lastIndex];
		if (lastLocation.y > aRect.origin.y
		  && lastLocation.y < aRect.origin.y + aRect.size.height
		  && [[menuv_items_link objectAtIndex: lastIndex]
		  hasSubmenu])
		  {
		    weLeftMenu = YES;
		    done = YES;
		  }
		else
		  {
		    if (![[menuv_items_link objectAtIndex: lastIndex] hasSubmenu])
		      {
		        [self setHighlightedItemIndex: -1];
		        lastIndex = index;
		        weWereOut = YES;
		        [window flushWindow];
		      }
		    else
		      {
		        weLeftMenu = YES;
		        done = YES;
		      }
		  }
	      }

	    /* If the mouse location is less than 0 we moved to the left,
	       perhaps into a supermenu? */

	    else if (lastLocation.x < 0)
	      {
		if ([menuv_menu supermenu])
		  {
		    weRightMenu = YES;
		    done = YES;
		  }
		else
		  {
		    [self setHighlightedItemIndex: -1];
		    lastIndex = index;
		    weWereOut = YES;
		    [window flushWindow];
		  }
	      }
	    else
	      {
      // FIXME, Michael. This might be needed... or not?
/* FIXME this code is just plain nasty.
      NSLog(@"This is the final else... its evil\n");
		if (lastIndex >= 0 && lastIndex < theCount)
		  {
		    [self setHighlightedItemIndex: -1];
		    lastIndex = index;
		    weWereOut = YES;
		    [window flushWindow];
		  }
*/
	      }
	    [window flushWindow];
	  default: 
	    break;
	}
    }

  /* If we didn't move out of the window to the left or right, and if we
didn't move beyond the bounds of the menu (?) and if we have a selected
cell do the following */

  if (!weLeftMenu && !weRightMenu && !weWereOut
    && menuv_highlightedItemIndex != -1)
    {
      if (![[menuv_items_link objectAtIndex: menuv_highlightedItemIndex]
	hasSubmenu])
	{
	  BOOL finished = NO;
	  NSMenu *aMenu = menuv_menu;

	  if (index >= 0 && index < theCount)
	    selectedCell = [menuv_items_link objectAtIndex: index];
	  else
	    selectedCell = nil;

	  [self setHighlightedItemIndex: -1];

	  [menuv_menu performActionForItem: 
	    [menuv_items_link objectAtIndex: lastIndex]];

          if (![menuv_menu _isBeholdenToPopUpButton])
	    {
	      while (!finished)
	        { // "forward"cursive menu find.
	          if ([aMenu attachedMenu])
		    {
		      aMenu = [aMenu attachedMenu];
		    }
	          else
		    finished = YES;
	        }

	      finished = NO;

	      while (!finished)
	        { // Recursive menu close & deselect.
	          if ([aMenu supermenu])
		    {
		      [[[aMenu supermenu] menuView] setHighlightedItemIndex: -1];
		      aMenu = [aMenu supermenu];
		    } 
	          else
		    finished = YES;
	        }
	    }
	  else
	    {
	      [menuv_menu close];
	    }
        }
      else
	{
	  BOOL finished = NO;
	  NSMenu *aMenu = menuv_menu;

	  if (index >= 0 && index < theCount)
	    selectedCell = [menuv_items_link objectAtIndex: index];
	  else
	    selectedCell = nil;

	  if (![[selectedCell target] isTornOff])
	    return;

	  [self setHighlightedItemIndex: -1];

	  /* If we are a menu */

          if (![menuv_menu _isBeholdenToPopUpButton])
	    {
	      while (!finished)
	        { // "forward"cursive menu find.
	          if ([aMenu attachedMenu])
		    {
		      aMenu = [aMenu attachedMenu];
		    }
	          else
		    finished = YES;
	        }

	      finished = NO;

	      while (!finished)
	        { // Recursive menu close & deselect.
	          if ([aMenu supermenu])
		    {
		      [[aMenu menuView] setHighlightedItemIndex: -1];
		      aMenu = [aMenu supermenu];
		    } 
	          else
		    finished = YES;

	          [window flushWindow];
	        }
	    }
	  else
	    {
	      [menuv_menu close];
	    }

	}
    }

  /* If the mouse is released and there is no highlighted cell */

  else if (menuv_highlightedItemIndex == -1
	&& [menuv_menu _isBeholdenToPopUpButton])
    {
      [menuv_menu close];
    }

  /* We went to the left of the current NSMenuView. BOOL is a misnomer. */

  else if (weRightMenu)
    {
      NSPoint cP = [window convertBaseToScreen: lastLocation];

      [self setHighlightedItemIndex: -1];

      if ([menuv_menu supermenu] && ![menuv_menu isTornOff])
	{
	  [self mouseUp: 
		[NSEvent mouseEventWithType: NSLeftMouseUp
		    location: cP
		    modifierFlags: [event modifierFlags]
		    timestamp: [event timestamp]
		    windowNumber: [window windowNumber]
		    context: [event context] 
		    eventNumber: [event eventNumber]
		    clickCount: [event clickCount]
		    pressure: [event pressure]]];

	  [[[menuv_menu supermenu] menuView] mouseDown: 
		[NSEvent mouseEventWithType: NSLeftMouseDragged
		    location: cP
		    modifierFlags: [event modifierFlags]
		    timestamp: [event timestamp]
		    windowNumber: [[[[menuv_menu supermenu] menuView] window] windowNumber]
		    context: [event context] 
		    eventNumber: [event eventNumber]
		    clickCount: [event clickCount]
		    pressure: [event pressure]]];
	}
    }

  /* We went to the right of the current NSMenuView. BOOL is a misnomer. */

  else if (weLeftMenu)
    { /* The weLeftMenu case */
      NSPoint cP = [window convertBaseToScreen: lastLocation];

      selectedCell = [menuv_items_link objectAtIndex: lastIndex];
      if ([selectedCell hasSubmenu])
	{
	  [self mouseUp: 
		[NSEvent mouseEventWithType: NSLeftMouseUp
		    location: cP
		    modifierFlags: [event modifierFlags]
		    timestamp: [event timestamp]
		    windowNumber: [window windowNumber]
		    context: [event context] 
		    eventNumber: [event eventNumber]
		    clickCount: [event clickCount]
		    pressure: [event pressure]]];

	  [[[selectedCell target] menuView] mouseDown: 
		[NSEvent mouseEventWithType: NSLeftMouseDragged
		    location: cP
		    modifierFlags: [event modifierFlags]
		    timestamp: [event timestamp]
		    windowNumber: [[[[selectedCell target] menuView] window] windowNumber]
		    context: [event context] 
		    eventNumber: [event eventNumber]
		    clickCount: [event clickCount]
		    pressure: [event pressure]]];
	}
    }

  return YES;                
}

- (void)mouseDown: (NSEvent *)theEvent
{
  [self trackWithEvent: theEvent];
}

-(void) performKeyEquivalent: (NSEvent *)theEvent
{
  [menuv_menu performKeyEquivalent: theEvent];
}

@end
