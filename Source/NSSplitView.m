/* 
   NSSplitView.m

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

#include <gnustep/gui/NSSplitView.h>

// NSSplitView notifications
NSString *NSSplitViewDidResizeSubviewsNotification;
NSString *NSSplitViewWillResizeSubviewsNotification;

@implementation NSSplitView

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSplitView class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//

//
// Managing Component Views 
//
- (void)adjustSubviews
{}

- (float)dividerThickness
{
  return 0.0;
}

- (void)drawDividerInRect:(NSRect)aRect
{}

//
// Assigning a Delegate 
//
- (id)delegate
{
  return nil;
}

- (void)setDelegate:(id)anObject
{}

//
// Implemented by the Delegate 
//
- (void)splitView:(NSSplitView *)splitView
constrainMinCoordinate:(float *)min
maxCoordinate:(float *)max
ofSubviewAt:(int)offset
{}

- (void)splitView:(NSSplitView *)sender
resizeSubviewsWithOldSize:(NSSize)oldSize
{}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification
{}

- (void)splitViewWillResizeSubviews:(NSNotification *)notification
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
