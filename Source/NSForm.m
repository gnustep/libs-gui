/* 
   NSForm.m

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

#include <gnustep/gui/NSForm.h>

@implementation NSForm

//
// Laying Out the Form 
//
- (NSFormCell *)addEntry:(NSString *)title
{
  return nil;
}

- (NSFormCell *)insertEntry:(NSString *)title
		    atIndex:(int)index
{
  return nil;
}

- (void)removeEntryAtIndex:(int)index
{}

- (void)setInterlineSpacing:(float)spacing
{}

//
// Finding Indices
//
- (int)indexOfCellWithTag:(int)aTag
{
  return 0;
}

- (int)indexOfSelectedItem
{
  return 0;
}

//
// Modifying Graphic Attributes 
//
- (void)setBezeled:(BOOL)flag
{}

- (void)setBordered:(BOOL)flag
{}

- (void)setTextAlignment:(int)mode
{}

- (void)setTextFont:(NSFont *)fontObject
{}

- (void)setTitleAlignment:(NSTextAlignment)mode
{}

- (void)setTitleFont:(NSFont *)fontObject
{}

//
// Setting the Cell Class
//
+ (Class)cellClass
{
  return nil;
}

+ (void)setCellClass:(Class)classId
{}

//
// Getting a Cell 
//
- (id)cellAtIndex:(int)index
{
  return nil;
}

//
// Displaying a Cell
//
- (void)drawCellAtIndex:(int)index
{}

//
// Editing Text 
//
- (void)selectTextAtIndex:(int)index
{}

//
// Resizing the Form 
//
- (void)setEntryWidth:(float)width
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
