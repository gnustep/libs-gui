/** <title>NSOutlineView</title>

   <abstract>
   This class is a subclass of NSTableView which provides the user with a way
   to display tree structured data in an outline format.   It is particularly useful for show
   hierarchical data such as a class inheritance tree or any other set of relationships.
   </abstract>
   
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

#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSCell.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSOutlineView.h"
#include "AppKit/NSScroller.h"
#include "AppKit/NSTableColumn.h"
#include "AppKit/NSTableHeaderView.h"
#include "AppKit/NSText.h"
#include "AppKit/NSTextFieldCell.h"
#include "AppKit/NSWindow.h"

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
- (id)_objectValueForTableColumn: (NSTableColumn *)tb
			     row: (int)index;
- (void) _setObjectValue: (id)value
	  forTableColumn: (NSTableColumn *)tb
		     row: (int) index;
@end

// These methods are private...
@interface NSOutlineView (TableViewInternalPrivate)
- (void) _setSelectingColumns: (BOOL)flag;
- (BOOL) _editNextEditableCellAfterRow: (int)row
				column: (int)column;
- (BOOL) _editPreviousEditableCellBeforeRow: (int)row
				     column: (int)column;
- (void) _autosaveExpandedItems;
- (void) _autoloadExpandedItems;
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
      collapsed    = [NSImage imageNamed: @"common_outlineCollapsed.tiff"];
      expanded     = [NSImage imageNamed: @"common_outlineExpanded.tiff"];
      unexpandable = [NSImage imageNamed: @"common_outlineUnexpandable.tiff"];
    }
}

// Instance methods

/**
 *  Initalizes the outline view with the given frame.   Invokes
 * the superclass method initWithFrame: as well to initialize the object.
 *
 */
- (id)initWithFrame: (NSRect)frame
{
  [super initWithFrame: frame];

  // Initial values
  _indentationMarkerFollowsCell = YES;
  _autoResizesOutlineColumn = NO;
  _autosaveExpandedItems = NO;
  _indentationPerLevel = 0.0;
  _outlineTableColumn = nil;
  _itemDict = NSCreateMapTable(NSObjectMapKeyCallBacks,
			       NSObjectMapValueCallBacks,
			       64);
  _items = [NSMutableArray new];
  _expandedItems = [NSMutableArray new];
  _levelOfItems = NSCreateMapTable(NSObjectMapKeyCallBacks,
				   NSObjectMapValueCallBacks,
				   64);

  return self;
}

- (void) dealloc
{
  RELEASE(_items);
  RELEASE(_expandedItems);
  NSFreeMapTable(_itemDict);
  NSFreeMapTable(_levelOfItems);

  if(_autosaveExpandedItems)
    {
      // notify when an item expands...
      [nc removeObserver: self
	  name: NSOutlineViewItemDidExpandNotification
	  object: self];
      
      // notify when an item collapses...
      [nc removeObserver: self
	  name: NSOutlineViewItemDidCollapseNotification
	  object: self];
    }

  [super dealloc];
}

/**
 * Causes the outline column, the column containing the expand/collapse gadget, to
 * resize based on the amount of space needed by widest content.
 */
- (BOOL)autoResizesOutlineColumn
{
  return _autoResizesOutlineColumn;
}

/**
 * Causes the outline column, the column containing the expand/collapse gadget, to
 * resize based on the amount of space needed by widest content.
 */
- (BOOL)autosaveExpandedItems
{
  return _autosaveExpandedItems;
}

// Collect all of the items under a given element.
- (void)_collectItemsStartingWith: (id)startitem
			     into: (NSMutableArray *)allChildren
{
  int num = 0;
  int i = 0;
  id object = nil;

  object = NSMapGet(_itemDict, startitem); 
  num = [object count];
  for(i = 0; i < num; i++)
    {
      id obj = NSMapGet(_itemDict, startitem);
      id anitem = [obj objectAtIndex: i];

      // Only collect the children if the item is expanded
      if([self isItemExpanded: startitem])
	{
	  [allChildren addObject: anitem];
	}

      [self _collectItemsStartingWith: anitem
	    into: allChildren];
    }
}

