/*
   NSMatrix.m

   Matrix class for grouping controls

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   A completely rewritten version of the original source by Pascal Forget and
   Scott Christley.
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998

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

#include <AppKit/NSColor.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSActionCell.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>



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

#define FREE(p) do { if (p) free (p); } while (0)

#define POINT_FROM_INDEX(index) \
    ({MPoint point = { index % numCols, index / numCols }; point; })

#define INDEX_FROM_COORDS(x,y) \
    (y * numCols + x)
#define INDEX_FROM_POINT(point) \
    (point.y * numCols + point.x)


typedef struct _tMatrix {
  int numRows, numCols;
  int allocatedRows, allocatedCols;
  BOOL** matrix;
} *tMatrix;

static tMatrix newMatrix (int numRows, int numCols)
{
  int rows = (numRows ? numRows : 1);
  int cols = (numCols ? numCols : 1);
  tMatrix m = malloc (sizeof(struct _tMatrix));
  int i;

  m->matrix = malloc (rows * sizeof(BOOL*));
  for (i = 0; i < rows; i++)
    m->matrix[i] = calloc (cols, sizeof(BOOL));

  m->allocatedRows = rows;
  m->allocatedCols = cols;
  m->numRows = numRows;
  m->numCols = numCols;

  return m;
}

static void freeMatrix (tMatrix m)
{
  int i;

  for (i = 0; i < m->allocatedRows; i++)
    FREE (m->matrix[i]);
  FREE (m->matrix);
  FREE (m);
}

/* Grow the matrix to some arbitrary dimensions */
static void growMatrix (tMatrix m, int numRows, int numCols)
{
  int i, j;

  if (numCols > m->allocatedCols) {
    /* Grow the existing rows to numCols */
    for (i = 0; i < m->allocatedRows; i++) {
      m->matrix[i] = realloc (m->matrix[i], numCols * sizeof(BOOL));
      for (j = m->allocatedCols - 1; j < numCols; j++)
	m->matrix[i][j] = NO;
    }
    m->allocatedCols = numCols;
  }

  if (numRows > m->allocatedRows) {
    /* Grow the vector that keeps the rows */
    m->matrix = realloc (m->matrix, numRows * sizeof(BOOL*));

    /* Allocate the rows up to allocatedRows that are NULL */
    for (i = 0; i < m->allocatedRows; i++)
      if (!m->matrix[i])
	m->matrix[i] = calloc (m->allocatedCols, sizeof(BOOL));

    /* Add the necessary rows */
    for (i = m->allocatedRows; i < numRows; i++)
      m->matrix[i] = calloc (m->allocatedCols, sizeof(BOOL));
    m->allocatedRows = numRows;
  }

  m->numRows = numRows;
  m->numCols = numCols;
}

static void insertRow (tMatrix m, int rowPosition)
{
  int rows = m->numRows + 1;
  int i;

  /* Create space for the new rows if necessary */
  if (rows > m->allocatedRows)
    {
      m->matrix = realloc (m->matrix, rows * sizeof(BOOL*));
      m->allocatedRows = rows;
    }

  /* Make room for the new row */
  for (i = m->numRows - 1; i > rowPosition; i--)
    m->matrix[i] = m->matrix[i - 1];

  /* Allocate any NULL row that exists up to rowPosition */
  for (i = 0; i < rowPosition; i++)
    if (!m->matrix[i])
      m->matrix[i] = calloc (m->allocatedCols, sizeof(BOOL));

  /* Create the required row */
  m->matrix[rowPosition] = calloc (m->allocatedCols, sizeof(BOOL));

  m->numRows++;
}

static void insertColumn (tMatrix m, int colPosition)
{
  int cols = m->numCols + 1;
  int i, j;

  /* First grow the rows to hold `cols' elements */
  if (cols > m->allocatedCols)
    {
      for (i = 0; i < m->numRows; i++)
	m->matrix[i] = realloc (m->matrix[i], cols * sizeof(BOOL));
      m->allocatedCols = cols;
    }

  /* Now insert a new column between the rows, in the required position.
    If it happens that a row is NULL create a new row with the maximum
    number of columns for it. */
  for (i = 0; i < m->numRows; i++)
    {
      BOOL* row = m->matrix[i];

      if (!row)
	m->matrix[i] = calloc (m->allocatedCols, sizeof(BOOL));
      else
	{
	  for (j = m->numCols - 1; j > colPosition; j--)
	    row[j] = row[j - 1];
	  row[colPosition] = NO;
	}
    }
  m->numCols++;
}

static void removeRow (tMatrix m, int row)
{
  int i;

  /* Free the row and shrink the matrix by removing the row from it */
  FREE (m->matrix[row]);
  m->matrix[row] = NULL;
  for (i = row; i < m->numRows - 1; i++)
    m->matrix[i] = m->matrix[i + 1];
  m->numRows--;
  m->matrix[m->numRows] = NULL;
}

static void removeColumn (tMatrix m, int column)
{
  int i, j;

  for (i = 0; i < m->numRows; i++)
    {
      BOOL* row = m->matrix[i];

      for (j = column; j < m->numCols - 1; j++)
	row[j] = row[j + 1];
      row[m->numCols] = NO;
    }
  m->numCols--;
}

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
- (void) _setState: (int)state
	 highlight: (BOOL)highlight
	startIndex: (int)start
	  endIndex: (int)end;
@end

enum {
  DEFAULT_CELL_HEIGHT = 17,
  DEFAULT_CELL_WIDTH = 100
};

@implementation NSMatrix

/* Class variables */
static Class defaultCellClass = nil;
static int mouseDownFlags = 0;

+ (void) initialize
{
  if (self == [NSMatrix class])
    {
      /* Set the initial version */
      [self setVersion: 1];

      /* Set the default cell class */
      defaultCellClass = [NSCell class];
    }
}

+ (Class) cellClass
{
  return defaultCellClass;
}

+ (void) setCellClass: (Class)classId
{
  defaultCellClass = classId;
}

- init
{
  return [self initWithFrame: NSZeroRect
	       mode: NSRadioModeMatrix
	       prototype: [[[isa cellClass] new] autorelease]
	       numberOfRows: 0
	       numberOfColumns: 1];
}

- (id) initWithFrame: (NSRect)frameRect
{
  return [self initWithFrame: frameRect
	       mode: NSRadioModeMatrix
	       cellClass: [isa cellClass]
	       numberOfRows: 0
	       numberOfColumns: 0];
}

- (id) initWithFrame: (NSRect)frameRect
	        mode: (int)aMode
	   cellClass: (Class)class
        numberOfRows: (int)rowsHigh
     numberOfColumns: (int)colsWide
{
  return [self initWithFrame: frameRect
	       mode: aMode
	       prototype: [[class new] autorelease]
	       numberOfRows: rowsHigh
	       numberOfColumns: colsWide];
}

- (id) initWithFrame: (NSRect)frameRect
	        mode: (int)aMode
	   prototype: (NSCell*)prototype
        numberOfRows: (int)rows
     numberOfColumns: (int)cols
{
  int i, j;

  [super initWithFrame: frameRect];

  ASSIGN(cellPrototype, prototype);

  cells = [[NSMutableArray alloc] initWithCapacity: rows];
  selectedCells = newMatrix (rows, cols);
  for (i = 0; i < rows; i++)
    {
      NSMutableArray* row = [NSMutableArray arrayWithCapacity: cols];

      [cells addObject: row];
      for (j = 0; j < cols; j++)
	{
	  [row addObject: [[cellPrototype copy] autorelease]];
	}
    }

  numRows = rows;
  numCols = cols;
  mode = aMode;
  [self setFrame: frameRect];

  cellSize = NSMakeSize(DEFAULT_CELL_WIDTH, DEFAULT_CELL_HEIGHT);
  intercell = NSMakeSize(1, 1);
  [self setBackgroundColor: [NSColor lightGrayColor]];
  [self setDrawsBackground: YES];
  [self setCellBackgroundColor: [NSColor lightGrayColor]];
  [self setSelectionByRect: YES];
  [self setAutosizesCells: YES];
  if (mode == NSRadioModeMatrix && numRows && numCols)
    {
      [self selectCellAtRow: 0 column: 0];
    }
  else
    selectedRow = selectedColumn = 0;

  return self;
}

- (void) dealloc
{
  [cells release];
  [cellPrototype release];
  [backgroundColor release];
  [cellBackgroundColor release];
  freeMatrix (selectedCells);
  [super dealloc];
}

- (void) addColumn
{
  [self insertColumn: numCols];
}

- (void) addColumnWithCells: (NSArray*)cellArray
{
  [self insertColumn: numCols withCells: cellArray];
}

- (void) addRow
{
  [self insertRow: numRows];
}

- (void) addRowWithCells: (NSArray*)cellArray
{
  [self insertRow: numRows withCells: cellArray];
}

- (void) insertColumn: (int)column
{
  int i;

  /* Grow the matrix if necessary */
  if (column >= numCols)
    [self renewRows: (numRows == 0 ? 1 : numRows) columns: column];
  if (numRows == 0)
    {
      numRows = 1;
      [cells addObject: [NSMutableArray array]];
    }

  numCols++;
  for (i = 0; i < numRows; i++)
    [self makeCellAtRow: i column: column];
  insertColumn (selectedCells, column);

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow: 0 column: 0];
}

- (void) insertColumn: (int)column withCells: (NSArray*)cellArray
{
  int i;

  /* Grow the matrix if necessary */
  if (column >= numCols)
    [self renewRows: (numRows == 0 ? 1 : numRows) columns: column];
  if (numRows == 0)
    {
      numRows = 1;
      [cells addObject: [NSMutableArray array]];
    }

  numCols++;
  for (i = 0; i < numRows; i++)
    [[cells objectAtIndex: i]
	replaceObjectAtIndex: column withObject: [cellArray objectAtIndex: i]];
  insertColumn (selectedCells, column);

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow: 0 column: 0];
}

- (void) insertRow: (int)row
{
  int i;

  /* Grow the matrix if necessary */
  if (row >= numRows)
    [self renewRows: row columns: (numCols == 0 ? 1 : numCols)];
  if (numCols == 0)
    numCols = 1;

  [cells insertObject: [NSMutableArray arrayWithCapacity: numCols] atIndex: row];

  numRows++;
  for (i = 0; i < numCols; i++)
    [self makeCellAtRow: row column: i];

  insertRow (selectedCells, row);

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow: 0 column: 0];
}

- (void) insertRow: (int)row withCells: (NSArray*)cellArray
{
  /* Grow the matrix if necessary */
  if (row >= numRows)
    [self renewRows: row columns: (numCols == 0 ? 1 : numCols)];
  if (numCols == 0)
    numCols = 1;

  [cells insertObject: [cellArray subarrayWithRange: NSMakeRange(0, numCols)]
	      atIndex: row];

  insertRow (selectedCells, row);

  numRows++;

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow: 0 column: 0];
}

