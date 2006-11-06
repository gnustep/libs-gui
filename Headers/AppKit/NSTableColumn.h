/* 
   NSTableColumn.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Michael Hanni  <mhanni@sprintmail.com>
   Date: 1999

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999

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

#ifndef _GNUstep_H_NSTableColumn
#define _GNUstep_H_NSTableColumn

#include <Foundation/NSObject.h>
#include <AppKit/AppKitDefines.h>

@class NSCell;
@class NSTableView;

@interface NSTableColumn : NSObject <NSCoding>
{
  id _identifier;
  NSTableView *_tableView;
  float _width;
  float _min_width;
  float _max_width;
  BOOL _is_resizable;
  BOOL _is_editable;
  NSCell *_headerCell;
  NSCell *_dataCell;
}
/* 
 * Initializing an NSTableColumn instance 
 */
- (id) initWithIdentifier: (id)anObject;
/*
 * Managing the Identifier
 */
- (void) setIdentifier: (id)anObject;
- (id) identifier;
/*
 * Setting the NSTableView 
 */
- (void) setTableView: (NSTableView *)aTableView;
- (NSTableView *) tableView;
/*
 * Controlling size 
 */
- (void) setWidth: (float)newWidth;
- (float) width; 
- (void) setMinWidth: (float)minWidth;
- (float) minWidth; 
- (void) setMaxWidth: (float)maxWidth;
- (float) maxWidth; 
- (void) setResizable: (BOOL)flag;
- (BOOL) isResizable; 
- (void) sizeToFit;
/*
 * Controlling editability 
 */
- (void) setEditable: (BOOL)flag;
- (BOOL) isEditable;
/*
 * Setting component cells 
 */
- (void) setHeaderCell: (NSCell *)aCell;
- (NSCell *) headerCell; 
- (void) setDataCell: (NSCell *)aCell; 
- (NSCell *) dataCell;
- (NSCell *) dataCellForRow: (int)row;
@end

/* Notifications */
APPKIT_EXPORT NSString *NSTableViewColumnDidResizeNotification;
#endif
