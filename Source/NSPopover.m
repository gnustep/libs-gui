/*
   NSPopover.m

   The popover class

   Copyright (C) 2013 Free Software Foundation, Inc.

   Author:  Gregory Casamento <greg.casamento@gmail.com>
   Date: 2013

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

#import <Foundation/NSArchiver.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSNotification.h>

#import "AppKit/NSPopover.h"
#import "AppKit/NSViewController.h"
#import "AppKit/NSView.h"
#import "AppKit/NSPanel.h"
#import "AppKit/NSNibLoading.h"
#import "AppKit/NSStoryboard.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSBezierPath.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSBitmapImageRep.h"
#import "GNUstepGUI/GSDisplayServer.h"

// Popover private classes

/* The arrow is part of the panel, outside the controller's content view. */
static const CGFloat GSPopoverArrowSize = 12.0;

@interface GSPopoverView : NSView
{
  NSRectEdge _edge;
}

- (void) setEdge: (NSRectEdge)edge;
- (NSRect) bodyRect;
- (NSBezierPath *) outlinePath;

@end

@implementation GSPopoverView

- (void) setEdge: (NSRectEdge)edge
{
  _edge = edge;
  [self setNeedsDisplay: YES];
}

- (NSRect) bodyRect
{
  NSRect rect = [self bounds];

  if (_edge == NSMinXEdge || _edge == NSMaxXEdge)
    {
      rect.size.width -= GSPopoverArrowSize;
      if (_edge == NSMaxXEdge)
        rect.origin.x += GSPopoverArrowSize;
    }
  else
    {
      rect.size.height -= GSPopoverArrowSize;
      if (_edge == NSMaxYEdge)
        rect.origin.y += GSPopoverArrowSize;
    }
  return rect;
}

- (BOOL) isOpaque
{
  return NO;
}

- (NSBezierPath *) outlinePath
{
  NSRect body = NSInsetRect([self bodyRect], 0.5, 0.5);
  NSBezierPath *path = [NSBezierPath bezierPath];
  CGFloat halfWidth = MIN(GSPopoverArrowSize,
    MIN(NSWidth(body), NSHeight(body)) / 2);

  [path moveToPoint: NSMakePoint(NSMinX(body), NSMinY(body))];
  if (_edge == NSMaxYEdge)
    {
      [path lineToPoint: NSMakePoint(NSMidX(body) - halfWidth, NSMinY(body))];
      [path lineToPoint: NSMakePoint(NSMidX(body), 0.5)];
      [path lineToPoint: NSMakePoint(NSMidX(body) + halfWidth, NSMinY(body))];
    }
  [path lineToPoint: NSMakePoint(NSMaxX(body), NSMinY(body))];
  if (_edge == NSMinXEdge)
    {
      [path lineToPoint: NSMakePoint(NSMaxX(body), NSMidY(body) - halfWidth)];
      [path lineToPoint: NSMakePoint(NSMaxX([self bounds]) - 0.5, NSMidY(body))];
      [path lineToPoint: NSMakePoint(NSMaxX(body), NSMidY(body) + halfWidth)];
    }
  [path lineToPoint: NSMakePoint(NSMaxX(body), NSMaxY(body))];
  if (_edge == NSMinYEdge)
    {
      [path lineToPoint: NSMakePoint(NSMidX(body) + halfWidth, NSMaxY(body))];
      [path lineToPoint: NSMakePoint(NSMidX(body), NSMaxY([self bounds]) - 0.5)];
      [path lineToPoint: NSMakePoint(NSMidX(body) - halfWidth, NSMaxY(body))];
    }
  [path lineToPoint: NSMakePoint(NSMinX(body), NSMaxY(body))];
  if (_edge == NSMaxXEdge)
    {
      [path lineToPoint: NSMakePoint(NSMinX(body), NSMidY(body) + halfWidth)];
      [path lineToPoint: NSMakePoint(0.5, NSMidY(body))];
      [path lineToPoint: NSMakePoint(NSMinX(body), NSMidY(body) - halfWidth)];
    }
  [path closePath];
  [path setLineWidth: 1.0];
  [path setLineJoinStyle: NSRoundLineJoinStyle];
  return path;
}

