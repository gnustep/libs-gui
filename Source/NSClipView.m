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
#include <AppKit/PSOperators.h>

@implementation NSClipView

- (id) init
{
  [super init];
  [self setAutoresizesSubviews: YES];
  [self setBackgroundColor: [NSColor controlColor]];
  _copiesOnScroll = YES;
  _drawsBackground = YES;
  return self;
}

- (void) dealloc
{
  RELEASE(_documentView);
  RELEASE(_cursor);
  RELEASE(_backgroundColor);

  [super dealloc];
}

- (void) setDocumentView: (NSView*)aView
{
  NSNotificationCenter	*nc;

  if (_documentView == aView)
    {
      return;
    }
  
  nc = [NSNotificationCenter defaultCenter];
  if (_documentView)
    {
      [nc removeObserver: self  name: nil  object: _documentView];
      [_documentView removeFromSuperview];
    }

  ASSIGN (_documentView, aView);

  /* Call this before doing anything else ! */
  _rFlags.flipped_view = [self isFlipped];
  [self _invalidateCoordinates];

  if (_documentView)
    {
      NSRect	df;

      [self addSubview: _documentView];

      df = [_documentView frame];
      [self setBoundsOrigin: df.origin];

      if ([aView respondsToSelector: @selector(backgroundColor)])
	{
	  [self setBackgroundColor: [(id)aView backgroundColor]];
	}
      
      if ([aView respondsToSelector: @selector(drawsBackground)])
	{
	  [self setDrawsBackground: [(id)aView drawsBackground]];
	}

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

  /* TODO: Adjust the key view loop to include the new document view */

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

  if (NSEqualPoints (originalBounds.origin, newBounds.origin))
    {
      return;
    }

  if (_documentView == nil)
    {
      return;
    }
      
  if (_copiesOnScroll && _window && [_window gState])
    {
      /* Copy the portion of the view that is common before and after
	 scrolling.  Then, document view needs to redraw the remaining
	 areas. */

      /* Common part - which is a first approx of what we could
         copy... */
      intersection = NSIntersectionRect (originalBounds, newBounds);

      /* but we must make sure we only copy from visible rect - we
	 can't copy bits which have been clipped (ie discarded) */
      intersection = NSIntersectionRect (intersection, [self visibleRect]);

      /* At this point, intersection is the rectangle containing the
	 image we can recycle from the old to the new situation.  We
	 must not make any assumption on its position/size, because it
	 has been intersected with visible rect, which is an arbitrary
	 rectangle as far as we know. */
      if (NSEqualRects (intersection, NSZeroRect))
	{
	  // no recyclable part -- docview should redraw everything
	  // from scratch
	  [super setBoundsOrigin: newBounds.origin];
	  [_documentView setNeedsDisplayInRect: 
			   [self documentVisibleRect]];
	}
      else
	{
	  /* Copy the intersection to the new position */
	  NSPoint destPoint = intersection.origin;
	  float dx = newBounds.origin.x - originalBounds.origin.x;
	  float dy = newBounds.origin.y - originalBounds.origin.y;
	  NSRect redrawRect;
	  
	  destPoint.x -= dx;
	  destPoint.y -= dy;
	  [self lockFocus];
	  
	  /* FIXME! copy only an integral rect in device space */
	  NSCopyBits (0, intersection, destPoint);

	  [self unlockFocus];

	  /* Change coordinate system to the new one */
	  [super setBoundsOrigin: newBounds.origin];

	  /* Get the rectangle representing intersection in the new
             bounds (mainly to keep code readable) */
	  intersection.origin.x = destPoint.x;
	  intersection.origin.y = destPoint.y;
	  // intersection.size is the same

	  /* Now mark everything which is outside intersection as
             needing to be redrawn by hand.  NB: During simple usage -
             scrolling in a single direction (left/rigth/up/down) -
             and a normal visible rect, only one of the following
             rects will be non-empty. */

	  /* To the left of intersection */
	  redrawRect = NSMakeRect (NSMinX (_bounds), _bounds.origin.y,
				   NSMinX (intersection) - NSMinX (_bounds),
				   _bounds.size.height);
	  if (NSIsEmptyRect (redrawRect) == NO)
	    {
	      [_documentView setNeedsDisplayInRect: 
			       [self convertRect: redrawRect 
				     toView: _documentView]];
	    }

	  /* Right */
	  redrawRect = NSMakeRect (NSMaxX (intersection), _bounds.origin.y,
				   NSMaxX (_bounds) - NSMaxX (intersection),
				   _bounds.size.height);
	  if (NSIsEmptyRect (redrawRect) == NO)
	    {
	      [_documentView setNeedsDisplayInRect: 
			       [self convertRect: redrawRect 
				     toView: _documentView]];
	    }

	  /* Up (or Down according to whether it's flipped or not) */
	  redrawRect = NSMakeRect (_bounds.origin.x, NSMinY (_bounds),
				   _bounds.size.width, 
				   NSMinY (intersection) - NSMinY (_bounds));
	  if (NSIsEmptyRect (redrawRect) == NO)
	    {
	      [_documentView setNeedsDisplayInRect: 
			       [self convertRect: redrawRect 
				     toView: _documentView]];
	    }

	  /* Down (or Up) */
	  redrawRect = NSMakeRect (_bounds.origin.x, NSMaxY (intersection),
				   _bounds.size.width, 
				   NSMaxY (_bounds) - NSMaxY (intersection));
	  if (NSIsEmptyRect (redrawRect) == NO)
	    {
	      [_documentView setNeedsDisplayInRect: 
			       [self convertRect: redrawRect 
				     toView: _documentView]];
	    }
	}
    }
  else
    {
      // dont copy anything -- docview draws it all
      [super setBoundsOrigin: newBounds.origin];
      [_documentView setNeedsDisplayInRect: [self documentVisibleRect]];
    }

  /* ?? TODO: Understand the following code - and add explanatory comment */
  if ([NSView focusView] == _documentView)
    {
      PStranslate (NSMinX (originalBounds) - point.x, 
		   NSMinY (originalBounds) - point.y);
    }
  
  [_super_view reflectScrolledClipView: self];
}

- (NSPoint) constrainScrollPoint: (NSPoint)proposedNewOrigin
{
  NSRect	documentFrame;
  NSPoint	new = proposedNewOrigin;

  if (_documentView == nil)
    {
      return _bounds.origin;
    }
  
  documentFrame = [_documentView frame];
  if (documentFrame.size.width <= _bounds.size.width)
    {
      new.x = documentFrame.origin.x;
    }
  else if (proposedNewOrigin.x <= documentFrame.origin.x)
    {
      new.x = documentFrame.origin.x;
    }
  else if (proposedNewOrigin.x + _bounds.size.width >= NSMaxX(documentFrame))
    {
      new.x = NSMaxX(documentFrame) - _bounds.size.width;
    }

  if (documentFrame.size.height <= _bounds.size.height)
    {
      new.y = documentFrame.origin.y;
    }
  else if (proposedNewOrigin.y <= documentFrame.origin.y)
    {
      new.y = documentFrame.origin.y;
    }
  else if (proposedNewOrigin.y + _bounds.size.height >= NSMaxY(documentFrame))
    {
      new.y = NSMaxY(documentFrame) - _bounds.size.height;
    }

  // make it an integer coordinate in device space
  // to avoid some nice effects when scrolling
  new = [self convertPoint: new  toView: nil];
  new.x = (int)new.x;
  new.y = (int)new.y;
  new = [self convertPoint: new  fromView: nil];

  return new;
}

- (NSRect) documentRect
{
  NSRect documentFrame;
  NSRect clipViewBounds;
  NSRect rect;

  if (_documentView == nil)
    {
      return _bounds;
    }
  
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
    {
      return NSZeroRect;
    }

  documentBounds = [_documentView bounds];
  clipViewBounds = [self convertRect: _bounds  toView: _documentView];
  rect = NSIntersectionRect (documentBounds, clipViewBounds);

  return rect;
}

- (void) drawRect: (NSRect)rect
{
  if (_drawsBackground)
    {
      [_backgroundColor set];
      NSRectFill(rect);
    }
}

- (BOOL) autoscroll: (NSEvent*)theEvent
{
  NSPoint new;

  if (_documentView == nil)
    {
      return NO;
    }
  
  new = [_documentView convertPoint: [theEvent locationInWindow] 
		       fromView: nil];
  new = [self constrainScrollPoint: new];

  if (NSPointInRect(new, [self documentVisibleRect]))
  {
    return NO;
  }

  [self setBoundsOrigin: new];
  return YES;
}

- (void) viewBoundsChanged: (NSNotification*)aNotification
{
  [_super_view reflectScrolledClipView: self];
}

- (void) viewFrameChanged: (NSNotification*)aNotification
{
  [self setBoundsOrigin: [self constrainScrollPoint: _bounds.origin]];

  /* If document frame does not completely cover _bounds */
  if (NSContainsRect([_documentView frame], _bounds) == NO)
    {
      /*
       * fill the area not covered by documentView with background color
       */
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
  [self setBoundsOrigin: [self constrainScrollPoint: _bounds.origin]];
  [_super_view reflectScrolledClipView: self];
}

- (void) setFrameOrigin: (NSPoint)aPoint
{
  [super setFrameOrigin: aPoint];
  [self setBoundsOrigin: [self constrainScrollPoint: _bounds.origin]];
  [_super_view reflectScrolledClipView: self];
}

- (void) setFrame: (NSRect)rect
{
  [super setFrame: rect];
  [self setBoundsOrigin: [self constrainScrollPoint: _bounds.origin]];
  [_super_view reflectScrolledClipView: self];
}

- (void) translateOriginToPoint: (NSPoint)aPoint
{
  [super translateOriginToPoint: aPoint];
  [_super_view reflectScrolledClipView: self];
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
  ASSIGN (_cursor, aCursor);
}

- (NSCursor*) documentCursor
{
  return _cursor;
}

- (NSColor*) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor*)aColor
{
  ASSIGN (_backgroundColor, aColor);

  if (_drawsBackground == NO || _backgroundColor == nil
      || [_backgroundColor alphaComponent] < 1.0)
    {
      _isOpaque = NO;
    }
  else
    {
      _isOpaque = YES;
    }
}

- (void) setDrawsBackground:(BOOL)flag
{
  _drawsBackground = flag; 

  if (_drawsBackground == NO || _backgroundColor == nil
      || [_backgroundColor alphaComponent] < 1.0)
    {
      _isOpaque = NO;
    }
  else
    {
      _isOpaque = YES;
    }
}

- (BOOL) drawsBackground
{
  return _drawsBackground;
}

- (BOOL) isOpaque
{
  return _isOpaque;
}

- (BOOL) isFlipped
{
  return (_documentView != nil) ? _documentView->_rFlags.flipped_view : NO;
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
- (BOOL) acceptsFirstResponder
{
  return _documentView != nil;
}

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
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_drawsBackground];
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
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_drawsBackground];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cursor];

  document = [aDecoder decodeObject];
  [self setDocumentView: document];

  return self;
}
@end
