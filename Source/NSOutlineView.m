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

// Cache the arrow images...
static NSImage *collapsed = nil;
static NSImage *expanded  = nil;

// Some necessary things which should not become ivars....
static float widest = 0.0;

//
// Forward declarations for functions used by both the NSTableView class
// and NSOutlineView.
//
/* The selection arrays are stored so that the selected columns/rows
   are always in ascending order.  The following function is used
   whenever a new column/row is added to the array, to keep the
   columns/rows in the correct order. */
static
void _insertNumberInSelectionArray (NSMutableArray *array, 
				    NSNumber *num)
{
  int i, count;

  count = [array count];
 
  for (i = 0; i < count; i++)
    {
      NSNumber *number;
      
      number = [array objectAtIndex: i];
      if ([number compare: num] == NSOrderedDescending)
	break;
    }
  [array insertObject: num  atIndex: i];
}

/* 
 * Now some auxiliary functions used to manage real-time user selections. 
 *
 */

static void
_selectItemsInRange (NSOutlineView *ov, id delegate, 
		     int startRow, int endRow, int clickedRow)
{
  int i;
  int tmp;
  int shift = 1;

  /* Switch rows if in the wrong order */
  if (startRow > endRow)
    {
      tmp = startRow;
      startRow = endRow;
      endRow = tmp;
      shift = 0;
    }

  for (i = startRow + shift; i < endRow + shift; i++)
    {
      if (i != clickedRow)
	{
	  if (delegate != nil)
	    {
	      id item = [ov itemAtRow: i];
	      if ([delegate outlineView: ov shouldSelectItem: item] == NO)
		continue;
	    }

	  [ov selectRow: i  byExtendingSelection: YES];
	  [ov setNeedsDisplayInRect: [ov rectOfRow: i]];
	}
    }
}

static void
_deselectItemsInRange (NSOutlineView *ov, int startRow, int endRow, 
		       int clickedRow)
{
  int i;
  int tmp;
  int shift = 1;

  if (startRow > endRow)
    {
      tmp = startRow;
      startRow = endRow;
      endRow = tmp;
      shift = 0;
    }

  for (i = startRow + shift; i < endRow + shift; i++)
    {
      if (i != clickedRow)
	{
	  [ov deselectRow: i];
	  [ov setNeedsDisplayInRect: [ov rectOfRow: i]];
	}
    }
}

/*
 * The following function can work on columns or rows; 
 * passing the correct select/deselect function switches between one 
 * and the other.  Currently used only for rows, anyway.
 */

static void
_selectionChange (NSOutlineView *ov, id delegate, int numberOfRows, 
		  int clickedRow, 
		  int oldSelectedRow, int newSelectedRow, 
		  void (*deselectFunction)(NSOutlineView *, int, int, int), 
		  void (*selectFunction)(NSOutlineView *, id, int, int, int))
{
  int newDistance;
  int oldDistance;

  if (oldSelectedRow == newSelectedRow)
    return;

  /* Change coordinates - distance from the center of selection */
  oldDistance = oldSelectedRow - clickedRow;
  newDistance = newSelectedRow - clickedRow;

  /* If they have different signs, then we decompose it into 
     two problems with the same sign */
  if ((oldDistance * newDistance) < 0)
    {
      _selectionChange (ov, delegate, numberOfRows, clickedRow, 
			oldSelectedRow, clickedRow, deselectFunction, 
			selectFunction);
      _selectionChange (ov, delegate, numberOfRows, clickedRow, clickedRow, 
			newSelectedRow, deselectFunction, selectFunction);
      return;
    }

  /* Otherwise, take the modulus of the distances */
  if (oldDistance < 0)
    oldDistance = -oldDistance;

  if (newDistance < 0)
    newDistance = -newDistance;

  /* If the new selection is more wide, we need to select */
  if (newDistance > oldDistance)
    {
      selectFunction (ov, delegate, oldSelectedRow, newSelectedRow, 
		      clickedRow);
    }
  else /* Otherwise to deselect */
    {
      deselectFunction (ov, newSelectedRow, oldSelectedRow, clickedRow);
    }
}

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
      //      NSLog(@"%@ %@",rightArrow, downArrow);
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

