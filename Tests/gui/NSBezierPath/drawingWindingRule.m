/* The winding rules, checked by reading the pixels back.  A non-zero fill
 * paints a doubly-enclosed region, an even-odd fill leaves it as a hole, and
 * the same two rules apply to a clip built from the path.
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

/* An outer rectangle with a smaller inner rectangle, both appended as rects so
 * they wind the same way.  The inner hole spans device x,y in 7..13. */
static NSBezierPath *
donutPath(void)
{
  NSBezierPath *p = [NSBezierPath bezierPath];
  [p appendBezierPathWithRect: NSMakeRect(2, 2, 16, 16)];
  [p appendBezierPathWithRect: NSMakeRect(7, 7, 6, 6)];
  return p;
}

int
main(int argc, const char **argv)
{
  START_SET("winding rule")

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

  int w = 20, h = 20;
  NSImage *img;
  NSBitmapImageRep *rep;
  NSBezierPath *p;

  /* Non-zero fill: the inner region is enclosed twice, so it is filled and the
   * hole is painted over. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  p = donutPath();
  [p setWindingRule: NSNonZeroWindingRule];
  [p fill];
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 10, h - 1 - 10, 0, 0, 255),
       "a non-zero fill paints the doubly-enclosed inner region");
  PASS(rep != nil && GSPixelIs(rep, 4, h - 1 - 10, 0, 0, 255),
       "a non-zero fill paints the outer ring");

  /* Even-odd fill: the inner region is crossed twice, so it is left as a hole
   * while the outer ring is still painted. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  p = donutPath();
  [p setWindingRule: NSEvenOddWindingRule];
  [p fill];
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 10, h - 1 - 10, 255, 255, 255),
       "an even-odd fill leaves the inner region as a hole");
  PASS(rep != nil && GSPixelIs(rep, 4, h - 1 - 10, 0, 0, 255),
       "an even-odd fill still paints the outer ring");

  /* Even-odd clip: clipping with the even-odd rule confines a following fill to
   * the outer ring and leaves the inner hole and the outside untouched. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  p = donutPath();
  [p setWindingRule: NSEvenOddWindingRule];
  [p addClip];
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 4, h - 1 - 10, 255, 0, 0),
       "an even-odd clip admits drawing in the outer ring");
  PASS(rep != nil && GSPixelIs(rep, 10, h - 1 - 10, 255, 255, 255),
       "an even-odd clip excludes the inner hole");
  PASS(rep != nil && GSPixelIs(rep, 0, h - 1 - 0, 255, 255, 255),
       "an even-odd clip excludes the area outside the path");

  END_SET("winding rule")
  return 0;
}
