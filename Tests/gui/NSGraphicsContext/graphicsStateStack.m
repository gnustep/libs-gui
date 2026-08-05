/* The graphics state stack, checked by reading the pixels back: a save and
 * restore recovers the fill colour that was in force, lifts a clip that was
 * set inside it, and nests, so an inner restore recovers the middle entry
 * and an outer restore the first.
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
  START_SET("graphics state")

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

  /* Restoring the graphics state recovers the earlier fill colour: red is set,
   * the state saved, blue set, then restored, so a fill uses red again. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  [NSGraphicsContext saveGraphicsState];
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  [NSGraphicsContext restoreGraphicsState];
  NSRectFill(NSMakeRect(0, 0, w, h));
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, w / 2, h / 2, 255, 0, 0),
       "restoring the graphics state recovers the earlier fill colour");

  /* Restoring the graphics state recovers the earlier clip: with no clip set, a
   * clip to the left half is applied inside a saved state, then restored, so a
   * following fill reaches the right half again. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext saveGraphicsState];
  NSRectClip(NSMakeRect(0, 0, w / 2, h));
  [NSGraphicsContext restoreGraphicsState];
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, 3 * w / 4, h / 2, 255, 0, 0),
       "restoring the graphics state lifts a clip set inside it");

  /* A clip applied inside a saved state still confines drawing before the
   * restore. */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext saveGraphicsState];
  NSRectClip(NSMakeRect(0, 0, w / 2, h));
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext restoreGraphicsState];
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, w / 4, h / 2, 255, 0, 0)
       && GSPixelIs(rep, 3 * w / 4, h / 2, 255, 255, 255),
       "a clip inside a saved state confines drawing before the restore");

  /* The stack nests: red, save, green, save, blue, inner restore back to green,
   * outer restore back to red.  The left strip is filled after the inner
   * restore (green) and the right strip after the outer restore (red). */
  img = GSDrawBegin(w, h);
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  [NSGraphicsContext saveGraphicsState];
  [[NSColor colorWithDeviceRed: 0.0 green: 1.0 blue: 0.0 alpha: 1.0] set];
  [NSGraphicsContext saveGraphicsState];
  [[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] set];
  [NSGraphicsContext restoreGraphicsState];
  NSRectFill(NSMakeRect(0, 0, w / 2, h));
  [NSGraphicsContext restoreGraphicsState];
  NSRectFill(NSMakeRect(w / 2, 0, w / 2, h));
  rep = GSDrawEnd(img, w, h);
  PASS(rep != nil && GSPixelIs(rep, w / 4, h / 2, 0, 255, 0),
       "an inner restore recovers the middle colour on the stack");
  PASS(rep != nil && GSPixelIs(rep, 3 * w / 4, h / 2, 255, 0, 0),
       "an outer restore recovers the first colour on the stack");

  END_SET("graphics state")
  return 0;
}
