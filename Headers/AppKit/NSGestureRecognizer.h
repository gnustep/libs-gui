/*
   NSGestureRecognizer.h

   Abstract base class for monitoring user events

   Copyright (C) 2017 Free Software Foundation, Inc.

   Author: Daniel Ferreira <dtf@stanford.edu>
   Date: 2017
   Editor: Gregory John Casamento
   Date: Thu Dec  5 12:54:49 EST 2019

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
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSGestureRecognizer
#define _GNUstep_H_NSGestureRecognizer
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSArray.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSView, NSEvent;
@protocol NSGestureRecognizerDelegate;

typedef NS_ENUM(NSInteger, NSGestureRecognizerState) {
    NSGestureRecognizerStatePossible,
    NSGestureRecognizerStateBegan,
    NSGestureRecognizerStateChanged,
    NSGestureRecognizerStateEnded,
    NSGestureRecognizerStateCancelled,
    NSGestureRecognizerStateFailed,
    NSGestureRecognizerStateRecognized = NSGestureRecognizerStateEnded
};

APPKIT_EXPORT_CLASS
/**
 * NSGestureRecognizer is an abstract base class that provides the framework
 * for recognizing user gestures from input events. This class defines the
 * fundamental architecture for gesture recognition systems, enabling
 * applications to respond to complex user interactions like taps, swipes,
 * pinches, and rotations. Gesture recognizers maintain state machines that
 * track gesture progress through various phases from possible to recognized,
 * failed, or cancelled states. The class implements the target-action pattern
 * for delivering gesture recognition results to application objects. Each
 * gesture recognizer can be attached to a view and will monitor events
 * delivered to that view, processing them according to the specific gesture
 * recognition logic implemented by subclasses. The framework supports gesture
 * dependencies, simultaneous recognition, and delegate-based customization
 * of recognition behavior. Subclasses must implement specific event handling
 * methods to define their gesture recognition algorithms while leveraging
 * the base class infrastructure for state management and action delivery.
 */
@interface NSGestureRecognizer : NSObject <NSCoding>
{
@private
    id _target;
    SEL _action;
    NSGestureRecognizerState _state;
    NSView *_view;
    id<NSGestureRecognizerDelegate> _delegate;
    BOOL _enabled;
    BOOL _delaysPrimaryMouseButtonEvents;
    BOOL _delaysSecondaryMouseButtonEvents;
    BOOL _delaysOtherMouseButtonEvents;
    BOOL _delaysKeyEvents;
    NSMutableArray *_failureRequirements;
    NSEvent *_lastEvent;
}

// Initializing a Gesture Recognizer
/**
 * Initializes a new gesture recognizer with the specified target and action.
 * The target parameter specifies the object that will receive action messages
 * when the gesture is successfully recognized. The action parameter defines
 * the selector method that will be called on the target object. This designated
 * initializer establishes the target-action relationship that enables gesture
 * recognition results to be delivered to application objects. The initialized
 * gesture recognizer starts in the possible state and is enabled by default.
 * Multiple target-action pairs can be added after initialization using the
 * addTarget:action: method. The gesture recognizer maintains a weak reference
 * to the target object to prevent retain cycles. If target is nil or action
 * is NULL, no action will be performed when the gesture is recognized, but
 * the recognizer will still track gesture state and can be monitored through
 * its delegate or state property.
 */
- (instancetype)initWithTarget:(id)target action:(SEL)action;

// Adding and Removing Targets and Actions
/**
 * Adds a target-action pair to this gesture recognizer. The target parameter
 * specifies the object that should receive action messages when the gesture
 * is successfully recognized. The action parameter defines the selector method
 * that will be invoked on the target object. Multiple target-action pairs
 * can be associated with a single gesture recognizer, allowing the same
 * gesture to trigger multiple responses simultaneously. The gesture recognizer
 * maintains weak references to target objects to prevent retain cycles. When
 * the gesture is recognized, all registered target-action pairs will be
 * invoked in the order they were added. If either target or action is nil,
 * the method has no effect. The action method should accept either no arguments
 * or a single argument that will receive the gesture recognizer instance.
 */
