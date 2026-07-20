/* Setting state on a stack view that has no arranged subviews must not raise.
   The internal layout pass indexed the first subview of a possibly empty
   array; every setter routes through it, so on an empty stack view with the
   default (zero) spacing they each raised NSRangeException. These exercise
   that path and check the values round-trip. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSStackView.h>
#include <AppKit/NSLayoutConstraint.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSStackView *sv;

  START_SET("NSStackView emptyMutation")

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

      [sv setOrientation: NSUserInterfaceLayoutOrientationVertical];
      pass([sv orientation] == NSUserInterfaceLayoutOrientationVertical,
           "an empty stack view accepts setOrientation:");
      [sv setSpacing: 12.0];
      pass([sv spacing] == 12.0, "an empty stack view accepts setSpacing:");
      [sv setDistribution: NSStackViewDistributionFillEqually];
      pass([sv distribution] == NSStackViewDistributionFillEqually,
           "an empty stack view accepts setDistribution:");
      [sv setAlignment: NSLayoutAttributeCenterX];
      pass([sv alignment] == NSLayoutAttributeCenterX,
           "an empty stack view accepts setAlignment:");
      [sv setEdgeInsets: NSEdgeInsetsMake(1, 2, 3, 4)];
      {
        NSEdgeInsets e = [sv edgeInsets];
        pass(e.top == 1 && e.left == 2 && e.bottom == 3 && e.right == 4,
             "an empty stack view accepts setEdgeInsets:");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSStackView emptyMutation")

  DESTROY(arp);
  return 0;
}
