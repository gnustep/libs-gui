/* 
   NSForm.h

   Form class, a matrix of text fields with labels

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997

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

#ifndef _GNUstep_H_NSForm
#define _GNUstep_H_NSForm

#include <AppKit/NSMatrix.h>

@class NSFormCell;
@class NSFont;

@interface NSForm : NSMatrix <NSCoding>
{
  BOOL _title_width_needs_update;
}
//
// Laying Out the Form 
//
- (NSFormCell*)addEntry:(NSString*)title;
- (NSFormCell*)insertEntry:(NSString*)title
		    atIndex:(int)index;
- (void)removeEntryAtIndex:(int)index;
- (void)setInterlineSpacing:(float)spacing;

//
// Finding Indices
//
- (int)indexOfCellWithTag:(int)aTag;
- (int)indexOfSelectedItem;

//
// Modifying Graphic Attributes 
//
- (void)setBezeled:(BOOL)flag;
- (void)setBordered:(BOOL)flag;
- (void)setTextAlignment:(int)mode;
- (void)setTextFont:(NSFont*)fontObject;
- (void)setTitleAlignment:(NSTextAlignment)mode;
- (void)setTitleFont:(NSFont*)fontObject;

//
// Getting a Cell 
//
- (id)cellAtIndex:(int)index;

//
// Displaying a Cell
//
- (void)drawCellAtIndex:(int)index;

//
// Editing Text 
//
- (void)selectTextAtIndex:(int)index;

//
// Resizing the Form 
//
- (void)setEntryWidth:(float)width;

// Private
-(void) _setTitleWidthNeedsUpdate: (NSNotification*)notification;
@end

APPKIT_EXPORT NSString *_NSFormCellDidChangeTitleWidthNotification;

#endif // _GNUstep_H_NSForm
