/** <title>NSWindow+Toolbar</title>

   <abstract>The window class category to include toolbar support</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: January 2004

   This file is part of the GNUstep GUI Library.

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

#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSAutoreleasePool.h>
#include "AppKit/NSWindow+Toolbar.h"
#include "AppKit/NSView.h"
#include "AppKit/NSToolbar.h"
#include "GNUstepGUI/GSToolbarView.h"

#include "NSToolbarFrameworkPrivate.h"

@implementation NSWindow (Toolbar)

- (void) runToolbarCustomizationPalette: (id)sender
{
  [[self toolbar] runCustomizationPalette: sender];
}

- (void) toggleToolbarShown: (id)sender
{
  NSToolbar *toolbar = [self toolbar];
  BOOL isVisible = [toolbar isVisible];

  if (!toolbar)
    return;
  
  if (isVisible)
    {
      [_wv removeToolbarView: [toolbar _toolbarView]];
    }
  else
    {
      [_wv addToolbarView: [toolbar _toolbarView]];
    }

  // Important to set _visible after the toolbar view has been toggled because
  // NSWindow method _contentViewWithoutToolbar uses [NSToolbar visible]
  // when we toggle the toolbar
  // example : the toolbar needs to be still known visible in order to hide
  // it.
  [toolbar setVisible: !isVisible];

  [self display];
}

// Accessors

- (NSToolbar *) toolbar
{
  return _toolbar;
}

- (void) setToolbar: (NSToolbar*)toolbar
{
  if (toolbar == _toolbar)
    return;

  if (_toolbar != nil)
    {
      GSToolbarView *toolbarView = [_toolbar _toolbarView];

      // We throw the last toolbar out
      if ([_toolbar isVisible])
        {
          [_wv removeToolbarView: toolbarView];
        }
      [toolbarView setToolbar: nil];
      // Release the toolbarView, this may release the toolbar
      RELEASE(toolbarView);
    }
  
  ASSIGN(_toolbar, toolbar);

  if (toolbar != nil)
    {
      GSToolbarView *toolbarView = [toolbar _toolbarView];
  
      if (toolbarView != nil)
        {
          NSLog(@"Error: the new toolbar is still owned by a toolbar view");
        }
      else
        {
          // Instantiate the toolbar view
          // FIXME: Currently this is reatined until the toolbar
          // gets removed from the window.
          toolbarView = [[GSToolbarView alloc] 
                            initWithFrame: 
                                NSMakeRect(0, 0, 
                                           [NSWindow contentRectForFrameRect: [self frame]
                                                     styleMask: [self styleMask]].size.width, 100)];
          // _toggleToolbarView method will set the toolbar view to the right
          // frame
          [toolbarView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
          [toolbarView setBorderMask: GSToolbarViewBottomBorder];
          // Load the toolbar inside the toolbar view
          // Will set the _toolbarView variable for the toolbar
          [toolbarView setToolbar: toolbar];
        }
    
      // Make the toolbar view visible
      if ([toolbar isVisible])
        {
          [_wv addToolbarView: toolbarView];
        }
    }

  // To show the changed toolbar
  [self displayIfNeeded];
}

@end
