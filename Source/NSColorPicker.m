/* 
   NSColorPicker.m

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

#include <gnustep/gui/NSColorPicker.h>

@implementation NSColorPicker

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorPicker class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//

//
// Initializing an NSColorPicker 
//
- (id)initWithPickerMask:(int)aMask
	      colorPanel:(NSColorPanel *)colorPanel
{
  return nil;
}

//
// Getting the Color Panel 
//
- (NSColorPanel *)colorPanel
{
  return nil;
}

//
// Adding Button Images 
//
- (void)insertNewButtonImage:(NSImage *)newImage
			  in:(NSButtonCell *)newButtonCell
{}

- (NSImage *)provideNewButtonImage
{
  return nil;
}

//
// Setting the Mode 
//
- (void)setMode:(int)mode
{}

//
// Using Color Lists 
//
- (void)attachColorList:(NSColorList *)colorList
{}

- (void)detachColorList:(NSColorList *)colorList
{}

//
// Responding to a Resized View 
//
- (void)viewSizeChanged:(id)sender
{}

@end
