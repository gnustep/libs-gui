/** <title>GSThemePanel</title>

   <abstract>Theme management utility</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2010
   
   This file is part of the GNU Objective C User interface library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSString.h>
#include <Foundation/NSArchiver.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSApplication.h>

#include <GNUstepGUI/GSTheme.h>
#include <GNUstepGUI/GSWindowDecorationView.h>

#include "NSToolbarFrameworkPrivate.h"

@interface NSWindow (Private)
- (GSWindowDecorationView *) windowView;
- (void) _setMenu: (NSMenu *)menu;
@end

@implementation NSWindow (Private)
- (GSWindowDecorationView *) windowView
{
  return _wv;
}

- (void) _setMenu: (NSMenu *)menu
{
  [super setMenu: menu];
}
@end

@implementation	GSTheme (Menu)
- (void) setMenu: (NSMenu *)menu
       forWindow: (NSWindow *)window
{
  GSWindowDecorationView *wv = [window windowView];
  if ([window menu] == nil && menu != nil)
    {
      NSData *data = [NSArchiver archivedDataWithRootObject: menu]; // copy the view...
      NSMenu *newMenu = [NSUnarchiver unarchiveObjectWithData: data];
      NSMenuView *menuView = nil;

      /* 
       * Set the new menu
       */
      [window _setMenu: newMenu];

      /*
       * And transfer the new menu representation to the window decoration view.
       */
      menuView = [newMenu menuRepresentation];
      if (menuView != nil)
	{
	  [menu close];
	  [menuView setHorizontal: YES];
	  [wv addMenuView: menuView];
	  [menuView sizeToFit];
	}
    }
  else
    {
      NSMenu *m = [window menu];
      // NSMenuView *menuView = nil;

      [m update];      
      /*
      menuView = [m menuRepresentation];
      if (menuView != nil)
	{
	  [menu close];
	  [menuView setHorizontal: YES];
	  [wv addMenuView: menuView];
	  [menuView sizeToFit];
	}
      */
    }
}

- (void) rightMouseDisplay: (NSMenu *)menu
		  forEvent: (NSEvent *)theEvent
{
  NSMenuView *mv = [menu menuRepresentation];
  if ([mv isHorizontal] == NO)
    {
      [menu displayTransient];
      [mv mouseDown: theEvent];
      [menu closeTransient];
    }
}

- (void) displayPopUpMenu: (NSMenuView *)mr
	    withCellFrame: (NSRect)cellFrame
	controlViewWindow: (NSWindow *)cvWin
	    preferredEdge: (NSRectEdge)edge
	     selectedItem: (int)selectedItem
{ 
  // Ask the MenuView to attach the menu to this rect
  [mr setWindowFrameForAttachingToRect: cellFrame
			      onScreen: [cvWin screen]
			 preferredEdge: edge
		     popUpSelectedItem: selectedItem];
  
  // Set to be above the main window
  [cvWin addChildWindow: [mr window] ordered: NSWindowAbove];

  // Last, display the window
  [[mr window] orderFrontRegardless];
}

- (void) processCommand: (void *)context
{
  // this is only implemented when we handle native menus.
  // put code in here to handle commands from the native menu structure.
}

- (float) menuHeightForWindow: (NSWindow *)window
{
  return [NSMenuView menuBarHeight];
}

- (void) updateMenu: (NSMenu *)menu forWindow: (NSWindow *)window
{
  [self setMenu: menu 
	forWindow: window];
}

- (void) updateAllWindowsWithMenu: (NSMenu *) menu
{
  NSEnumerator *en = [[NSApp windows] objectEnumerator];
  id            o = nil;

  while ((o = [en nextObject]) != nil)
    {
      if([o canBecomeMainWindow])
	{
	  [self updateMenu: menu forWindow: o];
	}
    }
}

- (BOOL) doesProcessEventsForPopUpMenu
{
  return NO; // themes that handle events in a popUpMenu should return YES
}

@end

