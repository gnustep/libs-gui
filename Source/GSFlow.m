/** <title>GSFlow</title>

   <abstract>GSFlow class to layout views line by line dynamically (from left 
   to right and top to bottom)</abstract>

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date:  January 2007

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "GNUstepGUI/GSFlow.h"

/*
 * Private categories
 */

@interface NSView (GSFlow)
- (float) height;
- (float) width;
- (void) setHeight: (float)height;
- (void) setWidth: (float)width;
@end

@implementation NSView (GSFlow)
- (float) height
{
  return [self frame].size.height;
}

- (float) width
{
  return [self frame].size.width;
}

- (void) setHeight: (float)height
{
  float width = [self  width];

  [self setFrameSize: NSMakeSize(width, height)];
}

- (void) setWidth: (float)width
{
  float height = [self height];

  [self setFrameSize: NSMakeSize(width, height)];
}

- (float) x
{
  return [self frame].origin.x;
}

- (float) y
{
  return [self frame].origin.y;
}

- (void) setX: (float)x
{
  float y = [self  y];

  [self setFrameOrigin: NSMakePoint(x, y)];
}

- (void) setY: (float)y
{
  float x = [self x];

  [self setFrameOrigin: NSMakePoint(x, y)];
}
@end

/*
 * Dedicated helper class
 */
 
@interface GSLayoutLine : NSObject
{
  NSMutableArray *views;
  NSPoint baseLineLocation;
}

+ (id) layoutLineWithViews: (NSArray *)views;

- (NSPoint) baseLineLocation;
- (float) height;

@end

@implementation GSLayoutLine

+ (id) layoutLineWithViews: (NSArray *)views
{
    GSLayoutLine *layoutLine = [[GSLayoutLine alloc] init];
    
    ASSIGN(layoutLine->views, views);
    
    return AUTORELEASE(layoutLine);
}

- (NSMutableArray *) views
{
  return views;
}

- (void) setBaseLineLocation: (NSPoint)location
{
  baseLineLocation = location;

  NSEnumerator *e = [views objectEnumerator];
  NSView *view = nil;
  
  while ((view = [e nextObject]) != nil)
  {
    [view setY: baseLineLocation.y];
  }
}

- (NSPoint) baseLineLocation
{
  return baseLineLocation;  
}

- (float) height
{
  NSEnumerator *e = [views objectEnumerator];
  NSView *view = nil;
  int height = 0;
  
  /* We must look for the tallest layouted view (by line). Useful 
     once we get out of -computeViewLocationsForLayoutModel: view walking loop. */
           
  while ((view = [e nextObject]) != nil)
  {
    if ([view height] > height)
      height = [view height];
  }
  
  return height;
}

- (NSString *) description
{
    NSString *desc = [super description];
    NSEnumerator *e = [views objectEnumerator];
    id view = nil;
    
    while ((view = [e nextObject]) != nil)
    {
      desc = [desc stringByAppendingFormat: @", %@", NSStringFromRect([view frame])];
    }
    
    return desc;
}

@end

/*
 * Private methods
 */

@interface GSFlow (GNUstepPrivate)

- (void) setUpViewTree;
- (void) updateViewTree;

/* Layout processing methods */
- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel;
- (NSArray *) layoutedViewsForLayoutLineInViews: (NSArray *)views;

/* Utility methods */
- (NSRect) lineLayoutRectForViewAtIndex: (int)index;
- (NSPoint) locationForViewAtIndex: (int)index;
- (NSView *) viewIndexAtPoint: (NSPoint)location;
- (NSRange) viewRangeForLineLayoutWithIndex: (int)lineIndex;

@end

/*
 * Main implementation
 */

@implementation GSFlow

- (id) initWithViews: (NSArray *)views viewContainer: (NSView *)viewContainer
{
    self = [super init];
    
    if (self != nil)
    {
        if (views != nil)
        {
          ASSIGN(_layoutedViews, [views mutableCopy]);
        }
        else
        {
          _layoutedViews = [NSMutableArray new];
        }
        _layoutedViewIdentifiers = [NSMutableArray new];
        [self setViewContainer: viewContainer]; /* Will trigger -setUpViewTree */
    }
    
    return self;
}

- (void) dealloc
{
    /* Will take care to remove the subviews; that's important when the view 
       container is going to stay in use. */
    [self setViewContainer: nil]; 
    DESTROY(_layoutedViewIdentifiers);
    DESTROY(_layoutedViews);
    
    
    [super dealloc];
}

/** Moves the layouted views into the view container by removing them of their 
    previous superview, then adding them as view container subviews. */
- (void) setViewContainer: (NSView *)viewContainer
{
  BOOL viewTreeAltered = NO;
  
  if (_viewContainer != viewContainer)
    viewTreeAltered = YES;
    
  ASSIGN(_viewContainer, viewContainer);
  
  if (viewTreeAltered)
    [self setUpViewTree];
}

/** Returns the view where the layout happens (by computing location of a subview series). */
- (NSView *) viewContainer
{
  return _viewContainer;
}

