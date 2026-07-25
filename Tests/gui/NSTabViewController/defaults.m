#import "Testing.h"
#import <AppKit/NSViewController.h>
#import <AppKit/NSTabViewController.h>

/* A fresh NSTabViewController allows user interaction during transitions and
   propagates the selected child's title by default.  These are plain
   properties that do not need a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSTabViewController *tc = AUTORELEASE([[NSTabViewController alloc] init]);

  PASS([tc transitionOptions] == NSViewControllerTransitionAllowUserInteraction,
    "the default transition options allow user interaction");
  PASS([tc canPropagateSelectedChildViewControllerTitle] == YES,
    "a fresh controller propagates the selected child's title");

  DESTROY(arp);
  return 0;
}
