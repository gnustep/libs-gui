/** <title>GSStandardWindowDecorationView</title>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2004-03-24

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "GSWindowDecorationView.h"

#include <Foundation/NSException.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSParagraphStyle.h"
#include "AppKit/NSScreen.h"
#include "AppKit/NSStringDrawing.h"
#include "AppKit/NSWindow.h"
#include "AppKit/PSOperators.h"
#include "GNUstepGUI/GSDisplayServer.h"


@implementation GSStandardWindowDecorationView

/* These include the black border. */
#define TITLE_HEIGHT 23.0
#define RESIZE_HEIGHT 9.0

+(void) offsets: (float *)l : (float *)r : (float *)t : (float *)b
   forStyleMask: (unsigned int)style
{
  if (style
      & (NSTitledWindowMask | NSClosableWindowMask
	 | NSMiniaturizableWindowMask | NSResizableWindowMask))
    *l = *r = *t = *b = 1.0;
  else
    *l = *r = *t = *b = 0.0;

  if (style
      & (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask))
    {
      *t = TITLE_HEIGHT;
    }
  if (style & NSResizableWindowMask)
    {
      *b = RESIZE_HEIGHT;
    }
}

+(void) screenOffsets: (float *)l : (float *)r : (float *)t : (float *)b
   forStyleMask: (unsigned int)style
{
  *l = *r = *r = *b = 0.0;
}

+ (float) minFrameWidthWithTitle: (NSString *)aTitle
		       styleMask: (unsigned int)aStyle
{
  float l, r, t, b, width;
  [self offsets: &l : &r : &t : &b
   forStyleMask: aStyle];

  width = l + r;

  if (aStyle & NSTitledWindowMask)
    width += [aTitle sizeWithAttributes: nil].width;

  return width;
}


static NSDictionary *titleTextAttributes[3];
static NSColor *titleColor[3];

-(void) updateRects
{
  if (hasTitleBar)
    titleBarRect = NSMakeRect(0.0, _frame.size.height - TITLE_HEIGHT,
			      _frame.size.width, TITLE_HEIGHT);
  if (hasResizeBar)
    resizeBarRect = NSMakeRect(0.0, 0.0, _frame.size.width, RESIZE_HEIGHT);

  if (hasCloseButton)
    {
      closeButtonRect = NSMakeRect(
	_frame.size.width - 15 - 4, _frame.size.height - 15 - 4, 15, 15);
      [closeButton setFrame: closeButtonRect];
    }

  if (hasMiniaturizeButton)
    {
      miniaturizeButtonRect = NSMakeRect(4, _frame.size.height - 15 - 4,
					 15, 15);
      [miniaturizeButton setFrame: miniaturizeButtonRect];
    }
}

