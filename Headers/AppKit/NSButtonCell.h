/*
   NSButtonCell.h

   The cell class for NSButton

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
	    Ovidiu Predescu <ovidiu@net-community.com>
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

#ifndef _GNUstep_H_NSButtonCell
#define _GNUstep_H_NSButtonCell
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSActionCell.h>

@class NSFont;
@class NSSound;

/** Type of button in an NSButton or NSButtonCell.
 * <deflist>
 *  <term>NSMomentaryPushInButton</term>
 *   <desc><em>Default button type!</em>  Pushed in and lit when mouse is
 *         down, pushed out and unlit when mouse is release.</desc>
 *  <term>NSPushOnPushOffButton</term>
 *   <desc>Used to show/store ON / OFF states.  In when ON, out when OFF.</desc>
 *  <term>NSToggleButton</term>
 *   <desc>Like NSPushOnPushOffButton but images is changed for ON and
 *         OFF state.</desc>
 *  <term>NSSwitchButton</term>
 *   <desc>A borderless NSToggleButton</desc>
 *  <term>NSRadioButton</term>
 *   <desc>A type of NSSwitchButton similar to a Microsoft Windows radio
 *         button.</desc>
 *  <term>NSMomentaryChangeButton</term>
 *   <desc>Image of button changes on mouse down and then changes back
 *         once released.</desc>
 *  <term>NSOnOffButton</term>
 *   <desc>Simple ON / OFF button.  First click lights the button,
 *         seconds click unlights it.</desc>
 *  <term>NSMomentaryLightButton</term>
 *   <desc>Like NSMomentaryPushInButton but button is not pushed
 *         in on mouse down</desc>
 *
 *  <term>NSMomentaryLight</term>
 *   <desc>Same as NSMomentaryPushInButton. Has been depricated in Cocoa.</desc>
 *  <term>NSMomentaryPushButton</term>
 *   <desc>Same as NSMomentaryLightButton. Has been depricated in
 *         Cocoa.</desc>
 * </deflist>
 */
typedef enum _NSButtonType {
  NSMomentaryLightButton,
  NSPushOnPushOffButton,
  NSToggleButton,
  NSSwitchButton,
  NSRadioButton,
  NSMomentaryChangeButton,
  NSOnOffButton,
  NSMomentaryPushInButton,
#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)
  NSAcceleratorButton,
  NSMultiLevelAcceleratorButton,
#endif
  // These are old names
  NSMomentaryLight = NSMomentaryPushInButton,
  NSMomentaryPushButton = NSMomentaryLightButton
} NSButtonType;

typedef enum _NSBezelStyle {
  NSRoundedBezelStyle = 1,
  NSRegularSquareBezelStyle,
  NSThickSquareBezelStyle,
  NSThickerSquareBezelStyle,
  NSDisclosureBezelStyle,
  NSShadowlessSquareBezelStyle,
  NSCircularBezelStyle,
  NSTexturedSquareBezelStyle,
  NSHelpButtonBezelStyle,
  NSSmallSquareBezelStyle,
  NSTexturedRoundedBezelStyle,
  NSRoundRectBezelStyle,
  NSRecessedBezelStyle,
  NSRoundedDisclosureBezelStyle,
  // The next five no longer show up in the MacOSX documentation
  NSNeXTBezelStyle,
  NSPushButtonBezelStyle,
  NSSmallIconButtonBezelStyle,
  NSMediumIconButtonBezelStyle,
  NSLargeIconButtonBezelStyle
} NSBezelStyle;

typedef enum _NSGradientType {
    NSGradientNone,
    NSGradientConcaveWeak,
    NSGradientConcaveStrong,
    NSGradientConvexWeak,
    NSGradientConvexStrong
} NSGradientType;


/**
 * NSButtonCell is the cell class responsible for displaying and handling
 * the behavior of buttons in the GNUstep GUI framework. It provides
 * functionality for various button types including push buttons, toggle
 * buttons, radio buttons, and switch buttons. The cell manages the button's
 * appearance, state, key equivalents, images, and user interaction behavior.
 *
 * As a subclass of NSActionCell, NSButtonCell inherits action and target
 * functionality while adding button-specific features such as alternate
 * titles and images for different button states, periodic actions for
 * continuous button presses, and customizable visual styles through
 * bezel styles and gradient types.
 */
