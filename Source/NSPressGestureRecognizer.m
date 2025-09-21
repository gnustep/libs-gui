/* Implementation of class NSPressGestureRecognizer
   Copyright (C) 2019 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Thu Dec  5 12:54:21 EST 2019

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <AppKit/NSPressGestureRecognizer.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSCoder.h>

@interface NSPressGestureRecognizer ()
- (void)_pressTimerFired:(NSTimer *)timer;
- (void)_invalidateTimer;
- (void)_setState:(NSGestureRecognizerState)state;
@end

@implementation NSPressGestureRecognizer

#pragma mark - Class Methods

+ (void)initialize
{
  if (self == [NSPressGestureRecognizer class])
    {
      [self setVersion: 1];
    }
}

#pragma mark - Initialization

/**
 * Initializes a new press gesture recognizer with the specified target
 * and action. The recognizer is configured with default values for
 * minimum press duration of 0.5 seconds, allowable movement of 10 points,
 * and requires a single touch or mouse press. The internal timer and
 * tracking state are initialized to their default values. The recognizer
 * begins in the possible state and is ready to process mouse events.
 */
- (instancetype)initWithTarget:(id)target action:(SEL)action
{
  self = [super initWithTarget:target action:action];
  if (self)
    {
      _minimumPressDuration = 0.5; // Default 0.5 seconds
      _allowableMovement = 10.0;   // Default 10 points
      _numberOfTouchesRequired = 1; // Default single touch
      _pressTimer = nil;
      _initialLocation = NSZeroPoint;
      _pressDetected = NO;
    }
  return self;
}

/**
 * Deallocates the press gesture recognizer and cleans up resources.
 * This method invalidates and releases any active timer to prevent
 * memory leaks and ensure proper cleanup. The superclass dealloc
 * is called to complete the deallocation process. This method is
 * called automatically by the runtime when the recognizer is released.
 */
- (void)dealloc
{
  [self _invalidateTimer];
  [super dealloc];
}

#pragma mark - Properties

/**
 * Returns the current minimum duration in seconds that a press must
 * be held before the gesture is recognized. This value determines the
 * timer delay used to transition from the possible state to the began
 * state. The duration is measured from the initial mouse down event
 * and represents the threshold for distinguishing between a brief
 * click and a sustained press gesture.
 */
- (NSTimeInterval)minimumPressDuration
{
  return _minimumPressDuration;
}

/**
 * Sets the minimum duration in seconds that a press must be held
 * before the gesture is recognized. Negative values are automatically
 * clamped to 0 to prevent invalid timer intervals. This property
 * affects when the internal timer fires and transitions the gesture
 * from the possible state to the began state. Changes to this value
 * take effect on the next gesture recognition cycle.
 */
- (void)setMinimumPressDuration:(NSTimeInterval)duration
{
  if (duration < 0)
    duration = 0;
  _minimumPressDuration = duration;
}

/**
 * Returns the maximum distance in points that the user can move during
 * a press gesture without causing it to fail. This tolerance value
 * accommodates natural hand tremor and minor movements during sustained
 * presses. The distance is calculated as the Euclidean distance from
 * the initial press location to any subsequent location during the
 * gesture. Movement beyond this threshold causes the gesture to fail.
 */
- (CGFloat)allowableMovement
{
  return _allowableMovement;
}

/**
 * Sets the maximum distance in points that the user can move during
 * a press gesture without causing it to fail. Negative values are
 * automatically clamped to 0 to ensure a valid movement threshold.
 * This property controls the sensitivity of the gesture recognizer
 * to movement during the press. Smaller values create stricter
 * movement requirements while larger values are more permissive.
 */
- (void)setAllowableMovement:(CGFloat)movement
{
  if (movement < 0)
    movement = 0;
  _allowableMovement = movement;
}

/**
 * Returns the number of touches or mouse presses required to trigger
 * the gesture recognition process. For mouse-based systems, this is
 * typically 1 since simultaneous multiple mouse presses are uncommon.
 * This property determines how many concurrent press points must be
 * detected before the gesture recognizer begins timing and tracking
 * the press gesture. The default value is 1 for single-press gestures.
 */
- (NSUInteger)numberOfTouchesRequired
{
  return _numberOfTouchesRequired;
}

/**
 * Sets the number of touches or mouse presses required to trigger
 * the gesture recognition process. Values of 0 are automatically
 * clamped to 1 to ensure at least one press is required. This
 * property is most relevant for multi-touch interfaces where
 * multiple simultaneous presses might be desired. For traditional
 * mouse interfaces, this should remain at 1 for optimal usability.
 */
- (void)setNumberOfTouchesRequired:(NSUInteger)numberOfTouches
{
  if (numberOfTouches == 0)
    numberOfTouches = 1;
  _numberOfTouchesRequired = numberOfTouches;
}

#pragma mark - Gesture Recognition Override Methods

/**
 * Resets the press gesture recognizer to its initial state after
 * a gesture ends or fails. This method cleans up the internal timer,
 * clears tracking locations, and resets detection flags. The superclass
 * reset method is called first to ensure proper base class cleanup.
 * This method is called automatically by the gesture recognition
 * framework when transitioning to terminal states.
 */
- (void)reset
{
  [super reset];
  [self _invalidateTimer];
  _initialLocation = NSZeroPoint;
  _pressDetected = NO;
}

/**
 * Handles mouse down events to begin press gesture recognition. This
 * method validates that the recognizer is enabled and in the possible
 * state, then checks if the required number of touches matches the
 * current event. If conditions are met, it stores the initial press
 * location and starts the minimum duration timer. The gesture remains
 * in the possible state until the timer fires or the gesture fails
 * due to movement or early release.
 */
- (void)mouseDown:(NSEvent *)event
{
  [super mouseDown:event];

  if (![self isEnabled] || [self state] != NSGestureRecognizerStatePossible)
    {
      return;
    }

  // Check if we have the required number of touches (simplified for mouse events)
  if (_numberOfTouchesRequired != 1)
    {
      [self _setState:NSGestureRecognizerStateFailed];
      return;
    }

  // Store the initial location
  _initialLocation = [self locationInView:[self view]];
  _pressDetected = NO;

  // Start the press timer
  [self _invalidateTimer];
  _pressTimer = [NSTimer scheduledTimerWithTimeInterval:_minimumPressDuration
                                                 target:self
                                               selector:@selector(_pressTimerFired:)
                                               userInfo:nil
                                                repeats:NO];
}

/**
 * Handles mouse drag events during a potential press gesture. This
 * method calculates the distance moved from the initial press location
 * and compares it against the allowable movement threshold. If the
 * movement exceeds the threshold, the gesture fails immediately. If
 * the gesture is already in the began state and movement is within
 * tolerance, the state transitions to changed to indicate continued
 * gesture recognition with slight movement.
 */
- (void)mouseDragged:(NSEvent *)event
{
  [super mouseDragged:event];

  if (![self isEnabled] || [self state] == NSGestureRecognizerStateFailed)
    {
      return;
    }

  // Check if movement exceeds allowable threshold
  NSPoint currentLocation = [self locationInView:[self view]];
  CGFloat distance = sqrt(pow(currentLocation.x - _initialLocation.x, 2) +
                         pow(currentLocation.y - _initialLocation.y, 2));

  if (distance > _allowableMovement)
    {
      [self _invalidateTimer];
      [self _setState:NSGestureRecognizerStateFailed];
      return;
    }

  // If we've already detected a press and we're within allowable movement,
  // update the state to changed
  if (_pressDetected && [self state] == NSGestureRecognizerStateBegan)
    {
      [self _setState:NSGestureRecognizerStateChanged];
    }
}

/**
 * Handles mouse up events to complete or terminate press gesture
 * recognition. If the gesture is in an active state and the minimum
 * duration timer has fired indicating a successful press, the gesture
 * transitions to the ended state. If the timer has not fired, indicating
 * an early release, the gesture transitions to the failed state. The
 * internal timer is invalidated and tracking state is reset regardless
 * of the outcome.
 */
- (void)mouseUp:(NSEvent *)event
{
  if ([self state] == NSGestureRecognizerStatePossible ||
      [self state] == NSGestureRecognizerStateBegan ||
      [self state] == NSGestureRecognizerStateChanged)
    {
      [self _invalidateTimer];

      if (_pressDetected)
        {
          [self _setState:NSGestureRecognizerStateEnded];
        }
      else
        {
          [self _setState:NSGestureRecognizerStateFailed];
        }

      _pressDetected = NO;
      _initialLocation = NSZeroPoint;
    }
}

/**
 * Handles right mouse button down events by delegating to the standard
 * mouse down handler. Press gestures can be triggered by any mouse
 * button, so right mouse events are treated identically to left mouse
 * events. The superclass method is called first to ensure proper
 * event propagation and then the standard mouse down processing is
 * invoked to begin gesture recognition timing and tracking.
 */
- (void)rightMouseDown:(NSEvent *)event
{
  [super rightMouseDown:event];
  [self mouseDown:event]; // Treat right mouse like left mouse for press gestures
}

/**
 * Handles right mouse button drag events by delegating to the standard
 * mouse drag handler. Movement tracking and tolerance checking are
 * identical regardless of which mouse button initiated the press gesture.
 * The superclass method is called for proper event handling and then
 * the standard drag processing validates movement against the allowable
 * threshold and updates gesture state accordingly.
 */
- (void)rightMouseDragged:(NSEvent *)event
{
  [super rightMouseDragged:event];
  [self mouseDragged:event];
}

/**
 * Handles right mouse button up events by delegating to the standard
 * mouse up handler. Press gesture completion logic is identical for
 * all mouse buttons, checking if the minimum duration was met and
 * transitioning to the appropriate final state. The superclass method
 * ensures proper event handling while the standard mouse up processing
 * determines gesture success or failure based on timing.
 */
- (void)rightMouseUp:(NSEvent *)event
{
  [super rightMouseUp:event];
  [self mouseUp:event];
}

/**
 * Handles other mouse button down events by delegating to the standard
 * mouse down handler. This includes middle mouse buttons and additional
 * buttons on multi-button mice. Press gestures are uniformly supported
 * across all mouse buttons to provide consistent behavior. The superclass
 * method handles event propagation while the standard processing begins
 * gesture recognition with timing and location tracking.
 */
- (void)otherMouseDown:(NSEvent *)event
{
  [super otherMouseDown:event];
  [self mouseDown:event]; // Treat other mouse buttons like left mouse
}

/**
 * Handles other mouse button drag events by delegating to the standard
 * mouse drag handler. Movement validation and state transitions are
 * consistent across all mouse button types to ensure predictable
 * behavior. The superclass method manages event handling while the
 * standard drag processing checks movement tolerance and updates
 * the gesture state based on distance from the initial location.
 */
- (void)otherMouseDragged:(NSEvent *)event
{
  [super otherMouseDragged:event];
  [self mouseDragged:event];
}

/**
 * Handles other mouse button up events by delegating to the standard
 * mouse up handler. Gesture completion processing is uniform across
 * all mouse button types, evaluating whether the minimum press duration
 * was achieved and transitioning to the appropriate terminal state.
 * The superclass method ensures proper event handling while standard
 * processing determines the final outcome of the gesture.
 */
- (void)otherMouseUp:(NSEvent *)event
{
  [super otherMouseUp:event];
  [self mouseUp:event];
}

#pragma mark - Private Methods

/**
 * Internal timer callback method invoked when the minimum press duration
 * has elapsed. If the gesture recognizer is still in the possible state,
 * indicating that the press has been maintained without excessive movement
 * or early release, the gesture transitions to the began state and the
 * press is considered successfully detected. The timer is then invalidated
 * to prevent further callbacks and conserve resources.
 */
- (void)_pressTimerFired:(NSTimer *)timer
{
  if ([self state] == NSGestureRecognizerStatePossible)
    {
      _pressDetected = YES;
      [self _setState:NSGestureRecognizerStateBegan];
    }
  [self _invalidateTimer];
}

/**
 * Invalidates and cleans up the internal press timer to prevent memory
 * leaks and unwanted timer callbacks. This method safely checks for
 * timer existence before invalidating and sets the timer reference to
 * nil to prevent future access to the invalidated timer. This cleanup
 * is essential when gestures fail, succeed, or when the recognizer
 * is being deallocated to ensure proper resource management.
 */
- (void)_invalidateTimer
{
  if (_pressTimer)
    {
      [_pressTimer invalidate];
      _pressTimer = nil;
    }
}

#pragma mark - NSCoding

#pragma mark - NSCoding Protocol

/**
 * Initializes a press gesture recognizer from encoded data during
 * deserialization. This method decodes the minimum press duration,
 * allowable movement, and number of touches required from the coder
 * using both keyed and non-keyed coding formats for compatibility.
 * Invalid decoded values are replaced with sensible defaults to ensure
 * proper functionality. Transient state like timers and locations are
 * initialized to their default values since they should not persist.
 */
- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self)
    {
      if ([coder allowsKeyedCoding])
        {
          _minimumPressDuration = [coder decodeDoubleForKey:@"NSMinimumPressDuration"];
          _allowableMovement = [coder decodeDoubleForKey:@"NSAllowableMovement"];
          _numberOfTouchesRequired = [coder decodeIntegerForKey:@"NSNumberOfTouchesRequired"];
        }
      else
        {
          [coder decodeValueOfObjCType:@encode(NSTimeInterval) at:&_minimumPressDuration];
          [coder decodeValueOfObjCType:@encode(CGFloat) at:&_allowableMovement];
          [coder decodeValueOfObjCType:@encode(NSUInteger) at:&_numberOfTouchesRequired];
        }

      // Set defaults if values are invalid
      if (_minimumPressDuration <= 0)
        _minimumPressDuration = 0.5;
      if (_allowableMovement < 0)
        _allowableMovement = 10.0;
      if (_numberOfTouchesRequired == 0)
        _numberOfTouchesRequired = 1;

      _pressTimer = nil;
      _initialLocation = NSZeroPoint;
      _pressDetected = NO;
    }
  return self;
}

/**
 * Encodes the press gesture recognizer's configuration for serialization.
 * This method encodes the minimum press duration, allowable movement,
 * and number of touches required using both keyed and non-keyed coding
 * formats to maintain compatibility with different archiving mechanisms.
 * Only persistent configuration properties are encoded since transient
 * state like timers and current locations should not be preserved
 * across serialization boundaries.
 */
- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];

  if ([coder allowsKeyedCoding])
    {
      [coder encodeDouble:_minimumPressDuration forKey:@"NSMinimumPressDuration"];
      [coder encodeDouble:_allowableMovement forKey:@"NSAllowableMovement"];
      [coder encodeInteger:_numberOfTouchesRequired forKey:@"NSNumberOfTouchesRequired"];
    }
  else
    {
      [coder encodeValueOfObjCType:@encode(NSTimeInterval) at:&_minimumPressDuration];
      [coder encodeValueOfObjCType:@encode(CGFloat) at:&_allowableMovement];
      [coder encodeValueOfObjCType:@encode(NSUInteger) at:&_numberOfTouchesRequired];
    }
}

@end

