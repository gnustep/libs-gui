/* 
   NSStepperCell.h

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   
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

#ifndef _GNUstep_H_NSStepperCell
#define _GNUstep_H_NSStepperCell

#include <AppKit/NSActionCell.h>


@interface NSStepperCell : NSActionCell <NSCoding>
{
  // Think of the following ones as of two BOOL ivars
  #define _autorepeat _cell.subclass_bool_one
  #define _valueWraps _cell.subclass_bool_two

  double _maxValue;
  double _minValue;
  double _increment;
  BOOL highlightUp;
  BOOL highlightDown;
}

- (double)maxValue;
- (void)setMaxValue: (double)maxValue;
- (double)minValue;
- (void)setMinValue: (double)minValue;
- (double)increment;
- (void)setIncrement: (double)increment;


- (BOOL)autorepeat;
- (void)setAutorepeat: (BOOL)autorepeat;
- (BOOL)valueWraps;
- (void)setValueWraps: (BOOL)valueWraps;


//
// NSCoding protocol
//
- (void)encodeWithCoder: (NSCoder *)aCoder;
- initWithCoder: (NSCoder *)aDecoder;

@end

@interface NSStepperCell (Private)
- (void) highlight: (BOOL) highlight
	  upButton: (BOOL) upButton
	 withFrame: (NSRect) frame
	    inView: (NSView*) controlView;

- (NSRect)upButtonRectWithFrame: (NSRect) frame;
- (NSRect)downButtonRectWithFrame: (NSRect) frame;
- (void)_drawText: (NSRect)aRect;
@end
#endif // _GNUstep_H_NSStepperCell
