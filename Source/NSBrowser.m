/*
   NSBrowser.m

   Control to display and select from hierarchal lists

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author:  Franck Wolff <wolff@cybercable.fr>
   Date: November 1999
   Author:  Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: September 2000

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

#include <math.h>                  // (float)rintf(float x)
#include <gnustep/gui/config.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/PSOperators.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>

/* Cache */
static float scrollerWidth; // == [NSScroller scrollerWidth]

#ifndef HAVE_RINTF
#define rintf rint
#endif

#define NSBR_COLUMN_SEP 6
#define NSBR_VOFFSET 2

#define NSBR_COLUMN_IS_VISIBLE(i) \
(((i)>=_firstVisibleColumn)&&((i)<=_lastVisibleColumn))

//#define NSBTRACE_all


//
// Internal class for maintaining information about columns
//
@interface NSBrowserColumn : NSObject
{
  BOOL _isLoaded;
  id _columnScrollView;
  id _columnMatrix;
  int _numberOfRows;
  NSString *_columnTitle;
}

- (void)setIsLoaded: (BOOL)flag;
- (BOOL)isLoaded;
- (void)setColumnScrollView: (id)aView;
- columnScrollView;
- (void)setColumnMatrix: (id)aMatrix;
- columnMatrix;
- (void)setNumberOfRows: (int)num;
- (int)numberOfRows;
- (void)setColumnTitle: (NSString *)aString;
- (NSString *)columnTitle;

@end

@implementation NSBrowserColumn

- (id) init
{
  [super init];

  _isLoaded = NO;

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_columnScrollView);
  TEST_RELEASE(_columnMatrix);
  TEST_RELEASE(_columnTitle);
  [super dealloc];
}

- (void) setIsLoaded: (BOOL)flag
{
  _isLoaded = flag;
}

- (BOOL) isLoaded
{
  return _isLoaded;
}

- (void) setColumnScrollView: (id)aView
{
  ASSIGN(_columnScrollView, aView);
}

- columnScrollView
{
  return _columnScrollView;
}

- (void)setColumnMatrix: (id)aMatrix
{
  ASSIGN(_columnMatrix, aMatrix);
}

- columnMatrix
{
  return _columnMatrix;
}

- (void) setNumberOfRows: (int)num
{
  _numberOfRows = num;
}

- (int)numberOfRows
{
  return _numberOfRows;
}

- (void)setColumnTitle: (NSString *)aString
{
  if (!aString)
    aString = @"";

  ASSIGN(_columnTitle, aString);
}

- (NSString *)columnTitle
{
  return _columnTitle;
}

@end

// NB: this is used in the NSFontPanel too
@interface GSBrowserTitleCell: NSTextFieldCell
@end

@implementation GSBrowserTitleCell
- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];

  [self setTextColor: [NSColor windowFrameTextColor]];
  [self setBackgroundColor: [NSColor controlShadowColor]];
  [self setFont: [NSFont titleBarFontOfSize: 0]];
  [self setAlignment: NSCenterTextAlignment];
  _cell.is_editable = NO;
  _cell.is_bezeled = YES;
  _textfieldcell_draws_background = YES;

  return self;
}
- (void) drawWithFrame: (NSRect)cellFrame  inView: (NSView*)controlView
{
  if (NSIsEmptyRect (cellFrame) || ![controlView window])
    {
      return;
    }

  [controlView lockFocus];
  NSDrawGrayBezel (cellFrame, NSZeroRect);
  [controlView unlockFocus];
  [super drawInteriorWithFrame: cellFrame  inView: controlView];
}
@end

//
// Private NSBrowser methods
//
@interface NSBrowser (Private)
- (NSString *) _getTitleOfColumn: (int)column;
- (void) _performLoadOfColumn: (int)column;
- (void) _unloadFromColumn: (int)column;
- (void) _remapColumnSubviews: (BOOL)flag;
- (void) _adjustMatrixOfColumn: (int)column;
- (void) _setColumnSubviewsNeedDisplay;
- (void) _setColumnTitlesNeedDisplay;
@end

//
// NSBrowser implementation
//

@implementation NSBrowser



// #############################################################################
//
//  PUBLIC METHODS (MacOSXServer Documentation 1998)
//
// #############################################################################



