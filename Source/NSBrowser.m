/*
   NSBrowser.m

   Control to display and select from hierarchal lists

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
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
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/PSOperators.h>

#define COLUMN_SEP 6

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
  [_columnScrollView release];
  [_columnMatrix release];
  [_emptyView release];
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

//
// Private NSBrowser methods
//
@interface NSBrowser (Private)
- (void)_adjustMatrixOfColumn: (int)column;
- (void)_adjustScrollerFrameOfColumn: (int)column force: (BOOL)flag;
- (void)_adjustScrollerFrames: (BOOL)flag;
- (void)_performLoadOfColumn: (int)column;
- (void)_unloadFromColumn: (int)column;
@end

//
// NSBrowser implementation
//
@implementation NSBrowser

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSBrowser class])
    {
      // Initial version
      [self setVersion: 1];
    }
}

//
// Setting Component Classes
//
+ (Class)cellClass
{
  return [NSBrowserCell class];
}

//
// Instance methods
//
- initWithFrame: (NSRect)rect
{
  NSSize bs;
  NSRect scroller_rect;

  [super initWithFrame: rect];

  _browserCellClass = [NSBrowser cellClass];
  _browserCellPrototype = [[_browserCellClass alloc] init];
  _browserMatrixClass = [NSMatrix class];
  _pathSeparator = @"/";
  _isLoaded = NO;
  _allowsBranchSelection = YES;
  _allowsEmptySelection = YES;
  _allowsMultipleSelection = YES;
  _reusesColumns = NO;
  _maxVisibleColumns = 1;
  bs = [NSCell sizeForBorderType: NSBezelBorder];
  _minColumnWidth = [NSScroller scrollerWidth] + (2 * bs.width);
  _separatesColumns = YES;
  _takesTitleFromPreviousColumn = YES;
  _isTitled = YES;
  _hasHorizontalScroller = YES;
  scroller_rect.origin = NSZeroPoint;
  scroller_rect.size.width = frame.size.width;
  scroller_rect.size.height = [NSScroller scrollerWidth];
  _horizontalScroller = [[NSScroller alloc] initWithFrame: scroller_rect];
  [_horizontalScroller setTarget: self];
  [_horizontalScroller setAction: @selector(scrollViaScroller:)];
  [self addSubview: _horizontalScroller];
  _acceptsArrowKeys = YES;
  _sendsActionOnArrowKeys = YES;
  _browserDelegate = nil;
  _passiveDelegate = YES;
  _doubleAction = NULL;
  _browserColumns = [[NSMutableArray alloc] init];
  _titleCell = [NSTextFieldCell new];
  [_titleCell setEditable: NO];
  [_titleCell setTextColor: [NSColor whiteColor]];
  [_titleCell setBackgroundColor: [NSColor darkGrayColor]];
  //[_titleCell setBordered: YES];
  //[_titleCell setBezeled: YES];
  [_titleCell setAlignment: NSCenterTextAlignment];

  // Calculate geometry
  [self tile];

  // Create a single column
  _lastColumnLoaded = -1;
  _firstVisibleColumn = 0;
  _lastVisibleColumn = 0;
  [self addColumn];

  return self;
}

- (void)dealloc
{
  [_browserCellPrototype release];
  [_pathSeparator release];
  [_horizontalScroller release];
  [_browserColumns release];
  [_titleCell release];

  [super dealloc];
}

//
// Setting the Delegate
//
- (id)delegate
{
  return _browserDelegate;
}

- (void)setDelegate: (id)anObject
{
  BOOL flag = NO;
  BOOL both = NO;

  if (![anObject respondsToSelector:
		  @selector(browser: willDisplayCell: atRow: column:)])
    [NSException raise: NSBrowserIllegalDelegateException
		 format: @"Delegate does not respond to %s\n",
		 "browser: willDisplayCell: atRow: column: "];

  if ([anObject respondsToSelector:
		  @selector(browser: numberOfRowsInColumn:)])
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

//
// Target and Action
//
- (SEL)doubleAction
{
  return _doubleAction;
}

- (BOOL)sendAction
{
  return [self sendAction: [self action] to: [self target]];
}

- (void)setDoubleAction: (SEL)aSelector
{
  _doubleAction = aSelector;
}

//
// Setting Component Classes
//
- (id)cellPrototype
{
  return _browserCellPrototype;
}

- (Class)matrixClass
{
  return _browserMatrixClass;
}

- (void)setCellClass: (Class)classId
{
  _browserCellClass = classId;

  // set the prototype for the new class
  [self setCellPrototype: [[[_browserCellClass alloc] init] autorelease]];
}

- (void)setCellPrototype: (NSCell *)aCell
{
  [aCell retain];
  [_browserCellPrototype release];
  _browserCellPrototype = aCell;
}

- (void)setMatrixClass: (Class)classId
{
  _browserMatrixClass = classId;
}

//
// Setting NSBrowser Behavior
//
- (BOOL)reusesColumns
{
  return _reusesColumns;
}

- (void)setReusesColumns: (BOOL)flag
{
  _reusesColumns = flag;
}

- (void)setTakesTitleFromPreviousColumn: (BOOL)flag
{
  _takesTitleFromPreviousColumn = flag;
}

- (BOOL)takesTitleFromPreviousColumn
{
  return _takesTitleFromPreviousColumn;
}

//
// Allowing Different Types of Selection
//
- (BOOL)allowsBranchSelection
{
  return _allowsBranchSelection;
}

- (BOOL)allowsEmptySelection
{
  return _allowsEmptySelection;
}

- (BOOL)allowsMultipleSelection
{
  return _allowsMultipleSelection;
}

- (void)setAllowsBranchSelection: (BOOL)flag
{
  _allowsBranchSelection = flag;
}

- (void)setAllowsEmptySelection: (BOOL)flag
{
  _allowsEmptySelection = flag;
}

- (void)setAllowsMultipleSelection: (BOOL)flag
{
  _allowsMultipleSelection = flag;
}

//
// Setting Arrow Key Behavior
//
- (BOOL)acceptsArrowKeys
{
  return _acceptsArrowKeys;
}

- (BOOL)sendsActionOnArrowKeys
{
  return _sendsActionOnArrowKeys;
}

- (void)setAcceptsArrowKeys: (BOOL)flag
{
  _acceptsArrowKeys = flag;
}

- (void)setSendsActionOnArrowKeys: (BOOL)flag
{
  _sendsActionOnArrowKeys = flag;
}

//
// Showing a Horizontal Scroller
//
- (void)setHasHorizontalScroller: (BOOL)flag
{
  _hasHorizontalScroller = flag;

  if (!flag)
    [_horizontalScroller removeFromSuperview];

  [self tile];
}

- (BOOL)hasHorizontalScroller
{
  return _hasHorizontalScroller;
}

//
// Setting the NSBrowser's Appearance
//
- (int)maxVisibleColumns
{
  return _maxVisibleColumns;
}

- (int)minColumnWidth
{
  return _minColumnWidth;
}

- (BOOL)separatesColumns
{
  return _separatesColumns;
}

- (void)setMaxVisibleColumns: (int)columnCount
{
  int i, count = [_browserColumns count];

  _maxVisibleColumns = columnCount;

  // Create additional columns if necessary
  for (i = count; i < _maxVisibleColumns; ++i)
    [self addColumn];

  _lastVisibleColumn = _maxVisibleColumns - _firstVisibleColumn - 1;

  [self tile];
  [self _adjustScrollerFrames: NO];
}

- (void)setMinColumnWidth: (int)columnWidth
{
  float sw = [NSScroller scrollerWidth];
  NSSize bs = [NSCell sizeForBorderType: NSBezelBorder];
  float bw = 2 * bs.width;

  // Take the border into account
  if (_separatesColumns)
    sw += bw;

  // Column width cannot be less than scroller and border
  if (columnWidth < sw)
    _minColumnWidth = sw;
  else
    _minColumnWidth = columnWidth;

  [self tile];
}

- (void)setSeparatesColumns: (BOOL)flag
{
  _separatesColumns = flag;

  [self tile];
}

//
// Manipulating Columns
//
- (void)addColumn
{
  NSBrowserColumn *bc;
  NSScrollView *sc;
  int n = [_browserColumns count];

  bc = [[[NSBrowserColumn alloc] init] autorelease];

  // Create a scrollview
  sc = [[[NSScrollView alloc]
	 initWithFrame: [self frameOfInsideOfColumn: n]]
	 autorelease];
  [sc setHasHorizontalScroller: NO];
  [sc setHasVerticalScroller: YES];
  [bc setColumnScrollView: sc];
  [self addSubview: sc];

  [_browserColumns addObject: bc];
}

- (int)columnOfMatrix: (NSMatrix *)matrix
{
  NSBrowserColumn *bc;
  int i, count = [_browserColumns count];

  // Loop through columns and compare matrixes
  for (i = 0;i < count; ++i)
    {
      bc = [_browserColumns objectAtIndex: i];
      if (matrix == [bc columnMatrix])
	return i;
    }

  // Not found
  return NSNotFound;
}

- (void) displayAllColumns
{
  int i, count = [_browserColumns count];

  for (i = 0; i < count; ++i)
    {
      //NSBrowserColumn *bc = [_browserColumns objectAtIndex: i];

      // Only display if loaded
      //if ([bc isLoaded])
      [self displayColumn: i];
    }
}

- (void) displayColumn: (int)column
{
  NSBrowserColumn *bc;

  // If not visible then nothing to display
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    return;

  bc = [_browserColumns objectAtIndex: column];

  // Ask the delegate for the column title
  if ([_browserDelegate respondsToSelector:
			  @selector(browser:titleOfColumn:)])
    [self setTitle: [_browserDelegate browser: self
				      titleOfColumn: column]
	  ofColumn: column];
  else
    {
      // Check if we take title from previous column
      if ([self takesTitleFromPreviousColumn])
	{
	  // If first column then use the path separator
	  if (column == 0)
	    [self setTitle: _pathSeparator ofColumn: 0];
	  else
	    {
	      // Get the selected cell
	      // Use its string value as the title
	      // Only if it is not a leaf
	      id c = [self selectedCellInColumn: column - 1];
	      if ([c isLeaf])
		[self setTitle: @"" ofColumn: column];
	      else
		[self setTitle: [c stringValue] ofColumn: column];
	    }
	}
      else
	[self setTitle: @"" ofColumn: column];
    }

  // Draw the title
  [self drawTitle: [bc columnTitle]
	inRect: [self titleFrameOfColumn: column]
	ofColumn: column];
}

- (int)firstVisibleColumn
{
  return _firstVisibleColumn;
}

- (BOOL)isLoaded
{
  return _isLoaded;
}

- (int)lastColumn
{
  return _lastColumnLoaded;
}

- (int)lastVisibleColumn
{
  return _lastVisibleColumn;
}

- (void)loadColumnZero
{
  // load column 0
  [self _performLoadOfColumn: 0];

  // Unload other columns
  [self _unloadFromColumn: 1];

  // set last column loaded
  [self setLastColumn: 0];

  _isLoaded = YES;
  [self tile];
  [self _adjustScrollerFrames: YES];
}

- (int)numberOfVisibleColumns
{
  int i, j, count = [_browserColumns count];
  BOOL done;

  // As I interpret it, the number of visible columns
  // is the total number of scrollviews in the scrolling
  // region regardless of whether they are actually
  // visible or not.

  // We have at least upto the last visible column
  i = _lastVisibleColumn;

  // Plus any loaded columns after that
  done = NO;
  j = i + 1;
  while ((!done) && (j < count))
    {
      NSBrowserColumn *bc = [_browserColumns objectAtIndex: j];
      if ([bc isLoaded])
	{
	  i = j;
	  ++j;
	}
      else
	done = YES;
    }

  // Should be at least the max visible columns
  if (i < _maxVisibleColumns)
    return _maxVisibleColumns;
  else
    return i + 1;
}

- (void)reloadColumn: (int)column
{
  NSBrowserColumn *bc;

  // Make sure the column even exists
  if (column >= (int)[_browserColumns count])
    return;

  bc = [_browserColumns objectAtIndex: column];

  // If the column has not be loaded then do not reload
  if (![bc isLoaded])
    return;

  // Perform the data load
  [self _performLoadOfColumn: column];

  // Unload the columns after
  [self _unloadFromColumn: column + 1];

  // set last column loaded
  [self setLastColumn: column];
}

- (void)selectAll: (id)sender
{
  id matrix = [self matrixInColumn: _lastVisibleColumn];
  [matrix selectAll: sender];
}

- (int)selectedColumn
{
  id o, e = [_browserColumns reverseObjectEnumerator];
  BOOL found = NO;
  id c = nil;
  int i = [_browserColumns count] - 1;

  while ((!found) && (o = [e nextObject]))
    {
      id matrix = [o columnMatrix];

      c = [matrix selectedCell];
      if (c)
	found = YES;
      else
	--i;
    }

  if (found)
    return i;
  else
    return NSNotFound;
}

- (int) selectedRowInColumn: (int)column
{
  return [[self matrixInColumn: column] selectedRow];
}

- (void)setLastColumn: (int)column
{
  _lastColumnLoaded = column;
}

- (void)validateVisibleColumns
{
  int i;

  // xxx Should we trigger an exception?
  if (![_browserDelegate respondsToSelector:
			   @selector(browser:isColumnValid:)])
    return;

  // Loop through the visible columns
  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
    {
      // Ask delegate if the column is valid and if not
      // then reload the column
      BOOL v = [_browserDelegate browser: self isColumnValid: i];
      if (!v)
	[self reloadColumn: i];
    }
}

//
// Manipulating Column Titles
//
- (void)drawTitle: (NSString *)title
	   inRect: (NSRect)aRect
	 ofColumn: (int)column
{
  // Not titled then nothing to draw
  if (![self isTitled])
    return;

  // If column is not visible then nothing to draw
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    return;

  [_titleCell setStringValue: title];
  [_titleCell drawWithFrame: aRect inView: self];
}

- (BOOL)isTitled
{
  return _isTitled;
}

- (void)setTitled: (BOOL)flag
{
  _isTitled = flag;

  [self tile];
}

- (void)setTitle: (NSString *)aString
	ofColumn: (int)column
{
  NSBrowserColumn *bc = [_browserColumns objectAtIndex: column];
  [bc setColumnTitle: aString];

  // If column is not visible then nothing to redisplay
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    return;
  else
    [self setNeedsDisplayInRect: [self titleFrameOfColumn: column]];
}

- (NSRect)titleFrameOfColumn: (int)column
{
  NSRect r;
  int n;

  // Not titled then no frame
  if (![self isTitled])
    return NSZeroRect;

  // Number of columns over from the first
  n = column - _firstVisibleColumn;

  // Calculate the frame
  r.origin.x = n * _columnSize.width;
  r.origin.y = frame.size.height - [self titleHeight] + 2;
  r.size.width = _columnSize.width;
  r.size.height = [self titleHeight] - 4;

  if (_separatesColumns)
    r.origin.x += n * COLUMN_SEP;

  return r;
}

- (float)titleHeight
{
  return 24;
}

- (NSString *)titleOfColumn: (int)column
{
  NSBrowserColumn *bc = [_browserColumns objectAtIndex: column];
  return [bc columnTitle];
}

//
// Scrolling an NSBrowser
//
- (void)scrollColumnsLeftBy: (int)shiftAmount
{
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

  // Update the scrollviews
  [self _adjustScrollerFrames: YES];

  // Update the scroller
  [self updateScroller];

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserDidScroll:)])
    [_browserDelegate browserDidScroll: self];
}

- (void)scrollColumnsRightBy: (int)shiftAmount
{
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

  // Update the scrollviews
  [self _adjustScrollerFrames: YES];

  // Update the scroller
  [self updateScroller];

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserDidScroll:)])
    [_browserDelegate browserDidScroll: self];
}

- (void)scrollColumnToVisible: (int)column
{
  int i;

  // If its the last visible column then we are there already
  if (_lastVisibleColumn == column)
    return;

  // If there are not enough columns to scroll with
  // then the column must be visible
  if ([self numberOfVisibleColumns] <= _maxVisibleColumns)
    return;

  i = _lastVisibleColumn - column;
  if (i > 0)
    [self scrollColumnsLeftBy: i];
  else
    [self scrollColumnsRightBy: (-i)];
}

- (void)scrollViaScroller: (NSScroller *)sender
{
  NSScrollerPart hit = [sender hitPart];

  // Scroll to the left
  if ((hit == NSScrollerDecrementLine) || (hit == NSScrollerDecrementPage))
    {
      [self scrollColumnsLeftBy: 1];
      return;
    }

  // Scroll to the right
  if ((hit == NSScrollerIncrementLine) || (hit == NSScrollerIncrementPage))
    {
      [self scrollColumnsRightBy: 1];
      return;
    }

  // The knob or knob slot
  if ((hit == NSScrollerKnob) || (hit == NSScrollerKnobSlot))
    {
      float f = [sender floatValue];
      int c = [self numberOfVisibleColumns] - 1;
      float i;

      // If the number of loaded columns has shrunk then
      // there will be more columns displayed then loaded
      // so use that value instead
      if (c > _lastColumnLoaded)
	i = c - _maxVisibleColumns + 1;
      else
	i = _lastColumnLoaded - _maxVisibleColumns + 1;

      if (_lastColumnLoaded != 0)
	{
	  f = (f - 1) * i;
	  f += _lastColumnLoaded;
	  [self scrollColumnToVisible: (int)f];
	}
      else
	[self updateScroller];
      return;
    }
}

- (void) updateScroller
{
  // If there are not enough columns to scroll with
  // then the column must be visible
  if ((_lastColumnLoaded == 0) ||
      (_lastColumnLoaded <= (_maxVisibleColumns - 1)))
    [_horizontalScroller setEnabled: NO];
  else
    {
      float prop = (float)_maxVisibleColumns / (float)(_lastColumnLoaded + 1);
      float i = _lastColumnLoaded - _maxVisibleColumns + 1;
      float f = 1 + ((_lastVisibleColumn - _lastColumnLoaded) / i);
      [_horizontalScroller setFloatValue: f knobProportion: prop];
      [_horizontalScroller setEnabled: YES];
    }

  [self setNeedsDisplay: YES];
}

//
// Event Handling
//
- (void)doClick: (id)sender
{
  int column = [self columnOfMatrix: sender];
  NSArray *a;
  BOOL shouldSelect = YES;

  // If the matrix isn't ours then just return
  if (column == NSNotFound)
    return;

  // Ask delegate if selection is ok
  if ([_browserDelegate respondsToSelector:
				@selector(browser:selectRow:inColumn:)])
    {
      int row = [sender selectedRow];
      shouldSelect = [_browserDelegate browser: self selectRow: row
				       inColumn: column];
    }
  else
    {
      // Try the other method
      if ([_browserDelegate respondsToSelector:
			    @selector(browser:selectCellWithString:inColumn:)])
	{
	  id c = [sender selectedCell];
	  shouldSelect = [_browserDelegate browser: self
					   selectCellWithString:
					     [c stringValue]
					   inColumn: column];
	}
    }

  // If we should not select the cell
  // then select it and return
  if (!shouldSelect)
    {
      [sender deselectSelectedCell];
      return;
    }

  a = [sender selectedCells];

  // If only one cell is selected
  if ([a count] == 1)
    {
      id c = [a objectAtIndex: 0];

      // If the cell is a leaf
      // then unload the columns after
      if ([c isLeaf])
	{
	  [self _unloadFromColumn: column + 1];
	  [self setLastColumn: column];
	}
      else
	{
	  // The cell is not a leaf so we need to load a column

	  // If last column then add a column
	  if (column == (int)([_browserColumns count] - 1))
	    [self addColumn];

	  // Load column
	  [self _performLoadOfColumn: column + 1];
	  [self setLastColumn: column + 1];
	  [self _adjustMatrixOfColumn: column + 1];
	  [self _unloadFromColumn: column + 2];

	  // If this column is the last visible
	  // then scroll right by one column
	  if (column == _lastVisibleColumn)
	    [self scrollColumnsRightBy: 1];
	}
    }
  else
    {
      // If multiple selection
      // then we unload the columns after
      [self _unloadFromColumn: column + 1];
      [self setLastColumn: column];
    }

  // Send the action to target
  [self sendAction];
  [self setNeedsDisplay: YES];
}

- (void)doDoubleClick: (id)sender
{
  // We have already handled the single click
  // so send the double action
  [self sendAction: _doubleAction to: [self target]];
}

//
// Getting Matrices and Cells
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
    return nil;

  bc = [_browserColumns objectAtIndex: column];
  matrix = [bc columnMatrix];
  columnCells = [matrix cells];
  count = [columnCells count];

  // row range check
  if (row >= count)
    return nil;

  // Get the cell
  aCell = [matrix cellAtRow: row column: 0];

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

- (NSMatrix *)matrixInColumn: (int)column
{
  NSBrowserColumn *bc = [_browserColumns objectAtIndex: column];
  return [bc columnMatrix];
}

- (id)selectedCell
{
  int i = [self selectedColumn];
  id matrix;

  // Nothing selected
  if (i == NSNotFound)
    return nil;

  matrix = [self matrixInColumn: i];
  return [matrix selectedCell];
}

- (id)selectedCellInColumn: (int)column
{
  id matrix = [self matrixInColumn: column];
  return [matrix selectedCell];
}

- (NSArray *)selectedCells
{
  int i = [self selectedColumn];
  id matrix;

  // Nothing selected
  if (i == NSNotFound)
    return nil;

  matrix = [self matrixInColumn: i];
  return [matrix selectedCells];
}

//
// Getting Column Frames
//
- (NSRect)frameOfColumn: (int)column
{
  NSRect r = NSZeroRect;
  int n;

  // Number of columns over from the first
  n = column - _firstVisibleColumn;

  // Calculate the frame
  r.size = _columnSize;
  r.origin.x = n * _columnSize.width;

  if (_separatesColumns)
    r.origin.x += n * COLUMN_SEP;

  // Adjust for horizontal scroller
  if (_hasHorizontalScroller)
    r.origin.y = [NSScroller scrollerWidth] + 4;

  return r;
}

- (NSRect)frameOfInsideOfColumn: (int)column
{
  // xxx what does this one do?
  return [self frameOfColumn: column];
}

//
// Manipulating Paths
//
- (NSString *)path
{
  return [self pathToColumn: _lastColumnLoaded + 1];
}

- (NSString *)pathSeparator
{
  return _pathSeparator;
}

- (NSString *)pathToColumn: (int)column
{
  int i;
  NSMutableString *s = [NSMutableString stringWithCString: ""];

  // Cannot go past the number of loaded columns
  if (column > _lastColumnLoaded)
    column = _lastColumnLoaded + 1;

  [s appendString: _pathSeparator];
  for (i = 0;i < column; ++i)
    {
      id c = [self selectedCellInColumn: i];
      if (i != 0)
	[s appendString: _pathSeparator];
      [s appendString: [c stringValue]];
    }

  return [[[NSString alloc] initWithString: s] autorelease];
}

- (BOOL)setPath: (NSString *)path
{
  return NO;
}

- (void)setPathSeparator: (NSString *)aString
{
  [aString retain];
  [_pathSeparator release];
  _pathSeparator = aString;
}

//
// Arranging an NSBrowser's Components
//
- (void)tile
{
  NSRect scroller_rect;
  int num;

  // It is assumed the frame/bounds are set appropriately
  // before calling this method

  // Determine number of columns and their widths
  num = _maxVisibleColumns;
  if (_separatesColumns)
    _columnSize.width = (frame.size.width - ((num - 1) * COLUMN_SEP))
      / (float)num;
  else
    _columnSize.width = frame.size.width / (float)num;
  _columnSize.height = frame.size.height;

  // Horizontal scroller
  if (_hasHorizontalScroller)
    {
      scroller_rect.origin = frame.origin;
      scroller_rect.size.width = frame.size.width;
      scroller_rect.size.height = [NSScroller scrollerWidth] + 4;
      _columnSize.height -= scroller_rect.size.height;
    }
  else
    scroller_rect = NSZeroRect;

  // Title
  if (_isTitled)
    _columnSize.height -= [self titleHeight];

  if (_columnSize.height < 0)
    _columnSize.height = 0;

}

- (void)drawRect: (NSRect)rect
{
  int i;

  NSRectClip(rect);
  // Load the first column if not already done
  if (!_isLoaded)
    {
      [self loadColumnZero];
      [self displayAllColumns];
    }

  // Loop through the visible columns
  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
    {
      // If the column title intersects with the rect to be drawn
      // then draw that column
      NSRect r = NSIntersectionRect([self titleFrameOfColumn: i], rect);
      if (! NSIsEmptyRect(r))
	[self displayColumn: i];
    }
}

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

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end

//
// Private NSBrowser methods
//
@implementation NSBrowser (Private)

- (void)_adjustMatrixOfColumn: (int)column
{
NSBrowserColumn *bc;
NSScrollView *sc;
id matrix;
NSSize cs, ms;
NSRect mr;

	if (column >= (int)[_browserColumns count])
		return;

	bc = [_browserColumns objectAtIndex: column];
	sc = [bc columnScrollView];
	matrix = [bc columnMatrix];
  										// Adjust matrix to fit in scrollview
	if (sc && matrix && [bc isLoaded])	// do it only if column has been loaded
		{
		cs = [sc contentSize];
		ms = [matrix cellSize];
		ms.width = cs.width;
		[matrix setCellSize: ms];
		mr = [matrix frame];

		if (mr.size.height < cs.height)					// matrix smaller than
			{											// scrollview's content
			mr.origin.y = cs.height;					// view requires origin
			[matrix setFrame: mr];						// adjustment for it to
			}											// appear at top

		[sc setDocumentView: matrix];
		}
}

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

- (void)_adjustScrollerFrames: (BOOL)force
{
  int i, count = [_browserColumns count];

  // Loop through the columns
  for (i = 0;i < count; ++i)
    {
      // If its a visible column
      if ((i >= _firstVisibleColumn) && (i <= _lastVisibleColumn))
	{
	  NSBrowserColumn *bc = [_browserColumns objectAtIndex: i];
	  id sc = [bc columnScrollView];

	  // Add as subview if necessary
	  if (sc)
	    if (![sc superview])
	      [self addSubview: sc];

	  [self _adjustScrollerFrameOfColumn: i force: force];
	  [self _adjustMatrixOfColumn: i];
	}
      else
	{
	  // If it is not visible
	  NSBrowserColumn *bc = [_browserColumns objectAtIndex: i];
	  id sc = [bc columnScrollView];

	  // Remove it from its superview if it has one
	  if (sc)
	    if ([sc superview])
	      {
		NSLog(@"before: %d\n", [sc retainCount]);
		[sc removeFromSuperview];
		NSLog(@"after: %d\n", [sc retainCount]);
	      }
	}
    }
}

- (void)_performLoadOfColumn: (int)column
{
  NSBrowserColumn *bc = [_browserColumns objectAtIndex: column];

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
	  id matrix;
	  id sc = [bc columnScrollView];
	  id oldm = [bc columnMatrix];
	  NSRect matrixRect = {{0, 0}, {100, 100}};
	  int i;

	  matrix = [[[_browserMatrixClass alloc]		// create a new col matrix
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

	  [bc setColumnMatrix: matrix];		// set new col matrix and release old
	  [sc setDocumentView: matrix];

	  // Now loop through the cells and load each one
	  for (i = 0;i < n; ++i)
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
	  id matrix;
	  id sc = [bc columnScrollView];
	  id oldm = [bc columnMatrix];
	  NSRect matrixRect = {{0, 0}, {100, 100}};

	  matrix = [[[_browserMatrixClass alloc]		// create a new col matrix
					initWithFrame: matrixRect
					mode: NSListModeMatrix
					prototype: _browserCellPrototype
					numberOfRows: 0
					numberOfColumns: 0]
					autorelease];
	  [matrix setAllowsEmptySelection: _allowsEmptySelection];
	  if (!_allowsMultipleSelection)
	    [matrix setMode: NSRadioModeMatrix];
	  [matrix setTarget: self];
	  [matrix setAction: @selector(doClick:)];
	  [matrix setDoubleAction: @selector(doDoubleClick:)];

	  [bc setColumnMatrix: matrix];		// set new col matrix and release old
	  [sc setDocumentView: matrix];

	  // Tell the delegate to create the rows
	  [_browserDelegate browser: self createRowsForColumn: column
			    inMatrix: matrix];
	}
    }

  [bc setIsLoaded: YES];
}

- (void)_unloadFromColumn: (int)column
{
  int i, count = [_browserColumns count];

  for (i = column; i < count; ++i)
    {
      NSBrowserColumn *bc = [_browserColumns objectAtIndex: i];
      if ([bc isLoaded])
	{
	  id sc = [bc columnScrollView];

	  // Make the column appear empty
	  // by removing the matrix
	  [sc setDocumentView: [bc emptyView]];

	  [bc setIsLoaded: NO];
	}
    }
}

- (void) resizeSubviewsWithOldSize: (NSSize)oldSize
{
  [super resizeSubviewsWithOldSize: oldSize];
  [self tile];
  [self _adjustScrollerFrames: YES];
}

@end
