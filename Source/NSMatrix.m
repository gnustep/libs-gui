/* 
   NSMatrix.m

   Matrix class for grouping controls

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   A completely rewritten version of the original source by Pascal Forget and
   Scott Christley.
   
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
#include <AppKit/NSActionCell.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>

/* Define the following symbol when NSView will support flipped views */
//#define HAS_FLIPPED_VIEWS 1

#define ASSIGN(a, b) \
  [b retain]; \
  [a release]; \
  a = b;

#ifdef MIN
# undef MIN
#endif
#define MIN(a, b) \
    ({typedef _ta = (a), _tb = (b);   \
	_ta _a = (a); _tb _b = (b);     \
	_a < _b ? _a : _b; })

#ifdef MAX
# undef MAX
#endif
#define MAX(a, b) \
    ({typedef _ta = (a), _tb = (b);   \
	_ta _a = (a); _tb _b = (b);     \
	_a > _b ? _a : _b; })

#ifdef ABS
# undef ABS
#endif
#define ABS(x) \
    ({typedef _tx = (x); \
      _tx _x = (x); \
      _x >= 0 ? _x : -_x; })

#define SIGN(x) \
    ({typedef _tx = (x); \
      _tx _x = (x); \
      _x > 0 ? 1 : (_x == 0 ? 0 : -1); })

#define FREE(p) do { if (p) free (p); } while (0)

#define POINT_FROM_INDEX(index) \
    ({MPoint point = { index % numCols, index / numCols }; point; })

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
  tMatrix m = malloc (sizeof (struct _tMatrix));
  int i;

  m->matrix = malloc (rows * sizeof (BOOL*));
  for (i = 0; i < rows; i++)
    m->matrix[i] = calloc (cols, sizeof (BOOL));

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
    for (i = 0; i < numRows; i++) {
      m->matrix[i] = realloc (m->matrix[i], numCols * sizeof (BOOL));
      for (j = m->allocatedCols - 1; j < numCols; j++)
	m->matrix[i][j] = NO;
    }
    m->allocatedCols = numCols;
  }

  if (numRows > m->allocatedRows) {
    /* Grow the vector that keeps the rows */
    m->matrix = realloc (m->matrix, numRows * sizeof (BOOL*));

    /* Allocate the rows up to allocatedRows that are NULL */
    for (i = 0; i < m->allocatedRows; i++)
      if (!m->matrix[i])
	m->matrix[i] = calloc (m->allocatedCols, sizeof (BOOL));

    /* Add the necessary rows */
    for (i = m->allocatedRows; i < numRows; i++)
      m->matrix[i] = calloc (m->allocatedCols, sizeof (BOOL));
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
  if (rows > m->allocatedRows) {
    m->matrix = realloc (m->matrix, rows * sizeof (BOOL*));
    m->allocatedRows = rows;
  }

  /* Make room for the new row */
  for (i = m->numRows - 1; i > rowPosition; i--)
    m->matrix[i] = m->matrix[i - 1];

  /* Allocate any NULL row that exists up to rowPosition */
  for (i = 0; i < rowPosition; i++)
    if (!m->matrix[i])
      m->matrix[i] = calloc (m->allocatedCols, sizeof (BOOL));

  /* Create the required row */
  m->matrix[rowPosition] = calloc (m->allocatedCols, sizeof (BOOL));

  m->numRows++;
}

