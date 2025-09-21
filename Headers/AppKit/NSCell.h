/* -*-objc-*-
   NSCell.h

   The abstract cell class

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

#ifndef _GNUstep_H_NSCell
#define _GNUstep_H_NSCell
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>

// For tint
#import <AppKit/NSColor.h>
// for NSWritingDirection
#import <AppKit/NSParagraphStyle.h>
// For text alignment
#import <AppKit/NSText.h>
// for NSFocusRingType
#import <AppKit/NSView.h>
#import <AppKit/NSUserInterfaceLayout.h>

@class NSString;
@class NSMutableDictionary;
@class NSView;
@class NSFont;
@class NSText;
@class NSFormatter;

enum _NSCellType {
  NSNullCellType,
  NSTextCellType,
  NSImageCellType
};
typedef NSUInteger NSCellType;

enum {
  NSAnyType,
  NSIntType,
  NSPositiveIntType,
  NSFloatType,
  NSPositiveFloatType,
  NSDoubleType,
  NSPositiveDoubleType,
  NSDateType
};

enum {
  NSNoImage = 0,
  NSImageOnly,
  NSImageLeft,
  NSImageRight,
  NSImageBelow,
  NSImageAbove,
  NSImageOverlaps
};
typedef NSUInteger NSCellImagePosition;

enum _NSCellAttribute {
  NSCellDisabled,
  NSCellState,
  NSPushInCell,
  NSCellEditable,
  NSChangeGrayCell,
  NSCellHighlighted,
  NSCellLightsByContents,
  NSCellLightsByGray,
  NSChangeBackgroundCell,
  NSCellLightsByBackground,
  NSCellIsBordered,
  NSCellHasOverlappingImage,
  NSCellHasImageHorizontal,
  NSCellHasImageOnLeftOrBottom,
  NSCellChangesContents,
  NSCellIsInsetButton,
  NSCellAllowsMixedState
};
typedef NSUInteger NSCellAttribute;

enum {
  NSNoCellMask			= 0,
  NSContentsCellMask		= 1,
  NSPushInCellMask		= 2,
  NSChangeGrayCellMask		= 4,
  NSChangeBackgroundCellMask	= 8
};

enum {
  GSCellTextImageXDist = 2,	// horizontal distance between the text and image rects.
  GSCellTextImageYDist = 2	// vertical distance between the text and image rects.
};

/*
 * We try to do as in macosx.
 */
enum {
  NSMixedState			= -1,
  NSOffState			= 0,
  NSOnState			= 1
};
typedef NSUInteger NSCellStateValue;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_13, GS_API_LATEST)
/*
 * Control state values as of 10.13
 */
enum {
  NSControlStateValueMixed = -1,
  NSControlStateValueOff   =  0,
  NSControlStateValueOn    =  1
};
typedef NSUInteger NSControlStateValue;
#endif

/**
 *  <p>Enumeration of the ways that you can display an image in an
 *  NSImageCell.  The available ones are:</p>
 *  <p><code>NSScaleNone</code>: The image is always displayed with
 *  its natural size.  If it's bigger than the cell size, it is
 *  cropped.</p>
 *  <p><code>NSScaleProportionally</code>: If the image is bigger
 *  than the cell size, it is displayed in its natural size.  If it
 *  is smaller than the cell size, it is resized down proportionally
 *  to fit the cell size.</p>
 *  <p><code>NSScaleToFit</code>: The image is always resized (up
 *  or down) to fit exactly in the cell size.</p>
 */
enum {
  NSScaleProportionally = 0,
  NSScaleToFit = 1,
  NSScaleNone = 2,
  NSImageScaleProportionallyDown = 0,
  NSImageScaleAxesIndependently = 1,
  NSImageScaleNone = 2,
  NSImageScaleProportionallyUpOrDown = 3
};
typedef NSUInteger NSImageScaling;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
enum {
  NSCellHitNone = 0,
  NSCellHitContentArea = 1,
  NSCellHitEditableTextArea = 2,
  NSCellHitTrackableArea = 4
};
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)
typedef NSUInteger NSCellHitResult;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
enum {
  NSBackgroundStyleLight = 0,
  NSBackgroundStyleNormal = 0,
  NSBackgroundStyleDark = 1,
  NSBackgroundStyleEmphasized = 1,
  NSBackgroundStyleRaised = 2,
  NSBackgroundStyleLowered = 3
};
typedef NSInteger NSBackgroundStyle;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)
enum __NSControlSize {
  NSControlSizeRegular,
  NSControlSizeSmall,
  NSControlSizeMini
};
#endif

