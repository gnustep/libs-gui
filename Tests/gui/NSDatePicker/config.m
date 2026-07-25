/* Coverage for the NSDatePicker configuration: the defaults that match AppKit
   (text-field-and-stepper style, single date mode, the year-month-day and
   hour-minute-second elements, no drawn background, no border, no date limits)
   and the setter round-trips, including the date value and the min/max range.
   Checked against AppKit on a macOS runner (style, mode and element flags are
   compared by their enumerated names).  A fixed reference date drives the date
   round-trips.  The picker uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSDate.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePicker *dp;

  START_SET("NSDatePicker config")

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
      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0, 0, 180, 24)]);

      /* Defaults. */
      PASS([dp datePickerStyle] == NSTextFieldAndStepperDatePickerStyle,
           "the default style is text field and stepper");
      PASS([dp datePickerMode] == NSSingleDateMode,
           "the default mode is a single date");
      PASS([dp datePickerElements] == (NSYearMonthDayDatePickerElementFlag
             | NSHourMinuteSecondDatePickerElementFlag),
           "the default elements are year-month-day and hour-minute-second");
      PASS([dp drawsBackground] == NO, "the picker draws no background by default");
      PASS([dp isBordered] == NO, "the picker is not bordered by default");
      PASS([dp minDate] == nil, "there is no minimum date by default");
      PASS([dp maxDate] == nil, "there is no maximum date by default");

      /* Setter round-trips. */
      [dp setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
      PASS([dp datePickerStyle] == NSClockAndCalendarDatePickerStyle,
           "setDatePickerStyle: round trips");
      [dp setDatePickerMode: NSRangeDateMode];
      PASS([dp datePickerMode] == NSRangeDateMode, "setDatePickerMode: round trips");
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      PASS([dp datePickerElements] == NSYearMonthDayDatePickerElementFlag,
           "setDatePickerElements: round trips");
      [dp setDrawsBackground: YES];
      PASS([dp drawsBackground] == YES, "setDrawsBackground: round trips");
      [dp setBezeled: NO];
      PASS([dp isBezeled] == NO, "setBezeled: NO round trips");

      /* Date value and range round-trips. */
      NSDate *d  = [NSDate dateWithTimeIntervalSinceReferenceDate: 700000000.0];
      NSDate *lo = [NSDate dateWithTimeIntervalSinceReferenceDate: 600000000.0];
      NSDate *hi = [NSDate dateWithTimeIntervalSinceReferenceDate: 800000000.0];
      [dp setDateValue: d];
      PASS([[dp dateValue] timeIntervalSinceReferenceDate] == 700000000.0,
           "setDateValue: round trips");
      [dp setMinDate: lo];
      PASS([[dp minDate] timeIntervalSinceReferenceDate] == 600000000.0,
           "setMinDate: round trips");
      [dp setMaxDate: hi];
      PASS([[dp maxDate] timeIntervalSinceReferenceDate] == 800000000.0,
           "setMaxDate: round trips");
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

  END_SET("NSDatePicker config")

  DESTROY(arp);
  return 0;
}
