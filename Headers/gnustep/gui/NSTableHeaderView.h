#ifndef _GNUstep_H_NSTableHeaderView
#define _GNUstep_H_NSTableHeaderView  

#include <AppKit/NSView.h>

@class NSTableView;

@interface NSTableHeaderView : NSView
{
  NSTableView *tbhv_tableview;
}
- (void)setTableView:(NSTableView *)aTableView;
- (NSTableView *)tableView;
- (int)draggedColumn;
- (float)draggedDistance;
- (int)resizedColumn;
- (int)columnAtPoint:(NSPoint)aPoint;
- (NSRect)headerRectOfColumn:(int)columnIndex;
@end

#endif