- (void) drawRect: (NSRect)dirtyRect
{
  NSBezierPath *path = [self outlinePath];

  [[NSColor clearColor] set];
  NSRectFillUsingOperation(dirtyRect, NSCompositeCopy);
  [[NSColor windowBackgroundColor] set];
  [path fill];
  [[NSColor darkGrayColor] set];
  [path stroke];
}

@end

@interface GSPopoverPanel : NSPanel

- (void) setPopoverView: (NSView *)view edge: (NSRectEdge)edge;

@end

@implementation GSPopoverPanel

- (id) initWithContentRect: (NSRect)contentRect
                 styleMask: (NSUInteger)aStyle
                   backing: (NSBackingStoreType)bufferingType
                     defer: (BOOL)flag
{
  self = [super initWithContentRect: contentRect
                          styleMask: aStyle
                            backing: bufferingType
                              defer: flag];
  if (self)
    {
      [super setContentView: AUTORELEASE([[GSPopoverView alloc]
        initWithFrame: NSMakeRect(0, 0, NSWidth(contentRect),
                                 NSHeight(contentRect))])];
      [self setReleasedWhenClosed: NO];
      [self setOpaque: NO];
      [self setBackgroundColor: [NSColor clearColor]];
    }
  return self;
}

- (BOOL) canBecomeKeyWindow
{
  return NO;
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (void) setPopoverView: (NSView *)view edge: (NSRectEdge)edge
{
  GSPopoverView *decoration = (GSPopoverView *)[super contentView];
  NSArray *children = AUTORELEASE([[decoration subviews] copy]);
  NSUInteger i;
  NSImage *shape;
  NSBitmapImageRep *bitmap;
  NSBezierPath *path;

  for (i = 0; i < [children count]; i++)
    {
      [[children objectAtIndex: i] removeFromSuperview];
    }
  [decoration setEdge: edge];
  /* Keep opaque controller views inside the one-point outline. */
  [view setFrame: NSInsetRect([decoration bodyRect], 1.0, 1.0)];
  [decoration addSubview: view];

  /* Non-composited backends need a window shape as well as clear pixels. */
  shape = [[NSImage alloc] initWithSize: [decoration bounds].size];
  [shape setBackgroundColor: [NSColor clearColor]];
  [shape lockFocus];
  [[NSColor clearColor] set];
  NSRectFillUsingOperation([decoration bounds], NSCompositeCopy);
  path = [decoration outlinePath];
  [[NSColor whiteColor] set];
  [path fill];
  [path stroke];
  bitmap = [[NSBitmapImageRep alloc]
    initWithFocusedViewRect: [decoration bounds]];
  [shape unlockFocus];
  RELEASE(shape);
  /* The display server needs bitmap pixels, not a cached image rep. */
  shape = [[NSImage alloc] initWithSize: [decoration bounds].size];
  [shape setBackgroundColor: [NSColor clearColor]];
  [shape addRepresentation: bitmap];
  RELEASE(bitmap);
  [GSServerForWindow(self) restrictWindow: [self windowNumber] toImage: shape];
  RELEASE(shape);
}

@end

/* Class */
@implementation NSPopover

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _animates = YES;
    }
  return self;
}

- (void) dealloc
{
  [_realPanel setDelegate: nil];
  [[_realPanel parentWindow] removeChildWindow: _realPanel];
  [_realPanel close];
  DESTROY(_realPanel);
  DESTROY(_contentViewController);
  DEALLOC;
}

/* Properties */

- (void) setAnimates: (BOOL)flag
{
  _animates = flag;
}

- (BOOL) animates
{
  return _animates;
}

