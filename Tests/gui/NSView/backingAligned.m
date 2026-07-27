#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>

/* -[NSView backingAlignedRect:options:] aligns each axis of a rectangle to the
   backing store grid (scale 1 for a windowless view). The expected values were
   checked against AppKit on a macOS runner. */

static BOOL
rectEqual(NSRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  if (fabs(r.origin.x - x) > 0.001 || fabs(r.origin.y - y) > 0.001
    || fabs(r.size.width - w) > 0.001 || fabs(r.size.height - h) > 0.001)
    {
      printf("expected (%g %g)+(%g %g), got (%g %g)+(%g %g)\n",
             x, y, w, h,
             r.origin.x, r.origin.y, r.size.width, r.size.height);
      return NO;
    }
  return YES;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSView *v;
  NSRect r;
  NSRect n;

  START_SET("NSView backingAlignedRect")

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

  v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)]);

  /* minX=10.3 minY=20.7 maxX=15.7 maxY=27.5 */
  r = NSMakeRect(10.3, 20.7, 5.4, 6.8);

  PASS(rectEqual([v backingAlignedRect: r options: NSAlignAllEdgesNearest],
                 10, 21, 6, 7),
       "all edges nearest rounds each edge to the closest pixel");
  PASS(rectEqual([v backingAlignedRect: r options: NSAlignAllEdgesInward],
                 11, 21, 4, 6),
       "all edges inward shrinks the rectangle to whole pixels");
  PASS(rectEqual([v backingAlignedRect: r options: NSAlignAllEdgesOutward],
                 10, 20, 6, 8),
       "all edges outward grows the rectangle to whole pixels");

  PASS(rectEqual([v backingAlignedRect: r
                              options: NSAlignMinXNearest | NSAlignWidthNearest
                                       | NSAlignMinYNearest | NSAlignHeightNearest],
                 10, 21, 5, 7),
       "a min edge with a size rounds the origin and size independently");
  PASS(rectEqual([v backingAlignedRect: r
                              options: NSAlignMaxXNearest | NSAlignWidthNearest
                                       | NSAlignMaxYNearest | NSAlignHeightNearest],
                 11, 21, 5, 7),
       "a max edge with a size anchors the far edge and rounds the size");
  PASS(rectEqual([v backingAlignedRect: r
                              options: NSAlignMinXInward | NSAlignMaxXOutward
                                       | NSAlignMinYNearest | NSAlignMaxYNearest],
                 11, 21, 5, 7),
       "each edge takes its own rounding direction");

  PASS(rectEqual([v backingAlignedRect: r
                              options: NSAlignAllEdgesNearest | NSAlignRectFlipped],
                 10, 21, 6, 6),
       "the flipped flag rounds a tie on the max Y edge downward");

  /* minX=-3.4 minY=-5.6 maxX=-1.2 maxY=-2.3 */
  n = NSMakeRect(-3.4, -5.6, 2.2, 3.3);
  PASS(rectEqual([v backingAlignedRect: n options: NSAlignAllEdgesNearest],
                 -3, -6, 2, 4),
       "nearest handles a negative-origin rectangle");
  PASS(rectEqual([v backingAlignedRect: n options: NSAlignAllEdgesInward],
                 -3, -5, 1, 2),
       "inward shrinks a negative-origin rectangle");
  PASS(rectEqual([v backingAlignedRect: n options: NSAlignAllEdgesOutward],
                 -4, -6, 3, 4),
       "outward grows a negative-origin rectangle");

  PASS(rectEqual([v backingAlignedRect: NSMakeRect(4, 5, 6, 7)
                              options: NSAlignAllEdgesNearest],
                 4, 5, 6, 7),
       "an already integral rectangle is unchanged");

  {
    BOOL raised = NO;

    NS_DURING
      [v backingAlignedRect: r options: NSAlignMinXInward];
    NS_HANDLER
      if ([[localException name] isEqualToString: NSInvalidArgumentException])
        raised = YES;
    NS_ENDHANDLER
    PASS(raised,
         "an axis without exactly two of min, max and size raises");
  }

  END_SET("NSView backingAlignedRect")

  DESTROY(arp);
  return 0;
}
