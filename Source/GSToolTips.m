/**
   Implementation of the GSToolTips class

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 2006

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include <Foundation/Foundation.h>
#include "AppKit/NSAttributedString.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSScreen.h"
#include "GNUstepGUI/GSTrackingRect.h"
#include "GSToolTips.h"

@interface	NSWindow (GNUstepPrivate)

+ (void) _setToolTipVisible: (GSToolTips*)t;
+ (GSToolTips*) _toolTipVisible;

@end


@interface	NSObject (ToolTips)
- (NSString*) view: (NSView*)v stringForToolTip: (NSToolTipTag)t
 point: (NSPoint)p userData: (void*)d;
@end

/* A trivial class to hold information about the provider of the tooltip
 * string.  Instance allocation/deallocation is managed by GSToolTip and
 * are instances are stored in the user data field of tracking rectangles.
 */
@interface	GSTTProvider : NSObject
{
  id	object;
  void	*data;
}
- (void*) data;
- (id) initWithObject: (id)o userData: (void*)d;
- (id) object;
- (void) setObject: (id)o;
@end

@implementation	GSTTProvider
- (void*) data
{
  return data;
}
- (id) initWithObject: (id)o userData: (void*)d
{
  data = d;
  object = o;
  return self;
}
- (id) object
{
  return object;
}
- (void) setObject: (id)o
{
  object = o;
}
@end

@interface	GSToolTips (Private)
- (void) _drawText: (NSAttributedString *)text;
- (void) _endDisplay;
- (void) _timedOut: (NSTimer *)timer;
@end

typedef struct NSView_struct
{
  @defs(NSView)
} *NSViewPtr;

@implementation GSToolTips

static NSMapTable	*viewsMap = 0;

+ (void) initialize
{
  viewsMap = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
			     NSObjectMapValueCallBacks, 8);
}

+ (void) removeTipsForView: (NSView*)aView
{
  GSToolTips	*tt = (GSToolTips*)NSMapGet(viewsMap, (void*)aView);

  if (tt != nil)
    {
      [tt removeAllToolTips];
      NSMapRemove(viewsMap, (void*)aView);
    }
}

+ (GSToolTips*) tipsForView: (NSView*)aView
{
  GSToolTips	*tt = (GSToolTips*)NSMapGet(viewsMap, (void*)aView);

  if (tt == nil)
    {
      tt = [[GSToolTips alloc] initForView: aView];
      NSMapInsert(viewsMap, (void*)aView, (void*)tt);
      RELEASE(tt);
    }
  return tt;
}



- (NSToolTipTag) addToolTipRect: (NSRect)aRect
                          owner: (id)anObject
                       userData: (void *)data
{
  NSTrackingRectTag	tag;
  GSTTProvider		*provider;

  if (timer != nil)
    {
      return -1;	// A tip is already in progress.
    }
  if (NSEqualRects(aRect, NSZeroRect))
    {
      return -1;	// No rectangle.
    }
  if (anObject == nil)
    {
      return -1;	// No provider object.
    }

  provider = [[GSTTProvider alloc] initWithObject: anObject userData: data];
  tag = [view addTrackingRect: aRect
                        owner: self
                     userData: provider
                 assumeInside: NO];
  return tag;
}

- (unsigned) count
{
  NSEnumerator		*enumerator;
  GSTrackingRect	*rect;
  unsigned		count = 0;

  enumerator = [((NSViewPtr)view)->_tracking_rects objectEnumerator];
  while ((rect = [enumerator nextObject]) != nil)
    {
      if (rect->owner == self)
        {
	  count++;
	}
    }
  return count;
}

- (void) dealloc
{
  [self _endDisplay];
  [self removeAllToolTips];
  [super dealloc];
}

- (id) initForView: (NSView*)aView
{
  view = aView;
  timer = nil;
  window = nil;
  toolTipTag = -1;
  return self;
}

- (void) mouseEntered: (NSEvent *)theEvent
{
  if (timer == nil)
    {
      GSTTProvider	*provider = (GSTTProvider*)[theEvent userData];
      NSString		*toolTipString;

      if ([[provider object] respondsToSelector:
	@selector(view:stringForToolTip:point:userData:)] == YES)
	{
	  toolTipString = [[provider object] view: view
				 stringForToolTip: [theEvent trackingNumber]
					    point: [theEvent locationInWindow]
					 userData: [provider data]];
	}
      else
        {
	  toolTipString = [[provider object] description];
	}

      timer = [NSTimer scheduledTimerWithTimeInterval: 0.5
	                                         target: self
			                       selector: @selector(_timedOut:)
			                       userInfo: toolTipString
                                                repeats: YES];
      if ([[view window] acceptsMouseMovedEvents] == YES)
        {
	  restoreMouseMoved = NO;
	}
      else
        {
	  restoreMouseMoved = YES;
          [[view window] setAcceptsMouseMovedEvents: YES];
	}
      [NSWindow _setToolTipVisible: self];
    }
}

- (void) mouseExited: (NSEvent *)theEvent
{
  [self _endDisplay];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  [self _endDisplay];
}

- (void) mouseMoved: (NSEvent *)theEvent
{
  NSPoint mouseLocation;
  NSPoint origin;

  if (window == nil)
    {
      return;
    }

  mouseLocation = [NSEvent mouseLocation];

  origin = NSMakePoint(mouseLocation.x + offset.width,
    mouseLocation.y + offset.height);

  [window setFrameOrigin: origin];
}

- (void) rebuild
{
  NSEnumerator		*enumerator;
  GSTrackingRect	*rect;

  enumerator = [((NSViewPtr)view)->_tracking_rects objectEnumerator];
  while ((rect = [enumerator nextObject]) != nil)
    {
      if (rect->owner == self)
        {
          GSTTProvider		*provider = (GSTTProvider *)rect->user_data;

	  // FIXME can we do anything with tooltips other than the main one?
	  if (rect->tag == toolTipTag)
	    {
	      NSTrackingRectTag	tag;
	      NSRect		frame;

	      [view removeTrackingRect: rect->tag];
	      frame = [view frame];
	      frame.origin.x = 0;
	      frame.origin.y = 0;
	      tag = [view addTrackingRect: frame
				    owner: self
				 userData: provider
			     assumeInside: NO];
	      toolTipTag = tag;
	    }
	}
    }
}

- (void) removeAllToolTips
{
  NSEnumerator		*enumerator;
  GSTrackingRect	*rect;

  [self _endDisplay];

  enumerator = [((NSViewPtr)view)->_tracking_rects objectEnumerator];
  while ((rect = [enumerator nextObject]) != nil)
    {
      if (rect->owner == self)
        {
	  RELEASE((GSTTProvider*)rect->user_data);
          [view removeTrackingRect: rect->tag];
	}
    }
  toolTipTag = -1;
}

- (void) removeToolTip: (NSToolTipTag)tag
{
  NSEnumerator   	*enumerator;
  GSTrackingRect	*rect;

  enumerator = [((NSViewPtr)view)->_tracking_rects objectEnumerator];
  while ((rect = [enumerator nextObject]) != nil)
    {
      if (rect->tag == tag && rect->owner == self)
	{
	  RELEASE((GSTTProvider*)rect->user_data);
	  [view removeTrackingRect: tag];
	}
    }
}

- (void) setToolTip: (NSString *)string
{
  if ([string length] == 0)
    {
      if (toolTipTag != -1)
        {
	  [self _endDisplay];
	  [self removeToolTip: toolTipTag];
	  toolTipTag = -1;
	}
    }
  else
    {
      GSTTProvider	*provider;

      if (toolTipTag == -1)
        {
	  NSRect	rect;

	  rect = [view frame];
	  rect.origin.x = 0;
	  rect.origin.y = 0;

	  provider = [[GSTTProvider alloc] initWithObject: string
						 userData: nil];
	  toolTipTag = [view addTrackingRect: rect
					owner: self
				     userData: provider
				 assumeInside: NO];
	}
      else
        {
	  NSEnumerator   	*enumerator;
	  GSTrackingRect	*rect;

	  enumerator = [((NSViewPtr)view)->_tracking_rects objectEnumerator];
	  while ((rect = [enumerator nextObject]) != nil)
	    {
	      if (rect->tag == toolTipTag && rect->owner == self)
		{
		  [((GSTTProvider*)rect->user_data) setObject: string];
		}
	    }
	}
    }
}

