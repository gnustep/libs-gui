/*
   NSMatrix.m

   Matrix class for grouping controls

   Copyright (C) 1996, 1997, 1999 Free Software Foundation, Inc.

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   A completely rewritten version of the original source by Pascal Forget and
   Scott Christley.
   Modified:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Cell handling rewritten: <richard@brainstorm.co.uk>
   Date: November 1999
   Implementation of Editing: Nicola Pero <n.pero@mi.flashnet.it>
   Date: November 1999

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

#include <gnustep/gui/config.h>
#include <stdlib.h>

#include <Foundation/NSValue.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSZone.h>

#include <AppKit/NSColor.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSActionCell.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>


#define	STRICT	0

#ifdef MIN
# undef MIN
#endif
#define MIN(A,B)  ({ typeof(A) __a = (A); \
		  typeof(B) __b = (B); \
		  __a < __b ? __a : __b; })

#ifdef MAX
# undef MAX
#endif
#define MAX(A,B)  ({ typeof(A) __a = (A); \
		  typeof(B) __b = (B); \
		  __a < __b ? __b : __a; })

#ifdef ABS
# undef ABS
#endif
#define ABS(A)	({ typeof(A) __a = (A); __a < 0 ? -__a : __a; })


#define SIGN(x) \
    ({typeof(x) _SIGN_x = (x); \
      _SIGN_x > 0 ? 1 : (_SIGN_x == 0 ? 0 : -1); })

#define POINT_FROM_INDEX(index) \
    ({MPoint point = { index % numCols, index / numCols }; point; })

#define INDEX_FROM_COORDS(x,y) \
    (y * numCols + x)
#define INDEX_FROM_POINT(point) \
    (point.y * numCols + point.x)


/* Some stuff needed to compute the selection in the list mode. */
typedef struct {
  int x;
  int y;
} MPoint;

typedef struct {
  int x;
  int y;
  int width;
  int height;
} MRect;

static inline MPoint MakePoint (int x, int y)
{
  MPoint point = { x, y };
  return point;
}

@interface NSMatrix (PrivateMethods)
- (void) _renewRows: (int)row
	    columns: (int)col
	   rowSpace: (int)rowSpace
	   colSpace: (int)colSpace;
- (void) _setState: (int)state
	 highlight: (BOOL)highlight
	startIndex: (int)start
	  endIndex: (int)end;
-(BOOL) _selectNextSelectableCellAfterRow: (int)row
				   column: (int)column;
-(BOOL) _selectPreviousSelectableCellBeforeRow: (int)row
					column: (int)column;
@end

enum {
  DEFAULT_CELL_HEIGHT = 17,
  DEFAULT_CELL_WIDTH = 100
};

@implementation NSMatrix

/* Class variables */
static Class defaultCellClass = nil;
static int mouseDownFlags = 0;
static SEL copySel = @selector(copyWithZone:);
static SEL initSel = @selector(init);
static SEL allocSel = @selector(allocWithZone:);
static SEL getSel = @selector(objectAtIndex:);

+ (void) initialize
{
  if (self == [NSMatrix class])
    {
      /* Set the initial version */
      [self setVersion: 1];

      /*
       * MacOS-X docs say default cell class is NSActionCell
       */
      defaultCellClass = [NSActionCell class];
    }
}

+ (Class) cellClass
{
  return defaultCellClass;
}

+ (void) setCellClass: (Class)classId
{
  defaultCellClass = classId;
  if (defaultCellClass == nil)
    defaultCellClass = [NSActionCell class];
}

- (id) init
{
  return [self initWithFrame: NSZeroRect
		        mode: NSRadioModeMatrix
		   cellClass: [isa cellClass]
		numberOfRows: 0
	     numberOfColumns: 0];
}

- (id) initWithFrame: (NSRect)frameRect
{
  return [self initWithFrame: frameRect
		        mode: NSRadioModeMatrix
		   cellClass: [isa cellClass]
		numberOfRows: 0
	     numberOfColumns: 0];
}

- (id) _privateFrame: (NSRect)frameRect
	        mode: (int)aMode
        numberOfRows: (int)rows
     numberOfColumns: (int)cols
{
  myZone = [self zone];
  [self _renewRows: rows columns: cols rowSpace: 0 colSpace: 0];
  mode = aMode;
  [self setFrame: frameRect];

  if ((numCols > 0) && (numRows > 0))
    cellSize = NSMakeSize (frameRect.size.width/numCols,
			   frameRect.size.height/numRows);
  else
    cellSize = NSMakeSize (DEFAULT_CELL_WIDTH, DEFAULT_CELL_HEIGHT);

  intercell = NSMakeSize(1, 1);
  _tabKeyTraversesCells = YES;
  [self setBackgroundColor: [NSColor controlBackgroundColor]];
  [self setDrawsBackground: YES];
  [self setCellBackgroundColor: [NSColor controlBackgroundColor]];
  [self setSelectionByRect: YES];
  [self setAutosizesCells: YES];
  if (mode == NSRadioModeMatrix && numRows && numCols)
    {
      [self selectCellAtRow: 0 column: 0];
    }
  else
    {
      _selectedRow = _selectedColumn = 0;
    }
  return self;
}

- (id) initWithFrame: (NSRect)frameRect
	        mode: (int)aMode
	   cellClass: (Class)class
        numberOfRows: (int)rowsHigh
     numberOfColumns: (int)colsWide
{
  self = [super initWithFrame: frameRect];

  [self setCellClass: class];
  return [self _privateFrame: frameRect
		        mode: aMode
		numberOfRows: rowsHigh
	     numberOfColumns: colsWide];
}

- (id) initWithFrame: (NSRect)frameRect
	        mode: (int)aMode
	   prototype: (NSCell*)prototype
        numberOfRows: (int)rowsHigh
     numberOfColumns: (int)colsWide
{
  self = [super initWithFrame: frameRect];

  [self setPrototype: prototype];
  return [self _privateFrame: frameRect
		        mode: aMode
		numberOfRows: rowsHigh
	     numberOfColumns: colsWide];
}

- (void) dealloc
{
  int		i;

  for (i = 0; i < maxRows; i++)
    {
      int	j;

      for (j = 0; j < maxCols; j++)
	{
	  [cells[i][j] release];
	}
      NSZoneFree(myZone, cells[i]);
      NSZoneFree(GSAtomicMallocZone(), selectedCells[i]);
    }
  NSZoneFree(myZone, cells);
  NSZoneFree(myZone, selectedCells);

  [cellPrototype release];
  [backgroundColor release];
  [cellBackgroundColor release];
  [super dealloc];
}

- (void) addColumn
{
  [self insertColumn: numCols withCells: nil];
}

- (void) addColumnWithCells: (NSArray*)cellArray
{
  [self insertColumn: numCols withCells: cellArray];
}

- (void) addRow
{
  [self insertRow: numRows withCells: nil];
}

- (void) addRowWithCells: (NSArray*)cellArray
{
  [self insertRow: numRows withCells: cellArray];
}

- (void) insertColumn: (int)column
{
  [self insertColumn: column withCells: nil];
}

- (void) insertColumn: (int)column withCells: (NSArray*)cellArray
{
  int	count = [cellArray count];
  int	i = numCols + 1;

  if (column < 0)
    {
      column = 0;
#if	STRICT == 0
      NSLog(@"insert negative column (%d) in matrix", column);
#else
      [NSException raise: NSRangeException
		  format: @"insert negative column (%d) in matrix", column];
#endif
    }

  if (column >= i)
    {
      i = column + 1;
    }

  /*
   * Use _renewRows:columns:rowSpace:colSpace: to grow the matrix as necessary.
   * MacOS-X docs say that if the matrix is empty, we make it have one column
   * and enough rows for all the elements.
   */
  if (count > 0 && (numRows == 0 || numCols == 0))
    {
      [self _renewRows: count columns: 1 rowSpace: 0 colSpace: count];
    }
  else
    {
      [self _renewRows: numRows ? numRows : 1
	       columns: i
	      rowSpace: 0
	      colSpace: count];
    }

  /*
   * Rotate the new column to the insertion point if necessary.
   */
  if (numCols != column)
    {
      for (i = 0; i < numRows; i++)
	{
	  int	j = numCols;
	  id	old = cells[i][j-1];

	  while (--j > column)
	    {
	      cells[i][j] = cells[i][j-1];
	      selectedCells[i][j] = selectedCells[i][j-1];
	    }
	  cells[i][column] = old;
	  selectedCells[i][column] = NO;
	}
    }

  /*
   * Now put the new cells from the array into the matrix.
   */
  if (count > 0)
    {
      IMP	getImp = [cellArray methodForSelector: getSel];

      for (i = 0; i < numRows && i < count; i++)
	{
	  ASSIGN(cells[i][column], (*getImp)(cellArray, getSel, i));
	}
    }

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && _selectedCell == nil)
    [self selectCellAtRow: 0 column: 0];
}

