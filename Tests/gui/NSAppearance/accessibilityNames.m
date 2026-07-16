/* The accessibility appearance names are the strings AppKit uses, which do not
 * spell out "HighContrast" the way the constants naming them do.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSAppearance.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the accessibility appearance names")
    PASS([NSAppearanceNameAccessibilityHighContrastAqua
      isEqualToString: @"NSAppearanceNameAccessibilityAqua"],
      "the high contrast aqua name is the one AppKit uses");
    PASS([NSAppearanceNameAccessibilityHighContrastDarkAqua
      isEqualToString: @"NSAppearanceNameAccessibilityDarkAqua"],
      "the high contrast dark aqua name is the one AppKit uses");
    PASS([NSAppearanceNameAccessibilityHighContrastVibrantLight
      isEqualToString: @"NSAppearanceNameAccessibilityVibrantLight"],
      "the high contrast vibrant light name is the one AppKit uses");
    PASS([NSAppearanceNameAccessibilityHighContrastVibrantDark
      isEqualToString: @"NSAppearanceNameAccessibilityVibrantDark"],
      "the high contrast vibrant dark name is the one AppKit uses");
  END_SET("the accessibility appearance names")

  START_SET("the other appearance names are unchanged")
    PASS([NSAppearanceNameAqua isEqualToString: @"NSAppearanceNameAqua"],
      "the aqua name is unchanged");
    PASS([NSAppearanceNameVibrantLight
      isEqualToString: @"NSAppearanceNameVibrantLight"],
      "the vibrant light name is unchanged");
  END_SET("the other appearance names are unchanged")

  DESTROY(arp);
  return 0;
}