- (NSString *) toolTip
{
  NSEnumerator		*enumerator;
  GSTrackingRect	*rect;

  enumerator = [((NSViewPtr)view)->_tracking_rects objectEnumerator];
  while ((rect = [enumerator nextObject]) != nil)
    {
      if (rect->tag == toolTipTag)
	{
	  return [((GSTTProvider*)rect->user_data) object];
	}
    }
  return nil;
}

@end

@implementation	GSToolTips (Private)

- (void) _drawText: (NSAttributedString *)text
{
  NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge, NSMaxXEdge, NSMinYEdge};
  NSColor    *black = [NSColor blackColor];
  NSColor    *colors[] = {black, black, black, black};
  NSRect     bounds = [[window contentView] bounds];
  NSRect     textRect;

  textRect = [window frame];
  textRect.origin.x = 2;
  textRect.origin.y = -2;

  [[window contentView] lockFocus];

  [text drawInRect: textRect];
  NSDrawColorTiledRects(bounds, bounds, sides, colors, 4);

  [[window contentView] unlockFocus];
}

- (void) _endDisplay
{
  if ([NSWindow _toolTipVisible] == self)
    {
      [NSWindow _setToolTipVisible: nil];
    }
  if (timer != nil)
    {
      if ([timer isValid])
	{
	  [timer invalidate];
	}
      timer = nil;
    }
  if (window != nil)
    {
      [window close];
      window = nil;
    }
  if (restoreMouseMoved == YES)
    {
      restoreMouseMoved = NO;
      [[view window] setAcceptsMouseMovedEvents: NO];
    }
}

- (void) _timedOut: (NSTimer *)aTimer
{
  NSString *toolTipString = [aTimer userInfo];

  if (timer != nil)
    {
      if ([timer isValid])
	{
	  [timer invalidate];
	}
      timer = nil;
    }

  if (window == nil)
    {
      NSAttributedString	*toolTipText = nil;
      NSSize			textSize;
      NSPoint			mouseLocation = [NSEvent mouseLocation];
      NSRect			visible;
      NSRect			rect;
      NSColor			*color;
      NSMutableDictionary	*attributes;

      attributes = [NSMutableDictionary dictionary];
      [attributes setObject: [NSFont toolTipsFontOfSize: 10.0]
		     forKey: NSFontAttributeName];
      toolTipText =
	[[NSAttributedString alloc] initWithString: toolTipString
	                                attributes: attributes];
      textSize = [toolTipText size];

      /* Create window just off the current mouse position
       * Constrain it to be on screen, shrinking if necessary.
       */
      rect = NSMakeRect(mouseLocation.x + 8,
        mouseLocation.y - 16 - (textSize.height+3),
        textSize.width + 4, textSize.height + 4);
      visible = [[NSScreen mainScreen] visibleFrame];
      if (NSMaxY(rect) > NSMaxY(visible))
        {
	  rect.origin.y -= (NSMaxY(rect) - NSMaxY(visible));
	}
      if (NSMinY(rect) < NSMinY(visible))
        {
	  rect.origin.y += (NSMinY(visible) - NSMinY(rect));
	}
      if (NSMaxY(rect) > NSMaxY(visible))
        {
	  rect.origin.y = visible.origin.y;
	  rect.size.height = visible.size.height;
	}
        
      if (NSMaxX(rect) > NSMaxX(visible))
        {
	  rect.origin.x -= (NSMaxX(rect) - NSMaxX(visible));
	}
      if (NSMinX(rect) < NSMinX(visible))
        {
	  rect.origin.x += (NSMinX(visible) - NSMinX(rect));
	}
      if (NSMaxX(rect) > NSMaxX(visible))
        {
	  rect.origin.x = visible.origin.x;
	  rect.size.width = visible.size.width;
	}
      offset.height = rect.origin.y - mouseLocation.y;
      offset.width = rect.origin.x - mouseLocation.x;

      window = [[NSWindow alloc] initWithContentRect: rect
					   styleMask: NSBorderlessWindowMask
					     backing: NSBackingStoreRetained
					       defer: YES];

      color
	= [NSColor colorWithDeviceRed: 1.0 green: 1.0 blue: 0.90 alpha: 1.0];
      [window setBackgroundColor: color];
      [window setReleasedWhenClosed: YES];
      [window setExcludedFromWindowsMenu: YES];
      [window setLevel: NSStatusWindowLevel];

      [window orderFront: nil];

      [self _drawText: toolTipText];
      RELEASE(toolTipText);
    }
}

@end