- (NSCell*) makeCellAtRow: (int)row
		   column: (int)column
{
  NSCell* aCell;

  if (cellPrototype)
    aCell = [[cellPrototype copy] autorelease];
  else if (cellClass)
    aCell = [[cellClass new] autorelease];
  else
    aCell = [[NSActionCell new] autorelease];

  [[cells objectAtIndex: row] insertObject: aCell atIndex: column];
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
  [[cells objectAtIndex: row] replaceObjectAtIndex: column withObject: newCell];
  [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
}

- (void) removeColumn: (int)column
{
  int i;

  if (column >= numCols)
    return;

  for (i = 0; i < numRows; i++)
    [[cells objectAtIndex: i] removeObjectAtIndex: column];

  removeColumn (selectedCells, column);
  numCols--;

  if (column == selectedColumn)
    {
      selectedCell = nil;
      [self selectCellAtRow: 0 column: 0];
    }
}

- (void) removeRow: (int)row
{
  if (row >= numRows)
    return;

  [cells removeObjectAtIndex: row];
  removeRow (selectedCells, row);
  numRows--;

  if (row == selectedRow)
    {
      selectedCell = nil;
      [self selectCellAtRow: 0 column: 0];
    }
}

- (void) renewRows: (int)newRows
	   columns: (int)newColumns
{
  int i, j;

  if (newColumns > numCols)
    {
      /* First check to see if the rows really have fewer cells than
       newColumns. This may happen because the row arrays are not shrink
       when a lower number of cells is given. */
      if (numRows && newColumns > [[cells objectAtIndex: 0] count])
	{
	  /* Add columns to the existing rows. Call makeCellAtRow: column: 
	   to be consistent. */
	  for (i = 0; i < numRows; i++)
	    {
	      for (j = numCols; j < newColumns; j++)
		[self makeCellAtRow: i column: j];
	    }
	}
    }
  numCols = newColumns;

  if (newRows > numRows)
    {
      for (i = numRows; i < newRows; i++)
	{
	  [cells addObject: [NSMutableArray arrayWithCapacity: numCols]];
	  for (j = 0; j < numCols; j++)
	    [self makeCellAtRow: i column: j];
	}
    }
  numRows = newRows;

  growMatrix (selectedCells, newRows, newColumns);
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
  NSMutableArray* sorted = [NSMutableArray arrayWithCapacity: numRows*numCols];
  NSMutableArray* row;
  int i, j, index = 0;

  for (i = 0; i < numRows; i++)
    [sorted addObjectsFromArray: [[cells objectAtIndex: i]
				  subarrayWithRange: NSMakeRange(0, numCols)]];

  [sorted sortUsingFunction: comparator context: context];

  for (i = 0; i < numRows; i++)
    {
      row = [cells objectAtIndex: i];
      for (j = 0; j < numCols; j++)
	{
	  [row replaceObjectAtIndex: j
			 withObject: [sorted objectAtIndex: index]];
	  index++;
	}
    }
}

- (void) sortUsingSelector: (SEL)comparator
{
  NSMutableArray* sorted = [NSMutableArray arrayWithCapacity: numRows*numCols];
  NSMutableArray* row;
  int i, j, index = 0;

  for (i = 0; i < numRows; i++)
    [sorted addObjectsFromArray: [[cells objectAtIndex: i]
				  subarrayWithRange: NSMakeRange(0, numCols)]];

  [sorted sortUsingSelector: comparator];

  for (i = 0; i < numRows; i++)
    {
      row = [cells objectAtIndex: i];
      for (j = 0; j < numCols; j++)
	{
	  [row replaceObjectAtIndex: j
			 withObject: [sorted objectAtIndex: index]];
	  index++;
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
  NSRect theBounds = [self bounds];

  /* First check the limit cases */
  beyondCols = (point.x > theBounds.size.width || point.x < 0);
  beyondRows = (point.y > theBounds.size.height || point.y < 0);

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
  int i, j;

  for (i = 0; i < numRows; i++)
    {
      NSMutableArray* rowArray = [cells objectAtIndex: i];

      for (j = 0; j < numCols; j++)
	if ([rowArray objectAtIndex: j] == aCell)
	  {
	    *row = i;
	    *column = j;
	    return YES;
	  }
    }

  return NO;
}

- (void) setState: (int)value
	    atRow: (int)row
	   column: (int)column
{
  NSCell* aCell = [self cellAtRow: row column: column];

  if (!aCell)
    return;

  if (mode == NSRadioModeMatrix)
    {
      if (value)
	{
	  selectedCell = aCell;
	  selectedRow = row;
	  selectedColumn = column;
	  [selectedCell setState: 1];
	  ((tMatrix)selectedCells)->matrix[row][column] = YES;
	}
      else if (allowsEmptySelection)
	[self deselectSelectedCell];
    }
  else
    [aCell setState: value];

  [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
}

- (void) deselectAllCells
{
  unsigned	i, j;
  NSArray	*row;
  NSCell	*aCell;

  for (i = 0; i < numRows; i++)
    {
      row = nil;
      for (j = 0; j < numCols; j++)
	{
	  if (((tMatrix)selectedCells)->matrix[i][j])
	    {
	      NSRect theFrame = [self cellFrameAtRow: i column: j];

	      if (!row)
		row = [cells objectAtIndex: i];
	      aCell = [row objectAtIndex: j];
	      [aCell setState: 0];
	      [aCell highlight: NO withFrame: theFrame inView: self];
	      [self setNeedsDisplayInRect: theFrame];
	      ((tMatrix)selectedCells)->matrix[i][j] = NO;
	    }
	}
    }

  if (!allowsEmptySelection && mode == NSRadioModeMatrix)
    [self selectCellAtRow: 0 column: 0];
}

- (void) deselectSelectedCell
{
  if (!selectedCell || (!allowsEmptySelection && (mode == NSRadioModeMatrix)))
    return;
  
  ((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = NO;
  [selectedCell setState: 0];
  selectedCell = nil;
  selectedRow = 0;
  selectedColumn = 0;
}

- (void) selectAll: (id)sender
{
  unsigned	i, j;
  NSArray	*row;

  /* Make the selected cell the cell at (0, 0) */
  selectedCell = [self cellAtRow: 0 column: 0];		// select current cell
  selectedRow = 0;
  selectedColumn = 0;

  for (i = 0; i < numRows; i++)
    {
      row = [cells objectAtIndex: i];

      for (j = 0; j < numCols; j++)
	{
	  [[row objectAtIndex: j] setState: 1];
	  ((tMatrix)selectedCells)->matrix[i][j] = YES;
	}
    }

  [self display];
}

- (void) selectCellAtRow: (int)row column: (int)column
{
  NSCell* aCell = [self cellAtRow: row column: column];

  if (!aCell)
    return;

  if (selectedCell && selectedCell != aCell)
    {
      ((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = NO;
      [selectedCell setState: 0];
    }

  selectedCell = aCell;
  selectedRow = row;
  selectedColumn = column;
  ((tMatrix)selectedCells)->matrix[row][column] = YES;
  [selectedCell setState: 1];

  [self setNeedsDisplayInRect: [self cellFrameAtRow: row column: column]];
}

- (BOOL) selectCellWithTag: (int)anInt
{
  NSMutableArray* row;
  id aCell;
  int i, j;

  for (i = numRows - 1; i >= 0; i--)
    {
      row = [cells objectAtIndex: i];
      for (j = numCols - 1; j >= 0; j --)
	{
	  aCell = [row objectAtIndex: j];
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
  NSMutableArray* array = [NSMutableArray array];
  int i, j;

  for (i = 0; i < numRows; i++)
    {
      NSArray* row = [cells objectAtIndex: i];

      for (j = 0; j < numCols; j++)
	if (((tMatrix)selectedCells)->matrix[i][j])
	  [array addObject: [row objectAtIndex: j]];
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
  [self display];
}

- (id) cellAtRow: (int)row
	  column: (int)column
{
  if (row < 0 || row >= numRows || column < 0 || column >= numCols)
    return nil;

  return [[cells objectAtIndex: row] objectAtIndex: column];
}

- (id) cellWithTag: (int)anInt
{
  NSMutableArray* row;
  id aCell;
  int i, j;

  for (i = numRows - 1; i >= 0; i--)
    {
      row = [cells objectAtIndex: i];
      for (j = numCols - 1; j >= 0; j --)
	{
	  aCell = [row objectAtIndex: j];
	  if ([aCell tag] == anInt)
	    return aCell;
	}
    }

  return nil;
}

- (NSArray*) cells
{
  return cells;
}

- (void) selectText: (id)sender
{
fprintf(stderr, " NSMatrix: selectText --- ");
// TODO
}

- (id) selectTextAtRow: (int)row column: (int)column
{
// TODO
//  NSCell* aCell = [self cellAtRow: row column: column];

fprintf(stderr, " NSMatrix: selectTextAtRow --- ");


  return nil;
}

- (id) nextText
{
// TODO
  return nil;
}

- (id) previousText
{
// TODO
  return nil;
}

- (void) textDidBeginEditing: (NSNotification*)notification
{
}

- (void) textDidChange: (NSNotification*)notification
{
}

- (void) textDidEndEditing: (NSNotification*)notification
{
}

- (BOOL) textShouldBeginEditing: (NSText*)textObject
{
  return YES;
}

- (BOOL) textShouldEndEditing: (NSText*)textObject
{
  return YES;
}

- (void) setNextText: (id)anObject
{
// TODO
}

- (void) setPreviousText: (id)anObject
{
// TODO
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
  int i, j;

  for (i = 0; i < numRows; i++)
    {
      NSArray* row = [cells objectAtIndex: i];

      for (j = 0; j < numCols; j++)
	[[row objectAtIndex: j] setScrollable: flag];
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
      // draw the background
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

- (void) drawCellAtRow: (int)row column: (int)column
{
  NSCell *aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      NSRect cellFrame = [self cellFrameAtRow: row column: column];

      if (drawsCellBackground)
	{
	  [cellBackgroundColor set];
	  NSRectFill(cellFrame);
	}
      [aCell drawWithFrame: cellFrame inView: self];
    }
}

- (void) highlightCell: (BOOL)flag atRow: (int)row column: (int)column
{
  NSCell *aCell = [self cellAtRow: row column: column];

  if (aCell)
    {
      NSRect cellFrame = [self cellFrameAtRow: row column: column];

      if (drawsCellBackground)
	{
	  [cellBackgroundColor set];
	  NSRectFill(cellFrame);
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
	return [super sendAction: theAction to: theTarget];
      else
	return [super sendAction: theAction to: [self target]];
    }
  else
    return [super sendAction: [self action] to: [self target]];
}


- (BOOL) sendAction
{
  if (![selectedCell isEnabled])
    return NO;

  return [self sendAction: [selectedCell action] to: [selectedCell target]];
}

- (void) sendAction: (SEL)aSelector
		 to: (id)anObject
        forAllCells: (BOOL)flag
{
  int i, j;

  if (flag)
    {
      for (i = 0; i < numRows; i++)
	{
	  NSMutableArray* row = [cells objectAtIndex: i];

	  for (j = 0; j < numCols; j++)
	    if (![anObject performSelector: aSelector
			   withObject: [row objectAtIndex: j]])
	      return;
	}
    }
  else
    {
      for (i = 0; i < numRows; i++)
	{
	  BOOL* row = ((tMatrix)selectedCell)->matrix[i];
	  NSMutableArray* cellRow = [cells objectAtIndex: i];

	  for (j = 0; j < numCols; j++)
	    if (row[i])
	      if (![anObject performSelector: aSelector
				  withObject: [cellRow objectAtIndex: j]])
		return;
	}
    }
}

- (void) sendDoubleAction
{
  if (![selectedCell isEnabled])
    return;

  if (doubleAction)
    [target performSelector: doubleAction withObject: self];
  else
    [self sendAction];
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return mode == NSListModeMatrix ? NO : YES;
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

  [self lockFocus];

  if ((mode == NSRadioModeMatrix) && selectedCell)
    {
      [selectedCell setState: NSOffState];
      [self drawCellAtRow: selectedRow column: selectedColumn];
      [window flushWindow];
      ((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = NO;
      selectedCell = nil;
      selectedRow = selectedColumn = -1;
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

          selectedCell = mouseCell;
          selectedRow = mouseRow;
          selectedColumn = mouseColumn;
          ((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = YES;

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
    // if not, selectedCell is the last cell that had the mouse, and
    // it's state is Off. It must be set into a consistent state.
    // anyway, the action has to be sent
    if (!mouseUpInCell)
      {
        if ((mode == NSRadioModeMatrix) && !allowsEmptySelection)
          {
            [selectedCell setState: NSOnState];
            [window flushWindow];
          }
        else
          {
            if (selectedCell)
              {
                ((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn]
		  = NO;
                selectedCell = nil;
                selectedRow = selectedColumn = -1;
              }
          }
        [self sendAction];
      }

    if (highlightedCell)
      {
        [self highlightCell: NO
                      atRow: highlightedRow
                     column: highlightedColumn];
        [window flushWindow];
      }

    [self unlockFocus];
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

  mouseDownFlags = [theEvent modifierFlags];

  if (mode != NSListModeMatrix)
    {
      [self _mouseDownNonListMode: theEvent];
      return;
    }

  lastLocation = [self convertPoint: lastLocation fromView: nil];
  if ((mode != NSTrackModeMatrix) && (mode != NSHighlightModeMatrix))
    [NSEvent startPeriodicEventsAfterDelay: 0.05 withPeriod: 0.05];
  ASSIGN(lastEvent, theEvent);

  [self lockFocus];
  // selection involves two steps, first
  // a loop that continues until the left mouse goes up; then a series of
  // steps which send actions and display the cell as it should appear after
  // the selection process is complete
  while (!done)
    {
      BOOL shouldProceedEvent = NO;

      onCell = [self getRow: &row column: &column forPoint: lastLocation];
      if (onCell)
	{
	  aCell = [self cellAtRow: row column: column];
	  rect = [self cellFrameAtRow: row column: column];
	  if (aCell != previousCell)
	    {
	      switch (mode)
		{
		  case NSTrackModeMatrix: 
		    // in Track mode the cell should track the mouse
		    // until the cursor either leaves the cellframe or
		    // NSLeftMouseUp occurs
		    selectedCell = aCell;
		    selectedRow = row;
		    selectedColumn = column;
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
		    selectedCell = aCell;
		    selectedRow = row;
		    selectedColumn = column;
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
		    if (selectedCell)
		      {
			[selectedCell setState: 0];
			if (!previousCell)
			  previousCellRect = [self cellFrameAtRow: selectedRow
			   column: selectedColumn];
			[selectedCell highlight: NO
				      withFrame: previousCellRect
					 inView: self];
			((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = NO;
		      }
		    // select current cell
		    selectedCell = aCell;
		    selectedRow = row;
		    selectedColumn = column;
		    [aCell setState: 1];
		    [aCell highlight: YES withFrame: rect inView: self];
		    ((tMatrix)selectedCells)->matrix[row][column] = YES;
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
			      selectedCell = aCell;
			      selectedRow = row;
			      selectedColumn = column;

			      [selectedCell setState: 1];
			      [selectedCell highlight: YES
					    withFrame: rect
					       inView: self];
			      ((tMatrix)selectedCells)->matrix[row][column]=YES;
			      [window flushWindow];
			      break;
			    }
			}
		      [self setSelectionFrom:
			INDEX_FROM_COORDS(selectedColumn, selectedRow)
			to: INDEX_FROM_COORDS(column, row)
			anchor: INDEX_FROM_POINT(anchor)
			highlight: YES];

		      [window flushWindow];
		      selectedCell = aCell;
		      selectedRow = row;
		      selectedColumn = column;
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
	if (selectedCell)
	  [selectedCell highlight: NO withFrame: rect inView: self];
      case NSListModeMatrix: 
	[self setNeedsDisplayInRect: rect];
	[window flushWindow];
      case NSHighlightModeMatrix: 
      case NSTrackModeMatrix: 
	break;
    }

  if (selectedCell)
    {
      // send single click action
      if (!(selectedCellTarget = [selectedCell target]))
	{
	  // selected cell has no target so send single
	  // click action to matrix's (self's) target
	  if (target)
	    [target performSelector: action withObject: self];
	}
      else
	{
	  // in Track and Highlight modes the single
	  // click action has already been sent by the
	  // cell to it's target (if it has one)
	  if ((mode != NSTrackModeMatrix) && (mode != NSHighlightModeMatrix))
	    [selectedCellTarget performSelector: [selectedCell action]
				     withObject: self];
	}
    }
  // click count > 1 indicates a double click
  if (target && doubleAction && ([lastEvent clickCount] > 1))
    [target performSelector: doubleAction withObject: self];

  [self unlockFocus];

  if ((mode != NSTrackModeMatrix) && (mode != NSHighlightModeMatrix))
    [NSEvent stopPeriodicEvents];

  [lastEvent release];
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
  int i, j;
  NSMutableArray* row;
  NSString* key = [theEvent charactersIgnoringModifiers];

  for (i = 0; i < numRows; i++)
    {
      row = [cells objectAtIndex: i];
      for (j = 0; j < numCols; j++)
	{
	  NSCell* aCell = [row objectAtIndex: j];

	  if ([aCell isEnabled]
	    && [[aCell keyEquivalent] isEqualToString: key])
	    {
	      NSCell* oldSelectedCell = selectedCell;

	      selectedCell = aCell;
	      [self highlightCell: YES atRow: i column: j];
	      [aCell setState: ![aCell state]];
	      [self sendAction];
	      [self highlightCell: NO atRow: i column: j];
	      selectedCell = oldSelectedCell;

	      return YES;
	    }
	}
    }

  return NO;
}

- (void) resetCursorRects
{
  int i, j;

  for (i = 0; i < numRows; i++)
    {
      NSArray* row = [cells objectAtIndex: i];

      for (j = 0; j < numCols; j++)
	{
	  NSCell* aCell = [row objectAtIndex: j];
	  [aCell resetCursorRect: [self cellFrameAtRow: i column: j]
			  inView: self];
	}
    }
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
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
}

- (Class) cellClass
{
  return cellClass;
}

- (void) setPrototype: (NSCell*)aCell
{
  ASSIGN(cellPrototype, aCell);
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
  ASSIGN(delegate, object);
}

- (id) delegate
{
  return delegate;
}

- (void) setTarget: anObject
{
  ASSIGN(target, anObject);
}

- (id) target
{
  return target;
}

- (void) setAction: (SEL)sel
{
  action = sel;
}

- (SEL) action
{
  return action;
}

- (void) setDoubleAction: (SEL)sel
{
  doubleAction = sel;
}

- (SEL) doubleAction
{
  return doubleAction;
}

- (void) setErrorAction: (SEL)sel
{
  errorAction = sel;
}

- (SEL) errorAction
{
  return errorAction;
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
  return selectedCell;
}

- (int) selectedColumn
{
  return selectedColumn;
}

- (int) selectedRow
{
  return selectedRow;
}

- (int) mouseDownFlags
{
  return mouseDownFlags;
}

- (BOOL) isFlipped
{
  return YES;
}


//
//	Methods that may not be needed FIX ME
//

/*
 * Get characters until you encounter
 * a carriage return, return number of characters.
 * Deal with backspaces, etc.  Deal with Expose events
 * on all windows associated with this application.
 * Deal with keyboard remapping.
 */

- (void) keyDown: (NSEvent *)theEvent;
{
  unsigned int flags = [theEvent modifierFlags];
  unsigned int key_code = [theEvent keyCode];
  NSRect rect = [self cellFrameAtRow: selectedRow column: selectedColumn];

  fprintf(stderr, " NSMatrix: keyDown --- ");

  // If not editable then don't recognize the key down
  if (![selectedCell isEditable])
    return;

  [self lockFocus];

  // If RETURN key then make the next text the first responder
  if (key_code == 0x0d)
    {
      [selectedCell endEditing: nil];
      [selectedCell drawInteriorWithFrame: rect inView: self];
      [self unlockFocus];
      return;
    }

  // Hide the cursor during typing
  [NSCursor hide];

  [selectedCell _handleKeyEvent: theEvent];
  [selectedCell drawInteriorWithFrame: rect inView: self];
  [self unlockFocus];
}

- (BOOL) acceptsFirstResponder
{
  if ([selectedCell isSelectable])
    return YES;
  else
    return NO;
}

- (BOOL) becomeFirstResponder
{
  if ([selectedCell isSelectable])
    {
//      [selectedCell selectText: self];
      return YES;
    }
  else
    {
      return NO;
    }
}

@end


@implementation NSMatrix (PrivateMethods)

- (void) _setState: (int)state
	 highlight: (BOOL)highlight
	startIndex: (int)start
	  endIndex: (int)end
{
  int		i, j;
  MPoint	startPoint = POINT_FROM_INDEX(start);
  MPoint	endPoint = POINT_FROM_INDEX(end);

  for (i = startPoint.y; i <= endPoint.y; i++)
    {
      NSArray	*row = [cells objectAtIndex: i];
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
	  NSCell	*aCell = [row objectAtIndex: j];

	  [aCell setState: state];
	  [aCell highlight: highlight withFrame: rect inView: self];
	  [self setNeedsDisplayInRect: rect];
	  if (state == 0)
	    ((tMatrix)selectedCells)->matrix[i][j] = NO;
	  else
	    ((tMatrix)selectedCells)->matrix[i][j] = YES;
	}
    }
}

@end
