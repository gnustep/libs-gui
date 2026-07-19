/* bestMatchFromAppearancesWithNames: picks the appearance's own name when the
 * list offers it, otherwise the appearance it is a variant of, otherwise
 * nothing.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSAppearance.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("an exact name wins")
    NSAppearance	*aqua;
    NSAppearance	*dark;
    NSArray		*aquaFirst;
    NSArray		*darkFirst;

    aqua = [NSAppearance appearanceNamed: NSAppearanceNameAqua];
    dark = [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    aquaFirst = [NSArray arrayWithObjects: NSAppearanceNameAqua,
      NSAppearanceNameDarkAqua, nil];
    darkFirst = [NSArray arrayWithObjects: NSAppearanceNameDarkAqua,
      NSAppearanceNameAqua, nil];

    PASS([[aqua bestMatchFromAppearancesWithNames: aquaFirst]
      isEqualToString: NSAppearanceNameAqua],
      "the aqua appearance matches aqua");
    PASS([[aqua bestMatchFromAppearancesWithNames: darkFirst]
      isEqualToString: NSAppearanceNameAqua],
      "the order of the names does not decide the match");
    PASS([[dark bestMatchFromAppearancesWithNames: aquaFirst]
      isEqualToString: NSAppearanceNameDarkAqua],
      "the dark aqua appearance matches dark aqua");
  END_SET("an exact name wins")

  START_SET("a vibrant appearance falls back to the one it varies")
    NSAppearance	*light;
    NSAppearance	*dark;
    NSArray		*both;
    NSArray		*onlyAqua;
    NSArray		*onlyDark;

    light = [NSAppearance appearanceNamed: NSAppearanceNameVibrantLight];
    dark = [NSAppearance appearanceNamed: NSAppearanceNameVibrantDark];
    both = [NSArray arrayWithObjects: NSAppearanceNameAqua,
      NSAppearanceNameDarkAqua, nil];
    onlyAqua = [NSArray arrayWithObject: NSAppearanceNameAqua];
    onlyDark = [NSArray arrayWithObject: NSAppearanceNameDarkAqua];

    PASS([[light bestMatchFromAppearancesWithNames: both]
      isEqualToString: NSAppearanceNameAqua],
      "the vibrant light appearance falls back to aqua");
    PASS([[dark bestMatchFromAppearancesWithNames: both]
      isEqualToString: NSAppearanceNameDarkAqua],
      "the vibrant dark appearance falls back to dark aqua");
    PASS([[light bestMatchFromAppearancesWithNames: onlyAqua]
      isEqualToString: NSAppearanceNameAqua],
      "the vibrant light appearance matches a list of just aqua");
    PASS([dark bestMatchFromAppearancesWithNames: onlyAqua] == nil,
      "the vibrant dark appearance does not match aqua");
    PASS([light bestMatchFromAppearancesWithNames: onlyDark] == nil,
      "the vibrant light appearance does not match dark aqua");
  END_SET("a vibrant appearance falls back to the one it varies")

  START_SET("no match")
    NSAppearance	*aqua;
    NSAppearance	*light;

    aqua = [NSAppearance appearanceNamed: NSAppearanceNameAqua];
    light = [NSAppearance appearanceNamed: NSAppearanceNameVibrantLight];

    PASS([aqua bestMatchFromAppearancesWithNames:
      [NSArray arrayWithObject: NSAppearanceNameDarkAqua]] == nil,
      "the aqua appearance does not match dark aqua");
    PASS([aqua bestMatchFromAppearancesWithNames:
      [NSArray arrayWithObject: NSAppearanceNameVibrantLight]] == nil,
      "a plain appearance does not match a vibrant one");
    PASS([aqua bestMatchFromAppearancesWithNames: [NSArray array]] == nil,
      "an empty list matches nothing");
    PASS([aqua bestMatchFromAppearancesWithNames:
      [NSArray arrayWithObject: @"Bogus"]] == nil,
      "a list of names that are not appearances matches nothing");
    PASS([light bestMatchFromAppearancesWithNames:
      [NSArray arrayWithObject: NSAppearanceNameVibrantDark]] == nil,
      "one vibrant appearance does not match the other");
  END_SET("no match")

  DESTROY(arp);
  return 0;
}