/**
 * NSCell is the abstract base class that defines the fundamental behavior
 * for objects that display content and handle user interaction within
 * controls. Cells are lightweight objects that can display text, images,
 * or other content without the overhead of a full view. They are commonly
 * used as components within controls like buttons, text fields, and table
 * views to provide efficient rendering and interaction handling.
 *
 * The cell architecture separates the visual representation and behavior
 * from the containing control, allowing multiple cells to share common
 * functionality while being customized for specific display requirements.
 * This design enables efficient memory usage and fast drawing performance
 * for controls that display many similar elements.
 *
 * NSCell provides comprehensive support for various content types including
 * plain text, attributed strings, images, and formatted data through
 * formatters. It handles user interaction through target-action patterns,
 * supports various visual states like highlighting and enabling/disabling,
 * and provides extensive customization options for appearance and behavior.
 *
 * Common subclasses include NSTextFieldCell for text display and editing,
 * NSButtonCell for button-like behavior, NSImageCell for image display,
 * and various specialized cells for specific control types. The cell system
 * forms the foundation for most user interface controls in the AppKit.
 */
APPKIT_EXPORT_CLASS
@interface NSCell : NSObject <NSCopying, NSCoding>
{
  // Attributes
  id _contents;
  NSImage *_cell_image;
  NSFont *_font;
  id _object_value;
  struct GSCellFlagsType {
    // total 32 bits.  0 bits left.
    unsigned contents_is_attributed_string: 1;
    unsigned is_highlighted: 1;
    unsigned is_disabled: 1;
    unsigned is_editable: 1;
    unsigned is_rich_text: 1;
    unsigned imports_graphics: 1;
    unsigned shows_first_responder: 1;
    unsigned refuses_first_responder: 1;
    unsigned sends_action_on_end_editing: 1;
    unsigned is_bordered: 1;
    unsigned is_bezeled: 1;
    unsigned is_scrollable: 1;
    unsigned reserved: 1;
    unsigned text_align: 3; // 5 values
    unsigned is_selectable: 1;
    unsigned allows_mixed_state: 1;
    unsigned has_valid_object_value: 1;
    unsigned type: 2;           // 3 values
    unsigned image_position: 3; // 7 values
    unsigned entry_type: 4;     // 8 values
    unsigned allows_undo: 1;
    unsigned line_break_mode: 3; // 6 values

    // 23 bits for NSCell use, 4 bits for subclass use.
    // 5 bits remain unused.
    int state: 2; // 3 values but one negative
    unsigned mnemonic_location: 8;
    unsigned control_tint: 3;
    unsigned control_size: 2;
    unsigned focus_ring_type: 2; // 3 values
    unsigned base_writing_direction: 2; // 3 values
    // 4 bits reserved for subclass use
    unsigned subclass_bool_one: 1;
    unsigned subclass_bool_two: 1;
    unsigned subclass_bool_three: 1;
    unsigned subclass_bool_four: 1;
    // Set while the cell is edited/selected
    unsigned in_editing: 1;
    // Set if cell uses single line mode.
    unsigned uses_single_line_mode:1;
    unsigned background_style: 2; // 3 values
  } _cell;
  NSUInteger _mouse_down_flags;
  NSUInteger _action_mask;
  NSFormatter *_formatter;
  NSMenu *_menu;
  id _represented_object;
  void *_reserved1;
}

//
// Class methods
//
#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Returns the default focus ring type used by cells when no specific
 * focus ring type has been set. The focus ring provides visual indication
 * when a cell has keyboard focus, helping users understand which element
 * will respond to keyboard input. The default type depends on system
 * preferences and the current user interface theme.
 */
+ (NSFocusRingType)defaultFocusRingType;
#endif
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the default menu used by cells when no specific menu has been
 * assigned. This provides a standard context menu for cell interactions,
 * typically containing common operations like copy, paste, and formatting
 * options appropriate for the cell's content type and current state.
 */