APPKIT_EXPORT_CLASS
@interface NSButtonCell : NSActionCell
{
  // Attributes
  NSString *_altContents;
  NSImage *_altImage;
  NSString *_keyEquivalent;
  NSFont *_keyEquivalentFont;
  NSSound *_sound;
  NSUInteger _keyEquivalentModifierMask;
  NSInteger _highlightsByMask;
  NSInteger _showAltStateMask;
  float _delayInterval;
  float _repeatInterval;
  NSBezelStyle _bezel_style;
  NSGradientType _gradient_type;
  NSColor *_backgroundColor;
  // Think of the following as a BOOL ivars
#define _buttoncell_is_transparent _cell.subclass_bool_one
#define _image_dims_when_disabled _cell.subclass_bool_two
#define _shows_border_only_while_mouse_inside _cell.subclass_bool_three
#define _mouse_inside _cell.subclass_bool_four
  NSImageScaling _imageScaling;
}

//
// Setting the Titles
//
/**
 * Returns the alternate title displayed when the button is in its alternate
 * state. The alternate title is typically shown when the button is pressed
 * or highlighted, providing visual feedback to the user about the button's
 * current state.
 */
- (NSString *)alternateTitle;
/**
 * Sets the alternate title to be displayed when the button is in its
 * alternate state. This title is shown during button press or highlight
 * states, allowing for different text to appear based on the button's
 * current interaction state. Pass nil to remove the alternate title.
 */
- (void)setAlternateTitle: (NSString *)aString;
/**
 * Sets the font used to display both the regular and alternate titles
 * of the button cell. This font affects all text rendering within the
 * button, ensuring consistent typography across different button states.
 * The font object is retained by the button cell.
 */
- (void)setFont: (NSFont *)fontObject;
/**
 * Sets the primary title text displayed on the button. This is the
 * default text shown when the button is in its normal state. The title
 * string is copied and stored by the button cell. Pass nil to remove
 * the title text entirely.
 */
- (void)setTitle: (NSString *)aString;
/**
 * Returns the primary title text currently displayed on the button.
 * This is the main text shown when the button is in its normal,
 * non-highlighted state. Returns nil if no title has been set.
 */
- (NSString *)title;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the alternate title as an attributed string, providing access
 * to formatting information such as font, color, and style attributes
 * applied to the alternate title text. Returns nil if no alternate
 * attributed title has been set.
 */
- (NSAttributedString *)attributedAlternateTitle;
/**
 * Returns the primary title as an attributed string, including all
 * formatting attributes such as font, color, and text styling. This
 * provides richer text display capabilities than plain string titles.
 * Returns nil if no attributed title has been set.
 */
- (NSAttributedString *)attributedTitle;
/**
 * Sets the alternate title using an attributed string, allowing for
 * rich text formatting including font variations, colors, and other
 * text attributes. This attributed title is displayed when the button
 * is in its alternate state. Pass nil to remove the attributed alternate title.
 */
- (void)setAttributedAlternateTitle: (NSAttributedString *)aString;
/**
 * Sets the primary title using an attributed string, enabling rich
 * text formatting with fonts, colors, and styling attributes. This
 * becomes the main title displayed when the button is in its normal
 * state. Pass nil to remove the attributed title.
 */
- (void)setAttributedTitle: (NSAttributedString *)aString;
/**
 * Sets the primary title from a string that includes mnemonic markers,
 * typically ampersand characters that indicate keyboard shortcuts.
 * The mnemonic character is automatically processed to create the
 * appropriate key equivalent and visual underlining for accessibility.
 */
- (void)setTitleWithMnemonic: (NSString *)aString;
/**
 * Returns the mnemonic character extracted from the alternate title,
 * which represents the keyboard shortcut character for the button's
 * alternate state. Returns nil if no mnemonic has been set for the
 * alternate title.
 */
