/* 
   NSMatrix.m

   Matrix class for grouping controls

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Pascal Forget <pascal@wsc.com>
            Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSMatrix.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSArray.h>
#include <gnustep/gui/NSActionCell.h>
#include <gnustep/gui/NSWindow.h>
#include <gnustep/gui/NSApplication.h>

#define GNU_DEFAULT_CELL_HEIGHT 20

//
// Class variables
//
Class NSMATRIX_DEFAULT_CELL_CLASS;

@implementation NSMatrix

+ (void)initialize
{
    if (self == [NSMatrix class])
	{
	    NSDebugLog(@"Initialize NSMatrix class\n");

	    // Set initial version
	    [self setVersion: 1];
	}
}

//
// Initializing the NSMatrix Class 
//
+ (Class)cellClass
{
  return NSMATRIX_DEFAULT_CELL_CLASS;
}

+ (void)setCellClass:(Class)classId
{
    NSMATRIX_DEFAULT_CELL_CLASS = classId;
}

//
// Initializing an NSMatrix Object
//
- (void)createInitialMatrix
{
    NSSize cs;
    int i, j;
    id aRow, aFloat;

    // Determine cell width and height for uniform cell size
    cs.width = (frame.size.width - (inter_cell.width * (num_cols - 1)))
	/ num_cols;
    cs.height = (frame.size.height - (inter_cell.height * (num_rows - 1)))
	/ num_rows;

    // Save cell widths and heights in arrays
    aFloat = [NSNumber numberWithFloat: cs.height];
    for (i = 0;i < num_rows; ++i)
	[row_heights addObject:aFloat];
    aFloat = [NSNumber numberWithFloat: cs.width];
    for (i = 0;i < num_cols; ++i)
	[col_widths addObject:aFloat];

    for (i = 0;i < num_rows; ++i)
	{
	    aRow = [NSMutableArray arrayWithCapacity: num_cols];
	    [rows addObject: aRow];
	    for (j = 0;j < num_cols; ++j)
		{
		    if (cell_prototype != nil)
			{
			    [(NSMutableArray *)aRow addObject: 
					       [cell_prototype copy]];
			}
		    else
			{
			    [(NSMutableArray *)aRow addObject: 
					       [[cell_class alloc] init]];
			}
		}
	}
}

- (id)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect
		 mode:NSTrackModeMatrix
		 cellClass:[NSCell class]
		 numberOfRows:0
		 numberOfColumns:0];
}

- (id)initWithFrame:(NSRect)frameRect
	       mode:(int)aMode
	  cellClass:(Class)classId
       numberOfRows:(int)rowsHigh
    numberOfColumns:(int)colsWide
{
    NSDebugLog(@"NSMatrix start -initWithFrame: ..cellClass:\n");

    [super initWithFrame:frameRect];

    if (rowsHigh < 0)
    {
	NSLog(@"NSMatrix initWithFrame:mode: rows has to be >= 0.\n");
	NSLog(@"Will create matrix with 0 rows.\n");

	num_rows = 0;
    }
    else
    {
	num_rows = rowsHigh;
    }

    if (colsWide < 0)
    {
	NSLog(@"NSMatrix initWithFrame:mode: columns has to be >= 0.\n");
	NSLog(@"Will create matrix with 0 columns.\n");

	num_cols = 0;
    }
    else
    {
	num_cols = colsWide;
    }

    rows = [[NSMutableArray alloc] init];    
    row_heights = [[NSMutableArray alloc] init];
    col_widths = [[NSMutableArray alloc] init];
    selected_cells = [[NSMutableArray alloc] init];
    inter_cell.width = inter_cell.height = 2;
    
    cell_prototype = nil;
    cell_class = classId;
    mode = aMode;

    [self createInitialMatrix];

    NSDebugLog(@"NSMatrix end -initWithFrame: ..cellClass:\n");
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
	       mode:(int)aMode
	  prototype:(NSCell *)aCell
       numberOfRows:(int)rowsHigh
    numberOfColumns:(int)colsWide
{
    [super initWithFrame:frameRect];

    if (aCell == nil)
    {
	NSLog(@"NSMatrix ");
	NSLog(@"initWithFrame:mode:prototype:numberOfRows:numberOfColumns: ");
	NSLog(@"prototype can't be nil. ");
	NSLog(@"Using NSCell as the default class.\n");
	
	cell_prototype = nil;

	cell_class = [NSCell class];
    }
    else
    {
	cell_prototype = [aCell retain];
    }
    
    return self;
}

//
// Setting the Selection Mode 
//
- (NSMatrixMode)mode
{
  return mode;
}

- (void)setMode:(NSMatrixMode)aMode
{
    mode = aMode;
}

//
// Configuring the NSMatrix 
//
- (BOOL)allowsEmptySelection
{
  return allows_empty_selection;
}

- (BOOL)isSelectionByRect
{
  return selection_by_rect;
}

- (void)setAllowsEmptySelection:(BOOL)flag
{
    allows_empty_selection = flag;
}

- (void)setSelectionByRect:(BOOL)flag
{
    selection_by_rect = flag;
}

//
// Setting the Cell Class 
//
- (Class)cellClass
{
  return cell_class;
}

- (id)prototype
{
  return cell_prototype;
}

- (void)setCellClass:(Class)classId
{
    cell_class = classId;
}

- (void)setPrototype:(NSCell *)aCell
{
    cell_prototype = [aCell retain];
}

//
// Laying Out the NSMatrix 
//
- (void)addColumn
{
    int i;
    NSNumber *anInt;
    NSMutableArray *aRow;

    if (num_rows <= 0)
    {
	[rows addObject:[[NSMutableArray alloc] init]];
	num_rows = 1;

	[row_heights removeAllObjects];
	anInt = [NSNumber numberWithInt: GNU_DEFAULT_CELL_HEIGHT];
	[row_heights addObject:anInt];
    }

    for (i=0; i<num_rows; i++)
    {
	aRow = (NSMutableArray *)[rows objectAtIndex:i];

	if (cell_prototype != nil)
	{
	    [aRow addObject:[cell_prototype copy]];
	}
	else
	{
	    [aRow addObject:[[cell_class alloc] init]];
	}

	anInt = [NSNumber numberWithInt: 
			  (frame.size.width / (float)(num_cols+1))];
	[col_widths addObject:anInt];
	
    }
    num_cols++;
}

- (void)addColumnWithCells:(NSArray *)cellArray
{
    [self insertColumn:num_cols withCells:cellArray];
}

- (void)addRow
{
    int i;
    NSNumber *anInt;
    NSMutableArray *newRow = [[NSMutableArray alloc] init];

    if (cell_prototype != nil)
    {
	[newRow addObject:[cell_prototype copy]];
    }
    else
    {
	[newRow addObject:[[cell_class alloc] init]];
    }
    
    if (num_cols > 0)
    {
	for (i=1; i<num_cols; i++)
	{
	    if (cell_prototype != nil)
	    {
		[newRow addObject:[cell_prototype copy]];
	    }
	    else
	    {
		[newRow addObject:[[cell_class alloc] init]];
	    }
	}

	anInt = [NSNumber numberWithInt: GNU_DEFAULT_CELL_HEIGHT];
	[row_heights addObject:anInt];
    
	[rows addObject:newRow];
	num_rows++;

    }
    else
    {
	[self addColumn];
    }
}

- (void)addRowWithCells:(NSArray *)cellArray
{
    [self insertRow:num_rows withCells:cellArray];
}

- (NSRect)cellFrameAtRow:(int)row
		  column:(int)column
{
    NSRect r;
    int i;

    /* Initialize the size to all zeroes */
    r.origin.x = 0;
    r.origin.y = 0;
    r.size.width = 0;
    r.size.height = 0;

    /* Validate arguments */
    if ((row >= num_rows) || (row < 0))
    {
	return r;
    }

    if ((column >= num_cols) || (column < 0))
    {
	return r;
    }    

    /* Compute the x origin */
    for (i=0; i<column; i++)
    {
	r.origin.x += [(NSNumber *)[col_widths objectAtIndex:i] floatValue];
	r.origin.x += inter_cell.width;
    }

    /* Get the column width */
    r.size.width = [(NSNumber *)[col_widths objectAtIndex:i] floatValue];

    /* Compute the y origin */
    for (i=0; i<row; i++)
    {
	r.origin.y += [(NSNumber *)[row_heights objectAtIndex:i] floatValue];
	r.origin.y += inter_cell.height;
    }

    /* Get the height */
    r.size.height = [(NSNumber *)[row_heights objectAtIndex:i] floatValue];

    NSDebugLog(@"NSMatrix cellFrameAtRow: %d column:%d is: %f %f %f %f\n",
	    row, column,
	    r.origin.x, r.origin.y, r.size.width, r.size.height);
    
    return r;
}