+ (NSMenu *)defaultMenu;
#endif
/**
 * Returns whether cells prefer to continue tracking mouse events until
 * the mouse button is released, rather than stopping when the mouse
 * leaves the cell's bounds. This affects how cells handle extended
 * mouse interactions and determines the default tracking behavior
 * for mouse-down events within cell boundaries.
 */
+ (BOOL)prefersTrackingUntilMouseUp;

//
// Initializing an NSCell
//
/**
 * Initializes a cell for displaying an image. The cell is configured
 * with image display capabilities and the specified image becomes the
 * cell's primary content. This creates an NSImageCellType cell that
 * is optimized for image rendering and handles image-specific display
 * properties like scaling and positioning within the cell bounds.
 */
- (id)initImageCell:(NSImage *)anImage;
/**
 * Initializes a cell for displaying text content. The cell is configured
 * as an NSTextCellType with the specified string as its initial content.
 * This creates a text-capable cell that supports text editing, formatting,
 * and display properties like font, alignment, and text attributes.
 */
- (id)initTextCell:(NSString *)aString;

//
// Setting the NSCell's Value
//
/**
 * Returns the cell's current value as an object. This is the primary
 * method for accessing the cell's content in its native object form,
 * which could be a string, number, date, or other object type depending
 * on the cell's configuration and the type of data it represents.
 */
- (id)objectValue;
/**
 * Returns whether the cell currently contains a valid object value.
 * This indicates if the cell's content represents valid data that can
 * be used for display or processing, as opposed to placeholder or
 * invalid content that might result from failed validation or parsing.
 */
- (BOOL)hasValidObjectValue;
/**
 * Returns the cell's value as a double-precision floating point number.
 * If the cell's content cannot be converted to a numeric value, this
 * returns zero. The conversion handles various string representations
 * of numbers and uses any assigned formatter for interpretation.
 */
- (double)doubleValue;
/**
 * Returns the cell's value as a single-precision floating point number.
 * Similar to doubleValue, this converts the cell's content to a numeric
 * representation, returning zero if conversion is not possible. Formatters
 * are used if available to interpret string representations of numbers.
 */
- (float)floatValue;
/**
 * Returns the cell's value as an integer. The cell's content is converted
 * to an integer representation, with string values parsed numerically.
 * Non-numeric content results in a return value of zero. Formatters
 * assist in interpreting complex string representations when present.
 */
- (int)intValue;
/**
 * Returns the cell's value as a string representation. This provides
 * a textual representation of the cell's content regardless of the
 * underlying data type. Objects are converted using their string
 * description methods, and formatters are applied when available.
 */
- (NSString *)stringValue;
/**
 * Sets the cell's value using an arbitrary object. This is the primary
 * method for setting cell content and accepts any object type. The
 * cell stores the object and uses it for display and value conversion
 * operations. Pass nil to clear the cell's content.
 */
- (void) setObjectValue:(id)object;
/**
 * Sets the cell's value from a double-precision floating point number.
 * The numeric value is stored and can be retrieved in various formats.
 * If a formatter is assigned to the cell, it may be used to control
 * how the numeric value is displayed as text.
 */
- (void)setDoubleValue:(double)aDouble;
/**
 * Sets the cell's value from a single-precision floating point number.
 * Similar to setDoubleValue, this stores a numeric value that can be
 * accessed in different formats and displayed according to any assigned
 * formatter's specifications for numeric presentation.
 */
- (void)setFloatValue:(float)aFloat;
/**
 * Sets the cell's value from an integer. The integer value is stored
 * and becomes available through the various value accessor methods.
 * Display formatting is handled by any assigned formatter, allowing
 * for customized presentation of the numeric content.
 */
- (void)setIntValue:(int)anInt;
/**
 * Sets the cell's value from a string. The string becomes the cell's
 * content and may be parsed into other data types when accessed through
 * numeric value methods. Formatters can provide additional parsing
 * and validation capabilities for string content interpretation.
 */
- (void)setStringValue:(NSString *)aString;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
- (NSInteger) integerValue;
- (void) setIntegerValue: (NSInteger)anInt;
- (void) takeIntegerValueFrom: (id)sender;
#endif
//
// Setting Parameters
//
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
//
// Setting Parameters
//
/**
 * Returns the value of the specified cell attribute parameter. Cell
 * attributes control various aspects of the cell's behavior and appearance,
 * such as whether it's selectable, editable, or has scrollable content.
 * The returned value interpretation depends on the specific attribute type.
 */
