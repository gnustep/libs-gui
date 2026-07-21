/* Coverage for NSAppearance: the values of the appearance name constants, the
 * appearance returned by appearanceNamed:, and the current appearance.  Every
 * assertion here matches AppKit (verified on a macOS runner) and passes on
 * unmodified GNUstep.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSAppearance.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the appearance names")
    PASS([NSAppearanceNameAqua isEqualToString: @"NSAppearanceNameAqua"],
      "the aqua appearance name is the documented one");
    PASS([NSAppearanceNameDarkAqua isEqualToString: @"NSAppearanceNameDarkAqua"],
      "the dark aqua appearance name is the documented one");
    PASS([NSAppearanceNameVibrantLight
      isEqualToString: @"NSAppearanceNameVibrantLight"],
      "the vibrant light appearance name is the documented one");
    PASS([NSAppearanceNameVibrantDark
      isEqualToString: @"NSAppearanceNameVibrantDark"],
      "the vibrant dark appearance name is the documented one");
  END_SET("the appearance names")

  START_SET("appearanceNamed:")
    NSAppearance	*aqua;
    NSAppearance	*dark;

    aqua = [NSAppearance appearanceNamed: NSAppearanceNameAqua];
    PASS(aqua != nil, "the aqua appearance is created");
    PASS([[aqua name] isEqualToString: NSAppearanceNameAqua],
      "the aqua appearance keeps its name");
    PASS([aqua allowsVibrancy] == NO, "the aqua appearance is not vibrant");

    dark = [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    PASS(dark != nil, "the dark aqua appearance is created");
    PASS([[dark name] isEqualToString: NSAppearanceNameDarkAqua],
      "the dark aqua appearance keeps its name");
    PASS([dark allowsVibrancy] == NO,
      "the dark aqua appearance is not vibrant");
  END_SET("appearanceNamed:")

  START_SET("an unknown appearance name")
    NSAppearance	*unknown;

    /* AppKit hands back an appearance for a name it does not know, rather
     * than nil, and that appearance is not vibrant. */
    unknown = [NSAppearance appearanceNamed: @"NotAnAppearance"];
    PASS(unknown != nil, "an unknown name still returns an appearance");
    PASS([[unknown name] isEqualToString: @"NotAnAppearance"],
      "an unknown appearance keeps the name it was asked for");
    PASS([unknown allowsVibrancy] == NO,
      "an unknown appearance is not vibrant");
  END_SET("an unknown appearance name")

  START_SET("the current appearance")
    NSAppearance	*aqua;

    aqua = [NSAppearance appearanceNamed: NSAppearanceNameAqua];
    [NSAppearance setCurrentAppearance: aqua];
    PASS([NSAppearance currentAppearance] == aqua,
      "the current appearance reads back");
  END_SET("the current appearance")

  DESTROY(arp);
  return 0;
}
