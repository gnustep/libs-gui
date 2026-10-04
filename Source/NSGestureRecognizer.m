/*
   NSGestureRecognizer.m

   Abstract base class for monitoring user events

   Copyright (C) 2017 Free Software Foundation, Inc.

   Author: Daniel Ferreira <dtf@stanford.edu>
   Date: 2017

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

#import <AppKit/NSGestureRecognizer.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSView.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>

@interface NSGestureRecognizer ()
- (void)_setState:(NSGestureRecognizerState)state;
- (void)_callDelegateWithSelector:(SEL)selector withObject:(id)object;
@end

@implementation NSGestureRecognizer

#pragma mark - Class Methods

+ (void)initialize
{
  if (self == [NSGestureRecognizer class])
    {
      [self setVersion: 1];
    }
}

#pragma mark - Initialization

- (instancetype)init
{
  return [self initWithTarget:nil action:NULL];
}

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
  self = [super init];
  if (self)
    {
      _target = target;
      _action = action;
      _state = NSGestureRecognizerStatePossible;
      _enabled = YES;
      _delaysPrimaryMouseButtonEvents = YES;
      _delaysSecondaryMouseButtonEvents = YES;
      _delaysOtherMouseButtonEvents = YES;
      _delaysKeyEvents = NO;
      _failureRequirements = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(_failureRequirements);
  RELEASE(_lastEvent);
  [super dealloc];
}

#pragma mark - Target-Action Management

- (void)addTarget:(id)target action:(SEL)action
{
  if (!target || !action)
    return;

  // For simplicity, this basic implementation only supports one target-action pair
  // A full implementation would maintain multiple target-action pairs
  _target = target;
  _action = action;
}

- (void)removeTarget:(id)target action:(SEL)action
{
  if (target == _target && (action == NULL || action == _action))
    {
      _target = nil;
      _action = NULL;
    }
}

#pragma mark - State Management

- (NSGestureRecognizerState)state
{
  return _state;
}

- (void)_setState:(NSGestureRecognizerState)state
{
  if (_state == state)
    return;

  NSGestureRecognizerState oldState = _state;
  _state = state;

  // Trigger action if appropriate
  if (state == NSGestureRecognizerStateRecognized && _target && _action)
    {
      [_target performSelector:_action withObject:self];
    }

  // Reset state after terminal states
  if (state == NSGestureRecognizerStateEnded ||
      state == NSGestureRecognizerStateCancelled ||
      state == NSGestureRecognizerStateFailed)
    {
      [self reset];
      _state = NSGestureRecognizerStatePossible;
    }
}

#pragma mark - Properties

- (BOOL)isEnabled
{
  return _enabled;
}

- (void)setEnabled:(BOOL)enabled
{
  if (_enabled == enabled)
    return;

  _enabled = enabled;

  if (!enabled)
    {
      [self _setState:NSGestureRecognizerStateFailed];
    }
}

- (id<NSGestureRecognizerDelegate>)delegate
{
  return _delegate;
}

- (void)setDelegate:(id<NSGestureRecognizerDelegate>)delegate
{
  _delegate = delegate;
}

- (NSView *)view
{
  return _view;
}

- (BOOL)delaysPrimaryMouseButtonEvents
{
  return _delaysPrimaryMouseButtonEvents;
}

- (void)setDelaysPrimaryMouseButtonEvents:(BOOL)delays
{
  _delaysPrimaryMouseButtonEvents = delays;
}

- (BOOL)delaysSecondaryMouseButtonEvents
{
  return _delaysSecondaryMouseButtonEvents;
}

- (void)setDelaysSecondaryMouseButtonEvents:(BOOL)delays
{
  _delaysSecondaryMouseButtonEvents = delays;
}

- (BOOL)delaysOtherMouseButtonEvents
{
  return _delaysOtherMouseButtonEvents;
}

- (void)setDelaysOtherMouseButtonEvents:(BOOL)delays
{
  _delaysOtherMouseButtonEvents = delays;
}

- (BOOL)delaysKeyEvents
{
  return _delaysKeyEvents;
}

- (void)setDelaysKeyEvents:(BOOL)delays
{
  _delaysKeyEvents = delays;
}

#pragma mark - Location and Touch Information

- (NSPoint)locationInView:(NSView *)view
{
  if (!_lastEvent)
    return NSZeroPoint;

  if (!view)
    view = _view;

  if (!view)
    return [_lastEvent locationInWindow];

  return [view convertPoint:[_lastEvent locationInWindow] fromView:nil];
}

- (NSPoint)locationOfTouch:(NSUInteger)touchIndex inView:(NSView *)view
{
  // Base implementation assumes single touch
  if (touchIndex != 0)
    return NSZeroPoint;

  return [self locationInView:view];
}

- (NSUInteger)numberOfTouches
{
  // Base implementation assumes single touch
  return _lastEvent ? 1 : 0;
}

#pragma mark - Gesture Dependencies

- (void)requireGestureRecognizerToFail:(NSGestureRecognizer *)otherGestureRecognizer
{
  if (!otherGestureRecognizer || [_failureRequirements containsObject:otherGestureRecognizer])
    return;

  [_failureRequirements addObject:otherGestureRecognizer];
}

#pragma mark - Subclass Methods

- (void)reset
{
  // Subclasses should override to reset their specific state
  ASSIGN(_lastEvent, nil);
}

- (void)ignoreEvent:(NSEvent *)event
{
  // Subclasses can override to ignore specific events
}

- (BOOL)canPreventGestureRecognizer:(NSGestureRecognizer *)preventedGestureRecognizer
{
  // Subclasses can override for custom prevention logic
  return YES;
}

- (BOOL)canBePreventedByGestureRecognizer:(NSGestureRecognizer *)preventingGestureRecognizer
{
  // Subclasses can override for custom prevention logic
  return YES;
}

#pragma mark - Event Handling

- (void)mouseDown:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);

  // Check delegate before beginning recognition
  if (_delegate && [_delegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)])
    {
      if (![_delegate gestureRecognizerShouldBegin:self])
        {
          [self _setState:NSGestureRecognizerStateFailed];
          return;
        }
    }

  if (_delegate && [_delegate respondsToSelector:@selector(gestureRecognizer:shouldAttemptToRecognizeWithEvent:)])
    {
      if (![_delegate gestureRecognizer:self shouldAttemptToRecognizeWithEvent:event])
        {
          [self _setState:NSGestureRecognizerStateFailed];
          return;
        }
    }
}

- (void)mouseDragged:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)mouseUp:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)rightMouseDown:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)rightMouseDragged:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)rightMouseUp:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)otherMouseDown:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)otherMouseDragged:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)otherMouseUp:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)keyDown:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)keyUp:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)flagsChanged:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)tabletPoint:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)magnifyWithEvent:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)rotateWithEvent:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)swipeWithEvent:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

- (void)scrollWheel:(NSEvent *)event
{
  ASSIGN(_lastEvent, event);
}

#pragma mark - Private Helper Methods

- (void)_callDelegateWithSelector:(SEL)selector withObject:(id)object
{
  if (_delegate && [_delegate respondsToSelector:selector])
    {
      [_delegate performSelector:selector withObject:self withObject:object];
    }
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if (self)
    {
      if ([coder allowsKeyedCoding])
        {
          _enabled = [coder decodeBoolForKey:@"NSEnabled"];
          _delaysPrimaryMouseButtonEvents = [coder decodeBoolForKey:@"NSDelaysPrimaryMouseButtonEvents"];
          _delaysSecondaryMouseButtonEvents = [coder decodeBoolForKey:@"NSDelaysSecondaryMouseButtonEvents"];
          _delaysOtherMouseButtonEvents = [coder decodeBoolForKey:@"NSDelaysOtherMouseButtonEvents"];
          _delaysKeyEvents = [coder decodeBoolForKey:@"NSDelaysKeyEvents"];

          if ([coder containsValueForKey:@"NSTarget"])
            _target = [coder decodeObjectForKey:@"NSTarget"];

          if ([coder containsValueForKey:@"NSAction"])
            {
              NSString *actionString = [coder decodeObjectForKey:@"NSAction"];
              _action = NSSelectorFromString(actionString);
            }
        }
      else
        {
          [coder decodeValueOfObjCType:@encode(BOOL) at:&_enabled];
          [coder decodeValueOfObjCType:@encode(BOOL) at:&_delaysPrimaryMouseButtonEvents];
          [coder decodeValueOfObjCType:@encode(BOOL) at:&_delaysSecondaryMouseButtonEvents];
          [coder decodeValueOfObjCType:@encode(BOOL) at:&_delaysOtherMouseButtonEvents];
          [coder decodeValueOfObjCType:@encode(BOOL) at:&_delaysKeyEvents];
          _target = RETAIN([coder decodeObject]);
          [coder decodeValueOfObjCType:@encode(SEL) at:&_action];
        }

      _state = NSGestureRecognizerStatePossible;
      _failureRequirements = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeBool:_enabled forKey:@"NSEnabled"];
      [coder encodeBool:_delaysPrimaryMouseButtonEvents forKey:@"NSDelaysPrimaryMouseButtonEvents"];
      [coder encodeBool:_delaysSecondaryMouseButtonEvents forKey:@"NSDelaysSecondaryMouseButtonEvents"];
      [coder encodeBool:_delaysOtherMouseButtonEvents forKey:@"NSDelaysOtherMouseButtonEvents"];
      [coder encodeBool:_delaysKeyEvents forKey:@"NSDelaysKeyEvents"];

      if (_target)
        [coder encodeObject:_target forKey:@"NSTarget"];

      if (_action)
        [coder encodeObject:NSStringFromSelector(_action) forKey:@"NSAction"];
    }
  else
    {
      [coder encodeValueOfObjCType:@encode(BOOL) at:&_enabled];
      [coder encodeValueOfObjCType:@encode(BOOL) at:&_delaysPrimaryMouseButtonEvents];
      [coder encodeValueOfObjCType:@encode(BOOL) at:&_delaysSecondaryMouseButtonEvents];
      [coder encodeValueOfObjCType:@encode(BOOL) at:&_delaysOtherMouseButtonEvents];
      [coder encodeValueOfObjCType:@encode(BOOL) at:&_delaysKeyEvents];
      [coder encodeObject:_target];
      [coder encodeValueOfObjCType:@encode(SEL) at:&_action];
    }
}

@end

