/** <title>NSOutlineView</title>

   <abstract>The outline class.</abstract>
   
   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: October 2001
   
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

#import <AppKit/NSOutlineView.h>
#import <Foundation/NSNotification.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableHeaderView.h>
#import <AppKit/NSText.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSWindow.h>
#import <AppKit/PSOperators.h>
#import <AppKit/NSCachedImageRep.h>
#import <Foundation/NSArray.h>

static NSNotificationCenter *nc = nil;
static const int current_version = 1;

int NSOutlineViewDropOnItemIndex = -1;

static int lastVerticalQuarterPosition;
static int lastHorizontalHalfPosition;

static NSRect oldDraggingRect;
static int oldDropRow;
static int oldProposedDropRow;
static int currentDropRow;
static int oldDropLevel;
static int currentDropLevel;


// Cache the arrow images...
static NSImage *collapsed = nil;
static NSImage *expanded  = nil;
static NSImage *unexpandable  = nil;

// Some necessary things which should not become ivars....
static float widest = 0.0;


@interface NSOutlineView (NotificationRequestMethods)
- (void) _postSelectionIsChangingNotification;
- (void) _postSelectionDidChangeNotification;
- (void) _postColumnDidMoveNotificationWithOldIndex: (int) oldIndex
					   newIndex: (int) newIndex;
- (void) _postColumnDidResizeNotification;
- (BOOL) _shouldSelectTableColumn: (NSTableColumn *)tableColumn;
- (BOOL) _shouldSelectRow: (int)rowIndex;
- (BOOL) _shouldSelectionChange;
- (BOOL) _shouldEditTableColumn: (NSTableColumn *)tableColumn
			    row: (int) rowIndex;
@end

// These methods are defined in NSTableView.
@interface NSOutlineView (TableViewInternalPrivate)
- (void) _setSelectingColumns: (BOOL)flag;
- (BOOL) _editNextEditableCellAfterRow: (int)row
				column: (int)column;
- (BOOL) _editPreviousEditableCellBeforeRow: (int)row
				     column: (int)column;
- (void) _autosaveTableColumns;
- (void) _autoloadTableColumns;
- (void) _openItem: (id)item;
- (void) _closeItem: (id)item;
@end

@implementation NSOutlineView

// Initialize the class when it is loaded
+ (void) initialize
{
  if (self == [NSOutlineView class])
    {
      [self setVersion: current_version];
      nc = [NSNotificationCenter defaultCenter];
      collapsed = [NSImage imageNamed: @"common_outlineCollapsed.tiff"];
      expanded  = [NSImage imageNamed: @"common_outlineExpanded.tiff"];
      unexpandable = [NSImage imageNamed: @"common_outlineUnexpandable.tiff"];
    }
}

// Instance methods
- (id)initWithFrame: (NSRect)frame
{
  [super initWithFrame: frame];

  _indentationMarkerFollowsCell = NO;
  _autoResizesOutlineColumn = NO;
  _autosaveExpandedItems = NO;
  _indentationPerLevel = 0.0;
  _outlineTableColumn = nil;
  _shouldCollapse = NO;
  _items = [NSMutableArray array];
  _expandedItems = [NSMutableArray array];

  // Retain items
  RETAIN(_items);
  RETAIN(_expandedItems);

  return self;
}

- (BOOL)autoResizesOutlineColumn
{
  return _autoResizesOutlineColumn;
}

- (BOOL)autosaveExpandedItems
{
  return _autosaveExpandedItems;
}

// Collect all of the items under a given element.
static void _collectItems(NSOutlineView *outline,
		     id startitem,
		     NSMutableArray *allChildren)
{
  int num = [[outline dataSource] outlineView: outline
				  numberOfChildrenOfItem: startitem];
  int i = 0;

  for(i = 0; i < num; i++)
    {
      id anitem = [[outline dataSource] outlineView: outline
					child: i
					ofItem: startitem];

      // Only collect the children if the item is expanded
      if([outline isItemExpanded: startitem])
	{
	  [allChildren addObject: anitem];
	}

      _collectItems(outline, anitem, allChildren); 
    }
}

- (void)_closeItem: (id)item
{
  int numchildren = 0;
  int i = 0;
  NSMutableArray *removeAll = [NSMutableArray array];

  _collectItems(self, item, removeAll);
  numchildren = [removeAll count];

  // close the item...
  if(item != nil)
    {
      [_expandedItems removeObject: item];
    }

  // For the close method it doesn't matter what order they are 
  // removed in.
  
  for(i=0; i < numchildren; i++)
    {
      id child = [removeAll objectAtIndex: i];
      [_items removeObject: child];
    }
}

- (void)_openItem: (id)item
{
  int numchildren = [_dataSource outlineView: self 
				 numberOfChildrenOfItem: item];
  int i = 0;
  int insertionPoint = 0;

  // open the item...
  if(item != nil)
    {
      [_expandedItems addObject: item];
    }

  insertionPoint = [_items indexOfObject: item];
  if(insertionPoint == NSNotFound)
    {
      insertionPoint = 0;
    }
  else
    {
      insertionPoint++;
    }

  [self setNeedsDisplay: YES];  
  for(i=numchildren-1; i >= 0; i--)
    {
      id child = [_dataSource outlineView: self
			      child: i
			      ofItem: item];

      // Add all of the children...
      if([self isItemExpanded: child])
	{
	  NSMutableArray *insertAll = [NSMutableArray array];
	  int i = 0, numitems = 0;

	  _collectItems(self, child, insertAll);
	  numitems = [insertAll count];
	  for(i = numitems-1; i >= 0; i--)
	    {
	      [_items insertObject: [insertAll objectAtIndex: i]
		      atIndex: insertionPoint];
	    }
	}
      
      // Add the parent
      [_items insertObject: child atIndex: insertionPoint];
    }
}

- (void)collapseItem: (id)item
{
  [self collapseItem: item collapseChildren: NO];
}

- (void)collapseItem: (id)item collapseChildren: (BOOL)collapseChildren
{
  const SEL shouldSelector = @selector(outlineView:shouldCollapseItem:);
  BOOL canCollapse = YES;

  if([_delegate respondsToSelector: shouldSelector])
    {
      canCollapse = [_delegate outlineView: self shouldCollapseItem: item];
    }

  if([self isExpandable: item] && [self isItemExpanded: item] && canCollapse)
    {
      NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];      
      [infoDict setObject: item forKey: @"NSObject"];
      
      // Send out the notification to let observers know that this is about
      // to occur.
      [nc postNotificationName: NSOutlineViewItemWillCollapseNotification
	  object: self
	  userInfo: infoDict];
      
      // collapse...
      [self _closeItem: item];

      // Send out the notification to let observers know that this has
      // occured.
      [nc postNotificationName: NSOutlineViewItemDidCollapseNotification
	  object: self
	  userInfo: infoDict];
      

      if(collapseChildren) // collapse all
	{
	  int numchild = [_dataSource outlineView: self
				      numberOfChildrenOfItem: item];
	  int index = 0;
	  for(index = 0;index < numchild;index++)
	    {
	      id child = [_dataSource outlineView: self
				      child: index
				      ofItem: item];
	      NSMutableDictionary *infoDict = [NSDictionary dictionary];      
	      [infoDict setObject: child forKey: @"NSObject"];

	      // Send out the notification to let observers know 
	      // that this is about to occur.
	      [nc postNotificationName: NSOutlineViewItemWillCollapseNotification
		  object: self
		  userInfo: infoDict];

	      if([self isItemExpanded: child])
		{
		  [self _closeItem: child];
		}

	      // Send out the notification to let observers know that
	      // this is about to occur.
	      [nc postNotificationName: NSOutlineViewItemDidCollapseNotification
		  object: self
		  userInfo: infoDict];
	    }
	}
    }
  [self reloadData];
}

- (void)expandItem: (id)item
{
  [self expandItem: item expandChildren: NO];
}

- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren
{
  const SEL shouldExpandSelector = @selector(outlineView:shouldExpandItem:);
  BOOL canExpand = YES;

  if([_delegate respondsToSelector: shouldExpandSelector])
    {
      canExpand = [_delegate outlineView: self shouldExpandItem: item];
    }

  if([self isExpandable: item] && ![self isItemExpanded: item] && canExpand)
    {
      NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
      
      [infoDict setObject: item forKey: @"NSObject"];
      
      // Send out the notification to let observers know that this is about
      // to occur.
      [nc postNotificationName: NSOutlineViewItemWillExpandNotification
	  object: self
	  userInfo: infoDict];

      // insert the root element, if necessary otherwise insert the
      // actual object.
      [self _openItem: item];

      // Send out the notification to let observers know that this has
      // occured.
      [nc postNotificationName: NSOutlineViewItemDidExpandNotification
	  object: self
	  userInfo: infoDict];

      if(expandChildren) // expand all
	{
	  int numchild = [_dataSource outlineView: self
				      numberOfChildrenOfItem: item];
	  int index = 0;
	  for(index = 0;index < numchild;index++)
	    {
	      id child = [_dataSource outlineView: self
				      child: index
				      ofItem: item];
	      // Send out the notification to let observers know that this has
	      // occured.
	      [nc postNotificationName: NSOutlineViewItemWillExpandNotification
		  object: self
		  userInfo: infoDict];
	      
	      if(![self isItemExpanded: child])
		{
		  [self _openItem: child];
		}
	      
	      // Send out the notification to let observers know that this has
	      // occured.
	      [nc postNotificationName: NSOutlineViewItemDidExpandNotification
		  object: self
		  userInfo: infoDict];

	    }
	}      
    }
  [self reloadData];
}

- (BOOL)indentationMarkerFollowsCell
{
  return _indentationMarkerFollowsCell;
}

- (float)indentationPerLevel
{
  return _indentationPerLevel;
}

- (BOOL)isExpandable: (id)item
{
  return [_dataSource outlineView: self isItemExpandable: item];
}

- (BOOL)isItemExpanded: (id)item
{
  id object = item;

  // if the object to be expanded is nil, then the root
  // object is being queried.   We need to check for a
  // placeholder.
  if(object == nil)
    {
      object = @"root";
    }

  // Check the array to determine if it is expanded.
  return([_expandedItems containsObject: object]);
}

- (id)itemAtRow: (int)row
{
  return [_items objectAtIndex: row];
}

// Utility function to determine the level of an item.
static int _levelForItem(NSOutlineView *outline,
			id startitem,
			id searchitem,
			int level,
			BOOL *found)
{
  int num = [[outline dataSource] outlineView: outline
				  numberOfChildrenOfItem: startitem];
  int i = 0;
  int finallevel = 0;

  if(*found == YES)
    {
      return level;
    }
  
  if(searchitem == startitem)
    {
      *found = YES;
      return level;
    }

  for(i = 0; i < num; i++)
    {
      id anitem = [[outline dataSource] outlineView: outline
					child: i
					ofItem: startitem];
      finallevel = _levelForItem(outline, anitem, searchitem, level + 1, found); 
      if(*found) break;
    }

  return finallevel;
}

- (int)levelForItem: (id)item
{
  if(item != nil)
    {
      BOOL found = NO;
      return _levelForItem(self, nil, item, -1, &found);
    }

  return -1;
}

- (int)levelForRow: (int)row
{
  return [self levelForItem: [self itemAtRow: row]];
}

- (NSTableColumn *)outlineTableColumn
{
  return _outlineTableColumn;
}

- (void)reloadItem: (id)item
{
  [self reloadItem: item reloadChildren: YES];
}

- (void)reloadItem: (id)item reloadChildren: (BOOL)reloadChildren
{
  // Nothing yet...
}

- (int)rowForItem: (id)item
{
  return [_items indexOfObject: item];
}

- (void)setAutoresizesOutlineColumn: (BOOL)resize
{
  _autoResizesOutlineColumn = resize;
}

- (void)setAutosaveExpandedItems: (BOOL)flag
{
  _autosaveExpandedItems = flag;
}

- (void)setIndentationMarkerFollowsCell: (BOOL)followsCell
{
  _indentationMarkerFollowsCell = followsCell;
}

- (void)setIndentationPerLevel: (float)newIndentLevel
{
  _indentationPerLevel = newIndentLevel;
}

- (void)setOutlineTableColumn: (NSTableColumn *)outlineTableColumn
{
  _outlineTableColumn = outlineTableColumn;
}

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited: (BOOL)deposited
{
  return _shouldCollapse;
}

- (void) noteNumberOfRowsChanged
{
  _numberOfRows = [_items count];
  
  /* If we are selecting rows, we have to check that we have no
     selected rows below the new end of the table */
  if (!_selectingColumns)
    {
      int i, count = [_selectedRows count]; 
      int row = -1;
      
      /* Check that all selected rows are in the new range of rows */
      for (i = 0; i < count; i++)
	{
	  row = [[_selectedRows objectAtIndex: i] intValue];

	  if (row >= _numberOfRows)
	    {
	      break;
	    }
	}

      if (i < count  &&  row > -1)
	{
	  /* Some of them are outside the table ! - Remove them */
	  for (; i < count; i++)
	    {
	      [_selectedRows removeLastObject];
	    }
	  /* Now if the _selectedRow is outside the table, reset it to be
	     the last selected row (if any) */
	  if (_selectedRow >= _numberOfRows)
	    {
	      if ([_selectedRows count] > 0)
		{
		  _selectedRow = [[_selectedRows lastObject] intValue];
		}
	      else
		{
		  /* Argh - all selected rows were outside the table */
		  if (_allowsEmptySelection)
		    {
		      _selectedRow = -1;
		    }
		  else
		    {
		      /* We shouldn't allow empty selection - try
                         selecting the last row */
		      int lastRow = _numberOfRows - 1;
		      
		      if (lastRow > -1)
			{
			  [_selectedRows addObject: 
					   [NSNumber numberWithInt: lastRow]];
			  _selectedRow = lastRow;
			}
		      else
			{
			  /* problem - there are no rows at all */
			  _selectedRow = -1;
			}
		    }
		}
	    }
	}
    }

  [self setFrame: NSMakeRect (_frame.origin.x, 
			      _frame.origin.y,
			      _frame.size.width, 
			      (_numberOfRows * _rowHeight) + 1)];
  
  /* If we are shorter in height than the enclosing clipview, we
     should redraw us now. */
  if (_super_view != nil)
    {
      NSRect superviewBounds; // Get this *after* [self setFrame:]
      superviewBounds = [_super_view bounds];
      if ((superviewBounds.origin.x <= _frame.origin.x) 
          && (NSMaxY (superviewBounds) >= NSMaxY (_frame)))
	{
	  [self setNeedsDisplay: YES];
	}
    }
}

