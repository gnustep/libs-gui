@implementation NSTableHeaderView
- (void)setTableView:(NSTableView *)aTableView
{
  ASSIGN(tbhv_tableview, aTableView);
}

- (NSTableView *)tableView
{
  return tbhv_tableview;
}

- (int)draggedColumn
{
  // more thought has to go into this, though the default case is -1.

  return -1;
}

- (float)draggedDistance
{
  // return horizontal distance from last location.

  return -1;
}

- (int)resizedColumn
{
  // index of resized column?

  return -1;
}

- (int)columnAtPoint:(NSPoint)aPoint
{
  // black magic here to deduce the column at point, quite easy.

  return -1; // No such column
}

- (NSRect)headerRectOfColumn:(int)columnIndex
{
  // bzzt. weird.
}
@end
