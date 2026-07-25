#import "Testing.h"
#import "../GSRenderTest.h"
#import <AppKit/NSFontPanel.h>

/* Local render exercise for NSFontPanel: render the shared panel for real, save
   a PNG to look at, and check its browser interface drew.  Needs a window
   server, so it skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSFontPanel render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSFontPanel *fp = [NSFontPanel sharedFontPanel];
      NSView *content = [fp contentView];
      NSSize sz = [content bounds].size;
      NSBitmapImageRep *rep;

      rep = GSRenderWindow(fp);
      GSSavePNG(rep, @"nsfontpanel");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the font panel renders into a bitmap of its content size");

      /* the family/face/size browsers fill the middle of the panel */
      PASS(GSRegionHasContent(rep,
        NSMakeRect(0, sz.height * 0.35, sz.width, sz.height * 0.4)),
        "the browser area has drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nsfontpanel", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSFontPanel render")
  DESTROY(arp);
  return 0;
}
