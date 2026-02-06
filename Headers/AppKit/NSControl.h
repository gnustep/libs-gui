/*
   NSControl.h

   The abstract control class

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
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSControl
#define _GNUstep_H_NSControl
#import <AppKit/AppKitDefines.h>

// for NSWritingDirection
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSView.h>

@class NSString;
@class NSNotification;
@class NSFormatter;

@class NSCell;
@class NSFont;
@class NSEvent;
@class NSTextView;

/**
 * NSControl is an abstract class that defines the common interface and
 * behavior for user interface controls. It provides the basic functionality
 * for controls that use NSCell objects to display content and handle user
 * interaction. NSControl manages the relationship between the control and
 * its cell, handles target-action messaging, and provides methods for
 * value management and display.
 *
 * Key features include:
 * - Cell-based architecture for content display and editing
 * - Target-action mechanism for user interaction
 * - Value management with type conversion methods
 * - Text formatting and editing support
 * - Mouse tracking and event handling
 * - Integration with field editor for text input
 *
 * NSControl is subclassed by concrete controls like NSButton, NSTextField,
 * NSSlider, and others that implement specific user interface elements.
 */
APPKIT_EXPORT_CLASS
@interface NSControl : NSView
{
  // Attributes
  NSInteger _tag;
  id _cell; // id so compiler wont complain too much for subclasses
  BOOL _ignoresMultiClick;
}

//
// Setting the Control's Cell
//
/**
 * Returns the default cell class used by this control class.
 * Returns: The Class object representing the default cell type
 */
+ (Class)cellClass;

/**
 * Sets the default cell class for this control class.
 * factoryId: The Class object to use as the default cell class
 */
+ (void)setCellClass:(Class)factoryId;

/**
 * Returns the cell object used by this control.
 * Returns: The NSCell object managing the control's content and behavior
 */
- (id)cell;

/**
 * Sets the cell object for this control.
 * aCell: The NSCell object to use for managing content and behavior
 */
- (void)setCell:(NSCell *)aCell;

//
// Enabling and Disabling the Control
//
/**
 * Returns whether the control is enabled for user interaction.
 * Returns: YES if the control is enabled, NO if disabled
 */
- (BOOL)isEnabled;

/**
 * Sets whether the control is enabled for user interaction.
 * flag: YES to enable the control, NO to disable it
 */
- (void)setEnabled:(BOOL)flag;

//
// Identifying the Selected Cell
//
/**
 * Returns the currently selected cell.
 * Returns: The NSCell object that is currently selected, or nil if none
 */
- (id)selectedCell;

/**
 * Returns the tag of the currently selected cell.
 * Returns: The tag value of the selected cell, or -1 if none selected
 */
- (NSInteger)selectedTag;

//
// Setting the Control's Value
//
/**
 * Sets the control's value as a double.
 * aDouble: The double value to set
 */
- (void) setDoubleValue: (double)aDouble;

/**
 * Returns the control's value as a double.
 * Returns: The double representation of the control's value
 */
- (double) doubleValue;

/**
 * Sets the control's value as a float.
 * aFloat: The float value to set
 */
- (void) setFloatValue: (float)aFloat;

/**
 * Returns the control's value as a float.
 * Returns: The float representation of the control's value
 */
- (float) floatValue;

/**
 * Sets the control's value as an integer.
 * anInt: The integer value to set
 */
- (void) setIntValue: (int)anInt;

/**
 * Returns the control's value as an integer.
 * Returns: The integer representation of the control's value
 */
- (int) intValue;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 * Returns the control's value as an NSInteger.
 * Returns: The NSInteger representation of the control's value
 */
- (NSInteger) integerValue;

/**
 * Sets the control's value as an NSInteger.
 * anInt: The NSInteger value to set
 */
- (void) setIntegerValue: (NSInteger)anInt;

/**
 * Sets the control's value from the integer value of the sender.
 * sender: The object whose integer value should be used
 */
