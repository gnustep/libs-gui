/*
   NSTableHeaderView.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Michael Hanni  <mhanni@sprintmail.com>
   Date: 1999
   Skeleton.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999
   First actual coding.

   Author: Nicola Pero <nicola@brainstorm.co.uk>
   Date: August 2000
   Selection and Dragging of Columns.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/NSArray.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSTableHeaderView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSApplication.h>

@implementation NSTableHeaderView
{
}
/*
 *
 * Class methods
 *
 */
+ (void) initialize
{
  if (self == [NSTableColumn class])
    [self setVersion: 1];
}

/*
 *
 * Instance methods
 *
 */

/*
 * Initializes an instance
 */

// TODO: Remove this method, if not really needed
- (NSTableHeaderView*)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  _tableView = nil;
  return self;
}
/*
 * Setting the table view 
 */
- (void)setTableView: (NSTableView*)aTableView
{
  // We do not RETAIN aTableView but aTableView is supposed 
  // to RETAIN us.
  _tableView = aTableView;

}
- (NSTableView*)tableView
{
  return _tableView;
}
/*
 * Checking altered columns 
 */
- (int)draggedColumn
{
  // TODO
  return -1;
}
- (float)draggedDistance
{
  // TODO
  return -1;
}
- (int)resizedColumn
{
  // TODO
  return -1;
}
/*
 * Utility methods 
 */
- (int)columnAtPoint: (NSPoint)aPoint
{
  if (_tableView == nil)
    return -1;

  /* Ask to the tableview, which is caching geometry info */
  aPoint = [self convertPoint: aPoint toView: _tableView];
  aPoint.y = [_tableView bounds].origin.y;
  return [_tableView columnAtPoint: aPoint];
}

- (NSRect)headerRectOfColumn: (int)columnIndex
{
  NSRect rect;

  if (_tableView == nil)
    return NSZeroRect;

  /* Ask to the tableview, which is caching geometry info */
  rect = [_tableView rectOfColumn: columnIndex];
  rect = [self convertRect: rect fromView: _tableView];
  rect.origin.y = _bounds.origin.y;
  rect.size.height = _bounds.size.height;
  
  return rect;
}

/*
 * Overidden Methods
 */
