#import "Testing.h"
#import <AppKit/NSViewController.h>
#import <AppKit/NSSplitViewController.h>

/* NSSplitViewController state: the minimum thickness for inline sidebars is a
   plain property that round-trips and does not need a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSSplitViewController *svc = AUTORELEASE([[NSSplitViewController alloc] init]);

  [svc setMinimumThicknessForInlineSidebars: 120.0];
  PASS([svc minimumThicknessForInlineSidebars] == 120.0,
    "the minimum inline sidebar thickness round-trips");
  [svc setMinimumThicknessForInlineSidebars: 44.5];
  PASS([svc minimumThicknessForInlineSidebars] == 44.5,
    "the minimum inline sidebar thickness round-trips to another value");

  DESTROY(arp);
  return 0;
}
