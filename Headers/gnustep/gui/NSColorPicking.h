/* 
   NSColorPicking.h

   Protocols for picking colors

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSColorPicking
#define _GNUstep_H_NSColorPicking

#include <AppKit/NSPasteboard.h>

@class NSColor;
@class NSColorPanel;
@class NSImage;
@class NSButtonCell;
@class NSColorList;

@protocol NSColorPickingCustom

//
// Getting the Mode
//
- (int)currentMode;
- (BOOL)supportsMode:(int)mode;

//
// Getting the view
//
- (NSView *)provideNewView:(BOOL)firstRequest;

//
// Setting the Current Color
//
- (void)setColor:(NSColor *)aColor;

@end

@protocol NSColorPickingDefault

//
// Initialize a Color Picker
//
- (id)initWithPickerMask:(int)mask
              colorPanel:(NSColorPanel *)colorPanel;

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
- (void)attachColorList:(NSColorList *)aColorList;
- (void)detachColorList:(NSColorList *)aColorList;

//
// Showing Opacity Controls
//
- (void)alphaControlAddedOrRemoved:(id)sender;

//
// Responding to a Resized View
//
- (void)viewSizeChanged:(id)sender;

@end

#endif // _GNUstep_H_NSColorPicking
