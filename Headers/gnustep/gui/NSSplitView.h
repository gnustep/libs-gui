/* -*-objc-*-
   NSSplitView.h

   Allows multiple views to share a region in a window

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Robert Vasvari <vrobi@ddrummer.com>
   Date: Jul 1998
   
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

#ifndef _GNUstep_H_NSSplitView
#define _GNUstep_H_NSSplitView

#include <AppKit/NSView.h>

@class NSImage, NSColor, NSNotification;

@interface NSSplitView : NSView
{
  id	   _delegate;
  float    _dividerWidth;
  float    _draggedBarWidth;
  BOOL     _isVertical;
  NSImage *_dimpleImage;
  NSColor *_backgroundColor; 
  NSColor *_dividerColor;
  BOOL     _never_displayed_before;
}

- (void) setDelegate: (id)anObject;
- (id) delegate;
- (void) adjustSubviews;
- (void) drawDividerInRect: (NSRect)aRect;
- (float) dividerThickness;

/* Vertical splitview has a vertical split bar */ 
- (void) setVertical: (BOOL)flag;
- (BOOL) isVertical;

#ifndef STRICT_OPENSTEP
- (BOOL) isSubviewCollapsed: (NSView *)subview;
- (BOOL) isPaneSplitter;
- (void) setIsPaneSplitter: (BOOL)flag;
#endif

@end

#ifndef	NO_GNUSTEP
@interface NSSplitView (GNUstepExtra)
/* extra methods to make it more usable */
- (float) draggedBarWidth;
- (void) setDraggedBarWidth: (float)newWidth;
/* if flag is yes, dividerThickness is reset to the height/width of the dimple
   image + 1;
*/
- (void) setDimpleImage: (NSImage *)anImage resetDividerThickness: (BOOL)flag;
- (NSImage *) dimpleImage;
- (NSColor *) backgroundColor;
- (void) setBackgroundColor: (NSColor *)aColor;
- (NSColor *) dividerColor;
- (void) setDividerColor: (NSColor *)aColor;

@end
#endif 

@interface NSObject (NSSplitViewDelegate)
- (void) splitView: (NSSplitView *)sender 
resizeSubviewsWithOldSize: (NSSize)oldSize;

- (void) splitView: (NSSplitView *)sender 
constrainMinCoordinate: (float *)min 
     maxCoordinate: (float *)max 
       ofSubviewAt: (int)offset;

- (float) splitView: (NSSplitView *)sender
constrainSplitPosition: (float)proposedPosition
	ofSubviewAt: (int)offset;

- (void) splitViewWillResizeSubviews: (NSNotification *)notification;
- (void) splitViewDidResizeSubviews: (NSNotification *)notification;

#ifndef STRICT_OPENSTEP
- (BOOL) splitView: (NSSplitView *)sender
canCollapseSubview: (NSView *)subview;

- (float) splitView: (NSSplitView *)sender
constrainMaxCoordinate: (float)proposedMax
	ofSubviewAt: (int)offset;

- (float) splitView: (NSSplitView *)sender
constrainMinCoordinate: (float)proposedMin
	ofSubviewAt: (int)offset;
#endif

@end

/* Notifications */
APPKIT_EXPORT NSString *NSSplitViewDidResizeSubviewsNotification;
APPKIT_EXPORT NSString *NSSplitViewWillResizeSubviewsNotification;

#endif
