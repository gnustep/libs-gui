/** <title>GSTitleView</title>

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Serg Stoyan <stoyan@on.com.ua>
   Date:   Mar 2003
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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
#include <Foundation/NSRunLoop.h>

#include <AppKit/NSApplication.h>
#include "AppKit/NSAttributedString.h"
#include <AppKit/NSButton.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

#include <GNUstepGUI/GSTitleView.h>
#include "GNUstepGUI/GSTheme.h"

@implementation GSTitleView

// ============================================================================
// ==== Initialization & deallocation
// ============================================================================

+ (float) height
{
  static float height = 0.0;

  if (height == 0.0)
    {
      NSFont *font = [NSFont menuFontOfSize: 0.0];

      /* Minimum title height is 23 */
      height = ([font boundingRectForFont].size.height) + 9;
      if (height < 23)
	{
	  height = 23;
	}
    }

  return height;
}

- (id) init
{
  self = [super init];

  _owner = nil;
  _ownedByMenu = NO;
  _hasCloseButton = NO;
  _hasMiniaturizeButton = NO;
  _isKeyWindow = NO;
  _isMainWindow = NO;
  _isActiveApplication = NO;

  [self setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  textAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
    [NSFont boldSystemFontOfSize: 0], NSFontAttributeName,
    [NSColor blackColor], NSForegroundColorAttributeName, nil];

  titleColor = RETAIN ([NSColor lightGrayColor]);

  return self;
}

- (id) initWithOwner: (id)owner
{
  [self init];
  [self setOwner: owner];

  return self;
}

- (void) setOwner: (id)owner
{
  NSNotificationCenter *theCenter = [NSNotificationCenter defaultCenter];

  if ([owner isKindOfClass:[NSWindow class]])
    {
      NSDebugLLog(@"GSTitleView", @"owner is NSWindow or NSPanel");
      _owner = owner;
      _ownedByMenu = NO;

      [self setFrame: 
        NSMakeRect (-1, [_owner frame].size.height - [GSTitleView height]-40,
                    [_owner frame].size.width+2, [GSTitleView height])];

      if ([_owner styleMask] & NSClosableWindowMask)
	{
	  [self addCloseButtonWithAction:@selector (performClose:)];
	}
      if ([_owner styleMask] & NSMiniaturizableWindowMask)
	{
	  [self addMiniaturizeButtonWithAction:@selector (performMiniaturize:)];
	}

      // NSWindow observers
      [theCenter addObserver: self
                    selector: @selector(windowBecomeKey:)
                        name: NSWindowDidBecomeKeyNotification
                      object: _owner];
      [theCenter addObserver: self
                    selector: @selector(windowResignKey:)
                        name: NSWindowDidResignKeyNotification
                      object: _owner];
      [theCenter addObserver: self
                    selector: @selector(windowBecomeMain:)
                        name: NSWindowDidBecomeMainNotification
                      object: _owner];
      [theCenter addObserver: self
                    selector: @selector(windowResignMain:)
                        name: NSWindowDidResignMainNotification
                      object: _owner];

      // NSApplication observers
      [theCenter addObserver: self
                    selector: @selector(applicationBecomeActive:)
                        name: NSApplicationWillBecomeActiveNotification
                      object: NSApp];
      [theCenter addObserver: self
                    selector: @selector(applicationResignActive:)
                        name: NSApplicationWillResignActiveNotification
                      object: NSApp];
    }
  else if ([owner isKindOfClass:[NSMenu class]])
    {
      NSDebugLLog(@"GSTitleView", @"owner is NSMenu");
      _owner = owner;
      _ownedByMenu = YES;

      RELEASE (titleColor);
      titleColor = RETAIN ([NSColor blackColor]);
      [textAttributes setObject: [NSColor whiteColor] 
                         forKey: NSForegroundColorAttributeName];
    }
  else
    {
      NSDebugLLog(@"GSTitleView", 
		  @"%@ owner is not NSMenu or NSWindow or NSPanel",
		  [owner className]);
      return;
    }
}

- (id) owner
{
  return _owner;
}

- (void) dealloc
{
  if (!_ownedByMenu)
    {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
    }

  RELEASE (textAttributes);
  RELEASE (titleColor);

  [super dealloc];
}

// ============================================================================
// ==== Drawing
// ============================================================================

- (NSSize) titleSize
{
  return [[_owner title] sizeWithAttributes: textAttributes];
}

