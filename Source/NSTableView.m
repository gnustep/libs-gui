@implementation NSTableView
- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];

  tbv_headerview = [[NSTableHeaderView alloc] initWithFrame:NSZeroRect];
}

- (void)setDataSource:(id)anObject
{

// This method raises an NSInternalInconistencyException if anObject
// doesn't respond to either
// numberOfRowsInTableView: or tableView:objectValueForTableColumn:row:.

  ASSIGN(tb_datasource, anObject);

  [self tile];
}

- (id)dataSource
{
  return tb_datasource;
}

- (void)reloadData
{
  // anything else?

  [self setNeedsDisplay:YES];
}

- (void)setDoubleAction:(SEL)aSelector
{
}

- (SEL)doubleAction
{
}

- (int)clickedColumn
{
  return -1;
}

- (int)clickedRow
{
  return -1;
}

@end