- (NSSize)cellSize
{
    /*****************************************
     * This method is for the OpenStep mode, *
     * where all rows have the same size.    *                                
     *****************************************/

    NSSize s = {0, 0};

    if ((num_cols < 1) || (num_rows < 1))
    {
	return s;
    }

    s.width = [[col_widths objectAtIndex:0] floatValue];
    s.height= [[row_heights objectAtIndex:0] floatValue];

    return s;
}

- (void)getNumberOfRows:(int *)rowCount
		columns:(int *)columnCount
{
    *rowCount = num_rows;
    *columnCount = num_cols;
}

- (void)insertColumn:(int)column
{
    NSMutableArray *currentRow;
    id newCell;
    int i, j;

    i = column - num_cols;

    while (i--)
    {
	[self addColumn];
    }

    if (num_cols > 1)
    {
	for (i=0; i<num_rows; i++)
	{
	    currentRow = [rows objectAtIndex:i];
	    newCell = [currentRow lastObject];

	    for (j=num_cols-1; j>column; j--)
	    {
		[currentRow replaceObjectAtIndex:j withObject:
			    [currentRow objectAtIndex:i-1]];
	    }
	    [currentRow replaceObjectAtIndex:column withObject:newCell];
	}
    }
}

- (void)insertColumn:(int)column withCells:(NSArray *)cellArray
{
    NSCell *newCell;
    int i, count;

    [self insertColumn:column];

    if (cellArray != nil)
    {
	count = [cellArray count];
    }
    else
    {
	count = 0;
    }

    for (i=0; i<num_rows; i++)
    {
	if (i < count)
	{
	    newCell = (NSCell *)[cellArray objectAtIndex:i];

	    [self putCell:newCell atRow:i  column:column];
	}
	else
	{
	    break;
	}
    }
}

