/* Everything a date picker cell is set to has to survive an archive: the
   settings of the class itself, the dates that bound it, its colours, and
   the state NSCell holds, which needs -encodeWithCoder: to reach super.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSKeyedArchiver.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSDatePickerCell.h>

int
main(int argc, char **argv)
{
  NSDatePickerCell *cell;
  NSDatePickerCell *decoded;
  NSData *data;
  NSDate *value;
  NSDate *low;
  NSDate *high;
  NSColor *textColor;
  NSColor *backgroundColor;

  START_SET("NSDatePickerCell coding")

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
      value = [NSDate dateWithTimeIntervalSinceReferenceDate: 700000000.0];
      low = [NSDate dateWithTimeIntervalSinceReferenceDate: 600000000.0];
      high = [NSDate dateWithTimeIntervalSinceReferenceDate: 800000000.0];
      textColor = [NSColor colorWithCalibratedRed: 0.0
                                            green: 0.0
                                             blue: 1.0
                                            alpha: 1.0];
      backgroundColor = [NSColor colorWithCalibratedRed: 1.0
                                                  green: 0.0
                                                   blue: 0.0
                                                  alpha: 1.0];

      cell = AUTORELEASE([[NSDatePickerCell alloc] initTextCell: @""]);
      [cell setDateValue: value];
      [cell setMinDate: low];
      [cell setMaxDate: high];
      [cell setTextColor: textColor];
      [cell setBackgroundColor: backgroundColor];
      [cell setDrawsBackground: YES];
      [cell setDatePickerMode: NSRangeDateMode];
      [cell setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
      [cell setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [cell setTimeInterval: 3600.0];

      data = [NSKeyedArchiver archivedDataWithRootObject: cell];
      decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];

      PASS([decoded isKindOfClass: [NSDatePickerCell class]],
           "a date picker cell comes back from an archive");
      PASS([decoded datePickerStyle] == NSClockAndCalendarDatePickerStyle,
           "the style survives the archive");
      PASS([decoded datePickerMode] == NSRangeDateMode,
           "the mode survives the archive");
      PASS([decoded datePickerElements] == NSYearMonthDayDatePickerElementFlag,
           "the elements survive the archive");
      PASS([decoded timeInterval] == 3600.0,
           "the time interval survives the archive");
      PASS([decoded drawsBackground] == YES,
           "drawing the background survives the archive");
      PASS_EQUAL([decoded dateValue], value, "the date survives the archive");
      PASS_EQUAL([decoded minDate], low,
                 "the minimum date survives the archive");
      PASS_EQUAL([decoded maxDate], high,
                 "the maximum date survives the archive");
      PASS_EQUAL([decoded textColor], textColor,
                 "the text colour survives the archive");
      PASS_EQUAL([decoded backgroundColor], backgroundColor,
                 "the background colour survives the archive");
      PASS([decoded isBezeled] == [cell isBezeled],
           "the state NSCell holds survives the archive");

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

  END_SET("NSDatePickerCell coding")

  return 0;
}
