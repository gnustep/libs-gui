/*
   NSSplitView.m

   Allows multiple views to share a region in a window

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Robert Vasvari < vrobi@ddrummer.com >
   Date: Jul 1998
   Author:  Felipe A. Rodriguez < far@ix.netcom.com >
   Date: November 1998
   Author:  Richard Frith-Macdonald < richard@brainstorm.co.uk >
   Date: January 1999

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

#include <gnustep/gui/config.h>
#include <string.h>
#include <math.h>

#import <Foundation/Foundation.h>

#import <AppKit/AppKit.h>



@implementation NSSplitView

/*
 * Instance methods
 */
- (id) initWithFrame: (NSRect)frameRect
{
  if ((self = [super initWithFrame: frameRect]) != nil)
    {
      _dividerWidth = [self dividerThickness];
      _draggedBarWidth = 8; // default bigger than dividerThickness
      _isVertical = NO;
      ASSIGN (_dividerColor, [NSColor controlShadowColor]);
      ASSIGN (_backgroundColor, [NSColor controlBackgroundColor]);
      ASSIGN (_dimpleImage, [NSImage imageNamed: @"common_Dimple.tiff"]); 
    }
  return self;
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSApplication	*app = [NSApplication sharedApplication];
  static NSRect	oldRect; //only one can be dragged at a time
  NSPoint	p;
  NSEvent	*e;
  NSRect	r, r1, bigRect, vis;
  id		v = nil, prev = nil;
  float		minCoord, maxCoord;
  NSArray	*subs = [self subviews];
  int		offset = 0, i, count = [subs count];
  float		divVertical, divHorizontal;
  NSDate	*farAway = [NSDate distantFuture];
  unsigned	int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			      | NSLeftMouseDraggedMask | NSMouseMovedMask
			      | NSPeriodicMask;

  /*  if there are less the two subviews, there is nothing to do */
  if (count < 2)
    return;

  [_window setAcceptsMouseMovedEvents: YES];
  vis = [self visibleRect];

  /* find out which divider it is */
  p = [theEvent locationInWindow];
  p = [self convertPoint: p fromView: nil];
  for (i = 0; i < count; i++)
    {
      v = [subs objectAtIndex: i];
      r = [v frame];
      /* if the click is inside of a subview, return.  this should
	 happen only if a subview has leaked a mouse down to next
	 responder */
      if (NSPointInRect(p, r))
	{
	  NSLog(@"NSSplitView got mouseDown in subview area");
	  goto RETURN_LABEL;
	}
      if (_isVertical == NO)
        {
	  if (NSMaxY(r) <= p.y)
	    {				// can happen only when i>0.
 	      NSView	*tempView;

	      offset = i-1;

	      /* get the enclosing rect for the two views */
	      if (prev)
		r = [prev frame];
	      else
		{
		  /*
		   * This happens if user pressed exactly on the
		   * top of the top subview
		   */
		  goto RETURN_LABEL;
		}
	      if (v)
		r1 = [v frame];
	      bigRect = r;
	      bigRect = NSUnionRect(r1, bigRect);
	      tempView = prev; prev = v; v = tempView;
	      break;
            }
	  prev = v;
        }
      else
        {
	  if (NSMinX(r) >= p.x)
            {
	      offset = i;

	      /* get the enclosing rect for the two views */
	      if (prev)
		r = [prev frame];
	      else
		{
		  /*
		   * This happens if user pressed exactly on the
		   * left of the left subview
		   */
		  goto RETURN_LABEL;
		}
	      if (v)
		r1 = [v frame];
	      bigRect = r;
	      bigRect = NSUnionRect(r1 , bigRect);
	      break;
            }
	  prev = v;
        }
    }
  if (_isVertical == NO)
    {
      divVertical = _dividerWidth;
      divHorizontal = NSWidth(_frame);
      /* set the default limits on the dragging */
      minCoord = NSMinY(bigRect) + divVertical;
      maxCoord = NSHeight(bigRect) + NSMinY(bigRect) - divVertical;
    }
  else
    {
      divHorizontal = _dividerWidth;
      divVertical = NSHeight(_frame);
      /* set the default limits on the dragging */
      minCoord = NSMinX(bigRect) + divHorizontal;
      maxCoord = NSWidth(bigRect) + NSMinX(bigRect) - divHorizontal;
    }


  /* find out what the dragging limit is */
  if (_delegate && [_delegate respondsToSelector:
      @selector(splitView:constrainMinCoordinate:maxCoordinate:ofSubviewAt:)])
    {
      if (_isVertical == NO)
        {
	  float delMinY= minCoord, delMaxY= maxCoord;
	  [_delegate splitView: self
		     constrainMinCoordinate: &delMinY
		     maxCoordinate: &delMaxY
		     ofSubviewAt: offset];
	  /* we are still constrained by the original bounds */
	  if (delMinY > minCoord)
	    minCoord = delMinY;
	  if (delMaxY < maxCoord)
	    maxCoord = delMaxY;
        }
      else
        {
	  float delMinX= minCoord, delMaxX= maxCoord;
	  [_delegate splitView: self
		     constrainMinCoordinate: &delMinX
		     maxCoordinate: &delMaxX
		     ofSubviewAt: offset];
	  /* we are still constrained by the original bounds */
	  if (delMinX > minCoord)
	    minCoord = delMinX;
	  if (delMaxX < maxCoord)
	    maxCoord = delMaxX;
        }
    }

  oldRect = NSZeroRect;
  [self lockFocus];

  /* FIXME: Are these really needed? */
  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.1];
  [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];

  [_dividerColor set];
  r.size.width = divHorizontal;
  r.size.height = divVertical;
  e = [app nextEventMatchingMask: eventMask
		       untilDate: farAway
			  inMode: NSEventTrackingRunLoopMode
			 dequeue: YES];

  // user is moving the knob loop until left mouse up
  while ([e type] != NSLeftMouseUp)
    {
      if ([e type] != NSPeriodic)
	p = [self convertPoint: [e locationInWindow] fromView: nil];
      if (_isVertical == NO)
	{
	  if (p.y < minCoord)
	    p.y = minCoord;
	  if (p.y > maxCoord)
	    p.y = maxCoord;
	  r.origin.y = p.y - (divVertical/2.);
	  r.origin.x = NSMinX(vis);
	}
      else
	{
	  if (p.x < minCoord)
	    p.x = minCoord;
	  if (p.x > maxCoord)
	    p.x = maxCoord;
	  r.origin.x = p.x - (divHorizontal/2.);
	  r.origin.y = NSMinY(vis);
	}
      NSDebugLog(@"drawing divider at x: %d, y: %d, w: %d, h: %d\n",
			      (int)NSMinX(r),(int)NSMinY(r),(int)NSWidth(r),
			      (int)NSHeight(r));
      [_dividerColor set];
      NSHighlightRect(r);
      oldRect = r;
      e = [app nextEventMatchingMask: eventMask
			   untilDate: farAway
			      inMode: NSEventTrackingRunLoopMode
			     dequeue: YES];
      [_dividerColor set];
      NSHighlightRect(oldRect);
    }

  [self unlockFocus];
  [NSEvent stopPeriodicEvents];

  /* resize the subviews accordingly */
  r = [prev frame];
  if (_isVertical == NO)
    {
      r.size.height = p.y - NSMinY(bigRect) - (divVertical/2.);
      if (NSHeight(r) < 1.)
	r.size.height = 1.;
    }
  else
    {
      r.size.width = p.x - NSMinX(bigRect) - (divHorizontal/2.);
      if (NSWidth(r) < 1.)
	r.size.width = 1.;
    }
  [prev setFrame: r];
  NSDebugLog(@"drawing PREV at x: %d, y: %d, w: %d, h: %d\n",
	     (int)NSMinX(r),(int)NSMinY(r),(int)NSWidth(r),(int)NSHeight(r));

  r1 = [v frame];
  if (_isVertical == NO)
    {
      r1.origin.y = p.y + (divVertical/2.);
      if (NSMinY(r1) < 0.)
	r1.origin.y = 0.;
      r1.size.height = NSHeight(bigRect) - NSHeight(r) - divVertical;
      if (NSHeight(r) < 1.)
	r.size.height = 1.;
    }
  else
    {
      r1.origin.x = p.x + (divHorizontal/2.);
      if (NSMinX(r1) < 0.)
	r1.origin.x = 0.;
      r1.size.width = NSWidth(bigRect) - NSWidth(r) - divHorizontal;
      if (NSWidth(r1) < 1.)
	r1.size.width = 1.;
    }
  [v setFrame: r1];
  NSDebugLog(@"drawing LAST at x: %d, y: %d, w: %d, h: %d\n",
	     (int)NSMinX(r1),(int)NSMinY(r1),(int)NSWidth(r1),
	     (int)NSHeight(r1));

  [_window invalidateCursorRectsForView: self];


  [self setNeedsDisplay: YES];

  [self display];
RETURN_LABEL:
  [_window setAcceptsMouseMovedEvents: NO];
}

- (void) adjustSubviews
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc postNotificationName: NSSplitViewWillResizeSubviewsNotification
		    object: self];

  if (_delegate && [_delegate 
		     respondsToSelector:
		       @selector(splitView:resizeSubviewsWithOldSize:)])
    {
      [_delegate splitView: self resizeSubviewsWithOldSize: _frame.size];
    }
  else
    {	/* split the area up evenly */
      NSArray	*subs = [self subviews];
      unsigned	count = [subs count];
      NSView	*views[count];
      NSRect	frames[count];
      NSSize	newSize;
      NSPoint	newPoint;
      unsigned	i;
      NSRect	r;
      float	oldTotal;
      float	newTotal;
      float	scale;
      float	running;

      [subs getObjects: views];
      if (_isVertical == NO)
	{
	  newTotal = NSHeight(_bounds) - _dividerWidth*(count - 1);
	  oldTotal = 0.0;
	  for (i = 0; i < count; i++)
	    {
	      frames[i] = [views[i] frame];
	      oldTotal +=  NSHeight(frames[i]);
	    }
	  scale = newTotal/oldTotal;
	  running = NSHeight (_bounds);
	  for (i = 0; i < count; i++)
	    {
	      float	newHeight;

	      r = [views[i] frame];
	      newHeight = NSHeight(frames[i]) * scale;
	      if (i == count - 1)
		newHeight = floor(newHeight);
	      else
		newHeight = ceil(newHeight);
	      newSize = NSMakeSize(NSWidth(_bounds), newHeight);
	      running -= newHeight;
	      newPoint = NSMakePoint(0.0, running);
	      running -= _dividerWidth;
	      [views[i] setFrameSize: newSize];
	      [views[i] setFrameOrigin: newPoint];
	    }
	}
      else
	{
	  newTotal = NSWidth(_bounds) - _dividerWidth*(count - 1);
	  oldTotal = 0.0;
	  for (i = 0; i < count; i++)
	    {
	      oldTotal +=  NSWidth([views[i] frame]);
	    }
	  scale = newTotal/oldTotal;
	  running = 0.0;
	  for (i = 0; i < count; i++)
	    {
	      float	newWidth;

	      r = [views[i] frame];
	      newWidth = NSWidth(r) * scale;
	      if (i == count - 1)
		newWidth = floor(newWidth);
	      else
		newWidth = ceil(newWidth);
	      newSize = NSMakeSize(newWidth, NSHeight(_bounds));
	      newPoint = NSMakePoint(running, 0.0);
	      running += newWidth + _dividerWidth;
	      [views[i] setFrameSize: newSize];
	      [views[i] setFrameOrigin: newPoint];
	    }
	}
    }
  [nc postNotificationName: NSSplitViewDidResizeSubviewsNotification
		    object: self];
}

