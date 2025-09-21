/*
   NSColorPicking.h

   Protocols for picking colors

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997

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

#ifndef _GNUstep_H_NSColorPicking
#define _GNUstep_H_NSColorPicking
#import <AppKit/AppKitDefines.h>

@class NSColor;
@class NSColorPanel;
@class NSView;
@class NSImage;
@class NSButtonCell;
@class NSColorList;

/**
 * The NSColorPickingCustom protocol defines the interface for creating custom
 * color picker views that can be integrated into the NSColorPanel. Objects
 * conforming to this protocol provide custom color selection interfaces with
 * specialized functionality beyond the standard color picking modes. This
 * protocol enables developers to extend the color panel with domain-specific
 * color selection tools, artistic color interfaces, or specialized color
 * workflows. Custom color pickers must provide their own view hierarchy and
 * handle color selection events appropriately. The protocol supports dynamic
 * mode checking to ensure compatibility with different color panel
 * configurations.
 */
@protocol NSColorPickingCustom

//
// Getting the Mode
//
/**
 * Returns the current operating mode of the custom color picker. The mode
 * identifies which color selection interface or algorithm is currently active
 * within this custom picker implementation. Different modes may correspond to
 * different color models, selection techniques, or user interface layouts.
 * Custom color pickers can support multiple modes to provide varied color
 * selection experiences. The returned integer value should correspond to
 * constants defined by the color picker implementation. This method enables
 * the color panel to query and coordinate with the active color selection
 * mode.
 */
- (int)currentMode;
/**
 * Tests whether this custom color picker supports the specified operating mode.
 * The mode parameter represents a color selection mode that may be requested
 * by the color panel or user interaction. Custom color pickers should return
 * YES only for modes they can properly handle and display. This method allows
 * the color panel to determine which modes are available and prevent
 * activation of unsupported functionality. Mode support may depend on the
 * picker's capabilities, available resources, or current configuration state.
 * Returning NO for unsupported modes helps maintain consistent user experience.
 */
- (BOOL)supportsMode:(int)mode;

//
// Getting the view
//
/**
 * Provides a new view instance for displaying the custom color picker
 * interface. The firstRequest parameter indicates whether this is the initial
 * view request or a subsequent request for view replacement. When firstRequest
 * is YES, the picker should create and configure its primary user interface
 * view with all necessary controls and initial state. When NO, the picker may
 * return a cached view or create a replacement view as needed. The returned
 * view becomes part of the color panel's view hierarchy and should handle
 * user interactions to facilitate color selection. This method enables
 * dynamic view management and lazy loading of picker interfaces.
 */
- (NSView *)provideNewView:(BOOL)firstRequest;

//
// Setting the Current Color
//
/**
 * Updates the custom color picker to display and reflect the specified color
 * value. The aColor parameter represents the new color that should be shown
 * as selected within the picker's user interface. This method is called when
 * the color panel needs to synchronize the picker's display with a color
 * change from another source, such as a different picker or programmatic
 * color assignment. The custom picker should update all relevant visual
 * indicators, sliders, color wells, or other interface elements to accurately
 * represent the new color value. This ensures consistent color representation
 * across all components of the color panel interface.
 */
- (void)setColor:(NSColor *)aColor;

@end

/**
 * The NSColorPickingDefault protocol defines the standard interface for color
 * picker implementations that integrate with the NSColorPanel system. Objects
 * conforming to this protocol provide the essential functionality for standard
 * color selection modes within the color panel framework. This protocol
 * encompasses initialization, button management, mode handling, color list
 * integration, opacity controls, and view management. Default color pickers
 * are designed to work seamlessly with the color panel's architecture,
 * providing consistent behavior and appearance. The protocol supports dynamic
 * mode switching, color list attachment for organized color selection, and
 * responsive interface updates for optimal user experience.
 */
@protocol NSColorPickingDefault

//
// Initialize a Color Picker
//
/**
 * Initializes a new color picker instance with the specified picker mask and
 * associated color panel. The mask parameter defines which color selection
 * modes or features this picker should support, using bitwise flags to enable
 * specific functionality. The colorPanel parameter provides the parent color
 * panel that will contain and coordinate with this picker instance. This
 * initialization method establishes the picker's configuration and creates
 * necessary connections with the color panel framework. The picker should
 * configure its internal state, prepare any required resources, and establish
 * communication channels with the provided color panel. Proper initialization
 * ensures seamless integration within the color selection system.
 */
