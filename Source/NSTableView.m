/* 
   NSTableView.m

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2000
   
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

#import <AppKit/NSTableView.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableHeaderView.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/PSOperators.h>

@interface GSTableCornerView : NSView
{}
@end

@implementation GSTableCornerView

- (void) drawRect: (NSRect)aRect
{
  NSRect rect = _bounds;

  NSDrawButton (rect, aRect);
  [[NSColor controlShadowColor] set];
  rect.size.width -= 4;
  rect.size.height -= 4;
  rect.origin.x += 2;
  rect.origin.y += 2;
  NSRectFill (rect);
}

@end

@implementation NSTableView 

+ (void) initialize
{
  if (self == [NSTableView class])
    [self setVersion: 1];
}

/*
 * Initializing/Releasing 
 */

- (id) initWithFrame: (NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  _drawsGrid        = YES;
  _rowHeight        = 16.0;
  _intercellSpacing = NSMakeSize (2.0, 3.0);
  ASSIGN (_gridColor, [NSColor gridColor]); 
  ASSIGN (_backgroundColor, [NSColor controlBackgroundColor]); 
  ASSIGN (_tableColumns, [NSMutableArray array]);
  _headerView = [NSTableHeaderView new];
  [_headerView setFrameSize: NSMakeSize (frameRect.size.width, 22.0)];
  [_headerView setTableView: self];
  _cornerView = [GSTableCornerView new];
  [self tile];
  return self;
}

- (void) dealloc
{
  TEST_RELEASE (_dataSource);
  RELEASE (_gridColor);
  RELEASE (_tableColumns);
  TEST_RELEASE (_headerView);
  TEST_RELEASE (_cornerView);
  if (_numberOfColumns > 0)
    {
      NSZoneFree (NSDefaultMallocZone (), _columnOrigins);
    }
  [super dealloc];
}

- (BOOL) isFlipped
{
  return YES;
}

/*
 * Table Dimensions 
 */

- (int) numberOfColumns
{
  return _numberOfColumns;
}

- (int) numberOfRows
{
  return _numberOfRows;
}

/* 
 * Columns 
 */

- (void) addTableColumn: (NSTableColumn *)aColumn
{
  [aColumn setTableView: self];
  [_tableColumns addObject: aColumn];
  _numberOfColumns++;
  if (_numberOfColumns > 1)
    {
      _columnOrigins = NSZoneRealloc (NSDefaultMallocZone (), _columnOrigins,
				      (sizeof (float)) * _numberOfColumns);
    }
  else 
    {
      _columnOrigins = NSZoneMalloc (NSDefaultMallocZone (), 
      				     sizeof (float));
      _columnOrigins = malloc (sizeof (float));
    }      
  [self tile];
}

- (void) removeTableColumn: (NSTableColumn *)aColumn
{
  int columnIndex = [self columnWithIdentifier: [aColumn identifier]];

  if (columnIndex == -1)
    {
      NSLog (@"Warning: Tried to remove not-existent column from table");
      return;
    }

  [_tableColumns removeObject: aColumn];
  [aColumn setTableView: nil];
  _numberOfColumns--;
  if (_numberOfColumns > 0)
    {
      _columnOrigins = NSZoneRealloc (NSDefaultMallocZone (), _columnOrigins,
				      (sizeof (float)) * _numberOfColumns);
    }
  else 
    {
      NSZoneFree (NSDefaultMallocZone (), _columnOrigins);
    }      
  [self tile];
}

- (void) moveColumn: (int)columnIndex toColumn: (int)newIndex
{
  // TODO
  return;
}

- (NSArray *) tableColumns
{
  return AUTORELEASE ([_tableColumns mutableCopyWithZone: 
				       NSDefaultMallocZone ()]);
}

- (int) columnWithIdentifier: (id)anObject
{
  NSEnumerator	*enumerator = [_tableColumns objectEnumerator];
  NSTableColumn	*tb;
  int           return_value = 0;
  
  while ((tb = [enumerator nextObject]) != nil)
    {
      if ([[tb identifier] isEqual: anObject])
	return return_value;
      else
	return_value++;
    }
  return -1;
}

- (NSTableColumn *) tableColumnWithIdentifier:(id)anObject
{
  int indexOfColumn = [self columnWithIdentifier: anObject];

  if (indexOfColumn == -1)
    return nil;
  else 
    return [_tableColumns objectAtIndex: indexOfColumn];
}

/* 
 * Data Source 
 */

- (id) dataSource
{
  return _dataSource;
}

- (void) setDataSource: (id)anObject
{
  /* Used only for readability */
  SEL sel_a = @selector (numberOfRowsInTableView:);
  SEL sel_b = @selector (tableView:objectValueForTableColumn:row:);
  
  if ([anObject respondsToSelector: sel_a] == NO) 
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"Data Source doesn't respond to numberOfRowsInTableView:"];
    }
  
  if ([anObject respondsToSelector: sel_b] == NO) 
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Data Source doesn't respond to "
		   @"tableView:objectValueForTableColumn:row:"];
    }
  
  ASSIGN (_dataSource, anObject);
  [self tile];
  [self reloadData];
}

/* 
 * Loading data 
 */

- (void) reloadData
{
  [self noteNumberOfRowsChanged];
  [self setNeedsDisplay: YES];
}

/* 
 * Target-action 
 */

- (void) setDoubleAction: (SEL)aSelector
{
  // TODO - implement this in mouseDown:
  _doubleAction = aSelector;
}

- (SEL) doubleAction
{
  return _doubleAction;
}

- (int) clickedColumn
{
  // TODO
  return -1;
}

- (int) clickedRow
{
  // TODO
  return -1;
}

/*
 *Configuration 
 */ 

- (void) setAllowsColumnReordering: (BOOL)flag
{
  // TODO
}

- (BOOL) allowsColumnReordering
{
  // TODO
  return NO;
}

- (void) setAllowsColumnResizing: (BOOL)flag
{
  // TODO
}

- (BOOL) allowsColumnResizing
{
  // TODO
  return NO;
}

- (void) setAllowsMultipleSelection: (BOOL)flag
{
  // TODO
}

- (BOOL) allowsMultipleSelection
{
  // TODO
  return NO;
}

- (void) setAllowsEmptySelection: (BOOL)flag
{
  // TODO
}

- (BOOL) allowsEmptySelection
{
  // TODO
  return YES;
}

- (void) setAllowsColumnSelection: (BOOL)flag
{
  // TODO
}

- (BOOL) allowsColumnSelection
{
  // TODO
  return NO;
}

/* 
 * Drawing Attributes 
 */

- (void) setIntercellSpacing: (NSSize)aSize
{
  _intercellSpacing = aSize;
  [self setNeedsDisplay: YES];
}

- (NSSize) intercellSpacing
{
  return _intercellSpacing;
}

- (void) setRowHeight: (float)rowHeight
{
  _rowHeight = rowHeight;
  [self tile];
}