static void insertColumn (tMatrix m, int colPosition)
{
  int cols = m->numCols + 1;
  int i, j;

  /* First grow the rows to hold `cols' elements */
  if (cols > m->allocatedCols) {
    for (i = 0; i < m->numRows; i++)
      m->matrix[i] = realloc (m->matrix[i], cols * sizeof (BOOL));
    m->allocatedCols = cols;
  }

  /* Now insert a new column between the rows, in the required position.
    If it happens that a row is NULL create a new row with the maximum
    number of columns for it. */
  for (i = 0; i < m->numRows; i++) {
    BOOL* row = m->matrix[i];

    if (!row)
      m->matrix[i] = calloc (m->allocatedCols, sizeof (BOOL));
    else {
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

  for (i = 0; i < m->numRows; i++) {
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

/* Returns by reference the row and column of cell that is above or below or
   to the left or to the right of point. `point' is in the matrix coordinates.
   Returns NO if the point is outside the bounds of matrix, YES otherwise.
 */
- (BOOL)_getRow:(int*)row
	 column:(int*)column
       forPoint:(NSPoint)point
	  above:(BOOL)aboveRequired
	  right:(BOOL)rightRequired
 isBetweenCells:(BOOL*)isBetweenCells;
- (void)_selectRectUsingAnchor:(MPoint)anchor
			  last:(MPoint)last
		       current:(MPoint)current;
- (void)_setState:(int)state inRect:(MRect)rect;
- (void)_selectContinuousUsingAnchor:(MPoint)anchor
			       last:(MPoint)last
			    current:(MPoint)current;
- (void)_setState:(int)state startIndex:(int)start endIndex:(int)end;
@end

enum {
  DEFAULT_CELL_HEIGHT = 17,
  DEFAULT_CELL_WIDTH = 100
};

@implementation NSMatrix

/* Class variables */
static Class defaultCellClass = nil;
static int mouseDownFlags = 0;

+ (void)initialize
{
  if (self == [NSMatrix class]) {
    /* Set the initial version */
    [self setVersion: 1];

    /* Set the default cell class */
    defaultCellClass = [NSCell class];
  }
}

+ (Class)cellClass
{
  return defaultCellClass;
}

+ (void)setCellClass:(Class)classId
{
  defaultCellClass = classId;
}

- init
{
  return [self initWithFrame:NSZeroRect
	       mode:NSRadioModeMatrix
	       prototype:[[[isa cellClass] new] autorelease]
	       numberOfRows:0
	       numberOfColumns:1];
}

- (id)initWithFrame:(NSRect)frameRect
{
  return [self initWithFrame:frameRect
	       mode:NSRadioModeMatrix
	       cellClass:[isa cellClass]
	       numberOfRows:0
	       numberOfColumns:0];
}

- (id)initWithFrame:(NSRect)frameRect
	       mode:(int)aMode
	  cellClass:(Class)class
       numberOfRows:(int)rowsHigh
    numberOfColumns:(int)colsWide
{
  return [self initWithFrame:frameRect
	       mode:aMode
	       prototype:[[class new] autorelease]
	       numberOfRows:rowsHigh
	       numberOfColumns:colsWide];
}

- (id)initWithFrame:(NSRect)frameRect
	       mode:(int)aMode
	  prototype:(NSCell*)prototype
       numberOfRows:(int)rows
    numberOfColumns:(int)cols
{
  int i, j;

  [super initWithFrame:frameRect];

  ASSIGN(cellPrototype, prototype);

  cells = [[NSMutableArray alloc] initWithCapacity:rows];
  selectedCells = newMatrix (rows, cols);
  for (i = 0; i < rows; i++) {
    NSMutableArray* row = [NSMutableArray arrayWithCapacity:cols];

    [cells addObject:row];
    for (j = 0; j < cols; j++) {
      [row addObject:[[cellPrototype copy] autorelease]];
    }
  }

  numRows = rows;
  numCols = cols;
  mode = aMode;
  [self setFrame:frameRect];

  cellSize = NSMakeSize(DEFAULT_CELL_WIDTH, DEFAULT_CELL_HEIGHT);
  intercell = NSMakeSize(1, 1);
  [self setBackgroundColor:[NSColor lightGrayColor]];
  [self setCellBackgroundColor:[NSColor lightGrayColor]];
  [self setSelectionByRect:YES];
  [self setAutosizesCells:YES];
  if (mode == NSRadioModeMatrix && numRows && numCols) {
    selectedRow = selectedColumn = 0;
    [self selectCellAtRow:0 column:0];
  }
  else
    selectedRow = selectedColumn = -1;

  return self;
}

- (void)dealloc
{
  [cells release];
  [cellPrototype release];
  [backgroundColor release];
  [cellBackgroundColor release];
  freeMatrix (selectedCells);
  [super dealloc];
}

- (void)addColumn
{
  [self insertColumn:numCols];
}

- (void)addColumnWithCells:(NSArray*)cellArray
{
  [self insertColumn:numCols withCells:cellArray];
}

- (void)addRow
{
  [self insertRow:numRows];
}

- (void)addRowWithCells:(NSArray*)cellArray
{
  [self insertRow:numRows withCells:cellArray];
}

- (void)insertColumn:(int)column
{
  int i;

  /* Grow the matrix if necessary */
  if (column >= numCols)
    [self renewRows:(numRows == 0 ? 1 : numRows) columns:column];
  if (numRows == 0) {
    numRows = 1;
    [cells addObject:[NSMutableArray array]];
  }

  numCols++;
  for (i = 0; i < numRows; i++)
    [self makeCellAtRow:i column:column];
  insertColumn (selectedCells, column);

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow:0 column:0];
}

- (void)insertColumn:(int)column withCells:(NSArray*)cellArray
{
  int i;

  /* Grow the matrix if necessary */
  if (column >= numCols)
    [self renewRows:(numRows == 0 ? 1 : numRows) columns:column];
  if (numRows == 0) {
    numRows = 1;
    [cells addObject:[NSMutableArray array]];
  }

  numCols++;
  for (i = 0; i < numRows; i++)
    [[cells objectAtIndex:i]
	replaceObjectAtIndex:column withObject:[cellArray objectAtIndex:i]];
  insertColumn (selectedCells, column);

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow:0 column:0];
}

- (void)insertRow:(int)row
{
  int i;

  /* Grow the matrix if necessary */
  if (row >= numRows)
    [self renewRows:row columns:(numCols == 0 ? 1 : numCols)];
  if (numCols == 0)
    numCols = 1;

  [cells insertObject:[NSMutableArray arrayWithCapacity:numCols] atIndex:row];

  numRows++;
  for (i = 0; i < numCols; i++)
    [self makeCellAtRow:row column:i];

  insertRow (selectedCells, row);

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow:0 column:0];
}

- (void)insertRow:(int)row withCells:(NSArray*)cellArray
{
  /* Grow the matrix if necessary */
  if (row >= numRows)
    [self renewRows:row columns:(numCols == 0 ? 1 : numCols)];
  if (numCols == 0)
    numCols = 1;

  [cells insertObject:[cellArray subarrayWithRange:NSMakeRange(0, numCols)]
	      atIndex:row];

  insertRow (selectedCells, row);

  numRows++;

  if (mode == NSRadioModeMatrix && !allowsEmptySelection && !selectedCell)
    [self selectCellAtRow:0 column:0];
}

- (NSCell*)makeCellAtRow:(int)row
		   column:(int)column
{
  NSCell* aCell;

  if (cellPrototype)
    aCell = [[cellPrototype copy] autorelease];
  else if (cellClass)
    aCell = [[cellClass new] autorelease];
  else
    aCell = [[NSActionCell new] autorelease];

  [[cells objectAtIndex:row] insertObject:aCell atIndex:column];
  return aCell;
}

- (NSRect)cellFrameAtRow:(int)row
		  column:(int)column
{
  NSRect rect;

  rect.origin.x = column * (cellSize.width + intercell.width);
#if HAS_FLIPPED_VIEWS
  rect.origin.y = row * (cellSize.height + intercell.height);
#else
  rect.origin.y = (numRows - row - 1) * (cellSize.height + intercell.height);
#endif
  rect.size = cellSize;
  return rect;
}

- (void)getNumberOfRows:(int*)rowCount
		columns:(int*)columnCount
{
    *rowCount = numRows;
    *columnCount = numCols;
}

- (void)putCell:(NSCell*)newCell
	  atRow:(int)row
	 column:(int)column
{
  [[cells objectAtIndex:row] replaceObjectAtIndex:column withObject:newCell];
  [self setNeedsDisplayInRect:[self cellFrameAtRow:row column:column]];
}

- (void)removeColumn:(int)column
{
  int i;

  if (column >= numCols)
    return;

  if (column == selectedColumn)
    [self selectCellAtRow:0 column:0];

  for (i = 0; i < numRows; i++)
    [[cells objectAtIndex:i] removeObjectAtIndex:column];

  removeColumn (selectedCells, column);
  numCols--;
}

- (void)removeRow:(int)row
{
  if (row >= numRows)
    return;

  if (row == selectedRow)
    [self selectCellAtRow:0 column:0];

  [cells removeObjectAtIndex:row];
  removeRow (selectedCells, row);
  numRows--;
}

- (void)renewRows:(int)newRows
	  columns:(int)newColumns
{
  int i, j;

  if (newColumns > numCols) {
    /* First check to see if the rows really have fewer cells than
       newColumns. This may happen because the row arrays are not shrink
       when a lower number of cells is given. */
    if (numRows && newColumns > [[cells objectAtIndex:0] count]) {
      /* Add columns to the existing rows. Call makeCellAtRow:column:
	 to be consistent. */
      for (i = 0; i < numRows; i++) {
	for (j = numCols; j < newColumns; j++)
	  [self makeCellAtRow:i column:j];
      }
    }
  }
  numCols = newColumns;

  if (newRows > numRows) {
    for (i = numRows; i < newRows; i++) {
      [cells addObject:[NSMutableArray arrayWithCapacity:numCols]];
      for (j = 0; j < numCols; j++)
	[self makeCellAtRow:i column:j];
    }
  }
  numRows = newRows;

  growMatrix (selectedCells, newRows, newColumns);
}

- (void)setCellSize:(NSSize)size
{
  cellSize = size;
  [self sizeToCells];
}

- (void)setIntercellSpacing:(NSSize)size
{
  intercell = size;
  [self sizeToCells];
}

- (void)sortUsingFunction:(int (*)(id element1, id element2, 
				   void *userData))comparator
		  context:(void*)context
{
  NSMutableArray* sorted = [NSMutableArray arrayWithCapacity:numRows*numCols];
  NSMutableArray* row;
  int i, j, index = 0;

  for (i = 0; i < numRows; i++)
    [sorted addObjectsFromArray:[[cells objectAtIndex:i]
				  subarrayWithRange:NSMakeRange(0, numCols)]];

  [sorted sortUsingFunction:comparator context:context];

  for (i = 0; i < numRows; i++) {
    row = [cells objectAtIndex:i];
    for (j = 0; j < numCols; j++) {
      [row replaceObjectAtIndex:j withObject:[sorted objectAtIndex:index]];
      index++;
    }
  }
}

- (void)sortUsingSelector:(SEL)comparator
{
  NSMutableArray* sorted = [NSMutableArray arrayWithCapacity:numRows*numCols];
  NSMutableArray* row;
  int i, j, index = 0;

  for (i = 0; i < numRows; i++)
    [sorted addObjectsFromArray:[[cells objectAtIndex:i]
				  subarrayWithRange:NSMakeRange(0, numCols)]];

  [sorted sortUsingSelector:comparator];

  for (i = 0; i < numRows; i++) {
    row = [cells objectAtIndex:i];
    for (j = 0; j < numCols; j++) {
      [row replaceObjectAtIndex:j withObject:[sorted objectAtIndex:index]];
      index++;
    }
  }
}

- (BOOL)getRow:(int*)row
	column:(int*)column
      forPoint:(NSPoint)aPoint
{
  BOOL isBetweenCells, insideBounds;

  insideBounds = [self _getRow:row column:column
		       forPoint:aPoint
		       above:NO right:NO
		       isBetweenCells:&isBetweenCells];

  if (!insideBounds || isBetweenCells)
    return NO;
  else return YES;
}

- (BOOL)getRow:(int*)row
	column:(int*)column
	ofCell:(NSCell*)aCell
{
  int i, j;

  for (i = 0; i < numRows; i++) {
    NSMutableArray* row = [cells objectAtIndex:i];

    for (j = 0; j < numCols; j++)
      if ([row objectAtIndex:j] == aCell)
	return YES;
  }

  return NO;
}

- (void)setState:(int)value
	   atRow:(int)row
	  column:(int)column
{
  NSCell* aCell = [self cellAtRow:row column:column];

  if (!aCell)
    return;

  if (mode == NSRadioModeMatrix) {
    if (value) {
      ASSIGN(selectedCell, aCell);
      selectedRow = row;
      selectedColumn = column;
      [selectedCell setState:1];
    }
    else if (allowsEmptySelection)
      [self deselectSelectedCell];
  }
  else
    [aCell setState:value];

  [self setNeedsDisplayInRect:[self cellFrameAtRow:row column:column]];
}

- (void)deselectAllCells
{
  int i, j;
  NSArray* row;
  NSCell* aCell;

  for (i = 0; i < numRows; i++) {
    row = [cells objectAtIndex:i];
    for (j = 0; j < numCols; j++)
      if (((tMatrix)selectedCells)->matrix[i][j]) {
	NSRect theFrame = [self cellFrameAtRow:i column:j];

	aCell = [row objectAtIndex:j];
	[aCell setState:0];
	[aCell highlight:NO withFrame:theFrame inView:self];
	[self setNeedsDisplayInRect:theFrame];
	((tMatrix)selectedCells)->matrix[i][j] = NO;
      }
  }
}

- (void)deselectSelectedCell
{
  [selectedCell setState:0];
  selectedCell = nil;
  selectedRow = -1;
  selectedColumn = -1;
}

- (void)selectAll:(id)sender
{
  int i, j;
  NSArray* row;

  /* Make the selected cell the cell at (0, 0) */
  ASSIGN(selectedCell, [self cellAtRow:0 column:0]);
  selectedRow = 0;
  selectedColumn = 0;

  for (i = 0; i < numRows; i++) {
    row = [cells objectAtIndex:i];

    for (j = 0; j < numCols; j++) {
      [[row objectAtIndex:j] setState:1];
      ((tMatrix)selectedCells)->matrix[i][j] = YES;
    }
  }

  [self display];
}

- (void)selectCellAtRow:(int)row
		 column:(int)column
{
  NSCell* aCell = [self cellAtRow:row column:column];

  if (mode == NSRadioModeMatrix) {
    /* Don't allow loosing of selection if in radio mode and empty selection
       not allowed. Otherwise deselect the selected cell. */
    if (!aCell && !allowsEmptySelection)
      return;
    else if (selectedCell)
      [selectedCell setState:0];
  }
  else if (!aCell)
    return;

  ASSIGN(selectedCell, aCell);
  selectedRow = row;
  selectedColumn = column;
  [selectedCell setState:1];

  [self setNeedsDisplayInRect:[self cellFrameAtRow:row column:column]];
}

- (BOOL)selectCellWithTag:(int)anInt
{
  NSMutableArray* row;
  id aCell;
  int i, j;

  for (i = numRows - 1; i >= 0; i--) {
    row = [cells objectAtIndex:i];
    for (j = numCols - 1; j >= 0; j --) {
      aCell = [row objectAtIndex:j];
      if ([aCell tag] == anInt) {
	[self selectCellAtRow:i column:j];
	return YES;
      }
    }
  }

  return NO;
}

- (NSArray*)selectedCells
{
  NSMutableArray* array = [NSMutableArray array];
  int i, j;

  for (i = 0; i < numRows; i++) {
    NSArray* row = [cells objectAtIndex:i];

    for (j = 0; j < numCols; j++)
      if (((tMatrix)selectedCells)->matrix[i][j])
	[array addObject:[row objectAtIndex:j]];
  }

  return array;
}

- (void)setSelectionFrom:(int)startPos
		      to:(int)endPos
		  anchor:(int)anchorPos
	       highlight:(BOOL)flag
{
  MPoint anchor = POINT_FROM_INDEX(anchorPos);
  MPoint last = POINT_FROM_INDEX(startPos);
  MPoint current = POINT_FROM_INDEX(endPos);

  if (selectionByRect)
    [self _selectRectUsingAnchor:anchor last:last current:current];
  else
    [self _selectContinuousUsingAnchor:anchor last:last current:current];
  [self display];
}

- (id)cellAtRow:(int)row
	 column:(int)column
{
  if (row < 0 || row >= numRows || column < 0 || column >= numCols)
    return nil;

  return [[cells objectAtIndex:row] objectAtIndex:column];
}

- (id)cellWithTag:(int)anInt
{
  NSMutableArray* row;
  id aCell;
  int i, j;

  for (i = numRows - 1; i >= 0; i--) {
    row = [cells objectAtIndex:i];
    for (j = numCols - 1; j >= 0; j --) {
      aCell = [row objectAtIndex:j];
      if ([aCell tag] == anInt)
	return aCell;
    }
  }

  return nil;
}

- (NSArray*)cells
{
  return cells;
}

- (void)selectText:(id)sender
{
// TODO
}

- (id)selectTextAtRow:(int)row
	       column:(int)column
{
// TODO
  return nil;
}

- (id)nextText
{
// TODO
  return nil;
}

- (id)previousText
{
// TODO
  return nil;
}

- (void)textDidBeginEditing:(NSNotification*)notification
{
}

- (void)textDidChange:(NSNotification*)notification
{
}

- (void)textDidEndEditing:(NSNotification*)notification
{
}

- (BOOL)textShouldBeginEditing:(NSText*)textObject
{
  return YES;
}

- (BOOL)textShouldEndEditing:(NSText*)textObject
{
  return YES;
}

- (void)setNextText:(id)anObject
{
// TODO
}

- (void)setPreviousText:(id)anObject
{
// TODO
}

- (void)setValidateSize:(BOOL)flag
{
// TODO
}

- (void)sizeToCells
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
  [self setFrameSize:newSize];
}

- (void)scrollCellToVisibleAtRow:(int)row
			  column:(int)column
{
  [self scrollRectToVisible:[self cellFrameAtRow:row column:column]];
}

- (void)setAutoscroll:(BOOL)flag
{
    autoscroll = flag;
}

- (void)setScrollable:(BOOL)flag
{
  int i, j;

  for (i = 0; i < numRows; i++) {
    NSArray* row = [cells objectAtIndex:i];

    for (j = 0; j < numCols; j++)
      [[row objectAtIndex:j] setScrollable:flag];
  }
  [cellPrototype setScrollable:flag];
}

- (void)drawRect:(NSRect)rect
{
  int i, j;
  int row1, col1;	// The cell at the upper left corner
  int row2, col2;	// The cell at the lower right corner
  NSRect intRect, upperLeftRect;
  NSArray* row;

  [self _getRow:&row1 column:&col1
#if HAS_FLIPPED_VIEWS
       forPoint:rect.origin
#else
       forPoint:NSMakePoint (rect.origin.x, rect.origin.y + rect.size.height)
#endif
	  above:NO right:NO
	isBetweenCells:NULL];
  [self _getRow:&row2 column:&col2
#if HAS_FLIPPED_VIEWS
	  forPoint:NSMakePoint(rect.origin.x + rect.size.width,
			       rect.origin.y + rect.size.height)
#else
	  forPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y)
#endif
	  above:NO right:NO
	  isBetweenCells:NULL];

  if (row1 < 0)
    row1 = 0;
  if (col1 < 0)
    col1 = 0;