- (void) insertRow: (int)row
{
  [self insertRow: row withCells: nil];
}

- (void) insertRow: (int)row withCells: (NSArray*)cellArray
{
  int	count = [cellArray count];
  int	i = numRows + 1;

  if (row < 0)
    {
      row = 0;
#if	STRICT == 0
      NSLog(@"insert negative row (%d) in matrix", row);
#else
      [NSException raise: NSRangeException
		  format: @"insert negative row (%d) in matrix", row];
#endif
    }

  if (row >= i)
    {
      i = row + 1;
    }

  /*
   * Grow the matrix to have the new row.
   * MacOS-X docs say that if the matrix is empty, we make it have one
   * row and enough columns for all the elements.
   */
  if (count > 0 && (numRows == 0 || numCols == 0))
    {
      [self _renewRows: 1 columns: count rowSpace: count colSpace: 0];
    }
  else
    {
      [self _renewRows: i
	       columns: numCols ? numCols : 1
	      rowSpace: count
	      colSpace: 0];
    }

  /*
   * Rotate the newly created row to the insertion point if necessary.
   */
  if (numRows != row)
    {
      id	*oldr = cells[numRows - 1];
      BOOL	*olds = selectedCells[numRows - 1];

      for (i = numRows - 1; i > row; i--)
	{
	  cells[i] = cells[i-1];
	  selectedCells[i] = selectedCells[i-1];
	}
      cells[row] = oldr;
      selectedCells[row] = olds;
    }

  /*
   * Put cells from the array into the matrix.
   */
  if (count > 0)
    {
      IMP	getImp = [cellArray methodForSelector: getSel];

      for (i = 0; i < numCols && i < count; i++)
	{
	  ASSIGN(cells[row][i], (*getImp)(cellArray, getSel, i));
	}
    }

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && _selectedCell == nil)
    [self selectCellAtRow: 0 column: 0];
}

- (NSCell*) makeCellAtRow: (int)row
		   column: (int)column
{
  NSCell	*aCell;

  if (cellPrototype != nil)
    {
      aCell = (*cellNew)(cellPrototype, copySel, myZone);
    }
  else
    {
      aCell = (*cellNew)(cellClass, allocSel, myZone);
      if (aCell != nil)
	{
	  aCell = (*cellInit)(aCell, initSel);
	}
    }
  /*
   * This is only ever called when we are creating a new cell - so we know
   * we can simply assign a value into the matrix without releasing an old
   * value.  If someone uses this method directly (which the documentation
   * specifically says they shouldn't) they may produce a memory leak.
   */
  cells[row][column] = aCell;
  return aCell;
}

- (NSRect) cellFrameAtRow: (int)row
		   column: (int)column
{
  NSRect rect;

  rect.origin.x = column * (cellSize.width + intercell.width);
  if (_rFlags.flipped_view)
    rect.origin.y = row * (cellSize.height + intercell.height);
  else
    rect.origin.y = (numRows - row - 1) * (cellSize.height + intercell.height);
  rect.size = cellSize;
  return rect;
}

- (void) getNumberOfRows: (int*)rowCount
		 columns: (int*)columnCount
{
  *rowCount = numRows;
  *columnCount = numCols;
}

