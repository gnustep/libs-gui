/** <title>NSColorPicker</title>

   <abstract>Abstract superclass for NSColorPanel color pickers</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Jonathan Gapen <jagapen@whitewater.chem.wisc.edu>
   Date: March 2000
   
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
#include <Foundation/NSBundle.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSColorPicker.h>

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
  ASSIGN(_colorPanel, colorPanel);
  return self;
}

//
// Getting the Color Panel 
//
- (NSColorPanel *)colorPanel
{
  return _colorPanel;
}

//
// Adding Button Images 
//
- (void)insertNewButtonImage:(NSImage *)newImage
			  in:(NSButtonCell *)newButtonCell
{
  [newButtonCell setImage: newImage];
}

- (NSImage *)provideNewButtonImage
{
  Class myClass = [self class];
  NSBundle *bundle = [NSBundle bundleForClass: myClass];
  NSString *file = [bundle pathForResource: NSStringFromClass(myClass)
                                    ofType:@"tiff"];

  return [[NSImage alloc] initWithContentsOfFile: file];
}

//
// Setting the Mode 
//
- (void)setMode:(int)mode
{} // does nothing; override

//
// Using Color Lists 
//
- (void)attachColorList:(NSColorList *)colorList
{} // does nothing; override

- (void)detachColorList:(NSColorList *)colorList
{} // does nothing; override

//
// Showing Opacity Controls
//
- (void)alphaControlAddedOrRemoved:(id)sender
{} // does nothing; override

//
// Responding to a Resized View 
//
- (void)viewSizeChanged:(id)sender
{} // does nothing; override

@end
