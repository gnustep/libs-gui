/* Coverage for NSPageController: the transition style enumeration, the init
 * defaults and the transition style, delegate and arranged objects
 * round-trips.  Every assertion here matches AppKit (verified on a macOS
 * runner) and passes on unmodified GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSPageController.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSPageController basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSPageController	*controller;
    NSArray		*objects;
    id			delegate;

    /* the enumeration */
    PASS(NSPageControllerTransitionStyleStackHistory == 0
      && NSPageControllerTransitionStyleStackBook == 1
      && NSPageControllerTransitionStyleHorizontalStrip == 2,
      "the transition styles have their AppKit values");

    /* init defaults */
    controller = AUTORELEASE([[NSPageController alloc] init]);
    PASS(controller != nil, "a page controller is created");
    PASS([controller transitionStyle]
      == NSPageControllerTransitionStyleStackHistory,
      "a new controller uses the stack history transition");
    PASS([controller delegate] == nil, "a new controller has no delegate");
    PASS([controller arrangedObjects] != nil,
      "a new controller has an arranged objects array");
    PASS([[controller arrangedObjects] count] == 0,
      "a new controller has no arranged objects");
    PASS([controller selectedIndex] == 0,
      "a new controller has a selected index of zero");
    PASS([controller selectedViewController] == nil,
      "a new controller has no selected view controller");

    /* setter round-trips */
    [controller setTransitionStyle:
      NSPageControllerTransitionStyleHorizontalStrip];
    PASS([controller transitionStyle]
      == NSPageControllerTransitionStyleHorizontalStrip,
      "the transition style round-trips");

    delegate = AUTORELEASE([[NSObject alloc] init]);
    [controller setDelegate: delegate];
    PASS([controller delegate] == delegate, "the delegate reads back");

    objects = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    [controller setArrangedObjects: objects];
    PASS([[controller arrangedObjects] count] == 3,
      "the arranged objects are set");
    PASS([[controller arrangedObjects] isEqualToArray: objects],
      "the arranged objects read back");
    PASS([controller selectedIndex] == 0,
      "arranging objects leaves the selected index at zero");
  }

  END_SET("NSPageController basic")

  DESTROY(arp);
  return 0;
}