- (void)addTarget:(id)target action:(SEL)action;
/**
 * Removes a target-action pair from this gesture recognizer. The target
 * parameter specifies the target object to remove, and the action parameter
 * specifies the action selector to remove. If target matches a registered
 * target and action either matches the registered action or is NULL, the
 * target-action pair is removed from the recognizer. When action is NULL,
 * all actions associated with the specified target are removed. This method
 * enables dynamic modification of gesture response behavior during the
 * application lifecycle. Removing a target-action pair prevents future
 * action messages from being sent to that target when the gesture is
 * recognized. If the specified target-action pair is not found, the method
 * has no effect.
 */
- (void)removeTarget:(id)target action:(SEL)action;

// Getting the Touches and Location of a Gesture
/**
 * Returns the location of the gesture in the coordinate system of the
 * specified view. The view parameter determines the coordinate system for
 * the returned point. If view is nil, the method uses the gesture recognizer's
 * associated view. If no view is associated, the method returns the location
 * in window coordinates. The location represents the centroid of all active
 * touch points involved in the gesture. For single-touch gestures, this is
 * the location of the single touch. For multi-touch gestures, this is the
 * average location of all touches. The returned point is calculated based
 * on the most recent event processed by the gesture recognizer. This method
 * provides a convenient way to determine where the gesture is occurring
 * without needing to access individual touch locations.
 */
- (NSPoint)locationInView:(NSView *)view;
/**
 * Returns the location of a specific touch in the coordinate system of the
 * specified view. The touchIndex parameter specifies which touch to query,
 * with 0 representing the first touch, 1 the second touch, and so on. The
 * view parameter determines the coordinate system for the returned point.
 * If view is nil, the method uses the gesture recognizer's associated view.
 * This method enables access to individual touch locations in multi-touch
 * gestures where the overall gesture location may not provide sufficient
 * detail. For single-touch gestures, only index 0 is valid. If touchIndex
 * exceeds the number of active touches, the method returns NSZeroPoint.
 * The returned location is based on the most recent event processed by
 * the gesture recognizer.
 */
- (NSPoint)locationOfTouch:(NSUInteger)touchIndex inView:(NSView *)view;
/**
 * Returns the number of touches currently involved in the gesture. For
 * single-touch gestures like taps or swipes, this returns 1. For multi-touch
 * gestures like pinches or rotations, this returns the number of simultaneous
 * touches being tracked. The count reflects the number of active touches
 * at the time of the most recent event processed by the gesture recognizer.
 * During gesture recognition, the touch count may change as touches are
 * added or removed. Subclasses can use this information to validate gesture
 * requirements and adjust recognition behavior based on the number of
 * concurrent touches. A return value of 0 indicates no active touches,
 * which typically occurs before gesture recognition begins or after all
 * touches have ended.
 */
- (NSUInteger)numberOfTouches;

// Getting and Setting the Gesture Recognizer's State
- (NSGestureRecognizerState) state;

// Enabling and Disabling a Gesture Recognizer
- (BOOL) isEnabled;
- (void) setEnabled: (BOOL)enabled;

// Specifying Dependencies Between Gesture Recognizers
/**
 * Establishes a failure dependency on another gesture recognizer. The
 * otherGestureRecognizer parameter specifies the gesture recognizer that
 * must fail before this gesture recognizer can succeed. This creates a
 * recognition precedence where the other gesture recognizer is given the
 * first opportunity to recognize its gesture. Only if the other recognizer
 * fails to recognize its gesture will this recognizer be allowed to succeed.
 * This mechanism enables complex gesture interactions where specific gestures
 * take priority over more general ones. For example, a double-tap recognizer
 * might require a single-tap recognizer to fail, ensuring that single taps
 * are not recognized when the user intends a double tap. Multiple failure
 * dependencies can be established, creating chains of recognition precedence.
 * If otherGestureRecognizer is nil or already a dependency, the method has
 * no effect.
 */