////////////////////////////////////////////////////////////////////////////////
// Setting component classes
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the NSBrowserCell class (regardless of whether a 
// setCellClass: message has been sent to a particular instance)
//

+ (Class)cellClass
{
  return [NSBrowserCell class];
}

// -------------------
// Sets the class of NSCell used in the columns of the NSBrowser.
// 

- (void)setCellClass: (Class)classId
{
  _browserCellClass = classId;

  // set the prototype for the new class
  [self setCellPrototype: AUTORELEASE([[_browserCellClass alloc] init])];
}

// -------------------
// Returns the NSBrowser's prototype NSCell.
// 

- (id)cellPrototype
{
  return _browserCellPrototype;
}

// -------------------
// Sets the NSCell instance copied to display items in the columns of NSBrowser.
//

- (void)setCellPrototype: (NSCell *)aCell
{
  ASSIGN(_browserCellPrototype, aCell);
}

// -------------------
// Returns the class of NSMatrix used in the NSBrowser's columns.
//

- (Class)matrixClass
{
  return _browserMatrixClass;
}

// -------------------
// Sets the matrix class (NSMatrix or an NSMatrix subclass) used in the
// NSBrowser's columns.
//

- (void)setMatrixClass: (Class)classId
{
  _browserMatrixClass = classId;
}



////////////////////////////////////////////////////////////////////////////////
// Getting matrices, cells, and rows
////////////////////////////////////////////////////////////////////////////////


// -------------------
// Returns the last (rightmost and lowest) selected NSCell.
//

- (id)selectedCell
{
  int i;
  id matrix;

  // Nothing selected
  if ((i = [self selectedColumn]) == -1)
    {
      return nil;
    }
  
  if (!(matrix = [self matrixInColumn: i]))
    {
      return nil;
    }

  return [matrix selectedCell];
}

// -------------------
// Returns the last (lowest) NSCell that's selected in column.
//

- (id)selectedCellInColumn: (int)column
{
  id matrix;

  if (!(matrix = [self matrixInColumn: column]))
    {
      return nil;
    }

  return [matrix selectedCell];
}

// -------------------
// Returns all cells selected in the rightmost column.
//

- (NSArray *)selectedCells
{
  int i;
  id matrix;

  // Nothing selected
  if ((i = [self selectedColumn]) == -1)
    {
      return nil;
    }
  
  if (!(matrix = [self matrixInColumn: i]))
    {
      return nil;
    }

  return [matrix selectedCells];
}

// -------------------
// Selects all NSCells in the last column of the NSBrowser.
//

- (void)selectAll: (id)sender
{
  id matrix;

  if (!(matrix = [self matrixInColumn: _lastVisibleColumn]))
    {
      return;
    }

  [matrix selectAll: sender];
}

// -------------------
// Returns the row index of the selected cell in the column specified by
// index column.
//

- (int) selectedRowInColumn: (int)column
{
  id matrix;

  if (!(matrix = [self matrixInColumn: column]))
    {
      return -1;
    }

  return [matrix selectedRow];
}

// -------------------
// Selects the cell at index row in the column identified by index column.
//

- (void)selectRow:(int)row inColumn:(int)column 
{
  id matrix;
  id cell;

  if (column < 0 || column > _lastColumnLoaded)
    return;

  if (!(matrix = [self matrixInColumn: column]))
    return;

  if ((cell = [matrix cellAtRow: row column: column]))
    {
      if (column < _lastColumnLoaded)
	{
	  [self setLastColumn: column];
	}

      [matrix deselectAllCells];
      [matrix selectCellAtRow: row column: 0];

      if (![cell isLeaf])
	{
	  [self addColumn];
	}
    }
}

// -------------------
// Loads if necessary and returns the NSCell at row in column.
//

- (id)loadedCellAtRow: (int)row
	       column: (int)column
{
  NSBrowserColumn *bc;
  NSArray *columnCells;
  id matrix;
  int count = [_browserColumns count];
  id aCell;

  // column range check
  if (column >= count)
    {
      return nil;
    }

  bc = [_browserColumns objectAtIndex: column];

  if (!(matrix = [bc columnMatrix]))
    {
      return nil;
    }

  if (!(columnCells = [matrix cells]))
    {
      return nil;
    }

  count = [columnCells count];

  // row range check
  if (row >= count)
    {
      return nil;
    }

  // Get the cell
  if (!(aCell = [matrix cellAtRow: row column: 0]))
    {
      return nil;
    }

  // Load if not already loaded
  if ([aCell isLoaded])
    {
      return aCell;
    }
  else
    {
      if (_passiveDelegate || [_browserDelegate respondsToSelector: 
		  @selector(browser:willDisplayCell:atRow:column:)])
	{
	  [_browserDelegate browser: self  willDisplayCell: aCell
			    atRow: row  column: column];
	}
      [aCell setLoaded: YES];
    }

  return aCell;
}

// -------------------
// Returns the matrix located in the column identified by index column.
//

- (NSMatrix *)matrixInColumn: (int)column
{
  NSBrowserColumn *bc;

  bc = [_browserColumns objectAtIndex: column];
  
  if (![bc isLoaded])
    {
      return nil;
    }

  return [bc columnMatrix];
}

//#undef NSBTRACE_all


////////////////////////////////////////////////////////////////////////////////
// Getting and setting paths
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the browser's current path.
//

- (NSString *)path
{
  return [self pathToColumn: _lastColumnLoaded + 1];
}

// -------------------
// Parses path and selects corresponding items in the NSBrowser columns.
//

- (BOOL) setPath: (NSString *)path
{
  NSArray	*subStrings;
  NSString	*aStr;
  unsigned	numberOfSubStrings;
  unsigned	i, j, column = 0;
  BOOL	      	found = YES;

  // If that's all, return.
  if (path == nil)
    {
      [self setNeedsDisplay: YES];
      return YES;
    }

  // Otherwise, decompose the path.
  subStrings = [path componentsSeparatedByString: _pathSeparator];
  numberOfSubStrings = [subStrings count];

  // Ignore a trailing void component. 
  if (numberOfSubStrings > 0
      && [[subStrings objectAtIndex: 0] isEqualToString: @""])
    {
      numberOfSubStrings--;

      if (numberOfSubStrings)
	{
	  NSRange theRange;

	  theRange.location = 1;
	  theRange.length = numberOfSubStrings;
	  subStrings = [subStrings subarrayWithRange: theRange];
	}

      [self loadColumnZero];
    }

  column = _lastColumnLoaded;
  if (column < 0)
    column = 0;

  // cycle thru str's array created from path
  for (i = 0; i < numberOfSubStrings; i++)
    {
      NSBrowserColumn	*bc = [_browserColumns objectAtIndex: column + i];
      NSMatrix		*matrix = [bc columnMatrix];
      NSArray		*cells = [matrix cells];
      unsigned		numOfRows = [cells count];
      NSBrowserCell	*selectedCell = nil;
      
      aStr = [subStrings objectAtIndex: i];

      if (![aStr isEqualToString: @""])
	{
	  found = NO;

	  // find the cell in the browser matrix which is equal to aStr
	  for (j = 0; j < numOfRows; j++)
	    {
	      NSString	*cellString;
	      
	      selectedCell = [cells objectAtIndex: j];
	      cellString = [selectedCell stringValue];
	      
	      if ([cellString isEqualToString: aStr])
		{
		  [matrix selectCellAtRow: j column: 0];
		  found = YES;
		  break;
		}
	    }
	  // if unable to find a cell whose title matches aStr return NO
	  if (found == NO)
	    {
	      NSDebugLog (@"NSBrowser: unable to find cell '%@' in column %d\n", 
			  aStr, column + i);
	      break;
	    }
	  // if the cell is a leaf, we are finished setting the path
	  if ([selectedCell isLeaf])
	    break;
	  
	  // else, it is not a leaf: add a column to the browser for it
	  [self addColumn];
	}
    }

  [self setNeedsDisplay: YES];
  
  return found;
}

// -------------------
// Returns a string representing the path from the first column up to,
// but not including, the column at index column.
//

- (NSString *)pathToColumn: (int)column
{
  NSMutableString	*s = [_pathSeparator mutableCopy];
  unsigned		i;
  NSString              *string;
  

  /*
   * Cannot go past the number of loaded columns
   */
  if (column > _lastColumnLoaded)
    {
      column = _lastColumnLoaded + 1;
    }

  for (i = 0; i < column; ++i)
    {
      id	c = [self selectedCellInColumn: i];

      if (i != 0)
	{
	  [s appendString: _pathSeparator];
	}

      string = [c stringValue];
      
      if (string == nil)
	{
	  /* This should happen only when c == nil, in which case it
	     doesn't make sense to go with the path */
	  break;
	}
      else
	{
	  [s appendString: string];	  
	}
    }
  /*
   * We actually return a mutable string, but that's ok since a mutable
   * string is a string and the documentation specifically says that
   * people should not depend on methods that return strings to return
   * immutable strings.
   */

  return AUTORELEASE (s);
}

// -------------------
// Returns the path separator. The default is "/".
//

- (NSString *)pathSeparator
{
  return _pathSeparator;
}

// -------------------
// Sets the path separator to newString.
//

- (void)setPathSeparator: (NSString *)aString
{
  ASSIGN(_pathSeparator, aString);
}



////////////////////////////////////////////////////////////////////////////////
// Manipulating columns
////////////////////////////////////////////////////////////////////////////////


- (NSBrowserColumn *)_createColumn
{
  NSBrowserColumn *bc;
  NSScrollView *sc;
  NSRect rect = {{0, 0}, {100, 100}};

  bc = [[NSBrowserColumn alloc] init];

  // Create a scrollview
  sc = [[NSScrollView alloc]
	 initWithFrame: rect];
  [sc setHasHorizontalScroller: NO];
  [sc setHasVerticalScroller: YES];
  [bc setColumnScrollView: sc];
  [self addSubview: sc];
  RELEASE(sc);

  [_browserColumns addObject: bc];
  RELEASE(bc);

  return bc;
}

// -------------------
// Adds a column to the right of the last column.
//

- (void)addColumn
{
  int i;

  if (_lastColumnLoaded + 1 >= [_browserColumns count])
    {
      i = [_browserColumns indexOfObject: [self _createColumn]];
    }
  else
    {
      i = _lastColumnLoaded + 1;
    }

  if (i < 0)
    {
      i = 0;
    }

  [self _performLoadOfColumn: i];
  [self setLastColumn: i];
  [self _adjustMatrixOfColumn: i];

  _isLoaded = YES;

  [self tile];

  if (i > 0  &&  i - 1 == _lastVisibleColumn)
    {
      [self scrollColumnsRightBy: 1];
    }
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) becomeFirstResponder
{
  NSMatrix *matrix;
  int selectedColumn;

  selectedColumn = [self selectedColumn];
  if (selectedColumn == -1)
    matrix = [self matrixInColumn: 0];
  else
    matrix = [self matrixInColumn: selectedColumn];

  if (matrix)
    [_window makeFirstResponder: matrix];

  return YES;
}

// -------------------
// Updates the NSBrowser to display all loaded columns.
//

- (void) displayAllColumns
{
  [self tile];
}

// -------------------
// Updates the NSBrowser to display the column with the given index.
//

- (void) displayColumn: (int)column
{
  id bc, sc;

  // If not visible then nothing to display
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    {
      return;
    }

  [self tile];

  // Update and display title of column
  if (_isTitled)
    {
      NSString *title = [self _getTitleOfColumn: column];
      [self setTitle: title ofColumn: column];
      [self drawTitle: title
	    inRect: [self titleFrameOfColumn: column]
	    ofColumn: column];
    }

  // Display column
  if (!(bc = [_browserColumns objectAtIndex: column]))
    return;
  if (!(sc = [bc columnScrollView]))
    return;

  [sc setNeedsDisplay: YES];
}

// -------------------
// Returns the column number in which matrix is located.
//

- (int)columnOfMatrix: (NSMatrix *)matrix
{
  int i, count;
  id bc;

  // Loop through columns and compare matrixes
  count = [_browserColumns count];
  for (i = 0; i < count; ++i)
    {
      if (!(bc = [_browserColumns objectAtIndex: i]))
      	continue;
      if (matrix == [bc columnMatrix])
      	return i;
    }

  // Not found
  return -1;
}

// -------------------
// Returns the index of the last column with a selected item.
//

- (int)selectedColumn
{
  int i;
  id bc, matrix;

  for (i = _lastColumnLoaded; i >= 0; i--)
    {
      if (!(bc = [_browserColumns objectAtIndex: i]))
      	continue;
      if (![bc isLoaded] || !(matrix = [bc columnMatrix]))
      	continue;
      if ([matrix selectedCell])
      	return i;
    }
  
  return -1;
}

// -------------------
// Returns the index of the last column loaded.
//

- (int)lastColumn
{
  return _lastColumnLoaded;
}

// -------------------
// Sets the last column to column.
//

- (void)setLastColumn: (int)column
{
  if (column < -1)
    {
      column = -1;
    }

  _lastColumnLoaded = column;
  [self _unloadFromColumn: column + 1];
  [self _setColumnTitlesNeedDisplay];
}

// -------------------
// Returns the index of the first visible column.
//

- (int)firstVisibleColumn
{
  return _firstVisibleColumn;
}

// -------------------
// Returns the number of columns visible.
//

- (int)numberOfVisibleColumns
{
  int num;

  num = _lastVisibleColumn - _firstVisibleColumn + 1;

  return (num > 0 ? num : 1);
}

// -------------------
// Returns the index of the last visible column.
//

- (int)lastVisibleColumn
{
  return _lastVisibleColumn;
}

// -------------------
// Invokes delegate method browser:isColumnValid: for visible columns.
//

- (void)validateVisibleColumns
{
  int i;

  // If delegate doesn't care, just return
  if (![_browserDelegate respondsToSelector: 
			   @selector(browser:isColumnValid:)])
    {
      return;
    }

  // Loop through the visible columns
  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
    {
      // Ask delegate if the column is valid and if not
      // then reload the column
      if (![_browserDelegate browser: self  isColumnValid: i])
	{
	  [self reloadColumn: i];
	}
    }
}



////////////////////////////////////////////////////////////////////////////////
// Loading columns
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns whether column zero is loaded.
//

- (BOOL)isLoaded
{
  return _isLoaded;
}

// -------------------
// Loads column zero; unloads previously loaded columns.
//

- (void)loadColumnZero
{
  // set last column loaded
  [self setLastColumn: -1];

  // load column 0
  [self addColumn];

  [self _remapColumnSubviews: YES];
  [self _setColumnTitlesNeedDisplay];
}

// -------------------
// Reloads column if it is loaded; sets it as the last column.
//

- (void)reloadColumn: (int)column
{
  NSArray *selectedCells;
  NSMatrix *matrix;
  int i, count, max;
  int *selectedIndexes = NULL;

  // Make sure the column even exists
  if (column > _lastColumnLoaded)
    return;

  // Save the index of the previously selected cells
  matrix = [self matrixInColumn: column];
  selectedCells = [matrix selectedCells];
  count = [selectedCells count];
  if (count > 0)
    {
      selectedIndexes = NSZoneMalloc (NSDefaultMallocZone (), 
				      sizeof (int) * count);
      for (i = 0; i < count; i++)
	{
	  NSCell *cell = [selectedCells objectAtIndex: i];
	  int sRow, sColumn;
	  
	  [matrix getRow: &sRow  column: &sColumn  ofCell: cell];
	  selectedIndexes[i] = sRow;
	}
    }
  

  // Perform the data load
  [self _performLoadOfColumn: column];
  [self _adjustMatrixOfColumn: column];

  // Restore the selected cells
  if (count > 0)
    {
      matrix = [self matrixInColumn: column];
      max = [matrix numberOfRows];
      for (i = 0; i < count; i++)
	{
	  // Abort when it stops making sense
	  if (selectedIndexes[i] > max)
	    {
	      break;
	    }
	  
	  [matrix selectCellAtRow: selectedIndexes[i]  column: 0];
	}
      NSZoneFree (NSDefaultMallocZone (), selectedIndexes);
    }

  // set last column loaded
  [self setLastColumn: column];
}



////////////////////////////////////////////////////////////////////////////////
// Setting selection characteristics
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns whether the user can select branch items when multiple selection
// is enabled.
//

- (BOOL)allowsBranchSelection
{
  return _allowsBranchSelection;
}

// -------------------
// Sets whether the user can select branch items when multiple selection
// is enabled.
//

- (void)setAllowsBranchSelection: (BOOL)flag
{
  _allowsBranchSelection = flag;
}

// -------------------
// Returns whether there can be nothing selected.
//

- (BOOL)allowsEmptySelection
{
  return _allowsEmptySelection;
}

// -------------------
// Sets whether there can be nothing selected.
//

- (void)setAllowsEmptySelection: (BOOL)flag
{
  _allowsEmptySelection = flag;
}

// -------------------
// Returns whether the user can select multiple items.
//

- (BOOL)allowsMultipleSelection
{
  return _allowsMultipleSelection;
}

// -------------------
// Sets whether the user can select multiple items.
//

- (void)setAllowsMultipleSelection: (BOOL)flag
{
  _allowsMultipleSelection = flag;
}



////////////////////////////////////////////////////////////////////////////////
// Setting column characteristics
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns YES if NSMatrix objects aren't freed when their columns are unloaded.
//

- (BOOL)reusesColumns
{
  return _reusesColumns;
}

// -------------------
// If flag is YES, prevents NSMatrix objects from being freed when their
// columns are unloaded, so they can be reused.
//

- (void)setReusesColumns: (BOOL)flag
{
  _reusesColumns = flag;
}

// -------------------
// Returns the maximum number of visible columns.
//

- (int)maxVisibleColumns
{
  return _maxVisibleColumns;
}

// -------------------
// Sets the maximum number of columns displayed.
//

- (void)setMaxVisibleColumns: (int)columnCount
{
  if ((columnCount < 1) || (_maxVisibleColumns == columnCount))
    return;

  _maxVisibleColumns = columnCount;

  // Redisplay
  [self tile];
}

// -------------------
// Returns the minimum column width in pixels.
//

- (int)minColumnWidth
{
  return _minColumnWidth;
}

// -------------------
// Sets the minimum column width in pixels.
//

- (void)setMinColumnWidth: (int)columnWidth
{
  float sw;

  sw = scrollerWidth;
  // Take the border into account
  if (_separatesColumns)
    sw += 2 * (_sizeForBorderType (NSBezelBorder)).width;

  // Column width cannot be less than scroller and border
  if (columnWidth < sw)
    _minColumnWidth = sw;
  else
    _minColumnWidth = columnWidth;

  [self tile];
}

// -------------------
// Returns whether columns are separated by bezeled borders.
//

- (BOOL)separatesColumns
{
  return _separatesColumns;
}

// -------------------
// Sets whether to separate columns with bezeled borders.
//

- (void)setSeparatesColumns: (BOOL)flag
{
  if (_separatesColumns != flag)
    {
      _separatesColumns = flag;
      [self tile];
    }
}

// -------------------
// Returns YES if the title of a column is set to the string value of
// the selected NSCell in the previous column.
//

- (BOOL)takesTitleFromPreviousColumn
{
  return _takesTitleFromPreviousColumn;
}

// -------------------
// Sets whether the title of a column is set to the string value of the
// selected NSCell in the previous column.
//

- (void)setTakesTitleFromPreviousColumn: (BOOL)flag
{
  _takesTitleFromPreviousColumn = flag;
}



////////////////////////////////////////////////////////////////////////////////
// Manipulating column titles
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the title displayed for the column at index column.
//

- (NSString *) titleOfColumn: (int)column
{
  id bc;

  bc = [_browserColumns objectAtIndex: column];

  return [bc columnTitle];
}

// -------------------
// Sets the title of the column at index column to aString.
//

- (void) setTitle: (NSString *)aString
	 ofColumn: (int)column
{
  id bc;

  bc = [_browserColumns objectAtIndex: column];

  [bc setColumnTitle: aString];
  
  // If column is not visible then nothing to redisplay
  if (!_isTitled || !NSBR_COLUMN_IS_VISIBLE(column))
    return;
  
  [self setNeedsDisplayInRect: [self titleFrameOfColumn: column]];
}

// -------------------
// Returns whether columns display titles.
//

- (BOOL)isTitled
{
  return _isTitled;
}

// -------------------
// Sets whether columns display titles.
//

- (void)setTitled: (BOOL)flag
{
  if (_isTitled != flag)
    {
      _isTitled = flag;
      [self tile];
      [self setNeedsDisplay: YES];
    }
}

// -------------------
// Draws the title for the column at index column within the rectangle
// defined by aRect.
//

- (void)drawTitle: (NSString *)title
	   inRect: (NSRect)aRect
	 ofColumn: (int)column
{
  if (!_isTitled || !NSBR_COLUMN_IS_VISIBLE(column))
    return;

  [_titleCell setStringValue: title];
  [_titleCell drawWithFrame: aRect inView: self];
}

// -------------------
// Returns the height of column titles. 
//

- (float)titleHeight
{
  // Nextish look requires 21 here
  return 21;
}

// -------------------
// Returns the bounds of the title frame for the column at index column.
//

- (NSRect)titleFrameOfColumn: (int)column
{
  // Not titled then no frame
  if (!_isTitled)
    {
      return NSZeroRect;
    }
  else
    {
      // Number of columns over from the first
      int n = column - _firstVisibleColumn;
      int h = [self titleHeight];
      NSRect r;

      // Calculate origin
      if (_separatesColumns)
	{
	  r.origin.x = n * (_columnSize.width + NSBR_COLUMN_SEP);
	}
      else
	{
	  r.origin.x = n * _columnSize.width;
	}
      r.origin.y = _frame.size.height - h;
      
      // Calculate size
      if (column == _lastVisibleColumn)
	{
	  r.size.width = _frame.size.width - r.origin.x;
	}
      else
	{
	  r.size.width = _columnSize.width;
	}
      r.size.height = h;

      return r;
    }
}



////////////////////////////////////////////////////////////////////////////////
// Scrolling an NSBrowser
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Scrolls to make the column at index column visible.
//

- (void)scrollColumnToVisible: (int)column
{
  int i;

  // If its the last visible column then we are there already
  if (_lastVisibleColumn == column)
    return;

  // If there are not enough columns to scroll with
  // then the column must be visible
  if (_lastColumnLoaded + 1 <= [self numberOfVisibleColumns])
    return;

  i = _lastVisibleColumn - column;
  if (i > 0)
    [self scrollColumnsLeftBy: i];
  else
    [self scrollColumnsRightBy: (-i)];
}

// -------------------
// Scrolls columns left by shiftAmount columns.
//

- (void)scrollColumnsLeftBy: (int)shiftAmount
{
  // Cannot shift past the zero column
  if ((_firstVisibleColumn - shiftAmount) < 0)
    shiftAmount = _firstVisibleColumn;

  // No amount to shift then nothing to do
  if (shiftAmount <= 0)
    return;

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserWillScroll:)])
    [_browserDelegate browserWillScroll: self];

  // Shift
  _firstVisibleColumn = _firstVisibleColumn - shiftAmount;
  _lastVisibleColumn = _lastVisibleColumn - shiftAmount;

  // Update the scroller
  [self updateScroller];

  // Update the scrollviews
  [self tile];
  [self _remapColumnSubviews: YES];
  [self _setColumnTitlesNeedDisplay];

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserDidScroll:)])
    [_browserDelegate browserDidScroll: self];  
}