- (void) _loadDictionaryStartingWith: (id) startitem
			     atLevel: (int) level
{
  int num = [_dataSource outlineView: self
			 numberOfChildrenOfItem: startitem];
  int i = 0;
  id sitem = (startitem == nil)?[NSNull null]:startitem;

  if(num > 0)
    {
      NSMapInsert(_itemDict, sitem, [NSMutableArray array]);
    }

  NSMapInsert(_levelOfItems, sitem, [NSNumber numberWithInt: level]);

  for(i = 0; i < num; i++)
    {
      id anitem = [_dataSource outlineView: self
			       child: i
			       ofItem: startitem];

      id anarray = NSMapGet(_itemDict, sitem); 
      
      [anarray addObject: anitem];
      [self _loadDictionaryStartingWith: anitem
	    atLevel: level + 1]; 
    }
}

- (void)_closeItem: (id)item
{
  int numchildren = 0;
  int i = 0;
  NSMutableArray *removeAll = [NSMutableArray array];

  [self _collectItemsStartingWith: item into: removeAll];
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
  int numchildren = 0;
  int i = 0;
  int insertionPoint = 0;
  id object = nil;
  id sitem = (item == nil)?[NSNull null]:item;

  object = NSMapGet(_itemDict, sitem);
  numchildren = [object count];
  
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
      id obj = NSMapGet(_itemDict, sitem);
      id child = [obj objectAtIndex: i];

      // Add all of the children...
      if([self isItemExpanded: child])
	{
	  NSMutableArray *insertAll = [NSMutableArray array];
	  int i = 0, numitems = 0;

	  [self _collectItemsStartingWith: child into: insertAll];
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

/**
 * Collapses the given item only.  This is the equivalent of calling 
 * [NSOutlineView-collapseItem:collapseChildren:] with NO.
 */
- (void)collapseItem: (id)item
{
  [self collapseItem: item collapseChildren: NO];
}

/**
 * Collapses the specified item.  If collapseChildren is set to YES, then all of the
 * expandable children of this item all also collapsed in a recursive fashion (i.e.
 * all children, grandchildren and etc).
 */
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
      
      // recursively find all children and call this method to open them.
      if(collapseChildren) // collapse all
	{
	  NSMutableArray *allChildren = nil;
	  int numchild = 0;
	  int index = 0;
	  id sitem = (item == nil)?[NSNull null]:item;

	  allChildren = NSMapGet(_itemDict, sitem);
	  numchild = [allChildren count];

	  for(index = 0;index < numchild;index++)
	    {
	      id child = [allChildren objectAtIndex: index];

	      if([self isExpandable: child])
		{
		  [self collapseItem: child collapseChildren: collapseChildren];
		}
	    }
	}
      [self noteNumberOfRowsChanged];
    }
}

/**
 * Expands the given item only.  This is the equivalent of calling 
 * [NSOutlineView-expandItem:expandChildren:] with NO.
 */
- (void)expandItem: (id)item
{
  [self expandItem: item expandChildren: NO];
}

/**
 * Expands the specified item.  If expandChildren is set to YES, then all of the
 * expandable children of this item all also expanded in a recursive fashion (i.e.
 * all children, grandchildren and etc).
 */
- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren
{
  const SEL shouldExpandSelector = @selector(outlineView:shouldExpandItem:);
  BOOL canExpand = YES;

  if([_delegate respondsToSelector: shouldExpandSelector])
    {
      canExpand = [_delegate outlineView: self shouldExpandItem: item];
    }

  // if the item is expandable
  if([self isExpandable: item])
    {
      // if it is not already expanded and it can be expanded, then expand
      if(![self isItemExpanded: item] && canExpand)
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
	}

      // recursively find all children and call this method to open them.
      if(expandChildren) // expand all
	{
	  NSMutableArray *allChildren = nil;
	  int numchild = 0;
	  int index = 0;
	  id sitem = (item == nil)?[NSNull null]:item;

	  allChildren = NSMapGet(_itemDict, sitem);
	  numchild = [allChildren count];

	  for(index = 0;index < numchild;index++)
	    {
	      id child = [allChildren objectAtIndex: index];

	      if([self isExpandable: child])
		{
		  [self expandItem: child expandChildren: expandChildren];
		}
	    }
	}      
    }
  [self noteNumberOfRowsChanged];
}

/**
 * Returns whether or not the indentation marker or "knob" is indented
 * along with the content inside the cell.
 */
- (BOOL)indentationMarkerFollowsCell
{
  return _indentationMarkerFollowsCell;
}

/**
 * Returns the amount of indentation, in points, for each level 
 * of the tree represented by the outline view.
 */
- (float)indentationPerLevel
{
  return _indentationPerLevel;
}

/**
 * Returns YES, if the item is able to be expanded, NO otherwise.
 */
- (BOOL)isExpandable: (id)item
{
  return [_dataSource outlineView: self isItemExpandable: item];
}

/**
 * Returns YES if the item is expanded or open, NO otherwise.
 */
- (BOOL)isItemExpanded: (id)item
{
  if(item == nil)
      return YES;

  // Check the array to determine if it is expanded.
  return([_expandedItems containsObject: item]);
}

/**
 * Returns the item at a given row.
 */
- (id)itemAtRow: (int)row
{
  return [_items objectAtIndex: row];
}

/**
 * Returns the level for a given item.
 */
- (int)levelForItem: (id)item
{
  if(item != nil)
    {
      id object = NSMapGet(_levelOfItems, item);
      return [object intValue];
    }

  return -1;
}

/**
 * Returns the level for the given row.
 */
- (int)levelForRow: (int)row
{
  return [self levelForItem: [self itemAtRow: row]];
}

/**
 * Returns the outline table column.
 */
- (NSTableColumn *)outlineTableColumn
{
  return _outlineTableColumn;
}

- (BOOL)_findItem: (id)item
       childIndex: (int *)index
	 ofParent: (id)parent
{
  NSArray *allKeys = NSAllMapTableKeys(_itemDict);
  BOOL hasChildren = NO;
  NSEnumerator *en = [allKeys objectEnumerator];
  id object = nil;

  // initial values for return parameters
  *index = NSNotFound;
  parent = nil;
  
  if([allKeys containsObject: item])
    {
      hasChildren = YES;
    }
  
  while((object = [en nextObject]))
    {
      NSArray *childArray = NSMapGet(_itemDict, object);

      if((*index = [childArray indexOfObject: item]) != NSNotFound)
	{
	  parent = object;
	  break;
	}
    }

  return hasChildren;
}

/**
 * Causes an item to be reloaded.  This is the equivalent of calling
 * [NSOutlineView-reloadItem:reloadChildren:] with reloadChildren set to NO.
 */
- (void)reloadItem: (id)item
{
  [self reloadItem: item reloadChildren: NO];
}

/**
 * Causes an item and all of it's children to be reloaded if reloadChildren is
 * set to YES, if it's set to NO, then only the item itself is refreshed from the
 * datasource.
 */
- (void)reloadItem: (id)item reloadChildren: (BOOL)reloadChildren
{
  id parent = nil;
  id dsobj = nil;
  BOOL haschildren = NO;
  int index = 0;
  id obj = nil;
  id object = (item == nil)?([NSNull null]):item;

  // find the item
  haschildren = [self _findItem: object
		   childIndex: &index
		   ofParent: parent];

  dsobj = [_dataSource outlineView: self
		       child: index
		       ofItem: parent];
  
  obj = NSMapGet(_itemDict, parent);
  [obj removeObject: item];
  [obj insertObject: dsobj atIndex: index];
  
  if(reloadChildren && haschildren) // expand all
    {
      [self _loadDictionaryStartingWith: object
	    atLevel: [self levelForItem: object]];

      // release the old array
      if(_items != nil)
	{
	  RELEASE(_items); 
	}

      // regenerate the _items array based on the new dictionary
      [self _openItem: nil];
    }      
}

/**
 * Returns the corresponding row in the outline view for the given item.
 */
- (int)rowForItem: (id)item
{
  return [_items indexOfObject: item];
}

/**
 * When set to YES this causes the outline column, the column containing 
 * the expand/collapse gadget, to resize based on the amount of space 
 * needed by widest content.
 */
- (void)setAutoresizesOutlineColumn: (BOOL)resize
{
  _autoResizesOutlineColumn = resize;
}

/**
 * When set to YES, the outline view will save the state of all expanded or 
 * collapsed items in the view to the users defaults for the application the
 * outline view is running in.
 */
- (void)setAutosaveExpandedItems: (BOOL)flag
{
  if(flag == _autosaveExpandedItems)
    {
      return;
    }

  _autosaveExpandedItems = flag;
  if(flag)
    {
      [self _autoloadExpandedItems];
      // notify when an item expands...
      [nc addObserver: self
	  selector: @selector(_autosaveExpandedItems)
	  name: NSOutlineViewItemDidExpandNotification
	  object: self];

      // notify when an item collapses...
      [nc addObserver: self
	  selector: @selector(_autosaveExpandedItems)
	  name: NSOutlineViewItemDidCollapseNotification
	  object: self];
    }
  else
    {
      // notify when an item expands...
      [nc removeObserver: self
	  name: NSOutlineViewItemDidExpandNotification
	  object: self];

      // notify when an item collapses...
      [nc removeObserver: self
	  name: NSOutlineViewItemDidCollapseNotification
	  object: self];
    }
}

/**
 * If set to YES, the indentation marker will follow the content at each level.
 * Otherwise, the indentation marker will remain at the left most position of
 * the view regardless of how many levels in the content is indented.
 */
- (void)setIndentationMarkerFollowsCell: (BOOL)followsCell
{
  _indentationMarkerFollowsCell = followsCell;
}

/**
 * Sets the amount, in points, that each level is to be indented by.
 */
- (void)setIndentationPerLevel: (float)newIndentLevel
{
  _indentationPerLevel = newIndentLevel;
}

/**
 * Sets the outline table column in which to place the indentation marker.
 */
- (void)setOutlineTableColumn: (NSTableColumn *)outlineTableColumn
{
  _outlineTableColumn = outlineTableColumn;
}

/**
 * Returns YES, by default.   Subclasses should override this method if 
 * a different behaviour is required.
 */
- (BOOL)shouldCollapseAutoExpandedItemsForDeposited: (BOOL)deposited
{
  return YES;
}

/**
 * This method returns the number of rows changed in the data source.
 */
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

/**
 * Sets the data source for this outline view. 
 */
- (void) setDataSource: (id)anObject
{
#define CHECK_REQUIRED_METHOD(selector_name) \
  if (anObject && ![anObject respondsToSelector: @selector(selector_name)]) \
    [NSException raise: NSInternalInconsistencyException \
                 format: @"data source does not respond to %@", @#selector_name]

  CHECK_REQUIRED_METHOD(outlineView:child:ofItem:);
  CHECK_REQUIRED_METHOD(outlineView:isItemExpandable:);
  CHECK_REQUIRED_METHOD(outlineView:numberOfChildrenOfItem:);
  CHECK_REQUIRED_METHOD(outlineView:objectValueForTableColumn:byItem:);

  // Is the data source editable?
  _dataSource_editable = [anObject respondsToSelector: 
				     @selector(outlineView:setObjectValue:forTableColumn:byItem:)];

  /* We do *not* retain the dataSource, it's like a delegate */
  _dataSource = anObject;
  [self tile];
  [self reloadData];
}

/**
 * Forces a from scratch reload of all data in the outline view. 
 */
- (void) reloadData
{
  // release the old array
  if(_items != nil)
    {
      RELEASE(_items); 
    }

  if(_itemDict != NULL)
    {
      NSFreeMapTable(_itemDict);
    }

  if(_levelOfItems != NULL)
    {
      NSFreeMapTable(_levelOfItems);
    }

  // create a new empty one
  _items = RETAIN([NSMutableArray array]); 
  _itemDict = NSCreateMapTable(NSObjectMapKeyCallBacks,
			       NSObjectMapValueCallBacks,
			       64);
  _levelOfItems = NSCreateMapTable(NSObjectMapKeyCallBacks,
				   NSObjectMapValueCallBacks,
				   64);

  // reload all the open items...
  [self _loadDictionaryStartingWith: nil
	atLevel: -1];
  [self _openItem: nil];
  [super reloadData];
}

/**
 * Sets the delegate of the outline view. 
 */
- (void) setDelegate: (id)anObject
{
  const SEL sel = @selector(outlineView:willDisplayCell:forTableColumn:item:);
 
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

  _del_responds = [_delegate respondsToSelector: sel];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_autoResizesOutlineColumn];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_indentationMarkerFollowsCell];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_autosaveExpandedItems];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_indentationPerLevel];
  [aCoder encodeConditionalObject: _outlineTableColumn];
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

  _itemDict = NSCreateMapTable(NSObjectMapKeyCallBacks,
			       NSObjectMapValueCallBacks,
			       64);
  _items = [NSMutableArray array];
  _expandedItems = [NSMutableArray array];
  _levelOfItems = NSCreateMapTable(NSObjectMapKeyCallBacks,
				   NSObjectMapValueCallBacks,
				   64); 
  // Retain items
  RETAIN(_items);
  RETAIN(_expandedItems);

  return self;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSTableColumn *tb;
  NSImage *image = nil;

  location = [self convertPoint: location  fromView: nil];
  _clickedRow = [self rowAtPoint: location];
  _clickedColumn = [self columnAtPoint: location];

  if([self isItemExpanded: [self itemAtRow: _clickedRow]])
    {
      image = expanded;
    }
  else
    {
      image = collapsed;
    }
  
  tb = [_tableColumns objectAtIndex: _clickedColumn];
  if(tb == _outlineTableColumn)
    {
      int level = [self levelForRow: _clickedRow];
      int position = 0;
      
      if(_indentationMarkerFollowsCell)
	{
	  position = _indentationPerLevel * level;
	}

      position += _columnOrigins[_clickedColumn];

      if(location.x >= position && location.x <= position + [image size].width)
	{
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

  if(rowIndex >= _numberOfRows)
    {
      return;
    }

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
	  
	  if ([_delegate respondsToSelector: @selector(outlineView:willDisplayCell:forTableColumn:item:)])
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
	      // float originalWidth = drawingRect.size.width;

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
	      
	      if ([_delegate respondsToSelector: @selector(outlineView:willDisplayOutlineCell:forTableColumn:item:)])
		{
		  [_delegate outlineView: self
			     willDisplayOutlineCell: imageCell
			     forTableColumn: tb
			     item: item];
		}

	      [imageCell drawWithFrame: imageRect inView: self];

	      drawingRect.origin.x += indentationFactor + [image size].width + 5;
	      drawingRect.size.width -= indentationFactor + [image size].width + 5;
	      RELEASE(imageCell);
	    }

	  [cell drawWithFrame: drawingRect inView: self];

	}
    }
}

- (void) drawRect: (NSRect)aRect
{
  int index = 0;

  if(_autoResizesOutlineColumn)
    {
      float widest = 0;
      for(index = 0;index < _numberOfRows; index++)
	{
	  float offset = [self levelForRow: index] * 
	    [self indentationPerLevel];
	  NSRect drawingRect = [self frameOfCellAtColumn: 0
				     row: index];
	  float length = drawingRect.size.width + offset;
	  if(widest < length) widest = length;
	}
      // [_outlineTableColumn setWidth: widest];
    }

  [super drawRect: aRect];
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

- (id) _objectValueForTableColumn: (NSTableColumn *)tb
			      row: (int) index
{
  id result = nil;
  id item = [self itemAtRow: index];

  if([_dataSource respondsToSelector:
		    @selector(outlineView:objectValueForTableColumn:byItem:)])
    {
      result = [_dataSource outlineView: self
			    objectValueForTableColumn: tb
			    byItem: item];
    }

  return result;
}

- (void) _setObjectValue: (id)value
	  forTableColumn: (NSTableColumn *)tb
		     row: (int) index
{
  id item = [self itemAtRow: index];
  if([_dataSource respondsToSelector:
		    @selector(outlineView:objectValueForTableColumn:byItem:)])
    {
      [_dataSource outlineView: self
		   setObjectValue: value
		   forTableColumn: tb
		   byItem: item];
    }
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

- (void) draggingExited: (id <NSDraggingInfo>) sender
{
  [self setNeedsDisplayInRect: oldDraggingRect];
  [self displayIfNeeded];
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
	  @selector(outlineView:acceptDrop:item:childIndex:)])
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
	       acceptDrop: sender
	       item: item
	       childIndex: childIndex];
    }
  else
    return NO;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  [self setNeedsDisplayInRect: oldDraggingRect];
  [self displayIfNeeded];

  return YES;
}

// Autosave methods...
- (void) setAutosaveName: (NSString *)name
{
  [super setAutosaveName: name];
  [self _autoloadExpandedItems];
}

- (void) _autosaveExpandedItems
{
  if (_autosaveExpandedItems && _autosaveName != nil) 
    {
      NSUserDefaults      *defaults;
      NSString            *tableKey;

      defaults  = [NSUserDefaults standardUserDefaults];
      tableKey = [NSString stringWithFormat: @"NSOutlineView Expanded Items %@", 
			   _autosaveName];
      [defaults setObject: _expandedItems  forKey: tableKey];
      [defaults synchronize];
    }
}

