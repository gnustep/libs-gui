/* 
   NSSearchFieldCell.h
 
   Text field cell class for text search
 
   Copyright (C) 2004 Free Software Foundation, Inc.
 
   Author: H. Nikolaus Schaller <hns@computer.org>
   Date: Dec 2004
 
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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

#ifndef _GNUstep_H_NSSearchFieldCell
#define _GNUstep_H_NSSearchFieldCell

#include <AppKit/NSTextFieldCell.h>

@class NSButtonCell;
@class NSMenu;

enum
{
    NSSearchFieldRecentsTitleMenuItemTag,
    NSSearchFieldRecentsMenuItemTag,
    NSSearchFieldClearRecentsMenuItemTag,
    NSSearchFieldNoRecentsMenuItemTag
};

@interface NSSearchFieldCell : NSTextFieldCell
{
    NSArray *_recent_searches;
    NSString *_recents_autosave_name;
    NSButtonCell *_search_button_cell;
    NSButtonCell *_cancel_button_cell;
    NSMenu *_menu_template;
    BOOL _sends_whole_search_string;
    BOOL _sends_search_string_immediatly;
    unsigned char _max_recents;
}

// Managing button cells
- (NSButtonCell *) cancelButtonCell;
- (void) setCancelButtonCell: (NSButtonCell *)cell;
- (void) resetCancelButtonCell;
- (NSButtonCell *) searchButtonCell;
- (void) setSearchButtonCell: (NSButtonCell *)cell;
- (void) resetSearchButtonCell;

// Custom layout
- (NSRect) cancelButtonRectForBounds: (NSRect)rect;
- (NSRect) searchButtonRectForBounds: (NSRect)rect;
- (NSRect) searchTextRectForBounds: (NSRect)rect;

// template
- (NSMenu *) searchMenuTemplate;
- (void) setSearchMenuTemplate: (NSMenu *)menu;

// search mode
- (BOOL) sendsWholeSearchString;
- (void) setSendsWholeSearchString: (BOOL)flag;
- (BOOL) sendsSearchStringImmediately;
- (void) setSendsSearchStringImmediately: (BOOL)flag;

// search results
- (int) maximumRecents;
- (void) setMaximumRecents: (int)max;
- (NSArray *) recentSearches;
- (NSString *) recentsAutosaveName;
- (void) setRecentSearches: (NSArray *)searches;
- (void) setRecentsAutosaveName: (NSString *)name;

@end

#endif /* _GNUstep_H_NSSearchFieldCell */
