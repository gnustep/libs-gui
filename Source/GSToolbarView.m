/*
   <Title>GSToolbarView.m</title>

   <abstract>The toolbar view class.</abstract>
   
   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
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
#include "AppKit/NSToolbarItem.h"
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


@interface GSToolbar (GNUstepPrivate)
- (void) _build;
- (void) _setToolbarView: (GSToolbarView *)toolbarView;
- (GSToolbarView *) _toolbarView;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (NSView *) _backView;
- (BOOL) _isModified;
- (BOOL) _isFlexibleSpace;
- (void) _layout;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _handleBackViewsFrame;
- (void) _handleViewsVisibility;
- (void) _reload;
- (void) _setToolbar: (GSToolbar *)toolbar;
- (void) _takeInAccountFlexibleSpaces;

// Accessors
- (float) _heightFromLayout;
- (NSArray *) _visibleBackViews;
- (void) _setWillBeVisible: (BOOL)willBeVisible;
- (BOOL) _willBeVisible;
@end

@interface GSToolbarClippedItemsButton : NSButton
{
  GSToolbar *_toolbar;
}

- (id) init;

// Accessors 
- (NSMenu *) returnMenu; 

// this method cannot be called "menu" otherwise it would override NSResponder
// method with the same name

- (void) layout;
- (void) setToolbar: (GSToolbar *)toolbar; 
@end

@implementation GSToolbarClippedItemsButton
- (id) init
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarClippedItemsMark"];
  
  if ((self = [super initWithFrame: NSMakeRect(0, 0, _ClippedItemsViewWidth, 
    _ItemBackViewDefaultHeight)]) != nil)
    {
      [self setBordered: NO];
      [[self cell] setHighlightsBy: NSChangeGrayCellMask 
        | NSChangeBackgroundCellMask];
      [self setAutoresizingMask: NSViewNotSizable];
      [self setImagePosition: NSImageOnly];
      [image setScalesWhenResized: YES];
      //[image setSize: NSMakeSize(20, 20)];
      [self setImage: image];
      return self;
    }
  return nil;
}

- (void) layout {
  [self setFrameSize: NSMakeSize([self frame].size.width, 
                                 [[_toolbar _toolbarView] _heightFromLayout])];
}

- (void) mouseDown: (NSEvent *)event {
   NSMenu *clippedItemsMenu = [self menuForEvent:event];
   
   [super highlight: YES];
   
   if (clippedItemsMenu != nil)
    {
      [NSMenu popUpContextMenu: clippedItemsMenu withEvent: event 
                                                   forView: self];
    }
    
    [super highlight: NO];
}

- (NSMenu *) menuForEvent: (NSEvent *)event {
  if ([event type] == NSLeftMouseDown)
    {
      return [self returnMenu];
    }
  return nil;
}

- (NSMenu *) returnMenu 
{
  // this method cannot be called menu otherwise it would
  // override NSResponder method with the same name
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

- (void) setToolbar: (GSToolbar *)toolbar
{
  ASSIGN(_toolbar, toolbar);
}
@end

// Implementation GSToolbarView

@implementation GSToolbarView
- (id) initWithFrame: (NSRect)frame
{
  return [self initWithFrame: frame 
                 displayMode: NSToolbarDisplayModeDefault 
	            sizeMode: NSToolbarSizeModeDefault];
}

- (id) initWithFrame: (NSRect)frame 
         displayMode: (NSToolbarDisplayMode)displayMode 
	    sizeMode: (NSToolbarSizeMode)sizeMode
{
  if((self = [super initWithFrame: frame]) != nil)
    {
      float toolbarViewHeight;
      
      _displayMode = displayMode;
      _sizeMode = sizeMode;
      
      switch (_sizeMode)
        {
	  case NSToolbarSizeModeDefault:
	    toolbarViewHeight = _ToolbarViewDefaultHeight;
	    break;
	  case NSToolbarSizeModeRegular:
	    toolbarViewHeight = _ToolbarViewRegularHeight;
	    break;
	  case NSToolbarSizeModeSmall:
	    toolbarViewHeight = _ToolbarViewSmallHeight;
	    break;
	  default:
	    // raise exception
	    toolbarViewHeight = 0;
	}
  
      [self setFrame: NSMakeRect(
        frame.origin.x, 
        frame.origin.y, 
        frame.size.width,
        toolbarViewHeight)];
        
      // ---
      
      _clipView = [[NSClipView alloc] initWithFrame: 
        NSMakeRect(0, 1, frame.size.width, toolbarViewHeight - 1)];

      [_clipView setAutoresizingMask: (NSViewWidthSizable |
        NSViewHeightSizable)];

      [self addSubview: _clipView];
      
      _clippedItemsMark = [[GSToolbarClippedItemsButton alloc] init];
      
      _borderMask = GSToolbarViewTopBorder | GSToolbarViewBottomBorder 
        | GSToolbarViewRightBorder | GSToolbarViewLeftBorder;
      
      // ---

      return self;
    }
    
  return nil;
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
                              toPoint: NSMakePoint(viewFrame.size.width, 
                                                   viewFrame.size.height -  0.5)];
  }
  if (_borderMask & GSToolbarViewLeftBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0.5, 0) 
                              toPoint: NSMakePoint(0.5, viewFrame.size.height)];
  }
  if (_borderMask & GSToolbarViewRightBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(viewFrame.size.width - 0.5,0)
                              toPoint: NSMakePoint(viewFrame.size.width - 0.5, 
                                                   viewFrame.size.height)];
  }
  
  [super drawRect: aRect];

}

- (BOOL) isOpaque
{
  return YES;
}

- (void) windowDidResize: (NSNotification *)notification
{ 
  if ([self superview] == nil) 
    return;
  
  [self _reload];
}

- (void) viewDidMoveToSuperview
{ 
  // NSView method called when a view is moved not to a superview
  
 if (_toolbar != nil)
    {
      //[self _reload];
    }
}

- (void) viewDidMoveToWindow
{ 
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  // NSView method called when a view is moved to a window (NSView has a
  // variable _window)
  [super viewDidMoveToWindow]; 
  
  [nc removeObserver: self name: NSWindowDidResizeNotification object: _window];
  [nc addObserver: self selector: @selector(windowDidResize:) 
                            name: NSWindowDidResizeNotification object: nil];
  
  //[self viewDidMoveToSuperview];
}

// More methods... Accessors

- (unsigned int) borderMask
{
  return _borderMask;
}

- (GSToolbar *) toolbar
{
  return _toolbar;
}

- (void) setBorderMask: (unsigned int)borderMask
{
  _borderMask = borderMask;
}

- (void) setToolbar: (GSToolbar *)toolbar 
{
  if ([toolbar isKindOfClass: [NSToolbar class]])
    [NSException raise: NSInvalidArgumentException
                format: @"NSToolbar instance can't be attached directly to a \
                          toolbar view, setToolbar: from the NSWindow toolbar \
                          category must be used."];
  
  [self _setToolbar: toolbar];
}

// Private methods

- (void) _handleBackViewsFrame
{
  NSEnumerator *e = [[_toolbar items] objectEnumerator];
  NSToolbarItem *item;
  NSView *itemBackView;
  NSRect itemBackViewFrame;
  float x = 0;
  // ---
  NSArray *subviews = [self subviews];
  
  _heightFromLayout = 100;
 
  while ((item = [e nextObject]) != nil) 
    {
      itemBackView = [item _backView];
      if (![subviews containsObject: itemBackView] 
        || [item _isModified] 
        || [item _isFlexibleSpace])
        {
	  // When a label is changed, _isModified returns YES to let us known we
	  // must recalculate the text length and then the size for the edited
	  // item back view
          [item _layout];
        }
      
      itemBackViewFrame = [itemBackView frame];
      [itemBackView setFrame: NSMakeRect(x, 
         itemBackViewFrame.origin.y, 
         itemBackViewFrame.size.width, 
         itemBackViewFrame.size.height)];
      x += [itemBackView frame].size.width;
      
      if (itemBackViewFrame.size.height < _heightFromLayout)
        _heightFromLayout = itemBackViewFrame.size.height;
    }
    
}

- (void) _handleViewsVisibility
{
  NSArray *items = [_toolbar items];
  
  // The back views which are associated with each toolbar item (the toolbar
  // items doesn't reflect the toolbar view content)
  NSArray *backViews = [items valueForKey: @"_backView"];
  
  // The back views which will be visible in the toolbar view (when
  // _handleViewsVisibility will be terminated)
  NSArray *visibleBackViews;
  
  NSArray *subviews;
  NSEnumerator *e;
  NSView *backView;
  NSRect clipViewFrame;
  
  // First, we resize
  [self _handleBackViewsFrame];
  [self _takeInAccountFlexibleSpaces];
  
  // Then we retrieve the back views which should be visible now that the resize
  // process has been taken in account
  visibleBackViews = [self _visibleBackViews];
  
  // ---
     
  // We remove each back view associated with a removed toolbar item
 
  e = [[_clipView subviews] objectEnumerator];
  
  while ((backView = [e nextObject]) != nil) 
    {
      if (![backViews containsObject: backView])
        {
          if ([backView superview] != nil) 
            [backView removeFromSuperview];
        }
    }
      
  // We add each backView associated with an added toolbar item
  
  e = [backViews objectEnumerator];
 subviews = [_clipView subviews];
 
  while ((backView = [e nextObject]) != nil) 
  {
    if (![subviews containsObject: backView])
      {
        [_clipView addSubview: backView];
      }
  }
  
  // ---
     
  // We manage the clipped items view in the case it should become visible or
  // invisible
  
  clipViewFrame = [_clipView frame];  
  
  if ([visibleBackViews count] < [backViews count])
    {
      NSView *lastVisibleBackView = [visibleBackViews lastObject];
      float width = 0;
      
      // Resize the clip view
      
      if (lastVisibleBackView != nil)
          width = NSMaxX([lastVisibleBackView frame]);  
      [_clipView setFrame: NSMakeRect(clipViewFrame.origin.x,
                                      clipViewFrame.origin.y, 
                                      width,
                                      clipViewFrame.size.height)]; 
	
      // Adjust the clipped items mark 
      // Frame handling   
      
      [_clippedItemsMark layout];
      
      clipViewFrame = [_clipView frame]; // We get the new _clipView frame
      [_clippedItemsMark setFrameOrigin: NSMakePoint(
        [self frame].size.width - _ClippedItemsViewWidth, clipViewFrame.origin.y)];
	
      // ---
	
      if ([_clippedItemsMark superview] == nil)       
        [self addSubview: _clippedItemsMark];  
      
    }
  else if (([_clippedItemsMark superview] != nil) 
    && ([visibleBackViews count] >= [backViews count]))
    {      
      [_clippedItemsMark removeFromSuperview];
      
      [_clipView setFrame: NSMakeRect(clipViewFrame.origin.x,
                                      clipViewFrame.origin.y, 
                                      [self frame].size.width,
                                      clipViewFrame.size.height)]; 
    }
 
}

- (void) _reload 
{  
  [self _handleViewsVisibility]; 
  [self setNeedsDisplay: YES];
}

- (void) _setToolbar: (GSToolbar *)toolbar
{
  if ([toolbar sizeMode] != _sizeMode)
    ; // FIXME : raise exception here
  
  [toolbar _setToolbarView: self]; // We set the toolbar view on the new toolbar
  [_toolbar _setToolbarView: nil]; // We unset the toolbar view from the previous toolbar    
  
  ASSIGN(_toolbar, toolbar);
  
  [_clippedItemsMark setToolbar: _toolbar];
  
  [self _reload]; // Load the toolbar in the toolbar view
}

- (void) _takeInAccountFlexibleSpaces
{
  NSArray *items = [_toolbar items];
  NSEnumerator *e = [items objectEnumerator];
  NSToolbarItem *item;
  NSView *backView; 
  NSRect lastBackViewFrame = [[[items lastObject] _backView] frame];
  float lengthAvailable = [self frame].size.width -
    NSMaxX(lastBackViewFrame);
  unsigned int flexibleSpaceItemsNumber = 0;
  BOOL mustAdjustNext = NO;
  float x = 0;
  
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
    backView = [item _backView];
    if ([item _isFlexibleSpace])
    {
      NSRect backViewFrame = [backView frame];
      
      [backView setFrame: NSMakeRect(x, backViewFrame.origin.y,
        lengthAvailable / flexibleSpaceItemsNumber, 
	backViewFrame.size.height)];
      mustAdjustNext = YES;
    }
    else if (mustAdjustNext)
    {
      NSRect backViewFrame = [backView frame];
      
      [backView setFrame: NSMakeRect(x, backViewFrame.origin.y,
        backViewFrame.size.width, backViewFrame.size.height)];
    }
    x += [backView frame].size.width;
  }
  
}

// Accessors private methods

- (float) _heightFromLayout
{    
  return _heightFromLayout;
}

- (NSArray *) _visibleBackViews
{
  NSArray *items = [_toolbar items];
  NSView *backView;
  int i, n = [items count];
  float backViewsWidth = 0, toolbarWidth = [self frame].size.width;
  /*
  // _willBeVisible indicates that the toolbar view previously hidden is in
  // process to become visible again before the end of current the event loop.
  if ([self superview] == nil && ![self _willBeVisible]) 
    return nil;
  */
  [_visibleBackViews release];
  _visibleBackViews = [[NSMutableArray alloc] init];
  
  for (i = 0; i < n; i++)
    {
      backView = [[items objectAtIndex:i] _backView];
  
      backViewsWidth += [backView frame].size.width;

      if ((backViewsWidth + _ClippedItemsViewWidth <= toolbarWidth)
        || (i == n - 1 && backViewsWidth <= toolbarWidth))
        {
          [_visibleBackViews addObject: backView];
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
