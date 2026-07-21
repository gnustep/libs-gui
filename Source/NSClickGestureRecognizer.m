/* Implementation of class NSClickGestureRecognizer
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

#import <AppKit/NSClickGestureRecognizer.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSValue.h>

@implementation NSClickGestureRecognizer

// Initialization

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
  self = [super initWithTarget: target action: action];
  if (self != nil)
    {
      _buttonMask = 1; // Default to left mouse button
      _numberOfClicksRequired = 1; // Default to single click
      _numberOfTouchesRequired = 1; // Default to single touch
    }
  return self;
}

- (instancetype)init
{
  return [self initWithTarget: nil action: NULL];
}

// Button Mask Property

- (NSUInteger) buttonMask
{
  return _buttonMask;
}

- (void) setButtonMask:(NSUInteger)mask
{
  _buttonMask = mask;
}

// Number of Clicks Required Property

- (NSUInteger) numberOfClicksRequired
{
  return _numberOfClicksRequired;
}

- (void) setNumberOfClicksRequired:(NSUInteger)clicks
{
  if (clicks >= 1)
    {
      _numberOfClicksRequired = clicks;
    }
}

// Number of Touches Required Property

- (NSUInteger) numberOfTouchesRequired
{
  return _numberOfTouchesRequired;
}

- (void) setNumberOfTouchesRequired:(NSUInteger)touches
{
  if (touches >= 1)
    {
      _numberOfTouchesRequired = touches;
    }
}

// Gesture Recognition Event Handlers

- (void) mouseDown:(NSEvent *)event
{
  [super mouseDown: event];

  if (![self isEnabled])
    {
      return;
    }

  // Check if the button matches our requirements
  NSUInteger buttonNumber = [event buttonNumber];
  NSUInteger eventButtonMask = 1 << buttonNumber;

  if ((_buttonMask & eventButtonMask) == 0)
    {
      [self setState: NSGestureRecognizerStateFailed];
      return;
    }

  // Check click count
  NSInteger clickCount = [event clickCount];
  if (clickCount == _numberOfClicksRequired)
    {
      [self setState: NSGestureRecognizerStateRecognized];
    }
  else if (clickCount < _numberOfClicksRequired)
    {
      [self setState: NSGestureRecognizerStatePossible];
    }
  else
    {
      [self setState: NSGestureRecognizerStateFailed];
    }
}

- (void) rightMouseDown:(NSEvent *)event
{
  [super rightMouseDown: event];

  if (![self isEnabled])
    {
      return;
    }

  // Right mouse button has button number 1
  NSUInteger eventButtonMask = 1 << 1;

  if ((_buttonMask & eventButtonMask) == 0)
    {
      [self setState: NSGestureRecognizerStateFailed];
      return;
    }

  // Check click count
  NSInteger clickCount = [event clickCount];
  if (clickCount == _numberOfClicksRequired)
    {
      [self setState: NSGestureRecognizerStateRecognized];
    }
  else if (clickCount < _numberOfClicksRequired)
    {
      [self setState: NSGestureRecognizerStatePossible];
    }
  else
    {
      [self setState: NSGestureRecognizerStateFailed];
    }
}

- (void) otherMouseDown:(NSEvent *)event
{
  [super otherMouseDown: event];

  if (![self isEnabled])
    {
      return;
    }

  // Other mouse buttons start from button number 2
  NSUInteger buttonNumber = [event buttonNumber];
  NSUInteger eventButtonMask = 1 << buttonNumber;

  if ((_buttonMask & eventButtonMask) == 0)
    {
      [self setState: NSGestureRecognizerStateFailed];
      return;
    }

  // Check click count
  NSInteger clickCount = [event clickCount];
  if (clickCount == _numberOfClicksRequired)
    {
      [self setState: NSGestureRecognizerStateRecognized];
    }
  else if (clickCount < _numberOfClicksRequired)
    {
      [self setState: NSGestureRecognizerStatePossible];
    }
  else
    {
      [self setState: NSGestureRecognizerStateFailed];
    }
}

- (void) mouseDragged:(NSEvent *)event
{
  [super mouseDragged: event];

  // If we're in possible state and user starts dragging, fail the gesture
  if ([self state] == NSGestureRecognizerStatePossible)
    {
      [self setState: NSGestureRecognizerStateFailed];
    }
}

- (void) rightMouseDragged:(NSEvent *)event
{
  [super rightMouseDragged: event];

  // If we're in possible state and user starts dragging, fail the gesture
  if ([self state] == NSGestureRecognizerStatePossible)
    {
      [self setState: NSGestureRecognizerStateFailed];
    }
}

- (void) otherMouseDragged:(NSEvent *)event
{
  [super otherMouseDragged: event];

  // If we're in possible state and user starts dragging, fail the gesture
  if ([self state] == NSGestureRecognizerStatePossible)
    {
      [self setState: NSGestureRecognizerStateFailed];
    }
}

// NSCoding Support

- (void) encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder: coder];
  [coder encodeObject: [NSNumber numberWithUnsignedInteger: _buttonMask] forKey: @"NSClickGestureRecognizer.buttonMask"];
  [coder encodeObject: [NSNumber numberWithUnsignedInteger: _numberOfClicksRequired] forKey: @"NSClickGestureRecognizer.numberOfClicksRequired"];
  [coder encodeObject: [NSNumber numberWithUnsignedInteger: _numberOfTouchesRequired] forKey: @"NSClickGestureRecognizer.numberOfTouchesRequired"];
}

- (instancetype) initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self != nil)
    {
      NSNumber *buttonMask = [coder decodeObjectForKey: @"NSClickGestureRecognizer.buttonMask"];
      _buttonMask = buttonMask ? [buttonMask unsignedIntegerValue] : 1;

      NSNumber *clicksRequired = [coder decodeObjectForKey: @"NSClickGestureRecognizer.numberOfClicksRequired"];
      _numberOfClicksRequired = clicksRequired ? [clicksRequired unsignedIntegerValue] : 1;

      NSNumber *touchesRequired = [coder decodeObjectForKey: @"NSClickGestureRecognizer.numberOfTouchesRequired"];
      _numberOfTouchesRequired = touchesRequired ? [touchesRequired unsignedIntegerValue] : 1;
    }
  return self;
}

// NSCopying Support

- (id) copyWithZone:(NSZone *)zone
{
  NSClickGestureRecognizer *copy = [super copyWithZone: zone];
  if (copy != nil)
    {
      copy->_buttonMask = _buttonMask;
      copy->_numberOfClicksRequired = _numberOfClicksRequired;
      copy->_numberOfTouchesRequired = _numberOfTouchesRequired;
    }
  return copy;
}

// Description

- (NSString *) description
{
  return [NSString stringWithFormat: @"<%@: %p; state = %ld; buttonMask = %lu; numberOfClicksRequired = %lu; numberOfTouchesRequired = %lu>",
          [self class], self, (long)[self state], (unsigned long)_buttonMask,
          (unsigned long)_numberOfClicksRequired, (unsigned long)_numberOfTouchesRequired];
}

@end