- initWithFrame: (NSRect)frame
	 window: (NSWindow *)w
{
  if (!titleTextAttributes[0])
    {
      NSMutableParagraphStyle *p;

      p = [NSMutableParagraphStyle defaultParagraphStyle];
      [p setLineBreakMode: NSLineBreakByClipping];

      titleTextAttributes[0] = [[NSMutableDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont titleBarFontOfSize: 0], NSFontAttributeName,
	  [NSColor windowFrameTextColor], NSForegroundColorAttributeName,
	  p, NSParagraphStyleAttributeName,
	  nil];
      titleTextAttributes[1] = [[NSMutableDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont titleBarFontOfSize: 0], NSFontAttributeName,
	  [NSColor blackColor], NSForegroundColorAttributeName, /* TODO: need a named color for this */
	  p, NSParagraphStyleAttributeName,
	  nil];
      titleTextAttributes[2] = [[NSMutableDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont titleBarFontOfSize: 0], NSFontAttributeName,
	  [NSColor windowFrameTextColor], NSForegroundColorAttributeName,
	  p, NSParagraphStyleAttributeName,
	  nil];

      titleColor[0] = RETAIN([NSColor windowFrameColor]);
      titleColor[1] = RETAIN([NSColor lightGrayColor]);
      titleColor[2] = RETAIN([NSColor darkGrayColor]);
    }

  self = [super initWithFrame: frame
		       window: w];
  if (!self) return nil;

  if ([w styleMask]
      & (NSTitledWindowMask | NSClosableWindowMask
	 | NSMiniaturizableWindowMask))
    {
      hasTitleBar = YES;
    }
  if ([w styleMask] & NSTitledWindowMask)
    isTitled = YES;
  if ([w styleMask] & NSClosableWindowMask)
    {
      hasCloseButton = YES;

      closeButton = [[NSButton alloc] init];
      [closeButton setRefusesFirstResponder: YES];
      [closeButton setButtonType: NSMomentaryChangeButton];
      [closeButton setImagePosition: NSImageOnly];
      [closeButton setBordered: YES];
      [closeButton setImage: [NSImage imageNamed: @"common_Close"]];
      [closeButton setAlternateImage: [NSImage imageNamed: @"common_CloseH"]];
      [closeButton setTarget: window];
      /* TODO: -performClose: should (but doesn't currently) highlight the
      button, which is wrong here. When -performClose: is fixed, we'll need a
      different method here. */
      [closeButton setAction: @selector(performClose:)];
      [self addSubview: closeButton];
      RELEASE(closeButton);
    }
  if ([w styleMask] & NSMiniaturizableWindowMask)
    {
      hasMiniaturizeButton = YES;

      miniaturizeButton = [[NSButton alloc] init];
      [miniaturizeButton setRefusesFirstResponder: YES];
      [miniaturizeButton setButtonType: NSMomentaryChangeButton];
      [miniaturizeButton setImagePosition: NSImageOnly];
      [miniaturizeButton setBordered: YES];
      [miniaturizeButton setImage:
	[NSImage imageNamed: @"common_Miniaturize"]];
      [miniaturizeButton setAlternateImage:
	[NSImage imageNamed: @"common_MiniaturizeH"]];
      [miniaturizeButton setTarget: window];
      /* TODO: -performMiniaturize: should (but doesn't currently) highlight
      the button, which is wrong here, just like -performClose: above. */
      [miniaturizeButton setAction: @selector(performMiniaturize:)];
      [self addSubview: miniaturizeButton];
      RELEASE(miniaturizeButton);
    }
  if ([w styleMask] & NSResizableWindowMask)
    hasResizeBar = YES;

  [self updateRects];

  return self;
}


-(void) drawTitleBar
{
static const NSRectEdge edges[4] = {NSMinXEdge, NSMaxYEdge,
				    NSMaxXEdge, NSMinYEdge};
  float grays[3][4] =
    {{NSLightGray, NSLightGray, NSDarkGray, NSDarkGray},
    {NSWhite, NSWhite, NSDarkGray, NSDarkGray},
    {NSLightGray, NSLightGray, NSBlack, NSBlack}};
  NSRect workRect;
  NSString *title = [window title];

  /*
  Draw the black border towards the rest of the window. (The outer black
  border is drawn in -drawRect: since it might be drawn even if we don't have
  a title bar.
  */
  [[NSColor blackColor] set];
  PSmoveto(0, NSMinY(titleBarRect) + 0.5);
  PSrlineto(titleBarRect.size.width, 0);
  PSstroke();

  /*
  Draw the button-like border.
  */
  workRect = titleBarRect;
  workRect.origin.x += 1;
  workRect.origin.y += 1;
  workRect.size.width -= 2;
  workRect.size.height -= 2;

  workRect = NSDrawTiledRects(workRect, workRect, edges, grays[inputState], 4);
 
  /*
  Draw the background.
  */
  [titleColor[inputState] set];
  NSRectFill(workRect);

  /* Draw the title. */
  if (isTitled)
    {
      NSSize titleSize;
    
      if (hasMiniaturizeButton)
	{
	  workRect.origin.x += 17;
	  workRect.size.width -= 17;
	}
      if (hasCloseButton)
	{
	  workRect.size.width -= 17;
	}
  
      titleSize = [title sizeWithAttributes: titleTextAttributes[inputState]];
      if (titleSize.width <= workRect.size.width)
	workRect.origin.x = NSMidX(workRect) - titleSize.width / 2;
      workRect.origin.y = NSMidY(workRect) - titleSize.height / 2;
      workRect.size.height = titleSize.height;
      [title drawInRect: workRect
	 withAttributes: titleTextAttributes[inputState]];
    }
}