- (void) addSubview: (NSView*)aView
	 positioned: (NSWindowOrderingMode)place
	 relativeTo: (NSView*)otherView
{
  [super addSubview: aView positioned: place relativeTo: otherView];
  [self adjustSubviews];
}

- (void) addSubview: aView
{
  [super addSubview: aView];
  [self adjustSubviews];
}

- (float) dividerThickness 
{
  /*
   * You need to override this method in subclasses to change the
   * dividerThickness (or, without need for subclassing, invoke
   * setDimpleImage:resetDividerThickness:YES below)
   */
  return 6;
}

/*
 * FIXME: Perhaps the following two should be removed and _dividerWidth 
 * should be used also for dragging?
 */
- (float) draggedBarWidth //defaults to 8
{
  return _draggedBarWidth;
}

- (void) setDraggedBarWidth: (float)newWidth
{
  _draggedBarWidth = newWidth;
}

static inline NSPoint centerSizeInRect(NSSize innerSize, NSRect outerRect)
{
  NSPoint p;
  p.x = MAX(NSMidX(outerRect) - (innerSize.width/2.),0.);
  p.y = MAX(NSMidY(outerRect) - (innerSize.height/2.),0.);
  return p;
}

- (void) drawDividerInRect: (NSRect)aRect
{
  NSPoint dimpleOrigin;
  NSSize dimpleSize;

  /* focus is already on self */
  if (!_dimpleImage)
    return;
  dimpleSize = [_dimpleImage size];

  dimpleOrigin = centerSizeInRect(dimpleSize, aRect);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if (_rFlags.flipped_view)
    dimpleOrigin.y -= dimpleSize.height;
  [_dimpleImage compositeToPoint: dimpleOrigin 
		operation: NSCompositeSourceOver];
}

