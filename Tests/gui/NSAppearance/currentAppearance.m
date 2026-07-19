/* There is always a current appearance, so that the views and the application
 * asked for their effective appearance before anyone has set one have an
 * appearance to answer with.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSAppearance.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  /* This has to come before anything sets the current appearance. */
  START_SET("before anything sets one")
    NSAppearance	*current;

    current = [NSAppearance currentAppearance];
    PASS(current != nil, "there is a current appearance from the start");
    PASS([[current name] isEqualToString: NSAppearanceNameAqua],
      "the current appearance starts out as aqua");
  END_SET("before anything sets one")

  START_SET("setting one")
    NSAppearance	*dark;

    dark = [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    [NSAppearance setCurrentAppearance: dark];
    PASS([NSAppearance currentAppearance] == dark,
      "the current appearance reads back");
    PASS([[[NSAppearance currentAppearance] name]
      isEqualToString: NSAppearanceNameDarkAqua],
      "the current appearance keeps its name");
  END_SET("setting one")

  DESTROY(arp);
  return 0;
}
