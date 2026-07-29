/* Everything a date picker cell is set to has to survive an archive: the
   settings of the class itself, the dates that bound it, its colours, and
   the state NSCell holds, which needs -encodeWithCoder: to reach super.
*/
#include "Testing.h"

#include <Foundation/NSArchiver.h>
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
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePickerCell *cell;
  NSDatePickerCell *decoded;
  NSData *data;
  NSDate *value;
  NSDate *low;
  NSDate *high;

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

      cell = AUTORELEASE([[NSDatePickerCell alloc] initTextCell: @""]);
      [cell setDateValue: value];
      [cell setMinDate: low];
      [cell setMaxDate: high];
      [cell setTextColor: [NSColor blueColor]];
      [cell setBackgroundColor: [NSColor redColor]];
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
      PASS_EQUAL([decoded textColor], [NSColor blueColor],
                 "the text colour survives the archive");
      PASS_EQUAL([decoded backgroundColor], [NSColor redColor],
                 "the background colour survives the archive");
      PASS([decoded isBezeled] == [cell isBezeled],
           "the state NSCell holds survives the archive");

      /* The same, through an archive written without keys. */
      data = [NSArchiver archivedDataWithRootObject: cell];
      decoded = [NSUnarchiver unarchiveObjectWithData: data];

      PASS([decoded isKindOfClass: [NSDatePickerCell class]],
           "a cell comes back from an archive written without keys");
      PASS([decoded datePickerStyle] == NSClockAndCalendarDatePickerStyle
           && [decoded datePickerMode] == NSRangeDateMode
           && [decoded datePickerElements] == NSYearMonthDayDatePickerElementFlag
           && [decoded timeInterval] == 3600.0
           && [decoded drawsBackground] == YES,
           "the settings survive an archive without keys");
      PASS_EQUAL([decoded dateValue], value,
                 "the date survives an archive without keys");
      PASS_EQUAL([decoded minDate], low,
                 "the minimum date survives an archive without keys");
      PASS_EQUAL([decoded maxDate], high,
                 "the maximum date survives an archive without keys");
      PASS_EQUAL([decoded textColor], [NSColor blueColor],
                 "the text colour survives an archive without keys");
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

  DESTROY(arp);
  return 0;
}