- (NSString *)alternateMnemonic;
/**
 * Returns the character position of the mnemonic within the alternate
 * title string. This indicates where the mnemonic character appears
 * for proper keyboard navigation and visual highlighting. Returns
 * NSNotFound if no mnemonic location is set.
 */
- (NSUInteger)alternateMnemonicLocation;
/**
 * Sets the character position within the alternate title where the
 * mnemonic character should be highlighted. This is used for keyboard
 * navigation accessibility and visual indication of the shortcut key.
 * Pass NSNotFound to remove the mnemonic location.
 */
- (void)setAlternateMnemonicLocation: (NSUInteger)location;
/**
 * Sets the alternate title from a string containing mnemonic markers,
 * automatically processing ampersand characters to create keyboard
 * shortcuts and visual indicators. The processed title becomes the
 * alternate title with appropriate mnemonic highlighting.
 */
- (void)setAlternateTitleWithMnemonic: (NSString *)aString;
#endif

//
// Setting the Images
//
/**
 * Returns the alternate image displayed when the button is in its
 * alternate state, such as when pressed or highlighted. The alternate
 * image provides visual feedback to indicate the button's current
 * interaction state. Returns nil if no alternate image is set.
 */
- (NSImage *)alternateImage;
/**
 * Returns the current positioning of the image relative to the title
 * text within the button cell. The image position determines the
 * layout arrangement of the image and text elements, such as image
 * above text, image to the left of text, or image only.
 */
- (NSCellImagePosition)imagePosition;
/**
 * Sets the alternate image to be displayed when the button is in its
 * alternate state. This image is shown during button press, highlight,
 * or other alternate state conditions. Pass nil to remove the alternate
 * image. The image object is retained by the button cell.
 */
- (void)setAlternateImage: (NSImage *)anImage;
/**
 * Sets the positioning of the image relative to the title text within
 * the button cell. This determines the visual layout of image and text
 * elements, controlling whether the image appears above, below, to the
 * left, to the right, or overlapping with the text.
 */
- (void)setImagePosition: (NSCellImagePosition)aPosition;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 * Returns the current image scaling mode used when displaying the
 * button's image. This determines how the image is resized to fit
 * within the available space, such as proportional scaling, scaling
 * to fit, or scaling to fill the entire area.
 */
- (NSImageScaling)imageScaling;
/**
 * Sets the image scaling mode that determines how the button's image
 * is resized to fit within the button's bounds. Different scaling
 * modes provide various behaviors for maintaining aspect ratio and
 * fitting images into the available display area.
 */
- (void)setImageScaling:(NSImageScaling)scaling;
#endif

//
// Setting the Repeat Interval
//
/**
 * Retrieves the current periodic delay and interval settings for
 * continuous button actions. The delay specifies how long to wait
 * before beginning repeated actions, while the interval specifies
 * the time between subsequent repeated actions. Both values are
 * returned through the provided pointer parameters.
 */
- (void)getPeriodicDelay: (float *)delay
		interval: (float *)interval;
/**
 * Sets the periodic delay and interval for continuous button actions
 * when the button is held down. The delay parameter specifies the
 * initial wait time before repeated actions begin, and the interval
 * parameter specifies the time between subsequent repeated actions.
 * This enables automatic repetition for buttons like scrollers.
 */
- (void)setPeriodicDelay: (float)delay
		interval: (float)interval;

//
// Setting the Key Equivalent
//
/**
 * Returns the key equivalent string that can be used to activate
 * this button via keyboard shortcut. The key equivalent is typically
 * a single character that, when pressed with appropriate modifier
 * keys, triggers the button's action. Returns nil if no key
 * equivalent is set.
 */
- (NSString *)keyEquivalent;
/**
 * Returns the font used to display the key equivalent symbol or
 * character within the button. This font may differ from the main
 * title font and is used specifically for rendering key equivalent
 * indicators. Returns nil if using the default system font.
 */
- (NSFont *)keyEquivalentFont;
/**
 * Returns the modifier key mask that must be pressed along with the
 * key equivalent to activate the button. This mask combines flags
 * like NSCommandKeyMask, NSShiftKeyMask, NSControlKeyMask, and
 * NSAlternateKeyMask to specify the required key combination.
 */
