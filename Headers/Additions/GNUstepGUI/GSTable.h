/*
   GSTable.h

   The GSTable class (a GNU extension)

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
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

#ifndef _GNUstep_H_GSTable
#define _GNUstep_H_GSTable

#include <AppKit/NSView.h>

@interface GSTable: NSView
{
  int _numberOfRows;
  int _numberOfColumns;
  // Border around the table.
  float _minXBorder;  
  float _maxXBorder;
  float _minYBorder;
  float _maxYBorder;
  // We control the NSView inserted in the GSTable (which we call 
  // the prisoners) by enclosing them in jails. 
  // Each prisoner is enclosed in a jail (which is a subview under 
  // our control). 
  // Each prisoner is allowed to resize only inside its jail.   
  NSView **_jails;
  // YES if the column/row should be expanded/reduced when the size 
  // of the GSTable is expanded/reduced (this BOOL is otherwhere 
  // called X/Y Resizing Enabled). 
  BOOL *_expandColumn;
  BOOL *_expandRow;
  // Cache the total number of rows/columns which have expand set to YES 
  int _expandingColumnNumber;
  int _expandingRowNumber;
  // Dimension of each column/row
  float *_columnDimension;
  float *_rowDimension;
  // Origin of each column/row
  float *_columnXOrigin;
  float *_rowYOrigin;
  // Minimum dimension each row/column is allowed to have 
  // (which is the size the jail had when first created).  
  float *_minColumnDimension;
  float *_minRowDimension;
  // Cache the minimum size the GSTable should be resized to.
  NSSize _minimumSize;
  // YES if there is a prisoner in that GSTable position. 
  // (to avoid creating a jail if there is no prisoner to control). 
  BOOL *_havePrisoner;
}
//
// Initizialing.  
// 
-(id) initWithNumberOfRows: (int)rows 
           numberOfColumns: (int)columns;

// Initialize with a default of 2 columns and 2 rows. 
-(id) init;
//
// Setting Border Dimension.
// Border is space around the table. 
//
-(void) setBorder: (float)aBorder;
-(void) setXBorder: (float)aBorder;
-(void) setYBorder: (float)aBorder;
-(void) setMinXBorder: (float)aBorder;
-(void) setMaxXBorder: (float)aBorder;
-(void) setMinYBorder: (float)aBorder;
-(void) setMaxYBorder: (float)aBorder;
//
//  Adding a View. 
//  Use these methods to put views in the GSTable. 
//  
-(void) putView: (NSView *)aView
	  atRow: (int)row
	 column: (int)column;

-(void) putView: (NSView *)aView
	  atRow: (int)row
	 column: (int)column
    withMargins: (float)margins;

-(void) putView: (NSView *)aView
	  atRow: (int)row
	 column: (int)column
   withXMargins: (float)xMargins
       yMargins: (float)yMargins;

-(void) putView: (NSView *)aView
	  atRow: (int)row
	 column: (int)column
  // Each view which is added to the GSTable can have some margins
  // set.  The GSTable treats the view and its margins as a whole.
  // They are given (as a whole) some space, which is reduced or
  // increased (but only if X or Y Resizing is Enabled for the column
  // or the row in which the view resides) when the GSTable is
  // resized.  When this happens, the space is added (or subtracted)
  // to the view or to the margins according to the autoResizeMask of
  // the view.
 withMinXMargin: (float)minXMargin   // Left Margin 
     maxXMargin: (float)maxXMargin   // Right Margin
     minYMargin: (float)minYMargin   // Lower Margin (Upper if flipped)
     maxYMargin: (float)maxYMargin;  // Upper Margin (Lower if flipped)
//
// Minimum Size. 
// This returns the minimum size the GSTable should be resized to. 
// Trying to resize the GSTable below this size will only result in clipping 
// (ie, making it disappear) part of the GSTable.
//
-(NSSize) minimumSize;
//
// Resizing. 
// If for any reason you need the GSTable to be redrawn (with minimum size), 
// invoke the following.
-(void) sizeToFit;
//
// Setting Row and Column Expand Flag
// When the GSTable is resized, the extra space is equally divided 
// between the Rows and Columns which have X/Y Resizing Enabled. 
//
-(void) setXResizingEnabled: (BOOL)aFlag 
		  forColumn: (int)aColumn;

-(BOOL) isXResizingEnabledForColumn: (int)aColumn;

-(void) setYResizingEnabled: (BOOL)aFlag 
		     forRow: (int)aRow;

-(BOOL) isYResizingEnabledForRow: (int)aRow;
//
// Adding Rows and Columns
// These should be used to add more rows and columns to the GSTable. 
// Of course it is faster to create a GSTable with the right number of rows 
// and columns from the beginning.
//
-(void) addRow;
// TODO: -(void) insertRow: (int)row;
// TODO: -(void) removeRow: (int)row;

-(void) addColumn;
// TODO: -(void) insertColumn: (int)column;
// TODO: -(void) removeColumn: (int)column;
//
// Getting Row and Column Number
//
-(int) numberOfRows;

-(int) numberOfColumns;
@end

#endif /* _GNUstep_H_GSTable */





