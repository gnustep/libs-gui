/** <title>NSDrawer</title>

   <abstract>The drawer class</abstract>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Douglas Simons <doug.simons@testplant.com>
   Date: 2009
   Author: Gregory Casamento <greg_casamento@yahoo.com>
   Date: 2006
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: 2001
   
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

#import <Foundation/NSCoder.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSException.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSTimer.h>
#import "AppKit/NSWindow.h"
#import "AppKit/NSBox.h"
#import "AppKit/NSView.h"
#import "AppKit/NSDrawer.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSScreen.h"

static NSNotificationCenter *nc = nil;

/* All live drawers, held without retaining them, so a window can report the
   drawers whose parent window it is. */
static NSHashTable *_drawers = nil;

@interface GSDrawerWindow : NSWindow
{
  NSWindow  *_parentWindow;
  NSWindow  *_pendingParentWindow;
  NSDrawer  *_drawer;
  id         _container;
  BOOL       _hasPendingParentWindow;
  NSSize     _borderSize;
  NSTimer   *_timer;
  NSRect     _latestParentFrame;
  BOOL       _wasOpen;
  NSRectEdge _currentEdge;
}

- (NSRect) frameFromParentWindowFrameInState:(NSInteger)state;
- (void) configureContainer: (NSRect)contentRect;
- (void) resetContentSize: (NSSize)size;
- (void) _resetWindowPosition;

// open/close
- (void) openOnEdge: (NSRectEdge)edge;
- (void) closeOnEdge: (NSRectEdge)edge;
- (void) closeOnEdge;
- (void) slideOpen: (BOOL)opening onEdge: (NSRectEdge)edge;
- (void) slideOpen: (BOOL)opening;
- (void) startTimer;
- (void) stopTimer;

// window/drawer properties
- (void) setParentWindow: (NSWindow *)window;
- (NSWindow *) parentWindow;
- (void) setPendingParentWindow: (NSWindow *)window;
- (NSWindow *) pendingParentWindow;
- (void) setDrawer: (NSDrawer *)drawer;
- (NSDrawer *) drawer;

// handle notifications...
- (void) handleWindowDidBecomeKey: (NSNotification *)notification;
- (void) handleWindowClose: (NSNotification *)notification;
- (void) handleWindowMiniaturize: (NSNotification *)notification;
- (void) handleWindowDeminiaturize: (NSNotification *)notification;
- (void) handleWindowMove: (NSNotification *)notification;

@end

@implementation GSDrawerWindow