- (void)_closeItem: (id)item
{
  int numchildren = [_dataSource outlineView: self 
				 numberOfChildrenOfItem: item];
  int i = 0;

  NSLog(@"closing: %@", item);
  // close the item...
  if(item == nil)
    {
      [_expandedItems removeObject: @"root"];
    }
  else
    {
      [_expandedItems removeObject: item];
    }

  // For the close method it doesn't matter what order they are 
  // removed in.
  for(i=1;i<=numchildren;i++)
    {
      id child = [_dataSource outlineView: self
			      child: i
			      ofItem: item];
      NSLog(@"child = %@",child);
      [_items removeObject: child];
    }
}

- (void)_openItem: (id)item
{
  int numchildren = [_dataSource outlineView: self 
				 numberOfChildrenOfItem: item];
  int i = 0;
  int insertionPoint = 0;

  NSLog(@"opening: %@", item);
  // open the item...
  if(item == nil)
    {
      [_expandedItems addObject: @"root"];
    }
  else
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

  // [self setNeedsDisplayInRect: [self rectOfRow: [self rowForItem: item]]];  
  [self setNeedsDisplay: YES];  
  NSLog(@"Insertion point = %d",insertionPoint);
  for(i=numchildren; i > 0; i--)
    {
      id child = [_dataSource outlineView: self
			      child: i
			      ofItem: item];
      NSLog(@"In here....");
      NSLog(@"child = %@",child);
      [_items insertObject: child atIndex: insertionPoint];
      // [self setNeedsDisplayInRect: [self rectOfRow: [self rowForItem: child]]]; 
      NSLog(@"_items = %@",_items);
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
  NSLog(@"itemAtRow %d",row);
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

  for(i = 1; i <= num; i++)
    {
      id anitem = [[outline dataSource] outlineView: outline
					child: i
					ofItem: startitem];
      finallevel = _levelForItem(outline, anitem, searchitem, level + 1, found); 
    }

  return finallevel;
}

- (int)levelForItem: (id)item
{
  //  NSLog(@"Getting level for %@", item);
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

- (void)setDropItem:(id)item dropChildIndex: (int)index
{
  // Nothing yet...
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
  NSLog(@"_numberOfRows = %d", _numberOfRows);
  
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

- (void) moveColumn: (int)columnIndex toColumn: (int)newIndex
{
  /* The range of columns which need to be shifted, 
     extremes included */
  int minRange, maxRange;
  /* Amount of shift for these columns */
  int shift;
  /* Dummy variables for the loop */
  int i, count, column;
  NSDictionary *dict;

  if ((columnIndex < 0) || (columnIndex > (_numberOfColumns - 1)))
    {
      NSLog (@"Attempt to move column outside table");
      return;
    }
  if ((newIndex < 0) || (newIndex > (_numberOfColumns - 1)))
    {
      NSLog (@"Attempt to move column to outside table");
      return;
    }

  if (columnIndex == newIndex)
    return;

  if (columnIndex > newIndex)
    {
      minRange = newIndex;
      maxRange = columnIndex - 1;
      shift = +1;
    }
  else // columnIndex < newIndex
    {
      minRange = columnIndex + 1;
      maxRange = newIndex;
      shift = -1;
    }

  /* Rearrange selection */
  if (_selectedColumn == columnIndex)
    {
      _selectedColumn = newIndex;
    }
  else if ((_selectedColumn >= minRange) && (_selectedColumn <= maxRange)) 
    {
      _selectedColumn += shift;
    }

  count = [_selectedColumns count];
  for (i = 0; i < count; i++)
    {
      column = [[_selectedColumns objectAtIndex: i] intValue];

      if (column == columnIndex)
	{
	  [_selectedColumns replaceObjectAtIndex: i 
			    withObject: [NSNumber numberWithInt: newIndex]];
	  continue;
	}

      if ((column >= minRange) && (column <= maxRange))
	{
	  column += shift;
	  [_selectedColumns replaceObjectAtIndex: i 
			    withObject: [NSNumber numberWithInt: column]];
	  continue;
	}

      if ((column > columnIndex) && (column > newIndex))
	{
	  break;
	}
    }
  /* Now really move the column */
  if (columnIndex < newIndex)
    {
      [_tableColumns insertObject: [_tableColumns objectAtIndex: columnIndex]
		     atIndex: newIndex + 1];
      [_tableColumns removeObjectAtIndex: columnIndex];
    }
  else
    {
      [_tableColumns insertObject: [_tableColumns objectAtIndex: columnIndex]
		     atIndex: newIndex];
      [_tableColumns removeObjectAtIndex: columnIndex + 1];
    }
  /* Tile */
  [self tile];

  /* Post notification */
  dict =[NSDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithInt: columnIndex], @"NSOldColumn", 
		      [NSNumber numberWithInt: newIndex], @"NSNewColumn", nil];
  [nc postNotificationName: NSOutlineViewColumnDidMoveNotification
      object: self
      userInfo: dict];

  [self _autosaveTableColumns];
}

/*
 * Selecting Columns and Rows
 */
- (void) selectColumn: (int)columnIndex 
 byExtendingSelection: (BOOL)flag
{
  NSNumber *num  = [NSNumber numberWithInt: columnIndex];
  
  if (columnIndex < 0 || columnIndex > _numberOfColumns)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Column index out of table in selectColumn"];
    }

  _selectingColumns = YES;

  if (flag == NO)
    {
      /* If the current selection is the one we want, just ends editing
       * This is not just a speed up, it prevents us from sending
       * a NSOutlineViewSelectionDidChangeNotification.
       * This behaviour is required by the specifications */
      if ([_selectedColumns count] == 1
	  && [_selectedColumns containsObject: num] == YES)
	{
	  /* Stop editing if any */
	  if (_textObject != nil)
	    {
	      [self validateEditing];
	      [self abortEditing];
	    }  
	  return;
	} 

      /* If _numberOfColumns == 1, we can skip trying to deselect the
	 only column - because we have been called to select it. */
      if (_numberOfColumns > 1)
	{
	  [_selectedColumns removeAllObjects];
	  _selectedColumn = -1;
	}
    }
  else // flag == YES
    {
      if (_allowsMultipleSelection == NO)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Can not extend selection in table view when multiple selection is disabled"];  
	}
    }

  /* Stop editing if any */
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }  

  /* Now select the column and post notification only if needed */ 
  if ([_selectedColumns containsObject: num] == NO)
    {
      _insertNumberInSelectionArray (_selectedColumns, num);
      _selectedColumn = columnIndex;
      [nc postNotificationName: NSOutlineViewSelectionDidChangeNotification
	  object: self];
    }
  else /* Otherwise simply change the last selected column */
    {
      _selectedColumn = columnIndex;
    }
}

- (void) selectRow: (int)rowIndex
byExtendingSelection: (BOOL)flag
{
  NSNumber *num  = [NSNumber numberWithInt: rowIndex];

  if (rowIndex < 0 || rowIndex > _numberOfRows)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Row index out of table in selectRow"];
    }

  _selectingColumns = NO;

  if (flag == NO)
    {
      /* If the current selection is the one we want, just ends editing
       * This is not just a speed up, it prevents us from sending
       * a NSOutlineViewSelectionDidChangeNotification.
       * This behaviour is required by the specifications */
      if ([_selectedRows count] == 1
	  && [_selectedRows containsObject: num] == YES)
	{
	  /* Stop editing if any */
	  if (_textObject != nil)
	    {
	      [self validateEditing];
	      [self abortEditing];
	    }
	  return;
	} 

      /* If _numberOfRows == 1, we can skip trying to deselect the
	 only row - because we have been called to select it. */
      if (_numberOfRows > 1)
	{
	  [_selectedRows removeAllObjects];
	  _selectedRow = -1;
	}
    }
  else // flag == YES
    {
      if (_allowsMultipleSelection == NO)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Can not extend selection in table view when multiple selection is disabled"];  
	}
    }

  /* Stop editing if any */
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }  

  /* Now select the row and post notification only if needed */ 
  if ([_selectedRows containsObject: num] == NO)
    {
      _insertNumberInSelectionArray (_selectedRows, num);
      _selectedRow = rowIndex;
      [nc postNotificationName: NSOutlineViewSelectionDidChangeNotification
	  object: self];
    }
  else /* Otherwise simply change the last selected row */
    {
      _selectedRow = rowIndex;
    }
}

- (void) deselectColumn: (int)columnIndex
{
  NSNumber *num  = [NSNumber numberWithInt: columnIndex];

  if ([_selectedColumns containsObject: num] == NO)
    {
      return;
    }

  /* Now by internal consistency we assume columnIndex is in fact a
     valid column index, since it was the index of a selected column */

  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }
  
  _selectingColumns = YES;

  [_selectedColumns removeObject: num];

  if (_selectedColumn == columnIndex)
    {
      int i, count = [_selectedColumns count]; 
      int nearestColumn = -1;
      int nearestColumnDistance = _numberOfColumns;
      int column, distance;
      for (i = 0; i < count; i++)
	{
	  column = [[_selectedColumns objectAtIndex: i] intValue];

	  distance = column - columnIndex;
	  if (distance < 0)
	    {
	      distance = -distance;
	    }

	  if (distance < nearestColumnDistance)
	    {
	      nearestColumn = column;
	    }
	}
      _selectedColumn = nearestColumn;
    }

  [nc postNotificationName: NSOutlineViewSelectionDidChangeNotification
      object: self];
}

- (void) deselectRow: (int)rowIndex
{
  NSNumber *num  = [NSNumber numberWithInt: rowIndex];

  if ([_selectedRows containsObject: num] == NO)
    {
      return;
    }

  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }

  _selectingColumns = NO;

  [_selectedRows removeObject: num];

  if (_selectedRow == rowIndex)
    {
      int i, count = [_selectedRows count]; 
      int nearestRow = -1;
      int nearestRowDistance = _numberOfRows;
      int row, distance;
      for (i = 0; i < count; i++)
	{
	  row = [[_selectedRows objectAtIndex: i] intValue];

	  distance = row - rowIndex;
	  if (distance < 0)
	    {
	      distance = -distance;
	    }

	  if (distance < nearestRowDistance)
	    {
	      nearestRow = row;
	    }
	}
      _selectedRow = nearestRow;
    }

  [nc postNotificationName: NSOutlineViewSelectionDidChangeNotification
      object: self];
}

- (void) selectAll: (id) sender
{
  SEL selector; 

  if (_allowsMultipleSelection == NO)
    return;

  /* Ask the delegate if we can select all columns or rows */
  if (_selectingColumns == YES)
    {
      if ([_selectedColumns count] == _numberOfColumns)
	{
	  // Nothing to do !
	  return;
	}

      selector = @selector (outlineView:shouldSelectTableColumn:);
      
      if ([_delegate respondsToSelector: selector] == YES) 
	{
	  NSEnumerator *enumerator = [_tableColumns objectEnumerator];
	  NSTableColumn *tb;
	  while ((tb = [enumerator nextObject]) != nil)
	    {
	      if ([_delegate outlineView: self  
			     shouldSelectTableColumn: tb] == NO)
		{
		  return;
		}
	    }
	}
    }
  else // selecting rows
    {
      if ([_selectedRows count] == _numberOfRows)
	{
	  // Nothing to do !
	  return;
	}

      selector = @selector (outlineView:shouldSelectRow:);
      
      if ([_delegate respondsToSelector: selector] == YES) 
	{
	  int row; 
      
	  for (row = 0; row < _numberOfRows; row++)
	    {
	      id item = [self itemAtRow: row];
	      if ([_delegate outlineView: self shouldSelectItem: item] == NO)
		  return;
	    }
	}
    }

  /* Stop editing if any */
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }  

  /* Do the real selection */
  if (_selectingColumns == YES)
    {
      int column;

      [_selectedColumns removeAllObjects];
      for (column = 0; column < _numberOfColumns; column++)
	{
	  NSNumber *num  = [NSNumber numberWithInt: column];
	  [_selectedColumns addObject: num];
	}
    }
  else // selecting rows
    {
      int row;

      [_selectedRows removeAllObjects];
      for (row = 0; row < _numberOfRows; row++)
	{
	  NSNumber *num  = [NSNumber numberWithInt: row];
	  [_selectedRows addObject: num];
	}
    }
  
  [nc postNotificationName: NSOutlineViewSelectionDidChangeNotification
      object: self];
}

