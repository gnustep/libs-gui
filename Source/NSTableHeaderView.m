/** <title>NSTableHeaderView</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999
   First actual coding.

   Author: Nicola Pero <nicola@brainstorm.co.uk>
   Date: August 2000, Semptember 2000
   Selection and resizing of Columns.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSRunLoop.h>
#include "AppKit/NSTableHeaderCell.h"
#include "AppKit/NSTableHeaderView.h"
#include "AppKit/NSTableColumn.h"
#include "AppKit/NSTableView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSGraphics.h"

/*
 * Number of pixels in either direction that will be counted as a hit 
 * on the column border and trigger a column resize.
 */
#define mouse_sensitivity 4

@interface NSTableView (GNUstepPrivate)
- (void) _userResizedTableColumn: (int)index
                           width: (float)width;
- (float *) _columnOrigins;
- (void) _mouseDownInHeaderOfTableColumn: (NSTableColumn *)tc;
- (void) _didClickTableColumn: (NSTableColumn *)tc;
@end

@implementation NSTableHeaderView

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
- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if (self == nil)
      return nil;

  _tableView = nil;
  _resizedColumn = -1;
  return self;
}

- (BOOL) isFlipped
{
  return YES;
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
- (int) draggedColumn
{
  // TODO
  return -1;
}
- (float) draggedDistance
{
  // TODO
  return -1;
}
- (int) resizedColumn
{
  return _resizedColumn;
}
/*
 * Utility methods 
 */
- (int) columnAtPoint: (NSPoint)aPoint
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
  NSTableColumn *highlightedTableColumn;
  float width;
  int i;
  NSCell *cell;

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
  if (![self isFlipped])
    {
      drawingRect.origin.y++;
    }
  drawingRect.size.height--;

  columns = [_tableView tableColumns];
  highlightedTableColumn = [_tableView highlightedTableColumn];
  
  for (i = firstColumnToDraw; i < lastColumnToDraw; i++)
    {
      column = [columns objectAtIndex: i];
      width = [column width];
      drawingRect.size.width = width;
      cell = [column headerCell];
      if ((column == highlightedTableColumn)
          || [_tableView isColumnSelected: i])
        {
          [cell setHighlighted: YES];
        }
      else
        {
          [cell setHighlighted: NO];
        }
      [cell drawWithFrame: drawingRect
                           inView: self];
      drawingRect.origin.x += width;
    }
  if (lastColumnToDraw == [_tableView numberOfColumns] - 1)
    {
      column = [columns objectAtIndex: lastColumnToDraw];
      width = [column width] - 1;
      drawingRect.size.width = width;
      cell = [column headerCell];
      if ((column == highlightedTableColumn)
          || [_tableView isColumnSelected: lastColumnToDraw])
        {
          [cell setHighlighted: YES];
        }
      else
        {
          [cell setHighlighted: NO];
        }
      [cell drawWithFrame: drawingRect
                           inView: self];
      drawingRect.origin.x += width;
    }
  else
    {
      column = [columns objectAtIndex: lastColumnToDraw];
      width = [column width];
      drawingRect.size.width = width;
      cell = [column headerCell];
      if ((column == highlightedTableColumn)
          || [_tableView isColumnSelected: lastColumnToDraw])
        {
          [cell setHighlighted: YES];
        }
      else
        {
          [cell setHighlighted: NO];
        }
      [cell drawWithFrame: drawingRect
                           inView: self];
      drawingRect.origin.x += width;
    }

  {
    NSRectEdge up_sides[] = {NSMinYEdge, NSMaxXEdge};
    NSRectEdge dn_sides[] = {NSMaxYEdge, NSMaxXEdge};
    float grays[] = {NSBlack, NSBlack};
    
    if (![self isFlipped])
      {
        NSDrawTiledRects(_bounds, aRect, up_sides, grays, 2);
      }
    else
      {
        NSDrawTiledRects(_bounds, aRect, dn_sides, grays, 2);
      }
  }
}

