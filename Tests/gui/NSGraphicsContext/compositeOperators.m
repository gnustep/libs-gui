/* The compositing operators, checked by reading the pixels back: copy
 * replaces the destination, source-over shows an opaque source and blends a
 * transparent one, destination-over keeps an opaque destination,
 * plus-lighter adds the two, and clear erases.
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

/* Fill a red destination, then fill it again with FG using OP, and read the
 * centre pixel back. */
static NSBitmapImageRep *
composite(NSColor *fg, NSCompositingOperation op)
{
  int w = 20, h = 20;
  NSImage *img = GSDrawBegin(w, h);

  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [fg set];
  NSRectFillUsingOperation(NSMakeRect(0, 0, w, h), op);
  return GSDrawEnd(img, w, h);
}

int
main(int argc, const char **argv)
{
  START_SET("composite ops")

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

  NSColor *blue = [NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
  NSColor *green = [NSColor colorWithDeviceRed: 0.0 green: 1.0 blue: 0.0 alpha: 1.0];

  PASS(GSPixelIs(composite(blue, NSCompositeCopy), 10, 10, 0, 0, 255),
    "copy replaces the destination with the source");

  PASS(GSPixelIs(composite(blue, NSCompositeSourceOver), 10, 10, 0, 0, 255),
    "source-over with an opaque source shows the source");

  PASS(GSPixelIs(composite(blue, NSCompositeDestinationOver), 10, 10, 255, 0, 0),
    "destination-over keeps the opaque destination");

  PASS(GSPixelIs(composite(green, NSCompositePlusLighter), 10, 10, 255, 255, 0),
    "plus-lighter adds the source to the destination");

  PASS(GSPixelIs(composite(blue, NSCompositeClear), 10, 10, 0, 0, 0),
    "clear erases the destination");

  END_SET("composite ops")
  return 0;
}
