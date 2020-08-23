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

#import "AppKit/NSGridView.h"

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
  return nil; //  ASSIGNCOPY(_rows, rows);
}

- (NSInteger) numberOfRows
{
  return [_rows count];
}

- (NSInteger) numberOfColumns
{
  return [[_rows objectAtIndex: 0] count];
}

- (NSGridRow *) rowAtIndex: (NSInteger)index
{
  return nil;
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
  return 0;
}

- (void) setXPlacement: (NSGridCellPlacement)x;
{
}

- (NSGridCellPlacement) yPlacement;
{
  return 0;
}

- (void) setYPlacement: (NSGridCellPlacement)y;
{
}

- (NSGridRowAlignment) rowAlignment;
{
  return 0;
}

- (void) setRowAlignment: (NSGridRowAlignment)a;
{
}

- (CGFloat) rowSpacing
{
  return 0.0;
}

- (void) setRowSpacing: (CGFloat)f
{
}

- (CGFloat) columnSpacing
{
  return 0.0;
}

- (void) setColumnSpacing: (CGFloat)f
{
}
  
- (void) mergeCellsInHorizontalRange: (NSRange)hRange verticalRange: (NSRange)vRange
{
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  return self;
}

@end



/// Cell ///
@implementation NSGridCell

- (NSView *) contentView
{
  return nil;
}

- (void) setContentView: (NSView *)v
{
}
  
+ (NSView *) emptyContentView
{
  return AUTORELEASE([[NSView alloc] initWithFrame: NSZeroRect]);
}

// Weak references to row/column
- (NSGridRow *) row
{
  return nil;
}

- (NSGridColumn *) column
{
  return nil;
}

// Placement
- (NSGridCellPlacement) xPlacement
{
  return 0;
}

- (void) setXPlacement: (NSGridCellPlacement)x
{
}

- (NSGridCellPlacement) yPlacement
{
  return 0;
}

- (void) setYPlacement: (NSGridCellPlacement)y
{
}

- (NSGridRowAlignment) rowAlignment
{
  return 0;
}

- (void) setRowAlignment: (NSGridRowAlignment)a
{
}

// Constraints
- (NSArray *) customPlacementConstraints
{
  return nil;
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  return self;
}

@end


/// Column ///
@implementation NSGridColumn

- (NSGridView *) gridView
{
  return nil;
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
  return 0;
}

- (void) setXPlacement: (NSGridCellPlacement)x
{
}

- (CGFloat) width
{
  return 0.0;
}

- (void) setWidth: (CGFloat)f
{
}

- (CGFloat) leadingPadding
{
  return 0.0;
}

- (void) setLeadingPadding: (CGFloat)f
{
}

- (CGFloat) trailingPadding
{
  return 0.0;
}

- (void) setTrailingPadding: (CGFloat)f
{
}

- (BOOL) isHidden
{
  return NO;
}

- (void) mergeCellsInRange: (NSRange)range
{
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  return self;
}

@end


/// Row ///
@implementation NSGridRow

- (NSGridView *) gridView
{
  return nil;
}

- (NSInteger) numberOfCells
{
  return 0;
}

- (NSGridCell *) cellAtIndex:(NSInteger)index
{
  return nil;
}

- (NSGridCellPlacement) yPlacement
{
  return 0;
}

- (void) setYPlacement: (NSGridCellPlacement)x
{
}

- (CGFloat) height
{
  return 0.0;
}

- (void) setHeight: (CGFloat)f
{
}

- (CGFloat) topPadding
{
  return 0.0;
}

- (void) setTopPadding: (CGFloat)f
{
}

- (CGFloat) bottomPadding
{
  return 0.0;
}

- (void) setBottomPadding: (CGFloat)f
{
}

- (BOOL) isHidden
{
  return NO;
}

- (void) mergeCellsInRange: (NSRange)range
{
}

// coding
- (void) encodeWithCoder: (NSCoder *)coder
{
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  return self;
}

@end