- (void) mouseDown: (NSEvent*)event
{
  NSPoint location = [event locationInWindow];
  int clickCount;
  int columnIndex;
  NSTableColumn *currentColumn;

  clickCount = [event clickCount];

  /*  
  if (clickCount > 2)
    {
      return;
    }
  */  

  location = [self convertPoint: location fromView: nil];
  columnIndex = [self columnAtPoint: location];
  
  if (columnIndex == -1)
    {
      return;  
    }
  currentColumn = [[_tableView tableColumns]
                    objectAtIndex: columnIndex];


  if (clickCount == 2)
    {
      [_tableView _sendDoubleActionForColumn: columnIndex];
      //      return;
    }

  //  if (clickCount == 1)
    {
      NSRect rect = [self headerRectOfColumn: columnIndex];

      /* Safety check */
      if (_resizedColumn != -1)
        {
          NSLog(@"Bug: starting resizing of column while already resizing!");
          _resizedColumn = -1;
        }
      
      if ([_tableView allowsColumnResizing])
        {
          /* Start resizing if the mouse is down on the bounds of a column. */
          if (location.x >= NSMaxX(rect) - mouse_sensitivity)
            {
              if (columnIndex < [_tableView numberOfColumns])
                {
                  _resizedColumn = columnIndex;
                }
              else
                {
                  NSLog(@"Bug: Trying to resize column past the end of the table.");
                }
            }
          else if (location.x <= NSMinX(rect) + mouse_sensitivity) 
            {
              if (columnIndex > 0)
                {
                  _resizedColumn = columnIndex - 1;
                }
            }
        }

      /* Resizing */
      if (_resizedColumn != -1)
        {
          /* Width of the highlighted area. */
          const float divWidth = 4;
          /* Dragging limits */
          float minCoord; 
          float maxCoord; 
          float minAbsCoord; 
          float maxAbsCoord; 
          float minVisCoord;
          float maxVisCoord;
          NSRect tvRect;
          NSPoint unconverted;
          NSArray *columns;
          /* Column on the left of resizing bound */
          NSTableColumn *column;
          NSRect rectLow = [self headerRectOfColumn: _resizedColumn];
          /* Old highlighted rect, used to avoid useless redrawing */
          NSRect oldRect = NSZeroRect;
          /* Current highlighted rect */
          NSRect r;
          /* Mouse position */
          float p;
          float q;
          BOOL outside = NO;
          /* YES if some highlighting was done and needs to be undone */
          BOOL lit = NO;
          /* YES if some dragging was actually done - to avoid
             retiling/redrawing the table if no dragging is done */
          BOOL dragged = NO;
          NSEvent *e;
          NSDate *farAway = [NSDate distantFuture];
          unsigned int eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask
            | NSPeriodicMask;

          /* Determine dragging limits, constrained to visible rect */
          rect = [self visibleRect];
          minVisCoord = MAX (NSMinX (rectLow), NSMinX (rect)) + divWidth;
          maxVisCoord = NSMaxX (rect) - divWidth;
          
          /* Then constrain to minimum and maximum column width if any */
          columns = [_tableView tableColumns];
          /* Column at the left */
          column = [columns objectAtIndex: _resizedColumn];
          if ([column isResizable] == NO)
            {
              _resizedColumn = -1;
              return;
            }
          /* We use p as a temporary variable for a while */
          minAbsCoord = NSMinX (rectLow) + [column minWidth];
          maxAbsCoord = NSMinX (rectLow) + [column maxWidth];
          minCoord = MAX (minAbsCoord, minVisCoord);
          maxCoord = MIN (maxAbsCoord, maxVisCoord);
          

          /* Do we need to check that we already fit into this area ? 
             We should */

          [self lockFocus];
          
          [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];
          
          [[NSColor lightGrayColor] set];
          r.size.width = divWidth;
          r.size.height = NSHeight (rect);
          r.origin.y = NSMinY (rect);
          
          [NSEvent startPeriodicEventsAfterDelay: 0.05 withPeriod: 0.05];
          e = [NSApp nextEventMatchingMask: eventMask
                     untilDate: farAway
                     inMode: NSEventTrackingRunLoopMode
                     dequeue: YES];

          /* Safety assignment to make sure p is never left
             unitialized - should make no difference with current code
             but anyway */
          p = NSMaxX (rectLow);

          while ([e type] != NSLeftMouseUp)
            {
              if ([e type] != NSPeriodic)
                {
                  dragged = YES;
                  unconverted = [e locationInWindow];
                  p = [self convertPoint: unconverted fromView: nil].x;
                  q = p;
                  if (p > maxVisCoord || p < minVisCoord)
                    {
                      outside = YES;
                    }
                  else
                    {
                      outside = NO;
                    }
                  if (p < minCoord)
                    {
                      p = minCoord;
                    }
                  else if (p > maxCoord)
                    {
                      p = maxCoord;
                    }
                  r.origin.x = p - (divWidth / 2.);
                  
                  if (!outside && NSEqualRects(r, oldRect) == NO)
                    {
                      if (lit == YES)
                        {
                          NSHighlightRect (oldRect);
                        }
                      NSHighlightRect (r);
                      [_window flushWindow];
                      lit = YES;
                      oldRect = r;
                    }
                }
              else
                {
                  if (outside)
                    {
                      q = [self convertPoint: unconverted
                                fromView: nil].x;
                      if (lit)
                        {
                          NSHighlightRect (oldRect);
                          [_window flushWindow];
                          lit = NO;
                        }
                      tvRect = [_tableView visibleRect];
                      if (q > maxVisCoord)
                        {
                          if (q > maxAbsCoord + 5)
                            q = maxAbsCoord + 5;
                          tvRect.origin.x += (q - maxVisCoord)/2;
                        }
                      else if (q < minVisCoord)
                        {
                          if (q < minAbsCoord - 5)
                            q = minAbsCoord - 5;
                          tvRect.origin.x += (q - minVisCoord)/2;
                        }
                      else // TODO remove this condition
                        {
                          NSLog(@"not outside !");
                        }
                      [_tableView scrollPoint: tvRect.origin];
                      rect = [self visibleRect];
                      minVisCoord = NSMinX (rect) + divWidth;
                      maxVisCoord = NSMaxX (rect) - divWidth;
                      minCoord = MAX (minAbsCoord, minVisCoord);
                      maxCoord = MIN (maxAbsCoord, maxVisCoord);
                    }
                }
              e = [NSApp nextEventMatchingMask: eventMask
                         untilDate: farAway
                         inMode: NSEventTrackingRunLoopMode
                         dequeue: YES];
            }
          [NSEvent stopPeriodicEvents];
          if (outside)
            {
              p = [self convertPoint: [e locationInWindow] fromView: nil].x;
              if (p > maxAbsCoord)
                p = maxAbsCoord;
              else if (p < minAbsCoord)
                p = minAbsCoord;
            }
          if (lit == YES)
            {
              NSHighlightRect(oldRect);
              [_window flushWindow];
            }

          [self unlockFocus];

          /* The following tiles the table.  We use a private method 
             which avoids tiling the table twice. */
          if (dragged == YES)
            {
              [_tableView _userResizedTableColumn: _resizedColumn
                          width: (p - NSMinX (rectLow))];
            }

          /* Clean up */
          _resizedColumn = -1;
          return;
        }

      /* We are not resizing
         Let's launch a mouseDownInHeaderOfTableColumn message
      */
      {
        NSRect rect = [self headerRectOfColumn: columnIndex];
        [_tableView _mouseDownInHeaderOfTableColumn: 
                      [[_tableView tableColumns] 
                        objectAtIndex: columnIndex]];
        rect.origin.y++;
        rect.size.height--;
        [[currentColumn headerCell] setHighlighted: YES];

        [self lockFocus];
        [[currentColumn headerCell]
          highlight: YES
          withFrame: rect
          inView: self];
        [self unlockFocus];
        [_window flushWindow];
      }


      /* Dragging */
      /* Wait for mouse dragged events. 
         If mouse is dragged, move the column.
         If mouse is not dragged but released, select/deselect the column. */
      if ([_tableView allowsColumnReordering])
        {
          int i = columnIndex;
          int j = columnIndex;
          float minCoord; 
          float maxCoord; 
          float minVisCoord;
          float maxVisCoord;
          float *_cO;
          float *_cO_minus1;
          int numberOfColumns = [_tableView numberOfColumns];
          unsigned int eventMask = (NSLeftMouseUpMask 
                                    | NSLeftMouseDraggedMask 
                                    | NSPeriodicMask);
          unsigned int modifiers = [event modifierFlags];
          NSEvent *e;
          NSDate *distantFuture = [NSDate distantFuture];
          NSRect visibleRect = [self visibleRect];
          NSRect tvRect;
          NSRect highlightRect = NSZeroRect, oldRect = NSZeroRect;
          BOOL outside = NO;
          BOOL lit = NO;
        
          BOOL mouseDragged = NO;
          float p;
          NSPoint unconverted;
          minVisCoord = NSMinX (visibleRect);
          maxVisCoord = NSMaxX (visibleRect);
          {
            NSRect bounds = [self bounds];
            minCoord = NSMinX(bounds);
            maxCoord = NSMaxX(bounds);
          }
          {
            float *_c = [_tableView _columnOrigins];
            _cO_minus1 = malloc((numberOfColumns + 3) * sizeof(float));
            _cO = _cO_minus1 + 1;
            memcpy(_cO, _c, numberOfColumns * sizeof(float));
            _cO[numberOfColumns] = maxCoord;
            _cO[numberOfColumns + 1] = maxCoord;
            _cO[-1] = minCoord;
          }

          highlightRect.size.height = NSHeight (visibleRect);
          highlightRect.origin.y = NSMinY (visibleRect);

          [self lockFocus];
          [[NSColor lightGrayColor] set];
          [NSEvent startPeriodicEventsAfterDelay: 0.05
                   withPeriod: 0.05];
          e = [NSApp nextEventMatchingMask: eventMask 
                     untilDate: distantFuture
                     inMode: NSEventTrackingRunLoopMode 
                     dequeue: YES];

          while ([e type] != NSLeftMouseUp)
            {
              switch ([e type])
                {
                case NSLeftMouseDragged:
                  unconverted = [e locationInWindow];
                  p = [self convertPoint: unconverted fromView: nil].x;
                  if (mouseDragged == NO)
                    {
                      NSLog(@"TODO: Deselect the column");
                    }
                  mouseDragged = YES;
                  if (p < minVisCoord || p > maxVisCoord)
                    {
                      outside = YES;
                    }
                  else
                    {
                      outside = NO;
                      i = j;
                      if (p > (_cO[i] + _cO[i+1]) / 2)
                        {
                          while (p > (_cO[i] + _cO[i+1]) / 2)
                            i++;
                        }
                      else if (p < (_cO[i] + _cO[i-1]) / 2)
                        {
                          while (p < (_cO[i] + _cO[i-1]) / 2)
                            i--;
                        }
                      if (i != columnIndex
                          && i != columnIndex + 1)
                        {
                          j = i;
                          highlightRect.size.height = NSHeight (visibleRect);
                          highlightRect.origin.y = NSMinY (visibleRect);
                          highlightRect.size.width = 7;
                          if (i == numberOfColumns)
                            {
                              highlightRect.origin.x = _cO[i] - 3;
                            }
                          else if (i == 0)
                            {
                              highlightRect.origin.x = _cO[i] - 3;
                            }
                          else
                            {
                              highlightRect.origin.x = _cO[i] - 3;
                            }
                          if (!NSEqualRects(highlightRect, oldRect))
                            {
                              if (lit)
                                NSHighlightRect(oldRect);
                              NSHighlightRect(highlightRect);
                              [_window flushWindow];
                            }
                          else if (!lit)
                            {
                              NSHighlightRect(highlightRect);
                              [_window flushWindow];
                            }
                          oldRect = highlightRect;
                          lit = YES;
                        }
                      else
                        {
                          i = columnIndex;
                          highlightRect.size.height = NSHeight (visibleRect);
                          highlightRect.origin.y = NSMinY (visibleRect);
                          highlightRect.origin.x = _cO[columnIndex];
                          highlightRect.size.width = 
                            _cO[columnIndex + 1] - _cO[columnIndex];
                        
                          if (!NSEqualRects(highlightRect, oldRect))
                            {
                              if (lit)
                                NSHighlightRect(oldRect);
                              //  NSHighlightRect(highlightRect);
                              [_window flushWindow];
                            }
                          else if (!lit)
                            {
                              //  NSHighlightRect(highlightRect);
                              // [_window flushWindow];
                            }
                          // oldRect = highlightRect;
                          oldRect = NSZeroRect;
                          lit = NO; //lit = YES;
                        }
                    }
                  break;
                case NSPeriodic:
                  if (outside == YES)
                    {
                      if (lit)
                        {
                          NSHighlightRect(oldRect);
                          [_window flushWindow];
                          lit = NO;
                          oldRect = NSZeroRect;
                        }
                      p = [self convertPoint: unconverted
                                fromView: nil].x;
                      tvRect = [_tableView visibleRect];
                      if (p > maxVisCoord)
                        {
                          if (p > maxCoord)
                            tvRect.origin.x += (p - maxVisCoord)/8;
                          else
                            tvRect.origin.x += (p - maxVisCoord)/2;
                        }
                      else if (p < minVisCoord)
                        {
                          if (p < minCoord)
                            tvRect.origin.x += (p - minVisCoord)/8;
                          else
                            tvRect.origin.x += (p - minVisCoord)/2;
                        }
                      else // TODO remove this condition
                        {
                          NSLog(@"not outside !");
                        }
                      [_tableView scrollPoint: tvRect.origin];
                      visibleRect = [self visibleRect];
                      minVisCoord = NSMinX (visibleRect);
                      maxVisCoord = NSMaxX (visibleRect);
                    }
                  break;
                default:
                  break;
                }
              e = [NSApp nextEventMatchingMask: eventMask 
                         untilDate: distantFuture
                         inMode: NSEventTrackingRunLoopMode 
                         dequeue: YES]; 
            }
          if (lit)
            {
              NSHighlightRect(highlightRect);
              [_window flushWindow];
              lit = NO;
            }



          [NSEvent stopPeriodicEvents];        
          [self unlockFocus];
          if (mouseDragged == NO)
            {
              [_tableView _selectColumn: columnIndex
                          modifiers: modifiers];
              
              [_tableView _didClickTableColumn:
                           currentColumn];

              [self setNeedsDisplay: YES];;
            }
          else // mouseDragged == YES
            {
              {
                NSRect rect = [self headerRectOfColumn: columnIndex];
                [_tableView _mouseDownInHeaderOfTableColumn: 
                              [[_tableView tableColumns] 
                                objectAtIndex: columnIndex]];
                rect.origin.y++;
                rect.size.height--;
                [[currentColumn headerCell]
                  setHighlighted: NO];
                
                [self lockFocus];
                [[currentColumn headerCell] 
                  highlight: NO
                  withFrame: rect
                  inView: self];
                [self unlockFocus];
                [_window flushWindow];
              }
              if (i > columnIndex)
                i--;
              if (i != columnIndex)
                {
                  [_tableView moveColumn: columnIndex
                              toColumn: i];
                }
            }
          free(_cO_minus1);
          return;
        }
      else
        {
          NSRect cellFrame = [self headerRectOfColumn: columnIndex];
          NSApplication *theApp = [NSApplication sharedApplication];
          unsigned int modifiers = [event modifierFlags];
          NSPoint location = [event locationInWindow];
          NSPoint point = [self convertPoint: location fromView: nil];

          if (![self mouse: point inRect: cellFrame])
            {
              NSLog(@"not in frame, what's happening ?");
              return;
            }

          event = [theApp nextEventMatchingMask: NSLeftMouseUpMask
                          untilDate: nil
                          inMode: NSEventTrackingRunLoopMode
                          dequeue: NO];
          

          location = [event locationInWindow];
          
          point = [self convertPoint: location fromView: nil];
          
          if (![self mouse: point inRect: cellFrame])
            {
              NSDebugLLog(@"NSCell", 
                          @"tableheaderview point not in cell frame\n");
              {
                NSRect rect = [self headerRectOfColumn: columnIndex];
                [_tableView _mouseDownInHeaderOfTableColumn: 
                              [[_tableView tableColumns] 
                                objectAtIndex: columnIndex]];
                rect.origin.y++;
                rect.size.height--;
                [[currentColumn headerCell]
                  setHighlighted: NO];
                
                [self lockFocus];
                [[currentColumn headerCell] 
                  highlight: NO
                  withFrame: rect
                  inView: self];
                [self unlockFocus];
                [_window flushWindow];
              }

            }
          else
            {
              [_tableView _selectColumn: columnIndex
                          modifiers: modifiers];
              [_tableView _didClickTableColumn:
                           currentColumn];

              [self setNeedsDisplay: YES];
              /*              
              if ([_tableView highlightedTableColumn] != currentColumn)
                {
                  NSRect rect = [self headerRectOfColumn: columnIndex];
                  
                  // [_tableView _mouseDownInHeaderOfTableColumn: 
                  // [[_tableView tableColumns] 
                  // objectAtIndex: columnIndex]];

                  rect.origin.y++;
                  rect.size.height--;
                  NSLog(@"highlight");
                  [[currentColumn headerCell] setHighlighted: NO];
                  
                  [[currentColumn headerCell] 
                    highlight: NO
                    withFrame: rect
                    inView: self];
                  [_window flushWindow];
                }
              */
            }
        }
    }
}

/*
 * Encoding/Decoding
 */

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  /* Nothing else to encode in NSTableHeaderView:
       - _tableView is set by the parent NSTableView
       - _resizedColumn is reset on decoding anyway
     */
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
  if (self == nil)
      return nil;

  _tableView = nil;
  _resizedColumn = -1;

  return self;
}

@end