//  NSLog (@"display cells between (%d, %d) and (%d, %d)",
//	 row1, col1, row2, col2);

  /* Draw the cells within the drawing rectangle. */
  intRect = upperLeftRect = [self cellFrameAtRow:row1 column:col1];
  for (i = row1; i <= row2 && i < numRows; i++) {
    row = [cells objectAtIndex:i];
    intRect.origin.x = upperLeftRect.origin.x;

    for (j = col1; j <= col2 && j < numCols; j++) {
      NSCell *aCell = [row objectAtIndex:j];
      [aCell drawWithFrame:intRect inView:self];
      intRect.origin.x += cellSize.width + intercell.width;
    }
#if HAS_FLIPPED_VIEWS
    intRect.origin.y += cellSize.height + intercell.height;
#else
    intRect.origin.y -= cellSize.height + intercell.height;
#endif
  }
}

- (void)drawCellAtRow:(int)row
	       column:(int)column
{
  NSCell *aCell = [self cellAtRow:row column:column];
  NSRect cellFrame = [self cellFrameAtRow:row column:column];

  [aCell drawWithFrame:cellFrame inView:self];
}

- (void)highlightCell:(BOOL)flag
		atRow:(int)row
	       column:(int)column
{
  NSCell *aCell = [self cellAtRow:row column:column];
  NSRect cellFrame;

  if (aCell) {
    cellFrame = [self cellFrameAtRow:row column:column];
    [aCell highlight:flag
	   withFrame:[self cellFrameAtRow:row column:column]
	   inView:self];
  }
}

- (BOOL)sendAction
{
  SEL theAction;
  id theTarget;

  if (![selectedCell isEnabled])
    return NO;

  theAction = [selectedCell action];
  theTarget = [selectedCell target];

  if (theAction) {
    if (theTarget)
      [selectedCell performSelector:theAction withObject:self];
    else
      [target performSelector:theAction withObject:self];
  }
  else
    [target performSelector:action withObject:self];

  return YES;
}

- (void)sendAction:(SEL)aSelector
		to:(id)anObject
       forAllCells:(BOOL)flag
{
  int i, j;

  if (flag) {
    for (i = 0; i < numRows; i++) {
      NSMutableArray* row = [cells objectAtIndex:i];

      for (j = 0; j < numCols; j++)
	if (![anObject performSelector:aSelector
		       withObject:[row objectAtIndex:j]])
	  return;
    }
  }
  else {
    for (i = 0; i < numRows; i++) {
      BOOL* row = ((tMatrix)selectedCell)->matrix[i];
      NSMutableArray* cellRow = [cells objectAtIndex:i];

      for (j = 0; j < numCols; j++)
	if (row[i])
	  if (![anObject performSelector:aSelector
			      withObject:[cellRow objectAtIndex:j]])
	    return;
    }
  }
}

- (void)sendDoubleAction
{
  if (![selectedCell isEnabled])
    return;

  if (doubleAction)
    [target performSelector:doubleAction withObject:self];
  else
    [self sendAction];
}

- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
  return mode == NSListModeMatrix ? NO : YES;
}

- (void)mouseDown:(NSEvent*)theEvent
{
  BOOL isBetweenCells, insideBounds;
  int row, column;
  unsigned eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
    | NSMouseMovedMask | NSLeftMouseDraggedMask | NSPeriodicMask;
  NSPoint lastLocation = [theEvent locationInWindow];
  NSEvent* lastEvent = nil;
  BOOL done = NO;
  NSRect rect;
  id aCell, previousCell = nil;
  NSRect previousCellRect;
  MPoint anchor;

  mouseDownFlags = [theEvent modifierFlags];
  lastLocation = [self convertPoint:lastLocation fromView:nil];
  if (mode != NSTrackModeMatrix)
    [NSEvent startPeriodicEventsAfterDelay:0.05 withPeriod:0.05];
  ASSIGN(lastEvent, theEvent);

  // capture mouse
  [[self window] captureMouse: self];

  [self lockFocus];

  while (!done) {
    BOOL shouldProceedEvent = NO;

    insideBounds = [self _getRow:&row
			  column:&column
			forPoint:lastLocation
			   above:NO right:NO
		  isBetweenCells:&isBetweenCells];
    if (insideBounds && !isBetweenCells) {
      aCell = [self cellAtRow:row column:column];
      rect = [self cellFrameAtRow:row column:column];

      switch (mode) {
	case NSTrackModeMatrix:
	  ASSIGN(selectedCell, aCell);
	  selectedRow = row;
	  selectedColumn = column;

	  [selectedCell trackMouse:lastEvent
			    inRect:rect
			    ofView:self
		      untilMouseUp:YES];
	  done = YES;
	  break;

	case NSHighlightModeMatrix:
	  if (previousCell == aCell)
	    break;

	  [previousCell highlight:NO withFrame:previousCellRect inView:self];
	  [self setNeedsDisplayInRect:previousCellRect];
	  ASSIGN(selectedCell, aCell);
	  selectedRow = row;
	  selectedColumn = column;
	  [selectedCell highlight:YES withFrame:rect inView:self];
	  [self setNeedsDisplayInRect:rect];
	  break;

	case NSRadioModeMatrix:
	  if (previousCell == aCell)
	    break;

	  /* At the first click, deselect the selected cell */
	  if (!previousCell) {
	    NSRect f = [self cellFrameAtRow:selectedRow column:selectedColumn];

	    [self deselectSelectedCell];
	    [self setNeedsDisplayInRect:f];
	  }
	  else {
	    [previousCell highlight:NO withFrame:previousCellRect inView:self];
	    [self setNeedsDisplayInRect:previousCellRect];
	  }

	  ASSIGN(selectedCell, aCell);
	  selectedRow = row;
	  selectedColumn = column;
	  [selectedCell highlight:YES withFrame:rect inView:self];
	  [self setNeedsDisplayInRect:rect];
	  break;

	case NSListModeMatrix: {
	  unsigned modifiers = [lastEvent modifierFlags];

	  if (previousCell == aCell)
	    break;

	  /* When the user first clicks on a cell we clear the existing
	    selection unless Alternate or Shift key modifiers have been
	    pressed. */
	  if (!previousCell) {
	    if (!(modifiers & NSShiftKeyMask) &&
		!(modifiers & NSAlternateKeyMask))
	      [self deselectAllCells];

	    if ((modifiers & NSAlternateKeyMask))
	      /* Consider the selected cell as the anchor to allow extending
		the selection to the current cell. */
	      anchor = MakePoint (selectedColumn, selectedRow);
	    else {
	      anchor = MakePoint (column, row);

	      ASSIGN(selectedCell, aCell);
	      selectedRow = row;
	      selectedColumn = column;

	      [selectedCell setState:1];
	      [selectedCell highlight:YES withFrame:rect inView:self];
	      ((tMatrix)selectedCells)->matrix[row][column] = YES;
	      [self setNeedsDisplayInRect:rect];
	      break;
	    }
	  }

	  if (selectionByRect)
	    [self _selectRectUsingAnchor:anchor
				last:MakePoint (selectedColumn, selectedRow)
				current:MakePoint (column, row)];
	  else
	    [self _selectContinuousUsingAnchor:anchor
				last:MakePoint (selectedColumn, selectedRow)
				current:MakePoint (column, row)];

	  ASSIGN(selectedCell, aCell);
	  selectedRow = row;
	  selectedColumn = column;
	  break;
	}
      }

      previousCell = aCell;
      previousCellRect = rect;
      [self scrollRectToVisible:rect];
    }

    if (done)
      break;

    /* Get the next event */
    while (!shouldProceedEvent) {
      theEvent = [[NSApplication sharedApplication]
		   nextEventMatchingMask:eventMask
		   untilDate:[NSDate distantFuture]
		   inMode:NSEventTrackingRunLoopMode
		   dequeue:YES];
      switch ([theEvent type]) {
	case NSPeriodic:
	  NSDebugLog(@"NSMatrix: got NSPeriodic event\n");
	  shouldProceedEvent = YES;
	  break;
	case NSLeftMouseUp:
	  done = YES;
	  shouldProceedEvent = YES;
	  ASSIGN(lastEvent, theEvent);
	  break;
	default:
	  NSDebugLog(@"NSMatrix: got event type: %d\n", [theEvent type]);
	  ASSIGN(lastEvent, theEvent);
	  continue;
      }
    }
    lastLocation = [lastEvent locationInWindow];
    lastLocation = [self convertPoint:lastLocation fromView:nil];
  }

  // Release mouse
  [[self window] releaseMouse: self];

  /* Finalize the selection */
  switch (mode) {
    case NSTrackModeMatrix:
    case NSHighlightModeMatrix:
      [selectedCell setState:![selectedCell state]];
      [selectedCell highlight:NO withFrame:rect inView:self];
      [self setNeedsDisplayInRect:rect];
      break;
    case NSRadioModeMatrix:
      [selectedCell setState:1];
      [selectedCell highlight:NO withFrame:rect inView:self];
      [self setNeedsDisplayInRect:rect];
      break;
    case NSListModeMatrix:
      break;
  }

  if ([selectedCell target])
    [[selectedCell target] performSelector:[selectedCell action] withObject:self];
  else if (target)
    [target performSelector:action withObject:self];

  [self unlockFocus];
  if (mode != NSTrackModeMatrix)
    [NSEvent stopPeriodicEvents];
  [lastEvent release];
}

- (BOOL)performKeyEquivalent:(NSEvent*)theEvent
{
  int i, j;
  NSMutableArray* row;
  NSString* key = [theEvent charactersIgnoringModifiers];

  for (i = 0; i < numRows; i++) {
    row = [cells objectAtIndex:i];
    for (j = 0; j < numCols; j++) {
      NSCell* aCell = [row objectAtIndex:j];

      if ([aCell isEnabled] && [[aCell keyEquivalent] isEqualToString:key]) {
	NSCell* oldSelectedCell = selectedCell;

	selectedCell = aCell;
	[self highlightCell:YES atRow:i column:j];
	[aCell setState:![aCell state]];
	[self sendAction];
	[self highlightCell:NO atRow:i column:j];
	selectedCell = oldSelectedCell;

	return YES;
      }
    }
  }

  return NO;
}

- (void)resetCursorRects
{
  int i, j;

  for (i = 0; i < numRows; i++) {
    NSArray* row = [cells objectAtIndex:i];

    for (j = 0; j < numCols; j++) {
      NSCell* aCell = [row objectAtIndex:j];
      [aCell resetCursorRect:[self cellFrameAtRow:i column:j] inView:self];
    }
  }
}

- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

- (void)setMode:(NSMatrixMode)aMode	{ mode = aMode; }
- (NSMatrixMode)mode			{ return mode; }
- (void)setCellClass:(Class)class	{ cellClass = class; }
- (Class)cellClass			{ return cellClass; }
- (void)setPrototype:(NSCell*)aCell	{ ASSIGN(cellPrototype, aCell) }
- (id)prototype				{ return cellPrototype; }
- (NSSize)cellSize			{ return cellSize; }
- (NSSize)intercellSpacing		{ return intercell; }
- (void)setBackgroundColor:(NSColor*)c	{ ASSIGN(backgroundColor, c) }
- (NSColor*)backgroundColor		{ return backgroundColor; }
- (void)setCellBackgroundColor:(NSColor*)c { ASSIGN(cellBackgroundColor, c) }
- (NSColor*)cellBackgroundColor		{ return cellBackgroundColor; }
- (void)setDelegate:(id)object		{ ASSIGN(delegate, object) }
- (id)delegate				{ return delegate; }
- (void)setTarget:anObject		{ ASSIGN(target, anObject) }
- (id)target				{ return target; }
- (void)setAction:(SEL)sel		{ action = sel; }
- (SEL)action				{ return action; }
- (void)setDoubleAction:(SEL)sel	{ doubleAction = sel; }
- (SEL)doubleAction			{ return doubleAction; }
- (void)setErrorAction:(SEL)sel		{ errorAction = sel; }
- (SEL)errorAction			{ return errorAction; }
- (void)setAllowsEmptySelection:(BOOL)f	{ allowsEmptySelection = f; }
- (BOOL)allowsEmptySelection		{ return allowsEmptySelection; }
- (void)setSelectionByRect:(BOOL)flag	{ selectionByRect = flag; }
- (BOOL)isSelectionByRect		{ return selectionByRect; }
- (void)setDrawsBackground:(BOOL)flag	{ drawsBackground = flag; }
- (BOOL)drawsBackground			{ return drawsBackground; }
- (void)setDrawsCellBackground:(BOOL)f	{ drawsCellBackground = f; }
- (BOOL)drawsCellBackground		{ return drawsCellBackground; }
- (void)setAutosizesCells:(BOOL)flag	{ autosizesCells = flag; }
- (BOOL)autosizesCells			{ return autosizesCells; }
- (BOOL)isAutoscroll			{ return autoscroll; }
- (int)numberOfRows			{ return numRows; }
- (int)numberOfColumns			{ return numCols; }
- (id)selectedCell			{ return selectedCell; }
- (int)selectedColumn			{ return selectedColumn; }
- (int)selectedRow			{ return selectedRow; }
- (int)mouseDownFlags		   	{ return mouseDownFlags; }

#if HAS_FLIPPED_VIEWS
- (BOOL)isFlipped			{ return YES; }
#endif

@end


@implementation NSMatrix (PrivateMethods)

#define SET_POINTER_VALUE(pointer, value) \
  do { if (pointer) *pointer = value; } while (0)

/* Returns by reference the row and column of cell that is above or below or
   to the left or to the right of point. `point' is in the matrix coordinates.
   Returns NO if the point is outside the bounds of matrix, YES otherwise.

   Note that the cell numbering is flipped relative to the coordinate system.
 */
