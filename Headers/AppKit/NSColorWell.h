/*
   NSColorWell.h

   NSControl for selecting and display a single color value.

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

#ifndef _GNUstep_H_NSColorWell
#define _GNUstep_H_NSColorWell
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSControl.h>

@class NSColor;

/**
 * NSColorWell provides a simple, compact interface for displaying and selecting
 * colors within applications. It appears as a rectangular well that displays
 * the current color and allows users to click to open the system color panel
 * for color selection.
 *
 * Key features include:
 * * Visual color display with customizable border appearance
 * * Integration with the system color panel for color selection
 * * Drag-and-drop color support for easy color sharing
 * * Activation/deactivation states for color panel interaction
 * * Target-action pattern for color change notifications
 * * Automatic color well management and exclusivity handling
 * * Support for both bordered and borderless display styles
 * * Full integration with Interface Builder and archiving
 *
 * Color wells can be activated to connect with the shared color panel,
 * allowing users to select new colors through the full range of system
 * color pickers. The well automatically manages its activation state and
 * ensures only one color well is active at a time when exclusive activation
 * is used.
 *
 * The control supports standard target-action patterns, sending action
 * messages when the color changes. Color wells also participate in the
 * responder chain and can take colors from other controls that implement
 * the color sharing protocol.
 *
 * Visual appearance can be customized with bordered or borderless styles,
 * making color wells suitable for various interface designs from utility
 * panels to integrated application interfaces.
 */
APPKIT_EXPORT_CLASS
@interface NSColorWell : NSControl <NSCoding>

{
  // Attributes
  NSColor *_the_color;
  BOOL _is_active;
  BOOL _is_bordered;
  NSRect _wellRect;
  id _target;
  SEL _action;
  // Mouse tracking
  NSPoint _mouseDownPoint;
}

//
// Drawing
//

/**
 * Draws the color well's interior within the specified rectangle.
 * insideRect: The rectangle defining the interior area to draw the color
 */
- (void)drawWellInside:(NSRect)insideRect;

//
// Activating
//

/**
 * Activates the color well to connect with the shared color panel.
 * exclusive: YES to deactivate other color wells, NO to allow multiple active wells
 */
- (void)activate:(BOOL)exclusive;

/**
 * Deactivates the color well, disconnecting it from the color panel.
 */
- (void)deactivate;

/**
 * Returns whether the color well is currently active.
 * Returns: YES if the color well is connected to the color panel, NO otherwise
 */
- (BOOL)isActive;

//
// Managing Color
//

/**
 * Returns the current color displayed in the color well.
 * Returns: The NSColor currently shown in the well
 */
- (NSColor *)color;

/**
 * Sets the color to display in the color well.
 * color: The NSColor to display in the well
 */
- (void)setColor:(NSColor *)color;

/**
 * Takes the color from the specified sender object.
 * sender: An object that responds to the -color method to provide a color
 */
- (void)takeColorFrom:(id)sender;

//
// Managing Borders
//

/**
 * Returns whether the color well displays a border.
 * Returns: YES if the well has a border, NO for borderless display
 */
- (BOOL)isBordered;

/**
 * Sets whether the color well should display a border.
 * bordered: YES to show a border around the well, NO for borderless appearance
 */
- (void)setBordered:(BOOL)bordered;

//
// NSCoding protocol
//

/**
 * Encodes the color well's state to the specified coder.
 * aCoder: The coder to write the color well's data to
 */
- (void)encodeWithCoder: (NSCoder *)aCoder;

/**
 * Initializes a color well from data in the specified decoder.
 * aDecoder: The decoder containing the color well's archived data
 * Returns: An initialized NSColorWell instance, or nil if initialization fails
 */
- (id)initWithCoder: (NSCoder *)aDecoder;

@end

#endif // _GNUstep_H_NSColorWell
