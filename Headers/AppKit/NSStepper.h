/*
   NSStepper.h

   The stepper class

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: August 2001
   
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

#ifndef _GNUstep_H_NSStepper
#define _GNUstep_H_NSStepper

#include <AppKit/NSControl.h>

@class NSEvent;

@interface NSStepper : NSControl
{
  // Attributes
}
- (double) maxValue;
- (void) setMaxValue: (double)maxValue;
- (double) minValue;
- (void) setMinValue: (double)minValue;
- (double) increment;
- (void) setIncrement: (double)increment;


- (BOOL)autorepeat;
- (void)setAutorepeat: (BOOL)autorepeat;
- (BOOL)valueWraps;
- (void)setValueWraps: (BOOL)valueWraps;

- (void)mouseDown:(NSEvent*)event;
@end

@interface NSStepper (Private)
- (void)_increment;
- (void)_decrement;
@end

#endif // _GNUstep_H_NSStepper