- (float) rowHeight
{
  return _rowHeight;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
  ASSIGN (_backgroundColor, aColor);
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

/*
 * Selecting Columns and Rows
 */
- (void) selectColumn: (int) columnIndex 
 byExtendingSelection: (BOOL) flag
{
  // TODO
  return;
}

- (void) selectRow: (int) rowIndex 
byExtendingSelection: (BOOL) flag
{
  // TODO
  return;
}

- (void) deselectColumn: (int) columnIndex
{
  // TODO
  return;
}

- (void) deselectRow: (int) rowIndex
{
  // TODO
  return;
}

- (int) numberOfSelectedColumns
{
  // TODO
  return 0;
}

- (int) numberOfSelectedRows
{
  // TODO
  return 0;
}

- (int) selectedColumn
{
  // TODO 
  return -1;
}

- (int) selectedRow
{
  // TODO 
  return -1;
}

- (BOOL) isColumnSelected: (int) columnIndex
{
  // TODO
  return NO;
}

- (BOOL) isRowSelected: (int) rowIndex
{
  // TODO
  return NO;
}

- (NSEnumerator *) selectedColumnEnumerator
{
  // TODO
  return nil;
}

- (NSEnumerator *) selectedRowEnumerator
{
  // TODO
  return nil;
}

- (void) selectAll: (id) sender
{
  // TODO 
  return;
}

- (void) deselectAll: (id) sender
{
  // TODO
  return;
}

/* 
 * Grid Drawing attributes 
 */

- (void) setDrawsGrid: (BOOL)flag
{
  _drawsGrid = flag;
}

- (BOOL) drawsGrid
{
  return _drawsGrid;
}

- (void) setGridColor: (NSColor *)aColor
{
  ASSIGN (_gridColor, aColor);
}

- (NSColor *) gridColor
{
  return _gridColor;
}

/* 
 * Editing Cells 
 */

- (void) editColumn: (int) columnIndex 
		row: (int) rowIndex 
	  withEvent: (NSEvent *) theEvent 
	     select: (BOOL) flag
{
  // TODO
  return;
}

- (int) editedRow
{
  // TODO
  return -1;
}

- (int) editedColumn
{
  // TODO
  return -1;
}

/* 
 * Auxiliary Components 
 */

- (void) setHeaderView: (NSTableHeaderView*)aHeaderView
{
  if (_super_view != nil)
    {
      /* Changing the headerView after the table has been linked to a
	 scrollview is not yet supported - the doc is not clear
	 whether it should be supported at all.  If it is, perhaps
	 it's going to be done through a private method between the
	 tableview and the scrollview. */
      NSLog (@"setHeaderView: called after NSTableView has been put "
	     @"in the view tree!"); 
    }
  [_headerView setTableView: nil];
  ASSIGN (_headerView, aHeaderView);
  [_headerView setTableView: self];
  [self tile];
}

- (NSTableHeaderView*) headerView
{
  return _headerView;
}

- (void) setCornerView: (NSView*)aView
{
  ASSIGN (_cornerView, aView);
  [self tile];
}

- (NSView*) cornerView
{
  return _cornerView;
}

/* 
 * Layout 
 */

- (NSRect) rectOfColumn: (int)columnIndex
{
  NSRect rect;

  if (columnIndex < 0)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"ColumnIndex < 0 in [NSTableView -rectOfColumn:]"];
    }
  if (columnIndex >= _numberOfColumns)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"ColumnIndex => _numberOfColumns in [NSTableView -rectOfColumn:]"];
    }

  rect.origin.x = _columnOrigins[columnIndex];
  rect.origin.y = _bounds.origin.y;
  rect.size.width = [[_tableColumns objectAtIndex: columnIndex] width];
  rect.size.height = _bounds.size.height;
  return rect;
}

- (NSRect) rectOfRow: (int)rowIndex
{
  NSRect rect;

  if (rowIndex < 0)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"RowIndex < 0 in [NSTableView -rectOfRow:]"];
    }
  if (rowIndex >= _numberOfRows)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"RowIndex => _numberOfRows in [NSTableView -rectOfRow:]"];
    }
  rect.origin.x = _bounds.origin.x;
  rect.origin.y = _bounds.origin.y + (_rowHeight * rowIndex);
  rect.size.width = _bounds.size.width;
  rect.size.height = _rowHeight;
  return rect;
}

- (NSRange) columnsInRect: (NSRect)aRect
{
  NSRange range;

  range.location = [self columnAtPoint: aRect.origin];
  range.length = [self columnAtPoint: 
			 NSMakePoint (NSMaxX (aRect), _bounds.origin.y)];
  range.length -= range.location;
  range.length += 1;
  return range;
}

- (NSRange) rowsInRect: (NSRect)aRect
{
  NSRange range;

  range.location = [self rowAtPoint: aRect.origin];
  range.length = [self rowAtPoint: 
			 NSMakePoint (_bounds.origin.x, NSMaxY (aRect))];
  range.length -= range.location;
  range.length += 1;
  return range;
}

