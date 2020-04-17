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

- (void) drawRect: (NSRect)rect
{
  [[GSTheme theme] drawSwitchInRect: rect
                           forState: _state
                            enabled: [self isEnabled]
                         bezelColor: [NSColor blackColor]
                          knobColor: [NSColor redColor]];
}

@end

