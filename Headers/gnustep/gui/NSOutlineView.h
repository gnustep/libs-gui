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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSOutlineView
#define _GNUstep_H_NSOutlineView

#include <AppKit/NSTableView.h>

@interface NSOutlineView : NSTableView
{
  BOOL _resize;
  BOOL _followsCell;
  BOOL _autosave;
  float _indentLevel;
  NSTableColumn *_outlineTableColumn;
  BOOL _shouldCollapse;
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
- (void)setDropItem:(id)item dropChildIndex: (int)index;
- (void)setIndentationMarkerFollowsCell: (BOOL)followsCell;
- (void)setIndentationPerLevel: (float)newIndentLevel;
- (void)setOutlineTableColumn: (NSTableColumn *)outlineTableColumn;
- (BOOL)shouldCollapseAutoExpandedItemsForDeposited: (BOOL)deposited;

@end /* interface of NSTableView */

/* 
 * Informal protocol NSOutlineViewDataSource 
 */
@interface NSObject (NSOutlineViewDataSource)
- (BOOL)outlineView: (NSOutlineView *)outlineView 
         acceptDrop: (id <NSDraggingInfo>)info 
               item: (id)item 
         childIndex: (int)index;

- (id)outlineView: (NSOutlineView *)outlineView 
            child: (int)index 
           ofItem:(id)item;

- (BOOL)outlineView: (NSOutlineView *)outlineView
   isItemExpandable: (id)item;

- (id)outlineView: (NSOutlineView *)outlineView 
itemForPersistentObject:(id)object;

- (int)outlineView: (NSOutlineView *)outlineView
numberOfChildrenOfItem: (id)item;

- (id)outlineView: (NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
           byItem:(id)item;

- (id)outlineView: (NSOutlineView *)outlineView
persistentObjectForItem: (id)item;

- (void)outlineView: (NSOutlineView *)outlineView 
      setObjectView: (id)object
     forTableColumn: (NSTableColumn *)tableColumn;

- (NSDragOperation)outlineView: (NSOutlineView*)outlineView 
                  validateDrop: (id <NSDraggingInfo>)info 
                  proposedItem: (id)item proposedChildIndex:(int)index;

- (BOOL)outlineView: (NSOutlineView *)outlineView 
         writeItems: (NSArray*)items 
       toPasteboard: (NSPasteboard*)pboard;
@end

/*
 * Constants
 */
enum { NSOutlineViewDropOnItemIndex = -1 };

/*
 * Notifications
 */
APPKIT_EXPORT NSString *NSOutlineViewColumnDidMoveNotification;
APPKIT_EXPORT NSString *NSOutlineViewColumnDidResizeNotification;
APPKIT_EXPORT NSString *NSOutlineViewSelectionDidChangeNotification;
APPKIT_EXPORT NSString *NSOutlineViewSelectionIsChangingNotification;
APPKIT_EXPORT NSString *NSOutlineViewItemDidExpandNotification;
APPKIT_EXPORT NSString *NSOutlineViewItemDidCollapseNotification;

/*
 * Methods Implemented by the Delegate
 */
@interface NSObject (NSOutlineViewDelegate)

- (BOOL)  outlineView: (NSOutlineView *)aOutlineView 
shouldEditTableColumn: (NSTableColumn *)aTableColumn 
	          row: (int)rowIndex;
- (BOOL)  outlineView: (NSOutlineView *)aOutlineView 
      shouldSelectRow: (int)rowIndex;
- (BOOL)  outlineView: (NSOutlineView *)aOutlineView 
shouldSelectTableColumn: (NSTableColumn *)aTableColumn;
- (void)  outlineView: (NSOutlineView *)aOutlineView 
      willDisplayCell: (id)aCell 
       forTableColumn: (NSTableColumn *)aTableColumn
	          row: (int)rowIndex;
- (void) outlineViewColumnDidMove: (NSNotification *)aNotification;
- (void) outlineViewColumnDidResize: (NSNotification *)aNotification;
- (void) outlineViewSelectionDidChange: (NSNotification *)aNotification;
- (void) outlineViewSelectionIsChanging: (NSNotification *)aNotification;
- (void) outlineViewItemDidExpand: (NSNotification *)aNotification;
- (void) outlineViewItemDidCollapse: (NSNotification *)aNotification;
@end

#endif /* _GNUstep_H_NSOutlineView */
