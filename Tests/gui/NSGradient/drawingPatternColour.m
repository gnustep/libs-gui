/* Drawing a gradient whose stops are not RGB colours must not raise.  A
 * pattern colour refuses -redComponent, -greenComponent and -blueComponent,
 * so a backend that reads the components straight off the stop colours raises
 * an NSInternalInconsistencyException instead of drawing.  Both the linear
 * and the radial entry points are checked, since they reach different
 * primitives.
 *
 * None of it is particular to one backend, so it runs against whichever one
 * is installed and skips when there is none.
 */
#import <Foundation/NSObject.h>
#import "Testing.h"
#import "../GSDrawTest.h"

#import <AppKit/AppKit.h>
#include <stdlib.h>

int
main(int argc, const char **argv)
{
  START_SET("gradient with a pattern colour")

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

  NSImage *pat;
  NSColor *pattern;
  NSColor *white;
  NSGradient *g;
  NSImage *img;

  /* A pattern colour, which has no red, green or blue component to read. */
  pat = [[NSImage alloc] initWithSize: NSMakeSize(4, 4)];
  [pat lockFocus];
  [[NSColor colorWithCalibratedRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] setFill];
  NSRectFill(NSMakeRect(0, 0, 4, 4));
  [pat unlockFocus];
  pattern = [NSColor colorWithPatternImage: pat];
  [pat release];

  white = [NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0];

  /* The linear path, through -drawInRect:angle:. */
  g = [[NSGradient alloc] initWithStartingColor: pattern endingColor: white];
  img = GSDrawBegin(100, 100);
  PASS_RUNS(([g drawInRect: NSMakeRect(0, 0, 100, 100) angle: 90.0]),
    "a linear gradient with a pattern colour draws without raising");
  (void)GSDrawEnd(img, 100, 100);
  [g release];

  /* The radial path, through -drawFromCenter:radius:toCenter:radius:options:. */
  g = [[NSGradient alloc] initWithStartingColor: pattern endingColor: white];
  img = GSDrawBegin(100, 100);
  PASS_RUNS(([g drawFromCenter: NSMakePoint(50, 50) radius: 0
                      toCenter: NSMakePoint(50, 50) radius: 50
                       options: 0]),
    "a radial gradient with a pattern colour draws without raising");
  (void)GSDrawEnd(img, 100, 100);
  [g release];

  END_SET("gradient with a pattern colour")

  return 0;
}
