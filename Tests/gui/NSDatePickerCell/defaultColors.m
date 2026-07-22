/* A default NSDatePickerCell uses the control text and control background
   colours, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSDatePickerCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePickerCell *cell;

  START_SET("NSDatePickerCell defaultColors")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSDatePickerCell alloc] init]);
  PASS([[cell textColor] isEqual: [NSColor controlTextColor]],
       "default textColor is controlTextColor");
  PASS([[cell backgroundColor] isEqual: [NSColor controlBackgroundColor]],
       "default backgroundColor is controlBackgroundColor");

  END_SET("NSDatePickerCell defaultColors")

  DESTROY(arp);
  return 0;
}
