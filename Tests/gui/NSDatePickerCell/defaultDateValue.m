/* A default NSDatePickerCell has a non-nil date value; AppKit uses the
   reference date (2001-01-01 00:00:00 GMT). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePickerCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePickerCell *cell;

  START_SET("NSDatePickerCell defaultDateValue")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  pass([cell dateValue] != nil, "default dateValue is non-nil");
  pass([[cell dateValue] isEqualToDate:
          [NSDate dateWithTimeIntervalSinceReferenceDate: 0.0]],
       "default dateValue is the reference date");

  END_SET("NSDatePickerCell defaultDateValue")

  DESTROY(arp);
  return 0;
}
