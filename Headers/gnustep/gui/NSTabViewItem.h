/*
   NSTabViewItem.h
   
   Copyright (C) 1996 Free Software Foundation, Inc.
  
   Author:  Michael Hanni <mhanni@sprintmail.com>
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

#ifndef _GNUstep_H_NSTabViewItem
#define _GNUstep_H_NSTabViewItem

#include <AppKit/NSTabView.h>

typedef enum {
  NSSelectedTab = 0,
  NSBackgroundTab,
  NSPressedTab
} NSTabState;

@class NSColor;

@interface NSTabViewItem : NSObject <NSCoding>
{
  id item_ident;
  NSString *item_label;
  NSView *item_view;
  NSColor *item_color;
  NSTabState item_state;
  NSTabView *item_tabview;
}
- (id) initWithIdentifier:(id)identifier;

- (void)setIdentifier:(id)identifier;
- (id)identifier;

- (void)setLabel:(NSString *)label;
- (NSString *)label;
- (NSSize)sizeOfLabel:(BOOL)shouldTruncateLabel;

- (void)setView:(NSView *)view;
- (NSView *)view;

- (void)setColor:(NSColor *)color;
- (NSColor *)color;

- (NSTabState)tabState;
- (NSTabView *)tabView;

- (void)setInitialFirstResponder:(NSView *)view;
- (id)initialFirstResponder;

- (void)drawLabel:(BOOL)shouldTruncateLabel
           inRect:(NSRect)tabRect;

- (void) encodeWithCoder: (NSCoder*)aCoder;
- (id) initWithCoder: (NSCoder*)aDecoder;
@end

#endif // _GNUstep_H_NSTabViewItem

