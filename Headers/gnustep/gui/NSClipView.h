/*
   NSClipView.h

   The class that contains the document view displayed by a NSScrollView.

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _GNUstep_H_NSClipView
#define _GNUstep_H_NSClipView

#include <AppKit/NSView.h>

@class NSNotification;
@class NSCursor;
@class NSColor;

@interface NSClipView : NSView
{
  NSView* _documentView;
  NSCursor* _cursor;
  NSColor* _backgroundColor;
  BOOL _drawsBackground;
  BOOL _copiesOnScroll;
  /* Cached */
  BOOL _isOpaque;
}

/* Setting the document view */
- (void)setDocumentView:(NSView*)aView;
- (id)documentView;

/* Scrolling */
- (void)scrollToPoint:(NSPoint)newOrigin;
- (BOOL)autoscroll:(NSEvent*)theEvent;
- (NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin;

/* Determining scrolling efficiency */
- (void)setCopiesOnScroll:(BOOL)flag;
- (BOOL)copiesOnScroll;

/* Getting the visible portion */
- (NSRect)documentRect;
- (NSRect)documentVisibleRect;

/* Setting the document cursor */
- (void)setDocumentCursor:(NSCursor*)aCursor;
- (NSCursor*)documentCursor;

/* Setting the background color */
- (void)setBackgroundColor:(NSColor*)aColor;
- (NSColor*)backgroundColor;

#ifndef	STRICT_OPENSTEP
/* Setting the background drawing */
- (void)setDrawsBackground:(BOOL)flag;
- (BOOL)drawsBackground;
#endif

/* Overridden NSView methods */
- (BOOL)acceptsFirstResponder;
- (BOOL)isFlipped;
- (void)rotateByAngle:(float)angle;
- (void)scaleUnitSquareToSize:(NSSize)newUnitSize;
- (void)setBoundsOrigin:(NSPoint)aPoint;
- (void)setBoundsRotation:(float)angle;
- (void)setBoundsSize:(NSSize)aSize;
- (void)setFrameSize:(NSSize)aSize;
- (void)setFrameOrigin:(NSPoint)aPoint;
- (void)setFrameRotation:(float)angle;
- (void)translateOriginToPoint:(NSPoint)aPoint;
- (void)viewBoundsChanged:(NSNotification*)aNotification;
- (void)viewFrameChanged:(NSNotification*)aNotification;

@end

@interface NSClipView (BackendMethods)
- (void)_translateToPoint:(NSPoint)point oldPoint:(NSPoint)oldPoint;
@end

#endif /* _GNUstep_H_NSClipView */
