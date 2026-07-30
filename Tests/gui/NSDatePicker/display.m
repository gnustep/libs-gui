/* The text a date picker shows follows the elements it is configured with,
   in the order and the form its locale writes them, and in its own time zone.
   The assertions look for the parts of the date rather than a whole string,
   so that they hold for the pattern any CLDR version produces.  A build
   without ICU has no pattern generator and falls back to a fixed order, so
   the one assertion that compares two locales is made only when the
   generator answers.  The picker uses the theme and font backend, so the set
   is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSDateFormatter.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSLocale.h>
#include <Foundation/NSString.h>
#include <Foundation/NSTimeZone.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>

static BOOL
has(NSString *string, NSString *part)
{
  return [string rangeOfString: part].length > 0;
}

int
main(int argc, char **argv)
{
  NSDatePicker *dp;
  NSString *text;
  NSString *american;
  NSDate *date;
  BOOL generator;

  START_SET("NSDatePicker display")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      generator = ([NSDateFormatter dateFormatFromTemplate: @"yMd"
                                                   options: 0
                                                    locale: [NSLocale localeWithLocaleIdentifier: @"en_US"]]
                    != nil);

      /* 8 March 2023, 20:26:40 GMT. */
      date = [NSDate dateWithTimeIntervalSinceReferenceDate: 700000000.0];
      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0, 0, 260, 26)]);
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDateValue: date];

      text = [[dp cell] stringValue];
      PASS(has(text, @"2023") && has(text, @":26:") && has(text, @"40"),
           "the default elements show the date and the time to the second");
      PASS(!has(text, @"+0000") && ![text isEqualToString: [date description]],
           "the shown text is not the description of the date");

      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      text = [[dp cell] stringValue];
      PASS(has(text, @"2023") && !has(text, @":26"),
           "the year-month-day elements drop the time");

      [dp setDatePickerElements: NSHourMinuteSecondDatePickerElementFlag];
      text = [[dp cell] stringValue];
      PASS(has(text, @":26:") && has(text, @"40") && !has(text, @"2023"),
           "the hour-minute-second elements drop the date");

      [dp setDatePickerElements: NSHourMinuteDatePickerElementFlag];
      text = [[dp cell] stringValue];
      PASS(has(text, @":26") && !has(text, @":26:"),
           "the hour-minute elements drop the seconds");

      [dp setDatePickerElements: NSYearMonthDatePickerElementFlag];
      text = [[dp cell] stringValue];
      PASS(has(text, @"2023") && !has(text, @":"),
           "the year-month elements drop the day and the time");

      /* The time zone the picker is set to decides the hour it shows. */
      [dp setDatePickerElements: NSHourMinuteSecondDatePickerElementFlag];
      text = [[dp cell] stringValue];
      [dp setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 3600 * 5]];
      PASS(![[[dp cell] stringValue] isEqualToString: text],
           "the shown time follows the time zone of the picker");

      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      american = [[dp cell] stringValue];
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"de_DE"]];
      if (generator)
        {
          PASS(![[[dp cell] stringValue] isEqualToString: american],
               "the shown date follows the locale of the picker");
        }
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSDatePicker display")

  return 0;
}
