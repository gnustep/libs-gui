/* 
   NSToolbarItemGroup.h

   The toolbar item group class.
   
   Copyright (C) 2008 Free Software Foundation, Inc.

   Author:  Fred Kiefer <fredkiefer@gmx.de>
   Date: Dec 2008
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSIndexSet.h>
#import "AppKit/NSToolbarItemGroup.h"

@interface NSToolbarItemGroup (Private)
- (void) _checkIndex: (NSInteger)index;
@end

@implementation NSToolbarItemGroup
// FIXME: The subitems are not laid out by the toolbar yet.

- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  self = [super initWithItemIdentifier: itemIdentifier];
  if (self != nil)
    {
      _selectedIndexes = [[NSMutableIndexSet alloc] init];
      _selectedIndex = -1;
    }

  return self;
}

- (void) setSubitems: (NSArray *)items
{
  ASSIGN(_subitems, items);
  [_selectedIndexes removeAllIndexes];
  _selectedIndex = -1;
}

- (NSArray *) subitems
{
  if (_subitems == nil)
    {
      return [NSArray array];
    }
  return _subitems;
}

- (NSToolbarItemGroupSelectionMode) selectionMode
{
  return _selectionMode;
}

/* The mode decides what later selection changes do; it leaves any selection
   already made alone. */
- (void) setSelectionMode: (NSToolbarItemGroupSelectionMode)selectionMode
{
  _selectionMode = selectionMode;
}

- (NSToolbarItemGroupControlRepresentation) controlRepresentation
{
  return _controlRepresentation;
}

- (void) setControlRepresentation:
  (NSToolbarItemGroupControlRepresentation)controlRepresentation
{
  _controlRepresentation = controlRepresentation;
}

/* The index selected last, or -1 when nothing has been selected.  Deselecting
   leaves it alone. */
- (NSInteger) selectedIndex
{
  return _selectedIndex;
}

- (void) setSelectedIndex: (NSInteger)selectedIndex
{
  if (selectedIndex == -1)
    {
      return;
    }

  [self _checkIndex: selectedIndex];
  if (_selectionMode == NSToolbarItemGroupSelectionModeMomentary)
    {
      _selectedIndex = selectedIndex;
      return;
    }

  if (_selectionMode == NSToolbarItemGroupSelectionModeSelectOne)
    {
      [_selectedIndexes removeAllIndexes];
    }
  [_selectedIndexes addIndex: selectedIndex];
  _selectedIndex = selectedIndex;
}

- (BOOL) isSelectedAtIndex: (NSInteger)index
{
  [self _checkIndex: index];
  return [_selectedIndexes containsIndex: index];
}

- (void) setSelected: (BOOL)selected atIndex: (NSInteger)index
{
  [self _checkIndex: index];
  if (_selectionMode == NSToolbarItemGroupSelectionModeMomentary)
    {
      return;
    }

  if (selected)
    {
      if (_selectionMode == NSToolbarItemGroupSelectionModeSelectOne)
        {
          [_selectedIndexes removeAllIndexes];
        }
      [_selectedIndexes addIndex: index];
      _selectedIndex = index;
    }
  else if (_selectionMode == NSToolbarItemGroupSelectionModeSelectAny)
    {
      /* A group that selects one is never left with nothing selected. */
      [_selectedIndexes removeIndex: index];
    }
}

- (void) _checkIndex: (NSInteger)index
{
  if (index < 0 || (NSUInteger)index >= [_subitems count])
    {
      [NSException raise: NSRangeException
                  format: @"subitem index %ld out of range 0 to %lu",
        (long)index, (unsigned long)[_subitems count]];
    }
}

- (void) dealloc
{
  RELEASE(_subitems);
  RELEASE(_selectedIndexes);

  [super dealloc];
}

// NSCopying protocol
- (id) copyWithZone: (NSZone *)zone 
{
  NSToolbarItemGroup *new = (NSToolbarItemGroup *)[super copyWithZone: zone];
  
  [new setSubitems: [self subitems]];

  return new;
}

@end