- (NSUInteger)keyEquivalentModifierMask;
/**
 * Sets the key equivalent string that allows keyboard activation of
 * the button. When this key is pressed with the appropriate modifier
 * keys, the button's action is triggered. Pass an empty string or
 * nil to remove the key equivalent. Common values include single
 * characters, escape sequences, or special key constants.
 */
- (void)setKeyEquivalent: (NSString *)key;
/**
 * Sets the modifier key mask that must be pressed along with the key
 * equivalent to activate the button. The mask should combine
 * appropriate flags like NSCommandKeyMask to specify which modifier
 * keys are required for the keyboard shortcut.
 */
- (void)setKeyEquivalentModifierMask: (NSUInteger)mask;
/**
 * Sets the font used for displaying key equivalent indicators within
 * the button. This font is used specifically for key equivalent
 * symbols and may be different from the main button title font.
 * Pass nil to use the default system font for key equivalents.
 */
- (void)setKeyEquivalentFont: (NSFont *)fontObj;
/**
 * Sets the key equivalent font using a font name and size. This
 * convenience method creates a font object from the specified name
 * and size, then sets it as the key equivalent font. The font is
 * used for rendering key equivalent indicators within the button.
 */
- (void)setKeyEquivalentFont: (NSString *)fontName
			size: (float)fontSize;

//
// Modifying Graphic Attributes
//
/**
 * Returns whether the button cell is configured to be transparent,
 * meaning its background does not draw and content behind it shows
 * through. Transparent buttons are useful for overlay controls and
 * custom drawing scenarios where background visibility is desired.
 */
- (BOOL)isTransparent;
/**
 * Sets whether the button cell should be transparent. When set to YES,
 * the button's background is not drawn, allowing content behind it to
 * show through. This is useful for creating overlay buttons or custom
 * visual effects where background transparency is needed.
 */
- (void)setTransparent: (BOOL)flag;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the current bezel style used for drawing the button's
 * border and background. The bezel style determines the visual
 * appearance of the button, including its shape, shadows, and
 * dimensional effects. Different styles provide various visual
 * treatments from flat to highly dimensional appearances.
 */
- (NSBezelStyle)bezelStyle;
/**
 * Sets the bezel style that determines the visual appearance of the
 * button's border and background. The bezel style controls the
 * button's shape, dimensionality, and visual treatment, ranging
 * from flat styles to highly dimensional effects with shadows
 * and highlighting.
 */
- (void)setBezelStyle: (NSBezelStyle)bezelStyle;
/**
 * Returns whether the button shows its border only when the mouse
 * cursor is positioned over it. This creates a hover effect where
 * the button appears borderless until mouse interaction, providing
 * a cleaner interface with interactive feedback.
 */
- (BOOL)showsBorderOnlyWhileMouseInside;
/**
 * Sets whether the button should display its border only during
 * mouse hover. When enabled, the button appears borderless until
 * the mouse enters its bounds, at which point the border appears
 * to provide visual feedback for potential interaction.
 */
- (void)setShowsBorderOnlyWhileMouseInside: (BOOL)show;
/**
 * Returns the current gradient type applied to the button's
 * background. The gradient type determines the direction and
 * intensity of shading effects, creating dimensional appearance
 * through light and shadow gradients across the button surface.
 */
- (NSGradientType)gradientType;
/**
 * Sets the gradient type for the button's background shading.
 * Different gradient types provide various dimensional effects
 * through directional shading, from subtle concave effects to
 * strong convex appearance with pronounced highlighting and
 * shadowing.
 */
- (void)setGradientType: (NSGradientType)gradientType;
/**
 * Returns whether the button's image automatically dims when the
 * button is disabled. When enabled, disabled buttons show their
 * images with reduced opacity or altered appearance to indicate
 * the non-interactive state visually.
 */
- (BOOL)imageDimsWhenDisabled;
/**
 * Sets whether the button's image should automatically dim when
 * the button becomes disabled. When enabled, this provides visual
 * feedback about the button's non-interactive state by reducing
 * image opacity or applying visual effects to indicate disability.
 */
