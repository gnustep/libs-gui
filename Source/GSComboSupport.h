/*
   GSComboSupport.h

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

#ifndef _GNUstep_H_GSComboSupport
#define _GNUstep_H_GSComboSupport

#include <AppKit/NSWindow.h>

@class NSArray;
@class NSBrowser;
@class NSComboBoxCell;
@class NSMatrix;

@interface GSComboWindow : NSWindow
{
   NSBrowser	*browser;

@private;
   NSArray	*list;
   NSComboBoxCell *_cell;
   BOOL		_stopped;
}

+ (GSComboWindow *)defaultPopUp;

- (NSMatrix *)matrix;
- (NSSize)popUpCellSizeForPopUp:(NSComboBoxCell *)aCell;
- (void)popUpCell:(NSComboBoxCell *)aCell
	  popUpAt:(NSPoint)aPoint
	    width:(float)aWidth;
- (void)runModalPopUp;
- (void)runLoop;

@end

#endif /* _GNUstep_H_GSComboSupport */
