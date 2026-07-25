/* A new NSStackView has AppKit's state defaults: gravity-areas distribution,
   a spacing of 8, hidden-view detachment on, and centre-Y alignment (checked
   against AppKit on a macOS runner). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSStackView.h>
#include <AppKit/NSLayoutConstraint.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSStackView *sv;

  START_SET("NSStackView defaults")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      sv = AUTORELEASE([[NSStackView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);

      PASS([sv distribution] == NSStackViewDistributionGravityAreas,
           "the default distribution is gravity areas");
      PASS([sv spacing] == 8.0, "the default spacing is 8");
      PASS([sv detachesHiddenViews] == YES,
           "hidden views are detached by default");
      PASS([sv alignment] == NSLayoutAttributeCenterY,
           "the default alignment is centre-Y");
      PASS([sv arrangedSubviews] != nil
           && [[sv arrangedSubviews] count] == 0,
           "a frame-initialised stack view has no arranged subviews");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSStackView defaults")

  DESTROY(arp);
  return 0;
}
