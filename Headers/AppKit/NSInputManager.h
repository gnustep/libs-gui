/* -*-objc-*-
   NSInputManager.h

   Copyright (C) 2001, 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 2001, February 2002

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

/**
 * <title>NSInputManager</title>
 * <abstract>Advanced text input management with sophisticated keybinding system</abstract>
 *
 * NSInputManager provides comprehensive text input processing capabilities with
 * a sophisticated keybinding system that supports complex keystroke sequences,
 * multi-client text interaction, and customizable input behavior. The manager
 * acts as an intermediary between raw keyboard events and text insertion,
 * enabling advanced text editing workflows and internationalization support.
 *
 * The keybinding system supports multiple levels of complexity:
 * - Simple keystroke-to-selector mappings (Control-f → moveForward:)
 * - Multi-action sequences (Control-k → moveToBeginningOfLine:, deleteToEndOfLine:)
 * - Nested keybinding contexts (Control-c Control-f → openFile:)
 * - Literal text insertion for unbound keystrokes
 * - Special override keys (Control-g for abort, Control-q for quoting)
 *
 * Key features include:
 * - Customizable keybinding tables loaded from configuration files
 * - Multi-keystroke sequence processing with context switching
 * - Client management for multiple text input targets
 * - Marked text support for composition-based input methods
 * - Mouse event handling integration
 * - Literal keystroke quoting and sequence abortion
 * - Configurable control key insertion behavior
 *
 * The input manager maintains internal state including pending keystroke
 * sequences, current binding contexts, and client relationships. It integrates
 * seamlessly with the NSTextInput protocol to provide advanced text editing
 * capabilities across all text-capable controls in the application.
 */

#ifndef _GNUstep_H_NSInputManager
#define _GNUstep_H_NSInputManager
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>

@class NSArray;
@class NSAttributedString;
@class NSMutableArray;
@class NSInputServer;
@class NSEvent;
@class NSImage;

/**
 * <title>NSTextInput</title>
 * <abstract>Protocol for text input client objects</abstract>
 *
 * The NSTextInput protocol defines the interface that text-capable objects
 * must implement to work with input managers. This protocol enables sophisticated
 * text input processing including marked text composition and character-level
 * interaction.
 */
@protocol NSTextInput

/**
 * Sets marked text with a selected range for composition.
 * aString: The string or attributed string to mark
 * selRange: The selected range within the marked text
 */
- (void) setMarkedText: (id)aString selectedRange: (NSRange)selRange;

/**
 * Returns whether there is currently marked text.
 * Returns: YES if marked text exists, NO otherwise
 */
- (BOOL) hasMarkedText;

/**
 * Returns the range of marked text.
 * Returns: NSRange of marked text, or NSNotFound range if none
 */
- (NSRange) markedRange;

/**
 * Returns the currently selected text range.
 * Returns: NSRange of selected text
 */
- (NSRange) selectedRange;

/**
 * Removes marking from text, finalizing composition.
 */
- (void) unmarkText;

/**
 * Returns attributes valid for marked text display.
 * Returns: NSArray of attribute names that can be used for marked text
 */
- (NSArray*) validAttributesForMarkedText;

/**
 * Returns attributed substring from the specified range.
 * theRange: The range of text to retrieve
 * Returns: NSAttributedString containing the text and attributes
 */
- (NSAttributedString *) attributedSubstringFromRange: (NSRange)theRange;

/**
 * Returns character index for a given point.
 * thePoint: The point to convert to character index
 * Returns: Character index at the specified point
 */
- (NSUInteger) characterIndexForPoint: (NSPoint)thePoint;

/**
 * Returns unique identifier for this text input conversation.
 * Returns: Unique integer identifier for input session tracking
 */
- (NSInteger) conversationIdentifier;

/**
 * Executes a command by selector.
 * aSelector: The selector identifying the command to execute
 */
- (void) doCommandBySelector: (SEL)aSelector;

/**
 * Returns rectangle for the specified character range.
 * theRange: The character range to get rectangle for
 * Returns: NSRect bounding the specified character range
 */