- (void)insertRow:(int)row
{
    NSMutableArray *aRow;
    int i;

    i = row - num_rows;

    while (i--)
    {
	[self addRow];
    }

    if (num_rows > 1)
    {
	aRow = [rows lastObject];

	for (i=num_rows-1; i> row; i--)
	{
	    [rows replaceObjectAtIndex:i withObject:[rows objectAtIndex:i-1]];
	}
	[rows replaceObjectAtIndex:row withObject:aRow];
    }
}

- (void)insertRow:(int)row withCells:(NSArray *)cellArray
{
    NSCell *newCell;
    int i, count;

    [self insertRow:row];

    if (cellArray != nil)
    {
	count = [cellArray count];
    }
    else
    {
	count = 0;
    }

    for (i=0; i<num_cols; i++)
    {
	if (i < count)
	{
	    newCell = (NSCell *)[cellArray objectAtIndex:i];

	    [self putCell:newCell atRow:row  column:i];
	}
	else
	{
	    break;
	}
    }
}

- (NSSize)intercellSpacing
{
  return inter_cell;
}

- (NSCell *)makeCellAtRow:(int)row
		   column:(int)column
{
    id newCell;

    if ((row < num_rows)
	&& (row > -1)
	&& (column < num_cols)
	&& (column > -1))
    {
	newCell = [[cell_class alloc] init];
	[[rows objectAtIndex:row] replaceObjectAtIndex:column 
				  withObject:newCell];
	return newCell;
    }
    else
    {
	return nil;
    }
}

