/* -*-objc-*-
   NSDrawer.h

   The drawer class

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Fred Kiefer <FredKiefer@gmx.de>
   Date: 2001
   
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

#ifndef _GNUstep_H_NSDrawer
#define _GNUstep_H_NSDrawer

#include <Foundation/NSGeometry.h>
#include <AppKit/NSResponder.h>

@class NSWindow;
@class NSView;

enum {
  NSDrawerClosedState,
  NSDrawerOpeningState,
  NSDrawerOpenState,
  NSDrawerClosingState
};

@interface NSDrawer : NSResponder
{
  // Attributes
  id _delegate;
  NSView *_contentView;
  NSWindow *_parentWindow;
  NSRectEdge _preferredEdge;
  NSRectEdge _currentEdge;
  NSSize _maxContentSize;
  NSSize _minContentSize;
  float _leadingOffset;
  float _trailingOffset;
  int _state;
}

// Creation
- (id) initWithContentSize: (NSSize)contentSize 
	     preferredEdge: (NSRectEdge)edge;

// Opening and Closing
- (void) close;
- (void) close: (id)sender;
- (void) open;
- (void) open: (id)sender;
- (void) openOnEdge: (NSRectEdge)edge;
- (void) toggle: (id)sender;

// Managing Size
- (NSSize) contentSize;
- (float) leadingOffset;
- (NSSize) maxContentSize;
- (NSSize) minContentSize;
- (void) setContentSize: (NSSize)size;
- (void) setLeadingOffset: (float)offset;
- (void) setMaxContentSize: (NSSize)size;
- (void) setMinContentSize: (NSSize)size;
- (void) setTrailingOffset: (float)offset;
- (float) trailingOffset;

// Managing Edge
- (NSRectEdge) edge;
- (NSRectEdge) preferredEdge;
- (void) setPreferredEdge: (NSRectEdge)preferredEdge;

// Managing Views
- (NSView *) contentView;
- (NSWindow *) parentWindow;
- (void) setContentView: (NSView *)aView;
- (void) setParentWindow: (NSWindow *)parent;
 
// Delegation and State
- (id) delegate;
- (void) setDelegate: (id)anObject;
- (int) state;

@end

@interface NSDrawerDelegate
- (BOOL) drawerShouldClose: (NSDrawer *)sender;
- (BOOL) drawerShouldOpen: (NSDrawer *)sender;
- (NSSize) drawerWillResizeContents: (NSDrawer *)sender 
			    toSize: (NSSize)contentSize;
- (void) drawerDidClose: (NSNotification *)notification;
- (void) drawerDidOpen: (NSNotification *)notification;
- (void) drawerWillClose: (NSNotification *)notification;
- (void) drawerWillOpen: (NSNotification *)notification;
@end

// Notifications
APPKIT_EXPORT NSString *NSDrawerDidCloseNotification;
APPKIT_EXPORT NSString *NSDrawerDidOpenNotification;
APPKIT_EXPORT NSString *NSDrawerWillCloseNotification;
APPKIT_EXPORT NSString *NSDrawerWillOpenNotification;

#endif // _GNUstep_H_NSDrawer