- (void)requireGestureRecognizerToFail:(NSGestureRecognizer *)otherGestureRecognizer;

// Setting and Getting the Delegate
- (id<NSGestureRecognizerDelegate>) delegate;
- (void) setDelegate: (id<NSGestureRecognizerDelegate>)delegate;

// Getting the Gesture Recognizer's View
- (NSView *) view;

// Delaying Touches
- (BOOL) delaysPrimaryMouseButtonEvents;
- (void) setDelaysPrimaryMouseButtonEvents: (BOOL)delays;

- (BOOL) delaysSecondaryMouseButtonEvents;
- (void) setDelaysSecondaryMouseButtonEvents: (BOOL)delays;

- (BOOL) delaysOtherMouseButtonEvents;
- (void) setDelaysOtherMouseButtonEvents: (BOOL)delays;

- (BOOL) delaysKeyEvents;
- (void) setDelaysKeyEvents: (BOOL)delays;

// Methods for Subclasses
/**
 * Resets the gesture recognizer to its initial state. This method is called
 * automatically by the framework when the gesture recognizer transitions
 * to terminal states like ended, cancelled, or failed. Subclasses should
 * override this method to reset any gesture-specific state variables,
 * accumulated values, or tracking data to their initial conditions. The
 * base implementation clears internal event tracking and prepares the
 * recognizer for processing new gesture sequences. Custom implementations
 * should call the super implementation to ensure proper base class cleanup.
 * This method enables gesture recognizers to be reused for multiple gesture
 * recognition cycles without creating new instances. The reset occurs after
 * action messages have been sent, allowing action handlers to access final
 * gesture state before cleanup.
 */
- (void)reset;
/**
 * Instructs the gesture recognizer to ignore a specific event. The event
 * parameter specifies the event that should be excluded from gesture
 * recognition processing. This method provides a way for subclasses to
 * filter out events that are not relevant to their specific gesture type
 * or that occur under conditions where recognition should not proceed.
 * Ignored events are not processed by the normal event handling methods
 * and do not contribute to gesture state transitions. This selective
 * event filtering can improve recognition accuracy and prevent unwanted
 * gesture triggers. The base implementation provides a placeholder that
 * subclasses can override to implement custom event filtering logic.
 * Events that are ignored do not affect the gesture recognizer's state
 * or trigger delegate method calls.
 */
- (void)ignoreEvent:(NSEvent *)event;
/**
 * Determines whether this gesture recognizer can prevent another gesture
 * recognizer from succeeding. The preventedGestureRecognizer parameter
 * specifies the gesture recognizer that might be prevented from recognizing
 * its gesture. This method enables custom gesture interaction policies
 * where certain gestures take precedence over others. The default
 * implementation returns YES, allowing this recognizer to prevent any other
 * recognizer. Subclasses can override this method to implement more
 * sophisticated interaction rules based on gesture types, view hierarchies,
 * or application-specific requirements. When this method returns NO, both
 * gesture recognizers may succeed simultaneously if their delegate methods
 * also permit simultaneous recognition. This method is called during gesture
 * recognition to resolve conflicts between competing recognizers.
 */
- (BOOL)canPreventGestureRecognizer:(NSGestureRecognizer *)preventedGestureRecognizer;
/**
 * Determines whether this gesture recognizer can be prevented from succeeding
 * by another gesture recognizer. The preventingGestureRecognizer parameter
 * specifies the gesture recognizer that might prevent this one from
 * recognizing its gesture. This method enables custom gesture interaction
 * policies where certain recognizers can be overridden by others. The
 * default implementation returns YES, allowing any other recognizer to
 * prevent this one. Subclasses can override this method to implement
 * resistance to prevention based on gesture priority, specificity, or
 * application requirements. When this method returns NO, this recognizer
 * cannot be prevented by the specified preventing recognizer. This method
 * works in conjunction with canPreventGestureRecognizer: to establish
 * complex gesture hierarchies and interaction patterns.
 */
- (BOOL)canBePreventedByGestureRecognizer:(NSGestureRecognizer *)preventingGestureRecognizer;