- (void)putCell:(NSCell *)newCell
	  atRow:(int)row
	 column:(int)column
{
    NSMutableArray *aRow;

    if ((row > -1)
	&& (row < num_rows)
	&& (column > -1)
	&& (column < num_cols))
    {
	aRow = (NSMutableArray *)[rows objectAtIndex:row];
	[aRow replaceObjectAtIndex:column withObject:newCell];
    }
}

- (void)removeColumn:(int)column
{
    int i;
    NSMutableArray *aRow;
    
    if ((column > -1) && (column < num_cols))
    {
	for (i=0; i<num_rows; i++)
	{
	    aRow = (NSMutableArray *)[rows objectAtIndex:i];
	    [aRow removeObjectAtIndex:column];
	}
	[col_widths removeObjectAtIndex:column];
	num_cols--;
    }
}

- (void)removeRow:(int)row
{
    if ((row > -1) && (row < num_rows))
    {
	[rows removeObjectAtIndex:row];
	
	[row_heights removeObjectAtIndex:row];
	num_rows--;
    }
}

- empty
{
    [rows removeAllObjects];
    [selected_cells removeAllObjects];
    num_rows = 0;
    num_cols = 0;
    return self;
}

- (void)renewRows:(int)newRows
	  columns:(int)newColumns
{}

- (void)setCellSize:(NSSize)aSize
{
    NSNumber *aFloat;
    id old;
    int i;

    for (i=0; i<num_cols; i++)
    {
	aFloat = [NSNumber numberWithFloat: aSize.width];
	old = [col_widths objectAtIndex:i];
	[col_widths replaceObjectAtIndex:i withObject: aFloat];
	[old release];
    }

    for (i=0; i<num_rows; i++)
    {
	aFloat = [NSNumber numberWithFloat: aSize.height];
	old = [row_heights objectAtIndex:i];
	[row_heights replaceObjectAtIndex:i withObject: aFloat];
	[old release];
    }
}

- (void)setColumnWidth:(int)width at:(int)column;
{
    NSNumber *aFloat;
    id old;

    if ((column > -1) && (column < num_cols))
    {
	aFloat = [NSNumber numberWithFloat: width];
	old = [col_widths objectAtIndex:column];
	[col_widths replaceObjectAtIndex:column withObject: aFloat];
	[old release];
    }
}

- (void)setIntercellSpacing:(NSSize)aSize
{
    inter_cell = aSize;
}

- (void)sortUsingFunction:(int (*)(id element1, id element2, 
				   void *userData))comparator
		  context:(void *)context
{}

- (void)sortUsingSelector:(SEL)comparator
{}

- (int)numCols;
{
    return num_cols;
}

- (int)numRows;
{
    return num_rows;
}

//
// Finding Matrix Coordinates 
//
/*
 * The next function returns NO if the point is located inside
 * the matrix but also in an intercell gap, which may or may
 * not be the behavior God intended...
 */
- (BOOL)getRow:(int *)row
	column:(int *)column
      forPoint:(NSPoint)aPoint
{
    NSRect myFrame = [self bounds];
    NSRect cFrame;
    int i, j;

    /* Trivial rejection if the point is not in the Matrix's frame rect */

    if ((aPoint.x < myFrame.origin.x)
	|| (aPoint.x > (myFrame.origin.x + myFrame.size.width))
	|| (aPoint.y < myFrame.origin.y)
	|| (aPoint.y > (myFrame.origin.y + myFrame.size.height)))
    {
	NSDebugLog(@"NSMatrix point %f %f not in rect %f %f %f %f\n",
		   aPoint.x, aPoint.y, myFrame.origin.x, myFrame.origin.y,
		   myFrame.size.width, myFrame.size.height);
	return NO;
    }
    else
    {
	/* Here an optimized algo could be used at the expense of clarity */

	for (i=0; i<num_rows; i++)
	{
	    for (j=0; j<num_cols; j++)
	    {
		cFrame = [self cellFrameAtRow:i column:j];

		if ((aPoint.x >= cFrame.origin.x)
		    && (aPoint.x <= (cFrame.origin.x + cFrame.size.width))
		    && (aPoint.y >= cFrame.origin.y)
		    && (aPoint.y <= (cFrame.origin.y + cFrame.size.height)))
		{
		    *row = i;
		    *column = j;
		    return YES;
		}
	    }
	}
	return NO;
    }
}