+ (void) initialize
{
  if (self == [GSDrawerWindow class])
    {
      nc = [NSNotificationCenter defaultCenter];
      [self setVersion: 0];
    }
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (NSUInteger)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
{
  /* Measure the theme's trim before reducing the window to the requested
     content size.  A tiny initial box would clip its content to zero and
     underestimate the trim. */
  contentRect.size.width = MAX(100, contentRect.size.width);
  contentRect.size.height = MAX(100, contentRect.size.height);

  self = [super initWithContentRect: contentRect
			  styleMask: aStyle
			    backing: bufferingType
			      defer: flag];

  if (self != nil)
    {
      [self configureContainer: contentRect];
    }
  
  return self;
}

- (void) configureContainer: (NSRect)contentRect
{
  NSRect rect = NSMakeRect(0, 0, contentRect.size.width,
                           contentRect.size.height);
  NSSize containerContentSize;

  if (_container == nil)
    {
      _container = [[NSBox alloc] initWithFrame: rect];
      [[super contentView] addSubview: _container];
      RELEASE(_container);
      
      [_container setTitle: @""];
      [_container setTitlePosition: NSNoTitle];
      [_container setBorderType: NSLineBorder];
      [_container setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
      [_container setContentViewMargins: NSMakeSize(4, 4)];
    }
  else
    {
      [_container setFrame: rect];
    }

  // determine the difference between the container's content size and the window content size
  containerContentSize = [[_container contentView] frame].size;
  _borderSize = NSMakeSize(contentRect.size.width - containerContentSize.width,
			   contentRect.size.height - containerContentSize.height);
}

- (id) container
{
  return _container;
}

/* Keep the content size independent of the surrounding drawer trim. */
- (void) resetContentSize: (NSSize)size
{
  [self setContentSize: NSMakeSize(size.width + _borderSize.width,
                                 size.height + _borderSize.height)];
  [self _resetWindowPosition];
}

- (NSRect) frameFromParentWindowFrameInState: (NSInteger)state
{
  NSRect parent = [_parentWindow frame];
  NSRect content = [[_parentWindow contentView] convertRect:
    [[_parentWindow contentView] bounds] toView: nil];
  NSRect frame = parent;
  NSSize size = [_drawer contentSize];
  CGFloat leading = [_drawer leadingOffset];
  CGFloat trailing = [_drawer trailingOffset];
  BOOL opened = (state == NSDrawerOpenState || state == NSDrawerOpeningState);

  if (_currentEdge == NSMinXEdge || _currentEdge == NSMaxXEdge)
    {
      frame.size.width = opened ? size.width + _borderSize.width : 1;
      frame.size.height = MAX(_borderSize.height,
                              content.size.height - leading - trailing);
      frame.origin.y += NSMinY(content) + trailing;
      frame.origin.x = (_currentEdge == NSMinXEdge)
        ? NSMinX(parent) - (opened ? frame.size.width : 0)
        : NSMaxX(parent) - (opened ? 0 : frame.size.width);
    }
  else
    {
      frame.size.height = opened ? size.height + _borderSize.height : 1;
      frame.size.width = MAX(_borderSize.width,
                             content.size.width - leading - trailing);
      frame.origin.x += NSMinX(content) + leading;
      frame.origin.y = (_currentEdge == NSMinYEdge)
        ? NSMinY(parent) - (opened ? frame.size.height : 0)
        : NSMaxY(parent) - (opened ? 0 : frame.size.height);
    }
  return frame;
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (void) becomeKeyWindow
{
  [_parentWindow orderFrontRegardless]; // so clicking on the drawer will bring the parent to the front
  [super becomeKeyWindow];
}

- (void) startTimer
{
  NSTimeInterval time = 0.1;

  [self stopTimer];
  _timer = [NSTimer scheduledTimerWithTimeInterval: time
					    target: self
					  selector: @selector(_timedWindowReset)
					  userInfo: nil
					   repeats: YES];
}

- (void) stopTimer
{
  [_timer invalidate];
  _timer = nil;
}

- (void) orderFrontRegardless
{
  [self orderFront: self];
}

- (void) orderOut: (id)sender
{
  [super orderOut: sender];
}

// set the _container to not resize during the slide,
// and attach it to the appropriate edge instead
- (void) lockBorderBoxForSliding
{
  NSUInteger resizeMask = 0;

  if (_currentEdge == NSMinXEdge) // left
    {
      resizeMask = NSViewMaxXMargin;
    }
  else if (_currentEdge == NSMinYEdge) // bottom
    {
      resizeMask = NSViewMaxYMargin;
    }
  else if (_currentEdge == NSMaxXEdge) // right
    {
      resizeMask = NSViewMinXMargin;
    }
  else if (_currentEdge == NSMaxYEdge) // top
    {
      resizeMask = NSViewMinYMargin;
    }  

  // don't resize -- just give appearance of sliding
  [_container setAutoresizingMask: resizeMask];
}

- (void) unlockBorderBoxAfterSliding
{
  // set the _container to resize again
  [_container setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
}

// prepare drawer contents before sliding...
- (void) openOnEdge: (NSRectEdge)edge
{
  NSRect frame;

  _currentEdge = edge;
  frame = [self frameFromParentWindowFrameInState: NSDrawerOpenState];
  [self setFrame:frame display: YES]; // make sure it's the full (open) size before locking the borderBox
  if ([_parentWindow isVisible]) // don't order front until parent window is visible
    {
      [self lockBorderBoxForSliding];
      [self slideOpen: YES onEdge: edge];
      [self unlockBorderBoxAfterSliding];
    }
  [self startTimer];
}

- (void) openOnEdge
{
  [self openOnEdge: _currentEdge];
}

- (void) closeOnEdge: (NSRectEdge)edge
{
  NSRect frame;

  [self stopTimer];
  [self lockBorderBoxForSliding];
  [self slideOpen: NO onEdge: edge];
  [self orderOut: self];

  frame = [self frameFromParentWindowFrameInState:NSDrawerOpenState];
  [self setFrame:frame display: YES]; // make sure it's the full (open) size again (offscreen) before unlocking
  [self unlockBorderBoxAfterSliding];

  if (_hasPendingParentWindow)
    {
      [self setParentWindow: _pendingParentWindow];
      DESTROY(_pendingParentWindow);
      _hasPendingParentWindow = NO;
    }
}

- (void) closeOnEdge
{
  [self closeOnEdge: _currentEdge];
}

- (void) slideOpen: (BOOL)opening onEdge: (NSRectEdge)edge
{
  NSUInteger count = 10;
  NSRect frame = [self frameFromParentWindowFrameInState:
			    (opening ? NSDrawerClosedState : NSDrawerOpenState)];
  NSRect newFrame = [self frameFromParentWindowFrameInState:
			       (opening ? NSDrawerOpenState : NSDrawerClosedState)];
  NSTimeInterval slideDelay = 0.03;
  NSDate *nextStop = [NSDate dateWithTimeIntervalSinceNow:slideDelay];
  CGFloat deltaX = (newFrame.origin.x - frame.origin.x) / count;
  CGFloat deltaY = (newFrame.origin.y - frame.origin.y) / count;
  CGFloat deltaW = (newFrame.size.width - frame.size.width) / count;
  CGFloat deltaH = (newFrame.size.height - frame.size.height) / count;

  _currentEdge = edge;
  if (opening)
    {
      [self setFrame: frame display: NO];
      [self orderFront: self];
    }
  while (count--)
    {
      frame.origin.x += deltaX;
      frame.origin.y += deltaY;
      frame.size.width += deltaW;
      frame.size.height += deltaH;
      [self setFrame: frame display: YES];
      [NSThread sleepUntilDate:nextStop];
      nextStop = [nextStop addTimeInterval: slideDelay];
    }
  
  [self setFrame:newFrame display: YES];
}

- (void) slideOpen: (BOOL)opening
{
  [self slideOpen: opening onEdge: _currentEdge];
}

- (void) _resetWindowPosition
{
  if ([_drawer state] == NSDrawerClosedState
      || [_drawer state] == NSDrawerClosingState)
    return;

  if (![_parentWindow isVisible] || [_parentWindow isMiniaturized])
    {
      [self orderOut: self];
      return;
    }

  if ([_parentWindow isVisible])
    { 
      NSRect frame = [self frameFromParentWindowFrameInState:[_drawer state]]; 
      [self setFrame: frame display: YES];
      if (![self isVisible] && [_drawer state] != NSDrawerClosedState)
        [self orderFront:self];
    }
  if ([self isVisible] && [_parentWindow isKeyWindow]) // do our best to maintain proper window ordering
    {
      [super orderFrontRegardless];
      [_parentWindow orderFront:self];
    }
}

- (void) _timedWindowReset
{
  NSRect frame = [_parentWindow frame];
  if (!NSEqualRects(frame, _latestParentFrame)
      || [self isVisible] != ([_parentWindow isVisible]
                             && ![_parentWindow isMiniaturized]))
    {
      [self _resetWindowPosition];
      _latestParentFrame = frame;
    }
}

- (void) handleWindowClose: (NSNotification *)notification
{
  [self stopTimer];
  [_drawer close];
  [self orderOut: self];
}

- (void) handleWindowMiniaturize: (NSNotification *)notification
{
  _wasOpen = ([_drawer state] == NSDrawerOpenState);
  if (_wasOpen)
    {
      // It would be nice to call [self closeOnEdge] here, but the parent window is already closing
      // (with animation) so it doesn't look right to slide the drawer. So we'll do this instead:
      [self stopTimer];
      [self close];
    }
}

- (void) handleWindowDeminiaturize: (NSNotification *)notification
{
  if (_wasOpen)
    {
      //[self openOnEdge]; -- this also doesn't work: see comment above
      _latestParentFrame = NSMakeRect(0,0,0,0);
      [self startTimer];
    }
}

- (void) handleWindowMove: (NSNotification *)notification
{
  [self _resetWindowPosition];
}

- (void) handleWindowDidBecomeKey: (NSNotification *)notification
{
  if([_drawer state] == NSDrawerOpenState)
    {
      [self _resetWindowPosition];
    }
}

- (void) setParentWindow: (NSWindow *)window
{
  if (_parentWindow != window)
    {
      [super setParentWindow: window];
      ASSIGN(_parentWindow, window);
      [nc removeObserver: self];

      if (_parentWindow != nil)
	{
	  [self _resetWindowPosition];

	  // add observers....
	  [nc addObserver: self
	      selector: @selector(handleWindowClose:)
	      name: NSWindowWillCloseNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowMiniaturize:)
	      name: NSWindowWillMiniaturizeNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowDeminiaturize:)
	      name: NSWindowDidDeminiaturizeNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowMove:)
	      name: NSWindowWillMoveNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowMove:)
	      name: NSWindowDidResizeNotification
	      object: _parentWindow];
	  
	  [nc addObserver: self
	      selector: @selector(handleWindowDidBecomeKey:)
	      name: NSWindowDidBecomeKeyNotification
	      object: _parentWindow];
	}
    }
}