-(void) drawResizeBar
{
  [[NSColor lightGrayColor] set];
  PSrectfill(1.0, 1.0, resizeBarRect.size.width - 2.0, RESIZE_HEIGHT - 3.0);

  PSsetlinewidth(1.0);

  [[NSColor blackColor] set];
  PSmoveto(0.0, 0.5);
  PSlineto(resizeBarRect.size.width, 0.5);
  PSstroke();

  [[NSColor darkGrayColor] set];
  PSmoveto(1.0, RESIZE_HEIGHT - 0.5);
  PSlineto(resizeBarRect.size.width - 1.0, RESIZE_HEIGHT - 0.5);
  PSstroke();

  [[NSColor whiteColor] set];
  PSmoveto(1.0, RESIZE_HEIGHT - 1.5);
  PSlineto(resizeBarRect.size.width - 1.0, RESIZE_HEIGHT - 1.5);
  PSstroke();


  /* Only draw the notches if there's enough space. */
  if (resizeBarRect.size.width < 30 * 2)
    return;

  [[NSColor darkGrayColor] set];
  PSmoveto(27.5, 1.0);
  PSlineto(27.5, RESIZE_HEIGHT - 2.0);
  PSmoveto(resizeBarRect.size.width - 28.5, 1.0);
  PSlineto(resizeBarRect.size.width - 28.5, RESIZE_HEIGHT - 2.0);
  PSstroke();

  [[NSColor whiteColor] set];
  PSmoveto(28.5, 1.0);
  PSlineto(28.5, RESIZE_HEIGHT - 2.0);
  PSmoveto(resizeBarRect.size.width - 27.5, 1.0);
  PSlineto(resizeBarRect.size.width - 27.5, RESIZE_HEIGHT - 2.0);
  PSstroke();
}

-(void) drawRect: (NSRect)rect
{
  if (hasTitleBar && NSIntersectsRect(rect, titleBarRect))
    {
      [self drawTitleBar];
    }

  if (hasResizeBar && NSIntersectsRect(rect, resizeBarRect))
    {
      [self drawResizeBar];
    }

  if (hasResizeBar || hasTitleBar)
    {
      PSsetlinewidth(1.0);
      [[NSColor blackColor] set];
      if (NSMinX(rect) < 1.0)
	{
	  PSmoveto(0.5, 0.0);
	  PSlineto(0.5, _frame.size.height);
	  PSstroke();
	}
      if (NSMaxX(rect) > _frame.size.width - 1.0)
	{
	  PSmoveto(_frame.size.width - 0.5, 0.0);
	  PSlineto(_frame.size.width - 0.5, _frame.size.height);
	  PSstroke();
	}
      if (NSMaxY(rect) > _frame.size.height - 1.0)
	{
	  PSmoveto(0.0, _frame.size.height - 0.5);
	  PSlineto(_frame.size.width, _frame.size.height - 0.5);
	  PSstroke();
	}
      if (NSMinY(rect) < 1.0)
	{
	  PSmoveto(0.0, 0.5);
	  PSlineto(_frame.size.width, 0.5);
	  PSstroke();
	}
    }

  [super drawRect: rect];
}


-(void) setTitle: (NSString *)newTitle
{
  if (isTitled)
    [self setNeedsDisplayInRect: titleBarRect];
  [super setTitle: newTitle];
}

-(void) setInputState: (int)state
{
  NSAssert(state >= 0 && state <= 2, @"Invalid state!");
  [super setInputState: state];
  if (hasTitleBar)
    [self setNeedsDisplayInRect: titleBarRect];
}

-(void) setDocumentEdited: (BOOL)flag
{
  if (flag)
    {
      [closeButton setImage: [NSImage imageNamed: @"common_CloseBroken"]];
      [closeButton setAlternateImage:
	[NSImage imageNamed: @"common_CloseBrokenH"]];
    }
  else
    {
      [closeButton setImage: [NSImage imageNamed: @"common_Close"]];
      [closeButton setAlternateImage:
	[NSImage imageNamed: @"common_CloseH"]];
    }
  [super setDocumentEdited: flag];
}


-(NSPoint) mouseLocationOnScreenOutsideOfEventStream
{
  int screen = [[window screen] screenNumber];
  return [GSServerForWindow(window) mouseLocationOnScreen: screen
						   window: NULL];
}

