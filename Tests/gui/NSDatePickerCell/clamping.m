/* NSDatePickerCell clamps its date value to [minDate, maxDate] when the value
   is set and when the bounds later move past the value, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePickerCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePickerCell *cell;
  NSDate *minD, *maxD;

  START_SET("NSDatePickerCell clamping")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  minD = [NSDate dateWithTimeIntervalSinceReferenceDate: 0.0];
  maxD = [NSDate dateWithTimeIntervalSinceReferenceDate: 1000000.0];

  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  [cell setMinDate: minD];
  [cell setMaxDate: maxD];
  [cell setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: -1000000.0]];
  PASS([[cell dateValue] isEqualToDate: minD],
       "a date before minDate is clamped to minDate");
  [cell setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: 2000000.0]];
  PASS([[cell dateValue] isEqualToDate: maxD],
       "a date after maxDate is clamped to maxDate");

  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  [cell setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: 500000.0]];
  [cell setMinDate: [NSDate dateWithTimeIntervalSinceReferenceDate: 600000.0]];
  PASS([[cell dateValue] isEqualToDate:
          [NSDate dateWithTimeIntervalSinceReferenceDate: 600000.0]],
       "raising minDate past the value clamps the value up");

  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  [cell setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: 500000.0]];
  [cell setMaxDate: [NSDate dateWithTimeIntervalSinceReferenceDate: 400000.0]];
  PASS([[cell dateValue] isEqualToDate:
          [NSDate dateWithTimeIntervalSinceReferenceDate: 400000.0]],
       "lowering maxDate past the value clamps the value down");

  END_SET("NSDatePickerCell clamping")

  DESTROY(arp);
  return 0;
}
