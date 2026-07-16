/* The vibrant appearances allow vibrancy; the plain ones and a name that is not
 * an appearance at all do not.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSAppearance.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("vibrancy")
    PASS([[NSAppearance appearanceNamed: NSAppearanceNameVibrantLight]
      allowsVibrancy] == YES, "the vibrant light appearance is vibrant");
    PASS([[NSAppearance appearanceNamed: NSAppearanceNameVibrantDark]
      allowsVibrancy] == YES, "the vibrant dark appearance is vibrant");

    PASS([[NSAppearance appearanceNamed: NSAppearanceNameAqua]
      allowsVibrancy] == NO, "the aqua appearance is not vibrant");
    PASS([[NSAppearance appearanceNamed: NSAppearanceNameDarkAqua]
      allowsVibrancy] == NO, "the dark aqua appearance is not vibrant");
    PASS([[NSAppearance appearanceNamed: @"NotAnAppearance"]
      allowsVibrancy] == NO, "an unknown appearance is not vibrant");
  END_SET("vibrancy")

  DESTROY(arp);
  return 0;
}
