/*
   NSTableHeaderView.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Michael Hanni  <mhanni@sprintmail.com>
   Date: 1999
   Skeleton.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999
   First actual coding.

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
  // TODO
  return -1;
}
- (NSRect)headerRectOfColumn: (int)columnIndex
{
  NSArray* columns;
  NSRect rect;
  int i;

  if (_tableView == nil)
    return NSZeroRect;

  columns = [_tableView tableColumns];
  
  NSAssert(columnIndex > 0, NSInternalInconsistencyException);
  NSAssert(columnIndex < [columns count], NSInternalInconsistencyException);

  rect.origin.x = _bounds.origin.x;
  rect.origin.y = _bounds.origin.y;
  rect.size.height = _bounds.size.height;
  
  for (i = 0; i < columnIndex; i++)
    {
      rect.origin.x += [[columns objectAtIndex: i] width];
    }
  rect.size.width = [[columns objectAtIndex: columnIndex] width];

  return rect;
}

/*
 * Overidden Methods
 */
- (void)drawRect: (NSRect)aRect
{
  NSArray* columns;
  NSRange columnsToDraw;
  int i;

  if (_tableView == nil)
    return;
  
  columnsToDraw = [_tableView columnsInRect: aRect];
  if (columnsToDraw.length == 0)
    return;

  columns = [_tableView tableColumns];
  
  for (i = columnsToDraw.location; i < columnsToDraw.length + 1; i++)
    {
      [[[columns objectAtIndex: i] headerCell] 
	drawWithFrame: [self headerRectOfColumn: i] 
	inView: self];
    }
}
-(void)mouseDown: (NSEvent*)event
{
  // TODO
  [super mouseDown: event];
}
@end