- (int) columnAtPoint: (NSPoint)aPoint
{
  if ((NSMouseInRect (aPoint, _bounds, YES)) == NO)
    return -1;
  else
    {
      int i = 0;
      
      while ((aPoint.x > _columnOrigins[i]) && (i < _numberOfColumns))
	{
	  i++;
	}
      return i - 1;
    }
}

- (int) rowAtPoint: (NSPoint)aPoint
{
  /* NB: Y coordinate system is flipped in NSTableView */
  if ((NSMouseInRect (aPoint, _bounds, YES)) == NO)
    return -1;
  else
    {
      int return_value;

      aPoint.y -= _bounds.origin.y;
      return_value = (int) (aPoint.y / _rowHeight);
      /* This could happen if point lies on the grid line below the last row */
      if (return_value == _numberOfRows)
	{
	  return_value--;
	}
      return return_value;
    }
}

- (NSRect) frameOfCellAtColumn: (int)columnIndex 
			   row: (int)rowIndex
{
  NSRect frameRect;

  if ((columnIndex < 0) 
      || (rowIndex < 0)
      || (columnIndex > (_numberOfColumns - 1))
      || (rowIndex > (_numberOfRows - 1)))
    return NSZeroRect;
      
  frameRect.origin.y  = _bounds.origin.y + (rowIndex * _rowHeight);
  frameRect.origin.y += _intercellSpacing.height / 2;
  frameRect.size.height = _rowHeight - _intercellSpacing.height;

  frameRect.origin.x = _columnOrigins[columnIndex];
  frameRect.origin.x  += _intercellSpacing.width / 2;
  frameRect.size.width = [[_tableColumns objectAtIndex: columnIndex] width];
  frameRect.size.width -= _intercellSpacing.width;

  // We add some space to separate the cell from the grid
  if (_drawsGrid)
    {
      frameRect.size.width -= 4;
      frameRect.origin.x += 2;
    }

  // Safety check
  if (frameRect.size.width < 0)
    frameRect.size.width = 0;
  
  return frameRect;
}

- (void) setAutoresizesAllColumnsToFit: (BOOL)flag
{
  // TODO
  return;
}

- (BOOL) autoresizesAllColumnsToFit
{
  // TODO
  return NO;
}

- (void) sizeLastColumnToFit
{
  if ((_super_view != nil) && (_numberOfColumns > 0))
    {
      float excess_width;
      float last_column_width;
      NSTableColumn *lastColumn;

      excess_width = NSMaxX ([self convertRect: [_super_view bounds] 
				      fromView: _super_view]);
      excess_width -= NSMaxX (_bounds);
      if (excess_width <= 0)
	return;
      lastColumn = [_tableColumns objectAtIndex: (_numberOfColumns - 1)];
      last_column_width = [lastColumn width];
      last_column_width += excess_width;
      [lastColumn setWidth: last_column_width];
      [self tile];
    }
}

