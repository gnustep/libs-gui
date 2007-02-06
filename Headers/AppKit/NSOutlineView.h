/* 
   NSOutlineView.h

   The outline class.
   
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
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSOutlineView
#define _GNUstep_H_NSOutlineView
#import <GNUstepBase/GSVersionMacros.h>

#include <AppKit/NSTableView.h>
#include <Foundation/NSMapTable.h>

@class NSMutableArray;
@class NSString;

@interface NSOutlineView : NSTableView
{
  NSMapTable *_itemDict;
  NSMutableArray *_items;
  NSMutableArray *_expandedItems;
  NSMutableArray *_selectedItems; /* No longer in use */
  NSMapTable *_levelOfItems;
  BOOL _autoResizesOutlineColumn;
  BOOL _indentationMarkerFollowsCell;
  BOOL _autosaveExpandedItems;
  float _indentationPerLevel;
  NSTableColumn *_outlineTableColumn;
}

// Instance methods
- (BOOL)autoResizesOutlineColumn;
- (BOOL)autosaveExpandedItems;
- (void)collapseItem: (id)item;
- (void)collapseItem: (id)item collapseChildren: (BOOL)collapseChildren;
- (void)expandItem: (id)item;
- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren;
- (BOOL)indentationMarkerFollowsCell;
- (float)indentationPerLevel;
- (BOOL)isExpandable: (id)item;
- (BOOL)isItemExpanded: (id)item;
- (id)itemAtRow: (int)row;
- (int)levelForItem: (id)item;
- (int)levelForRow:(int)row;
- (NSTableColumn *)outlineTableColumn;
- (void)reloadItem: (id)item;
- (void)reloadItem: (id)item reloadChildren: (BOOL)reloadChildren;
- (int)rowForItem: (id)item;
- (void)setAutoresizesOutlineColumn: (BOOL)resize;
- (void)setAutosaveExpandedItems: (BOOL)flag;
- (void)setDropItem:(id)item dropChildIndex: (int)childIndex;
- (void)setIndentationMarkerFollowsCell: (BOOL)followsCell;
- (void)setIndentationPerLevel: (float)newIndentLevel;
- (void)setOutlineTableColumn: (NSTableColumn *)outlineTableColumn;
- (BOOL)shouldCollapseAutoExpandedItemsForDeposited: (BOOL)deposited;

@end /* interface of NSOutlineView */

/** 
 * Informal protocol NSOutlineViewDataSource 
 */
@interface NSObject (NSOutlineViewDataSource)
/**
 * Returns whether or not the outline view should accept a drop 
 * into the indicated item.
 */
- (BOOL)outlineView: (NSOutlineView *)outlineView 
         acceptDrop: (id <NSDraggingInfo>)info 
               item: (id)item 
         childIndex: (int)index;
/**
 * Implementation of this method is required.  Returns the child at 
 * the specified index for the given item.
 */
- (id)outlineView: (NSOutlineView *)outlineView 
            child: (int)index 
           ofItem: (id)item;
/**
 * This is a required method.  Returns whether or not the outline view
 * item specified is expandable or not.
 */
- (BOOL)outlineView: (NSOutlineView *)outlineView
   isItemExpandable: (id)item;

/**
 * Returns the item for the given persistent object.
 */
- (id)outlineView: (NSOutlineView *)outlineView 
itemForPersistentObject:(id)object;

/*
 * This is a required method.  Returns the number of children of
 * the given item.
 */
- (int)outlineView: (NSOutlineView *)outlineView
numberOfChildrenOfItem: (id)item;

/**
 * This is a required method.  Returns the object corresponding to the
 * item representing it in the outline view.
 */
