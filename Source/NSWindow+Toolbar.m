/** <title>NSWindow+Toolbar</title>

   <abstract>The window class category to include toolbar support</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: January 2004

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>

#include "AppKit/NSWindow+Toolbar.h"
#include "AppKit/NSView.h"
#include "AppKit/NSToolbar.h"
#include "GNUstepGUI/GSToolbarView.h"

static const int ToolbarHeight = 61;

@interface NSToolbar (GNUstepPrivate)
+ (NSArray *) _toolbars;
- (GSToolbarView *) _toolbarView;
- (void) _setWindow: (NSWindow *)window;
- (NSWindow *) _window;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _setToolbar: (NSToolbar *)toolbar;
- (void) _handleViewsVisibility;
@end

@interface NSWindow (ToolbarPrivate)
- (void) _toggleToolbarView: (GSToolbarView *)toolbarView display: (BOOL)flag;
@end

@implementation NSWindow (Toolbar)

- (void) runToolbarCustomizationPalette: (id)sender
{
  [[self toolbar] runCustomizationPalette: sender];
}

- (void) toggleToolbarShown: (id)sender
{
  NSToolbar *toolbar = [self toolbar];
    
  if ([sender isEqual: toolbar]) 
  // we can enter this branch when the toolbar class has called
  // toggleToolbarShown:
  {
    [self _toggleToolbarView: [toolbar _toolbarView] display: YES];
  }
  else
  {
    // we call the toolbar class letting it call back on toggleToolbarShown:
    [toolbar setVisible: ![toolbar isVisible]];
  }
  
}

// Accessors

- (NSView *) contentViewWithoutToolbar
{
  NSToolbar *toolbar = [self toolbar];
  
  if (toolbar != nil && [toolbar isVisible])
  {
    NSArray *subviews = [_contentView subviews];
    id subview;
    int i, n = [subviews count];
    GSToolbarView *toolbarView = [toolbar _toolbarView];
    
    if (n > 2 || ![[toolbarView superview] isEqual: _contentView]) {
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
  NSArray *toolbars = [NSToolbar _toolbars];
  NSArray *windows;
  unsigned index = 0;
  
  if (toolbars == nil)
    return nil;

  windows = [toolbars valueForKey: @"_window"];
  index = [windows indexOfObjectIdenticalTo: self];

  return (index == NSNotFound) ? nil : [toolbars objectAtIndex: index];
}

// user oriented method
- (void) setContentViewWithoutToolbar: (NSView *)contentViewWithoutToolbar 
{
  NSToolbar *toolbar = [self toolbar];
  
  if (toolbar != nil && [toolbar isVisible]) 
  {
    [_contentView replaceSubview: [self contentViewWithoutToolbar] 
                            with: contentViewWithoutToolbar];
  }
  else
  {
    [self setContentView: contentViewWithoutToolbar];
  }
}


- (void) setToolbar: (NSToolbar*)toolbar
{
  NSToolbar *lastToolbar = [self toolbar];
  GSToolbarView *toolbarView = nil;
  // ---											  
  
  if (lastToolbar != nil)
  {
    // we throw the last toolbar out
    
    [self _toggleToolbarView : [lastToolbar _toolbarView] display: NO];
    [lastToolbar _setWindow: nil];
  }
  
  // when there is no new toolbar
  
  if (toolbar == nil)
  {
    [self display]; // to show we have toggle the previous toolbar view
    return;
  }
  
  // ELSE
  // the window want to know which toolbar is binded
  
  [toolbar _setWindow : self];
  
  // insert the toolbar view (we create this view when the toolbar hasn't such
  // view)...
  
  toolbarView = [toolbar _toolbarView];
  if (toolbarView == nil)
  {
    toolbarView = [[GSToolbarView alloc] initWithFrame: NSMakeRect(0, 0, 0, 0)]; 
    // _toggleToolbarView:display: method will set the toolbar view to the right
    // frame
    [toolbarView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
  }
  [toolbarView setBorderMask: GSToolbarViewBottomBorder];
  [self _toggleToolbarView: toolbarView display: YES];
  
  // load the toolbar inside the toolbar view
  
  [toolbarView _setToolbar: toolbar];
  
}

// Private methods

- (void) _toggleToolbarView: (GSToolbarView *)toolbarView display: (BOOL)flag {
  NSRect windowFrame;
  
  if ([toolbarView superview] == nil)
    {
      NSView *contentViewWithoutToolbar;
      NSRect contentViewWithoutToolbarFrame;
    
      contentViewWithoutToolbar = _contentView;
    
      // Switch the content view
  
      RETAIN(contentViewWithoutToolbar);
      [self setContentView: 
        [[NSView alloc] initWithFrame: [_contentView frame]]];
    
      // Resize the window
  
      windowFrame = [self frame];
      [self setFrame: NSMakeRect(windowFrame.origin.x, 
        windowFrame.origin.y - ToolbarHeight, windowFrame.size.width, 
        windowFrame.size.height + ToolbarHeight) display: flag];
  
      // Plug the toolbar view
    
      contentViewWithoutToolbarFrame = [contentViewWithoutToolbar frame];
      [toolbarView setFrame: NSMakeRect(0,contentViewWithoutToolbarFrame.size.height, 
        contentViewWithoutToolbarFrame.size.width, ToolbarHeight)];

      [_contentView addSubview: toolbarView];
      [toolbarView _handleViewsVisibility];
      [toolbarView setNextResponder: self];
    
      // Insert the previous content view 
  
      [_contentView addSubview: contentViewWithoutToolbar];
      RELEASE(contentViewWithoutToolbar);
    }
  else
    {
      NSView *contentViewWithoutToolbar;
    
      contentViewWithoutToolbar = [self contentViewWithoutToolbar];
    
      // Unplug the toolbar view
    
      [toolbarView removeFromSuperview];
    
      // Resize the window
      
      [contentViewWithoutToolbar setAutoresizingMask: NSViewMaxYMargin];
  
      windowFrame = [self frame];
      [self setFrame: NSMakeRect(windowFrame.origin.x, 
        windowFrame.origin.y + ToolbarHeight, windowFrame.size.width, 
        windowFrame.size.height - ToolbarHeight) display: flag];
      
      [contentViewWithoutToolbar setAutoresizingMask: NSViewWidthSizable 
        | NSViewHeightSizable];
      // Autoresizing mask will be set again by the setContentView: method
            
      // Switch the content view

      RETAIN(contentViewWithoutToolbar); 
      // because setContentView: will release the parent view and their subviews

      [self setContentView: contentViewWithoutToolbar];

      RELEASE(contentViewWithoutToolbar);
    }
  
}

@end
