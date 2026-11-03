/* Font metrics through NSFont.  The width of a string is its advance (how far
 * the drawing pen moves), so the width of a run of one character is a whole
 * multiple of a single character's width; the ink bounding box, which is
 * narrower, would not add up.  Also check that the metrics follow the point
 * size and that the ascender and descender have the right signs.
 *
 * The metrics of a scaled font are not exactly the metrics of the unscaled one
 * multiplied, because a font may be designed differently at different sizes,
 * so the two size assertions allow a tenth either way.  That is still far
 * inside a backend which ignores the point size altogether.
 *
 * None of this is particular to one backend, so it runs against whichever one
 * is installed and skips when there is none, or when that backend reports no
 * metrics.
 */
#import <Foundation/NSObject.h>
#import "Testing.h"

#import <AppKit/AppKit.h>
#include <stdlib.h>
#include <math.h>

static BOOL
nearly(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;

  return (d < 0.5 && d > -0.5) ? YES : NO;
}

/* `a` is within a tenth of `b`, both being positive metrics. */
static BOOL
inProportion(CGFloat a, CGFloat b)
{
  if (a <= 0.0 || b <= 0.0)
    {
      return NO;
    }
  return (fabs((double)(a - b)) <= 0.1 * (double)b) ? YES : NO;
}

int
main(int argc, char **argv)
{
  START_SET("font metrics")

  NSFont *f, *big;
  CGFloat wi, wiiii, wW, wWWWW;

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  f = [NSFont systemFontOfSize: 14];
  big = [NSFont systemFontOfSize: 28];
  if (nil == f || nil == big)
    {
      SKIP("the installed backend builds no font")
    }
  if ([f maximumAdvancement].width <= 0.0)
    {
      SKIP("the installed backend reports no font metrics")
    }
  PASS(f != nil && big != nil, "the system font is available at two sizes");

  PASS(nearly([f widthOfString: @""], 0.0), "an empty string has zero width");

  /* the width is the advance, so a run of a character is a whole multiple of
   * the single-character width */
  wi = [f widthOfString: @"i"];
  wiiii = [f widthOfString: @"iiii"];
  wW = [f widthOfString: @"W"];
  wWWWW = [f widthOfString: @"WWWW"];
  PASS(wi > 0.0 && nearly(wiiii, 4 * wi),
    "four i's are four times the width of one i");
  PASS(wW > 0.0 && nearly(wWWWW, 4 * wW),
    "four W's are four times the width of one W");

  /* metrics follow the point size */
  PASS(inProportion([big widthOfString: @"Wi"], 2 * [f widthOfString: @"Wi"]),
    "the string width follows the point size");
  PASS(inProportion([big ascender], 2 * [f ascender]),
    "the ascender follows the point size");

  /* the ascender is above the baseline, the descender below */
  PASS([f ascender] > 0.0, "the ascender is positive");
  PASS([f descender] < 0.0, "the descender is negative");

  /* no glyph advances more than the maximum advancement */
  PASS([f maximumAdvancement].width >= wW,
    "the maximum advancement is at least the width of a W");

  END_SET("font metrics")

  return 0;
}
