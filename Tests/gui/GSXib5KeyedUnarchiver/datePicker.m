#import "ObjectTesting.h"

#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSDatePicker.h>
#import <AppKit/NSDatePickerCell.h>
#import <Additions/GNUstepGUI/GSXibKeyedUnarchiver.h>

/* The values checked here are the ones AppKit gives for DatePicker.xib
 * when it is compiled by ibtool and loaded on macOS.
 */
static NSDatePicker *
pickerAt(NSArray *rootObjects, CGFloat y)
{
  NSEnumerator	*enumerator = [rootObjects objectEnumerator];
  id		element;

  while ((element = [enumerator nextObject]) != nil)
    {
      if ([element isKindOfClass: [NSDatePicker class]]
	&& [element frame].origin.y == y)
	{
	  return element;
	}
    }
  return nil;
}

int main()
{
  START_SET("GSXib5KeyedUnarchiver NSDatePicker tests")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
	isEqualToString: NSInternalInconsistencyException ])
	{
	  SKIP("It looks like GNUstep backend is not yet installed")
	}
    }
  NS_ENDHANDLER

  NSData		*data;
  GSXibKeyedUnarchiver	*unarchiver;
  NSArray		*rootObjects;
  NSDatePicker		*picker;
  NSDate		*saved;

  data = [NSData dataWithContentsOfFile: @"DatePicker.xib"];
  unarchiver = [GSXibKeyedUnarchiver unarchiverForReadingWithData: data];
  rootObjects = [unarchiver decodeObjectForKey: @"IBDocument.RootObjects"];
  saved = [NSDate dateWithTimeIntervalSinceReferenceDate: -595929600];

  picker = pickerAt(rootObjects, 10);
  PASS(picker != nil, "the year-month-day picker was found")
  PASS([picker datePickerStyle] == NSTextFieldAndStepperDatePickerStyle,
    "no datePickerStyle is the text field and stepper style")
  PASS([picker datePickerMode] == NSSingleDateMode,
    "no datePickerMode is single date mode")
  PASS([picker datePickerElements] == NSYearMonthDayDatePickerElementFlag,
    "year, month and day are year-month-day")
  PASS_EQUAL([picker dateValue], saved, "the saved date is the date")

  picker = pickerAt(rootObjects, 50);
  PASS([picker datePickerElements] == NSYearMonthDatePickerElementFlag,
    "year and month are year-month")

  picker = pickerAt(rootObjects, 90);
  PASS([picker datePickerStyle] == NSTextFieldDatePickerStyle,
    "datePickerStyle textField is the text field style")
  PASS([picker datePickerElements] == NSHourMinuteDatePickerElementFlag,
    "hour and minute are hour-minute")

  picker = pickerAt(rootObjects, 130);
  PASS([picker datePickerStyle] == NSClockAndCalendarDatePickerStyle,
    "datePickerStyle clockAndCalendar is the clock and calendar style")
  PASS_EQUAL([picker minDate],
    [NSDate dateWithTimeIntervalSinceReferenceDate: -631152000],
    "minDate is the earliest date")
  PASS_EQUAL([picker maxDate],
    [NSDate dateWithTimeIntervalSinceReferenceDate: -568080000],
    "maxDate is the latest date")

  picker = pickerAt(rootObjects, 290);
  PASS([picker datePickerMode] == NSRangeDateMode,
    "datePickerMode range is range mode")
  PASS([picker datePickerElements]
    == (NSYearMonthDayDatePickerElementFlag
      | NSHourMinuteSecondDatePickerElementFlag
      | NSTimeZoneDatePickerElementFlag),
    "every element with seconds and the time zone")
  PASS(fabs([[picker dateValue] timeIntervalSinceNow]) < 60,
    "useCurrentDate takes the current date over the saved one")

  END_SET("GSXib5KeyedUnarchiver NSDatePicker tests")
  return 0;
}