- (NSWindow *) parentWindow
{
  return _parentWindow;
}

- (void) setPendingParentWindow: (NSWindow *)window
{
  ASSIGN(_pendingParentWindow, window);
  _hasPendingParentWindow = YES;
}

- (NSWindow *) pendingParentWindow
{
  return _pendingParentWindow;
}

- (void) setDrawer: (NSDrawer *)drawer
{
  // don't retain, since the drawer retains us...
  _drawer = drawer;
}

- (NSDrawer *) drawer
{
  return _drawer;
}

- (void) dealloc
{
  [self stopTimer];
  RELEASE(_parentWindow);
  [nc removeObserver: self];
  TEST_RELEASE(_pendingParentWindow);
  DEALLOC;
}

@end

@implementation NSDrawer

+ (void) initialize
{
  if (self == [NSDrawer class])
    {
      nc = [NSNotificationCenter defaultCenter];
      _drawers = [[NSHashTable alloc] initWithOptions:
	NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality
					     capacity: 4];
      [self setVersion: 0];
    }
}

+ (NSArray *) _drawersForParentWindow: (NSWindow *)window
{
  NSMutableArray *result = [NSMutableArray array];
  NSEnumerator *e = [_drawers objectEnumerator];
  NSDrawer *d;

  while ((d = [e nextObject]) != nil)
    {
      if ([d parentWindow] == window)
	{
	  [result addObject: d];
	}
    }
  return result;
}