- (void) setDataSource: (id)anObject
{
  NSArray *requiredMethods = 
    [NSArray arrayWithObjects: @"outlineView:child:ofItem:",
	     @"outlineView:isItemExpandable:",
	     @"outlineView:numberOfChildrenOfItem:",
	     @"outlineView:objectValueForTableColumn:byItem:",
	     nil];
  NSEnumerator *en = [requiredMethods objectEnumerator];
  NSString *selectorName = nil;

  // Is the data source editable?
  _dataSource_editable = [anObject respondsToSelector: 
				     @selector(outlineView:setObjectValue:forTableColumn:byItem:)];

  while((selectorName = [en nextObject]) != nil)
    {
      SEL sel = NSSelectorFromString(selectorName);
      if ([anObject respondsToSelector: sel] == NO) 
	{
	  [NSException 
	    raise: NSInternalInconsistencyException 
	    format: @"Data Source doesn't respond to %@",
	    selectorName];
	}
    }

  /* We do *not* retain the dataSource, it's like a delegate */
  _dataSource = anObject;
  [self tile];
  [self reloadData];
}

- (void) reloadData
{
  if([_items count] == 0)
    {
      [self _openItem: nil];
    }
  [super reloadData];
}

- (void) setDelegate: (id)anObject
{
  SEL sel;
  
  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = anObject;
  
#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(outlineView##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(outlineView##notif_name:) \
      name: NSOutlineView##notif_name##Notification object: self]
  
  SET_DELEGATE_NOTIFICATION(ColumnDidMove);
  SET_DELEGATE_NOTIFICATION(ColumnDidResize);
  SET_DELEGATE_NOTIFICATION(SelectionDidChange);
  SET_DELEGATE_NOTIFICATION(SelectionIsChanging);
  SET_DELEGATE_NOTIFICATION(ItemDidExpand);
  SET_DELEGATE_NOTIFICATION(ItemDidCollapse);
  SET_DELEGATE_NOTIFICATION(ItemWillExpand);
  SET_DELEGATE_NOTIFICATION(ItemWillCollapse);
  
  /* Cache */
  sel = @selector(outlineView:willDisplayCell:forTableColumn:row:);
  sel = @selector(outlineView:setObjectValue:forTableColumn:row:);
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_autoResizesOutlineColumn];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_indentationMarkerFollowsCell];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_autosaveExpandedItems];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_indentationPerLevel];
  [aCoder encodeConditionalObject: _outlineTableColumn];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_shouldCollapse];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  // Since we only have one version....
  self = [super initWithCoder: aDecoder];
  
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_autoResizesOutlineColumn];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_indentationMarkerFollowsCell];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_autosaveExpandedItems];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_indentationPerLevel];
  _outlineTableColumn = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_shouldCollapse];

  return self;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSTableColumn *tb;

  location = [self convertPoint: location  fromView: nil];
  _clickedRow = [self rowAtPoint: location];
  _clickedColumn = [self columnAtPoint: location];

  NSLog(@"Clicked on row: %d, %d",_clickedRow, _clickedColumn);
  NSLog(@"item for row: %@",[self itemAtRow: _clickedRow]);
  NSLog(@"level for row: %d",[self levelForRow: _clickedRow]);

  tb = [_tableColumns objectAtIndex: _clickedColumn];
  if(tb == _outlineTableColumn)
    {
      int level = [self levelForRow: _clickedRow];
      int position = 0;
      
      if(_indentationMarkerFollowsCell)
	{
	  position = _indentationPerLevel * level;
	}
      
      NSLog(@"x = %f", location.x);
      if(location.x >= position && location.x <= position + 10)
	{
	  NSLog(@"HIT!!");
	  if(![self isItemExpanded: [self itemAtRow: _clickedRow]])
	    {
	      [self expandItem: [self itemAtRow: _clickedRow]];
	    }
	  else
	    {
	      [self collapseItem: [self itemAtRow: _clickedRow]];
	    }
	}
    }

  [super mouseDown: theEvent];
}  

/* 
 * Drawing 
 */
- (void)drawRow: (int)rowIndex clipRect: (NSRect)aRect
{
  int startingColumn; 
  int endingColumn;
  NSTableColumn *tb;
  NSRect drawingRect;
  NSCell *cell;
  NSCell *imageCell = nil;
  NSRect imageRect;
  int i;
  float x_pos;

  if (_dataSource == nil)
    {
      return;
    }

  /* Using columnAtPoint: here would make it called twice per row per drawn 
     rect - so we avoid it and do it natively */

  /* Determine starting column as fast as possible */
  x_pos = NSMinX (aRect);
  i = 0;
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  startingColumn = (i - 1);

  if (startingColumn == -1)
    startingColumn = 0;

  /* Determine ending column as fast as possible */
  x_pos = NSMaxX (aRect);
  // Nota Bene: we do *not* reset i
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;

  /* Draw the row between startingColumn and endingColumn */
  for (i = startingColumn; i <= endingColumn; i++)
    {
      if (i != _editedColumn || rowIndex != _editedRow)
	{
	  id item = [self itemAtRow: rowIndex];

	  tb = [_tableColumns objectAtIndex: i];
	  cell = [tb dataCellForRow: rowIndex];
	  
	  if (_del_responds)
	    {
	      [_delegate outlineView: self   
			 willDisplayCell: cell 
			 forTableColumn: tb   
			 item: item];
	    }

	  [cell setObjectValue: [_dataSource outlineView: self
					     objectValueForTableColumn: tb
					     byItem: item]]; 
	  drawingRect = [self frameOfCellAtColumn: i
			      row: rowIndex];

	  if(tb == _outlineTableColumn)
	    {
	      NSImage *image = nil;
	      int level = 0;
	      float indentationFactor = 0.0;
	      float originalWidth = drawingRect.size.width;

	      // display the correct arrow...
	      if([self isItemExpanded: item])
		{
		  image = expanded;
		}
	      else
		{
		  image = collapsed;
		}

	      if(![self isExpandable: item])
		{
		  image = unexpandable;
		}

	      level = [self levelForItem: item];
	      indentationFactor = _indentationPerLevel * level;
	      imageCell = [[NSCell alloc] initImageCell: image];

	      if(_indentationMarkerFollowsCell)
		{
		  imageRect.origin.x = drawingRect.origin.x + indentationFactor;
		  imageRect.origin.y = drawingRect.origin.y;
		}
	      else
		{
		  imageRect.origin.x = drawingRect.origin.x;
		  imageRect.origin.y = drawingRect.origin.y;
		}

	      imageRect.size.width = [image size].width;
	      imageRect.size.height = [image size].height;

	      [imageCell drawWithFrame: imageRect inView: self];

	      drawingRect.origin.x += indentationFactor + [image size].width + 5;
	      drawingRect.size.width -= indentationFactor + [image size].width + 5;
	      
	      if (widest < (drawingRect.origin.x + originalWidth))
		{
		  widest = (drawingRect.origin.x + originalWidth);
		}
	      else
		{
		  // NSLog(@"Still widest = %lf", widest);
		}
	    }

	  [cell drawWithFrame: drawingRect inView: self];

	}
    }
}