- (void) drawRect: (NSRect)rect
{
  GSTheme    *theme = [GSTheme theme];
  NSRect     workRect = [self bounds];
  NSSize     titleSize;
  NSRectEdge top_left[] = {NSMinXEdge, NSMaxYEdge};
  NSRectEdge bottom_right[] = {NSMaxXEdge, NSMinYEdge};
  float      blacks[] = {NSBlack, NSBlack};
  float      grays[] = {NSLightGray, NSLightGray};
  float      darkGrays[] = {NSDarkGray, NSDarkGray};

  // Draw the dark gray upper left lines for menu and black for others.
  // Rectangle 1
  if (_ownedByMenu)
    workRect = NSDrawTiledRects(workRect, workRect, top_left, darkGrays, 2);
  else
    workRect = NSDrawTiledRects(workRect, workRect, top_left, blacks, 2);


  // Rectangle 2
  // Draw the title box's button.
  [theme drawButton: workRect withClip: workRect];

  // Overdraw white top and left lines with light gray lines for window title
  workRect.origin.y += 1;
  workRect.size.height -= 1;
  workRect.size.width -= 1;
  if (!_ownedByMenu && (_isKeyWindow || _isMainWindow))
    {
      NSDrawTiledRects(workRect, workRect, top_left, grays, 2);
    }
 
  // Rectangle 3
  // Paint background
  workRect.origin.x += 1;
  workRect.origin.y += 1;
  workRect.size.height -= 2;
  workRect.size.width -= 2;

  [titleColor set];
  NSRectFill(workRect);

  if (!_ownedByMenu && _isMainWindow && !_isKeyWindow)
    {
      NSRect blRect = workRect;

      blRect.origin.y -= 1;
      blRect.size.width += 1;
      blRect.size.height += 1;
      NSDrawTiledRects(blRect, blRect, bottom_right, blacks, 2);
    }
  
  // Draw the title
  titleSize = [self titleSize];
  if (_ownedByMenu)
    {
      workRect.origin.x += 4;
    }
  else
    {
      workRect.origin.x += NSMidX (workRect) - titleSize.width / 2;
    }
  workRect.origin.y = NSMidY (workRect) - titleSize.height / 2;
  workRect.size.height = titleSize.height;
  [[_owner title] drawInRect: workRect  withAttributes: textAttributes];
}

// ============================================================================
// ==== Mouse actions
// ============================================================================

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
} 
 
- (void) mouseDown: (NSEvent*)theEvent
{
  NSPoint  lastLocation;
  NSPoint  location;
  unsigned eventMask = NSLeftMouseUpMask | NSPeriodicMask;
  BOOL     done = NO;
  BOOL	   moved = NO;
  NSDate   *theDistantFuture = [NSDate distantFuture];
  NSPoint  startWindowOrigin;
  NSPoint  endWindowOrigin;

  NSDebugLLog (@"NSMenu", @"Mouse down in title!");

  // Remember start position of window
  startWindowOrigin = [_window frame].origin;

  // Remember start location of cursor in window
  lastLocation = [theEvent locationInWindow];

  [_window _captureMouse: nil];
  
  [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.02];

  while (!done)
    {
      theEvent = [NSApp nextEventMatchingMask: eventMask
                                    untilDate: theDistantFuture
                                       inMode: NSEventTrackingRunLoopMode
                                      dequeue: YES];
      switch ([theEvent type])
        {
        case NSRightMouseUp:
        case NSLeftMouseUp: 
          done = YES; 
          [_window _releaseMouse: nil];
          break;
        case NSPeriodic:
          location = [_window mouseLocationOutsideOfEventStream];
          if (NSEqualPoints(location, lastLocation) == NO)
            {
              NSPoint origin = [_window frame].origin;

	      moved = YES;
              origin.x += (location.x - lastLocation.x);
              origin.y += (location.y - lastLocation.y);
	      if (_ownedByMenu)
		{
		  [_owner nestedSetFrameOrigin: origin];
		}
	      else
		{
		  [_owner setFrameOrigin: origin];
		}
            }
          break;

        default: 
          break;
        }
    }

  // Make menu torn off
  if (_ownedByMenu && ![_owner isTornOff] && [_owner supermenu])
    {
      endWindowOrigin = [_window frame].origin;
      if ((startWindowOrigin.x != endWindowOrigin.x 
	   || startWindowOrigin.y != endWindowOrigin.y))
	{
	  [_owner setTornOff: YES];
	}
    }

  [NSEvent stopPeriodicEvents];

  if (moved == YES)
    {
      // Let everything know the window has moved.
      [[NSNotificationCenter defaultCenter]
	postNotificationName: NSWindowDidMoveNotification object: _window];
    }
}

// We do not need app menu over menu
- (void) rightMouseDown: (NSEvent*)theEvent
{
}

// We do not want to popup menus in this menu.
- (NSMenu *) menuForEvent: (NSEvent*) theEvent
{
  return nil;
}

// ============================================================================
// ==== NSWindow & NSApplication notifications
// ============================================================================

- (void) applicationBecomeActive: (NSNotification *)notification
{
  _isActiveApplication = YES;
}