-(void) moveWindowStartingWithEvent: (NSEvent *)event
{
  unsigned int mask = NSLeftMouseDraggedMask | NSLeftMouseUpMask;
  NSEvent *currentEvent = event;
  NSDate *distantPast = [NSDate distantPast];
  NSPoint delta, point;

  delta = [event locationInWindow];

  [window _captureMouse: nil];
  do
    {
      while (currentEvent && [currentEvent type] != NSLeftMouseUp)
	{
	  currentEvent = [_window nextEventMatchingMask: mask
			   untilDate: distantPast
			   inMode: NSEventTrackingRunLoopMode
			   dequeue: YES];
	}

      point = [self mouseLocationOnScreenOutsideOfEventStream];
      [window setFrameOrigin: NSMakePoint(point.x - delta.x,
					  point.y - delta.y)];

      if (currentEvent && [currentEvent type] == NSLeftMouseUp)
	break;


      currentEvent = [_window nextEventMatchingMask: mask
			untilDate: nil
			inMode: NSEventTrackingRunLoopMode
			dequeue: YES];
    } while ([currentEvent type] != NSLeftMouseUp);
  [window _releaseMouse: nil];
}


static NSRect calc_new_frame(NSRect frame, NSPoint point, NSPoint firstPoint,
	int mode, NSSize minSize, NSSize maxSize)
{
  NSRect newFrame = frame;
  newFrame.origin.y = point.y - firstPoint.y;
  newFrame.size.height = NSMaxY(frame) - newFrame.origin.y;
  if (newFrame.size.height < minSize.height)
    {
      newFrame.size.height = minSize.height;
      newFrame.origin.y = NSMaxY(frame) - newFrame.size.height;
    }

  if (mode == 0)
    {
      newFrame.origin.x = point.x - firstPoint.x;
      newFrame.size.width = NSMaxX(frame) - newFrame.origin.x;

      if (newFrame.size.width < minSize.width)
	{
	  newFrame.size.width = minSize.width;
	  newFrame.origin.x = NSMaxX(frame) - newFrame.size.width;
	}
    }
  else if (mode == 1)
    {
      newFrame.size.width = point.x - frame.origin.x + frame.size.width
			    - firstPoint.x;

      if (newFrame.size.width < minSize.width)
	{
	  newFrame.size.width = minSize.width;
	  newFrame.origin.x = frame.origin.x;
	}
    }
  return newFrame;
}

-(void) resizeWindowStartingWithEvent: (NSEvent *)event
{
  unsigned int mask = NSLeftMouseDraggedMask | NSLeftMouseUpMask;
  NSEvent *currentEvent = event;
  NSDate *distantPast = [NSDate distantPast];
  NSPoint firstPoint, point;
  NSRect newFrame, frame;
  NSSize minSize, maxSize;

  /*
  0 drag lower left corner
  1 drag lower right corner
  2 drag lower edge
  */
  int mode;


  firstPoint = [event locationInWindow];
  if (resizeBarRect.size.width < 30 * 2
      && firstPoint.x < resizeBarRect.size.width / 2)
    mode = 0;
  else if (firstPoint.x > resizeBarRect.size.width - 29)
    mode = 1;
  else if (firstPoint.x < 29)
    mode = 0;
  else
    mode = 2;

  frame = [window frame];
  minSize = [window minSize];
  maxSize = [window maxSize];

  [window _captureMouse: nil];
  do
    {
      while (currentEvent && [currentEvent type] != NSLeftMouseUp)
	{
	  currentEvent = [_window nextEventMatchingMask: mask
			   untilDate: distantPast
			   inMode: NSEventTrackingRunLoopMode
			   dequeue: YES];
	}

      point = [self mouseLocationOnScreenOutsideOfEventStream];
      newFrame = calc_new_frame(frame, point, firstPoint, mode, minSize, maxSize);

      if (currentEvent && [currentEvent type] == NSLeftMouseUp)
	break;

      currentEvent = [_window nextEventMatchingMask: mask
			untilDate: nil
			inMode: NSEventTrackingRunLoopMode
			dequeue: YES];
    } while ([currentEvent type] != NSLeftMouseUp);
  [window _releaseMouse: nil];

  [window setFrame: newFrame  display: YES];
}

-(BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

-(void) mouseDown: (NSEvent *)event
{
  NSPoint p = [self convertPoint: [event locationInWindow] fromView: nil];

  if (NSPointInRect(p, contentRect))
    return;

  if (NSPointInRect(p, titleBarRect))
    {
      [self moveWindowStartingWithEvent: event];
      return;
    }

  if (NSPointInRect(p, resizeBarRect))
    {
      [self resizeWindowStartingWithEvent: event];
      return;
    }
}

- (void) setFrame: (NSRect)frameRect
{
  [super setFrame: frameRect];
  [self updateRects];
}

@end