// -------------------
// Scrolls columns right by shiftAmount columns.
//

- (void)scrollColumnsRightBy: (int)shiftAmount
{
  // Cannot shift past the last loaded column
  if ((shiftAmount + _lastVisibleColumn) > _lastColumnLoaded)
    shiftAmount = _lastColumnLoaded - _lastVisibleColumn;

  // No amount to shift then nothing to do
  if (shiftAmount <= 0)
    return;

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserWillScroll:)])
    [_browserDelegate browserWillScroll: self];

  // Shift
  _firstVisibleColumn = _firstVisibleColumn + shiftAmount;
  _lastVisibleColumn = _lastVisibleColumn + shiftAmount;

  // Update the scroller
  [self updateScroller];

  // Update the scrollviews
  [self tile];
  [self _remapColumnSubviews: NO];
  [self _setColumnTitlesNeedDisplay];

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserDidScroll:)])
    [_browserDelegate browserDidScroll: self];
}

// -------------------
// Updates the horizontal scroller to reflect column positions.
//

- (void) updateScroller
{
  int num;

  num = [self numberOfVisibleColumns];

  // If there are not enough columns to scroll with
  // then the column must be visible
  if ((_lastColumnLoaded == 0) ||
      (_lastColumnLoaded <= (num - 1)))
    {
      [_horizontalScroller setEnabled: NO];
    }
  else
    {
      if (!_skipUpdateScroller)
      	{
      	  float prop = (float)num / (float)(_lastColumnLoaded + 1);
      	  float i = _lastColumnLoaded - num + 1;
      	  float f = 1 + ((_lastVisibleColumn - _lastColumnLoaded) / i);

          [_horizontalScroller setFloatValue: f knobProportion: prop];
	}
      [_horizontalScroller setEnabled: YES];
    }

  [_horizontalScroller setNeedsDisplay: YES];
}

// -------------------
// Scrolls columns left or right based on an NSScroller.
//

- (void)scrollViaScroller: (NSScroller *)sender
{
  NSScrollerPart hit;

  if ([sender class] != [NSScroller class])
    return;
  
  hit = [sender hitPart];
  
  switch (hit)
    {
      // Scroll to the left
      case NSScrollerDecrementLine:
      case NSScrollerDecrementPage:
      	[self scrollColumnsLeftBy: 1];
      	break;
      
      // Scroll to the right
      case NSScrollerIncrementLine:
      case NSScrollerIncrementPage:
        [self scrollColumnsRightBy: 1];
      	break;
      
      // The knob or knob slot
      case NSScrollerKnob:
      case NSScrollerKnobSlot:
	{
	  int num = [self numberOfVisibleColumns];
	  float f = [sender floatValue];
	  float n = _lastColumnLoaded + 1 - num;

	  _skipUpdateScroller = YES;
	  [self scrollColumnToVisible: rintf(f * n) + num - 1];
	  _skipUpdateScroller = NO;
	}
      	break;
      
      // NSScrollerNoPart ???
      default:
      	break;
    }
}



////////////////////////////////////////////////////////////////////////////////
// Showing a horizontal scroller
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns whether an NSScroller is used to scroll horizontally.
//

- (BOOL)hasHorizontalScroller
{
  return _hasHorizontalScroller;
}

// -------------------
// Sets whether an NSScroller is used to scroll horizontally.
//

- (void)setHasHorizontalScroller: (BOOL)flag
{
  if (_hasHorizontalScroller != flag)
    {
      _hasHorizontalScroller = flag;
      if (!flag)
      	[_horizontalScroller removeFromSuperview];
      else
        [self addSubview: _horizontalScroller];
      [self tile];
      [self setNeedsDisplay: YES];
    }
}



////////////////////////////////////////////////////////////////////////////////
// Setting the behavior of arrow keys
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns YES if the arrow keys are enabled.
//

- (BOOL)acceptsArrowKeys
{
  return _acceptsArrowKeys;
}

// -------------------
// Enables or disables the arrow keys as used for navigating within
// and between browsers.
//

- (void) setAcceptsArrowKeys: (BOOL)flag
{
  _acceptsArrowKeys = flag;
}

// -------------------
// Returns NO if pressing an arrow key only scrolls the browser, YES if
// it also sends the action message specified by setAction:.
//

- (BOOL) sendsActionOnArrowKeys
{
  return _sendsActionOnArrowKeys;
}

// -------------------
// Sets whether pressing an arrow key will cause the action message
// to be sent (in addition to causing scrolling).
//

- (void) setSendsActionOnArrowKeys: (BOOL)flag
{
  _sendsActionOnArrowKeys = flag;
}



////////////////////////////////////////////////////////////////////////////////
// Getting column frames
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the rectangle containing the column at index column.
//

- (NSRect) frameOfColumn: (int)column
{
  NSRect r = NSZeroRect;
  NSSize bs = _sizeForBorderType (NSBezelBorder);
  int n;

  // Number of columns over from the first
  n = column - _firstVisibleColumn;

  // Calculate the frame
  r.size = _columnSize;
  r.origin.x = n * _columnSize.width;

  if (_separatesColumns)
    {
      r.origin.x += n * NSBR_COLUMN_SEP;
    }

  // Adjust for horizontal scroller
  if (_hasHorizontalScroller)
    {
      r.origin.y = scrollerWidth + (2 * bs.height) + NSBR_VOFFSET;
    }

  // Padding : _columnSize.width is rounded in "tile" method
  if (column == _lastVisibleColumn)
    {
      r.size.width = _frame.size.width - r.origin.x;
    }

  if (r.size.width < 0)
    {
      r.size.width = 0;
    }
  if (r.size.height < 0)
    {
      r.size.height = 0;
    }

  return r;
}

// -------------------
// Returns the rectangle containing the column at index column,
// not including borders.
//

- (NSRect) frameOfInsideOfColumn: (int)column
{
  // xxx what does this one do?
  return [self frameOfColumn: column];
}



////////////////////////////////////////////////////////////////////////////////
// Arranging browser components
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Adjusts the various subviews of NSBrowser-scrollers, columns, titles,
// and so on-without redrawing. Your code shouldn't send this message.
// It's invoked any time the appearance of the NSBrowser changes.
//

- (void) tile
{
  NSSize bs = _sizeForBorderType (NSBezelBorder);
  int i, num, columnCount, delta;
  id bc, sc;

  _columnSize.height = _frame.size.height;
  
  // Titles (there is no real frames to resize)
  if (_isTitled)
    {
      _columnSize.height -= [self titleHeight] + NSBR_VOFFSET;
    }

  // Horizontal scroller
  if (_hasHorizontalScroller)
    {
      _scrollerRect.origin.x = bs.width;
      _scrollerRect.origin.y = bs.height;
      _scrollerRect.size.width = _frame.size.width - (2 * bs.width);
      _scrollerRect.size.height = scrollerWidth;

      _columnSize.height -= scrollerWidth + (2 * bs.height) + NSBR_VOFFSET;
    }
  else
    {
      _scrollerRect = NSZeroRect;
    }

  if (!NSEqualRects(_scrollerRect, [_horizontalScroller frame]))
    {
      [_horizontalScroller setFrame: _scrollerRect];
    }
  
  num = _lastVisibleColumn - _firstVisibleColumn + 1;

  if (_minColumnWidth > 0)
    {
      float colWidth = _minColumnWidth + scrollerWidth;

      if ((int)(_frame.size.width > _minColumnWidth))
	{
	  if (_separatesColumns)
	    colWidth += NSBR_COLUMN_SEP;

	  columnCount = (int)(_frame.size.width / colWidth);
	}
      else
	columnCount = 1;
    }
  else
    columnCount = num;

  if (_maxVisibleColumns > 0 && columnCount > _maxVisibleColumns)
    columnCount = _maxVisibleColumns;

  if (columnCount != num)
    {
      if (num > 0)
	delta = columnCount - num;
      else
	delta = columnCount - 1;

      if ((delta > 0) && (_lastVisibleColumn <= _lastColumnLoaded))
	{
	  _firstVisibleColumn = (_firstVisibleColumn - delta > 0) ?
	    _firstVisibleColumn - delta : 0;
	}

      for (i = [_browserColumns count]; i < columnCount; i++)
	[self _createColumn];

      _lastVisibleColumn = _firstVisibleColumn + columnCount - 1;
    }

  // Columns
  if (_separatesColumns)
    {
      _columnSize.width = (int)((_frame.size.width - ((columnCount - 1)
						      * NSBR_COLUMN_SEP)) 
				/ (float)columnCount);
    }
  else
    {
      _columnSize.width = (int)(_frame.size.width / (float)columnCount);
    }

  if (_columnSize.height < 0)
    _columnSize.height = 0;
  
  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
    {
      bc = [_browserColumns objectAtIndex: i];

      if (!(sc = [bc columnScrollView]))
	return;

      [sc setFrame: [self frameOfColumn: i]];
      [self _adjustMatrixOfColumn: i];
    }

  if (columnCount != num)
    {
      [self updateScroller];
      [self _remapColumnSubviews: YES];
      //      [self _setColumnTitlesNeedDisplay];  
      [self setNeedsDisplay: YES];
    }
}



////////////////////////////////////////////////////////////////////////////////
// Setting the delegate
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the NSBrowser's delegate.
//

- (id) delegate
{
  return _browserDelegate;
}

// -------------------
// Sets the NSBrowser's delegate to anObject.
// Raises NSBrowserIllegalDelegateException if the delegate specified
// by anObject doesn't respond to browser:willDisplayCell:atRow:column:
// (if passive) and either of the methods browser:numberOfRowsInColumn:
// or browser:createRowsForColumn:inMatrix:.
//

- (void) setDelegate: (id)anObject
{
  BOOL flag = NO;
  BOOL both = NO;

  if ([anObject respondsToSelector: 
		  @selector(browser:numberOfRowsInColumn:)])
    {
      _passiveDelegate = YES;
      flag = YES;
    }

  if ([anObject respondsToSelector: 
		  @selector(browser:createRowsForColumn:inMatrix:)])
    {
      _passiveDelegate = NO;

      // If flag is already set
      // then delegate must respond to both methods
      if (flag)
	both = YES;

      flag = YES;
    }

  if (_passiveDelegate && ![anObject respondsToSelector: 
		  @selector(browser:willDisplayCell:atRow:column:)])
    [NSException raise: NSBrowserIllegalDelegateException
		 format: @"(Passive) Delegate does not respond to %s\n",
		 "browser: willDisplayCell: atRow: column: "];

  if (!flag)
    [NSException raise: NSBrowserIllegalDelegateException
		 format: @"Delegate does not respond to %s or %s\n",
		 "browser: numberOfRowsInColumn: ",
		 "browser: createRowsForColumn: inMatrix: "];

  if (both)
    [NSException raise: NSBrowserIllegalDelegateException
		 format: @"Delegate responds to both %s and %s\n",
		 "browser: numberOfRowsInColumn: ",
		 "browser: createRowsForColumn: inMatrix: "];

  _browserDelegate = anObject;
}



////////////////////////////////////////////////////////////////////////////////
// Target and action
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the NSBrowser's double-click action method.
//

- (SEL) doubleAction
{
  return _doubleAction;
}

// -------------------
// Sets the NSBrowser's double-click action to aSelector.
//

- (void) setDoubleAction: (SEL)aSelector
{
  _doubleAction = aSelector;
}

// -------------------
// Sends the action message to the target. Returns YES upon success,
// NO if no target for the message could be found. 
//

- (BOOL) sendAction
{
  return [self sendAction: [self action]  to: [self target]];
}



////////////////////////////////////////////////////////////////////////////////
// Event handling
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Responds to (single) mouse clicks in a column of the NSBrowser.
//

- (void) doClick: (id)sender
{
  NSArray        *a;
  NSMutableArray *selectedCells;
  NSEnumerator   *enumerator;
  NSBrowserCell  *cell;
  BOOL            shouldSelect = YES, sel1, sel2;
  int             row, column, aCount, selectedCellsCount;

  if ([sender class] != _browserMatrixClass)
    return;

  column = [self columnOfMatrix: sender];
  // If the matrix isn't ours then just return
  if (column == -1)
    return;

  a = [sender selectedCells];
  aCount = [a count];
  if(aCount == 0)
    return;

  selectedCells = [a mutableCopy];

  enumerator = [a objectEnumerator];
  while ((cell = [enumerator nextObject]))
    {
      if (_allowsBranchSelection == NO && [cell isLeaf] == NO)
	{
	  [selectedCells removeObject: cell];
	  continue;
	}
    }

  if ([selectedCells count] == 0)
    [selectedCells addObject: [sender selectedCell]];

  sel1 = [_browserDelegate respondsToSelector:
			     @selector(browser:selectRow:inColumn:)];
  sel2 = [_browserDelegate respondsToSelector: 
			     @selector(browser:selectCellWithString:inColumn:)];

  enumerator = [a objectEnumerator];
  while ((cell = [enumerator nextObject]))
    {
      if ([selectedCells containsObject: cell] == YES)
	{
	  // Ask delegate if selection is ok
	  if (sel1)
	    {
	      [sender getRow: &row column: NULL ofCell: cell];

	      shouldSelect = [_browserDelegate browser: self
					       selectRow: row
					       inColumn: column];
	    }
	  // Try the other method
	  else if (sel2)
	    {
	      shouldSelect = [_browserDelegate browser: self
					       selectCellWithString:
						 [cell stringValue]
					       inColumn: column];
	    }

	  if (shouldSelect == NO)
	    [selectedCells removeObject: cell];
	}
    }

  selectedCellsCount = [selectedCells count];

  if (selectedCellsCount == 0)
    {
      // If we should not select the cell
      // then deselect it and return

      [sender deselectAllCells];
      RELEASE(selectedCells);
      return;
    }
  else if (selectedCellsCount < aCount)
    {
      [sender deselectSelectedCell];

      enumerator = [selectedCells objectEnumerator];
      while ((cell = [enumerator nextObject]))
	[sender selectCell: cell];

      enumerator = [a objectEnumerator];
      while ((cell = [enumerator nextObject]))
	{
	  if ([selectedCells containsObject: cell] == NO)
	    {
	      if (![sender getRow: &row column: NULL ofCell: cell])
		continue;

	      if ([cell isHighlighted])
		[sender highlightCell: NO atRow: row column: 0];
	      else
		[sender drawCellAtRow: row column: 0];
	    }
	}
    }

  if (selectedCellsCount > 0)
    {
      // Single selection
      if (selectedCellsCount == 1)
      	{
      	  cell = [selectedCells objectAtIndex: 0];
	  
	  // If the cell is a leaf
	  // then unload the columns after
	  if ([cell isLeaf])
	    [self setLastColumn: column];
	  // The cell is not a leaf so we need to load a column
	  else
	    {
	      int count = [_browserColumns count];

	      if (column < count - 1)
		  [self setLastColumn: column];

	      [self addColumn];
	    }

	  [sender scrollCellToVisibleAtRow: [sender selectedRow]
		  column: column];
	}
      // Multiple selection
      else
	{
	  [self setLastColumn: column];
	}
    }

  // Send the action to target
  [self sendAction];

  // Marks titles band as needing display.
  [self _setColumnTitlesNeedDisplay];

  RELEASE(selectedCells);
}

// -------------------
// Responds to double-clicks in a column of the NSBrowser.
//

- (void)doDoubleClick: (id)sender
{
  // We have already handled the single click
  // so send the double action

  [self sendAction: _doubleAction to: [self target]];
}



// #############################################################################
//
//  OVERRIDING METHODS
//
// #############################################################################



////////////////////////////////////////////////////////////////////////////////
// Class methods
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Initialize
//

+ (void)initialize
{
  if (self == [NSBrowser class])
    {
      // Initial version
      [self setVersion: 1];
      scrollerWidth = [NSScroller scrollerWidth];
    }
}



////////////////////////////////////////////////////////////////////////////////
// Instance methods
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Setups browser with frame 'rect'.
//

- (id)initWithFrame: (NSRect)rect
{
  NSSize bs;
  //NSScroller *hs;

  self = [super initWithFrame: rect];

  // Class setting
  _browserCellClass = [NSBrowser cellClass];
  _browserCellPrototype = [[_browserCellClass alloc] init];
  _browserMatrixClass = [NSMatrix class];
  
  // Default values
  _pathSeparator = @"/";
  _allowsBranchSelection = YES;
  _allowsEmptySelection = YES;
  _allowsMultipleSelection = YES;
  _reusesColumns = NO;
  _separatesColumns = YES;
  _isTitled = YES;
  _takesTitleFromPreviousColumn = YES;
  _hasHorizontalScroller = YES;
  _isLoaded = NO;
  _acceptsArrowKeys = YES;
  _sendsActionOnArrowKeys = YES;
  _browserDelegate = nil;
  _passiveDelegate = YES;
  _doubleAction = NULL;  
  bs = _sizeForBorderType (NSBezelBorder);
  _minColumnWidth = scrollerWidth + (2 * bs.width);
  if (_minColumnWidth < 100.0)
    _minColumnWidth = 100.0;

  // Horizontal scroller
  _scrollerRect.origin.x = bs.width;
  _scrollerRect.origin.y = bs.height;
  _scrollerRect.size.width = _frame.size.width - (2 * bs.width);
  _scrollerRect.size.height = scrollerWidth;
  _horizontalScroller = [[NSScroller alloc] initWithFrame: _scrollerRect];
  [_horizontalScroller setTarget: self];
  [_horizontalScroller setAction: @selector(scrollViaScroller:)];
  [self addSubview: _horizontalScroller];
  _skipUpdateScroller = NO;

  // Columns
  _browserColumns = [[NSMutableArray alloc] init];
  _titleCell = [GSBrowserTitleCell new];

  // Create a single column
  _lastColumnLoaded = -1;
  _firstVisibleColumn = 0;
  _lastVisibleColumn = 0;
  [self _createColumn];

  return self;
}

// -------------------
// Frees components.
//

- (void)dealloc
{
  RELEASE(_browserCellPrototype);
  RELEASE(_pathSeparator);
  RELEASE(_horizontalScroller);
  RELEASE(_browserColumns);
  RELEASE(_titleCell);

  [super dealloc];
}



////////////////////////////////////////////////////////////////////////////////
// Target-actions
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Set target to 'target'
//

- (void) setTarget: (id)target
{
  _target = target;
}

// -------------------
// Return current target.
//

- (id) target
{
  return _target;
}

// -------------------
// Set action to 's'.
//

- (void) setAction: (SEL)s
{
  _action = s;
}

// -------------------
// Return current action.
//

- (SEL) action
{
  return _action;
}



////////////////////////////////////////////////////////////////////////////////
// Events handling
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Draws browser.
//

- (void)drawRect: (NSRect)rect
{
  NSRectClip(rect);
  [[_window backgroundColor] set];
  NSRectFill(rect);

  // Load the first column if not already done
  if (!_isLoaded)
    {
      [self loadColumnZero];
    }

  // Draws titles
  if (_isTitled)
    {
      int i;

      for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
	{
	  NSRect titleRect = [self titleFrameOfColumn: i];
	  if (NSIntersectsRect (titleRect, rect) == YES)
	    {
	      NSString *title;
	      
	      title = [self _getTitleOfColumn: i];
	      [self setTitle: title ofColumn: i];
	      [self drawTitle: title  inRect: titleRect  ofColumn: i];
	    }
	}
    }

  // Draws scroller border
  if (_hasHorizontalScroller)
    {
      NSRect scrollerBorderRect = _scrollerRect;
      NSSize bs = _sizeForBorderType (NSBezelBorder);

      scrollerBorderRect.origin.x = 0;
      scrollerBorderRect.origin.y = 0;
      scrollerBorderRect.size.width += 2 * bs.width;
      scrollerBorderRect.size.height += 2 * bs.height;

      if ((NSIntersectsRect (scrollerBorderRect, rect) == YES) && _window)
      	{
      	  NSDrawGrayBezel (scrollerBorderRect, rect);
	}
    }
}

// -------------------
// Informs the receivers's subviews that the receiver's bounds rectangle size
// has changed from oldFrameSize.
//

- (void) resizeSubviewsWithOldSize: (NSSize)oldSize
{
  [self tile];
}


// -------------------
// Override NSControl handler (prevents highlighting).
//

- (void)mouseDown: (NSEvent *)theEvent
{
}

- (void)moveLeft:(id)sender
{
  if (_acceptsArrowKeys)
    {
      NSMatrix *matrix;
      NSCell   *selectedCell;
      int       selectedRow, selectedColumn;

      selectedColumn = [self selectedColumn];
      if (selectedColumn > 0)
	{
	  matrix = [self matrixInColumn: selectedColumn];
	  selectedCell = [matrix selectedCell];
	  selectedRow = [matrix selectedRow];

	  [matrix deselectAllCells];

	  if(selectedColumn+1 <= [self lastColumn])
	    [self setLastColumn: selectedColumn];

	  matrix = [self matrixInColumn: [self selectedColumn]];
	  [_window makeFirstResponder: matrix];

	  if (_sendsActionOnArrowKeys == YES)
	    [super sendAction: _action to: _target];
	}
    }
}

- (void)moveRight:(id)sender
{
  if (_acceptsArrowKeys)
    {
      NSMatrix *matrix;
      BOOL      selectFirstRow = NO;
      int       selectedColumn;

      selectedColumn = [self selectedColumn];
      if (selectedColumn == -1)
	{
	  matrix = [self matrixInColumn: 0];

	  if ([[matrix cells] count])
	    {
	      [matrix selectCellAtRow: 0 column: 0];
	      [_window makeFirstResponder: matrix];
	      [self doClick: matrix];
	      selectedColumn = 0;
	    }
	}
      else
	{
	  matrix = [self matrixInColumn: selectedColumn];

	  if (![[matrix selectedCell] isLeaf]
	      && [[matrix selectedCells] count] == 1)
	    selectFirstRow = YES;
	}

      if(selectFirstRow == YES)
	{
	  matrix = [self matrixInColumn: [self lastColumn]];
	  if ([[matrix cells] count])
	    {
	      [matrix selectCellAtRow: 0 column: 0];
	      [_window makeFirstResponder: matrix];
	      [self doClick: matrix];
	    }
	}

      if (_sendsActionOnArrowKeys == YES)
	[super sendAction: _action to: _target];
    }
}

- (void) keyDown: (NSEvent *)theEvent
{
  NSString *characters = [theEvent characters];
  unichar character = 0;

  if ([characters length] > 0)
    {
      character = [characters characterAtIndex: 0];
    }

  if (_acceptsArrowKeys)
    {
      switch (character)
	{
	case NSUpArrowFunctionKey:
	case NSDownArrowFunctionKey:
	  return;
	case NSLeftArrowFunctionKey:
	  [self moveLeft:self];
	  return;
	case NSRightArrowFunctionKey:
	  [self moveRight:self];
	  return;
	case NSTabCharacter:
	  {
	    if ([theEvent modifierFlags] & NSShiftKeyMask)
	      {
		[_window selectKeyViewPrecedingView: self];
	      }
	    else
	      {
		[_window selectKeyViewFollowingView: self];
	      }
	  }
	  return;
	}
    }

  [super keyDown: theEvent];
}

////////////////////////////////////////////////////////////////////////////////
// NSCoding protocol
////////////////////////////////////////////////////////////////////////////////



// -------------------
// ...
//

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

// -------------------
// ...
//

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}



////////////////////////////////////////////////////////////////////////////////
// Div.
////////////////////////////////////////////////////////////////////////////////



// -------------------
// ...
//

- (BOOL) isOpaque
{
  return YES; // See drawRect.
}

/* ???????????????????
//
// Displaying the Control and Cell
//
- (void)drawCell: (NSCell *)aCell
{
}

- (void)drawCellInside: (NSCell *)aCell
{
}

- (void)selectCell: (NSCell *)aCell
{
}

- (void)updateCell: (NSCell *)aCell
{
}

- (void)updateCellInside: (NSCell *)aCell
{
}
*/

@end




// #############################################################################
//
//  PRIVATE METHODS
//
// #############################################################################



@implementation NSBrowser (Private)


// -------------------
// 
//

- (void)_adjustMatrixOfColumn: (int)column
{
  NSBrowserColumn	*bc;
  NSScrollView		*sc;
  id			matrix;
  NSSize		cs, ms;

  if (column >= (int)[_browserColumns count])
    return;

  bc = [_browserColumns objectAtIndex: column];

  sc = [bc columnScrollView];
  matrix = [bc columnMatrix];

  // Adjust matrix to fit in scrollview if column has been loaded
  if (sc && matrix && [bc isLoaded])
    {
      cs = [sc contentSize];
      ms = [matrix cellSize];
      ms.width = cs.width;
      [matrix setCellSize: ms];
      [sc setDocumentView: matrix];
    }
}

// -------------------
// 
//
#if 0
- (void)_adjustScrollerFrameOfColumn: (int)column force: (BOOL)flag
{
  // Only if we've loaded the first column
  if ((_isLoaded) || (flag))
    {
      NSBrowserColumn *bc;
      NSScrollView *sc;

      if (column >= (int)[_browserColumns count])
	return;

      bc = [_browserColumns objectAtIndex: column];
      sc = [bc columnScrollView];

      // Set the scrollview frame
      // Only set before the column has been loaded
      // Or we are being forced
      if (sc && ((![bc isLoaded]) || flag))
	[sc setFrame: [self frameOfInsideOfColumn: column]];
    }
}
#endif
// -------------------
// 
//

