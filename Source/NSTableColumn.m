/*
   NSTableColumn.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Michael Hanni  <mhanni@sprintmail.com>
   Date: 1999
   First Implementation.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999
   Completely Rewritten.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/NSNotification.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>

@implementation NSTableColumn
{
}

/*
 *
 * Class methods
 *
 */
+ (void) initialize
{
  if (self == [NSTableColumn class])
    [self setVersion: 1];
}

/*
 *
 * Instance methods
 *
 */

/* 
 * Initializing an NSTableColumn instance 
 */
- (NSTableColumn*)initWithIdentifier: (id)anObject
{
  self = [super init];
  _width = 0;
  _min_width = 0;
  _max_width = 100000;
  _is_resizable = YES;
  _is_editable = NO;
  _tableView = nil;

  _headerCell = [NSTableHeaderCell new];
  _dataCell = [NSTextFieldCell new];
  // TODO: When things start to work with the other NSTable* classes, 
  // set here default properties for the default cells to have them 
  // display with the default table appearance.

  ASSIGN (_identifier, anObject);
  return self;
}
- (void)dealloc
{
  [_headerCell release];
  [_dataCell release];
  TEST_RELEASE (_identifier);
  [super dealloc];
}
/*
 * Managing the Identifier
 */
- (void)setIdentifier: (id)anObject
{
  ASSIGN (_identifier, anObject);
}
- (id)identifier
{
  return _identifier;
}
/*
 * Setting the NSTableView 
 */
- (void)setTableView: (NSTableView*)aTableView
{
  // We do *not* RETAIN aTableView. 
  // On the contrary, aTableView is supposed to RETAIN us.
  _tableView = aTableView;
}
- (NSTableView *)tableView
{
  return _tableView;
}
/*
 * Controlling size 
 */
- (void)setWidth: (float)newWidth
{
  if (newWidth > _max_width)
    newWidth = _max_width;
  else if (newWidth < _min_width)
    newWidth = _min_width;

  _width = newWidth;
  
  if (_tableView)
    {
      [_tableView setNeedsDisplay: YES];
      
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: NSTableViewColumnDidResizeNotification
	object: _tableView];
    }
}
- (float)width
{
  return _width;
}
- (void)setMinWidth: (float)minWidth
{
  _min_width = minWidth;
  if (_width < _min_width)
    [self setWidth: _min_width];
}
- (float)minWidth
{
  return _min_width;
}
- (void)setMaxWidth: (float)maxWidth
{
  _max_width = maxWidth;
  if (_width > _max_width)
    [self setWidth: _max_width];
}
- (float)maxWidth
{
  return _max_width;
}
- (void)setResizable: (BOOL)flag
{
  _is_resizable = flag;
}
- (BOOL)isResizable
{
  return _is_resizable;
}
- (void)sizeToFit
{
  float new_width;

  new_width = [_headerCell cellSize].width;

  if (new_width > _max_width)
    _max_width = new_width;

  if (new_width < _min_width)
    _min_width = new_width;
  
  // For easier subclassing we dont do it directly
  [self setWidth: new_width];
}
/*
 * Controlling editability 
 */
- (void)setEditable: (BOOL)flag
{
  _is_editable = flag;
}
- (BOOL)isEditable
{
  return _is_editable;
}
/*
 * Setting component cells 
 */
- (void)setHeaderCell: (NSCell*)aCell
{
  if (aCell == nil)
    {
      NSLog (@"Attempt to set a nil headerCell for NSTableColumn");
      return;
    }
  ASSIGN (_headerCell, aCell);
}
- (NSCell*)headerCell
{
  return _headerCell;
}
- (void)setDataCell: (NSCell*)aCell
{
  if (aCell == nil)
    {
      NSLog (@"Attempt to set a nil dataCell for NSTableColumn");
      return;
    }
  ASSIGN (_dataCell, aCell);
}
- (NSCell*)dataCell
{
  return _dataCell;
}
@end
