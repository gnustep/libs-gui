/* 
   NSColorPicker.h

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

#ifndef _GNUstep_H_NSColorPicker
#define _GNUstep_H_NSColorPicker

#include <AppKit/stdappkit.h>
#include <AppKit/NSColorPanel.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSColorList.h>
#include <AppKit/NSButtonCell.h>

@interface NSColorPicker : NSObject

{
  // Attributes
}

//
// Initializing an NSColorPicker 
//
- (id)initWithPickerMask:(int)aMask
	      colorPanel:(NSColorPanel *)colorPanel;

//
// Getting the Color Panel 
//
- (NSColorPanel *)colorPanel;

//
// Adding Button Images 
//
- (void)insertNewButtonImage:(NSImage *)newImage
			  in:(NSButtonCell *)newButtonCell;
- (NSImage *)provideNewButtonImage;

//
// Setting the Mode 
//
- (void)setMode:(int)mode;

//
// Using Color Lists 
//
- (void)attachColorList:(NSColorList *)colorList;
- (void)detachColorList:(NSColorList *)colorList;

//
// Responding to a Resized View 
//
- (void)viewSizeChanged:(id)sender;

@end

#endif // _GNUstep_H_NSColorPicker
