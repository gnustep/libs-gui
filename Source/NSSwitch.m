/* Implementation of class NSSwitch
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr  8 22:01:02 EDT 2020

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

#import "AppKit/NSSwitch.h"
#import "AppKit/NSActionCell.h"

#import "GNUstepGUI/GSTheme.h"

@implementation NSSwitch

+ (void) initialize
{
  if (self == [NSSwitch class])
    {
      [self setVersion: 1];
    }
}

- (void) setState: (NSControlStateValue)s
{
  _state = s;
  [self setNeedsDisplay];
}

- (NSControlStateValue) state
{
  return _state;
}

- (void) setAction: (SEL)action
{
  NSString *s = NSStringFromSelector(action);
  NSLog(@"Action %@",s);
  _action = action;
}

- (SEL) action
{
  return _action;
}

- (void) setTarget: (id)target
{
  NSLog(@"Target %@", target);
  _target = target;
}

- (id) target
{
  return _target;
}

- (void) drawRect: (NSRect)rect
{
  [[GSTheme theme] drawSwitchInRect: rect
                           forState: _state
                            enabled: [self isEnabled]
                       bezelOnColor: [NSColor lightGrayColor]
                      bezelOffColor: [NSColor blackColor]
                          knobColor: [NSColor darkGrayColor]];
}

- (void) mouseDown: (NSEvent *)event
{
  [super mouseDown: event];
  if (_state == NSControlStateValueOn)
    {
      [self setState: NSControlStateValueOff];
    }
  else
    {
      [self setState: NSControlStateValueOn];
    }

  if (_action)
    {
      [self sendAction: _action
                    to: _target];
    }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  if ((self = [super initWithCoder: aDecoder]) != nil)
    {
      if ([aDecoder allowsKeyedCoding])
        {
          if ([aDecoder containsValueForKey: @"NSAction"])
            {
              NSString *action = [aDecoder decodeObjectForKey: @"NSAction"];
              if (action != nil)
                {
                  [self setAction: NSSelectorFromString(action)];
                }
            }
          if ([aDecoder containsValueForKey: @"NSTarget"])
            {
              id target = [aDecoder decodeObjectForKey: @"NSTarget"];
              [self setTarget: target];
            }
        }
      else
        {
        }
    }
  
    return self;
}

@end