- (NSRect) firstRectForCharacterRange: (NSRange)theRange;

/**
 * Inserts text at the current insertion point.
 * aString: The string or attributed string to insert
 */
- (void) insertText: (id)aString;
@end

/* The input manager understands quite sophisticated keybindings.
 *
 * A certain keystroke (represented by a unichar + some modifiers) can
 * be bound to a selector.  For example: "Control-f" = "moveForward:";
 * If you press Control-f, the selector moveForward: is invoked.
 *
 * A certain keystroke can be bound to an array of selectors.  For
 * example: "Control-k" = ("moveToBeginningOfLine:", "deleteToEndOfLine:");
 * If you press Control-k, the selector moveToBeginningOfLine: is invoked,
 * immediately followed by deleteToEndOfLine:.
 *
 * A certain keystroke can be bound to a dictionary of other
 * keybindings.  For example "Control-c" = { "Control-f" =
 * "openFile:"; "Control-s" = "save:"; };
 * If you press Control-c followed by Control-f, openFile: is invoked;
 * if you press Control-c followed by Control-s, save: is invoked.
 *
 * Any keystroke which is not bound by a keybinding is basically inserted
 * as it is by calling 'insertText:' of the caller.
 *
 * Control-g is normally bound to aborting the current keybinding
 * sequence.  Whenever you are confused about what the hell you have
 * typed and what strange command the input manager is going to
 * understand, just type Control-g to discard past pending keystrokes,
 * and reset the input manager.
 *
 * Control-q is normally bound to literally quoting the next
 * keystroke.  That is, the next keystroke is *not* interpreted by the
 * input manager, but rather inserted literally into the text.
 */

@class GSKeyBindingTable;

/**
 * <title>NSInputManager Class Interface</title>
 * <abstract>Concrete input manager implementation with keybinding system</abstract>
 *
 * NSInputManager provides the complete implementation of sophisticated text input
 * management, including customizable keybinding processing, multi-client support,
 * and advanced text composition capabilities.
 */
@interface NSInputManager: NSObject <NSTextInput>
{
  /* The current client we are working for.  */
  id<NSTextInput> _currentClient;

  /* This is the basic, root set of bindings.  Whenever the input
     manager detects that the current client has changed, it immediately
     resets the current key bindings to the root ones.  If you are typing
     and are confused about what's happening, pressing Control-g always
     resets the bindings to the root bindings.  */
  GSKeyBindingTable *_rootBindingTable;

  /* These are the bindings which will be used to interpret the next
     keystroke.  At the beginning, this is the same as the
     _rootBindingTable.  But when you type a keystroke which is the
     beginning of a sequence of keystrokes producing a certain action,
     then the input manager updates the _currentBindingTable to be the
     table where he looks up the next keystroke you put in.
  */
  GSKeyBindingTable *_currentBindingTable;

  /* When we are reading multi-keystroke bindings, we need to remember
     the keystrokes we read thinking they were the beginning of a
     multi-keystroke binding ... just in case it turns out that they
     are not :-)  */
  NSMutableArray *_pendingKeyEvents;

  /* When it is YES, the next key stroke is interpreted literally rather
     than looked up using the _currentBindingTable.  */
  BOOL _interpretNextKeyStrokeLiterally;

  /* Extremely special keybinding which overrides any other keybinding
     in all contexts - abort - normally bound to Control-g.  When we
     encounter this keystroke, we abort all pending keystrokes and
     reset ourselves immediately into vanilla root input state.  */
  unichar _abortCharacter;
  unsigned int _abortFlags;

  /* When it is YES, keystrokes containing the NSControlKeyMask as not
     inserted into the text.  This is so that if you press Control-x,
     and that is bound to nothing, it doesn't get inserted as a strange
     character into your text.  */
  BOOL _insertControlKeystrokes;
}

/**
 * Returns the current system input manager instance.
 * Returns: The shared NSInputManager instance for the current application
 */
+ (NSInputManager *) currentInputManager;

