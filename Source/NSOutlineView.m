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

#include <AppKit/NSOutlineView.h>

@implementation NSOutlineView

// Instance methods
- (id)init
{
  [super init];
  _resize = NO;
  _followsCell = NO;
  _autosave = NO;
  _indentLevel = 0.0;
  _outlineTableColumn = nil;
  _shouldCollapse = NO;

  return self;
}

- (BOOL)autoResizesOutlineColumn
{
  return _resize;
}

- (BOOL)autosaveExpandedItems
{
  return _autosave;
}

- (void)collapseItem: (id)item
{
  // Nothing yet...
}

- (void)collapseItem: (id)item collapseChildren: (BOOL)collapseChildren
{
  // Nothing yet...
}

- (void)expandItem: (id)item
{
  // Nothing yet...
}

- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren
{
  // Nothing yet...
}

- (BOOL)indentationMarkerFollowsCell
{
  return _followsCell;
}

- (float)indentationPerLevel
{
  return _indentLevel;
}

- (BOOL)isExpandable: (id)item
{
  // Nothing yet...
  return NO;
}

- (BOOL)isItemExpanded: (id)item
{
  // Nothing yet...
  return NO;
}

- (id)itemAtRow: (int)row
{
  // Nothing yet...
  return nil;
}

- (int)levelForItem: (id)item
{
  // Nothing yet...
  return -1;
}

- (int)levelForRow: (int)row
{
  // Nothing yet...
  return -1;
}

- (NSTableColumn *)outlineTableColumn
{
  return _outlineTableColumn;
}

- (void)reloadItem: (id)item
{
  // Nothing yet...
}

- (void)reloadItem: (id)item reloadChildren: (BOOL)reloadChildren
{
  // Nothing yet...
}

- (int)rowForItem: (id)item
{
  // Nothing yet...
  return -1;
}

- (void)setAutoresizesOutlineColumn: (BOOL)resize
{
  _resize = resize;
}

- (void)setAutosaveExpandedItems: (BOOL)flag
{
  _autosave = flag;
}

- (void)setDropItem:(id)item dropChildIndex: (int)index
{
  // Nothing yet...
}

- (void)setIndentationMarkerFollowsCell: (BOOL)followsCell
{
  _followsCell = followsCell;
}

- (void)setIndentationPerLevel: (float)newIndentLevel
{
  _indentLevel = newIndentLevel;
}

- (void)setOutlineTableColumn: (NSTableColumn *)outlineTableColumn
{
  _outlineTableColumn = outlineTableColumn;
}

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited: (BOOL)deposited
{
  return _shouldCollapse;
}

@end /* implementation of NSTableView */

