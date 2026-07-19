/* appearanceNamed: does not start with "alloc", "new", "copy" or
 * "mutableCopy", so the caller does not own what it returns: the appearance has
 * to be autoreleased, or every call leaks one.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSAppearance.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("appearanceNamed: ownership")
    NSAutoreleasePool	*pool;
    NSAppearance	*appearance;

    pool = [NSAutoreleasePool new];
    appearance = [NSAppearance appearanceNamed: NSAppearanceNameAqua];
    RETAIN(appearance);
    [pool release];

    /* The pool held the only claim the method left behind, so draining it
     * leaves just the retain taken above. */
    PASS([appearance retainCount] == 1,
      "appearanceNamed: returns an appearance the caller does not own");
    PASS([[appearance name] isEqualToString: NSAppearanceNameAqua],
      "the appearance is still usable after the pool it was made in");
    RELEASE(appearance);
  END_SET("appearanceNamed: ownership")

  START_SET("appearanceNamed: still works")
    NSAppearance	*appearance;

    appearance = [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    PASS(appearance != nil, "appearanceNamed: returns an appearance");
    PASS([[appearance name] isEqualToString: NSAppearanceNameDarkAqua],
      "the appearance keeps its name");
  END_SET("appearanceNamed: still works")

  DESTROY(arp);
  return 0;
}