- (void)_remapColumnSubviews: (BOOL)fromFirst
{
  id bc, sc;
  int i, count;
  id firstResponder = nil;
  BOOL setFirstResponder = NO;

  // Removes all column subviews.
  count = [_browserColumns count];
  for (i = 0; i < count; i++)
    {
      bc = [_browserColumns objectAtIndex: i];
      sc = [bc columnScrollView];

      if (!firstResponder && [bc columnMatrix] == [_window firstResponder])
	{
	  firstResponder = [bc columnMatrix];
	}
      if (sc)
	{
	  [sc removeFromSuperviewWithoutNeedingDisplay];
	}
    }

  if (_firstVisibleColumn > _lastVisibleColumn)
    return;

  // Sets columns subviews order according to fromFirst (display order...).
  // All added subviews are automaticaly marked as needing display (->
  // NSView).
  if (fromFirst)
    {
      for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
	{
	  bc = [_browserColumns objectAtIndex: i];
	  sc = [bc columnScrollView];
	  [self addSubview: sc];

	  if ([bc columnMatrix] == firstResponder)
	    {
	      [_window makeFirstResponder: firstResponder];
	      setFirstResponder = YES;
	    }
	}

      if (firstResponder && setFirstResponder == NO)
	{
	  [_window makeFirstResponder:
		     [[_browserColumns objectAtIndex: _firstVisibleColumn]
		       columnMatrix]];
	}
    }
  else
    {
      for (i = _lastVisibleColumn; i >= _firstVisibleColumn; i--)
	{
	  bc = [_browserColumns objectAtIndex: i];
	  sc = [bc columnScrollView];
	  [self addSubview: sc];

	  if ([bc columnMatrix] == firstResponder)
	    {
	      [_window makeFirstResponder: firstResponder];
	      setFirstResponder = YES;
	    }
	}

      if (firstResponder && setFirstResponder == NO)
	{
	  [_window makeFirstResponder:
		     [[_browserColumns objectAtIndex: _lastVisibleColumn]
		       columnMatrix]];
	}
    }
}

// -------------------
// Loads column 'column' (asking the delegate).
//

- (void)_performLoadOfColumn: (int)column
{
  id bc, sc, matrix;
  NSRect matrixRect = {{0, 0}, {100, 100}};
  NSSize matrixIntercellSpace = {0, 0};

  bc = [_browserColumns objectAtIndex: column];

  if (!(sc = [bc columnScrollView]))
    return;

  matrix = [bc columnMatrix];

  // Loading is different based upon passive/active delegate
  if (_passiveDelegate)
    {
      // Ask the delegate for the number of rows
      int i, n = [_browserDelegate browser: self numberOfRowsInColumn: column];

      if (_reusesColumns && matrix)
	{
	  [matrix renewRows: n columns: 1];
	  [sc setDocumentView: matrix];

	  for (i = 0; i < n; i++)
	    {
	      [[matrix cellAtRow: i column: 0] setLoaded: NO];
	      [self loadedCellAtRow: i column: column];
	    }
	}
      else
	{
	  // create a new col matrix
	  matrix = [[_browserMatrixClass alloc]
		     initWithFrame: matrixRect
		     mode: NSListModeMatrix
		     prototype: _browserCellPrototype
		     numberOfRows: n
		     numberOfColumns: 1];
	  [matrix setIntercellSpacing:matrixIntercellSpace];
	  [matrix setAllowsEmptySelection: _allowsEmptySelection];
	  [matrix setAutoscroll: YES];
	  if (!_allowsMultipleSelection)
	    {
	      [matrix setMode: NSRadioModeMatrix];
	    }
	  [matrix setTarget: self];
	  [matrix setAction: @selector(doClick:)];
	  [matrix setDoubleAction: @selector(doDoubleClick:)];

	  // set new col matrix and release old
	  [bc setColumnMatrix: matrix];
	  RELEASE (matrix);
	  [sc setDocumentView: matrix];

	  // Now loop through the cells and load each one
	  for (i = 0; i < n; i++)
	    {
	      [self loadedCellAtRow: i column: column];
	    }
	}
    }
  else
    {
      if (_reusesColumns && matrix)
	{
	  [matrix renewRows: 0 columns: 1];
	  [sc setDocumentView: matrix];

	  [_browserDelegate browser: self
		createRowsForColumn: column
			   inMatrix: matrix];
	}
      else
	{
	  // create a new col matrix
	  matrix = [[_browserMatrixClass alloc]
		     initWithFrame: matrixRect
		     mode: NSRadioModeMatrix
		     prototype: _browserCellPrototype
		     numberOfRows: 0
		     numberOfColumns: 0];
	  [matrix setIntercellSpacing:matrixIntercellSpace];
	  [matrix setAllowsEmptySelection: _allowsEmptySelection];
	  [matrix setAutoscroll: YES];
	  if (_allowsMultipleSelection)
	    {
	      [matrix setMode: NSListModeMatrix];
	    }
	  [matrix setTarget: self];
	  [matrix setAction: @selector(doClick:)];
	  [matrix setDoubleAction: @selector(doDoubleClick:)];

	  // set new col matrix and release old
	  [bc setColumnMatrix: matrix];
	  RELEASE (matrix);
	  [sc setDocumentView: matrix];

	  // Tell the delegate to create the rows
	  [_browserDelegate browser: self
		createRowsForColumn: column
			   inMatrix: matrix];
	}
    }

  [matrix sizeToFit];
  [sc setNeedsDisplay: YES];
  [bc setIsLoaded: YES];
}

// -------------------
// Unloads all columns from and including 'column'.
//

- (void)_unloadFromColumn: (int)column
{
  int i, count, num;
  id bc, sc;

  // Unloads columns.
  count = [_browserColumns count];
  num = [self numberOfVisibleColumns];

  for (i = column; i < count; ++i)
    {
      bc = [_browserColumns objectAtIndex: i];
      sc = [bc columnScrollView];

      if ([bc isLoaded])
	{
	  // Make the column appear empty by removing the matrix
	  if (sc)
	    {
	      [sc setDocumentView: nil];
	      [sc setNeedsDisplay: YES];
	    }
	  [bc setIsLoaded: NO];
	}

      if (!_reusesColumns && i >= num)
	{
	  [sc removeFromSuperview];
	  [_browserColumns removeObject: bc];
	  count--;
	  i--;
	}
    }
  
  if (column == 0)
    {
      _isLoaded = NO;
    }
  
  // Scrolls if needed.
  if (column <= _lastVisibleColumn)
    {
      [self scrollColumnsLeftBy: _lastVisibleColumn - column + 1];
    }
  [self updateScroller];
}

// -------------------
// Marks all visible columns as needing to be redrawn.
//

- (void)_setColumnSubviewsNeedDisplay
{
  int i;

  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
    {
      [[[_browserColumns objectAtIndex:i] columnScrollView] 
	setNeedsDisplay:YES];
    }
}


// -------------------
// Marks all titles as needing to be redrawn.
//

- (NSString *)_getTitleOfColumn: (int)column
{
  // If not visible then nothing to display
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    return @"";

  // Ask the delegate for the column title
  if ([_browserDelegate respondsToSelector: 
			  @selector(browser:titleOfColumn:)])
    {
      return [_browserDelegate browser: self titleOfColumn: column];
    }
  

  // Check if we take title from previous column
  if (_takesTitleFromPreviousColumn)
    {
      id c;
      
      // If first column then use the path separator
      if (column == 0)
	{
	  return _pathSeparator;
	}
      
      // Get the selected cell
      // Use its string value as the title
      // Only if it is not a leaf
      if(_allowsMultipleSelection == NO)
	{
	  c = [self selectedCellInColumn: column - 1];
	}
      else
	{
	  NSMatrix *matrix;
	  NSArray  *selectedCells;

	  if (!(matrix = [self matrixInColumn: column - 1]))
	    return @"";

	  selectedCells = [matrix selectedCells];

	  if([selectedCells count] == 1)
	    {
	      c = [selectedCells objectAtIndex:0];
	    }
	  else
	    {
	      return @"";
	    }
	}

      if ([c isLeaf])
	{
	  return @"";
	}
      else
	{ 
	  return [c stringValue];
	}
    }
  return @"";
}

// -------------------
// Marks all titles as needing to be redrawn.
//

- (void)_setColumnTitlesNeedDisplay
{
  if (_isTitled)
    {
      NSRect r = [self titleFrameOfColumn: _firstVisibleColumn];

      r.size.width = _frame.size.width;
      [self setNeedsDisplayInRect: r];
    }
}

@end
