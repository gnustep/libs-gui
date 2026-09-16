/* Implementation of class NSRotationGestureRecognizer
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

#import <AppKit/NSRotationGestureRecognizer.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSCoder.h>
#import <math.h>

@interface NSRotationGestureRecognizer ()
- (void)_setState:(NSGestureRecognizerState)state;
- (CGFloat)_angleFromPoint:(NSPoint)fromPoint toPoint:(NSPoint)toPoint;
- (CGFloat)_normalizeAngle:(CGFloat)angle;
- (void)_updateRotationWithEvent:(NSEvent *)event;
@end

@implementation NSRotationGestureRecognizer

#pragma mark - Class Methods

+ (void)initialize
{
  if (self == [NSRotationGestureRecognizer class])
    {
      [self setVersion: 1];
    }
}

#pragma mark - Initialization

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
  self = [super initWithTarget:target action:action];
  if (self)
    {
      _rotation = 0.0;
      _velocity = 0.0;
      _initialLocation = NSZeroPoint;
      _currentLocation = NSZeroPoint;
      _initialAngle = 0.0;
      _currentAngle = 0.0;
      _initialTime = 0.0;
      _currentTime = 0.0;
      _rotationStarted = NO;
    }
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

#pragma mark - Properties

- (CGFloat)rotation
{
  return _rotation;
}

- (CGFloat)velocity
{
  return _velocity;
}

#pragma mark - Gesture Recognition Override Methods

- (void)reset
{
  [super reset];
  _rotation = 0.0;
  _velocity = 0.0;
  _initialLocation = NSZeroPoint;
  _currentLocation = NSZeroPoint;
  _initialAngle = 0.0;
  _currentAngle = 0.0;
  _initialTime = 0.0;
  _currentTime = 0.0;
  _rotationStarted = NO;
}

- (void)mouseDown:(NSEvent *)event
{
  [super mouseDown:event];

  if (![self isEnabled] || [self state] != NSGestureRecognizerStatePossible)
    {
      return;
    }

  _initialLocation = [self locationInView:[self view]];
  _currentLocation = _initialLocation;
  _initialAngle = 0.0;
  _currentAngle = 0.0;
  _initialTime = [NSDate timeIntervalSinceReferenceDate];
  _currentTime = _initialTime;
  _rotationStarted = NO;
  _rotation = 0.0;
  _velocity = 0.0;
}

- (void)mouseDragged:(NSEvent *)event
{
  [super mouseDragged:event];

  if (![self isEnabled] || [self state] == NSGestureRecognizerStateFailed)
    {
      return;
    }

  [self _updateRotationWithEvent:event];
}

- (void)mouseUp:(NSEvent *)event
{
  if ([self state] == NSGestureRecognizerStatePossible ||
      [self state] == NSGestureRecognizerStateBegan ||
      [self state] == NSGestureRecognizerStateChanged)
    {
      if (_rotationStarted)
        {
          [self _setState:NSGestureRecognizerStateEnded];
        }
      else
        {
          [self _setState:NSGestureRecognizerStateFailed];
        }
    }
}

- (void)scrollWheel:(NSEvent *)event
{
  [super scrollWheel:event];

  if (![self isEnabled] || [self state] == NSGestureRecognizerStateFailed)
    {
      return;
    }

  // Handle scroll wheel rotation gestures
  CGFloat deltaX = [event deltaX];
  CGFloat deltaY = [event deltaY];

  // Calculate rotation from scroll deltas
  CGFloat rotationDelta = atan2(deltaY, deltaX);

  if (!_rotationStarted)
    {
      _initialTime = [NSDate timeIntervalSinceReferenceDate];
      _rotationStarted = YES;
      [self _setState:NSGestureRecognizerStateBegan];
    }
  else
    {
      [self _setState:NSGestureRecognizerStateChanged];
    }

  _rotation += rotationDelta;
  _currentTime = [NSDate timeIntervalSinceReferenceDate];

  // Calculate velocity
  NSTimeInterval timeDelta = _currentTime - _initialTime;
  if (timeDelta > 0)
    {
      _velocity = _rotation / timeDelta;
    }
}

- (void)rightMouseDown:(NSEvent *)event
{
  [super rightMouseDown:event];
  [self mouseDown:event];
}

- (void)rightMouseDragged:(NSEvent *)event
{
  [super rightMouseDragged:event];
  [self mouseDragged:event];
}

- (void)rightMouseUp:(NSEvent *)event
{
  [super rightMouseUp:event];
  [self mouseUp:event];
}

- (void)otherMouseDown:(NSEvent *)event
{
  [super otherMouseDown:event];
  [self mouseDown:event];
}

- (void)otherMouseDragged:(NSEvent *)event
{
  [super otherMouseDragged:event];
  [self mouseDragged:event];
}

- (void)otherMouseUp:(NSEvent *)event
{
  [super otherMouseUp:event];
  [self mouseUp:event];
}

#pragma mark - Private Methods

- (CGFloat)_angleFromPoint:(NSPoint)fromPoint toPoint:(NSPoint)toPoint
{
  CGFloat deltaX = toPoint.x - fromPoint.x;
  CGFloat deltaY = toPoint.y - fromPoint.y;
  return atan2(deltaY, deltaX);
}

- (CGFloat)_normalizeAngle:(CGFloat)angle
{
  while (angle > M_PI)
    angle -= 2 * M_PI;
  while (angle < -M_PI)
    angle += 2 * M_PI;
  return angle;
}

- (void)_updateRotationWithEvent:(NSEvent *)event
{
  NSPoint newLocation = [self locationInView:[self view]];
  NSPoint centerPoint = NSMakePoint((_initialLocation.x + newLocation.x) / 2.0,
                                   (_initialLocation.y + newLocation.y) / 2.0);

  // Calculate angles from center point
  CGFloat newAngle = [self _angleFromPoint:centerPoint toPoint:newLocation];

  if (!_rotationStarted)
    {
      _initialAngle = [self _angleFromPoint:centerPoint toPoint:_initialLocation];
      _currentAngle = newAngle;
      _rotation = [self _normalizeAngle:(_currentAngle - _initialAngle)];

      // Check if rotation threshold is met to start gesture
      if (fabs(_rotation) > 0.1) // ~5.7 degrees threshold
        {
          _rotationStarted = YES;
          _initialTime = [NSDate timeIntervalSinceReferenceDate];
          [self _setState:NSGestureRecognizerStateBegan];
        }
    }
  else
    {
      _currentAngle = newAngle;
      _rotation = [self _normalizeAngle:(_currentAngle - _initialAngle)];
      [self _setState:NSGestureRecognizerStateChanged];
    }

  _currentLocation = newLocation;
  _currentTime = [NSDate timeIntervalSinceReferenceDate];

  // Calculate velocity
  NSTimeInterval timeDelta = _currentTime - _initialTime;
  if (timeDelta > 0)
    {
      _velocity = _rotation / timeDelta;
    }
}

#pragma mark - NSCoding Protocol

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self)
    {
      _rotation = 0.0;
      _velocity = 0.0;
      _initialLocation = NSZeroPoint;
      _currentLocation = NSZeroPoint;
      _initialAngle = 0.0;
      _currentAngle = 0.0;
      _initialTime = 0.0;
      _currentTime = 0.0;
      _rotationStarted = NO;
    }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  // Transient state is not encoded since it should not persist
}

@end