- (NSInteger)cellAttribute:(NSCellAttribute)aParameter;
/**
 * Sets the value for the specified cell attribute parameter. This method
 * configures various behavioral and display characteristics of the cell
 * by modifying the appropriate attribute flags. Different attributes
 * accept different value ranges and meanings for their parameters.
 */
- (void)setCellAttribute:(NSCellAttribute)aParameter
                      to:(NSInteger)value;
#endif//
// Setting the NSCell's Type
//
/**
 * Sets the cell's type which determines its fundamental display and
 * interaction characteristics. The type affects how the cell renders
 * its content, handles user interaction, and manages its internal
 * state. Common types include text cells and image cells.
 */
- (void)setType:(NSCellType)aType;
/**
 * Returns the cell's current type identifier. The type indicates the
 * basic category of cell behavior and determines the primary methods
 * used for content display and user interaction. This affects the
 * cell's rendering strategy and available configuration options.
 */
- (NSCellType)type;

//
// Enabling and Disabling the NSCell
//
/**
 * Returns whether the cell is currently enabled for user interaction.
 * Enabled cells respond to user actions like clicks and key presses,
 * while disabled cells typically appear dimmed and ignore user input.
 * This setting affects both visual appearance and interactive behavior.
 */
- (BOOL)isEnabled;
/**
 * Sets whether the cell should be enabled for user interaction. When
 * disabled, the cell typically appears grayed out and does not respond
 * to user actions. This is commonly used to indicate unavailable
 * functionality or to prevent interaction during processing states.
 */
- (void)setEnabled:(BOOL)flag;

//
// Modifying Graphic Attributes
//
/**
 * Returns whether the cell is drawn with a bezeled appearance. Bezeled
 * cells have a three-dimensional border that creates a raised or recessed
 * visual effect, commonly used for buttons and other interactive elements
 * to provide visual feedback about their clickable nature.
 */
- (BOOL)isBezeled;
/**
 * Returns whether the cell is drawn with a simple border. Bordered cells
 * have a flat outline around their content area, providing visual separation
 * without the dimensional effects of bezeling. This is often used for
 * text fields and other content areas that need clear boundaries.
 */
- (BOOL)isBordered;
/**
 * Returns whether the cell is completely opaque when drawn. Opaque cells
 * fill their entire bounds with content, allowing the drawing system to
 * optimize rendering by skipping transparency calculations. Non-opaque
 * cells may have transparent areas that blend with background content.
 */
- (BOOL)isOpaque;
/**
 * Sets whether the cell should be drawn with a bezeled appearance. When
 * enabled, the cell displays with three-dimensional border effects that
 * create visual depth. This is typically used for interactive elements
 * like buttons to indicate their pressable nature to users.
 */
- (void)setBezeled:(BOOL)flag;
/**
 * Sets whether the cell should be drawn with a simple border outline.
 * Bordered cells have a flat perimeter that defines their content area
 * without three-dimensional effects. This provides clear visual boundaries
 * while maintaining a clean, flat appearance for modern interfaces.
 */
- (void)setBordered:(BOOL)flag;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
- (NSFocusRingType)focusRingType;
- (void)setFocusRingType:(NSFocusRingType)type;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_8, GS_API_LATEST)
#if GS_HAS_DECLARED_PROPERTIES
@property NSUserInterfaceLayoutDirection userInterfaceLayoutDirection;
#else
- (NSUserInterfaceLayoutDirection) userInterfaceLayoutDirection;
- (void) setUserInterfaceLayoutDirection: (NSUserInterfaceLayoutDirection)dir;
#endif
#endif

//
// Setting the NSCell's State
//
/**
 * Sets the cell's state value which controls its visual appearance and
 * behavior. Common state values include on, off, and mixed states for
 * controls like checkboxes and buttons. The state affects how the cell
 * renders itself and may trigger associated actions when changed.
 */
- (void)setState:(NSInteger)value;
/**
 * Returns the cell's current state value. The state represents the cell's
 * current condition or setting, such as whether a checkbox is checked,
 * unchecked, or in a mixed state. This value determines the cell's
 * visual representation and behavioral characteristics.
 */
