/* 
   NSClipView.m

   Description...

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

#include <gnustep/gui/NSClipView.h>

@implementation NSClipView

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSClipView class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Managing the Document View 
//
- (NSRect)documentRect
{
  return NSZeroRect;
}

- (id)documentView
{
  return nil;
}

- (NSRect)documentVisibleRect
{
  return NSZeroRect;
}

- (void)setDocumentView:(NSView *)aView
{}

//
// Setting the Cursor 
//
- (NSCursor *)documentCursor
{
  return nil;
}

- (void)setDocumentCursor:(NSCursor *)anObject
{}

//
// Setting the Background Color
//
- (NSColor *)backgroundColor
{
  return nil;
}

- (void)setBackgroundColor:(NSColor *)color
{}

//
// Scrolling 
//
- (BOOL)autoscroll:(NSEvent *)theEvent
{
  return NO;
}

- (NSPoint)constrainScrollPoint:(NSPoint)newOrigin
{
  return NSZeroPoint;
}

- (BOOL)copiesOnScroll
{
  return NO;
}

- (void)scrollToPoint:(NSPoint)newOrigin
{}

- (void)setCopiesOnScroll:(BOOL)flag
{}

//
// Responding to a Changed Frame
//
- (void)viewFrameChanged:(NSNotification *)notification
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
