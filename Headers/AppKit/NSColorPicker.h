/*
   NSColorPicker.h

   Abstract superclass of custom color pickers

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSColorPicker
#define _GNUstep_H_NSColorPicker
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <AppKit/NSColorPicking.h>

@class NSColorPanel;
@class NSColorList;
@class NSImage;
@class NSButtonCell;

/**
 * NSColorPicker serves as the abstract base class for implementing custom color
 * selection interfaces within NSColorPanel. It provides the foundational
 * framework for creating specialized color pickers that integrate seamlessly
 * with the system color panel.
 *
 * Key responsibilities include:
 * * Integration with NSColorPanel through the NSColorPickingDefault protocol
 * * Button image management for color picker mode selection
 * * Color list attachment and management for predefined color collections
 * * Response to alpha transparency control changes
 * * Adaptive layout handling for view size changes
 * * Mode switching and configuration management
 *
 * Subclasses must implement the NSColorPickingDefault protocol methods to
 * provide the actual color selection interface and behavior. The base class
 * handles the common infrastructure including panel integration, button
 * management, and standard notifications.
 *
 * Color pickers are typically instantiated by the color panel system based
 * on available picker masks and user preferences. Each picker represents
 * a distinct color selection method (RGB sliders, color wheel, CMYK controls,
 * etc.) and maintains its own interface state and color selection logic.
 *
 * The picker system supports dynamic reconfiguration including alpha control
 * visibility changes and view resizing, allowing pickers to adapt their
 * interface to changing requirements and panel configurations.
 */
APPKIT_EXPORT_CLASS
@interface NSColorPicker : NSObject <NSColorPickingDefault>
{
  // Attributes
  id _colorPanel;
}

//
// Initializing an NSColorPicker
//

/**
 * Initializes a color picker with the specified picker mask and color panel.
 * aMask: Bitmask indicating which color picker modes this picker supports
 * colorPanel: The NSColorPanel instance that will contain this picker
 * Returns: An initialized NSColorPicker instance, or nil if initialization fails
 */
- (id)initWithPickerMask:(int)aMask
	      colorPanel:(NSColorPanel *)colorPanel;

//
// Getting the Color Panel
//

/**
 * Returns the color panel that contains this color picker.
 * Returns: The NSColorPanel instance that owns this picker
 */
- (NSColorPanel *)colorPanel;

//
// Adding Button Images
//

/**
 * Inserts a button image into the specified button cell for picker selection.
 * newImage: The image to display in the picker selection button
 * newButtonCell: The button cell that will contain the image
 */
- (void)insertNewButtonImage:(NSImage *)newImage
			  in:(NSButtonCell *)newButtonCell;

/**
 * Provides the button image for this color picker.
 * Returns: An NSImage to be used in the color panel's picker selection interface
 */
- (NSImage *)provideNewButtonImage;

//
// Setting the Mode
//

/**
 * Sets the current mode for this color picker.
 * mode: The color picker mode constant indicating the active selection method
 */
- (void)setMode:(int)mode;

//
// Using Color Lists
//

/**
 * Attaches a color list to this color picker for use in color selection.
 * colorList: The NSColorList to make available for color selection
 */
- (void)attachColorList:(NSColorList *)colorList;

/**
 * Detaches a color list from this color picker.
 * colorList: The NSColorList to remove from color selection options
 */
- (void)detachColorList:(NSColorList *)colorList;

//
// Showing Opacity Controls
//

/**
 * Notifies the picker that alpha transparency controls have been added or removed.
 * sender: The object that triggered the alpha control change
 */
- (void)alphaControlAddedOrRemoved:(id)sender;

//
// Responding to a Resized View
//

/**
 * Notifies the picker that its view size has changed and layout should be updated.
 * sender: The object that triggered the view size change
 */
- (void)viewSizeChanged:(id)sender;

@end

#endif // _GNUstep_H_NSColorPicker
