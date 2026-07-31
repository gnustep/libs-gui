/* GSDrawTest.h

   Shared support for the drawing tests: draw into an offscreen image through
   the AppKit path, read the pixels back, and check them.  This exercises
   whichever backend is installed rather than any one of them, so the same
   test covers cairo, art, xlib and winlib.

   These helpers need a backend, so a test that uses them must keep the usual
   START_SET / SKIP guard.  Colours are checked with a small tolerance,
   because a backend may carry them through fixed-point arithmetic.

   GSRenderTest.h covers the other half of this ground, rendering a view or a
   window through the server; use that when a view hierarchy is what is being
   drawn, and this when the drawing calls themselves are.

   This is header-only (static inline) so each test tool gets its own copy.
*/

#ifndef GSDrawTest_h
#define GSDrawTest_h

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include <stdlib.h>

/* Start drawing into an offscreen image of the given size.  Pair with
   GSDrawEnd, which reads the pixels back. */
static inline NSImage *
GSDrawBegin(int w, int h)
{
  NSImage *img = [[NSImage alloc] initWithSize: NSMakeSize(w, h)];

  [img lockFocus];
  return img;
}

/* Finish the drawing started by GSDrawBegin and return the pixels.  Row 0 of
   the representation is the top of the image. */
static inline NSBitmapImageRep *
GSDrawEnd(NSImage *img, int w, int h)
{
  NSBitmapImageRep *rep;

  [[NSGraphicsContext currentContext] flushGraphics];
  rep = [[NSBitmapImageRep alloc]
	  initWithFocusedViewRect: NSMakeRect(0, 0, w, h)];
  [img unlockFocus];
  [img release];
  return [rep autorelease];
}

/* Whether the pixel at (x, y) is the given device-RGB colour, within a
   tolerance of tol per channel. */
static inline BOOL
GSPixelNear(NSBitmapImageRep *rep, int x, int y, int r, int g, int b, int tol)
{
  NSUInteger	px[5];

  [rep getPixel: px atX: x y: y];
  return (abs((int)px[0] - r) <= tol
	  && abs((int)px[1] - g) <= tol
	  && abs((int)px[2] - b) <= tol);
}

/* Whether the pixel at (x, y) is the given device-RGB colour. */
static inline BOOL
GSPixelIs(NSBitmapImageRep *rep, int x, int y, int r, int g, int b)
{
  return GSPixelNear(rep, x, y, r, g, b, 2);
}

/* The value of one channel of the pixel at (x, y), 0 for red, 1 for green,
   2 for blue. */
static inline int
GSPixelChannel(NSBitmapImageRep *rep, int x, int y, int channel)
{
  NSUInteger	px[5];

  [rep getPixel: px atX: x y: y];
  return (int)px[channel];
}

/* Start drawing into an offscreen image of the given size, with the whole of
   it filled opaque white first, so that a test can check that an area was
   left unpainted. */
static inline NSImage *
GSDrawBeginWhite(int w, int h)
{
  NSImage *img = GSDrawBegin(w, h);

  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, w, h));
  return img;
}

/* Whether the installed backend draws offscreen and reads the pixels back.
   A backend need not: the headless one draws nothing at all, and a server
   may be running without one that can.  A test calls this after the backend
   has started and skips when it answers NO, so that a backend which cannot
   draw reports a skip rather than a wall of failed assertions. */
static inline BOOL
GSCanDrawOffscreen(void)
{
  NSImage		*img;
  NSBitmapImageRep	*rep;
  BOOL			ok = NO;

  NS_DURING
    {
      img = GSDrawBegin(4, 4);
      [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] set];
      NSRectFill(NSMakeRect(0, 0, 4, 4));
      rep = GSDrawEnd(img, 4, 4);
      ok = (rep != nil && GSPixelIs(rep, 2, 2, 255, 0, 0)) ? YES : NO;
    }
  NS_HANDLER
    {
      ok = NO;
    }
  NS_ENDHANDLER
  return ok;
}

/* How many pixels in the rectangle are the given device-RGB colour. */
static inline int
GSPixelCount(NSBitmapImageRep *rep, NSRect area, int r, int g, int b)
{
  int	x, y, n = 0;

  for (y = (int)NSMinY(area); y < (int)NSMaxY(area); y++)
    {
      for (x = (int)NSMinX(area); x < (int)NSMaxX(area); x++)
	{
	  if (GSPixelIs(rep, x, y, r, g, b))
	    {
	      n++;
	    }
	}
    }
  return n;
}

#endif /* GSDrawTest_h */