- (void) drawRect: (NSRect)aRect
{
  int index = 0;

  for(index = 1;index <= _numberOfRows; index++)
    {
      NSRect drawingRect;

      drawingRect = [self frameOfCellAtColumn: 1
			  row: index];
    }

  [super drawRect: aRect];

  // We need to resize here since all of the columns have been
  // processed.
  if(_autoResizesOutlineColumn)
    {
      //      [_outlineTableColumn setWidth: widest];
      widest = 0; // blank this since it was just set into the column..
    }
}


/*
 * (NotificationRequestMethods)
 */
- (void) _postSelectionIsChangingNotification
{
  [nc postNotificationName: 
	NSOutlineViewSelectionIsChangingNotification
      object: self];
}
- (void) _postSelectionDidChangeNotification
{
  [nc postNotificationName: 
	NSOutlineViewSelectionDidChangeNotification
      object: self];
}
- (void) _postColumnDidMoveNotificationWithOldIndex: (int) oldIndex
					   newIndex: (int) newIndex
{
  [nc postNotificationName: 
	NSOutlineViewColumnDidMoveNotification
      object: self
      userInfo: [NSDictionary 
		  dictionaryWithObjectsAndKeys:
		  [NSNumber numberWithInt: newIndex],
		  @"NSNewColumn",
		    [NSNumber numberWithInt: oldIndex],
		  @"NSOldColumn",
		  nil]];
}

- (void) _postColumnDidResizeNotificationWithOldWidth: (float) oldWidth
{
  [nc postNotificationName: 
	NSOutlineViewColumnDidResizeNotification
      object: self
      userInfo: [NSDictionary 
		  dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithFloat: oldWidth],
		  @"NSOldWidth", 
		  nil]];
}

- (BOOL) _shouldSelectTableColumn: (NSTableColumn *)tableColumn
{
  if ([_delegate respondsToSelector: 
		   @selector (outlineView:shouldSelectTableColumn:)] == YES) 
    {
      if ([_delegate outlineView: self  shouldSelectTableColumn: tableColumn] == NO)
	{
	  return NO;
	}
    }

  return YES;
}

- (BOOL) _shouldSelectRow: (int)rowIndex
{
  id item = [self itemAtRow: rowIndex];

  if ([_delegate respondsToSelector: 
		   @selector (outlineView:shouldSelectItem:)] == YES) 
    {
      if ([_delegate outlineView: self  shouldSelectItem: item] == NO)
	{
	  return NO;
	}
    }
  
  return YES;
}

- (BOOL) _shouldSelectionChange
{
  if ([_delegate respondsToSelector: 
	  @selector (selectionShouldChangeInTableView:)] == YES) 
    {
      if ([_delegate selectionShouldChangeInTableView: self] == NO)
	{
	  return NO;
	}
    }
  
  return YES;
}

- (BOOL) _shouldEditTableColumn: (NSTableColumn *)tableColumn
			    row: (int) rowIndex
{
  id item = [self itemAtRow: rowIndex];

  if ([_delegate respondsToSelector: 
			@selector(outlineView:shouldEditTableColumn:item:)])
    {
      if ([_delegate outlineView: self shouldEditTableColumn: tableColumn
		     item: item] == NO)
	{
	  return NO;
	}
    }

  return YES;
}


- (void) setDropItem: (id) item
      dropChildIndex: (int) childIndex
{
  int row = [_items indexOfObject: item];
  id itemAfter;

  if (row == NSNotFound)
    {
      return;
    }

  if ([self isItemExpanded: item] == NO)
    {
      return;
    }

  if (childIndex == NSOutlineViewDropOnItemIndex)
    {
      currentDropRow = row;
      currentDropLevel = NSOutlineViewDropOnItemIndex;
    }
  else
    {
      itemAfter = [_dataSource outlineView: self
			       child: childIndex
			       ofItem: item];
      currentDropRow = [_items indexOfObject: itemAfter];
      currentDropLevel = [self levelForItem: itemAfter];
    }
}

- (BOOL) _isDraggingSource
{
  return [_dataSource respondsToSelector:
			@selector(outlineView:writeItems:toPasteboard:)];
}

