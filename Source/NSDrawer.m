/** <title>NSDrawer</title>

   <abstract>The drawer class</abstract>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: 2001
   
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

#include <Foundation/NSCoder.h>
#include <Foundation/NSNotification.h>
#include "AppKit/NSWindow.h"
#include "AppKit/NSView.h"
#include "AppKit/NSDrawer.h"

static NSNotificationCenter *nc = nil;

@implementation NSDrawer

+ (void) initialize
{
  if (self == [NSDrawer class])
    {
      nc = [NSNotificationCenter defaultCenter];
      [self setVersion: 1];
    }
}

// Creation
- (id) init
{
  return [self initWithContentSize: NSZeroSize
	       preferredEdge: NSMinXEdge];
}

- (id) initWithContentSize: (NSSize)contentSize 
	     preferredEdge: (NSRectEdge)edge
{
  self = [super init];

  _contentView = [[NSView alloc] initWithFrame: 
				     NSMakeRect(0, 0, contentSize.width,  
						contentSize.height)];
  _preferredEdge = edge;
  _currentEdge = edge;
  _maxContentSize = contentSize;
  _minContentSize = contentSize;
  _state = NSDrawerClosedState;

  return self;
}

- (void) dealloc
{
  RELEASE(_contentView);

  if (_delegate != nil)
    {
      [nc removeObserver: _delegate name: nil object: self];
      _delegate = nil;
    }

  [super dealloc];
}

// Opening and Closing
- (void) close
{
  if (_state != NSDrawerOpenState)
    return;

  if ((_delegate != nil) && 
      ([_delegate respondsToSelector:
		      @selector(drawerShouldClose:)]) &&
      ![_delegate drawerShouldClose: self])
    return;

  _state = NSDrawerClosingState;
  [nc postNotificationName: NSDrawerWillCloseNotification object: self];

  // FIXME Here should be the actual closing code

  _state = NSDrawerClosedState;
  [nc postNotificationName: NSDrawerDidCloseNotification object: self];
}

- (void) close: (id)sender
{
  [self close];
}

- (void) open
{
  [self openOnEdge: _preferredEdge];
}

- (void) open: (id)sender
{
  [self open];
}

- (void) openOnEdge: (NSRectEdge)edge
{
  if ((_state != NSDrawerClosedState) || 
      (_parentWindow == nil))
    return;

  if ((_delegate != nil) && 
      ([_delegate respondsToSelector:
		      @selector(drawerShouldOpen:)]) &&
      ![_delegate drawerShouldOpen: self])
    return;

  _state = NSDrawerOpeningState;
  [nc postNotificationName: NSDrawerWillOpenNotification object: self];

  // FIXME Here should be the actual opening code
  _currentEdge = edge;

  _state = NSDrawerOpenState;
  [nc postNotificationName: NSDrawerDidOpenNotification object: self];
}

- (void) toggle: (id)sender
{
  if (_state == NSDrawerClosedState)
    [self open: sender];
  else if (_state == NSDrawerOpenState)
    [self close: sender];
  // Do nothing for inbetween states
}

// Managing Size
- (NSSize) contentSize
{
  return [_contentView frame].size;
}

- (float) leadingOffset
{
  return _leadingOffset;
}

- (NSSize) maxContentSize
{
  return _maxContentSize; 
}

- (NSSize) minContentSize
{
  return _minContentSize;
}

- (void) setContentSize: (NSSize)size
{
  // Check with min and max size
  if (size.width < _minContentSize.width)
    size.width = _minContentSize.width;
  if (size.height < _minContentSize.height)
    size.height = _minContentSize.height;
  if (size.width > _maxContentSize.width)
    size.width = _maxContentSize.width;
  if (size.height > _maxContentSize.height)
    size.height = _maxContentSize.height;

  // Check with delegate
  if ((_delegate != nil) && 
      ([_delegate respondsToSelector:
		      @selector(drawerWillResizeContents:toSize:)]))
    size = [_delegate drawerWillResizeContents: self
		      toSize: size];

  [_contentView setFrameSize: size];
}

- (void) setLeadingOffset: (float)offset
{
  _leadingOffset = offset;
}

- (void) setMaxContentSize: (NSSize)size
{
  _maxContentSize = size;
}

- (void) setMinContentSize: (NSSize)size
{
  _minContentSize = size;
}

- (void) setTrailingOffset: (float)offset
{
  _trailingOffset = offset;
}

- (float) trailingOffset
{
  return _trailingOffset;
}

// Managing Edge
- (NSRectEdge) edge
{
  return _currentEdge;
}

- (NSRectEdge) preferredEdge
{
  return _preferredEdge;
}

- (void) setPreferredEdge: (NSRectEdge)preferredEdge
{
  _preferredEdge = preferredEdge;
}

// Managing Views
- (NSView *) contentView
{
  return _contentView;
}

- (NSWindow *) parentWindow
{
  return _parentWindow;
}

- (void) setContentView: (NSView *)aView
{
  ASSIGN(_contentView, aView);
}

- (void) setParentWindow: (NSWindow *)parent
{
  _parentWindow = parent; 
}

 
// Delegation and State
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)anObject
{
  if (_delegate)
    {
      [nc removeObserver: _delegate name: nil object: self];
    }

  _delegate = anObject; 

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(drawer##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(drawer##notif_name:) \
      name: NSDrawer##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidClose);
  SET_DELEGATE_NOTIFICATION(DidOpen);
  SET_DELEGATE_NOTIFICATION(WillClose);
  SET_DELEGATE_NOTIFICATION(WillOpen);
}

- (int) state
{
  return _state;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
//FIXME
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
//FIXME
  return self;
}

@end
