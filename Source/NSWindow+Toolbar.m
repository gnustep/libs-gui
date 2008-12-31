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

@interface GSToolbar (GNUstepPrivate)
- (GSToolbarView *) _toolbarView;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _setToolbar: (NSToolbar *)toolbar;
- (float) _heightFromLayout;
- (void) _reload;
@end

@interface NSWindow (ToolbarPrivate)
- (void) _adjustToolbarView;
- (void) _toggleToolbarView;
- (NSView *) _contentViewWithoutToolbar;
@end

@implementation NSWindow (Toolbar)

- (void) runToolbarCustomizationPalette: (id)sender
{
  [[self toolbar] runCustomizationPalette: sender];
}

- (void) toggleToolbarShown: (id)sender
{
  NSToolbar *toolbar = [self toolbar];

  if (!toolbar)
    return;

  [self _toggleToolbarView];
  
  // Important to set _visible after the toolbar view has been toggled because
  // NSWindow method contentViewWithoutToolbar uses [NSToolbar visible]
  // when we toggle the toolbar
  // example : the toolbar needs to be still known visible in order to hide
  // it.
  [toolbar setVisible: ![toolbar isVisible]];

  [self display];
}

// Accessors

- (NSView *) _contentViewWithoutToolbar
{
  NSToolbar *toolbar = [self toolbar];
  
  if (toolbar != nil && [toolbar isVisible])
    {
      NSArray *subviews = [_contentView subviews]; 
      // Take in account this method call returns an array which is an
      // autoreleased copy.
      // By side effect, this increments the toolbar view retain count until the
      // autorelease pool is cleared.
      NSView *subview;
      int i, n = [subviews count];
      GSToolbarView *toolbarView = [toolbar _toolbarView];
      
      if (n > 2 || ![[toolbarView superview] isEqual: _contentView])
        {
          [NSException raise: @"_contentView error" 
                       format: @"_contenView is not valid. _contentView needs a \
                            toolbar view and a contentViewWithoutToolbar, with \
                            no others subviews."];
        }
     
      for (i = 0; i < n; i++)
        {
          subview = [subviews objectAtIndex: i];
          if (![subview isEqual: toolbarView])
            {
              return subview;
            }
        }
    
      return nil;
    }
  
  return [self contentView];
}

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
          [self _toggleToolbarView];
        }
      [toolbarView _setToolbar: nil];
      // Release the toolbarView, this will release the toolbar
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
          [toolbarView _setToolbar: toolbar];
        }
    
      // Make the toolbar view visible
      if ([toolbar isVisible])
        {
          [self _toggleToolbarView];
        }
    }

  // To show the changed toolbar
  [self display];
}

// Private methods

- (void) _adjustToolbarView
{
  NSToolbar *toolbar = [self toolbar]; 
  
  if ([toolbar isVisible])
    { 
      // Views
      GSToolbarView *toolbarView = [toolbar _toolbarView];
      
      // Frame and height
      NSRect toolbarViewFrame = [toolbarView frame];
      float toolbarViewHeight = toolbarViewFrame.size.height;
      float newToolbarViewHeight = [toolbarView _heightFromLayout];
  
      if (toolbarViewHeight != newToolbarViewHeight)
        {
          NSView *contentViewWithoutToolbar = [self _contentViewWithoutToolbar];
          NSRect windowFrame = [self frame];
      
          [toolbarView setFrame: NSMakeRect(
                  toolbarViewFrame.origin.x,
                  toolbarViewFrame.origin.y + (toolbarViewHeight - newToolbarViewHeight),
                  toolbarViewFrame.size.width, 
                  newToolbarViewHeight)];
          
          // Resize the window
          [contentViewWithoutToolbar setAutoresizingMask: NSViewNotSizable];
          
          [self setFrame: NSMakeRect(
                  windowFrame.origin.x, 
                  windowFrame.origin.y + (toolbarViewHeight - newToolbarViewHeight), 
                  windowFrame.size.width, 
                  windowFrame.size.height - (toolbarViewHeight - newToolbarViewHeight))
                display: NO];
          
          [contentViewWithoutToolbar setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
          
          [self display];
        }
    }
   
}

- (void) _toggleToolbarView
{
  // Views
  GSToolbarView *toolbarView = [[self toolbar] _toolbarView];
  NSView *contentViewWithoutToolbar;
  
  // Frame
  NSRect windowContentFrame
    = [NSWindow contentRectForFrameRect: [self frame]
                              styleMask: [self styleMask]];
  
  if ([toolbarView superview] == nil)
    {
      float newToolbarViewHeight;
      NSRect contentViewWithoutToolbarFrame;

      [toolbarView setFrameSize:
                       NSMakeSize(windowContentFrame.size.width, 100)];
      // Will recalculate the layout
      [toolbarView _reload];
      newToolbarViewHeight = [toolbarView _heightFromLayout];

      contentViewWithoutToolbar = _contentView;
      contentViewWithoutToolbarFrame = [contentViewWithoutToolbar frame];
    
      // Switch the content view
      RETAIN(contentViewWithoutToolbar);
      [self setContentView: 
        AUTORELEASE([[NSView alloc] initWithFrame: 
                                        contentViewWithoutToolbarFrame])];
    
      // Resize the window
      windowContentFrame.origin.y -= newToolbarViewHeight;
      windowContentFrame.size.height += newToolbarViewHeight;
      [self setFrame: [NSWindow frameRectForContentRect: windowContentFrame
                                              styleMask: [self styleMask]]
             display: NO];
  
      // Plug the toolbar view
      [toolbarView setFrame: NSMakeRect(
        0,
        contentViewWithoutToolbarFrame.size.height, 
        contentViewWithoutToolbarFrame.size.width, 
        newToolbarViewHeight)];
      [_contentView addSubview: toolbarView];
      RELEASE(toolbarView);
      
      // Insert the previous content view 
      /* We want contentViewWithoutToolbarFrame at the origin of our new
      content view. There's no guarantee that the old position was (0,0). */
      contentViewWithoutToolbarFrame.origin.x = 0;
      contentViewWithoutToolbarFrame.origin.y = 0;
      [contentViewWithoutToolbar setFrame: contentViewWithoutToolbarFrame];

      [_contentView addSubview: contentViewWithoutToolbar];
      RELEASE(contentViewWithoutToolbar);
    }
  else
    {      
      float toolbarViewHeight = [toolbarView frame].size.height;
      
      contentViewWithoutToolbar = [self _contentViewWithoutToolbar];
    
      // Unplug the toolbar view
      RETAIN(toolbarView);
      [toolbarView removeFromSuperviewWithoutNeedingDisplay];
    
      // Resize the window
      [contentViewWithoutToolbar setAutoresizingMask: NSViewMaxYMargin];
  
      windowContentFrame.origin.y += toolbarViewHeight;
      windowContentFrame.size.height -= toolbarViewHeight;
      [self setFrame: [NSWindow frameRectForContentRect: windowContentFrame
                                              styleMask: [self styleMask]]
             display: NO];
      
      [contentViewWithoutToolbar setAutoresizingMask: NSViewWidthSizable 
        | NSViewHeightSizable];
      // Autoresizing mask will be set again by the setContentView: method
            
      // Switch the content view
      RETAIN(contentViewWithoutToolbar); 
      // Because setContentView: will release the parent view (aka _contentView) and 
      // its subviews and actually contentViewWithoutToolbar is a subview of _contentView

      [contentViewWithoutToolbar removeFromSuperviewWithoutNeedingDisplay];
      [self setContentView: contentViewWithoutToolbar];

      RELEASE(contentViewWithoutToolbar);
    }
}

@end