- (void) setAppearance: (NSPopoverAppearance)value
{
  _appearance = value;
}

- (NSPopoverAppearance) appearance
{
  return _appearance;
}

- (void) setBehavior: (NSPopoverBehavior)value
{
  _behavior = value;
}

- (NSPopoverBehavior) behavior
{
  return _behavior;
}

- (void) setContentSize: (NSSize)value
{
  _contentSize = value;
}

- (NSSize) contentSize
{
  return _contentSize;
}

- (void) setContentViewController: (NSViewController *)controller
{
  /* A controller that already provides its view, whether set directly or
     loaded from its own nib, needs nothing loaded here. */
  if (controller != nil && [controller view] == nil
      && [NSStoryboard mainStoryboard] == nil)
    {
      NSString *controllerClassName = NSStringFromClass([controller class]);
      BOOL loaded = [NSBundle loadNibNamed: controllerClassName
				     owner: controller];
      if (!loaded)
	{
	  [NSException raise: NSInternalInconsistencyException
		      format: @"Could not load controller %@", controllerClassName];
	}
      else
	{
	  if ([controller view] == nil)
	    {
	      [NSException raise: NSInternalInconsistencyException
			  format: @"Loaded controller named %@, but view is not set", controllerClassName];
	    }
	}
    }
  ASSIGN(_contentViewController, controller);
}

- (NSViewController *) contentViewController
{
  return _contentViewController;
}

- (void) setDelegate: (id)value
{
  _delegate = value;
}

- (id) delegate
{
  return _delegate;
}

- (void) setPositioningRect: (NSRect)value
{
  _positioningRect = value;
}

- (NSRect) positioningRect
{
  return _positioningRect;
}

- (BOOL) isShown
{
  return _shown;
}

/* Methods */

- (void) close
{
  [[_realPanel parentWindow] removeChildWindow: _realPanel];
  [_realPanel close];
  _shown = NO;
}

- (IBAction) performClose: (id)sender
{
  if ([self windowShouldClose: _realPanel])
    [self close];
}

- (void) showRelativeToRect: (NSRect)positioningRect
		     ofView: (NSView *)positioningView
	      preferredEdge: (NSRectEdge)preferredEdge
{
  NSView *view = [_contentViewController view];
  NSRect screenRect;
  NSRect windowFrame;
  NSSize size;

  if (positioningView == nil || [positioningView window] == nil)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"The popover positioning view must have a window"];
    }
  if (view == nil)
    {
      [NSException raise: NSInternalInconsistencyException
                  format: @"The popover requires a content view"];
    }
  if (NSIsEmptyRect(positioningRect))
    positioningRect = [positioningView bounds];
  _positioningRect = positioningRect;
  screenRect = [positioningView convertRect: positioningRect toView: nil];
  screenRect = [[positioningView window] convertRectToScreen: screenRect];

  /* The requested Y edge is in the positioning view's coordinate system. */
  if ([positioningView isFlipped])
    {
      if (preferredEdge == NSMinYEdge)
        preferredEdge = NSMaxYEdge;
      else if (preferredEdge == NSMaxYEdge)
        preferredEdge = NSMinYEdge;
    }
  size = _contentSize;
  if (size.width <= 0)
    size.width = NSWidth([view frame]);
  if (size.height <= 0)
    size.height = NSHeight([view frame]);
  size.width += 2.0;
  size.height += 2.0;
  if (preferredEdge == NSMinXEdge || preferredEdge == NSMaxXEdge)
    size.width += GSPopoverArrowSize;
  else
    size.height += GSPopoverArrowSize;
  windowFrame = NSMakeRect(NSMidX(screenRect) - size.width / 2,
                          NSMidY(screenRect) - size.height / 2,
                          size.width, size.height);
  switch (preferredEdge)
    {
      case NSMinXEdge:
        windowFrame.origin.x = NSMinX(screenRect) - size.width;
        break;
      case NSMaxXEdge:
        windowFrame.origin.x = NSMaxX(screenRect);
        break;
      case NSMinYEdge:
        windowFrame.origin.y = NSMinY(screenRect) - size.height;
        break;
      case NSMaxYEdge:
        windowFrame.origin.y = NSMaxY(screenRect);
        break;
    }

  if (_realPanel == nil)
    {
      _realPanel = [[GSPopoverPanel alloc]
        initWithContentRect: windowFrame
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO];
      [_realPanel setExcludedFromWindowsMenu: YES];
      [_realPanel setLevel: NSPopUpMenuWindowLevel];
      [_realPanel setDelegate: self];
    }
  if ([_realPanel parentWindow] != [positioningView window])
    [[_realPanel parentWindow] removeChildWindow: _realPanel];
  [_realPanel setFrame: windowFrame display: NO];
  [(GSPopoverPanel *)_realPanel setPopoverView: view edge: preferredEdge];
  [_realPanel orderFront: self];
  [[positioningView window] addChildWindow: _realPanel
                                 ordered: NSWindowAbove];
  _shown = YES;
}

