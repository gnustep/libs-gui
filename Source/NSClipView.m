/*
   NSClipView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: July 1997
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <gnustep/gui/config.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSClipView.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSGraphics.h>

@implementation NSClipView

- (id) init
{
  [super init];
  [self setAutoresizesSubviews: YES];
  [self setBackgroundColor: [NSColor controlColor]];
  _copiesOnScroll = YES;
  return self;
}

- (void) setDocumentView: (NSView*)aView
{
  NSNotificationCenter	*nc;

  if (_documentView == aView)
    return;

  nc = [NSNotificationCenter defaultCenter];
  if (_documentView)
    {
      [nc removeObserver: self name: nil object: _documentView];
      [_documentView removeFromSuperview];
    }

  ASSIGN(_documentView, aView);

  if (_documentView)
    {
      NSRect	df;

      [self addSubview: _documentView];

      df = [_documentView frame];
      [self setBoundsOrigin: df.origin];
      if ([aView respondsToSelector: @selector(backgroundColor)])
	[self setBackgroundColor: [(id)aView backgroundColor]];

      /* Register for notifications sent by the document view */
      [_documentView setPostsFrameChangedNotifications: YES];
      [_documentView setPostsBoundsChangedNotifications: YES];

      [nc addObserver: self
	     selector: @selector(viewFrameChanged:)
		 name: NSViewFrameDidChangeNotification
	       object: _documentView];
      [nc addObserver: self
	     selector: @selector(viewBoundsChanged:)
		 name: NSViewBoundsDidChangeNotification
	       object: _documentView];
    }

  _rFlags.flipped_view = [self isFlipped];

  /* TODO: invoke superview's reflectScrolledClipView: ? */
  [_super_view reflectScrolledClipView: self];
}

- (void) resetCursorRects
{
  [self addCursorRect: _bounds cursor: _cursor];
}

- (void) scrollToPoint: (NSPoint)point
{
  [self setBoundsOrigin: [self constrainScrollPoint: point]];
}

- (void) setBoundsOrigin: (NSPoint)point
{
  NSRect originalBounds = _bounds;
  NSRect newBounds = originalBounds;
  NSRect intersection;

  newBounds.origin = point;

  if (NSEqualPoints(originalBounds.origin, newBounds.origin))
    return;

  if (_documentView == nil)
    return;

  if (_copiesOnScroll && _window)
    {
      // copy the portion of the view that is common before 
      // and after scrolling.
      // then tell docview to draw the exposed parts.
      // intersection is the common rectangle
      intersection = NSIntersectionRect(originalBounds, newBounds);
      if (NSEqualRects(intersection, NSZeroRect))
	{
	  // no intersection -- docview should draw everything
	  [super setBoundsOrigin: newBounds.origin];
	  [_documentView setNeedsDisplayInRect: 
	    [self convertRect: newBounds toView: _documentView]];
	}
      else
	{
	  NSPoint destPoint = intersection.origin;
	  float dx = newBounds.origin.x - originalBounds.origin.x;
	  float dy = newBounds.origin.y - originalBounds.origin.y;

	  destPoint.x -= dx;
	  destPoint.y -= dy;
	  [self lockFocus];
	  NSCopyBits(0, intersection, destPoint);
	  [self unlockFocus];

	  [super setBoundsOrigin: newBounds.origin];
	  if (dx != 0)
	    {
	      // moved in x -- redraw a full-height rectangle at
	      // side of intersection
	      NSRect redrawRect;

	      redrawRect.origin.y = newBounds.origin.y;
	      redrawRect.size.height = newBounds.size.height;
	      redrawRect.size.width = newBounds.size.width
					- intersection.size.width;
	      if (dx < 0)
		{
		  // moved to the left -- redraw at left of intersection
		  redrawRect.origin.x = newBounds.origin.x;
		}
	      else
		{
		  // moved to the right -- redraw at right of intersection
		  redrawRect.origin.x = newBounds.origin.x
					+ intersection.size.width;
		}
	      [_documentView setNeedsDisplayInRect: 
		[self convertRect: redrawRect toView: _documentView]];
	    }

	  if (dy != 0)
	    {
	      // moved in y
	      // -- redraw rectangle with intersection's width over or under it
	      NSRect redrawRect;

	      redrawRect.origin.x = intersection.origin.x;
	      redrawRect.size.width = intersection.size.width;
	      redrawRect.size.height = newBounds.size.height
					- intersection.size.height;
	      if (dy < 0)
		{
		  // moved down -- redraw under intersection
		  redrawRect.origin.y = newBounds.origin.y;
		}
	      else
		{
		  // moved up -- redraw over intersection
		  redrawRect.origin.y = newBounds.origin.y
					+ intersection.size.height;
		}
	      [_documentView setNeedsDisplayInRect: 
		[self convertRect: redrawRect toView: _documentView]];
	    }
	}
    }
  else
    {
      // dont copy anything -- docview draws it all
      [super setBoundsOrigin: newBounds.origin];
      [_documentView setNeedsDisplayInRect: 
	[self convertRect: newBounds toView: _documentView]];
    }
  [_super_view reflectScrolledClipView: self];
}

