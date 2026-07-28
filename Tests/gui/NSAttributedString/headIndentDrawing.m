#import "Testing.h"
#import "../GSRenderTest.h"
#import <math.h>
#import <AppKit/NSView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSParagraphStyle.h>

/* A paragraph head indent shifts the drawn glyphs to the right on every line
   of the paragraph, first line and wrapped continuation lines alike, so the
   paragraph reads as one block with a common left edge (this matches AppKit).
   Render a wrapped, indented string and check that the first and second drawn
   lines start at the same column, and that the block is actually indented.
   Needs a window server, so it skips cleanly without one. */

#define INDENT 24.0

@interface HeadIndentView : NSView
@end

@implementation HeadIndentView
- (BOOL) isFlipped
{
  return YES;
}
- (void) drawRect: (NSRect)r
{
  NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
  NSDictionary *attrs;
  NSAttributedString *s;

  [[NSColor whiteColor] setFill];
  NSRectFill([self bounds]);

  [p setFirstLineHeadIndent: INDENT];
  [p setHeadIndent: INDENT];
  [p setLineBreakMode: NSLineBreakByWordWrapping];
  attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [NSFont systemFontOfSize: 12], NSFontAttributeName,
             [NSColor blackColor], NSForegroundColorAttributeName,
             p, NSParagraphStyleAttributeName, nil];
  RELEASE(p);
  s = AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"The quick brown fox jumps over the lazy dog"
         attributes: attrs]);
  [s drawInRect: [self bounds]];
}
@end

/* Leftmost column carrying drawn (dark, opaque) content within a row band. */
static int
leftmostContent(NSBitmapImageRep *rep, int y0, int y1)
{
  NSInteger W = [rep pixelsWide];
  int x, y;

  for (x = 0; x < W; x++)
    for (y = y0; y <= y1; y++)
      {
        CGFloat cr, cg, cb, ca;
        [[[rep colorAtX: x y: y]
          colorUsingColorSpaceName: NSDeviceRGBColorSpace]
          getRed: &cr green: &cg blue: &cb alpha: &ca];
        if (isnan(cr) || ca < 0.5)
          continue;
        if ((cr + cg + cb) / 3.0 < 0.5)
          return x;
      }
  return -1;
}

/* Row has any dark, opaque content. */
static BOOL
rowHasContent(NSBitmapImageRep *rep, int y)
{
  NSInteger W = [rep pixelsWide];
  int x, n = 0;

  for (x = 0; x < W; x++)
    {
      CGFloat cr, cg, cb, ca;
      [[[rep colorAtX: x y: y]
        colorUsingColorSpaceName: NSDeviceRGBColorSpace]
        getRed: &cr green: &cg blue: &cb alpha: &ca];
      if (isnan(cr) || ca < 0.5)
        continue;
      if ((cr + cg + cb) / 3.0 < 0.5)
        n++;
    }
  return (n > 2);
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSAttributedString head indent drawing")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      HeadIndentView *v = AUTORELEASE([[HeadIndentView alloc]
        initWithFrame: NSMakeRect(0, 0, 150, 80)]);
      NSBitmapImageRep *rep = GSRenderView(v);
      NSInteger H, y;
      int bands[8][2], nb = 0, inLine = 0, y0 = 0;
      int l1, l2;

      GSSavePNG(rep, @"headindentdrawing");
      H = [rep pixelsHigh];

      /* group content rows into line bands */
      for (y = 0; y < H; y++)
        {
          BOOL c = rowHasContent(rep, (int)y);
          if (c && !inLine) { inLine = 1; y0 = (int)y; }
          else if (!c && inLine)
            {
              inLine = 0;
              if ((int)y - y0 >= 2 && nb < 8)
                { bands[nb][0] = y0; bands[nb][1] = (int)y - 1; nb++; }
            }
        }
      if (inLine && nb < 8) { bands[nb][0] = y0; bands[nb][1] = (int)H - 1; nb++; }

      PASS(nb >= 2, "the indented string wraps to at least two drawn lines");

      if (nb >= 2)
        {
          l1 = leftmostContent(rep, bands[0][0], bands[0][1]);
          l2 = leftmostContent(rep, bands[1][0], bands[1][1]);

          PASS(l1 >= 0 && l2 >= 0, "both lines drew content");
          PASS(l1 >= 0 && l2 >= 0 && abs(l1 - l2) <= 2,
            "the wrapped continuation line starts at the same column as the first line");
          PASS(l1 >= (int)(INDENT) - 6,
            "the paragraph is drawn at the head indent, not flush to the edge");
        }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSAttributedString head indent drawing")
  DESTROY(arp);
  return 0;
}
