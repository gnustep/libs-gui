/** <title>NSMatrix</title>

   <abstract>Matrix class for grouping controls</abstract>

   Copyright (C) 1996, 1997, 1999 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   A completely rewritten version of the original source by Pascal Forget and
   Scott Christley.
   Modified: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Cell handling rewritten: Richard Frith-Macdonald <richard@brainstorm.co.uk>
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

/* Mouse Tracking Notes:

   The behaviour of mouse tracking is a bit different on OS42 and MaxOSX. The 
   implementation here reflects OS42 more closely (as the original code
   in NSMatrix). Examples of differences:
   - highlighting of NSButtonCells is different;
   - OS42 makes each cell under the cursor track the mouse, MacOSX makes only
     the clicked cell track it, untilMouseUp;
   - if mouse goes up outside of a cell, OS42 sends the action, MacOSX does not
   - keys used for selection in list mode are not the same (shift and alternate
     on OS42, command and shift on MacOSX).
*/

#include "config.h"
#include <stdlib.h>

#include <Foundation/NSValue.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSFormatter.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSString.h>
#include <Foundation/NSZone.h>

#include "AppKit/NSColor.h"
#include "AppKit/NSCursor.h"
#include "AppKit/NSActionCell.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSMatrix.h"

#include <math.h>

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
    ({MPoint point = { (index) % _numCols, (index) / _numCols }; point; })

#define INDEX_FROM_COORDS(x,y) \
    ((y) * _numCols + (x))
#define INDEX_FROM_POINT(point) \
    ((point).y * _numCols + (point).x)


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
- (BOOL) _selectNextSelectableCellAfterRow: (int)row
				    column: (int)column;
- (BOOL) _selectPreviousSelectableCellBeforeRow: (int)row
					 column: (int)column;
- (void) _drawCellAtRow: (int)row 
                 column: (int)column;
- (void) _setKeyRow: (int) row
             column: (int) column;
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
  if ((_numCols > 0) && (_numRows > 0))
    {
      /* 
	 We must not round the _cellSize to integers here!
	 
	 Any approximation is a loss of information.  We should give
	 to the backend as much information as possible, and trust
	 that it will use that information to provide the best
	 possible rendering on that device.  Depending on the backend,
	 that might go up to using antialias or advanced graphics
	 tricks to make an advanced rendering of things not lying on
	 pixel boundaries.  Approximating here just gives less
	 information to the backend, making the rendering worse.
	 
	 Even if the backend is just approximating to pixels, it would
	 still be wrong to round _cellSize here, because rounding
	 sizes of rectangles without considering the origin of the
	 rectangles has been definitely found to be wrong and to cause
	 incorrect rendering.  The origin of the whole matrix is very
	 likely a non-integer - if not originally, as a consequence of
	 the fact that the user resized the window - so making the
	 cell size integer does not cause drawing to be done on pixel
	 boundaries anyway, and will actually make more difficult for
	 the backend to render the rectangles properly since it will
	 be drawing approximately rectangles which are already only an
	 approximate description - and this first approximation having
	 been done incorrectly too! - of what we really want to draw.
      */

      _cellSize = NSMakeSize (frameRect.size.width/_numCols,
			      frameRect.size.height/_numRows);
    }
  else
    {
      _cellSize = NSMakeSize (DEFAULT_CELL_WIDTH, DEFAULT_CELL_HEIGHT);
    }

  _intercell = NSMakeSize(1, 1);
  [self setAutosizesCells: YES];
  [self setFrame: frameRect];

  _tabKeyTraversesCells = YES;
  [self setBackgroundColor: [NSColor controlBackgroundColor]];
  [self setDrawsBackground: YES];
  [self setCellBackgroundColor: [NSColor controlBackgroundColor]];
  [self setSelectionByRect: YES];
  _dottedRow = _dottedColumn = -1;
  if (_mode == NSRadioModeMatrix && _numRows > 0 && _numCols > 0)
    {
      [self selectCellAtRow: 0 column: 0];
    }
  else
    {
      _selectedCell = nil;
      _selectedRow = _selectedColumn = -1;
    }
  return self;
}

- (id) initWithFrame: (NSRect)frameRect
	        mode: (int)aMode
	   cellClass: (Class)classId
        numberOfRows: (int)rowsHigh
     numberOfColumns: (int)colsWide
{
  self = [super initWithFrame: frameRect];

  [self setCellClass: classId];
  return [self _privateFrame: frameRect
		        mode: aMode
		numberOfRows: rowsHigh
	     numberOfColumns: colsWide];
}

- (id) initWithFrame: (NSRect)frameRect
	        mode: (int)aMode
	   prototype: (NSCell*)aCell
        numberOfRows: (int)rowsHigh
     numberOfColumns: (int)colsWide
{
  self = [super initWithFrame: frameRect];

  [self setPrototype: aCell];
  return [self _privateFrame: frameRect
		        mode: aMode
		numberOfRows: rowsHigh
	     numberOfColumns: colsWide];
}

- (void) dealloc
{
  int		i;

  if (_textObject != nil)
    {
      [_selectedCell endEditing: _textObject];
      _textObject = nil;
    }

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

  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
      _delegate = nil;
    }

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
	{
	  _selectedColumn++;
	}
      if (_dottedColumn >= column)
	{
	  _dottedColumn++;
	}
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

  if (_mode == NSRadioModeMatrix && _allowsEmptySelection == NO
    && _selectedCell == nil)
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
    {
      [self selectCellAtRow: 0 column: 0];
    }
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
    {
      rect.origin.y = row * (_cellSize.height + _intercell.height);
    }
  else
    {
      rect.origin.y = (_numRows - row - 1)
	* (_cellSize.height + _intercell.height);
    }
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
    {
      _selectedCell = newCell;
    }
  
  ASSIGN(_cells[row][column], newCell);

  [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
}