- (void)drawRect: (NSRect)aRect
{
  NSArray *columns;
  int firstColumnToDraw;
  int lastColumnToDraw;
  NSRect drawingRect;
  NSTableColumn *column;
  float width;
  int i;

  if (_tableView == nil)
    return;

  firstColumnToDraw = [self columnAtPoint: NSMakePoint (aRect.origin.x,
							aRect.origin.y)];
  if (firstColumnToDraw == -1)
    firstColumnToDraw = 0;

  lastColumnToDraw = [self columnAtPoint: NSMakePoint (NSMaxX (aRect),
						       aRect.origin.y)];
  if (lastColumnToDraw == -1)
    lastColumnToDraw = [_tableView numberOfColumns] - 1;

  drawingRect = [self headerRectOfColumn: firstColumnToDraw];
  
  columns = [_tableView tableColumns];
  
  for (i = firstColumnToDraw; i <= lastColumnToDraw; i++)
    {
      column = [columns objectAtIndex: i];
      width = [column width];
      drawingRect.size.width = width;
      [[column headerCell] drawWithFrame: drawingRect
			   inView: self];
      drawingRect.origin.x += width;
    }
}
-(void)mouseDown: (NSEvent*)event
{
  NSPoint location = [event locationInWindow];
  int clickCount;
  int columnIndex;
  
  clickCount = [event clickCount];
  
  if (clickCount > 2)
    {
      return;
    }
  
  location = [self convertPoint: location fromView: nil];
  columnIndex = [self columnAtPoint: location];
  if (columnIndex == -1)
    {
      return;  
    }

  if (clickCount == 2)
    {
      [_tableView _sendDoubleActionForColumn: columnIndex];
      return;
    }

  if (clickCount == 1)
    {
      // TODO: Resizing table columns
      // Start resizing if the mouse is down on the bounds of a column.

      /* Dragging */
      /* Wait for mouse dragged events. 
	 If mouse is dragged, move the column.
	 If mouse is not dragged but released, select/deselect the column. */
      {
	BOOL mouseDragged = NO;
	BOOL startedPeriodicEvents = NO;
	unsigned int eventMask = (NSLeftMouseUpMask 
				  | NSLeftMouseDraggedMask 
				  | NSPeriodicMask);
	unsigned int modifiers = [event modifierFlags];
	NSEvent *lastEvent;
	BOOL done = NO;
	NSPoint mouseLocationWin;
	NSDate *distantFuture = [NSDate distantFuture];
	NSRect visibleRect = [self convertRect: [self visibleRect]
				   toView: nil];
	float minXVisible = NSMinX (visibleRect);
	float maxXVisible = NSMaxX (visibleRect);
	BOOL mouseLeft = NO;
	/* We have three zones of speed. 
	   0   -  50 pixels: period 0.2  <zone 1>
	   50  - 100 pixels: period 0.1  <zone 2>
	   100 - 150 pixels: period 0.01 <zone 3> */
	float oldPeriod = 0;
	inline float computePeriod ()
	  {
	    float distance = 0;
	    
	    if (mouseLocationWin.x < minXVisible) 
	      {
		distance = minXVisible - mouseLocationWin.x; 
	      }
	    else if (mouseLocationWin.x > maxXVisible)
	      {
		distance = mouseLocationWin.x - maxXVisible;
	      }
	    
	    if (distance < 50) 
	      return 0.2;
	    else if (distance < 100) 
	      return 0.1;
	    else   
	      return 0.01;
	  }

	while (done != YES)
	  {
	    lastEvent = [NSApp nextEventMatchingMask: eventMask 
			       untilDate: distantFuture
			       inMode: NSEventTrackingRunLoopMode 
			       dequeue: YES]; 
	    
	    switch ([lastEvent type])
	      {
	      case NSLeftMouseUp:
		done = YES;
		break;
	      case NSLeftMouseDragged:
		if (mouseDragged == NO)
		  {
		    // TODO: Deselect the column, prepare for dragging
		  }
		mouseDragged = YES;
		mouseLocationWin = [lastEvent locationInWindow]; 
		if ((mouseLocationWin.x > minXVisible) 
		    && (mouseLocationWin.x < maxXVisible))
		  {
		    NSPoint mouseLocationView;
		    
		    if (startedPeriodicEvents == YES)
		      {
			[NSEvent stopPeriodicEvents];
			startedPeriodicEvents = NO;
		      }
		    mouseLocationView = [self convertPoint: 
						mouseLocationWin 
					      fromView: nil];
		    // TODO: drag the column 

		    //[_window flushWindow];
		    // [nc postNotificationName: 
		    //                   object: self];
		      }
		else /* Mouse dragged out of the table */
		  {
		    if (startedPeriodicEvents == YES)
		      {
			/* Check - if the mouse did not change zone, 
			   we do nothing */
			if (computePeriod () == oldPeriod)
			  break;
			
			[NSEvent stopPeriodicEvents];
		      }
		    /* Start periodic events */
		    oldPeriod = computePeriod ();
		    
		    [NSEvent startPeriodicEventsAfterDelay: 0
			     withPeriod: oldPeriod];
		    startedPeriodicEvents = YES;
		    if (mouseLocationWin.x <= minXVisible) 
		      mouseLeft = YES;
		    else
		      mouseLeft = NO;
		  }
		break;
	      case NSPeriodic:
		if (mouseLeft == YES) // mouse left the table
		  {
		    // TODO: Drag the column 
		  }
		else /* mouse right the table */
		  {
		    // TODO: Drag the column 
		  }
		// [nc postNotificationName: 
		//                   object: self];
		break;
	      default:
		break;
	      }
	  }
	
	if (mouseDragged == NO)
	  {
	    [_tableView _selectColumn: columnIndex
			modifiers: modifiers];
	  }
	else // mouseDragged == YES
	  {
	    if (startedPeriodicEvents == YES)
	      [NSEvent stopPeriodicEvents];
	    
	    // TODO: Move the dragged column
	  }
	return;
      }
    }
}
@end

