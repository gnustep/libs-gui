/* 
   NSTableView.h

   The table class.
   
   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2000
   
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

#ifndef _GNUstep_H_NSTableView
#define _GNUstep_H_NSTableView

#include <AppKit/NSControl.h>
#include <AppKit/NSDragging.h>
#include <AppKit/NSUserInterfaceValidation.h>

@class NSArray;
@class NSIndexSet;
@class NSMutableIndexSet;
@class NSTableColumn;
@class NSTableHeaderView;
@class NSText;
@class NSImage;

typedef enum _NSTableViewDropOperation {
  NSTableViewDropOn,
  NSTableViewDropAbove
} NSTableViewDropOperation;

enum {
    NSTableViewGridNone = 0,
    NSTableViewSolidVerticalGridLineMask = 1,
    NSTableViewSolidHorizontalGridLineMask = 2
};

@interface NSTableView : NSControl <NSUserInterfaceValidations>
{
  /*
   * Real Ivars
   */
  id                 _dataSource;
  NSMutableArray    *_tableColumns;
  BOOL               _drawsGrid;
  NSColor           *_gridColor;
  NSColor           *_backgroundColor;
  float              _rowHeight;
  NSSize             _intercellSpacing;
  id                 _delegate;
  NSTableHeaderView *_headerView;
  NSView            *_cornerView;
  SEL                _action;
  SEL                _doubleAction;
  id                 _target;
  int                _clickedRow;
  int                _clickedColumn;
  NSTableColumn     *_highlightedTableColumn;
  NSMutableIndexSet    *_selectedColumns;
  NSMutableIndexSet    *_selectedRows;
  int                _selectedColumn;
  int                _selectedRow;
  BOOL               _allowsMultipleSelection;
  BOOL               _allowsEmptySelection;
  BOOL               _allowsColumnSelection;
  BOOL               _allowsColumnResizing;
  BOOL               _allowsColumnReordering;
  BOOL               _autoresizesAllColumnsToFit;
  BOOL               _selectingColumns;
  NSText            *_textObject;
  int                _editedRow;
  int                _editedColumn;
  NSCell            *_editedCell;
  BOOL               _autosaveTableColumns;
  NSString          *_autosaveName;

  /*
   * Ivars Acting as Cache 
   */
  int    _numberOfRows;
  int    _numberOfColumns;
  /* YES if _delegate responds to
     tableView:willDisplayCell:forTableColumn:row: */
  BOOL   _del_responds;
  /* YES if _dataSource responds to
     tableView:setObjectValue:forTableColumn:row: */
  BOOL   _dataSource_editable;

  /*
   * We cache column origins (precisely, the x coordinate of the left
   * origin of each column).  When a column width is changed through
   * [NSTableColumn setWidth:], then [NSTableView tile] gets called,
   * which updates the cache.  */
  float *_columnOrigins;

  /*
   *  We keep the superview's width in order to know when to
   *  size the last column to fit
   */
  float _superview_width;

  /* if YES [which happens only during a sizeToFit], we are doing
     computations on sizes so we ignore tile (produced for example by
     the NSTableColumns) during the computation.  We perform a global
     tile at the end */
  BOOL   _tilingDisabled;
}

/* Data Source */
- (void) setDataSource: (id)anObject;
- (id) dataSource;

/* Loading data */
- (void) reloadData;

/* Target-action */
- (void) setDoubleAction: (SEL)aSelector;
- (SEL) doubleAction;
- (int) clickedColumn;
- (int) clickedRow;

/* Configuration */ 
- (void) setAllowsColumnReordering: (BOOL)flag;
- (BOOL) allowsColumnReordering;
- (void) setAllowsColumnResizing: (BOOL)flag;
- (BOOL) allowsColumnResizing;
- (void) setAllowsMultipleSelection: (BOOL)flag;
- (BOOL) allowsMultipleSelection; 
- (void) setAllowsEmptySelection: (BOOL)flag;
- (BOOL) allowsEmptySelection;
- (void) setAllowsColumnSelection: (BOOL)flag;
- (BOOL) allowsColumnSelection;

/* Drawing Attributes */
- (void) setIntercellSpacing: (NSSize)aSize;
- (NSSize) intercellSpacing;
- (void) setRowHeight: (float)rowHeight;
- (float) rowHeight;
- (void) setBackgroundColor: (NSColor *)aColor;
- (NSColor *) backgroundColor;
- (void) setUsesAlternatingRowBackgroundColors: (BOOL)useAlternatingRowColors;
- (BOOL) usesAlternatingRowBackgroundColors;