- (void) putCell: (NSCell*)newCell
	   atRow: (int)row
	  column: (int)column
{
  if (row < 0 || row >= numRows || column < 0 || column >= numCols)
    {
      [NSException raise: NSRangeException
		  format: @"attempt to put cell outside matrix bounds"];
    }
  ASSIGN(cells[row][column], newCell);
  [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
}

- (void) removeColumn: (int)col
{
  if (col >= 0 && col < numCols)
    {
      int i;

      for (i = 0; i < maxRows; i++)
	{
	  int	j;

	  AUTORELEASE(cells[i][col]);
	  for (j = col + 1; j < maxCols; j++)
	    {
	      cells[i][j-1] = cells[i][j];
	      selectedCells[i][j-1] = selectedCells[i][j];
	    }
	}
      numCols--;
      maxCols--;

      if (col == _selectedColumn)
	{
	  _selectedCell = nil;
	  [self selectCellAtRow: 0 column: 0];
	}
    }
  else
    {
#if	STRICT == 0
      NSLog(@"remove non-existent column (%d) from matrix", col);
#else
      [NSException raise: NSRangeException
		  format: @"remove non-existent column (%d) from matrix", col];
#endif
    }
}

- (void) removeRow: (int)row
{
  if (row >= 0 && row < numRows)
    {
      int	i;

#if	GS_WITH_GC == 0
      for (i = 0; i < maxCols; i++)
	{
	  [cells[row][i] autorelease];
	}
#endif
      NSZoneFree(myZone, cells[row]);
      NSZoneFree(GSAtomicMallocZone(), selectedCells[row]);
      for (i = row + 1; i < maxRows; i++)
	{
	  cells[i-1] = cells[i];
	  selectedCells[i-1] = selectedCells[i];
	}
      maxRows--;
      numRows--;

      if (row == _selectedRow)
	{
	  _selectedCell = nil;
	  [self selectCellAtRow: 0 column: 0];
	}
    }
  else
    {
#if	STRICT == 0
      NSLog(@"remove non-existent row (%d) from matrix", row);
#else
      [NSException raise: NSRangeException
		  format: @"remove non-existent row (%d) from matrix", row];
#endif
    }
}

- (void) renewRows: (int)r
	   columns: (int)c
{
  [self _renewRows: r columns: c rowSpace: 0 colSpace: 0];
}

- (void) setCellSize: (NSSize)size
{
  cellSize = size;
  [self sizeToCells];
}

- (void) setIntercellSpacing: (NSSize)size
{
  intercell = size;
  [self sizeToCells];
}

- (void) sortUsingFunction: (int (*)(id element1, id element2,
				   void *userData))comparator
		   context: (void*)context
{
  NSMutableArray	*sorted;
  IMP			add;
  IMP			get;
  int			i, j, index = 0;

  sorted = [NSMutableArray arrayWithCapacity: numRows * numCols];
  add = [sorted methodForSelector: @selector(addObject:)];
  get = [sorted methodForSelector: @selector(objectAtIndex:)];

  for (i = 0; i < numRows; i++)
    {
      for (j = 0; j < numCols; j++)
	{
	  (*add)(sorted, @selector(addObject:), cells[i][j]);
	}
    }

  [sorted sortUsingFunction: comparator context: context];

  for (i = 0; i < numRows; i++)
    {
      for (j = 0; j < numCols; j++)
	{
	  cells[i][j] = (*get)(sorted, @selector(objectAtIndex:), index++);
	}
    }
}

- (void) sortUsingSelector: (SEL)comparator
{
  NSMutableArray	*sorted;
  IMP			add;
  IMP			get;
  int			i, j, index = 0;

  sorted = [NSMutableArray arrayWithCapacity: numRows * numCols];
  add = [sorted methodForSelector: @selector(addObject:)];
  get = [sorted methodForSelector: @selector(objectAtIndex:)];

  for (i = 0; i < numRows; i++)
    {
      for (j = 0; j < numCols; j++)
	{
	  (*add)(sorted, @selector(addObject:), cells[i][j]);
	}
    }

  [sorted sortUsingSelector: comparator];

  for (i = 0; i < numRows; i++)
    {
      for (j = 0; j < numCols; j++)
	{
	  cells[i][j] = (*get)(sorted, @selector(objectAtIndex:), index++);
	}
    }
}

- (BOOL) getRow: (int*)row
	 column: (int*)column
       forPoint: (NSPoint)point
{
  BOOL	betweenRows;
  BOOL	betweenCols;
  BOOL	beyondRows;
  BOOL	beyondCols;
  int	approxRow = point.y / (cellSize.height + intercell.height);
  float	approxRowsHeight = approxRow * (cellSize.height + intercell.height);
  int	approxCol = point.x / (cellSize.width + intercell.width);
  float	approxColsWidth = approxCol * (cellSize.width + intercell.width);

  /* First check the limit cases */
  beyondCols = (point.x > bounds.size.width || point.x < 0);
  beyondRows = (point.y > bounds.size.height || point.y < 0);

  /* Determine if the point is inside the cell */
  betweenRows = !(point.y > approxRowsHeight
		&& point.y <= approxRowsHeight + cellSize.height);
  betweenCols = !(point.x > approxColsWidth
		  && point.x <= approxColsWidth + cellSize.width);

  if (row)
    {
      if (_rFlags.flipped_view == NO)
	approxRow = numRows - approxRow - 1;

      if (approxRow < 0)
	approxRow = 0;
      else if (approxRow >= numRows)
	approxRow = numRows - 1;
      *row = approxRow;
    }

  if (column)
    {
      if (approxCol < 0)
	approxCol = 0;
      else if (approxCol >= numCols)
	approxCol = numCols - 1;
      *column = approxCol;
    }

  if (beyondRows || betweenRows || beyondCols || betweenCols)
    {
      return NO;
    }
  else
    {
      return YES;
    }
}

- (BOOL) getRow: (int*)row
	 column: (int*)column
	 ofCell: (NSCell*)aCell
{
  int	i;

  for (i = 0; i < numRows; i++)
    {
      int	j;

      for (j = 0; j < numCols; j++)
	{
	  if (cells[i][j] == aCell)
	    {
	      *row = i;
	      *column = j;
	      return YES;
	    }
	}
    }
  return NO;
}

- (void) setState: (int)value
	    atRow: (int)row
	   column: (int)column
{
  NSCell	*aCell = [self cellAtRow: row column: column];

  if (!aCell)
    return;

  if (mode == NSRadioModeMatrix)
    {
      if (value)
	{
	  _selectedCell = aCell;
	  _selectedRow = row;
	  _selectedColumn = column;
	  [_selectedCell setState: 1];
	  selectedCells[row][column] = YES;
	}
      else if (allowsEmptySelection)
	{
	  [self deselectSelectedCell];
	}
    }
  else
    {
      [aCell setState: value];
    }
  [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
}

- (void) deselectAllCells
{
  int		i;

  if (!allowsEmptySelection && mode == NSRadioModeMatrix)
    return;

  for (i = 0; i < numRows; i++)
    {
      int	j;

      for (j = 0; j < numCols; j++)
	{
	  if (selectedCells[i][j])
	    {
	      NSRect	theFrame = [self cellFrameAtRow: i column: j];
	      NSCell	*aCell = cells[i][j];

	      [aCell setState: 0];
	      [aCell highlight: NO withFrame: theFrame inView: self];
	      [self setNeedsDisplayInRect: theFrame];
	      selectedCells[i][j] = NO;
	    }
	}
    }
}

- (void) deselectSelectedCell
{
  if (!_selectedCell || (!allowsEmptySelection && (mode == NSRadioModeMatrix)))
    return;

  selectedCells[_selectedRow][_selectedColumn] = NO;
  [_selectedCell setState: 0];
  _selectedCell = nil;
  _selectedRow = 0;
  _selectedColumn = 0;
}

- (void) selectAll: (id)sender
{
  unsigned	i, j;

  /*
   * Make the selected cell the cell at (0, 0)
   */
  _selectedCell = [self cellAtRow: 0 column: 0];
  _selectedRow = 0;
  _selectedColumn = 0;

  for (i = 0; i < numRows; i++)
    {
      for (j = 0; j < numCols; j++)
	{
	  [cells[i][j] setState: 1];
	  selectedCells[i][j] = YES;
	}
    }

  [self setNeedsDisplay: YES];
}

- (void) selectCellAtRow: (int)row column: (int)column
{
  NSCell	*aCell = [self cellAtRow: row column: column];

  /*
   * We always deselect the current selection unless the new selection
   * is the same.
   */
  if (_selectedCell != nil && _selectedCell != aCell)
    {
      selectedCells[_selectedRow][_selectedColumn] = NO;
      [_selectedCell setState: 0];
      [self setNeedsDisplayInRect: [self cellFrameAtRow: _selectedRow
					 column: _selectedColumn]];
    }

  if (aCell != nil)
    {
      _selectedCell = aCell;
      _selectedRow = row;
      _selectedColumn = column;
      selectedCells[row][column] = YES;
      [_selectedCell setState: 1];

      [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
    }
}

- (BOOL) selectCellWithTag: (int)anInt
{
  id	aCell;
  int	i = numRows;

  while (i-- > 0)
    {
      int	j = numCols;

      while (j-- > 0)
	{
	  aCell = cells[i][j];
	  if ([aCell tag] == anInt)
	    {
	      [self selectCellAtRow: i column: j];
	      return YES;
	    }
	}
    }
  return NO;
}

- (NSArray*) selectedCells
{
  NSMutableArray	*array = [NSMutableArray array];
  int	i;

  for (i = 0; i < numRows; i++)
    {
      int	j;

      for (j = 0; j < numCols; j++)
	{
	  if (selectedCells[i][j] == YES)
	    {
	      [array addObject: cells[i][j]];
	    }
	}
    }
  return array;
}

- (void) setSelectionFrom: (int)startPos
		       to: (int)endPos
		   anchor: (int)anchorPos
	        highlight: (BOOL)flag
{
  MPoint anchor = POINT_FROM_INDEX(anchorPos);
  MPoint last = POINT_FROM_INDEX(startPos);
  MPoint current = POINT_FROM_INDEX(endPos);

  if (selectionByRect)
    {
      unsigned	omaxc = MAX(anchor.x, last.x);
      unsigned	ominc = MIN(anchor.x, last.x);
      unsigned	omaxr = MAX(anchor.y, last.y);
      unsigned	ominr = MIN(anchor.y, last.y);
      unsigned	nmaxc = MAX(anchor.x, current.x);
      unsigned	nminc = MIN(anchor.x, current.x);
      unsigned	nmaxr = MAX(anchor.y, current.y);
      unsigned	nminr = MIN(anchor.y, current.y);
      unsigned	maxr = MAX(omaxr, nmaxr);
      unsigned	minr = MIN(ominr, nminr);
      unsigned	maxc = MAX(omaxc, nmaxc);
      unsigned	minc = MIN(ominc, nminc);
      unsigned	r;

      for (r = minr; r <= maxr; r++)
	{
	  if (r >= ominr && r <= omaxr)
	    {
	      if (r >= nminr && r <= nmaxr)
		{
		  /*
		   * In old rectangle, and in new.
		   */
		  if (ominc != nminc)
		    {
		      MPoint	sp = { minc, r};
		      MPoint	ep = { MAX(ominc, nminc)-1, r};
		      int	state = (ominc < nminc) ? 0 : 1;

		      [self _setState: state
			    highlight: flag ? (BOOL)state : NO
			   startIndex: INDEX_FROM_POINT(sp)
			     endIndex: INDEX_FROM_POINT(ep)];
		    }

		  if (omaxc != nmaxc)
		    {
		      MPoint	sp = { MIN(omaxc, nmaxc)+1, r};
		      MPoint	ep = { maxc, r};
		      int	state = (nmaxc < omaxc) ? 0 : 1;

		      [self _setState: state
			    highlight: flag ? (BOOL)state : NO
			   startIndex: INDEX_FROM_POINT(sp)
			     endIndex: INDEX_FROM_POINT(ep)];
		    }
		}
	      else
		{
		  MPoint	sp = { ominc, r};
		  MPoint	ep = { omaxc, r};

		  /*
		   * In old rectangle, but not new - clear row.
		   */
		  [self _setState: 0
			highlight: NO
		       startIndex: INDEX_FROM_POINT(sp)
			 endIndex: INDEX_FROM_POINT(ep)];
		}
	    }
	  else if (r >= nminr && r <= nmaxr)
	    {
	      MPoint	sp = { nminc, r};
	      MPoint	ep = { nmaxc, r};

	      /*
	       * In new rectangle, but not old - select row.
	       */
	      [self _setState: 1
		    highlight: flag ? YES : NO
		   startIndex: INDEX_FROM_POINT(sp)
		     endIndex: INDEX_FROM_POINT(ep)];
	    }
	}
    }
  else
    {
      BOOL	doSelect = NO;
      BOOL	doUnselect = NO;
      int	selectx;
      int	selecty;
      int	unselectx;
      int	unselecty;
      int	dca = endPos - anchorPos;
      int	dla = startPos - anchorPos;
      int	dca_dla = SIGN(dca) / (SIGN(dla) ? SIGN(dla) : 1);

      if (dca_dla >= 0)
	{
	  if (ABS(dca) >= ABS(dla))
	    {
	      doSelect = YES;
	      selectx = MIN(startPos, endPos);
	      selecty = MAX(startPos, endPos);
	    }
	  else
	    {
	      doUnselect = YES;
	      if (endPos < startPos)
		{
		  unselectx = endPos + 1;
		  unselecty = startPos;
		}
	      else
		{
		  unselectx = startPos;
		  unselecty = endPos - 1;
		}
	    }
	}
      else
	{
	  doSelect = YES;
	  if (anchorPos < endPos)
	    {
	      selectx = anchorPos;
	      selecty = endPos;
	    }
	  else
	    {
	      selectx = endPos;
	      selecty = anchorPos;
	    }

	  doUnselect = YES;
	  if (anchorPos < startPos)
	    {
	      unselectx = anchorPos;
	      unselecty = startPos;
	    }
	  else
	    {
	      unselectx = startPos;
	      unselecty = anchorPos;
	    }
	}

      if (doUnselect)
	[self _setState: 0
	      highlight: NO
	     startIndex: unselectx
	       endIndex: unselecty];
      if (doSelect)
	[self _setState: 1
	      highlight: flag ? YES : NO
	     startIndex: selectx
	       endIndex: selecty];
    }
}

- (id) cellAtRow: (int)row
	  column: (int)column
{
  if (row < 0 || row >= numRows || column < 0 || column >= numCols)
    return nil;
  return cells[row][column];
}

- (id) cellWithTag: (int)anInt
{
  int	i = numRows;

  while (i-- > 0)
    {
      int	j = numCols;

      while (j-- > 0)
	{
	  id	aCell = cells[i][j];

	  if ([aCell tag] == anInt)
	    {
	      return aCell;
	    }
	}
    }
  return nil;
}

- (NSArray*) cells
{
  NSMutableArray	*c;
  IMP			add;
  int			i;

  c = [NSMutableArray arrayWithCapacity: numRows * numCols];
  add = [c methodForSelector: @selector(addObject:)];
  for (i = 0; i < numRows; i++)
    {
      int	j;

      for (j = 0; j < numCols; j++)
	{
	  (*add)(c, @selector(addObject:), cells[i][j]);
	}
    }
  return c;
}

- (void) selectText: (id)sender
{
  // Attention, we are *not* doing what MacOS-X does.
  // But they are *not* doing what the OpenStep specification says.
  // This is a compromise -- and fully OpenStep compliant.
  NSSelectionDirection s =  NSDirectSelection;

  if (window)
    s = [window keyViewSelectionDirection];

  switch (s)
    {
      // window selecting backwards
    case NSSelectingPrevious:
      [self _selectPreviousSelectableCellBeforeRow: numRows
	    column: numCols];
      break;
      // Window selecting forward
    case NSSelectingNext:
      [self _selectNextSelectableCellAfterRow: -1
	    column: -1];
      break;
    case NSDirectSelection:
      // Someone else -- we have some freedom here
      if ([_selectedCell isSelectable])
	{
	  [self selectTextAtRow: _selectedRow
		column: _selectedColumn];
	}
      else
	{
	  // TODO: Select keyCell
	}
      break;
    }
}

- (id) selectTextAtRow: (int)row column: (int)column
{
  if (row < 0 || row >= numRows || column < 0 || column >= numCols)
    return self;

  if ([cells[row][column] isSelectable] == NO)
    return nil;

  if (_textObject)
    {
      if (_selectedCell == cells[row][column])
	{
	  [_textObject selectAll: self];
	  return _selectedCell;
	}
      else
	{
	  [self validateEditing];
	  [self abortEditing];
	}
    }

  // Now _textObject == nil
  {
    NSText *t = [window fieldEditor: YES
			forObject: self];

    if ([t superview] != nil)
      if ([t resignFirstResponder] == NO)
	return nil;

    _selectedCell = cells[row][column];
    _selectedRow = row;
    _selectedColumn = column;
    _textObject = [_selectedCell setUpFieldEditorAttributes: t];
    [_selectedCell selectWithFrame: [self cellFrameAtRow: _selectedRow
					  column: _selectedColumn]
		   inView: self
		   editor: _textObject
		   delegate: self
		   start: 0
		   length: [[_selectedCell stringValue] length]];
    return _selectedCell;
  }
}

- (id) keyCell
{
  // TODO
  return nil;
}

- (id) nextText
{
  return _nextKeyView;
}

- (id) previousText
{
  return _previousKeyView;
}

- (void) textDidBeginEditing: (NSNotification *)aNotification
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary *d;

  d = [NSDictionary dictionaryWithObject:[aNotification object]
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidBeginEditingNotification
      object: self
      userInfo: d];
}

- (void) textDidChange: (NSNotification *)aNotification
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary *d;

  d = [NSDictionary dictionaryWithObject: [aNotification object]
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidChangeNotification
      object: self
      userInfo: d];
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary *d;
  id textMovement;

  [self validateEditing];

  d = [NSDictionary dictionaryWithObject: [aNotification object]
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidEndEditingNotification
      object: self
      userInfo: d];

  [_selectedCell endEditing: [aNotification object]];
  _textObject = nil;

  textMovement = [[aNotification userInfo] objectForKey: @"NSTextMovement"];
  if (textMovement)
    {
      switch ([(NSNumber *)textMovement intValue])
	{
	case NSReturnTextMovement:
	  [self sendAction];
	  break;
	case NSTabTextMovement:
	  if (_tabKeyTraversesCells)
	    {
	      if([self _selectNextSelectableCellAfterRow: _selectedRow
		       column: _selectedColumn])
		break;
	    }
	  [window selectKeyViewFollowingView: self];
	  break;
	case NSBacktabTextMovement:
	  if (_tabKeyTraversesCells)
	    {
	      if([self _selectPreviousSelectableCellBeforeRow: _selectedRow
		       column: _selectedColumn])
		break;
	    }
	  [window selectKeyViewPrecedingView: self];
	  break;
	}
    }
}

- (BOOL) textShouldBeginEditing: (NSText *)textObject
{
  if (_delegate && [_delegate respondsToSelector:
				@selector(control:textShouldBeginEditing:)])
    return [_delegate control: self
		      textShouldBeginEditing: textObject];
  else
    return YES;
}

- (BOOL) textShouldEndEditing: (NSText *)aTextObject
{
  if ([_selectedCell isEntryAcceptable: [aTextObject text]] == NO)
    {
      [self sendAction: _errorAction to: [self target]];
      return NO;
    }

  if ([_delegate respondsToSelector:
		   @selector(control:textShouldEndEditing:)])
    {
      if ([_delegate control: self
		     textShouldEndEditing: aTextObject] == NO)
	{
	  NSBeep ();
	  return NO;
	}
    }

  // In all other cases
  return YES;
}

- (BOOL) tabKeyTraversesCells
{
  return _tabKeyTraversesCells;
}

- (void) setTabKeyTraversesCells: (BOOL)flag
{
  _tabKeyTraversesCells = flag;
}

- (void) setNextText: (id)anObject
{
  [self setNextKeyView: anObject];
}

- (void) setPreviousText: (id)anObject
{
  [self setPreviousKeyView: anObject];
}

- (void) setValidateSize: (BOOL)flag
{
// TODO
}

- (void) sizeToCells
{
  NSSize newSize;
  int nc = numCols;
  int nr = numRows;

  if (!nc)
    nc = 1;
  if (!nr)
    nr = 1;
  newSize.width = nc * (cellSize.width + intercell.width) - intercell.width;
  newSize.height = nr * (cellSize.height + intercell.height) - intercell.height;
  [self setFrameSize: newSize];
}

- (void) sizeToFit
{
  NSSize newSize = NSZeroSize;
  NSSize tmpSize;
  int i, j;

  for (i = 0; i < numRows; i++)
    {
      for (j = 0; j < numCols; j++)
	{
	  tmpSize = [cells[i][j] cellSize];
	  if (tmpSize.width > newSize.width)
	    newSize.width = tmpSize.width;
	  if (tmpSize.height > newSize.height)
	    newSize.height = tmpSize.height;
	}
    }
  [self setCellSize: newSize];
}

- (void) scrollCellToVisibleAtRow: (int)row
			   column: (int)column
{
  [self scrollRectToVisible: [self cellFrameAtRow: row column: column]];
}

- (void) setAutoscroll: (BOOL)flag
{
  autoscroll = flag;
}

- (void) setScrollable: (BOOL)flag
{
  int	i;

  for (i = 0; i < numRows; i++)
    {
      int	j;

      for (j = 0; j < numCols; j++)
	{
	  [cells[i][j] setScrollable: flag];
	}
    }
  [cellPrototype setScrollable: flag];
}

- (void) drawRect: (NSRect)rect
{
  int i, j;
  int row1, col1;	// The cell at the upper left corner
  int row2, col2;	// The cell at the lower right corner

  if (drawsBackground)
    {
      [backgroundColor set];
      NSRectFill(rect);
    }

  [self getRow: &row1 column: &col1 forPoint: rect.origin];
  [self getRow: &row2 column: &col2
    forPoint: NSMakePoint(NSMaxX(rect), NSMaxY(rect))];

  if (row1 < 0)
    row1 = 0;
  if (col1 < 0)
    col1 = 0;

  /* Draw the cells within the drawing rectangle. */
  for (i = row1; i <= row2 && i < numRows; i++)
    for (j = col1; j <= col2 && j < numCols; j++)
      [self drawCellAtRow: i column: j];
}

- (BOOL) isOpaque
{
  return drawsBackground;
}

- (void) drawCellAtRow: (int)row column: (int)column
{
  NSCell *aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      NSRect cellFrame = [self cellFrameAtRow: row column: column];

      if (drawsCellBackground)
	{
	  [self lockFocus];
	  [cellBackgroundColor set];
	  NSRectFill(cellFrame);
	  [self unlockFocus];
	}
      [aCell drawWithFrame: cellFrame inView: self];
    }
}

