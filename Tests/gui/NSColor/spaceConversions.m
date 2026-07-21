/* Tests the NSColor colour space conversions that basic.m does not cover: the
 * conversions to grayscale and to CMYK, and the component counts of the
 * grayscale and CMYK spaces.  These are plain value operations with no window
 * server, so the test runs headlessly.
 */
#include "Testing.h"

#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>

static BOOL
eq(CGFloat a, CGFloat b)
{
  return fabs((double)(a - b)) < 0.001;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  /* An achromatic RGB colour keeps its value when converted to grayscale. */
  {
    NSColor *white = [NSColor colorWithDeviceRed: 1 green: 1 blue: 1 alpha: 1];
    NSColor *black = [NSColor colorWithDeviceRed: 0 green: 0 blue: 0 alpha: 1];
    NSColor *mid = [NSColor colorWithDeviceRed: 0.5 green: 0.5 blue: 0.5 alpha: 1];

    PASS(eq([[white colorUsingColorSpaceName: NSDeviceWhiteColorSpace]
             whiteComponent], 1.0)
      && eq([[black colorUsingColorSpaceName: NSDeviceWhiteColorSpace]
             whiteComponent], 0.0)
      && eq([[mid colorUsingColorSpaceName: NSDeviceWhiteColorSpace]
             whiteComponent], 0.5),
      "an achromatic RGB colour keeps its value in grayscale");
  }

  /* Registration black (a fully saturated CMYK black) converts to black. */
  {
    NSColor *reg = [NSColor colorWithDeviceCyan: 1 magenta: 1 yellow: 1
                                          black: 1 alpha: 1];

    PASS(eq([[reg colorUsingColorSpaceName: NSDeviceWhiteColorSpace]
             whiteComponent], 0.0),
      "CMYK registration black converts to a zero grayscale value");
  }

  /* Grayscale to RGB replicates the white value across the channels. */
  {
    NSColor *g = [NSColor colorWithDeviceWhite: 0.5 alpha: 1];
    NSColor *r = [g colorUsingColorSpaceName: NSDeviceRGBColorSpace];

    PASS(eq([r redComponent], 0.5) && eq([r greenComponent], 0.5)
      && eq([r blueComponent], 0.5),
      "grayscale converts to an equal-component RGB colour");
  }

  /* Alpha survives a colour space conversion. */
  {
    NSColor *c = [NSColor colorWithDeviceRed: 0.2 green: 0.4 blue: 0.6
                                       alpha: 0.5];

    PASS(eq([[c colorUsingColorSpaceName: NSDeviceWhiteColorSpace]
             alphaComponent], 0.5),
      "alpha is preserved across a colour space conversion");
  }

  /* The grayscale and CMYK spaces report their component counts. */
  {
    NSColor *gray = [NSColor colorWithDeviceWhite: 0 alpha: 1];
    NSColor *cmyk = [NSColor colorWithDeviceCyan: 0 magenta: 0 yellow: 0
                                           black: 0 alpha: 1];

    PASS([gray numberOfComponents] == 2 && [cmyk numberOfComponents] == 5,
      "the grayscale and CMYK spaces report two and five components");
  }

  DESTROY(arp);
  return 0;
}
