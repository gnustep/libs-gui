/*
   NSComboBox.h

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

#ifndef _GNUstep_H_NSComboBox
#define _GNUstep_H_NSComboBox

#include <Foundation/NSNotification.h>
#include <AppKit/NSTextField.h>

@interface NSComboBox : NSTextField
{
}

- (BOOL)hasVerticalScroller;
- (void)setHasVerticalScroller:(BOOL)flag;

- (NSSize)intercellSpacing;
- (void)setIntercellSpacing:(NSSize)aSize;

- (float)itemHeight;
- (void)setItemHeight:(float)itemHeight;

- (int)numberOfVisibleItems;
- (void)setNumberOfVisibleItems:(int)visibleItems;

- (void)reloadData;
- (void)noteNumberOfItemsChanged;

- (BOOL)usesDataSource;
- (void)setUsesDataSource:(BOOL)flag;

- (void)scrollItemAtIndexToTop:(int)index;
- (void)scrollItemAtIndexToVisible:(int)index;

- (void)selectItemAtIndex:(int)index;
- (void)deselectItemAtIndex:(int)index;
- (int)indexOfSelectedItem;
- (int)numberOfItems;

/* These two methods can only be used when usesDataSource is YES */
- (id)dataSource;
- (void)setDataSource:(id)aSource;

/* These methods can only be used when usesDataSource is NO */
- (void)addItemWithObjectValue:(id)object;
- (void)addItemsWithObjectValues:(NSArray *)objects;
- (void)insertItemWithObjectValue:(id)object atIndex:(int)index;
- (void)removeItemWithObjectValue:(id)object;
- (void)removeItemAtIndex:(int)index;
- (void)removeAllItems;
- (void)selectItemWithObjectValue:(id)object;
- (id)itemObjectValueAtIndex:(int)index;
- (id)objectValueOfSelectedItem;
- (int)indexOfItemWithObjectValue:(id)object;
- (NSArray *)objectValues;

#ifndef	STRICT_OPENSTEP
/* text completion */
- (void)setCompletes:(BOOL)completes;
- (BOOL)completes;
#endif

@end

@interface NSObject (NSComboBoxDataSource)
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index;
- (unsigned int)comboBox:(NSComboBox *)aComboBox
indexOfItemWithStringValue:(NSString *)string;
#ifndef	STRICT_OPENSTEP
/* text completion */
- (NSString *)comboBox:(NSComboBox *)aComboBox 
       completedString:(NSString *)aString;
#endif
@end

@interface NSObject (NSComboBoxNotifications)
- (void)comboBoxWillPopUp:(NSNotification *)notification;
- (void)comboBoxWillDismiss:(NSNotification *)notification;
- (void)comboBoxSelectionDidChange:(NSNotification *)notification;
- (void)comboBoxSelectionIsChanging:(NSNotification *)notification;
@end

NSString *NSComboBoxWillPopUpNotification;
NSString *NSComboBoxWillDismissNotification;
NSString *NSComboBoxSelectionDidChangeNotification;
NSString *NSComboBoxSelectionIsChangingNotification;

#endif /* _GNUstep_H_NSComboBox */
