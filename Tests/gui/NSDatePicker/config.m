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
      pass([dp datePickerStyle] == NSTextFieldAndStepperDatePickerStyle,
           "the default style is text field and stepper");
      pass([dp datePickerMode] == NSSingleDateMode,
           "the default mode is a single date");
      pass([dp datePickerElements] == (NSYearMonthDayDatePickerElementFlag
             | NSHourMinuteSecondDatePickerElementFlag),
           "the default elements are year-month-day and hour-minute-second");
      pass([dp drawsBackground] == NO, "the picker draws no background by default");
      pass([dp isBordered] == NO, "the picker is not bordered by default");
      pass([dp minDate] == nil, "there is no minimum date by default");
      pass([dp maxDate] == nil, "there is no maximum date by default");

      /* Setter round-trips. */
      [dp setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
      pass([dp datePickerStyle] == NSClockAndCalendarDatePickerStyle,
           "setDatePickerStyle: round trips");
      [dp setDatePickerMode: NSRangeDateMode];
      pass([dp datePickerMode] == NSRangeDateMode, "setDatePickerMode: round trips");
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      pass([dp datePickerElements] == NSYearMonthDayDatePickerElementFlag,
           "setDatePickerElements: round trips");
      [dp setDrawsBackground: YES];
      pass([dp drawsBackground] == YES, "setDrawsBackground: round trips");
      [dp setBezeled: NO];
      pass([dp isBezeled] == NO, "setBezeled: NO round trips");

      /* Date value and range round-trips. */
      NSDate *d  = [NSDate dateWithTimeIntervalSinceReferenceDate: 700000000.0];
      NSDate *lo = [NSDate dateWithTimeIntervalSinceReferenceDate: 600000000.0];
      NSDate *hi = [NSDate dateWithTimeIntervalSinceReferenceDate: 800000000.0];
      [dp setDateValue: d];
      pass([[dp dateValue] timeIntervalSinceReferenceDate] == 700000000.0,
           "setDateValue: round trips");
      [dp setMinDate: lo];
      pass([[dp minDate] timeIntervalSinceReferenceDate] == 600000000.0,
           "setMinDate: round trips");
      [dp setMaxDate: hi];
      pass([[dp maxDate] timeIntervalSinceReferenceDate] == 800000000.0,
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