/* Columns */
- (void) addTableColumn: (NSTableColumn *)aColumn;
- (void) removeTableColumn: (NSTableColumn *)aColumn;
- (void) moveColumn: (int)columnIndex toColumn: (int)newIndex;
- (NSArray *) tableColumns;
- (int) columnWithIdentifier: (id)identifier;
- (NSTableColumn *) tableColumnWithIdentifier: (id)anObject;

/* Selecting Columns and Rows */
- (void) selectColumn: (int) columnIndex byExtendingSelection: (BOOL)flag;
- (void) selectRow: (int) rowIndex byExtendingSelection: (BOOL)flag;
- (void) selectColumnIndexes: (NSIndexSet *)indexes byExtendingSelection: (BOOL)extend;
- (void) selectRowIndexes: (NSIndexSet *)indexes byExtendingSelection: (BOOL)extend;
- (NSIndexSet *) selectedColumnIndexes;
- (NSIndexSet *) selectedRowIndexes;
- (void) deselectColumn: (int)columnIndex;
- (void) deselectRow: (int)rowIndex;
- (int) numberOfSelectedColumns;
- (int) numberOfSelectedRows;
- (int) selectedColumn;
- (int) selectedRow;
- (BOOL) isColumnSelected: (int)columnIndex;
- (BOOL) isRowSelected: (int)rowIndex;
- (NSEnumerator *) selectedColumnEnumerator;
- (NSEnumerator *) selectedRowEnumerator;
- (void) selectAll: (id)sender;
- (void) deselectAll: (id)sender;

/* Table Dimensions */
- (int) numberOfColumns;
- (int) numberOfRows;

/* Grid Drawing attributes */
- (void) setDrawsGrid: (BOOL)flag;
- (BOOL) drawsGrid;
- (void) setGridColor: (NSColor *)aColor;
- (NSColor *) gridColor;
- (void) setGridStyleMask: (unsigned int)gridType;
- (unsigned int) gridStyleMask;

/* Editing Cells */
/* ALL TODOS */
- (void) editColumn: (int)columnIndex 
		row: (int)rowIndex 
	  withEvent: (NSEvent *)theEvent 
	     select: (BOOL)flag;
- (int) editedRow;
- (int) editedColumn;

/* Auxiliary Components */
- (void) setHeaderView: (NSTableHeaderView*)aHeaderView;
- (NSTableHeaderView*) headerView;
- (void) setCornerView: (NSView*)aView;
- (NSView*) cornerView;

/* Layout */
- (NSRect) rectOfColumn: (int)columnIndex;
- (NSRect) rectOfRow: (int)rowIndex;
- (NSRange) columnsInRect: (NSRect)aRect;
- (NSRange) rowsInRect: (NSRect)aRect;
- (int) columnAtPoint: (NSPoint)aPoint;
- (int) rowAtPoint: (NSPoint)aPoint;
- (NSRect) frameOfCellAtColumn: (int)columnIndex 
			   row: (int)rowIndex;
- (void) setAutoresizesAllColumnsToFit: (BOOL)flag;
- (BOOL) autoresizesAllColumnsToFit;
- (void) sizeLastColumnToFit;
- (void) noteNumberOfRowsChanged;
- (void) tile;

/* Drawing */
- (void) drawRow: (int)rowIndex clipRect: (NSRect)clipRect;
- (void) drawGridInClipRect: (NSRect)aRect;
- (void) highlightSelectionInClipRect: (NSRect)clipRect;
- (void) drawBackgroundInClipRect: (NSRect)clipRect;

/* Scrolling */
- (void) scrollRowToVisible: (int)rowIndex;
- (void) scrollColumnToVisible: (int)columnIndex;

/* Text delegate methods */
- (BOOL) textShouldBeginEditing: (NSText *)textObject;
- (void) textDidBeginEditing: (NSNotification *)aNotification;
- (void) textDidChange: (NSNotification *)aNotification;
- (BOOL) textShouldEndEditing: (NSText *)textObject;
- (void) textDidEndEditing: (NSNotification *)aNotification;

/* Persistence */
- (NSString *) autosaveName;
- (BOOL) autosaveTableColumns;
- (void) setAutosaveName: (NSString *)name;
- (void) setAutosaveTableColumns: (BOOL)flag;

