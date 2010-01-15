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
#include <AppKit/NSMenu.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenuView.h>

#include <GNUstepGUI/GSTheme.h>
#include <GNUstepGUI/GSWindowDecorationView.h>

#include "NSToolbarFrameworkPrivate.h"

@interface NSWindow (Private)
- (GSWindowDecorationView *) windowView;
@end

@implementation NSWindow (Private)
- (GSWindowDecorationView *) windowView
{
  return _wv;
}
@end

@implementation	GSTheme (Menu)
- (void) setMenu: (NSMenu *)menu
       forWindow: (NSWindow *)window
{
  GSWindowDecorationView *wv = [window windowView];
  if ([window menu] != menu)
    {
      NSMenuView *menuView;
      
      /* Restore the old representation to its original menu after
       * removing it from the window.  If we didn't do this, the menu
       * representation would be left without a partent view or
       * window to draw in.
       */
      menuView = [wv removeMenuView];
      [[window menu] setMenuRepresentation: menuView];
      [menuView sizeToFit];
      
      /* Set the new menu, and transfer the new menu representation
       * to the window decoration view.
       */
      menuView = [menu menuRepresentation];
      if (menuView != nil)
	{
	  [menu close];
	  [menuView setHorizontal: YES];
	  [menuView sizeToFit];
	  [wv addMenuView: menuView];
	}
    }
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
@end

