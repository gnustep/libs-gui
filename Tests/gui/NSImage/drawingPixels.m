/* The pixels of a drawn image, checked by reading them back: the image keeps
 * its orientation, with the top of the bitmap at the top, and a 24-bit image
 * with no alpha channel decodes to its own colour.
 *
 * None of it is particular to one backend, so it runs against whichever one
 * is installed and skips when there is none.
 */
#import <Foundation/NSObject.h>
#import "Testing.h"
#import "../GSDrawTest.h"

#import <AppKit/AppKit.h>
#include <stdlib.h>

/* Draw SRC scaled over the whole 20x20 canvas with nearest-neighbour sampling,
 * so each source pixel stays a solid block. */
static NSBitmapImageRep *
drawWithColorOnBackground(NSImage *src, NSColor *color, NSColor *background)
{
  int w = 20, h = 20;
  NSImage *dst = [[NSImage alloc] initWithSize: NSMakeSize(w, h)];
  NSBitmapImageRep *rep;

  [dst lockFocus];
  [[NSGraphicsContext currentContext]
    setImageInterpolation: NSImageInterpolationNone];
  [background set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [color set];
  [src drawInRect: NSMakeRect(0, 0, w, h)
         fromRect: NSZeroRect
        operation: NSCompositeSourceOver
         fraction: 1.0];
  [[NSGraphicsContext currentContext] flushGraphics];
  rep = [[NSBitmapImageRep alloc]
          initWithFocusedViewRect: NSMakeRect(0, 0, w, h)];
  [dst unlockFocus];
  [dst release];
  return [rep autorelease];
}

static NSBitmapImageRep *
drawWithColor(NSImage *src, NSColor *color)
{
  return drawWithColorOnBackground(src, color, [NSColor blackColor]);
}

static NSBitmapImageRep *
draw(NSImage *src)
{
  return drawWithColor(src, [NSColor blackColor]);
}

int
main(int argc, const char **argv)
{
  START_SET("image pixels")

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

  NSBitmapImageRep *rep, *out;
  NSImage *src;
  unsigned char *d;
  int i;

  /* A 2x2 image, bitmap row 0 (top) = red, green; row 1 (bottom) = blue, white.
   * Drawn over the canvas it must keep that layout. */
  rep = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: 2 pixelsHigh: 2
                bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
               colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 8 bitsPerPixel: 32];
  d = [rep bitmapData];
  d[0]  = 255; d[1]  = 0;   d[2]  = 0;   d[3]  = 255;   /* top-left  red   */
  d[4]  = 0;   d[5]  = 255; d[6]  = 0;   d[7]  = 255;   /* top-right green */
  d[8]  = 0;   d[9]  = 0;   d[10] = 255; d[11] = 255;   /* bot-left  blue  */
  d[12] = 255; d[13] = 255; d[14] = 255; d[15] = 255;   /* bot-right white */
  src = [[NSImage alloc] initWithSize: NSMakeSize(2, 2)];
  [src addRepresentation: rep];
  [rep release];
  out = draw(src);
  [src release];

  PASS(GSPixelIs(out, 5, 5, 255, 0, 0)
    && GSPixelIs(out, 15, 5, 0, 255, 0)
    && GSPixelIs(out, 5, 15, 0, 0, 255)
    && GSPixelIs(out, 15, 15, 255, 255, 255),
    "the image keeps its orientation, top of the bitmap at the top");

  /* A 24-bit RGB image without alpha decodes to its colour. */
  rep = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: 2 pixelsHigh: 2
                bitsPerSample: 8 samplesPerPixel: 3 hasAlpha: NO isPlanar: NO
               colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 6 bitsPerPixel: 24];
  d = [rep bitmapData];
  for (i = 0; i < 4; i++)
    { d[i * 3 + 0] = 0; d[i * 3 + 1] = 255; d[i * 3 + 2] = 255; }
  src = [[NSImage alloc] initWithSize: NSMakeSize(2, 2)];
  [src addRepresentation: rep];
  [rep release];
  out = draw(src);
  [src release];

  PASS(GSPixelIs(out, 10, 10, 0, 255, 255),
    "a 24-bit rgb image without alpha decodes to its colour");

  /* A template image uses source alpha as a stencil and the current drawing
   * colour as the fill. */
  rep = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: 2 pixelsHigh: 1
                bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
               colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 8 bitsPerPixel: 32];
  d = [rep bitmapData];
  d[0] = 0;   d[1] = 255; d[2] = 0; d[3] = 255;
  d[4] = 255; d[5] = 255; d[6] = 255; d[7] = 0;
  src = [[NSImage alloc] initWithSize: NSMakeSize(2, 1)];
  [src addRepresentation: rep];
  [src setTemplate: YES];
  [rep release];
  out = drawWithColor(src, [NSColor redColor]);

  PASS(GSPixelIs(out, 5, 10, 255, 0, 0)
    && GSPixelIs(out, 15, 10, 0, 0, 0),
    "a template image preserves the current colour across mask drawing");

  out = drawWithColorOnBackground(src, [NSColor redColor], [NSColor whiteColor]);
  [src release];

  PASS(GSPixelIs(out, 5, 10, 255, 0, 0)
    && GSPixelIs(out, 15, 10, 255, 255, 255),
    "a template image leaves transparent source pixels clear");

  END_SET("image pixels")
  return 0;
}
