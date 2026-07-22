/* Coverage for the NSStackView read-only state that does not depend on the
   layout pass: the default orientation, delegate, arranged-subview list and
   the deprecated hasEqualSpacing flag. Every assertion matches AppKit (checked
   on a macOS runner) and passes on unmodified GNUstep. The scalar setter
   round-trips and the remaining AppKit defaults are exercised by the fix
   branches that make them work. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSStackView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSStackView *sv;

  START_SET("NSStackView state")

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

      PASS([sv orientation] == NSUserInterfaceLayoutOrientationHorizontal,
           "a stack view is horizontal by default");
      PASS([sv delegate] == nil, "the default delegate is nil");
      PASS([[sv arrangedSubviews] count] == 0,
           "a new stack view has no arranged subviews");
      PASS([sv hasEqualSpacing] == NO, "hasEqualSpacing is NO by default");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSStackView state")

  DESTROY(arp);
  return 0;
}
