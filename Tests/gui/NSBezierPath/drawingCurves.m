/* Curved paths, checked by reading the pixels back: a filled oval paints its
 * centre and not the corner of its bounding box, and a stroked cubic curve
 * paints along its raised middle rather than along the straight chord.
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

int
main(int argc, const char **argv)
{
  START_SET("curves")

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

  /* A filled oval paints its centre and leaves the corners of the bounding box
   * clear, because the ellipse does not reach the corners. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  {
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p appendBezierPathWithOvalInRect: NSMakeRect(2, 2, 16, 16)];
    [p fill];
  }
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 10, h - 1 - 10, 0, 0, 255),
       "a filled oval paints its centre");
  PASS(rep != nil && GSPixelIs(rep, 3, h - 1 - 3, 255, 255, 255),
       "a filled oval leaves the corner of its bounding box clear");

  /* Stroking a cubic curve follows the curve, not the straight chord.  The
   * curve runs from (2,4) to (18,4) with both control points high, so it peaks
   * near y = 12 at the middle and stays clear of the chord at y = 4. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  {
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p setLineWidth: 2.0];
    [p moveToPoint: NSMakePoint(2, 4)];
    [p curveToPoint: NSMakePoint(18, 4)
       controlPoint1: NSMakePoint(2, 16)
       controlPoint2: NSMakePoint(18, 16)];
    [p stroke];
  }
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 10, h - 1 - 12, 0, 0, 0),
       "a stroked cubic curve paints along its raised middle");
  PASS(rep != nil && GSPixelIs(rep, 10, h - 1 - 4, 255, 255, 255),
       "a stroked cubic curve leaves the straight chord clear");

  END_SET("curves")
  return 0;
}
