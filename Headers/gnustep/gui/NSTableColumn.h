#ifndef _GNUstep_H_NSTableColumn
#define _GNUstep_H_NSTableColumn

#include <Foundation/Foundation.h>

#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSTableView.h>

@interface NSTableColumn : NSObject
{
  NSTableHeaderCell *tbcol_cell;
  NSTableView *tbcol_tableview;
  id tbcol_datacell;
  id tbcol_identifier;
  float tbcol_maxWidth;
  float tbcol_minWidth;
  float tbcol_width;
  BOOL tbcol_resizable;
  BOOL tbcol_editable;
}

- (id)initWithIdentifier:(id)anObject;
- (void)setIdentifier:(id)anObject;
- (id)identifier;
- (void)setTableView:(NSTableView *)aTableView;
- (NSTableView *)tableView;

// Sizing.

- (void)setWidth:(float)newWidth;
- (float)width;
- (void)setMinWidth:(float)minWidth;
- (float)minWidth;
- (void)setMaxWidth:(float)maxWidth;
- (float)maxWidth;
- (void)setResizable:(BOOL)flag;
- (BOOL)isResizable;
- (void)sizeToFit;
- (void)setEditable:(BOOL)flag;
- (BOOL)isEditable;
- (void)setHeaderCell:(NSCell *)aCell;
- (id)headerCell;
- (void)setDataCell:(NSCell *)aCell;
- (id)dataCell;
@end

extern NSString *NSTableViewColumnDidResizeNotification;

#endif