- (void) takeIntegerValueFrom: (id)sender;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)
/**
 * Returns the optimal size for the control within the given constraints.
 * size: The maximum size constraints
 * Returns: The optimal size for the control
 */
- (NSSize) sizeThatFits: (NSSize)size;
#endif

/**
 * Sets the control's value as a string.
 * aString: The string value to set
 */
- (void) setStringValue: (NSString *)aString;

/**
 * Returns the control's value as a string.
 * Returns: The string representation of the control's value
 */
- (NSString *) stringValue;

/**
 * Sets the control's value as an object.
 * anObject: The object value to set
 */
- (void) setObjectValue: (id)anObject;

/**
 * Returns the control's value as an object.
 * Returns: The object representation of the control's value
 */
- (id) objectValue;

/**
 * Marks the control as needing display refresh.
 */
- (void) setNeedsDisplay;

//
// Interacting with Other Controls
//
/**
 * Sets the control's value from the double value of the sender.
 * sender: The object whose double value should be used
 */
- (void) takeDoubleValueFrom: (id)sender;

/**
 * Sets the control's value from the float value of the sender.
 * sender: The object whose float value should be used
 */
- (void) takeFloatValueFrom: (id)sender;

/**
 * Sets the control's value from the integer value of the sender.
 * sender: The object whose integer value should be used
 */
- (void) takeIntValueFrom: (id)sender;

/**
 * Sets the control's value from the string value of the sender.
 * sender: The object whose string value should be used
 */
- (void) takeStringValueFrom: (id)sender;

/**
 * Sets the control's value from the object value of the sender.
 * sender: The object whose object value should be used
 */
- (void) takeObjectValueFrom: (id)sender;

//
// Formatting Text
//
/**
 * Returns the text alignment used by the control.
 * Returns: The NSTextAlignment value indicating text alignment
 */
- (NSTextAlignment)alignment;

/**
 * Returns the font used by the control.
 * Returns: The NSFont object used for displaying text
 */
- (NSFont *)font;

/**
 * Sets the text alignment used by the control.
 * mode: The NSTextAlignment value to use for text alignment
 */
- (void)setAlignment:(NSTextAlignment)mode;

/**
 * Sets the font used by the control.
 * fontObject: The NSFont object to use for displaying text
 */
- (void)setFont:(NSFont *)fontObject;

/**
 * Sets the floating point number format for the control.
 * autoRange: YES to automatically determine range, NO for fixed format
 * leftDigits: Number of digits to display to the left of decimal point
 * rightDigits: Number of digits to display to the right of decimal point
 */
- (void)setFloatingPointFormat:(BOOL)autoRange
			  left:(NSUInteger)leftDigits
			 right:(NSUInteger)rightDigits;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Sets the formatter for the control's cell.
 * newFormatter: The NSFormatter object to use for formatting values
 */
- (void)setFormatter:(NSFormatter*)newFormatter;

/**
 * Returns the formatter used by the control's cell.
 * Returns: The NSFormatter object used for formatting, or nil if none
 */
- (id)formatter;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Returns the base writing direction for the control's text.
 * Returns: The NSWritingDirection indicating text direction
 */
- (NSWritingDirection)baseWritingDirection;

/**
 * Sets the base writing direction for the control's text.
 * direction: The NSWritingDirection to use for text layout
 */
- (void)setBaseWritingDirection:(NSWritingDirection)direction;
#endif

//
// Managing the Field Editor
//
/**
 * Aborts current editing session and discards changes.
 * Returns: YES if editing was successfully aborted, NO otherwise
 */
- (BOOL)abortEditing;

/**
 * Returns the current field editor being used for text editing.
 * Returns: The NSText object serving as the field editor, or nil if none
 */
- (NSText *)currentEditor;

/**
 * Validates the current editing session and commits changes.
 */
- (void)validateEditing;

//
// Resizing the Control
//
/**
 * Calculates the optimal size for the control.
 */
- (void)calcSize;