- (BOOL)_getRow:(int*)row
  column:(int*)column
  forPoint:(NSPoint)point
  above:(BOOL)aboveRequired
  right:(BOOL)rightRequired
  isBetweenCells:(BOOL*)isBetweenCells
{
  BOOL rowReady = NO, colReady = NO;
  BOOL betweenRows = NO, betweenCols = NO;
  NSRect theBounds = [self bounds];

  SET_POINTER_VALUE(isBetweenCells, NO);

  /* First check the limit cases */
  if (point.x > theBounds.size.width) {
    SET_POINTER_VALUE(column, numCols);
    colReady = YES;
  }
  else if (point.x < 0) {
    SET_POINTER_VALUE(column, 0);
    colReady = YES;
  }

  if (point.y > theBounds.size.height) {
    SET_POINTER_VALUE(row, numRows);
    rowReady = YES;
  }
  else if (point.y < 0) {
    SET_POINTER_VALUE(row, 0);
    rowReady = YES;
  }

  if (rowReady && colReady)
    return NO;

  if (!rowReady) {
    int approxRow = point.y / (cellSize.height + intercell.height);
    float approxRowsHeight = approxRow * (cellSize.height + intercell.height);

    /* Determine if the point is inside the cell */
    betweenRows = !(point.y > approxRowsHeight
		    && point.y <= approxRowsHeight + cellSize.height);

    /* If the point is between cells then adjust the computed row taking into
       account the `aboveRequired' flag. */
    if (aboveRequired && betweenRows)
      approxRow++;

#if HAS_FLIPPED_VIEWS
    SET_POINTER_VALUE(row, approxRow);
#else
    SET_POINTER_VALUE(row, numRows - approxRow - 1);
#endif
    if (*row < 0) {
      *row = -1;
      rowReady = YES;
    }
    else if (*row >= numRows) {
      *row = numRows - 1;
      rowReady = YES;
    }
  }

  if (!colReady) {
    int approxCol = point.x / (cellSize.width + intercell.width);
    float approxColsWidth = approxCol * (cellSize.width + intercell.width);

    /* Determine if the point is inside the cell */
    betweenCols = !(point.x > approxColsWidth
		    && point.x <= approxColsWidth + cellSize.width);

    /* If the point is between cells then adjust the computed column taking
       into account the `rightRequired' flag. */
    if (rightRequired && betweenCols)
      approxCol++;

    SET_POINTER_VALUE(column, approxCol);
    if (*column < 0) {
      *column = -1;
      colReady = YES;
    }
    else if (*column >= numCols) {
      *column = numCols - 1;
      colReady = YES;
    }
  }

  /* If the point is outside the matrix bounds return NO */
  if (rowReady || colReady)
    return NO;

  if (betweenRows || betweenCols)
    SET_POINTER_VALUE(isBetweenCells, YES);
  return YES;
}

/* This method is used to select cells in the list mode with selection by rect
  option enabled. `anchor' is the first point in the selection (the coordinates
  of the cell first clicked). `last' is the last point up to which the anterior
  selection has been made. `current' is the point to which we must extend the
  selection. */

- (void)_selectRectUsingAnchor:(MPoint)anchor
		      last:(MPoint)last
		   current:(MPoint)current
{
  /* We use an imaginar coordinate system whose center is the `anchor' point.
    We should determine in which quadrants are located the `last' and the
    `current' points. Based on this we extend the selection to the rectangle
    determined by `anchor' and `current' points.

    The algorithm uses two rectangles: one determined by `anchor' and
    `current' that defines how the final selection rectangle will look, and
    another one determined by `anchor' and `last' that defines the current
    visible selection.

    The three points above determine 9 distinct zones depending on the
    position of `last' and `current' relative to `anchor'. Each of these
    zones have a different way of extending the selection from `last' to
    `current'.

    Note the coordinate system is a flipped one not a usual geometric one
    (the y coordinate increases downward).
  */

  int dxca = current.x - anchor.x;
  int dyca = current.y - anchor.y;
  int dxla = last.x - anchor.x;
  int dyla = last.y - anchor.y;
  int dxca_dxla, dyca_dyla;
  int selectRectsNo = 0;
  MRect selectRect[2];
  int unselectRectsNo = 0;
  MRect unselectRect[2];
  int tmpx, tmpy;
  int i;

  dxca_dxla = SIGN(dxca) / (SIGN(dxla) ? SIGN(dxla) : 1);
  dyca_dyla = SIGN(dyca) / (SIGN(dyla) ? SIGN(dyla) : 1);

  if (dxca_dxla >= 0) {
    if (dyca_dyla >= 0) {
      /* `current' is in the lower right quadrant. */
      if (ABS(dxca) <= ABS(dxla)) {
	if (ABS(dyca) <= ABS(dyla)) {
	  /* `current' is in zone I. */

	  NSDebugLog (@"zone I");

	  if (dxca != dxla) {
	    i = unselectRectsNo++;
	    tmpx = dxca > 0 ? current.x + 1 : current.x + SIGN(dxla);
	    unselectRect[i].x = MIN(tmpx, last.x);
	    unselectRect[i].y = MIN(anchor.y, current.y);
	    unselectRect[i].width = ABS(last.x - tmpx);
	    unselectRect[i].height = ABS(current.y - anchor.y);
	  }

	  if (dyca != dyla) {
	    i = unselectRectsNo++;
	    tmpy = dyca > 0 ? current.y + 1 : current.y + SIGN(dyla);
	    unselectRect[i].x = MIN(anchor.x, last.x);
	    unselectRect[i].y = MIN(tmpy, last.y);
	    unselectRect[i].width = ABS(last.x - anchor.x);
	    unselectRect[i].height = ABS(last.y - tmpy);
	  }
	}
	else {
	  /* `current' is in zone F. */

	  NSDebugLog (@"zone F");

	  selectRectsNo = 1;

	  tmpy = dyla >= 0 ? last.y + 1 : last.y - 1;
	  selectRect[0].x = MIN(anchor.x, current.x);
	  selectRect[0].y = MIN(tmpy, current.y);
	  selectRect[0].width = ABS(current.x - anchor.x);
	  selectRect[0].height = ABS(current.y - tmpy);

	  if (dxca != dxla) {
	    unselectRectsNo = 1;
	    tmpx = dxca > 0 ? current.x + 1 : current.x + SIGN(dxla);
	    unselectRect[0].x = MIN(tmpx, last.x);
	    unselectRect[0].y = MIN(anchor.y, last.y);
	    unselectRect[0].width = ABS(last.x - tmpx);
	    unselectRect[0].height = ABS(last.y - anchor.y);
	  }
	}
      }
      else {
	if (ABS(dyca) <= ABS(dyla)) {
	  /* `current' is in zone H. */

	  NSDebugLog (@"zone H");
	  selectRectsNo = 1;

	  tmpx = dxla >= 0 ? last.x + 1 : last.x - 1;
	  selectRect[0].x = MIN(tmpx, current.x);
	  selectRect[0].y = MIN(anchor.y, current.y);
	  selectRect[0].width = ABS(current.x - tmpx);
	  selectRect[0].height = ABS(current.y - anchor.y);

	  if (dyca != dyla) {
	    unselectRectsNo = 1;

	    tmpy = dyca >= 0 ? current.y + 1 : current.y - 1;
	    unselectRect[0].x = MIN(anchor.x, last.x);
	    unselectRect[0].y = MIN(tmpy, last.y);
	    unselectRect[0].width = ABS(last.x - anchor.x);
	    unselectRect[0].height = ABS(last.y - tmpy);
	  }
	}
	else {
	  /* `current' is in zone G. */

	  NSDebugLog (@"zone G");
	  selectRectsNo = 2;

	  tmpx = dxla >= 0 ? last.x + 1 : last.x - 1;
	  selectRect[0].x = MIN(tmpx, current.x);
	  selectRect[0].y = MIN(anchor.y, last.y);
	  selectRect[0].width = ABS(current.x - tmpx);
	  selectRect[0].height = ABS(last.y - anchor.y);

	  tmpy = dyla >= 0 ? last.y + 1 : last.y - 1;
	  selectRect[1].x = MIN(anchor.x, current.x);
	  selectRect[1].y = MIN(tmpy, current.y);
	  selectRect[1].width = ABS(current.x - anchor.x);
	  selectRect[1].height = ABS(current.y - tmpy);
	}
      }
    }
    else {
      /* `current' is in the upper right quadrant */

      if (ABS(dxca) <= ABS(dxla)) {
	/* `current' is in zone B. */

	NSDebugLog (@"zone B");

	selectRectsNo = 1;
	tmpy = dyca > 0 ? anchor.y + 1 : anchor.y - 1;
	selectRect[0].x = MIN(anchor.x, current.x);
	selectRect[0].y = MIN(current.y, tmpy);
	selectRect[0].width = ABS(current.x - anchor.x);
	selectRect[0].height = ABS(tmpy - current.y);

	if (dyla) {
	  unselectRectsNo = 1;
	  tmpy = dyca < 0 ? anchor.y + 1 : anchor.y + SIGN(dyla);
	  unselectRect[0].x = MIN(anchor.x, current.x);
	  unselectRect[0].y = MIN(tmpy, last.y);
	  unselectRect[0].width = ABS(last.x - anchor.x);
	  unselectRect[0].height = ABS(last.y - tmpy);
	}

	if (dxla && dxca != dxla) {
	  i = unselectRectsNo++;
	  tmpx = dxca > 0 ? current.x + 1 : current.x + SIGN(dxla);
	  unselectRect[i].x = MIN(tmpx, last.x);
	  unselectRect[i].y = MIN(anchor.y, last.y);
	  unselectRect[i].width = ABS(last.x - tmpx);
	  unselectRect[i].height = ABS(last.y - anchor.y);
	}
      }
      else {
	/* `current' is in zone A. */

	NSDebugLog (@"zone A");

	if (dyca != dyla) {
	  i = selectRectsNo++;
	  tmpy = dyca < 0 ? anchor.y - 1 : anchor.y + 1;
	  selectRect[i].x = MIN(anchor.x, last.x);
	  selectRect[i].y = MIN(tmpy, current.y);
	  selectRect[i].width = ABS(last.x - anchor.x);
	  selectRect[i].height = ABS(current.y - tmpy);
	}

	i = selectRectsNo++;
	tmpx = dxca > 0 ? last.x + 1 : last.x - 1;
	selectRect[i].x = MIN(tmpx, current.x);
	selectRect[i].y = MIN(current.y, anchor.y);
	selectRect[i].width = ABS(current.x - tmpx);
	selectRect[i].height = ABS(anchor.y - current.y);

	if (dyla) {
	  unselectRectsNo = 1;
	  tmpy = dyca < 0 ? anchor.y + 1 : anchor.y - 1;
	  unselectRect[0].x = MIN(anchor.x, last.x);
	  unselectRect[0].y = MIN(tmpy, last.y);
	  unselectRect[0].width = ABS(last.x - anchor.x);
	  unselectRect[0].height = ABS(last.y - tmpy);
	}
      }
    }
  }
  else {
    if (dyca_dyla > 0) {
      /* `current' is in the lower left quadrant */
      if (ABS(dyca) <= ABS(dyla)) {
	/* `current' is in zone D. */

	NSDebugLog (@"zone D");
	selectRectsNo = 1;

	tmpx = dxca < 0 ? anchor.x - 1 : anchor.x + 1;
	selectRect[0].x = MIN(tmpx, current.x);
	selectRect[0].y = MIN(anchor.y, current.y);
	selectRect[0].width = ABS(current.x - tmpx);
	selectRect[0].height = ABS(current.y - anchor.y);

	if (dxla) {
	  unselectRectsNo = 1;
	  tmpx = dxca < 0 ? anchor.x + 1 : anchor.x - 1;
	  unselectRect[0].x = MIN(tmpx, last.x);
	  unselectRect[0].y = MIN(anchor.y, current.y);
	  unselectRect[0].width = ABS(last.x - tmpx);
	  unselectRect[0].height = ABS(current.y - anchor.y);
	}

	if (dyla && dyca != dyla) {
	  i = unselectRectsNo++;
	  tmpy = dyca > 0 ? current.y + 1 : current.y + SIGN(dyla);
	  unselectRect[i].x = MIN(anchor.x, last.x);
	  unselectRect[i].y = MIN(tmpy, last.y);
	  unselectRect[i].width = ABS(last.x - anchor.x);
	  unselectRect[i].height = ABS(last.y - tmpy);
	}
      }
      else {
	/* `current' is in zone E. */

	NSDebugLog (@"zone E");

	i = selectRectsNo++;
	tmpx = dxca > 0 ? anchor.x + 1 : anchor.x - 1;
	selectRect[i].x = MIN(tmpx, current.x);
	selectRect[i].y = MIN(anchor.y, last.y);
	selectRect[i].width = ABS(current.x - tmpx);
	selectRect[i].height = ABS(last.y - anchor.y);

	i = selectRectsNo++;
	tmpy = dyca > 0 ? last.y + 1 : last.y - 1;
	selectRect[i].x = MIN(current.x, anchor.x);
	selectRect[i].y = MIN(current.y, tmpy);
	selectRect[i].width = ABS(anchor.x - current.x);
	selectRect[i].height = ABS(tmpy - current.y);

	if (dxla) {
	  unselectRectsNo = 1;
	  tmpx = dxca > 0 ? anchor.x - 1 : anchor.x + 1;
	  unselectRect[0].x = MIN(tmpx, last.x);
	  unselectRect[0].y = MIN(anchor.y, last.y);
	  unselectRect[0].width = ABS(last.x - tmpx);
	  unselectRect[0].height = ABS(last.y - anchor.y);
	}
      }
    }
    else {
      /* `current' is in zone C. */

      NSDebugLog (@"zone C");
      selectRectsNo = 1;

      selectRect[0].x = MIN(current.x, anchor.x);
      selectRect[0].y = MIN(current.y, anchor.y);
      selectRect[0].width = ABS(anchor.x - current.x);
      selectRect[0].height = ABS(anchor.y - current.y);

      if (dyca != dyla) {
	unselectRectsNo = 1;
	unselectRect[0].x = MIN(anchor.x, last.x);
	unselectRect[0].y = MIN(anchor.y, last.y);
	unselectRect[0].width = ABS(last.x - anchor.x);
	unselectRect[0].height = ABS(last.y - anchor.y);
      }
    }
  }

  /* In this point we know what are the rectangles that must be unselected and
    those that must be selected. Iterate on them and do the work. First unselect
    and only then do the cells selection. */
  for (i = 0; i < unselectRectsNo; i++)
    [self _setState:0 inRect:unselectRect[i]];
  for (i = 0; i < selectRectsNo; i++)
    [self _setState:1 inRect:selectRect[i]];
}

