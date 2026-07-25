/* Coverage for -convertFont:toSize:: the returned font has the requested size
 * and keeps the original name, and converting to the same size returns the
 * original font.  Building fonts needs the backend, so the test is guarded and
 * skips cleanly when none is present.
 *
 * The trait, weight, family and face conversions resolve against the physical
 * fonts the backend provides, so their results are environment-specific and are
 * not asserted here.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("convertFont:toSize:")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("It looks like the GNUstep backend is not available")
  NS_ENDHANDLER

  NS_DURING
    {
      NSFontManager *fm = [NSFontManager sharedFontManager];
      NSFont *h24 = [NSFont fontWithName: @"Helvetica" size: 24.0];
      NSFont *h12 = [fm convertFont: h24 toSize: 12.0];
      NSFont *same = [fm convertFont: h24 toSize: 24.0];

      PASS(h12 != nil && EQ([h12 pointSize], 12.0),
        "the converted font has the requested size");
      PASS([[h12 fontName] isEqualToString: [h24 fontName]],
        "the converted font keeps the original name");
      PASS(same == h24,
        "converting to the current size returns the original font");
    }
  NS_HANDLER
    SKIP("No font backend available to convert fonts")
  NS_ENDHANDLER

  END_SET("convertFont:toSize:")
  DESTROY(arp);
  return 0;
}
