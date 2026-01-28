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
#import "AppKit/NSAccessibility.h"
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
  _action = action;
}

- (SEL) action
{
  return _action;
}

- (void) setTarget: (id)target
{
  _target = target;
}

- (id) target
{
  return _target;
}

- (void) setEnabled: (BOOL)flag
{
  _enabled = flag;
  [self setNeedsDisplay];
}

- (BOOL) isEnabled
{
  return _enabled;
}

- (void) setDoubleValue: (double)val
{
  if (val < 1.0)
    {
      [self setState: NSControlStateValueOff];
    }
  else
    {
      [self setState: NSControlStateValueOn];
    }
}

- (double) doubleValue
{
  return (double)(([self state] == NSControlStateValueOn) ? 1.0 : 0.0);
}

- (void) setFloatValue: (float)val
{
  [self setDoubleValue: (double)val];
}

- (float) floatValue
{
  return (float)[self doubleValue];
}

- (void) setIntValue: (int)val
{
  [self setDoubleValue: (double)val];
}

- (int) intValue
{
  return (int)[self doubleValue];
}

- (void) setIntegerValue: (NSInteger)val
{
  [self setDoubleValue: (double)val];
}

- (NSInteger) integerValue
{
  return (NSInteger)[self doubleValue];
}

- (void) setStringValue: (NSString *)val
{
  [self setDoubleValue: [val doubleValue]];
}

- (NSString *) stringValue
{
  return [NSString stringWithFormat: @"%ld", [self integerValue]];
}

- (void) setObjectValue: (id)obj
{
  if ([obj respondsToSelector: @selector(stringValue)])
    {
      [self setStringValue: [obj stringValue]];
    }
}

- (id) objectValue
{
  return [self stringValue];
}

- (void) drawRect: (NSRect)rect
{
  [[GSTheme theme] drawSwitchInRect: [self bounds]
                           forState: _state
                            enabled: [self isEnabled]];
}

- (void) mouseDown: (NSEvent *)event
{
  if (![self isEnabled])
    {
      [super mouseDown: event];
      return;
    }
  
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

- (void)keyDown:(NSEvent *)event
{
  if (![self isEnabled])
    {
      [super keyDown: event];
      return;
    }
  
  NSString *chars = [event charactersIgnoringModifiers];
  if ([chars length] > 0)
    {
      unichar character = [chars characterAtIndex: 0];
      
      // Handle space bar to toggle the switch (accessibility standard)
      if (character == ' ' || character == '\r' || character == '\n')
        {
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
              [self sendAction: _action to: _target];
            }
          return;
        }
    }
  
  [super keyDown: event];
}

- (BOOL)acceptsFirstResponder
{
  return [self isEnabled];
}

- (BOOL)canBecomeKeyView
{
  return [self isEnabled] && ![self isHidden];
}

// Accessibility - NSAccessibilityElement protocol methods
- (NSRect)accessibilityFrame
{
  if ([self window] != nil)
    {
      NSRect frame = [self frame];
      return [[self superview] convertRect: frame toView: nil];
    }
  return NSZeroRect;
}

- (NSString *)accessibilityIdentifier
{
  // Return a unique identifier if set, otherwise nil
  return [super accessibilityIdentifier];
}

- (id)accessibilityParent
{
  return [self superview];
}

- (BOOL)isAccessibilityFocused
{
  return [[self window] firstResponder] == self;
}

// NSAccessibilityButton protocol methods
- (NSString *)accessibilityLabel
{
  // Try to get a label from associated label control or accessibility label
  NSString *label = [super accessibilityLabel];
  if (label != nil)
    {
      return label;
    }
  
  // Fallback to a generic switch description
  return @"Switch";
}

- (BOOL)accessibilityPerformPress
{
  if (![self isEnabled])
    {
      return NO;
    }
  
  // Toggle the switch state
  if (_state == NSControlStateValueOn)
    {
      [self setState: NSControlStateValueOff];
    }
  else
    {
      [self setState: NSControlStateValueOn];
    }
  
  // Send the action
  if (_action != NULL)
    {
      [self sendAction: _action to: _target];
    }
  
  return YES;
}

// NSAccessibilitySwitch protocol methods
- (BOOL)accessibilityPerformDecrement
{
  if (![self isEnabled])
    {
      return NO;
    }
  
  // For a switch, decrement means turn off
  if (_state == NSControlStateValueOn)
    {
      [self setState: NSControlStateValueOff];
      if (_action != NULL)
        {
          [self sendAction: _action to: _target];
        }
      return YES;
    }
  
  return NO; // Already off
}

- (BOOL)accessibilityPerformIncrement
{
  if (![self isEnabled])
    {
      return NO;
    }
  
  // For a switch, increment means turn on
  if (_state == NSControlStateValueOff)
    {
      [self setState: NSControlStateValueOn];
      if (_action != NULL)
        {
          [self sendAction: _action to: _target];
        }
      return YES;
    }
  
  return NO; // Already on
}

- (NSString *)accessibilityValue
{
  // Return a localized string representing the current state
  switch (_state)
    {
      case NSControlStateValueOn:
        return @"On";
      case NSControlStateValueOff:
        return @"Off";
      case NSControlStateValueMixed:
        return @"Mixed";
      default:
        return @"Unknown";
    }
}

// Additional NSAccessibilitySwitch protocol methods
- (id)accessibilityMinValue
{
  return [NSNumber numberWithInt: 0]; // Off state
}

- (id)accessibilityMaxValue
{
  return [NSNumber numberWithInt: 1]; // On state
}

- (NSArray *)accessibilityAllowedValues
{
  NSNumber *off = [NSNumber numberWithInt: 0];
  NSNumber *on = [NSNumber numberWithInt: 1];
  return [NSArray arrayWithObjects: off, on, nil]; // Off and On
}

- (NSString *)accessibilityValueDescription
{
  return [self accessibilityValue];
}

- (void)setAccessibilityValue:(id)value
{
  if (![self isEnabled])
    {
      return;
    }
  
  if ([value isKindOfClass: [NSNumber class]])
    {
      NSNumber *numValue = (NSNumber *)value;
      if ([numValue boolValue])
        {
          [self setState: NSControlStateValueOn];
        }
      else
        {
          [self setState: NSControlStateValueOff];
        }
    }
  else if ([value isKindOfClass: [NSString class]])
    {
      NSString *strValue = [(NSString *)value lowercaseString];
      if ([strValue isEqualToString: @"on"] || [strValue isEqualToString: @"1"] || [strValue isEqualToString: @"yes"])
        {
          [self setState: NSControlStateValueOn];
        }
      else
        {
          [self setState: NSControlStateValueOff];
        }
    }
}

// Additional accessibility support methods
- (NSString *)accessibilityRole
{
  return @"AXCheckBox"; // iOS/macOS uses checkbox role for switches
}

- (NSString *)accessibilityRoleDescription
{
  return @"switch";
}

- (NSString *)accessibilityHelp
{
  NSString *help = [super accessibilityHelp];
  if (help != nil)
    {
      return help;
    }
  
  return @"Toggle switch control";
}

- (BOOL)isAccessibilityElement
{
  return YES;
}

- (BOOL)isAccessibilityEnabled
{
  return [self isEnabled];
}

- (NSString *)accessibilityTitle
{
  // Try to get title from accessibility label first, then fall back to generic
  NSString *title = [self accessibilityLabel];
  if (title != nil && [title length] > 0)
    {
      return title;
    }
  
  return @"Switch";
}

// Button-specific properties required by NSAccessibilityButton protocol
- (BOOL)isAccessibilitySelected
{
  return _state == NSControlStateValueOn;
}

- (void)setAccessibilitySelected:(BOOL)selected
{
  if (![self isEnabled])
    {
      return;
    }
  
  NSControlStateValue newState = selected ? NSControlStateValueOn : NSControlStateValueOff;
  if (newState != _state)
    {
      [self setState: newState];
      if (_action != NULL)
        {
          [self sendAction: _action to: _target];
        }
    }
}

- (NSString *)accessibilityPlaceholderValue
{
  return nil; // Switches typically don't have placeholder values
}

- (void)setAccessibilityPlaceholderValue:(NSString *)placeholderValue
{
  // Switches typically don't support placeholder values
  // This method is required by protocol but can be empty for switches
}

// NSCoding
- (id) initWithCoder: (NSCoder *)coder
{
  if ((self = [super initWithCoder: coder]) != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSControlContents"])
            {
              [self setState: [coder decodeIntegerForKey: @"NSControlContents"]];
            }
          if ([coder containsValueForKey: @"NSControlAction"])
            {
              NSString *s = [coder decodeObjectForKey: @"NSControlAction"];
              [self setAction: NSSelectorFromString(s)];
            }
          if ([coder containsValueForKey: @"NSControlTarget"])
            {
              id t = [coder decodeObjectForKey: @"NSControlTarget"];
              [self setTarget: t];
            }
          if ([coder containsValueForKey: @"NSEnabled"])
            {
              BOOL e = [coder decodeBoolForKey: @"NSEnabled"];

              // NSControl decodes this, but does not use the value which
              // is decoded.  See comment in NSControl.m initWithCoder:.
              [self setEnabled: e];
            }
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_state];
          [self setAction: NSSelectorFromString((NSString *)[coder decodeObject])];
          [self setTarget: [coder decodeObject]];
        }
    }
  
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      [coder encodeInteger: _state
                    forKey: @"NSControlContents"];
      [coder encodeObject: NSStringFromSelector(_action)
                   forKey: @"NSControlAction"];
      [coder encodeObject: _target
                   forKey: @"NSControlTarget"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(NSInteger)
                                at: &_state];
      [coder encodeObject: NSStringFromSelector([self action])];
      [coder encodeObject: [self target]];
    }
}

@end