- (void) highlightCell: (BOOL)flag atRow: (int)row column: (int)column
{
  NSCell	*aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      NSRect cellFrame = [self cellFrameAtRow: row column: column];

      if (drawsCellBackground)
	{
	  [self lockFocus];
	  [cellBackgroundColor set];
	  NSRectFill(cellFrame);
	  [self unlockFocus];
	}
      [aCell highlight: flag
             withFrame: cellFrame
                inView: self];
    }
}


- (BOOL) sendAction: (SEL)theAction
		 to: (id)theTarget
{
  if (theAction)
    {
      if (theTarget)
	{
	  return [super sendAction: theAction to: theTarget];
	}
      else
	{
	  return [super sendAction: theAction to: [self target]];
	}
    }
  else
    {
      return [super sendAction: [self action] to: [self target]];
    }
}


- (BOOL) sendAction
{
  if (![_selectedCell isEnabled])
    {
      return NO;
    }
  return [self sendAction: [_selectedCell action] to: [_selectedCell target]];
}

- (void) sendAction: (SEL)aSelector
		 to: (id)anObject
        forAllCells: (BOOL)flag
{
  int	i;

  if (flag)
    {
      for (i = 0; i < numRows; i++)
	{
	  int	j;

	  for (j = 0; j < numCols; j++)
	    {
	      if (![anObject performSelector: aSelector
				  withObject: cells[i][j]])
		{
		  return;
		}
	    }
	}
    }
  else
    {
      for (i = 0; i < numRows; i++)
	{
	  int	j;

	  for (j = 0; j < numCols; j++)
	    {
	      if (selectedCells[i][j])
		{
		  if (![anObject performSelector: aSelector
				      withObject: cells[i][j]])
		    {
		      return;
		    }
		}
	    }
	}
    }
}

- (void) sendDoubleAction
{
  if (![_selectedCell isEnabled])
    {
      return;
    }
  if (_doubleAction != 0)
    {
      [_target performSelector: _doubleAction withObject: self];
    }
  else
    {
      [self sendAction];
    }
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  if (mode == NSListModeMatrix)
    return NO;
  else
    return YES;
}

- (void) _mouseDownNonListMode: (NSEvent *)theEvent
{
  BOOL mouseUpInCell = NO;
  NSCell *highlightedCell = nil;
  int highlightedRow = 0;
  int highlightedColumn = 0;
  NSCell *mouseCell;
  int mouseRow;
  int mouseColumn;
  NSPoint mouseLocation;
  NSRect mouseCellFrame;
  unsigned eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
                     | NSMouseMovedMask  | NSLeftMouseDraggedMask;

  if ((mode == NSRadioModeMatrix) && _selectedCell != nil)
    {
      [_selectedCell setState: NSOffState];
      [self drawCellAtRow: _selectedRow column: _selectedColumn];
      [window flushWindow];
      selectedCells[_selectedRow][_selectedColumn] = NO;
      _selectedCell = nil;
      _selectedRow = _selectedColumn = -1;
    }

  while (!mouseUpInCell && ([theEvent type] != NSLeftMouseUp))
    {
      mouseLocation = [self convertPoint: [theEvent locationInWindow]
                                fromView: nil];
      [self getRow: &mouseRow column: &mouseColumn forPoint: mouseLocation];
      mouseCellFrame = [self cellFrameAtRow: mouseRow column: mouseColumn];

      if (((mode == NSRadioModeMatrix) && ![self allowsEmptySelection])
	|| [self mouse: mouseLocation inRect: mouseCellFrame])
        {
          mouseCell = [self cellAtRow: mouseRow column: mouseColumn];

          _selectedCell = mouseCell;
          _selectedRow = mouseRow;
          _selectedColumn = mouseColumn;
          selectedCells[_selectedRow][_selectedColumn] = YES;

          if (((mode == NSRadioModeMatrix) || (mode == NSHighlightModeMatrix))
              && (highlightedCell != mouseCell))
            {
              if (highlightedCell)
                [self highlightCell: NO
                              atRow: highlightedRow
                             column: highlightedColumn];

              highlightedCell = mouseCell;
              highlightedRow = mouseRow;
              highlightedColumn = mouseColumn;
              [self highlightCell: YES
                            atRow: highlightedRow
                           column: highlightedColumn];
              [window flushWindow];
            }

          mouseUpInCell = [mouseCell trackMouse: theEvent
                                         inRect: mouseCellFrame
                                         ofView: self
                                   untilMouseUp: YES];

          if (mode == NSHighlightModeMatrix)
            {
              [self highlightCell: NO
                            atRow: highlightedRow
                           column: highlightedColumn];
              highlightedCell = nil;
              [window flushWindow];
            }
        }
      else
        {
          // mouse is not over a Cell
          if (highlightedCell)
            {
              [self highlightCell: NO
                            atRow: highlightedRow
                           column: highlightedColumn];
              highlightedCell = nil;
              [window flushWindow];
            }
        }

      // if mouse didn't go up, take next event
      if (!mouseUpInCell)
        theEvent = [NSApp nextEventMatchingMask: eventMask
                                      untilDate: [NSDate distantFuture]
                                         inMode: NSEventTrackingRunLoopMode
                                        dequeue: YES];
    }

  // the mouse went up.
  // if it was inside a cell, the cell has already sent the action.
  // if not, _selectedCell is the last cell that had the mouse, and
  // it's state is Off. It must be set into a consistent state.
  // anyway, the action has to be sent
  if (!mouseUpInCell)
    {
      if ((mode == NSRadioModeMatrix) && !allowsEmptySelection)
	{
	  [_selectedCell setState: NSOnState];
	  [window flushWindow];
	}
      else
	{
	  if (_selectedCell != nil)
	    {
	      selectedCells[_selectedRow][_selectedColumn] = NO;
	      _selectedCell = nil;
	      _selectedRow = _selectedColumn = -1;
	    }
	}
      [self sendAction];
    }

  if (_target && _doubleAction && ([theEvent clickCount] > 1))
    [_target performSelector: _doubleAction withObject: self];

  if (highlightedCell)
    {
      [self highlightCell: NO
		    atRow: highlightedRow
		   column: highlightedColumn];
      [window flushWindow];
    }
}