- (BOOL)getRow:(int *)row
	column:(int *)column
	ofCell:(NSCell *)aCell
{
    int i, j;

    for (i=0; i<num_rows; i++)
    {
	for (j=0; j<num_cols; j++)
	{
	    if ((NSCell *)[self cellAtRow:i column:j] == aCell)
	    {
		*row = i;
		*column = j;
		return YES;
	    }
	}
    }
    return NO;
}

//
// Modifying Individual Cells 
//
- (void)setState:(int)value
	   atRow:(int)row
	  column:(int)column
{
    NSMutableArray *aRow;
    NSCell *aCell;

    if ((row > -1)
	&& (row < num_rows)
	&& (column > -1)
	&& (column < num_cols))
    {
	aRow = (NSMutableArray *)[rows objectAtIndex:row];
	aCell = (NSCell *)[aRow objectAtIndex:column];
	[aCell setState:value];
    }
}

//
// Selecting Cells 
//
- (void)deselectAllCells
{
    [selected_cells removeAllObjects];
}

- (void)deselectSelectedCell
{
    [selected_cells removeLastObject];
}

- (void)selectAll:(id)sender
{
    [selected_cells removeAllObjects];
    [selected_cells addObjectsFromArray:[self cells]];
}

- (void)selectCellAtRow:(int)row
		 column:(int)column
{
    int index;
    id aCell = [self cellAtRow:row column:column];
    
    NSDebugLog(@"NSMatrix select cell at %d %d\n", row, column);
    if (aCell != nil)
    {
	index = [selected_cells indexOfObject:aCell];

	if ((index < 0) || (index > [selected_cells count]))
	{
	    [selected_cells addObject:aCell];
	}
    }
}

- (BOOL)selectCellWithTag:(int)anInt
{
    id aCell = [self cellWithTag:anInt];
    int index;
    
    if (cell != nil)
    {
	index = [selected_cells indexOfObject:aCell];

	if ((index < 0) || (index > [selected_cells count]))
	{
	    [selected_cells addObject:aCell];
	}
	return YES;
    } else {
	return NO;
    }
}

- (id)selectedCell
{
    return [selected_cells lastObject];
}

/*
 * returns an array of the selected cells
 */
- (NSArray *)selectedCells
{
  return selected_cells;
}

- (int)selectedColumn
{
    int row, col;
    NSMutableArray *aRow, *aCol;
    id aCell;
    
    if ([selected_cells count]) {

	aCell = [selected_cells lastObject];
	
	for (row=0; row<num_rows; row++)
	{
	    aRow = [rows objectAtIndex:row];

	    for (col=0; col<num_cols; col++)
	    {
		aCol = [aRow objectAtIndex:col];
		      
		if ([aCol indexOfObject:aCell] < num_cols)
		{
		    return col;
		}
	    }
	}
    }

    return -1; /* not found */
}

- (int)selectedRow
{
    int row, col;
    NSMutableArray *aRow, *aCol;
    id aCell;
    
    if ([selected_cells count] > 0)
    {
	aCell = [selected_cells lastObject];
	
	for (row=0; row<num_rows; row++)
	{
	    aRow = [rows objectAtIndex:row];

	    for (col=0; col<num_cols; col++)
	    {
		aCol = [aRow objectAtIndex:col];
		      
		if ([aCol indexOfObject:aCell] < num_cols)
		{
		    return row;
		}
	    }
	}
    }

    return -1; /* not found */
}

