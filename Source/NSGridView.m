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

@interface NSGridRow (Private)
- (void) _setRow: (NSMutableArray *)row;
- (NSMutableArray *) _row;
@end

@interface NSGridColumn (Private)
- (void) _setColumn: (NSMutableArray *)col;
- (NSMutableArray *) _column;
@end

@implementation NSGridView

- (instancetype) initWithFrame: (NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if (self != nil)
    {
      _rows = [[NSMutableArray alloc] initWithCapacity: 10];
    }
  return self;
}

- (instancetype) initWithViews: (NSArray *)rows
{
  self = [self initWithFrame: NSZeroRect];

  if (self != nil)
    {
      FOR_IN(NSMutableArray*, array, rows)
        {
          [_rows addObject: array];
        }
      END_FOR_IN(rows);
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
      NSMutableArray *col = [NSMutableArray arrayWithCapacity: columnCount];
      for (c = 0; c < columnCount; c++)
        {
          NSGridCell *gc = [[NSGridCell alloc] init];
          [col addObject: gc];
          RELEASE(gc);
        }
      [rows addObject: col];
    }
  
  return AUTORELEASE([self gridViewWithViews: rows]);
}

+ (instancetype) gridViewWithViews: (NSArray *)rows
{
  return [[self alloc] initWithViews: rows];
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
  NSGridRow *r = [[NSGridRow alloc] init];
  [r _setRow: [_rows objectAtIndex: index]];
  return r;
}

- (NSInteger) indexOfRow: (NSGridRow *)row
{
  return 0;
}

- (NSGridColumn *) columnAtIndex: (NSInteger)index
{
  return nil;
}

- (NSInteger) indexOfColumn: (NSGridColumn *)column
{
  return 0;
}

- (NSGridCell *) cellAtColumnIndex: (NSInteger)columnIndex rowIndex: (NSInteger)rowIndex
{
  return nil;
}

- (NSGridCell *) cellForView: (NSView*)view
{
  return nil;
}

- (NSGridRow *) addRowWithViews: (NSArray *)views
{
  return nil;
}

- (NSGridRow *) insertRowAtIndex: (NSInteger)index withViews: (NSArray *)views
{
  return nil;
}

- (void) moveRowAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex
{
}

- (void) removeRowAtIndex: (NSInteger)index
{
}

- (NSGridColumn *) addColumnWithViews: (NSArray*)views
{
  return nil;
}

- (NSGridColumn *) insertColumnAtIndex: (NSInteger)index withViews: (NSArray *)views
{
  return nil;
}

- (void) moveColumnAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex
{
}

- (void) removeColumnAtIndex: (NSInteger)index
{
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
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSGrid_alignment"])
        {
          _rowAlignment = [coder decodeIntegerForKey: @"NSGrid_alignment"];
        }
      if ([coder containsValueForKey: @"NSGrid_columnSpacing"])
        {
          _columnSpacing = [coder decodeFloatForKey: @"NSGrid_columnSpacing"];
        }
      if ([coder containsValueForKey: @"NSGrid_columns"])
        {
          ASSIGN(_columns, [coder decodeObjectForKey: @"NSGrid_columns"]);
        }
      if ([coder containsValueForKey: @"NSGrid_rowSpacing"])
        {
          _rowSpacing = [coder decodeFloatForKey: @"NSGrid_rowSpacing"];
        }
      if ([coder containsValueForKey: @"NSGrid_rows"])
        {
          ASSIGN(_rows, [coder decodeObjectForKey: @"NSGrid_rows"]);
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
      [coder decodeValueOfObjCType:@encode(NSUInteger)
                                at:&_rowAlignment];
      [coder decodeValueOfObjCType:@encode(CGFloat)
                                at:&_columnSpacing];
      ASSIGN(_columns, [coder decodeObject]);
      [coder decodeValueOfObjCType:@encode(CGFloat)
                                at:&_rowSpacing];
      ASSIGN(_rows, [coder decodeObject]);
      [coder decodeValueOfObjCType:@encode(NSUInteger)
                                at:&_xPlacement];
      [coder decodeValueOfObjCType:@encode(NSUInteger)
                                at:&_yPlacement];
    }
  
  return self;
}

@end


/// Cell ///
@implementation NSGridCell

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
  return nil;
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _contentView forKey: @"NSGrid_content"];
      [coder encodeObject: _mergeHead forKey: @"NSGrid_mergeHead"];
      [coder encodeObject: _owningRow forKey: @"NSGrid_owningRow"]; // weak
      [coder encodeObject: _owningColumn forKey: @"NSGrid_owningColumn"]; // weak
      [coder encodeInteger: _xPlacement forKey: @"NSGrid_xPlacement"];
      [coder encodeInteger: _yPlacement forKey: @"NSGrid_yPlacement"];
      [coder encodeInteger: _rowAlignment forKey: @"NSGrid_alignment"];
    }
  else
    {
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
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
      _owningRow = [coder decodeObject];
      _owningColumn = [coder decodeObject];
      [coder decodeValueOfObjCType:@encode(NSInteger)
                                at: &_xPlacement];
      [coder decodeValueOfObjCType:@encode(NSInteger)
                                at: &_yPlacement];
      [coder decodeValueOfObjCType:@encode(NSInteger)
                                at: &_rowAlignment];
    }
  return self;
}

@end


/// Column ///
@implementation NSGridColumn

- (NSGridView *) gridView
{
  return _gridView;
}

- (NSInteger) numberOfCells
{
  return 0;
}

- (NSGridCell *) cellAtIndex:(NSInteger)index
{
  return nil;
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
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeBool: _isHidden forKey: @"NSGrid_hidden"];
      [coder encodeFloat: _leadingPadding forKey: @"NSGrid_leadingPadding"];
      [coder encodeObject: _gridView forKey: @"NSGrid_owningGrid"]; // weak
      [coder encodeFloat: _trailingPadding forKey: @"NSGrid_trailingPadding"];
      [coder encodeFloat: _width forKey: @"NSGrid_width"];
      [coder encodeInteger: _xPlacement forKey: @"NSGrid_xPlacement"];
    }
  else
    {
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
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
    }
  return self;
}

@end


/// Row ///
@implementation NSGridRow

- (BOOL) isEqual: (NSGridRow *)r
{
  return NO;
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
  return 0; // [_row count];
}

- (NSGridCell *) cellAtIndex:(NSInteger)index
{
  return nil; // [_row objectAtIndex: index];
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
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
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
    }
  return self;
}

@end
