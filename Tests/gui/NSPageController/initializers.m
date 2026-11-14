/* A page controller made by any initializer has the state -init gives it:
 * an empty arranged objects array, the stack history transition and a
 * selected index of zero.  NSViewController's designated initializer is
 * -initWithNibName:bundle:, and nib loading uses -initWithCoder:, so a
 * controller made either way must not be left without its arranged objects.
 */
#include "Testing.h"

#include <Foundation/NSArchiver.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyedArchiver.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSPageController.h>

static BOOL
hasInitState(NSPageController *controller)
{
  return controller != nil
    && [controller arrangedObjects] != nil
    && [[controller arrangedObjects] count] == 0
    && [controller transitionStyle]
      == NSPageControllerTransitionStyleStackHistory
    && [controller selectedIndex] == 0
    && [controller selectedViewController] == nil;
}

int
main(int argc, char **argv)
{
  START_SET("NSPageController initializers")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSPageController	*controller;
    NSPageController	*decoded;
    NSArray		*objects;
    NSData		*data;

    controller = AUTORELEASE([[NSPageController alloc]
      initWithNibName: nil bundle: nil]);
    PASS(hasInitState(controller),
      "-initWithNibName:bundle: sets up the same state as -init");

    objects = [NSArray arrayWithObjects: @"a", @"b", nil];
    [controller setArrangedObjects: objects];
    PASS([[controller arrangedObjects] isEqualToArray: objects],
      "a controller made with -initWithNibName:bundle: keeps arranged objects");
    PASS_RUNS([controller setSelectedIndex: 1],
      "a controller made with -initWithNibName:bundle: selects an object");
    PASS([controller selectedIndex] == 1,
      "the selection reads back");

    controller = AUTORELEASE([[NSPageController alloc] init]);
    data = [NSKeyedArchiver archivedDataWithRootObject: controller];
    decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    PASS(hasInitState(decoded),
      "a keyed-unarchived controller has its arranged objects array");
  }

  END_SET("NSPageController initializers")

  return 0;
}
