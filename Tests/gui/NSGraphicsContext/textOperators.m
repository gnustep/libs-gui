/* The PostScript text operators draw the text they are given.  DPSshow: is
 * public through DPSOperators.h and PSOperators.h, so an application can call
 * it directly, and it must paint the string in the colour that is set rather
 * than any stand-in mark.  Drawn offscreen and read back, so this runs against
 * whichever backend is installed.
 */
#include "Testing.h"
#include "../GSDrawTest.h"

#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>

int
main(int argc, char **argv)
{
  START_SET("NSGraphicsContext textOperators")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  if (NO == GSCanDrawOffscreen())
    {
      SKIP("the installed backend does not draw offscreen")
    }

  {
    int		 w = 60, h = 40;
    NSImage	*img;
    NSBitmapImageRep *rep;
    NSGraphicsContext *ctxt;
    int		 x, y, dark = 0, green = 0;

    img = GSDrawBegin(w, h);
    [[NSColor colorWithDeviceRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0] set];
    NSRectFill(NSMakeRect(0, 0, w, h));

    ctxt = GSCurrentContext();
    [[NSFont systemFontOfSize: 14] set];
    [[NSColor blackColor] set];
    [ctxt DPSmoveto: 4 : 14];
    [ctxt DPSshow: "Hi"];

    rep = GSDrawEnd(img, w, h);

    for (y = 0; y < h; y++)
      for (x = 0; x < w; x++)
        {
          NSUInteger px[5];

          [rep getPixel: px atX: x y: y];
          if (px[0] < 100 && px[1] < 100 && px[2] < 100)
            {
              dark++;
            }
          /* A mark in a colour that was never set.  Only a saturated green
           * counts: a backend that antialiases text against the subpixels
           * leaves mild colour fringes behind, which are not a mark. */
          if (px[1] > 150 && px[0] < 100 && px[2] < 100)
            {
              green++;
            }
        }

    PASS(rep != nil && dark > 0,
      "the text operator paints in the colour that was set");
    PASS(rep != nil && dark < w * h,
      "the text operator does not cover the whole drawing");
    PASS(rep != nil && green == 0,
      "the text operator paints no mark in a colour that was never set");
  }

  END_SET("NSGraphicsContext textOperators")

  return 0;
}