// Creation
- (id) init
{
  return [self initWithContentSize: NSMakeSize(100,100)
	       preferredEdge: NSMinXEdge];
}

- (id) initWithContentSize: (NSSize)contentSize 
	     preferredEdge: (NSRectEdge)edge
{  
  self = [super init];

  if (self != nil)
    {
        NSRect rect = NSMakeRect(0, 0, contentSize.width, contentSize.height);

	// initialize the drawer window...  
	_drawerWindow =  [[GSDrawerWindow alloc] 
			     initWithContentRect: rect
				       styleMask: 0
					 backing: NSBackingStoreBuffered
					   defer: NO];
	[_drawerWindow setDrawer: self];
	[_drawerWindow setReleasedWhenClosed: NO];
	
	_preferredEdge = edge;
	_currentEdge = edge;
	_maxContentSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
	_minContentSize = NSZeroSize;
	_contentSize = contentSize;
	[_drawerWindow resetContentSize: contentSize];
	
	// for side drawers, top of drawer is immediately below the title bar
	if (edge == NSMinXEdge || edge == NSMaxXEdge)
	  {
	    _leadingOffset = 0.0;
	    _trailingOffset = 10.0;
	  }
	else
	  { 
	    _leadingOffset = 10.0;
	    _trailingOffset = 10.0;
	  }
	
	_state = NSDrawerClosedState;
	[_drawers addObject: self];
    }

  return self;
}

- (void) dealloc
{
  [_drawers removeObject: self];
  [_drawerWindow stopTimer];
  [_drawerWindow orderOut: nil];
  [_drawerWindow setDrawer: nil];
  RELEASE(_drawerWindow);
  if (_delegate != nil)
    {
      [nc removeObserver: _delegate name: nil object: self];
      _delegate = nil;
    }
  DEALLOC;
}

