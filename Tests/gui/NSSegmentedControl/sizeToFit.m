/* NSSegmentedControl -sizeToFit computes a size that fits its segments instead
   of collapsing to nearly zero: the width grows with the number of segments and
   the length of their labels, an explicit per-segment width is included, and the
   height is positive.  Exact metrics are font and theme dependent, so the test
   checks that the fitted size accommodates the content rather than exact pixels.
   The control uses the theme and font backend, so the set is skipped when the
   backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSegmentedControl.h>

static NSSegmentedControl *
control(NSInteger count)
{
  NSSegmentedControl *sc = AUTORELEASE([[NSSegmentedControl alloc]
    initWithFrame: NSMakeRect(0, 0, 10, 24)]);
  [sc setSegmentCount: count];
  return sc;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSegmentedControl *three;
  NSSegmentedControl *one;
  NSSegmentedControl *longLabels;
  NSSegmentedControl *explicit;
  CGFloat wThree, wOne;

  START_SET("NSSegmentedControl sizeToFit")

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
      three = control(3);
      [three setLabel: @"One" forSegment: 0];
      [three setLabel: @"Two" forSegment: 1];
      [three setLabel: @"Three" forSegment: 2];
      [three sizeToFit];
      wThree = [three frame].size.width;
      PASS(wThree > 30.0,
           "sizeToFit fits three labelled segments instead of collapsing");
      PASS([three frame].size.height > 0.0, "sizeToFit gives a positive height");

      one = control(1);
      [one setLabel: @"One" forSegment: 0];
      [one sizeToFit];
      wOne = [one frame].size.width;
      PASS(wThree > wOne, "more segments need more width");

      longLabels = control(3);
      [longLabels setLabel: @"Onnnnnnnnnnne" forSegment: 0];
      [longLabels setLabel: @"Twwwwwwwwwwwo" forSegment: 1];
      [longLabels setLabel: @"Threeeeeeeeee" forSegment: 2];
      [longLabels sizeToFit];
      PASS([longLabels frame].size.width > wThree, "longer labels need more width");

      explicit = control(1);
      [explicit setLabel: @"A" forSegment: 0];
      [explicit setWidth: 120.0 forSegment: 0];
      [explicit sizeToFit];
      PASS([explicit frame].size.width >= 120.0,
           "an explicit segment width is included in the fitted size");
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

  END_SET("NSSegmentedControl sizeToFit")

  DESTROY(arp);
  return 0;
}