- (void) sizeToFit
{
  NSCell *cell;
  NSEnumerator	*enumerator;
  NSTableColumn	*tb;
  float table_width;
  float width;
  float candidate_width;
  int row;

  _tilingDisabled = YES;
  
  /* First Step */
  /* Resize Each Column to its Minimum Width */
  table_width = _bounds.origin.x;
  enumerator = [_tableColumns objectEnumerator];
  while ((tb = [enumerator nextObject]) != nil)
    {
      // Compute min width of column 
      width = [[tb headerCell] cellSize].width;
      cell = [tb dataCell];
      for (row = 0; row < _numberOfRows; row++)
	{
	  [cell setObjectValue: [_dataSource tableView: self
					     objectValueForTableColumn: tb
					     row: row]]; 
	  if (_del_responds)
	    {
	      [_delegate tableView: self   willDisplayCell: cell 
			 forTableColumn: tb   row: row];
	    }
	  candidate_width = [cell cellSize].width;

	  if (_drawsGrid)
	    candidate_width += 4;

	  if (candidate_width > width)
	    {
	      width = candidate_width;
	    }
	}
      width += _intercellSpacing.width;
      [tb setWidth: width];
      /* It is necessary to ask the column for the width, since it might have 
	 been changed by the column to constrain it to a min or max width */
      table_width += [tb width];
    }

  /* Second Step */
  /* If superview (clipview) is bigger than that, divide remaining space 
     between all columns */
  if ((_super_view != nil) && (_numberOfColumns > 0))
    {
      float excess_width;

      excess_width = NSMaxX ([self convertRect: [_super_view bounds] 
				      fromView: _super_view]);
      excess_width -= table_width;
      if (excess_width <= 0)
	{
	  _tilingDisabled = NO;
	  [self tile];
	  return;
	}
      excess_width = excess_width / _numberOfColumns;

      enumerator = [_tableColumns objectEnumerator];
      while ((tb = [enumerator nextObject]) != nil)
	{
	  [tb setWidth: ([tb width] + excess_width)];
	}
    }

  _tilingDisabled = NO;
  [self tile];
}

- (void) noteNumberOfRowsChanged
{
  NSRect superviewBounds; // Get this *after* [self setFrame:]
  
  _numberOfRows = [_dataSource numberOfRowsInTableView: self];
  [self setFrame: NSMakeRect (_frame.origin.x, 
			      _frame.origin.y,
			      _frame.size.width, 
			      (_numberOfRows * _rowHeight) + 1)];
  
  /* If we are shorter in height than the enclosing clipview, we
     should redraw us now. */
  superviewBounds = [_super_view bounds];
  if ((superviewBounds.origin.x <= _frame.origin.x) 
      && (NSMaxY (superviewBounds) >= NSMaxY (_frame)))
    {
      [self setNeedsDisplay: YES];
    }
}

- (void) tile
{
  float table_width = 0;
  float table_height;

  if (_tilingDisabled == YES)
    return;

  if (_numberOfColumns > 0)
    {
      int i;
      float width;
  
      _columnOrigins[0] = _bounds.origin.x;
      width = [[_tableColumns objectAtIndex: 0] width];
      table_width += width;
      for (i = 1; i < _numberOfColumns; i++)
	{
	  _columnOrigins[i] = _columnOrigins[i - 1] + width;
	  width = [[_tableColumns objectAtIndex: i] width];
	  table_width += width;
	}
    }
  /* + 1 for the last grid line */
  table_height = (_numberOfRows * _rowHeight) + 1;
  [self setFrameSize: NSMakeSize (table_width, table_height)];
  [self setNeedsDisplay: YES];

  if (_headerView != nil)
    {
      [_headerView setFrameSize: 
		     NSMakeSize (_frame.size.width,
				 [_headerView frame].size.height)];
      [_cornerView setFrameSize: 
		     NSMakeSize ([NSScroller scrollerWidth] + 1,
				 [_headerView frame].size.height)];
      [_headerView setNeedsDisplay: YES];
      [_cornerView setNeedsDisplay: YES];
    }  
}

/* 
 * Drawing 
 */

- (void)drawRow: (int)rowIndex clipRect: (NSRect)aRect
{
  int startingColumn; 
  int endingColumn;
  NSTableColumn *tb;
  NSRect drawingRect;
  NSCell *cell;
  int i;
  float x_pos;

  if (_dataSource == nil)
    return;

  /* Using columnAtPoint: here would make it called twice per row per drawn 
     rect - so we avoid it and do it natively */

  /* Determine starting column as fast as possible */
  x_pos = NSMinX (aRect);
  i = 0;
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  startingColumn = (i - 1);

  if (startingColumn == -1)
    startingColumn = 0;

  /* Determine ending column as fast as possible */
  x_pos = NSMaxX (aRect);
  // Nota Bene: we do *not* reset i
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;

  /* Draw the row between startingColumn and endingColumn */
  for (i = startingColumn; i <= endingColumn; i++)
    {
      tb = [_tableColumns objectAtIndex: i];
      cell = [tb dataCell];
      if (_del_responds)
	{
	  [_delegate tableView: self   willDisplayCell: cell 
		     forTableColumn: tb   row: rowIndex];
	}
      [cell setObjectValue: [_dataSource tableView: self
					 objectValueForTableColumn: tb
					 row: rowIndex]]; 
      drawingRect = [self frameOfCellAtColumn: i
			  row: rowIndex];
      [cell drawWithFrame: drawingRect inView: self];
    }
}