- (void) mouseDown: (NSEvent*)theEvent
{
  BOOL onCell;
  int row, column;
  unsigned eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
			| NSMouseMovedMask | NSLeftMouseDraggedMask
			| NSPeriodicMask;
  NSPoint lastLocation = [theEvent locationInWindow];
  NSEvent* lastEvent = nil;
  BOOL done = NO;
  NSRect rect;
  id aCell, previousCell = nil, selectedCellTarget;
  NSRect previousCellRect;
  NSApplication *app = [NSApplication sharedApplication];
  static MPoint anchor = {0, 0};

  lastLocation = [self convertPoint: lastLocation
		       fromView: nil];

  // If mouse down was on a selectable cell, start editing/selecting.
  if([self getRow: &row
	   column: &column
	   forPoint: lastLocation])
    {
      if ([cells[row][column] isSelectable])
	{
	  NSText* t = [window fieldEditor: YES forObject: self];

	  if ([t superview] != nil)
	    {
	      if ([t resignFirstResponder] == NO)
		{
		  if ([window makeFirstResponder: window] == NO)
		    return;
		}
	    }
	  // During editing, the selected cell is the cell being edited
	  _selectedCell = cells[row][column];
	  _selectedRow = row;
	  _selectedColumn = column;
	  _textObject = [_selectedCell setUpFieldEditorAttributes: t];
	  [_selectedCell editWithFrame: [self cellFrameAtRow: row
					      column: column]
			inView: self
			editor: _textObject
			delegate: self
			event: theEvent];
	  return;
	}
    }

  // Paranoia check -- _textObject should already be nil, since we
  // accept first responder, so NSWindow should have already given
  // us first responder status (thus already ending editing with _textObject).
  if (_textObject)
    {
      NSLog (@"Hi, I am a bug.");
      [self validateEditing];
      [self abortEditing];
    }

  mouseDownFlags = [theEvent modifierFlags];

  if (mode != NSListModeMatrix)
    {
      [self _mouseDownNonListMode: theEvent];
      return;
    }

  if ((mode != NSTrackModeMatrix) && (mode != NSHighlightModeMatrix))
    [NSEvent startPeriodicEventsAfterDelay: 0.05
	     withPeriod: 0.05];
  ASSIGN(lastEvent, theEvent);

  // selection involves two steps, first
  // a loop that continues until the left mouse goes up; then a series of
  // steps which send actions and display the cell as it should appear after
  // the selection process is complete
  while (!done)
    {
      BOOL shouldProceedEvent = NO;

      onCell = [self getRow: &row
		     column: &column
		     forPoint: lastLocation];
      if (onCell)
	{
	  aCell = [self cellAtRow: row
			column: column];
	  rect = [self cellFrameAtRow: row
		       column: column];
	  if (aCell != previousCell)
	    {
	      switch (mode)
		{
		  case NSTrackModeMatrix:
		    // in Track mode the cell should track the mouse
		    // until the cursor either leaves the cellframe or
		    // NSLeftMouseUp occurs
		    _selectedCell = aCell;
		    _selectedRow = row;
		    _selectedColumn = column;
		    if ([aCell trackMouse: lastEvent
				   inRect: rect
				   ofView: self
			     untilMouseUp: YES])
		      done = YES;
		    break;

		  case NSHighlightModeMatrix:
		    // Highlight mode is like Track mode except that
		    // the cell is lit before begins tracking and
		    // unlit afterwards
		    [aCell setState: 1];
		    _selectedCell = aCell;
		    _selectedRow = row;
		    _selectedColumn = column;
		    [aCell highlight: YES withFrame: rect inView: self];
		    [window flushWindow];

		    if ([aCell trackMouse: lastEvent
				      inRect: rect
				      ofView: self
				      untilMouseUp: YES])
		      done = YES;

		    [aCell setState: 0];
		    [aCell highlight: NO withFrame: rect inView: self];
		    [window flushWindow];
		    break;

		  case NSRadioModeMatrix:
		    // Radio mode allows no more than one cell to be selected
		    if (previousCell == aCell)
		      break;

		    // deselect previously selected cell
		    if (_selectedCell != nil)
		      {
			[_selectedCell setState: 0];
			if (!previousCell)
			  previousCellRect = [self cellFrameAtRow: _selectedRow
			   column: _selectedColumn];
			[_selectedCell highlight: NO
				      withFrame: previousCellRect
					 inView: self];
			selectedCells[_selectedRow][_selectedColumn] = NO;
		      }
		    // select current cell
		    _selectedCell = aCell;
		    _selectedRow = row;
		    _selectedColumn = column;
		    [aCell setState: 1];
		    [aCell highlight: YES withFrame: rect inView: self];
		    selectedCells[row][column] = YES;
		    [window flushWindow];
		    break;

		  case NSListModeMatrix:
		    // List mode allows multiple cells to be selected
		    {
		      unsigned modifiers = [lastEvent modifierFlags];

		      if (previousCell == aCell)
			break;
		      // When the user first clicks on a cell
		      // we clear the existing selection
		      // unless the Alternate or Shift keys have been pressed.
		      if (!previousCell)
			{
			  if (!(modifiers & NSShiftKeyMask)
			    && !(modifiers & NSAlternateKeyMask))
			    {
			      [self deselectAllCells];
			      anchor = MakePoint (column, row);
			    }
			  // Consider the selected cell as the
			  // anchor from which to extend the
			  // selection to the current cell
			  if (!(modifiers & NSAlternateKeyMask))
			    {
			      _selectedCell = aCell;
			      _selectedRow = row;
			      _selectedColumn = column;

			      [_selectedCell setState: 1];
			      [_selectedCell highlight: YES
					    withFrame: rect
					       inView: self];
			      selectedCells[row][column]=YES;
			      [window flushWindow];
			      break;
			    }
			}
		      [self setSelectionFrom:
			INDEX_FROM_COORDS(_selectedColumn, _selectedRow)
			to: INDEX_FROM_COORDS(column, row)
			anchor: INDEX_FROM_POINT(anchor)
			highlight: YES];

		      [window flushWindow];
		      _selectedCell = aCell;
		      _selectedRow = row;
		      _selectedColumn = column;
		      break;
		    }
		}
	      previousCell = aCell;
	      previousCellRect = rect;
	      [self scrollRectToVisible: rect];
	    }
	}

      // if done break out of selection loop
      if (done)
	break;

      while (!shouldProceedEvent)
	{
	  theEvent = [app nextEventMatchingMask: eventMask
				      untilDate: [NSDate distantFuture]
					 inMode: NSEventTrackingRunLoopMode
				        dequeue: YES];
	  switch ([theEvent type])
	    {
	      case NSPeriodic:
		NSDebugLog(@"NSMatrix: got NSPeriodic event\n");
		shouldProceedEvent = YES;
		break;

	      // Track and Highlight modes do not use
	      // periodic events so we must break out
	      // and check if the mouse is in a cell
	      case NSLeftMouseUp:
		done = YES;
	      case NSLeftMouseDown:
	      default:
		if ((mode == NSTrackModeMatrix)
		  || (mode == NSHighlightModeMatrix))
		  shouldProceedEvent = YES;
		NSDebugLog(@"NSMatrix: got event of type: %d\n",
					      [theEvent type]);
		ASSIGN(lastEvent, theEvent);
		continue;
	    }
	}
      lastLocation = [lastEvent locationInWindow];
      lastLocation = [self convertPoint: lastLocation fromView: nil];
    }

  switch (mode)
    {
      case NSRadioModeMatrix:
	if (_selectedCell != nil)
	  [_selectedCell highlight: NO withFrame: rect inView: self];
      case NSListModeMatrix:
	[self setNeedsDisplayInRect: rect];
	[window flushWindow];
      case NSHighlightModeMatrix:
      case NSTrackModeMatrix:
	break;
    }

  if (_selectedCell != nil)
    {
      // send single click action
      if (!(selectedCellTarget = [_selectedCell target]))
	{
	  // selected cell has no target so send single
	  // click action to matrix's (self's) target
	  if (_target)
	    [_target performSelector: _action withObject: self];
	}
      else
	{
	  // in Track and Highlight modes the single
	  // click action has already been sent by the
	  // cell to it's target (if it has one)
	  if ((mode != NSTrackModeMatrix) && (mode != NSHighlightModeMatrix))
	    [selectedCellTarget performSelector: [_selectedCell action]
				     withObject: self];
	}
    }
  // click count > 1 indicates a double click
  if (_target && _doubleAction && ([lastEvent clickCount] > 1))
    [_target performSelector: _doubleAction withObject: self];

  if ((mode != NSTrackModeMatrix) && (mode != NSHighlightModeMatrix))
    [NSEvent stopPeriodicEvents];

  RELEASE(lastEvent);
}

