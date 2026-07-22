/* Coverage for NSDatePickerCell: the init defaults (style, mode, timeInterval,
   min/max date, drawsBackground), the plain setter round-trips for the style,
   mode, element flags, time interval and background flag, and that a date
   value inside [minDate, maxDate] is kept.  Every assertion here matches AppKit
   (verified on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePickerCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePickerCell *cell;
  NSDate *inRange;

  START_SET("NSDatePickerCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* init defaults */
  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  PASS([cell datePickerStyle] == NSTextFieldAndStepperDatePickerStyle,
       "default style is text-field-and-stepper");
  PASS([cell datePickerMode] == NSSingleDateMode,
       "default mode is single-date");
  PASS([cell timeInterval] == 0.0, "default timeInterval is 0");
  PASS([cell minDate] == nil, "default minDate is nil");
  PASS([cell maxDate] == nil, "default maxDate is nil");
  PASS([cell drawsBackground] == NO, "default drawsBackground is NO");

  /* setter round-trips */
  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  [cell setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
  [cell setDatePickerMode: NSRangeDateMode];
  [cell setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
  [cell setTimeInterval: 3600.0];
  [cell setDrawsBackground: YES];
  PASS([cell datePickerStyle] == NSClockAndCalendarDatePickerStyle,
       "datePickerStyle round-trips");
  PASS([cell datePickerMode] == NSRangeDateMode, "datePickerMode round-trips");
  PASS([cell datePickerElements] == NSYearMonthDayDatePickerElementFlag,
       "datePickerElements round-trips");
  PASS([cell timeInterval] == 3600.0, "timeInterval round-trips");
  PASS([cell drawsBackground] == YES, "drawsBackground round-trips");

  /* a date inside [minDate, maxDate] is kept as-is */
  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  [cell setMinDate: [NSDate dateWithTimeIntervalSinceReferenceDate: 0.0]];
  [cell setMaxDate: [NSDate dateWithTimeIntervalSinceReferenceDate: 1000000.0]];
  inRange = [NSDate dateWithTimeIntervalSinceReferenceDate: 500000.0];
  [cell setDateValue: inRange];
  PASS([[cell dateValue] isEqualToDate: inRange],
       "a date within [minDate, maxDate] is kept");

  END_SET("NSDatePickerCell basic")

  DESTROY(arp);
  return 0;
}
