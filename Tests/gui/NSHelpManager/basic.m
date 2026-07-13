/* Coverage for NSHelpManager: the shared instance, the context help
 * set/get/remove round-trip, and the context help mode flag.  These are
 * plain object operations and need no backend.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSHelpManager.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("shared instance")
    NSHelpManager	*hm = [NSHelpManager sharedHelpManager];

    PASS(hm != nil, "there is a shared help manager");
    PASS(hm == [NSHelpManager sharedHelpManager],
      "the shared help manager is the same object each time");
  END_SET("shared instance")

  START_SET("context help")
    NSHelpManager	*hm = [NSHelpManager sharedHelpManager];
    id			object = AUTORELEASE([[NSObject alloc] init]);
    NSAttributedString	*help = AUTORELEASE([[NSAttributedString alloc]
      initWithString: @"Help text"]);

    PASS([hm contextHelpForObject: object] == nil,
      "an object with no registered help returns nil");

    [hm setContextHelp: help forObject: object];
    PASS([[hm contextHelpForObject: object] isEqual: help],
      "setContextHelp:forObject: stores the help for the object");

    [hm removeContextHelpForObject: object];
    PASS([hm contextHelpForObject: object] == nil,
      "removeContextHelpForObject: removes the help");
  END_SET("context help")

  START_SET("context help mode")
    PASS([NSHelpManager isContextHelpModeActive] == NO,
      "context help mode is inactive by default");

    [NSHelpManager setContextHelpModeActive: YES];
    PASS([NSHelpManager isContextHelpModeActive] == YES,
      "setContextHelpModeActive: turns the mode on");

    [NSHelpManager setContextHelpModeActive: NO];
    PASS([NSHelpManager isContextHelpModeActive] == NO,
      "setContextHelpModeActive: turns the mode off");
  END_SET("context help mode")

  DESTROY(arp);
  return 0;
}
