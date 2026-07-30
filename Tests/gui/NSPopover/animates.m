#import "Testing.h"
#import <AppKit/NSPopover.h>

/* A new popover animates its appearance and disappearance by default.  This is
   an in-memory property and does not need a window server. */

int
main(int argc, const char **argv)
{
  START_SET("NSPopover animates")

  NSPopover *p = AUTORELEASE([[NSPopover alloc] init]);

  PASS([p animates] == YES, "a new popover animates by default");

  END_SET("NSPopover animates")
  return 0;
}
