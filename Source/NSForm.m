/*
   NSForm.m

   Form class, a text field with a label

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

#include <gnustep/gui/config.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>

@implementation NSForm

/* Class variables */
static Class defaultCellClass = nil;

+ (void)initialize
{
  if (self == [NSForm class]) {
    /* Set the initial version */
    [self setVersion: 1];

    /* Set the default cell class */
    defaultCellClass = [NSFormCell class];
  }
}

+ (Class)cellClass
{
  return defaultCellClass;
}

+ (void)setCellClass:(Class)classId
{
  defaultCellClass = classId;
}

- (NSFormCell*)addEntry:(NSString*)title
{
  return [self insertEntry:title atIndex:[self numberOfRows]];
}

- (NSFormCell*)insertEntry:(NSString*)title
		    atIndex:(int)index
{
  [self insertRow:index];
  return [self cellAtRow:index column:0];
}

- (void)removeEntryAtIndex:(int)index
{
  [self removeRow:index];
}

- (void)setBezeled:(BOOL)flag
{
  int i, count = [self numberOfRows];

  /* Set the bezeled attribute to the cell prototype */
  [[self prototype] setBezeled:flag];

  for (i = 0; i < count; i++)
    [[self cellAtRow:i column:0] setBezeled:flag];
}

- (void)setBordered:(BOOL)flag
{
  int i, count = [self numberOfRows];

  /* Set the bordered attribute to the cell prototype */
  [[self prototype] setBordered:flag];

  for (i = 0; i < count; i++)
    [[self cellAtRow:i column:0] setBordered:flag];
}

- (void)setEntryWidth:(float)width
{
  NSSize size = [self cellSize];

  size.width = width;
  [self setCellSize:size];
}

- (void)setInterlineSpacing:(float)spacing
{
  [self setIntercellSpacing:NSMakeSize(0, spacing)];
}

/* For the title attributes we use the corresponding attributes from the cell.
   For the text attributes we use instead the attributes inherited from the
   NSCell class. */
- (void)setTitleAlignment:(NSTextAlignment)aMode
{
  int i, count = [self numberOfRows];

  /* Set the title alignment attribute to the cell prototype */
  [[self prototype] setTitleAlignment:aMode];

  for (i = 0; i < count; i++)
    [[self cellAtRow:i column:0] setTitleAlignment:aMode];
}

- (void)setTextAlignment:(int)aMode
{
  int i, count = [self numberOfRows];

  /* Set the text alignment attribute to the cell prototype */
  [[self prototype] setAlignment:aMode];

  for (i = 0; i < count; i++)
    [[self cellAtRow:i column:0] setAlignment:aMode];
}

- (void)setTitleFont:(NSFont*)fontObject
{
  int i, count = [self numberOfRows];

  /* Set the title font attribute to the cell prototype */
  [[self prototype] setTitleFont:fontObject];

  for (i = 0; i < count; i++)
    [[self cellAtRow:i column:0] setTitleFont:fontObject];
}

- (void)setTextFont:(NSFont*)fontObject
{
  int i, count = [self numberOfRows];

  /* Set the text font attribute to the cell prototype */
  [[self prototype] setFont:fontObject];

  for (i = 0; i < count; i++)
    [[self cellAtRow:i column:0] setFont:fontObject];
}

- (int)indexOfCellWithTag:(int)aTag
{
  int i, count = [self numberOfRows];

  for (i = 0; i < count; i++)
    if ([[self cellAtRow:i column:0] tag] == aTag)
      return i;
  return -1;
}

- (int)indexOfSelectedItem
{
  return [self selectedRow];
}

- (id)cellAtIndex:(int)index
{
  return [self cellAtRow:index column:0];
}

- (void)drawCellAtIndex:(int)index
{
  id theCell = [self cellAtIndex:index];

  [theCell drawWithFrame:[self cellFrameAtRow:index column:0]
	   inView:self];
}

- (void)drawCellAtRow:(int)row column:(int)column
{
  [self drawCellAtIndex:row];
}

- (void)selectTextAtIndex:(int)index
{}

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
