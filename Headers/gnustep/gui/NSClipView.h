/* 
   NSClipView.h

   A clipped view

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#ifndef _GNUstep_H_NSClipView
#define _GNUstep_H_NSClipView

#include <AppKit/NSView.h>

@class NSNotification;

@class NSCursor;
@class NSEvent;
@class NSColor;

@interface NSClipView : NSView <NSCoding>
{
  // Attributes
}

//
// Managing the Document View 
//
- (NSRect)documentRect;
- (id)documentView;
- (NSRect)documentVisibleRect;
- (void)setDocumentView:(NSView *)aView;

//
// Setting the Cursor 
//
- (NSCursor *)documentCursor;
- (void)setDocumentCursor:(NSCursor *)anObject;

//
// Setting the Background Color
//
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)color;

//
// Scrolling 
//
- (BOOL)autoscroll:(NSEvent *)theEvent;
- (NSPoint)constrainScrollPoint:(NSPoint)newOrigin;
- (BOOL)copiesOnScroll;
- (void)scrollToPoint:(NSPoint)newOrigin;
- (void)setCopiesOnScroll:(BOOL)flag;

//
// Responding to a Changed Frame
//
- (void)viewFrameChanged:(NSNotification *)notification;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSClipView
