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

#define NSBR_COLUMN_SEP 6
#define NSBR_VOFFSET 3

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
  id _emptyView;
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
- emptyView;

@end

@implementation NSBrowserColumn

- (id) init
{
  [super init];

  _isLoaded = NO;
  _emptyView = [[NSView alloc] init];

  return self;
}

- (void) dealloc
{
  if (_columnScrollView)
    [_columnScrollView release];
  if (_columnMatrix)
    [_columnMatrix release];
  if (_emptyView)
    [_emptyView release];
  if (_columnTitle)
    [_columnTitle release];
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

  [aString retain];
  [_columnTitle release];
  _columnTitle = aString;
}

- (NSString *)columnTitle
{
  return _columnTitle;
}

- emptyView
{
  return _emptyView;
}

@end

@interface GSBrowserTitleCell: NSTextFieldCell
@end

@implementation GSBrowserTitleCell
- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];

  [self setTextColor: [NSColor windowFrameTextColor]];
  [self setBackgroundColor: [NSColor controlShadowColor]];
  [self setFont: [NSFont titleBarFontOfSize:12]];
  [self setEditable: NO];
  [self setBezeled: YES];
  [self setAlignment: NSCenterTextAlignment];
  _draws_background = YES;

  return self;
}
- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (NSIsEmptyRect (cellFrame) || ![controlView window])
    return;

  [controlView lockFocus];
  NSDrawGrayBezel (cellFrame, NSZeroRect);
  [controlView unlockFocus];
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}
@end

//
// Private NSBrowser methods
//
@interface NSBrowser (Private)
- (NSString *)_getTitleOfColumn: (int)column;
- (void)_performLoadOfColumn: (int)column;
- (void)_unloadFromColumn: (int)column;
- (void)_remapColumnSubviews: (BOOL)flag;
- (void)_adjustMatrixOfColumn: (int)column;
- (void)_setColumnSubviewsNeedDisplay;
- (void)_setColumnTitlesNeedDisplay;
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
  [self setCellPrototype: [[[_browserCellClass alloc] init] autorelease]];
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
  [aCell retain];
  [_browserCellPrototype release];
  _browserCellPrototype = aCell;
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


//#define NSBTRACE_all

// -------------------
// Returns the last (rightmost and lowest) selected NSCell.
//

- (id)selectedCell
{
  int i;
  id matrix;

#if defined NSBTRACE_selectedCell || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (id)selectedCell\n");
  fprintf(stderr, "----------- i: %d (%d)\n",
          [self selectedColumn], NSNotFound);
#endif

  // Nothing selected
  if ((i = [self selectedColumn]) == NSNotFound)
    return nil;

  if (!(matrix = [self matrixInColumn: i]))
    return nil;

  return [matrix selectedCell];
}

// -------------------
// Returns the last (lowest) NSCell that's selected in column.
//

- (id)selectedCellInColumn: (int)column
{
  id matrix;

#if defined NSBTRACE_selectedCellInColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSRect)selectedCellInColumn: %d\n", column);
#endif

  if (!(matrix = [self matrixInColumn: column]))
    return nil;

  return [matrix selectedCell];
}

// -------------------
// Returns all cells selected in the rightmost column.
//

- (NSArray *)selectedCells
{
  int i;
  id matrix;

#if defined NSBTRACE_selectedCells || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSArray *)selectedCells\n");
#endif

  // Nothing selected
  if ((i = [self selectedColumn]) == NSNotFound)
    return nil;

  if (!(matrix = [self matrixInColumn: i]))
    return nil;

  return [matrix selectedCells];
}

// -------------------
// Selects all NSCells in the last column of the NSBrowser.
//

- (void)selectAll: (id)sender
{
  id matrix;

#if defined NSBTRACE_selectAll || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)selectAll\n");
#endif

  if (!(matrix = [self matrixInColumn: _lastVisibleColumn]))
    return;

  [matrix selectAll: sender];
}

// -------------------
// Returns the row index of the selected cell in the column specified by
// index column.
//

- (int) selectedRowInColumn: (int)column
{
  id matrix;

#if defined NSBTRACE_selectedRowInColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (int)selectedRowInColumn: %d\n", column);
#endif

  if (!(matrix = [self matrixInColumn: column]))
    return NSNotFound;

  return [matrix selectedRow];
}

// -------------------
// Selects the cell at index row in the column identified by index column.
//

- (void)selectRow:(int)row inColumn:(int)column 
{
  id matrix;

#if defined NSBTRACE_selectRow || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSRect)selectedCellInColumn: %d\n", column);
#endif

  if (!(matrix = [self matrixInColumn: column]))
    return;

  [matrix selectCellAtRow: row column: 0];
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

#if defined NSBTRACE_loadedCellAtRow || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (id)loadedCellAtRow: %d,%d\n", row, column);
#endif

  // column range check
  if (column >= count)
    return nil;

  if (!(bc = [_browserColumns objectAtIndex: column]))
    return nil;
  
  if (!(matrix = [bc columnMatrix]))
    return nil;

  if (!(columnCells = [matrix cells]))
    return nil;

  count = [columnCells count];

  // row range check
  if (row >= count)
    return nil;

  // Get the cell
  if (!(aCell = [matrix cellAtRow: row column: 0]))
    return nil;

  // Load if not already loaded
  if ([aCell isLoaded])
    return aCell;
  else
    {
      [_browserDelegate browser: self willDisplayCell: aCell
			atRow: row column: column];
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

#if defined NSBTRACE_matrixInColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSMatrix *)matrixInColumn: %d\n", column);
#endif
  
  if (!(bc = [_browserColumns objectAtIndex: column]))
    return nil;
    
  if (![bc isLoaded])
    return nil;

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
#if defined NSBTRACE_path || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSString *)path\n");
#endif

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
  unsigned	i, j;
  BOOL	      	found = NO;
#define NSBTRACE_setPath
#if defined NSBTRACE_setPath || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (BOOL)setPath: %s\n", [path cString]);
#endif

  [self _unloadFromColumn: 0];
  
  // Column Zero is always present. 
  [self loadColumnZero];

  // If that's all, return.
  if ([path isEqualToString: _pathSeparator])
    {
      [self tile];
      [self updateScroller];
      [self _remapColumnSubviews: YES];
      [self setNeedsDisplay: YES];
      return YES;
    }

  // Otherwise, decompose the path.
  subStrings = [path componentsSeparatedByString: _pathSeparator];
  numberOfSubStrings = [subStrings count];

  // Ignore a trailing void component. 
  if (![subStrings objectAtIndex: 0])
    {
      NSRange theRange;
      
      theRange.location = 1;
      numberOfSubStrings--;
      theRange.length = numberOfSubStrings;
      subStrings = [subStrings subarrayWithRange: theRange];
    }

  // cycle thru str's array created from path
  for (i = 1; i < numberOfSubStrings; i++)
    {
      NSBrowserColumn	*bc = [_browserColumns objectAtIndex: i-1];
      NSMatrix		*matrix = [bc columnMatrix];
      NSArray		*cells = [matrix cells];
      unsigned		numOfRows = [cells count];
      NSBrowserCell	*selectedCell = nil;
      
      found = NO;
      aStr = [subStrings objectAtIndex: i];
      if (aStr)
	{
	  // find the cell in the browser matrix with the equal to aStr
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
	      NSLog (@"NSBrowser: unable to find cell '%@' in column %d\n", 
		     aStr, i - 1);
	      break;
	    }
	  // if the cell is not a leaf add a column to the browser for it
	  if (![selectedCell isLeaf])
	    {
	      if ([_browserColumns count] <= i) 
	      	[self addColumn];
	      [self _performLoadOfColumn: i];
	      [self setLastColumn: i];
	      [self _adjustMatrixOfColumn: i];
	      [self scrollColumnsRightBy: 1];
	    }
	  else
	    break;
	}
    }
  
  [self tile];
  [self updateScroller];
  [self _remapColumnSubviews: YES];
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

#if defined NSBTRACE_pathToColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSString *)pathToColumn: %d\n", column);
#endif

  /*
   * Cannot go past the number of loaded columns
   */
  if (column > _lastColumnLoaded)
    column = _lastColumnLoaded + 1;

  for (i = 0;i < column; ++i)
    {
      id	c = [self selectedCellInColumn: i];

      if (i != 0)
	[s appendString: _pathSeparator];
      [s appendString: [c stringValue]];
    }
  /*
   * We actually return a mutable string, but that's ok since a mutable
   * string is a string and the documentation specifically says that
   * people should not depend on methods that return strings to return
   * immutable strings.
   */

  return s;
}

// -------------------
// Returns the path separator. The default is "/".
//

- (NSString *)pathSeparator
{
#if defined NSBTRACE_pathSeparator || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSString *)pathSeparator\n");
#endif

  return _pathSeparator;
}

// -------------------
// Sets the path separator to newString.
//

- (void)setPathSeparator: (NSString *)aString
{
#if defined NSBTRACE_setPathSeparator || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setPathSeparator\n");
#endif

  [aString retain];
  [_pathSeparator release];
  _pathSeparator = aString;
}



////////////////////////////////////////////////////////////////////////////////
// Manipulating columns
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Adds a column to the right of the last column.
//

- (void)addColumn
{
  NSBrowserColumn *bc;
  NSScrollView *sc;
  NSRect rect = {{0, 0}, {100, 100}};

#if defined NSBTRACE_addColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)addColumn\n");
#endif

  bc = [[[NSBrowserColumn alloc] init] autorelease];

  // Create a scrollview
  sc = [[[NSScrollView alloc]
	 initWithFrame: rect]
	 autorelease];
  [sc setHasHorizontalScroller: NO];
  [sc setHasVerticalScroller: YES];
  [bc setColumnScrollView: sc];
  [self addSubview: sc];

  [_browserColumns addObject: bc];
  
  [self tile];
}

// -------------------
// Updates the NSBrowser to display all loaded columns.
//

- (void) displayAllColumns
{
#if defined NSBTRACE_displayAllColumns || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)displayAllColumns\n");
#endif
  
  [self tile];
  [self _remapColumnSubviews: YES];
  [self _setColumnTitlesNeedDisplay];  
}

