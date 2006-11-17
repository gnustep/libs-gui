/* 
   NSToolbar.h

   The toolbar class.
   
   Copyright (C) 2002 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>,
            Fabien Vallon <fabien.vallon@fr.alcove.com>,
	    Quentin Mathe <qmathe@club-internet.fr>
   Date: May 2002
   
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
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSToolbar
#define _GNUstep_H_NSToolbar

#include "GNUstepGUI/GSToolbar.h"

@interface NSToolbar : GSToolbar
{
  NSWindow *_window;
  BOOL _visible;
}

// Accessors

- (BOOL) isVisible;
- (void) setDisplayMode: (NSToolbarDisplayMode)displayMode;
- (void) setSizeMode: (NSToolbarSizeMode)sizeMode;
- (void) setVisible: (BOOL)shown;

@end /* interface of NSToolbar */

/*
 * Methods Implemented by the Delegate
 */
@interface NSObject (NSToolbarDelegate)

// delegate methods
// required method
- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag;
// required method
- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar;
// required method
- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar;
// optional method
- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar;
@end

#endif /* _GNUstep_H_NSToolbar */