// Event-Handling Methods
/**
 * Handles mouse down events for gesture recognition. The event parameter
 * contains information about the mouse press including location, timestamp,
 * and button state. This method is called when a mouse button is pressed
 * within the gesture recognizer's associated view. Subclasses override this
 * method to implement specific gesture recognition logic for mouse press
 * events. The base implementation stores the event for location tracking
 * and consults the delegate to determine whether recognition should proceed.
 * Mouse down events typically mark the beginning of gesture recognition
 * sequences. Subclasses should analyze event properties like click count,
 * location, and timing to determine appropriate state transitions. The
 * method should update the gesture recognizer's state based on recognition
 * progress and gesture completion criteria.
 */
- (void)mouseDown:(NSEvent *)event;
/**
 * Handles mouse drag events for gesture recognition. The event parameter
 * contains information about the mouse movement including location, delta
 * values, and timestamp. This method is called when the mouse is moved
 * while a button is pressed within the gesture recognizer's associated
 * view. Subclasses override this method to track gesture progression
 * through continuous mouse movements. The base implementation stores the
 * event for location tracking. Mouse drag events are crucial for gestures
 * that involve movement like swipes, pans, or drags. Subclasses should
 * analyze movement distance, direction, velocity, and patterns to determine
 * whether the movement matches their specific gesture criteria and update
 * state accordingly.
 */
- (void)mouseDragged:(NSEvent *)event;
/**
 * Handles mouse up events for gesture recognition. The event parameter
 * contains information about the mouse release including final location
 * and timing. This method is called when a mouse button is released
 * within the gesture recognizer's associated view. Subclasses override
 * this method to complete gesture recognition sequences that began with
 * mouse down events. The base implementation stores the event for location
 * tracking. Mouse up events typically mark the end of gesture recognition
 * sequences and often trigger final recognition decisions. Subclasses
 * should analyze the complete gesture sequence including duration, movement
 * patterns, and end conditions to determine whether recognition criteria
 * have been met and transition to appropriate terminal states.
 */
- (void)mouseUp:(NSEvent *)event;
/**
 * Handles right mouse down events for gesture recognition. The event
 * parameter contains information about the right mouse button press.
 * This method is called when the right mouse button is pressed within
 * the gesture recognizer's associated view. Subclasses override this
 * method to implement gesture recognition logic specific to right mouse
 * button interactions. The base implementation stores the event for
 * location tracking. Right mouse events can trigger different gesture
 * types than left mouse events, such as context menu gestures or
 * alternative interaction modes. Subclasses should distinguish between
 * different mouse buttons when implementing multi-button gesture support
 * and apply appropriate recognition logic based on button-specific
 * gesture requirements.
 */
- (void)rightMouseDown:(NSEvent *)event;
/**
 * Handles right mouse drag events for gesture recognition. The event
 * parameter contains information about right mouse button drag movements.
 * This method is called when the mouse is moved while the right button
 * is pressed within the gesture recognizer's associated view. Subclasses
 * override this method to track gesture progression through right mouse
 * movements. The base implementation stores the event for location tracking.
 * Right mouse drag events enable gesture types that are distinct from
 * left mouse drags, providing additional gesture vocabulary for applications.
 * Subclasses should implement button-specific movement analysis and apply
 * recognition criteria appropriate to right mouse button gesture semantics.
 */
- (void)rightMouseDragged:(NSEvent *)event;
/**
 * Handles right mouse up events for gesture recognition. The event parameter
 * contains information about the right mouse button release. This method
 * is called when the right mouse button is released within the gesture
 * recognizer's associated view. Subclasses override this method to complete
 * right mouse button gesture sequences. The base implementation stores
 * the event for location tracking. Right mouse up events typically conclude
 * right mouse button gesture recognition and may trigger different actions
 * than left mouse button gestures. Subclasses should implement button-
 * specific completion logic and transition to appropriate terminal states
 * based on right mouse button gesture criteria.
 */
