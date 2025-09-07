/*                                                    -*-objc-*-
   NSInputServer.h

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: August 2001

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
 * <title>NSInputServer</title>
 * <abstract>Input method server for text input processing and internationalization</abstract>
 *
 * NSInputServer provides a framework for implementing input method servers that
 * handle complex text input, particularly for international languages that require
 * composition, conversion, or special input techniques. The server acts as an
 * intermediary between user input events and the final text insertion, allowing
 * for sophisticated text processing workflows.
 *
 * The system supports input methods for languages that require:
 * - Multi-keystroke character composition (e.g., accented characters)
 * - Character conversion and candidate selection (e.g., Japanese IME)
 * - Context-sensitive input processing
 * - Custom keyboard layouts and input interpretations
 * - Advanced text editing operations and marked text handling
 *
 * Key components include:
 * - Mouse event tracking for character-level interaction
 * - Text insertion and marked text management
 * - Conversation state tracking for multi-step input
 * - Client activation and state management
 * - Configurable event handling preferences
 * - Integration with the text input system
 *
 * The input server communicates with text-capable controls through a delegate
 * pattern and protocol system, enabling seamless integration with existing
 * text editing infrastructure while providing the flexibility needed for
 * complex input method implementations.
 */

#ifndef _GNUstep_H_NSInputServer
#define _GNUstep_H_NSInputServer
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>

@class NSString;

/**
 * <title>NSInputServerMouseTracker</title>
 * <abstract>Protocol for handling mouse events in input server contexts</abstract>
 *
 * The NSInputServerMouseTracker protocol defines methods for handling mouse
 * events that occur over text content managed by an input server. This enables
 * character-level mouse interaction during text composition and input processing.
 */
@protocol NSInputServerMouseTracker

/**
 * Handles mouse down events at specific character positions.
 * index: The character index where the mouse down occurred
 * point: The coordinate of the mouse down event
 * flags: Modifier key flags active during the event
 * sender: The client object requesting mouse tracking
 * Returns: YES if the event was handled, NO to pass it on
 */
- (BOOL) mouseDownOnCharacterIndex: (unsigned)index
		      atCoordinate: (NSPoint)point
		      withModifier: (unsigned int)flags
			    client: (id)sender;

/**
 * Handles mouse dragged events at specific character positions.
 * index: The character index where the mouse drag occurred
 * point: The coordinate of the mouse drag event
 * flags: Modifier key flags active during the event
 * sender: The client object requesting mouse tracking
 * Returns: YES if the event was handled, NO to pass it on
 */
- (BOOL) mouseDraggedOnCharacterIndex: (unsigned)index
			 atCoordinate: (NSPoint)point
			 withModifier: (unsigned int)flags
			       client: (id)sender;

/**
 * Handles mouse up events at specific character positions.
 * index: The character index where the mouse up occurred
 * point: The coordinate of the mouse up event
 * flags: Modifier key flags active during the event
 * sender: The client object requesting mouse tracking
 */
- (void) mouseUpOnCharacterIndex: (unsigned)index
		    atCoordinate: (NSPoint)point
		    withModifier: (unsigned int)flags
			  client: (id)sender;
@end

/**
 * <title>NSInputServiceProvider</title>
 * <abstract>Protocol for providing input method services</abstract>
 *
 * The NSInputServiceProvider protocol defines the comprehensive interface for
 * input method service providers. This protocol handles all aspects of text
 * input processing, from client state management to text insertion and
 * conversation tracking.
 */
@protocol NSInputServiceProvider

/**
 * Notifies the provider when the active conversation changes.
 * sender: The client object initiating the change
 * newConversation: Identifier for the new active conversation
 */
- (void) activeConversationChanged: (id)sender
		 toNewConversation: (long)newConversation;

/**
 * Notifies the provider that the active conversation will change.
 * sender: The client object initiating the change
 * oldConversation: Identifier for the conversation being deactivated
 */
- (void) activeConversationWillChange: (id)sender
		  fromOldConversation: (long)oldConversation;

/**
 * Returns whether this input service can be disabled.
 * Returns: YES if the service can be disabled, NO if it must remain active
 */
- (BOOL) canBeDisabled;

/**
 * Requests the provider to execute a command by selector.
 * aSelector: The selector identifying the command to execute
 * sender: The client object requesting the command execution
 */
- (void) doCommandBySelector: (SEL)aSelector
		      client: (id)sender;

/**
 * Notifies the provider that an input client has become active.
 * sender: The client object that became active
 */
- (void) inputClientBecomeActive: (id)sender;

/**
 * Notifies the provider that an input client has been disabled.
 * sender: The client object that was disabled
 */
- (void) inputClientDisabled: (id)sender;

/**
 * Notifies the provider that an input client has been enabled.
 * sender: The client object that was enabled
 */
- (void) inputClientEnabled: (id)sender;

/**
 * Notifies the provider that an input client has resigned active status.
 * sender: The client object that resigned active status
 */
- (void) inputClientResignActive: (id)sender;

/**
 * Requests insertion of text into the active client.
 * aString: The string or attributed string to insert
 * sender: The client object where text should be inserted
 */
- (void) insertText: (id)aString
	     client: (id)sender;

/**
 * Notifies the provider that marked text has been abandoned.
 * This occurs when composition is cancelled without completion.
 * sender: The client object where marked text was abandoned
 */
- (void) markedTextAbandoned: (id)sender;

/**
 * Notifies the provider of marked text selection changes.
 * newSelection: The new selection range within the marked text
 * sender: The client object where selection changed
 */
- (void) markedTextSelectionChanged: (NSRange)newSelection
			     client: (id)sender;

/**
 * Requests the provider to terminate its operations.
 * sender: The client object requesting termination
 */
- (void) terminate: (id)sender;

/**
 * Returns whether the provider wants to delay text change notifications.
 * Returns: YES to delay notifications during input processing, NO for immediate notifications
 */
- (BOOL) wantsToDelayTextChangeNotifications;

/**
 * Returns whether the provider wants to handle mouse events.
 * Returns: YES to receive mouse events, NO to ignore them
 */
- (BOOL) wantsToHandleMouseEvents;

/**
 * Returns whether the provider wants to interpret all keystrokes.
 * Returns: YES to receive all key events, NO to receive only specific events
 */
- (BOOL) wantsToInterpretAllKeystrokes;
@end

/**
 * <title>NSInputServer Class Interface</title>
 * <abstract>Concrete input server implementation</abstract>
 *
 * NSInputServer provides a concrete implementation of input method server
 * functionality, conforming to both NSInputServerMouseTracker and
 * NSInputServiceProvider protocols. This class serves as the foundation
 * for building custom input method servers.
 */
@interface NSInputServer: NSObject <NSInputServerMouseTracker, NSInputServiceProvider>

/**
 * Initializes an input server with a delegate and name.
 * aDelegate: The delegate object that will handle input server events
 * name: The name identifying this input server instance
 * Returns: An initialized NSInputServer instance
 */
- (id) initWithDelegate: (id)aDelegate
		   name: (NSString *)name;
@end

#endif //_GNUstep_H_NSInputServer
