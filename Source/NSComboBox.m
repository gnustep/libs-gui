/*
   NSComboBox.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Gerrit van Dyk <gerritvd@decillion.net>
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

#import <AppKit/AppKit.h>

@interface NSObject(MouseUpping)
- (NSEvent *)_mouseUpEvent;
@end

@implementation NSComboBox

+ (void)initialize
{
   if (self == [NSComboBox class])
      [self setCellClass:[NSComboBoxCell class]];
}

- (NSComboBoxCell *)comboCell
{
   return (NSComboBoxCell *)[self cell];
}

- (BOOL)hasVerticalScroller
{
   return [[self comboCell] hasVerticalScroller];
}

- (void)setHasVerticalScroller:(BOOL)flag
{
   [[self comboCell] setHasVerticalScroller:flag];
}

- (NSSize)intercellSpacing
{
   return [[self comboCell] intercellSpacing];
}

- (void)setIntercellSpacing:(NSSize)aSize
{
   [[self comboCell] setIntercellSpacing:aSize];
}

- (float)itemHeight
{
   return [[self comboCell] itemHeight];
}

- (void)setItemHeight:(float)itemHeight
{
   [[self comboCell] setItemHeight:itemHeight];
}

- (int)numberOfVisibleItems
{
   return [[self comboCell] numberOfVisibleItems];
}

- (void)setNumberOfVisibleItems:(int)visibleItems
{
   [[self comboCell] setNumberOfVisibleItems:visibleItems];
}

- (void)reloadData
{
   [[self comboCell] reloadData];
}

- (void)noteNumberOfItemsChanged
{
   [[self comboCell] noteNumberOfItemsChanged];
}

- (BOOL)usesDataSource
{
   return [[self comboCell] usesDataSource];
}

- (void)setUsesDataSource:(BOOL)flag
{
   [[self comboCell] setUsesDataSource:flag];
}

- (void)scrollItemAtIndexToTop:(int)index
{
   [[self comboCell] scrollItemAtIndexToTop:index];
}

- (void)scrollItemAtIndexToVisible:(int)index
{
   [[self comboCell] scrollItemAtIndexToVisible:index];
}

- (void)selectItemAtIndex:(int)index
{
   [[self comboCell] selectItemAtIndex:index];
}

- (void)deselectItemAtIndex:(int)index
{
   [[self comboCell] deselectItemAtIndex:index];
}

- (int)indexOfSelectedItem
{
   return [[self comboCell] indexOfSelectedItem];
}

- (int)numberOfItems
{
   return [[self comboCell] numberOfItems];
}

- (id)dataSource
{
   return [[self comboCell] dataSource];
}

- (void)setDataSource:(id)aSource
{
   [[self comboCell] setDataSource:aSource];
}

- (void)addItemWithObjectValue:(id)object
{
   [[self comboCell] addItemWithObjectValue:object];
}

- (void)addItemsWithObjectValues:(NSArray *)objects
{
   [[self comboCell] addItemsWithObjectValues:objects];
}

- (void)insertItemWithObjectValue:(id)object atIndex:(int)index
{
   [[self comboCell] insertItemWithObjectValue:object atIndex:index];
}

- (void)removeItemWithObjectValue:(id)object
{
   [[self comboCell] removeItemWithObjectValue:object];
}

- (void)removeItemAtIndex:(int)index
{
   [[self comboCell] removeItemAtIndex:index];
}

- (void)removeAllItems
{
   [[self comboCell] removeAllItems];
}

- (void)selectItemWithObjectValue:(id)object
{
   [[self comboCell] selectItemWithObjectValue:object];
}

- (id)itemObjectValueAtIndex:(int)index
{
   return [[self comboCell] itemObjectValueAtIndex:index];
}

- (id)objectValueOfSelectedItem
{
   return [[self comboCell] objectValueOfSelectedItem];
}

- (int)indexOfItemWithObjectValue:(id)object
{
   return [[self comboCell] indexOfItemWithObjectValue:object];
}

- (NSArray *)objectValues
{
   return [[self comboCell] objectValues];
}

// Overridden
- (void)mouseDown:(NSEvent *)theEvent
{
   id		aCell;
   NSEvent	*cEvent;

   aCell = [self cell];
   [aCell trackMouse:theEvent inRect:[self bounds]
	  ofView:self untilMouseUp:YES];
   if ([aCell respondsToSelector: @selector(_mouseUpEvent)])
      cEvent = [aCell _mouseUpEvent];
   else
      cEvent = nil;
   if ([aCell isSelectable])
   {
      if (!cEvent)
	 cEvent = [NSApp currentEvent];
      if ([cEvent type] == NSLeftMouseUp &&
	  ([cEvent windowNumber] == [[self window] windowNumber]))
	 [NSApp postEvent:cEvent atStart:NO];
      [super mouseDown:theEvent];
   }
}

@end

NSString *NSComboBoxWillPopUpNotification = @"NSComboBoxWillPopUpNotification";
NSString *NSComboBoxWillDismissNotification = @"NSComboBoxWillDismissNotification";
NSString *NSComboBoxSelectionDidChangeNotification = @"NSComboBoxSelectionDidChangeNotification";
NSString *NSComboBoxSelectionIsChangingNotification = @"NSComboBoxSelectionIsChangingNotification";
