/* A default NSDatePickerCell shows the year/month/day and hour/minute/second
   elements, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePickerCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePickerCell *cell;

  START_SET("NSDatePickerCell defaultElements")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  pass([cell datePickerElements]
         == (NSYearMonthDayDatePickerElementFlag
             | NSHourMinuteSecondDatePickerElementFlag),
       "default elements are year-month-day and hour-minute-second");

  END_SET("NSDatePickerCell defaultElements")

  DESTROY(arp);
  return 0;
}
