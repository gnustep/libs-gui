@implementation NSTableColumn
- (id)initWithIdentifier:(id)anObject
{
  [super init];

  tbcol_cell = [NSTableHeaderCell new];

  if ([anObject isKindOfClass:[NSString class]])
    [tbcol_cell setStringValue:anObject];
  else
    [tbcol_cell setImage:anObject];

  ASSIGN(tbcol_identifier, anObject);

  return self;
}

- (void)setIdentifier:(id)anObject
{
  ASSIGN(tbcol_identifier, anObject);
}

- (id)identifier
{
  return tbcol_identifier;
}

- (void)setTableView:(NSTableView *)aTableView
{
  ASSIGN(tbcol_tableview, aTableView);
}

- (NSTableView *)tableView
{
  return tbcol_tableview;
}

// Sizing.

- (void)setWidth:(float)newWidth
{
  if (newWidth > tbcol_maxWidth)
    tbcol_width = tbcol_maxWidth;
  else if (newWidth < tbcol_minWidth)
    tbcol_width = tbcol_minWidth;
  else
    tbcol_width = newWidth;

  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTableViewColumnDidResizeNotification
    object:tbcol_tableview];
}

- (float)width
{
  return tbcol_width;
}

- (void)setMinWidth:(float)minWidth
{
  tbcol_minWidth = minWidth;

  if (tbcol_width < minWidth)
    [self setWidth:minWidth];
}

- (float)minWidth
{
  return tbcol_minWidth;
}

- (void)setMaxWidth:(float)maxWidth
{
  tbcol_maxWidth = maxWidth;

  if (tbcol_width > maxWidth)
    [self setWidth:maxWidth];
}

- (float)maxWidth
{
  return tbcol_maxWidth;
}

- (void)setResizable:(BOOL)flag
{
  tbcol_resizable = flag;
}

- (BOOL)isResizable
{
  return tbcol_resizable;
}

- (void)sizeToFit
{
  NSSize cell_size = [tbcol_cell cellSize];
  BOOL changed = NO;

  if (tbcol_width != cell_size.width)
    {
      tbcol_width = cell_size.width;
      changed = YES;
    }

  if (cell_size.width > tbcol_maxWidth)
    tbcol_maxWidth = cell_size.width;

  if (cell_size.width < tbcol_minWidth)
    tbcol_minWidth = cell_size.width;

  if (changed)
    [tbcol_tableview setNeedsDisplay:YES];
}

- (void)setEditable:(BOOL)flag
{
  tbcol_editable = flag;
}

- (BOOL)isEditable
{
  return tbcol_editable;
}

// This cell is the cell used to draw the header.

- (void)setHeaderCell:(NSCell *)aCell
{
  ASSIGN(tbcol_cell, aCell);
}

- (id)headerCell
{
  return tbcol_cell;
}

// This cell is used to draw the items in this column.

- (void)setDataCell:(NSCell *)aCell
{
  ASSIGN(tbcol_datacell, aCell);
}

- (id)dataCell
{
  if (!tbcol_datacell)
    return [[NSTextFieldCell new] autorelease];
  return tbcol_datacell;
}
@end