- (NSInteger)state;
/**
 * Returns whether the cell supports a mixed state in addition to its
 * primary on and off states. Mixed state is useful for hierarchical
 * controls where some but not all child elements are selected, or for
 * representing indeterminate conditions in the user interface.
 */
- (BOOL)allowsMixedState;
/**
 * Sets whether the cell should support mixed state functionality. When
 * enabled, the cell can display and respond to a third state between
 * its primary on and off conditions, typically used for partial or
 * indeterminate selections in hierarchical or grouped controls.
 */
- (void)setAllowsMixedState:(BOOL)flag;
/**
 * Returns the state value that would follow the current state in the
 * cell's state cycle. For cells with mixed state support, this cycles
 * through off, on, and mixed values. For binary cells, it alternates
 * between off and on states as appropriate for the cell type.
 */
- (NSInteger)nextState;
/**
 * Advances the cell to its next state in the state progression cycle.
 * This method updates the cell's state value to the next logical value,
 * cycling through available states as determined by the cell's configuration
 * and mixed state support settings.
 */
- (void)setNextState;

//
// Modifying Text Attributes
//
/**
 * Returns the text alignment setting for the cell's content. This
 * determines how text is positioned within the cell's bounds, with
 * options for left, right, center, justified, and natural alignment
 * based on the text's writing direction and locale preferences.
 */
- (NSTextAlignment)alignment;
/**
 * Returns the font used for displaying the cell's text content. The
 * font determines the typeface, size, and style characteristics used
 * for rendering text, affecting both appearance and text metrics for
 * layout calculations within the cell's display area.
 */
- (NSFont *)font;
/**
 * Returns whether the cell's text content can be edited by the user.
 * Editable cells allow direct text input and modification, typically
 * displaying a text cursor and accepting keyboard input when activated.
 * Non-editable cells display text as read-only content.
 */
- (BOOL)isEditable;
/**
 * Returns whether the cell's text content can be selected by the user.
 * Selectable cells allow users to highlight text for copying or other
 * operations, even if the text cannot be edited. This is useful for
 * displaying copyable information in read-only contexts.
 */
- (BOOL)isSelectable;
/**
 * Returns whether the cell's content area supports scrolling when the
 * content exceeds the visible bounds. Scrollable cells can display
 * content larger than their frame by allowing users to scroll through
 * the text or other content using keyboard navigation or scroll gestures.
 */
- (BOOL)isScrollable;
/**
 * Sets the text alignment for content displayed within the cell. The
 * alignment affects how text is positioned horizontally within the
 * cell's bounds and may interact with the text's natural writing
 * direction for proper internationalization support.
 */
- (void)setAlignment:(NSTextAlignment)mode;
/**
 * Sets whether the cell's text content should be editable by users.
 * Editable cells support direct text input and modification, while
 * non-editable cells display content as read-only. This affects both
 * the visual appearance and the interactive behavior of the cell.
 */
- (void)setEditable:(BOOL)flag;
/**
 * Sets the font to be used for displaying the cell's text content.
 * The font affects the visual appearance, size, and style of rendered
 * text, and influences layout calculations for text positioning and
 * cell sizing based on content requirements.
 */
- (void)setFont:(NSFont *)fontObject;
/**
 * Sets whether the cell's text content should be selectable by users.
 * Selectable cells allow text highlighting for operations like copying,
 * even when editing is disabled. This enables user interaction with
 * text content without allowing modifications.
 */
- (void)setSelectable:(BOOL)flag;
/**
 * Sets whether the cell should support scrolling when content exceeds
 * the visible area. Scrollable cells can accommodate content larger
 * than their display bounds by enabling navigation through the content
 * using keyboard controls or other scrolling mechanisms.
 */
- (void)setScrollable:(BOOL)flag;
/**
 * Sets whether text content should wrap to multiple lines when it
 * exceeds the cell's width. Text wrapping allows longer content to
 * be displayed by breaking it across lines rather than truncating
 * or requiring horizontal scrolling to view all content.
 */
