/*
   NSClipView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: July 1997
   
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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <gnustep/gui/config.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSClipView.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSGraphics.h>

#define ASSIGN(a, b) \
  [b retain]; \
  [a release]; \
  a = b;

#ifdef MIN
# undef MIN
#endif
#define MIN(a, b) \
    ({typedef _ta = (a), _tb = (b);   \
	_ta _a = (a); _tb _b = (b);     \
	_a < _b ? _a : _b; })

#ifdef MAX
# undef MAX
#endif
#define MAX(a, b) \
    ({typedef _ta = (a), _tb = (b);   \
	_ta _a = (a); _tb _b = (b);     \
	_a > _b ? _a : _b; })

@implementation NSClipView

- init
{
  [super init];
  [self setAutoresizesSubviews:YES];
  [self setBackgroundColor:[NSColor lightGrayColor]];
  return self;
}

- (void)setDocumentView:(NSView*)aView
{
  if (_documentView)
    [_documentView removeFromSuperview];

  ASSIGN(_documentView, aView);

  if (_documentView) {
    [self addSubview:_documentView];

    /* Register to notifications sent by the document view */
    [_documentView setPostsFrameChangedNotifications:YES];
    [_documentView setPostsBoundsChangedNotifications:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self
	selector:@selector(viewFrameChanged:)
	name:NSViewFrameDidChangeNotification object:_documentView];
    [[NSNotificationCenter defaultCenter] addObserver:self
	selector:@selector(viewBoundsChanged:)
	name:NSViewBoundsDidChangeNotification object:_documentView];
  }

  /* TODO: invoke superview's reflectScrolledClipView:? */
  [[self superview] reflectScrolledClipView:self];
}

- (void)resetCursorRects
{
  [self addCursorRect:[self bounds] cursor:_cursor];
}

- (void)scrollToPoint:(NSPoint)point
{
#ifdef DEBUGLOG
  NSPoint currentPoint = [self bounds].origin;

  NSLog (@"scrollToPoint: current point (%f, %f), point (%f, %f)",
	currentPoint.x, currentPoint.y,
	point.x, point.y);
#endif

  point = [self constrainScrollPoint:point];
  [self setBoundsOrigin:NSMakePoint(point.x, point.y)];

  if (_copiesOnScroll)
    /* TODO: move the visible portion of the document */;
  else
    [_documentView setNeedsDisplay:YES];
}

- (NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin
{
  NSRect documentFrame = [self documentRect];
  NSPoint new = proposedNewOrigin;

  if (proposedNewOrigin.x < documentFrame.origin.x)
    new.x = documentFrame.origin.x;
  else if (proposedNewOrigin.x
	   > documentFrame.size.width - bounds.size.width)
    new.x = documentFrame.size.width - bounds.size.width;

  if (proposedNewOrigin.y < documentFrame.origin.y)
    new.y = documentFrame.origin.y;
  else if (proposedNewOrigin.y
	   > documentFrame.size.height - bounds.size.height)
    new.y = documentFrame.size.height - bounds.size.height;

  return new;
}

- (NSRect)documentRect
{
  NSRect documentFrame = [_documentView frame];
  NSRect clipViewBounds = [self bounds];
  NSRect rect;

  rect.origin = documentFrame.origin;
  rect.size.width = MAX(documentFrame.size.width, clipViewBounds.size.width);
  rect.size.height = MAX(documentFrame.size.height,clipViewBounds.size.height);

  return rect;
}

- (NSRect)documentVisibleRect
{
  NSRect documentBounds = [_documentView bounds];
  NSRect clipViewBounds = [self bounds];
  NSRect rect;

  rect.origin = clipViewBounds.origin;
  rect.size.width = MIN(documentBounds.size.width, clipViewBounds.size.width);
  rect.size.height = MIN(documentBounds.size.height,
			 clipViewBounds.size.height);

  return rect;
}

- (BOOL)autoscroll:(NSEvent*)theEvent
{
  return 0;
}

- (void)viewBoundsChanged:(NSNotification*)aNotification
{
  [[self superview] reflectScrolledClipView:self];
}

- (void)viewFrameChanged:(NSNotification*)aNotification
{
  [self setBoundsOrigin:[self constrainScrollPoint:bounds.origin]];
  [[self superview] reflectScrolledClipView:self];
}

- (void)scaleUnitSquareToSize:(NSSize)newUnitSize
{
  [super scaleUnitSquareToSize:newUnitSize];
  [[self superview] reflectScrolledClipView:self];
}

- (void)setBoundsOrigin:(NSPoint)aPoint
{
  [super setBoundsOrigin:aPoint];
  [[self superview] reflectScrolledClipView:self];
}

- (void)setBoundsSize:(NSSize)aSize
{
  [super setBoundsSize:aSize];
  [[self superview] reflectScrolledClipView:self];
}

- (void)setFrameSize:(NSSize)aSize
{
  [super setFrameSize:aSize];
  [[self superview] reflectScrolledClipView:self];
}

- (void)setFrameOrigin:(NSPoint)aPoint
{
  [super setFrameOrigin:aPoint];
  [[self superview] reflectScrolledClipView:self];
}

- (void)setFrame:(NSRect)rect
{
  [super setFrame:rect];
  [[self superview] reflectScrolledClipView:self];
}

- (void)translateOriginToPoint:(NSPoint)aPoint
{
  [super translateOriginToPoint:aPoint];
  [[self superview] reflectScrolledClipView:self];
}

- (id)documentView				{ return _documentView; }
- (void)setCopiesOnScroll:(BOOL)flag		{ _copiesOnScroll = flag; }
- (BOOL)copiesOnScroll				{ return _copiesOnScroll; }
- (void)setDocumentCursor:(NSCursor*)aCursor	{ ASSIGN(_cursor, aCursor); }
- (NSCursor*)documentCursor			{ return _cursor; }
- (NSColor*)backgroundColor			{ return _backgroundColor; }
- (BOOL)isFlipped			{ return [_documentView isFlipped]; }
- (BOOL)acceptsFirstResponder		{ return _documentView != nil; }

- (void)setBackgroundColor:(NSColor*)aColor
{
  ASSIGN(_backgroundColor, aColor);
}

/* Disable rotation of clip view */
- (void)rotateByAngle:(float)angle
{}

- (void)setBoundsRotation:(float)angle
{}

- (void)setFrameRotation:(float)angle
{}

/* Managing responder chain */
- (BOOL)becomeFirstResponder
{
  return [_documentView becomeFirstResponder];
}

@end
