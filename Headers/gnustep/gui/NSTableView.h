#ifndef _GNUstep_H_NSTableView
#define _GNUstep_H_NSTableView

#include <Foundation/Foundation.h>
#include <AppKit/NSControl.h>

@class NSTableColumn;
@class NSTableHeaderView;
@class NSView;

@interface NSTableView : NSControl
{
  id delegate;
  id tb_datasource;
  BOOL tbv_allowsColumnReordering;
  BOOL tbv_allowsColumnResizing;
  BOOL tbv_allowsMultipleSelection;
  BOOL tbv_allowsEmptySelection;
  BOOL tbv_allowsColumnSelection;
  BOOL tbv_autoresizesAllColumnsToFit;
  NSSize tbv_interCellSpacing;
  float tbv_rowHeight;
  NSColor *tbv_backgroundColor;
  NSMutableArray *tbv_columns;
  NSMutableArray *tbv_selectedColumns;
  NSMutableArray *tbv_selectedRows;
  BOOL tbv_drawsGrid;
  NSColor *tbv_gridColor;
  NSTableHeaderView *tbv_headerView;
  NSView *tbv_cornerView;
}
- (id)initWithFrame:(NSRect)frameRect;
- (void)setDataSource:(id)anObject;
- (id)dataSource;
- (void)reloadData;
- (void)setDoubleAction:(SEL)aSelector;
- (SEL)doubleAction;
- (int)clickedColumn;
- (int)clickedRow;
- (void)setAllowsColumnReordering:(BOOL)flag;
- (BOOL)allowsColumnReordering;
- (void)setAllowsColumnResizing:(BOOL)flag;
- (BOOL)allowsColumnResizing;
- (void)setAllowsMultipleSelection:(BOOL)flag;
- (BOOL)allowsMultipleSelection;
- (void)setAllowsEmptySelection:(BOOL)flag;
- (BOOL)allowsEmptySelection;
- (void)setAllowsColumnSelection:(BOOL)flag;
- (BOOL)allowsColumnSelection;
- (void)setIntercellSpacing:(NSSize)aSize;
- (NSSize)intercellSpacing;
- (void)setRowHeight:(float)rowHeight;
- (float)rowHeight;
- (void)setBackgroundColor:(NSColor *)aColor;
- (NSColor *)backgroundColor;
- (void)addTableColumn:(NSTableColumn *)aColumn;
- (void)removeTableColumn:(NSTableColumn *)aTableColumn;
- (void)moveColumn:(int)columnIndex
          toColumn:(int)newIndex;
- (NSArray *)tableColumns;
- (int)columnWithIdentifier:(id)anObject;
- (NSTableColumn *)tableColumnWithIdentifier:(id)anObject;
- (void)selectColumn:(int)columnIndex byExtendingSelection:(BOOL)flag;
- (void)selectRow:(int)rowIndex byExtendingSelection:(BOOL)flag;
- (void)deselectColumn:(int)columnIndex;
- (void)deselectRow:(int)rowIndex;
- (int)numberOfSelectedColumns;
- (int)numberOfSelectedRows;
- (int)selectedColumn;
- (int)selectedRow;
- (BOOL)isColumnSelected:(int)columnIndex;
- (BOOL)isRowSelected:(int)rowIndex;
- (NSEnumerator *)selectedColumnEnumerator;
- (NSEnumerator *)selectedRowEnumerator;
- (void)selectAll:(id)sender;
- (void)deselectAll:(id)sender;
- (int)numberOfColumns;
- (int)numberOfRows;
- (void)setDrawsGrid:(BOOL)flag;
- (BOOL)drawsGrid;
- (void)setGridColor:(NSColor *)aColor ;
- (NSColor *)gridColor;
- (void)editColumn:(int)columnIndex
               row:(int)rowIndex
         withEvent:(NSEvent *)theEvent
            select:(BOOL)flag;
- (int)editedRow;
- (int)editedColumn;
- (void)setHeaderView:(NSTableHeaderView *)aHeaderView;
- (NSTableHeaderView *)headerView;
- (void)setCornerView:(NSView *)aView;
- (NSView *)cornerView;
- (NSRect)rectOfColumn:(int)columnIndex;
- (NSRect)rectOfRow:(int)rowIndex;
- (NSRange)columnsInRect:(NSRect)aRect;
- (NSRange)rowsInRect:(NSRect)aRect;
- (int)columnAtPoint:(NSPoint)aPoint;
- (int)rowAtPoint:(NSPoint)aPoint;
- (NSRect)frameOfCellAtColumn:(int)columnIndex
                          row:(int)rowIndex;
- (void)setAutoresizesAllColumnsToFit:(BOOL)flag;
- (BOOL)autoresizesAllColumnsToFit;
- (void)sizeLastColumnToFit;
- (void)sizeToFit;
- (void)noteNumberOfRowsChanged;
- (void)tile;
- (void)drawRow:(int)rowIndex
       clipRect:(NSRect)clipRect;
- (void)drawGridInClipRect:(NSRect)aRect;
- (void)highlightSelectionInClipRect:(NSRect)clipRect;
- (void)scrollRowToVisible:(int)rowIndex;
- (void)scrollColumnToVisible:(int)columnIndex;
- (BOOL)textShouldBeginEditing:(NSText *)textObject;
- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidChange:(NSNotification *)aNotification;
- (BOOL)textShouldEndEditing:(NSText *)textObject;
- (void)textDidEndEditing:(NSNotification *)aNotification;
@end

@interface NSObject(NSTableViewDelegate)
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn;
@end

@interface NSObject(NSTableViewNotifications)
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (void)tableViewColumnDidMove:(NSNotification *)notification;
- (void)tableViewColumnDidResize:(NSNotification *)notification;
- (void)tableViewSelectionIsChanging:(NSNotification *)notification;
@end
 
@interface NSObject(NSTableDataSource)
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
@end

extern NSString *NSTableViewSelectionDidChangeNotification;
extern NSString *NSTableViewColumnDidMoveNotification;  // @"NSOldColumn", @"NSNewColumn"
extern NSString *NSTableViewColumnDidResizeNotification; // @"NSTableColumn", @"NSOldWidth"
extern NSString *NSTableViewSelectionIsChangingNotification;

#endif