- (void)rightMouseUp:(NSEvent *)event;
/**
 * Handles other mouse button down events for gesture recognition. The
 * event parameter contains information about additional mouse button
 * presses beyond left and right buttons. This method is called when
 * mouse buttons other than left or right are pressed within the gesture
 * recognizer's associated view. Subclasses override this method to support
 * gesture recognition using additional mouse buttons like middle buttons
 * or extended button sets on multi-button mice. The base implementation
 * stores the event for location tracking. Other mouse button events
 * expand the gesture vocabulary available to applications and enable
 * specialized interaction modes based on extended mouse hardware capabilities.
 */
- (void)otherMouseDown:(NSEvent *)event;
/**
 * Handles other mouse button drag events for gesture recognition. The
 * event parameter contains information about drag movements with additional
 * mouse buttons pressed. This method is called when the mouse is moved
 * while buttons other than left or right are pressed within the gesture
 * recognizer's associated view. Subclasses override this method to track
 * gesture progression through extended mouse button movements. The base
 * implementation stores the event for location tracking. Other mouse
 * button drag events enable specialized gesture types that utilize the
 * full capabilities of multi-button input devices and provide additional
 * interaction possibilities for sophisticated applications.
 */
- (void)otherMouseDragged:(NSEvent *)event;
/**
 * Handles other mouse button up events for gesture recognition. The event
 * parameter contains information about additional mouse button releases.
 * This method is called when mouse buttons other than left or right are
 * released within the gesture recognizer's associated view. Subclasses
 * override this method to complete extended mouse button gesture sequences.
 * The base implementation stores the event for location tracking. Other
 * mouse button up events conclude gesture recognition sequences that
 * began with other mouse button down events and enable completion of
 * specialized gesture types that leverage extended mouse button capabilities
 * for enhanced user interaction patterns.
 */
- (void)otherMouseUp:(NSEvent *)event;
/**
 * Handles key down events for gesture recognition. The event parameter
 * contains information about key presses including key codes, character
 * values, and modifier flags. This method is called when keys are pressed
 * while the gesture recognizer's associated view has keyboard focus.
 * Subclasses override this method to implement gesture recognition that
 * incorporates keyboard input. The base implementation stores the event
 * for tracking. Key events can be part of composite gestures that combine
 * keyboard and mouse input, or can trigger keyboard-only gesture sequences.
 * Subclasses should analyze key codes, modifiers, and timing to implement
 * keyboard-based gesture recognition appropriate to their specific
 * gesture requirements.
 */
- (void)keyDown:(NSEvent *)event;
/**
 * Handles key up events for gesture recognition. The event parameter
 * contains information about key releases including key codes and timing.
 * This method is called when keys are released while the gesture
 * recognizer's associated view has keyboard focus. Subclasses override
 * this method to complete keyboard-based gesture recognition sequences.
 * The base implementation stores the event for tracking. Key up events
 * mark the completion of key press sequences and enable gesture recognizers
 * to analyze complete keyboard input patterns including key press duration
 * and release timing. Subclasses should implement key release handling
 * appropriate to their keyboard gesture recognition requirements.
 */
- (void)keyUp:(NSEvent *)event;
/**
 * Handles modifier flag change events for gesture recognition. The event
 * parameter contains information about changes to modifier key states
 * including shift, control, command, and option keys. This method is
 * called when modifier key states change while the gesture recognizer's
 * associated view is active. Subclasses override this method to implement
 * gesture recognition that responds to modifier key combinations. The
 * base implementation stores the event for tracking. Flag change events
 * enable gesture recognition based on modifier key sequences and
 * combinations, supporting complex keyboard-based gesture vocabularies.
 * Subclasses should analyze modifier flag transitions to implement
 * appropriate gesture state changes.
 */
- (void)flagsChanged:(NSEvent *)event;
/**
 * Handles tablet input events for gesture recognition. The event parameter
 * contains information about tablet pen or stylus input including pressure,
 * tilt, and position data. This method is called when tablet input occurs
 * within the gesture recognizer's associated view. Subclasses override
 * this method to implement gesture recognition that utilizes advanced
 * tablet input capabilities. The base implementation stores the event
 * for tracking. Tablet events provide rich input data that enables
 * sophisticated gesture recognition based on pressure sensitivity, tilt
 * angles, and precise positioning. Subclasses should analyze tablet-
 * specific properties to implement gesture recognition appropriate to
 * stylus-based interaction patterns.
 */