- (void) deselectAll: (id) sender
{
  SEL selector; 

  if (_allowsEmptySelection == NO)
    return;

  selector = @selector (selectionShouldChangeInOutlineView:);
  if ([_delegate respondsToSelector: selector] == YES) 
    {
      if ([_delegate selectionShouldChangeInOutlineView: self] == NO)
	{
	  return;
	}
    }

  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }
	  
  if (([_selectedColumns count] > 0) || ([_selectedRows count] > 0))
    {
      [_selectedColumns removeAllObjects];
      [_selectedRows removeAllObjects];
      [nc postNotificationName: NSOutlineViewSelectionDidChangeNotification
	  object: self];
    }

  _selectedColumn = -1;
  _selectedRow = -1;
  _selectingColumns = NO;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSTableColumn *tb;
  int clickCount;
  BOOL shouldEdit;

  //
  // Pathological case -- ignore mouse down
  //
  if ((_numberOfRows == 0) || (_numberOfColumns == 0))
    {
      [super mouseDown: theEvent];
      return; 
    }
  
  clickCount = [theEvent clickCount];

  if (clickCount > 2)
    return;

  // Determine row and column which were clicked
  location = [self convertPoint: location  fromView: nil];
  _clickedRow = [self rowAtPoint: location];
  _clickedColumn = [self columnAtPoint: location];

  NSLog(@"location (%f,%f)",location.x,location.y);

  // Selection
  if (clickCount == 1)
    {
      SEL selector;
      unsigned int modifiers;
      modifiers = [theEvent modifierFlags];

      /* Unselect a selected row if the shift key is pressed */
      if ([self isRowSelected: _clickedRow] == YES
	  && (modifiers & NSShiftKeyMask))
	{
	  if (([_selectedRows count] == 1) && (_allowsEmptySelection == NO))
	    return;

	  selector = @selector (selectionShouldChangeInOutlineView:);
	  if ([_delegate respondsToSelector: selector] == YES) 
	    {
	      if ([_delegate selectionShouldChangeInOutlineView: self] == NO)
		{
		  return;
		}
	    }

	  if (_selectingColumns == YES)
	    {
	      [self _setSelectingColumns: NO];
	    }
	 
	  [self deselectRow: _clickedRow];
	  [self setNeedsDisplayInRect: [self rectOfRow: _clickedRow]];
	  return;
	}
      else // row is not selected 
	{
	  BOOL newSelection;

	  NSLog(@"row which was clicked %d, item %@", 
		_clickedRow,
		[self itemAtRow: _clickedRow]);

	  if(![self isItemExpanded: [self itemAtRow: _clickedRow]])
	    {
	      [self expandItem: [self itemAtRow: _clickedRow]];
	    }
	  else
	    {
	      [self collapseItem: [self itemAtRow: _clickedRow]];
	    }

	  if ((modifiers & (NSShiftKeyMask | NSAlternateKeyMask)) 
	      && _allowsMultipleSelection)
	    newSelection = NO;
	  else
	    newSelection = YES;

	  selector = @selector (selectionShouldChangeInOutlineView:);
	  if ([_delegate respondsToSelector: selector] == YES) 
	    {
	      if ([_delegate selectionShouldChangeInOutlineView: self] == NO)
		{
		  return;
		}
	    }
	  
	  selector = @selector (outlineView:shouldSelectItem:);
	  if ([_delegate respondsToSelector: selector] == YES) 
	    {
	      id clickedItem = [self itemAtRow: _clickedRow];
	      if ([_delegate outlineView: self 
			     shouldSelectItem: clickedItem] == NO)
		{
		  return;
		}
	    }

	  if (_selectingColumns == YES)
	    {
	      [self _setSelectingColumns: NO];
	    }

	  if (newSelection == YES)
	    {
	      /* No shift or alternate key pressed: clear the old selection */
	      
	      /* Compute rect to redraw to clear the old selection */
	      int row, i, count = [_selectedRows count];
	      
	      for (i = 0; i < count; i++)
		{
		  row = [[_selectedRows objectAtIndex: i] intValue];
		  [self setNeedsDisplayInRect: [self rectOfRow: row]];
		}

	      /* Draw the new selection */
	      [self selectRow: _clickedRow  byExtendingSelection: NO];
	      [self setNeedsDisplayInRect: [self rectOfRow: _clickedRow]];
	    }
	  else /* Simply add to the old selection */
	    {
	      [self selectRow: _clickedRow  byExtendingSelection: YES];
	      [self setNeedsDisplayInRect: [self rectOfRow: _clickedRow]];
	    }

	  if (_allowsMultipleSelection == NO)
	    {
	      return;
	    }
	  
	  /* else, we track the mouse to allow extending selection to
	     areas by dragging the mouse */
	  
	  /* Draw immediately because we are going to enter an event
	     loop to track the mouse */
	  [_window flushWindow];
	  
	  /* We track the cursor and highlight according to the cursor
	     position.  When the cursor gets out (up or down) of the
	     table, we start periodic events and scroll periodically
	     the table enlarging or reducing selection. */
	  {
	    BOOL startedPeriodicEvents = NO;
	    unsigned int eventMask = (NSLeftMouseUpMask 
				      | NSLeftMouseDraggedMask 
				      | NSPeriodicMask);
	    NSEvent *lastEvent;
	    BOOL done = NO;
	    NSPoint mouseLocationWin;
	    NSDate *distantFuture = [NSDate distantFuture];
	    int lastSelectedRow = _clickedRow;
	    NSRect visibleRect = [self convertRect: [self visibleRect]
				       toView: nil];
	    float minYVisible = NSMinY (visibleRect);
	    float maxYVisible = NSMaxY (visibleRect);
	    BOOL delegateTakesPart;
	    BOOL mouseUp = NO;
	    /* We have three zones of speed. 
	       0   -  50 pixels: period 0.2  <zone 1>
	       50  - 100 pixels: period 0.1  <zone 2>
	       100 - 150 pixels: period 0.01 <zone 3> */
	    float oldPeriod = 0;
	    inline float computePeriod ()
	      {
		float distance = 0;
		
		if (mouseLocationWin.y < minYVisible) 
		  {
		    distance = minYVisible - mouseLocationWin.y; 
		  }
		else if (mouseLocationWin.y > maxYVisible)
		  {
		    distance = mouseLocationWin.y - maxYVisible;
		  }
		
		if (distance < 50)
		  return 0.2;
		else if (distance < 100)
		  return 0.1;
		else 
		  return 0.01;
	      }

	    selector = @selector (outlineView:shouldSelectRow:);
	    delegateTakesPart = [_delegate respondsToSelector: selector];
	    
	    while (done != YES)
	      {
		lastEvent = [NSApp nextEventMatchingMask: eventMask 
				   untilDate: distantFuture
				   inMode: NSEventTrackingRunLoopMode 
				   dequeue: YES]; 

		switch ([lastEvent type])
		  {
		  case NSLeftMouseUp:
		    done = YES;
		    break;
		  case NSLeftMouseDragged:
		    mouseLocationWin = [lastEvent locationInWindow]; 
		    if ((mouseLocationWin.y > minYVisible) 
			&& (mouseLocationWin.y < maxYVisible))
		      {
			NSPoint mouseLocationView;
			int rowAtPoint;
			
			if (startedPeriodicEvents == YES)
			  {
			    [NSEvent stopPeriodicEvents];
			    startedPeriodicEvents = NO;
			  }
			mouseLocationView = [self convertPoint: 
						    mouseLocationWin 
						  fromView: nil];
			mouseLocationView.x = _bounds.origin.x;
			rowAtPoint = [self rowAtPoint: mouseLocationView];
			
			if (delegateTakesPart == YES)
			  {
			    _selectionChange (self, _delegate, 
					      _numberOfRows, _clickedRow, 
					      lastSelectedRow, rowAtPoint, 
					      _deselectItemsInRange, 
					      _selectItemsInRange);
			  }
			else
			  {
			    _selectionChange (self, nil,
					      _numberOfRows, _clickedRow, 
					      lastSelectedRow, rowAtPoint, 
					      _deselectItemsInRange, 
					      _selectItemsInRange);
			  }
			lastSelectedRow = rowAtPoint;
			[_window flushWindow];
			[nc postNotificationName: 
			      NSOutlineViewSelectionIsChangingNotification
			    object: self];
		      }
		    else /* Mouse dragged out of the table */
		      {
			if (startedPeriodicEvents == YES)
			  {
			    /* Check - if the mouse did not change zone, 
			       we do nothing */
			    if (computePeriod () == oldPeriod)
			      break;

			    [NSEvent stopPeriodicEvents];
			  }
			/* Start periodic events */
			oldPeriod = computePeriod ();
			
			[NSEvent startPeriodicEventsAfterDelay: 0
				 withPeriod: oldPeriod];
			startedPeriodicEvents = YES;
			if (mouseLocationWin.y <= minYVisible) 
			  mouseUp = NO;
			else
			  mouseUp = YES;
		      }
		    break;
		  case NSPeriodic:
		    if (mouseUp == NO) // mouse below the table
		      {
			if (lastSelectedRow < _clickedRow)
			  {
			    [self deselectRow: lastSelectedRow];
			    [self setNeedsDisplayInRect: 
				    [self rectOfRow: lastSelectedRow]];
			    [self scrollRowToVisible: lastSelectedRow];
			    [_window flushWindow];
			    lastSelectedRow++;
			  }
			else
			  {
			    if ((lastSelectedRow + 1) < _numberOfRows)
			      {
				id item = nil;

				lastSelectedRow++;
				item = [self itemAtRow: lastSelectedRow];
				if ((delegateTakesPart == YES) &&
				    ([_delegate 
				       outlineView: self 
				       shouldSelectItem: item] 
				     == NO))
				  {
				    break;
				  }
				[self selectRow: lastSelectedRow 
				      byExtendingSelection: YES];
				[self setNeedsDisplayInRect: 
					[self rectOfRow: lastSelectedRow]];
				[self scrollRowToVisible: lastSelectedRow];
				[_window flushWindow];
			      }
			  }
		      }
		    else /* mouse above the table */
		      {
			if (lastSelectedRow <= _clickedRow)
			  {
			    if ((lastSelectedRow - 1) >= 0)
			      {
				id item = nil;

				lastSelectedRow--;
				item = [self itemAtRow: lastSelectedRow];
				if ((delegateTakesPart == YES) &&
				    ([_delegate 
				       outlineView: self 
				       shouldSelectItem: item] 
				     == NO))
				  {
				    break;
				  }
				[self selectRow: lastSelectedRow 
				      byExtendingSelection: YES];
				[self setNeedsDisplayInRect: 
					[self rectOfRow: lastSelectedRow]];
				[self scrollRowToVisible: lastSelectedRow];
				[_window flushWindow];
			      }
			  }
			else
			  {
			    [self deselectRow: lastSelectedRow];
			    [self setNeedsDisplayInRect: 
				    [self rectOfRow: lastSelectedRow]];
			    [self scrollRowToVisible: lastSelectedRow];
			    [_window flushWindow];
			    lastSelectedRow--;
			  }
		      }
		    [nc postNotificationName: 
			  NSOutlineViewSelectionIsChangingNotification
			object: self];
		    break;
		  default:
		    break;
		  }

	      }
	    
	    if (startedPeriodicEvents == YES)
	      [NSEvent stopPeriodicEvents];

	    [nc postNotificationName: 
		  NSOutlineViewSelectionDidChangeNotification
		object: self];
	    
	    return;
	  }
	}
    }

  // Double-click events

  if ([self isRowSelected: _clickedRow] == NO)
    return;

  tb = [_tableColumns objectAtIndex: _clickedColumn];

  shouldEdit = YES;

  if ([tb isEditable] == NO)
    {
      shouldEdit = NO;
    }
  else if ([_delegate respondsToSelector: 
			@selector(outlineView:shouldEditTableColumn:item:)])
    {
      id clickedItem = [self itemAtRow: _clickedRow];
      if ([_delegate outlineView: self shouldEditTableColumn: tb 
		     item: clickedItem] == NO)
	{
	  shouldEdit = NO;
	}
    }
  
  if (shouldEdit == NO)
    {
      // Send double-action but don't edit
      [self sendAction: _doubleAction to: _target];
      return;
    }

  // It is OK to edit column.  Go on, do it.
  [self editColumn: _clickedColumn  row: _clickedRow
	withEvent: theEvent  select: NO];
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

  NSLog(@"In the drawing code...");
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
	  NSLog(@"Drawing rect (%f, %f, %f, %f)",
		drawingRect.origin.x, 
		drawingRect.origin.y, 
		drawingRect.size.width, 
		drawingRect.size.height);

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

	      level = [self levelForItem: item];
	      //	      NSLog(@"outlineColumn: %@ level = %d", item, level);
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

	      // Draw the arrow if the item is expandable..
	      if([self isExpandable: item])
		{
		  [imageCell drawWithFrame: imageRect inView: self];
		}

	      drawingRect.origin.x += indentationFactor + [image size].width + 1;
	      drawingRect.size.width -= indentationFactor + [image size].width + 1;
	      
	      if (widest < (drawingRect.origin.x + originalWidth))
		{
		  widest = (drawingRect.origin.x + originalWidth);
		  NSLog(@"widest = %lf", widest);
		}
	      else
		{
		  NSLog(@"Still widest = %lf", widest);
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

      NSLog(@"Row = %d",index);
      drawingRect = [self frameOfCellAtColumn: 1
			  row: index];
      NSLog(@"Width = %d",drawingRect.size.width);
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

@end /* implementation of NSOutlineView */

