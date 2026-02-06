/*
   NSColorPanel.h

   System generic color panel

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

#ifndef _GNUstep_H_NSColorPanel
#define _GNUstep_H_NSColorPanel
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSColorPicking.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSNibDeclarations.h>
#import <AppKit/NSPanel.h>

@class NSBox;
@class NSButton;
@class NSColorList;
@class NSEvent;
@class NSMatrix;
@class NSSlider;
@class NSSplitView;
@class NSView;

enum {
  NSGrayModeColorPanel,
  NSRGBModeColorPanel,
  NSCMYKModeColorPanel,
  NSHSBModeColorPanel,
  NSCustomPaletteModeColorPanel,
  NSColorListModeColorPanel,
  NSWheelModeColorPanel,
  NSCrayonModeColorPanel
};

enum {
  NSColorPanelGrayModeMask = 1,
  NSColorPanelRGBModeMask = 2,
  NSColorPanelCMYKModeMask = 4,
  NSColorPanelHSBModeMask = 8,
  NSColorPanelCustomPaletteModeMask = 16,
  NSColorPanelColorListModeMask = 32,
  NSColorPanelWheelModeMask = 64,
  NSColorPanelCrayonModeMask = 128,
  NSColorPanelAllModesMask = 255
};

@interface NSApplication (NSColorPanel)

/**
 * Brings the shared color panel to the front and makes it key.
 * sender: The object that sent the message (typically a menu item or button)
 */
- (void) orderFrontColorPanel: (id)sender;

@end

/**
 * NSColorPanel provides a comprehensive color selection interface that allows
 * users to choose colors using various color picking methods and modes. The
 * panel is typically used as a shared system-wide color picker that can be
 * integrated into applications requiring color selection functionality.
 *
 * Key features include:
 * * Multiple color picker modes (RGB, HSB, CMYK, grayscale, wheel, crayon, etc.)
 * * Customizable picker mask to enable/disable specific color modes
 * * Alpha transparency support with optional alpha slider
 * * Target-action pattern for color change notifications
 * * Continuous or discrete update modes
 * * Color list integration for predefined color collections
 * * Accessory view support for custom interface extensions
 * * Drag and drop color support for easy color sharing
 * * Automatic color space conversion between picker modes
 *
 * The color panel operates as a singleton shared instance and integrates
 * seamlessly with the application's event system. It supports both programmatic
 * color setting and interactive user selection, with flexible notification
 * mechanisms to keep the application synchronized with color changes.
 *
 * Color picker modes can be selectively enabled or disabled using picker masks,
 * allowing applications to restrict the available color selection methods to
 * match their specific requirements or user interface constraints.
 */
APPKIT_EXPORT_CLASS
@interface NSColorPanel : NSPanel
{
  // Attributes
  NSView		*_topView;
  NSColorWell		*_colorWell;
  NSButton		*_magnifyButton;
  NSMatrix		*_pickerMatrix;
  NSBox			*_pickerBox;
  NSSlider		*_alphaSlider;
  NSSplitView		*_splitView;
  NSView		*_accessoryView;

  //NSMatrix		*_swatches;

  NSMutableArray	*_pickers;
  id<NSColorPickingCustom,NSColorPickingDefault> _currentPicker;
  id			_target;
  SEL			_action;
  BOOL			_isContinuous;
  BOOL                  _showsAlpha;
}

//
// Creating the NSColorPanel
//

/**
 * Returns the shared color panel instance, creating it if necessary.
 * Returns: The singleton NSColorPanel instance for the application
 */
+ (NSColorPanel *)sharedColorPanel;

/**
 * Returns whether the shared color panel has been created.
 * Returns: YES if the shared color panel exists, NO otherwise
 */
+ (BOOL)sharedColorPanelExists;

//
// Setting the NSColorPanel
//

/**
 * Sets which color picker modes are available in the color panel.
 * mask: Bitmask of NSColorPanel*ModeMask constants specifying available modes
 */
+ (void)setPickerMask:(int)mask;

/**
 * Sets the current color picker mode for new color panel instances.
 * mode: The color picker mode constant (NSGrayModeColorPanel, etc.)
 */
+ (void)setPickerMode:(int)mode;

/**
 * Returns the accessory view displayed in the color panel.
 * Returns: The current accessory view, or nil if none is set
 */
- (NSView *)accessoryView;

/**
 * Returns whether the color panel operates in continuous mode.
 * Returns: YES if the panel sends continuous updates, NO for discrete updates
 */
- (BOOL)isContinuous;

/**
 * Returns the current color picker mode.
 * Returns: The current mode constant (NSGrayModeColorPanel, etc.)
 */
- (int)mode;

/**
 * Sets an accessory view to display in the color panel.
 * aView: The view to display as an accessory, or nil to remove
 */
- (void)setAccessoryView:(NSView *)aView;

/**
 * Sets the action message sent when the color changes.
 * aSelector: The selector to invoke on the target when color changes
 */
- (void)setAction:(SEL)aSelector;

/**
 * Sets whether the color panel operates in continuous mode.
 * flag: YES for continuous updates during interaction, NO for discrete updates
 */
- (void)setContinuous:(BOOL)flag;

/**
 * Sets the current color picker mode.
 * mode: The color picker mode constant to activate
 */
- (void)setMode:(int)mode;

/**
 * Sets whether the alpha transparency slider is visible.
 * flag: YES to show the alpha slider, NO to hide it
 */
- (void)setShowsAlpha:(BOOL)flag;

/**
 * Sets the target object for color change actions.
 * anObject: The object to receive action messages when color changes
 */
- (void)setTarget:(id)anObject;

/**
 * Returns whether the alpha transparency slider is visible.
 * Returns: YES if the alpha slider is shown, NO if hidden
 */
- (BOOL)showsAlpha;

//
// Attaching a Color List
//

/**
 * Attaches a color list to the color panel for the color list picker mode.
 * aColorList: The NSColorList to make available in the color panel
 */
- (void)attachColorList:(NSColorList *)aColorList;

/**
 * Detaches a color list from the color panel.
 * aColorList: The NSColorList to remove from the color panel
 */
- (void)detachColorList:(NSColorList *)aColorList;

//
// Setting Color
//

/**
 * Initiates a drag operation with the specified color.
 * aColor: The color to drag
 * anEvent: The mouse event that initiated the drag
 * sourceView: The view from which the drag originated
 * Returns: YES if the drag was successful, NO otherwise
 */
+ (BOOL)dragColor:(NSColor *)aColor
	withEvent:(NSEvent *)anEvent
	 fromView:(NSView *)sourceView;

/**
 * Sets the current color in the color panel.
 * aColor: The color to display and select in the panel
 */
- (void)setColor:(NSColor *)aColor;

/**
 * Returns the current alpha transparency value.
 * Returns: The alpha component (0.0 to 1.0) of the current color
 */
- (CGFloat)alpha;

/**
 * Returns the currently selected color.
 * Returns: The NSColor currently selected in the color panel
 */
- (NSColor *)color;

@end

/* Notifications */
APPKIT_EXPORT NSString *NSColorPanelColorDidChangeNotification;

#endif // _GNUstep_H_NSColorPanel
