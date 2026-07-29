/** <title>NSDatePicker</title>

   <abstract>The date picker class</abstract>

   Copyright (C) 2020 Free Software Foundation, Inc.

   Author:  Nikolaus Schaller <hns@computer.org>
   Date:    April 2006

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date:   January 2020

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSDatePickerCell.h"
#import "AppKit/NSDatePicker.h"
#import "AppKit/NSEvent.h"

@interface NSDatePickerCell (Private)
- (BOOL) _handleKeyEvent: (NSEvent *)event;
- (BOOL) _selectFieldAtPoint: (NSPoint)point inRect: (NSRect)frame;
- (NSInteger) _stepperDirectionAtPoint: (NSPoint)point
                                inRect: (NSRect)frame
                                ofView: (NSView *)view;
- (BOOL) _stepSelectedFieldBy: (NSInteger)delta;
- (void) _setHighlightedStepper: (NSInteger)direction;
- (BOOL) _showsCalendar;
- (BOOL) _selectDayAtPoint: (NSPoint)point
                    inRect: (NSRect)frame
                    ofView: (NSView *)view;
@end

static id usedCellClass = nil;

@implementation NSDatePicker

+ (void) initialize
{
  if (self == [NSDatePicker class])
    {
      [self setVersion: 1];
      [self setCellClass: [NSDatePickerCell class]];
    }
}

+ (Class) cellClass
{
  return usedCellClass;
}

+ (void) setCellClass: (Class)cellClass
{
  usedCellClass = cellClass;
}

- (void) keyDown: (NSEvent *)theEvent
{
  NSDate *before = [_cell dateValue];

  if ([(NSDatePickerCell *)_cell _handleKeyEvent: theEvent])
    {
      NSDate *after = [_cell dateValue];

      [self setNeedsDisplay: YES];
      if (before == nil || ![before isEqualToDate: after])
        {
          [self sendAction: [self action] to: [self target]];
        }
      return;
    }

  [super keyDown: theEvent];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSDatePickerCell *cell = (NSDatePickerCell *)_cell;
  NSPoint point;
  NSDate *before;
  NSInteger direction;

  if (![self isEnabled])
    {
      [super mouseDown: theEvent];
      return;
    }

  point = [self convertPoint: [theEvent locationInWindow] fromView: nil];
  before = [cell dateValue];
  if ([cell _showsCalendar])
    {
      if (![cell _selectDayAtPoint: point inRect: _bounds ofView: self])
        {
          [super mouseDown: theEvent];
          return;
        }
      [[self window] makeFirstResponder: self];
      [self setNeedsDisplay: YES];
      if (before == nil || ![before isEqualToDate: [cell dateValue]])
        {
          [self sendAction: [self action] to: [self target]];
        }
      return;
    }

  direction = [cell _stepperDirectionAtPoint: point
                                      inRect: _bounds
                                      ofView: self];
  if (direction == 0 && ![cell _selectFieldAtPoint: point inRect: _bounds])
    {
      [super mouseDown: theEvent];
      return;
    }

  if ([[self window] firstResponder] != self)
    {
      [[self window] makeFirstResponder: self];
    }
  if (direction != 0)
    {
      [self _trackStepperInDirection: direction];
      return;
    }
  [self setNeedsDisplay: YES];
  if (before == nil || ![before isEqualToDate: [cell dateValue]])
    {
      [self sendAction: [self action] to: [self target]];
    }
}

/* Steps once for the click and then goes on stepping while the button is
   held.  Periodic events pace the repeat; the wait has an end so that the
   picker stops rather than running on if the mouse up never arrives.
*/
- (void) _trackStepperInDirection: (NSInteger)direction
{
  NSDatePickerCell *cell = (NSDatePickerCell *)_cell;

  [self _stepOnceInDirection: direction];
  [NSEvent startPeriodicEventsAfterDelay: 0.5 withPeriod: 0.075];
  while (YES)
    {
      NSEvent *event = [NSApp
        nextEventMatchingMask: NSLeftMouseUpMask | NSPeriodicMask
                    untilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]
                       inMode: NSEventTrackingRunLoopMode
                      dequeue: YES];

      if (event == nil || [event type] == NSLeftMouseUp)
        {
          break;
        }
      [self _stepOnceInDirection: direction];
    }
  [NSEvent stopPeriodicEvents];
  [cell _setHighlightedStepper: 0];
  [self setNeedsDisplay: YES];
}

- (void) _stepOnceInDirection: (NSInteger)direction
{
  NSDatePickerCell *cell = (NSDatePickerCell *)_cell;
  NSDate *before = [cell dateValue];

  [cell _setHighlightedStepper: direction];
  if (![cell _stepSelectedFieldBy: direction])
    {
      return;
    }
  [self setNeedsDisplay: YES];
  [self displayIfNeeded];
  if (before == nil || ![before isEqualToDate: [cell dateValue]])
    {
      [self sendAction: [self action] to: [self target]];
    }
}

- (BOOL) becomeFirstResponder
{
  [self setNeedsDisplay: YES];
  return YES;
}

- (BOOL) resignFirstResponder
{
  [self setNeedsDisplay: YES];
  return YES;
}

- (NSColor *) backgroundColor
{
  return [_cell backgroundColor];
}

- (NSCalendar *) calendar
{
  return [_cell calendar];
}

- (NSDatePickerElementFlags) datePickerElements
{
  return [_cell datePickerElements];
}

- (NSDatePickerMode) datePickerMode
{
  return [_cell datePickerMode];
}

- (NSDatePickerStyle) datePickerStyle
{
  return [_cell datePickerStyle];
}

- (NSDate *) dateValue
{
  return [_cell dateValue];
}

- (id) delegate
{
  return [_cell delegate];
}

- (BOOL) drawsBackground
{
  return [_cell drawsBackground];
}

- (BOOL) isBezeled
{
  return [_cell isBezeled];
}

- (BOOL) isBordered
{
  return [_cell isBordered];
}

- (NSLocale *) locale
{
  return [_cell locale];
}

- (NSDate *) maxDate
{
  return [_cell maxDate];
}

- (NSDate *) minDate
{
  return [_cell minDate];
}

- (void) setBackgroundColor: (NSColor *)color
{
  [_cell setBackgroundColor: color];
}

- (void) setBezeled: (BOOL)flag
{
  [_cell setBezeled: flag];
}

- (void) setBordered: (BOOL)flag
{
  [_cell setBordered: flag];
}

- (void) setCalendar: (NSCalendar *)calendar
{
  [_cell setCalendar: calendar];
}

- (void) setDatePickerElements: (NSDatePickerElementFlags)flags
{
  [_cell setDatePickerElements: flags];
}

- (void) setDatePickerMode: (NSDatePickerMode)mode
{
  [_cell setDatePickerMode: mode];
}

- (void) setDatePickerStyle: (NSDatePickerStyle)style
{
  [_cell setDatePickerStyle: style];
}

- (void) setDateValue: (NSDate *)date
{
  [_cell setDateValue: date];
}

- (void) setDelegate: (id)obj
{
  [_cell setDelegate: obj];
}

- (void) setDrawsBackground: (BOOL)flag
{
  [_cell setDrawsBackground: flag];
}

- (void) setLocale: (NSLocale *)locale
{
  [_cell setLocale: locale];
}

- (void) setMaxDate: (NSDate *)date
{
  [_cell setMaxDate: date];
}

- (void) setMinDate: (NSDate *)date
{
  [_cell setMinDate: date];
}

- (void) setTextColor: (NSColor *)color
{
  [_cell setTextColor: color];
}

- (void) setTimeInterval: (NSTimeInterval)interval
{
  [_cell setTimeInterval: interval];
}

- (void) setTimeZone: (NSTimeZone *)zone
{
  [_cell setTimeZone: zone];
}

- (NSColor *) textColor
{
  return [_cell textColor];
}

- (NSTimeInterval) timeInterval
{
  return [_cell timeInterval];
}

- (NSTimeZone *) timeZone
{
  return [_cell timeZone];
}

@end