- (void)setWraps:(BOOL)flag;
/**
 * Returns whether the cell's text content wraps to multiple lines
 * when it exceeds the available width. Wrapping cells display long
 * text across multiple lines within the cell's bounds, while non-wrapping
 * cells may truncate or scroll content that doesn't fit horizontally.
 */
- (BOOL)wraps;
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObject;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)setAttributedStringValue:(NSAttributedString *)attribStr;
- (NSAttributedString *)attributedStringValue;
- (void)setAllowsEditingTextAttributes:(BOOL)flag;
- (BOOL)allowsEditingTextAttributes;
- (void)setImportsGraphics:(BOOL)flag;
- (BOOL)importsGraphics;
- (void)setTitle:(NSString *)aString;
- (NSString *)title;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (NSWritingDirection)baseWritingDirection;
- (void)setBaseWritingDirection:(NSWritingDirection)direction;
- (NSLineBreakMode)lineBreakMode;
- (void)setLineBreakMode:(NSLineBreakMode)mode;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
- (void) setUsesSingleLineMode: (BOOL)flag;
- (BOOL) usesSingleLineMode;
#endif

//
// Target and Action
//
- (SEL)action;
- (BOOL)isContinuous;
- (NSInteger)sendActionOn:(NSInteger)mask;
- (void)setAction:(SEL)aSelector;
- (void)setContinuous:(BOOL)flag;
- (void)setTarget:(id)anObject;
- (id)target;

//
// Setting the Image
//
- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

//
// Assigning a Tag
//
- (void)setTag:(NSInteger)anInt;
- (NSInteger)tag;

//
// Formatting Data and Validating Input
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)setFormatter:(NSFormatter *)newFormatter;
- (id)formatter;
#endif
- (NSInteger)entryType;
- (BOOL)isEntryAcceptable:(NSString *)aString;
- (void)setEntryType:(NSInteger)aType;
- (void)setFloatingPointFormat:(BOOL)autoRange
                          left:(NSUInteger)leftDigits
                         right:(NSUInteger)rightDigits;

//
// Menu
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)setMenu:(NSMenu *)aMenu;
- (NSMenu *)menu;
- (NSMenu *)menuForEvent:(NSEvent *)anEvent
                  inRect:(NSRect)cellFrame
                  ofView:(NSView *)aView;
#endif

//
// Comparing to Another NSCell
//
- (NSComparisonResult)compare:(id)otherCell;

//
// respond to keyboard
//
// All these methods except -performClick: are provided only for some
// compatibility with MacOS-X code and their use in new programs is
// deprecated.  Please use -isEnabled, -setEnabled: instead of
// -acceptsFirstReponder, -refusesFirstResponder,
// -setRefusesFirstResponder:.  Mnemonics (eg 'File' with the 'F'
// underlined as in MS Windows(tm) menus) are not part of GNUstep's
// interface so methods referring to mnemonics do nothing -- they are
// provided for compatibility only; please use key equivalents instead
// in your GNUstep programs.
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (BOOL)acceptsFirstResponder;
- (void)setShowsFirstResponder:(BOOL)flag;
- (BOOL)showsFirstResponder;
- (void)setTitleWithMnemonic:(NSString *)aString;
- (NSString *)mnemonic;
- (void)setMnemonicLocation:(NSUInteger)location;
- (NSUInteger)mnemonicLocation;
- (BOOL)refusesFirstResponder;
- (void)setRefusesFirstResponder:(BOOL)flag;

// deprecated method now in favor of performClickWithFrame:inView:
- (void)performClick:(id)sender;

- (void)performClickWithFrame: (NSRect)cellFrame
                       inView: (NSView *)controlView;
#endif

//
// Interacting with Other NSCells
//
- (void)takeObjectValueFrom: (id)sender;
- (void)takeDoubleValueFrom:(id)sender;
- (void)takeFloatValueFrom:(id)sender;
- (void)takeIntValueFrom:(id)sender;
- (void)takeStringValueFrom:(id)sender;

//
// Using the NSCell to Represent an Object
//
- (id)representedObject;
- (void)setRepresentedObject:(id)anObject;

//
// Tracking the Mouse
//
- (BOOL)continueTracking:(NSPoint)lastPoint
		      at:(NSPoint)currentPoint
		  inView:(NSView *)controlView;