/**
 * Resizes the control to fit its content optimally.
 */
- (void)sizeToFit;

//
// Displaying the Control and Cell
//
/**
 * Draws the specified cell within the control.
 * aCell: The NSCell object to draw
 */
- (void)drawCell:(NSCell *)aCell;

/**
 * Draws the interior of the specified cell.
 * aCell: The NSCell object whose interior should be drawn
 */
- (void)drawCellInside:(NSCell *)aCell;

/**
 * Selects the specified cell for interaction.
 * aCell: The NSCell object to select
 */
- (void)selectCell:(NSCell *)aCell;

/**
 * Updates the specified cell's display.
 * aCell: The NSCell object to update
 */
- (void)updateCell:(NSCell *)aCell;

/**
 * Updates the interior display of the specified cell.
 * aCell: The NSCell object whose interior should be updated
 */
- (void)updateCellInside:(NSCell *)aCell;

//
// Target and Action
//
/**
 * Returns the action selector sent to the target.
 * Returns: The SEL representing the action method
 */
- (SEL)action;

/**
 * Returns whether the control sends actions continuously.
 * Returns: YES if continuous action sending is enabled, NO otherwise
 */
- (BOOL)isContinuous;

/**
 * Sends the specified action to the specified target.
 * theAction: The action selector to send
 * theTarget: The target object to receive the action
 * Returns: YES if the action was successfully sent, NO otherwise
 */
- (BOOL)sendAction:(SEL)theAction
		to:(id)theTarget;

/**
 * Sets the events that trigger action sending.
 * mask: A bitmask of event types that should trigger action sending
 * Returns: The previous event mask value
 */
- (NSInteger)sendActionOn:(NSInteger)mask;

/**
 * Sets the action selector sent to the target.
 * aSelector: The SEL representing the action method
 */
- (void)setAction:(SEL)aSelector;

/**
 * Sets whether the control sends actions continuously.
 * flag: YES to enable continuous action sending, NO to disable
 */
- (void)setContinuous:(BOOL)flag;

/**
 * Sets the target object for action messages.
 * anObject: The object that should receive action messages
 */
- (void)setTarget:(id)anObject;

/**
 * Returns the target object for action messages.
 * Returns: The object that receives action messages
 */
- (id)target;

//
// Attributed string handling
//
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the control's value as an attributed string.
 * Returns: The NSAttributedString representation of the control's value
 */
- (NSAttributedString *)attributedStringValue;

/**
 * Sets the control's value as an attributed string.
 * attribStr: The NSAttributedString value to set
 */
- (void)setAttributedStringValue:(NSAttributedString *)attribStr;
#endif

//
// Assigning a Tag
//
/**
 * Sets the tag value for the control.
 * anInt: The integer tag value to assign
 */
- (void)setTag:(NSInteger)anInt;

/**
 * Returns the tag value assigned to the control.
 * Returns: The integer tag value, or -1 if none assigned
 */
- (NSInteger)tag;

//
// Activation
//
/**
 * Simulates a mouse click on the control.
 * sender: The object requesting the click simulation
 */
- (void)performClick:(id)sender;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns whether the control refuses to become first responder.
 * Returns: YES if the control refuses first responder status, NO otherwise
 */
- (BOOL)refusesFirstResponder;

/**
 * Sets whether the control refuses to become first responder.
 * flag: YES to refuse first responder status, NO to accept it
 */
- (void)setRefusesFirstResponder:(BOOL)flag;
#endif

//
// Tracking the Mouse
//
/**
 * Handles mouse down events in the control.
 * theEvent: The mouse event to process
 */
- (void)mouseDown:(NSEvent *)theEvent;

/**
 * Returns whether the control ignores multiple clicks.
 * Returns: YES if multi-clicks are ignored, NO otherwise
 */
- (BOOL)ignoresMultiClick;

/**
 * Sets whether the control ignores multiple clicks.
 * flag: YES to ignore multi-clicks, NO to process them
 */
