/** <title>NSStepper</title>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: August 2001

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include "config.h"

#import "AppKit/NSStepper.h"
#import "AppKit/NSEvent.h"
#import "AppKit/NSStepperCell.h"
#import "AppKit/NSAccessibility.h"
#import "AppKit/NSAccessibilityProtocols.h"

//
// class variables
//
id _nsstepperCellClass = nil;

@implementation NSStepper

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSStepper class])
    {
      [self setVersion: 1];
      [self setCellClass: [NSStepperCell class]];
    }
}

//
// Initializing the NSStepper Factory
//
+ (Class) cellClass
{
  return _nsstepperCellClass;
}

+ (void) setCellClass: (Class)classId
{
  _nsstepperCellClass = classId;
}

//
// Instance methods
//

//
// Determining the first responder
//
- (BOOL) becomeFirstResponder
{
  [_cell setShowsFirstResponder: YES];
  [self setNeedsDisplay: YES];

  return YES;
}

- (BOOL) resignFirstResponder
{
  [_cell setShowsFirstResponder: NO];
  [self setNeedsDisplay: YES];

  return YES;
}

- (BOOL)acceptsFirstResponder
{
  // FIXME: change to `YES` after `keyDown:` implementation.
  return NO;
}

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

- (void) keyDown: (NSEvent*)theEvent
{
  // FIXME
  [super keyDown: theEvent];
}

- (double) maxValue
{
  return [_cell maxValue];
}

- (void) setMaxValue: (double)maxValue
{
  [_cell setMaxValue: maxValue];
}

- (double) minValue
{
  return [_cell minValue];
}

- (void) setMinValue: (double)minValue
{
  [_cell setMinValue: minValue];
}

- (double) increment
{
  return [_cell increment];
}

- (void) setIncrement: (double)increment
{
  [_cell setIncrement: increment];
}

- (BOOL)autorepeat
{
  return [_cell autorepeat];
}

- (void)setAutorepeat: (BOOL)autorepeat
{
  [_cell setAutorepeat: autorepeat];
}

- (BOOL)valueWraps
{
  return [_cell valueWraps];
}

- (void)setValueWraps: (BOOL)valueWraps
{
  [_cell setValueWraps: valueWraps];
}

@end
// MARK: - NSStepper (NSAccessibilityStepper)

@implementation NSStepper (NSAccessibilityStepper)

// MARK: - NSAccessibilityElement Protocol Implementation

- (NSString *) accessibilityRole
{
  return NSAccessibilityIncrementorRole;
}

- (NSString *) accessibilitySubrole
{
  return nil;
}

- (NSString *) accessibilityLabel
{
  return nil; // Steppers typically get their labels from associated labels
}

- (NSString *) accessibilityTitle
{
  return nil; // Steppers typically don't have titles
}

- (NSString *) accessibilityHelp
{
  NSString *toolTip = [self toolTip];
  if (toolTip && [toolTip length] > 0)
    {
      return toolTip;
    }
  
  return nil;
}

- (BOOL) isAccessibilityEnabled
{
  return [self isEnabled];
}

- (NSArray *) accessibilityChildren
{
  return nil; // Steppers are leaf elements
}

- (NSArray *) accessibilitySelectedChildren
{
  return nil;
}

- (NSArray *) accessibilityVisibleChildren
{
  return nil;
}

- (id) accessibilityWindow
{
  return [self window];
}

- (id) accessibilityTopLevelUIElement
{
  NSWindow *window = [self window];
  return window ? [window contentView] : nil;
}

- (NSPoint) accessibilityActivationPoint
{
  NSRect frame = [self frame];
  if ([self window] != nil)
    {
      frame = [[self superview] convertRect: frame toView: nil];
    }
  
  if (NSEqualRects(frame, NSZeroRect))
    {
      return NSZeroPoint;
    }
  
  return NSMakePoint(NSMidX(frame), NSMidY(frame));
}

- (NSString *) accessibilityURL
{
  return nil;
}

- (NSNumber *) accessibilityIndex
{
  id parent = [self superview];
  if (parent && [parent respondsToSelector: @selector(subviews)])
    {
      NSArray *siblings = [parent subviews];
      NSUInteger index = [siblings indexOfObject: self];
      if (index != NSNotFound)
        {
          return [NSNumber numberWithUnsignedInteger: index];
        }
    }
  return [NSNumber numberWithInteger: 0];
}

// MARK: - NSAccessibilityStepper Protocol Implementation

- (NSNumber *) accessibilityValue
{
  return [NSNumber numberWithDouble: [self doubleValue]];
}

- (void) setAccessibilityValue: (id) value
{
  if ([value respondsToSelector: @selector(doubleValue)])
    {
      double newValue = [value doubleValue];
      double minValue = [self minValue];
      double maxValue = [self maxValue];
      
      // Clamp the value to the stepper's range
      if (newValue < minValue)
        {
          if ([self valueWraps])
            {
              newValue = maxValue;
            }
          else
            {
              newValue = minValue;
            }
        }
      else if (newValue > maxValue)
        {
          if ([self valueWraps])
            {
              newValue = minValue;
            }
          else
            {
              newValue = maxValue;
            }
        }
      
      [self setDoubleValue: newValue];
      [self sendAction: [self action] to: [self target]];
    }
}

- (NSNumber *) accessibilityMinValue
{
  return [NSNumber numberWithDouble: [self minValue]];
}

- (NSNumber *) accessibilityMaxValue
{
  return [NSNumber numberWithDouble: [self maxValue]];
}

- (NSString *) accessibilityValueDescription
{
  return [NSString stringWithFormat: @"%.2f", [self doubleValue]];
}

- (BOOL) accessibilityPerformIncrement
{
  if ([self isEnabled])
    {
      double currentValue = [self doubleValue];
      double maxValue = [self maxValue];
      double increment = [self increment];
      
      if (currentValue < maxValue)
        {
          double newValue = currentValue + increment;
          if (newValue > maxValue)
            {
              if ([self valueWraps])
                {
                  newValue = [self minValue];
                }
              else
                {
                  newValue = maxValue;
                }
            }
          
          [self setDoubleValue: newValue];
          [self sendAction: [self action] to: [self target]];
          return YES;
        }
      else if ([self valueWraps])
        {
          [self setDoubleValue: [self minValue]];
          [self sendAction: [self action] to: [self target]];
          return YES;
        }
    }
  
  return NO;
}

- (BOOL) accessibilityPerformDecrement
{
  if ([self isEnabled])
    {
      double currentValue = [self doubleValue];
      double minValue = [self minValue];
      double decrement = [self increment];
      
      if (currentValue > minValue)
        {
          double newValue = currentValue - decrement;
          if (newValue < minValue)
            {
              if ([self valueWraps])
                {
                  newValue = [self maxValue];
                }
              else
                {
                  newValue = minValue;
                }
            }
          
          [self setDoubleValue: newValue];
          [self sendAction: [self action] to: [self target]];
          return YES;
        }
      else if ([self valueWraps])
        {
          [self setDoubleValue: [self maxValue]];
          [self sendAction: [self action] to: [self target]];
          return YES;
        }
    }
  
  return NO;
}

- (id) accessibilityIncrementButton
{
  // For simple steppers, return self as the increment button
  return self;
}

- (id) accessibilityDecrementButton
{
  // For simple steppers, return self as the decrement button  
  return self;
}

// MARK: - Additional Methods

- (NSArray *) accessibilityCustomRotors
{
  return nil;
}

- (BOOL) accessibilityPerformEscape
{
  return NO;
}

- (NSArray *) accessibilityCustomActions
{
  return nil;
}

- (void) setAccessibilityElement: (BOOL) isElement
{
  // Steppers are always accessibility elements
}

- (void) setAccessibilityFrame: (NSRect) frame
{
  // Frame is determined by the actual view frame
}

- (void) setAccessibilityParent: (id) parent
{
  // Parent relationship is managed by the view hierarchy
}

- (void) setAccessibilityFocused: (BOOL) focused
{
  if (focused)
    {
      [[self window] makeFirstResponder: self];
    }
  else
    {
      if ([[self window] firstResponder] == self)
        {
          [[self window] makeFirstResponder: nil];
        }
    }
}

@end