- (void) setUpViewTree
{
  [_layoutedViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
  
  if (_viewContainer != nil)
  {
    NSEnumerator *e = [_layoutedViews objectEnumerator];
    NSView *layoutedView = nil;
    
    while ((layoutedView = [e nextObject]) != nil)
    {
      [_viewContainer addSubview: layoutedView];
    }
  }
}

- (void) updateViewTree
{
  [self setUpViewTree];
}

- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel
{
  NSEnumerator *layoutWalker = [layoutModel objectEnumerator];
  GSLayoutLine *line;
  NSEnumerator *lineWalker = nil;
  NSView *view;
  NSPoint viewLocation = NSMakePoint(0, [_viewContainer height]);
  
  while ((line = [layoutWalker nextObject]) != nil)
  {
    /*
         A +---------------------------------------
           |          ----------------
           |----------|              |    Layout
           | Layouted |   Layouted   |    Line
           |  View 1  |   View 2     |
         --+--------------------------------------- <-- here is the baseline
           B
       
       In view container coordinates we have:   
       baseLineLocation.x = A.x and baseLineLocation.y = A.y - B.y
       
     */
    
    [line setBaseLineLocation: viewLocation];
    lineWalker = [[line views] objectEnumerator];
    
    while ((view = [lineWalker nextObject]) != nil)
    {
        [view setX: viewLocation.x];
        viewLocation.x += [view width];
    }
    
    /* NOTE: to avoid computing view locations when they are outside of the
       frame, think to add an exit condition here. */
    
    /* Before computing the following views location in 'x' on the next line, we have 
       to reset the 'x' accumulator and take in account the end of the current 
       line, by substracting to 'y' the last layout line height. */
       [line setBaseLineLocation: 
         NSMakePoint([line baseLineLocation].x, viewLocation.y - [line height])];
       viewLocation.x = 0;
       viewLocation.y = [line baseLineLocation].y;
       
//       NSLog(@"View locations computed by layout line :%@", line);
  }

}

/* A layout is decomposed in lines. A line is decomposed in views. Finally a layout is displayed in a view container. */

/** Run the layout computation which assigns a location in the view container
    to each view added to the flow layout manager. */
- (void) layout
{
  NSMutableArray *unlayoutedViews = 
    [NSMutableArray arrayWithArray: _layoutedViews];
  NSArray *layoutedViewsByLine;
  NSMutableArray *layoutLineList = [NSMutableArray array];
  
  /* First start by breaking views to layout by lines. We have to fill the layout
     line (layoutLineList) until a view is crossing the right boundary which
     happens when -layoutedViewForNextLineInViews: returns nil. */
  while ([unlayoutedViews count] > 0)
  {
     layoutedViewsByLine = [self layoutedViewsForLayoutLineInViews: unlayoutedViews];
     [layoutLineList addObject: [GSLayoutLine layoutLineWithViews: layoutedViewsByLine]];    
     
     if ([layoutedViewsByLine count] == 0)
     {
       NSLog(@"Not enough space to layout all the views. Views remaining unlayouted: %@", unlayoutedViews);
       break;
     }
     
     /* In unlayoutedViews, remove the views which have just been layouted on the previous line. */
     [unlayoutedViews removeObjectsInArray: layoutedViewsByLine];
  }
  
  /* Now computes the location of every views by relying on the line by line 
     decomposition already made. */
  [self computeViewLocationsForLayoutModel: layoutLineList];
}

/** Returns a line filled with views to layout (stored in an array). */
- (NSArray *) layoutedViewsForLayoutLineInViews: (NSArray *)views
{
  //int maxViewHeightInLayoutLine = 0;
  NSEnumerator *e = [views objectEnumerator];
  NSView *layoutedView = nil;
  float hAccumulator = 0;
  NSMutableArray *layoutedViewsByLine = [NSMutableArray array];
    
  while ((layoutedView = [e nextObject]) != nil)
  {
    hAccumulator += [layoutedView width];
    
    if (hAccumulator < [_viewContainer width])
    {
      [layoutedViewsByLine addObject: layoutedView];
    }
    else
    {
      break;
    }
  }
  
  if ([layoutedViewsByLine count] == 0)
      return nil;
  
  return layoutedViewsByLine;
}

/* 
 * Utility methods
 */
 
- (NSRect) lineLayoutRectForViewAtIndex: (int)index { return NSZeroRect; }

- (NSPoint) locationForViewAtIndex: (int)index
{
    return NSZeroPoint;
}

- (NSView *) viewIndexAtPoint: (NSPoint)location
{
    return nil;
}

//- (NSRange) viewRangeForLineLayout:
- (NSRange) viewRangeForLineLayoutWithIndex: (int)lineIndex
{
    return NSMakeRange(0, 0);
}

/** Add a view to layout as a subview of the view container. */
- (void) addView: (NSView *)view
{
  if ([_layoutedViews containsObject: view] == NO)
    [_layoutedViews addObject: view];
}

/** Remove a view which was layouted as a subview of the view container. */
- (void) removeView: (NSView *)view
{
  [_layoutedViews removeObject: view];
}

/** Remove the view located at index in the series of views (which were layouted as subviews of the view container). */
- (void) removeViewAtIndex: (int)index
{
  [_layoutedViews removeObjectAtIndex: index];
}

/** Return the view located at index in the series of views (which are layouted as subviews of the view container). */
- (NSView *) viewAtIndex: (int)index
{
  return [_layoutedViews objectAtIndex: index];
}

- (void) addView: (NSView *)view withIdentifier: (NSString *)identifier
{
  if ([_layoutedViews containsObject: view] == NO)
  {
    [_layoutedViews addObject: view];
    [_layoutedViewIdentifiers setObject: view forKey: identifier];
  }
}

- (void) removeViewForIdentifier:(NSString *)identifier
{
  NSView *view = [_layoutedViewIdentifiers objectForKey: identifier];
    
  /* We try to remove view by its identifier first, then if it fails we won't
     remove a view which could be properly part of layouted views. */
    
  [_layoutedViewIdentifiers removeObjectForKey: identifier];
  [_layoutedViews removeObject: view];
}


- (NSView *) viewForIdentifier: (NSString *)identifier
{
  return [_layoutedViewIdentifiers objectForKey: identifier];
}

@end