- (id)initWithPickerMask:(int)mask
              colorPanel:(NSColorPanel *)colorPanel;

//
// Adding Button Images
//
/**
 * Inserts a new button image into the specified button cell for color panel
 * interface integration. The newImage parameter contains the graphical
 * representation that should be displayed within the button, typically
 * representing the picker's visual identity or current color selection mode.
 * The newButtonCell parameter specifies the target button cell that will
 * display the provided image. This method enables dynamic button
 * customization within the color panel's toolbar or mode selection interface.
 * The picker should ensure the image is properly scaled and formatted for
 * optimal display within the button cell's bounds and visual context.
 */
- (void)insertNewButtonImage:(NSImage *)newImage
                          in:(NSButtonCell *)newButtonCell;
/**
 * Provides a new button image for representing this color picker in the color
 * panel interface. The returned image serves as the visual identifier for
 * this picker when displayed in the color panel's mode selection toolbar or
 * picker selection interface. The image should clearly represent the picker's
 * functionality or visual theme to help users identify and select the
 * appropriate color selection mode. This method enables dynamic button image
 * creation and supports customizable picker representation. The image should
 * be appropriately sized and designed for clear visibility within standard
 * button dimensions and color panel visual themes.
 */
- (NSImage *)provideNewButtonImage;

//
// Setting the Mode
//
/**
 * Configures the color picker to operate in the specified selection mode.
 * The mode parameter determines which color selection interface or algorithm
 * the picker should activate and display to the user. Different modes may
 * correspond to various color models like RGB, HSB, CMYK, or specialized
 * selection interfaces like color wheels, sliders, or swatches. The picker
 * should transition its user interface to reflect the new mode, updating
 * controls, layouts, and interaction patterns as appropriate. This method
 * enables dynamic mode switching within the color panel system and ensures
 * the picker adapts to user preferences and workflow requirements.
 */
- (void)setMode:(int)mode;

//
// Using Color Lists
//
/**
 * Attaches a color list to this color picker for organized color selection.
 * The aColorList parameter contains a named collection of colors that should
 * be made available within the picker's interface. This method enables
 * integration with predefined color collections, custom color palettes, or
 * application-specific color schemes. The picker should incorporate the
 * attached color list into its user interface, allowing users to browse and
 * select colors from the organized collection. Multiple color lists may be
 * attached to provide comprehensive color organization and selection options.
 * This supports workflow efficiency and color consistency across applications.
 */
- (void)attachColorList:(NSColorList *)aColorList;
/**
 * Detaches a previously attached color list from this color picker. The
 * aColorList parameter specifies which color collection should be removed
 * from the picker's available selections. This method enables dynamic color
 * list management and allows applications to control which color collections
 * are accessible through the picker interface. The picker should update its
 * user interface to remove references to the detached color list and ensure
 * users can no longer access colors from the removed collection. This
 * supports dynamic color workspace management and application-specific color
 * collection control.
 */
- (void)detachColorList:(NSColorList *)aColorList;

//
// Showing Opacity Controls
//
/**
 * Responds to the addition or removal of alpha transparency controls in the
 * color panel interface. The sender parameter identifies the component that
 * initiated the alpha control change, typically the color panel itself. This
 * method is called when the color panel's opacity controls are shown or
 * hidden, allowing the picker to adjust its interface layout and
 * functionality accordingly. The picker should update its user interface to
 * accommodate or remove alpha selection controls, ensuring proper integration
 * with the panel's transparency features. This enables consistent alpha
 * channel handling across different picker implementations and maintains
 * visual coherence within the color panel system.
 */
- (void)alphaControlAddedOrRemoved:(id)sender;

//
// Responding to a Resized View
//
/**
 * Responds to size changes in the color panel or picker view hierarchy. The
 * sender parameter identifies the component that initiated or detected the
 * size change, typically the color panel or a parent view. This method is
 * called when the available display area for the picker changes due to
 * window resizing, panel reconfiguration, or interface layout updates. The
 * picker should adjust its user interface layout, control positioning, and
 * visual elements to optimize the user experience within the new dimensions.
 * This enables responsive interface behavior and ensures picker usability
 * across different window sizes and display configurations. Proper size
 * adaptation maintains interface quality and accessibility.
 */
- (void)viewSizeChanged:(id)sender;

@end

#endif // _GNUstep_H_NSColorPicking
