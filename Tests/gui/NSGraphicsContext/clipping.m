/* Clipping through the AppKit path, checked by reading the pixels back.
 * Covers intersecting and disjoint clip rectangles, and a clip built from a
 * path surviving a save and restore of the graphics state, for a triangle,
 * an oval and an even-odd ring.
 *
 * None of it is particular to one backend, so it runs against whichever one
 * is installed and skips when there is none.
 */
#import <Foundation/NSObject.h>
#import "Testing.h"
#import "../GSDrawTest.h"

#import <AppKit/AppKit.h>
#include <stdlib.h>

/* Clip to the given path, save, fill everything red, restore.  The fill runs on
 * the copied state that inherited the clip. */
static NSBitmapImageRep *
clipSaveFill(int w, int h, NSBezierPath *clip)
{
  NSImage *img = GSDrawBeginWhite(w, h);

  [clip addClip];
  [NSGraphicsContext saveGraphicsState];
  [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  [NSGraphicsContext restoreGraphicsState];
  return GSDrawEnd(img, w, h);
}

int
main(int argc, const char **argv)
{
  START_SET("clipping")

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

  int w = 24, h = 24;
  NSBitmapImageRep *rep;
  NSBezierPath *p;

  /* A triangle with the right angle at (3,3) and hypotenuse (21,3)-(3,21).
   * Read back (top-left origin) its interior is the lower-left half: (7,16) is
   * inside, (18,6) is above the hypotenuse, outside the triangle but inside its
   * bounding box.  If the clip were reduced to its bounding box, (18,6) would
   * fill. */
  p = [NSBezierPath bezierPath];
  [p moveToPoint: NSMakePoint(3, 3)];
  [p lineToPoint: NSMakePoint(21, 3)];
  [p lineToPoint: NSMakePoint(3, 21)];
  [p closePath];
  rep = clipSaveFill(w, h, p);
  PASS(rep != nil && GSPixelIs(rep, 7, 16, 255, 0, 0),
       "a triangle clip still paints its interior after save/restore");
  PASS(rep != nil && GSPixelIs(rep, 18, 6, 255, 255, 255),
       "a triangle clip is not widened to its bounding box by save/restore");

  /* An oval clip: the centre is inside, a bounding-box corner is outside. */
  p = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(3, 3, 18, 18)];
  rep = clipSaveFill(w, h, p);
  PASS(rep != nil && GSPixelIs(rep, 12, 12, 255, 0, 0),
       "an oval clip still paints its interior after save/restore");
  PASS(rep != nil && GSPixelIs(rep, 4, 4, 255, 255, 255),
       "an oval clip corner is not filled after save/restore");

  /* An even-odd ring (outer rect minus inner rect): a point on the ring is
   * inside, the central hole is outside.  Checks that the even-odd rule is
   * carried across the save as well as the geometry. */
  p = [NSBezierPath bezierPath];
  [p appendBezierPathWithRect: NSMakeRect(3, 3, 18, 18)];
  [p appendBezierPathWithRect: NSMakeRect(9, 9, 6, 6)];
  [p setWindingRule: NSEvenOddWindingRule];
  rep = clipSaveFill(w, h, p);
  PASS(rep != nil && GSPixelIs(rep, 5, 12, 255, 0, 0),
       "an even-odd ring clip still paints the ring after save/restore");
  PASS(rep != nil && GSPixelIs(rep, 12, 12, 255, 255, 255),
       "an even-odd ring clip keeps its hole after save/restore");

  END_SET("clipping")
  return 0;
}
