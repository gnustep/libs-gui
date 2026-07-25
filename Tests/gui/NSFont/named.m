/* Coverage for creating a font by name and by matrix: the requested name,
 * point size and text matrix must round-trip on the returned font.  Building a
 * font resolves it against the font backend, so the whole test is guarded and
 * skips cleanly where no backend is available.
 *
 * The resolved family name, display name, fixed-pitch flag and glyph metrics
 * depend on which physical font the backend substitutes for the request, so
 * they are environment-specific and are not asserted here.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontDescriptor.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSFont creation")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("It looks like the GNUstep backend is not available")
  NS_ENDHANDLER

  NS_DURING
    {
      NSFont *h = [NSFont fontWithName: @"Helvetica" size: 24.0];
      const CGFloat *m;

      PASS(h != nil, "fontWithName:size: returns a font");
      PASS([[h fontName] isEqualToString: @"Helvetica"],
        "the font keeps the requested name");
      PASS(EQ([h pointSize], 24.0), "the font has the requested point size");

      m = [h matrix];
      PASS(EQ(m[0], 24.0) && EQ(m[3], 24.0),
        "the matrix diagonal is the point size");
      PASS(EQ(m[1], 0.0) && EQ(m[2], 0.0) && EQ(m[4], 0.0) && EQ(m[5], 0.0),
        "the matrix off-diagonal and translation are zero");

      PASS(EQ([[h fontDescriptor] pointSize], 24.0),
        "the font descriptor reports the point size");
    }

    {
      const CGFloat wanted[6] = {30, 0, 0, 30, 0, 0};
      NSFont *hm = [NSFont fontWithName: @"Helvetica" matrix: wanted];
      const CGFloat *m;

      PASS(hm != nil, "fontWithName:matrix: returns a font");
      PASS(EQ([hm pointSize], 30.0),
        "the point size comes from the matrix diagonal");
      m = [hm matrix];
      PASS(EQ(m[0], 30.0) && EQ(m[3], 30.0),
        "the requested matrix round-trips");
    }

    {
      NSFont *hb = [NSFont fontWithName: @"Helvetica-Bold" size: 12.0];

      PASS(hb != nil, "a styled font name resolves");
      PASS([[hb fontName] isEqualToString: @"Helvetica-Bold"],
        "the styled name round-trips");
      PASS(EQ([hb pointSize], 12.0), "the styled font has the requested size");
    }
  NS_HANDLER
    SKIP("No font backend available to build fonts")
  NS_ENDHANDLER

  END_SET("NSFont creation")
  DESTROY(arp);
  return 0;
}
