/* A copy of a date picker cell has to hold the colours and the dates the
   original holds, and hold them itself: NSCell copies its object ivars as
   bare pointers and retains only the ones it knows about, so the ones this
   class adds are given back twice when the two cells go away.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSDatePickerCell.h>

int
main(int argc, char **argv)
{
  NSDatePickerCell *cell;
  NSDatePickerCell *copy;
  NSColor *colour;
  NSDate *low;
  NSDate *high;
  NSUInteger held;

  START_SET("NSDatePickerCell copying")

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
      low = [NSDate dateWithTimeIntervalSinceReferenceDate: 600000000.0];
      high = [NSDate dateWithTimeIntervalSinceReferenceDate: 800000000.0];
      colour = RETAIN([NSColor colorWithCalibratedRed: 0.1
                                                green: 0.2
                                                 blue: 0.3
                                                alpha: 1.0]);

      cell = [[NSDatePickerCell alloc] initTextCell: @""];
      [cell setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate:
        700000000.0]];
      [cell setMinDate: low];
      [cell setMaxDate: high];
      [cell setBackgroundColor: colour];
      [cell setTextColor: [NSColor blueColor]];
      [cell setDrawsBackground: YES];
      [cell setDatePickerMode: NSRangeDateMode];
      [cell setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
      [cell setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [cell setTimeInterval: 3600.0];

      held = [colour retainCount];
      copy = [cell copy];

      PASS([copy isKindOfClass: [NSDatePickerCell class]] && copy != cell,
           "a date picker cell copies to another one");
      PASS([colour retainCount] == held + 1,
           "the copy holds the colours it shares with the original");

      PASS_EQUAL([copy minDate], low, "the copy has the same minimum date");
      PASS_EQUAL([copy maxDate], high, "the copy has the same maximum date");
      PASS_EQUAL([copy dateValue], [cell dateValue],
                 "the copy has the same date");
      PASS_EQUAL([copy backgroundColor], colour,
                 "the copy has the same background colour");
      PASS_EQUAL([copy textColor], [cell textColor],
                 "the copy has the same text colour");
      PASS([copy drawsBackground] == YES
           && [copy datePickerMode] == NSRangeDateMode
           && [copy datePickerStyle] == NSClockAndCalendarDatePickerStyle
           && [copy datePickerElements] == NSYearMonthDayDatePickerElementFlag
           && [copy timeInterval] == 3600.0,
           "the copy has the same settings");

      RELEASE(copy);
      PASS([colour retainCount] == held,
           "letting the copy go gives back only what the copy held");
      PASS_EQUAL([cell backgroundColor], colour,
                 "the original still has its background colour");

      RELEASE(cell);
      PASS([colour retainCount] == held - 1,
           "letting the original go gives back the last hold on the colour");
      RELEASE(colour);
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

  END_SET("NSDatePickerCell copying")

  return 0;
}