- (void)tabletPoint:(NSEvent *)event;
/**
 * Handles magnification gesture events for gesture recognition. The event
 * parameter contains information about pinch-to-zoom gestures including
 * magnification factors and center points. This method is called when
 * magnification gestures are detected by the system's built-in gesture
 * recognition. Subclasses override this method to implement custom
 * responses to magnification gestures or to combine magnification with
 * other gesture types. The base implementation stores the event for
 * tracking. Magnification events provide high-level gesture information
 * that can be used directly or combined with other event types to create
 * composite gesture recognition behavior.
 */
- (void)magnifyWithEvent:(NSEvent *)event;
/**
 * Handles rotation gesture events for gesture recognition. The event
 * parameter contains information about rotation gestures including rotation
 * angles and center points. This method is called when rotation gestures
 * are detected by the system's built-in gesture recognition. Subclasses
 * override this method to implement custom responses to rotation gestures
 * or to combine rotation with other gesture types. The base implementation
 * stores the event for tracking. Rotation events provide processed gesture
 * data that can be used to implement rotation-based interactions or
 * combined with other events to create complex multi-touch gesture
 * recognition patterns.
 */
- (void)rotateWithEvent:(NSEvent *)event;
/**
 * Handles swipe gesture events for gesture recognition. The event parameter
 * contains information about swipe gestures including direction and velocity.
 * This method is called when swipe gestures are detected by the system's
 * built-in gesture recognition. Subclasses override this method to implement
 * custom responses to swipe gestures or to combine swipes with other
 * gesture types. The base implementation stores the event for tracking.
 * Swipe events provide directional gesture information that enables
 * navigation and transitional interfaces. Subclasses should analyze
 * swipe direction and characteristics to implement appropriate gesture
 * responses and state transitions.
 */
- (void)swipeWithEvent:(NSEvent *)event;
/**
 * Handles scroll wheel events for gesture recognition. The event parameter
 * contains information about scroll wheel input including scroll deltas
 * and direction. This method is called when scroll wheel events occur
 * within the gesture recognizer's associated view. Subclasses override
 * this method to implement gesture recognition that incorporates scroll
 * wheel input. The base implementation stores the event for tracking.
 * Scroll wheel events can be part of composite gestures or can trigger
 * scroll-based gesture sequences. Subclasses should analyze scroll
 * direction, magnitude, and timing to implement scroll wheel gesture
 * recognition appropriate to their specific requirements.
 */
- (void)scrollWheel:(NSEvent *)event;

@end

/**
 * The NSGestureRecognizerDelegate protocol defines methods that customize
 * gesture recognition behavior and enable fine-grained control over gesture
 * recognizer interactions. Delegates can influence when gesture recognition
 * begins, whether gestures should be recognized simultaneously, and how
 * gesture recognizers interact with each other and with the event system.
 * This protocol enables application-specific gesture recognition policies
 * that go beyond the default behavior provided by gesture recognizers.
 * Delegate methods are called at key points during the gesture recognition
 * process, allowing applications to implement custom logic for gesture
 * coordination, conflict resolution, and recognition customization. The
 * delegate pattern provides a powerful mechanism for adapting gesture
 * recognition to specific application requirements without subclassing
 * gesture recognizer classes.
 */
@protocol NSGestureRecognizerDelegate <NSObject>
#if GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#else
@end
@interface NSObject (NSGestureRecognizerDelegate)
#endif
/**
 * Asks the delegate whether the gesture recognizer should attempt to
 * recognize its gesture when the specified event is received. The
 * gestureRecognizer parameter is the recognizer requesting permission
 * to process the event, and the event parameter is the event that
 * triggered the recognition attempt. This method is called before the
 * gesture recognizer processes events and enables the delegate to
 * selectively filter events based on application state, event properties,
 * or other contextual factors. Returning NO prevents the gesture recognizer
 * from processing the event and may cause it to fail. Returning YES
 * allows normal event processing to proceed. This method provides
 * event-level control over gesture recognition and enables dynamic
 * gesture recognition policies based on runtime conditions.
 */
