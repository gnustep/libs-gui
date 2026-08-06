/* Drawing an image with an alpha channel, checked by reading the pixels
 * back: a half-transparent image composites with what is under it, and an
 * opaque one shows its own colour.
 *
 * None of it is particular to one backend, so it runs against whichever one
 * is installed and skips when there is none.  Colours are checked with a
 * small tolerance, because a backend may carry them through fixed-point
 * arithmetic.
 */
#import <Foundation/NSObject.h>
#import "Testing.h"
#import "../GSDrawTest.h"

#import <AppKit/AppKit.h>
#include <stdlib.h>

/* An n x n bitmap filled with one RGBA colour. */
static NSImage *
solidImage(int n, int r, int g, int b, int a)
{
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: n pixelsHigh: n
                bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
               colorSpaceName: NSDeviceRGBColorSpace
                 bitmapFormat: NSAlphaNonpremultipliedBitmapFormat
                  bytesPerRow: n * 4 bitsPerPixel: 32];
  unsigned char *d = [rep bitmapData];
  NSImage *img;
  int i;

  for (i = 0; i < n * n; i++)
    {
      d[i * 4 + 0] = r;
      d[i * 4 + 1] = g;
      d[i * 4 + 2] = b;
      d[i * 4 + 3] = a;
    }
  img = [[NSImage alloc] initWithSize: NSMakeSize(n, n)];
  [img addRepresentation: rep];
  [rep release];
  return AUTORELEASE(img);
}

/* Draw IMG over a solid background of the given gray and read the centre. */
static NSBitmapImageRep *
over(NSImage *img, int bg)
{
  int w = 20, h = 20;
  NSImage *dst = [[NSImage alloc] initWithSize: NSMakeSize(w, h)];
  NSBitmapImageRep *rep;

  [dst lockFocus];
  [[NSColor colorWithDeviceRed: bg / 255.0 green: bg / 255.0 blue: bg / 255.0
                         alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [img drawInRect: NSMakeRect(0, 0, w, h)
         fromRect: NSZeroRect
        operation: NSCompositeSourceOver
         fraction: 1.0];
  [[NSGraphicsContext currentContext] flushGraphics];
  rep = [[NSBitmapImageRep alloc]
          initWithFocusedViewRect: NSMakeRect(0, 0, w, h)];
  [dst unlockFocus];
  [dst release];
  return AUTORELEASE(rep);
}

int
main(int argc, const char **argv)
{
  START_SET("image alpha")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  if (NO == GSCanDrawOffscreen())
    {
      SKIP("the installed backend does not draw offscreen")
    }

  /* a half-transparent gray over black is half of 128 */
  PASS(GSPixelIs(over(solidImage(4, 128, 128, 128, 128), 0), 10, 10, 64, 64, 64),
    "a half-transparent gray image over black composites to a quarter tone");

  /* a half-transparent gray over white keeps half the background */
  PASS(GSPixelIs(over(solidImage(4, 128, 128, 128, 128), 255), 10, 10, 191, 191, 191),
    "a half-transparent gray image over white composites to a light tone");

  /* an opaque image still shows its own colour (regression guard) */
  PASS(GSPixelIs(over(solidImage(4, 128, 128, 128, 255), 0), 10, 10, 128, 128, 128),
    "an opaque gray image over black shows its colour");

  END_SET("image alpha")
  return 0;
}
