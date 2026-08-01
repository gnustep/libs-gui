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

#import <Foundation/NSString.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDateFormatter.h>
#import "AppKit/NSDatePickerCell.h"
#import "AppKit/NSColor.h"

@interface NSDatePickerCell (Private)
- (void) _updateDateFormat;
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

  if (elements & NSEraDatePickerElementFlag)
    {
      [template appendString: @"G"];
    }
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
  if (elements & NSEraDatePickerElementFlag)
    {
      [format appendString: @" G"];
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
  _datePickerElements = flags;
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
  [self setObjectValue: [self _clampedDate: date]];
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

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeDouble: [self timeInterval] forKey: @"NSTimeInterval"];
      [aCoder encodeInt: [self datePickerElements] forKey: @"NSDatePickerElements"];
      [aCoder encodeInt: [self datePickerStyle] forKey: @"NSDatePickerType"];
      [aCoder encodeObject: [self backgroundColor] forKey: @"NSBackgroundColor"];
    }
  else
    {
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
          [self setBackgroundColor: [aDecoder decodeObjectForKey: @"NSBackgroundColor"]];
        }
      else
        {
        }
    }

  return self;
}

@end