- (void) updateCell: (NSCell*)aCell
{
  int		row, col;
  NSRect	rect;

  if ([self getRow: &row column: &col ofCell: aCell] == NO)
    return;	// Not a cell in this matrix - we can't update it.

  rect = [self cellFrameAtRow: row column: col];
  [self setNeedsDisplayInRect: rect];
}

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  NSString	*key = [theEvent charactersIgnoringModifiers];
  int		i;

  for (i = 0; i < numRows; i++)
    {
      int	j;

      for (j = 0; j < numCols; j++)
	{
	  NSCell	*aCell = cells[i][j];;

	  if ([aCell isEnabled]
	    && [[aCell keyEquivalent] isEqualToString: key])
	    {
	      NSCell	*oldSelectedCell = _selectedCell;

	      _selectedCell = aCell;
	      [self highlightCell: YES atRow: i column: j];
	      [aCell setState: ![aCell state]];
	      [self sendAction];
	      [self highlightCell: NO atRow: i column: j];
	      _selectedCell = oldSelectedCell;

	      return YES;
	    }
	}
    }

  return NO;
}

- (void) resetCursorRects
{
  int	i;

  for (i = 0; i < numRows; i++)
    {
      int	j;

      for (j = 0; j < numCols; j++)
	{
	  NSCell	*aCell = cells[i][j];

	  [aCell resetCursorRect: [self cellFrameAtRow: i column: j]
		 inView: self];
	}
    }
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // TODO
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  // TODO
  [super initWithCoder: aDecoder];

  return self;
}

- (void) setMode: (NSMatrixMode)aMode
{
  mode = aMode;
}

- (NSMatrixMode) mode
{
  return mode;
}

- (void) setCellClass: (Class)class
{
  cellClass = class;
  if (cellClass == nil)
    {
      cellClass = defaultCellClass;
    }
  cellNew = [cellClass methodForSelector: allocSel];
  cellInit = [cellClass instanceMethodForSelector: initSel];
  DESTROY(cellPrototype);
}

- (Class) cellClass
{
  return cellClass;
}

- (void) setPrototype: (NSCell*)aCell
{
  ASSIGN(cellPrototype, aCell);
  if (cellPrototype == nil)
    {
      [self setCellClass: defaultCellClass];
    }
  else
    {
      cellNew = [cellPrototype methodForSelector: copySel];
      cellInit = 0;
      cellClass = [aCell class];
    }
}

- (id) prototype
{
  return cellPrototype;
}

- (NSSize) cellSize
{
  return cellSize;
}

- (NSSize) intercellSpacing
{
  return intercell;
}

- (void) setBackgroundColor: (NSColor*)c
{
  ASSIGN(backgroundColor, c);
}

- (NSColor*) backgroundColor
{
  return backgroundColor;
}

- (void) setCellBackgroundColor: (NSColor*)c
{
  ASSIGN(cellBackgroundColor, c);
}

- (NSColor*) cellBackgroundColor
{
  return cellBackgroundColor;
}

- (void) setDelegate: (id)object
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = object;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(controlText##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(controlText##notif_name:) \
      name: NSControlText##notif_name##Notification object: self]

  if (_delegate)
    {
      SET_DELEGATE_NOTIFICATION(DidBeginEditing);
      SET_DELEGATE_NOTIFICATION(DidEndEditing);
      SET_DELEGATE_NOTIFICATION(DidChange);
    }
}

- (id) delegate
{
  return _delegate;
}

- (void) setTarget: anObject
{
  ASSIGN(_target, anObject);
}

- (id) target
{
  return _target;
}

- (void) setAction: (SEL)sel
{
  _action = sel;
}

- (SEL) action
{
  return _action;
}

- (void) setDoubleAction: (SEL)sel
{
  _doubleAction = sel;
}

- (SEL) doubleAction
{
  return _doubleAction;
}

- (void) setErrorAction: (SEL)sel
{
  _errorAction = sel;
}

- (SEL) errorAction
{
  return _errorAction;
}

- (void) setAllowsEmptySelection: (BOOL)f
{
  allowsEmptySelection = f;
}

- (BOOL) allowsEmptySelection
{
  return allowsEmptySelection;
}

- (void) setSelectionByRect: (BOOL)flag
{
  selectionByRect = flag;
}

- (BOOL) isSelectionByRect
{
  return selectionByRect;
}

- (void) setDrawsBackground: (BOOL)flag
{
  drawsBackground = flag;
}

- (BOOL) drawsBackground
{
  return drawsBackground;
}

- (void) setDrawsCellBackground: (BOOL)f
{
  drawsCellBackground = f;
}

- (BOOL) drawsCellBackground
{
  return drawsCellBackground;
}

- (void) setAutosizesCells: (BOOL)flag
{
  autosizesCells = flag;
}

- (BOOL) autosizesCells
{
  return autosizesCells;
}

- (BOOL) isAutoscroll
{
  return autoscroll;
}

- (int) numberOfRows
{
  return numRows;
}

- (int) numberOfColumns
{
  return numCols;
}

- (id) selectedCell
{
  return _selectedCell;
}

- (int) selectedColumn
{
  return _selectedColumn;
}

- (int) selectedRow
{
  return _selectedRow;
}

- (int) mouseDownFlags
{
  return mouseDownFlags;
}

- (BOOL) isFlipped
{
  return YES;
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  NSSize oldBoundsSize = bounds.size;
  NSSize newBoundsSize;
  NSSize change;
  int nc = numCols;
  int nr = numRows;

  [super resizeWithOldSuperviewSize: oldSize];

  newBoundsSize = bounds.size;

  change.height = newBoundsSize.height - oldBoundsSize.height;
  change.width = newBoundsSize.width - oldBoundsSize.width;

  if (autosizesCells)
    {
      if (change.height != 0)
	{
	  if (nr <= 0) nr = 1;
	  if (cellSize.height == 0)
	    {
	      cellSize.height = oldBoundsSize.height
		- ((nr - 1) * intercell.height);
	      cellSize.height = cellSize.height / nr;
	    }
	  change.height = change.height / nr;
	  cellSize.height += change.height;
	  if (cellSize.height < 0)
	    cellSize.height = 0;
	}
      if (change.width != 0)
	{
	  if (nc <= 0) nc = 1;
	  if (cellSize.width == 0)
	    {
	      cellSize.width = oldBoundsSize.width
		- ((nc - 1) * intercell.width);
	      cellSize.width = cellSize.width / nc;
	    }
	  change.width = change.width / nc;
	  cellSize.width += change.width;
	  if (cellSize.width < 0)
	    cellSize.width = 0;
	}
    }
  else // !autosizesCells
    {
      if (change.height != 0)
	{
	  if (nr > 1)
	    {
	      if (intercell.height == 0)
		{
		  intercell.height = oldBoundsSize.height - (nr * cellSize.height);
		  intercell.height = intercell.height / (nr - 1);
		}
	      change.height = change.height / (nr - 1);
	      intercell.height += change.height;
	      if (intercell.height < 0)
		intercell.height = 0;
	    }
	}
      if (change.width != 0)
	{
	  if (nc > 1)
	    {
	      if (intercell.width == 0)
		{
		  intercell.width = oldBoundsSize.width - (nc * cellSize.width);
		  intercell.width = intercell.width / (nc - 1);
		}
	      change.width = change.width / (nc - 1);
	      intercell.width += change.width;
	      if (intercell.width < 0)
		intercell.width = 0;
	    }
	}
    }
  [self setNeedsDisplay: YES];
}

