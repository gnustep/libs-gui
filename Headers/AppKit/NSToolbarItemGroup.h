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

#ifndef _GNUstep_H_NSToolbarItemGroup
#define _GNUstep_H_NSToolbarItemGroup
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSToolbarItem.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)

@class NSArray;
@class NSMutableIndexSet;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST)
enum {
  NSToolbarItemGroupSelectionModeSelectOne = 0,
  NSToolbarItemGroupSelectionModeSelectAny = 1,
  NSToolbarItemGroupSelectionModeMomentary = 2
};
typedef NSInteger NSToolbarItemGroupSelectionMode;

enum {
  NSToolbarItemGroupControlRepresentationAutomatic = 0,
  NSToolbarItemGroupControlRepresentationExpanded = 1,
  NSToolbarItemGroupControlRepresentationCollapsed = 2
};
typedef NSInteger NSToolbarItemGroupControlRepresentation;
#endif

APPKIT_EXPORT_CLASS
@interface NSToolbarItemGroup : NSToolbarItem
{
	NSArray *_subitems;
	NSMutableIndexSet *_selectedIndexes;
	NSInteger _selectionMode;
	NSInteger _controlRepresentation;
	NSInteger _selectedIndex;
}

- (void) setSubitems: (NSArray *)items;
- (NSArray *) subitems;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST)
- (NSToolbarItemGroupSelectionMode) selectionMode;
- (void) setSelectionMode: (NSToolbarItemGroupSelectionMode)selectionMode;

- (NSToolbarItemGroupControlRepresentation) controlRepresentation;
- (void) setControlRepresentation:
  (NSToolbarItemGroupControlRepresentation)controlRepresentation;

- (NSInteger) selectedIndex;
- (void) setSelectedIndex: (NSInteger)selectedIndex;

- (BOOL) isSelectedAtIndex: (NSInteger)index;
- (void) setSelected: (BOOL)selected atIndex: (NSInteger)index;
#endif

@end

#endif
#endif /* _GNUstep_H_NSToolbarItemGroup */
