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
   Modified: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: March 2001

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

static NSNotificationCenter *nc;

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
    ({MPoint point = { index % _numCols, index / _numCols }; point; })

#define INDEX_FROM_COORDS(x,y) \
    (y * _numCols + x)
#define INDEX_FROM_POINT(point) \
    (point.y * _numCols + point.x)


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
static SEL copySel;
static SEL initSel;
static SEL allocSel;
static SEL getSel;

+ (void) initialize
{
  if (self == [NSMatrix class])
    {
      /* Set the initial version */
      [self setVersion: 1];

      copySel = @selector(copyWithZone:);
      initSel = @selector(init);
      allocSel = @selector(allocWithZone:);
      getSel = @selector(objectAtIndex:);

      /*
       * MacOS-X docs say default cell class is NSActionCell
       */
      defaultCellClass = [NSActionCell class];
      //
      nc = [NSNotificationCenter defaultCenter];
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
  _myZone = [self zone];
  [self _renewRows: rows columns: cols rowSpace: 0 colSpace: 0];
  _mode = aMode;
  [self setFrame: frameRect];

  if ((_numCols > 0) && (_numRows > 0))
    _cellSize = NSMakeSize (frameRect.size.width/_numCols,
			    frameRect.size.height/_numRows);
  else
    _cellSize = NSMakeSize (DEFAULT_CELL_WIDTH, DEFAULT_CELL_HEIGHT);

  _intercell = NSMakeSize(1, 1);
  _tabKeyTraversesCells = YES;
  [self setBackgroundColor: [NSColor controlBackgroundColor]];
  [self setDrawsBackground: YES];
  [self setCellBackgroundColor: [NSColor controlBackgroundColor]];
  [self setSelectionByRect: YES];
  [self setAutosizesCells: YES];
  _dottedRow = _dottedColumn = -1;
  if (_mode == NSRadioModeMatrix && _numRows > 0 && _numCols > 0)
    {
      [self selectCellAtRow: 0 column: 0];
    }
  else
    {
      _selectedRow = _selectedColumn = -1;
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

  for (i = 0; i < _maxRows; i++)
    {
      int	j;

      for (j = 0; j < _maxCols; j++)
	{
	  [_cells[i][j] release];
	}
      NSZoneFree(_myZone, _cells[i]);
      NSZoneFree(GSAtomicMallocZone(), _selectedCells[i]);
    }
  NSZoneFree(_myZone, _cells);
  NSZoneFree(_myZone, _selectedCells);

  [_cellPrototype release];
  [_backgroundColor release];
  [_cellBackgroundColor release];
  [super dealloc];
}

- (void) addColumn
{
  [self insertColumn: _numCols withCells: nil];
}

- (void) addColumnWithCells: (NSArray*)cellArray
{
  [self insertColumn: _numCols withCells: cellArray];
}

- (void) addRow
{
  [self insertRow: _numRows withCells: nil];
}

- (void) addRowWithCells: (NSArray*)cellArray
{
  [self insertRow: _numRows withCells: cellArray];
}

- (void) insertColumn: (int)column
{
  [self insertColumn: column withCells: nil];
}

- (void) insertColumn: (int)column withCells: (NSArray*)cellArray
{
  int	count = [cellArray count];
  int	i = _numCols + 1;

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
  if (count > 0 && (_numRows == 0 || _numCols == 0))
    {
      [self _renewRows: count columns: 1 rowSpace: 0 colSpace: count];
    }
  else
    {
      [self _renewRows: _numRows ? _numRows : 1
	       columns: i
	      rowSpace: 0
	      colSpace: count];
    }

  /*
   * Rotate the new column to the insertion point if necessary.
   */
  if (_numCols != column)
    {
      for (i = 0; i < _numRows; i++)
	{
	  int	j = _numCols;
	  id	old = _cells[i][j-1];

	  while (--j > column)
	    {
	      _cells[i][j] = _cells[i][j-1];
	      _selectedCells[i][j] = _selectedCells[i][j-1];
	    }
	  _cells[i][column] = old;
	  _selectedCells[i][column] = NO;
	}
	if (_selectedCell && (_selectedColumn >= column))
	_selectedColumn++;
    }

  /*
   * Now put the new cells from the array into the matrix.
   */
  if (count > 0)
    {
      IMP	getImp = [cellArray methodForSelector: getSel];

      for (i = 0; i < _numRows && i < count; i++)
	{
	  ASSIGN(_cells[i][column], (*getImp)(cellArray, getSel, i));
	}
    }

  if (_mode == NSRadioModeMatrix && !_allowsEmptySelection && _selectedCell == nil)
    [self selectCellAtRow: 0 column: 0];
}

- (void) insertRow: (int)row
{
  [self insertRow: row withCells: nil];
}

- (void) insertRow: (int)row withCells: (NSArray*)cellArray
{
  int	count = [cellArray count];
  int	i = _numRows + 1;

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
  if (count > 0 && (_numRows == 0 || _numCols == 0))
    {
      [self _renewRows: 1 columns: count rowSpace: count colSpace: 0];
    }
  else
    {
      [self _renewRows: i
	       columns: _numCols ? _numCols : 1
	      rowSpace: count
	      colSpace: 0];
    }

  /*
   * Rotate the newly created row to the insertion point if necessary.
   */
  if (_numRows != row)
    {
      id	*oldr = _cells[_numRows - 1];
      BOOL	*olds = _selectedCells[_numRows - 1];

      for (i = _numRows - 1; i > row; i--)
	{
	  _cells[i] = _cells[i-1];
	  _selectedCells[i] = _selectedCells[i-1];
	}
      _cells[row] = oldr;
      _selectedCells[row] = olds;
      if (_selectedCell && (_selectedRow >= row))
	_selectedRow++;

      if (_dottedRow != -1 && _dottedRow >= row)
	_dottedRow++;
    }

  /*
   * Put cells from the array into the matrix.
   */
  if (count > 0)
    {
      IMP	getImp = [cellArray methodForSelector: getSel];

      for (i = 0; i < _numCols && i < count; i++)
	{
	  ASSIGN(_cells[row][i], (*getImp)(cellArray, getSel, i));
	}
    }

  if (_mode == NSRadioModeMatrix && !_allowsEmptySelection
      && _selectedCell == nil)
    [self selectCellAtRow: 0 column: 0];
}

- (NSCell*) makeCellAtRow: (int)row
		   column: (int)column
{
  NSCell	*aCell;

  if (_cellPrototype != nil)
    {
      aCell = (*_cellNew)(_cellPrototype, copySel, _myZone);
    }
  else
    {
      aCell = (*_cellNew)(_cellClass, allocSel, _myZone);
      if (aCell != nil)
	{
	  aCell = (*_cellInit)(aCell, initSel);
	}
    }
  /*
   * This is only ever called when we are creating a new cell - so we know
   * we can simply assign a value into the matrix without releasing an old
   * value.  If someone uses this method directly (which the documentation
   * specifically says they shouldn't) they may produce a memory leak.
   */
  _cells[row][column] = aCell;
  return aCell;
}

- (NSRect) cellFrameAtRow: (int)row
		   column: (int)column
{
  NSRect rect;

  rect.origin.x = column * (_cellSize.width + _intercell.width);
  if (_rFlags.flipped_view)
    rect.origin.y = row * (_cellSize.height + _intercell.height);
  else
    rect.origin.y = (_numRows - row - 1) * (_cellSize.height + _intercell.height);
  rect.size = _cellSize;
  return rect;
}

- (void) getNumberOfRows: (int*)rowCount
		 columns: (int*)columnCount
{
  *rowCount = _numRows;
  *columnCount = _numCols;
}

- (void) putCell: (NSCell*)newCell
	   atRow: (int)row
	  column: (int)column
{
  if (row < 0 || row >= _numRows || column < 0 || column >= _numCols)
    {
      [NSException raise: NSRangeException
		  format: @"attempt to put cell outside matrix bounds"];
    }

  if ((row == _selectedRow) && (column == _selectedColumn) 
      && (_selectedCell != nil))
    _selectedCell = newCell;
  
  ASSIGN(_cells[row][column], newCell);

  [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
}

- (void) removeColumn: (int)col
{
  if (col >= 0 && col < _numCols)
    {
      int i;

      for (i = 0; i < _maxRows; i++)
	{
	  int	j;

	  AUTORELEASE(_cells[i][col]);
	  for (j = col + 1; j < _maxCols; j++)
	    {
	      _cells[i][j-1] = _cells[i][j];
	      _selectedCells[i][j-1] = _selectedCells[i][j];
	    }
	}
      _numCols--;
      _maxCols--;

      if (col == _selectedColumn)
	{
	  _selectedCell = nil;
	  [self selectCellAtRow: _selectedRow column: 0];
	}
      if (col == _dottedColumn)
	{
	  if (_numCols && [_cells[_dottedRow][0] acceptsFirstResponder])
	    _dottedColumn = 0;
	  else
	    _dottedRow = _dottedColumn = -1;
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
  if (row >= 0 && row < _numRows)
    {
      int	i;

#if	GS_WITH_GC == 0
      for (i = 0; i < _maxCols; i++)
	{
	  [_cells[row][i] autorelease];
	}
#endif
      NSZoneFree(_myZone, _cells[row]);
      NSZoneFree(GSAtomicMallocZone(), _selectedCells[row]);
      for (i = row + 1; i < _maxRows; i++)
	{
	  _cells[i-1] = _cells[i];
	  _selectedCells[i-1] = _selectedCells[i];
	}
      _maxRows--;
      _numRows--;

      if (row == _selectedRow)
	{
	  _selectedCell = nil;
	  [self selectCellAtRow: 0 column: _selectedColumn];
	}
      if (row == _dottedRow)
	{
	  if (_numRows && [_cells[0][_dottedColumn] acceptsFirstResponder])
	    _dottedRow = 0;
	  else
	    _dottedRow = _dottedColumn = -1;
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
  _cellSize = size;
  [self sizeToCells];
}

- (void) setIntercellSpacing: (NSSize)size
{
  _intercell = size;
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

  sorted = [NSMutableArray arrayWithCapacity: _numRows * _numCols];
  add = [sorted methodForSelector: @selector(addObject:)];
  get = [sorted methodForSelector: @selector(objectAtIndex:)];

  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  (*add)(sorted, @selector(addObject:), _cells[i][j]);
	}
    }

  [sorted sortUsingFunction: comparator context: context];

  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  _cells[i][j] = (*get)(sorted, @selector(objectAtIndex:), index++);
	}
    }
}

- (void) sortUsingSelector: (SEL)comparator
{
  NSMutableArray	*sorted;
  IMP			add;
  IMP			get;
  int			i, j, index = 0;

  sorted = [NSMutableArray arrayWithCapacity: _numRows * _numCols];
  add = [sorted methodForSelector: @selector(addObject:)];
  get = [sorted methodForSelector: @selector(objectAtIndex:)];

  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  (*add)(sorted, @selector(addObject:), _cells[i][j]);
	}
    }

  [sorted sortUsingSelector: comparator];

  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  _cells[i][j] = (*get)(sorted, @selector(objectAtIndex:), index++);
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
  BOOL nullMatrix = NO;
  int	approxRow = point.y / (_cellSize.height + _intercell.height);
  float	approxRowsHeight = approxRow * (_cellSize.height + _intercell.height);
  int	approxCol = point.x / (_cellSize.width + _intercell.width);
  float	approxColsWidth = approxCol * (_cellSize.width + _intercell.width);

  /* First check the limit cases */
  beyondCols = (point.x > _bounds.size.width || point.x < 0);
  beyondRows = (point.y > _bounds.size.height || point.y < 0);

  /* Determine if the point is inside the cell */
  betweenRows = !(point.y > approxRowsHeight
		&& point.y <= approxRowsHeight + _cellSize.height);
  betweenCols = !(point.x > approxColsWidth
		  && point.x <= approxColsWidth + _cellSize.width);

  if (beyondRows || betweenRows || beyondCols || betweenCols || nullMatrix)
    {
      if (row)
	*row = -1;

      if (column)
	*column = -1;

      return NO;
    }

  if (row)
    {
      if (_rFlags.flipped_view == NO)
	approxRow = _numRows - approxRow - 1;

      if (approxRow < 0)
	approxRow = 0;
      else if (approxRow >= _numRows)
	approxRow = _numRows - 1;
      if (_numRows == 0)
	{
	  nullMatrix = YES;
	  approxRow = 0;
	}
      *row = approxRow;
    }

  if (column)
    {
      if (approxCol < 0)
	approxCol = 0;
      else if (approxCol >= _numCols)
	approxCol = _numCols - 1;
      if (_numCols == 0)
	{
	  nullMatrix = YES;
	  approxCol = 0;
	}
      *column = approxCol;
    }

  return YES;
}

- (BOOL) getRow: (int*)row
	 column: (int*)column
	 ofCell: (NSCell*)aCell
{
  int	i;

  for (i = 0; i < _numRows; i++)
    {
      int	j;

      for (j = 0; j < _numCols; j++)
	{
	  if (_cells[i][j] == aCell)
	    {
	      if(row)
		*row = i;
	      if(column)
		*column = j;
	      return YES;
	    }
	}
    }

  if(row)
    *row = -1;
  if(column)
    *column = -1;

  return NO;
}

- (void) setState: (int)value
	    atRow: (int)row
	   column: (int)column
{
  NSCell	*aCell = [self cellAtRow: row column: column];

  if (!aCell)
    return;

  if (_mode == NSRadioModeMatrix)
    {
      if (value)
	{
	  if (_selectedRow > -1 && _selectedColumn > -1)
	    {
	      _selectedCells[_selectedRow][_selectedColumn] = NO;
	    }

	  _selectedCell = aCell;
	  _selectedRow = row;
	  _selectedColumn = column;

	  if ([_cells[_dottedRow][_dottedColumn] acceptsFirstResponder])
	    {
	      _dottedRow = row;
	      _dottedColumn = column;
	    }

	  [_selectedCell setState: value];
	  _selectedCells[row][column] = YES;
	}
      else if (_allowsEmptySelection)
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

  if (!_allowsEmptySelection && _mode == NSRadioModeMatrix)
    return;

  for (i = 0; i < _numRows; i++)
    {
      int	j;

      for (j = 0; j < _numCols; j++)
	{
	  if (_selectedCells[i][j])
	    {
	      NSCell	*aCell = _cells[i][j];
	      BOOL       isHighlighted = [aCell isHighlighted];

	      _selectedCells[i][j] = NO;

	      if ([aCell state] || isHighlighted)
		{
		  [aCell setState: NSOffState];

		  if (isHighlighted)
		    [self highlightCell: NO atRow: i column: j];
		  else
		    [self drawCellAtRow: i column: j];
		}
	    }
	}
    }
  _selectedCell = nil;
  _selectedRow = -1;
  _selectedColumn = -1;
}

- (void) deselectSelectedCell
{
  int i,j;

  if (!_selectedCell || (!_allowsEmptySelection && (_mode == NSRadioModeMatrix)))
    return;

  /*
   * For safety (as in macosx)
   */
  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  if (_selectedCells[i][j])
	    {
	      [_cells[i][j] setState: NSOffState];
	      _selectedCells[i][j] = NO;
	    }
	}
    }

  _selectedCell = nil;
  _selectedRow = -1;
  _selectedColumn = -1;
}

- (void) selectAll: (id)sender
{
  unsigned	i, j;

  _selectedCell = nil;
  _selectedRow = -1;
  _selectedColumn = -1;

  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  if ([_cells[i][j] isEnabled] == YES
	      && [_cells[i][j] isEditable] == NO)
	    {
	      _selectedCell = _cells[i][j];
	      [_selectedCell setState: NSOnState];
	      _selectedCells[i][j] = YES;

	      _selectedRow = i;
	      _selectedColumn = j;
	    }
	  else
	    {
	      _selectedCells[i][j] = NO;
	      [_cells[i][j] setShowsFirstResponder: NO];
	    }
	}
    }

  [self setNeedsDisplay: YES];
}

- (void) _selectCell: (NSCell *)aCell atRow: (int)row column: (int)column
{
  /*
   * We always deselect the current selection unless the new selection
   * is the same. (in NSRadioModeMatrix)
   */
  if (_mode == NSRadioModeMatrix && _selectedCell && aCell
      && _selectedCell != aCell)
    {
      _selectedCells[_selectedRow][_selectedColumn] = NO;
      [_selectedCell setState: NSOffState];
      [self setNeedsDisplayInRect: [self cellFrameAtRow: _selectedRow
					 column: _selectedColumn]];
    }

  if (aCell)
    {
      NSRect cellFrame;

      if (_selectedCell && _selectedCell != aCell)
	{
	  [_selectedCell setShowsFirstResponder: NO];
	  [self setNeedsDisplayInRect: [self cellFrameAtRow: _selectedRow
					     column: _selectedColumn]];
	}

      _selectedCell = aCell;
      _selectedRow = row;
      _selectedColumn = column;
      _selectedCells[row][column] = YES;

      cellFrame = [self cellFrameAtRow: row column: column];

      if ([_cells[row][column] acceptsFirstResponder])
	{
	  int lastRow, lastColumn;

	  lastRow = _dottedRow;
	  lastColumn = _dottedColumn;

	  _dottedRow = row;
	  _dottedColumn = column;

	  if (lastRow != -1 && lastColumn != -1
	      && (lastRow != row || lastColumn != column) 
	      && [self window] != nil)
	    [self drawCellAtRow: lastRow column: lastColumn];
	}

      [_selectedCell setState: NSOnState];

      if (_mode == NSListModeMatrix)
	[aCell setCellAttribute: NSCellHighlighted to: 1];

      if (_autoscroll)
	[self scrollRectToVisible: cellFrame];

      // Note: we select the cell iff it is 'selectable', not 'editable' 
      // as macosx says.  This looks definitely more appropriate. 
      // [This is going to start editing only if the cell is also editable,
      // otherwise the text gets selected and that's all.]
      [self selectTextAtRow: row column: column];

      [self setNeedsDisplayInRect: cellFrame];
    }
  else
    {
      _selectedCell = nil;
      _selectedRow = _selectedColumn = -1;
    }
}