- (void)setImageDimsWhenDisabled: (BOOL)flag;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Returns the background color used when drawing the button cell.
 * This color is applied behind the button's content and affects the
 * overall appearance of the button. Returns nil if using the default
 * system background color for the button's current style and state.
 */
- (NSColor *) backgroundColor;
/**
 * Sets the background color for the button cell. This color is drawn
 * behind the button's content and can be used to customize the
 * button's appearance beyond the standard bezel styles. Pass nil to
 * use the default system background color for the button's style.
 */
- (void) setBackgroundColor: (NSColor *)color;
/**
 * Draws the button's bezel (border and background) within the specified
 * frame in the given view. This method handles the visual rendering of
 * the button's dimensional appearance, including borders, background
 * fills, shadows, and other bezel-related visual elements.
 */
- (void) drawBezelWithFrame: (NSRect)cellFrame inView: (NSView*)controlView;
/**
 * Draws the specified image within the given frame in the control view.
 * This method handles the rendering of the button's image content,
 * including proper scaling, positioning, and state-dependent visual
 * effects such as dimming for disabled buttons.
 */
- (void) drawImage: (NSImage*)imageToDisplay
         withFrame: (NSRect)cellFrame
            inView: (NSView *)controlView;
/**
 * Draws the button's title text within the specified frame and returns
 * the actual rectangle used for text rendering. This method handles
 * text layout, font application, color application, and positioning
 * of the title content within the button's available space.
 */
- (NSRect) drawTitle: (NSAttributedString*)titleToDisplay
           withFrame: (NSRect)cellFrame
              inView: (NSView *)controlView;
#endif

//
// Modifying Graphic Attributes
//
/**
 * Returns the mask that specifies which user interactions cause the
 * button to highlight visually. The mask combines flags that determine
 * whether the button highlights on mouse down, mouse entered, content
 * changes, or other interaction states to provide visual feedback.
 */
- (NSInteger)highlightsBy;
/**
 * Sets the mask that determines which user interactions trigger visual
 * highlighting of the button. The mask combines various flags to specify
 * highlighting behavior for mouse down, mouse entry, content changes,
 * and other interactive states that should provide visual feedback.
 */
- (void)setHighlightsBy: (NSInteger)mask;
/**
 * Sets the mask that determines which conditions cause the button to
 * display its alternate state visually. This controls when the button
 * shows alternate titles, images, or other state-dependent visual
 * elements to reflect different operational conditions.
 */
- (void)setShowsStateBy: (NSInteger)mask;
/**
 * Configures the button's type, which determines its fundamental
 * interaction behavior and visual appearance. Different button types
 * provide distinct behaviors for state changes, highlighting, and
 * response to user interaction such as momentary, toggle, or radio
 * button behaviors.
 */
- (void)setButtonType: (NSButtonType)buttonType;
/**
 * Returns the mask that specifies which conditions cause the button
 * to show its alternate state visually. This mask determines when
 * alternate titles, images, or other state-dependent visual elements
 * are displayed to reflect the button's current operational state.
 */
- (NSInteger)showsStateBy;

//
// Sound
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Sets the sound that plays when the button is activated. The sound
 * provides auditory feedback for button interactions, enhancing the
 * user experience with audio cues. Pass nil to remove the button's
 * sound and disable audio feedback for button activation.
 */
- (void)setSound: (NSSound *)aSound;
/**
 * Returns the sound object that plays when the button is activated.
 * This sound provides auditory feedback for button interactions.
 * Returns nil if no sound has been assigned to the button or if
 * audio feedback is disabled for button activation.
 */
- (NSSound *)sound;
#endif

//
// Mouse
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Handles mouse entered events when the cursor moves into the button
 * cell's bounds. This method is called to update the button's
 * appearance for mouse hover effects, such as highlighting or showing
 * borders only while the mouse is inside the button area.
 */
- (void)mouseEntered: (NSEvent *)event;
/**
 * Handles mouse exited events when the cursor moves out of the button
 * cell's bounds. This method is called to update the button's
 * appearance when mouse interaction ends, such as removing hover
 * highlights or hiding borders that only show during mouse interaction.
 */
- (void)mouseExited: (NSEvent *)event;
#endif

@end

#endif // _GNUstep_H_NSButtonCell
