/* 
   NSForm.h

   Form class, a text field with a label

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSForm
#define _GNUstep_H_NSForm

#include <AppKit/stdappkit.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSFont.h>
#include <Foundation/NSCoder.h>

@interface NSForm : NSMatrix <NSCoding>

{
  // Attributes
}

//
// Laying Out the Form 
//
- (NSFormCell *)addEntry:(NSString *)title;
- (NSFormCell *)insertEntry:(NSString *)title
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
- (void)setTextFont:(NSFont *)fontObject;
- (void)setTitleAlignment:(NSTextAlignment)mode;
- (void)setTitleFont:(NSFont *)fontObject;

//
// Setting the Cell Class
//
+ (Class)cellClass;
+ (void)setCellClass:(Class)classId;

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

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSForm
