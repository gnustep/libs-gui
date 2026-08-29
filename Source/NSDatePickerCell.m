/** <title>NSDatePickerCell</title>

   <abstract>The date picker cell class</abstract>

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

#import <Foundation/NSArray.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>

#import "AppKit/NSAttributedString.h"
#import "AppKit/NSBezierPath.h"
#import "AppKit/NSDatePickerCell.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSEvent.h"
#import "AppKit/NSFont.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSStringDrawing.h"
#import "AppKit/NSWindow.h"
#import "GNUstepGUI/GSTheme.h"

@interface NSDatePickerCell (Private)
- (void) _updateDateFormat;
- (NSArray *) _editableFields;
- (NSCalendar *) _pickerCalendar;
- (NSRange) _rangeOfFieldAtIndex: (NSInteger)wanted
                        inString: (NSString *)text;
- (void) _setSelectedFieldIndex: (NSInteger)index;
@end

@implementation NSDatePickerCell

- (void) dealloc
{
  RELEASE(_backgroundColor);
  RELEASE(_textColor);
  RELEASE(_maxDate);
  RELEASE(_minDate);
  DEALLOC
}

- (id) initTextCell: (NSString*)aString
{
  if ((self = [super  initTextCell: aString]))
    {
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

      [self setFormatter: formatter];
      RELEASE(formatter);
      [self setTextColor: [NSColor controlTextColor]];
      [self setBackgroundColor: [NSColor controlBackgroundColor]];
      [self setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: 0.0]];
      [self setBezeled: YES];
      _datePickerElements = NSYearMonthDayDatePickerElementFlag
        | NSHourMinuteSecondDatePickerElementFlag;
      [self _updateDateFormat];
    }

  return self;
}

/* The template holds one letter per element the picker shows.  The pattern
   generator turns it into the pattern the locale writes those elements in.
   'j' stands for the hour in the clock the locale uses, twelve or twenty
   four.
*/
- (NSString *) _dateFormatTemplate
{
  NSMutableString *template = [NSMutableString stringWithCapacity: 8];
  NSDatePickerElementFlags elements = _datePickerElements;

  if (elements & NSYearMonthDatePickerElementFlag)
    {
      [template appendString: @"yM"];
    }
  if ((elements & NSYearMonthDayDatePickerElementFlag)
    == NSYearMonthDayDatePickerElementFlag)
    {
      [template appendString: @"d"];
    }
  if (elements & NSHourMinuteDatePickerElementFlag)
    {
      [template appendString: @"jm"];
    }
  if ((elements & NSHourMinuteSecondDatePickerElementFlag)
    == NSHourMinuteSecondDatePickerElementFlag)
    {
      [template appendString: @"s"];
    }
  if (elements & NSTimeZoneDatePickerElementFlag)
    {
      [template appendString: @"z"];
    }

  return template;
}

/* Used when the pattern generator is unavailable, which is the case in a
   build without ICU.
*/
- (NSString *) _fallbackDateFormat
{
  NSMutableString *format = [NSMutableString stringWithCapacity: 24];
  NSDatePickerElementFlags elements = _datePickerElements;

  if (elements & NSYearMonthDatePickerElementFlag)
    {
      [format appendString: @"y-MM"];
      if ((elements & NSYearMonthDayDatePickerElementFlag)
        == NSYearMonthDayDatePickerElementFlag)
        {
          [format appendString: @"-dd"];
        }
    }
  if (elements & NSHourMinuteDatePickerElementFlag)
    {
      if ([format length] > 0)
        {
          [format appendString: @" "];
        }
      [format appendString: @"HH:mm"];
      if ((elements & NSHourMinuteSecondDatePickerElementFlag)
        == NSHourMinuteSecondDatePickerElementFlag)
        {
          [format appendString: @":ss"];
        }
    }
  if (elements & NSTimeZoneDatePickerElementFlag)
    {
      [format appendString: @" zzz"];
    }

  return format;
}

- (void) _updateDateFormat
{
  NSDateFormatter *formatter = (NSDateFormatter *)[self formatter];
  NSString *template;
  NSString *format = nil;

  if (![formatter isKindOfClass: [NSDateFormatter class]])
    {
      return;
    }

  template = [self _dateFormatTemplate];
  if ([template length] > 0)
    {
      format = [NSDateFormatter dateFormatFromTemplate: template
                                               options: 0
                                                locale: [formatter locale]];
      if (format == nil)
        {
          format = [self _fallbackDateFormat];
        }
    }
  [formatter setDateFormat: (format == nil) ? (NSString *)@"" : format];
  _selectedField = 0;
  _typedValue = 0;
  _typedDigits = 0;
}

/* Every run of one pattern letter is a field.  Only the runs standing for a
   part of the date the user can change are returned, in the order the
   pattern writes them.  Text between quotes is a literal, not a field.
*/
- (NSArray *) _editableFields
{
  NSDateFormatter *formatter = (NSDateFormatter *)[self formatter];
  NSString *pattern;
  NSMutableArray *fields;
  NSUInteger index;
  NSUInteger length;
  BOOL quoted = NO;

  if (![formatter isKindOfClass: [NSDateFormatter class]])
    {
      return [NSArray array];
    }

  pattern = [formatter dateFormat];
  length = [pattern length];
  fields = [NSMutableArray arrayWithCapacity: 8];
  for (index = 0; index < length; index++)
    {
      unichar c = [pattern characterAtIndex: index];
      NSUInteger run = index;

      if (c == '\'')
        {
          quoted = !quoted;
          continue;
        }
      if (quoted)
        {
          continue;
        }
      if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')))
        {
          continue;
        }
      while (index + 1 < length && [pattern characterAtIndex: index + 1] == c)
        {
          index++;
        }
      switch (c)
        {
          case 'y': case 'Y': case 'u':
          case 'M': case 'L':
          case 'd':
          case 'h': case 'H': case 'k': case 'K':
          case 'm':
          case 's':
          case 'a': case 'b': case 'B':
            [fields addObject: [pattern substringWithRange:
              NSMakeRange(run, index - run + 1)]];
            break;
          default:
            break;
        }
    }

  return fields;
}

/* The calendar the picker counts in.  It has to hold the time zone of the
   picker, or a day added to a date lands at the wrong hour.
*/
- (NSCalendar *) _pickerCalendar
{
  NSCalendar *calendar = [self calendar];
  NSTimeZone *zone = [self timeZone];

  if (calendar == nil)
    {
      calendar = [NSCalendar currentCalendar];
    }
  calendar = AUTORELEASE([calendar copy]);
  if (zone != nil)
    {
      [calendar setTimeZone: zone];
    }
  if ([self locale] != nil)
    {
      [calendar setLocale: [self locale]];
    }

  return calendar;
}

- (NSCalendarUnit) _unitOfField: (NSString *)field
{
  switch ([field characterAtIndex: 0])
    {
      case 'y': case 'Y': case 'u': return NSCalendarUnitYear;
      case 'M': case 'L':           return NSCalendarUnitMonth;
      case 'd':                     return NSCalendarUnitDay;
      case 'h': case 'H':
      case 'k': case 'K':           return NSCalendarUnitHour;
      case 'm':                     return NSCalendarUnitMinute;
      case 's':                     return NSCalendarUnitSecond;
      default:                      return 0;
    }
}

- (NSInteger) _selectedFieldIndex
{
  NSInteger count = (NSInteger)[[self _editableFields] count];

  if (count == 0)
    {
      return -1;
    }
  if (_selectedField < 0 || _selectedField >= count)
    {
      return 0;
    }

  return _selectedField;
}

- (void) _setSelectedFieldIndex: (NSInteger)index
{
  NSInteger count = (NSInteger)[[self _editableFields] count];

  if (count > 0)
    {
      while (index < 0)
        {
          index += count;
        }
      _selectedField = index % count;
    }
  _typedValue = 0;
  _typedDigits = 0;
}

/* The range the field covers in the text the cell shows.  The fields are
   looked for in the order they are written, so a number that appears twice
   is still found in its own place.
*/
- (NSRange) _rangeOfFieldAtIndex: (NSInteger)wanted
                        inString: (NSString *)text
{
  NSDateFormatter *formatter = (NSDateFormatter *)[self formatter];
  NSArray *fields = [self _editableFields];
  NSDateFormatter *scratch;
  NSRange found = NSMakeRange(NSNotFound, 0);
  NSUInteger from = 0;
  NSUInteger index;
  NSDate *date = [self dateValue];

  if (date == nil || wanted < 0 || wanted >= (NSInteger)[fields count])
    {
      return found;
    }

  scratch = AUTORELEASE([[NSDateFormatter alloc] init]);
  [scratch setLocale: [formatter locale]];
  [scratch setTimeZone: [formatter timeZone]];
  [scratch setCalendar: [formatter calendar]];

  for (index = 0; index <= (NSUInteger)wanted; index++)
    {
      NSString *part;
      NSRange rest = NSMakeRange(from, [text length] - from);

      [scratch setDateFormat: [fields objectAtIndex: index]];
      part = [scratch stringFromDate: date];
      if ([part length] == 0)
        {
          return NSMakeRange(NSNotFound, 0);
        }
      found = [text rangeOfString: part options: 0 range: rest];
      if (found.location == NSNotFound)
        {
          return found;
        }
      from = NSMaxRange(found);
    }

  return found;
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGN(_backgroundColor, color);
}

- (NSCalendar *) calendar
{
  return [[self formatter] calendar];
}

- (void) setCalendar: (NSCalendar *)calendar
{
  [[self formatter] setCalendar: calendar];
}

- (NSDatePickerElementFlags) datePickerElements
{
  return _datePickerElements;
}

- (void) setDatePickerElements: (NSDatePickerElementFlags)flags
{
  /* AppKit keeps the low eight bits, which leaves the era out. */
  _datePickerElements = flags & 0xff;
  [self _updateDateFormat];
}

- (NSDatePickerMode) datePickerMode
{
  return _datePickerMode;
}

- (void) setDatePickerMode: (NSDatePickerMode)mode
{
  _datePickerMode = mode;
}

- (NSDatePickerStyle) datePickerStyle
{
  return _datePickerStyle;
}

- (void) setDatePickerStyle: (NSDatePickerStyle)style
{
  _datePickerStyle = style;
}

- (NSDate *) dateValue
{
  return (NSDate *)[self objectValue];
}

- (NSDate *) _clampedDate: (NSDate *)date
{
  if (date == nil)
    {
      return date;
    }
  if (_minDate != nil && [date compare: _minDate] == NSOrderedAscending)
    {
      return _minDate;
    }
  if (_maxDate != nil && [date compare: _maxDate] == NSOrderedDescending)
    {
      return _maxDate;
    }
  return date;
}

- (void) setDateValue: (NSDate *)date
{
  NSDate *proposed = [self _clampedDate: date];

  if (proposed != nil && [_delegate respondsToSelector:
    @selector(datePickerCell:validateProposedDateValue:timeInterval:)])
    {
      NSTimeInterval interval = _timeInterval;

      [_delegate datePickerCell: self
      validateProposedDateValue: &proposed
                   timeInterval: &interval];
      _timeInterval = interval;
    }
  [self setObjectValue: proposed];
}

/* One step of the field the user is on.  The step is a step of the calendar,
   so it carries into the fields above it, and the day of a month that is too
   short for it moves back to the last day of that month.
*/
- (BOOL) _stepSelectedFieldBy: (NSInteger)delta
{
  NSArray *fields = [self _editableFields];
  NSInteger index = [self _selectedFieldIndex];
  NSCalendar *calendar = [self _pickerCalendar];
  NSDate *date = [self dateValue];
  NSDateComponents *step;
  NSCalendarUnit unit;
  NSDate *stepped;

  if (date == nil || index < 0)
    {
      return NO;
    }

  step = AUTORELEASE([[NSDateComponents alloc] init]);
  unit = [self _unitOfField: [fields objectAtIndex: index]];
  switch (unit)
    {
      case NSCalendarUnitYear:   [step setYear: delta];   break;
      case NSCalendarUnitMonth:  [step setMonth: delta];  break;
      case NSCalendarUnitDay:    [step setDay: delta];    break;
      case NSCalendarUnitHour:   [step setHour: delta];   break;
      case NSCalendarUnitMinute: [step setMinute: delta]; break;
      case NSCalendarUnitSecond: [step setSecond: delta]; break;
      default:
        {
          /* The morning and afternoon marker has one other state. */
          NSDateComponents *now = [calendar components: NSCalendarUnitHour
                                              fromDate: date];

          [step setHour: ([now hour] < 12) ? 12 : -12];
        }
        break;
    }

  stepped = [calendar dateByAddingComponents: step toDate: date options: 0];
  if (stepped == nil)
    {
      return NO;
    }
  _typedValue = 0;
  _typedDigits = 0;
  [self setDateValue: stepped];

  return YES;
}

/* How large the number in a field can grow, so that a digit that cannot be
   the first of a larger number is taken on its own.
*/
- (NSInteger) _highestValueOfField: (NSString *)field
{
  NSCalendar *calendar = [self _pickerCalendar];
  NSDate *date = [self dateValue];

  switch ([self _unitOfField: field])
    {
      case NSCalendarUnitYear:
        return 9999;
      case NSCalendarUnitMonth:
        return [calendar rangeOfUnit: NSCalendarUnitMonth
                              inUnit: NSCalendarUnitYear
                             forDate: date].length;
      case NSCalendarUnitDay:
        return NSMaxRange([calendar rangeOfUnit: NSCalendarUnitDay
                                         inUnit: NSCalendarUnitMonth
                                        forDate: date]) - 1;
      case NSCalendarUnitHour:
        return ([field characterAtIndex: 0] == 'h'
          || [field characterAtIndex: 0] == 'K') ? 12 : 23;
      case NSCalendarUnitMinute:
      case NSCalendarUnitSecond:
        return 59;
      default:
        return 0;
    }
}

- (BOOL) _setSelectedFieldToValue: (NSInteger)value
{
  NSArray *fields = [self _editableFields];
  NSInteger index = [self _selectedFieldIndex];
  NSCalendar *calendar = [self _pickerCalendar];
  NSDate *date = [self dateValue];
  NSString *field;
  NSDateComponents *parts;
  NSDate *edited;
  NSUInteger units = NSCalendarUnitEra | NSCalendarUnitYear
    | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour
    | NSCalendarUnitMinute | NSCalendarUnitSecond;

  if (date == nil || index < 0)
    {
      return NO;
    }

  field = [fields objectAtIndex: index];
  parts = [calendar components: units fromDate: date];
  switch ([self _unitOfField: field])
    {
      case NSCalendarUnitYear:
        [parts setYear: value];
        break;
      case NSCalendarUnitMonth:
        [parts setMonth: value];
        break;
      case NSCalendarUnitDay:
        [parts setDay: value];
        break;
      case NSCalendarUnitHour:
        if ([field characterAtIndex: 0] == 'h'
          || [field characterAtIndex: 0] == 'K')
          {
            /* A twelve hour field keeps the half of the day it is in. */
            [parts setHour: (value % 12) + (([parts hour] < 12) ? 0 : 12)];
          }
        else
          {
            [parts setHour: value];
          }
        break;
      case NSCalendarUnitMinute:
        [parts setMinute: value];
        break;
      case NSCalendarUnitSecond:
        [parts setSecond: value];
        break;
      default:
        return NO;
    }

  edited = [calendar dateFromComponents: parts];
  if (edited == nil)
    {
      return NO;
    }
  [self setDateValue: edited];

  return YES;
}

/* A digit joins the digits already typed into the same field while the
   number they make can still grow.  Once it cannot, the field takes it.
*/
- (BOOL) _typeDigit: (NSInteger)digit
{
  NSArray *fields = [self _editableFields];
  NSInteger index = [self _selectedFieldIndex];
  NSInteger highest;
  NSInteger value;

  if (index < 0)
    {
      return NO;
    }

  highest = [self _highestValueOfField: [fields objectAtIndex: index]];
  if (highest == 0)
    {
      return NO;
    }

  value = (_typedDigits > 0) ? (_typedValue * 10 + digit) : digit;
  if (value > highest)
    {
      value = digit;
    }
  _typedValue = value;
  _typedDigits++;

  if (value == 0 || value * 10 <= highest)
    {
      /* Another digit could still follow, so wait for it. */
      return YES;
    }

  _typedValue = 0;
  _typedDigits = 0;

  return [self _setSelectedFieldToValue: value];
}

- (BOOL) _hasMeridiemField
{
  NSEnumerator *fields = [[self _editableFields] objectEnumerator];
  NSString *field;

  while ((field = [fields nextObject]) != nil)
    {
      if ([self _unitOfField: field] == 0)
        {
          return YES;
        }
    }

  return NO;
}

- (BOOL) _setMeridiemAfterNoon: (BOOL)afternoon
{
  NSCalendar *calendar = [self _pickerCalendar];
  NSDate *date = [self dateValue];
  NSDateComponents *now;
  NSDateComponents *step;
  NSDate *edited;

  if (date == nil)
    {
      return NO;
    }
  now = [calendar components: NSCalendarUnitHour fromDate: date];
  if (([now hour] >= 12) == afternoon)
    {
      return YES;
    }

  step = AUTORELEASE([[NSDateComponents alloc] init]);
  [step setHour: afternoon ? 12 : -12];
  edited = [calendar dateByAddingComponents: step toDate: date options: 0];
  if (edited == nil)
    {
      return NO;
    }
  [self setDateValue: edited];

  return YES;
}

/* The clock and calendar style draws a month of days, a clock, or both,
   depending on the elements it is asked for.
*/
- (BOOL) _showsCalendar
{
  return (_datePickerStyle == NSClockAndCalendarDatePickerStyle
    && (_datePickerElements & NSYearMonthDatePickerElementFlag) != 0);
}

- (BOOL) _showsClock
{
  return (_datePickerStyle == NSClockAndCalendarDatePickerStyle
    && (_datePickerElements & NSHourMinuteDatePickerElementFlag) != 0);
}

- (NSFont *) _drawingFont
{
  NSFont *font = [self font];

  return (font == nil) ? [NSFont userFontOfSize: 0.0] : font;
}

- (NSDictionary *) _dayAttributes
{
  NSColor *color = [self textColor];

  if (color == nil)
    {
      color = [NSColor controlTextColor];
    }

  return [NSDictionary dictionaryWithObjectsAndKeys:
    [self _drawingFont], NSFontAttributeName,
    color, NSForegroundColorAttributeName,
    nil];
}

/* One row of the month, and one column of it.  Wide enough for two digits
   and for the initial of a weekday.
*/
- (NSSize) _dayCellSize
{
  NSFont *font = [self _drawingFont];
  NSSize size = [@"88" sizeWithAttributes:
    [NSDictionary dictionaryWithObject: font forKey: NSFontAttributeName]];

  size.width = ceil(size.width) + 8.0;
  size.height = ceil([font boundingRectForFont].size.height) + 2.0;

  return size;
}

/* The month takes a row for its name, a row for the initials of the
   weekdays and six rows of days.
*/
- (NSSize) _calendarSize
{
  NSSize day = [self _dayCellSize];

  return NSMakeSize(day.width * 7.0, day.height * 8.0);
}

- (NSRect) _calendarFrameForFrame: (NSRect)frame
{
  NSRect calendar = frame;

  if ([self _showsClock])
    {
      calendar.size.width = [self _calendarSize].width;
    }

  return calendar;
}

- (NSRect) _clockFrameForFrame: (NSRect)frame
{
  NSRect clock = frame;

  if ([self _showsCalendar])
    {
      CGFloat used = [self _calendarSize].width;

      clock.origin.x += used;
      clock.size.width -= used;
    }

  return clock;
}

/* Where a day of the month sits in the grid.  Row zero is the first week
   under the initials of the weekdays.
*/
- (NSRect) _dayCellRectAtRow: (NSInteger)row
                      column: (NSInteger)column
                     inFrame: (NSRect)frame
                      ofView: (NSView *)view
{
  NSRect calendar = [self _calendarFrameForFrame: frame];
  NSSize day = [self _dayCellSize];
  NSRect cell;

  cell.size = day;
  cell.origin.x = NSMinX(calendar) + column * day.width;
  if ([view isFlipped])
    {
      cell.origin.y = NSMinY(calendar) + (row + 2) * day.height;
    }
  else
    {
      cell.origin.y = NSMaxY(calendar) - (row + 3) * day.height;
    }

  return cell;
}

/* The day of the month in a cell of the grid, or zero when the cell falls
   outside the month.
*/
- (NSInteger) _dayAtRow: (NSInteger)row column: (NSInteger)column
{
  NSCalendar *calendar = [self _pickerCalendar];
  NSDate *date = [self dateValue];
  NSDateComponents *parts;
  NSDate *first;
  NSInteger lead;
  NSInteger day;
  NSInteger length;

  if (date == nil)
    {
      return 0;
    }

  parts = [calendar components: NSCalendarUnitEra | NSCalendarUnitYear
    | NSCalendarUnitMonth fromDate: date];
  [parts setDay: 1];
  first = [calendar dateFromComponents: parts];
  if (first == nil)
    {
      return 0;
    }

  lead = [[calendar components: NSCalendarUnitWeekday fromDate: first] weekday]
    - (NSInteger)[calendar firstWeekday];
  while (lead < 0)
    {
      lead += 7;
    }
  length = [calendar rangeOfUnit: NSCalendarUnitDay
                          inUnit: NSCalendarUnitMonth
                         forDate: date].length;
  day = row * 7 + column - lead + 1;
  if (day < 1 || day > length)
    {
      return 0;
    }

  return day;
}

- (NSString *) _monthTitle
{
  NSDateFormatter *formatter = (NSDateFormatter *)[self formatter];
  NSDateFormatter *scratch = AUTORELEASE([[NSDateFormatter alloc] init]);
  NSString *pattern;

  if (![formatter isKindOfClass: [NSDateFormatter class]]
    || [self dateValue] == nil)
    {
      return @"";
    }

  [scratch setLocale: [formatter locale]];
  [scratch setTimeZone: [formatter timeZone]];
  [scratch setCalendar: [formatter calendar]];
  pattern = [NSDateFormatter dateFormatFromTemplate: @"yMMMM"
                                            options: 0
                                             locale: [formatter locale]];
  [scratch setDateFormat: (pattern == nil) ? (NSString *)@"MMMM y" : pattern];

  return [scratch stringFromDate: [self dateValue]];
}

- (NSArray *) _weekdayInitials
{
  NSDateFormatter *formatter = (NSDateFormatter *)[self formatter];
  NSArray *symbols = nil;

  if ([formatter isKindOfClass: [NSDateFormatter class]])
    {
      symbols = [formatter veryShortWeekdaySymbols];
      if ([symbols count] != 7)
        {
          symbols = [formatter shortWeekdaySymbols];
        }
    }
  if ([symbols count] != 7)
    {
      symbols = [NSArray arrayWithObjects: @"S", @"M", @"T", @"W", @"T",
        @"F", @"S", nil];
    }

  return symbols;
}

/* Whether a day of the month on show is part of what the picker holds: the
   one day it is set to, or, in the mode that picks a range, any day the
   range covers.
*/
- (BOOL) _dayIsPicked: (NSInteger)day
{
  NSCalendar *calendar = [self _pickerCalendar];
  NSDate *start = [self dateValue];
  NSDateComponents *parts;
  NSDate *dayStart;
  NSDate *dayEnd;
  NSDate *end;

  if (start == nil)
    {
      return NO;
    }

  parts = [calendar components: NSCalendarUnitEra | NSCalendarUnitYear
    | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: start];
  if (_datePickerMode != NSRangeDateMode || _timeInterval <= 0.0)
    {
      return (day == [parts day]);
    }

  [parts setDay: day];
  dayStart = [calendar dateFromComponents: parts];
  if (dayStart == nil)
    {
      return NO;
    }
  [parts setDay: day + 1];
  dayEnd = [calendar dateFromComponents: parts];
  end = [start dateByAddingTimeInterval: _timeInterval];

  return ([dayStart compare: end] != NSOrderedDescending
    && (dayEnd == nil || [dayEnd compare: start] == NSOrderedDescending));
}

static void
drawCentred(NSString *text, NSRect rect, NSDictionary *attributes)
{
  NSSize size = [text sizeWithAttributes: attributes];
  NSPoint at;

  at.x = NSMinX(rect) + (NSWidth(rect) - size.width) / 2.0;
  at.y = NSMinY(rect) + (NSHeight(rect) - size.height) / 2.0;
  [text drawAtPoint: at withAttributes: attributes];
}

- (void) _drawCalendarInFrame: (NSRect)frame ofView: (NSView *)view
{
  NSDictionary *attributes = [self _dayAttributes];
  NSRect calendar = [self _calendarFrameForFrame: frame];
  NSSize day = [self _dayCellSize];
  NSArray *initials = [self _weekdayInitials];
  NSCalendar *cal = [self _pickerCalendar];
  NSInteger first = (NSInteger)[cal firstWeekday];
  NSRect row;
  NSInteger index;

  row = NSMakeRect(NSMinX(calendar), 0.0, NSWidth(calendar), day.height);
  row.origin.y = [view isFlipped] ? NSMinY(calendar)
    : NSMaxY(calendar) - day.height;
  drawCentred([self _monthTitle], row, attributes);

  for (index = 0; index < 7; index++)
    {
      NSRect cell = [self _dayCellRectAtRow: -1 column: index
                                    inFrame: frame ofView: view];

      drawCentred([initials objectAtIndex: (first - 1 + index) % 7],
                  cell, attributes);
    }

  for (index = 0; index < 42; index++)
    {
      NSInteger number = [self _dayAtRow: index / 7 column: index % 7];
      NSRect cell;

      if (number == 0)
        {
          continue;
        }
      cell = [self _dayCellRectAtRow: index / 7 column: index % 7
                             inFrame: frame ofView: view];
      if ([self _dayIsPicked: number])
        {
          NSMutableDictionary *marked = AUTORELEASE([attributes mutableCopy]);

          [[NSColor selectedTextBackgroundColor] set];
          NSRectFill(cell);
          [marked setObject: [NSColor selectedTextColor]
                     forKey: NSForegroundColorAttributeName];
          drawCentred([NSString stringWithFormat: @"%ld", (long)number],
                      cell, marked);
        }
      else
        {
          drawCentred([NSString stringWithFormat: @"%ld", (long)number],
                      cell, attributes);
        }
    }
}

- (void) _drawClockInFrame: (NSRect)frame
{
  NSRect clock = [self _clockFrameForFrame: frame];
  CGFloat size = MIN(NSWidth(clock), NSHeight(clock)) - 4.0;
  NSPoint centre = NSMakePoint(NSMidX(clock), NSMidY(clock));
  NSCalendar *calendar = [self _pickerCalendar];
  NSDateComponents *parts;
  NSBezierPath *face;
  CGFloat hour;
  CGFloat minute;
  NSInteger index;

  if (size <= 0.0 || [self dateValue] == nil)
    {
      return;
    }

  face = [NSBezierPath bezierPathWithOvalInRect:
    NSMakeRect(centre.x - size / 2.0, centre.y - size / 2.0, size, size)];
  [[NSColor controlBackgroundColor] set];
  [face fill];
  [[NSColor controlDarkShadowColor] set];
  [face stroke];

  for (index = 0; index < 12; index++)
    {
      CGFloat angle = index * M_PI / 6.0;
      NSPoint from = NSMakePoint(centre.x + sin(angle) * size * 0.45,
                                 centre.y + cos(angle) * size * 0.45);
      NSPoint to = NSMakePoint(centre.x + sin(angle) * size * 0.40,
                               centre.y + cos(angle) * size * 0.40);

      [NSBezierPath strokeLineFromPoint: from toPoint: to];
    }

  parts = [calendar components: NSCalendarUnitHour | NSCalendarUnitMinute
                      fromDate: [self dateValue]];
  minute = [parts minute] * M_PI / 30.0;
  hour = ([parts hour] % 12) * M_PI / 6.0 + minute / 12.0;
  [NSBezierPath strokeLineFromPoint: centre
                            toPoint: NSMakePoint(
                              centre.x + sin(hour) * size * 0.25,
                              centre.y + cos(hour) * size * 0.25)];
  [NSBezierPath strokeLineFromPoint: centre
                            toPoint: NSMakePoint(
                              centre.x + sin(minute) * size * 0.38,
                              centre.y + cos(minute) * size * 0.38)];
}

/* The day of the month the point falls on, keeping the time of day the
   picker holds, or nil for a point that is not on a day of this month.
*/
- (NSDate *) _dayAtPoint: (NSPoint)point
                  inRect: (NSRect)frame
                  ofView: (NSView *)view
{
  NSCalendar *calendar = [self _pickerCalendar];
  NSDateComponents *parts;
  NSInteger index;

  if ([self dateValue] == nil)
    {
      return nil;
    }

  for (index = 0; index < 42; index++)
    {
      NSRect cell = [self _dayCellRectAtRow: index / 7 column: index % 7
                                    inFrame: frame ofView: view];
      NSInteger number = [self _dayAtRow: index / 7 column: index % 7];

      if (number == 0 || !NSMouseInRect(point, cell, [view isFlipped]))
        {
          continue;
        }
      parts = [calendar components: NSCalendarUnitEra | NSCalendarUnitYear
        | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour
        | NSCalendarUnitMinute | NSCalendarUnitSecond
                          fromDate: [self dateValue]];
      [parts setDay: number];

      return [calendar dateFromComponents: parts];
    }

  return nil;
}

- (BOOL) _selectDayAtPoint: (NSPoint)point
                   inRect: (NSRect)frame
                   ofView: (NSView *)view
{
  NSDate *picked = [self _dayAtPoint: point inRect: frame ofView: view];

  if (picked == nil)
    {
      return NO;
    }
  [self setDateValue: picked];

  return YES;
}

/* In the calendar the arrow keys walk the grid, a day across and a week up
   or down.
*/
- (BOOL) _stepDaysBy: (NSInteger)days
{
  NSCalendar *calendar = [self _pickerCalendar];
  NSDateComponents *step = AUTORELEASE([[NSDateComponents alloc] init]);
  NSDate *stepped;

  if ([self dateValue] == nil)
    {
      return NO;
    }
  [step setDay: days];
  stepped = [calendar dateByAddingComponents: step
                                      toDate: [self dateValue]
                                     options: 0];
  if (stepped == nil)
    {
      return NO;
    }
  [self setDateValue: stepped];

  return YES;
}

/* The style with a stepper keeps room for it at the trailing edge, and the
   text is drawn in what is left.
*/
- (BOOL) _hasStepper
{
  return (_datePickerStyle == NSTextFieldAndStepperDatePickerStyle);
}

- (CGFloat) _stepperWidth
{
  NSImage *image = [NSImage imageNamed: @"common_StepperUp"];

  return (image == nil) ? 0.0 : [image size].width;
}

- (NSRect) _stepperFrameForFrame: (NSRect)frame
{
  NSRect stepper = frame;

  stepper.size.width = [self _stepperWidth];
  stepper.origin.x = NSMaxX(frame) - NSWidth(stepper);

  return stepper;
}

- (NSRect) _textFrameForFrame: (NSRect)frame
{
  if ([self _hasStepper])
    {
      frame.size.width -= [self _stepperWidth];
    }

  return frame;
}

/* Which of the two stepper buttons is drawn pressed: one for the upper,
   minus one for the lower, zero for neither.
*/
- (void) _setHighlightedStepper: (NSInteger)direction
{
  _highlightedStepper = direction;
}

- (NSSize) cellSize
{
  NSSize size;

  if ([self _showsCalendar] || [self _showsClock])
    {
      size = NSMakeSize(0.0, [self _calendarSize].height);
      if ([self _showsCalendar])
        {
          size.width += [self _calendarSize].width;
        }
      if ([self _showsClock])
        {
          size.width += size.height;
        }

      return size;
    }

  size = [super cellSize];
  if ([self _hasStepper])
    {
      size.width += [self _stepperWidth];
    }

  return size;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  if (_drawsBackground && _backgroundColor != nil)
    {
      [_backgroundColor set];
      NSRectFill([self drawingRectForBounds: cellFrame]);
    }

  if ([self _showsCalendar] || [self _showsClock])
    {
      if ([self _showsCalendar])
        {
          [self _drawCalendarInFrame: cellFrame ofView: controlView];
        }
      if ([self _showsClock])
        {
          [self _drawClockInFrame: cellFrame];
        }

      return;
    }

  if ([self _hasStepper] && NSWidth(cellFrame) > [self _stepperWidth])
    {
      [[GSTheme theme] drawStepperCell: self
                             withFrame: [self _stepperFrameForFrame: cellFrame]
                                inView: controlView
                           highlightUp: (_highlightedStepper > 0)
                         highlightDown: (_highlightedStepper < 0)];
    }

  [super drawInteriorWithFrame: [self _textFrameForFrame: cellFrame]
                        inView: controlView];
}

/* Where the text starts inside the frame it is drawn in. */
- (CGFloat) _textOriginForFrame: (NSRect)frame width: (CGFloat)width
{
  NSRect title = [self titleRectForBounds: [self _textFrameForFrame: frame]];

  switch ([self alignment])
    {
      case NSRightTextAlignment:
        return NSMaxX(title) - width;
      case NSCenterTextAlignment:
        return NSMidX(title) - width / 2.0;
      default:
        return NSMinX(title);
    }
}

/* Picks the part of the date the point falls in.  Returns NO when the point
   is not over the text at all.
*/
- (BOOL) _selectFieldAtPoint: (NSPoint)point inRect: (NSRect)frame
{
  NSAttributedString *text = [self attributedStringValue];
  NSString *string = [text string];
  NSArray *fields = [self _editableFields];
  NSUInteger count = [fields count];
  NSUInteger index;
  CGFloat origin;

  if ([string length] == 0 || count == 0)
    {
      return NO;
    }
  if ([self _hasStepper] && point.x >= NSMaxX([self _textFrameForFrame: frame]))
    {
      return NO;
    }

  origin = [self _textOriginForFrame: frame width: [text size].width];
  for (index = 0; index < count; index++)
    {
      NSRange range = [self _rangeOfFieldAtIndex: index inString: string];
      CGFloat end;

      if (range.location == NSNotFound)
        {
          continue;
        }
      end = origin + [[text attributedSubstringFromRange:
        NSMakeRange(0, NSMaxRange(range))] size].width;
      if (point.x < end || index + 1 == count)
        {
          [self _setSelectedFieldIndex: index];
          return YES;
        }
    }

  return NO;
}

/* Which half of the stepper the point is in: one for the upper button,
   minus one for the lower one, zero for anywhere else.
*/
- (NSInteger) _stepperDirectionAtPoint: (NSPoint)point
                                inRect: (NSRect)frame
                                ofView: (NSView *)view
{
  NSRect stepper;
  BOOL flipped = [view isFlipped];

  if (![self _hasStepper] || NSWidth(frame) <= [self _stepperWidth])
    {
      return 0;
    }

  stepper = [self _stepperFrameForFrame: frame];
  if (!NSMouseInRect(point, stepper, flipped))
    {
      return 0;
    }
  if (flipped)
    {
      return (point.y < NSMidY(stepper)) ? 1 : -1;
    }

  return (point.y > NSMidY(stepper)) ? 1 : -1;
}

/* Returns YES when the key belongs to the picker.  The caller looks at the
   date to see whether it changed.
*/
- (BOOL) _handleKeyEvent: (NSEvent *)event
{
  NSString *characters = [event charactersIgnoringModifiers];
  NSArray *fields;
  unichar c;

  if ([characters length] == 0)
    {
      return NO;
    }

  fields = [self _editableFields];
  if ([fields count] == 0 || [self dateValue] == nil || ![self isEnabled])
    {
      return NO;
    }

  c = [characters characterAtIndex: 0];
  if ([self _showsCalendar])
    {
      switch (c)
        {
          case NSUpArrowFunctionKey:    return [self _stepDaysBy: -7];
          case NSDownArrowFunctionKey:  return [self _stepDaysBy: 7];
          case NSLeftArrowFunctionKey:  return [self _stepDaysBy: -1];
          case NSRightArrowFunctionKey: return [self _stepDaysBy: 1];
          default: break;
        }
    }
  else
    {
      switch (c)
        {
          case NSUpArrowFunctionKey:
            return [self _stepSelectedFieldBy: 1];
          case NSDownArrowFunctionKey:
            return [self _stepSelectedFieldBy: -1];
          case NSLeftArrowFunctionKey:
            [self _setSelectedFieldIndex: [self _selectedFieldIndex] - 1];
            return YES;
          case NSRightArrowFunctionKey:
            [self _setSelectedFieldIndex: [self _selectedFieldIndex] + 1];
            return YES;
          default:
            break;
        }
    }

  if (c >= '0' && c <= '9')
    {
      return [self _typeDigit: c - '0'];
    }
  if ((c == 'a' || c == 'A' || c == 'p' || c == 'P')
    && [self _hasMeridiemField])
    {
      return [self _setMeridiemAfterNoon: (c == 'p' || c == 'P')];
    }

  return NO;
}

/* NSCell keeps the text its formatter made when the value was set, which is
   stale once the elements or the locale change, and -stringForObjectValue:
   builds that text from a %-style format rather than from the pattern.
*/
- (NSString *) stringValue
{
  NSDateFormatter *formatter = (NSDateFormatter *)[self formatter];
  id value = [self objectValue];

  if ([value isKindOfClass: [NSDate class]]
    && [formatter isKindOfClass: [NSDateFormatter class]]
    && [[formatter dateFormat] length] > 0)
    {
      return [formatter stringFromDate: (NSDate *)value];
    }

  return [super stringValue];
}

/* The field the user is on is shown the way selected text is, and only while
   the picker holds the keyboard.
*/
- (BOOL) _showsSelectedField
{
  NSView *view = [self controlView];

  return (view != nil && [[view window] firstResponder] == view
    && [[view window] isKeyWindow] && [self isEnabled]);
}

- (NSAttributedString *) attributedStringValue
{
  NSAttributedString *text = [super attributedStringValue];
  NSMutableAttributedString *marked;
  NSRange range;

  if (![self _showsSelectedField])
    {
      return text;
    }

  range = [self _rangeOfFieldAtIndex: [self _selectedFieldIndex]
                            inString: [text string]];
  if (range.location == NSNotFound)
    {
      return text;
    }

  marked = AUTORELEASE([text mutableCopy]);
  [marked addAttribute: NSBackgroundColorAttributeName
                 value: [NSColor selectedTextBackgroundColor]
                 range: range];
  [marked addAttribute: NSForegroundColorAttributeName
                 value: [NSColor selectedTextColor]
                 range: range];

  return marked;
}

- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)obj
{
  _delegate = obj;
}

- (BOOL) drawsBackground
{
  return _drawsBackground;
}

- (void) setDrawsBackground: (BOOL)flag
{
  _drawsBackground = flag;
}

- (NSLocale *) locale
{
  return [[self formatter] locale];
}

- (void) setLocale: (NSLocale *)locale
{
  [[self formatter] setLocale: locale];
  [self _updateDateFormat];
}

- (NSDate *) maxDate
{
  return _maxDate;
}

- (void) setMaxDate: (NSDate *)date
{
  ASSIGN(_maxDate, date);
  [self setObjectValue: [self _clampedDate: [self dateValue]]];
}

- (NSDate *) minDate
{
  return _minDate;
}

- (void) setMinDate: (NSDate *)date
{
  ASSIGN(_minDate, date);
  [self setObjectValue: [self _clampedDate: [self dateValue]]];
}

- (NSColor *) textColor
{
  return _textColor;
}

- (void) setTextColor: (NSColor *)color
{
  ASSIGN(_textColor, color);
}

- (NSTimeInterval) timeInterval
{
  return _timeInterval;
}

- (void) setTimeInterval: (NSTimeInterval)interval
{
  _timeInterval = interval;
}

- (NSTimeZone *) timeZone
{
  return [[self formatter] timeZone];
}

- (void) setTimeZone: (NSTimeZone *)zone
{
  [[self formatter] setTimeZone: zone];
}

/* A date picker is edited in place and it tracks the mouse, in every style
   it draws, so it is all three kinds of area at once.
*/
- (NSUInteger) hitTestForEvent: (NSEvent *)event
                        inRect: (NSRect)cellFrame
                        ofView: (NSView *)controlView
{
  if (![self isEnabled])
    {
      return NSCellHitContentArea;
    }

  return NSCellHitContentArea | NSCellHitEditableTextArea
    | NSCellHitTrackableArea;
}

/* NSCell copies its own object ivars as bare pointers and then retains them,
   leaving the ones added here held by two cells but retained by one.
*/
- (id) copyWithZone: (NSZone *)zone
{
  NSDatePickerCell *copy = [super copyWithZone: zone];

  copy->_backgroundColor = TEST_RETAIN(_backgroundColor);
  copy->_textColor = TEST_RETAIN(_textColor);
  copy->_minDate = TEST_RETAIN(_minDate);
  copy->_maxDate = TEST_RETAIN(_maxDate);

  return copy;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeDouble: [self timeInterval] forKey: @"NSTimeInterval"];
      [aCoder encodeInt: [self datePickerElements] forKey: @"NSDatePickerElements"];
      [aCoder encodeInt: [self datePickerStyle] forKey: @"NSDatePickerType"];
      [aCoder encodeInt: [self datePickerMode] forKey: @"NSDatePickerMode"];
      [aCoder encodeObject: [self backgroundColor] forKey: @"NSBackgroundColor"];
      [aCoder encodeObject: [self textColor] forKey: @"NSTextColor"];
      [aCoder encodeBool: [self drawsBackground] forKey: @"NSDrawsBackground"];
      [aCoder encodeObject: [self minDate] forKey: @"NSMinDate"];
      [aCoder encodeObject: [self maxDate] forKey: @"NSMaxDate"];
      /* NSCell writes the text of its value, not the value, and the text of
         a date does not read back as one. */
      [aCoder encodeObject: [self dateValue] forKey: @"NSDateValue"];
    }
  else
    {
      int elements = (int)_datePickerElements;
      int mode = (int)_datePickerMode;
      int style = (int)_datePickerStyle;
      BOOL draws = _drawsBackground;
      NSDate *value = [self dateValue];

      [aCoder encodeValueOfObjCType: @encode(NSTimeInterval)
                                 at: &_timeInterval];
      [aCoder encodeValueOfObjCType: @encode(int) at: &elements];
      [aCoder encodeValueOfObjCType: @encode(int) at: &mode];
      [aCoder encodeValueOfObjCType: @encode(int) at: &style];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &draws];
      [aCoder encodeObject: _backgroundColor];
      [aCoder encodeObject: _textColor];
      [aCoder encodeObject: _minDate];
      [aCoder encodeObject: _maxDate];
      [aCoder encodeObject: value];
    }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  if ((self = [super initWithCoder: aDecoder]))
    {
      if (![[self formatter] isKindOfClass: [NSDateFormatter class]])
        {
          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

          [self setFormatter: formatter];
          RELEASE(formatter);
        }
      if ([aDecoder allowsKeyedCoding])
        {
          [self setTimeInterval: [aDecoder decodeDoubleForKey: @"NSTimeInterval"]];
          [self setDatePickerElements: [aDecoder decodeIntForKey: @"NSDatePickerElements"]];
          [self setDatePickerStyle: [aDecoder decodeIntForKey: @"NSDatePickerType"]];
          if ([aDecoder containsValueForKey: @"NSDatePickerMode"])
            {
              [self setDatePickerMode:
                [aDecoder decodeIntForKey: @"NSDatePickerMode"]];
            }
          [self setBackgroundColor: [aDecoder decodeObjectForKey: @"NSBackgroundColor"]];
          if ([aDecoder containsValueForKey: @"NSTextColor"])
            {
              [self setTextColor: [aDecoder decodeObjectForKey: @"NSTextColor"]];
            }
          if ([aDecoder containsValueForKey: @"NSDrawsBackground"])
            {
              [self setDrawsBackground:
                [aDecoder decodeBoolForKey: @"NSDrawsBackground"]];
            }
          [self setMinDate: [aDecoder decodeObjectForKey: @"NSMinDate"]];
          [self setMaxDate: [aDecoder decodeObjectForKey: @"NSMaxDate"]];
          if ([aDecoder containsValueForKey: @"NSDateValue"])
            {
              [self setDateValue:
                [aDecoder decodeObjectForKey: @"NSDateValue"]];
            }
        }
      else
        {
          int elements;
          int mode;
          int style;
          BOOL draws;
          NSTimeInterval interval;

          [aDecoder decodeValueOfObjCType: @encode(NSTimeInterval)
                                       at: &interval];
          [aDecoder decodeValueOfObjCType: @encode(int) at: &elements];
          [aDecoder decodeValueOfObjCType: @encode(int) at: &mode];
          [aDecoder decodeValueOfObjCType: @encode(int) at: &style];
          [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &draws];
          [self setTimeInterval: interval];
          [self setDatePickerElements: elements];
          [self setDatePickerMode: mode];
          [self setDatePickerStyle: style];
          [self setDrawsBackground: draws];
          [self setBackgroundColor: [aDecoder decodeObject]];
          [self setTextColor: [aDecoder decodeObject]];
          [self setMinDate: [aDecoder decodeObject]];
          [self setMaxDate: [aDecoder decodeObject]];
          [self setDateValue: [aDecoder decodeObject]];
        }
    }

  return self;
}

@end
