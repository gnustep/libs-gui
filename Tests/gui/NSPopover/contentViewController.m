#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSPopover.h>

/* Setting a content view controller that already provides its view assigns it
   without trying to load a nib named after the controller class.  These are
   in-memory properties and do not need a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSPopover *p = AUTORELEASE([[NSPopover alloc] init]);
  NSViewController *vc = AUTORELEASE([[NSViewController alloc] init]);

  [vc setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 80)])];

  [p setContentViewController: vc];
  PASS([p contentViewController] == vc,
    "a content view controller with a view is assigned directly");

  DESTROY(arp);
  return 0;
}