// Opening and Closing
- (NSRectEdge) _computeEdge
{
  NSRectEdge result = _preferredEdge;
  NSRect windowFrame = [[self parentWindow] frame];
  NSScreen *screen = [[self parentWindow] screen];
  NSRect screenRect = [(screen != nil ? screen : [NSScreen mainScreen])
    visibleFrame];
  NSSize contentSize = [self contentSize];
  
  // Diffs,,,
  CGFloat top = NSMaxY(screenRect) - NSMaxY(windowFrame);
  CGFloat bottom = NSMinY(windowFrame) - NSMinY(screenRect);
  CGFloat right = NSMaxX(screenRect) - NSMaxX(windowFrame);
  CGFloat left = NSMinX(windowFrame) - NSMinX(screenRect);

  // Space left...
  CGFloat topSpace = top - contentSize.height;
  CGFloat bottomSpace = bottom - contentSize.height;
  CGFloat rightSpace = right - contentSize.width;
  CGFloat leftSpace = left - contentSize.width;
  
  switch (_preferredEdge)
    {
    case NSMinXEdge:
      if (leftSpace < 0.0 && rightSpace > leftSpace)
	{
	  result = NSMaxXEdge;
	}
      break;
      
    case NSMinYEdge:
      if (bottomSpace < 0.0 && topSpace > bottomSpace)
	{
	  result = NSMaxYEdge;
	}
      break;
      
    case NSMaxXEdge:
      if (rightSpace < 0.0 && leftSpace > rightSpace)
	{
	  result = NSMinXEdge;
	}
      break;
      
    case NSMaxYEdge:
      if (topSpace < 0.0 && bottomSpace > topSpace)
	{
	  result = NSMinYEdge;
	}
      break;
    }

  return result;
}

- (void) close
{
  if (_state != NSDrawerOpenState)
    return;

  if ((_delegate != nil)
    && ([_delegate respondsToSelector: @selector(drawerShouldClose:)])
    && ![_delegate drawerShouldClose: self])
    return;

  _state = NSDrawerClosingState;
  [nc postNotificationName: NSDrawerWillCloseNotification object: self];

  [_drawerWindow closeOnEdge];

  _state = NSDrawerClosedState;
  [nc postNotificationName: NSDrawerDidCloseNotification object: self];
}

- (void) close: (id)sender
{
  [self close];
}

- (void) open
{
  NSRectEdge edge = [self _computeEdge];
  [self openOnEdge: edge];
}

- (void) open: (id)sender
{
  [self open];
}

- (void) openOnEdge: (NSRectEdge)edge
{
  if ((_state != NSDrawerClosedState)
    || ([self parentWindow] == nil))
    return;

  if ((_delegate != nil)
    && ([_delegate respondsToSelector: @selector(drawerShouldOpen:)])
    && ![_delegate drawerShouldOpen: self])
    return;

  _currentEdge = edge;
  _state = NSDrawerOpeningState;
  [nc postNotificationName: NSDrawerWillOpenNotification object: self];

  [_drawerWindow openOnEdge: edge]; 
  
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
  if (_state == NSDrawerOpenState)
    return [[self contentView] frame].size;
  return _contentSize;
}

- (CGFloat) leadingOffset
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
  // Check with delegate
  if ((_delegate != nil)
    && ([_delegate respondsToSelector:
      @selector(drawerWillResizeContents:toSize:)]))
    {
      size = [_delegate drawerWillResizeContents: self
					  toSize: size];
    }

  size.width = MAX(_minContentSize.width, MIN(size.width, _maxContentSize.width));
  size.height = MAX(_minContentSize.height, MIN(size.height, _maxContentSize.height));
  _contentSize = size;
  [_drawerWindow resetContentSize: size];
}

- (void) setLeadingOffset: (CGFloat)offset
{
  _leadingOffset = offset;
  [_drawerWindow _resetWindowPosition];
}

- (void) setMaxContentSize: (NSSize)size
{
  _maxContentSize = size;
}

- (void) setMinContentSize: (NSSize)size
{
  _minContentSize = size;
}

- (void) setTrailingOffset: (CGFloat)offset
{
  _trailingOffset = offset;
  [_drawerWindow _resetWindowPosition];
}

- (CGFloat) trailingOffset
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
  return [[_drawerWindow container] contentView];
}

- (NSWindow *) parentWindow
{
  return [_drawerWindow parentWindow];
}

- (void) setContentView: (NSView *)aView
{
  [[_drawerWindow container] setContentView: aView];
}