- (void)setIgnoresMultiClick:(BOOL)flag;

@end

APPKIT_EXPORT NSString *NSControlTextDidBeginEditingNotification;
APPKIT_EXPORT NSString *NSControlTextDidEndEditingNotification;
APPKIT_EXPORT NSString *NSControlTextDidChangeNotification;

//
// Methods Implemented by the Delegate
//
/**
 * This protocol defines methods that delegates can implement to
 * control and respond to text editing operations in NSControl objects.
 * It provides fine-grained control over validation, formatting,
 * and editing behavior.
 */
@protocol NSControlTextEditingDelegate <NSObject>
#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST) && GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#else
@end
@interface NSObject (NSControlTextEditingDelegate)
#endif

/**
 * Validates an object value for the control.
 * control: The NSControl object requesting validation
 * object: The object value to validate
 * Returns: YES if the object is valid, NO otherwise
 */
- (BOOL) control: (NSControl *)control  isValidObject:(id)object;

/**
 * Determines whether text editing should begin in the control.
 * control: The NSControl object requesting to begin editing
 * fieldEditor: The NSText object that will serve as the field editor
 * Returns: YES to allow editing to begin, NO to prevent it
 */
- (BOOL) control: (NSControl *)control
  textShouldBeginEditing: (NSText *)fieldEditor;

/**
 * Determines whether text editing should end in the control.
 * control: The NSControl object requesting to end editing
 * fieldEditor: The NSText object serving as the field editor
 * Returns: YES to allow editing to end, NO to continue editing
 */
- (BOOL) control: (NSControl *)control
  textShouldEndEditing: (NSText *)fieldEditor;

/**
 * Notifies when string formatting fails for the control.
 * control: The NSControl object where formatting failed
 * string: The string that failed to format
 * error: Description of the formatting error
 * Returns: YES if the error was handled, NO otherwise
 */
- (BOOL) control: (NSControl *)control
  didFailToFormatString: (NSString *)string
  errorDescription: (NSString *)error;

/**
 * Notifies when partial string validation fails.
 * control: The NSControl object where validation failed
 * string: The partial string that failed validation
 * error: Description of the validation error
 */
- (void) control: (NSControl *)control
  didFailToValidatePartialString: (NSString *)string
  errorDescription: (NSString *)error;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Handles command selector execution during text editing.
 * control: The NSControl object where the command occurred
 * textView: The NSTextView object handling the editing
 * command: The selector representing the command to execute
 * Returns: YES if the command was handled, NO to use default handling
 */
- (BOOL) control: (NSControl *)control
  textView: (NSTextView *)textView
  doCommandBySelector: (SEL)command;

/**
 * Provides completions for partial word input during text editing.
 * control: The NSControl object requesting completions
 * textView: The NSTextView object handling the editing
 * words: Array of potential completion words
 * charRange: The character range of the partial word
 * index: Pointer to store the index of the preferred completion
 * Returns: Array of completion strings to display
 */
- (NSArray *) control: (NSControl *)control
  textView: (NSTextView *)textView
  completions: (NSArray *)words
  forPartialWordRange: (NSRange)charRange
  indexOfSelectedItem: (int *)index;
#endif

@end

/**
 * This category provides methods that objects can implement to receive
 * notifications about text editing events in NSControl objects.
 */
@interface NSObject (NSControlDelegate)

/**
 * Called when text editing begins in a control.
 * aNotification: Notification containing the NSControl object
 */
- (void) controlTextDidBeginEditing: (NSNotification *)aNotification;

/**
 * Called when text editing ends in a control.
 * aNotification: Notification containing the NSControl object
 */
- (void) controlTextDidEndEditing: (NSNotification *)aNotification;

/**
 * Called when text changes during editing in a control.
 * aNotification: Notification containing the NSControl object
 */
- (void) controlTextDidChange: (NSNotification *)aNotification;
@end

#endif // _GNUstep_H_NSControl