- (BOOL) windowShouldClose: (id)sender
{
  if ([_delegate respondsToSelector: @selector(popoverShouldClose:)])
    return [_delegate popoverShouldClose: self];
  return YES;
}

- (void) windowDidClose: (NSNotification *)notification
{
  [[NSNotificationCenter defaultCenter] postNotificationName:NSPopoverDidCloseNotification
						      object:self
						    userInfo:nil];
}

- (void) windowWillClose: (NSNotification *)notification
{
  [[NSNotificationCenter defaultCenter] postNotificationName:NSPopoverWillCloseNotification
						      object:self
						    userInfo:nil];
}

- (id) initWithCoder: (NSCoder *)coder
{
  if (nil != (self = [super initWithCoder:coder]))
    {
      if (YES == [coder allowsKeyedCoding])
	{
	  _appearance = [coder decodeIntForKey: @"NSAppearance"];
	  _behavior   = [coder decodeIntForKey: @"NSBehavior"];
	  _animates   = [coder decodeBoolForKey: @"NSAnimates"];
	  _contentSize.width = [coder decodeDoubleForKey: @"NSContentWidth"];
	  _contentSize.height = [coder decodeDoubleForKey: @"NSContentHeight"];
	  [self setContentViewController:[coder decodeObjectForKey:@"NSContentViewController"]];
	}
      else
	{
	  [coder decodeValueOfObjCType: @encode(NSInteger) at: &_appearance];
	  [coder decodeValueOfObjCType: @encode(NSInteger) at: &_behavior];
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &_animates];
	  [coder decodeValueOfObjCType: @encode(CGFloat) at: &_contentSize.width];
	  [coder decodeValueOfObjCType: @encode(CGFloat) at: &_contentSize.height];
	  [self setContentViewController:[coder decodeObject]];
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder:coder];
  if (YES == [coder allowsKeyedCoding])
    {
      [coder encodeInt: _appearance forKey: @"NSAppearance"];
      [coder encodeInt: _behavior forKey: @"NSBehavior"];
      [coder encodeBool: _animates forKey: @"NSAnimates"];
      [coder encodeDouble: _contentSize.width forKey: @"NSContentWidth"];
      [coder encodeDouble: _contentSize.height forKey: @"NSContentHeight"];
      [coder encodeObject:_contentViewController forKey:@"NSContentViewController"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(NSInteger) at: &_appearance];
      [coder encodeValueOfObjCType: @encode(NSInteger) at: &_behavior];
      [coder encodeValueOfObjCType: @encode(BOOL) at: &_animates];
      [coder encodeValueOfObjCType: @encode(CGFloat) at: &_contentSize.width];
      [coder encodeValueOfObjCType: @encode(CGFloat) at: &_contentSize.height];
      [coder encodeObject:_contentViewController];
    }
}

@end