/* Delegate */
- (void) setDelegate: (id)anObject;
- (id) delegate;

/* indicator image */
/* NB: ALL TODOS */
- (NSImage *) indicatorImageInTableColumn: (NSTableColumn *)aTableColumn;
- (void) setIndicatorImage: (NSImage *)anImage
	     inTableColumn: (NSTableColumn *)aTableColumn;

/* highlighting columns */
/* NB: ALL TODOS */
- (NSTableColumn *) highlightedTableColumn;
- (void) setHighlightedTableColumn: (NSTableColumn *)aTableColumn;

/* dragging rows */
/* NB: ALL TODOS */
- (NSImage*) dragImageForRows: (NSArray*)dragRows
			event: (NSEvent*)dragEvent
	      dragImageOffset: (NSPoint*)dragImageOffset;
- (void) setDropRow: (int)row
      dropOperation: (NSTableViewDropOperation)operation;
- (void) setVerticalMotionCanBeginDrag: (BOOL)flag;
- (BOOL) verticalMotionCanBeginDrag;

/* sorting */
- (void) setSortDescriptors: (NSArray *)array;
- (NSArray *) sortDescriptors;

@end /* interface of NSTableView */

@interface NSTableView (GNUPrivate)
- (void) _sendDoubleActionForColumn: (int)columnIndex;
- (void) _selectColumn: (int)columnIndex  
	     modifiers: (unsigned int)modifiers;
@end

/* 
 * Informal protocol NSTableDataSource 
 */

@interface NSObject (NSTableDataSource)

- (int) numberOfRowsInTableView: (NSTableView *)aTableView;
- (id) tableView: (NSTableView *)aTableView 
objectValueForTableColumn: (NSTableColumn *)aTableColumn 
	     row: (int)rowIndex;
- (void) tableView: (NSTableView *)aTableView 
    setObjectValue: (id)anObject 
    forTableColumn: (NSTableColumn *)aTableColumn
	       row: (int)rowIndex;

/* Dragging */
- (BOOL) tableView: (NSTableView*)tableView
	acceptDrop: (id <NSDraggingInfo>)info
	       row: (int)row
     dropOperation: (NSTableViewDropOperation)operation;
- (NSDragOperation) tableView: (NSTableView*)tableView
		 validateDrop: (id <NSDraggingInfo>)info
		  proposedRow: (int)row
	proposedDropOperation: (NSTableViewDropOperation)operation;
- (BOOL) tableView: (NSTableView *)tableView
	 writeRows: (NSArray*)rows
      toPasteboard: (NSPasteboard*)pboard;
@end

APPKIT_EXPORT NSString *NSTableViewColumnDidMoveNotification;
APPKIT_EXPORT NSString *NSTableViewColumnDidResizeNotification;
APPKIT_EXPORT NSString *NSTableViewSelectionDidChangeNotification;
APPKIT_EXPORT NSString *NSTableViewSelectionIsChangingNotification;

/*
 * Methods Implemented by the Delegate
 */

@interface NSObject (NSTableViewDelegate)

- (BOOL) selectionShouldChangeInTableView: (NSTableView *)aTableView;
- (void) tableView: (NSTableView*)tableView
didClickTableColumn: (NSTableColumn *)tableColumn;
- (void) tableView: (NSTableView*)tableView
didDragTableColumn: (NSTableColumn *)tableColumn;
- (void) tableView: (NSTableView*)tableView
mouseDownInHeaderOfTableColumn: (NSTableColumn *)tableColumn;
- (BOOL)tableView: (NSTableView *)aTableView 
shouldEditTableColumn: (NSTableColumn *)aTableColumn 
	      row: (int)rowIndex;
- (BOOL) tableView: (NSTableView *)aTableView 
   shouldSelectRow: (int)rowIndex;
- (BOOL) tableView: (NSTableView *)aTableView 
shouldSelectTableColumn: (NSTableColumn *)aTableColumn;
- (void) tableView: (NSTableView *)aTableView 
   willDisplayCell: (id)aCell 
    forTableColumn: (NSTableColumn *)aTableColumn
	       row: (int)rowIndex;
- (void) tableViewColumnDidMove: (NSNotification *)aNotification;
- (void) tableViewColumnDidResize: (NSNotification *)aNotification;
- (void) tableViewSelectionDidChange: (NSNotification *)aNotification;
- (void) tableViewSelectionIsChanging: (NSNotification *)aNotification;

@end

#endif /* _GNUstep_H_NSTableView */
