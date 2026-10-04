/* Implementation of class NSPanGestureRecognizer
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

#import <AppKit/NSPanGestureRecognizer.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSView.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDate.h>
#include <math.h>

@implementation NSPanGestureRecognizer

// Initialization

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
  self = [super initWithTarget:target action:action];
  if (self != nil)
    {
      _minimumNumberOfTouches = 1;
      _maximumNumberOfTouches = NSUIntegerMax;
      _translation = NSZeroPoint;
      _velocity = NSZeroPoint;
      _startLocation = NSZeroPoint;
      _previousLocation = NSZeroPoint;
      _previousTime = 0.0;
      _isTracking = NO;
      _buttonMask = 1; // Default to left mouse button
    }
  return self;
}

- (instancetype)init
{
  return [self initWithTarget:nil action:NULL];
}

// Touch Count Properties

- (NSUInteger)minimumNumberOfTouches
{
  return _minimumNumberOfTouches;
}

- (void)setMinimumNumberOfTouches:(NSUInteger)touches
{
  if (touches >= 1)
    {
      _minimumNumberOfTouches = touches;
      if (_maximumNumberOfTouches < _minimumNumberOfTouches)
        {
          _maximumNumberOfTouches = _minimumNumberOfTouches;
        }
    }
}

- (NSUInteger)maximumNumberOfTouches
{
  return _maximumNumberOfTouches;
}

- (void)setMaximumNumberOfTouches:(NSUInteger)touches
{
  if (touches >= _minimumNumberOfTouches)
    {
      _maximumNumberOfTouches = touches;
    }
}

// Button Mask Property

- (NSUInteger)buttonMask
{
  return _buttonMask;
}

- (void)setButtonMask:(NSUInteger)mask
{
  _buttonMask = mask;
}

// Translation Methods

- (NSPoint)translationInView:(NSView *)view
{
  if (view == nil || view == [self view])
    {
      return _translation;
    }

  // Convert translation to the specified view's coordinate system
  NSView *gestureView = [self view];
  if (gestureView != nil)
    {
      NSPoint convertedTranslation = [view convertPoint:_translation fromView:gestureView];
      NSPoint basePoint = [view convertPoint:NSZeroPoint fromView:gestureView];
      return NSMakePoint(convertedTranslation.x - basePoint.x, convertedTranslation.y - basePoint.y);
    }

  return _translation;
}

- (void)setTranslation:(NSPoint)translation inView:(NSView *)view
{
  if (view == nil || view == [self view])
    {
      _translation = translation;
    }
  else
    {
      // Convert translation from the specified view's coordinate system
      NSView *gestureView = [self view];
      if (gestureView != nil)
        {
          NSPoint convertedTranslation = [gestureView convertPoint:translation fromView:view];
          NSPoint basePoint = [gestureView convertPoint:NSZeroPoint fromView:view];
          _translation = NSMakePoint(convertedTranslation.x - basePoint.x, convertedTranslation.y - basePoint.y);
        }
      else
        {
          _translation = translation;
        }
    }
}

// Velocity Methods

- (NSPoint)velocityInView:(NSView *)view
{
  if (view == nil || view == [self view])
    {
      return _velocity;
    }

  // Convert velocity to the specified view's coordinate system
  NSView *gestureView = [self view];
  if (gestureView != nil)
    {
      // For velocity, we only need to account for scaling, not translation
      NSPoint unitPoint = NSMakePoint(1.0, 1.0);
      NSPoint convertedUnit = [view convertPoint:unitPoint fromView:gestureView];
      NSPoint basePoint = [view convertPoint:NSZeroPoint fromView:gestureView];
      CGFloat xScale = convertedUnit.x - basePoint.x;
      CGFloat yScale = convertedUnit.y - basePoint.y;
      return NSMakePoint(_velocity.x * xScale, _velocity.y * yScale);
    }

  return _velocity;
}

// Private Methods

- (void)_updateTranslationAndVelocityWithEvent:(NSEvent *)event
{
  NSPoint currentLocation = [event locationInWindow];
  NSTimeInterval currentTime = [event timestamp];

  if (!_isTracking)
    {
      _startLocation = currentLocation;
      _previousLocation = currentLocation;
      _previousTime = currentTime;
      _translation = NSZeroPoint;
      _velocity = NSZeroPoint;
      _isTracking = YES;
    }
  else
    {
      // Update translation
      _translation = NSMakePoint(currentLocation.x - _startLocation.x,
                                currentLocation.y - _startLocation.y);

      // Update velocity
      NSTimeInterval timeDelta = currentTime - _previousTime;
      if (timeDelta > 0.0)
        {
          CGFloat deltaX = currentLocation.x - _previousLocation.x;
          CGFloat deltaY = currentLocation.y - _previousLocation.y;
          _velocity = NSMakePoint(deltaX / timeDelta, deltaY / timeDelta);
        }

      _previousLocation = currentLocation;
      _previousTime = currentTime;
    }
}

- (void)_resetPanTracking
{
  _translation = NSZeroPoint;
  _velocity = NSZeroPoint;
  _startLocation = NSZeroPoint;
  _previousLocation = NSZeroPoint;
  _previousTime = 0.0;
  _isTracking = NO;
}

- (BOOL)_shouldRecognizeButtonForEvent:(NSEvent *)event
{
  NSUInteger buttonNumber = 0;
  NSEventType eventType = [event type];

  switch (eventType)
    {
    case NSLeftMouseDown:
    case NSLeftMouseDragged:
    case NSLeftMouseUp:
      buttonNumber = 0;
      break;
    case NSRightMouseDown:
    case NSRightMouseDragged:
    case NSRightMouseUp:
      buttonNumber = 1;
      break;
    case NSOtherMouseDown:
    case NSOtherMouseDragged:
    case NSOtherMouseUp:
      buttonNumber = [event buttonNumber];
      break;
    default:
      return NO;
    }

  NSUInteger eventButtonMask = 1 << buttonNumber;
  return (_buttonMask & eventButtonMask) != 0;
}

// Gesture Recognition Event Handlers

- (void)mouseDown:(NSEvent *)event
{
  [super mouseDown:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      [self setState:NSGestureRecognizerStateFailed];
      return;
    }

  [self setState:NSGestureRecognizerStatePossible];
  [self _updateTranslationAndVelocityWithEvent:event];
}

- (void)rightMouseDown:(NSEvent *)event
{
  [super rightMouseDown:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      [self setState:NSGestureRecognizerStateFailed];
      return;
    }

  [self setState:NSGestureRecognizerStatePossible];
  [self _updateTranslationAndVelocityWithEvent:event];
}

- (void)otherMouseDown:(NSEvent *)event
{
  [super otherMouseDown:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      [self setState:NSGestureRecognizerStateFailed];
      return;
    }

  [self setState:NSGestureRecognizerStatePossible];
  [self _updateTranslationAndVelocityWithEvent:event];
}

- (void)mouseDragged:(NSEvent *)event
{
  [super mouseDragged:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      return;
    }

  NSGestureRecognizerState currentState = [self state];

  if (currentState == NSGestureRecognizerStatePossible)
    {
      [self setState:NSGestureRecognizerStateBegan];
    }
  else if (currentState == NSGestureRecognizerStateBegan ||
           currentState == NSGestureRecognizerStateChanged)
    {
      [self setState:NSGestureRecognizerStateChanged];
    }

  [self _updateTranslationAndVelocityWithEvent:event];
}

- (void)rightMouseDragged:(NSEvent *)event
{
  [super rightMouseDragged:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      return;
    }

  NSGestureRecognizerState currentState = [self state];

  if (currentState == NSGestureRecognizerStatePossible)
    {
      [self setState:NSGestureRecognizerStateBegan];
    }
  else if (currentState == NSGestureRecognizerStateBegan ||
           currentState == NSGestureRecognizerStateChanged)
    {
      [self setState:NSGestureRecognizerStateChanged];
    }

  [self _updateTranslationAndVelocityWithEvent:event];
}

- (void)otherMouseDragged:(NSEvent *)event
{
  [super otherMouseDragged:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      return;
    }

  NSGestureRecognizerState currentState = [self state];

  if (currentState == NSGestureRecognizerStatePossible)
    {
      [self setState:NSGestureRecognizerStateBegan];
    }
  else if (currentState == NSGestureRecognizerStateBegan ||
           currentState == NSGestureRecognizerStateChanged)
    {
      [self setState:NSGestureRecognizerStateChanged];
    }

  [self _updateTranslationAndVelocityWithEvent:event];
}

- (void)mouseUp:(NSEvent *)event
{
  [super mouseUp:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      return;
    }

  NSGestureRecognizerState currentState = [self state];

  if (currentState == NSGestureRecognizerStateBegan ||
      currentState == NSGestureRecognizerStateChanged)
    {
      [self setState:NSGestureRecognizerStateEnded];
    }
  else if (currentState == NSGestureRecognizerStatePossible)
    {
      [self setState:NSGestureRecognizerStateFailed];
    }
}

- (void)rightMouseUp:(NSEvent *)event
{
  [super rightMouseUp:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      return;
    }

  NSGestureRecognizerState currentState = [self state];

  if (currentState == NSGestureRecognizerStateBegan ||
      currentState == NSGestureRecognizerStateChanged)
    {
      [self setState:NSGestureRecognizerStateEnded];
    }
  else if (currentState == NSGestureRecognizerStatePossible)
    {
      [self setState:NSGestureRecognizerStateFailed];
    }
}

- (void)otherMouseUp:(NSEvent *)event
{
  [super otherMouseUp:event];

  if (![self isEnabled] || ![self _shouldRecognizeButtonForEvent:event])
    {
      return;
    }

  NSGestureRecognizerState currentState = [self state];

  if (currentState == NSGestureRecognizerStateBegan ||
      currentState == NSGestureRecognizerStateChanged)
    {
      [self setState:NSGestureRecognizerStateEnded];
    }
  else if (currentState == NSGestureRecognizerStatePossible)
    {
      [self setState:NSGestureRecognizerStateFailed];
    }
}

// Reset Method

- (void)reset
{
  [super reset];
  [self _resetPanTracking];
}

// NSCoding Support

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:[NSNumber numberWithUnsignedInteger:_minimumNumberOfTouches]
               forKey:@"NSPanGestureRecognizer.minimumNumberOfTouches"];
  [coder encodeObject:[NSNumber numberWithUnsignedInteger:_maximumNumberOfTouches]
               forKey:@"NSPanGestureRecognizer.maximumNumberOfTouches"];
  [coder encodeObject:[NSNumber numberWithUnsignedInteger:_buttonMask]
               forKey:@"NSPanGestureRecognizer.buttonMask"];
  [coder encodeObject:[NSValue valueWithPoint:_translation]
               forKey:@"NSPanGestureRecognizer.translation"];
  [coder encodeObject:[NSValue valueWithPoint:_velocity]
               forKey:@"NSPanGestureRecognizer.velocity"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self != nil)
    {
      NSNumber *minTouches = [coder decodeObjectForKey:@"NSPanGestureRecognizer.minimumNumberOfTouches"];
      _minimumNumberOfTouches = minTouches ? [minTouches unsignedIntegerValue] : 1;

      NSNumber *maxTouches = [coder decodeObjectForKey:@"NSPanGestureRecognizer.maximumNumberOfTouches"];
      _maximumNumberOfTouches = maxTouches ? [maxTouches unsignedIntegerValue] : NSUIntegerMax;

      NSNumber *buttonMask = [coder decodeObjectForKey:@"NSPanGestureRecognizer.buttonMask"];
      _buttonMask = buttonMask ? [buttonMask unsignedIntegerValue] : 1;

      NSValue *translation = [coder decodeObjectForKey:@"NSPanGestureRecognizer.translation"];
      _translation = translation ? [translation pointValue] : NSZeroPoint;

      NSValue *velocity = [coder decodeObjectForKey:@"NSPanGestureRecognizer.velocity"];
      _velocity = velocity ? [velocity pointValue] : NSZeroPoint;

      _startLocation = NSZeroPoint;
      _previousLocation = NSZeroPoint;
      _previousTime = 0.0;
      _isTracking = NO;
    }
  return self;
}

// NSCopying Support

- (id)copyWithZone:(NSZone *)zone
{
  NSPanGestureRecognizer *copy = [super copyWithZone:zone];
  if (copy != nil)
    {
      copy->_minimumNumberOfTouches = _minimumNumberOfTouches;
      copy->_maximumNumberOfTouches = _maximumNumberOfTouches;
      copy->_buttonMask = _buttonMask;
      copy->_translation = _translation;
      copy->_velocity = _velocity;
      copy->_startLocation = _startLocation;
      copy->_previousLocation = _previousLocation;
      copy->_previousTime = _previousTime;
      copy->_isTracking = _isTracking;
    }
  return copy;
}

// Description

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: %p; state = %ld; translation = {%f, %f}; velocity = {%f, %f}; minTouches = %lu; maxTouches = %lu; buttonMask = %lu>",
          [self class], self, (long)[self state],
          _translation.x, _translation.y, _velocity.x, _velocity.y,
          (unsigned long)_minimumNumberOfTouches, (unsigned long)_maximumNumberOfTouches,
          (unsigned long)_buttonMask];
}

@end