- (NSInteger)mouseDownFlags;
- (void)getPeriodicDelay:(float *)delay
		interval:(float *)interval;
- (BOOL)startTrackingAt:(NSPoint)startPoint
		 inView:(NSView *)controlView;
- (void)stopTracking:(NSPoint)lastPoint
		  at:(NSPoint)stopPoint
	      inView:(NSView *)controlView
		  mouseIsUp:(BOOL)flag;
- (BOOL)trackMouse:(NSEvent *)theEvent
	    inRect:(NSRect)cellFrame
	    ofView:(NSView *)controlView
	    untilMouseUp:(BOOL)flag;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
- (NSBackgroundStyle)backgroundStyle;
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)
- (NSCellHitResult)hitTestForEvent:(NSEvent *)event
                       inRect:(NSRect)cellFrame
                       ofView:(NSView *)controlView;
#else
- (NSUInteger)hitTestForEvent:(NSEvent *)event
                       inRect:(NSRect)cellFrame
                       ofView:(NSView *)controlView;
#endif
#endif

//
// Managing the Cursor
//
- (void)resetCursorRect:(NSRect)cellFrame
		 inView:(NSView *)controlView;

//
// Handling Keyboard Alternatives
//
- (NSString *)keyEquivalent;

//
// Determining Component Sizes
//
- (void)calcDrawInfo:(NSRect)aRect;
- (NSSize)cellSize;
- (NSSize)cellSizeForBounds:(NSRect)aRect;
- (NSRect)drawingRectForBounds:(NSRect)theRect;
- (NSRect)imageRectForBounds:(NSRect)theRect;
- (NSRect)titleRectForBounds:(NSRect)theRect;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)setControlSize:(NSControlSize)controlSize;
- (NSControlSize)controlSize;
#endif

//
// Displaying
//
- (NSView *)controlView;
- (void)drawInteriorWithFrame:(NSRect)cellFrame
		       inView:(NSView *)controlView;
- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView;
- (void)highlight:(BOOL)lit
	withFrame:(NSRect)cellFrame
	   inView:(NSView *)controlView;
- (BOOL)isHighlighted;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)setHighlighted: (BOOL) flag;
- (NSColor*)highlightColorWithFrame:(NSRect)cellFrame
			     inView:(NSView *)controlView;
- (void)setControlTint:(NSControlTint)controlTint;
- (NSControlTint)controlTint;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (void)setControlView:(NSView*)view;
#endif


//
// Editing Text
//
- (void)editWithFrame:(NSRect)aRect
	       inView:(NSView *)controlView
	       editor:(NSText *)textObject
	       delegate:(id)anObject
		event:(NSEvent *)theEvent;
- (void)selectWithFrame:(NSRect)aRect
		 inView:(NSView *)controlView
		 editor:(NSText *)textObject
		 delegate:(id)anObject
		  start:(NSInteger)selStart
		 length:(NSInteger)selLength;
- (void)endEditing:(NSText *)textObject;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (BOOL)sendsActionOnEndEditing;
- (void)setSendsActionOnEndEditing:(BOOL)flag;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (BOOL)allowsUndo;
- (void)setAllowsUndo:(BOOL)flag;
#endif

@end

//
// Methods that are private GNUstep extensions
//
@interface NSCell (PrivateMethods)

- (NSDictionary*) _nonAutoreleasedTypingAttributes;
- (NSColor*) textColor;
- (NSSize) _sizeText: (NSString*) title;
- (void) _drawText: (NSString*)aString  inFrame: (NSRect)cellFrame;
- (void) _drawAttributedText: (NSAttributedString*)aString
		     inFrame: (NSRect)aRect;
- (BOOL) _sendsActionOn:(NSUInteger)eventTypeMask;
- (NSAttributedString*) _drawAttributedString;
- (void) _drawBorderAndBackgroundWithFrame: (NSRect)cellFrame
                                    inView: (NSView*)controlView;
- (void) _drawFocusRingWithFrame: (NSRect)cellFrame
                          inView: (NSView*)controlView;
- (void) _drawEditorWithFrame: (NSRect)cellFrame
		       inView: (NSView*)controlView;
- (void) _setInEditing: (BOOL)flag;
- (void) _updateFieldEditor: (NSText*)textObject;
@end

#endif // _GNUstep_H_NSCell