// -------------------
// Updates the NSBrowser to display the column with the given index.
//

- (void) displayColumn: (int)column
{
  id bc, sc;

#if defined NSBTRACE_displayColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)displayColumn: %d\n", column);
#endif

  // If not visible then nothing to display
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    return;

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

#if defined NSBTRACE_columnOfMatrix || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (int)columnOfMatrix\n");
#endif

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
  return NSNotFound;
}

// -------------------
// Returns the index of the last column with a selected item.
//

- (int)selectedColumn
{
  int i;
  id bc, matrix;

//#define NSBTRACE_selectedColumn
#if defined NSBTRACE_selectedColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (int)selectedColumn\n");
#endif

  for (i = _lastColumnLoaded; i >= 0; i--)
    {
      if (!(bc = [_browserColumns objectAtIndex: i]))
      	continue;
      if (![bc isLoaded] || !(matrix = [bc columnMatrix]))
      	continue;
      if ([matrix selectedCell])
      	return i;
    }
  
  return NSNotFound;
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
#if defined NSBTRACE_setLastColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setLastColumn: %d\n", column);
#endif

  _lastColumnLoaded = column;
  [self _unloadFromColumn: column + 1];
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
#if defined NSBTRACE_numberOfVisibleColumns || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (int)numberOfVisibleColumns\n");
#endif

  // Number of visible columns (actual or potential via scroller)
  return (_maxVisibleColumns > _lastColumnLoaded + 1) ?
      	  _maxVisibleColumns : _lastColumnLoaded + 1;
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

#if defined NSBTRACE_validateVisibleColumns || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)validateVisibleColumns\n");
#endif

  // If delegate doesn't care, just return
  if (![_browserDelegate respondsToSelector: 
			   @selector(browser:isColumnValid:)])
    return;

  // Loop through the visible columns
  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
    {
      // Ask delegate if the column is valid and if not
      // then reload the column
      if (![_browserDelegate browser: self isColumnValid: i])
	[self reloadColumn: i];
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
#if defined NSBTRACE_loadColumnZero || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)loadColumnZero\n");
#endif

  // set last column loaded
  [self setLastColumn: 0];

  // load column 0
  [self _performLoadOfColumn: 0];

  _isLoaded = YES;

  [self tile];
  [self _remapColumnSubviews: YES];
  [self _setColumnTitlesNeedDisplay];
}

// -------------------
// Reloads column if it is loaded; sets it as the last column.
//

- (void)reloadColumn: (int)column
{
  id bc;

#if defined NSBTRACE_reloadColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)reloadColumn: %d\n", column);
#endif

  // Make sure the column even exists
  if (column >= (int)[_browserColumns count])
    return;

  if (!(bc = [_browserColumns objectAtIndex: column]))
    return;

  // If the column has not be loaded then do not reload
  if (![bc isLoaded])
    return;

  // Perform the data load
  [self _performLoadOfColumn: column];

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
  int i, delta;

#if defined NSBTRACE_setMaxVisibleColumns || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setMaxVisibleColumns: %d\n", columnCount);
  fprintf(stderr, "  fvc: %d, lvc: %d, mvc: %d, lcl: %d\n",
          _firstVisibleColumn, _lastVisibleColumn,
	  _maxVisibleColumns, _lastColumnLoaded);
#endif

  if ((columnCount < 1) || (_maxVisibleColumns == columnCount))
    return;
  
  // Scroll left as needed
  delta = columnCount - _maxVisibleColumns;
  if ((delta > 0) && (_lastVisibleColumn <= _lastColumnLoaded))
    _firstVisibleColumn = (_firstVisibleColumn - delta > 0) ?
                           _firstVisibleColumn - delta : 0;

  // Adds columns as needed
  for (i = [_browserColumns count]; i < columnCount; i++)
    [self addColumn];

  // Sets other variables
  _lastVisibleColumn = _firstVisibleColumn + columnCount - 1;
  _maxVisibleColumns = columnCount;

  // Redisplay
  [self tile];
  [self updateScroller];
  [self _remapColumnSubviews: YES];
  [self setNeedsDisplay: YES];
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

#if defined NSBTRACE_setMinColumnWidth || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setMinColumnWidth: %d\n", columnWidth);
#endif

  sw = [NSScroller scrollerWidth];
  // Take the border into account
  if (_separatesColumns)
    sw += 2 * [NSCell sizeForBorderType: NSBezelBorder].width;

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
#if defined NSBTRACE_separatesColumns || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)separatesColumns\n");
#endif

  return _separatesColumns;
}

// -------------------
// Sets whether to separate columns with bezeled borders.
//

- (void)setSeparatesColumns: (BOOL)flag
{
#if defined NSBTRACE_setSeparatesColumns || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setSeparatesColumns: %d\n", flag);
#endif

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

- (NSString *)titleOfColumn: (int)column
{
  id bc;

#if defined NSBTRACE_titleOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSString *)titleOfColumn: %d\n", column);
#endif

  if (!(bc = [_browserColumns objectAtIndex: column]))
    return nil;

  return [bc columnTitle];
}

// -------------------
// Sets the title of the column at index column to aString.
//

- (void)setTitle: (NSString *)aString
	ofColumn: (int)column
{
  id bc;

#if defined NSBTRACE_setTitle || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setTitle: %d\n", column);
#endif

  if (!(bc = [_browserColumns objectAtIndex: column]))
    return;

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
#if defined NSBTRACE_isTitled || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)isTitled\n");
#endif

  return _isTitled;
}

// -------------------
// Sets whether columns display titles.
//

- (void)setTitled: (BOOL)flag
{
#if defined NSBTRACE_setTitled || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setTitled: %d\n", flag);
#endif

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
#if defined NSBTRACE_drawTitle || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)drawTitle: %d\n", column);
#endif

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
  NSSize bs = [NSCell sizeForBorderType: NSBezelBorder];

#if defined NSBTRACE_titleHeight || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)titleHeight\n");
#endif

  // Same as horizontal scroller with borders
  return ([NSScroller scrollerWidth] + (2 * bs.height));
}

// -------------------
// Returns the bounds of the title frame for the column at index column.
//

- (NSRect)titleFrameOfColumn: (int)column
{
#if defined NSBTRACE_titleFrameOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)titleFrameOfColumn: %d\n", column);
#endif

  // Not titled then no frame
  if (!_isTitled)
    return NSZeroRect;
  else
    {
      // Number of columns over from the first
      int n = column - _firstVisibleColumn;
      int h = [self titleHeight];
      NSRect r;

      // Calculate origin
      if (_separatesColumns)
        r.origin.x = n * (_columnSize.width + NSBR_COLUMN_SEP);
      else
      	r.origin.x = n * _columnSize.width;
      r.origin.y = frame.size.height - h;
      
      // Calculate size
      if (column == _lastVisibleColumn)
	r.size.width = frame.size.width - r.origin.x;
      else
      	r.size.width = _columnSize.width;
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
//#define NSBTRACE_scrollColumnToVisible
#if defined NSBTRACE_scrollColumnToVisible || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)scrollColumnToVisible: %d\n", column);
#endif

  // If its the last visible column then we are there already
  if (_lastVisibleColumn == column)
    return;

  // If there are not enough columns to scroll with
  // then the column must be visible
  if (_lastColumnLoaded + 1 <= _maxVisibleColumns)
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
//#define NSBTRACE_scrollColumnsLeftBy
#if defined NSBTRACE_scrollColumnsLeftBy || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)scrollColumnsLeftBy: %d\n", shiftAmount);
#endif

  // Cannot shift past the zero column
  if ((_firstVisibleColumn - shiftAmount) < 0)
    shiftAmount = _firstVisibleColumn;

  // No amount to shift then nothing to do
  if (shiftAmount == 0)
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
//#define NSBTRACE_scrollColumnsRightBy
#if defined NSBTRACE_scrollColumnsRightBy || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)scrollColumnsRightBy: %d\n", shiftAmount);
#endif

  // Cannot shift past the last loaded column
  if ((shiftAmount + _lastVisibleColumn) > _lastColumnLoaded)
    shiftAmount = _lastColumnLoaded - _lastVisibleColumn;

  // No amount to shift then nothing to do
  if (shiftAmount == 0)
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
//#define NSBTRACE_updateScroller
#if defined NSBTRACE_updateScroller || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)updateScroller\n");
#endif

  // If there are not enough columns to scroll with
  // then the column must be visible
  if ((_lastColumnLoaded == 0) ||
      (_lastColumnLoaded <= (_maxVisibleColumns - 1)))
    [_horizontalScroller setEnabled: NO];
  else
    {
      if (!_skipUpdateScroller)
      	{
      	  float prop = (float)_maxVisibleColumns / (float)(_lastColumnLoaded + 1);
      	  float i = _lastColumnLoaded - _maxVisibleColumns + 1;
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

//#define NSBTRACE_scrollViaScroller
#if defined NSBTRACE_scrollViaScroller || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)scrollViaScroller\n");
  fprintf(stderr, "[%d,%d] f:%f, _l:%d, _m:%d\n",
          _firstVisibleColumn, _lastVisibleColumn, [sender floatValue],
	  _lastColumnLoaded, _maxVisibleColumns);
#endif

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
	  float f = [sender floatValue];
	  float n = _lastColumnLoaded + 1 - _maxVisibleColumns;

	  _skipUpdateScroller = YES;
	  [self scrollColumnToVisible: rintf(f * n) + _maxVisibleColumns - 1];
	  _skipUpdateScroller = NO;
	}
      	break;
      
      // NSScrollerNoPart ???
      default:
#if defined NSBTRACE_scrollViaScroller || defined NSBTRACE_all
      	fprintf(stderr, "NSBrowser - (void)scrollViaScroller [default:%d]\n",
	        hit);
#endif
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
#if defined NSBTRACE_setHasHorizontalScroller || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setHasHorizontalScroller: %d\n", flag);
#endif

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

- (void)setAcceptsArrowKeys: (BOOL)flag
{
  _acceptsArrowKeys = flag;
}

// -------------------
// Returns NO if pressing an arrow key only scrolls the browser, YES if
// it also sends the action message specified by setAction:.
//

- (BOOL)sendsActionOnArrowKeys
{
  return _sendsActionOnArrowKeys;
}

// -------------------
// Sets whether pressing an arrow key will cause the action message
// to be sent (in addition to causing scrolling).
//

- (void)setSendsActionOnArrowKeys: (BOOL)flag
{
  _sendsActionOnArrowKeys = flag;
}



////////////////////////////////////////////////////////////////////////////////
// Getting column frames
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the rectangle containing the column at index column.
//

- (NSRect)frameOfColumn: (int)column
{
  NSRect r = NSZeroRect;
  NSSize bs = [NSCell sizeForBorderType: NSBezelBorder];
  int n;

//#define NSBTRACE_frameOfColumn
#if defined NSBTRACE_frameOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSRect)frameOfColumn: %d", column);
#endif

  // Number of columns over from the first
  n = column - _firstVisibleColumn;

  // Calculate the frame
  r.size = _columnSize;
  r.origin.x = n * _columnSize.width;

  if (_separatesColumns)
    r.origin.x += n * NSBR_COLUMN_SEP;

  // Adjust for horizontal scroller
  if (_hasHorizontalScroller)
    r.origin.y = [NSScroller scrollerWidth] + (2 * bs.height) + NSBR_VOFFSET;

  // Padding : _columnSize.width is rounded in "tile" method
  if (column == _lastVisibleColumn)
    r.size.width = frame.size.width - r.origin.x;

  if (r.size.width < 0)
    r.size.width = 0;
  if (r.size.height < 0)
    r.size.height = 0;

#if defined NSBTRACE_frameOfColumn || defined NSBTRACE_all
  fprintf(stderr, " -> %s\n", [NSStringFromRect(r) cString]);
#endif

  return r;
}

// -------------------
// Returns the rectangle containing the column at index column,
// not including borders.
//

- (NSRect)frameOfInsideOfColumn: (int)column
{
#if defined NSBTRACE_frameOfInsideOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (NSRect)frameOfInsideOfColumn: %d\n", column);
#endif

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

- (void)tile
{
  NSSize bs = [NSCell sizeForBorderType: NSBezelBorder];
  int i, num = _maxVisibleColumns;
  id bc, sc;

//#define NSBTRACE_tile
#if defined NSBTRACE_tile || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)tile - num: %d, frame: %s\n",
          num, [NSStringFromRect(frame) cString]);
#endif

  if (num <= 0)
    return;

  _columnSize.height = frame.size.height;
  
  // Titles (there is no real frames to resize)
  if (_isTitled)
    _columnSize.height -= [self titleHeight] + NSBR_VOFFSET;

  // Horizontal scroller
  if (_hasHorizontalScroller)
    {
      _scrollerRect.origin.x = bs.width;
      _scrollerRect.origin.y = bs.height;
      _scrollerRect.size.width = frame.size.width - (2 * bs.width);
      _scrollerRect.size.height = [NSScroller scrollerWidth];

      _columnSize.height -= [NSScroller scrollerWidth] + (2 * bs.height)
                            + NSBR_VOFFSET;
    }
  else
    _scrollerRect = NSZeroRect;
  if (!NSEqualRects(_scrollerRect, [_horizontalScroller frame]))
    [_horizontalScroller setFrame: _scrollerRect];
  
  // Columns
  if (_separatesColumns)
    _columnSize.width = (int)((frame.size.width - ((num - 1) * NSBR_COLUMN_SEP))
                              / (float)num);
  else
    _columnSize.width = (int)(frame.size.width / (float)num);

  if (_columnSize.height < 0)
    _columnSize.height = 0;

  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
    {
      if (!(bc = [_browserColumns objectAtIndex: i]))
      	return;
      if (!(sc = [bc columnScrollView]))
      	return;
      [sc setFrame: [self frameOfColumn: i]];
      [self _adjustMatrixOfColumn: i];
    }
}



////////////////////////////////////////////////////////////////////////////////
// Setting the delegate
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the NSBrowser's delegate.
//

- (id)delegate
{
  return _browserDelegate;
}

// -------------------
// Sets the NSBrowser's delegate to anObject.
// Raises NSBrowserIllegalDelegateException if the delegate specified
// by anObject doesn't respond to browser:willDisplayCell:atRow:column:
// and either of the methods browser:numberOfRowsInColumn:
// or browser:createRowsForColumn:inMatrix:.
//

- (void)setDelegate: (id)anObject
{
  BOOL flag = NO;
  BOOL both = NO;

#if defined NSBTRACE_setDelegate || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)setDelegate\n");
#endif

  if (![anObject respondsToSelector: 
		  @selector(browser:willDisplayCell:atRow:column:)])
    [NSException raise: NSBrowserIllegalDelegateException
		 format: @"Delegate does not respond to %s\n",
		 "browser: willDisplayCell: atRow: column: "];

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

  [anObject retain];
  [_browserDelegate release];
  _browserDelegate = anObject;
}



////////////////////////////////////////////////////////////////////////////////
// Target and action
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Returns the NSBrowser's double-click action method.
//

- (SEL)doubleAction
{
  return _doubleAction;
}

// -------------------
// Sets the NSBrowser's double-click action to aSelector.
//

- (void)setDoubleAction: (SEL)aSelector
{
  _doubleAction = aSelector;
}

// -------------------
// Sends the action message to the target. Returns YES upon success,
// NO if no target for the message could be found. 
//

- (BOOL)sendAction
{
  return [self sendAction: [self action] to: [self target]];
}



////////////////////////////////////////////////////////////////////////////////
// Event handling
////////////////////////////////////////////////////////////////////////////////



// -------------------
// Responds to (single) mouse clicks in a column of the NSBrowser.
//

- (void)doClick: (id)sender
{
  int column;
  NSArray *a;
  BOOL shouldSelect = YES;

#if defined NSBTRACE_doClick || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)doClick\n");
#endif

  if ([sender class] != _browserMatrixClass)
    return;
  
  column = [self columnOfMatrix: sender];
  // If the matrix isn't ours then just return
  if (column == NSNotFound)
    return;

  // Ask delegate if selection is ok
  if ([_browserDelegate respondsToSelector: 
				@selector(browser:selectRow:inColumn:)])
    {
      int row = [sender selectedRow];
      shouldSelect = [_browserDelegate browser: self
                                       selectRow: row
				       inColumn: column];
    }
  // Try the other method
  else if ([_browserDelegate respondsToSelector: 
			    @selector(browser:selectCellWithString:inColumn:)])
    {
      id c = [sender selectedCell];
      shouldSelect = [_browserDelegate browser: self
				       selectCellWithString: [c stringValue]
				       inColumn: column];
    }

  // If we should not select the cell
  // then deselect it and return
  if (!shouldSelect)
    {
      [sender deselectSelectedCell];
      return;
    }

  a = [sender selectedCells];

  if (([a count] > 0) && (_browserCellClass == [NSBrowserCell class]))
    {
      // Single selection
      if ([a count] == 1)
      	{
      	  id c = [a objectAtIndex: 0];
	  
	  // If the cell is a leaf
	  // then unload the columns after
	  if ([c isLeaf])
	    [self setLastColumn: column];
	  // The cell is not a leaf so we need to load a column
	  else
	    {
	      int count = [_browserColumns count];
	      // If last column then add a column
	      if (column >= count - 1)
		[self addColumn];

	      // Load column
	      [self _performLoadOfColumn: column + 1];
	      [self _adjustMatrixOfColumn: column + 1];
	      [self setLastColumn: column + 1];

	      // If this column is the last visible
	      // then scroll right by one column
	      if (column == _lastVisibleColumn)
		[self scrollColumnsRightBy: 1];

	    }
	}
      // Multiple selection
      else
	[self setLastColumn: column];
    }

  // Send the action to target
  [self sendAction];

  // Marks titles band as needing display.
  [self _setColumnTitlesNeedDisplay];

#if defined NSBTRACE_doClick || defined NSBTRACE_all
  fprintf(stderr, "---------- (void)doClick ---------\n");
  fprintf(stderr, "  fvc: %d, lvc: %d, mvc: %d, lcl: %d\n",
          _firstVisibleColumn, _lastVisibleColumn,
	  _maxVisibleColumns, _lastColumnLoaded);
  fprintf(stderr, "  %s\n",
          [NSStringFromRect([[[_browserColumns
	                       objectAtIndex:_firstVisibleColumn]
			       columnMatrix] frame]) cString]);
#endif
}

// -------------------
// Responds to double-clicks in a column of the NSBrowser.
//

- (void)doDoubleClick: (id)sender
{
  // We have already handled the single click
  // so send the double action
#if defined NSBTRACE_doDoubleClick || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)doDoubleClick\n");
#endif

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
#if defined NSBTRACE_initialize || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)initialize\n");
#endif

  if (self == [NSBrowser class])
    {
      // Initial version
      [self setVersion: 1];
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

#if defined NSBTRACE_initWithFrame || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (id)initWithFrame: %s\n",
          [NSStringFromRect(rect) cString]);
#endif

  [super initWithFrame: rect];

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
  bs = [NSCell sizeForBorderType: NSBezelBorder];
  _minColumnWidth = [NSScroller scrollerWidth] + (2 * bs.width);
  
  // Horizontal scroller
  _scrollerRect.origin.x = bs.width;
  _scrollerRect.origin.y = bs.height;
  _scrollerRect.size.width = frame.size.width - (2 * bs.width);
  _scrollerRect.size.height = [NSScroller scrollerWidth];
  _horizontalScroller = [[NSScroller alloc] initWithFrame: _scrollerRect];
  [_horizontalScroller setTarget: self];
  [_horizontalScroller setAction: @selector(scrollViaScroller:)];
  [self addSubview: _horizontalScroller];
  _skipUpdateScroller = NO;

  // Columns
  _browserColumns = [[NSMutableArray alloc] init];
  _titleCell = [GSBrowserTitleCell new];

  // Create a single column
  _maxVisibleColumns = 1;
  _lastColumnLoaded = -1;
  _firstVisibleColumn = 0;
  _lastVisibleColumn = 0;
  [self addColumn];

  return self;
}

// -------------------
// Frees components.
//

- (void)dealloc
{
#if defined NSBTRACE_dealloc || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)dealloc\n");
#endif

  [_browserCellPrototype release];
  [_pathSeparator release];
  [_horizontalScroller release];
  [_browserColumns release];
  [_titleCell release];

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
//#define NSBTRACE_drawRect
#if defined NSBTRACE_drawRect || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)drawRect: %s\n", [NSStringFromRect(rect) cString]);
#endif

  NSRectClip(rect);
  [[window backgroundColor] set];
  NSRectFill(rect);

  // Load the first column if not already done
  if (!_isLoaded)
    [self loadColumnZero];

  // Draws titles
  if (_isTitled)
    {
      int i;
      NSString *title;

      for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
	{
	  NSRect r = NSIntersectionRect([self titleFrameOfColumn: i], rect);
	  if (! NSIsEmptyRect(r))
	    {
	      title = [self _getTitleOfColumn: i];
	      [self setTitle: title ofColumn: i];
	      [self drawTitle: title
		    inRect: [self titleFrameOfColumn: i]
		    ofColumn: i];
	    }
	}
    }

  // Draws scroller border
  if (_hasHorizontalScroller)
    {
      NSRect scrollerBorderRect = _scrollerRect;
      NSSize bs = [NSCell sizeForBorderType: NSBezelBorder];

      scrollerBorderRect.origin.x = 0;
      scrollerBorderRect.origin.y = 0;
      scrollerBorderRect.size.width += 2 * bs.width;
      scrollerBorderRect.size.height += 2 * bs.height;

      if (! NSIsEmptyRect(NSIntersectionRect(scrollerBorderRect, rect)) &&
          [self window])
      	{
	  [self lockFocus];
      	  NSDrawGrayBezel(scrollerBorderRect, rect);
	  [self unlockFocus];
	}
    }
}

// -------------------
// Informs the receivers's subviews that the receiver's bounds rectangle size
// has changed from oldFrameSize.
//

- (void) resizeSubviewsWithOldSize: (NSSize)oldSize
{
//#define NSBTRACE_resizeSubviewsWithOldSize
#if defined NSBTRACE_resizeSubviewsWithOldSize || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)resizeSubviewsWithOldSize\n");
#endif

  [super resizeSubviewsWithOldSize: oldSize];
  [self tile];
}


// -------------------
// Override NSControl handler (prevents highlighting).
//

- (void)mouseDown: (NSEvent *)theEvent
{
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
  NSRect		mr;

  if (column >= (int)[_browserColumns count])
    return;

#if defined NSBTRACE__adjustMatrixOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_adjustMatrixOfColumn: %d\n", column);
#endif

  if (!(bc = [_browserColumns objectAtIndex: column]))
    return;
  sc = [bc columnScrollView];
  matrix = [bc columnMatrix];

  // Adjust matrix to fit in scrollview if column has been loaded
  if (sc && matrix && [bc isLoaded])
    {
      cs = [sc contentSize];
      ms = [matrix cellSize];
      ms.width = cs.width;
      [matrix setCellSize: ms];
      mr = [matrix frame];

      // matrix smaller than scrollview's content
      if (mr.size.height < cs.height)
	{
	  // view requires origin adjustment for it to appear at top
	  mr.origin.y = cs.height;
	  [matrix setFrame: mr];
	}

      [sc setDocumentView: matrix];
    }
}

// -------------------
// 
//
#if 0
- (void)_adjustScrollerFrameOfColumn: (int)column force: (BOOL)flag
{
#if defined NSBTRACE__adjustScrollerFrameOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_adjustScrollerFrameOfColumn: %d,%d\n", column, flag);
#endif

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

#if defined NSBTRACE__remapColumnSubviews || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_remapColumnSubviews: %d\n", fromFirst);
#endif

  // Removes all column subviews.
  count = [_browserColumns count];
  for (i = 0; i < count; i++)
    {
      bc = [_browserColumns objectAtIndex: i];
      sc = [bc columnScrollView];
      [sc removeFromSuperviewWithoutNeedingDisplay];
    }
  
  if (_firstVisibleColumn > _lastVisibleColumn)
    return;

  // Sets columns subviews order according to fromFirst (display order...).
  // All added subviews are automaticaly marked as needing display (-> NSView).
  if (fromFirst)
    {
      for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
	{
	  bc = [_browserColumns objectAtIndex: i];
	  sc = [bc columnScrollView];
	  [self addSubview: sc];
	}
    }
  else
    {
      for (i = _lastVisibleColumn; i >= _firstVisibleColumn; i--)
	{
	  bc = [_browserColumns objectAtIndex: i];
	  sc = [bc columnScrollView];
	  [self addSubview: sc];
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

#if defined NSBTRACE__performLoadOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_performLoadOfColumn: %d\n", column);
#endif

  if (!(bc = [_browserColumns objectAtIndex: column]))
    return;

  if (!(sc = [bc columnScrollView]))
    return;

  // Loading is different based upon passive/active delegate
  if (_passiveDelegate)
    {
      // Ask the delegate for the number of rows
      int n = [_browserDelegate browser: self numberOfRowsInColumn: column];

      if (_reusesColumns)
	{
	}
      else
	{
	  int i;

	  // create a new col matrix
	  matrix = [[[_browserMatrixClass alloc]
					initWithFrame: matrixRect
					mode: NSListModeMatrix
					prototype: _browserCellPrototype
					numberOfRows: n
					numberOfColumns: 1]
					autorelease];
	  [matrix setAllowsEmptySelection: _allowsEmptySelection];
	  if (!_allowsMultipleSelection)
	    [matrix setMode: NSRadioModeMatrix];
	  [matrix setTarget: self];
	  [matrix setAction: @selector(doClick:)];
	  [matrix setDoubleAction: @selector(doDoubleClick:)];

	  // set new col matrix and release old
	  [bc setColumnMatrix: matrix];
	  [sc setDocumentView: matrix];

	  // Now loop through the cells and load each one
	  for (i = 0; i < n; i++)
	    [self loadedCellAtRow: i column: column];
	}
    }
  else
    {
      if (_reusesColumns)
	{
	}
      else
	{
	  //NSRect matrixRect = {{0, 0}, {100, 100}};
	  // create a new col matrix
	  matrix = [_browserMatrixClass alloc];
	  [matrix initWithFrame: matrixRect
		  mode: NSRadioModeMatrix
		  prototype: _browserCellPrototype
		  numberOfRows: 0
		  numberOfColumns: 0];
	  [matrix setAllowsEmptySelection: _allowsEmptySelection];
	  if (_allowsMultipleSelection)
	    [matrix setMode: NSListModeMatrix];
	  [matrix setTarget: self];
	  [matrix setAction: @selector(doClick:)];
	  [matrix setDoubleAction: @selector(doDoubleClick:)];

	  // set new col matrix and release old
	  [[bc columnMatrix] release];
	  [bc setColumnMatrix: matrix];
	  [sc setDocumentView: matrix];

	  // Tell the delegate to create the rows
	  [_browserDelegate browser: self
		createRowsForColumn: column
			   inMatrix: matrix];
	}
    }

  [sc setNeedsDisplay: YES];
  [bc setIsLoaded: YES];
}

// -------------------
// Unloads all columns from and including 'column'.
//

- (void)_unloadFromColumn: (int)column
{
  int i, count;
  id bc, sc;

#if defined NSBTRACE__unloadFromColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_unloadFromColumn: %d\n", column);
#endif

  // Unloads columns.
  count = [_browserColumns count];
  for (i = column; i < count; ++i)
    {
      if (!(bc = [_browserColumns objectAtIndex: i]))
      	continue;
      if ([bc isLoaded])
	{
	  if (!(sc = [bc columnScrollView]))
	    continue;
	  // Make the column appear empty by removing the matrix
	  [sc setDocumentView: [bc emptyView]];
      	  [sc setNeedsDisplay: YES];
	  [bc setIsLoaded: NO];
	}
    }
  
  if (column == 0)
    _isLoaded = NO;
  
  // Scrolls if needed.
  if (column <= _lastVisibleColumn)
    [self scrollColumnsLeftBy: _lastVisibleColumn - column + 1];
  [self updateScroller];
}

// -------------------
// Marks all visible columns as needing to be redrawn.
//

- (void)_setColumnSubviewsNeedDisplay
{
  int i;

#if defined NSBTRACE__setColumnSubviewsNeedDisplay || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_setColumnSubviewsNeedDisplay\n");
#endif

  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
    [[[_browserColumns objectAtIndex:i] columnScrollView] setNeedsDisplay:YES];
}

// -------------------
// Marks all titles as needing to be redrawn.
//

- (NSString *)_getTitleOfColumn: (int)column
{
#if defined NSBTRACE__getTitleOfColumn || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_getTitleOfColumn: %d\n", column);
#endif

  // If not visible then nothing to display
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    return @"";

  // Ask the delegate for the column title
  if ([_browserDelegate respondsToSelector: 
			  @selector(browser:titleOfColumn:)])
    return [_browserDelegate browser: self titleOfColumn: column];

  // Check if we take title from previous column
  if (_takesTitleFromPreviousColumn)
    {
      id c;
      
      // If first column then use the path separator
      if (column == 0)
	return _pathSeparator;

      // Get the selected cell
      // Use its string value as the title
      // Only if it is not a leaf
      c = [self selectedCellInColumn: column - 1];
      if ([c isLeaf])
	return @"";
      else
	return [c stringValue];
    }
  return @"";
}

// -------------------
// Marks all titles as needing to be redrawn.
//

- (void)_setColumnTitlesNeedDisplay
{
#if defined NSBTRACE__setColumnTitlesNeedDisplay || defined NSBTRACE_all
  fprintf(stderr, "NSBrowser - (void)_setColumnTitlesNeedDisplay\n");
#endif

  if (_isTitled)
    {
      NSRect r = [self titleFrameOfColumn: _firstVisibleColumn];
      r.size.width = frame.size.width;
      [self setNeedsDisplayInRect: r];
    }
}

@end