- (void) removeColumn: (int)column
{
  if (column >= 0 && column < _numCols)
    {
      int i;

      for (i = 0; i < _maxRows; i++)
	{
	  int	j;

	  AUTORELEASE(_cells[i][column]);
	  for (j = column + 1; j < _maxCols; j++)
	    {
	      _cells[i][j-1] = _cells[i][j];
	      _selectedCells[i][j-1] = _selectedCells[i][j];
	    }
	}
      _numCols--;
      _maxCols--;

      if (column == _selectedColumn)
	{
	  _selectedCell = nil;
	  [self selectCellAtRow: _selectedRow column: 0];
	}
      if (column == _dottedColumn)
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
      NSLog(@"remove non-existent column (%d) from matrix", column);
#else
      [NSException raise: NSRangeException
	format: @"remove non-existent column (%d) from matrix", column];
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

- (void) renewRows: (int)newRows
	   columns: (int)newColumns
{
  [self _renewRows: newRows columns: newColumns rowSpace: 0 colSpace: 0];
}

- (void) setCellSize: (NSSize)aSize
{
  _cellSize = aSize;
  [self sizeToCells];
}

- (void) setIntercellSpacing: (NSSize)aSize
{
  _intercell = aSize;
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
       forPoint: (NSPoint)aPoint
{
  BOOL	betweenRows;
  BOOL	betweenCols;
  BOOL	beyondRows;
  BOOL	beyondCols;
  int	approxRow = aPoint.y / (_cellSize.height + _intercell.height);
  float	approxRowsHeight = approxRow * (_cellSize.height + _intercell.height);
  int	approxCol = aPoint.x / (_cellSize.width + _intercell.width);
  float	approxColsWidth = approxCol * (_cellSize.width + _intercell.width);

  /* First check the limit cases - is the point outside the matrix */
  beyondCols = (aPoint.x > _bounds.size.width  || aPoint.x < 0);
  beyondRows = (aPoint.y > _bounds.size.height || aPoint.y < 0);

  /* Determine if the point is inside a cell - note: if the point lies
     on the cell boundaries, we consider it inside the cell.  to be
     outside the cell (that is, in the intercell spacing) it must be
     completely in the intercell spacing - not on the border */
  /* The following is non zero if the point lies between rows (not inside 
     a cell) */
  betweenRows = (aPoint.y < approxRowsHeight
    || aPoint.y > approxRowsHeight + _cellSize.height);
  betweenCols = (aPoint.x < approxColsWidth
    || aPoint.x > approxColsWidth + _cellSize.width);

  if (beyondRows || betweenRows || beyondCols || betweenCols
    || (_numCols == 0) || (_numRows == 0))
    {
      if (row)
	{
	  *row = -1;
	}

      if (column)
	{
	  *column = -1;
	}
      
      return NO;
    }

  if (row)
    {
      if (_rFlags.flipped_view == NO)
	{
	  approxRow = _numRows - approxRow - 1;
	}
      
      if (approxRow < 0)
	{
	  approxRow = 0;
	}
      else if (approxRow >= _numRows)
	{
	  approxRow = _numRows - 1;
	}
      *row = approxRow;
    }

  if (column)
    {
      if (approxCol < 0)
	{
	  approxCol = 0;
	}
      else if (approxCol >= _numCols)
	{
	  approxCol = _numCols - 1;
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

	  [_selectedCell setState: value];
	  _selectedCells[row][column] = YES;

          [self _setKeyRow: row column: column];
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
		    {
		      [aCell setHighlighted: NO];
		    }
		  [self setNeedsDisplayInRect: [self cellFrameAtRow: i
						     column: j]];
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

  if (!_selectedCell
    || (!_allowsEmptySelection && (_mode == NSRadioModeMatrix)))
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
  int i, j;

  /* Can't select all if only one can be selected.  */
  if (_mode == NSRadioModeMatrix)
    {
      return;
    }

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
  if (aCell)
    {
      NSRect cellFrame;

      if (_selectedCell && _selectedCell != aCell)
	{
          if (_mode == NSRadioModeMatrix)
            {
              _selectedCells[_selectedRow][_selectedColumn] = NO;
              [_selectedCell setState: NSOffState];
            }
	  [self setNeedsDisplayInRect: [self cellFrameAtRow: _selectedRow
					     column: _selectedColumn]];
	}

      _selectedCell = aCell;
      _selectedRow = row;
      _selectedColumn = column;
      _selectedCells[row][column] = YES;

      [_selectedCell setState: NSOnState];

      if (_mode == NSListModeMatrix)
	[aCell setHighlighted: YES];

      cellFrame = [self cellFrameAtRow: row column: column];
      if (_autoscroll)
	[self scrollRectToVisible: cellFrame];

      [self setNeedsDisplayInRect: cellFrame];

      [self _setKeyRow: row column: column];
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
    {
      [self _selectCell: aCell atRow: row column: column];

      // Note: we select the cell iff it is 'selectable', not 'editable' 
      // as macosx says.  This looks definitely more appropriate. 
      // [This is going to start editing only if the cell is also editable,
      // otherwise the text gets selected and that's all.]
      [self selectTextAtRow: row column: column];
    }
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
    {
      [self _selectCell: aCell atRow: row column: column];
      [self selectTextAtRow: row column: column];
    }
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
	      [self selectTextAtRow: i column: j];
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
  /* Cells are selected from the anchor (A) to the point where the mouse
   * went down (S) and then they are selected (if the mouse moves away from A)
   * or deselected (if the mouse moves closer to A) until the point 
   * where the mouse goes up (E).
   * This is inverted if flag is false (not sure about this though; if this is
   * changed, mouse tracking in list mode should be changed too).
   */
  /* An easy way of doing this is unselecting all cells from A to S and then
   * selecting all cells from A to E. Let's try to do it in a more optimized
   * way..
   */
  /* Linear and rectangular selections are a bit different */
  if (![self isSelectionByRect]
      || [self numberOfRows] == 1 || [self numberOfColumns] == 1)
    {
      /* Linear selection
       * There are three possibilities (ignoring direction):
       *    A    S    E 
       *    sssssssssss
       *
       *    A    E    S
       *    ssssssuuuuu
       *
       *    E    A    S
       *    ssssssuuuuu
       *
       * So, cells from A to E are selected and, if S is outside the
       * range from A to E, cells from S to its closest point are unselected
       */
      int selStart = MIN(anchorPos, endPos);
      int selEnd = MAX(anchorPos, endPos);
      [self _setState: flag ? NSOnState : NSOffState
	    highlight: flag
	    startIndex: selStart
	    endIndex: selEnd];
      if (startPos > selEnd)
        {
          [self _setState: flag ? NSOffState : NSOnState
	        highlight: !flag
	        startIndex: selEnd+1
	        endIndex: startPos];
        }
      else if (startPos < selStart)
        {
          [self _setState: flag ? NSOffState : NSOnState
	        highlight: !flag
	        startIndex: startPos
	        endIndex: selStart-1];
        }
    }
  else
    {
      /* Rectangular selection
       *
       *   A     sss
       *    S    sss
       *     E   sss
       *
       *   A     ssu
       *    E    ssu
       *     S   uuu
       *
       *   E     ss 
       *    A    ssu
       *     S    uu
       *
       *   A     ssu
       *     S   ssu
       *    E    ss
       *
       * So, cells of the rect from A to E are selected and cells of the
       * rect from A to S that are outside the first rect are unselected
       */
      MPoint anchorPoint = POINT_FROM_INDEX(anchorPos);
      MPoint endPoint = POINT_FROM_INDEX(endPos);
      MPoint startPoint = POINT_FROM_INDEX(startPos);
      int minx_AE = MIN(anchorPoint.x, endPoint.x);
      int miny_AE = MIN(anchorPoint.y, endPoint.y);
      int maxx_AE = MAX(anchorPoint.x, endPoint.x);
      int maxy_AE = MAX(anchorPoint.y, endPoint.y);
      int minx_AS = MIN(anchorPoint.x, startPoint.x);
      int miny_AS = MIN(anchorPoint.y, startPoint.y);
      int maxx_AS = MAX(anchorPoint.x, startPoint.x);
      int maxy_AS = MAX(anchorPoint.y, startPoint.y);
      
      [self _setState: flag ? NSOnState : NSOffState
	    highlight: flag
	    startIndex: INDEX_FROM_COORDS(minx_AE, miny_AE)
	    endIndex: INDEX_FROM_COORDS(maxx_AE, maxy_AE)];
      if (startPoint.x > maxx_AE)
        {
          [self _setState: flag ? NSOffState : NSOnState
	        highlight: !flag
	        startIndex: INDEX_FROM_COORDS(maxx_AE+1, miny_AS)
	        endIndex: INDEX_FROM_COORDS(startPoint.x, maxy_AS)];
        }
      else if (startPoint.x < minx_AE)
        {
          [self _setState: flag ? NSOffState : NSOnState
	        highlight: !flag
	        startIndex: INDEX_FROM_COORDS(startPoint.x, miny_AS)
	        endIndex: INDEX_FROM_COORDS(minx_AE-1, maxy_AS)];
        }
      if (startPoint.y > maxy_AE)
        {
          [self _setState: flag ? NSOffState : NSOnState
	        highlight: !flag
	        startIndex: INDEX_FROM_COORDS(minx_AS, maxy_AE+1)
	        endIndex: INDEX_FROM_COORDS(maxx_AS, startPoint.y)];
        }
      else if (startPoint.y < miny_AE)
        {
          [self _setState: flag ? NSOffState : NSOnState
	        highlight: !flag
	        startIndex: INDEX_FROM_COORDS(minx_AS, startPoint.y)
	        endIndex: INDEX_FROM_COORDS(maxx_AS, miny_AE-1)];
        }
    }

  /*
  Update the _selectedCell and related ivars. This could be optimized a lot
  in many cases, but the full search cannot be avoided in the general case,
  and being correct comes first.
  */
  {
    int i, j;
    for (i = _numRows - 1; i >= 0; i--)
      {
	for (j = _numCols - 1; j >= 0; j--)
	  {
	    if (_selectedCells[i][j])
	      {
		_selectedCell = _cells[i][j];
		_selectedRow = i;
		_selectedColumn = j;
		return;
	      }
	  }
      }
    _selectedCell = nil;
    _selectedColumn = -1;
    _selectedRow = -1;
  }
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
	  if (_dottedRow != -1)
	    {
              [self selectTextAtRow: _dottedRow  column: _dottedColumn];
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

    [self _selectCell: _cells[row][column] atRow: row column: column];

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
  if (_dottedRow == -1 || _dottedColumn == -1)
    {
      return nil;
    }
  else if(_cells != 0)
    {
      return _cells[_dottedRow][_dottedColumn];
    }

  return nil;
}

- (void) setKeyCell: (NSCell *)aCell 
{
  BOOL isValid;
  int row, column;

  isValid = [self getRow: &row  column: &column  ofCell: aCell];

  if (isValid == YES)
    {
      [self _setKeyRow: row column: column];
    }
}

- (id) nextText
{
  return [self nextKeyView];
}

- (id) previousText
{
  return [self previousKeyView];
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

  [_selectedCell endEditing: [aNotification object]];
  _textObject = nil;

  d = [[NSMutableDictionary alloc] initWithDictionary: 
				     [aNotification userInfo]];
  AUTORELEASE (d);
  [d setObject: [aNotification object] forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidEndEditingNotification
      object: self
      userInfo: d];

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

- (BOOL) textShouldBeginEditing: (NSText*)aTextObject
{
  if (_delegate && [_delegate respondsToSelector:
    @selector(control:textShouldBeginEditing:)])
    {
      return [_delegate control: self
	 textShouldBeginEditing: aTextObject];
    }
  return YES;
}

- (BOOL) textShouldEndEditing: (NSText *)aTextObject
{
  if ([_selectedCell isEntryAcceptable: [aTextObject text]] == NO)
    {
      [self sendAction: _errorAction to: _target];
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
  [super setFrameSize: newSize];
}
  
- (void) sizeToFit
{
  /*
   * A simple explanation of the logic behind this method.
   *
   * Example of when you would like to use this method:
   * you have a matrix containing radio buttons.  Say that you have the 
   * following radio buttons - 
   *
   * * First option
   * * Second option
   * * Third option
   * * No thanks, no option for me
   *
   * this method should size the matrix so that it can comfortably
   * show all the cells it contains.  To do it, we must consider that
   * all the cells should be given the same size, yet some cells need
   * more space than the others to show their contents, so we need to
   * choose the cell size as to be enough to display every cell.  We
   * loop on all cells, call cellSize on each (which returns the
   * *minimum* comfortable size to display that cell), and choose a
   * final cellSize which is enough big to be bigger than all these
   * cellSizes.  We resize the matrix to have that cellSize, and
   * that's it.  */
  NSSize newSize = NSZeroSize;

  int i, j;

  for (i = 0; i < _numRows; i++)
    {
      for (j = 0; j < _numCols; j++)
	{
	  NSSize tempSize = [_cells[i][j] cellSize];
	  tempSize.height = ceil(tempSize.height);
	  tempSize.width = ceil(tempSize.width);
	  if (tempSize.width > newSize.width)
	    {
	      newSize.width = tempSize.width;
	    }
	  if (tempSize.height > newSize.height)
	    {
	      newSize.height = tempSize.height;
	    }
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
  else if (row2 >= _numRows)
    row2 = _numRows - 1;

  if (col2 < 0)
    col2 = 0;
  else if (col2 >= _numCols)
    col2 = _numCols - 1;

  /* Draw the cells within the drawing rectangle. */
  for (i = row1; i <= row2 && i < _numRows; i++)
    for (j = col1; j <= col2 && j < _numCols; j++)
      {
	[self _drawCellAtRow: i column: j];
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

      if (!_drawsBackground)
	{
          // the matrix is not opaque, we call displayRect: so 
          // that our opaque ancestor is redrawn
	  [self displayRect: cellFrame];
	  return;
	}
      
      if (_drawsCellBackground)
	{
	  [_cellBackgroundColor set];
	  NSRectFill(cellFrame);
	}
      else
	{
	  [_backgroundColor set];
	  NSRectFill(cellFrame);
	}
      
      if (_dottedRow == row
          && _dottedColumn == column
	  && [aCell acceptsFirstResponder]
          && [_window isKeyWindow]
	  && [_window firstResponder] == self)
	{
	  [aCell setShowsFirstResponder: YES];
          [aCell drawWithFrame: cellFrame inView: self];
          [aCell setShowsFirstResponder: NO];
	}
      else
	{
	  [aCell setShowsFirstResponder: NO];
          [aCell drawWithFrame: cellFrame inView: self];
	}
    }
}

- (void) highlightCell: (BOOL)flag atRow: (int)row column: (int)column
{
  NSCell	*aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      [aCell setHighlighted: flag];
      [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
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
  BOOL mouseUpInCell = NO, onCell, scrolling = NO, mouseUp = NO;
  NSCell *mouseCell;
  int mouseRow;
  int mouseColumn;
  NSPoint mouseLocation;
  NSRect mouseCellFrame;
  NSCell *originallySelectedCell = _selectedCell;
  unsigned eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
                     | NSMouseMovedMask  | NSLeftMouseDraggedMask;

  while (!mouseUp)
    {
      mouseLocation = [self convertPoint: [theEvent locationInWindow]
                                fromView: nil];

      onCell = [self getRow: &mouseRow
		     column: &mouseColumn
		     forPoint: mouseLocation];

      if (onCell)
	{
	  mouseCellFrame = [self cellFrameAtRow: mouseRow column: mouseColumn];
	  mouseCell = [self cellAtRow: mouseRow column: mouseColumn];

	  if (_autoscroll)
            {
	      scrolling = [self scrollRectToVisible: mouseCellFrame];
            }

	  if ([mouseCell isEnabled])
	    {	      
              int old_state;
              
              /* Select the cell before tracking. The cell can send its action
               * during tracking, and the target discovers which cell was
               * clicked calling selectedCell.
               * The cell calls -nextState before sending the action, so its
               * state should not be changed here (except in radio mode).
               */
              old_state = [mouseCell state];
              [self _selectCell: mouseCell atRow: mouseRow column: mouseColumn];
              if (_mode == NSRadioModeMatrix && !_allowsEmptySelection)
                {
                  [mouseCell setState: NSOffState];
                }
              else
                {
                  [mouseCell setState: old_state];
                }
              
	      if (_mode != NSTrackModeMatrix)
		{
		  [self highlightCell: YES
			atRow: mouseRow
			column: mouseColumn];
		}

	      mouseUpInCell = [mouseCell trackMouse: theEvent
                                         inRect: mouseCellFrame
                                         ofView: self
					 untilMouseUp:
					   [[mouseCell class]
					     prefersTrackingUntilMouseUp]];

	      if (_mode != NSTrackModeMatrix)
		{
		  [self highlightCell: NO
			atRow: mouseRow
			column: mouseColumn];
		}
              else
                {
                  if ([mouseCell state] != old_state)
                    {
                      [self setNeedsDisplayInRect: mouseCellFrame];
                    }
                }
                
	      mouseUp = mouseUpInCell
                      || ([[NSApp currentEvent] type] == NSLeftMouseUp);

	      if (!mouseUpInCell)
		{
	          _selectedCells[_selectedRow][_selectedColumn] = NO;
	          _selectedCell = nil;
	          _selectedRow = _selectedColumn = -1;
		}
	    }
	}

      // if mouse didn't go up, take next event
      if (!mouseUp)
	{
          NSEvent *newEvent;
	  newEvent = [NSApp nextEventMatchingMask: eventMask
			    untilDate: !scrolling
			    ? [NSDate distantFuture]
			    : [NSDate dateWithTimeIntervalSinceNow: 0.05]
			    inMode: NSEventTrackingRunLoopMode
			    dequeue: YES];

	  if (newEvent != nil)
            {
              theEvent = newEvent;
              mouseUp = ([theEvent type] == NSLeftMouseUp);
            }
	}
    }

  if (!mouseUpInCell)
    {
      if (_mode == NSRadioModeMatrix && !_allowsEmptySelection)
        {
          [self selectCell: originallySelectedCell];
        }
      [self sendAction]; /* like OPENSTEP, unlike MacOSX */  
    }
}

- (void) _mouseDownListMode: (NSEvent *) theEvent
{
  NSPoint locationInWindow, mouseLocation;
  int mouseRow, mouseColumn;
  int mouseIndex, previousIndex = 0, anchor = 0;
  id mouseCell, previousCell = nil;
  BOOL onCell;
  BOOL isSelecting = YES;
  unsigned eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
                     | NSMouseMovedMask | NSLeftMouseDraggedMask
                     | NSPeriodicMask;

  // List mode
  // multiple cells can be selected, dragging the mouse
  // cells do not track the mouse
  // shift key makes expands selection noncontiguously
  // alternate key expands selection contiguously
  // implementation based on OS 4.2 behaviour, that is different from MacOS X

  if (_autoscroll)
    {
      [NSEvent startPeriodicEventsAfterDelay: 0.05 withPeriod: 0.05];
    }

  locationInWindow = [theEvent locationInWindow];

  while ([theEvent type] != NSLeftMouseUp)
    {
      // must convert location each time or periodic events won't work well
      mouseLocation = [self convertPoint: locationInWindow fromView: nil];
      onCell = [self getRow: &mouseRow
		     column: &mouseColumn
		     forPoint: mouseLocation];

      if (onCell)
	{
	  mouseCell = [self cellAtRow: mouseRow column: mouseColumn];
          mouseIndex = INDEX_FROM_COORDS(mouseColumn, mouseRow);

	  if (_autoscroll)
            {
              NSRect mouseRect;
              mouseRect = [self cellFrameAtRow: mouseRow column: mouseColumn];
	      [self scrollRectToVisible: mouseRect];
            }
                         

	  if (mouseCell != previousCell && [mouseCell isEnabled] == YES)
	    {
	      if (!previousCell)
		{
                  // When the user first clicks on a cell
                  // we clear the existing selection
                  // unless the Alternate or Shift keys have been pressed.
		  if (!(mouseDownFlags & NSShiftKeyMask)
		      && !(mouseDownFlags & NSAlternateKeyMask))
		    {
		      [self deselectAllCells];
		    }
                    
                  /* The clicked cell is the anchor of the selection, unless
                   * the Alternate key is pressed, when the anchor is made
                   * the key cell, from which the selection will be 
                   * extended (this is probably not the best cell when
                   * selection is by rect)
                   */
		  if (!(mouseDownFlags & NSAlternateKeyMask))
                    {
		      anchor = INDEX_FROM_COORDS(mouseColumn, mouseRow);
                    }
                  else
                    {
                      if (_dottedColumn != -1)
		        anchor = INDEX_FROM_COORDS(_dottedColumn, _dottedRow);
                      else
                        anchor = INDEX_FROM_COORDS(0, 0);
                    }
                    
                  /* With the shift key pressed, clicking on a selected cell
                   * deselects it (and inverts the selection on mouse dragging).
                   */
		  if (mouseDownFlags & NSShiftKeyMask)
                    {
                      isSelecting = ([mouseCell state] == NSOffState);
                    }
                  else
                    {
                      isSelecting = YES;
                    }

                  previousIndex = mouseIndex;
		}
                
	      [self setSelectionFrom: previousIndex
	            to: mouseIndex
	            anchor: anchor
	            highlight: isSelecting];
              [self _setKeyRow: mouseRow column: mouseColumn];
              
              previousIndex = mouseIndex;
	      previousCell = mouseCell;
	    }
	}

      theEvent = [NSApp nextEventMatchingMask: eventMask
                                    untilDate: [NSDate distantFuture]
                                       inMode: NSEventTrackingRunLoopMode
                                      dequeue: YES];

      NSDebugLLog(@"NSMatrix", @"matrix: got event of type: %d\n",
                  [theEvent type]);

      if ([theEvent type] != NSPeriodic)
        {
          locationInWindow = [theEvent locationInWindow];
        }
    }

  if (_autoscroll)
    {
      [NSEvent stopPeriodicEvents];
    }

  [self sendAction];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  int row, column;
  NSPoint lastLocation = [theEvent locationInWindow];
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
              [self _selectCell: _cells[row][column] atRow: row column: column];
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
    }
  else
    {
      [self _mouseDownListMode: theEvent];
    }
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
	      [self lockFocus];
	      [self highlightCell: YES atRow: i column: j];
	      [_window flushWindow];
	      [aCell setNextState];
	      [self sendAction];
	      [self highlightCell: NO atRow: i column: j];
	      [self unlockFocus];
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
  [aCoder encodeObject: [self keyCell]];
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

- (void) setCellClass: (Class)classId
{
  _cellClass = classId;
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

- (void) setBackgroundColor: (NSColor*)aColor
{
  ASSIGN(_backgroundColor, aColor);
}

- (NSColor*) backgroundColor
{
  return _backgroundColor;
}

- (void) setCellBackgroundColor: (NSColor*)aColor
{
  ASSIGN(_cellBackgroundColor, aColor);
}

- (NSColor*) cellBackgroundColor
{
  return _cellBackgroundColor;
}

- (void) setDelegate: (id)anObject
{
  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = anObject;

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
  _target = anObject;
}

- (id) target
{
  return _target;
}

/**
 * Sets the message to send when a single click occurs.<br />
 */
- (void) setAction: (SEL)aSelector
{
  _action = aSelector;
}

- (SEL) action
{
  return _action;
}

/**
 * Sets the message to send when a double click occurs.<br />
 * NB: In GNUstep the following method does *not* set 
 * ignoresMultiClick to NO as in the MacOS-X spec.<br />
 * It simply sets the doubleAction, as in OpenStep spec.
 */
- (void) setDoubleAction: (SEL)aSelector
{
  _doubleAction = aSelector;
}

- (SEL) doubleAction
{
  return _doubleAction;
}

- (void) setErrorAction: (SEL)aSelector
{
  _errorAction = aSelector;
}

- (SEL) errorAction
{
  return _errorAction;
}

/**
 * Sets a flag to indicate whether the matrix should permit empty selections
 * or should force one or mor cells to be selected at all times.
 */
- (void) setAllowsEmptySelection: (BOOL)flag
{
  _allowsEmptySelection = flag;
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

/**
 * Set a flag to say whether the matrix will draw call backgrounds (YES)
 * or expect the cell to do it itsself (NO).
 */
- (void) setDrawsCellBackground: (BOOL)flag
{
  _drawsCellBackground = flag;
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

- (void) _rebuildLayoutAfterResizing
{
  if (_autosizesCells)
    {
      /* Keep the intercell as it is, and adjust the cell size to fit.  */
      if (_numRows > 1)
	{
	  _cellSize.height = _bounds.size.height - ((_numRows - 1) * _intercell.height);
	  _cellSize.height = _cellSize.height / _numRows;
	  if (_cellSize.height < 0)
	    {
	      _cellSize.height = 0;
	    }
	}
      else
	{
	  _cellSize.height = _bounds.size.height;
	}
      
      if (_numCols > 1)
	{
	  _cellSize.width = _bounds.size.width - ((_numCols - 1) * _intercell.width);
	  _cellSize.width = _cellSize.width / _numCols;
	  if (_cellSize.width < 0)
	    {
	      _cellSize.width = 0;
	    }
	}
      else
	{
	  _cellSize.width = _bounds.size.width;
	}
    }
  else // !autosizesCells
    {
      /* Keep the cell size as it is, and adjust the intercell to fit.  */
      if (_numRows > 1)
	{
	  _intercell.height = _bounds.size.height - (_numRows * _cellSize.height);
	  _intercell.height = _intercell.height / (_numRows - 1);
	  if (_intercell.height < 0)
	    {
	      _intercell.height = 0;
	    }
	}
      else
	{
	  _intercell.height = 0;
	}

      if (_numCols > 1)
	{
	  _intercell.width = _bounds.size.width - (_numCols * _cellSize.width);
	  _intercell.width = _intercell.width / (_numCols - 1);
	  if (_intercell.width < 0)
	    {
	      _intercell.width = 0;
	    }
	}
      else
	{
	  _intercell.width = 0;
	}
    }  
}

- (void) setFrame: (NSRect)aFrame
{
  [super setFrame: aFrame];
  [self _rebuildLayoutAfterResizing];
}

- (void) setFrameSize: (NSSize)aSize
{
  [super setFrameSize: aSize];
  [self _rebuildLayoutAfterResizing];
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
	      [self deselectAllCells];
	    }

	  [self selectCellAtRow: _dottedRow column: _dottedColumn];
	}
      else
	[self setNeedsDisplayInRect: [self cellFrameAtRow: _dottedRow
					   column: _dottedColumn]];
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
	      /* FIXME */
	      /*
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
	      */
	    }
	  else
	    [self deselectAllCells];

	  [self selectCellAtRow: _dottedRow column: _dottedColumn];
	}
      else
	{
	  [self setNeedsDisplayInRect: [self cellFrameAtRow: lastDottedRow
					     column: lastDottedColumn]];
	  [self setNeedsDisplayInRect: [self cellFrameAtRow: _dottedRow
					     column: _dottedColumn]];
	}
    }

  if (selectCell)
    {
      [self displayIfNeeded];
      [self performClick: self];
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

  [self lockFocus];
  [self drawCell: _cells[lastDottedRow][_dottedColumn]];
  [self drawCell: _cells[_dottedRow][_dottedColumn]];
  [self unlockFocus];
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

  [self displayIfNeeded];
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
		  [self setNeedsDisplayInRect: [self cellFrameAtRow: _dottedRow
						     column: _dottedColumn]];
		  break;

		case NSListModeMatrix:
		  if (!(modifiers & NSShiftKeyMask))
		    [self deselectAllCells];

		case NSRadioModeMatrix:
		  [self selectCellAtRow: _dottedRow column: _dottedColumn];
		  break;
		}

	      [self displayIfNeeded];
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
      string = AUTORELEASE ([[_textObject text] copy]);

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

      if (_selectionByRect || i == startPoint.y)
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

          if ([aCell isEnabled]
              && ([aCell state] != state || [aCell isHighlighted] != highlight
                  || (state == NSOffState && _selectedCells[i][j] != NO)
                  || (state != NSOffState && _selectedCells[i][j] == NO)))
            {
	      [aCell setState: state];

	      if (state == NSOffState)
	        _selectedCells[i][j] = NO;
	      else
	        _selectedCells[i][j] = YES;

	      [aCell setHighlighted: highlight];
	      [self setNeedsDisplayInRect: [self cellFrameAtRow: i column: j]];
            }
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
	      _selectedCell = [self selectTextAtRow: row column: j];
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
	      _selectedCell = [self selectTextAtRow: i column: j];
	      _selectedRow = i;
	      _selectedColumn = j;
	      return YES;
	    }
	}
    }
  return NO;
}

- (void) _drawCellAtRow: (int)row column: (int)column
{
  NSCell *aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      NSRect cellFrame = [self cellFrameAtRow: row column: column];

      // we don't need to draw the matrix's background
      // as it has already been done in drawRect: if needed
      // (this method is only called by drawRect:)
      if (_drawsCellBackground)
	{
	  [_cellBackgroundColor set];
	  NSRectFill(cellFrame);
	}

      if (_dottedRow == row && _dottedColumn == column
	  && [aCell acceptsFirstResponder])
	{
	  [aCell
	    setShowsFirstResponder: ([_window isKeyWindow]
				     && [_window firstResponder] == self)];
	}
      else
        {
	  [aCell setShowsFirstResponder: NO];
	}
      
      [aCell drawWithFrame: cellFrame inView: self];
      [aCell setShowsFirstResponder: NO];
    }
}

- (void) _setKeyRow: (int)row column: (int)column
{
  if (_dottedRow == row && _dottedColumn == column)
    {
      return;
    }
  if ([_cells[row][column] acceptsFirstResponder])
    {
      if (_dottedRow != -1 && _dottedColumn != -1)
        {
          [self setNeedsDisplayInRect: [self cellFrameAtRow: _dottedRow
                                             column: _dottedColumn]];
	}
      _dottedRow = row;
      _dottedColumn = column;
      [self setNeedsDisplayInRect: [self cellFrameAtRow: _dottedRow
                                         column: _dottedColumn]];
    }
}
@end