- (void)_setState:(int)state inRect:(MRect)matrixRect
{
  int i, j, rowNo, colNo;
  NSArray* row;
  NSCell* aCell;
  NSRect rect, upperLeftRect;
  BOOL highlight = state ? YES : NO;
  int cellsCount = [cells count];
  int rowCount;

  rect = upperLeftRect = [self cellFrameAtRow:matrixRect.y column:matrixRect.x];

  for (i = 0, rowNo = matrixRect.y;
       i <= matrixRect.height && rowNo < cellsCount;
       i++, rowNo++) {
    row = [cells objectAtIndex:rowNo];
    rowCount = [row count];
    rect.origin.x = upperLeftRect.origin.x;

    for (j = 0, colNo = matrixRect.x;
	 j <= matrixRect.width && colNo < rowCount;
	 j++, colNo++) {
      aCell = [row objectAtIndex:colNo];
      [aCell setState:state];
      [aCell highlight:highlight withFrame:rect inView:self];
      [self setNeedsDisplayInRect:rect];
      ((tMatrix)selectedCells)->matrix[rowNo][colNo] = YES;
      rect.origin.x += cellSize.width + intercell.width;
    }
    rect.origin.y -= cellSize.height + intercell.height;
  }
}


/* This method is used to select and unselect the cells in the list mode with
  selection by rect option disabled. This method has a far lower complexity than
  the similar method used by list mode with selection by rect option. */
- (void)_selectContinuousUsingAnchor:(MPoint)anchor
			       last:(MPoint)last
			    current:(MPoint)current
{
  /* The idea is to compare the points based on their linear index in matrix and
  do the appropriate action. */

  int anchorIndex = INDEX_FROM_POINT(anchor);
  int lastIndex = INDEX_FROM_POINT(last);
  int currentIndex = INDEX_FROM_POINT(current);
  BOOL doSelect = NO;
  MPoint selectPoint;
  BOOL doUnselect = NO;
  MPoint unselectPoint;

  int dca = currentIndex - anchorIndex;
  int dla = lastIndex - anchorIndex;
  int dca_dla = SIGN(dca) / (SIGN(dla) ? SIGN(dla) : 1);

  if (dca_dla >= 0) {
    if (ABS(dca) >= ABS(dla)) {
      doSelect = YES;
      if (currentIndex > lastIndex) {
	selectPoint.x = lastIndex;
	selectPoint.y = currentIndex;
      }
      else {
	selectPoint.x = currentIndex;
	selectPoint.y = lastIndex;
      }
    }
    else {
      doUnselect = YES;
      if (currentIndex < lastIndex) {
	unselectPoint.x = currentIndex + 1;
	unselectPoint.y = lastIndex;
      }
      else {
	unselectPoint.x = lastIndex;
	unselectPoint.y = currentIndex - 1;
      }
    }
  }
  else {
    doSelect = YES;
    if (anchorIndex < currentIndex) {
      selectPoint.x = anchorIndex;
      selectPoint.y = currentIndex;
    }
    else {
      selectPoint.x = currentIndex;
      selectPoint.y = anchorIndex;
    }

    doUnselect = YES;
    if (anchorIndex < lastIndex) {
      unselectPoint.x = anchorIndex;
      unselectPoint.y = lastIndex;
    }
    else {
      unselectPoint.x = lastIndex;
      unselectPoint.y = anchorIndex;
    }
  }

  if (doUnselect)
    [self _setState:0 startIndex:unselectPoint.x endIndex:unselectPoint.y];
  if (doSelect)
    [self _setState:1 startIndex:selectPoint.x endIndex:selectPoint.y];
}

- (void)_setState:(int)state startIndex:(int)start endIndex:(int)end
{
  int i, j, colLimit;
  NSArray* row;
  NSCell* aCell;
  NSRect rect, upperLeftRect;
  BOOL highlight = state ? YES : NO;
  MPoint startPoint = POINT_FROM_INDEX(start);
  MPoint endPoint = POINT_FROM_INDEX(end);

  rect = upperLeftRect = [self cellFrameAtRow:startPoint.y column:0];

  for (i = startPoint.y; i <= endPoint.y; i++) {
    row = [cells objectAtIndex:i];

    if (i == startPoint.y) {
      j = startPoint.x;
      rect.origin.x = upperLeftRect.origin.x
		      + j * (cellSize.width + intercell.width);
    }
    else {
      j = 0;
      rect.origin.x = upperLeftRect.origin.x;
    }

    if (i == endPoint.y)
      colLimit = endPoint.x;
    else
      colLimit = numCols - 1;

    for (; j <= colLimit; j++) {
      aCell = [row objectAtIndex:j];
      [aCell setState:state];
      [aCell highlight:highlight withFrame:rect inView:self];
      [self setNeedsDisplayInRect:rect];
      ((tMatrix)selectedCells)->matrix[i][j] = YES;
      rect.origin.x += cellSize.width + intercell.width;
    }
    rect.origin.y -= cellSize.height + intercell.height;
  }
}

#ifdef DEBUG
#include <stdio.h>

/* A test to exhaustively check if the list selection mode works correctly. */
- (void)_selectRect2UsingAnchor:(MPoint)anchor
		      last:(MPoint)last
		   current:(MPoint)current
{
  MRect selectRect;
  MRect unselectRect;

  selectRect.x = MIN(anchor.x, current.x);
  selectRect.y = MIN(anchor.y, current.y);
  selectRect.width = ABS(current.x - anchor.x);
  selectRect.height = ABS(current.y - anchor.y);

  unselectRect.x = MIN(anchor.x, last.x);
  unselectRect.y = MIN(anchor.y, last.y);
  unselectRect.width = ABS(current.x - last.x);
  unselectRect.height = ABS(current.y - last.y);

  [self _setState:0 inRect:unselectRect];
  [self _setState:1 inRect:selectRect];
}

/* This method assumes the receiver matrix has at least 5 rows and 5 columns.
 */
- (void)_test
{
  NSArray* selectedCellsByMethod1;
  NSArray* selectedCellsByMethod2;
  NSAutoreleasePool* pool;
  MPoint anchor, last, current;
  int i = 1;
  int noOfErrors = 0;

  if (numRows < 5 || numCols < 5) {
    NSLog (@"matrix should have at least 5 rows and 5 columns!");
    return;
  }

  for (anchor.x = 0; anchor.x < 5; anchor.x++)
    for (anchor.y = 0; anchor.y < 5; anchor.y++)
      for (last.x = 0; last.x < 5; last.x++)
	for (last.y = 0; last.y < 5; last.y++)
	  for (current.x = 0; current.x < 5; current.x++)
	    for (current.y = 0; current.y < 5; current.y++) {
	      pool = [NSAutoreleasePool new];

	      printf ("%d\r", i++);
	      fflush (stdout);

	      /* First determine the selected cells using the sure method */
	      [self _selectRect2UsingAnchor:anchor last:last current:current];
	      selectedCellsByMethod2 = [self selectedCells];

	      /* Then determine the same using the optimized method */
	      [self _selectRectUsingAnchor:anchor last:last current:current];
	      selectedCellsByMethod1 = [self selectedCells];

	      /* Compare the selected cells determined by the two methods */
	      if (![selectedCellsByMethod1 isEqual:selectedCellsByMethod2]) {
		NSLog (@"\nSelected cells are different for:\n"
		    @"anchor = (%d, %d)\nlast = (%d, %d)\ncurrent = (%d, %d)",
		    anchor.x, anchor.y, last.x, last.y, current.x, current.y);
		noOfErrors++;
	      }

	      [pool release];
	    }

  printf ("\nready!\nnumber of errors = %d\n", noOfErrors);
  fflush (stdout);
}
#endif

@end
