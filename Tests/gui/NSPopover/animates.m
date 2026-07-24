#import "Testing.h"
#import <AppKit/NSPopover.h>

/* A new popover animates its appearance and disappearance by default.  This is
   an in-memory property and does not need a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSPopover *p = AUTORELEASE([[NSPopover alloc] init]);

  PASS([p animates] == YES, "a new popover animates by default");

  DESTROY(arp);
  return 0;
}