- (void)setSelectionFrom:(int)startPos
		      to:(int)endPos
		  anchor:(int)anchorPos
		      highlight:(BOOL)flag
{}

//
// Finding Cells 
//
- (id)cellAtRow:(int)row
	 column:(int)column
{
    if ((row >= num_rows) || (row < 0))
    {
	NSLog(@"NSMatrix cellAt:: invalid row (%d)\n", row);
	return nil;
    }

    if ((column >= num_cols) || (column < 0))
    {
	NSLog(@"NSMatrix cellAt:: invalid column (%d)\n", column);
	return nil;
    }

    return [(NSArray *)[rows objectAtIndex:row] objectAtIndex:column];
}

- (id)cellWithTag:(int)anInt
{
    int i, j;
    NSMutableArray *aRow;
    NSCell *aCell;
    
    for (i=0; i<num_rows; i++)
    {
	aRow = (NSMutableArray *)[rows objectAtIndex:i];

	for (j=0; j<num_cols; j++)
	{
	    aCell = [aRow objectAtIndex:j];
	    
	    if ([aCell tag] == anInt)
	    {
		return (id)aCell;
	    }
	}
    }
    return nil;
}

- (NSArray *)cells
{
    NSMutableArray *cells;
    int i;
    
    if ((num_cols < 1) || (num_rows < 1))
    {
	return nil;
    }
    else
    {
	cells = [[NSMutableArray alloc] 
			initWithCapacity:(num_rows * num_cols)];

	for (i=0; i<num_rows; i++)
	{
	    [cells addObjectsFromArray:(NSArray *)[rows objectAtIndex:i]];
	}

	return cells;
    }
}

//
// Modifying Graphic Attributes 
//
- (NSColor *)backgroundColor
{
  return nil;
}

- (NSColor *)cellBackgroundColor
{
  return nil;
}

- (BOOL)drawsBackground
{
  return draws_background;
}

- (BOOL)drawsCellBackground
{
  return draws_cell_background;
}

- (void)setBackgroundColor:(NSColor *)aColor
{}

- (void)setCellBackgroundColor:(NSColor *)aColor
{}

- (void)setDrawsBackground:(BOOL)flag
{
    draws_background = flag;
}

- (void)setDrawsCellBackground:(BOOL)flag
{
    draws_cell_background = flag;
}

//
// Editing Text in Cells 
//
- (void)selectText:(id)sender
{}

- (id)selectTextAtRow:(int)row
	       column:(int)column
{
  return nil;
}

- (void)textDidBeginEditing:(NSNotification *)notification
{}

- (void)textDidChange:(NSNotification *)notification
{}

- (void)textDidEndEditing:(NSNotification *)notification
{}

- (BOOL)textShouldBeginEditing:(NSText *)textObject
{
  return NO;
}

- (BOOL)textShouldEndEditing:(NSText *)textObject
{
  return NO;
}

//
// Setting Tab Key Behavior 
//
- (id)nextText
{
  return nil;
}

- (id)previousText
{
  return nil;
}

- (void)setNextText:(id)anObject
{}

- (void)setPreviousText:(id)anObject
{}

//
// Assigning a Delegate 
//
- (void)setDelegate:(id)anObject
{}

- (id)delegate
{
  return nil;
}

//
// Resizing the Matrix and Cells 
//
- (BOOL)autosizesCells
{
  return autosize;
}

- (void)setAutosizesCells:(BOOL)flag
{
    autosize = flag;
}

- (void)setValidateSize:(BOOL)flag
{}

