/* Interaction coverage for NSSwitch: a switch is enabled by default (checked
   against AppKit), and a click - delivered with -performClick: - toggles its
   state and sends the target/action, while a disabled switch ignores the
   click.  The switch uses the theme and font backend, so the set is skipped
   when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSwitch.h>

@interface SwitchTarget : NSObject
{
@public
  int count;
}
- (void) toggled: (id)sender;
@end

@implementation SwitchTarget
- (void) toggled: (id)sender
{
  count++;
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSwitch *sw;
  SwitchTarget *t;

  START_SET("NSSwitch interaction")

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

  NS_DURING
    {
      t = AUTORELEASE([[SwitchTarget alloc] init]);
      sw = AUTORELEASE([[NSSwitch alloc]
        initWithFrame: NSMakeRect(0, 0, 40, 24)]);
      [sw setTarget: t];
      [sw setAction: @selector(toggled:)];

      PASS([sw isEnabled] == YES, "a switch is enabled by default");

      /* A click turns the switch on and sends the action. */
      [sw performClick: nil];
      PASS([sw state] == NSControlStateValueOn && t->count == 1,
        "clicking an off switch turns it on and sends the action");

      /* Clicking again turns it off and sends the action again. */
      [sw performClick: nil];
      PASS([sw state] == NSControlStateValueOff && t->count == 2,
        "clicking an on switch turns it off and sends the action again");

      /* A disabled switch ignores the click. */
      [sw setEnabled: NO];
      [sw performClick: nil];
      PASS([sw state] == NSControlStateValueOff && t->count == 2,
        "a disabled switch ignores the click");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSSwitch interaction")

  DESTROY(arp);
  return 0;
}
