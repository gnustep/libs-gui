@implementation NSTableView
- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];

  tbv_interCellSpacing = NSMakeSize (3,2);
  tbv_rowHeight = 16.0;
  tbv_columns = [NSMutableArray new];
  tbv_gridColor = [NSColor grayColor];

  tbv_headerView = nil;
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

- (void)setAllowsColumnReordering:(BOOL)flag
{
  tbv_allowsColumnReordering = flag;
}

- (BOOL)allowsColumnReordering
{
  return tbv_allowsColumnReordering;
}

- (void)setAllowsColumnResizing:(BOOL)flag
{
  tbv_allowsColumnResizing = flag;
}

- (BOOL)allowsColumnResizing
{
  return tbv_allowsColumnResizing;
}

- (void)setAllowsMultipleSelection:(BOOL)flag
{
  tbv_allowsMultipleSelection = flag;
}

- (BOOL)allowsMultipleSelection
{
  return tbv_allowsMultipleSelection;
}

- (void)setAllowsEmptySelection:(BOOL)flag
{
  tbv_allowsEmptySelection = flag;
}

- (BOOL)allowsEmptySelection
{
  return tbv_allowsEmptySelection;
}

- (void)setAllowsColumnSelection:(BOOL)flag
{
  tbv_allowsColumnSelection = flag;
}

- (BOOL)allowsColumnSelection
{
  return tbv_allowsColumnSelection;
}

- (void)setIntercellSpacing:(NSSize)aSize
{
  tbv_interCellSpacing = aSize;
}

- (NSSize)intercellSpacing
{
  return tbv_interCellSpacing;
}

- (void)setRowHeight:(float)rowHeight
{
  tbv_rowHeight = rowHeight;

  [self tile];
}

- (float)rowHeight
{
  return tbv_rowHeight;
}

- (void)setBackgroundColor:(NSColor *)aColor
{
  ASSIGN(tbv_backgroundColor, aColor);
}

- (NSColor *)backgroundColor
{
  return aColor;
}

- (void)addTableColumn:(NSTableColumn *)aColumn
{
  [tbv_columns addObject:aColumn];
}

- (void)removeTableColumn:(NSTableColumn *)aTableColumn
{
  [tbv_columns removeObject:aTableColumn];
}

- (void)moveColumn:(int)columnIndex
	  toColumn:(int)newIndex
{
  // FIXME, Michael: this is wrong, but what am I supposed to do?

  [tbv_columns replaceObjectAtIndex:newIndex withObject:[tbv_columns
    objectAtIndex:columnIndex]];
}

- (NSArray *)tableColumns
{
  return (NSArray *)tbv_columns;
}

- (int)columnWithIdentifier:(id)anObject
{
  int howMany = [tbv_columns count];

  for (i=0;i<howMany;i++)
    {
      NSTableColumn *tbCol = [tbv_columns objectAtIndex:i];
      if ([[tbCol identifier] isEqual:anObject])
        {
          return i;
        }
    }

  return -1;
}

- (NSTableColumn *)tableColumnWithIdentifier:(id)anObject
{
  int indexOfIdent = [self columnWithIdentifier:anObject];

  if (indexOfIdent != -1)
    {
      return [tbv_columns objectAtIndex:indexOfIdent];
    }

  return nil;
}

