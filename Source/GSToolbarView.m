/*
   <title>GSToolbarView.m</title>

   <abstract>The toolbar view class.</abstract>
   
   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Quentin Mathé <qmathe@club-internet.fr>
   Date: January 2004
   
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

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSView.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSToolbarView.h"

// internal
static const int current_version = 1;


@interface NSToolbar (GNUstepPrivate)
- (void) _build;
- (void) _setToolbarView: (GSToolbarView *)toolbarView;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (NSView *) _backView;
- (BOOL) _isModified;
- (BOOL) _isFlexibleSpace;
- (void) _layout;
@end

@interface GSToolbarClippedItemsButton : NSButton
{
  NSToolbar *_toolbar;
}

- (id) init;

// Accessors
- (NSMenu *) returnMenu; // this method cannot be called menu otherwise 
// it would override NSResponder method with the same name
- (void)setToolbar: (NSToolbar *)toolbar;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _handleViewsSize;
- (void) _handleViewsOrigin;
- (void) _handleViewsVisibility;
- (void) _reload;
- (void) _takeInAccountFlexibleSpaces;

// Accessors
- (NSArray *) _visibleBackViews;
- (void) _setWillBeVisible: (BOOL)willBeVisible;
- (BOOL) _willBeVisible;
@end

@implementation GSToolbarClippedItemsButton
- (id)init
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarClippedItemsMark"];
  
  if ((self = [super initWithFrame: NSMakeRect(0, 0, _ClippedItemsViewWidth, _ItemBackViewDefaultHeight)]) != nil)
    {
      [self setBordered: NO];
      [[self cell] setHighlightsBy: NSChangeGrayCellMask | NSChangeBackgroundCellMask];
      [self setAutoresizingMask: (NSViewNotSizable | NSViewMinXMargin)];
      [self setImagePosition: NSImageOnly];
      [image setScalesWhenResized: YES];
      [image setSize: NSMakeSize(20., 20.)];
      [self setImage: image];
      return self;
    }
  return nil;
}

- (void)mouseDown: (NSEvent *)event {
   NSMenu *clippedItemsMenu = [self menuForEvent:event];
   
   if (clippedItemsMenu != nil)
    {
      [NSMenu popUpContextMenu: clippedItemsMenu withEvent: event forView: self];
    }
}

- (NSMenu *)menuForEvent: (NSEvent *)event {
  if ([event type] == NSLeftMouseDown)
    {
      return [self returnMenu];
    }
  return nil;
}

- (NSMenu *)returnMenu 
// this method cannot be called menu otherwise it would override NSResponder method with the same name
{
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
  NSEnumerator *e;
  id item;
  NSArray *visibleItems;
  
  AUTORELEASE(menu);
  
  visibleItems = [_toolbar visibleItems];

  e = [[_toolbar items] objectEnumerator];
  while ((item = [e nextObject]) != nil)
    {
      if (![visibleItems containsObject: item])
        {
          id menuItem;
      
      	  menuItem = [item menuFormRepresentation];
          if (menuItem != nil)
            [menu addItem: menuItem];
        }
    }

  return menu;
}

// Accessors

- (void)setToolbar: (NSToolbar *)toolbar
{
  ASSIGN(_toolbar, toolbar);
}
@end

// Implementation GSToolbarView

@implementation GSToolbarView
- (id) initWithFrame: (NSRect)frame
{
  if((self = [super initWithFrame: frame]) != nil)
    {
      _clipView = [[NSClipView alloc] initWithFrame: NSMakeRect(0, 1, frame.size.width, frame.size.height)];
      [_clipView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
      [self addSubview: _clipView];
      
      _clippedItemsMark = [[GSToolbarClippedItemsButton alloc] init];
      
      _borderMask = GSToolbarViewTopBorder | GSToolbarViewBottomBorder | GSToolbarViewRightBorder | GSToolbarViewLeftBorder;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_toolbar);
  RELEASE(_clippedItemsMark);
  RELEASE(_clipView);

  [super dealloc];
}

// More overrided methods

- (void) drawRect: (NSRect)aRect
{
  NSBezierPath *rect = [NSBezierPath bezierPathWithRect: aRect];
  NSRect viewFrame = [self frame];
  
  // We draw the background
  [[NSColor colorWithDeviceRed: 0.8 green: 0.8 blue: 0.8 alpha:1] set];
  [rect fill];
  
  // We draw the border
  [[NSColor colorWithDeviceRed: 0.5 green: 0.5 blue: 0.5 alpha:1] set];
  if (_borderMask & GSToolbarViewBottomBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 0.5) 
                              toPoint: NSMakePoint(viewFrame.size.width, 0.5)];
  }
  if (_borderMask & GSToolbarViewTopBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0, viewFrame.size.height - 0.5) 
                              toPoint: NSMakePoint(viewFrame.size.width, viewFrame.size.height -  0.5)];
  }
  if (_borderMask & GSToolbarViewLeftBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0.5, 0) 
                              toPoint: NSMakePoint(0.5, viewFrame.size.height)];
  }
  if (_borderMask & GSToolbarViewRightBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(viewFrame.size.width - 0.5, 0) 
                              toPoint: NSMakePoint(viewFrame.size.width - 0.5, viewFrame.size.height)];
  }
  
  [super drawRect: aRect];

}

- (BOOL) isOpaque
{
  return YES;
}

- (void) windowDidResize: (NSNotification *)notification
{ 
  if (![_toolbar isVisible]) return;
  
  [self _handleViewsVisibility];
}

- (void) viewDidMoveToSuperview
{ 
  // NSView method called when a view is moved not to a superview
  
 if (_toolbar != nil)
    {
      [self _handleViewsVisibility];
    }
}

- (void) viewDidMoveToWindow
{ 
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  // NSView method called when a view is moved to a window (NSView has a variable _window)
  [super viewDidMoveToWindow]; 
  
  [nc removeObserver: self name: NSWindowDidResizeNotification object: _window];
  [nc addObserver: self selector: @selector(windowDidResize:) name: NSWindowDidResizeNotification object: nil];
  
  [self viewDidMoveToSuperview];
}

// More methods... Accessors

- (unsigned int) borderMask
{
  return _borderMask;
}

- (NSToolbar *) toolbar
{
  return _toolbar;
}

- (void) setBorderMask: (unsigned int)borderMask
{
  _borderMask = borderMask;
}

- (void) setToolbar: (NSToolbar *)toolbar
{
  ASSIGN(_toolbar, toolbar);
  [_clippedItemsMark setToolbar: _toolbar];
  
  [_toolbar _build]; // Use the delegate to build the toolbar
  
  [_toolbar _setToolbarView: self];
  [self _reload]; // Load the toolbar in the toolbar view
}

// Private methods

- (void) _handleViewsOrigin
{
  NSEnumerator *e = [[_toolbar items] objectEnumerator];
  NSToolbarItem *item;
  NSView *itemView;
  NSRect itemViewFrame;
  float x = 0.;
 
  while ((item = [e nextObject]) != nil) 
    {
      itemView = [item _backView];
      
      if ([item _isFlexibleSpace]) 
      {
	[item _layout];
      }
      
      itemViewFrame = [itemView frame];
      [itemView setFrame: NSMakeRect(x, itemViewFrame.origin.y, itemViewFrame.size.width, itemViewFrame.size.height)];
       x += [itemView frame].size.width;
    }
}

- (void) _handleViewsSize
{
  NSEnumerator *e = [[_toolbar items] objectEnumerator];
  NSToolbarItem *item;
  NSView *itemView, *itemViewEdited;
  NSArray *subviews = [self subviews];
 
  while ((item = [e nextObject]) != nil) 
    {
      itemView = [item _backView];
      if (![subviews containsObject: itemView] || [item _isModified]) 
        {
          itemViewEdited = itemView;
        }
    
          // Example : when a label is changed, _isModified returns YES
          // to let us known we must recalculate the text lenght and 
          // then the item view size with the subsequent arrangement
    
          if (itemViewEdited != nil)
            [item _layout];
    }
    
}

- (void) _handleViewsVisibility
{
  NSArray *items = [_toolbar items];
  
  // the backViews which are associated with the toolbar items now (the toolbar items doesn't 
  // reflect the toolbar view content)
  NSArray *itemBackViews = [items valueForKey: @"_backView"];
  
  // the backViews which will be visible in the toolbar view (when _handleViewsVisibility will be terminated)
  NSArray *visibleItemBackViews = [self _visibleBackViews];
  
  // the backViews which are visible in the toolbar view now
  NSArray *currentItemBackViews = [_clipView subviews];
  
  NSEnumerator *e;
  NSView *itemBackView;
  NSRect clipViewFrame;
  
  [self _handleViewsOrigin];
  
  [self _takeInAccountFlexibleSpaces];
  
  // We remove the _backView (itemBackView variable) associated with the removed or not visible 
  // toolbar items
 
  e = [currentItemBackViews objectEnumerator];
  
  while ((itemBackView = [e nextObject]) != nil) 
    {
      if (![itemBackViews containsObject: itemBackView] || ![visibleItemBackViews containsObject: itemBackView])
        {
          if ([itemBackView superview] != nil) 
            [itemBackView removeFromSuperview];
        }
    }
      
  // We add the _backView (itemBackView variable) associated with the added toolbar item when it 
  // is visible
  
  e = [visibleItemBackViews objectEnumerator];
 
  while ((itemBackView = [e nextObject]) != nil) 
  {
    if (![currentItemBackViews containsObject: itemBackView])
      {
        [_clipView addSubview: itemBackView];
      }
  }
 
  clipViewFrame = [_clipView frame];  
  
  if (([_clippedItemsMark superview] == nil) && ([visibleItemBackViews count] < [itemBackViews count]))
    {
      [_clipView setFrame: NSMakeRect(clipViewFrame.origin.x, clipViewFrame.origin.y, 
				      clipViewFrame.size.width - _ClippedItemsViewWidth, 
				      clipViewFrame.size.height)]; 
      clipViewFrame = [_clipView frame]; // we get the new _clipView frame
      [_clippedItemsMark setFrameOrigin: NSMakePoint(clipViewFrame.size.width, 
						     clipViewFrame.origin.y)];
      [self addSubview: _clippedItemsMark];
    }
  else if (([_clippedItemsMark superview] != nil) && ([visibleItemBackViews count] >= 
						      [itemBackViews count]))
    {
      [_clippedItemsMark removeFromSuperview];
      [_clipView setFrame: NSMakeRect(clipViewFrame.origin.x, clipViewFrame.origin.y, 
				      clipViewFrame.size.width + _ClippedItemsViewWidth, clipViewFrame.size.height)]; 
    }
  
  [self setNeedsDisplay: YES];
}

- (void) _reload {
 
  [self _handleViewsSize];
  [self _handleViewsVisibility]; 
  
}

- (void) _takeInAccountFlexibleSpaces
{
  NSArray *items = [_toolbar items];
  NSEnumerator *e = [items objectEnumerator];
  NSToolbarItem *item;
  NSView *itemView; 
  NSRect lastItemViewFrame = [[[items lastObject] _backView] frame];
  float lengthAvailable = [self frame].size.width - (lastItemViewFrame.origin.x + 
						     lastItemViewFrame.size.width);
  int flexibleSpaceItemsNumber = 0;
  BOOL mustAdjustNext = NO;
  float x = 0.;
  
  if (lengthAvailable < 1)
    return;
  
  while ((item = [e nextObject]) != nil) 
  {
    if ([item _isFlexibleSpace])
    {
      flexibleSpaceItemsNumber++;
    }
  }
  
  if (lengthAvailable < flexibleSpaceItemsNumber)
    return;
  
  e = [items objectEnumerator];
  while ((item = [e nextObject]) != nil)
  {
    itemView = [item _backView];
    if ([item _isFlexibleSpace])
    {
      NSRect itemViewFrame = [itemView frame];
      
      [itemView setFrame: 
        NSMakeRect(x, itemViewFrame.origin.y, lengthAvailable / flexibleSpaceItemsNumber, 
		   itemViewFrame.size.height)];
      mustAdjustNext = YES;
    }
    else if (mustAdjustNext)
    {
      NSRect itemViewFrame = [itemView frame];
      
      [itemView setFrame: NSMakeRect(x, itemViewFrame.origin.y, itemViewFrame.size.width, 
				     itemViewFrame.size.height)];
    }
    x += [itemView frame].size.width;
  }
  
}

// Accessors private methods

- (NSArray *) _visibleBackViews
{
  NSArray *items = [_toolbar items];
  NSView *itemView;
  int i, n = [items count];
  float totalWidth = 0, toolbarWidth;
  
  if (![_toolbar isVisible] && ![self _willBeVisible]) 
    return nil;
  
  [_visibleBackViews release];
  _visibleBackViews = [[NSMutableArray alloc] init];
  
  toolbarWidth = [self frame].size.width;;
  
  for (i = 0; i < n; i++)
    {
      itemView = [[items objectAtIndex:i] _backView];
  
      totalWidth += [itemView frame].size.width;

      if ((totalWidth + _ClippedItemsViewWidth <= toolbarWidth) || (i == n - 1 && totalWidth <= 
								    toolbarWidth))
        {
          [_visibleBackViews addObject: itemView];
        }     
    }
  
  return _visibleBackViews;
  
}

- (BOOL) _willBeVisible
{
  return _willBeVisible;
}

- (void) _setWillBeVisible: (BOOL)willBeVisible
{
  _willBeVisible = willBeVisible;
}

@end
