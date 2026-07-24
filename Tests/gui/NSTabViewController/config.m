#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSTabViewController.h>

/* NSTabViewController state: the tab style, transition options and title
   propagation flag round-trip.  These are plain properties that do not need a
   window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSTabViewController *tc = AUTORELEASE([[NSTabViewController alloc] init]);

  PASS([tc tabStyle] == NSTabViewControllerTabStyleSegmentedControlOnTop,
    "the default tab style is a segmented control on top");

  [tc setTabStyle: NSTabViewControllerTabStyleToolbar];
  PASS([tc tabStyle] == NSTabViewControllerTabStyleToolbar,
    "the tab style round-trips");
  [tc setTabStyle: NSTabViewControllerTabStyleSegmentedControlOnBottom];
  PASS([tc tabStyle] == NSTabViewControllerTabStyleSegmentedControlOnBottom,
    "the tab style round-trips to a segmented control on the bottom");

  [tc setTransitionOptions: NSViewControllerTransitionCrossfade];
  PASS([tc transitionOptions] == NSViewControllerTransitionCrossfade,
    "the transition options round-trip");
  [tc setTransitionOptions: NSViewControllerTransitionNone];
  PASS([tc transitionOptions] == NSViewControllerTransitionNone,
    "the transition options round-trip to none");

  [tc setCanPropagateSelectedChildViewControllerTitle: YES];
  PASS([tc canPropagateSelectedChildViewControllerTitle] == YES,
    "the title propagation flag round-trips to YES");
  [tc setCanPropagateSelectedChildViewControllerTitle: NO];
  PASS([tc canPropagateSelectedChildViewControllerTitle] == NO,
    "the title propagation flag round-trips to NO");

  DESTROY(arp);
  return 0;
}
