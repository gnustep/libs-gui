/* Round line caps and joins, checked by reading the pixels back: a round cap
 * paints on the axis past the endpoint but rounds off the corner that a
 * square cap would fill, and a miter join fills the outer corner more than a
 * round join does.
 *
 * None of it is particular to one backend, so it runs against whichever one
 * is installed and skips when there is none.
 */
#import <Foundation/NSObject.h>
#import "Testing.h"
#import "../GSDrawTest.h"

#import <AppKit/AppKit.h>
#import <AppKit/NSBezierPath.h>
#include <stdlib.h>

/* Count dark pixels in the square [x0,x1) x [y0,y1) of the rep. */
static long
darkCount(NSBitmapImageRep *rep, int x0, int y0, int x1, int y1)
{
  long n = 0;
  int x, y;

  for (y = y0; y < y1; y++)
    for (x = x0; x < x1; x++)
      {
        NSUInteger px[5];

        [rep getPixel: px atX: x y: y];
        if (px[0] < 100)
          n++;
      }
  return n;
}

int
main(int argc, const char **argv)
{
  START_SET("round stroke")

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

  int w = 40, h = 40;
  NSImage *img;
  NSBitmapImageRep *rep;

  /* A round cap paints a half-disc past the endpoint, so a point on the axis
   * just beyond the endpoint is painted, but rounds off the square corner, so a
   * point out at the corner of where a square cap would reach is left clear.
   * The line runs to x = 24 with width 12 (radius 6). */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  {
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p setLineWidth: 12.0];
    [p setLineCapStyle: NSRoundLineCapStyle];
    [p moveToPoint: NSMakePoint(8, 20)];
    [p lineToPoint: NSMakePoint(24, 20)];
    [p stroke];
  }
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 28, h - 1 - 20, 0, 0, 0),
       "a round cap paints on the axis past the endpoint");
  PASS(rep != nil && GSPixelIs(rep, 29, h - 1 - 25, 255, 255, 255),
       "a round cap rounds off the corner a square cap would fill");

  /* A round join cuts the sharp outer corner, so it fills fewer pixels in the
   * outer-corner region than a miter join.  The path bends at (12,12) from a
   * vertical to a horizontal segment; the outer corner is the lower-left. */
  {
    long dark[2] = { 0, 0 };
    int style;

    for (style = 0; style < 2; style++)
      {
        img = GSDrawBegin(w, h);
        [[NSColor whiteColor] set];
        NSRectFill(NSMakeRect(0, 0, w, h));
        [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
        {
          NSBezierPath *p = [NSBezierPath bezierPath];
          [p setLineWidth: 12.0];
          [p setLineJoinStyle: (style == 0 ? NSMiterLineJoinStyle
                                           : NSRoundLineJoinStyle)];
          [p moveToPoint: NSMakePoint(12, 32)];
          [p lineToPoint: NSMakePoint(12, 12)];
          [p lineToPoint: NSMakePoint(32, 12)];
          [p stroke];
        }
        rep = GSDrawEnd(img, w, h);
        /* The miter fills the outer wedge out to the sharp corner at device
         * (6,6); the differing region is device x,y in 6..12, which in rep
         * space is cols 6..12, rows h-1-12 .. h-1-6. */
        dark[style] = darkCount(rep, 5, h - 1 - 12, 13, h - 1 - 5);
      }
    PASS(dark[0] > dark[1],
         "a miter join fills the outer corner more than a round join");
  }

  END_SET("round stroke")
  return 0;
}