- (void) applicationResignActive: (NSNotification *)notification
{
  _isActiveApplication = NO;
  RELEASE (titleColor);
  titleColor = RETAIN ([NSColor lightGrayColor]);
  [textAttributes setObject: [NSColor blackColor] 
                     forKey: NSForegroundColorAttributeName];
  [self setNeedsDisplay: YES];
}

- (void) windowBecomeKey: (NSNotification *)notification
{
  _isKeyWindow = YES;
  RELEASE (titleColor);
  titleColor = RETAIN ([NSColor blackColor]);
  [textAttributes setObject: [NSColor whiteColor] 
                     forKey: NSForegroundColorAttributeName];

  [self setNeedsDisplay: YES];
}

- (void) windowResignKey: (NSNotification *)notification
{
  _isKeyWindow = NO;
  RELEASE (titleColor);
  if (_isActiveApplication && _isMainWindow)
    {
      titleColor = RETAIN ([NSColor darkGrayColor]);
      [textAttributes setObject: [NSColor whiteColor] 
                         forKey: NSForegroundColorAttributeName];
    }
  else
    {
      titleColor = RETAIN ([NSColor lightGrayColor]);
      [textAttributes setObject: [NSColor blackColor] 
                         forKey: NSForegroundColorAttributeName];
    }
  [self setNeedsDisplay: YES];
}

- (void) windowBecomeMain: (NSNotification *)notification 
{
  _isMainWindow = YES;
}

- (void) windowResignMain: (NSNotification *)notification 
{
  _isMainWindow = NO;
}

// ============================================================================
// ==== Buttons
// ============================================================================

- (NSButton *) _createButtonWithImage: (NSImage *)image
                       highlightImage: (NSImage *)imageH
                               action: (SEL)action
{
  NSButton *button;
  NSSize   imageSize = [image size]; 
  NSRect   rect = NSMakeRect (0, 0, imageSize.width+3, imageSize.height+3);

  button = [[NSButton alloc] initWithFrame: rect];
  [button setRefusesFirstResponder: YES];
  [button setButtonType: NSMomentaryChangeButton];
  [button setImagePosition: NSImageOnly];
  [button setBordered: YES];
  [button setAutoresizingMask: NSViewMaxXMargin | NSViewMaxYMargin];
  [button setImage: image];
  [button setAlternateImage: imageH];
  [button setTarget: _owner];
  [button setAction: action];

  return button;
}
            
- (void) addCloseButtonWithAction: (SEL)closeAction
{
  if (closeButton == nil)
    {
      NSImage *closeImage = [NSImage imageNamed: @"common_Close"];
      NSImage *closeHImage = [NSImage imageNamed: @"common_CloseH"];

      NSSize viewSize;
      NSSize buttonSize;
      
      closeButton = [self _createButtonWithImage: closeImage 
                                  highlightImage: closeHImage
                                          action: closeAction];

      viewSize = [self frame].size;
      buttonSize = [closeButton frame].size;

      // Update location
      [closeButton setFrameOrigin:
        NSMakePoint (viewSize.width - buttonSize.width - 4,
                     (viewSize.height - buttonSize.height) / 2)];

      [closeButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
    }

  if ([closeButton superview] == nil)
    {
      [self addSubview: closeButton];
      RELEASE (closeButton);
      [self setNeedsDisplay: YES];
    }
}

- (NSButton *) closeButton
{
  return closeButton;
}

- (void) removeCloseButton
{
  if ([closeButton superview] != nil)
    {
      RETAIN (closeButton);
      [closeButton removeFromSuperview];
    }
}

- (void) addMiniaturizeButtonWithAction: (SEL)miniaturizeAction
{
  if (miniaturizeButton == nil)
    {
      NSImage *miniImage = [NSImage imageNamed: @"common_Miniaturize"];
      NSImage *miniHImage = [NSImage imageNamed: @"common_MiniaturizeH"];

      NSSize viewSize;
      NSSize buttonSize;
      
      miniaturizeButton = [self _createButtonWithImage: miniImage
                                        highlightImage: miniHImage
                                                action: miniaturizeAction];

      viewSize = [self frame].size;
      buttonSize = [miniaturizeButton frame].size;

      // Update location
      [miniaturizeButton setFrameOrigin:
        NSMakePoint (4, (viewSize.height - buttonSize.height) / 2)];

      [miniaturizeButton setAutoresizingMask: 
        NSViewMaxXMargin | NSViewMaxYMargin];
    }
    
  if ([miniaturizeButton superview] == nil)
    {
      [self addSubview: miniaturizeButton];
      RELEASE (miniaturizeButton);
      [self setNeedsDisplay: YES];
    }
}

- (NSButton *) miniaturizeButton
{
  return miniaturizeButton;
}

- (void) removeMiniaturizeButton
{
  if ([miniaturizeButton superview] != nil)
    {
      RETAIN (miniaturizeButton);
      [miniaturizeButton removeFromSuperview];
    }
}

@end 