- (NSPoint) constrainScrollPoint: (NSPoint)proposedNewOrigin
{
  NSRect	documentFrame;
  NSPoint	new = proposedNewOrigin;

  if (_documentView == nil)
    return _bounds.origin;

  documentFrame = [_documentView frame];
  if (documentFrame.size.width <= _bounds.size.width)
    new.x = documentFrame.origin.x;
  else if (proposedNewOrigin.x <= documentFrame.origin.x)
    new.x = documentFrame.origin.x;
  else if (proposedNewOrigin.x
	   >= documentFrame.size.width - _bounds.size.width)
    new.x = documentFrame.size.width - _bounds.size.width;

  if (documentFrame.size.height <= _bounds.size.height)
    new.y = documentFrame.origin.y;
  else if (proposedNewOrigin.y <= documentFrame.origin.y)
    new.y = documentFrame.origin.y;
  else if (proposedNewOrigin.y
           >= documentFrame.size.height - _bounds.size.height)
    new.y = documentFrame.size.height - _bounds.size.height;

  // make it an integer coordinate in device space
  // to avoid some nice effects when scrolling
  new = [self convertPoint: new toView: nil];
  new.x = (int)new.x;
  new.y = (int)new.y;
  new = [self convertPoint: new fromView: nil];

  return new;
}

- (NSRect) documentRect
{
  NSRect documentFrame;
  NSRect clipViewBounds;
  NSRect rect;

  if (_documentView == nil)
    return _bounds;

  documentFrame = [_documentView frame];
  clipViewBounds = _bounds;
  rect.origin = documentFrame.origin;
  rect.size.width = MAX(documentFrame.size.width, clipViewBounds.size.width);
  rect.size.height = MAX(documentFrame.size.height, clipViewBounds.size.height);

  return rect;
}

- (NSRect) documentVisibleRect
{
  NSRect documentBounds;
  NSRect clipViewBounds;
  NSRect rect;

  if (_documentView == nil)
    return NSZeroRect;

  documentBounds = [_documentView bounds];
  clipViewBounds = [self convertRect: _bounds toView: _documentView];
  rect = NSIntersectionRect(documentBounds, clipViewBounds);

  return rect;
}

- (void) drawRect: (NSRect)rect
{
  [_backgroundColor set];
  NSRectFill(rect);
}

- (BOOL) autoscroll: (NSEvent*)theEvent
{
  return 0;
}

- (void) viewBoundsChanged: (NSNotification*)aNotification
{
  [_super_view reflectScrolledClipView: self];
}

- (void) viewFrameChanged: (NSNotification*)aNotification
{
  NSRect documentFrame = [_documentView frame];
  
  [self setBoundsOrigin: [self constrainScrollPoint: _bounds.origin]];

  /* If _bounds completely encloses (touching allowed) documentFrame */
  if ((_bounds.origin.x <= documentFrame.origin.x) 
      && (_bounds.origin.y <= documentFrame.origin.y)
      && (_bounds.origin.x + _bounds.size.width 
	  >= documentFrame.origin.x + documentFrame.size.width)
      && (_bounds.origin.y + _bounds.size.height 
	  >= documentFrame.origin.y + documentFrame.size.height))
    {
      /* then fill the area not covered by documentView with background color */
      [self setNeedsDisplay: YES];
    }

  [_super_view reflectScrolledClipView: self];
}

- (void) scaleUnitSquareToSize: (NSSize)newUnitSize
{
  [super scaleUnitSquareToSize: newUnitSize];
  [_super_view reflectScrolledClipView: self];
}

- (void) setBoundsSize: (NSSize)aSize
{
  [super setBoundsSize: aSize];
  [_super_view reflectScrolledClipView: self];
}

- (void) setFrameSize: (NSSize)aSize
{
  [super setFrameSize: aSize];
  [_super_view reflectScrolledClipView: self];
}

- (void) setFrameOrigin: (NSPoint)aPoint
{
  [super setFrameOrigin: aPoint];
  [_super_view reflectScrolledClipView: self];
}

- (void) setFrame: (NSRect)rect
{
  [super setFrame: rect];
  [_super_view reflectScrolledClipView: self];
}

- (void) translateOriginToPoint: (NSPoint)aPoint
{
  [super translateOriginToPoint: aPoint];
  [_super_view reflectScrolledClipView: self];
}

- (BOOL) isOpaque
{
  return YES;
}

- (id) documentView
{
  return _documentView;
}

- (void) setCopiesOnScroll: (BOOL)flag
{
  _copiesOnScroll = flag;
}

- (BOOL) copiesOnScroll
{
  return _copiesOnScroll;
}

- (void) setDocumentCursor: (NSCursor*)aCursor
{
  ASSIGN(_cursor, aCursor);
}

- (NSCursor*) documentCursor
{
  return _cursor;
}

- (NSColor*) backgroundColor
{
  return _backgroundColor;
}

- (BOOL) isFlipped
{
  return (_documentView != nil) ? _documentView->_rFlags.flipped_view : NO;
}

- (BOOL) acceptsFirstResponder
{
  return _documentView != nil;
}

- (void) setBackgroundColor: (NSColor*)aColor
{
  ASSIGN(_backgroundColor, aColor);
}

/* Disable rotation of clip view */
- (void) rotateByAngle: (float)angle
{
}

- (void) setBoundsRotation: (float)angle
{
}

- (void) setFrameRotation: (float)angle
{
}

/* Managing responder chain */
- (BOOL) becomeFirstResponder
{
  return (_documentView != nil) ? [_documentView becomeFirstResponder] : NO;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: _backgroundColor];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_copiesOnScroll];
  [aCoder encodeObject: _cursor];
  [aCoder encodeObject: _documentView];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  NSView *document;

  self = [super initWithCoder: aDecoder];
  [self setAutoresizesSubviews: YES];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_backgroundColor];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_copiesOnScroll];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cursor];

  document = [aDecoder decodeObject];
  [self setDocumentView: document];

  return self;
}
@end