/**
 * Initializes an input manager with specified input server and host.
 * inputServerName: Name of the input server to use
 * hostName: Host name for distributed input server communication
 * Returns: An initialized NSInputManager instance
 */
- (NSInputManager *) initWithName: (NSString *)inputServerName
			     host: (NSString *)hostName;

/**
 * Handles mouse events for input processing.
 * theMouseEvent: The mouse event to process
 * Returns: YES if the event was handled, NO to pass it on
 */
- (BOOL) handleMouseEvent: (NSEvent *)theMouseEvent;

/**
 * Processes an array of keyboard events for the specified client.
 * eventArray: Array of NSEvent objects representing keyboard input
 * client: The text input client that should receive processed input
 */
- (void) handleKeyboardEvents: (NSArray *)eventArray
		       client: (id)client;

/**
 * Returns the language code for the current input method.
 * Returns: String identifier for the input method language
 */
- (NSString *) language;

/**
 * Returns localized name of the input manager.
 * Returns: Human-readable name of the input manager in current locale
 */
- (NSString *) localizedInputManagerName;

/**
 * Notifies the manager that marked text has been abandoned.
 * client: The client where marked text was abandoned
 */
- (void) markedTextAbandoned: (id)client;

/**
 * Notifies the manager of marked text selection changes.
 * newSel: The new selection range within marked text
 * client: The client where selection changed
 */
- (void) markedTextSelectionChanged: (NSRange)newSel
			    client: (id)client;

/**
 * Returns whether the manager wants to delay text change notifications.
 * Returns: YES to delay notifications during processing, NO for immediate notifications
 */
- (BOOL) wantsToDelayTextChangeNotifications;

/**
 * Returns whether the manager wants to handle mouse events.
 * Returns: YES to receive mouse events, NO to ignore them
 */
- (BOOL) wantsToHandleMouseEvents;

/**
 * Returns whether the manager wants to interpret all keystrokes.
 * Returns: YES to process all keystrokes, NO for selective processing
 */
- (BOOL) wantsToInterpretAllKeystrokes;

/* GNUstep Extensions.  */

/**
 * Loads keybindings from a configuration file.
 * This method can be called explicitly by applications to load
 * application-specific keybindings for use by the input manager.
 * fullPath: Full path to the keybinding configuration file
 */
- (void) loadBindingsFromFile: (NSString *)fullPath;

/**
 * Parses a key string into character and modifier components.
 * Parses a key as found in a keybinding file (e.g., 'Control-f' or 'Control-Shift-LeftArrow').
 * key: String representation of the keystroke
 * character: Pointer to store the parsed character
 * modifiers: Pointer to store the parsed modifier flags
 * Returns: YES if the key could be parsed successfully, NO otherwise
 */
+ (BOOL) parseKey: (NSString *)key
    intoCharacter: (unichar *)character
     andModifiers: (unsigned int *)modifiers;

/**
 * Creates a string description of a keystroke for configuration files.
 * This method converts an actual keystroke into a string that can be used
 * in keybinding files. Useful for Preferences applications that need to
 * capture user keystrokes and save them to configuration.
 * character: The character component of the keystroke
 * modifiers: The modifier flags (pass 0 to ignore modifiers)
 * Returns: String representation suitable for keybinding files
 */
+ (NSString *) describeKeyStroke: (unichar)character
		   withModifiers: (unsigned int)modifiers;

/* Methods used internally ... not really part of the public API, can change
   without notice.  */

/**
 * Resets the internal state of the input manager.
 * Normally bound to Control-g (regardless of context), but also automatically
 * called whenever the current client changes. Clears pending keystrokes and
 * returns to the root keybinding context.
 */
- (void) resetInternalState;

/**
 * Sets flag to quote the next keystroke literally.
 * Normally bound to Control-q. The next keystroke will be inserted as literal
 * text rather than being interpreted through the keybinding system.
 */
- (void) quoteNextKeyStroke;


@end

#endif /* _GNUstep_H_NSInputManager */