- (BOOL) _writeRows: (NSArray *) rows
       toPasteboard: (NSPasteboard *)pboard
{
  int count = [rows count];
  int i;
  NSMutableArray *itemArray = [NSMutableArray
				arrayWithCapacity: count];

  for ( i = 0; i < count; i++ )
    {
      [itemArray addObject: 
		   [self itemAtRow: 
			   [[rows objectAtIndex: i] intValue]]];
    }

  if ([_dataSource respondsToSelector:
		     @selector(outlineView:writeItems:toPasteboard:)] == YES)
    {
      return [_dataSource outlineView: self
			  writeItems: itemArray
			  toPasteboard: pboard];
    }
  return NO;
}

/*
 *  Drag'n'drop support
 */

- (unsigned int) draggingEntered: (id <NSDraggingInfo>) sender
{
  NSLog(@"draggingEntered");
  currentDropRow = -1;
  //  currentDropOperation = -1;
  oldDropRow = -1;
  lastVerticalQuarterPosition = -1;
  oldDraggingRect = NSMakeRect(0.,0., 0., 0.);
  return NSDragOperationCopy;
}


- (unsigned int) draggingUpdated: (id <NSDraggingInfo>) sender
{
  NSPoint p = [sender draggingLocation];
  NSRect newRect;
  int row;
  int verticalQuarterPosition;
  int horizontalHalfPosition;
  int levelBefore;
  int levelAfter;
  int level;

  p = [self convertPoint: p fromView: nil];
  verticalQuarterPosition = 
    (p.y - _bounds.origin.y) / _rowHeight * 4.;
  horizontalHalfPosition = 
    (p.x - _bounds.origin.y) / _indentationPerLevel * 2.;


  if ((verticalQuarterPosition - oldProposedDropRow * 4 <= 2) &&
      (verticalQuarterPosition - oldProposedDropRow * 4 >= -3) )
    {
      row = oldProposedDropRow;
    }
  else
    {
      row = (verticalQuarterPosition + 2) / 4;
    }

  if (row > _numberOfRows)
    row = _numberOfRows;

  //  NSLog(@"horizontalHalfPosition = %d", horizontalHalfPosition);

  //  NSLog(@"dropRow %d", row);

  if (row == 0)
    {
      levelBefore = 0;
    }
  else
    {
      levelBefore = [self levelForRow: (row - 1)];
    }
  if (row == _numberOfRows)
    {
      levelAfter = 0;
    }
  else
    {
      levelAfter = [self levelForRow: row];
    }

  if (levelBefore < levelAfter)
    levelBefore = levelAfter;

  
  //  NSLog(@"horizontalHalfPosition = %d", horizontalHalfPosition);
  //  NSLog(@"level before = %d", levelBefore);
  //  NSLog(@"level after = %d", levelAfter);



  if ((lastVerticalQuarterPosition != verticalQuarterPosition)
      || (lastHorizontalHalfPosition != horizontalHalfPosition))
    {
      id item;
      int childIndex;

      if (horizontalHalfPosition / 2 < levelAfter)
	horizontalHalfPosition = levelAfter * 2;
      else if (horizontalHalfPosition / 2 > levelBefore)
	horizontalHalfPosition = levelBefore * 2 + 1;
      level = horizontalHalfPosition / 2;


      lastVerticalQuarterPosition = verticalQuarterPosition;
      lastHorizontalHalfPosition = horizontalHalfPosition;
      
      //      NSLog(@"horizontalHalfPosition = %d", horizontalHalfPosition);
      //      NSLog(@"verticalQuarterPosition = %d", verticalQuarterPosition);
      
      currentDropRow = row;
      currentDropLevel = level;

      {
	int i;
	int j = 0;
	int lvl;
	for ( i = row - 1; i >= 0; i-- )
	  {
	    lvl = [self levelForRow: i];
	    if (lvl == level - 1)
	      {
		break;
	      }
	    else if (lvl == level)
	      {
		j++;
	      }
	  }
	//	NSLog(@"found %d (proposed childIndex = %d)", i, j);
	if (i == -1)
	  item = nil;
	else
	  item = [self itemAtRow: i];
	
	childIndex = j;
      }


      oldProposedDropRow = currentDropRow;
      if ([_dataSource respondsToSelector: 
			 @selector(outlineView:validateDrop:proposedItem:proposedChildIndex:)])
	{
	  //	  NSLog(@"currentDropLevel %d, currentDropRow %d",
	  //		currentDropRow, currentDropLevel);
	  [_dataSource outlineView: self
		       validateDrop: sender
		       proposedItem: item
		       proposedChildIndex: childIndex];
	  //	  NSLog(@"currentDropLevel %d, currentDropRow %d", 
	  //		currentDropRow, currentDropLevel);
	}
      
      if ((currentDropRow != oldDropRow) || (currentDropLevel != oldDropLevel))
	{
	  [self lockFocus];
	  
	  [self setNeedsDisplayInRect: oldDraggingRect];
	  [self displayIfNeeded];
	  
	  [[NSColor darkGrayColor] set];
	  
	  //	  NSLog(@"currentDropLevel %d, currentDropRow %d", 
	  //		currentDropRow, currentDropLevel);
	  if (currentDropLevel != NSOutlineViewDropOnItemIndex)
	    {
	      if (currentDropRow == 0)
		{
		  newRect = NSMakeRect([self visibleRect].origin.x,
				       currentDropRow * _rowHeight,
				       [self visibleRect].size.width,
				       3);
		}
	      else if (currentDropRow == _numberOfRows)
		{
		  newRect = NSMakeRect([self visibleRect].origin.x,
				       currentDropRow * _rowHeight - 2,
				       [self visibleRect].size.width,
				       3);
		}
	      else
		{
		  newRect = NSMakeRect([self visibleRect].origin.x,
				       currentDropRow * _rowHeight - 1,
				       [self visibleRect].size.width,
				       3);
		}
	      newRect.origin.x += currentDropLevel * _indentationPerLevel;
	      newRect.size.width -= currentDropLevel * _indentationPerLevel;
	      NSRectFill(newRect);
	      oldDraggingRect = newRect;

	    }
	  else
	    {
	      newRect = [self frameOfCellAtColumn: 0
			      row: currentDropRow];
	      newRect.origin.x = _bounds.origin.x;
	      newRect.size.width = _bounds.size.width + 2;
	      newRect.origin.x -= _intercellSpacing.height / 2;
	      newRect.size.height += _intercellSpacing.height;
	      oldDraggingRect = newRect;
	      oldDraggingRect.origin.y -= 1;
	      oldDraggingRect.size.height += 2;

	      newRect.size.height -= 1;

	      newRect.origin.x += 3;
	      newRect.size.width -= 3;
		
	      if (_drawsGrid)
		{
		  //newRect.origin.y += 1;
		  //newRect.origin.x += 1;
		  //newRect.size.width -= 2;
		  newRect.size.height += 1;
		}
	      else
		{
		}

	      newRect.origin.x += currentDropLevel * _indentationPerLevel;
	      newRect.size.width -= currentDropLevel * _indentationPerLevel;

	      NSFrameRectWithWidth(newRect, 2.0);
	      //	      NSRectFill(newRect);

	      }
	  [_window flushWindow];
	  
	  [self unlockFocus];
	  
	  oldDropRow = currentDropRow;
	  oldDropLevel = currentDropLevel;
	}
    }


  return NSDragOperationCopy;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSLog(@"performDragOperation");
  if ([_dataSource 
	respondsToSelector: 
	  @selector(outlineView:validateDrop:proposedItem:proposedChildIndex:)])
    {
      id item;
      int childIndex;
      int i;
      int j = 0;
      int lvl;
      for ( i = currentDropRow - 1; i >= 0; i-- )
	{
	  lvl = [self levelForRow: i];
	  if (lvl == currentDropLevel - 1)
	    {
	      break;
	    }
	  else if (lvl == currentDropLevel)
	    {
	      j++;
	    }
	}
      if (i == -1)
	item = nil;
      else
	item = [self itemAtRow: i];
      
      childIndex = j;


      return [_dataSource 
	       outlineView: self
		 validateDrop: sender
		 proposedItem: item
		 proposedChildIndex: childIndex];
    }
  else
    return NO;
}

@end /* implementation of NSOutlineView */

