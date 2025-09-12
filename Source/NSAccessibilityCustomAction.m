/* Implementation of class NSAccessibilityCustomAction
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Mon 15 Jun 2020 03:18:47 AM EDT

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSString.h>
#import "AppKit/NSAccessibilityCustomAction.h"

@implementation NSAccessibilityCustomAction

- (instancetype) initWithName: (NSString *)name
                      handler: (GSAccessibilityCustomActionHandler)handler
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_name, name);
      if (_handler != handler)
        {
          if (_handler != NULL) { Block_release(_handler); }
          _handler = handler ? Block_copy(handler) : NULL;
        }
    }
  return self;
}

- (instancetype) initWithName: (NSString *)name
                       target: (id)target
                     selector: (SEL)selector
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_name, name);
      _target = target;
      _selector = selector;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_name);
  if (_handler != NULL)
    {
      Block_release(_handler);
      _handler = NULL;
    }
  [super dealloc];
}

- (NSString *) name
{
  return _name;
}

- (void) setName: (NSString *)name
{
  ASSIGN(_name, name);
}

- (GSAccessibilityCustomActionHandler) handler
{
  return _handler;
}

- (void) setHandler: (GSAccessibilityCustomActionHandler)handler
{
  if (_handler != handler)
    {
      if (_handler != NULL) { Block_release(_handler); }
      _handler = handler ? Block_copy(handler) : NULL;
    }
}

- (id) target
{
  return _target;
}

- (void) setTarget: (id)target
{
  _target = target;
}

- (SEL) selector
{
  return _selector;
}

- (void) setSelector: (SEL)selector
{
  _selector = selector;
}

+ (instancetype) actionWithName: (NSString *)name
                        handler: (GSAccessibilityCustomActionHandler)handler
{
  NSAccessibilityCustomAction *a = [[self alloc] initWithName: name handler: handler];
  return AUTORELEASE(a);
}

+ (instancetype) actionWithName: (NSString *)name
                         target: (id)target
                       selector: (SEL)selector
{
  NSAccessibilityCustomAction *a = [[self alloc] initWithName: name target: target selector: selector];
  return AUTORELEASE(a);
}

- (BOOL) perform
{
  if (_handler != NULL)
    {
      _handler(YES); // Cocoa's block signature is usually BOOL(^)(void) or void(^)(id); adapt: pass YES to indicate invocation context
      return YES;
    }
  if (_target != nil && _selector != NULL && [_target respondsToSelector: _selector])
    {
      // Suppress potential leak warning for performSelector (intentional dynamic invocation)
      #pragma clang diagnostic push
      #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [_target performSelector: _selector withObject: self];
      #pragma clang diagnostic pop
      return YES;
    }
  return NO;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"<%@: %p name=%@ hasHandler=%@ target=%@ selector=%@>",
          NSStringFromClass([self class]), self, _name,
          _handler?@"YES":@"NO", _target, NSStringFromSelector(_selector)];
}

@end

