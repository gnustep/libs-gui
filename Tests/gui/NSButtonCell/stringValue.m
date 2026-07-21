/* An NSButtonCell has no separate value: its string value is the string
   form of its state, so it is "1" when on, "0" when off and "-1" when
   mixed (verified against OS X). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButtonCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSButtonCell *cell;

  START_SET("NSButtonCell stringValue")

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

  cell = AUTORELEASE([[NSButtonCell alloc] init]);

  [cell setState: NSOnState];
  pass([[cell stringValue] isEqualToString: @"1"], "an on cell has string value 1");
  [cell setState: NSOffState];
  pass([[cell stringValue] isEqualToString: @"0"], "an off cell has string value 0");
  [cell setAllowsMixedState: YES];
  [cell setState: NSMixedState];
  pass([[cell stringValue] isEqualToString: @"-1"], "a mixed cell has string value -1");

  END_SET("NSButtonCell stringValue")

  DESTROY(arp);
  return 0;
}
