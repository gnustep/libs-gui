/* 
   NSBrowser.m

   Description...

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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/config.h>
#include <AppKit/NSBrowser.h>

@implementation NSBrowser

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSBrowser class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Setting Component Classes 
//
+ (Class)cellClass
{
  return NULL;
}

//
// Instance methods
//

//
// Setting the Delegate 
//
- (id)delegate
{
  return nil;
}

- (void)setDelegate:(id)anObject
{}

//
// Target and Action 
//
- (SEL)doubleAction
{
  return NULL;
}

- (BOOL)sendAction
{
  return NO;
}

- (void)setDoubleAction:(SEL)aSelector
{}

//
// Setting Component Classes 
//
- (id)cellPrototype
{
  return nil;
}

- (Class)matrixClass
{
  return NULL;
}

- (void)setCellClass:(Class)classId
{}

- (void)setCellPrototype:(NSCell *)aCell
{}

- (void)setMatrixClass:(Class)classId
{}

//
// Setting NSBrowser Behavior 
//
- (BOOL)reusesColumns
{
  return NO;
}

- (void)setReusesColumns:(BOOL)flag
{}

- (void)setTakesTitleFromPreviousColumn:(BOOL)flag
{}

- (BOOL)takesTitleFromPreviousColumn
{
  return NO;
}

//
// Allowing Different Types of Selection 
//
- (BOOL)allowsBranchSelection
{
  return NO;
}

- (BOOL)allowsEmptySelection
{
  return NO;
}

- (BOOL)allowsMultipleSelection
{
  return NO;
}

- (void)setAllowsBranchSelection:(BOOL)flag
{}

- (void)setAllowsEmptySelection:(BOOL)flag
{}

- (void)setAllowsMultipleSelection:(BOOL)flag
{}

//
// Setting Arrow Key Behavior
//
- (BOOL)acceptsArrowKeys
{
  return NO;
}

- (BOOL)sendsActionOnArrowKeys
{
  return NO;
}

- (void)setAcceptsArrowKeys:(BOOL)flag
{}

- (void)setSendsActionOnArrowKeys:(BOOL)flag
{}

//
// Showing a Horizontal Scroller 
//
- (void)setHasHorizontalScroller:(BOOL)flag
{}

- (BOOL)hasHorizontalScroller
{
  return NO;
}

//
// Setting the NSBrowser's Appearance 
//
- (int)maxVisibleColumns
{
  return 0;
}

- (int)minColumnWidth
{
  return 0;
}

- (BOOL)separatesColumns
{
  return NO;
}

- (void)setMaxVisibleColumns:(int)columnCount
{}

- (void)setMinColumnWidth:(int)columnWidth
{}

- (void)setSeparatesColumns:(BOOL)flag
{}

//
// Manipulating Columns 
//
- (void)addColumn
{}

- (int)columnOfMatrix:(NSMatrix *)matrix
{
  return 0;
}

- (void)displayAllColumns
{}

- (void)displayColumn:(int)column
{}

- (int)firstVisibleColumn
{
  return 0;
}

- (BOOL)isLoaded
{
  return NO;
}

- (int)lastColumn
{
  return 0;
}

- (int)lastVisibleColumn
{
  return 0;
}

- (void)loadColumnZero
{}

- (int)numberOfVisibleColumns
{
  return 0;
}

- (void)reloadColumn:(int)column
{}

- (void)selectAll:(id)sender
{}

- (int)selectedColumn
{
  return 0;
}

- (void)setLastColumn:(int)column
{}

- (void)validateVisibleColumns
{}

//
// Manipulating Column Titles 
//
- (void)drawTitle:(NSString *)title
	   inRect:(NSRect)aRect
ofColumn:(int)column
{}

- (BOOL)isTitled
{
  return NO;
}

- (void)setTitled:(BOOL)flag
{}

- (void)setTitle:(NSString *)aString
	ofColumn:(int)column
{}

- (NSRect)titleFrameOfColumn:(int)column
{
  return NSZeroRect;
}

- (float)titleHeight
{
  return 0;
}

- (NSString *)titleOfColumn:(int)column
{
  return nil;
}

//
// Scrolling an NSBrowser 
//
- (void)scrollColumnsLeftBy:(int)shiftAmount
{}

- (void)scrollColumnsRightBy:(int)shiftAmount
{}

- (void)scrollColumnToVisible:(int)column
{}

- (void)scrollViaScroller:(NSScroller *)sender
{}

- (void)updateScroller
{}

//
// Event Handling 
//
- (void)doClick:(id)sender
{}

- (void)doDoubleClick:(id)sender
{}

//
// Getting Matrices and Cells 
//
- (id)loadedCellAtRow:(int)row
	       column:(int)column
{
  return nil;
}

- (NSMatrix *)matrixInColumn:(int)column
{
  return nil;
}

- (id)selectedCell
{
  return nil;
}

- (id)selectedCellInColumn:(int)column
{
  return nil;
}

- (NSArray *)selectedCells
{
  return nil;
}

//
// Getting Column Frames 
//
- (NSRect)frameOfColumn:(int)column
{
  return NSZeroRect;
}

- (NSRect)frameOfInsideOfColumn:(int)column
{
  return NSZeroRect;
}

//
// Manipulating Paths 
//
- (NSString *)path
{
  return nil;
}

- (NSString *)pathSeparator
{
  return nil;
}

- (NSString *)pathToColumn:(int)column
{
  return nil;
}

- (BOOL)setPath:(NSString *)path
{
  return NO;
}

- (void)setPathSeparator:(NSString *)aString
{}

//
// Arranging an NSBrowser's Components 
//
- (void)tile
{}

//
// Methods Implemented by the Delegate 
//
- (void)browser:(NSBrowser *)sender
createRowsForColumn:(int)column
inMatrix:(NSMatrix *)matrix
{}

- (BOOL)browser:(NSBrowser *)sender
  isColumnValid:(int)column
{
  return NO;
}

- (int)browser:(NSBrowser *)sender
numberOfRowsInColumn:(int)column
{
  return 0;
}

- (BOOL)browser:(NSBrowser *)sender
     selectCell:(NSString *)title
inColumn:(int)column
{
  return NO;
}

- (NSString *)browser:(NSBrowser *)sender
	titleOfColumn:(int)column
{
  return nil;
}

- (void)browser:(NSBrowser *)sender
willDisplayCell:(id)cell
atRow:(int)row
column:(int)column
{}

- (void)browserDidScroll:(NSBrowser *)sender
{}

- (void)browserWillScroll:(NSBrowser *)sender
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