- (void) _autoloadExpandedItems
{
  if (_autosaveExpandedItems && _autosaveName != nil) 
    { 
      NSUserDefaults     *defaults;
      id                  config;
      NSString           *tableKey;

      defaults  = [NSUserDefaults standardUserDefaults];
      tableKey = [NSString stringWithFormat: @"NSOutlineView Expanded Items %@", 
			   _autosaveName];
      config = [defaults objectForKey: tableKey];
      if (config != nil) 
	{
	  NSEnumerator *en = [config objectEnumerator];
	  id item = nil;
	  
	  while ((item = [en nextObject]) != nil) 
	    {
	      [self expandItem: item];
	    }
	}
    }
}

- (void) editColumn: (int) columnIndex 
		row: (int) rowIndex 
	  withEvent: (NSEvent *) theEvent 
	     select: (BOOL) flag
{
  NSText *t;
  NSTableColumn *tb;
  NSRect drawingRect, imageRect;
  unsigned length = 0;
  id item = nil;
  int level = 0;
  float indentationFactor = 0.0;
  NSImage *image = nil;
  NSCell *imageCell = nil;

  // We refuse to edit cells if the delegate can not accept results 
  // of editing.
  if (_dataSource_editable == NO)
    {
      return;
    }
  
  [self scrollRowToVisible: rowIndex];
  [self scrollColumnToVisible: columnIndex];

  if (rowIndex < 0 || rowIndex >= _numberOfRows 
      || columnIndex < 0 || columnIndex >= _numberOfColumns)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Row/column out of index in edit"];
    }
  
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }

  // Now (_textObject == nil)

  t = [_window fieldEditor: YES  forObject: self];

  if ([t superview] != nil)
    {
      if ([t resignFirstResponder] == NO)
	{
	  return;
	}
    }
  
  _editedRow = rowIndex;
  _editedColumn = columnIndex;
  item = [self itemAtRow: _editedRow];

  // Prepare the cell
  tb = [_tableColumns objectAtIndex: columnIndex];
  // NB: need to be released when no longer used
  _editedCell = [[tb dataCellForRow: rowIndex] copy];

  [_editedCell setEditable: YES];
  [_editedCell setObjectValue: [self _objectValueForTableColumn: tb
				     row: rowIndex]];

  // We really want the correct background color!
  if ([_editedCell respondsToSelector: @selector(setBackgroundColor:)])
    {
      [(NSTextFieldCell *)_editedCell setBackgroundColor: _backgroundColor];
    }
  else
    {
      [t setBackgroundColor: _backgroundColor];
    }
  
  // But of course the delegate can mess it up if it wants
  if (_del_responds)
    {
      [_delegate outlineView: self   
		 willDisplayCell: _editedCell 
		 forTableColumn: tb   
		 item: [self itemAtRow: rowIndex]];
    }

  /* Please note the important point - calling stringValue normally
     causes the _editedCell to call the validateEditing method of its
     control view ... which happens to be this object :-)
     but we don't want any spurious validateEditing to be performed
     before the actual editing is started (otherwise you easily end up
     with the table view picking up the string stored in the field
     editor, which is likely to be the string resulting from the last
     edit somewhere else ... getting into the bug that when you TAB
     from one cell to another one, the string is copied!), so we must
     call stringValue when _textObject is still nil.  */
  if (flag)
    {
      length = [[_editedCell stringValue] length];
    }

  _textObject = [_editedCell setUpFieldEditorAttributes: t];

  // determine which image to use...
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
  // move the drawing rect over like in the drawRow routine...
  drawingRect = [self frameOfCellAtColumn: columnIndex  row: rowIndex];

  [self lockFocus];

  if(tb == [self outlineTableColumn])
    {
      level = [self levelForItem: item];
      indentationFactor = _indentationPerLevel * level;
      drawingRect.origin.x += indentationFactor + 5 + [image size].width;
      drawingRect.size.width -= indentationFactor + 5 + [image size].width;

      // create the image cell..
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
      
      // draw...
      imageRect.size.width = [image size].width;
      imageRect.size.height = [image size].height;
      [imageCell drawWithFrame: imageRect inView: self];
    }

  if (flag)
    {
      [_editedCell selectWithFrame: drawingRect
		   inView: self
		   editor: _textObject
		   delegate: self
		   start: 0
		   length: length];
    }
  else
    {
      [_editedCell editWithFrame: drawingRect
		   inView: self
		   editor: _textObject
		   delegate: self
		   event: theEvent];
    }

  [self unlockFocus];
  return;
}
@end /* implementation of NSOutlineView */

