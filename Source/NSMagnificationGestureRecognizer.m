/* Implementation of class NSMagnificationGestureRecognizer
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

#import <AppKit/NSMagnificationGestureRecognizer.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSCoder.h>
#import <math.h>

@interface NSMagnificationGestureRecognizer ()
- (void)_setState:(NSGestureRecognizerState)state;
- (void)_updateMagnificationWithEvent:(NSEvent *)event;
- (void)_resetMagnificationTracking;
@end

@implementation NSMagnificationGestureRecognizer

#pragma mark - Class Methods

+ (void)initialize
{
  if (self == [NSMagnificationGestureRecognizer class])
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
      _magnification = 0.0;
      _velocity = 0.0;
      _initialLocation = NSZeroPoint;
      _initialMagnification = 1.0;
      _initialTime = 0.0;
      _currentTime = 0.0;
      _magnificationStarted = NO;
      _cumulativeMagnification = 0.0;
    }
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

#pragma mark - Properties

- (CGFloat)magnification
{
  return _magnification;
}

- (CGFloat)velocity
{
  return _velocity;
}

#pragma mark - Gesture Recognition Override Methods

- (void)reset
{
  [super reset];
  [self _resetMagnificationTracking];
}

- (void)scrollWheel:(NSEvent *)event
{
  [super scrollWheel:event];

  if (![self isEnabled])
    {
      return;
    }

  // Check for magnification in scroll wheel event
  CGFloat magnificationDelta = [event magnification];

  if (magnificationDelta != 0.0)
    {
      [self _updateMagnificationWithEvent:event];
    }
  else
    {
      // Check for scroll wheel zoom (when no direct magnification available)
      CGFloat deltaY = [event deltaY];

      if (fabs(deltaY) > 0.1 && ([event modifierFlags] & NSEventModifierFlagCommand))
        {
          // Treat Command+scroll as magnification
          magnificationDelta = deltaY * 0.01; // Scale factor
          [self _updateMagnificationWithEvent:event];
        }
      else if ([self state] == NSGestureRecognizerStateBegan ||
               [self state] == NSGestureRecognizerStateChanged)
        {
          // End gesture if no more magnification input
          [self _setState:NSGestureRecognizerStateEnded];
        }
    }
}

- (void)mouseDown:(NSEvent *)event
{
  [super mouseDown:event];

  if (![self isEnabled] || [self state] != NSGestureRecognizerStatePossible)
    {
      return;
    }

  _initialLocation = [self locationInView:[self view]];
  [self _resetMagnificationTracking];
}

- (void)mouseDragged:(NSEvent *)event
{
  [super mouseDragged:event];

  if (![self isEnabled] || [self state] == NSGestureRecognizerStateFailed)
    {
      return;
    }

  // For mouse drag magnification, we could implement distance-based zoom
  // This is less common but can be useful for some interfaces
  NSPoint currentLocation = [self locationInView:[self view]];
  CGFloat distance = sqrt(pow(currentLocation.x - _initialLocation.x, 2) +
                         pow(currentLocation.y - _initialLocation.y, 2));

  // Only start magnification if significant movement detected
  if (distance > 20.0) // 20 point threshold
    {
      CGFloat magnificationDelta = (distance - 20.0) * 0.001; // Scale factor

      if (!_magnificationStarted)
        {
          _initialTime = [NSDate timeIntervalSinceReferenceDate];
          _magnificationStarted = YES;
          [self _setState:NSGestureRecognizerStateBegan];
        }
      else
        {
          [self _setState:NSGestureRecognizerStateChanged];
        }

      _magnification = magnificationDelta;
      _cumulativeMagnification += magnificationDelta;
      _currentTime = [NSDate timeIntervalSinceReferenceDate];

      // Calculate velocity
      NSTimeInterval timeDelta = _currentTime - _initialTime;
      if (timeDelta > 0)
        {
          _velocity = _cumulativeMagnification / timeDelta;
        }
    }
}

- (void)mouseUp:(NSEvent *)event
{
  if ([self state] == NSGestureRecognizerStatePossible ||
      [self state] == NSGestureRecognizerStateBegan ||
      [self state] == NSGestureRecognizerStateChanged)
    {
      if (_magnificationStarted)
        {
          [self _setState:NSGestureRecognizerStateEnded];
        }
      else
        {
          [self _setState:NSGestureRecognizerStateFailed];
        }
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

- (void)_updateMagnificationWithEvent:(NSEvent *)event
{
  CGFloat magnificationDelta = [event magnification];

  if (magnificationDelta == 0.0)
    {
      // Fallback for systems without direct magnification support
      CGFloat deltaY = [event deltaY];
      if (fabs(deltaY) > 0.1 && ([event modifierFlags] & NSEventModifierFlagCommand))
        {
          magnificationDelta = deltaY * 0.01; // Scale factor
        }
      else
        {
          return;
        }
    }

  if (!_magnificationStarted)
    {
      _initialTime = [NSDate timeIntervalSinceReferenceDate];
      _magnificationStarted = YES;
      _cumulativeMagnification = 0.0;
      [self _setState:NSGestureRecognizerStateBegan];
    }
  else
    {
      [self _setState:NSGestureRecognizerStateChanged];
    }

  _magnification = magnificationDelta;
  _cumulativeMagnification += magnificationDelta;
  _currentTime = [NSDate timeIntervalSinceReferenceDate];

  // Calculate velocity
  NSTimeInterval timeDelta = _currentTime - _initialTime;
  if (timeDelta > 0)
    {
      _velocity = _cumulativeMagnification / timeDelta;
    }
}

- (void)_resetMagnificationTracking
{
  _magnification = 0.0;
  _velocity = 0.0;
  _initialLocation = NSZeroPoint;
  _initialMagnification = 1.0;
  _initialTime = 0.0;
  _currentTime = 0.0;
  _magnificationStarted = NO;
  _cumulativeMagnification = 0.0;
}

#pragma mark - NSCoding Protocol

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self)
    {
      _magnification = 0.0;
      _velocity = 0.0;
      _initialLocation = NSZeroPoint;
      _initialMagnification = 1.0;
      _initialTime = 0.0;
      _currentTime = 0.0;
      _magnificationStarted = NO;
      _cumulativeMagnification = 0.0;
    }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  // Transient state is not encoded since it should not persist
}

@end

