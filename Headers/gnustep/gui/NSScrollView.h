/* 
   NSScrollView.h

   A scrolling view to allow documents larger than screen to be shown

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

#ifndef _GNUstep_H_NSScrollView
#define _GNUstep_H_NSScrollView

#include <AppKit/stdappkit.h>
#include <AppKit/NSView.h>
#include <AppKit/NSScroller.h>
#include <Foundation/NSCoder.h>

@interface NSScrollView : NSView <NSCoding>

{
  // Attributes
}

//
// Determining Component Sizes 
//
- (NSSize)contentSize;
- (NSRect)documentVisibleRect;

//
// Laying Out the NSScrollView 
//
+ (NSSize)contentSizeForFrameSize:(NSSize)size
	    hasHorizontalScroller:(BOOL)horizFlag
hasVerticalScroller:(BOOL)vertFlag 
	    borderType:(NSBorderType)aType;
+ (NSSize)frameSizeForContentSize:(NSSize)size
	    hasHorizontalScroller:(BOOL)horizFlag
hasVerticalScroller:(BOOL)vertFlag 
	    borderType:(NSBorderType)aType;
- (void)setHasHorizontalScroller:(BOOL)flag;
- (BOOL)hasHorizontalScroller;
- (void)setHasVerticalScroller:(BOOL)flag;
- (BOOL)hasVerticalScroller;
- (void)tile;
- (void)toggleRuler:(id)sender;
- (BOOL)isRulerVisible;

//
// Managing Component Views 
//
- (void)setDocumentView:(NSView *)aView;
- (id)documentView;
- (void)setHorizontalScroller:(NSScroller *)anObject;
- (NSScroller *)horizontalScroller;
- (void)setVerticalScroller:(NSScroller *)anObject;
- (NSScroller *)verticalScroller;
- (void)reflectScrolledClipView:(NSClipView *)cView;

//
// Modifying Graphic Attributes 
//
- (void)setBorderType:(NSBorderType)aType;
- (NSBorderType)borderType;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;

//
// Setting Scrolling Behavior 
//
- (float)lineScroll;
- (float)pageScroll;
- (void)setScrollsDynamically:(BOOL)flag;
- (BOOL)scrollsDynamically;
- (void)setLineScroll:(float)value;
- (void)setPageScroll:(float)value;

//
// Managing the Cursor 
//
- (void)setDocumentCursor:(NSCursor *)anObject;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSScrollView
