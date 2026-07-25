/* Coverage for NSSplitView subview membership: added subviews are present and
   uncollapsed, the minimum position of the first divider is 0, and
   adjustSubviews runs without error. Every assertion matches AppKit (checked
   on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSSplitView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSplitView *sv;
  NSView *a, *b;

  START_SET("NSSplitView structure")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      sv = AUTORELEASE([[NSSplitView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);
      a = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 40)]);
      b = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 40)]);
      [sv addSubview: a];
      [sv addSubview: b];
      [sv adjustSubviews];

      PASS([[sv subviews] count] == 2, "two added subviews are present");
      PASS([sv isSubviewCollapsed: a] == NO,
           "an added subview is not collapsed");
      PASS([sv isSubviewCollapsed: b] == NO,
           "the second added subview is not collapsed");
      PASS([sv minPossiblePositionOfDividerAtIndex: 0] == 0,
           "the minimum position of the first divider is 0");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSplitView structure")

  DESTROY(arp);
  return 0;
}
