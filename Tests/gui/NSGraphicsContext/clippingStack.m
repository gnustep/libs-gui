/* Successive clips intersect: setting a second clip does not replace the
 * first, so drawing is confined to the intersection of the two, and two
 * disjoint clips leave nothing to draw.  The other clipping tests only set a
 * single clip, so this covers the accumulation of the clip stack.
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
  START_SET("clip stack")

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

  /* Two clips intersect: a clip to the left half and then to the top half
   * confine a fill to the top-left quadrant only. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  NSRectClip(NSMakeRect(0, 0, w / 2, h));
  NSRectClip(NSMakeRect(0, h / 2, w, h / 2));
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, w / 4, h - 1 - (3 * h / 4), 255, 0, 0),
       "two clips admit drawing in their intersecting quadrant");
  PASS(rep != nil && GSPixelIs(rep, 3 * w / 4, h - 1 - (3 * h / 4), 255, 255, 255),
       "the quadrant outside the first clip stays clear");
  PASS(rep != nil && GSPixelIs(rep, w / 4, h - 1 - (h / 4), 255, 255, 255),
       "the quadrant outside the second clip stays clear");

  /* Two disjoint clips leave an empty region: a clip to the left half and then
   * to the right half admit no drawing at all. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  NSRectClip(NSMakeRect(0, 0, w / 2, h));
  NSRectClip(NSMakeRect(w / 2, 0, w / 2, h));
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, w / 4, h / 2, 255, 255, 255)
       && GSPixelIs(rep, 3 * w / 4, h / 2, 255, 255, 255),
       "two disjoint clips leave nothing to draw");

  END_SET("clip stack")

  return 0;
}