- (void)selectColumn:(int)columnIndex byExtendingSelection:(BOOL)flag
{
  if(!flag)
    {
      [tbv_selectedColumns removeAllObjects];
      [tbv_selectedColumns addObject:[NSNumber numberWithInt:columnIndex]];
    }
  else
    {
      if (!tbv_allowsMultipleSelection)
	{
	  [NSException raise: NSInternalInconsistencyException
        format: @"Cannot select multiple items when
	allowsMultipleSelection is NO."];
	  // We exit here.
	}
      [tbv_selectedColumns addObject:[NSNumber numberWithInt:columnIndex]];
      [[NSNotificationCenter defaultCenter]
	postNotificationName: NSTableViewSelectionDidChangeNotification
	object: self];
    }
}

- (void)selectRow:(int)rowIndex byExtendingSelection:(BOOL)flag
{
  if(!flag)
    {
      [tbv_selectedRows removeAllObjects];
      [tbv_selectedRows addObject:[NSNumber numberWithInt:rowIndex]];
    }
  else
    {
      if (!tbv_allowsMultipleSelection)
	{
	  [NSException raise: NSInternalInconsistencyException
        format: @"Cannot select multiple items when
	allowsMultipleSelection is NO."];
	  // We exit here.
	}
      [tbv_selectedRows addObject:[NSNumber numberWithInt:rowIndex]];
      [[NSNotificationCenter defaultCenter]
	postNotificationName: NSTableViewSelectionDidChangeNotification
	object: self];
    }
}

- (void)deselectColumn:(int)columnIndex
{
  [tbv_selectedColumns removeObject:[NSNumber numberWithInt:columnIndex]];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTableViewSelectionDidChangeNotification
    object: self];

/* If the indicated column was the last column selected by the user, the
column nearest it effectively becomes the last selected column. In case of
a tie, priority is given to the column on the left. */

}

- (void)deselectRow:(int)rowIndex
{
  [tbv_selectedRows removeObject:[NSNumber numberWithInt:rowIndex]];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTableViewSelectionDidChangeNotification
    object: self];

/* If the indicated row was the last row selected by the user, the row
nearest it effectively becomes the last selected row. In case of a tie,
priority is given to the row above. */

}

- (int)numberOfSelectedColumns
{
  return [tbv_selectedColumns count];
}

- (int)numberOfSelectedRows
{
  return [tbv_selectedRows count];
}

- (int)selectedColumn
{
  if (![tbv_selectedColumns count])
    {
      return -1;
    }
  return [[tbv_selectedColumns lastObject] intValue];
}

- (int)selectedRow
{
  if (![tbv_selectedRows count])
    {
      return -1;
    }
  return [[tbv_selectedRows lastObject] intValue];
}

- (BOOL)isColumnSelected:(int)columnIndex
{
  return [tbv_selectedColumns containsObject:[NSNumber numberWithInt:columnIndex]];
}

- (BOOL)isRowSelected:(int)rowIndex
{
  return [tbv_selectedRows containsObject:[NSNumber numberWithInt:rowIndex]];
}

- (NSEnumerator *)selectedColumnEnumerator
{
  return [tbv_selectedColumns objectEnumerator];
}

- (NSEnumerator *)selectedRowEnumerator
{
  return [tbv_selecedRows objectEnumerator];
}

- (void)selectAll:(id)sender
{
  if (tbv_allowsMultipleSelection)
  {
//FIXME
  }
}

- (void)deselectAll:(id)sender
{
  if (tbv_allowsMultipleSelection)
  {
//FIXME
  }
}

- (int)numberOfColumns
{
  return [tbv_columns count];
}

- (int)numberOfRows
{
  return [tb_datasource numberOfRowsInTableView:self];
}

- (void)setDrawsGrid:(BOOL)flag
{
  tbv_drawsGrid = flag;
}

- (BOOL)drawsGrid
{
  return tbv_drawsGrid;
}

- (void)setGridColor:(NSColor *)aColor
{
  ASSIGN(tbv_gridColor, aColor);
}

- (NSColor *)gridColor
{
  return tbv_gridColor;
}

- (void)editColumn:(int)columnIndex 
               row:(int)rowIndex 
         withEvent:(NSEvent *)theEvent 
            select:(BOOL)flag
{

/* This method scrolls the receiver so that the cell is visible, sets up
the field editor, and sends
selectWithFrame:inView:editor:delegate:start:length: and
editWithFrame:inView:editor:delegate:event: to the field editor's NSCell
object with the NSTableView as the text delegate. */

}

- (int)editedRow
{
  return -1;
}

- (int)editedColumn
{
  return -1;
}

- (void)setHeaderView:(NSTableHeaderView *)aHeaderView
{
  ASSIGN(tbv_headerView, aHeaderView);
}

- (NSTableHeaderView *)headerView
{
  return tbv_headerView;
}

- (void)setCornerView:(NSView *)aView
{
  ASSIGN(tbv_cornerView, aView);
}