- (void) keyDown: (NSEvent *)theEvent;
{
  /*  unsigned int flags = [theEvent modifierFlags];
      unsigned int key_code = [theEvent keyCode];*/

  // TODO
  // Selecting (not-editable, not-selectable cells) with the keyboard
  NSLog (@"NSMatrix -keyDown:");

  [super keyDown: theEvent];
}

- (BOOL) acceptsFirstResponder
{
  // We gratefully accept keyboard events.
  return YES;
}

- (BOOL) abortEditing
{
  if (_textObject)
    {
      [_textObject setString: @""];
      [_selectedCell endEditing: _textObject];
      _textObject = nil;
      return YES;
    }
  else
    return NO;
}

- (NSText *) currentEditor
{
  if (_textObject && ([window firstResponder] == _textObject))
    return _textObject;
  else
    return nil;
}

- (void) validateEditing
{
  if (_textObject)
    [_selectedCell setStringValue: [_textObject text]];
}

@end


@implementation NSMatrix (PrivateMethods)

/*
 * Renew rows and columns, but when expanding the matrix, refrain from
 * creating rowSpace  items in the last row and colSpace items in the
 * last column.  When inserting the contents of an array into the matrix,
 * this avoids creation of new cless which would immediately be replaced
 * by those from the array.
 * NB. new spaces in the matrix are pre-initialised with nil values so
 * that replacing them doesn't cause attempts to release random memory.
 */
- (void) _renewRows: (int)row
	    columns: (int)col
	   rowSpace: (int)rowSpace
	   colSpace: (int)colSpace
{
  int		i, j;
  int		oldMaxC;
  int		oldMaxR;
  SEL		mkSel = @selector(makeCellAtRow:column:);
  IMP		mkImp = [self methodForSelector: mkSel];

//NSLog(@"%x - mr: %d mc:%d nr:%d nc:%d r:%d c:%d", (unsigned)self, maxRows, maxCols, numRows, numCols, row, col);
  if (row < 0)
    {
#if	STRICT == 0
      NSLog(@"renew negative row (%d) in matrix", row);
#else
      [NSException raise: NSRangeException
		  format: @"renew negative row (%d) in matrix", row];
#endif
      row = 0;
    }
  if (col < 0)
    {
#if	STRICT == 0
      NSLog(@"renew negative column (%d) in matrix", col);
#else
      [NSException raise: NSRangeException
		  format: @"renew negative column (%d) in matrix", col];
#endif
      col = 0;
    }

  /*
   * Update matrix dimension before we actually change it - so that
   * makeCellAtRow:column: diesn't think we are trying to make a cell
   * outside the array bounds.
   * Our implementation doesn't care, but a subclass might use
   * putCell:atRow:column: to implement it, and that checks bounds.
   */
  oldMaxC = maxCols;
  numCols = col;
  if (col > maxCols)
    maxCols = col;
  oldMaxR = maxRows;
  numRows = row;
  if (row > maxRows)
    maxRows = row;

  if (col > oldMaxC)
    {
      int	end = col - 1;

      for (i = 0; i < oldMaxR; i++)
	{
	  cells[i] = NSZoneRealloc(myZone, cells[i], col * sizeof(id));
	  selectedCells[i] = NSZoneRealloc(GSAtomicMallocZone(),
	    selectedCells[i], col * sizeof(BOOL));

	  for (j = oldMaxC; j < col; j++)
	    {
	      cells[i][j] = nil;
	      selectedCells[i][j] = NO;
	      if (j == end && colSpace > 0)
		{
		  colSpace--;
		}
	      else
		{
		  (*mkImp)(self, mkSel, i, j);
		}
	    }
	}
    }

  if (row > oldMaxR)
    {
      int	end = row - 1;

      cells = NSZoneRealloc(myZone, cells, row * sizeof(id*));
      selectedCells = NSZoneRealloc(myZone, selectedCells, row * sizeof(BOOL*));

      /* Allocate the new rows and fill them */
      for (i = oldMaxR; i < row; i++)
	{
	  cells[i] = NSZoneMalloc(myZone, col * sizeof(id));
	  selectedCells[i] = NSZoneMalloc(GSAtomicMallocZone(),
	    col * sizeof(BOOL));

	  if (i == end)
	    {
	      for (j = 0; j < col; j++)
		{
		  cells[i][j] = nil;
		  selectedCells[i][j] = NO;
		  if (rowSpace > 0)
		    {
		      rowSpace--;
		    }
		  else
		    {
		      (*mkImp)(self, mkSel, i, j);
		    }
		}
	    }
	  else
	    {
	      for (j = 0; j < col; j++)
		{
		  cells[i][j] = nil;
		  selectedCells[i][j] = NO;
		  (*mkImp)(self, mkSel, i, j);
		}
	    }
	}
    }

  [self deselectAllCells];
//NSLog(@"%x - end mr: %d mc:%d nr:%d nc:%d r:%d c:%d", (unsigned)self, maxRows, maxCols, numRows, numCols, row, col);
}

- (void) _setState: (int)state
	 highlight: (BOOL)highlight
	startIndex: (int)start
	  endIndex: (int)end
{
  int		i;
  MPoint	startPoint = POINT_FROM_INDEX(start);
  MPoint	endPoint = POINT_FROM_INDEX(end);

  for (i = startPoint.y; i <= endPoint.y; i++)
    {
      int	j;
      int	colLimit;

      if (i == startPoint.y)
	{
	  j = startPoint.x;
	}
      else
	{
	  j = 0;
	}

      if (i == endPoint.y)
	colLimit = endPoint.x;
      else
	colLimit = numCols - 1;

      for (; j <= colLimit; j++)
	{
	  NSRect	rect = [self cellFrameAtRow: i column: j];
	  NSCell	*aCell = cells[i][j];

	  [aCell setState: state];
	  [aCell highlight: highlight withFrame: rect inView: self];
	  [self setNeedsDisplayInRect: rect];
	  if (state == 0)
	    selectedCells[i][j] = NO;
	  else
	    selectedCells[i][j] = YES;
	}
    }
}

// Return YES on success; NO if no selectable cell found.
-(BOOL) _selectNextSelectableCellAfterRow: (int)row
				   column: (int)column
{
  int i,j;
  if (row > -1)
    {
      // First look for cells in the same row
      for (j = column + 1; j < numCols; j++)
	{
	  if ([cells[row][j] isSelectable])
	    {
	      _selectedCell = [self selectTextAtRow: row
				    column: j];
	      _selectedRow = row;
	      _selectedColumn = j;
	      return YES;
	    }
	}
    }
  // Otherwise, make the big cycle.
  for (i = row + 1; i < numRows; i++)
    {
      for (j = 0; j < numCols; j++)
	{
	  if ([cells[i][j] isSelectable])
	    {
	      _selectedCell = [self selectTextAtRow: i
				    column: j];
	      _selectedRow = i;
	      _selectedColumn = j;
	      return YES;
	    }
	}
    }
  return NO;
}
-(BOOL) _selectPreviousSelectableCellBeforeRow: (int)row
					column: (int)column
{
  int i,j;
  if (row < numCols)
    {
      // First look for cells in the same row
      for (j = column - 1; j > -1; j--)
	{
	  if ([cells[row][j] isSelectable])
	    {
	      _selectedCell = [self selectTextAtRow: row
				    column: j];
	      _selectedRow = row;
	      _selectedColumn = j;
	      return YES;
	    }
	}
    }
  // Otherwise, make the big cycle.
  for (i = row - 1; i > -1; i--)
    {
      for (j = numCols - 1; j > -1; j--)
	{
	  if ([cells[i][j] isSelectable])
	    {
	      _selectedCell = [self selectTextAtRow: i
				    column: j];
	      _selectedRow = i;
	      _selectedColumn = j;
	      return YES;
	    }
	}
    }
  return NO;
}
@end