- (BOOL)gestureRecognizer:(NSGestureRecognizer *)gestureRecognizer
shouldAttemptToRecognizeWithEvent:(NSEvent *)event;
/**
 * Asks the delegate whether the gesture recognizer should begin recognizing
 * its gesture. The gestureRecognizer parameter is the recognizer that is
 * about to begin recognition. This method is called when the recognizer
 * has detected initial conditions that might lead to gesture recognition
 * but before committing to the recognition process. Returning NO prevents
 * the gesture recognizer from transitioning out of the possible state
 * and effectively cancels recognition. Returning YES allows recognition
 * to proceed normally. This method provides high-level control over
 * when gesture recognition can begin and enables delegates to implement
 * application-specific recognition policies based on current state or
 * context. The method is not called for every event but only at the
 * beginning of potential recognition sequences.
 */
- (BOOL)gestureRecognizerShouldBegin:(NSGestureRecognizer *)gestureRecognizer;
/**
 * Asks the delegate whether two gesture recognizers should be allowed to
 * recognize their gestures simultaneously. The gestureRecognizer parameter
 * is one of the recognizers, and otherGestureRecognizer is the other
 * recognizer that might recognize simultaneously. This method enables
 * applications to define custom simultaneous recognition policies that
 * go beyond the default mutual exclusion behavior. Returning YES allows
 * both recognizers to succeed at the same time, while returning NO
 * enforces mutual exclusion. This method is called for both recognizers
 * in the pair, and both must return YES for simultaneous recognition
 * to occur. Simultaneous recognition enables complex multi-gesture
 * interactions where multiple gesture types can be active at the same
 * time, such as pinch-to-zoom combined with rotation.
 */
- (BOOL)gestureRecognizer:(NSGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(NSGestureRecognizer *)otherGestureRecognizer;
/**
 * Asks the delegate whether one gesture recognizer should require another
 * to fail before it can succeed. The gestureRecognizer parameter is the
 * recognizer that would wait for failure, and otherGestureRecognizer is
 * the recognizer that must fail first. This method enables dynamic
 * establishment of recognition dependencies based on runtime conditions.
 * Returning YES creates a failure dependency similar to calling
 * requireGestureRecognizerToFail: but allows the dependency to be
 * determined dynamically. Returning NO prevents the dependency from
 * being established. This method provides delegate-controlled recognition
 * precedence that can adapt to changing application state or user
 * interaction patterns. Dynamic dependencies enable flexible gesture
 * hierarchies that respond to contextual factors.
 */
- (BOOL)gestureRecognizer:(NSGestureRecognizer *)gestureRecognizer
shouldRequireFailureOfGestureRecognizer:(NSGestureRecognizer *)otherGestureRecognizer;
/**
 * Asks the delegate whether one gesture recognizer should be required
 * to fail by another gesture recognizer. The gestureRecognizer parameter
 * is the recognizer that might be required to fail, and
 * otherGestureRecognizer is the recognizer that would wait for this
 * failure. This method enables dynamic establishment of recognition
 * dependencies from the perspective of the recognizer that would fail
 * first. Returning YES allows the dependency to be created, while
 * returning NO prevents it. This method complements
 * shouldRequireFailureOfGestureRecognizer: by providing control from
 * both sides of the dependency relationship. Dynamic failure requirements
 * enable sophisticated gesture interaction patterns that adapt to
 * application context and user behavior patterns.
 */
- (BOOL)gestureRecognizer:(NSGestureRecognizer *)gestureRecognizer
shouldBeRequiredToFailByGestureRecognizer:(NSGestureRecognizer *)otherGestureRecognizer;
@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _GNUstep_H_NSGestureRecognizer */