- (NSView *)cornerView
{
  if (!tbv_cornerView)
    {
      return [[[NSView alloc] initWithFrame:NSMakeRect(0,0,20,20)] autorelease];
    }
  return tbv_cornerView;
}

- (NSRect)rectOfColumn:(int)columnIndex
{
  id tabCol = [tbv_columns objectAtIndex:columnIndex];
  float tabColWidth = [tabCol width];
  int tabColRows = [self numberOfRows];
  float tabColOrigin = columnIndex * tabColWidth;

//FIXME!

  return NSMakeRect(tabColOrigin,0,tbv_rowHeight*tabColRows,tabColWidth);
}

- (NSRect)rectOfRow:(int)rowIndex
{
  int tabColRows = [self numberOfRows];

//FIXME! 100 is a place keeper.

  return NSMakeRect(0,(rowIndex - 1) * tabColRows, 100, tbv_rowHeight);
}

- (NSRange)columnsInRect:(NSRect)aRect
{
  int howMany = [self numberOfColumns];
  int location;
  int length;

  if (aRect.size.width > 0 && aRect.size.height > 0)
    {
      for (i=0;i<howMany;i++)
        {
          NSRect tabRect = [self rectOfColumn:i];

	  if (NSIntersectionRect(tabRect, aRect)
            {
	      if (!location)
	        location = i;
	      else
		length = i;
            }
        }

      if (!length)
        length = 0;

      return NSMakeRange(location, length);
    }
  return NSMakeRange(0, 0);
}

- (NSRange)rowsInRect:(NSRect)aRect
{
  int howMany = [self numberOfRows];
  int location;
  int length;

  if (aRect.size.width > 0 && aRect.size.height > 0)
    {
      for (i=0;i<howMany;i++)
        {
          NSRect tabRect = [self rectOfRow:i];

	  if (NSIntersectionRect(tabRect, aRect)
            {
	      if (!location)
	        location = i;
	      else
		length = i;
            }
        }

      if (!length)
        length = 0;

      return NSMakeRange(location, length);
    }
  return NSMakeRange(0, 0);
}

- (int)columnAtPoint:(NSPoint)aPoint
{
  int howMany = [tbv_columns count];

  for (i=0;i<howMany;i++)
    {
      if (NSPointInRect([self rectOfColumn:i])
        return i;
    }

  return NSNotFound;
}

//FIXME
- (int)rowAtPoint:(NSPoint)aPoint
{
  int howMany = [self numberOfRows];

  for (i=0;i<howMany;i++)
    {
      NSRect tabRect = [self rectOfRow:i];

      if (NSPointInRect(aPoint, tabRect))
        return i;
    }

  return NSNotFound;
}

- (NSRect)frameOfCellAtColumn:(int)columnIndex
			  row:(int)rowIndex
{
  NSRect colRect = [self rectOfColumn:columnIndex];
  NSRect rowRect = [self rectOfRow:rowIndex];

  return NSIntersectionRect(colRect, rowRect);
}

- (void)setAutoresizesAllColumnsToFit:(BOOL)flag
{
  tbv_autoresizesAllColumnsToFit = flag;
}

- (BOOL)autoresizesAllColumnsToFit
{
  return tbv_autoresizesAllColumnsToFit;
}

- (void)sizeLastColumnToFit
{
  //FIXME
}

- (void)sizeToFit
{
}

- (void)noteNumberOfRowsChanged
{
  //FIXME, update scrollers.
}

- (void)tile
{
  [self setNeedsDisplay:YES];
}

- (void)drawRow:(int)rowIndex
       clipRect:(NSRect)clipRect
{
  NSRange colsToDraw = [self columnsInRect:clipRect];

  for (i=0;i<colsToDraw.length;i++)
    {
//      tableView:willDisplayCell:forTableColumn:row: 
      // now draw the cell.
    }
}

- (void)drawGridInClipRect:(NSRect)aRect
{
  //FIXME, weird.
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
 //FIXME, explain.
}

- (void)scrollRowToVisible:(int)rowIndex
{
  [[self superview] scrollToPoint:NSZeroPoint];
}

- (void)scrollColumnToVisible:(int)columnIndex
{
  [[self superview] scrollToPoint:NSZeroPoint];
}

// more, but not yet.
@end