- (void)sizeToCells
{
    NSSize newSize;
    NSNumber *value;
    int row, col;

    newSize.width = 0;
    newSize.height = 0;

    NSDebugLog(@"NSMatrix intercell height: %4.0f\n", inter_cell.height);
    
    for (row=0; row<num_rows; row++)
    {
	value = [row_heights objectAtIndex:row];

	newSize.height += [value intValue];

	if ((row > 0) && (row < (num_rows-1) ))
	{
	    newSize.height += inter_cell.height;
	}
    }

    for (col=0; col<num_cols; col++)
    {
	value = [col_widths objectAtIndex:col];

	newSize.width += [value intValue];

	if ((col > 0) && (col < (num_cols-1) ))
	{
	    newSize.width += inter_cell.width;
	}
    }

#if 1    
    NSDebugLog(@"NSMatrix size: %4.0f %4.0f\n",newSize.width,newSize.height);
#endif
    
    [(NSView *)self setFrameSize:newSize];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
  NSDebugLog(@"NSMatrix resize %f %f old %f %f\n", bounds.size.width,
	     bounds.size.height, oldSize.width, oldSize.height);
}

//
// Scrolling 
//
- (BOOL)isAutoscroll
{
  return autoscroll;
}

- (void)scrollCellToVisibleAtRow:(int)row
			  column:(int)column
{}

- (void)setAutoscroll:(BOOL)flag
{
    autoscroll = flag;
}

- (void)setScrollable:(BOOL)flag
{
    scrollable = flag;
}

//
// Displaying 
//
- (void)display;
{
    int row,col;
    int rcnt, ccnt;
    NSMutableArray *aRow;

    NSDebugLog(@"NSMatrix display\n");
    
    rcnt = [rows count];
    if (rcnt != num_rows) 
	NSLog(@"NSMatrix internal error: num_rows != actual rows\n");

    for (row=0; row<rcnt; row++)
    {
	aRow = [rows objectAtIndex:row];
	ccnt = [aRow count];
	if (ccnt != num_cols) 
	    NSLog(@"NSMatrix internal error: num_cols != actual columns\n");

	for (col=0; col<ccnt; col++)
	{
	    [self drawCellAtRow: row column: col];
	}
    }
    NSDebugLog(@"End NSMatrix display\n");
}

- (void)drawCellAtRow:(int)row
	       column:(int)column
{
    NSMutableArray *aRow = [rows objectAtIndex: row];

    [[aRow objectAtIndex:column] drawWithFrame:
				 [self cellFrameAtRow:row column:column]
				 inView:self];
}

- (void)highlightCell:(BOOL)flag
		atRow:(int)row
	       column:(int)column
{
    NSCell *aCell = [self cellAtRow:row column:column];
    NSRect cellFrame;

    if (aCell != nil)
    {
	cellFrame = [self cellFrameAtRow:row column:column];
	[aCell highlight:flag withFrame:cellFrame inView:self];
    }

}

//
// Target and Action 
//
- (SEL)doubleAction
{
  return double_action;
}

- (void)setDoubleAction:(SEL)aSelector
{
    double_action = aSelector;
}

- (SEL)errorAction
{
  return error_action;
}

- (BOOL)sendAction
{
    NSCell *aCell = [self selectedCell];

    NSDebugLog(@"NSMatrix -sendAction\n");
    if (!aCell) return NO;

    if ([aCell isKindOfClass:[NSActionCell class]])
	{
	    NSDebugLog(@"NSMatrix sending action\n");
	    [self sendAction: [aCell action] to: [aCell target]];
	    return YES;
	}
    NSDebugLog(@"NSMatrix no action\n");
    return NO;
}

- (void)sendAction:(SEL)aSelector
		to:(id)anObject
       forAllCells:(BOOL)flag
{
    BOOL (*test)(id, SEL, id);
    id row, columns, col;
    id aCell;
    BOOL result;

    // If the object doesn't respond to selector then quit
    if (![anObject respondsToSelector: aSelector])
	return;

    // Obtain function pointer to selector
    test = (BOOL (*)(id, SEL, id))[anObject methodForSelector: aSelector];

    // Enumerate through all the cells
    row = [rows objectEnumerator];
    columns = [row nextObject];
    while (columns)
	{
	    col = [columns objectEnumerator];
	    aCell = [col nextObject];
	    while (aCell)
		{
		    // Call the method
		    result = test(anObject, aSelector, aCell);

		    // If the result is NO
		    // and we shouldn't continue for all cells
		    // then quit
		    if ((!result) && (!flag))
			return;

		    aCell = [col nextObject];
		}
	    columns = [row nextObject];
	}
}

