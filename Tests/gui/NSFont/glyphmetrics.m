/* Per-glyph metrics through NSFont: the advancement of a glyph, its ink
 * bounding box (which is narrower than the advancement, since the advancement
 * includes the side bearings), that the advancement follows the point size,
 * and that a fixed-pitch font advances every glyph the same.
 *
 * An NSGlyph is an index into the font, so which value stands for a character
 * is the font's business: casting the character gives the metrics of an
 * unrelated glyph.  The glyphs are therefore taken from a layout manager,
 * which maps the characters through the same font the drawing path uses.
 *
 * As in fontmetrics.m, a scaled font is not exactly the unscaled one
 * multiplied, so the size assertion allows a tenth either way.
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

/* The glyph the layout machinery uses for character `index` of `string` when
 * it is set in `font`. */
static NSGlyph
glyphInFont(NSFont *font, NSString *string, unsigned index)
{
  NSTextStorage *storage;
  NSLayoutManager *layout;
  NSTextContainer *container;
  NSGlyph glyph;

  storage = [[NSTextStorage alloc] initWithString: string];
  [storage addAttribute: NSFontAttributeName
                  value: font
                  range: NSMakeRange(0, [string length])];
  layout = [[NSLayoutManager alloc] init];
  container = [[NSTextContainer alloc]
    initWithContainerSize: NSMakeSize(1000, 1000)];
  [layout addTextContainer: container];
  [storage addLayoutManager: layout];

  glyph = ([layout numberOfGlyphs] > index)
    ? [layout glyphAtIndex: index] : NSNullGlyph;

  RELEASE(container);
  RELEASE(layout);
  RELEASE(storage);
  return glyph;
}

int
main(int argc, char **argv)
{
  START_SET("glyph metrics")

  NSFont *f, *big, *mono;
  NSGlyph gW, gi, gA, bigW, monoW, monoi;
  NSSize aW, ai;
  NSRect bW, bi;

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
  mono = [NSFont userFixedPitchFontOfSize: 14];
  if (nil == f || nil == big || nil == mono)
    {
      SKIP("the installed backend builds no font")
    }
  if ([f maximumAdvancement].width <= 0.0)
    {
      SKIP("the installed backend reports no font metrics")
    }
  PASS(f != nil && big != nil && mono != nil, "the fonts are available");

  gW = glyphInFont(f, @"Wi", 0);
  gi = glyphInFont(f, @"Wi", 1);
  gA = glyphInFont(f, @"A", 0);
  bigW = glyphInFont(big, @"Wi", 0);
  monoW = glyphInFont(mono, @"Wi", 0);
  monoi = glyphInFont(mono, @"Wi", 1);

  aW = [f advancementForGlyph: gW];
  ai = [f advancementForGlyph: gi];
  bW = [f boundingRectForGlyph: gW];
  bi = [f boundingRectForGlyph: gi];

  PASS(gW != NSNullGlyph && gi != NSNullGlyph,
    "the layout manager finds a glyph for a character");

  PASS(aW.width > 0.0 && aW.width > ai.width,
    "a W advances further than an i in a proportional font");

  PASS(inProportion([big advancementForGlyph: bigW].width, 2 * aW.width),
    "the glyph advancement follows the point size");

  PASS(bW.size.width > 0.0 && bW.size.height > 0.0,
    "a glyph has a non-empty ink bounding box");

  PASS(bi.size.width > 0.0 && bi.size.width < ai.width,
    "the ink box of an i is narrower than its advancement");

  PASS([mono advancementForGlyph: monoi].width > 0.0
    && nearly([mono advancementForGlyph: monoi].width,
              [mono advancementForGlyph: monoW].width),
    "a fixed-pitch font advances i and W the same");

  PASS([f glyphIsEncoded: gA],
    "a common character is an encoded glyph");

  END_SET("glyph metrics")

  return 0;
}
