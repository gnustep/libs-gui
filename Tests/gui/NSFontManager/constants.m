/* Coverage for the NSFontManager trait mask and font action constants.  These
 * are plain enumeration values and need no font backend, so the test runs
 * anywhere.  The expected values are those used by AppKit.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSFontManager.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("trait mask values")
    PASS(NSItalicFontMask == 1, "NSItalicFontMask is 1");
    PASS(NSBoldFontMask == 2, "NSBoldFontMask is 2");
    PASS(NSUnboldFontMask == 4, "NSUnboldFontMask is 4");
    PASS(NSNonStandardCharacterSetFontMask == 8,
      "NSNonStandardCharacterSetFontMask is 8");
    PASS(NSNarrowFontMask == 16, "NSNarrowFontMask is 16");
    PASS(NSExpandedFontMask == 32, "NSExpandedFontMask is 32");
    PASS(NSCondensedFontMask == 64, "NSCondensedFontMask is 64");
    PASS(NSSmallCapsFontMask == 128, "NSSmallCapsFontMask is 128");
    PASS(NSPosterFontMask == 256, "NSPosterFontMask is 256");
    PASS(NSCompressedFontMask == 512, "NSCompressedFontMask is 512");
    PASS(NSFixedPitchFontMask == 1024, "NSFixedPitchFontMask is 1024");
    PASS(NSUnitalicFontMask == (1 << 24), "NSUnitalicFontMask is 1 << 24");
  END_SET("trait mask values")

  /* Only the first three font action values match AppKit; the ordering of the
   * remaining values differs between the two, so they are compared by symbol
   * elsewhere rather than pinned to a number here.
   */
  START_SET("font action values")
    PASS(NSNoFontChangeAction == 0, "NSNoFontChangeAction is 0");
    PASS(NSViaPanelFontAction == 1, "NSViaPanelFontAction is 1");
    PASS(NSAddTraitFontAction == 2, "NSAddTraitFontAction is 2");
  END_SET("font action values")

  DESTROY(arp);
  return 0;
}
