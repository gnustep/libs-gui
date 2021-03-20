/* Implementation of class NSGridView
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 08-08-2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSArray.h>
#import "AppKit/NSGridView.h"
#import "GSFastEnumeration.h"

// Private interfaces...
@interface NSGridCell (Private)
- (void) _setOwningRow: (NSGridRow *)r;
- (void) _setOwningColumn: (NSGridColumn *)c;
@end

@interface NSGridView (Private)
- (NSArray *) _cellsForRowAtIndex: (NSUInteger)rowIndex;
- (NSArray *) _viewsForRowAtIndex: (NSUInteger)rowIndex;
- (NSArray *) _cellsForColumnAtIndex: (NSUInteger)columnIndex;
- (NSArray *) _viewsForColumnAtIndex: (NSUInteger)columnIndex;
@end

@implementation NSGridView (Private)
- (NSArray *) _cellsForRowAtIndex: (NSUInteger)rowIndex
{
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: [_columns count]];
  NSGridRow *row = [_columns objectAtIndex: rowIndex];
  
  FOR_IN(NSGridCell*, c, _cells)
    {
      if ([c row] == row)
        {          
          [result addObject: c];
        }
    }
  END_FOR_IN(_cells);
  
  return result;
}

- (NSArray *) _viewsForRowAtIndex: (NSUInteger)rowIndex
{
  NSArray *cells = [self _cellsForColumnAtIndex: rowIndex];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: [_columns count]];
  
  FOR_IN(NSGridCell*, c, cells)
    {
      NSView *v = [c contentView];
      if (c != nil)
        {
          [result addObject: v];
        }
      else
        {
          [result addObject: [NSGridCell emptyContentView]];
        }
    }
  END_FOR_IN(cells);

  return result;
}

- (NSArray *) _cellsForColumnAtIndex: (NSUInteger)columnIndex
{
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: [_columns count]];
  NSGridColumn *col = [_columns objectAtIndex: columnIndex];

  FOR_IN(NSGridCell*, c, _cells)
    {
      if ([c column] == col)
        {          
          [result addObject: c];
        }
    }
  END_FOR_IN(_cells);
  
  return result;
}

- (NSArray *) _viewsForColumnAtIndex: (NSUInteger)columnIndex
{
  NSArray *cells = [self _cellsForColumnAtIndex: columnIndex];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: [_rows count]];
  
  FOR_IN(NSGridCell*, c, cells)
    {
      NSView *v = [c contentView];
      if (c != nil)
        {
          [result addObject: v];
        }
      else
        {
          [result addObject: [NSGridCell emptyContentView]];
        }
    }
  END_FOR_IN(cells);

  return result;
}
@end


// Private methods...
@implementation NSGridCell (Private)
- (void) _setOwningRow: (NSGridRow *)r
{
  _owningRow = r;
}

- (void) _setOwningColumn: (NSGridColumn *)c
{
  _owningColumn = c;
}
@end

@implementation NSGridView

+ (void) initialize
{
  if (self == [NSGridView class])
    {
      [self setVersion: 1];
    }
}

- (void) _refreshCells
{
  if ([self isHidden])
    {
      return;
    }
  else
    {
      NSUInteger i = 0;
      NSUInteger num_col = [self numberOfColumns];
      // NSUInteger num_rows = [self numberOfRows];
      NSRect f = [self frame];
      CGFloat current_x = 0.0, current_y = f.size.height;
      NSMutableArray *colWidths = [NSMutableArray array];
      NSMutableArray *rowHeights = [NSMutableArray array];
      
      // precalculate w/h
      FOR_IN(NSGridCell*, c, _cells)
        {
          NSView *v = [c contentView];
          NSUInteger ri = 0, ci = 0;
          NSRect rect = NSMakeRect(0,0,100,30); // default size by observation...
          
          // Get row and column index...
          ci = i % num_col;
          ri = i / num_col;
          
          if (v != nil)
            {
              rect = [v frame];
              // NOTE: I am not sure why this is needed, the row and column heights are coming in via the nib
              // as VERY small numbers (1.175...e-38) (see PR for this work, I have attached the XML nib there)
              // so it is necessary to figure out the width of each column so that things can be properly spaced.
              if (ci == 0)
                {
                  if (rect.size.width > 0.0)
                    {
                      [rowHeights addObject: [NSNumber numberWithFloat: rect.size.height]];
                    }
                }
              
              if (ri == 0)
                {
                  if (rect.size.width > 0.0)
                    {
                      [colWidths addObject: [NSNumber numberWithFloat: rect.size.width]];
                    }
                }
            }
          
          // If the first column or row is blank... then take the next value that is non-zero
          if (ri > 0 && [colWidths count] == 0)
            {
              if (rect.size.width > 0.0)
                {
                  [colWidths addObject: [NSNumber numberWithFloat: rect.size.width]];
                }
            }
          
          if (ci > 0 && [rowHeights count] == 0)
            {
              if (rect.size.width > 0.0)
                {
                  [rowHeights addObject: [NSNumber numberWithFloat: rect.size.height]];
                }
            }
        }
      END_FOR_IN(_cells);
      
      // Format the grid...
      FOR_IN(NSGridCell*, c, _cells)
        {
          NSView *v = [c contentView];
          NSUInteger ri = 0, ci = 0;
          
          // Get row and column index...
          ci = i % num_col;
          ri = i / num_col;
          
          // Get the row and col...
          NSGridRow *row = [self rowAtIndex: ri];
          NSGridColumn *col = [self columnAtIndex: ci];
          NSRect rect = NSZeroRect;
          
          if (v != nil)
            {
              rect = [v frame];
            }
          
          // Do the math for the frame...
          // NOTE: I am not sure why this is needed, the row and column heights are coming in via the nib
          // as VERY small numbers (1.175... e-38) (see PR for this work, I have attached the XML nib there)
          // so it is necessary to figure out the width of each column so that things can be properly spaced.
          if (ci == 0)
            {
              current_y -= [[rowHeights objectAtIndex: ci] floatValue]; // rect.size.height;
              current_x = 0.0;
            }
          
          current_y -= [c yPlacement] - [row topPadding];
          current_x += [c xPlacement] + [col leadingPadding] + [col width];
          
          if (v != nil)
            {
              rect.origin.x = current_x;
              rect.origin.y = current_y;
              [v setFrame: rect];
              [self addSubview: v];
            }
          
          current_x += [col trailingPadding] + [col width] + [[colWidths objectAtIndex: ci] floatValue] + _columnSpacing;
          current_y -= [row bottomPadding] - [row height]; // - _rowSpacing; // add paddings after view...
          
          // inc
          i++;
        }
      END_FOR_IN(_cells);
    }
}

- (instancetype) initWithFrame: (NSRect)frameRect
{
  self = [super initWithFrame: frameRect];

  if (self != nil)
    {
      _rows = [[NSMutableArray alloc] init];
      _columns = [[NSMutableArray alloc] init];
      _cells = [[NSMutableArray alloc] init];
    }

  [self _refreshCells];
  
  return self;
}

- (instancetype) initWithViews: (NSArray *)views // an array of arrays
{
  self = [self initWithFrame: NSZeroRect];

  NSUInteger c = 0;
  NSUInteger r = 0;

  if (self != nil)
    {
      NSUInteger rc = [views count], cc = 0;

      if (rc > 0)
        {
          cc = [[views objectAtIndex: 0] count];
        }
      
      _cells = [[NSMutableArray alloc] initWithCapacity: rc * cc];
      _rows = [[NSMutableArray alloc] initWithCapacity: rc];
      _columns = [[NSMutableArray alloc] initWithCapacity: cc];

      FOR_IN(NSArray*, row, views)
        {
          NSArray *columns = [row objectAtIndex: c];
          FOR_IN(NSArray*, column, columns)
            {
              NSView *v = [column objectAtIndex: c];
              NSGridCell *cell = [[NSGridCell alloc] init];

              if (r == 0)
                {
                  NSGridRow *gr = [[NSGridRow alloc] init];
                  [gr setGridView: self];
                  [_rows addObject: gr];
                  [cell _setOwningRow: gr];
                }

              if (c == 0)
                {
                  NSGridColumn *gc = [[NSGridColumn alloc] init];
                  [gc setGridView: self];
                  [_columns addObject: gc];
                  [cell _setOwningColumn: gc];
                }
              
              [cell setContentView: v];
              [_cells addObject: cell];
              c++;
            }
          END_FOR_IN(columns);
          r++;
        }
      END_FOR_IN(views);
      [self _refreshCells];
    }  
  return self;
}

+ (instancetype) gridViewWithNumberOfColumns: (NSInteger)columnCount rows: (NSInteger)rowCount
{
  NSUInteger r = 0;
  NSUInteger c = 0;
  NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity: rowCount];
  
  for (r = 0; r < rowCount; r++)
    {
      NSMutableArray *col = [[NSMutableArray alloc] initWithCapacity: columnCount];
      for (c = 0; c < columnCount; c++)
        {
          NSView *gv = [[NSView alloc] init];
          [col addObject: gv];
          RELEASE(gv);
        }
      [rows addObject: col];
    }

  return [self gridViewWithViews: rows];
}

+ (instancetype) gridViewWithViews: (NSArray *)views
{
  return AUTORELEASE([[self alloc] initWithViews: views]);
}

- (NSInteger) numberOfRows
{
  return [_rows count];
}

- (NSInteger) numberOfColumns
{
  return [_columns count];
}

- (NSGridRow *) rowAtIndex: (NSInteger)index
{
  return [_rows objectAtIndex: index];
}

- (NSInteger) indexOfRow: (NSGridRow *)row
{
  return [_rows indexOfObject: row];
}

- (NSGridColumn *) columnAtIndex: (NSInteger)index
{
  return [_columns objectAtIndex: index];
}

- (NSInteger) indexOfColumn: (NSGridColumn *)column
{
  return [_columns indexOfObject: column];
}

- (NSGridCell *) cellAtColumnIndex: (NSInteger)columnIndex rowIndex: (NSInteger)rowIndex
{
  NSUInteger idx = rowIndex * [self numberOfColumns] + columnIndex;
  return [_cells objectAtIndex: idx];
}

- (NSGridCell *) cellForView: (NSView*)view
{
  NSGridCell *result = nil;

  FOR_IN(NSGridCell*, c, _cells)
    {
      NSView *v = [c contentView];
      if (v == view)
        {
          result = c;
          break;
        }
    }
  END_FOR_IN(_cells);

  return result;
}

- (NSGridRow *) addRowWithViews: (NSArray *)views
{
  return [self insertRowAtIndex: [self numberOfRows]
                      withViews: views];
}

- (NSRect) _findProtypeView
{
  NSRect f = NSMakeRect(0,0,10,10);

  // Find a cell to base the size off of.
  if ([_cells count] > 0)
    {
      FOR_IN(NSGridCell*, acell, _cells)
        {
          NSView *av = [acell contentView];
          if (av)
            {
              f = [av frame];
              break;
            }
        }
      END_FOR_IN(_cells);
    }
  
  return f;
}

- (NSGridRow *) _insertRowAtIndex: (NSInteger)index withCells: (NSArray *)cells
{
  NSGridRow *gr = [[NSGridRow alloc] init];

  // Insert the row and release...
  [_rows insertObject: gr atIndex: index];
  [gr setGridView: self];
  RELEASE(gr);

  NSUInteger i = 0;
  NSUInteger pos = index * [self numberOfColumns];
  FOR_IN(NSGridCell*, c, cells)
    {
      NSGridColumn *col = [_columns objectAtIndex: i];

      [c _setOwningRow: gr];
      [c _setOwningColumn: col];
      [_cells insertObject: c
                   atIndex: pos + i];
      i++;
    }
  END_FOR_IN(cells);

  // Insert remainder of cells for views not present..
  NSUInteger r = [self numberOfColumns] - i;
  NSUInteger idx = 0;
  pos += i;
  for(idx = 0; idx < r; idx++)
    {
      NSGridCell *c = [[NSGridCell alloc] init];
      NSGridColumn *col = [_columns objectAtIndex: i];

      [c _setOwningRow: gr];
      [c _setOwningColumn: col];
      [_cells insertObject: c
                   atIndex: pos + idx];
    }
  
  // Refresh...
  [self _refreshCells];
  
  return gr;
}

- (NSGridRow *) insertRowAtIndex: (NSInteger)index withViews: (NSArray *)views
{
  NSRect f = [self _findProtypeView];
  NSMutableArray *cells = [NSMutableArray arrayWithCapacity: [views count]];
  FOR_IN(NSView*, v, views)
    {
      NSGridCell *c = [[NSGridCell alloc] init];

      [v setFrame: f];
      [c setContentView: v];
      [cells addObject: c];
    }
  END_FOR_IN(views);
  return [self _insertRowAtIndex: index withCells: cells];
}

- (void) moveRowAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex
{
  NSArray *cells = [self _cellsForRowAtIndex: fromIndex];
  [self removeRowAtIndex: fromIndex];
  [self _insertRowAtIndex: toIndex withCells: cells];
}

- (void) removeRowAtIndex: (NSInteger)index
{
  NSArray *objs = [self _cellsForRowAtIndex: index];

  [_rows removeObjectAtIndex: index];
  [_cells removeObjectsInArray: objs];

  [self _refreshCells];
}

- (NSGridColumn *) addColumnWithViews: (NSArray*)views
{
  return [self insertColumnAtIndex: [self numberOfColumns]
                         withViews: views];
}

- (NSGridColumn *) _insertColumnAtIndex: (NSInteger)index withCells: (NSArray *)cells
{
  NSGridColumn *gc = [[NSGridColumn alloc] init];

  // Insert the row and release...
  [_columns insertObject: gc atIndex: index];
  [gc setGridView: self];
  RELEASE(gc);

  NSUInteger i = 0;
  NSUInteger pos = index;
  FOR_IN(NSGridCell*, c, cells)
    {
      NSGridRow *row = [_rows objectAtIndex: i];

      [c _setOwningRow: row];
      [c _setOwningColumn: gc];
      [_cells insertObject: c
                   atIndex: pos + i * [self numberOfColumns]];
      i++;
    }
  END_FOR_IN(cells);

  // Insert remainder of cells for views not present..
  NSUInteger r = [self numberOfColumns] - i;
  NSUInteger idx = 0;
  pos += i;
  for(idx = 0; idx < r; idx++)
    {
      NSGridCell *c = [[NSGridCell alloc] init];
      NSGridRow *row = [_rows objectAtIndex: i];

      [c _setOwningRow: row];
      [c _setOwningColumn: gc];
      [_cells insertObject: c atIndex: pos + idx * [self numberOfColumns]];
    }
  
  // Refresh...
  [self _refreshCells];
  return gc;
}

- (NSGridColumn *) insertColumnAtIndex: (NSInteger)index withViews: (NSArray *)views
{
  NSRect f = [self _findProtypeView];
  NSMutableArray *cells = [NSMutableArray arrayWithCapacity: [views count]];
  FOR_IN(NSView*, v, views)
    {
      NSGridCell *c = [[NSGridCell alloc] init];

      [v setFrame: f];
      [c setContentView: v];
      [cells addObject: c];
    }
  END_FOR_IN(views);
  return [self _insertColumnAtIndex: index withCells: cells];
}

- (void) moveColumnAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex
{
  NSArray *cells = [self _cellsForColumnAtIndex: fromIndex];
  [self removeColumnAtIndex: fromIndex];
  [self _insertColumnAtIndex: toIndex withCells: cells];
}

- (void) removeColumnAtIndex: (NSInteger)index
{
  NSArray *objs = [self _cellsForColumnAtIndex: index];

  [_columns removeObjectAtIndex: index];
  [_cells removeObjectsInArray: objs];

  [self _refreshCells];
}

- (NSGridCellPlacement) xPlacement
{
  return _xPlacement;
}

- (void) setXPlacement: (NSGridCellPlacement)x;
{
  _xPlacement = x;
}

- (NSGridCellPlacement) yPlacement;
{
  return _yPlacement;
}

- (void) setYPlacement: (NSGridCellPlacement)y;
{
  _yPlacement = y;
}

- (NSGridRowAlignment) rowAlignment;
{
  return _rowAlignment;
}

- (void) setRowAlignment: (NSGridRowAlignment)a;
{
  _rowAlignment = a;
}

- (CGFloat) rowSpacing
{
  return _rowSpacing;
}

- (void) setRowSpacing: (CGFloat)f
{
  _rowSpacing = f;
}

- (CGFloat) columnSpacing
{
  return _columnSpacing;
}

- (void) setColumnSpacing: (CGFloat)f
{
  _columnSpacing = f;
}
  
- (void) mergeCellsInHorizontalRange: (NSRange)hRange verticalRange: (NSRange)vRange
{
  NSLog(@"Method %@ unimplemented.", NSStringFromSelector(_cmd));
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      [coder encodeInteger: _rowAlignment
                    forKey: @"NSGrid_alignment"];
      [coder encodeFloat: _columnSpacing
                  forKey: @"NSGrid_columnSpacing"];
      [coder encodeObject: _columns
                   forKey: @"NSGrid_columns"];
      [coder encodeFloat: _rowSpacing
                  forKey: @"NSGrid_rowSpacing"];
      [coder encodeObject: _rows
                   forKey: @"NSGrid_rows"];
      [coder encodeInteger: _xPlacement
                    forKey: @"NSGrid_xPlacement"];
      [coder encodeInteger: _yPlacement forKey: @"NSGrid_yPlacement"];
      [coder encodeObject: _cells
                   forKey: @"NSGrid_cells"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(NSUInteger)
                                at: &_rowAlignment];
      [coder encodeObject: _columns];
      [coder encodeObject: _rows];
      [coder encodeObject: _cells];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_columnSpacing];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_rowSpacing];
      [coder encodeValueOfObjCType: @encode(NSUInteger)
                                at: &_xPlacement];
      [coder encodeValueOfObjCType: @encode(NSUInteger)
                                at: &_yPlacement];
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSGrid_alignment"])
            {
              _rowAlignment = (NSGridRowAlignment)[coder decodeIntegerForKey: @"NSGrid_alignment"];
            }
          if ([coder containsValueForKey: @"NSGrid_columns"])
            {
              ASSIGN(_columns, [coder decodeObjectForKey: @"NSGrid_columns"]);
            }
          if ([coder containsValueForKey: @"NSGrid_rows"])
            {
              ASSIGN(_rows, [coder decodeObjectForKey: @"NSGrid_rows"]);
            }
          if ([coder containsValueForKey: @"NSGrid_cells"])
            {
              ASSIGN(_cells, [coder decodeObjectForKey: @"NSGrid_cells"]);
            }
          if ([coder containsValueForKey: @"NSGrid_columnSpacing"])
            {
              _columnSpacing = [coder decodeFloatForKey: @"NSGrid_columnSpacing"];
            }
          if ([coder containsValueForKey: @"NSGrid_rowSpacing"])
            {
              _rowSpacing = [coder decodeFloatForKey: @"NSGrid_rowSpacing"];
            }
          if ([coder containsValueForKey: @"NSGrid_xPlacement"])
            {
              _xPlacement = [coder decodeIntegerForKey: @"NSGrid_xPlacement"];
            }
          if ([coder containsValueForKey: @"NSGrid_yPlacement"])
            {
              _yPlacement = [coder decodeIntegerForKey: @"NSGrid_yPlacement"];
            }
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(NSUInteger)
                                    at: &_rowAlignment];
          ASSIGN(_columns, [coder decodeObject]);
          ASSIGN(_rows, [coder decodeObject]);
          ASSIGN(_cells, [coder decodeObject]);
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_columnSpacing];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_rowSpacing];
          [coder decodeValueOfObjCType: @encode(NSUInteger)
                                    at: &_xPlacement];
          [coder decodeValueOfObjCType: @encode(NSUInteger)
                                    at: &_yPlacement];
        }
    }
  
  [self _refreshCells];
  
  return self;
}

- (void) dealloc
{
  RELEASE(_columns);
  RELEASE(_rows);
  RELEASE(_cells);
  [super dealloc];
}

@end

/// Cell ///
@implementation NSGridCell

+ (void) initialize
{
  if (self == [NSGridCell class])
    {
      [self setVersion: 1];
    }
}

- (NSView *) contentView
{
  return _contentView;
}

- (void) setContentView: (NSView *)v
{
  ASSIGN(_contentView, v);
}
  
+ (NSView *) emptyContentView
{
  return AUTORELEASE([[NSView alloc] initWithFrame: NSZeroRect]);
}

// Weak references to row/column
- (NSGridRow *) row
{
  return _owningRow;
}

- (NSGridColumn *) column
{
  return _owningColumn;
}

// Placement
- (NSGridCellPlacement) xPlacement
{
  return _xPlacement;
}

- (void) setXPlacement: (NSGridCellPlacement)x
{
  _xPlacement = x;
}

- (NSGridCellPlacement) yPlacement
{
  return _yPlacement;
}

- (void) setYPlacement: (NSGridCellPlacement)y
{
  _yPlacement = y;
}

- (NSGridRowAlignment) rowAlignment
{
  return _rowAlignment;
}

- (void) setRowAlignment: (NSGridRowAlignment)a
{
  _rowAlignment = a;
}

// Constraints
- (NSArray *) customPlacementConstraints
{
  return _customPlacementConstraints;
}

- (void) setCustomPlacementConstraints: (NSArray *)constraints
{
  ASSIGNCOPY(_customPlacementConstraints, constraints);
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _contentView
                   forKey: @"NSGrid_content"];
      [coder encodeObject: _mergeHead
                   forKey: @"NSGrid_mergeHead"];
      [coder encodeObject: _owningRow
                   forKey: @"NSGrid_owningRow"]; // weak
      [coder encodeObject: _owningColumn
                   forKey: @"NSGrid_owningColumn"]; // weak
      [coder encodeInteger: _xPlacement
                    forKey: @"NSGrid_xPlacement"];
      [coder encodeInteger: _yPlacement
                    forKey: @"NSGrid_yPlacement"];
      [coder encodeInteger: _rowAlignment
                    forKey: @"NSGrid_alignment"];
    }
  else
    {
      [coder encodeObject: [self contentView]];
      [coder encodeObject: _mergeHead];
      [coder encodeObject: _owningRow];
      [coder encodeObject: _owningColumn];
      [coder encodeObject: _customPlacementConstraints];
      [coder encodeValueOfObjCType:@encode(NSInteger)
                                at: &_xPlacement];
      [coder encodeValueOfObjCType:@encode(NSInteger)
                                at: &_yPlacement];
      [coder encodeValueOfObjCType:@encode(NSInteger)
                                at: &_rowAlignment];
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSGrid_content"])
            {
              [self setContentView: [coder decodeObjectForKey: @"NSGrid_content"]];
            }
          if ([coder containsValueForKey: @"NSGrid_mergeHead"])
            {
              _mergeHead = [coder decodeObjectForKey: @"NSGrid_mergeHead"];
            }
          if ([coder containsValueForKey: @"NSGrid_owningRow"])
            {
              _owningRow = [coder decodeObjectForKey: @"NSGrid_owningRow"]; // weak
            }
          if ([coder containsValueForKey: @"NSGrid_owningColumn"])
            {
              _owningColumn = [coder decodeObjectForKey: @"NSGrid_owningColumn"]; // weak
            }
          if ([coder containsValueForKey: @"NSGrid_xPlacement"])
            {
              _xPlacement = [coder decodeIntegerForKey: @"NSGrid_xPlacement"];
            }      
          if ([coder containsValueForKey: @"NSGrid_yPlacement"])
            {
              _yPlacement = [coder decodeIntegerForKey: @"NSGrid_yPlacement"];
            }  
          if ([coder containsValueForKey: @"NSGrid_alignment"])
            {
              _rowAlignment = [coder decodeIntegerForKey: @"NSGrid_alignment"];
            }      
        }
      else
        {
          [self setContentView: [coder decodeObject]];
          ASSIGN(_mergeHead, [coder decodeObject]);
          _owningRow = [coder decodeObject]; // weak
          _owningColumn = [coder decodeObject]; // weak
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_xPlacement];
          [coder decodeValueOfObjCType:@encode(NSInteger)
                                    at: &_yPlacement];
          [coder decodeValueOfObjCType:@encode(NSInteger)
                                    at: &_rowAlignment];
        }
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_contentView);
  RELEASE(_mergeHead);
  [super dealloc];
}

@end

/// Column ///
@implementation NSGridColumn

+ (void) initialize
{
  if (self == [NSGridColumn class])
    {
      [self setVersion: 1];
    }
}

- (void) setGridView: (NSGridView *)gv
{
  _gridView = gv;
}

- (NSGridView *) gridView
{
  return _gridView;
}

- (NSInteger) numberOfCells
{
  // The number of cells in a column = # of rows
  return [_gridView numberOfRows];
}

- (NSGridCell *) cellAtIndex: (NSInteger)index
{
  NSUInteger ci = [_gridView indexOfColumn: self];
  // First we get the columnIndex (ci) then we get the member of that column
  // referred to by index.  The method called here gets the correct cell out of
  // the _cells array in the containing NSGridView.
  return [_gridView cellAtColumnIndex: ci
                             rowIndex: index];
}

- (NSGridCellPlacement) xPlacement
{
  return _xPlacement;
}

- (void) setXPlacement: (NSGridCellPlacement)x
{
  _xPlacement = x;
}

- (CGFloat) width
{
  return _width;
}

- (void) setWidth: (CGFloat)f
{
  _width = f;
}

- (CGFloat) leadingPadding
{
  return _leadingPadding;
}

- (void) setLeadingPadding: (CGFloat)f
{
  _leadingPadding = f;
}

- (CGFloat) trailingPadding
{
  return _trailingPadding;
}

- (void) setTrailingPadding: (CGFloat)f
{
  _trailingPadding = f;
}

- (BOOL) isHidden
{
  return _isHidden;
}

- (void) mergeCellsInRange: (NSRange)range
{
  NSUInteger ci = [_gridView indexOfColumn: self];
  NSRange hRange = NSMakeRange(ci, 1);
  [_gridView mergeCellsInHorizontalRange: hRange
                           verticalRange: range];
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeBool: _isHidden
                 forKey: @"NSGrid_hidden"];
      [coder encodeFloat: _leadingPadding
                  forKey: @"NSGrid_leadingPadding"];
      [coder encodeObject: _gridView
                   forKey: @"NSGrid_owningGrid"]; // weak
      [coder encodeFloat: _trailingPadding
                  forKey: @"NSGrid_trailingPadding"];
      [coder encodeFloat: _width
                  forKey: @"NSGrid_width"];
      [coder encodeInteger: _xPlacement
                    forKey: @"NSGrid_xPlacement"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_isHidden];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_leadingPadding];
      [coder encodeObject: _gridView];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_trailingPadding];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_width];
      [coder encodeValueOfObjCType: @encode(NSInteger)
                                at: &_xPlacement];
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSGrid_hidden"])
            {
              _isHidden = [coder decodeBoolForKey: @"NSGrid_hidden"];
            }
          if ([coder containsValueForKey: @"NSGrid_leadingPadding"])
            {
              _leadingPadding = [coder decodeFloatForKey: @"NSGrid_leadingPadding"];
            }
          if ([coder containsValueForKey: @"NSGrid_owningGrid"])
            {
              _gridView = [coder decodeObjectForKey: @"NSGrid_owningGrid"]; // weak
            }
          if ([coder containsValueForKey: @"NSGrid_trailingPadding"])
            {
              _trailingPadding = [coder decodeFloatForKey: @"NSGrid_trailingPadding"];
            }
          if ([coder containsValueForKey: @"NSGrid_width"])
            {
              _width = [coder decodeFloatForKey: @"NSGrid_width"];
            }
          if ([coder containsValueForKey: @"NSGrid_xPlacement"])
            {
              _xPlacement = [coder decodeIntegerForKey: @"NSGrid_xPlacement"];
            }      
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_isHidden];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_leadingPadding];
          _gridView = [coder decodeObject]; 
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_trailingPadding];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_width];
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_xPlacement];
        }
    }
  return self;
}

@end

/// Row ///
@implementation NSGridRow

+ (void) initialize
{
  if (self == [NSGridRow class])
    {
      [self setVersion: 1];
    }
}

- (void) setGridView: (NSGridView *)gridView
{
  _gridView = gridView; // weak reference...
}

- (NSGridView *) gridView
{
  return _gridView;
}

- (NSInteger) numberOfCells
{
  // The number of cells in a row = # of columns
  return [_gridView numberOfColumns];
}

- (NSGridCell *) cellAtIndex: (NSInteger)index
{
  NSUInteger ri = [_gridView indexOfRow: self];
  // First we get the rowIndex (ri) then we get the member of that row
  // referred to by index.  The method called here gets the correct cell out of
  // the _cells array in the containing NSGridView.
  return [_gridView cellAtColumnIndex: index 
                             rowIndex: ri];
}

- (NSGridCellPlacement) yPlacement
{
  return _yPlacement;
}

- (void) setYPlacement: (NSGridCellPlacement)y
{
  _yPlacement = y;
}

- (CGFloat) height
{
  return _height;
}

- (void) setHeight: (CGFloat)f
{
  _height = f;
}

- (CGFloat) topPadding
{
  return _topPadding;
}

- (void) setTopPadding: (CGFloat)f
{
  _topPadding = f;
}

- (CGFloat) bottomPadding
{
  return _bottomPadding;
}

- (void) setBottomPadding: (CGFloat)f
{
  _bottomPadding = f;
}

- (BOOL) isHidden
{
  return _isHidden;
}

- (void) setHidden: (BOOL)flag
{
  _isHidden = flag;
}

- (void) mergeCellsInRange: (NSRange)range
{
  
  NSUInteger ri = [_gridView indexOfRow: self];
  NSRange vRange = NSMakeRange(ri, 1);
  [_gridView mergeCellsInHorizontalRange: range
                           verticalRange: vRange];
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeBool: _isHidden forKey: @"NSGrid_hidden"];
      [coder encodeFloat: _bottomPadding forKey: @"NSGrid_bottomPadding"];
      [coder encodeObject: _gridView forKey: @"NSGrid_owningGrid"];
      [coder encodeFloat: _topPadding forKey: @"NSGrid_topPadding"];
      [coder encodeFloat: _height forKey: @"NSGrid_height"];
      [coder encodeFloat: _yPlacement forKey: @"NSGrid_yPlacement"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_isHidden];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_bottomPadding];
      [coder encodeObject: _gridView];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_topPadding];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_height];
      [coder encodeValueOfObjCType: @encode(NSInteger)
                                at: &_yPlacement];
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSGrid_hidden"])
            {
              _isHidden = [coder decodeBoolForKey: @"NSGrid_hidden"];
            }
          if ([coder containsValueForKey: @"NSGrid_bottomPadding"])
            {
              _bottomPadding = [coder decodeFloatForKey: @"NSGrid_bottomPadding"];
            }
          if ([coder containsValueForKey: @"NSGrid_owningGrid"])
            {
              _gridView = [coder decodeObjectForKey: @"NSGrid_owningGrid"];
            }
          if ([coder containsValueForKey: @"NSGrid_topPadding"])
            {
              _topPadding = [coder decodeFloatForKey: @"NSGrid_topPadding"];
            }
          if ([coder containsValueForKey: @"NSGrid_height"])
            {
              _height = [coder decodeFloatForKey: @"NSGrid_height"];
            }
          if ([coder containsValueForKey: @"NSGrid_yPlacement"])
            {
              _yPlacement = [coder decodeFloatForKey: @"NSGrid_yPlacement"];
            }
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_isHidden];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_bottomPadding];
          _gridView = [coder decodeObject]; 
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_topPadding];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_height];
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_yPlacement];
        }
    }
  return self;
}

@end