- (id)outlineView: (NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
           byItem:(id)item;

/**
 * Returns the persistent object for the item specified.
 */
- (id)outlineView: (NSOutlineView *)outlineView
persistentObjectForItem: (id)item;

/**
 * Sets the object value of the given item in the given table column to the object provided.
 */
- (void)outlineView: (NSOutlineView *)outlineView 
     setObjectValue: (id)object
     forTableColumn: (NSTableColumn *)tableColumn
             byItem: (id)item;

/**
 * Used by the Drag and Drop system.  Returns the drap operations which was performed on the
 * given outline view.
 */
- (NSDragOperation)outlineView: (NSOutlineView*)outlineView 
                  validateDrop: (id <NSDraggingInfo>)info 
                  proposedItem: (id)item 
            proposedChildIndex: (int)index;

/**
 * Causes the outline view to write the specified items to the pastboard.
 */
- (BOOL)outlineView: (NSOutlineView *)outlineView 
         writeItems: (NSArray*)items 
       toPasteboard: (NSPasteboard*)pboard;
@end

/*
 * Constants
 */
extern int NSOutlineViewDropOnItemIndex;

//enum { NSOutlineViewDropOnItemIndex = -1 };

/*
 * Notifications
 */
APPKIT_EXPORT NSString *NSOutlineViewColumnDidMoveNotification;
APPKIT_EXPORT NSString *NSOutlineViewColumnDidResizeNotification;
APPKIT_EXPORT NSString *NSOutlineViewSelectionDidChangeNotification;
APPKIT_EXPORT NSString *NSOutlineViewSelectionIsChangingNotification;
APPKIT_EXPORT NSString *NSOutlineViewItemDidExpandNotification;
APPKIT_EXPORT NSString *NSOutlineViewItemDidCollapseNotification;
APPKIT_EXPORT NSString *NSOutlineViewItemWillExpandNotification;
APPKIT_EXPORT NSString *NSOutlineViewItemWillCollapseNotification;

/*
 * Methods Implemented by the Delegate
 */
@interface NSObject (NSOutlineViewDelegate)
// notification methods
/**
 * Called after the column has moved.
 */
- (void) outlineViewColumnDidMove: (NSNotification *)aNotification;
/**
 * Called after the view column is resized.
 */
- (void) outlineViewColumnDidResize: (NSNotification *)aNotification;
/**
 * Called after the item has collapsed.
 */
- (void) outlineViewItemDidCollapse: (NSNotification *)aNotification;
/**
 * Called after the item has expanded
 */
- (void) outlineViewItemDidExpand: (NSNotification *)aNotification;
/**
 * Called before the item has collapsed.
 */
- (void) outlineViewItemWillCollapse: (NSNotification *)aNotification;
/**
 * Called before the item is expanded.
 */
- (void) outlineViewItemWillExpand: (NSNotification *)aNotification;
/**
 * Called when the selection has changed.
 */
- (void) outlineViewSelectionDidChange: (NSNotification *)aNotification;
/**
 * Called when the selection is about to change.
 */
- (void) outlineViewSelectionIsChanging: (NSNotification *)aNotification;

// delegate methods
/**
 * Returns whether or not the specified item should be allowed to collapse.
 */
- (BOOL)  outlineView: (NSOutlineView *)outlineView 
   shouldCollapseItem: (id)item;
/**
 * Returns whether or not the given table column should be allowed to be edited.
 */
- (BOOL)  outlineView: (NSOutlineView *)outlineView 
shouldEditTableColumn: (NSTableColumn *)tableColumn
	         item: (id)item;
/**
 * Returns whether or not the specified item should be expanded.
 */
- (BOOL)  outlineView: (NSOutlineView *)outlineView 
     shouldExpandItem: (id)item;
/**
 * Returns YES or NO depending on if the given item is selectable.  If YES, the item is selected,
 * otherwise the outline view will reject the selection.
 */
- (BOOL)  outlineView: (NSOutlineView *)outlineView 
     shouldSelectItem: (id)item;
/**
 * Returns YES or NO depending on if the given table column is selectable according
 * to the delegate.  If NO is returned the outline view will not allow the selection, if YES
 * it will allow the selection.
 */
- (BOOL)  outlineView: (NSOutlineView *)outlineView 
shouldSelectTableColumn: (NSTableColumn *)tableColumn;
/**
 * Called when the given cell is about to be displayed.  This method is
 * useful for making last second modifications to what will be shown. 
 */
- (void)  outlineView: (NSOutlineView *)outlineView 
      willDisplayCell: (id)cell
       forTableColumn: (NSTableColumn *)tableColumn
                 item: (id)item;  
/**
 * Called when the given cell in the outline column is about to be displayed.  This method is
 * useful for making last second modifications to what will be shown.
 */
- (void)  outlineView: (NSOutlineView *)outlineView 
willDisplayOutlineCell: (id)cell
       forTableColumn: (NSTableColumn *)tableColumn
                 item: (id)item;
/**
 * Called before the selection is modified.  This method should return YES if
 * the selection is allowed and NO, if not.
 */
- (BOOL) selectionShouldChangeInOutlineView: (NSOutlineView *)outlineView;
@end

#endif /* _GNUstep_H_NSOutlineView */