- (void) setParentWindow: (NSWindow *)parent
{
  if (_state == NSDrawerClosedState)
    {
      [_drawerWindow setParentWindow: parent];
    }
  else
    {
      [_drawerWindow setPendingParentWindow: parent];
    }
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

- (NSInteger) state
{
  return _state;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  id parent = [self parentWindow];

  [super encodeWithCoder: aCoder];
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeSize: [self contentSize] forKey: @"NSContentSize"];

      if (_delegate != nil)
	{
	  [aCoder encodeObject: _delegate forKey: @"NSDelegate"];
	}

      [aCoder encodeFloat: _leadingOffset forKey: @"NSLeadingOffset"];
      [aCoder encodeSize: _maxContentSize forKey: @"NSMaxContentSize"];
      [aCoder encodeSize: _minContentSize forKey: @"NSMinContentSize"];
      
      if (parent != nil)
	{
	  [aCoder encodeObject: parent forKey: @"NSParentWindow"];
	}

      [aCoder encodeInt: _preferredEdge forKey: @"NSPreferredEdge"];
      [aCoder encodeFloat: _trailingOffset forKey: @"NSTrailingOffset"];
    }
  else
    {
      [aCoder encodeSize: [self contentSize]];
      [aCoder encodeObject: _delegate];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_leadingOffset];
      [aCoder encodeSize: _maxContentSize];
      [aCoder encodeSize: _minContentSize];
      [aCoder encodeObject: parent];
      [aCoder encodeValueOfObjCType: @encode(unsigned) at: &_preferredEdge];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_trailingOffset];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ((self = [super initWithCoder: aDecoder]) != nil)
    {
      NSWindow *parentWindow = nil;
      
      if ([aDecoder allowsKeyedCoding])
	{
	  _contentSize = [aDecoder decodeSizeForKey: @"NSContentSize"];

	  if ([aDecoder containsValueForKey: @"NSDelegate"])
	    {
	      _delegate = [aDecoder decodeObjectForKey: @"NSDelegate"];
	    }

	  _leadingOffset = [aDecoder decodeFloatForKey: @"NSLeadingOffset"];
	  _maxContentSize = [aDecoder decodeSizeForKey: @"NSMaxContentSize"];
	  _minContentSize = [aDecoder decodeSizeForKey: @"NSMinContentSize"];
	  
	  if ([aDecoder containsValueForKey: @"NSParentWindow"])
	    {
	      parentWindow = [aDecoder decodeObjectForKey: @"NSParentWindow"];
	    }

	  _preferredEdge = [aDecoder decodeIntForKey: @"NSPreferredEdge"];
	  _trailingOffset = [aDecoder decodeFloatForKey: @"NSTrailingOffset"];
	}
      else
	{
	  int version = [aDecoder versionForClassName: @"NSDrawer"];
	  if (version == 0)
	    {
	      _contentSize = [aDecoder decodeSize];
	      _delegate = [aDecoder decodeObject];
	      [aDecoder decodeValueOfObjCType: @encode(float)
					   at: &_leadingOffset];
	      _maxContentSize = [aDecoder decodeSize];
	      _minContentSize = [aDecoder decodeSize];
	      parentWindow = [aDecoder decodeObject];
	      [aDecoder decodeValueOfObjCType: @encode(unsigned)
					   at: &_preferredEdge];
	      [aDecoder decodeValueOfObjCType: @encode(float)
					   at: &_trailingOffset];	      
	    }
	  else      
	    {
	      [NSException raise: NSInternalInconsistencyException
		format: @"Invalid version of NSDrawer (version = %d).",
		version];
	      return nil; // not reached, but keeps gcc happy...
	    }
	}

      // set up drawer...
      _drawerWindow =  [[GSDrawerWindow alloc] 
			 initWithContentRect:  
			   NSMakeRect(0, 0,_contentSize.width,
				      _contentSize.height)
			 styleMask: 0
			 backing: NSBackingStoreBuffered
			 defer: NO];
      [_drawerWindow setDrawer: self];
      [_drawerWindow resetContentSize: _contentSize];
      [_drawerWindow setParentWindow: parentWindow];
      [_drawerWindow setReleasedWhenClosed: NO];

      // initial state...
      _state = NSDrawerClosedState;
      _currentEdge = _preferredEdge;
      [self setDelegate: _delegate];
      [_drawers addObject: self];
  
    }
  return self;
}

@end
