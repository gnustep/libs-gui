/*
   GSHbox.h

   The GSHbox class (a GNU extension)

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

#ifndef _GNUstep_H_GSHbox
#define _GNUstep_H_GSHbox

#include "GSTable.h"

//
// GSHbox inherits from GSTable the autosizing/autoresizing engine.
// The only real difference between a GSHbox and a GSTable with 1 row 
// is that the GSHbox has a much simpler, easier and friendlier API. 
//
// You shouldn't use GSTable methods with GSHbox (exception: methods 
// explicitly quoted in comments to this file as 'inherited from GSTable'). 
// If you need to do that, you should be using GSTable instead.
//
@interface GSHbox: GSTable
{
  BOOL _haveViews;
  float _defaultMinXMargin;
}
//
// Initizialing.  
// Always use init for GSHbox: other methods don't make sense. 
// Don't used GSTable methods.  You do not need to specify 
// the number of views you plan to put in the box 
// when you initialize it. 
// So, the correct way to start a new GSHbox is simply: 
//
// hbox = [GSHbox new];
//
-(id) init;
//
// Setting Border.
// 

// Use these if you want some spacing around the table.
// Changing the border will update immediately the box.
// The default border is zero.
//
// Inherited from GSTable Class: 
// To have the same border on the four sides use: 
//-(void) setBorder: (float)aBorder;
//
// To set borders in the horizontal or vertical direction, use:
//-(void) setXBorder: (float)aBorder;
//-(void) setYBorder: (float)aBorder;
// 
// To specificy different borders, use: 
//-(void) setMinXBorder: (float)aBorder;
//-(void) setMaxXBorder: (float)aBorder;
//-(void) setMinYBorder: (float)aBorder;
//-(void) setMaxYBorder: (float)aBorder;
//

//
//  Adding a View. 
//  Use these methods to pack views in the GSHbox. 
//  Don't use the corresponding methods of GSTable, which are far more general 
//  and far more complicate.  If you need to do that, use GSTable instead. 
//
-(void) addView: (NSView *)aView;

-(void) addView: (NSView *)aView
enablingXResizing: (BOOL)flag;

-(void) addView: (NSView *)aView
 withMinXMargin: (float)aMargin;

-(void) addView: (NSView *)aView
  // enablingXResizing is YES if the {view and its margins} should be
  // resized when the GSHbox is resized in the horizontal direction.
  // FALSE does not resize it.  Default is YES.
enablingXResizing: (BOOL)flag
  // With a GSHbox, only one margin is set when you add views to the GSHbox: 
  // the margin between each view and the preceding one. 
  // Exception: the first view is special, and has no margin set (it has no 
  // preceding view to be separated from). 
  // Space above or below the view may result if the view is shorter, 
  // in the vertical direction, than the other views in the GSHbox; 
  // in that case the view is resized to fit vertically, 
  // according to its autoresizingMask.  
  // By changing the autoresizingMask you may decide whether the space 
  // should go to the view or to its vertical margins; this for example 
  // lets you center vertically or flush up/down your view.
 withMinXMargin: (float)aMargin;
//
// Adding a Separator. 
//
-(void) addSeparator;
-(void) addSeparatorWithMinXMargin: (float)aMargin;

//
//  Setting Margins.  
//
  
// Use only the following method to set a default margin. 
// The default margin set with the following method will be used 
// for all the views added after.  
// (Exception: the first view put in the box has no margins at all)
// It will not affect already added views.
// In a GSHbox, only one margin is used, the one between each view 
// and the preceding one.  If what you want is space around the GSHbox, 
// you don't want a margin but a border; use setBorder: 
// (see above, "Setting Border"). 
// If you need more complicated margins/borders, use GSTable. 
-(void) setDefaultMinXMargin: (float)aMargin;

//
// Minimum Size. 
// 

// This returns the minimum size the GSHbox should be resized to. 
// Trying to resize the GSHbox below this size will only result in clipping 
// (ie, making it disappear) part of the GSHbox.
// Inherited from GSTable Class: 
// -(NSSize) minimumSize;

//
// Resizing. 
// 

// If for any reason you need the GSHbox to revert to its minimum size, 
// invoke the following.
// Inherited from GSTable Class: 
// -(void) sizeToFit;

//
// Getting Number of Views
//

// Return the number of views in the GSHbox (separators included).  
-(int) numberOfViews;
@end

#endif /* _GNUstep_H_GSHbox */