- (void) drawGridInClipRect: (NSRect)aRect
{
  float minX = NSMinX (aRect);
  float maxX = NSMaxX (aRect);
  float minY = NSMinY (aRect);
  float maxY = NSMaxY (aRect);
  /* Using columnAtPoint:, rowAtPoint: here calls them only twice 
     per drawn rect */
  int startingRow    = [self rowAtPoint: 
			       NSMakePoint (_bounds.origin.x, minY)];
  int endingRow      = [self rowAtPoint: 
			       NSMakePoint (_bounds.origin.x, maxY)];
  int startingColumn = [self columnAtPoint: 
			       NSMakePoint (minX, _bounds.origin.y)];
  int endingColumn   = [self columnAtPoint: 
			       NSMakePoint (maxX, _bounds.origin.y)];
  int i;
  NSGraphicsContext *ctxt = GSCurrentContext ();
  float position;

  DPSgsave (ctxt);
  DPSsetlinewidth (ctxt, 1);
  [_gridColor set];

  if (_numberOfRows > 0)
    {
      /* Draw horizontal lines */
      if (startingRow == -1)
	startingRow = 0;
      if (endingRow == -1)
	endingRow = _numberOfRows - 1;
      
      position = _bounds.origin.y;
      position += startingRow * _rowHeight;
      for (i = startingRow; i <= endingRow + 1; i++)
	{
	  DPSmoveto (ctxt, minX, position);
	  DPSlineto (ctxt, maxX, position);
	  DPSstroke (ctxt);
	  position += _rowHeight;
	}
    }
  
  if (_numberOfColumns > 0)
    {
      /* Draw vertical lines */
      if (startingColumn == -1)
	startingColumn = 0;
      if (endingColumn == -1)
	endingColumn = _numberOfColumns - 1;

      for (i = startingColumn; i <= endingColumn; i++)
	{
	  DPSmoveto (ctxt, _columnOrigins[i], minY);
	  DPSlineto (ctxt, _columnOrigins[i], maxY);
	  DPSstroke (ctxt);
	}
      position =  _columnOrigins[endingColumn];
      position += [[_tableColumns objectAtIndex: endingColumn] width];  
      /* Last vertical line must moved a pixel to the left */
      if (endingColumn == (_numberOfColumns - 1))
	position -= 1;
      DPSmoveto (ctxt, position, minY);
      DPSlineto (ctxt, position, maxY);
      DPSstroke (ctxt);
    }

  DPSgrestore (ctxt);
}

- (void) highlightSelectionInClipRect: (NSRect)clipRect
{
  // TODO
  return;
}

- (void) drawRect: (NSRect)aRect
{
  int startingRow;
  int endingRow;
  int i;

  /* Draw background */
  [_backgroundColor set];
  NSRectFill (_bounds);

  if ((_numberOfRows == 0) || (_numberOfColumns == 0))
    return;
  
  /* Draw grid */
  if (_drawsGrid)
    {
      [self drawGridInClipRect: aRect];
    }
  
  /* Draw visible cells */
  /* Using rowAtPoint: here calls them only twice per drawn rect */
  startingRow = [self rowAtPoint: NSMakePoint (0, NSMinY (aRect))];
  endingRow   = [self rowAtPoint: NSMakePoint (0, NSMaxY (aRect))];

  if (startingRow == -1)
    startingRow = 0;
  if (endingRow == -1)
    endingRow = _numberOfRows - 1;

  for (i = startingRow; i <= endingRow; i++)
    {
      [self drawRow: i  clipRect: aRect];
    }
}

/* 
 * Scrolling 
 */

- (void) scrollRowToVisible: (int)rowIndex
{
  if (_super_view != nil)
    {
      NSRect rowRect = [self rectOfRow: rowIndex];
      NSRect visibleRect = [self convertRect: [_super_view bounds]
				 toView: self];

      // If the row is over the top, or it is partially visible 
      // on top,
      if ((rowRect.origin.y < visibleRect.origin.y))	
	{
	  // Then make it visible on top
	  NSPoint newOrigin;  
	  
	  newOrigin.x = visibleRect.origin.x;
	  newOrigin.y = rowRect.origin.y;
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
      // If the row is under the bottom, or it is partially visible on
      // the bottom,
      if (NSMaxY (rowRect) > NSMaxY (visibleRect))
	{
	  // Then make it visible on bottom
	  NSPoint newOrigin;  
	  
	  newOrigin.x = visibleRect.origin.x;
	  newOrigin.y = visibleRect.origin.y;
	  newOrigin.y += NSMaxY (rowRect) - NSMaxY (visibleRect);
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
    }
}

- (void) scrollColumnToVisible: (int)columnIndex
{
  if (_super_view != nil)
    {
      NSRect columnRect = [self rectOfColumn: columnIndex];
      NSRect visibleRect = [self convertRect: [_super_view bounds]
				 toView: self];
      float diff;

      // If the row is out on the left, or it is partially visible 
      // on the left
      if ((columnRect.origin.x < visibleRect.origin.x))	
	{
	  // Then make it visible on the left
	  NSPoint newOrigin;  
	  
	  newOrigin.x = columnRect.origin.x;
	  newOrigin.y = visibleRect.origin.y;
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
      diff = NSMaxX (columnRect) - NSMaxX (visibleRect);
      // If the row is out on the right, or it is partially visible on
      // the right,
      if (diff > 0)
	{
	  // Then make it visible on the right
	  NSPoint newOrigin;

	  newOrigin.x = visibleRect.origin.x;
	  newOrigin.y = visibleRect.origin.y;
	  newOrigin.x += diff;
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
    }
}


/* 
 * Text delegate methods 
 */

- (BOOL) textShouldBeginEditing: (NSText *)textObject
{
  // TODO
  return NO;
}

- (void) textDidBeginEditing: (NSNotification *)aNotification
{
  // TODO
}

- (void) textDidChange: (NSNotification *)aNotification
{
  // TODO
}

- (BOOL) textShouldEndEditing: (NSText *)textObject
{
  // TODO
  return YES;
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  // TODO
  return;
}


/* 
 * Persistence 
 */

- (NSString *) autosaveName
{
  // TODO
  return nil;
}

- (BOOL) autosaveTableColumns
{
  // TODO
  return NO;
}

- (void) setAutosaveName: (NSString *)name
{
  // TODO
}

- (void) setAutosaveTableColumns: (BOOL)flag
{
  // TODO
}

/* 
 * Delegate 
 */

- (void) setDelegate: (id)anObject
{
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  SEL sel;

  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = anObject;
  
#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(tableView##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(tableView##notif_name:) \
      name: NSTableView##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(ColumnDidMove);
  SET_DELEGATE_NOTIFICATION(ColumnDidResize);
  SET_DELEGATE_NOTIFICATION(SelectionDidChange);
  SET_DELEGATE_NOTIFICATION(SelectionIsChanging);
  
  /* Cache */
  sel = @selector(tableView:willDisplayCell:forTableColumn:row:);
  _del_responds = [_delegate respondsToSelector: sel];     
}

- (id) delegate
{
  return _delegate;
}

/*
 * Encoding/Decoding
 */

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  // TODO
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  return [super initWithCoder: aDecoder];
  // TODO
}

@end /* implementation of NSTableView */