/* Vertical splitview has a vertical split bar */
- (void) setVertical: (BOOL)flag
{
  _isVertical = flag;
}

- (BOOL) isVertical
{
  return _isVertical;
}

- (void) setDimpleImage: (NSImage*)anImage resetDividerThickness: (BOOL)flag
{
  ASSIGN(_dimpleImage, anImage);

  if (flag)
    {
      NSSize s = NSMakeSize(6., 6.);

      if (_dimpleImage)
	s = [_dimpleImage size];
      if (_isVertical)
	_dividerWidth = s.width;
      else
	_dividerWidth = s.height;
    }
}

- (void) drawRect: (NSRect)r
{
  NSArray *subs = [self subviews];
  int i, count = [subs count];
  id v;
  NSRect divRect;

  if ([self isOpaque])
    {
      [_backgroundColor set];
      NSRectFill(r);
    }

  /* draw the dimples */
  {
    for (i = 0; i < (count-1); i++)
      {
	v = [subs objectAtIndex: i];
	divRect = [v frame];
	if (_isVertical == NO)
	  {
	    divRect.size.height = _dividerWidth;
	    divRect.origin.y -= divRect.size.height;
	  }
	else
	  {
	    divRect.origin.x = NSMaxX(divRect);
	    divRect.size.width = _dividerWidth;
	  }
	[self drawDividerInRect: divRect];
      }
  }
}

- (NSImage*) dimpleImage
{
  return _dimpleImage;
}

/* Overridden Methods */
- (BOOL) isFlipped
{
  return NO;
}

- (BOOL) isOpaque
{
  return YES;
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  [super resizeWithOldSuperviewSize: oldSize];
  [self adjustSubviews];
  [_window invalidateCursorRectsForView: self];
}

- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)anObject
{
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(splitView##notif_name:)]) \
    [nc addObserver: _delegate \
	   selector: @selector(splitView##notif_name: ) \
	       name: NSSplitView##notif_name##Notification \
	     object: self]

  SET_DELEGATE_NOTIFICATION(DidResizeSubviews);
  SET_DELEGATE_NOTIFICATION(WillResizeSubviews);
}

- (NSColor*) dividerColor
{
  return _dividerColor;
}

- (void) setDividerColor: (NSColor*) aColor
{
  ASSIGN(_dividerColor, aColor);
}

- (NSColor*) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor*)aColor
{
  ASSIGN(_backgroundColor, aColor);
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  /*
   *	Encode objects we don't own.
   */
  [aCoder encodeConditionalObject: _delegate];
  [aCoder encodeConditionalObject: _splitCursor]; // ?

  /*
   *	Encode the objects we do own.
   */
  // FIXME When encoding/decoding of images is supported.
  //  [aCoder encodeObject: _dimpleImage];
  [aCoder encodeObject: _backgroundColor];
  [aCoder encodeObject: _dividerColor];

  /*
   *	Encode the rest of the ivar data.
   */
  [aCoder encodeValueOfObjCType: @encode(int) at: &_draggedBarWidth];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isVertical];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  /*
   *	Decode objects that we don't retain.
   */
  [self setDelegate: [aDecoder decodeObject]];
  _splitCursor = [aDecoder decodeObject]; // ?

  /*
   *	Decode objects that we do retain.
   */

  // FIXME When encoding/decoding of images is supported.
  //[aDecoder decodeValueOfObjCType: @encode(id) at: &_dimpleImage];
  ASSIGN (_dimpleImage, [NSImage imageNamed: @"common_Dimple.tiff"]);

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_backgroundColor];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_dividerColor];

  /*
   *	Decode non-object data.
   */
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_draggedBarWidth];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isVertical];

  /*
   *
   */
  _dividerWidth = [self dividerThickness];

  return self;
}

- (void) dealloc
{
  [_backgroundColor release];
  [_dividerColor release];
  [_dimpleImage release];
  [super dealloc];
}

@end
