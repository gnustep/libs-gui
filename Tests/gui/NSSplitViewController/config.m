#import "Testing.h"
#import <AppKit/NSViewController.h>
#import <AppKit/NSSplitViewController.h>

#include <float.h>

/* NSSplitViewController state: the minimum thickness for inline sidebars is a
   plain property that round-trips and does not need a window server.  Its
   default is NSSplitViewControllerAutomaticDimension (-FLT_MAX), matching
   AppKit. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSSplitViewController *svc = AUTORELEASE([[NSSplitViewController alloc] init]);

  PASS(NSSplitViewControllerAutomaticDimension == -FLT_MAX,
    "the automatic dimension constant is -FLT_MAX");
  PASS([svc minimumThicknessForInlineSidebars]
       == NSSplitViewControllerAutomaticDimension,
    "the default minimum inline sidebar thickness is the automatic dimension");

  [svc setMinimumThicknessForInlineSidebars: 120.0];
  PASS([svc minimumThicknessForInlineSidebars] == 120.0,
    "the minimum inline sidebar thickness round-trips");
  [svc setMinimumThicknessForInlineSidebars: 44.5];
  PASS([svc minimumThicknessForInlineSidebars] == 44.5,
    "the minimum inline sidebar thickness round-trips to another value");

  DESTROY(arp);
  return 0;
}
