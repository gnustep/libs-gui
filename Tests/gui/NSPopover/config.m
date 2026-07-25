#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSPopover.h>

/* NSPopover state: its behaviour, appearance, content size, positioning rect
   and shown flag, and their round-trips.  These are plain properties that do
   not need a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSPopover *p = AUTORELEASE([[NSPopover alloc] init]);

  /* defaults */
  PASS([p behavior] == NSPopoverBehaviorApplicationDefined,
    "the default behavior is application defined");
  PASS([p appearance] == NSPopoverAppearanceMinimal,
    "the default appearance is minimal");
  PASS(NSEqualSizes([p contentSize], NSZeroSize),
    "the content size starts at zero");
  PASS([p isShown] == NO, "a new popover is not shown");
  PASS(NSEqualRects([p positioningRect], NSZeroRect),
    "the positioning rect starts at zero");
  PASS([p contentViewController] == nil,
    "a new popover has no content view controller");

  /* round-trips */
  [p setAnimates: NO];
  PASS([p animates] == NO, "animates round-trips to NO");
  [p setAnimates: YES];
  PASS([p animates] == YES, "animates round-trips to YES");

  [p setBehavior: NSPopoverBehaviorTransient];
  PASS([p behavior] == NSPopoverBehaviorTransient,
    "the behavior round-trips to transient");
  [p setBehavior: NSPopoverBehaviorSemitransient];
  PASS([p behavior] == NSPopoverBehaviorSemitransient,
    "the behavior round-trips to semitransient");

  [p setAppearance: NSPopoverAppearanceHUD];
  PASS([p appearance] == NSPopoverAppearanceHUD,
    "the appearance round-trips");

  [p setContentSize: NSMakeSize(200, 150)];
  PASS(NSEqualSizes([p contentSize], NSMakeSize(200, 150)),
    "the content size round-trips");

  [p setPositioningRect: NSMakeRect(1, 2, 3, 4)];
  PASS(NSEqualRects([p positioningRect], NSMakeRect(1, 2, 3, 4)),
    "the positioning rect round-trips");

  DESTROY(arp);
  return 0;
}
