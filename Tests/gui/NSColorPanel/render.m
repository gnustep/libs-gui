#import "Testing.h"
#import "../GSRenderTest.h"
#import <AppKit/NSColorPanel.h>

/* Local render exercise for NSColorPanel: render the shared panel for real,
   save a PNG to look at, and check that it drew its picker interface.  Needs a
   window server, so it skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSColorPanel render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSColorPanel *cp = [NSColorPanel sharedColorPanel];
      NSView *content = [cp contentView];
      NSSize sz = [content bounds].size;
      NSBitmapImageRep *rep;

      rep = GSRenderWindow(cp);
      GSSavePNG(rep, @"nscolorpanel");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the color panel renders into a bitmap of its content size");

      /* the picker interface fills the upper part of the panel */
      PASS(GSRegionHasContent(rep,
        NSMakeRect(0, sz.height * 0.4, sz.width, sz.height * 0.5)),
        "the picker area has drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nscolorpanel", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSColorPanel render")
  DESTROY(arp);
  return 0;
}
