/** <title>NSComboBox</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Gerrit van Dyk <gerritvd@decillion.net>
   Date: 1999

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

#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSComboBox.h>
#include <AppKit/NSComboBoxCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>

@interface NSObject(MouseUpping)
- (NSEvent *)_mouseUpEvent;
@end

/*
 * Class variables
 */
static Class usedCellClass;
static Class comboBoxCellClass;
static NSNotificationCenter *nc;


@implementation NSComboBox

+ (void)initialize
{
  if (self == [NSComboBox class])
    {
       [self setVersion: 1];
       comboBoxCellClass = [NSComboBoxCell class];
       usedCellClass = comboBoxCellClass;
       nc = [NSNotificationCenter defaultCenter];
    }
}

/*
 * Setting the Cell class
 */
+ (Class) cellClass
{
  return usedCellClass;
}

+ (void) setCellClass: (Class)factoryId
{
  usedCellClass = factoryId ? factoryId : comboBoxCellClass;
}


- (BOOL)hasVerticalScroller
{
  return [_cell hasVerticalScroller];
}

- (void)setHasVerticalScroller:(BOOL)flag
{
  [_cell setHasVerticalScroller:flag];
}

- (NSSize)intercellSpacing
{
  return [_cell intercellSpacing];
}

- (void)setIntercellSpacing:(NSSize)aSize
{
  [_cell setIntercellSpacing:aSize];
}

- (float)itemHeight
{
  return [_cell itemHeight];
}

- (void)setItemHeight:(float)itemHeight
{
  [_cell setItemHeight:itemHeight];
}

- (int)numberOfVisibleItems
{
  return [_cell numberOfVisibleItems];
}

- (void)setNumberOfVisibleItems:(int)visibleItems
{
  [_cell setNumberOfVisibleItems:visibleItems];
}

- (void)reloadData
{
  [_cell reloadData];
}

- (void)noteNumberOfItemsChanged
{
  [_cell noteNumberOfItemsChanged];
}

- (BOOL)usesDataSource
{
  return [_cell usesDataSource];
}

- (void)setUsesDataSource:(BOOL)flag
{
  [_cell setUsesDataSource:flag];
}

- (void)scrollItemAtIndexToTop:(int)index
{
  [_cell scrollItemAtIndexToTop:index];
}

- (void)scrollItemAtIndexToVisible:(int)index
{
  [_cell scrollItemAtIndexToVisible:index];
}

- (void)selectItemAtIndex:(int)index
{
  [_cell selectItemAtIndex:index];
}

- (void)deselectItemAtIndex:(int)index
{
  [_cell deselectItemAtIndex:index];
}

- (int)indexOfSelectedItem
{
  return [_cell indexOfSelectedItem];
}

- (int)numberOfItems
{
  return [_cell numberOfItems];
}

- (id)dataSource
{
  return [_cell dataSource];
}

- (void)setDataSource:(id)aSource
{
  [_cell setDataSource:aSource];
}

- (void)addItemWithObjectValue:(id)object
{
  [_cell addItemWithObjectValue:object];
}

- (void)addItemsWithObjectValues:(NSArray *)objects
{
  [_cell addItemsWithObjectValues:objects];
}

- (void)insertItemWithObjectValue:(id)object atIndex:(int)index
{
  [_cell insertItemWithObjectValue:object atIndex:index];
}

- (void)removeItemWithObjectValue:(id)object
{
  [_cell removeItemWithObjectValue:object];
}

- (void)removeItemAtIndex:(int)index
{
  [_cell removeItemAtIndex:index];
}

- (void)removeAllItems
{
  [_cell removeAllItems];
}

- (void)selectItemWithObjectValue:(id)object
{
  [_cell selectItemWithObjectValue:object];
}

- (id)itemObjectValueAtIndex:(int)index
{
  return [_cell itemObjectValueAtIndex:index];
}

- (id)objectValueOfSelectedItem
{
  return [_cell objectValueOfSelectedItem];
}

- (int)indexOfItemWithObjectValue:(id)object
{
  return [_cell indexOfItemWithObjectValue:object];
}

- (NSArray *)objectValues
{
  return [_cell objectValues];
}

- (void)setCompletes:(BOOL)completes
{
  [_cell setCompletes: completes];
}

- (BOOL)completes
{
  return [_cell completes];
}

- (void) setDelegate: (id)anObject
{
  [super setDelegate: anObject];

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(comboBox##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(comboBox##notif_name:) \
      name: NSComboBox##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(SelectionDidChange);
  SET_DELEGATE_NOTIFICATION(SelectionIsChanging);
  SET_DELEGATE_NOTIFICATION(WillPopUp);
  SET_DELEGATE_NOTIFICATION(WillDismiss);
}

// Overridden
- (void)mouseDown:(NSEvent *)theEvent
{
  NSEvent *cEvent;

  [_cell trackMouse: theEvent inRect: [self bounds]
	 ofView: self untilMouseUp: YES];
  if ([_cell respondsToSelector: @selector(_mouseUpEvent)])
    cEvent = [_cell _mouseUpEvent];
  else
    cEvent = nil;
  if ([_cell isSelectable])
    {
      if (!cEvent)
	cEvent = [NSApp currentEvent];
      if ([cEvent type] == NSLeftMouseUp &&
	  ([cEvent windowNumber] == [[self window] windowNumber]))
	[NSApp postEvent: cEvent atStart: NO];
      [super mouseDown: theEvent];
    }
}

@end