- (void) selectCell: (NSCell *)aCell
{
  int row, column;

  if ([self getRow: &row column: &column ofCell: aCell] == YES)
    [self _selectCell: aCell atRow: row column: column];
}

- (void) selectCellAtRow: (int)row column: (int)column
{
  NSCell	*aCell;

  if ((row == -1) || (column == -1))
    {
      [self deselectAllCells];
      return;
    }

  aCell = [self cellAtRow: row column: column];

  if (aCell)
    [self _selectCell: aCell atRow: row column: column];
}

- (BOOL) selectCellWithTag: (int)anInt
{
  id	aCell;
  int	i = _numRows;

  while (i-- > 0)
    {
      int	j = _numCols;

      while (j-- > 0)
	{
	  aCell = _cells[i][j];
	  if ([aCell tag] == anInt)
	    {
	      [self _selectCell: aCell atRow: i column: j];
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

  for (i = 0; i < _numRows; i++)
    {
      int	j;

      for (j = 0; j < _numCols; j++)
	{
	  if (_selectedCells[i][j] == YES)
	    {
	      [array addObject: _cells[i][j]];
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
  BOOL	 doSelect = NO;
  BOOL	 doUnselect = NO;
  BOOL   drawLast = NO;
  int	 selectx = 0;
  int	 selecty = 0;
  int	 unselectx = 0;
  int	 unselecty = 0;
  int	 dca = endPos - anchorPos;
  int	 dla = startPos - anchorPos;
  int	 dca_dla = SIGN(dca) / (SIGN(dla) ? SIGN(dla) : 1);
  int    lastDottedRow, lastDottedColumn;
  MPoint end = POINT_FROM_INDEX(endPos);

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
	  drawLast = YES;
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
	  unselecty = startPos - 1;
	}
      else
	{
	  unselectx = startPos;
	  unselecty = anchorPos - 1;
	}
    }

  if (_dottedRow != -1 && _dottedColumn != -1
      && (_dottedRow != end.y || _dottedColumn != end.x))
    {
      lastDottedRow = _dottedRow;
      lastDottedColumn = _dottedColumn;

      [self drawCellAtRow: lastDottedRow column: lastDottedColumn];
    }

  _selectedRow = _dottedRow = end.y;
  _selectedColumn = _dottedColumn = end.x;
  _selectedCells[_selectedRow][_selectedColumn] = YES;
  _selectedCell = _cells[_selectedRow][_selectedColumn];

  if (doUnselect)
    {
      [self _setState: flag ? NSOffState : NSOnState
	    highlight: flag ? NO : YES
	    startIndex: unselectx
	    endIndex: unselecty];
    }
  if (doSelect)
    {
      [self _setState: flag ? NSOnState : NSOffState
	    highlight: flag ? YES : NO
	    startIndex: selectx
	    endIndex: selecty];
    }

  if (drawLast)
    [self drawCellAtRow: _dottedRow column: _dottedColumn];
}

- (id) cellAtRow: (int)row
	  column: (int)column
{
  if (row < 0 || row >= _numRows || column < 0 || column >= _numCols)
    return nil;
  return _cells[row][column];
}

- (id) cellWithTag: (int)anInt
{
  int	i = _numRows;

  while (i-- > 0)
    {
      int	j = _numCols;

      while (j-- > 0)
	{
	  id	aCell = _cells[i][j];

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

  c = [NSMutableArray arrayWithCapacity: _numRows * _numCols];
  add = [c methodForSelector: @selector(addObject:)];
  for (i = 0; i < _numRows; i++)
    {
      int	j;

      for (j = 0; j < _numCols; j++)
	{
	  (*add)(c, @selector(addObject:), _cells[i][j]);
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

  if (_window)
    s = [_window keyViewSelectionDirection];

  switch (s)
    {
      // _window selecting backwards
    case NSSelectingPrevious:
      [self _selectPreviousSelectableCellBeforeRow: _numRows
	    column: _numCols];
      break;
      // _Window selecting forward
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
	  if (_keyCell != nil)
	    {
	      BOOL isValid;
	      int row, column;
	      
	      isValid = [self getRow: &row  column: &column  
			      ofCell: _keyCell];
	      if (isValid == YES)
		{
		  [self selectTextAtRow: row  column: column];
		}
	    }
	}
      break;
    }
}

- (id) selectTextAtRow: (int)row column: (int)column
{
  if (row < 0 || row >= _numRows || column < 0 || column >= _numCols)
    return self;

  // macosx doesn't select the cell if it isn't 'editable'; instead,
  // we select the cell if and only if it is 'selectable', which looks
  // more appropriate.  This is going to start editing if and only if
  // the cell is also 'editable'.
  if ([_cells[row][column] isSelectable] == NO)
    return nil;

  if (_textObject)
    {
      if (_selectedCell == _cells[row][column])
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
    NSText *t = [_window fieldEditor: YES
			forObject: self];
    int length;

    if ([t superview] != nil)
      if ([t resignFirstResponder] == NO)
	return nil;

    if (_selectedCell && _selectedCell != _cells[row][column])
      {
	[_selectedCell setShowsFirstResponder: NO];
	[self setNeedsDisplayInRect: [self cellFrameAtRow: _selectedRow
					   column: _selectedColumn]];
      }

    _selectedCell = _cells[row][column];
    _selectedRow = row;
    _selectedColumn = column;

    if ([_cells[row][column] acceptsFirstResponder])
      {
	_dottedRow = row;
	_dottedColumn = column;
      }

    /* See comment in NSTextField */
    length = [[_selectedCell stringValue] length];
    _textObject = [_selectedCell setUpFieldEditorAttributes: t];
    [_selectedCell selectWithFrame: [self cellFrameAtRow: _selectedRow
					  column: _selectedColumn]
		   inView: self
		   editor: _textObject
		   delegate: self
		   start: 0
		   length: length];
    return _selectedCell;
  }
}

- (id) keyCell
{
  return _keyCell;
}

- (void) setKeyCell: (NSCell *)aCell 
{
  BOOL isValid;
  int row, column;

  isValid = [self getRow: &row  column: &column  ofCell: aCell];

  if (isValid == YES)
    {
      ASSIGN (_keyCell, aCell);
    }
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
  NSMutableDictionary *d;

  d = [[NSMutableDictionary alloc] initWithDictionary: 
				     [aNotification userInfo]];
  AUTORELEASE (d);
  [d setObject: [aNotification object] forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidBeginEditingNotification
      object: self
      userInfo: d];
}

- (void) textDidChange: (NSNotification *)aNotification
{
  NSMutableDictionary *d;
  NSFormatter *formatter;

  // MacOS-X asks us to inform the cell if possible.
  if ((_selectedCell != nil) && [_selectedCell respondsToSelector: 
						 @selector(textDidChange:)])
    [_selectedCell textDidChange: aNotification];

  d = [[NSMutableDictionary alloc] initWithDictionary: 
				     [aNotification userInfo]];
  AUTORELEASE (d);
  [d setObject: [aNotification object] forKey: @"NSFieldEditor"];

  [nc postNotificationName: NSControlTextDidChangeNotification
      object: self
      userInfo: d];

  formatter = [_cell formatter];
  if (formatter != nil)
    {
      /*
       * FIXME: This part needs heavy interaction with the yet to finish 
       * text system.
       *
       */
      NSString *partialString;
      NSString *newString = nil;
      NSString *error = nil;
      BOOL wasAccepted;
      
      partialString = [_textObject string];
      wasAccepted = [formatter isPartialStringValid: partialString 
			       newEditingString: &newString 
			       errorDescription: &error];

      if (wasAccepted == NO)
	{
	  [_delegate control:self 
		     didFailToValidatePartialString: partialString 
		     errorDescription: error];
	}

      if (newString != nil)
	{
	  NSLog (@"Unimplemented: should set string to %@", newString);
	  // FIXME ! This would reset editing !
	  //[_textObject setString: newString];
	}
      else
	{
	  if (wasAccepted == NO)
	    {
	      // FIXME: Need to delete last typed character (?!)
	      NSLog (@"Unimplemented: should delete last typed character");
	    }
	}
      
    }
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  NSMutableDictionary *d;
  id textMovement;

  [self validateEditing];

  d = [[NSMutableDictionary alloc] initWithDictionary: 
				     [aNotification userInfo]];
  AUTORELEASE (d);
  [d setObject: [aNotification object] forKey: @"NSFieldEditor"];
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
	  if ([self sendAction] == NO)
	    {
	      NSEvent *event = [_window currentEvent];

	      if ([self performKeyEquivalent: event] == NO
		  && [_window performKeyEquivalent: event] == NO)
		[self selectText: self];
	    }
	  break;
	case NSTabTextMovement:
	  if (_tabKeyTraversesCells)
	    {
	      if([self _selectNextSelectableCellAfterRow: _selectedRow
		       column: _selectedColumn])
		break;
	    }
	  [_window selectKeyViewFollowingView: self];

	  if ([_window firstResponder] == _window)
	    {
	      if (_tabKeyTraversesCells)
		{
		  if([self _selectNextSelectableCellAfterRow: -1
			   column: -1])
		    break;
		}
	      [self selectText: self];
	    }
	  break;
	case NSBacktabTextMovement:
	  if (_tabKeyTraversesCells)
	    {
	      if([self _selectPreviousSelectableCellBeforeRow: _selectedRow
		       column: _selectedColumn])
		break;
	    }
	  [_window selectKeyViewPrecedingView: self];

	  if ([_window firstResponder] == _window)
	    {
	      if (_tabKeyTraversesCells)
		{
		  if([self _selectPreviousSelectableCellBeforeRow: _numRows
			   column: _numCols])
		    break;
		}
	      [self selectText: self];
	    }
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

  if ([_delegate respondsToSelector: 
		   @selector(control:isValidObject:)] == YES)
    {
      NSFormatter *formatter;
      id newObjectValue;
      
      formatter = [_cell formatter];
      
      if ([formatter getObjectValue: &newObjectValue 
		     forString: [_textObject text] 
		     errorDescription: NULL] == YES)
	{
	  if ([_delegate control: self
			 isValidObject: newObjectValue] == NO)
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
  int nc = _numCols;
  int nr = _numRows;

  if (!nc)
    nc = 1;
  if (!nr)
    nr = 1;
  newSize.width = nc * (_cellSize.width + _intercell.width) - _intercell.width;
  newSize.height = nr * (_cellSize.height + _intercell.height) - _intercell.height;
  [self setFrameSize: newSize];
}

- (void) sizeToFit
{
  NSSize newSize = NSZeroSize;
  NSSize tmpSize;
  int i, j;

  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  tmpSize = [_cells[i][j] cellSize];
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
  _autoscroll = flag;
}

- (void) setScrollable: (BOOL)flag
{
  int	i;

  for (i = 0; i < _numRows; i++)
    {
      int	j;

      for (j = 0; j < _numCols; j++)
	{
	  [_cells[i][j] setScrollable: flag];
	}
    }
  [_cellPrototype setScrollable: flag];
}

- (void) drawRect: (NSRect)rect
{
  int i, j;
  int row1, col1;	// The cell at the upper left corner
  int row2, col2;	// The cell at the lower right corner

  if (_drawsBackground)
    {
      [_backgroundColor set];
      NSRectFill(rect);
    }

  if (!_numRows || !_numCols)
    return;

  row1 = rect.origin.y / (_cellSize.height + _intercell.height);
  col1 = rect.origin.x / (_cellSize.width + _intercell.width);
  row2 = NSMaxY(rect) / (_cellSize.height + _intercell.height);
  col2 = NSMaxX(rect) / (_cellSize.width + _intercell.width);

  if (_rFlags.flipped_view == NO)
    {
      row1 = _numRows - row1 - 1;
      row2 = _numRows - row2 - 1;
    }

  if (row1 < 0)
    row1 = 0;
  else if (row1 >= _numRows)
    row1 = _numRows - 1;

  if (col1 < 0)
    col1 = 0;
  else if (col1 >= _numCols)
    col1 = _numCols - 1;

  if (row2 < 0)
    row2 = 0;
  else if (row1 >= _numRows)
    row2 = _numRows - 1;

  if (col2 < 0)
    col2 = 0;
  else if (col2 >= _numCols)
    col2 = _numCols - 1;

  /* Draw the cells within the drawing rectangle. */
  for (i = row1; i <= row2 && i < _numRows; i++)
    for (j = col1; j <= col2 && j < _numCols; j++)
      {
	[self drawCellAtRow: i column: j];
      }
}

- (BOOL) isOpaque
{
  return _drawsBackground;
}

- (void) drawCell: (NSCell *)aCell
{
  int row, column;

  if ([self getRow: &row  column: &column  ofCell: aCell] == YES)
    {
      [self drawCellAtRow: row  column: column];
    }
}

- (void) drawCellAtRow: (int)row column: (int)column
{
  NSCell *aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      NSRect cellFrame = [self cellFrameAtRow: row column: column];

      if (_drawsCellBackground)
	{
	  [self lockFocus];
	  [_cellBackgroundColor set];
	  NSRectFill(cellFrame);
	  [self unlockFocus];
	}

      if (_dottedRow == row && _dottedColumn == column
	  && [aCell acceptsFirstResponder])
	{
	  [aCell
	    setShowsFirstResponder: ([_window isKeyWindow]
				     && [_window firstResponder] == self)];
	}
      else
	[aCell setShowsFirstResponder: NO];

      [aCell drawWithFrame: cellFrame inView: self];
      [aCell setShowsFirstResponder: NO];
    }
}

- (void) highlightCell: (BOOL)flag atRow: (int)row column: (int)column
{
  NSCell	*aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      NSRect cellFrame = [self cellFrameAtRow: row column: column];

      if (_drawsCellBackground)
	{
	  [self lockFocus];
	  [_cellBackgroundColor set];
	  NSRectFill(cellFrame);
	  [self unlockFocus];
	}

      if (_dottedRow != -1 && _dottedColumn != -1
	  && _cells[_dottedRow][_dottedColumn] == aCell
	  && [_cells[_dottedRow][_dottedColumn] acceptsFirstResponder])
	{
	  [_cells[_dottedRow][_dottedColumn]
		 setShowsFirstResponder:
		   ([_window isKeyWindow]
		    && [_window firstResponder] == self)];
	}

      [aCell highlight: flag
             withFrame: cellFrame
                inView: self];

      if (_dottedRow != -1 && _dottedColumn != -1)
	[_cells[_dottedRow][_dottedColumn] setShowsFirstResponder: NO];
    }
}

- (BOOL) sendAction
{
  if (_selectedCell)
    {
      if ([_selectedCell isEnabled] == NO)
	return NO;

      return [self sendAction: [_selectedCell action] 
		   to:         [_selectedCell target]]; 
    }

  // _selectedCell == nil
  return [super sendAction: _action to: _target];
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
	  return [super sendAction: theAction to: _target];
	}
    }
  else
    {
      return [super sendAction: _action to: _target];
    }
}

- (void) sendAction: (SEL)aSelector
		 to: (id)anObject
        forAllCells: (BOOL)flag
{
  int	i;

  if (flag)
    {
      for (i = 0; i < _numRows; i++)
	{
	  int	j;

	  for (j = 0; j < _numCols; j++)
	    {
	      if (![anObject performSelector: aSelector
				  withObject: _cells[i][j]])
		{
		  return;
		}
	    }
	}
    }
  else
    {
      for (i = 0; i < _numRows; i++)
	{
	  int	j;

	  for (j = 0; j < _numCols; j++)
	    {
	      if (_selectedCells[i][j])
		{
		  if (![anObject performSelector: aSelector
				      withObject: _cells[i][j]])
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
  if ([_selectedCell isEnabled] == NO)
    return;

  if (_doubleAction)
    [self sendAction: _doubleAction to: _target];
  else
    [self sendAction];
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  if (_mode == NSListModeMatrix)
    return NO;
  else
    return YES;
}

- (void) _mouseDownNonListMode: (NSEvent *)theEvent
{
  BOOL mouseUpInCell = NO, onCell, scrolling = NO;
  NSCell *highlightedCell = nil;
  int highlightedRow = 0;
  int highlightedColumn = 0;
  NSCell *mouseCell;
  int mouseRow;
  int mouseColumn;
  NSPoint mouseLocation;
  NSRect mouseCellFrame;
  NSEvent *currentEvent = nil;
  unsigned eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
                     | NSMouseMovedMask  | NSLeftMouseDraggedMask;

  while (!mouseUpInCell && ([theEvent type] != NSLeftMouseUp))
    {
      mouseLocation = [self convertPoint: [theEvent locationInWindow]
                                fromView: nil];

      onCell = [self getRow: &mouseRow
		     column: &mouseColumn
		     forPoint: mouseLocation];

      if (!onCell)
	scrolling = NO;

      if (onCell)
	{
	  mouseCellFrame = [self cellFrameAtRow: mouseRow column: mouseColumn];
	  mouseCell = [self cellAtRow: mouseRow column: mouseColumn];

	  if (_autoscroll)
	    scrolling = [self scrollRectToVisible: mouseCellFrame];

	  if ([mouseCell isEnabled])
	    {
	      if ([mouseCell acceptsFirstResponder])
		{
		  NSCell *aCell = [self cellAtRow: _dottedRow
					column: _dottedColumn];

		  _dottedRow = mouseRow;
		  _dottedColumn = mouseColumn;

		  if (aCell && aCell != mouseCell)
		    [self drawCell: aCell];
		}

	      if (_selectedCell)
		{
		  if (_mode == NSRadioModeMatrix)
		    {
		      [_selectedCell setState: NSOffState];
		      [self drawCell: _selectedCell];
		    }

		  _selectedCells[_selectedRow][_selectedColumn] = NO;
		}

	      _selectedCell = mouseCell;
	      _selectedRow = mouseRow;
	      _selectedColumn = mouseColumn;
	      _selectedCells[_selectedRow][_selectedColumn] = YES;

	      if (_mode != NSTrackModeMatrix && highlightedCell != mouseCell)
		{
		  highlightedCell = mouseCell;
		  highlightedRow = mouseRow;
		  highlightedColumn = mouseColumn;

		  [self highlightCell: YES
			atRow: highlightedRow
			column: highlightedColumn];
		  [_window flushWindow];
		}

	      if (_mode == NSRadioModeMatrix)
		[mouseCell setState: NSOffState];

	      mouseUpInCell = [mouseCell trackMouse: theEvent
                                         inRect: mouseCellFrame
                                         ofView: self
					 untilMouseUp:
					   [[mouseCell class]
					     prefersTrackingUntilMouseUp]];

	      if (_mode != NSTrackModeMatrix)
		{
		  if(_mode == NSRadioModeMatrix)
		    {
		      if (!mouseUpInCell)
			[mouseCell setState: NSOnState];
		    }

		  highlightedCell = nil;

		  [self highlightCell: NO
			atRow: highlightedRow
			column: highlightedColumn];
		  [_window flushWindow];
		}

	      if (!mouseUpInCell)
		{
		  ASSIGN(currentEvent, [NSApp currentEvent]);

		  if (currentEvent && currentEvent != theEvent
		      && [currentEvent type] != NSPeriodic)
		    {
		      if (!scrolling)
			{
			  theEvent = currentEvent;
			  continue;
			}
		    }
		  else
		    DESTROY(currentEvent);
		}
	    }
	}
      else if (_mode != NSRadioModeMatrix)
        {
          // mouse is not over a Cell
	  if (_selectedCell != nil)
	    {
	      if ([_selectedCell state])
		{
		  [_selectedCell setState: NSOffState];
		  [self drawCell: _selectedCell];
		}

	      _selectedCells[_selectedRow][_selectedColumn] = NO;
	      _selectedCell = nil;
	      _selectedRow = _selectedColumn = -1;
	    }
        }

      // if mouse didn't go up, take next event
      if (!mouseUpInCell)
	{
	  theEvent = [NSApp nextEventMatchingMask: eventMask
			    untilDate: !scrolling || !currentEvent
			    ? [NSDate distantFuture]
			    : [NSDate dateWithTimeIntervalSinceNow: 0.05]
			    inMode: NSEventTrackingRunLoopMode
			    dequeue: YES];

	  if (scrolling && !theEvent)
	    theEvent = currentEvent;
	  else
	    DESTROY(currentEvent);
	}
    }

  RELEASE(currentEvent);

  // the mouse went up.
  // if it was inside a cell, the cell has already sent the action.
  // if not, _selectedCell is the last cell that had the mouse, and
  // it's state is Off. It must be set into a consistent state.
  // anyway, the action has to be sent
  if (!mouseUpInCell)
    {
      if (_mode != NSRadioModeMatrix)
	{
	  if (_selectedCell != nil)
	    {
	      _selectedCells[_selectedRow][_selectedColumn] = NO;
	      _selectedCell = nil;
	      _selectedRow = _selectedColumn = -1;
	    }
	}
      [self sendAction];
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
  id aCell, previousCell = nil;
  NSRect previousRect;
  NSApplication *app = [NSApplication sharedApplication];
  static MPoint anchor = {0, 0};
  int clickCount;

  /*
   * Pathological case -- ignore mouse down
   */
  if ((_numRows == 0) || (_numCols == 0))
    {
      [super mouseDown: theEvent];
      return; 
    }

  // Manage multi-click events
  clickCount = [theEvent clickCount];

  if (clickCount > 2)
    return;

  if (clickCount == 2 && (_ignoresMultiClick == NO))
    {
      [self sendDoubleAction];
      return;
    }

  // From now on, code to manage simple-click events

  lastLocation = [self convertPoint: lastLocation
		       fromView: nil];

  // If mouse down was on a selectable cell, start editing/selecting.
  if ([self getRow: &row
	    column: &column
	    forPoint: lastLocation])
    {
      if ([_cells[row][column] isEnabled])
	{
	  if ((_mode == NSRadioModeMatrix) && _selectedCell != nil)
	    {
	      [_selectedCell setState: NSOffState];
	      [self drawCellAtRow: _selectedRow column: _selectedColumn];
	      [_window flushWindow];
	      _selectedCells[_selectedRow][_selectedColumn] = NO;
	      _selectedCell = nil;
	      _selectedRow = _selectedColumn = -1;
	    }

	  if ([_cells[row][column] isSelectable])
	    {
	      NSText* t = [_window fieldEditor: YES forObject: self];

	      if ([t superview] != nil)
		{
		  if ([t resignFirstResponder] == NO)
		    {
		      if ([_window makeFirstResponder: _window] == NO)
			return;
		    }
		}
	      // During editing, the selected cell is the cell being edited
	      _selectedCell = _cells[row][column];
	      _selectedRow = row;
	      _selectedColumn = column;
	      if ([_cells[row][column] acceptsFirstResponder])
		{
		  _dottedRow = row;
		  _dottedColumn = column;
		}
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

  if (_mode != NSListModeMatrix)
    {
      [self _mouseDownNonListMode: theEvent];
      return;
    }

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
	  aCell = [self cellAtRow: row column: column];
	  rect = [self cellFrameAtRow: row column: column];

	  if (_autoscroll)
	    [self scrollRectToVisible: rect];

	  if (aCell != previousCell && [aCell isEnabled] == YES)
	    {
	      unsigned modifiers = [lastEvent modifierFlags];

	      // List mode allows multiple cells to be selected

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
		    [self _selectCell: aCell atRow: row column: column];
		}
	      else
		{
		  [self setSelectionFrom:
			  INDEX_FROM_COORDS(_selectedColumn, _selectedRow)
			to: INDEX_FROM_COORDS(column, row)
			anchor: INDEX_FROM_POINT(anchor)
			highlight: YES];
		}

	      [_window flushWindow];

	      previousCell = aCell;
	      previousRect = rect;
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

	    case NSLeftMouseUp:
	      done = YES;
	    case NSLeftMouseDown:
	    default:
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

  [self setNeedsDisplayInRect: rect];
  [_window flushWindow];

  [NSEvent stopPeriodicEvents];

  [self sendAction];
  
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

  for (i = 0; i < _numRows; i++)
    {
      int	j;

      for (j = 0; j < _numCols; j++)
	{
	  NSCell	*aCell = _cells[i][j];;

	  if ([aCell isEnabled]
	    && [[aCell keyEquivalent] isEqualToString: key])
	    {
	      NSCell *oldSelectedCell = _selectedCell;
	      int     oldSelectedRow = _selectedRow; 
	      int     oldSelectedColumn = _selectedColumn;

	      _selectedCell = aCell;
	      [self highlightCell: YES atRow: i column: j];
	      [aCell setNextState];
	      [self sendAction];
	      [self highlightCell: NO atRow: i column: j];
	      _selectedCell = oldSelectedCell;
	      _selectedRow = oldSelectedRow;
	      _selectedColumn = oldSelectedColumn;

	      return YES;
	    }
	}
    }

  return NO;
}

- (void) resetCursorRects
{
  int	i;

  for (i = 0; i < _numRows; i++)
    {
      int	j;

      for (j = 0; j < _numCols; j++)
	{
	  NSCell	*aCell = _cells[i][j];

	  [aCell resetCursorRect: [self cellFrameAtRow: i column: j]
		 inView: self];
	}
    }
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode (int) at: &_mode];
  [aCoder encodeValueOfObjCType: @encode (BOOL) at: &_allowsEmptySelection];
  [aCoder encodeValueOfObjCType: @encode (BOOL) at: &_selectionByRect];
  [aCoder encodeValueOfObjCType: @encode (BOOL) at: &_autosizesCells];
  [aCoder encodeValueOfObjCType: @encode (BOOL) at: &_autoscroll];
  [aCoder encodeSize: _cellSize];
  [aCoder encodeSize: _intercell];
  [aCoder encodeObject: _backgroundColor];
  [aCoder encodeObject: _cellBackgroundColor];
  [aCoder encodeValueOfObjCType: @encode (BOOL) at: &_drawsBackground];
  [aCoder encodeValueOfObjCType: @encode (BOOL) at: &_drawsCellBackground];
  [aCoder encodeObject: NSStringFromClass (_cellClass)];
  [aCoder encodeObject: _cellPrototype];
  [aCoder encodeValueOfObjCType: @encode (int) at: &_numRows];
  [aCoder encodeValueOfObjCType: @encode (int) at: &_numCols];
  
  /* This is slower, but does not expose NSMatrix internals and will work 
     with subclasses */
  [aCoder encodeObject: [self cells]];
  
  [aCoder encodeConditionalObject: _delegate];
  [aCoder encodeConditionalObject: _target];
  [aCoder encodeValueOfObjCType: @encode (SEL) at: &_action];
  [aCoder encodeValueOfObjCType: @encode (SEL) at: &_doubleAction];
  [aCoder encodeValueOfObjCType: @encode (SEL) at: &_errorAction];
  [aCoder encodeValueOfObjCType: @encode (BOOL) at: &_tabKeyTraversesCells];
  [aCoder encodeObject: _keyCell];
  /* We do not encode information on selected cells, because this is saved 
     with the cells themselves */
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  Class class;
  id cell;
  int rows, columns;
  NSArray *array;
  int i, count;

  [super initWithCoder: aDecoder];

  _myZone = [self zone];
  [aDecoder decodeValueOfObjCType: @encode (int) at: &_mode];
  [aDecoder decodeValueOfObjCType: @encode (BOOL) at: &_allowsEmptySelection];
  [aDecoder decodeValueOfObjCType: @encode (BOOL) at: &_selectionByRect];
  [aDecoder decodeValueOfObjCType: @encode (BOOL) at: &_autosizesCells];
  [aDecoder decodeValueOfObjCType: @encode (BOOL) at: &_autoscroll];
  _cellSize = [aDecoder decodeSize];
  _intercell = [aDecoder decodeSize];
  [aDecoder decodeValueOfObjCType: @encode (id) at: &_backgroundColor];
  [aDecoder decodeValueOfObjCType: @encode (id) at: &_cellBackgroundColor];
  [aDecoder decodeValueOfObjCType: @encode (BOOL) at: &_drawsBackground];
  [aDecoder decodeValueOfObjCType: @encode (BOOL) at: &_drawsCellBackground];

  class = NSClassFromString ((NSString *)[aDecoder decodeObject]);
  if (class != Nil)
    {
      [self setCellClass: class]; 
    }

  cell = [aDecoder decodeObject];
  if (cell != nil)
    {
      [self setPrototype: cell];
    }

  if (_cellPrototype == nil)
    {
      [self setCellClass: [isa cellClass]];
    }

  [aDecoder decodeValueOfObjCType: @encode (int) at: &rows];
  [aDecoder decodeValueOfObjCType: @encode (int) at: &columns];

  /* NB: This works without changes for NSForm */
  array = [aDecoder decodeObject];
  [self renewRows: rows  columns: columns];
  count = [array count];
  if (count != rows * columns)
    {
      NSLog (@"Trying to decode an invalid NSMatrix: cell number does not fit matrix dimension");
      // Quick fix to do what we can
      if (count > rows * columns)
	{
	  count = rows * columns;
	}
    }

  _selectedRow = _selectedColumn = 0;

  for (i = 0; i < count; i++)
    {
      int row, column;
      cell = [array objectAtIndex: i];

      row = i / columns;
      column = i % columns;
      
      [self putCell:cell   atRow: row   column: column];
      if ([cell state])
	 {
	   [self selectCellAtRow: row   column: column];
	 }
     }

  [aDecoder decodeValueOfObjCType: @encode (id) at: &_delegate];
  [aDecoder decodeValueOfObjCType: @encode (id) at: &_target];
  [aDecoder decodeValueOfObjCType: @encode (SEL) at: &_action];
  [aDecoder decodeValueOfObjCType: @encode (SEL) at: &_doubleAction];
  [aDecoder decodeValueOfObjCType: @encode (SEL) at: &_errorAction];
  [aDecoder decodeValueOfObjCType: @encode (BOOL) at: &_tabKeyTraversesCells];
  [self setKeyCell: [aDecoder decodeObject]];
  
  return self;
}

- (void) setMode: (NSMatrixMode)aMode
{
  _mode = aMode;
}

- (NSMatrixMode) mode
{
  return _mode;
}

- (void) setCellClass: (Class)class
{
  _cellClass = class;
  if (_cellClass == nil)
    {
      _cellClass = defaultCellClass;
    }
  _cellNew = [_cellClass methodForSelector: allocSel];
  _cellInit = [_cellClass instanceMethodForSelector: initSel];
  DESTROY(_cellPrototype);
}

- (Class) cellClass
{
  return _cellClass;
}

- (void) setPrototype: (NSCell*)aCell
{
  ASSIGN(_cellPrototype, aCell);
  if (_cellPrototype == nil)
    {
      [self setCellClass: defaultCellClass];
    }
  else
    {
      _cellNew = [_cellPrototype methodForSelector: copySel];
      _cellInit = 0;
      _cellClass = [aCell class];
    }
}

- (id) prototype
{
  return _cellPrototype;
}

- (NSSize) cellSize
{
  return _cellSize;
}

- (NSSize) intercellSpacing
{
  return _intercell;
}

- (void) setBackgroundColor: (NSColor*)c
{
  ASSIGN(_backgroundColor, c);
}

- (NSColor*) backgroundColor
{
  return _backgroundColor;
}

- (void) setCellBackgroundColor: (NSColor*)c
{
  ASSIGN(_cellBackgroundColor, c);
}

- (NSColor*) cellBackgroundColor
{
  return _cellBackgroundColor;
}

- (void) setDelegate: (id)object
{
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

// NB: In GNUstep the following method does *not* set 
// ignoresMultiClick to NO as in the MacOS-X spec. 
// It simply sets the doubleAction, as in OpenStep spec.
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
  _allowsEmptySelection = f;
}

- (BOOL) allowsEmptySelection
{
  return _allowsEmptySelection;
}

- (void) setSelectionByRect: (BOOL)flag
{
  _selectionByRect = flag;
}

- (BOOL) isSelectionByRect
{
  return _selectionByRect;
}

- (void) setDrawsBackground: (BOOL)flag
{
  _drawsBackground = flag;
}

- (BOOL) drawsBackground
{
  return _drawsBackground;
}

- (void) setDrawsCellBackground: (BOOL)f
{
  _drawsCellBackground = f;
}

- (BOOL) drawsCellBackground
{
  return _drawsCellBackground;
}

- (void) setAutosizesCells: (BOOL)flag
{
  _autosizesCells = flag;
}

- (BOOL) autosizesCells
{
  return _autosizesCells;
}

- (BOOL) isAutoscroll
{
  return _autoscroll;
}

- (int) numberOfRows
{
  return _numRows;
}

- (int) numberOfColumns
{
  return _numCols;
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
  NSSize oldBoundsSize = _bounds.size;
  NSSize newBoundsSize;
  NSSize change;
  int nc = _numCols;
  int nr = _numRows;

  [super resizeWithOldSuperviewSize: oldSize];

  newBoundsSize = _bounds.size;

  change.height = newBoundsSize.height - oldBoundsSize.height;
  change.width = newBoundsSize.width - oldBoundsSize.width;

  if (_autosizesCells)
    {
      if (change.height != 0)
	{
	  if (nr <= 0) nr = 1;
	  if (_cellSize.height == 0)
	    {
	      _cellSize.height = oldBoundsSize.height
		- ((nr - 1) * _intercell.height);
	      _cellSize.height = _cellSize.height / nr;
	    }
	  change.height = change.height / nr;
	  _cellSize.height += change.height;
	  if (_cellSize.height < 0)
	    _cellSize.height = 0;
	}
      if (change.width != 0)
	{
	  if (nc <= 0) nc = 1;
	  if (_cellSize.width == 0)
	    {
	      _cellSize.width = oldBoundsSize.width
		- ((nc - 1) * _intercell.width);
	      _cellSize.width = _cellSize.width / nc;
	    }
	  change.width = change.width / nc;
	  _cellSize.width += change.width;
	  if (_cellSize.width < 0)
	    _cellSize.width = 0;
	}
    }
  else // !autosizesCells
    {
      if (change.height != 0)
	{
	  if (nr > 1)
	    {
	      if (_intercell.height == 0)
		{
		  _intercell.height = oldBoundsSize.height - (nr * _cellSize.height);
		  _intercell.height = _intercell.height / (nr - 1);
		}
	      change.height = change.height / (nr - 1);
	      _intercell.height += change.height;
	      if (_intercell.height < 0)
		_intercell.height = 0;
	    }
	}
      if (change.width != 0)
	{
	  if (nc > 1)
	    {
	      if (_intercell.width == 0)
		{
		  _intercell.width = oldBoundsSize.width - (nc * _cellSize.width);
		  _intercell.width = _intercell.width / (nc - 1);
		}
	      change.width = change.width / (nc - 1);
	      _intercell.width += change.width;
	      if (_intercell.width < 0)
		_intercell.width = 0;
	    }
	}
    }
  [self setNeedsDisplay: YES];
}

- (void)_move:(unichar)pos
{
  BOOL selectCell = NO;
  int h, i, lastDottedRow, lastDottedColumn;

  if (_mode == NSRadioModeMatrix || _mode == NSListModeMatrix)
    selectCell = YES;

  if (_dottedRow == -1 || _dottedColumn == -1)
    {
      if (pos == NSUpArrowFunctionKey || pos == NSDownArrowFunctionKey)
	{
	  for (h = 0; h < _numCols; h++)
	    {
	      for (i = 0; i < _numRows; i++)
		{
		  if ([_cells[i][h] acceptsFirstResponder])
		    {
		      _dottedRow = i;
		      _dottedColumn = h;
		      break;
		    }
		}

	      if (i == _dottedRow)
		break;
	    }
	}
      else
	{
	  for (i = 0; i < _numRows; i++)
	    {
	      for (h = 0; h < _numCols; h++)
		{
		  if ([_cells[i][h] acceptsFirstResponder])
		    {
		      _dottedRow = i;
		      _dottedColumn = h;
		      break;
		    }
		}

	      if (h == _dottedColumn)
		break;
	    }
	}

      if (_dottedRow == -1 || _dottedColumn == -1)
	return;

      if (selectCell)
	{
	  if (_selectedCell)
	    {
	      if (_mode == NSRadioModeMatrix)
		{
		  NSCell *aCell = _selectedCell;

		  [aCell setState: NSOffState];
		  _selectedCells[_selectedRow][_selectedColumn] = NO;
		  _selectedRow = _selectedColumn = -1;
		  _selectedCell = nil;

		  [self drawCell: aCell];
		}
	      else
		[self deselectAllCells];
	    }

	  [self selectCellAtRow: _dottedRow column: _dottedColumn];
	}
      else
	[self drawCellAtRow: _dottedRow column: _dottedColumn];
    }
  else
    {
      lastDottedRow = _dottedRow;
      lastDottedColumn = _dottedColumn;

      if (pos == NSUpArrowFunctionKey)
	{
	  if (_dottedRow <= 0)
	    return;

	  for (i = _dottedRow-1; i >= 0; i--)
	    {
	      if ([_cells[i][_dottedColumn] acceptsFirstResponder])
		{
		  _dottedRow = i;
		  break;
		}
	    }
	}
      else if (pos == NSDownArrowFunctionKey)
	{
	  if (_dottedRow >= _numRows-1)
	    return;

	  for (i = _dottedRow+1; i < _numRows; i++)
	    {
	      if ([_cells[i][_dottedColumn] acceptsFirstResponder])
		{
		  _dottedRow = i;
		  break;
		}
	    }
	}
      else if (pos == NSLeftArrowFunctionKey)
	{
	  if (_dottedColumn <= 0)
	    return;

	  for (i = _dottedColumn-1; i >= 0; i--)
	    {
	      if ([_cells[_dottedRow][i] acceptsFirstResponder])
		{
		  _dottedColumn = i;
		  break;
		}
	    }
	}
      else
	{
	  if (_dottedColumn >= _numCols-1)
	    return;

	  for (i = _dottedColumn+1; i < _numCols; i++)
	    {
	      if ([_cells[_dottedRow][i] acceptsFirstResponder])
		{
		  _dottedColumn = i;
		  break;
		}
	    }
	}

      if ((pos == NSUpArrowFunctionKey || pos == NSDownArrowFunctionKey)
	  && _dottedRow != i)
	return;

      if ((pos == NSLeftArrowFunctionKey || pos == NSRightArrowFunctionKey)
	  && _dottedColumn != i)
	return;

      if (selectCell)
	{
	  if (_mode == NSRadioModeMatrix)
	    {
	      NSCell *aCell = _cells[lastDottedRow][lastDottedColumn];
	      BOOL    isHighlighted = [aCell isHighlighted];

	      if ([aCell state] || isHighlighted)
		{
		  [aCell setState: NSOffState];
		  _selectedCells[lastDottedRow][lastDottedColumn] = NO;
		  _selectedRow = _selectedColumn = -1;
		  _selectedCell = nil;

		  if (isHighlighted)
		    [self highlightCell: NO
			  atRow: lastDottedRow
			  column: lastDottedColumn];
		  else
		    [self drawCell: aCell];
		}
	    }
	  else
	    [self deselectAllCells];

	  [self selectCellAtRow: _dottedRow column: _dottedColumn];
	}
      else
	{
	  [self drawCell: _cells[lastDottedRow][lastDottedColumn]];
	  [self drawCell: _cells[_dottedRow][_dottedColumn]];
	}
    }

  [_window flushWindow];

  if (selectCell)
    {
      [self performClick: self];
      [_window flushWindow];
    }
}

- (void)moveUp:(id)sender
{
  [self _move: NSUpArrowFunctionKey];
}

- (void)moveDown:(id)sender
{
  [self _move: NSDownArrowFunctionKey];
}

- (void)moveLeft:(id)sender
{
  [self _move: NSLeftArrowFunctionKey];
}

- (void)moveRight:(id)sender
{
  [self _move: NSRightArrowFunctionKey];
}

- (void) _shiftModifier:(unichar)character
{
  int i, lastDottedRow, lastDottedColumn;

  lastDottedRow = _dottedRow;
  lastDottedColumn = _dottedColumn;

  if (character == NSUpArrowFunctionKey)
    {
      if (_dottedRow <= 0)
	return;

      for (i = _dottedRow-1; i >= 0; i--)
	{
	  if ([_cells[i][_dottedColumn] acceptsFirstResponder])
	    {
	      _dottedRow = i;
	      break;
	    }
	}

      if (_dottedRow != i)
	return;
    }
  else if (character == NSDownArrowFunctionKey)
    {
      if (_dottedRow < 0 || _dottedRow >= _numRows-1)
	return;

      for (i = _dottedRow+1; i < _numRows; i++)
	{
	  if ([_cells[i][_dottedColumn] acceptsFirstResponder])
	    {
	      _dottedRow = i;
	      break;
	    }
	}
    }
  else if (character == NSLeftArrowFunctionKey)
    {
      if (_dottedColumn <= 0)
	return;

      for (i = _dottedColumn-1; i >= 0; i--)
	{
	  if ([_cells[_dottedRow][i] acceptsFirstResponder])
	    {
	      _dottedColumn = i;
	      break;
	    }
	}
    }
  else
    {
      if (_dottedColumn < 0 || _dottedColumn >= _numCols-1)
	return;

      for (i = _dottedColumn+1; i < _numCols; i++)
	{
	  if ([_cells[_dottedRow][i] acceptsFirstResponder])
	    {
	      _dottedColumn = i;
	      break;
	    }
	}
    }

  [self drawCell: _cells[lastDottedRow][_dottedColumn]];
  [self drawCell: _cells[_dottedRow][_dottedColumn]];
  [_window flushWindow];

  [self performClick: self];
}

- (void) _altModifier:(unichar)character
{
  switch (character)
    {
    case NSUpArrowFunctionKey:
      if (_dottedRow <= 0)
	return;

      _dottedRow--;
      break;

    case NSDownArrowFunctionKey:
      if (_dottedRow < 0 || _dottedRow >= _numRows-1)
	return;

      _dottedRow++;
      break;

    case NSLeftArrowFunctionKey:
      if (_dottedColumn <= 0)
	return;

      _dottedColumn--;
      break;

    case NSRightArrowFunctionKey:
      if (_dottedColumn < 0 || _dottedColumn >= _numCols-1)
	return;

      _dottedColumn++;
      break;
    }

  [self setSelectionFrom:
	  INDEX_FROM_COORDS(_selectedRow, _selectedColumn)
	to: INDEX_FROM_COORDS(_dottedRow, _dottedColumn)
	anchor: INDEX_FROM_COORDS(_selectedRow, _selectedColumn)
	highlight: YES];

  [self performClick: self];
}

- (void) keyDown: (NSEvent *)theEvent
{
  NSString *characters = [theEvent characters];
  unsigned modifiers = [theEvent modifierFlags];
  unichar  character = 0;

  if ([characters length] > 0)
    {
      character = [characters characterAtIndex: 0];
    }

  switch (character)
    {
    case NSCarriageReturnCharacter:
    case NSNewlineCharacter:
    case NSEnterCharacter: 
      [self selectText: self];
      break;

    case ' ':
      if (_dottedRow != -1 && _dottedColumn != -1)
	{
	  if (modifiers & NSAlternateKeyMask)
	    [self _altModifier: character];
	  else
	    {
	      NSCell *cell;

	      switch (_mode)
		{
		case NSTrackModeMatrix:
		case NSHighlightModeMatrix:
		  cell = _cells[_dottedRow][_dottedColumn];

		  [cell setNextState];
		  [self drawCell: cell];
		  break;

		case NSListModeMatrix:
		  if (!(modifiers & NSShiftKeyMask))
		    [self deselectAllCells];

		case NSRadioModeMatrix:
		  [self selectCellAtRow: _dottedRow column: _dottedColumn];
		  break;
		}

	      [_window flushWindow];
	      [self performClick: self];
	    }
	  return;
	}
      break;

    case NSLeftArrowFunctionKey:
    case NSRightArrowFunctionKey:
      if (_numCols <= 1)
	break;

    case NSUpArrowFunctionKey:
    case NSDownArrowFunctionKey:
      if (modifiers & NSShiftKeyMask)
	[self _shiftModifier: character];
      else if (modifiers & NSAlternateKeyMask)
	[self _altModifier: character];
      else
	{
	  if (character == NSUpArrowFunctionKey)
	    [self moveUp: self];
	  else if (character == NSDownArrowFunctionKey)
	    [self moveDown: self];
	  else if (character == NSLeftArrowFunctionKey)
	    [self moveLeft: self];
	  else
	    [self moveRight: self];
	}
      return;

    case NSTabCharacter:
      if (_tabKeyTraversesCells)
	{
	  if ([theEvent modifierFlags] & NSShiftKeyMask)
	    {
	      if([self _selectNextSelectableCellAfterRow: _selectedRow
		       column: _selectedColumn])
		return;
	    }
	  else
	    {
	      if([self _selectPreviousSelectableCellBeforeRow: _selectedRow
		       column: _selectedColumn])
		return;
	    }
	}
      break;

    default:
      break;
    }

  [super keyDown: theEvent];
}

- (void) performClick: (id)sender
{
  [super sendAction: _action to: _target];
}

- (BOOL) acceptsFirstResponder
{
  // We gratefully accept keyboard events.
  return YES;
}

- (void) _setNeedsDisplayDottedCell
{
  if (_dottedRow != -1 && _dottedColumn != -1)
    {
      [self setNeedsDisplayInRect: [self cellFrameAtRow: _dottedRow
					 column: _dottedColumn]];
    }
}

- (BOOL) becomeFirstResponder
{
  [self _setNeedsDisplayDottedCell];

  return YES;
}

- (BOOL) resignFirstResponder
{
  [self _setNeedsDisplayDottedCell];

  return YES;
}

- (void) becomeKeyWindow
{
  [self _setNeedsDisplayDottedCell];
}

- (void) resignKeyWindow
{
  [self _setNeedsDisplayDottedCell];
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
  if (_textObject && ([_window firstResponder] == _textObject))
    return _textObject;
  else
    return nil;
}

- (void) validateEditing
{
   if (_textObject)
    {
      NSFormatter *formatter;
      NSString *string;

      formatter = [_selectedCell formatter];
      string = [_textObject text];

      if (formatter == nil)
	{
	  [_selectedCell setStringValue: string];
	}
      else
	{
	  id newObjectValue;
	  NSString *error;
 
	  if ([formatter getObjectValue: &newObjectValue 
			 forString: string 
			 errorDescription: &error] == YES)
	    {
	      [_selectedCell setObjectValue: newObjectValue];
	    }
	  else
	    {
	      if ([_delegate control: self 
			     didFailToFormatString: string 
			     errorDescription: error] == YES)
		{
		  [_selectedCell setStringValue: string];
		}
	      
	    }
	}
    }
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

//NSLog(@"%x - mr: %d mc:%d nr:%d nc:%d r:%d c:%d", (unsigned)self, _maxRows, _maxCols, _numRows, _numCols, row, col);
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
  oldMaxC = _maxCols;
  _numCols = col;
  if (col > _maxCols)
    _maxCols = col;
  oldMaxR = _maxRows;
  _numRows = row;
  if (row > _maxRows)
    _maxRows = row;

  if (col > oldMaxC)
    {
      int	end = col - 1;

      for (i = 0; i < oldMaxR; i++)
	{
	  _cells[i] = NSZoneRealloc(_myZone, _cells[i], col * sizeof(id));
	  _selectedCells[i] = NSZoneRealloc(GSAtomicMallocZone(),
	    _selectedCells[i], col * sizeof(BOOL));

	  for (j = oldMaxC; j < col; j++)
	    {
	      _cells[i][j] = nil;
	      _selectedCells[i][j] = NO;
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

      _cells = NSZoneRealloc(_myZone, _cells, row * sizeof(id*));
      _selectedCells = NSZoneRealloc(_myZone, _selectedCells, row * sizeof(BOOL*));

      /* Allocate the new rows and fill them */
      for (i = oldMaxR; i < row; i++)
	{
	  _cells[i] = NSZoneMalloc(_myZone, col * sizeof(id));
	  _selectedCells[i] = NSZoneMalloc(GSAtomicMallocZone(),
	    col * sizeof(BOOL));

	  if (i == end)
	    {
	      for (j = 0; j < col; j++)
		{
		  _cells[i][j] = nil;
		  _selectedCells[i][j] = NO;
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
		  _cells[i][j] = nil;
		  _selectedCells[i][j] = NO;
		  (*mkImp)(self, mkSel, i, j);
		}
	    }
	}
    }

  [self deselectAllCells];
//NSLog(@"%x - end mr: %d mc:%d nr:%d nc:%d r:%d c:%d", (unsigned)self, _maxRows, _maxCols, _numRows, _numCols, row, col);
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

      if (_selectionByRect || i == endPoint.y)
	colLimit = endPoint.x;
      else
	colLimit = _numCols - 1;

      for (; j <= colLimit; j++)
	{
	  NSCell	*aCell = _cells[i][j];

	  [aCell setState: state];

	  if (state == NSOffState)
	    _selectedCells[i][j] = NO;
	  else
	    _selectedCells[i][j] = YES;

	  [aCell setCellAttribute: NSCellHighlighted to: highlight];
	  [self drawCell: aCell];
	}
    }

  [_window flushWindow];
}

// Return YES on success; NO if no selectable cell found.
-(BOOL) _selectNextSelectableCellAfterRow: (int)row
				   column: (int)column
{
  int i,j;
  if (row > -1)
    {
      // First look for cells in the same row
      for (j = column + 1; j < _numCols; j++)
	{
	  if ([_cells[row][j] isEnabled] && [_cells[row][j] isSelectable])
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
  for (i = row + 1; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  if ([_cells[i][j] isEnabled] && [_cells[i][j] isSelectable])
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
  if (row < _numRows)
    {
      // First look for cells in the same row
      for (j = column - 1; j > -1; j--)
	{
	  if ([_cells[row][j] isEnabled] && [_cells[row][j] isSelectable])
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
      for (j = _numCols - 1; j > -1; j--)
	{
	  if ([_cells[i][j] isEnabled] && [_cells[i][j] isSelectable])
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
