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
#include <AppKit/NSFontManager.h>

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv, char **env)
{
  GSInitializeProcess(argc, argv, env);
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
      NSArray *available = [[NSFontManager sharedFontManager] availableFonts];
      NSString *fontName = [available count] > 0
        ? [available objectAtIndex: 0] : nil;
      NSFont *h = fontName != nil
        ? [NSFont fontWithName: fontName size: 24.0] : nil;
      const CGFloat *m;

      if (fontName == nil || h == nil)
        {
          SKIP("No installed font is available to test named font creation")
        }
      else
        {
          PASS(h != nil, "fontWithName:size: returns a font");
          PASS([[h fontName] isEqualToString: fontName],
            "the font keeps the requested name");
          PASS(CLOSE([h pointSize], 24.0), "the font has the requested point size");

          m = [h matrix];
          PASS(CLOSE(m[0], 24.0) && CLOSE(m[3], 24.0),
            "the matrix diagonal is the point size");
          PASS(CLOSE(m[1], 0.0) && CLOSE(m[2], 0.0)
            && CLOSE(m[4], 0.0) && CLOSE(m[5], 0.0),
            "the matrix off-diagonal and translation are zero");

          PASS(CLOSE([[h fontDescriptor] pointSize], 24.0),
            "the font descriptor reports the point size");

          {
            const CGFloat wanted[6] = {30, 0, 0, 30, 0, 0};
            NSFont *hm = [NSFont fontWithName: fontName matrix: wanted];

            PASS(hm != nil, "fontWithName:matrix: returns a font");
            if (hm != nil)
              {
                PASS(CLOSE([hm pointSize], 30.0),
                  "the point size comes from the matrix diagonal");
                m = [hm matrix];
                PASS(CLOSE(m[0], 30.0) && CLOSE(m[3], 30.0),
                  "the requested matrix round-trips");
              }
          }

          {
            NSFont *f = [NSFont fontWithName: fontName size: 12.0];

            PASS(f != nil, "an installed font name resolves");
            PASS([[f fontName] isEqualToString: fontName],
              "the installed font name round-trips");
            PASS(CLOSE([f pointSize], 12.0),
              "the installed font has the requested size");
          }
        }
    }
  NS_HANDLER
    SKIP("No font backend available to build fonts")
  NS_ENDHANDLER

  END_SET("NSFont creation")
  DESTROY(arp);
  return 0;
}