- (void)sendDoubleAction
{
    NSCell *aCell = [self selectedCell];

    NSDebugLog(@"NSMatrix -sendDoubleAction\n");
    if (!aCell) return;

    if (double_action)
	{
	    NSDebugLog(@"NSMatrix sending double action\n");
	    [self sendAction: double_action to: [aCell target]];
	}
    else
	NSDebugLog(@"NSMatrix no double action\n");
}

- (void)setErrorAction:(SEL)aSelector
{
    error_action = aSelector;
}

//
// Handling Event and Action Messages 
//
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    if (mode == NSListModeMatrix)
    {
	return NO;
    }
    return YES;
}

- (void)highlightTrackingMode:(NSEvent *)theEvent
{
    NSPoint location;
    NSPoint point;
    NSCell *aCell;
    int aRow, aCol;
    NSRect cellFrame;
    NSApplication *theApp = [NSApplication sharedApplication];
    BOOL mouseUp, done;
    NSEvent *e;
    unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask
        | NSMouseMovedMask;

    // Capture mouse
    [[self window] captureMouse: self];

    mouseUp = NO;
    done = NO;
    e = theEvent;
    while (!done)
        {
            location = [e locationInWindow];
            point = [self convertPoint: location fromView: nil];

            // Find out what cell was clicked on
            if ([self getRow:&aRow column:&aCol forPoint:point])
                {
                    NSDebugLog(@"NSMatrix found row/column from point\n");

                    aCell = [self cellAtRow:aRow column:aCol];
                    if (!aCell)
                        {
                            // Yikes problem here
                            NSLog(@"NSMatrix no cell at %d %d\n", aRow, aCol);
                            mouseUp = NO;
                            done = YES;
                            continue;
                        }

                    NSDebugLog(@"NSMatrix found cell\n");
                    cellFrame = [self cellFrameAtRow: aRow column: aCol];

                    mouseUp = [aCell trackMouse: e inRect: cellFrame
                                     ofView:self untilMouseUp:YES];
                    e = [theApp currentEvent];
                }

            // If mouse went up then we are done
            if ((mouseUp) || ([e type] == NSLeftMouseUp))
		done = YES;
            else
                {
                    NSDebugLog(@"NSMatrix process another event\n");
                    e = [theApp nextEventMatchingMask:event_mask untilDate:nil
                                inMode:nil dequeue:YES];
                }
        }


    // Release mouse
    [[self window] releaseMouse: self];

    // If the mouse went up in the button
    if (mouseUp)
        {
	    NSDebugLog(@"NSMatrix the mouse went up in a button\n");

            // Unhighlight the cell
            [aCell highlight: NO withFrame: cellFrame
                  inView: self];

            // Select the cell
            [self selectCellAtRow: aRow column: aCol];

	    NSDebugLog(@"NSMatrix send action\n");
            // Send action
            if ([theEvent clickCount] == 1)
                [self sendAction];
            else
                [self sendDoubleAction];
        }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSView *view = [[self window] contentView];
    NSPoint location = [theEvent locationInWindow];
    NSPoint point = [super_view convertPoint:location fromView:view];

    NSDebugLog(@"NSMatrix mouseDown at point %f %f\n", point.x, point.y);

    // What mode are we in?
    switch(mode)
	{
	case NSTrackModeMatrix:
	    break;

	case NSHighlightModeMatrix:
	    NSDebugLog(@"NSMatrix NSHighlightModeMatrix\n");
	    [self highlightTrackingMode: theEvent];
	    break;

	case NSRadioModeMatrix:
	    break;

	case NSListModeMatrix:
	    break;
	}
}

- (int)mouseDownFlags
{
  return 0;
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
  return NO;
}

//
// Managing the Cursor 
//
- (void)resetCursorRects
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
