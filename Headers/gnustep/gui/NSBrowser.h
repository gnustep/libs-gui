/* 
   NSBrowser.h

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSBrowser
#define _GNUstep_H_NSBrowser

#include <AppKit/stdappkit.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSScroller.h>
#include <Foundation/NSCoder.h>

@interface NSBrowser : NSControl <NSCoding>

{
  // Attributes
}

//
// Setting the Delegate 
//
- (id)delegate;
- (void)setDelegate:(id)anObject;

//
// Target and Action 
//
- (SEL)doubleAction;
- (BOOL)sendAction;
- (void)setDoubleAction:(SEL)aSelector;

//
// Setting Component Classes 
//
+ (Class)cellClass;
- (id)cellPrototype;
- (Class)matrixClass;
- (void)setCellClass:(Class)classId;
- (void)setCellPrototype:(NSCell *)aCell;
- (void)setMatrixClass:(Class)classId;

//
// Setting NSBrowser Behavior 
//
- (BOOL)reusesColumns;
- (void)setReusesColumns:(BOOL)flag;
- (void)setTakesTitleFromPreviousColumn:(BOOL)flag;
- (BOOL)takesTitleFromPreviousColumn;

//
// Allowing Different Types of Selection 
//
- (BOOL)allowsBranchSelection;
- (BOOL)allowsEmptySelection;
- (BOOL)allowsMultipleSelection;
- (void)setAllowsBranchSelection:(BOOL)flag;
- (void)setAllowsEmptySelection:(BOOL)flag;
- (void)setAllowsMultipleSelection:(BOOL)flag;

//
// Setting Arrow Key Behavior
//
- (BOOL)acceptsArrowKeys;
- (BOOL)sendsActionOnArrowKeys;
- (void)setAcceptsArrowKeys:(BOOL)flag;
- (void)setSendsActionOnArrowKeys:(BOOL)flag;

//
// Showing a Horizontal Scroller 
//
- (void)setHasHorizontalScroller:(BOOL)flag;
- (BOOL)hasHorizontalScroller;

//
// Setting the NSBrowser's Appearance 
//
- (int)maxVisibleColumns;
- (int)minColumnWidth;
- (BOOL)separatesColumns;
- (void)setMaxVisibleColumns:(int)columnCount;
- (void)setMinColumnWidth:(int)columnWidth;
- (void)setSeparatesColumns:(BOOL)flag;

//
// Manipulating Columns 
//
- (void)addColumn;
- (int)columnOfMatrix:(NSMatrix *)matrix;
- (void)displayAllColumns;
- (void)displayColumn:(int)column;
- (int)firstVisibleColumn;
- (BOOL)isLoaded;
- (int)lastColumn;
- (int)lastVisibleColumn;
- (void)loadColumnZero;
- (int)numberOfVisibleColumns;
- (void)reloadColumn:(int)column;
- (void)selectAll:(id)sender;
- (int)selectedColumn;
- (void)setLastColumn:(int)column;
- (void)validateVisibleColumns;

//
// Manipulating Column Titles 
//
- (void)drawTitle:(NSString *)title
	   inRect:(NSRect)aRect
ofColumn:(int)column;
- (BOOL)isTitled;
- (void)setTitled:(BOOL)flag;
- (void)setTitle:(NSString *)aString
	ofColumn:(int)column;
- (NSRect)titleFrameOfColumn:(int)column;
- (float)titleHeight;
- (NSString *)titleOfColumn:(int)column;

//
// Scrolling an NSBrowser 
//
- (void)scrollColumnsLeftBy:(int)shiftAmount;
- (void)scrollColumnsRightBy:(int)shiftAmount;
- (void)scrollColumnToVisible:(int)column;
- (void)scrollViaScroller:(NSScroller *)sender;
- (void)updateScroller;

//
// Event Handling 
//
- (void)doClick:(id)sender;
- (void)doDoubleClick:(id)sender;

//
// Getting Matrices and Cells 
//
- (id)loadedCellAtRow:(int)row
	       column:(int)column;
- (NSMatrix *)matrixInColumn:(int)column;
- (id)selectedCell;
- (id)selectedCellInColumn:(int)column;
- (NSArray *)selectedCells;

//
// Getting Column Frames 
//
- (NSRect)frameOfColumn:(int)column;
- (NSRect)frameOfInsideOfColumn:(int)column;

//
// Manipulating Paths 
//
- (NSString *)path;
- (NSString *)pathSeparator;
- (NSString *)pathToColumn:(int)column;
- (BOOL)setPath:(NSString *)path;
- (void)setPathSeparator:(NSString *)aString;

//
// Arranging an NSBrowser's Components 
//
- (void)tile;

//
// Methods Implemented by the Delegate 
//
- (void)browser:(NSBrowser *)sender
createRowsForColumn:(int)column
inMatrix:(NSMatrix *)matrix;
- (BOOL)browser:(NSBrowser *)sender
  isColumnValid:(int)column;
- (int)browser:(NSBrowser *)sender
numberOfRowsInColumn:(int)column;
- (BOOL)browser:(NSBrowser *)sender
     selectCell:(NSString *)title
inColumn:(int)column;
- (NSString *)browser:(NSBrowser *)sender
	titleOfColumn:(int)column;
- (void)browser:(NSBrowser *)sender
willDisplayCell:(id)cell
atRow:(int)row
column:(int)column;
- (void)browserDidScroll:(NSBrowser *)sender;
- (void)browserWillScroll:(NSBrowser *)sender;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSBrowser
