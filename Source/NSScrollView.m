/* 
   NSScrollView.m

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSScrollView.h>

@implementation NSScrollView

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSScrollView class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Laying Out the NSScrollView 
//
+ (NSSize)contentSizeForFrameSize:(NSSize)size
	    hasHorizontalScroller:(BOOL)horizFlag
hasVerticalScroller:(BOOL)vertFlag 
	    borderType:(NSBorderType)aType
{
  return NSZeroSize;
}

+ (NSSize)frameSizeForContentSize:(NSSize)size
	    hasHorizontalScroller:(BOOL)horizFlag
hasVerticalScroller:(BOOL)vertFlag 
	    borderType:(NSBorderType)aType
{
  return NSZeroSize;
}

//
// Instance methods
//
//
// Determining Component Sizes 
//
- (NSSize)contentSize
{
  return NSZeroSize;
}

- (NSRect)documentVisibleRect
{
  return NSZeroRect;
}

//
// Laying Out the NSScrollView 
//
- (void)setHasHorizontalScroller:(BOOL)flag
{}

- (BOOL)hasHorizontalScroller
{
  return NO;
}

- (void)setHasVerticalScroller:(BOOL)flag
{}

- (BOOL)hasVerticalScroller
{
  return NO;
}

- (void)tile
{}

- (void)toggleRuler:(id)sender
{}

- (BOOL)isRulerVisible
{
  return NO;
}

//
// Managing Component Views 
//
- (void)setDocumentView:(NSView *)aView
{}

- (id)documentView
{
  return nil;
}

- (void)setHorizontalScroller:(NSScroller *)anObject
{}

- (NSScroller *)horizontalScroller
{
  return nil;
}

- (void)setVerticalScroller:(NSScroller *)anObject
{}

- (NSScroller *)verticalScroller
{
  return nil;
}

- (void)reflectScrolledClipView:(NSClipView *)cView
{}

//
// Modifying Graphic Attributes 
//
- (void)setBorderType:(NSBorderType)aType
{}

- (NSBorderType)borderType
{
  return 0;
}

- (void)setBackgroundColor:(NSColor *)color
{}

- (NSColor *)backgroundColor
{
  return nil;
}

//
// Setting Scrolling Behavior 
//
- (float)lineScroll
{
  return 0.0;
}

- (float)pageScroll
{
  return 0.0;
}

- (void)setScrollsDynamically:(BOOL)flag
{}

- (BOOL)scrollsDynamically
{
  return NO;
}

- (void)setLineScroll:(float)value
{}

- (void)setPageScroll:(float)value
{}

//
// Managing the Cursor 
//
- (void)setDocumentCursor:(NSCursor *)anObject
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
