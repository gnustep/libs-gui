/* 
   NSSplitView.h

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

#ifndef _GNUstep_H_NSSplitView
#define _GNUstep_H_NSSplitView

#include <AppKit/stdappkit.h>
#include <AppKit/NSView.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSNotification.h>

@interface NSSplitView : NSView <NSCoding>

{
  // Attributes
}

//
// Managing Component Views 
//
- (void)adjustSubviews;
- (float)dividerThickness;
- (void)drawDividerInRect:(NSRect)aRect;

//
// Assigning a Delegate 
//
- (id)delegate;
- (void)setDelegate:(id)anObject;

//
// Implemented by the Delegate 
//
- (void)splitView:(NSSplitView *)splitView
constrainMinCoordinate:(float *)min
    maxCoordinate:(float *)max
      ofSubviewAt:(int)offset;
- (void)splitView:(NSSplitView *)sender
resizeSubviewsWithOldSize:(NSSize)oldSize;
- (void)splitViewDidResizeSubviews:(NSNotification *)notification;
- (void)splitViewWillResizeSubviews:(NSNotification *)notification;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSSplitView
