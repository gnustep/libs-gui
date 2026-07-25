/* Coverage for the NSFont-related global constants: the standard font weight
 * values, the identity font matrix and the NSControlGlyph marker.  These are
 * plain compile-time / linked constants and need no font backend, so the test
 * runs anywhere.  The expected values are those reported by AppKit.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSFont.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.0001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("font weight constants")
    PASS(EQ(NSFontWeightUltraLight, -0.8), "NSFontWeightUltraLight is -0.8");
    PASS(EQ(NSFontWeightThin, -0.6), "NSFontWeightThin is -0.6");
    PASS(EQ(NSFontWeightLight, -0.4), "NSFontWeightLight is -0.4");
    PASS(EQ(NSFontWeightRegular, 0.0), "NSFontWeightRegular is 0");
    PASS(EQ(NSFontWeightMedium, 0.23), "NSFontWeightMedium is 0.23");
    PASS(EQ(NSFontWeightSemibold, 0.3), "NSFontWeightSemibold is 0.3");
    PASS(EQ(NSFontWeightBold, 0.4), "NSFontWeightBold is 0.4");
    PASS(EQ(NSFontWeightHeavy, 0.56), "NSFontWeightHeavy is 0.56");
    PASS(EQ(NSFontWeightBlack, 0.62), "NSFontWeightBlack is 0.62");

    PASS(NSFontWeightUltraLight < NSFontWeightRegular
      && NSFontWeightRegular < NSFontWeightBold
      && NSFontWeightBold < NSFontWeightBlack,
      "the weight constants are monotonically ordered");
  END_SET("font weight constants")

  START_SET("identity matrix")
    PASS(EQ(NSFontIdentityMatrix[0], 1.0), "identity matrix a is 1");
    PASS(EQ(NSFontIdentityMatrix[1], 0.0), "identity matrix b is 0");
    PASS(EQ(NSFontIdentityMatrix[2], 0.0), "identity matrix c is 0");
    PASS(EQ(NSFontIdentityMatrix[3], 1.0), "identity matrix d is 1");
    PASS(EQ(NSFontIdentityMatrix[4], 0.0), "identity matrix tx is 0");
    PASS(EQ(NSFontIdentityMatrix[5], 0.0), "identity matrix ty is 0");
  END_SET("identity matrix")

  START_SET("glyph markers")
    PASS(NSControlGlyph == 0x00ffffff, "NSControlGlyph is 0x00ffffff");
    PASS(NSNullGlyph == 0x0, "NSNullGlyph is 0");
  END_SET("glyph markers")

  START_SET("rendering mode values")
    PASS(NSFontDefaultRenderingMode == 0, "NSFontDefaultRenderingMode is 0");
    PASS(NSFontAntialiasedRenderingMode == 1,
      "NSFontAntialiasedRenderingMode is 1");
    PASS(NSFontIntegerAdvancementsRenderingMode == 2,
      "NSFontIntegerAdvancementsRenderingMode is 2");
    PASS(NSFontAntialiasedIntegerAdvancementsRenderingMode == 3,
      "NSFontAntialiasedIntegerAdvancementsRenderingMode is 3");
  END_SET("rendering mode values")

  DESTROY(arp);
  return 0;
}
