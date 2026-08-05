/* A shadow set on the graphics context, checked by reading the pixels back.
 * A shape is drawn with a coloured shadow at a known offset; the offset
 * region carries the shadow colour, the shape sits on top of its own shadow
 * in its own colour, the shadow does not reach beyond its offset region, and
 * restoring the graphics state clears it.  Fill, even-odd fill and stroke
 * are each exercised.
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
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSShadow.h>
#include <stdlib.h>

static NSShadow *
redShadow(void)
{
  NSShadow *s = [[[NSShadow alloc] init] autorelease];

  [s setShadowColor: [NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0
                                           alpha: 1.0]];
  [s setShadowOffset: NSMakeSize(8, -8)];
  [s setShadowBlurRadius: 0.0];
  return s;
}

int
main(int argc, const char **argv)
{
  START_SET("shadow")

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
  NSBezierPath *p;

  /* A blue rectangle with a red shadow offset to the lower right.  The shape
   * spans device x,y in 10..22 and the shadow 18..30 vertically 12..24. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext saveGraphicsState];
  [redShadow() set];
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  [[NSBezierPath bezierPathWithRect: NSMakeRect(10, 20, 12, 12)] fill];
  [NSGraphicsContext restoreGraphicsState];
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 28, h - 1 - 16, 255, 0, 0),
       "a filled shape casts a shadow at the offset location");
  PASS(rep != nil && GSPixelIs(rep, 12, h - 1 - 30, 0, 0, 255),
       "a filled shape is drawn in its own colour");
  PASS(rep != nil && GSPixelIs(rep, 20, h - 1 - 22, 0, 0, 255),
       "a filled shape sits on top of its own shadow");
  PASS(rep != nil && GSPixelIs(rep, 3, h - 1 - 3, 255, 255, 255),
       "the shadow does not extend beyond its offset region");

  /* Even-odd fill casts a shadow through the same path. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext saveGraphicsState];
  [redShadow() set];
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  p = [NSBezierPath bezierPathWithRect: NSMakeRect(10, 20, 12, 12)];
  [p setWindingRule: NSEvenOddWindingRule];
  [p fill];
  [NSGraphicsContext restoreGraphicsState];
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 28, h - 1 - 16, 255, 0, 0),
       "an even-odd fill casts a shadow at the offset location");

  /* A stroked shape casts a shadow of its outline. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext saveGraphicsState];
  [redShadow() set];
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  p = [NSBezierPath bezierPathWithRect: NSMakeRect(10, 20, 12, 12)];
  [p setLineWidth: 6];
  [p stroke];
  [NSGraphicsContext restoreGraphicsState];
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 30, h - 1 - 18, 255, 0, 0),
       "a stroked shape casts a shadow of its outline");
  PASS(rep != nil && GSPixelIs(rep, 22, h - 1 - 26, 0, 0, 255),
       "a stroked shape is drawn in its own colour");

  /* The shadow follows the graphics state stack: after the state that set it is
   * restored, a further fill casts no shadow. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext saveGraphicsState];
  [redShadow() set];
  [NSGraphicsContext restoreGraphicsState];
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  [[NSBezierPath bezierPathWithRect: NSMakeRect(10, 20, 12, 12)] fill];
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 28, h - 1 - 16, 255, 255, 255),
       "a restored graphics state clears the shadow");

  END_SET("shadow")
  return 0;
}
